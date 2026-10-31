class_name CityScene
extends Node3D
## Scène principale de la cité : relie le modèle (GameState.city), la vue 3D,
## la caméra, les gestes tactiles et l'interface.

const GRID_SHADER := preload("res://assets/shaders/grid_overlay.gdshader")
const TAP_THRESHOLD := 14.0

var cam: CityCamera
var hud: CityHud
var env: CaveEnvironment
var population: PopulationView
var wild_view: WildView
var nodes := {}  # uid -> BuildingNode
var selected_uid := 0

var _buildings_root: Node3D
var _grid_overlay: MeshInstance3D
var _ghost: PlacementGhost
var _moving_uid := 0
var _dragging_ghost := false
var _grab_offset := Vector2i.ZERO
var _touches := {}
var _press_pos := Vector2.ZERO
var _moved := false
var _drag_velocity := Vector2.ZERO
var _pinch_dist := 0.0
var _refresh_accum := 0.0


func _ready() -> void:
	var cfg := GameState.config()
	env = CaveEnvironment.new()
	env.name = "Cave"
	add_child(env)
	env.build(cfg.grid_size, cfg.buildable_rect)
	_buildings_root = Node3D.new()
	_buildings_root.name = "Buildings"
	add_child(_buildings_root)
	_build_grid_overlay(cfg.buildable_rect)
	wild_view = WildView.new()
	wild_view.name = "Wilds"
	add_child(wild_view)
	population = PopulationView.new()
	population.name = "Population"
	add_child(population)
	cam = CityCamera.new()
	cam.name = "CameraRig"
	cam.bounds = Rect2(cfg.buildable_rect)
	add_child(cam)
	hud = CityHud.new()
	hud.name = "Hud"
	hud.controller = self
	add_child(hud)
	Events.building_added.connect(_on_building_added)
	Events.building_removed.connect(_on_building_removed)
	Events.building_changed.connect(_on_building_changed)
	Events.building_task_finished.connect(_on_task_finished)
	Events.story_chapter_requested.connect(_show_story)
	Events.game_loaded.connect(_rebuild_city)
	_rebuild_city()


func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum >= 0.1:
		_refresh_accum = 0.0
		var now := GameClock.now()
		for n in nodes.values():
			n.refresh(now)


func dialog_parent() -> Control:
	return hud.root


# --- Construction de la vue ---------------------------------------------------

func _rebuild_city() -> void:
	cancel_placement()
	deselect()
	for n in nodes.values():
		n.queue_free()
	nodes.clear()
	for b in GameState.city.buildings.values():
		_spawn(b)
	var temple := _temple_state()
	cam.position = _world_center(temple) if temple else Vector3(20, 0, 20)
	GameState.request_story_for_level.call_deferred(1)


func _spawn(b: BuildingState) -> BuildingNode:
	var n := BuildingNode.new()
	_buildings_root.add_child(n)
	n.setup(b)
	nodes[b.uid] = n
	return n


func _build_grid_overlay(rect: Rect2i) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(rect.size)
	var m := ShaderMaterial.new()
	m.shader = GRID_SHADER
	_grid_overlay = MeshKit.part(self, plane, m, Vector3(rect.get_center().x, 0.03, rect.get_center().y))
	_grid_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grid_overlay.visible = false


func _temple_state() -> BuildingState:
	for b in GameState.city.buildings.values():
		if b.data_id == CityState.TEMPLE_ID:
			return b
	return null


func _world_center(b: BuildingState) -> Vector3:
	var fp := b.footprint()
	return Vector3(b.cell.x + fp.x / 2.0, 0, b.cell.y + fp.y / 2.0)


# --- Gestes -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom_at(0.9, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom_at(1.1, event.position)
	elif event is InputEventMagnifyGesture:
		cam.zoom_at(1.0 / event.factor, event.position)
	elif event is InputEventPanGesture:
		cam.pan(event.position, event.position - event.delta * 8.0)


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_press_pos = e.position
			_moved = false
			_drag_velocity = Vector2.ZERO
			cam.stop()
			_dragging_ghost = _ghost != null and _ghost_hit(e.position)
		elif _touches.size() == 2:
			_dragging_ghost = false
			_moved = true
			var p: Array = _touches.values()
			_pinch_dist = (p[0] as Vector2).distance_to(p[1])
		return
	if not _touches.has(e.index):
		return
	_touches.erase(e.index)
	if _touches.is_empty():
		if not _moved:
			_handle_tap(e.position)
		elif not _dragging_ghost:
			cam.fling(_drag_velocity)
		_dragging_ghost = false


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	var prev: Vector2 = _touches[e.index]
	_touches[e.index] = e.position
	if not _moved and _press_pos.distance_to(e.position) > TAP_THRESHOLD:
		_moved = true
	if _touches.size() >= 2:
		var p: Array = _touches.values()
		var a: Vector2 = p[0]
		var b: Vector2 = p[1]
		var dist := a.distance_to(b)
		if _pinch_dist > 0.0 and dist > 0.0:
			cam.zoom_at(_pinch_dist / dist, (a + b) / 2.0)
		_pinch_dist = dist
	elif _dragging_ghost:
		_move_ghost(_screen_cell(e.position) - _grab_offset)
	elif _moved:
		cam.pan(prev, e.position)
		_drag_velocity = e.velocity


func _screen_cell(pos: Vector2) -> Vector2i:
	var g := cam.screen_to_ground(pos)
	return Vector2i(floori(g.x), floori(g.z))


func _ghost_hit(pos: Vector2) -> bool:
	var cell := _screen_cell(pos)
	var r := Rect2i(_ghost.cell, _ghost.data.footprint).grow(1)
	if r.has_point(cell):
		_grab_offset = cell - _ghost.cell
		return true
	return false


func _handle_tap(pos: Vector2) -> void:
	var cell := _screen_cell(pos)
	if _ghost:
		_move_ghost(cell - _ghost.data.footprint / 2)
		return
	var b := GameState.city.building_at(cell)
	if b == null:
		if GameState.city.wild_at(cell) != "":
			harvest(cell)
			return
		deselect()
		return
	var n: BuildingNode = nodes.get(b.uid)
	# Une bulle de collecte visible : on récolte directement.
	if n and n._bubble.visible and selected_uid != b.uid:
		collect(b.uid)
		return
	select(b.uid)


# --- Sélection ----------------------------------------------------------------

func select(uid: int) -> void:
	if selected_uid == uid:
		return
	deselect()
	selected_uid = uid
	var n: BuildingNode = nodes.get(uid)
	if n:
		n.set_selected(true)
	hud.building_panel.show_building(uid)


func deselect() -> void:
	if selected_uid != 0 and nodes.has(selected_uid):
		nodes[selected_uid].set_selected(false)
	selected_uid = 0
	if hud:
		hud.building_panel.visible = false


func focus_temple() -> void:
	var t := _temple_state()
	if t:
		cam.focus_on(_world_center(t))
		select(t.uid)


# --- Placement ----------------------------------------------------------------

func start_new_building(d: BuildingData) -> void:
	cancel_placement()
	deselect()
	var center := _screen_cell(get_viewport().get_visible_rect().size / 2.0)
	var cell := _find_free_cell(center - d.footprint / 2, d.footprint, 0)
	if cell.x < 0:
		Events.toast_requested.emit("Plus aucune place libre dans la cité", "error")
		return
	_begin_placement(d, 1, cell, 0)


func start_move(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	deselect()
	_begin_placement(b.data(), maxi(b.level, 1), b.cell, uid)
	nodes[uid].visible = false


func _begin_placement(d: BuildingData, level: int, cell: Vector2i, moving_uid: int) -> void:
	_moving_uid = moving_uid
	_ghost = PlacementGhost.new()
	add_child(_ghost)
	_ghost.setup(d, level)
	_move_ghost(cell)
	_grid_overlay.visible = true
	hud.show_placement(d, moving_uid != 0)
	cam.focus_on(_ghost.position, 0.3)


func _move_ghost(cell: Vector2i) -> void:
	var r := GameState.config().buildable_rect
	var fp := _ghost.data.footprint
	cell.x = clampi(cell.x, r.position.x, r.end.x - fp.x)
	cell.y = clampi(cell.y, r.position.y, r.end.y - fp.y)
	var valid := GameState.city.is_area_free(cell, fp, _moving_uid)
	_ghost.set_cell(cell, valid)
	hud.set_placement_valid(valid)


func confirm_placement() -> void:
	if _ghost == null or not _ghost.valid:
		return
	var city := GameState.city
	if _moving_uid != 0:
		var b := city.get_building(_moving_uid)
		city.move(b, _ghost.cell)
		var n: BuildingNode = nodes[_moving_uid]
		n.visible = true
		n.refresh(GameClock.now())
		n.play_pop()
		_end_placement()
		GameState.save()
		return
	var d := _ghost.data
	var b := city.place_new(d, _ghost.cell, GameState.wallet, GameClock.now())
	if b == null:
		Events.toast_requested.emit(city.can_build_reason(d, GameState.wallet), "error")
		return
	_end_placement()
	Events.toast_requested.emit("Construction lancée : %s" % d.display_name, "success")
	GameState.save()


func cancel_placement() -> void:
	if _ghost == null:
		return
	if _moving_uid != 0 and nodes.has(_moving_uid):
		nodes[_moving_uid].visible = true
	_end_placement()


func _end_placement() -> void:
	if _ghost:
		_ghost.queue_free()
	_ghost = null
	_moving_uid = 0
	_dragging_ghost = false
	_grid_overlay.visible = false
	hud.hide_placement()


## Recherche en spirale de l'emplacement libre le plus proche.
func _find_free_cell(origin: Vector2i, fp: Vector2i, ignore_uid: int) -> Vector2i:
	var city := GameState.city
	for radius in range(0, 40):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var c := origin + Vector2i(dx, dy)
				if city.is_area_free(c, fp, ignore_uid):
					return c
	return Vector2i(-1, -1)


# --- Actions sur les bâtiments --------------------------------------------------

func collect(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	var res := b.data().produces
	var got := GameState.city.collect(b, GameState.wallet, GameClock.now())
	var n: BuildingNode = nodes.get(uid)
	if got > 0:
		var rt := DataRegistry.resource_type(res)
		if n:
			n.float_text("+%s" % Fmt.amount(got), rt.color.lightened(0.2))
			n.play_pop(1.05)
	elif b.stored_production(GameClock.now()) >= 1.0:
		Events.toast_requested.emit("Stockage plein : améliorez vos réserves !", "error")


const SCREENS := ["laboratory", "fusion_forge", "hero_sanctuary", "divine_altar", "monster_habitat"]


func has_screen(data_id: String) -> bool:
	return data_id in SCREENS


func open_building_screen(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	deselect()
	match b.data_id:
		"laboratory":
			hud.laboratory_screen.open_screen()
		"fusion_forge":
			hud.fusion_screen.open_screen()
		"hero_sanctuary":
			hud.summon_screen.open_for(false)
		"divine_altar":
			hud.summon_screen.open_for(true)
		"monster_habitat":
			hud.collection_screen.show_screen(1)


## Récolte manuelle d'une ressource sauvage.
func harvest(cell: Vector2i) -> void:
	deselect()
	var node := wild_view.node_at(cell)
	var origin := node.global_position if node else Vector3(cell.x + 0.5, 0, cell.y + 0.5)
	var kind_id := GameState.city.wild_at(cell)
	var got := GameState.city.harvest_wild(cell, GameState.wallet, GameState.config().premium_resource, GameClock.now())
	if got.is_empty():
		Events.toast_requested.emit("Réserves pleines : rien n'a pu être récolté", "error")
		return
	var i := 0
	for id in got:
		var rt := DataRegistry.resource_type(id)
		_float_at(origin + Vector3(0, 0.8 + i * 0.45, 0), "+%s %s" % [Fmt.amount(got[id]), rt.display_name], rt.color.lightened(0.25))
		i += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var kind := DataRegistry.wild(kind_id)
	if kind:
		var items := kind.roll_items(rng)
		for id in items:
			var rt := DataRegistry.resource_type(id)
			if rt:
				GameState.wallet.add(id, items[id])
				_float_at(origin + Vector3(0, 0.8 + i * 0.45, 0), "+%d %s" % [items[id], rt.display_name], rt.color.lightened(0.25))
			else:
				GameState.inventory.add(id, items[id])
				_float_at(origin + Vector3(0, 0.8 + i * 0.45, 0), "+%d %s" % [items[id], DataRegistry.ingredient(id).display_name], Color("9bffb0"))
			i += 1
	var bonus := GameState.collection.roll_wild_bonus(kind_id, rng, GameState.city)
	if bonus.has("fragments"):
		for hid in bonus.fragments:
			var h := DataRegistry.hero(hid)
			_float_at(origin + Vector3(0, 0.8 + i * 0.45, 0), "+%d fragments : %s" % [bonus.fragments[hid], h.display_name], Color("d8b4ff"))
		if bonus.unlocked != "":
			hud.collection_screen.announce_hero(bonus.unlocked)
	elif bonus.has("monster"):
		hud.collection_screen.announce_monster(bonus.monster)
	GameState.save()


func _float_at(pos: Vector3, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.font = BuildingNode.TITLE_FONT
	l.font_size = 52
	l.outline_size = 14
	l.outline_modulate = Color("1b1430")
	l.modulate = color
	l.pixel_size = 0.008
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 12
	l.outline_render_priority = 11
	l.text = text
	l.position = pos
	add_child(l)
	var t := l.create_tween().set_parallel()
	t.tween_property(l, "position:y", pos.y + 1.4, 1.3).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.8)
	t.chain().tween_callback(l.queue_free)


func start_feast() -> void:
	var reason := GameState.city.start_feast(GameState.wallet, GameClock.now(), GameState.config())
	if reason != "":
		Events.toast_requested.emit(reason, "error")
		return
	Events.toast_requested.emit("Festin ! Le bien-être de la cité augmente", "reward")
	GameState.save()


func change_workers(uid: int, delta: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	var city := GameState.city
	if delta > 0 and city.idle_inhabitants() == 0 and b.workers >= b.worker_target():
		Events.toast_requested.emit("Aucun habitant libre : agrandissez les logements", "error")
	city.set_desired_workers(b, b.workers + delta, GameClock.now())
	GameState.save()


func open_upgrade(uid: int) -> void:
	var city := GameState.city
	var b := city.get_building(uid)
	if b == null:
		return
	var d := b.data()
	var next := b.level + 1
	var reason := city.can_upgrade_reason(b, GameState.wallet)
	if b.level >= d.max_level:
		DialogBox.open(dialog_parent(), d.display_name, "Ce bâtiment a atteint son niveau maximal.")
		return
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.add_child(UiTheme.label("Niveau %d  →  %d" % [b.level, next], "HeaderLabel", 28))
	body.add_child(BuildingStats.comparison(d, b.level, next))
	if d.id == CityState.TEMPLE_ID:
		var unlocks: Array[String] = []
		for other in DataRegistry.all_buildings():
			if other.unlock_temple_level == next:
				unlocks.append(other.display_name)
		if not unlocks.is_empty():
			var l := UiTheme.label("Débloque : " + ", ".join(unlocks), "", 20, UiTheme.GOLD)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(l)
		body.add_child(UiTheme.label("Niveau maximal des autres bâtiments relevé.", "DimLabel", 18))
	var cost_row := HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 20)
	cost_row.add_child(UiTheme.cost_row(d.cost_for_level(next), GameState.wallet, 24))
	cost_row.add_child(UiTheme.icon_rect(preload("res://assets/icons/ui/clock.svg"), 28))
	cost_row.add_child(UiTheme.label(Fmt.duration(d.build_seconds_for_level(next)), "HudLabel", 24))
	body.add_child(cost_row)
	if reason != "":
		body.add_child(UiTheme.label(reason, "HudLabel", 22, UiTheme.RED))
	DialogBox.open(dialog_parent(), "Améliorer : " + d.display_name, body, [
		{"text": "Annuler", "variation": "SecondaryButton"},
		{"text": "Améliorer", "variation": "SuccessButton", "disabled": reason != "",
			"icon": preload("res://assets/icons/ui/upgrade.svg"), "action": func(): _do_upgrade(uid)},
	], 720)


func _do_upgrade(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	var reason := GameState.city.start_upgrade(b, GameState.wallet, GameClock.now())
	if reason != "":
		Events.toast_requested.emit(reason, "error")
		return
	Events.toast_requested.emit("Amélioration lancée", "success")
	GameState.save()


func speed_up(uid: int) -> void:
	var city := GameState.city
	var b := city.get_building(uid)
	if b == null or not b.is_busy():
		return
	var cfg := GameState.config()
	var cost := city.speedup_cost(b, GameClock.now(), cfg)
	if cost == 0:
		_do_speed_up(uid)
		return
	var prem := DataRegistry.resource_type(cfg.premium_resource)
	DialogBox.open(dialog_parent(), "Terminer maintenant ?",
		"Terminer immédiatement ce chantier pour [b]%d %s[/b] ?" % [cost, prem.display_name.to_lower()], [
		{"text": "Non", "variation": "SecondaryButton"},
		{"text": "%d" % cost, "variation": "PremiumButton", "icon": prem.icon, "action": func(): _do_speed_up(uid)},
	])


func _do_speed_up(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	if not GameState.city.speed_up(b, GameState.wallet, GameClock.now(), GameState.config()):
		Events.toast_requested.emit("Pas assez de prismes", "error")
		return
	GameState.save()


func confirm_cancel_task(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b == null or not b.is_busy():
		return
	var what := "la construction" if b.task == BuildingState.Task.CONSTRUCTING else "l'amélioration"
	DialogBox.open(dialog_parent(), "Annuler le chantier ?",
		"Annuler %s ? [b]%d %%[/b] des ressources dépensées seront remboursées." % [what, int(CityState.CANCEL_REFUND_RATIO * 100)], [
		{"text": "Non", "variation": "SecondaryButton"},
		{"text": "Annuler le chantier", "variation": "DangerButton", "action": func():
			var bs := GameState.city.get_building(uid)
			if bs:
				GameState.city.cancel_task(bs, GameState.wallet, GameClock.now())
				GameState.save()},
	])


# --- Événements ---------------------------------------------------------------

func _on_building_added(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	if b and not nodes.has(uid):
		_spawn(b).play_pop()


func _on_building_removed(uid: int) -> void:
	if selected_uid == uid:
		deselect()
	if nodes.has(uid):
		nodes[uid].queue_free()
		nodes.erase(uid)


func _on_building_changed(uid: int) -> void:
	if nodes.has(uid):
		nodes[uid].refresh(GameClock.now())


func _on_task_finished(uid: int) -> void:
	var b := GameState.city.get_building(uid)
	var n: BuildingNode = nodes.get(uid)
	if b == null or n == null:
		return
	n.refresh(GameClock.now())
	n.play_pop(1.15)
	n.float_text("Niveau %d !" % b.level, UiTheme.GOLD)
	Events.toast_requested.emit("%s : niveau %d terminé !" % [b.data().display_name, b.level], "reward")


func _show_story(chapter: StoryChapterData) -> void:
	var body := VBoxContainer.new()
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/branding/highvale_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 150)
	body.add_child(logo)
	var text := RichTextLabel.new()
	text.fit_content = true
	text.text = chapter.text
	text.add_theme_font_size_override("normal_font_size", 22)
	body.add_child(text)
	DialogBox.open(dialog_parent(), chapter.title, body, [{"text": "Continuer", "variation": "PrimaryButton"}], 760)
	GameState.save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()


## Bouton « retour » Android : ferme l'élément le plus haut.
func _handle_back() -> void:
	for c in hud.root.get_children():
		if c is DialogBox:
			c.close()
			return
	for s in [hud.laboratory_screen, hud.fusion_screen, hud.summon_screen]:
		if s.visible:
			s.close_screen()
			return
	if hud.collection_screen.visible:
		hud.collection_screen.back()
	elif hud.build_menu.visible:
		hud.build_menu.hide_menu()
	elif _ghost:
		cancel_placement()
	elif selected_uid != 0:
		deselect()
	else:
		SettingsPanel.open(hud.root, true)
