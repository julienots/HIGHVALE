class_name ResourceChip
extends PanelContainer
## Pastille de ressource du HUD : icône, quantité et jauge de remplissage.

signal pressed(resource_id: String)

var resource_id := ""
var _icon: TextureRect
var _label: Label
var _bar: ProgressBar
var _last := -1


func setup(rt: ResourceTypeData, with_bar := true) -> void:
	resource_id = rt.id
	theme_type_variation = "ChipPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = UiTheme.icon_rect(rt.icon, 40)
	row.add_child(_icon)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_label = UiTheme.label("0", "HudLabel", 24)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_label)
	if with_bar:
		_bar = ProgressBar.new()
		_bar.show_percentage = false
		_bar.custom_minimum_size = Vector2(96, 10)
		_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill := UiTheme.box(rt.color, Color(0, 0, 0, 0), 6, 0)
		fill.set_content_margin_all(0)
		_bar.add_theme_stylebox_override("fill", fill)
		var bg := UiTheme.box(Color(0, 0, 0, 0.6), Color(0, 0, 0, 0), 6, 0)
		bg.set_content_margin_all(0)
		_bar.add_theme_stylebox_override("background", bg)
		col.add_child(_bar)
	refresh()


func refresh() -> void:
	var w := GameState.wallet
	var amount := w.amount(resource_id)
	var cap := w.capacity(resource_id)
	_label.text = Fmt.amount(amount)
	if _bar:
		_bar.max_value = maxf(cap, 1)
		_bar.value = amount
		_label.add_theme_color_override("font_color", UiTheme.RED if cap > 0 and amount >= cap else UiTheme.TEXT)
	if _last >= 0 and amount > _last:
		_icon.pivot_offset = _icon.size / 2.0
		var t := create_tween()
		t.tween_property(_icon, "scale", Vector2(1.3, 1.3), 0.08)
		t.tween_property(_icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	_last = amount


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		pressed.emit(resource_id)
		accept_event()
