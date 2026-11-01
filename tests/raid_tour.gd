extends Node
## Visite d'un assaut et d'une défense avec captures (vérification visuelle).

var out_dir := "user://tour"


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out_dir = OS.get_cmdline_user_args()[0]
	SaveSystem.save_path = "user://raid_tour.json"
	SaveSystem.backup_path = "user://raid_tour.bak.json"
	SaveSystem.temp_path = "user://raid_tour.tmp.json"
	SaveSystem.delete_save()
	await get_tree().process_frame
	GameState.start_or_load()
	var coll := GameState.collection
	for id in ["noctis", "aegis", "magnus", "seren", "leo"]:
		coll.unlock_hero(id)
		coll.heroes[id].level = 25
	coll.add_monster("storm_eagle", 15)
	coll.add_monster("plains_wolf", 15)
	coll.default_team()
	GameState.pending_raid = {"mode": "attack", "seed": 77, "base": RaidBaseGen.generate(4, 77)}
	print("TOUR: chargement de la scène")
	var t0 := Time.get_ticks_msec()
	var scene: RaidScene = load("res://scenes/raid/raid.tscn").instantiate()
	get_tree().root.add_child(scene)
	print("TOUR: scène prête en %d ms" % (Time.get_ticks_msec() - t0))
	await _frames(30)
	await _shot("r1_start")
	scene._select(0)
	await _frames(5)
	await _shot("r2_select")
	scene._select(0)
	var t := 0.0
	var shots := 0
	while t < 40.0 and not scene.sim.is_over():
		if int(t * 2) % 6 == 0:
			scene.sim.elixir = 10.0
			for slot in 4:
				scene.sim.deploy(slot, Vector2i(1 + slot * 2, 2 + (int(t) % 18)))
		await _frames(1)
		t += get_process_delta_time()
		if t > 6.0 + shots * 10.0:
			await _shot("r3_action_%d" % shots)
			shots += 1
	print("RAID destruction=", scene.sim.destruction(), " stars=", scene.sim.stars())
	scene.sim.surrender()
	await get_tree().create_timer(2.0).timeout
	await _shot("r4_end")
	scene.queue_free()
	await _frames(2)
	GameState.city.add_built("archer_tower", Vector2i(14, 22), 3, GameClock.now())
	GameState.city.add_built("cannon", Vector2i(22, 22), 3, GameClock.now())
	for x in range(12, 28):
		GameState.city.add_built("wall", Vector2i(x, 26), 2, GameClock.now())
	GameState.pending_raid = {"mode": "defense", "seed": 5}
	var d: RaidScene = load("res://scenes/raid/raid.tscn").instantiate()
	get_tree().root.add_child(d)
	await _frames(20)
	d.sim.elixir = 10.0
	d.sim.deploy(0, Vector2i(19, 24))
	await get_tree().create_timer(8.0).timeout
	await _shot("r5_defense")
	print("RAID_TOUR_OK")
	SaveSystem.delete_save()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	print("TOUR: capture ", name, " à ", Time.get_ticks_msec())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
