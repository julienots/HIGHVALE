class_name CityState
extends RefCounted
## Modèle logique de la cité : grille, bâtiments, chantiers, production et stockage.
## Indépendant de l'affichage 3D pour être testable et sauvegardable.

signal building_added(b: BuildingState)
signal building_removed(b: BuildingState)
signal building_changed(b: BuildingState)
signal task_finished(b: BuildingState)

const TEMPLE_ID := "primordial_temple"
const CANCEL_REFUND_RATIO := 0.5

var grid_size := Vector2i(40, 40)
var buildable_rect := Rect2i(3, 3, 34, 34)
var base_builders := 1
var buildings := {}  # uid -> BuildingState
var _occupancy := {}  # Vector2i -> uid
var _next_uid := 1


func configure(config: GameConfig) -> void:
	grid_size = config.grid_size
	buildable_rect = config.buildable_rect
	base_builders = config.base_builders


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


func is_area_free(cell: Vector2i, size: Vector2i, ignore_uid := 0) -> bool:
	if not buildable_rect.encloses(Rect2i(cell, size)):
		return false
	for x in size.x:
		for y in size.y:
			var owner: int = _occupancy.get(cell + Vector2i(x, y), 0)
			if owner != 0 and owner != ignore_uid:
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
	return cap


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
	_start_task(b, BuildingState.Task.CONSTRUCTING, data.build_seconds_for_level(1), cost, now)
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
	_start_task(b, BuildingState.Task.UPGRADING, b.data().build_seconds_for_level(b.level + 1), cost, now)
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
	return done


# --- Interne --------------------------------------------------------------

func _create(data_id: String, cell: Vector2i, level: int) -> BuildingState:
	var b := BuildingState.new()
	b.uid = _next_uid
	_next_uid += 1
	b.data_id = data_id
	b.cell = cell
	b.level = level
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
	return {"next_uid": _next_uid, "buildings": list}


func from_dict(d: Dictionary) -> void:
	buildings.clear()
	_occupancy.clear()
	_next_uid = int(d.get("next_uid", 1))
	for bd in d.get("buildings", []):
		var b := BuildingState.from_dict(bd)
		if b.data() == null:
			push_warning("CityState : bâtiment inconnu ignoré « %s »" % b.data_id)
			continue
		if not is_area_free(b.cell, b.footprint()):
			push_warning("CityState : chevauchement ignoré pour « %s »" % b.data_id)
			continue
		buildings[b.uid] = b
		_set_occupancy(b, true)
		_next_uid = maxi(_next_uid, b.uid + 1)
