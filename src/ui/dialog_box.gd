class_name DialogBox
extends Control
## Fenêtre modale générique : titre, contenu libre et rangée de boutons.

signal closed

var content: VBoxContainer
var buttons: HBoxContainer
var _panel: PanelContainer


## Crée et affiche une fenêtre. Chaque bouton : { text, variation, icon, action: Callable, disabled }.
static func open(parent: Node, title: String, body: Variant = null, button_defs: Array = [], width := 640.0) -> DialogBox:
	var d := DialogBox.new()
	parent.add_child(d)
	d._build(title, width)
	if body is String:
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.text = body
		rt.add_theme_font_size_override("normal_font_size", 22)
		rt.add_theme_font_size_override("bold_font_size", 22)
		rt.add_theme_font_override("bold_font", UiTheme.TITLE_FONT)
		d.content.add_child(rt)
	elif body is Control:
		d.content.add_child(body)
	for def in button_defs:
		d.add_button(def.get("text", "OK"), def.get("variation", "Button"), def.get("action", Callable()), def.get("icon", null), def.get("disabled", false))
	if button_defs.is_empty():
		d.add_button("OK", "PrimaryButton")
	UiSfx.pop_in.call_deferred(d._panel)
	return d


func add_button(text: String, variation := "Button", action := Callable(), icon: Texture2D = null, disabled := false) -> Button:
	var b := UiTheme.button(text, variation, icon)
	b.disabled = disabled
	b.custom_minimum_size = Vector2(160, 64)
	b.pressed.connect(func():
		close()
		if action.is_valid():
			action.call())
	buttons.add_child(b)
	return b


func close() -> void:
	closed.emit()
	queue_free()


func _build(title: String, width: float) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.6)
	dim.material = UiFx.backdrop_material(Color(1.0, 0.8, 0.4))
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_panel.add_child(col)
	var t := UiTheme.label(title, "TitleLabel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFx.shine(t, 0.5, 4.0)
	col.add_child(t)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	col.add_child(content)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	col.add_child(buttons)
