class_name Fx
extends RefCounted
## Effets de particules ponctuels (étincelles, poussière, éclats lumineux).


## Gerbe de particules qui se détruit d'elle-même.
static func burst(parent: Node, pos: Vector3, color: Color, amount := 24, speed := 2.5, size := 0.06, up := 1.0, lifetime := 0.9) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = int(amount * Settings.particle_factor())
	if p.amount < 2:
		return
	p.lifetime = lifetime
	p.direction = Vector3(0, up, 0)
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -3.0, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = m
	p.mesh = quad
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


## Poussière de chantier.
static func dust(parent: Node, pos: Vector3, radius := 1.2) -> void:
	for i in 4:
		var a := TAU * i / 4.0
		burst(parent, pos + Vector3(cos(a), 0.1, sin(a)) * radius, Color("c8b090"), 10, 1.2, 0.14, 0.4, 0.8)
