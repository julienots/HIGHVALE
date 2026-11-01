class_name UiFx
extends RefCounted
## Effets de l'interface : reflets lumineux qui balaient les boutons et les
## titres, fond animé des écrans (rayons et étincelles), halo pulsé des cartes
## rares et apparitions en cascade.

const SHINE_SHADER := """
shader_type canvas_item;
uniform float period = 4.5;
uniform float offset = 0.0;
uniform float width = 60.0;
uniform float strength = 0.35;
void fragment() {
	float t = mod(TIME + offset, period) / period;
	float x = FRAGCOORD.x + FRAGCOORD.y * 0.55;
	float pos = mix(-600.0, 3200.0, t);
	float band = exp(-pow((x - pos) / width, 2.0));
	COLOR.rgb += band * strength * COLOR.a;
}
"""

const BACKDROP_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.02, 0.02, 0.07, 0.8);
uniform vec4 glow : source_color = vec4(0.35, 0.5, 1.0, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	vec2 d = uv - vec2(0.5, -0.2);
	float ang = atan(d.y, d.x);
	float rays = pow(0.5 + 0.5 * sin(ang * 16.0 + TIME * 0.22), 8.0) * smoothstep(1.5, 0.15, length(d));
	float halo = smoothstep(0.9, 0.0, length((uv - vec2(0.5, 0.0)) * vec2(1.0, 1.6)));
	vec3 col = tint.rgb + glow.rgb * (rays * 0.09 + halo * 0.07);
	vec2 g = uv * vec2(48.0, 27.0);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	float tw = pow(0.5 + 0.5 * sin(TIME * (0.8 + h * 2.0) + h * 40.0), 16.0) * step(0.86, h);
	float sp = tw * smoothstep(0.14, 0.0, length(f));
	col += vec3(0.8, 0.88, 1.0) * sp * 0.7;
	COLOR = vec4(col, tint.a + sp * 0.15);
}
"""

static var _shine: Shader
static var _backdrop: Shader


static func shine_material(strength := 0.35, period := 4.5, width := 60.0) -> ShaderMaterial:
	if _shine == null:
		_shine = Shader.new()
		_shine.code = SHINE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shine
	m.set_shader_parameter("offset", randf() * period)
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("period", period)
	m.set_shader_parameter("width", width)
	return m


static func backdrop_material(glow := Color(0.35, 0.5, 1.0)) -> ShaderMaterial:
	if _backdrop == null:
		_backdrop = Shader.new()
		_backdrop.code = BACKDROP_SHADER
	var m := ShaderMaterial.new()
	m.shader = _backdrop
	m.set_shader_parameter("glow", glow)
	return m


## Reflet lumineux qui balaie le contrôle de temps en temps.
static func shine(c: CanvasItem, strength := 0.35, period := 4.5) -> void:
	c.material = shine_material(strength, period)


## Halo pulsé (ombre colorée) autour d'un panneau ; utile pour les raretés hautes.
static func glow(panel: Control, color: Color, size := 14) -> void:
	var sb: StyleBox = panel.get_theme_stylebox("panel")
	if not sb is StyleBoxFlat:
		return
	var s: StyleBoxFlat = sb.duplicate()
	s.shadow_color = Color(color, 0.55)
	s.shadow_size = size
	s.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", s)
	var t := panel.create_tween().set_loops()
	t.tween_property(s, "shadow_color", Color(color, 0.15), 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "shadow_color", Color(color, 0.6), 0.9).set_trans(Tween.TRANS_SINE)


## Effets selon la rareté : halo dès Épique, reflet en plus pour Légendaire et Divin.
static func rarity_fx(panel: Control, rarity: int) -> void:
	if rarity >= GameEnums.Rarity.EPIC:
		glow(panel, GameEnums.rarity_color(rarity), 10 + 4 * (rarity - GameEnums.Rarity.EPIC))
	if rarity >= GameEnums.Rarity.LEGENDARY:
		shine(panel, 0.28, 3.5)


## Apparition en cascade des enfants d'un conteneur (fondu et glissement).
static func cascade(container: Node, step := 0.035, max_items := 30) -> void:
	var i := 0
	for c in container.get_children():
		if not c is Control or i >= max_items:
			continue
		var ctrl: Control = c
		ctrl.modulate.a = 0.0
		var tw := ctrl.create_tween()
		tw.tween_interval(step * i)
		tw.tween_property(ctrl, "modulate:a", 1.0, 0.22)
		i += 1


## Premier conteneur « liste » (grille ou colonne de plusieurs éléments) sous un nœud.
static func find_list(n: Node, depth := 5) -> Node:
	if depth < 0:
		return null
	if (n is GridContainer or n is VBoxContainer or n is HFlowContainer) and n.get_child_count() >= 3:
		return n
	for c in n.get_children():
		var r := find_list(c, depth - 1)
		if r:
			return r
	return null
