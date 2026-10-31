class_name StagesScreen
extends ModalScreen
## Défis des profondeurs et composition de l'équipe.

var _tab := 0
var _tabs: HBoxContainer
var _content: VBoxContainer


func _ready() -> void:
	_build_shell("Défis des profondeurs")
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	header.add_child(_tabs)
	header.move_child(_tabs, 1)
	for i in 2:
		var b := UiTheme.button(["Défis", "Équipe"][i], "TabButton", null, 22)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func():
			_tab = i
			refresh())
		_tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	Events.collection_changed.connect(func():
		if visible:
			refresh())


func refresh() -> void:
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	clear(_content)
	if _tab == 0:
		_fill_stages()
	else:
		_fill_team()


func _fill_stages() -> void:
	var coll := GameState.collection
	var team_power := coll.team_power()
	_content.add_child(UiTheme.label("Puissance de l'équipe : %d" % team_power, "HudLabel", 22, UiTheme.GOLD))
	for enc in DataRegistry.encounters():
		var unlocked := BattleSetup.is_unlocked(enc, coll)
		var cleared := enc.order <= coll.stages_cleared
		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		if not unlocked:
			card.modulate = Color(0.55, 0.55, 0.65)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UiTheme.label("%d. %s%s" % [enc.order, enc.display_name, "  ✓" if cleared else ""], "HeaderLabel", 22, UiTheme.GREEN if cleared else UiTheme.TEXT))
		var d := UiTheme.label(enc.description, "DimLabel", 16)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d)
		var p := BattleSetup.enemy_power(enc)
		info.add_child(UiTheme.label("Puissance ennemie : %d" % p, "HudLabel", 17, UiTheme.RED if p > team_power * 1.15 else UiTheme.TEXT))
		var rew := enc.rewards.duplicate()
		if not cleared:
			for id in enc.first_clear_rewards:
				rew[id] = int(rew.get(id, 0)) + enc.first_clear_rewards[id]
		info.add_child(UiTheme.cost_row(rew, null, 16))
		var foes := HBoxContainer.new()
		foes.add_theme_constant_override("separation", 4)
		for e in enc.enemies:
			var m := DataRegistry.monster(e.id)
			var t := item_tile(m.portrait, "Niv. %d" % e.level, m.rarity, 58)
			if e.get("boss", false):
				t.modulate = Color(1.0, 0.75, 0.6)
			foes.add_child(t)
		row.add_child(foes)
		var go := UiTheme.button("Combattre" if unlocked else "Verrouillé", "DangerButton" if unlocked else "SecondaryButton", null, 22)
		go.custom_minimum_size = Vector2(170, 64)
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		go.disabled = not unlocked
		go.pressed.connect(func():
			GameState.pending_encounter = enc.id
			GameState.pending_zone = ""
			GameState.pending_battle = null
			GameState.save()
			SceneRouter.go_to(SceneRouter.BATTLE))
		row.add_child(go)
		_content.add_child(card)


func _fill_team() -> void:
	var coll := GameState.collection
	_content.add_child(UiTheme.label("Équipe (%d / %d) — puissance %d. Touchez un personnage pour l'ajouter ou le retirer." % [coll.team.size(), CollectionState.TEAM_SIZE, coll.team_power()], "HudLabel", 20))
	var counts := {}
	for c in coll.build_team_combatants():
		counts[c.element] = int(counts.get(c.element, 0)) + 1
	for el in counts:
		if counts[el] >= 3:
			_content.add_child(UiTheme.label("Synergie %s active : +10 %% d'attaque pour ces membres." % GameEnums.element_name(el), "HudLabel", 18, UiTheme.GOLD))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(grid)
	var hs: Array = coll.heroes.keys()
	hs.sort_custom(func(a, b): return coll.hero_power(a) > coll.hero_power(b))
	for id in hs:
		var h := DataRegistry.hero(id)
		grid.add_child(_member_tile(h.portrait, "%s\nNiv. %d" % [h.display_name, coll.hero_level(id)], h.rarity, coll.in_team("h", id), func(): _toggle("h", id)))
	for uid in coll.monsters:
		var m: Dictionary = coll.monsters[uid]
		var d := DataRegistry.monster(m.id)
		grid.add_child(_member_tile(d.portrait, "%s\nNiv. %d" % [d.display_name, m.level], d.rarity, coll.in_team("m", uid), func(): _toggle("m", uid)))


func _member_tile(portrait: Texture2D, text: String, rarity: int, selected: bool, cb: Callable) -> Control:
	var t := item_tile(portrait, text.split("\n")[1], rarity, 110)
	t.tooltip_text = text
	if selected:
		var sb := UiTheme.box(UiTheme.GOLD.darkened(0.5), UiTheme.GOLD, 12, 5, 5)
		sb.set_content_margin_all(4)
		t.add_theme_stylebox_override("panel", sb)
	else:
		t.modulate = Color(0.75, 0.75, 0.85)
	on_tap(t, cb)
	return t


func _toggle(kind: String, key: Variant) -> void:
	var r := GameState.collection.toggle_team(kind, key)
	if r != "":
		Events.toast_requested.emit(r, "error")
	GameState.save()
