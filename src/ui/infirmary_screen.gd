class_name InfirmaryScreen
extends ModalScreen
## Infirmerie : héros blessés (mis K.O. en combat), temps de repos restant et
## soin immédiat contre de l'Essence vitale.

var _list: VBoxContainer
var _info: Label
var _tick := 0.0
## [label, id] des compteurs affichés, mis à jour chaque seconde sans tout reconstruire.
var _timers: Array = []


func _ready() -> void:
	_build_shell("Infirmerie")
	_info = UiTheme.label("", "HudLabel", 20)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_info)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	Events.collection_changed.connect(func():
		if visible:
			refresh())


func _process(delta: float) -> void:
	if not visible:
		return
	_tick += delta
	if _tick < 1.0:
		return
	_tick = 0.0
	var now := GameClock.now()
	for t in _timers:
		var left := int(GameState.collection.wound_left(t[1], now))
		if left <= 0:
			refresh()
			return
		t[0].text = "Repos : %d:%02d" % [left / 60, left % 60]


func refresh() -> void:
	clear(_list)
	_timers.clear()
	var coll := GameState.collection
	var now := GameClock.now()
	coll.prune_wounds(now)
	var lvl := GameState.city.best_level("infirmary")
	title_label.text = "Infirmerie (niveau %d)" % lvl if lvl > 0 else "Infirmerie"
	_info.text = "Les héros mis K.O. se reposent %d min avant de pouvoir combattre à nouveau (−8 %% par niveau d'Infirmerie). Un soin immédiat coûte %d Essence vitale par minute restante." % [
		ceili(CollectionState.wound_seconds(lvl) / 60.0), CollectionState.HEAL_ESSENCE_PER_MINUTE]
	var hurt := coll.wounded_heroes(now)
	if hurt.is_empty():
		var ok := UiTheme.label("Aucun blessé. Toute l'équipe est prête au combat !", "HeaderLabel", 24, UiTheme.GREEN)
		ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(ok)
		return
	hurt.sort_custom(func(a, b): return coll.wound_left(a, now) < coll.wound_left(b, now))
	for id in hurt:
		_list.add_child(_row(id, now))


func _row(id: String, now: float) -> Control:
	var coll := GameState.collection
	var h := DataRegistry.hero(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(Color(0.25, 0.08, 0.1, 0.9), Color("ff8a8a"), 14, 3, 4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.add_child(UiTheme.icon_rect(h.portrait, 84))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UiTheme.label("%s — Niv. %d" % [h.display_name, coll.hero_level(id)], "HeaderLabel", 22))
	var left := int(coll.wound_left(id, now))
	var timer := UiTheme.label("Repos : %d:%02d" % [left / 60, left % 60], "HudLabel", 20, Color("ff8a8a"))
	v.add_child(timer)
	_timers.append([timer, id])
	var cost := coll.heal_cost(id, now)
	v.add_child(UiTheme.cost_row(cost, GameState.wallet, 18))
	var b := UiTheme.button("Soigner", "PrimaryButton", preload("res://assets/icons/ui/heart.svg"), 20)
	b.custom_minimum_size = Vector2(170, 64)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not GameState.wallet.can_afford(cost)
	b.pressed.connect(func():
		var r := coll.heal_hero(id, GameState.wallet, GameClock.now())
		if r == "":
			Events.toast_requested.emit("%s est guéri !" % h.display_name, "success")
			AudioManager.sfx("heal")
			GameState.save()
		else:
			Events.toast_requested.emit(r, "error")
		refresh())
	row.add_child(b)
	return card
