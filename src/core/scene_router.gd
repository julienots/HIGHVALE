extends CanvasLayer
## Navigation entre écrans avec fondu (autoload « SceneRouter »).

const SPLASH := "res://scenes/boot/splash.tscn"
const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const CITY := "res://scenes/city/city.tscn"
const BATTLE := "res://scenes/combat/battle.tscn"
const RAID := "res://scenes/raid/raid.tscn"

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func go_to(path: String, fade_time := 0.35) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, fade_time)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, fade_time)
	await t.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
