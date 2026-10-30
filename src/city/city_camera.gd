class_name CityCamera
extends Node3D
## Caméra isométrique orthographique : déplacement au doigt avec inertie,
## zoom par pincement ou molette centré sur le point visé.

const PITCH := -40.0
const YAW := 45.0
const DISTANCE := 70.0

@export var min_zoom := 6.0
@export var max_zoom := 34.0

var camera: Camera3D
var zoom := 13.0
var bounds := Rect2(0, 0, 40, 40)
var _velocity := Vector3.ZERO
var _focus_tween: Tween


func _ready() -> void:
	rotation_degrees = Vector3(PITCH, YAW, 0)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.near = 1.0
	camera.far = 200.0
	camera.position = Vector3(0, 0, DISTANCE)
	add_child(camera)
	camera.make_current()


func _process(delta: float) -> void:
	if _velocity.length_squared() > 0.0001:
		_set_target(position + _velocity * delta)
		_velocity = _velocity.lerp(Vector3.ZERO, clampf(delta * 5.0, 0.0, 1.0))


## Point du sol (y = 0) sous une position écran.
func screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return origin
	return origin + dir * (-origin.y / dir.y)


func pan(from_screen: Vector2, to_screen: Vector2) -> void:
	_stop_focus()
	_set_target(position + screen_to_ground(from_screen) - screen_to_ground(to_screen))


## Lance l'inertie après un glissé (vitesse en pixels/seconde).
func fling(screen_velocity: Vector2) -> void:
	var center := get_viewport().get_visible_rect().size / 2.0
	_velocity = screen_to_ground(center) - screen_to_ground(center + screen_velocity)
	if _velocity.length() > 60.0:
		_velocity = _velocity.normalized() * 60.0


func stop() -> void:
	_velocity = Vector3.ZERO


func zoom_at(factor: float, screen_pos: Vector2) -> void:
	_stop_focus()
	var before := screen_to_ground(screen_pos)
	zoom = clampf(zoom * factor, min_zoom, max_zoom)
	camera.size = zoom
	_set_target(position + before - screen_to_ground(screen_pos))


func focus_on(point: Vector3, duration := 0.45) -> void:
	_stop_focus()
	stop()
	var dest := _clamped(Vector3(point.x, 0, point.z))
	_focus_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_property(self, "position", dest, duration)


func _stop_focus() -> void:
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()


func _set_target(p: Vector3) -> void:
	position = _clamped(p)


func _clamped(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, bounds.position.x, bounds.end.x), 0, clampf(p.z, bounds.position.y, bounds.end.y))
