class_name SettingsPanel
extends RefCounted
## Fenêtre des paramètres (graphismes, partie).


static func open(parent: Node, in_city: bool) -> DialogBox:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.add_child(UiTheme.label("Son", "HeaderLabel"))
	for entry in [["Musique", "music_volume"], ["Effets sonores", "sfx_volume"]]:
		var row := HBoxContainer.new()
		var l := UiTheme.label(entry[0], "", 22)
		l.custom_minimum_size = Vector2(200, 0)
		row.add_child(l)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Settings.get(entry[1])
		slider.custom_minimum_size = Vector2(260, 36)
		slider.value_changed.connect(func(v): Settings.set_value(entry[1], v))
		row.add_child(slider)
		body.add_child(row)
	body.add_child(UiTheme.label("Graphismes", "HeaderLabel"))
	var qrow := HBoxContainer.new()
	qrow.add_child(UiTheme.label("Qualité", "", 22))
	var q := OptionButton.new()
	for name in ["Économie (batterie)", "Équilibrée", "Élevée"]:
		q.add_item(name)
	q.select(Settings.quality)
	q.item_selected.connect(func(i): Settings.set_value("quality", i))
	qrow.add_child(q)
	body.add_child(qrow)
	var shadows := CheckButton.new()
	shadows.text = "Ombres dynamiques"
	shadows.button_pressed = Settings.shadows_enabled
	shadows.toggled.connect(func(on): Settings.set_value("shadows_enabled", on))
	body.add_child(shadows)
	var fps := CheckButton.new()
	fps.text = "Afficher les images par seconde"
	fps.button_pressed = Settings.show_fps
	fps.toggled.connect(func(on): Settings.set_value("show_fps", on))
	body.add_child(fps)
	var cap_row := HBoxContainer.new()
	cap_row.add_child(UiTheme.label("Images par seconde max. (batterie)", "", 22))
	var cap := OptionButton.new()
	for v in [30, 60]:
		cap.add_item("%d" % v, v)
	cap.select(0 if Settings.max_fps == 30 else 1)
	cap.item_selected.connect(func(i): Settings.set_value("max_fps", cap.get_item_id(i)))
	cap_row.add_child(cap)
	body.add_child(cap_row)
	var buttons := []
	if in_city:
		body.add_child(HSeparator.new())
		body.add_child(UiTheme.label("Partie", "HeaderLabel"))
		var reset := UiTheme.button("Recommencer la partie", "DangerButton", null, 22)
		reset.pressed.connect(func(): _confirm_reset(parent))
		body.add_child(reset)
		buttons.append({"text": "Menu principal", "variation": "SecondaryButton", "action": func():
			GameState.save()
			SceneRouter.go_to(SceneRouter.MAIN_MENU)})
	buttons.append({"text": "Fermer", "variation": "PrimaryButton"})
	body.add_child(UiTheme.label("HIGHVALE v%s — Super Essence Studio" % ProjectSettings.get_setting("application/config/version"), "DimLabel", 16))
	return DialogBox.open(parent, "Paramètres", body, buttons, 620)


static func _confirm_reset(parent: Node) -> void:
	for c in parent.get_children():
		if c is DialogBox:
			c.close()
	DialogBox.open(parent, "Recommencer ?",
		"Toute la progression de la cité sera [b]définitivement effacée[/b]. Continuer ?",
		[{"text": "Annuler", "variation": "SecondaryButton"},
		 {"text": "Effacer", "variation": "DangerButton", "action": GameState.reset_game}])
