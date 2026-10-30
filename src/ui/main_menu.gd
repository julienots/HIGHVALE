extends Node3D
## Menu principal : la cité du joueur tourne lentement derrière le logo.

const GAME_LOGO := preload("res://assets/branding/highvale_logo.png")
const STUDIO_LOGO := preload("res://assets/branding/super_essence_logo.jpg")

var _pivot: Node3D
var _logo: TextureRect
var _time := 0.0
var _ui: Control


func _ready() -> void:
	var cfg := GameState.config()
	var env := CaveEnvironment.new()
	add_child(env)
	env.build(cfg.grid_size, cfg.buildable_rect)
	for b in GameState.city.buildings.values():
		var n := BuildingNode.new()
		add_child(n)
		n.setup(b)
	_pivot = Node3D.new()
	_pivot.position = Vector3(cfg.grid_size.x / 2.0, 0, cfg.grid_size.y / 2.0)
	add_child(_pivot)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.position = Vector3(0, 13, 24)
	_pivot.add_child(cam)
	cam.look_at(_pivot.global_position + Vector3(0, 1.5, 0))
	cam.make_current()
	_build_ui()


func _process(delta: float) -> void:
	_time += delta
	_pivot.rotation_degrees.y += delta * 4.0
	if _logo:
		_logo.position.y = sin(_time * 1.4) * 6.0


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.theme = UiTheme.get_theme()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0.02, 0.03, 0.08, 0.15))
	grad.gradient.set_color(1, Color(0.02, 0.03, 0.08, 0.85))
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	shade.texture = grad
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	_ui.add_child(col)
	var logo_holder := Control.new()
	logo_holder.custom_minimum_size = Vector2(0, 300)
	col.add_child(logo_holder)
	_logo = TextureRect.new()
	_logo.texture = GAME_LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_holder.add_child(_logo)
	var play := UiTheme.button("Jouer", "PrimaryButton", null, 40)
	play.custom_minimum_size = Vector2(340, 92)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func(): SceneRouter.go_to(SceneRouter.CITY))
	col.add_child(play)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var settings := UiTheme.button("Paramètres", "SecondaryButton", preload("res://assets/icons/ui/settings.svg"), 24)
	settings.custom_minimum_size = Vector2(0, 64)
	settings.pressed.connect(func(): SettingsPanel.open(_ui, false))
	row.add_child(settings)
	var credits := UiTheme.button("Crédits", "SecondaryButton", preload("res://assets/icons/ui/info.svg"), 24)
	credits.custom_minimum_size = Vector2(0, 64)
	credits.pressed.connect(_show_credits)
	row.add_child(credits)
	var studio := TextureRect.new()
	studio.texture = STUDIO_LOGO
	studio.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	studio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	studio.custom_minimum_size = Vector2(220, 56)
	studio.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	studio.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	studio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(studio)
	var version := UiTheme.label("v%s" % ProjectSettings.get_setting("application/config/version"), "DimLabel", 16)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 14)
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(version)
	UiSfx.pop_in.call_deferred(play, 0.4)


func _show_credits() -> void:
	DialogBox.open(_ui, "Crédits",
		"[center][b]HIGHVALE[/b]\nUn jeu de [b]Super Essence Studio[/b]\n\n" +
		"Moteur : Godot Engine (licence MIT)\n" +
		"Polices : Lilita One (Juan Montoreano) et Fredoka (Milena Brandão), licence SIL Open Font\n" +
		"Icônes, modèles procéduraux et shaders : créés pour HIGHVALE[/center]", [], 700)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		for c in _ui.get_children():
			if c is DialogBox:
				c.close()
				return
		GameState.save()
		get_tree().quit()
