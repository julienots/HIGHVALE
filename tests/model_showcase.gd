extends Node3D
## Vitrine des modèles : chaque bâtiment aux paliers 0 et 3 dans la caverne.
## xvfb-run godot --rendering-method gl_compatibility res://tests/model_showcase.tscn -- <dossier>

func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var env := CaveEnvironment.new()
	add_child(env)
	env.build(Vector2i(40, 40), Rect2i(3, 3, 34, 34))
	var all := DataRegistry.all_buildings()
	var only := OS.get_cmdline_user_args().slice(1)
	if not only.is_empty():
		all = all.filter(func(d): return d.id in only)
	for i in all.size():
		var d: BuildingData = all[i]
		var m := BuildingModels.build(d, 8)
		m.position = Vector3(6.0 + (i % 7) * 4.5, 0, 9.0 + (i / 7) * 5.0)
		add_child(m)
	var cam := CityCamera.new()
	add_child(cam)
	cam.position = Vector3(20, 0, 15)
	cam.camera.size = 17.0
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("showcase.png"))
	cam.camera.size = 7.0
	cam.position = Vector3(12, 0, 12) if only.is_empty() else Vector3(10, 0, 9)
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("showcase_zoom.png"))
	get_tree().quit()
