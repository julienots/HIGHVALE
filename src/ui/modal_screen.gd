class_name ModalScreen
extends Control
## Base des écrans plein écran (Laboratoire, Fusionnerie, Invocations) :
## fond assombri, panneau, titre et bouton de fermeture.

var body: VBoxContainer
var header: HBoxContainer
var title_label: Label


func _build_shell(title: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	col.add_child(header)
	title_label = UiTheme.label(title, "TitleLabel", 38)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close := UiTheme.button("", "DangerButton", preload("res://assets/icons/ui/cross.svg"))
	close.custom_minimum_size = Vector2(64, 64)
	close.pressed.connect(close_screen)
	header.add_child(close)
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	col.add_child(body)


func open_screen() -> void:
	visible = true
	refresh()
	UiSfx.pop_in(get_child(1), 0.2)


func close_screen() -> void:
	visible = false


func refresh() -> void:
	pass


static func clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()


static func item_tile(icon: Texture2D, label: String, rarity: int, size := 92) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiTheme.box(GameEnums.rarity_color(rarity).darkened(0.6), GameEnums.rarity_color(rarity), 12, 3, 3)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size, size + 18)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var ic := UiTheme.icon_rect(icon, size - 24)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := UiTheme.label(label, "HudLabel", 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return p


static func on_tap(c: Control, cb: Callable) -> void:
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				c.set_meta("press", e.global_position)
			elif e.global_position.distance_to(c.get_meta("press", e.global_position)) < 14.0:
				UiSfx.click(c)
				cb.call())
