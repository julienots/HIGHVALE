class_name MissionsScreen
extends ModalScreen
## Missions, passe saisonnier, récompenses de connexion et événement de la semaine.

var _tab := 0
var _tabs: HBoxContainer
var _content: VBoxContainer


func _ready() -> void:
	_build_shell("Missions")
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	header.add_child(_tabs)
	header.move_child(_tabs, 1)
	for i in 4:
		var b := UiTheme.button(["Missions", "Passe saisonnier", "Connexion", "Événement"][i], "TabButton", null, 20)
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
	Events.quests_changed.connect(func():
		if visible:
			refresh())


func refresh() -> void:
	var q := GameState.quests
	q.roll(GameClock.now())
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	clear(_content)
	match _tab:
		0:
			_content.add_child(UiTheme.label("Missions du jour", "HeaderLabel", 24))
			for id in q.daily_ids():
				_mission_row(id)
			_content.add_child(UiTheme.label("Missions de la semaine", "HeaderLabel", 24))
			for id in QuestState.WEEKLY:
				_mission_row(id)
		1:
			_content.add_child(UiTheme.label("Passe saisonnier : palier %d / %d  (%d XP)" % [q.pass_tier(), QuestState.PASS_TIERS, q.pass_xp], "HeaderLabel", 24))
			var bar := ProgressBar.new()
			bar.max_value = QuestState.PASS_XP_PER_TIER
			bar.value = q.pass_xp % QuestState.PASS_XP_PER_TIER
			bar.custom_minimum_size = Vector2(0, 22)
			bar.show_percentage = false
			_content.add_child(bar)
			_content.add_child(UiTheme.label("Chaque mission rapporte de l'expérience de saison (%d par mission du jour, %d par mission de la semaine)." % [QuestState.DAILY_XP, QuestState.WEEKLY_XP], "DimLabel", 17))
			var grid := GridContainer.new()
			grid.columns = 5
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			_content.add_child(grid)
			for t in QuestState.PASS_TIERS:
				var box := PanelContainer.new()
				box.theme_type_variation = "CardPanel"
				var v := VBoxContainer.new()
				box.add_child(v)
				v.add_child(UiTheme.label("Palier %d" % (t + 1), "HudLabel", 18, UiTheme.GOLD if t % 5 == 4 else UiTheme.TEXT))
				v.add_child(UiTheme.cost_row(QuestState.pass_reward(t), null, 16))
				if t < q.pass_claimed:
					v.add_child(UiTheme.label("Récupéré ✓", "DimLabel", 15))
				elif t == q.pass_claimed and t < q.pass_tier():
					var b := UiTheme.button("Récupérer", "SuccessButton", null, 16)
					b.pressed.connect(func():
						q.claim_pass(GameState.wallet)
						GameState.save())
					v.add_child(b)
				else:
					box.modulate = Color(0.6, 0.6, 0.7)
				grid.add_child(box)
		2:
			_content.add_child(UiTheme.label("Récompenses de connexion (série : %d jour%s)" % [q.login_streak, "s" if q.login_streak > 1 else ""], "HeaderLabel", 24))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			_content.add_child(row)
			for i in QuestState.LOGIN_REWARDS.size():
				var box := PanelContainer.new()
				box.theme_type_variation = "CardPanel"
				var v := VBoxContainer.new()
				box.add_child(v)
				v.add_child(UiTheme.label("Jour %d" % (i + 1), "HudLabel", 18))
				v.add_child(UiTheme.cost_row(QuestState.LOGIN_REWARDS[i], null, 16))
				if i < (q.login_streak - 1) % 7 + 1 and not q.login_available(GameClock.now()):
					box.modulate = Color(0.6, 0.9, 0.6)
				row.add_child(box)
			var b := UiTheme.button("Récupérer la récompense du jour", "PremiumButton", null, 22)
			b.disabled = not q.login_available(GameClock.now())
			b.pressed.connect(func():
				var r := q.claim_login(GameState.wallet, GameClock.now())
				if not r.is_empty():
					Events.toast_requested.emit("Récompense de connexion récupérée !", "reward")
				GameState.save())
			_content.add_child(b)
		3:
			var now := GameClock.now()
			var ev := EventCalendar.current(now)
			_content.add_child(UiTheme.label(ev.name, "TitleLabel", 34, ev.color))
			var d := UiTheme.label(ev.desc, "", 20)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_content.add_child(d)
			_content.add_child(UiTheme.label("Se termine dans " + Fmt.duration(EventCalendar.ends_in(now)), "HudLabel", 20))
			var enc := EventCalendar.boss_encounter(now, GameState.collection)
			var foes := HBoxContainer.new()
			for e in enc.enemies:
				var m := DataRegistry.monster(e.id)
				foes.add_child(item_tile(m.portrait, "Niv. %d" % e.level, m.rarity, 70))
			_content.add_child(foes)
			_content.add_child(UiTheme.label("Récompense du boss (une fois par jour) :", "DimLabel", 18))
			_content.add_child(UiTheme.cost_row(enc.rewards, null, 20))
			var done: bool = int(GameState.profile.get("event_day", -1)) == QuestState.day_index(now)
			var b := UiTheme.button("Déjà vaincu aujourd'hui" if done else "Affronter le boss", "DangerButton", null, 22)
			b.disabled = done
			b.pressed.connect(func():
				GameState.pending_battle = enc
				GameState.pending_zone = ""
				GameState.launch_battle())
			_content.add_child(b)


func _mission_row(id: String) -> void:
	var q := GameState.quests
	var m := q.mission(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := UiTheme.label(m[0] % m[2], "HudLabel", 19)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(UiTheme.label("%d / %d" % [mini(q.progress_of(id), m[2]), m[2]], "HudLabel", 19, UiTheme.GREEN if q.progress_of(id) >= m[2] else UiTheme.TEXT))
	row.add_child(UiTheme.cost_row(m[3], null, 16))
	if id in q.claimed:
		row.add_child(UiTheme.label("✓", "HudLabel", 22, UiTheme.GREEN))
	else:
		var b := UiTheme.button("Récupérer", "SuccessButton", null, 16)
		b.disabled = not q.can_claim(id)
		b.pressed.connect(func():
			q.claim(id, GameState.wallet)
			GameState.save())
		row.add_child(b)
	_content.add_child(row)
