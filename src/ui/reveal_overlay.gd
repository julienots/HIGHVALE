class_name RevealOverlay
extends Control
## Révélation spectaculaire d'une créature ou d'un héros : charge lumineuse,
## rayons, éclair puis présentation 3D. L'intensité grandit avec la rareté.

signal finished

var _rarity := 0
var _color := Color.WHITE
var _t := 0.0
var _phase := 0  # 0 charge, 1 révélé
var _charge_time := 1.6
var _viewer: CharacterViewer
var _info: VBoxContainer
var _flash: ColorRect
var _sparks: CPUParticles2D
var _secondary := Color.WHITE


## title : « Nouvelle espèce ! »… ; lines : textes sous le nom.
static func play(parent: Control, scene: PackedScene, rarity: int, title: String, name_text: String, lines: Array, secondary := Color(0, 0, 0, 0)) -> RevealOverlay:
	var r := RevealOverlay.new()
	parent.add_child(r)
	r._setup(scene, rarity, title, name_text, lines, secondary)
	return r


func _setup(scene: PackedScene, rarity: int, title: String, name_text: String, lines: Array, secondary: Color) -> void:
	_rarity = rarity
	_color = GameEnums.rarity_color(rarity)
	_secondary = secondary if secondary.a > 0.0 else _color.lightened(0.4)
	_charge_time = 1.4 + rarity * 0.45
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer = CharacterViewer.new()
	_viewer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_viewer.custom_minimum_size = Vector2(420, 420)
	_viewer.position = Vector2(-210, -260)
	_viewer.modulate.a = 0.0
	_viewer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewer)
	_viewer.show_character(scene, _color)
	_info = VBoxContainer.new()
	_info.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_info.position.y -= 190
	_info.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_info.alignment = BoxContainer.ALIGNMENT_CENTER
	_info.modulate.a = 0.0
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_info)
	for t in [[title, "TitleLabel", 30, UiTheme.GOLD], [name_text, "TitleLabel", 44, _color.lightened(0.35)],
			[GameEnums.rarity_name(rarity), "HudLabel", 24, _color.lightened(0.2)]]:
		var l := UiTheme.label(t[0], t[1], t[2], t[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_info.add_child(l)
	for line in lines:
		var l := UiTheme.label(str(line), "HudLabel", 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_info.add_child(l)
	var hint := UiTheme.label("Touchez pour continuer", "DimLabel", 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_child(hint)
	_sparks = CPUParticles2D.new()
	_sparks.amount = 30 + rarity * 30
	_sparks.lifetime = 1.6
	_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 30.0
	_sparks.direction = Vector2.UP
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 80.0
	_sparks.initial_velocity_max = 260.0 + rarity * 80.0
	_sparks.gravity = Vector2(0, 60)
	_sparks.scale_amount_min = 3.0
	_sparks.scale_amount_max = 7.0
	_sparks.color = _secondary
	_sparks.emitting = false
	add_child(_sparks)
	AudioManager.sfx("charge", 0.0)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _process(delta: float) -> void:
	_t += delta
	_sparks.position = size / 2.0 + Vector2(0, -60)
	if _phase == 0 and _t >= _charge_time:
		_reveal()
	queue_redraw()


func _reveal() -> void:
	_phase = 1
	AudioManager.sfx("reveal", 0.0)
	AudioManager.reveal(_rarity)
	_sparks.emitting = true
	var t := create_tween().set_parallel()
	_flash.color.a = 0.9 if _rarity >= GameEnums.Rarity.EPIC else 0.6
	t.tween_property(_flash, "color:a", 0.0, 0.6)
	_viewer.scale = Vector2(0.4, 0.4)
	_viewer.pivot_offset = _viewer.custom_minimum_size / 2.0
	t.tween_property(_viewer, "modulate:a", 1.0, 0.25)
	t.tween_property(_viewer, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_info, "modulate:a", 1.0, 0.4).set_delay(0.35)


func _draw() -> void:
	var c := size / 2.0 + Vector2(0, -60)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.06, 0.97))
	var k := clampf(_t / _charge_time, 0.0, 1.0) if _phase == 0 else 1.0
	# Rayons tournants, plus nombreux et plus rapides pour les raretés élevées.
	var rays := 8 + _rarity * 6
	var spin := _t * (0.4 + _rarity * 0.25)
	var reach := maxf(size.x, size.y) * (0.25 + 0.75 * k)
	for i in rays:
		var a := spin + TAU * i / rays
		var w := 0.06 + 0.03 * sin(_t * 3.0 + i)
		var col := (_color if i % 2 == 0 else _secondary)
		col.a = (0.10 + 0.12 * k) * (1.0 + _rarity * 0.15)
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - w) * reach, c + Vector2.from_angle(a + w) * reach]), col)
	# Orbe de charge
	var pulse := 1.0 + 0.15 * sin(_t * (6.0 + _rarity * 3.0))
	var r := (40.0 + 140.0 * k) * pulse if _phase == 0 else 210.0
	for j in 5:
		var gc := _color.lightened(0.2 * j)
		gc.a = 0.08 + 0.05 * j
		draw_circle(c, r * (1.0 - j * 0.16), gc)
	if _phase == 0:
		draw_circle(c, 18.0 + 30.0 * k, Color(1, 1, 1, 0.8))
		if _rarity >= GameEnums.Rarity.EPIC:
			for i in 3:
				var a := randf() * TAU
				var p := c
				var pts := PackedVector2Array([p])
				for s in 6:
					p += Vector2.from_angle(a + randf_range(-0.6, 0.6)) * (25.0 + 20.0 * k)
					pts.append(p)
				draw_polyline(pts, _secondary.lightened(0.4), 2.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _phase == 0:
			_t = _charge_time
		elif _t > _charge_time + 0.5:
			finished.emit()
			queue_free()
