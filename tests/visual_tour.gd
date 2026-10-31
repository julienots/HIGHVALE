extends Node
## Visite automatique de l'interface avec captures d'écran (vérification visuelle).
## xvfb-run godot --rendering-method gl_compatibility res://tests/visual_tour.tscn -- <dossier>

var out_dir := "user://tour"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveSystem.save_path = "user://tour_save.json"
	SaveSystem.backup_path = "user://tour_save.bak.json"
	SaveSystem.temp_path = "user://tour_save.tmp.json"
	SaveSystem.delete_save()
	await _run()
	SaveSystem.delete_save()
	get_tree().quit()


func _run() -> void:
	await _frames(1)
	GameState.start_or_load()
	var menu: Node = load("res://scenes/menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _frames(40)
	await _shot("01_main_menu")
	menu.queue_free()
	await _frames(2)

	var city: CityScene = load("res://scenes/city/city.tscn").instantiate()
	get_tree().root.add_child(city)
	await _frames(30)
	await _shot("02_city_intro_story")
	for c in city.hud.root.get_children():
		if c is DialogBox:
			c.close()
	await _frames(10)
	await _shot("03_city")

	# Sélection du Temple
	city.focus_temple()
	await _frames(40)
	await _shot("04_temple_selected")
	city.open_upgrade(city.selected_uid)
	await _frames(20)
	await _shot("05_upgrade_dialog")
	for c in city.hud.root.get_children():
		if c is DialogBox:
			c.close()
	city.deselect()

	# Menu de construction
	city.hud.build_menu.show_menu()
	await _frames(60)
	await _shot("06_build_menu")
	city.hud.build_menu.hide_menu()

	# Placement d'une Trésorerie puis construction
	city.start_new_building(DataRegistry.building("treasury"))
	await _frames(30)
	await _shot("07_placement")
	city.confirm_placement()
	await _frames(20)
	await _shot("08_construction")

	# Production : avance le temps pour faire apparaître les bulles de collecte
	GameClock.skip(1800)
	await _frames(20)
	city.cam.zoom_at(1.4, get_viewport().get_visible_rect().size / 2.0)
	await _frames(20)
	await _shot("09_bubbles_zoomed_out")
	for b in GameState.city.buildings.values():
		if b.data_id == "stone_mine":
			city.collect(b.uid)
			city.select(b.uid)
	await _frames(15)
	await _shot("10_collect_and_panel")
	city.deselect()
	# Habitants : gros plan après quelques secondes de vie
	city.cam.zoom = 6.5
	city.cam.camera.size = 6.5
	city.cam.position = Vector3(21, 0, 22)
	await _frames(240)
	await _shot("10b_villagers")
	print("habitants visibles : ", city.population.villagers.size())
	city.cam.zoom = 13.0
	city.cam.camera.size = 13.0
	city.deselect()
	# Collection
	city.hud.collection_screen.show_screen(0)
	await _frames(20)
	await _shot("12_collection_heroes")
	city.hud.collection_screen.open_detail("h:bram")
	await _frames(40)
	await _shot("13_hero_detail")
	city.hud.collection_screen.open_detail("h:seraphine")
	await _frames(40)
	await _shot("13b_hero_locked")
	city.hud.collection_screen.show_screen(1)
	await _frames(20)
	await _shot("14_collection_monsters")
	var uid: int = GameState.collection.monsters.keys()[0]
	city.hud.collection_screen.open_detail("m:%d" % uid)
	await _frames(40)
	await _shot("15_monster_detail")
	city.hud.collection_screen.visible = false
	city.hud.collection_screen.announce_monster("dragonling")
	await _frames(20)
	await _shot("16_announce")
	for c in city.hud.root.get_children():
		if c is DialogBox:
			c.close()
	# Laboratoire, Fusionnerie, invocations (bâtiments accordés pour la visite)
	for id in ["laboratory", "fusion_forge", "hero_sanctuary", "divine_altar"]:
		var d := DataRegistry.building(id)
		GameState.city.add_built(id, city._find_free_cell(Vector2i(8, 8), d.footprint, 0), 1, GameClock.now())
	for id in ["gold", "vital_essence", "prisms", "divine_dust", "ancient_shards"]:
		GameState.wallet.set_amount(id, 5000)
	GameState.inventory.add("magma_core", 1)
	GameState.inventory.add("ember_stone", 2)
	var lab: LaboratoryScreen = city.hud.laboratory_screen
	lab.open_screen()
	lab._slots = ["ember_stone", "magma_core"]
	lab.refresh()
	await _frames(30)
	await _shot("17_laboratory")
	lab._start()
	await _frames(30)
	await _shot("18_lab_running")
	GameState.lab.experiment.end = GameClock.now()
	lab.refresh()
	lab._claim()
	await _frames(12)
	await _shot("19_reveal_charge")
	await _frames(90)
	await _shot("20_reveal")
	for c in lab.get_children():
		if c is RevealOverlay:
			c.queue_free()
	lab.close_screen()
	var fus: FusionScreen = city.hud.fusion_screen
	fus.open_screen()
	fus._picked = GameState.collection.monsters.keys().slice(0, 2)
	fus.refresh()
	await _frames(20)
	await _shot("21_fusion")
	fus.close_screen()
	var sum: SummonScreen = city.hud.summon_screen
	sum.open_for(false)
	sum._banner = DataRegistry.banner("advanced")
	sum.refresh()
	await _frames(20)
	await _shot("22_summon")
	sum.open_for(true)
	await _frames(20)
	await _shot("23_altar")
	sum._summon()
	await _frames(140)
	await _shot("24_divine_reveal")
	for c in sum.get_children():
		if c is RevealOverlay:
			c.queue_free()
	sum.close_screen()
	SettingsPanel.open(city.hud.root, true)
	await _frames(15)
	await _shot("11_settings")
	for c in city.hud.root.get_children():
		if c is DialogBox:
			c.close()
	await _frames(5)
	await _input_checks(city)
	print("TOUR_OK")


## Vérifie le vrai chemin des entrées tactiles (événements injectés dans Input).
func _input_checks(city: CityScene) -> void:
	var grove: BuildingState
	for b in GameState.city.buildings.values():
		if b.data_id == "fungal_grove":
			grove = b
	GameClock.skip(1800)
	await _frames(5)
	var wood_before := GameState.wallet.amount("fungal_wood")
	await _tap(city.cam.camera.unproject_position(city.nodes[grove.uid].global_position))
	_expect(GameState.wallet.amount("fungal_wood") > wood_before, "toucher une bulle collecte la production")
	await _tap(city.cam.camera.unproject_position(city.nodes[grove.uid].global_position))
	_expect(city.selected_uid == grove.uid, "toucher un bâtiment le sélectionne")
	var cam_before := city.cam.position
	await _drag(Vector2(640, 300), Vector2(400, 300))
	_expect(city.cam.position.distance_to(cam_before) > 1.0, "glisser déplace la caméra")
	city.deselect()
	await _frames(5)
	var build_btn: Button = city.hud._build_button
	await _tap(build_btn.get_global_rect().get_center())
	_expect(city.hud.build_menu.visible, "le bouton Construire ouvre le menu")
	_expect(city.selected_uid == 0, "un toucher sur l'interface n'atteint pas la cité")
	city.hud.build_menu.hide_menu()


func _expect(cond: bool, what: String) -> void:
	print(("INPUT_OK   " if cond else "INPUT_FAIL ") + what)


func _tap(pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var r := InputEventScreenTouch.new()
	r.position = pos
	r.pressed = false
	Input.parse_input_event(r)
	await _frames(4)


func _drag(from: Vector2, to: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.position = from
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(1)
	for i in range(1, 11):
		var d := InputEventScreenDrag.new()
		d.position = from.lerp(to, i / 10.0)
		d.relative = (to - from) / 10.0
		Input.parse_input_event(d)
		await _frames(1)
	var r := InputEventScreenTouch.new()
	r.position = to
	r.pressed = false
	Input.parse_input_event(r)
	await _frames(4)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("capture ", name)
