class_name LaboratoryScreen
extends ModalScreen
## Laboratoire : ingrédients, probabilités affichées, machine animée, révélation.

var _slots: Array = []  # ids sélectionnés
var _machine: LabMachine
var _slot_row: HBoxContainer
var _action_box: VBoxContainer
var _odds: VBoxContainer
var _items: GridContainer
var _tab := 0
var _tabs: HBoxContainer
var _accum := 0.0


func _ready() -> void:
	_build_shell("Laboratoire")
	music = "music_mystic"
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	body.add_child(main)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(420, 0)
	left.add_theme_constant_override("separation", 8)
	main.add_child(left)
	_machine = LabMachine.new()
	left.add_child(_machine)
	_slot_row = HBoxContainer.new()
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.add_theme_constant_override("separation", 10)
	left.add_child(_slot_row)
	_action_box = VBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 6)
	left.add_child(_action_box)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	right.add_child(_tabs)
	for i in 2:
		var b := UiTheme.button(["Ingrédients", "Synthèse"][i], "TabButton", null, 20)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 50)
		b.pressed.connect(func():
			_tab = i
			refresh())
		_tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 220)
	right.add_child(scroll)
	_items = GridContainer.new()
	_items.columns = 6
	_items.add_theme_constant_override("h_separation", 10)
	_items.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_items)
	right.add_child(UiTheme.label("Chances de la prochaine expérience", "HeaderLabel", 22))
	_odds = VBoxContainer.new()
	right.add_child(_odds)
	Events.inventory_changed.connect(func():
		if visible:
			refresh())


func _process(delta: float) -> void:
	if not visible:
		return
	var lab := GameState.lab
	var now := GameClock.now()
	_machine.running = lab.is_running() and not lab.is_ready(now)
	if lab.is_running():
		var span := float(lab.experiment.end) - float(lab.experiment.start)
		_machine.progress = 1.0 - lab.remaining(now) / maxf(span, 1.0)
	_accum += delta
	if _accum > 0.5:
		_accum = 0.0
		if lab.is_running():
			_refresh_action()


func refresh() -> void:
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	var lab := GameState.lab
	var city := GameState.city
	var n_slots := LaboratoryState.slots(city)
	while _slots.size() > n_slots:
		_slots.pop_back()
	_machine.set_ingredients(LaboratoryState.ingredients_of(lab.experiment.ingredients) if lab.is_running() else LaboratoryState.ingredients_of(_slots))
	clear(_slot_row)
	for i in n_slots:
		if lab.is_running():
			var id: String = lab.experiment.ingredients[i] if i < lab.experiment.ingredients.size() else ""
			_slot_row.add_child(_slot_tile(id, false))
		else:
			var id: String = _slots[i] if i < _slots.size() else ""
			var t := _slot_tile(id, true)
			if id != "":
				var idx := i
				on_tap(t, func():
					_slots.remove_at(idx)
					refresh())
			_slot_row.add_child(t)
	_refresh_action()
	_refresh_items()
	_refresh_odds()


func _slot_tile(id: String, editable: bool) -> Control:
	if id == "":
		var empty := item_tile(preload("res://assets/icons/ui/info.svg"), "Vide", 0, 80)
		empty.modulate = Color(1, 1, 1, 0.45)
		return empty
	var ing := DataRegistry.ingredient(id)
	return item_tile(ing.icon, "Retirer" if editable else ing.display_name.split(" ")[0], ing.rarity, 80)


func _refresh_action() -> void:
	clear(_action_box)
	var lab := GameState.lab
	var now := GameClock.now()
	if lab.is_running():
		if lab.is_ready(now):
			var reveal := UiTheme.button("Révéler la créature", "PremiumButton", preload("res://assets/icons/ui/egg.svg"), 26)
			reveal.custom_minimum_size = Vector2(0, 70)
			reveal.pressed.connect(_claim)
			_action_box.add_child(reveal)
		else:
			_action_box.add_child(UiTheme.label("Expérience en cours…  %s" % Fmt.duration(lab.remaining(now)), "HeaderLabel", 26))
			var cost := lab.speed_up_cost(now, GameState.config())
			var sp := UiTheme.button("Terminer (%d)" % cost if cost > 0 else "Terminer (gratuit)", "PremiumButton",
				DataRegistry.resource_type(GameState.config().premium_resource).icon, 22)
			sp.pressed.connect(func():
				if not lab.speed_up(GameState.wallet, GameClock.now(), GameState.config()):
					Events.toast_requested.emit("Pas assez de prismes", "error")
				GameState.save()
				refresh())
			_action_box.add_child(sp)
		return
	var reason := lab.start_reason(_slots, GameState.wallet, GameState.inventory, GameState.city)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_action_box.add_child(row)
	var start := UiTheme.button("Lancer l'expérience", "SuccessButton", preload("res://assets/icons/ui/speedup.svg"), 22)
	start.custom_minimum_size = Vector2(0, 62)
	start.disabled = reason != "" and reason != "Ressources insuffisantes"
	start.pressed.connect(_start)
	row.add_child(start)
	if not _slots.is_empty():
		var info := VBoxContainer.new()
		info.add_child(UiTheme.cost_row(LabRules.cost(_slots.size()), GameState.wallet, 18))
		info.add_child(UiTheme.label("Durée : " + Fmt.duration(LabRules.duration(LaboratoryState.ingredients_of(_slots))), "DimLabel", 16))
		row.add_child(info)
	if reason != "" and not _slots.is_empty():
		_action_box.add_child(UiTheme.label(reason, "DimLabel", 16))


func _refresh_items() -> void:
	clear(_items)
	var inv := GameState.inventory
	if _tab == 0:
		for ing in DataRegistry.all_ingredients():
			var used := _slots.count(ing.id)
			var have := inv.count(ing.id) - used
			var t := item_tile(ing.icon, "×%d" % have, ing.rarity)
			t.tooltip_text = "%s — %s" % [ing.display_name, ing.description]
			if have <= 0:
				t.modulate = Color(1, 1, 1, 0.35)
			else:
				on_tap(t, func():
					if GameState.lab.is_running():
						return
					if _slots.size() >= LaboratoryState.slots(GameState.city):
						Events.toast_requested.emit("Tous les emplacements sont pleins", "error")
						return
					_slots.append(ing.id)
					refresh())
			_items.add_child(t)
	else:
		for id in LaboratoryState.SYNTHESIS:
			var ing := DataRegistry.ingredient(id)
			var box := VBoxContainer.new()
			box.add_child(item_tile(ing.icon, "×%d" % inv.count(id), ing.rarity))
			var b := UiTheme.button("Créer", "SecondaryButton", null, 18)
			b.disabled = not GameState.wallet.can_afford(LaboratoryState.SYNTHESIS[id])
			b.pressed.connect(func():
				var r := GameState.lab.synthesize(id, GameState.wallet, GameState.inventory)
				Events.toast_requested.emit(r if r != "" else "%s créé" % ing.display_name, "error" if r != "" else "success")
				if r == "":
					AudioManager.sfx("lab_bubble")
				GameState.save())
			box.add_child(b)
			box.add_child(UiTheme.cost_row(LaboratoryState.SYNTHESIS[id], GameState.wallet, 14))
			_items.add_child(box)


func _refresh_odds() -> void:
	clear(_odds)
	var ings := LaboratoryState.ingredients_of(_slots)
	if ings.is_empty():
		_odds.add_child(UiTheme.label("Ajoutez des ingrédients : leurs affinités et leur rareté orientent le résultat, sans jamais le garantir.", "DimLabel", 17))
		return
	var probs := LabRules.probabilities(ings)
	var dist := LabRules.rarity_distribution(probs)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 12)
	_odds.add_child(bars)
	for r in 4:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.add_child(UiTheme.label(GameEnums.rarity_name(r), "HudLabel", 15, GameEnums.rarity_color(r).lightened(0.3)))
		col.add_child(UiTheme.label("%.1f %%" % (dist[r] * 100.0), "HudLabel", 20))
		bars.add_child(col)
	var top: Array = probs.keys()
	top.sort_custom(func(a, b): return probs[a] > probs[b])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_odds.add_child(row)
	for id in top.slice(0, 5):
		var d := DataRegistry.monster(id)
		var known := GameState.collection.owns_monster_species(id)
		var t := item_tile(d.portrait, "%.0f %%" % (probs[id] * 100.0), d.rarity, 74)
		if not known:
			t.get_child(0).get_child(0).modulate = Color(0.08, 0.08, 0.14)
		row.add_child(t)


func _start() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var r := GameState.lab.start(_slots, GameState.wallet, GameState.inventory, GameState.city, GameClock.now(), rng)
	if r != "":
		Events.toast_requested.emit(r, "error")
		return
	_slots.clear()
	AudioManager.sfx("lab_start", 0.0)
	Events.action_done.emit("lab", 1)
	GameState.save()
	refresh()


func _claim() -> void:
	var got := GameState.lab.claim(GameState.collection, GameState.city, GameClock.now())
	if got.has("error"):
		Events.toast_requested.emit(got.error, "error")
		return
	GameState.save()
	AudioManager.sfx("hatch", 0.0)
	var d := DataRegistry.monster(got.id)
	RevealOverlay.play(self, d.model_scene, d.rarity, "Nouvelle espèce !" if got.new else "Une créature est née !", d.display_name,
		[GameEnums.MONSTER_CATEGORY_NAMES[d.category] + " • " + GameEnums.element_name(d.element)])
	refresh()
