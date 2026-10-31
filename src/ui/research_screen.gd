class_name ResearchScreen
extends ModalScreen
## Recherches de la Bibliothèque (cité) ou de l'Académie (héros).

var _building := "library"
var _list: VBoxContainer
var _active_box: VBoxContainer
var _timer_label: Label
var _speed_btn: Button
var _tick := 0.0


func _ready() -> void:
	_build_shell("Bibliothèque")
	_active_box = VBoxContainer.new()
	_active_box.add_theme_constant_override("separation", 6)
	body.add_child(_active_box)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	Events.research_changed.connect(func():
		if visible:
			refresh())


func open_for(building_id: String) -> void:
	_building = building_id
	open_screen()


func _process(delta: float) -> void:
	if not visible or _timer_label == null:
		return
	_tick += delta
	if _tick < 0.5:
		return
	_tick = 0.0
	var r := GameState.city.research
	var now := GameClock.now()
	if not r.active.has(_building):
		refresh()
		return
	_timer_label.text = "Temps restant : %s" % Fmt.duration(r.time_left(_building, now))
	_speed_btn.text = "Terminer (%d prismes)" % r.speedup_cost(_building, now)


func refresh() -> void:
	clear(_list)
	clear(_active_box)
	_timer_label = null
	var city := GameState.city
	var r := city.research
	var now := GameClock.now()
	var d := DataRegistry.building(_building)
	var blvl := city.best_level(_building)
	title_label.text = "%s (niveau %d)" % [d.display_name, blvl]
	var intro := UiTheme.label("Améliorez le bâtiment pour débloquer des niveaux de recherche supplémentaires. Une recherche à la fois.", "DimLabel", 18)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active_box.add_child(intro)
	if r.active.has(_building):
		var a: Dictionary = r.active[_building]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		_active_box.add_child(row)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(UiTheme.label("En cours : %s → niveau %d" % [ResearchState.TECHS[a.id].name, r.level(a.id) + 1], "HeaderLabel", 22, UiTheme.GOLD))
		_timer_label = UiTheme.label("Temps restant : %s" % Fmt.duration(r.time_left(_building, now)), "HudLabel", 20)
		v.add_child(_timer_label)
		_speed_btn = UiTheme.button("Terminer (%d prismes)" % r.speedup_cost(_building, now), "SecondaryButton", preload("res://assets/icons/ui/speedup.svg"), 18)
		_speed_btn.pressed.connect(func():
			var res := r.finish_now(_building, GameState.wallet, GameClock.now())
			Events.toast_requested.emit(res if res != "" else "Recherche terminée !", "error" if res != "" else "success")
			if res == "":
				AudioManager.sfx("levelup"))
		row.add_child(_speed_btn)
	for id in ResearchState.techs_for(_building):
		_list.add_child(_card(id))


func _card(id: String) -> Control:
	var city := GameState.city
	var r := city.research
	var t: Dictionary = ResearchState.TECHS[id]
	var lvl := r.level(id)
	var card := PanelContainer.new()
	var done: bool = lvl >= t.max
	card.add_theme_stylebox_override("panel", UiTheme.box(Color(0.12, 0.1, 0.22, 0.92), UiTheme.GOLD if done else Color("8a7cff"), 14, 3, 4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UiTheme.label("%s — niveau %d / %d" % [t.name, lvl, t.max], "HeaderLabel", 22))
	v.add_child(UiTheme.label(t.desc, "HudLabel", 18, UiTheme.GREEN))
	if done:
		v.add_child(UiTheme.label("Recherche complète", "HudLabel", 18, UiTheme.GOLD))
		return card
	var a: Dictionary = r.active.get(_building, {})
	if a.get("id", "") == id:
		v.add_child(UiTheme.label("Recherche du niveau %d en cours…" % (lvl + 1), "HudLabel", 18, UiTheme.GOLD))
		return card
	var cost := r.cost(id)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	info.add_child(UiTheme.cost_row(cost, GameState.wallet, 18))
	info.add_child(UiTheme.label(Fmt.duration(r.seconds(id)), "DimLabel", 18))
	v.add_child(info)
	var reason := r.reason(id, city, GameState.wallet)
	if reason != "" and reason != "Ressources insuffisantes":
		v.add_child(UiTheme.label(reason, "DimLabel", 16))
	var b := UiTheme.button("Rechercher", "PrimaryButton", null, 20)
	b.custom_minimum_size = Vector2(190, 64)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = reason != ""
	b.pressed.connect(func():
		var res := r.start(id, city, GameState.wallet, GameClock.now())
		Events.toast_requested.emit(res if res != "" else "Recherche lancée : %s" % t.name, "error" if res != "" else "success"))
	row.add_child(b)
	return card
