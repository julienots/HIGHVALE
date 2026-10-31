class_name Villager
extends Node3D
## Habitant visible : marche sur la grille, travaille, rapporte sa récolte.
## Le modèle glTF fournit des pièces articulées (legl, legr, arml, armr, body, carry).

enum Job { CITIZEN, MINER, CRYSTAL_MINER, FARMER, PORTER, BUILDER }
enum Mode { IDLE, WALK, WORK }

const MODELS := {
	Job.CITIZEN: preload("res://assets/models/characters/villager_citizen.glb"),
	Job.MINER: preload("res://assets/models/characters/villager_miner.glb"),
	Job.CRYSTAL_MINER: preload("res://assets/models/characters/villager_crystal_miner.glb"),
	Job.FARMER: preload("res://assets/models/characters/villager_farmer.glb"),
	Job.PORTER: preload("res://assets/models/characters/villager_porter.glb"),
	Job.BUILDER: preload("res://assets/models/characters/villager_builder.glb"),
}
const SPEED := 1.15
const SCALE := 1.25

var job := Job.CITIZEN
var key := ""
var work_uid := 0
var view: PopulationView
var mode := Mode.IDLE
var carrying := false

var _parts := {}  # préfixe -> Array[Node3D]
var _rest := {}  # Node3D -> Vector3 (rotation au repos)
var _path := PackedVector3Array()
var _path_i := 0
var _timer := 0.0
var _anim := 0.0
var _on_arrive := Callable()
var _stage := 0
var _rng := RandomNumberGenerator.new()


func setup(p_job: Job, p_key: String, p_work_uid: int, p_view: PopulationView) -> void:
	job = p_job
	key = p_key
	work_uid = p_work_uid
	view = p_view
	_rng.seed = hash(p_key)
	name = "Villager_" + p_key.replace(":", "_")
	var model: Node3D = MODELS[job].instantiate()
	model.scale = Vector3.ONE * SCALE
	add_child(model)
	for n in _all(model):
		if n is MeshInstance3D:
			ModelRig._prepare_materials(n)
		if n is Node3D:
			var prefix := String(n.name).split("_")[0]
			if prefix in ["legl", "legr", "arml", "armr", "body", "carry"]:
				if not _parts.has(prefix):
					_parts[prefix] = []
				_parts[prefix].append(n)
				_rest[n] = n.rotation
	_set_carry(false)
	_anim = _rng.randf() * TAU
	_think()


## Recalcule le trajet en cours (bâtiments déplacés, posés ou détruits).
func replan() -> void:
	if mode == Mode.WALK and _path.size() > 0:
		var target := CityNav.world_to_cell(_path[_path.size() - 1])
		_walk_to(target, _on_arrive)


func _process(delta: float) -> void:
	match mode:
		Mode.WALK:
			_step(delta)
		Mode.WORK, Mode.IDLE:
			_timer -= delta
			if _timer <= 0.0:
				_think()
	_animate(delta)


# --- Comportement -------------------------------------------------------------

func _think() -> void:
	var city := GameState.city
	var work := city.get_building(work_uid) if work_uid else null
	match job:
		Job.BUILDER:
			if work and work.is_busy():
				if _stage == 0:
					_stage = 1
					_walk_to(view.nav.door_cell(work), func(): _start_work(3.0))
				else:
					_start_work(3.0)
			else:
				_wander()
		Job.CITIZEN:
			_wander()
		_:
			if work == null:
				_wander()
				return
			# Cycle : travail au bâtiment, puis livraison au dépôt.
			if _stage == 0:
				_stage = 1
				_set_carry(false)
				_walk_to(view.nav.door_cell(work), func(): _start_work(_rng.randf_range(4.0, 7.0)))
			else:
				_stage = 0
				_set_carry(true)
				var depot := view.depot_for(work)
				if depot:
					_walk_to(view.nav.door_cell(depot), func():
						_set_carry(false)
						_idle(_rng.randf_range(0.6, 1.4)))
				else:
					_idle(1.0)


func _wander() -> void:
	_stage = 0
	var center := view.plaza_cell()
	var target := view.nav.random_cell_near(center, 7, _rng)
	_walk_to(target, func(): _idle(_rng.randf_range(1.5, 4.0)))


func _start_work(duration: float) -> void:
	mode = Mode.WORK
	_timer = duration
	var work := GameState.city.get_building(work_uid) if work_uid else null
	if work:
		_face(Vector3(work.rect().get_center().x, 0, work.rect().get_center().y) - position)


func _idle(duration: float) -> void:
	mode = Mode.IDLE
	_timer = duration


func _walk_to(cell: Vector2i, on_arrive: Callable) -> void:
	_on_arrive = on_arrive
	_path = view.nav.path(CityNav.world_to_cell(position), cell)
	_path_i = 0
	if _path.is_empty():
		_idle(1.5)
		return
	mode = Mode.WALK


func _step(delta: float) -> void:
	if _path_i >= _path.size():
		mode = Mode.IDLE
		_timer = 0.0
		if _on_arrive.is_valid():
			var cb := _on_arrive
			_on_arrive = Callable()
			cb.call()
		return
	var target := _path[_path_i]
	var to := target - position
	to.y = 0.0
	var dist := to.length()
	var move := SPEED * delta
	if dist <= move:
		position = Vector3(target.x, 0, target.z)
		_path_i += 1
	else:
		position += to / dist * move
		_face(to)


func _face(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 0.35)


func _set_carry(on: bool) -> void:
	carrying = on
	for n in _parts.get("carry", []):
		n.visible = on


# --- Animation ---------------------------------------------------------------

func _animate(delta: float) -> void:
	match mode:
		Mode.WALK:
			_anim += delta * 9.0
			var s := sin(_anim)
			_rot("legl", s * 0.55)
			_rot("legr", -s * 0.55)
			_rot("arml", -s * 0.5)
			_rot("armr", (-1.1 if carrying else s * 0.5))
			_rot("body", 0.0)
			_body_bob(absf(s) * 0.02)
		Mode.WORK:
			_anim += delta * (7.0 if job in [Job.MINER, Job.CRYSTAL_MINER, Job.BUILDER] else 4.0)
			var swing := sin(_anim)
			_rot("legl", 0.0)
			_rot("legr", 0.0)
			match job:
				Job.FARMER:
					_rot("body", 0.35)
					_rot("armr", -0.8 + swing * 0.5)
					_rot("arml", -0.4)
				Job.PORTER:
					_rot("body", 0.0)
					_rot("armr", -0.6 + swing * 0.2)
					_rot("arml", -0.6 - swing * 0.2)
				_:
					# Coup de pioche ou de marteau : levé lent, frappe rapide.
					var hit := pow(maxf(swing, 0.0), 0.5)
					_rot("armr", -2.2 * hit)
					_rot("arml", -0.3)
					_rot("body", 0.12 - 0.12 * hit)
			_body_bob(0.0)
		Mode.IDLE:
			_anim += delta * 2.0
			_rot("legl", 0.0)
			_rot("legr", 0.0)
			_rot("arml", sin(_anim) * 0.05)
			_rot("armr", -sin(_anim) * 0.05)
			_rot("body", 0.0)
			_body_bob(sin(_anim) * 0.004)


func _rot(prefix: String, angle_x: float) -> void:
	for n in _parts.get(prefix, []):
		var r: Vector3 = _rest[n]
		n.rotation = Vector3(r.x + angle_x, r.y, r.z)


func _body_bob(h: float) -> void:
	get_child(0).position.y = h


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in n.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out
