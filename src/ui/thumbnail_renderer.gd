class_name ThumbnailRenderer
extends SubViewport
## Rend les modèles 3D des bâtiments en vignettes pour les menus (mises en cache).

signal thumbnail_ready(id: String, texture: Texture2D)

static var _cache := {}

var _queue: Array[BuildingData] = []
var _busy := false
var _stage: Node3D
var _camera: Camera3D


func _ready() -> void:
	size = Vector2i(256, 256)
	transparent_bg = true
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8a9ad0")
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.3
	add_child(sun)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.rotation_degrees = Vector3(CityCamera.PITCH, CityCamera.YAW, 0)
	add_child(_camera)
	_stage = Node3D.new()
	add_child(_stage)


static func cached(id: String) -> Texture2D:
	return _cache.get(id)


func request(d: BuildingData) -> void:
	if _cache.has(d.id) or d in _queue:
		return
	_queue.append(d)
	if not _busy:
		_process_queue()


func _process_queue() -> void:
	_busy = true
	while not _queue.is_empty():
		var d: BuildingData = _queue.pop_front()
		for c in _stage.get_children():
			c.queue_free()
		_stage.add_child(BuildingModels.build(d, 1))
		var extent := maxf(d.footprint.x, d.footprint.y)
		_camera.size = extent * 1.45 + 0.8
		_camera.position = Vector3(0, extent * 0.32, 0) + _camera.global_transform.basis.z * 40.0
		render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if not is_inside_tree():
			return
		var img := get_texture().get_image()
		if img and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_cache[d.id] = tex
			thumbnail_ready.emit(d.id, tex)
	_busy = false
