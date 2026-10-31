extends Node
## Visite d'un combat automatique avec captures (vérification visuelle).

var out_dir := "user://tour"


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out_dir = OS.get_cmdline_user_args()[0]
	SaveSystem.save_path = "user://battle_tour.json"
	SaveSystem.backup_path = "user://battle_tour.bak.json"
	SaveSystem.temp_path = "user://battle_tour.tmp.json"
	SaveSystem.delete_save()
	await get_tree().process_frame
	GameState.start_or_load()
	GameState.collection.unlock_hero("kael")
	GameState.collection.toggle_team("h", "kael")
	GameState.pending_encounter = "forgotten_forge"
	var scene: BattleScene = load("res://scenes/combat/battle.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(40)
	await _shot("b1_start")
	scene.auto = true
	Engine.time_scale = 2.0
	await _frames(60)
	await _shot("b2_action")
	var guard := 0
	while not scene.battle.is_over() and guard < 3000:
		guard += 1
		await get_tree().process_frame
		if guard % 400 == 0:
			await _shot("b3_mid_%d" % guard)
	await _frames(40)
	await _shot("b4_end")
	print("BATTLE_DONE winner=", scene.battle.winner, " rounds=", scene.battle.round)
	SaveSystem.delete_save()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
