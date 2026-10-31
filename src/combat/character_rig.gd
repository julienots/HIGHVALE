class_name CharacterRig
extends Node3D
## Personnage (héros ou créature) animé à partir d'un modèle glTF articulé :
## respiration, bras, ailes, queue. Réutilisable par la collection et le combat.

const PARTS := ["legl", "legr", "arml", "armr", "body", "wingl", "wingr", "tail", "carry"]

var _parts := {}  # préfixe -> Array[Node3D]
var _rest := {}
var _time := 0.0
var _phase := randf() * TAU
var _model: Node3D


func setup(scene: PackedScene) -> void:
	_model = scene.instantiate()
	add_child(_model)
	ModelRig.apply(_model, 3)
	for n in _all(_model):
		if n is Node3D:
			var prefix := String(n.name).split("_")[0]
			if prefix in PARTS:
				if not _parts.has(prefix):
					_parts[prefix] = []
				_parts[prefix].append(n)
				_rest[n] = n.rotation
	for n in _parts.get("carry", []):
		n.visible = false


func _process(delta: float) -> void:
	_time += delta
	var t := _time * 2.2 + _phase
	var breathe := sin(t)
	_rot("body", Vector3(breathe * 0.04, 0, 0))
	_rot("arml", Vector3(-0.15 + breathe * 0.12, 0, -0.08))
	_rot("armr", Vector3(-0.25 - breathe * 0.12, 0, 0.08))
	_rot("legl", Vector3.ZERO)
	_rot("legr", Vector3.ZERO)
	var flap := sin(_time * 9.0 + _phase)
	_rot("wingl", Vector3(0, 0, -flap * 0.55))
	_rot("wingr", Vector3(0, 0, flap * 0.55))
	_rot("tail", Vector3(0, sin(_time * 3.0) * 0.35, 0))
	if _model:
		_model.position.y = 0.02 + maxf(sin(_time * 4.0 + _phase), 0.0) * 0.015 if _parts.has("wingl") else 0.0
	_animate_meta(delta)


func _animate_meta(delta: float) -> void:
	for n in _all(_model):
		if n is Node3D and n.has_meta("spin"):
			n.rotation_degrees += (n.get_meta("spin") as Vector3) * delta


func _rot(prefix: String, offset: Vector3) -> void:
	for n in _parts.get(prefix, []):
		n.rotation = _rest[n] + offset


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if n == null:
		return out
	for c in n.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out
