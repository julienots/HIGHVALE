class_name ModelRig
extends RefCounted
## Prépare un modèle glTF importé (voir tools/blender/hv_kit.py) :
##  - jeton « tN » : visible seulement à partir du palier N ;
##  - « spinY35 » / « bob8 » : métadonnées d'animation lues par BuildingNode ;
##  - « light_RRGGBB_eE_rR » : repère remplacé par une OmniLight3D ;
##  - matériaux : couleur de sommet activée, cristaux remplacés par le shader pulsé.

static var _prepared_materials := {}
static var _crystal_materials := {}


static func apply(root: Node3D, tier: int) -> void:
	for n in _all_children(root):
		if not n is Node3D:
			continue
		var tokens := String(n.name).to_lower().split("_")
		var node_tier := _tier_of(tokens)
		if tokens[0] == "light":
			_make_light(n, tokens, node_tier <= tier)
			continue
		if node_tier > tier:
			n.visible = false
			continue
		for t in tokens:
			if t.begins_with("spin") and t.length() > 5:
				var axis := t.substr(4, 1)
				var speed := float(t.substr(5))
				n.set_meta("spin", Vector3(speed if axis == "x" else 0.0, speed if axis == "y" else 0.0, speed if axis == "z" else 0.0))
			elif t.begins_with("bob") and t.substr(3).is_valid_int():
				n.set_meta("bob", float(t.substr(3)) / 100.0)
		if n is MeshInstance3D:
			_prepare_materials(n)


static func _tier_of(tokens: PackedStringArray) -> int:
	for t in tokens:
		if t.length() == 2 and t[0] == "t" and t[1].is_valid_int():
			return int(t[1])
	return 0


static func _make_light(marker: Node3D, tokens: PackedStringArray, enabled: bool) -> void:
	if not enabled or tokens.size() < 4:
		marker.visible = false
		return
	var l := OmniLight3D.new()
	l.light_color = Color.html(tokens[1])
	l.light_energy = float(tokens[2].substr(1)) / 10.0
	l.omni_range = float(tokens[3].substr(1)) / 10.0
	l.shadow_enabled = false
	marker.add_child(l)


static func _prepare_materials(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		var m := mesh.surface_get_material(i)
		var prepared := surface_material(m)
		if prepared != m:
			mi.set_surface_override_material(i, prepared)


## Matériau prêt pour le rendu HIGHVALE : couleurs de sommets, métal adouci,
## ou shader pulsé pour les cristaux (retourne alors un autre matériau).
static func surface_material(m: Material) -> Material:
	if not m is StandardMaterial3D:
		return m
	if m.resource_name.to_lower().begins_with("crystal"):
		return _crystal(m)
	if not _prepared_materials.has(m.get_instance_id()):
		_prepared_materials[m.get_instance_id()] = true
		_prepare_standard(m)
	return m


static func _prepare_standard(m: StandardMaterial3D) -> void:
	m.vertex_color_use_as_albedo = true
	# Caverne sans ciel : un métal pur ne refléterait que le noir.
	if m.metallic > 0.4:
		m.metallic = 0.4
		m.roughness = maxf(m.roughness, 0.35)
		m.albedo_color = m.albedo_color.lightened(0.12)
	m.rim_enabled = true
	m.rim = 0.08
	m.rim_tint = 0.7


static func _crystal(src: StandardMaterial3D) -> Material:
	var key := src.get_instance_id()
	if not _crystal_materials.has(key):
		var glow := src.emission if src.emission_enabled else src.albedo_color
		_crystal_materials[key] = MeshKit.crystal_mat(src.albedo_color, glow.lightened(0.15), 1.7)
	return _crystal_materials[key]


static func _all_children(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in n.get_children():
		out.append(c)
		out.append_array(_all_children(c))
	return out
