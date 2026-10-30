class_name MeshKit
extends RefCounted
## Boîte à outils de modélisation procédurale : primitives, matériaux mis en cache
## et rochers « low poly ». Sert aux décors et aux modèles provisoires des bâtiments
## (remplaçables par des modèles glTF via BuildingData.model_scene).

const CRYSTAL_SHADER := preload("res://assets/shaders/crystal.gdshader")

static var _materials := {}
static var _meshes := {}
static var _rocks: Array[ArrayMesh] = []


# --- Matériaux --------------------------------------------------------------

static func mat(color: Color, roughness := 0.85, metallic := 0.0) -> StandardMaterial3D:
	var key := "m%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		m.metallic = metallic
		m.rim_enabled = true
		m.rim = 0.1
		m.rim_tint = 0.6
		_materials[key] = m
	return _materials[key]


static func glow_mat(color: Color, energy := 2.0) -> StandardMaterial3D:
	var key := "g%s_%.2f" % [color.to_html(), energy]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
		_materials[key] = m
	return _materials[key]


static func glass_mat(color: Color) -> StandardMaterial3D:
	var key := "t%s" % color.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.metallic_specular = 0.9
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b) * 0.4
		_materials[key] = m
	return _materials[key]


static func crystal_mat(base: Color, glow: Color, strength := 1.6) -> ShaderMaterial:
	var key := "c%s_%s_%.2f" % [base.to_html(), glow.to_html(), strength]
	if not _materials.has(key):
		var m := ShaderMaterial.new()
		m.shader = CRYSTAL_SHADER
		m.set_shader_parameter("base_color", base)
		m.set_shader_parameter("glow_color", glow)
		m.set_shader_parameter("glow_strength", strength)
		_materials[key] = m
	return _materials[key]


# --- Maillages --------------------------------------------------------------

static func box(size: Vector3) -> BoxMesh:
	var key := "box%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _meshes[key]


static func cylinder(radius: float, height: float, top_radius := -1.0, segments := 12) -> CylinderMesh:
	var tr := radius if top_radius < 0.0 else top_radius
	var key := "cyl%.3f_%.3f_%.3f_%d" % [radius, height, tr, segments]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.bottom_radius = radius
		m.top_radius = tr
		m.height = height
		m.radial_segments = segments
		m.rings = 1
		_meshes[key] = m
	return _meshes[key]


static func sphere(radius: float, hemisphere := false, segments := 16) -> SphereMesh:
	var key := "sph%.3f_%s_%d" % [radius, hemisphere, segments]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius if hemisphere else radius * 2.0
		m.is_hemisphere = hemisphere
		m.radial_segments = segments
		m.rings = maxi(segments / 2, 4)
		_meshes[key] = m
	return _meshes[key]


static func prism(size: Vector3) -> PrismMesh:
	var key := "pri%s" % size
	if not _meshes.has(key):
		var m := PrismMesh.new()
		m.size = size
		_meshes[key] = m
	return _meshes[key]


static func torus(inner: float, outer: float) -> TorusMesh:
	var key := "tor%.3f_%.3f" % [inner, outer]
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 24
		m.ring_segments = 8
		_meshes[key] = m
	return _meshes[key]


## Rocher à facettes (octaèdre subdivisé et déformé, normales plates).
static func rock(variant: int) -> ArrayMesh:
	if _rocks.is_empty():
		for i in 8:
			_rocks.append(_make_rock(1000 + i * 17))
	return _rocks[variant % _rocks.size()]


static func _make_rock(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var v := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var faces := [[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2], [1, 4, 2], [1, 3, 4], [1, 5, 3], [1, 2, 5]]
	# Une subdivision : chaque triangle devient quatre.
	var tris: Array = []
	var mid_cache := {}
	for f in faces:
		var ids := []
		for k in 3:
			var a: int = f[k]
			var b: int = f[(k + 1) % 3]
			var key := "%d_%d" % [mini(a, b), maxi(a, b)]
			if not mid_cache.has(key):
				v.append(((v[a] + v[b]) * 0.5).normalized())
				mid_cache[key] = v.size() - 1
			ids.append(mid_cache[key])
		tris.append([f[0], ids[0], ids[2]])
		tris.append([f[1], ids[1], ids[0]])
		tris.append([f[2], ids[2], ids[1]])
		tris.append([ids[0], ids[1], ids[2]])
	for i in v.size():
		var p: Vector3 = v[i]
		p *= rng.randf_range(0.78, 1.15)
		p.y = p.y * 0.75 if p.y > 0.0 else p.y * 0.3
		v[i] = p
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		# Ordre inversé : faces orientées vers l'extérieur pour Godot.
		st.add_vertex(v[t[0]])
		st.add_vertex(v[t[2]])
		st.add_vertex(v[t[1]])
	st.generate_normals()
	return st.commit()


# --- Assemblage -------------------------------------------------------------

static func part(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


## Groupe de cristaux hexagonaux inclinés.
static func crystal_cluster(parent: Node3D, pos: Vector3, size: float, base: Color, glow: Color, rng: RandomNumberGenerator, count := 4) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var m := crystal_mat(base, glow)
	for i in count:
		var h := size * rng.randf_range(0.6, 1.3) * (1.4 if i == 0 else 1.0)
		var r := size * rng.randf_range(0.14, 0.22)
		var c := Node3D.new()
		c.position = Vector3(rng.randf_range(-0.3, 0.3) * size, 0, rng.randf_range(-0.3, 0.3) * size) if i > 0 else Vector3.ZERO
		c.rotation_degrees = Vector3(rng.randf_range(-28, 28), rng.randf_range(0, 360), rng.randf_range(-28, 28)) if i > 0 else Vector3(0, rng.randf_range(0, 60), 0)
		root.add_child(c)
		part(c, cylinder(r, h * 0.75, r, 6), m, Vector3(0, h * 0.375, 0))
		part(c, cylinder(r, h * 0.25, 0.0, 6), m, Vector3(0, h * 0.75 + h * 0.125, 0))
	return root
