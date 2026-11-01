class_name WallLinks
extends RefCounted
## Jonctions des remparts : chaque pilier n'affiche ses raccords (linkpx,
## linknx, linkpy, linkny du modèle Blender) que vers un rempart voisin.
## Axes : +x Blender = +x grille ; +y Blender = −y grille (−z Godot).

const DIRS := {"linkpx": Vector2i(1, 0), "linknx": Vector2i(-1, 0), "linkpy": Vector2i(0, -1), "linkny": Vector2i(0, 1)}


## has_wall : Callable(offset: Vector2i) -> bool
static func apply(root: Node, has_wall: Callable) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var prefix := String(n.name).split("_")[0]
		if DIRS.has(prefix) and n is Node3D:
			(n as Node3D).visible = has_wall.call(DIRS[prefix])
		stack.append_array(n.get_children())
