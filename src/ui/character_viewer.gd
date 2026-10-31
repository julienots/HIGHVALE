class_name CharacterViewer
extends SubViewportContainer
## Vitrine 3D d'un héros ou d'une créature : socle lumineux et rotation lente.
## Glisser horizontalement fait tourner le personnage.

var _viewport: SubViewport
var _pivot: Node3D
var _rig: CharacterRig
var _camera: Camera3D
var _drag := false
var _time := 0.0
var _user_yaw := 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9aa8e0")
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_viewport.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_energy = 1.4
	_viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_energy = 0.9
	rim.light_color = Color("9ad8ff")
	_viewport.add_child(rim)
	_camera = Camera3D.new()
	_camera.fov = 30
	_viewport.add_child(_camera)
	# Socle
	var base := Node3D.new()
	_viewport.add_child(base)
	MeshKit.part(base, MeshKit.cylinder(0.32, 0.05, 0.36, 32), MeshKit.mat(Color("2b3760"), 0.6), Vector3(0, -0.05, 0))
	MeshKit.part(base, MeshKit.torus(0.33, 0.35), MeshKit.glow_mat(Color("ffc531"), 1.6), Vector3(0, -0.002, 0))
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)


func show_character(scene: PackedScene, accent: Color) -> void:
	if _rig:
		_rig.queue_free()
	_rig = CharacterRig.new()
	_pivot.add_child(_rig)
	_rig.setup(scene)
	# Taille normalisée : tous les personnages occupent la même hauteur à l'écran.
	_rig.scale = Vector3.ONE * (0.6 / maxf(BuildingNode.model_height(_rig), 0.1))
	_pivot.rotation.y = 0.0
	_user_yaw = 0.0
	_time = 0.0
	_camera.position = Vector3(0, 0.45, 1.95)
	_camera.look_at(Vector3(0, 0.3, 0))
	var glow: MeshInstance3D = _viewport.get_child(_viewport.get_child_count() - 2).get_child(1)
	glow.material_override = MeshKit.glow_mat(accent, 1.8)


## Léger balancement face à la caméra ; le joueur peut tourner le personnage au doigt.
func _process(delta: float) -> void:
	_time += delta
	if _pivot and not _drag:
		_user_yaw = lerpf(_user_yaw, 0.0, clampf(delta * 1.5, 0.0, 1.0))
		_pivot.rotation.y = _user_yaw + sin(_time * 0.7) * 0.45


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_drag = event.pressed
	elif event is InputEventMouseMotion and _drag:
		_user_yaw += event.relative.x * 0.012
		_pivot.rotation.y = _user_yaw
