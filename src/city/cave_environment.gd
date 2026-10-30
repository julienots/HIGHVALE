class_name CaveEnvironment
extends Node3D
## Décor de la grande caverne : sol, falaises, cristaux lumineux, champignons
## géants, ruines antiques, cascade et spores flottantes. Généré de façon
## déterministe pour que la cité ait toujours le même visage.

const K = preload("res://src/city/mesh_kit.gd")
const GROUND_SHADER := preload("res://assets/shaders/cave_ground.gdshader")
const WATER_SHADER := preload("res://assets/shaders/water.gdshader")
const WATERFALL_SHADER := preload("res://assets/shaders/waterfall.gdshader")

const ROCK := Color("4a4560")
const ROCK_L := Color("6a6585")
const CRYSTAL_SETS := [
	[Color("2fa8ff"), Color("7fdcff")],
	[Color("7a5cff"), Color("c2b4ff")],
	[Color("1ad6c0"), Color("9bfff0")],
]

var grid_size := Vector2i(40, 40)
var buildable := Rect2i(3, 3, 34, 34)
var _rng := RandomNumberGenerator.new()
var _sun: DirectionalLight3D


func build(p_grid: Vector2i, p_buildable: Rect2i) -> void:
	grid_size = p_grid
	buildable = p_buildable
	_rng.seed = 424242
	_environment()
	_ground()
	_cliffs()
	_waterfall(Vector3(13.0, 0, -0.6))
	_crystals()
	_mushrooms()
	_ruins()
	_spores()
	_merge_static()
	Events.settings_changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	_sun.shadow_enabled = Settings.shadows_enabled


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("070a16")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("4a5890")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color("0c1430")
	env.fog_density = 0.004
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Lumière principale : lueur froide tombant des cristaux du plafond.
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color("dfe6ff")
	_sun.light_energy = 0.85
	_sun.rotation_degrees = Vector3(-58, -25, 0)
	_sun.shadow_blur = 1.5
	_sun.directional_shadow_max_distance = 120.0
	add_child(_sun)
	# Lumière chaude d'appoint pour le relief.
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("ffb877")
	fill.light_energy = 0.25
	fill.rotation_degrees = Vector3(-30, 150, 0)
	add_child(fill)


func _ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	var m := ShaderMaterial.new()
	m.shader = GROUND_SHADER
	m.set_shader_parameter("buildable", Vector4(buildable.position.x, buildable.position.y, buildable.end.x, buildable.end.y))
	var mi := K.part(self, plane, m, Vector3(grid_size.x / 2.0, 0, grid_size.y / 2.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("no_merge", true)


## Falaises hautes à l'arrière (côtés x≈0 et z≈0), rochers bas à l'avant pour garder la vue.
func _cliffs() -> void:
	var mat := K.mat(ROCK, 0.95)
	var mat_l := K.mat(ROCK_L, 0.95)
	var n := grid_size.x
	for i in range(-12, n + 14, 2):
		var t := float(i)
		# Paroi du fond le long de z = 0
		_rock(Vector3(t + _rng.randf_range(-0.8, 0.8), 0, -2.5 - _rng.randf_range(0, 2.5)), _rng.randf_range(2.5, 4.5), _rng.randf_range(3.0, 7.0), mat if i % 4 else mat_l)
		# Paroi du fond le long de x = 0
		_rock(Vector3(-2.5 - _rng.randf_range(0, 2.5), 0, t + _rng.randf_range(-0.8, 0.8)), _rng.randf_range(2.5, 4.5), _rng.randf_range(3.0, 7.0), mat_l if i % 4 else mat)
		# Arrière-plan plus lointain
		_rock(Vector3(t, 0, -8 - _rng.randf_range(0, 3)), 5.0, _rng.randf_range(6.0, 11.0), mat)
		_rock(Vector3(-8 - _rng.randf_range(0, 3), 0, t), 5.0, _rng.randf_range(6.0, 11.0), mat)
	# Bordure avant basse
	for i in range(0, n + 2, 3):
		var t := float(i)
		_rock(Vector3(t + _rng.randf(), 0, n + 1.5 + _rng.randf_range(0, 2)), _rng.randf_range(1.0, 2.0), _rng.randf_range(0.6, 1.2), mat_l)
		_rock(Vector3(n + 1.5 + _rng.randf_range(0, 2), 0, t + _rng.randf()), _rng.randf_range(1.0, 2.0), _rng.randf_range(0.6, 1.2), mat)
	# Stalagmites
	for i in 26:
		var p := _border_point(1.0)
		var h := _rng.randf_range(1.0, 3.2)
		if p.x > n - 2 or p.z > n - 2:
			h *= 0.5
		K.part(self, K.cylinder(_rng.randf_range(0.3, 0.5), h, 0.03, 7), mat_l, p + Vector3(0, h / 2, 0), Vector3(_rng.randf_range(-6, 6), _rng.randf() * 360, _rng.randf_range(-6, 6)))


func _rock(pos: Vector3, size: float, height: float, mat: Material) -> void:
	K.part(self, K.rock(_rng.randi()), mat, pos, Vector3(0, _rng.randf() * 360, 0), Vector3(size, height, size))


## Point aléatoire dans la bande non constructible autour de la cité.
func _border_point(margin: float) -> Vector3:
	var b := Rect2(buildable)
	while true:
		var p := Vector2(_rng.randf_range(-1.0, grid_size.x + 1.0), _rng.randf_range(-1.0, grid_size.y + 1.0))
		if not b.grow(margin).has_point(p):
			return Vector3(p.x, 0, p.y)
	return Vector3.ZERO


func _waterfall(pos: Vector3) -> void:
	var fall := QuadMesh.new()
	fall.size = Vector2(3.2, 9.0)
	var fm := ShaderMaterial.new()
	fm.shader = WATERFALL_SHADER
	var f := K.part(self, fall, fm, pos + Vector3(0, 4.5, -1.2))
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.set_meta("no_merge", true)
	# Bassin
	var pool := PlaneMesh.new()
	pool.size = Vector2(6.5, 3.2)
	pool.subdivide_width = 16
	pool.subdivide_depth = 8
	var wm := ShaderMaterial.new()
	wm.shader = WATER_SHADER
	var w := K.part(self, pool, wm, pos + Vector3(0, 0.06, 0.9))
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.set_meta("no_merge", true)
	for i in 10:
		var a := PI * i / 9.0
		_rock(pos + Vector3(cos(a) * 3.4, 0, 0.9 + sin(a) * 1.7), _rng.randf_range(0.5, 0.8), _rng.randf_range(0.4, 0.7), K.mat(ROCK_L))
	var light := OmniLight3D.new()
	light.light_color = Color("6fd8ff")
	light.light_energy = 0.8
	light.omni_range = 7.0
	light.position = pos + Vector3(0, 1.5, 1.2)
	add_child(light)


func _crystals() -> void:
	var lights := 0
	for i in 18:
		var p := _border_point(0.6)
		var colors: Array = CRYSTAL_SETS[i % CRYSTAL_SETS.size()]
		var size := _rng.randf_range(0.7, 1.6)
		K.crystal_cluster(self, p, size, colors[0], colors[1], _rng, _rng.randi_range(3, 6))
		if lights < 6 and size > 1.0:
			lights += 1
			var l := OmniLight3D.new()
			l.light_color = colors[1]
			l.light_energy = 1.5
			l.omni_range = 6.5
			l.position = p + Vector3(0, 1.2, 0)
			add_child(l)
	# Grands cristaux dans les parois du fond
	for p in [Vector3(4, 0, -3.5), Vector3(-3.5, 0, 26), Vector3(30, 0, -4), Vector3(-4, 0, 9)]:
		K.crystal_cluster(self, p, 3.2, Color("2fa8ff"), Color("9be6ff"), _rng, 5)


func _mushrooms() -> void:
	var caps := [Color("3fd6c0"), Color("7a5cff"), Color("ff6ad5")]
	for i in 14:
		var p := _border_point(0.4)
		var s := _rng.randf_range(0.5, 1.6)
		var c: Color = caps[i % caps.size()]
		K.part(self, K.cylinder(0.12 * s, 1.1 * s, 0.08 * s, 8), K.mat(Color("e8e0cc")), p + Vector3(0, 0.55 * s, 0))
		var cap := K.part(self, K.sphere(0.5 * s, true, 12), K.mat(c, 0.6), p + Vector3(0, 1.05 * s, 0))
		cap.scale = Vector3(1, 0.65, 1)
		K.part(self, K.sphere(0.46 * s, true, 12), K.glow_mat(c.lightened(0.25), 1.6), p + Vector3(0, 1.04 * s, 0), Vector3(180, 0, 0), Vector3(1, 0.2, 1))


func _ruins() -> void:
	var stone := K.mat(Color("8a8496"))
	for p in [Vector3(38.5, 0, 6), Vector3(1.6, 0, 37), Vector3(38.6, 0, 30), Vector3(20, 0, 38.8), Vector3(1.4, 0, 18)]:
		var h := _rng.randf_range(1.0, 2.6)
		K.part(self, K.cylinder(0.32, h, 0.3, 10), stone, p + Vector3(0, h / 2, 0), Vector3(_rng.randf_range(-8, 8), 0, _rng.randf_range(-8, 8)))
		K.part(self, K.box(Vector3(0.8, 0.2, 0.8)), stone, p + Vector3(0, 0.1, 0))
		K.part(self, K.cylinder(0.3, 0.8, -1, 10), stone, p + Vector3(0.8, 0.3, 0.4), Vector3(0, 30, 90))


## Fusionne les décors statiques par matériau : quelques appels de rendu au lieu
## de plusieurs centaines, indispensable sur téléphone.
func _merge_static() -> void:
	var groups := {}  # Material -> SurfaceTool
	var to_free: Array[Node] = []
	var inv := global_transform.affine_inverse()
	for mi in _static_meshes(self):
		var key: Material = mi.material_override
		if not groups.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = st
		groups[key].append_from(mi.mesh, 0, inv * mi.global_transform)
		to_free.append(mi)
	for n in to_free:
		var parent := n.get_parent()
		parent.remove_child(n)
		n.free()
		if parent != self and parent.get_child_count() == 0:
			parent.queue_free()
	for key in groups:
		var merged := MeshInstance3D.new()
		merged.mesh = groups[key].commit()
		merged.material_override = key
		add_child(merged)


func _static_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in n.get_children():
		if c is MeshInstance3D and not c.has_meta("no_merge"):
			out.append(c)
		elif c is Node3D and not (c is GPUParticles3D or c is Light3D or c is WorldEnvironment):
			out.append_array(_static_meshes(c))
	return out


func _spores() -> void:
	var p := GPUParticles3D.new()
	p.amount = 140
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.visibility_aabb = AABB(Vector3(-25, -2, -25), Vector3(50, 14, 50))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(grid_size.x * 0.6, 3.0, grid_size.y * 0.6)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.02, 0)
	pm.turbulence_enabled = false
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.2, 1))
	curve.add_point(Vector2(0.8, 1))
	curve.add_point(Vector2(1, 0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color("aef4ff")
	qm.emission_enabled = true
	qm.emission = Color("aef4ff")
	qm.emission_energy_multiplier = 3.0
	quad.material = qm
	p.draw_pass_1 = quad
	p.position = Vector3(grid_size.x / 2.0, 2.0, grid_size.y / 2.0)
	add_child(p)
