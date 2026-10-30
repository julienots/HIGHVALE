extends Control
## Écran de démarrage : logo Super Essence Studio, puis logo HIGHVALE et chargement.

const STUDIO_LOGO := preload("res://assets/branding/super_essence_logo.jpg")
const GAME_LOGO := preload("res://assets/branding/highvale_logo.png")

var _skip := false


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_run()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip = true


func _run() -> void:
	var studio := _centered_logo(STUDIO_LOGO, 0.62)
	await _fade(studio, 1.0, 0.5)
	await _wait(1.2)
	await _fade(studio, 0.0, 0.35)
	studio.queue_free()

	var bg := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color("1a2a5a"))
	grad.gradient.set_color(1, Color("05060f"))
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.45)
	grad.fill_to = Vector2(1.1, 1.1)
	bg.texture = grad
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.modulate.a = 0.0
	add_child(bg)
	var logo := _centered_logo(GAME_LOGO, 0.55, -40)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(420, 22)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.modulate.a = 0.0
	var fill := UiTheme.box(UiTheme.GOLD, UiTheme.INK, 8, 0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	var tip := UiTheme.label("Éveil du Temple Primordial…", "DimLabel", 18)
	tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 36)
	tip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(tip)
	_fade(bg, 1.0, 0.4)
	_fade(bar, 1.0, 0.4)
	await _fade(logo, 1.0, 0.5)

	# Chargement réel : données et partie, puis scènes en arrière-plan.
	GameState.start_or_load()
	ResourceLoader.load_threaded_request(SceneRouter.CITY)
	ResourceLoader.load_threaded_request(SceneRouter.MAIN_MENU)
	var shown := 0.0
	while true:
		var p := []
		var status := ResourceLoader.load_threaded_get_status(SceneRouter.CITY, p)
		var target := 1.0 if status == ResourceLoader.THREAD_LOAD_LOADED else clampf(p[0] if p.size() else 0.0, 0.0, 0.95)
		shown = move_toward(shown, target, get_process_delta_time() * 1.6)
		bar.value = shown * 100.0
		if shown >= 1.0 or status == ResourceLoader.THREAD_LOAD_FAILED:
			break
		await get_tree().process_frame
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _centered_logo(tex: Texture2D, width_ratio: float, y_offset := 0.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.anchor_left = (1.0 - width_ratio) / 2.0
	r.anchor_right = 1.0 - r.anchor_left
	r.anchor_top = 0.1
	r.anchor_bottom = 0.85
	r.position.y += y_offset
	r.modulate.a = 0.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _fade(c: CanvasItem, to: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(c, "modulate:a", to, 0.05 if _skip else time)
	await t.finished


func _wait(time: float) -> void:
	var left := time
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		left -= get_process_delta_time()
