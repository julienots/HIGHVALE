class_name WildView
extends Node3D
## Affiche les ressources sauvages de la cité (filons, champignons, cristaux).

var _nodes := {}  # Vector2i -> Node3D


func _ready() -> void:
	Events.wilds_changed.connect(refresh)
	Events.game_loaded.connect(refresh)
	refresh()


func refresh() -> void:
	var wilds := GameState.city.wilds
	for c in _nodes.keys():
		if not wilds.has(c):
			_remove(_nodes[c])
			_nodes.erase(c)
	for c in wilds:
		if _nodes.has(c):
			continue
		var kind := DataRegistry.wild(wilds[c])
		if kind == null or kind.model_scene == null:
			continue
		var n: Node3D = kind.model_scene.instantiate()
		ModelRig.apply(n, 0)
		n.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
		n.rotation.y = float(hash(c) % 628) / 100.0
		add_child(n)
		_nodes[c] = n
		n.scale = Vector3.ZERO
		n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func node_at(c: Vector2i) -> Node3D:
	return _nodes.get(c)


func _remove(n: Node3D) -> void:
	var t := n.create_tween()
	t.tween_property(n, "scale", Vector3(1.3, 0.2, 1.3), 0.15)
	t.tween_property(n, "scale", Vector3.ZERO, 0.12)
	t.tween_callback(n.queue_free)
