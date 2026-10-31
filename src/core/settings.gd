extends Node
## Paramètres utilisateur (autoload « Settings »), persistés hors sauvegarde de partie.

const PATH := "user://settings.cfg"

var shadows_enabled := true
var show_fps := false
var max_fps := 60
var music_volume := 0.7
var sfx_volume := 0.9
## 0 bas, 1 moyen, 2 élevé : ombres, lueur, résolution 3D et particules.
var quality := 1


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
	quality = cfg.get_value("graphics", "quality", quality)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "shadows", shadows_enabled)
	cfg.set_value("graphics", "show_fps", show_fps)
	cfg.set_value("graphics", "max_fps", max_fps)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(PATH)


func apply() -> void:
	Engine.max_fps = max_fps
	# Résolution 3D réduite sur les réglages modestes : gros gain sur téléphone.
	get_tree().root.scaling_3d_scale = [0.7, 0.85, 1.0][quality]
	Events.settings_changed.emit()


func glow_enabled() -> bool:
	return quality >= 1


func particle_factor() -> float:
	return [0.4, 0.75, 1.0][quality]


func set_value(key: String, value: Variant) -> void:
	set(key, value)
	save_settings()
	apply()
