extends Node
## Mesure des performances de rendu (appels, objets, triangles) dans la cité et en combat.


func _ready() -> void:
	SaveSystem.save_path = "user://perf.json"
	SaveSystem.backup_path = "user://perf.bak.json"
	SaveSystem.temp_path = "user://perf.tmp.json"
	SaveSystem.delete_save()
	await get_tree().process_frame
	GameState.start_or_load()
	for scene_path in ["res://scenes/city/city.tscn", "res://scenes/combat/battle.tscn"]:
		var s: Node = load(scene_path).instantiate()
		get_tree().root.add_child(s)
		for i in 90:
			await get_tree().process_frame
		print("PERF %s : appels de rendu %d, objets %d, triangles %d, mémoire vidéo %.0f Mo" % [scene_path.get_file(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		if OS.get_cmdline_user_args().size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("perf_%s.png" % scene_path.get_file().get_basename()))
		s.queue_free()
		await get_tree().process_frame
	SaveSystem.delete_save()
	get_tree().quit()
