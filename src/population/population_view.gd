class_name PopulationView
extends Node3D
## Fait vivre la cité : un habitant visible par poste (deux au plus par
## bâtiment), un bâtisseur par chantier et quelques flâneurs.

const MAX_VISIBLE := 26
const MAX_PER_BUILDING := 2
const MAX_WANDERERS := 6
const JOBS := {
	"stone_mine": Villager.Job.MINER,
	"crystal_mine": Villager.Job.CRYSTAL_MINER,
	"fungal_grove": Villager.Job.FARMER,
	"treasury": Villager.Job.PORTER,
}

var nav := CityNav.new()
var villagers := {}  # clé de rôle -> Villager
var _accum := 0.0


func _ready() -> void:
	rebuild_nav()
	Events.building_added.connect(func(_u): rebuild_nav())
	Events.building_removed.connect(func(_u): rebuild_nav())
	Events.building_changed.connect(_on_building_changed)
	Events.population_changed.connect(refresh_roster)
	Events.wilds_changed.connect(rebuild_nav)
	Events.game_loaded.connect(func():
		for v in villagers.values():
			v.queue_free()
		villagers.clear()
		rebuild_nav())
	refresh_roster()


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.5:
		_accum = 0.0
		refresh_roster()


func rebuild_nav() -> void:
	nav.rebuild(GameState.city)
	for v in villagers.values():
		v.replan()
	refresh_roster()


func _on_building_changed(_uid: int) -> void:
	# Un déplacement modifie la grille ; les autres changements n'ont pas d'effet ici.
	var signature := _occupancy_signature()
	if signature != get_meta("occ", ""):
		set_meta("occ", signature)
		rebuild_nav()


func _occupancy_signature() -> String:
	var parts: Array[String] = []
	for b in GameState.city.buildings.values():
		parts.append("%d:%d,%d" % [b.uid, b.cell.x, b.cell.y])
	return "|".join(parts)


## Rôles souhaités d'après l'état de la cité ; crée et retire les habitants.
func refresh_roster() -> void:
	if not is_inside_tree():
		return
	var city := GameState.city
	var wanted := {}  # clé -> [job, uid]
	var list: Array = city.buildings.values()
	list.sort_custom(func(a, b): return a.uid < b.uid)
	for b in list:
		if JOBS.has(b.data_id):
			for i in mini(b.workers, MAX_PER_BUILDING):
				wanted["w:%d:%d" % [b.uid, i]] = [JOBS[b.data_id], b.uid]
		if b.is_busy():
			wanted["b:%d" % b.uid] = [Villager.Job.BUILDER, b.uid]
	for i in mini(city.idle_inhabitants(), MAX_WANDERERS):
		wanted["c:%d" % i] = [Villager.Job.CITIZEN, 0]
	var keys: Array = wanted.keys()
	keys = keys.slice(0, MAX_VISIBLE)
	for k in villagers.keys():
		if not k in keys:
			_despawn(villagers[k])
			villagers.erase(k)
	for k in keys:
		if not villagers.has(k):
			var v := Villager.new()
			add_child(v)
			var spawn := _spawn_cell(wanted[k][1])
			v.position = Vector3(spawn.x + 0.5, 0, spawn.y + 0.5)
			v.setup(wanted[k][0], k, wanted[k][1], self)
			villagers[k] = v


func _despawn(v: Villager) -> void:
	var t := v.create_tween()
	t.tween_property(v, "scale", Vector3.ZERO, 0.3)
	t.tween_callback(v.queue_free)


## Les habitants sortent de leur logement (Hôtel le plus proche ou Temple).
func _spawn_cell(work_uid: int) -> Vector2i:
	var work := GameState.city.get_building(work_uid) if work_uid else null
	var best: BuildingState = null
	var best_d := INF
	for b in GameState.city.buildings.values():
		if b.data().population_base <= 0 or b.level < 1:
			continue
		var d := 0.0 if work == null else Vector2(b.cell).distance_to(Vector2(work.cell))
		if d < best_d:
			best_d = d
			best = b
	return nav.door_cell(best) if best else plaza_cell()


## Lieu de dépôt des récoltes : Entrepôt le plus proche, sinon le Temple.
func depot_for(work: BuildingState) -> BuildingState:
	var best: BuildingState = null
	var best_d := INF
	for b in GameState.city.buildings.values():
		if b.level < 1 or not (b.data_id == "warehouse" or b.data_id == CityState.TEMPLE_ID):
			continue
		if work.data_id == "treasury" and b.data_id != CityState.TEMPLE_ID:
			continue
		var d := Vector2(b.cell).distance_to(Vector2(work.cell)) * (1.0 if b.data_id == "warehouse" else 1.6)
		if d < best_d:
			best_d = d
			best = b
	return best


## Place centrale (devant le Temple) où flânent les habitants libres.
func plaza_cell() -> Vector2i:
	for b in GameState.city.buildings.values():
		if b.data_id == CityState.TEMPLE_ID:
			return nav.door_cell(b) + Vector2i(0, 2)
	return GameState.city.buildable_rect.get_center()
