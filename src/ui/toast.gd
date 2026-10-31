class_name Toast
extends VBoxContainer
## Messages courts empilés en haut de l'écran.

const COLORS := {"info": Color("2b3760"), "success": Color("2e8c3e"), "error": Color("b42b3a"), "reward": Color("b5781a")}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 6)
	Events.toast_requested.connect(show_message)


func show_message(text: String, kind := "info") -> void:
	if kind == "error":
		AudioManager.sfx("error", 0.0, -6.0)
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiTheme.box(COLORS.get(kind, COLORS.info), UiTheme.INK, 14, 3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(text, "HudLabel", 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(p)
	if get_child_count() > 3:
		get_child(0).queue_free()
	p.modulate.a = 0.0
	var t := p.create_tween()
	t.tween_property(p, "modulate:a", 1.0, 0.15)
	t.tween_interval(2.2)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(p.queue_free)
