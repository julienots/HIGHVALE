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
	# Arène de la surface
	scene.queue_free()
	await _frames(2)
	GameState.pending_zone = "renewal_plains"
	GameState.pending_stage = 2
	GameState.collection.team.clear()
	for id in ["sol", "aria", "luma", "orin", "draven"]:
		GameState.collection.unlock_hero(id)
		GameState.collection.toggle_team("h", id)
	var surf: BattleScene = load("res://scenes/combat/battle.tscn").instantiate()
	get_tree().root.add_child(surf)
	surf.auto = true
	await _frames(120)
	await _shot("b5_surface")
	print("BATTLE_DONE winner=", surf.battle.winner, " rounds=", surf.battle.round)
	SaveSystem.delete_save()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
