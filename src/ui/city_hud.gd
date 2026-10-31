class_name CityHud
extends CanvasLayer
## Interface de la cité : ressources, bâtisseurs, Temple, construction,
## panneau du bâtiment sélectionné, barre de placement et messages.

const ICON_BUILD := preload("res://assets/icons/ui/build.svg")
const ICON_SETTINGS := preload("res://assets/icons/ui/settings.svg")
const ICON_BUILDER := preload("res://assets/icons/ui/builder.svg")
const ICON_TEMPLE := preload("res://assets/icons/ui/temple.svg")
const ICON_CHECK := preload("res://assets/icons/ui/check.svg")
const ICON_CROSS := preload("res://assets/icons/ui/cross.svg")
const ICON_POP := preload("res://assets/icons/ui/population.svg")

var controller: Node  # CityScene
var root: Control
var building_panel: BuildingPanel
var build_menu: BuildMenu
var collection_screen: CollectionScreen
var laboratory_screen: LaboratoryScreen
var fusion_screen: FusionScreen
var summon_screen: SummonScreen
var stages_screen: StagesScreen
var forge_screen: ForgeScreen
var _chips := {}  # id -> ResourceChip
var _temple_label: Label
var _builders_label: Label
var _pop_label: Label
var _build_button: Button
var _placement_bar: PanelContainer
var _placement_title: Label
var _placement_cost: HBoxContainer
var _confirm_btn: Button
var _fps: Label
var _refresh_accum := 0.0


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.name = "Root"
	root.theme = UiTheme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar()
	_build_bottom()
	_build_placement_bar()
	building_panel = BuildingPanel.new()
	building_panel.controller = controller
	building_panel.visible = false
	building_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	building_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	building_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	building_panel.custom_minimum_size = Vector2(700, 0)
	root.add_child(building_panel)
	var toast := Toast.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position.y = 96
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(toast)
	build_menu = BuildMenu.new()
	root.add_child(build_menu)
	build_menu.build_requested.connect(func(d): controller.start_new_building(d))
	collection_screen = CollectionScreen.new()
	root.add_child(collection_screen)
	laboratory_screen = LaboratoryScreen.new()
	root.add_child(laboratory_screen)
	fusion_screen = FusionScreen.new()
	root.add_child(fusion_screen)
	summon_screen = SummonScreen.new()
	root.add_child(summon_screen)
	stages_screen = StagesScreen.new()
	root.add_child(stages_screen)
	forge_screen = ForgeScreen.new()
	root.add_child(forge_screen)
	_fps = UiTheme.label("", "DimLabel", 16)
	_fps.position = Vector2(12, 92)
	root.add_child(_fps)
	Events.resource_changed.connect(func(id, _a): _refresh_chip(id))
	Events.capacities_changed.connect(_refresh_all)
	Events.game_loaded.connect(_refresh_all)
	Events.population_changed.connect(_refresh_counters)
	_refresh_all()


func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum < 0.25:
		return
	_refresh_accum = 0.0
	if building_panel.visible:
		building_panel.refresh()
	_build_button.visible = not building_panel.visible and not _placement_bar.visible
	_refresh_counters()
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()


# --- Construction de l'interface --------------------------------------------

func _build_top_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	root.add_child(margin)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(bar)
	var temple := _info_chip(ICON_TEMPLE)
	_temple_label = temple.get_meta("label")
	temple.gui_input.connect(func(e):
		if e is InputEventMouseButton and not e.pressed:
			controller.focus_temple())
	bar.add_child(temple)
	var builders := _info_chip(ICON_BUILDER)
	_builders_label = builders.get_meta("label")
	builders.gui_input.connect(func(e):
		if e is InputEventMouseButton and not e.pressed:
			_show_builders_info())
	bar.add_child(builders)
	var pop := _info_chip(ICON_POP)
	_pop_label = pop.get_meta("label")
	pop.gui_input.connect(func(e):
		if e is InputEventMouseButton and not e.pressed:
			_show_population())
	bar.add_child(pop)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	for rt in DataRegistry.all_resource_types():
		if rt.show_in_hud or rt.is_premium:
			var chip := ResourceChip.new()
			chip.setup(rt, not rt.is_premium)
			chip.custom_minimum_size = Vector2(150 if not rt.is_premium else 110, 0)
			chip.pressed.connect(_show_resource_info)
			bar.add_child(chip)
			_chips[rt.id] = chip
	var more := UiTheme.button("+", "RoundButton", null, 26)
	more.custom_minimum_size = Vector2(52, 52)
	more.tooltip_text = "Toutes les ressources"
	more.pressed.connect(_show_all_resources)
	bar.add_child(more)


func _info_chip(icon: Texture2D) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "ChipPanel"
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(UiTheme.icon_rect(icon, 40))
	var l := UiTheme.label("", "HudLabel", 24)
	row.add_child(l)
	p.set_meta("label", l)
	return p


func _build_bottom() -> void:
	var settings := UiTheme.button("", "RoundButton", ICON_SETTINGS)
	settings.custom_minimum_size = Vector2(72, 72)
	settings.add_theme_constant_override("icon_max_width", 44)
	settings.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	settings.grow_vertical = Control.GROW_DIRECTION_BEGIN
	settings.pressed.connect(func(): SettingsPanel.open(root, true))
	root.add_child(settings)
	var coll := UiTheme.button("Collection", "SecondaryButton", preload("res://assets/icons/ui/collection.svg"), 24)
	coll.add_theme_constant_override("icon_max_width", 40)
	coll.custom_minimum_size = Vector2(0, 72)
	coll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	coll.grow_vertical = Control.GROW_DIRECTION_BEGIN
	coll.position.x += 88
	coll.pressed.connect(func():
		controller.deselect()
		collection_screen.show_screen())
	root.add_child(coll)
	var fight := UiTheme.button("Combats", "DangerButton", preload("res://assets/icons/elements/fire.svg"), 24)
	fight.add_theme_constant_override("icon_max_width", 40)
	fight.custom_minimum_size = Vector2(0, 72)
	fight.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	fight.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fight.position.x += 300
	fight.pressed.connect(func():
		controller.deselect()
		stages_screen.open_screen())
	root.add_child(fight)
	_build_button = UiTheme.button("Construire", "PrimaryButton", ICON_BUILD, 30)
	_build_button.add_theme_constant_override("icon_max_width", 48)
	_build_button.custom_minimum_size = Vector2(230, 84)
	_build_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_build_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_build_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_build_button.pressed.connect(func():
		controller.deselect()
		build_menu.show_menu())
	root.add_child(_build_button)


func _build_placement_bar() -> void:
	_placement_bar = PanelContainer.new()
	_placement_bar.visible = false
	_placement_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_placement_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	_placement_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_placement_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_placement_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_placement_bar.add_child(row)
	var cancel := UiTheme.button("", "DangerButton", ICON_CROSS)
	cancel.custom_minimum_size = Vector2(76, 70)
	cancel.pressed.connect(func(): controller.cancel_placement())
	row.add_child(cancel)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	_placement_title = UiTheme.label("", "HeaderLabel", 26)
	info.add_child(_placement_title)
	_placement_cost = HBoxContainer.new()
	info.add_child(_placement_cost)
	_confirm_btn = UiTheme.button("", "SuccessButton", ICON_CHECK)
	_confirm_btn.custom_minimum_size = Vector2(76, 70)
	_confirm_btn.pressed.connect(func(): controller.confirm_placement())
	row.add_child(_confirm_btn)


# --- Mises à jour -------------------------------------------------------------

func show_placement(d: BuildingData, is_move: bool) -> void:
	_placement_title.text = ("Déplacer : " if is_move else "") + d.display_name
	for c in _placement_cost.get_children():
		c.queue_free()
	if is_move:
		_placement_cost.add_child(UiTheme.label("Faites glisser le bâtiment", "DimLabel", 18))
	else:
		_placement_cost.add_child(UiTheme.cost_row(d.cost_for_level(1), GameState.wallet, 20))
	_placement_bar.visible = true
	UiSfx.pop_in(_placement_bar, 0.2)


func hide_placement() -> void:
	_placement_bar.visible = false


func set_placement_valid(valid: bool) -> void:
	_confirm_btn.disabled = not valid


func _refresh_all() -> void:
	for id in _chips:
		_chips[id].refresh()
	_refresh_counters()


func _refresh_chip(id: String) -> void:
	if _chips.has(id):
		_chips[id].refresh()


func _refresh_counters() -> void:
	var city := GameState.city
	_temple_label.text = "Niv. %d" % city.temple_level()
	_builders_label.text = "%d/%d" % [city.builders_total() - city.builders_busy(), city.builders_total()]
	_pop_label.text = "%d/%d" % [city.inhabitants, city.population_capacity()]


func _show_resource_info(id: String) -> void:
	var rt := DataRegistry.resource_type(id)
	var w := GameState.wallet
	var cap := w.capacity(id)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.add_child(UiTheme.icon_rect(rt.icon, 96))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(col)
	var desc := UiTheme.label(rt.description, "", 22)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)
	var amount := "%s / %s" % [Fmt.amount(w.amount(id)), Fmt.amount(cap)] if cap >= 0 else Fmt.amount(w.amount(id))
	col.add_child(UiTheme.label("Réserve : " + amount, "HudLabel", 24, rt.color))
	var hint := UiTheme.label(rt.source_hint, "DimLabel", 18)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	DialogBox.open(root, rt.display_name, body, [], 640)


func _show_all_resources() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 8)
	var w := GameState.wallet
	for rt in DataRegistry.all_resource_types():
		var row := HBoxContainer.new()
		row.add_child(UiTheme.icon_rect(rt.icon, 40))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -4)
		col.add_child(UiTheme.label(rt.display_name, "HudLabel", 20))
		var cap := w.capacity(rt.id)
		col.add_child(UiTheme.label("%s / %s" % [Fmt.amount(w.amount(rt.id)), Fmt.amount(cap)] if cap >= 0 else Fmt.amount(w.amount(rt.id)), "DimLabel", 18))
		row.add_child(col)
		row.custom_minimum_size = Vector2(300, 0)
		grid.add_child(row)
	DialogBox.open(root, "Ressources", grid, [], 760)


func _show_population() -> void:
	var city := GameState.city
	var now := GameClock.now()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	var cfg := GameState.config()
	for row in [["Bien-être", "%d %%" % city.happiness(now, cfg.feast_bonus)],
			["Habitants", "%d / %d" % [city.inhabitants, city.population_capacity()]],
			["Au travail", str(city.workers_total())], ["Libres", str(city.idle_inhabitants())],
			["Prochaine arrivée", "Logements pleins" if city.next_arrival_in(now) < 0 else Fmt.duration(city.next_arrival_in(now))]]:
		grid.add_child(UiTheme.label(row[0], "", 22))
		grid.add_child(UiTheme.label(row[1], "HudLabel", 24))
	body.add_child(grid)
	body.add_child(HSeparator.new())
	var any := false
	for b in city.buildings.values():
		if b.worker_slots() > 0:
			any = true
			body.add_child(UiTheme.label("%s (niv. %d) : %d / %d ouvriers — %d %%" % [b.data().display_name, b.level, b.workers, b.worker_slots(), roundi(b.efficiency() * 100)], "", 20))
	if not any:
		body.add_child(UiTheme.label("Aucun bâtiment de production.", "DimLabel", 18))
	var hint := UiTheme.label("Les habitants arrivent tant qu'il reste des logements. Le bien-être (décorations, Temple, festins) accélère leur arrivée. Un bâtiment sans ouvrier produit à 25 %.", "DimLabel", 17)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	var buttons := []
	if city.feast_active(now):
		body.add_child(UiTheme.label("Festin en cours : encore %s" % Fmt.duration(city.feast_until - now), "HudLabel", 22, UiTheme.GOLD))
	else:
		var cost_text := ""
		for id in cfg.feast_cost:
			cost_text += "%d %s" % [cfg.feast_cost[id], DataRegistry.resource_type(id).display_name.to_lower()]
		buttons.append({"text": "Festin (%s)" % cost_text, "variation": "PrimaryButton", "icon": preload("res://assets/icons/ui/heart.svg"),
			"disabled": not GameState.wallet.can_afford(cfg.feast_cost), "action": func(): controller.start_feast()})
	buttons.append({"text": "Fermer", "variation": "SecondaryButton"})
	DialogBox.open(root, "Population", body, buttons, 720)


func _show_builders_info() -> void:
	var city := GameState.city
	DialogBox.open(root, "Bâtisseurs",
		"[b]%d[/b] bâtisseur(s) libre(s) sur [b]%d[/b].\n\nChaque chantier (construction ou amélioration) occupe un bâtisseur. Construisez des [b]Hôtels des habitants[/b] pour en accueillir davantage." % [city.builders_total() - city.builders_busy(), city.builders_total()])
