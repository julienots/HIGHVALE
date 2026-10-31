extends Node
## Captures rapides des écrans Missions, Boutique et Exploration.


func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	SaveSystem.save_path = "user://ui_tour.json"
	SaveSystem.backup_path = "user://ui_tour.bak.json"
	SaveSystem.temp_path = "user://ui_tour.tmp.json"
	SaveSystem.delete_save()
	await get_tree().process_frame
	GameState.start_or_load()
	GameState.quests.track("collect", 900)
	var now := GameClock.now()
	GameState.city.add_built("library", Vector2i(30, 30), 3, now)
	GameState.wallet.add("gold", 5000)
	GameState.city.research.levels["extraction"] = 2
	GameState.city.research.start("warehouses", GameState.city, GameState.wallet, now)
	GameState.collection.wound_hero("bram", now, 2)
	GameState.collection.wound_hero("lysa", now - 300, 2)
	var city: CityScene = load("res://scenes/city/city.tscn").instantiate()
	get_tree().root.add_child(city)
	await _frames(20)
	for c in city.hud.root.get_children():
		if c is DialogBox:
			c.close()
	for s in [["missions", city.hud.missions_screen], ["shop", city.hud.shop_screen], ["map", city.hud.exploration_screen], ["infirmary", city.hud.infirmary_screen], ["research", city.hud.research_screen]]:
		s[1].open_screen()
		await _frames(15)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("ui_%s.png" % s[0]))
		s[1].close_screen()
	SaveSystem.delete_save()
	print("UI_TOUR_OK")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
