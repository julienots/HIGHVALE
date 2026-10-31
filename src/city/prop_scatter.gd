class_name PropScatter
extends Node3D
## Disperse des décors glTF (assets/models/props) en MultiMesh : une
## instance de rendu par pièce de décor, quel que soit le nombre de copies.

const DIR := "res://assets/models/props/"

static var _parts_cache := {}  # id -> Array[Dictionary{mesh, xform}]

var _instances := {}  # id -> Array[Transform3D]


func add(prop_id: String, pos: Vector3, scale_factor := 1.0, rot_y := 0.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3.ONE * scale_factor), pos)
	if not _instances.has(prop_id):
		_instances[prop_id] = []
	_instances[prop_id].append(xf)


func count() -> int:
	var n := 0
	for list in _instances.values():
		n += list.size()
	return n


const CHUNK := 16.0
## Décors massifs et lointains : pas d'ombre portée (gros gain sur mobile).
const NO_SHADOW_PREFIXES := ["cliff", "boulder", "tree"]


## Crée les MultiMeshInstance3D par zone de 16 × 16 : le moteur ignore les
## zones hors champ. À appeler une fois toutes les copies ajoutées.
func build() -> void:
	for id in _instances:
		var chunks := {}
		for xf: Transform3D in _instances[id]:
			var key := Vector2i(floori(xf.origin.x / CHUNK), floori(xf.origin.z / CHUNK))
			if not chunks.has(key):
				chunks[key] = []
			chunks[key].append(xf)
		var shadows := not NO_SHADOW_PREFIXES.any(func(p): return id.begins_with(p))
		for key in chunks:
			var list: Array = chunks[key]
			for part in _parts(id):
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = part.mesh
				mm.instance_count = list.size()
				for i in list.size():
					mm.set_instance_transform(i, list[i] * part.xform)
				var mmi := MultiMeshInstance3D.new()
				mmi.multimesh = mm
				if not shadows:
					mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var mat := ModelRig.surface_material(part.material)
				if mat != part.material:
					mmi.material_override = mat
				add_child(mmi)


static func _parts(id: String) -> Array:
	if _parts_cache.has(id):
		return _parts_cache[id]
	var out := []
	var scene: PackedScene = load(DIR + id + ".glb")
	if scene == null:
		push_error("PropScatter : décor introuvable " + id)
		return out
	var root := scene.instantiate()
	_collect(root, Transform3D.IDENTITY, out)
	root.free()
	_parts_cache[id] = out
	return out


static func _collect(n: Node, parent_xf: Transform3D, out: Array) -> void:
	for c in n.get_children():
		var xf := parent_xf
		if c is Node3D:
			xf = parent_xf * c.transform
		if c is MeshInstance3D and c.mesh:
			# Le maillage importé est gardé tel quel : il conserve ses niveaux de détail (LOD).
			var mat: Material = c.mesh.surface_get_material(0) if c.mesh.get_surface_count() > 0 else null
			out.append({"mesh": c.mesh, "xform": xf, "material": mat})
		_collect(c, xf, out)
