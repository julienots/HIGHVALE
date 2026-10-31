extends Node
## Musiques et effets sonores (autoload « AudioManager »).
## Canaux « Music » et « SFX » réglables dans les paramètres.

const DIR := "res://assets/audio/"
const POOL := 10

var _music: AudioStreamPlayer
var _current := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	Events.settings_changed.connect(apply_volumes)
	apply_volumes()


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(Settings.music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))


func _stream(name: String) -> AudioStream:
	if not _cache.has(name):
		_cache[name] = load(DIR + name + ".ogg")
	return _cache[name]


## Musique en boucle avec fondu.
func play_music(name: String, fade := 0.8) -> void:
	if name == _current:
		return
	_current = name
	var stream := _stream(name)
	if stream is AudioStreamOggVorbis:
		stream.loop = name.begins_with("music")
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	t.tween_callback(func():
		_music.stream = stream
		_music.volume_db = -40.0
		_music.play())
	t.tween_property(_music, "volume_db", 0.0, fade)


func stop_music(fade := 0.6) -> void:
	_current = ""
	var t := create_tween()
	t.tween_property(_music, "volume_db", -40.0, fade)
	t.tween_callback(_music.stop)


## Effet sonore, légère variation de hauteur pour éviter la monotonie.
func sfx(name: String, pitch_var := 0.06, volume_db := 0.0) -> void:
	var stream := _stream("sfx_" + name if not name.begins_with("jingle") else name)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = volume_db
	p.play()
