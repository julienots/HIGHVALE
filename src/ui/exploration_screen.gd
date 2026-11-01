class_name ExplorationScreen
extends ModalScreen
## Carte d'exploration : profondeurs, surface et expéditions.

var _tab := 0
var _tabs: HBoxContainer
var _content: VBoxContainer
var _accum := 0.0


func _ready() -> void:
	_build_shell("Exploration")
	music = "music_explore"
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	header.add_child(_tabs)
	header.move_child(_tabs, 1)
	for i in 3:
		var b := UiTheme.button(["Profondeurs", "Surface", "Expéditions"][i], "TabButton", null, 22)
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
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)


func _process(delta: float) -> void:
	_accum += delta
	if visible and _tab == 2 and _accum > 1.0:
		_accum = 0.0
		refresh()


func refresh() -> void:
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	clear(_content)
	if _tab == 2:
		_fill_expeditions()
		return
	var ex := GameState.exploration
	if _tab == 1 and GameState.city.temple_level() < 5:
		_content.add_child(UiTheme.label("Un courant d'air frais descend des hauteurs… Le passage vers la surface s'ouvrira quand le Temple Primordial atteindra le niveau 5.", "HeaderLabel", 22))
	for z in DataRegistry.zones():
		if z.is_surface != (_tab == 1):
			continue
		var reason := ex.unlock_reason(z, GameState.city)
		var card := PanelContainer.new()
		var sb := UiTheme.box(z.sky_color.lerp(Color("1d2540"), 0.5), z.light_color, 16, 4, 5)
		card.add_theme_stylebox_override("panel", sb)
		if reason != "":
			card.modulate = Color(0.55, 0.55, 0.65)
		var v := VBoxContainer.new()
		card.add_child(v)
		var head := HBoxContainer.new()
		v.add_child(head)
		var t := UiTheme.label("%d. %s" % [z.order, z.display_name], "TitleLabel", 28, z.light_color.lightened(0.2))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		head.add_child(UiTheme.label("Combats : %d / %d" % [ex.zone_progress(z), ZoneData.STAGES], "HudLabel", 20, UiTheme.GREEN if ex.is_cleared(z) else UiTheme.TEXT))
		var d := UiTheme.label(z.description, "", 18)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		var info := HBoxContainer.new()
		info.add_theme_constant_override("separation", 6)
		v.add_child(info)
		info.add_child(UiTheme.label("Créatures :", "DimLabel", 16))
		for mid in z.monster_ids:
			var m := DataRegistry.monster(mid)
			info.add_child(item_tile(m.portrait, "", m.rarity, 46))
		info.add_child(UiTheme.label("  Butin :", "DimLabel", 16))
		info.add_child(UiTheme.cost_row(z.resource_drops, null, 16))
		if reason != "":
			v.add_child(UiTheme.label(reason, "HudLabel", 18, UiTheme.RED))
		else:
			var stages := HBoxContainer.new()
			stages.add_theme_constant_override("separation", 10)
			v.add_child(stages)
			for s in ZoneData.STAGES:
				var enc := z.encounter(s)
				var boss := s == ZoneData.STAGES - 1
				var open := ex.stage_unlocked(z, s)
				var b := UiTheme.button(("Gardien (boss)" if boss else "Étape %d" % (s + 1)) + "\nPuissance %d" % BattleSetup.enemy_power(enc),
					"DangerButton" if boss else "SecondaryButton", null, 17)
				b.custom_minimum_size = Vector2(190, 62)
				b.disabled = not open
				if s < ex.zone_progress(z):
					b.text += "  ✓"
				b.pressed.connect(func():
					GameState.pending_battle = null
					GameState.pending_zone = z.id
					GameState.pending_stage = s
					GameState.launch_battle())
				stages.add_child(b)
			stages.add_child(UiTheme.label("Votre équipe : %d" % GameState.collection.team_power(), "HudLabel", 18, UiTheme.GOLD))
		_content.add_child(card)


func _fill_expeditions() -> void:
	var ex := GameState.exploration
	var city := GameState.city
	var now := GameClock.now()
	_content.add_child(UiTheme.label("Équipes d'exploration : %d / %d (Tour des explorateurs)" % [ex.expeditions.size(), ExplorationState.slots(city)], "HeaderLabel", 22))
	for i in ex.expeditions.size():
		var e: Dictionary = ex.expeditions[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var h := DataRegistry.hero(e.hero)
		row.add_child(item_tile(h.portrait, "", h.rarity, 64))
		row.add_child(UiTheme.label("%s explore %s" % [h.display_name, DataRegistry.zone(e.zone).display_name], "HudLabel", 20))
		var left := float(e.end) - now
		if left > 0:
			row.add_child(UiTheme.label("Retour dans " + Fmt.duration(left), "DimLabel", 18))
		else:
			var idx := i
			var b := UiTheme.button("Récupérer le butin", "SuccessButton", null, 18)
			b.pressed.connect(func():
				var got := ex.claim(idx, GameState.collection, GameState.wallet, GameClock.now())
				if got.has("resources"):
					Events.toast_requested.emit("Expédition de retour : butin récupéré !", "reward")
					AudioManager.sfx("collect", 0.0)
				GameState.save()
				refresh())
			row.add_child(b)
		_content.add_child(row)
	if ExplorationState.slots(city) < 1:
		_content.add_child(UiTheme.label("Construisez une Tour des explorateurs (Temple niveau 5) pour envoyer des héros en expédition.", "DimLabel", 18))
		return
	if ex.expeditions.size() >= ExplorationState.slots(city):
		return
	_content.add_child(UiTheme.label("Nouvelle expédition", "HeaderLabel", 22))
	for z in DataRegistry.zones():
		if ex.zone_progress(z) < 1:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(UiTheme.label(z.display_name, "HudLabel", 18))
		var hero_id := ""
		for id in GameState.collection.heroes:
			if not ex.hero_busy(id):
				hero_id = id
				break
		if hero_id == "":
			row.add_child(UiTheme.label("Aucun héros disponible", "DimLabel", 16))
		else:
			for hours in ExplorationState.EXPEDITION_HOURS:
				var b := UiTheme.button(Fmt.duration(ExplorationState.duration(hours, city)), "SecondaryButton", null, 17)
				b.tooltip_text = "Butin estimé : %s" % str(ExplorationState.expected_loot(z, hours, GameState.collection.hero_power(hero_id)))
				b.pressed.connect(func():
					var r := ex.start(z, hero_id, hours, city, GameState.collection, GameClock.now())
					Events.toast_requested.emit(r if r != "" else "%s part en expédition" % DataRegistry.hero(hero_id).display_name, "error" if r != "" else "success")
					if r == "":
						AudioManager.sfx("wind")
					GameState.save()
					refresh())
				row.add_child(b)
			row.add_child(UiTheme.label("(%s)" % DataRegistry.hero(hero_id).display_name, "DimLabel", 16))
		_content.add_child(row)
