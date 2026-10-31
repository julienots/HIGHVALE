class_name CityState
extends RefCounted
## Modèle logique de la cité : grille, bâtiments, chantiers, production et stockage.
## Indépendant de l'affichage 3D pour être testable et sauvegardable.

signal building_added(b: BuildingState)
signal building_removed(b: BuildingState)
signal building_changed(b: BuildingState)
signal task_finished(b: BuildingState)
signal population_changed
signal wilds_changed

const TEMPLE_ID := "primordial_temple"
const CANCEL_REFUND_RATIO := 0.5

var grid_size := Vector2i(40, 40)
var buildable_rect := Rect2i(3, 3, 34, 34)
var base_builders := 1
var growth_seconds := 20.0
## Habitants présents et horodatage de référence de la croissance.
var inhabitants := 0
var growth_since := 0.0
## Bien-être : base de configuration, fin du festin en cours.
var base_happiness := 40
var feast_until := 0.0
## Ressources sauvages : case -> identifiant de WildResourceData.
var wilds := {}
var next_wild_at := 0.0
var wild_spawn_seconds := 240.0
var max_wilds := 6
var buildings := {}  # uid -> BuildingState
## Recherches de la Bibliothèque et de l'Académie (effets sur la cité et les héros).
var research := ResearchState.new()
var _occupancy := {}  # Vector2i -> uid
var _next_uid := 1


func configure(config: GameConfig) -> void:
	grid_size = config.grid_size
	buildable_rect = config.buildable_rect
	base_builders = config.base_builders
	growth_seconds = config.population_growth_seconds
	base_happiness = config.base_happiness
	wild_spawn_seconds = config.wild_spawn_seconds
	max_wilds = config.max_wilds


# --- Requêtes -------------------------------------------------------------

func get_building(uid: int) -> BuildingState:
	return buildings.get(uid)


func building_at(cell: Vector2i) -> BuildingState:
	return buildings.get(_occupancy.get(cell, 0))


func temple_level() -> int:
	for b in buildings.values():
		if b.data_id == TEMPLE_ID:
			return maxi(b.level, 1)
	return 1


## Nombre d'exemplaires d'un type, chantiers de construction compris.
func count_of(data_id: String) -> int:
	var n := 0
	for b in buildings.values():
		if b.data_id == data_id:
			n += 1
	return n


## Durée d'un chantier, réduite par la recherche « Architecture ».
func build_seconds(data: BuildingData, level: int) -> float:
	return data.build_seconds_for_level(level) * (1.0 - research.value("architecture"))


## Multiplicateur de production apporté par la recherche « Extraction profonde ».
func production_mult() -> float:
	return 1.0 + research.value("extraction")


## Applique les effets de recherche à tous les bâtiments (après avoir figé leur production).
func apply_research(now: float) -> void:
	var mult := production_mult()
	for b: BuildingState in buildings.values():
		if not is_equal_approx(b.prod_mult, mult):
			b.flush(now)
			b.prod_mult = mult


## Niveau le plus élevé parmi les bâtiments d'un type (0 si aucun).
func best_level(data_id: String) -> int:
	var lvl := 0
	for b in buildings.values():
		if b.data_id == data_id:
			lvl = maxi(lvl, b.level)
	return lvl


func is_area_free(cell: Vector2i, size: Vector2i, ignore_uid := 0) -> bool:
	if not buildable_rect.encloses(Rect2i(cell, size)):
		return false
	for x in size.x:
		for y in size.y:
			var c := cell + Vector2i(x, y)
			var owner: int = _occupancy.get(c, 0)
			if (owner != 0 and owner != ignore_uid) or wilds.has(c):
				return false
	return true


func builders_total() -> int:
	var n := base_builders
	for b in buildings.values():
		if b.level >= 1:
			n += b.data().builders_provided
	return n


func builders_busy() -> int:
	var n := 0
	for b in buildings.values():
		if b.is_busy():
			n += 1
	return n


func has_free_builder() -> bool:
	return builders_busy() < builders_total()


func population_capacity() -> int:
	var n := 0
	for b in buildings.values():
		n += b.data().population_for_level(b.level)
	return n


## Capacité de stockage d'une ressource : base + bonus de tous les bâtiments.
func storage_capacity(resource_id: String) -> int:
	var rt := DataRegistry.resource_type(resource_id)
	if rt == null:
		return 0
	if rt.base_capacity < 0:
		return Wallet.UNLIMITED
	var cap := rt.base_capacity
	for b in buildings.values():
		cap += int(b.data().storage_for_level(b.level).get(resource_id, 0))
	return int(cap * (1.0 + research.value("warehouses")))


## Vérifie qu'un nouveau bâtiment peut être construit (hors emplacement). "" = OK.
func can_build_reason(data: BuildingData, wallet: Wallet) -> String:
	if not data.is_available():
		return "Prochainement : %s" % FeatureFlags.module_name(data.feature)
	var tl := temple_level()
	if tl < data.unlock_temple_level:
		return "Temple Primordial niveau %d requis" % data.unlock_temple_level
	if count_of(data.id) >= data.max_count(tl):
		return "Nombre maximal atteint (%d)" % data.max_count(tl)
	if not has_free_builder():
		return "Aucun bâtisseur disponible"
	if not wallet.can_afford(data.cost_for_level(1)):
		return "Ressources insuffisantes"
	return ""


func can_upgrade_reason(b: BuildingState, wallet: Wallet) -> String:
	var d := b.data()
	if b.is_busy():
		return "Chantier en cours"
	if b.level >= d.max_level:
		return "Niveau maximal atteint"
	if b.data_id != TEMPLE_ID and b.level >= d.level_cap(temple_level()):
		return "Améliorez le Temple Primordial"
	if not has_free_builder():
		return "Aucun bâtisseur disponible"
	if not wallet.can_afford(d.cost_for_level(b.level + 1)):
		return "Ressources insuffisantes"
	return ""


# --- Actions --------------------------------------------------------------

## Pose un nouveau bâtiment et démarre sa construction. Retourne null en cas d'échec.
func place_new(data: BuildingData, cell: Vector2i, wallet: Wallet, now: float) -> BuildingState:
	if can_build_reason(data, wallet) != "" or not is_area_free(cell, data.footprint):
		return null
	var cost := data.cost_for_level(1)
	wallet.spend(cost)
	var b := _create(data.id, cell, 0)
	_start_task(b, BuildingState.Task.CONSTRUCTING, build_seconds(data, 1), cost, now)
	building_added.emit(b)
	update(now)
	return b


## Ajoute un bâtiment déjà construit (nouvelle partie, récompenses).
func add_built(data_id: String, cell: Vector2i, level: int, now: float) -> BuildingState:
	var data := DataRegistry.building(data_id)
	if data == null or not is_area_free(cell, data.footprint):
		return null
	var b := _create(data_id, cell, level)
	b.prod_since = now
	building_added.emit(b)
	return b


func move(b: BuildingState, cell: Vector2i) -> bool:
	if not is_area_free(cell, b.footprint(), b.uid):
		return false
	_set_occupancy(b, false)
	b.cell = cell
	_set_occupancy(b, true)
	building_changed.emit(b)
	return true


func start_upgrade(b: BuildingState, wallet: Wallet, now: float) -> String:
	var reason := can_upgrade_reason(b, wallet)
	if reason != "":
		return reason
	var cost := b.data().cost_for_level(b.level + 1)
	wallet.spend(cost)
	b.prod_carry = b.stored_production(now)
	_start_task(b, BuildingState.Task.UPGRADING, build_seconds(b.data(), b.level + 1), cost, now)
	building_changed.emit(b)
	update(now)
	return ""


## Annule un chantier : rembourse une partie du coût. Une construction annulée retire le bâtiment.
func cancel_task(b: BuildingState, wallet: Wallet, now: float) -> void:
	if not b.is_busy():
		return
	var refund := {}
	for id in b.task_cost:
		refund[id] = int(b.task_cost[id] * CANCEL_REFUND_RATIO)
	wallet.refund(refund)
	if b.task == BuildingState.Task.CONSTRUCTING:
		remove(b)
		return
	b.task = BuildingState.Task.NONE
	b.task_cost = {}
	b.prod_since = now
	building_changed.emit(b)


func remove(b: BuildingState) -> void:
	_set_occupancy(b, false)
	buildings.erase(b.uid)
	building_removed.emit(b)
	update_population(growth_since)


## Coût en monnaie premium pour terminer immédiatement un chantier.
func speedup_cost(b: BuildingState, now: float, config: GameConfig) -> int:
	var remaining := b.task_remaining(now)
	if remaining <= config.free_speedup_seconds:
		return 0
	return maxi(1, int(ceil(config.speedup_factor * pow(remaining / 60.0, config.speedup_exponent))))


func speed_up(b: BuildingState, wallet: Wallet, now: float, config: GameConfig) -> bool:
	if not b.is_busy():
		return false
	var cost := speedup_cost(b, now, config)
	if cost > 0 and not wallet.spend({config.premium_resource: cost}):
		return false
	_finish_task(b, now)
	return true


## Collecte la production d'un bâtiment dans la limite de la place disponible.
func collect(b: BuildingState, wallet: Wallet, now: float) -> int:
	var d := b.data()
	if d.produces.is_empty():
		return 0
	var stored := b.stored_production(now)
	var taken := mini(int(floor(stored)), wallet.free_space(d.produces))
	if taken <= 0:
		return 0
	wallet.add(d.produces, taken)
	b.prod_carry = stored - taken
	if not b.is_busy():
		b.prod_since = now
	building_changed.emit(b)
	return taken


## Termine les chantiers échus. Retourne les bâtiments terminés.
func update(now: float) -> Array[BuildingState]:
	var done: Array[BuildingState] = []
	for b in buildings.values():
		if b.is_busy() and now >= b.task_end:
			done.append(b)
	# Ordre chronologique : important pour la progression hors ligne.
	done.sort_custom(func(a, c): return a.task_end < c.task_end)
	for b in done:
		_finish_task(b, b.task_end)
	if not research.update(now).is_empty():
		apply_research(now)
	update_population(now)
	update_wilds(now)
	return done


# --- Population -------------------------------------------------------------

func workers_total() -> int:
	var n := 0
	for b in buildings.values():
		n += b.workers
	return n


func idle_inhabitants() -> int:
	return maxi(inhabitants - workers_total(), 0)


## Secondes avant l'arrivée du prochain habitant (-1 si les logements sont pleins).
func next_arrival_in(now: float) -> float:
	if inhabitants >= population_capacity():
		return -1.0
	return maxf(growth_interval(now) - (now - growth_since), 0.0)


# --- Bien-être -----------------------------------------------------------------

func comfort() -> int:
	var n := 0
	for b in buildings.values():
		n += b.data().comfort_for_level(b.level)
	return n


func feast_active(now: float) -> bool:
	return now < feast_until


## Bien-être de 0 à 100 : base + confort des bâtiments + festin éventuel.
func happiness(now: float, feast_bonus := 25) -> int:
	return clampi(base_happiness + comfort() + int(research.value("festivities")) + (feast_bonus if feast_active(now) else 0), 0, 100)


## Intervalle entre deux arrivées : deux fois plus long à 0 %, deux fois plus court à 100 %.
func growth_interval(now: float) -> float:
	return growth_seconds * lerpf(2.0, 0.5, happiness(now) / 100.0)


func start_feast(wallet: Wallet, now: float, config: GameConfig) -> String:
	if feast_active(now):
		return "Un festin est déjà en cours"
	if not wallet.spend(config.feast_cost):
		return "Pas assez de nectar"
	update_population(now)
	feast_until = now + config.feast_seconds
	population_changed.emit()
	return ""


# --- Ressources sauvages ------------------------------------------------------

func wild_at(cell: Vector2i) -> String:
	return wilds.get(cell, "")


## Fait apparaître les ressources sauvages échues (aussi hors ligne), sans dépasser le maximum.
func update_wilds(now: float) -> void:
	if next_wild_at <= 0.0:
		next_wild_at = now + wild_spawn_seconds
	var spawned := false
	while now >= next_wild_at:
		if wilds.size() < max_wilds:
			spawned = spawn_wild(int(next_wild_at)) or spawned
		next_wild_at += wild_spawn_seconds
	if spawned:
		wilds_changed.emit()


## Place une ressource sauvage sur une case libre, à l'écart des bâtiments.
func spawn_wild(seed: int) -> bool:
	var kinds := DataRegistry.all_wilds()
	if kinds.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var total := 0.0
	for k in kinds:
		total += k.weight
	var roll := rng.randf() * total
	var kind: WildResourceData = kinds[0]
	for k in kinds:
		roll -= k.weight
		if roll <= 0.0:
			kind = k
			break
	for attempt in 60:
		var c := Vector2i(rng.randi_range(buildable_rect.position.x + 1, buildable_rect.end.x - 2),
			rng.randi_range(buildable_rect.position.y + 1, buildable_rect.end.y - 2))
		if is_area_free(c - Vector2i.ONE, Vector2i(3, 3)):
			wilds[c] = kind.id
			return true
	return false


## Récolte une ressource sauvage. Retourne les quantités réellement obtenues.
func harvest_wild(cell: Vector2i, wallet: Wallet, premium_id: String, now: float) -> Dictionary:
	var kind := DataRegistry.wild(wilds.get(cell, ""))
	if kind == null:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([cell, int(now)])
	var got := {}
	for id in kind.rewards:
		var r: Vector2i = kind.rewards[id]
		var added := wallet.add(id, rng.randi_range(r.x, r.y))
		if added > 0:
			got[id] = added
	if kind.premium_chance > 0.0 and rng.randf() < kind.premium_chance:
		got[premium_id] = wallet.add(premium_id, rng.randi_range(kind.premium_amount.x, kind.premium_amount.y))
	wilds.erase(cell)
	if wilds.size() == max_wilds - 1:
		# Le minuteur repart à la récolte quand la cité était pleine.
		next_wild_at = maxf(next_wild_at, now + wild_spawn_seconds)
	wilds_changed.emit()
	return got


## Croissance de la population (aussi hors ligne) puis affectation aux postes libres.
func update_population(now: float) -> void:
	var cap := population_capacity()
	var before := inhabitants
	if inhabitants > cap:
		inhabitants = cap
		_trim_workers(now)
	if inhabitants >= cap:
		growth_since = now
	elif growth_seconds > 0.0 and now > growth_since:
		var interval := growth_interval(now)
		var arrivals := int((now - growth_since) / interval)
		if arrivals > 0:
			inhabitants = mini(inhabitants + arrivals, cap)
			growth_since = now if inhabitants >= cap else growth_since + arrivals * interval
	if inhabitants != before:
		population_changed.emit()
	auto_assign(now)


## Répartit les habitants libres vers les postes les moins pourvus.
func auto_assign(now: float) -> void:
	var changed: Array[BuildingState] = []
	while idle_inhabitants() > 0:
		var best: BuildingState = null
		var best_ratio := 2.0
		for b in buildings.values():
			if b.level < 1 or b.workers >= b.worker_target():
				continue
			var ratio: float = float(b.workers) / b.worker_slots()
			if ratio < best_ratio or (ratio == best_ratio and best and b.uid < best.uid):
				best = b
				best_ratio = ratio
		if best == null:
			break
		best.flush(now)
		best.workers += 1
		if not best in changed:
			changed.append(best)
	for b in changed:
		building_changed.emit(b)
	if not changed.is_empty():
		population_changed.emit()


## Choix du joueur : nombre d'ouvriers souhaité dans un bâtiment.
func set_desired_workers(b: BuildingState, count: int, now: float) -> void:
	b.desired_workers = clampi(count, 0, b.worker_slots())
	if b.workers > b.worker_target():
		b.flush(now)
		b.workers = b.worker_target()
	auto_assign(now)
	building_changed.emit(b)
	population_changed.emit()


func _trim_workers(now: float) -> void:
	while workers_total() > inhabitants:
		var most: BuildingState = null
		for b in buildings.values():
			if b.workers > 0 and (most == null or b.workers > most.workers):
				most = b
		most.flush(now)
		most.workers -= 1
		building_changed.emit(most)


# --- Interne --------------------------------------------------------------

func _create(data_id: String, cell: Vector2i, level: int) -> BuildingState:
	var b := BuildingState.new()
	b.uid = _next_uid
	_next_uid += 1
	b.data_id = data_id
	b.cell = cell
	b.level = level
	b.prod_mult = production_mult()
	buildings[b.uid] = b
	_set_occupancy(b, true)
	return b


func _start_task(b: BuildingState, task: BuildingState.Task, seconds: float, cost: Dictionary, now: float) -> void:
	b.task = task
	b.task_start = now
	b.task_end = now + seconds
	b.task_cost = cost


func _finish_task(b: BuildingState, at: float) -> void:
	b.level += 1
	b.task = BuildingState.Task.NONE
	b.task_cost = {}
	b.prod_since = at
	auto_assign(at)
	building_changed.emit(b)
	task_finished.emit(b)


func _set_occupancy(b: BuildingState, occupied: bool) -> void:
	var r := b.rect()
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			if occupied:
				_occupancy[Vector2i(x, y)] = b.uid
			else:
				_occupancy.erase(Vector2i(x, y))


# --- Sauvegarde -----------------------------------------------------------

func to_dict() -> Dictionary:
	var list := []
	for b in buildings.values():
		list.append(b.to_dict())
	var wild_list := []
	for c in wilds:
		wild_list.append({"x": c.x, "y": c.y, "id": wilds[c]})
	return {"next_uid": _next_uid, "buildings": list, "inhabitants": inhabitants, "growth_since": growth_since,
		"feast_until": feast_until, "wilds": wild_list, "next_wild_at": next_wild_at, "research": research.to_dict()}


func from_dict(d: Dictionary) -> void:
	buildings.clear()
	_occupancy.clear()
	_next_uid = int(d.get("next_uid", 1))
	inhabitants = int(d.get("inhabitants", 0))
	growth_since = float(d.get("growth_since", 0.0))
	feast_until = float(d.get("feast_until", 0.0))
	next_wild_at = float(d.get("next_wild_at", 0.0))
	research.from_dict(d.get("research", {}))
	wilds.clear()
	for bd in d.get("buildings", []):
		var b := BuildingState.from_dict(bd)
		if b.data() == null:
			push_warning("CityState : bâtiment inconnu ignoré « %s »" % b.data_id)
			continue
		if not is_area_free(b.cell, b.footprint()):
			push_warning("CityState : chevauchement ignoré pour « %s »" % b.data_id)
			continue
		b.prod_mult = production_mult()
		buildings[b.uid] = b
		_set_occupancy(b, true)
		_next_uid = maxi(_next_uid, b.uid + 1)
	for w in d.get("wilds", []):
		var c := Vector2i(int(w.get("x", 0)), int(w.get("y", 0)))
		if DataRegistry.wild(str(w.get("id", ""))) and building_at(c) == null:
			wilds[c] = str(w.get("id", ""))
