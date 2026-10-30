extends Node
## Paramètres utilisateur (autoload « Settings »), persistés hors sauvegarde de partie.

const PATH := "user://settings.cfg"

var shadows_enabled := true
var show_fps := false
var max_fps := 60


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	shadows_enabled = cfg.get_value("graphics", "shadows", shadows_enabled)
	show_fps = cfg.get_value("graphics", "show_fps", show_fps)
	max_fps = cfg.get_value("graphics", "max_fps", max_fps)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "shadows", shadows_enabled)
	cfg.set_value("graphics", "show_fps", show_fps)
	cfg.set_value("graphics", "max_fps", max_fps)
	cfg.save(PATH)


func apply() -> void:
	Engine.max_fps = max_fps
	Events.settings_changed.emit()


func set_value(key: String, value: Variant) -> void:
	set(key, value)
	save_settings()
	apply()
