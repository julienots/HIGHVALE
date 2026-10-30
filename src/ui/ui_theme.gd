class_name UiTheme
extends RefCounted
## Thème visuel de HIGHVALE construit par code : panneaux sombres bordés d'or,
## boutons « cartoon » épais avec relief, typographie Lilita One / Fredoka.

const TITLE_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/Fredoka.ttf")

const INK := Color("1b1430")
const PANEL := Color("1d2540")
const PANEL_LIGHT := Color("2b3760")
const GOLD := Color("ffc531")
const GOLD_DARK := Color("c47f12")
const BLUE := Color("3d9bff")
const BLUE_DARK := Color("1d5fb8")
const GREEN := Color("5bd36b")
const GREEN_DARK := Color("2e8c3e")
const RED := Color("ff5a5a")
const RED_DARK := Color("b42b3a")
const PINK := Color("ff4fb6")
const PINK_DARK := Color("b51f7c")
const TEXT := Color("fff8e6")
const TEXT_DIM := Color("aab4cc")

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func box(bg: Color, border: Color, radius := 18, border_w := 4, bottom := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.border_width_bottom = border_w + bottom
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(12)
	s.anti_aliasing = true
	return s


static func _button_variant(t: Theme, name: String, face: Color, font_size := 26) -> void:
	if name != "Button":
		t.add_type(name)
		t.set_type_variation(name, "Button")
	var normal := box(face, INK, 16, 4, 6)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.shadow_color = Color(0, 0, 0, 0.35)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 3)
	var hover := normal.duplicate()
	hover.bg_color = face.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = face.darkened(0.12)
	pressed.border_width_bottom = 4
	pressed.content_margin_top = normal.content_margin_top + 4
	var disabled := normal.duplicate()
	disabled.bg_color = Color("59607a")
	t.set_stylebox("normal", name, normal)
	t.set_stylebox("hover", name, hover)
	t.set_stylebox("pressed", name, pressed)
	t.set_stylebox("disabled", name, disabled)
	t.set_stylebox("focus", name, StyleBoxEmpty.new())
	t.set_font("font", name, TITLE_FONT)
	t.set_font_size("font_size", name, font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, name, TEXT)
	t.set_color("font_disabled_color", name, Color("c8cddc"))
	t.set_color("font_outline_color", name, INK)
	t.set_constant("outline_size", name, 8)
	t.set_constant("h_separation", name, 10)
	t.set_color("icon_normal_color", name, Color.WHITE)
	t.set_color("icon_disabled_color", name, Color(1, 1, 1, 0.5))


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = BODY_FONT
	t.default_font_size = 22

	# Panneaux
	var panel := box(PANEL, GOLD, 22, 5)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 10
	panel.set_content_margin_all(18)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.add_type("CardPanel")
	t.set_type_variation("CardPanel", "PanelContainer")
	var card := box(PANEL_LIGHT, INK, 16, 4, 4)
	card.set_content_margin_all(10)
	t.set_stylebox("panel", "CardPanel", card)
	t.add_type("ChipPanel")
	t.set_type_variation("ChipPanel", "PanelContainer")
	var chip := box(Color(0.06, 0.07, 0.14, 0.82), INK, 14, 3)
	chip.content_margin_left = 8
	chip.content_margin_right = 14
	chip.content_margin_top = 4
	chip.content_margin_bottom = 4
	t.set_stylebox("panel", "ChipPanel", chip)

	# Textes
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 0)
	t.add_type("TitleLabel")
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", TITLE_FONT)
	t.set_font_size("font_size", "TitleLabel", 38)
	t.set_color("font_color", "TitleLabel", GOLD)
	t.set_constant("outline_size", "TitleLabel", 10)
	t.add_type("HeaderLabel")
	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", TITLE_FONT)
	t.set_font_size("font_size", "HeaderLabel", 26)
	t.set_constant("outline_size", "HeaderLabel", 7)
	t.add_type("DimLabel")
	t.set_type_variation("DimLabel", "Label")
	t.set_color("font_color", "DimLabel", TEXT_DIM)
	t.set_font_size("font_size", "DimLabel", 18)
	t.add_type("HudLabel")
	t.set_type_variation("HudLabel", "Label")
	t.set_font("font", "HudLabel", TITLE_FONT)
	t.set_font_size("font_size", "HudLabel", 24)
	t.set_constant("outline_size", "HudLabel", 7)
	t.set_color("font_color", "RichTextLabel", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)

	# Boutons
	_button_variant(t, "Button", BLUE)
	_button_variant(t, "PrimaryButton", Color("f2a516"))
	_button_variant(t, "SecondaryButton", BLUE)
	_button_variant(t, "SuccessButton", GREEN)
	_button_variant(t, "DangerButton", RED)
	_button_variant(t, "PremiumButton", PINK)
	_button_variant(t, "TabButton", Color("3a4670"), 22)
	var tab_on := box(GOLD, INK, 16, 4, 6)
	tab_on.content_margin_left = 22
	tab_on.content_margin_right = 22
	t.set_stylebox("pressed", "TabButton", tab_on)
	t.set_stylebox("hover_pressed", "TabButton", tab_on)
	_button_variant(t, "RoundButton", Color("2b3760"), 20)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var s: StyleBoxFlat = t.get_stylebox(st, "RoundButton").duplicate()
		s.set_corner_radius_all(40)
		s.set_content_margin_all(10)
		t.set_stylebox(st, "RoundButton", s)

	# Barres de progression
	t.set_stylebox("background", "ProgressBar", box(Color(0.05, 0.05, 0.1, 0.9), INK, 8, 3))
	var fill := box(GREEN, INK, 8, 0)
	fill.set_content_margin_all(0)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_font_size("font_size", "ProgressBar", 14)
	t.set_color("font_color", "ProgressBar", TEXT)

	# Curseurs et cases
	t.set_font_size("font_size", "CheckButton", 22)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_font_size("font_size", "OptionButton", 22)
	t.set_stylebox("panel", "PopupMenu", box(PANEL, GOLD, 12, 3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.08)
	sb.set_corner_radius_all(6)
	t.set_stylebox("scroll", "VScrollBar", sb)
	var grab := sb.duplicate()
	grab.bg_color = GOLD
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return t


## Bouton avec icône optionnelle et variation de thème.
static func button(text: String, variation := "Button", icon: Texture2D = null, font_size := -1) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	if icon:
		b.icon = icon
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
	if font_size > 0:
		b.add_theme_font_size_override("font_size", font_size)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): UiSfx.click(b))
	return b


static func label(text: String, variation := "", size := -1, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0:
		l.add_theme_color_override("font_color", color)
	return l


static func icon_rect(tex: Texture2D, size := 32) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Ligne « icône + quantité » pour afficher un coût. Rouge si non payable.
static func cost_row(cost: Dictionary, wallet: Wallet, size := 22) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in cost:
		var rt := DataRegistry.resource_type(id)
		if rt == null:
			continue
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 3)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon_rect(rt.icon, size + 6))
		var ok: bool = wallet == null or wallet.amount(id) >= cost[id]
		var l := label(Fmt.amount(cost[id]), "HudLabel", size, TEXT if ok else RED)
		cell.add_child(l)
		row.add_child(cell)
	return row
