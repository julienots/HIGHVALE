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
	for s in [["missions", city.hud.missions_screen], ["shop", city.hud.shop_screen], ["map", city.hud.exploration_screen], ["infirmary", city.hud.infirmary_screen], ["research", city.hud.research_screen], ["arena", city.hud.arena_screen]]:
		s[1].open_screen()
		await _frames(15)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("ui_%s.png" % s[0]))
		s[1].close_screen()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_hud.png"))
	GameState.wallet.add("prisms", 2000)
	var shop: ShopScreen = city.hud.shop_screen
	shop.open_screen()
	for tab in [2, 4]:
		shop._tab = tab
		shop.refresh()
		await _frames(10)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("ui_shop_%d.png" % tab))
	var chest_icon: Texture2D = load(ShopState.CHESTS["legend_chest"][3])
	var ov := RewardOverlay.play(city.hud.root, chest_icon, "Coffre légendaire", {"Fragments de Noctis": 50, "Lame runique": 1}, 3)
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_chest_open.png"))
	ov.queue_free()
	shop.close_screen()
	for id in ["noctis", "aegis", "seren", "malakar", "verdant", "leo", "magnus", "zircon", "vesper", "hilda", "kraken", "lilith"]:
		GameState.collection.unlock_hero(id)
	city.hud.collection_screen.show_screen(0)
	await _frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_collection.png"))
	for id in ["gold_dragon", "unicorn", "pegasus", "behemoth", "shadow_wyrm", "sea_dragon", "frost_drake", "king_shroom", "cobra_king", "griffin", "banshee", "royal_jelly"]:
		GameState.collection.add_monster(id)
	city.hud.collection_screen.show_screen(1)
	await _frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_creatures.png"))
	city.queue_free()
	await _frames(2)
	var menu: Node = load("res://scenes/menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _frames(40)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_menu.png"))
	SaveSystem.delete_save()
	print("UI_TOUR_OK")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
