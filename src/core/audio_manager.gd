extends Node
## Musiques, ambiance et effets sonores (autoload « AudioManager »).
## Canaux « Music », « Ambience » et « SFX » réglables dans les paramètres.
## Les écrans (boutique, laboratoire, carte…) empilent leur musique et la
## musique précédente reprend à leur fermeture.

const DIR := "res://assets/audio/"
const POOL := 14
## Son joué par élément de compétence (GameEnums.Element).
const ELEMENT_SFX := ["slash", "fire", "water", "earth", "wind", "nature", "ice", "light", "shadow", "void"]
const AMBIENCE_DB := -9.0

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _current := ""
var _stack: Array[String] = []
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last_play := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	add_child(_ambience)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	Events.settings_changed.connect(apply_volumes)
	apply_volumes()


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(Settings.music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(Settings.music_volume, 0.0001)) + AMBIENCE_DB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))


func _stream(name: String) -> AudioStream:
	if not _cache.has(name):
		var path := DIR + name + ".ogg"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


func has_sound(name: String) -> bool:
	return _stream(name) != null


## Musique en boucle avec fondu enchaîné.
func play_music(name: String, fade := 0.8) -> void:
	_stack.clear()
	_switch(name, fade)


## Musique d'un écran par-dessus la musique en cours (rétablie par pop_music).
func push_music(name: String, fade := 0.6) -> void:
	if name == "" or name == _current:
		_stack.append(_current)
		return
	_stack.append(_current)
	_switch(name, fade)


func pop_music(fade := 0.6) -> void:
	if _stack.is_empty():
		return
	var prev: String = _stack.pop_back()
	if prev != _current and prev != "":
		_switch(prev, fade)


func current_music() -> String:
	return _current


func _switch(name: String, fade: float) -> void:
	if name == _current:
		return
	_current = name
	var stream := _stream(name)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
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
	_stack.clear()
	var t := create_tween()
	t.tween_property(_music, "volume_db", -40.0, fade)
	t.tween_callback(_music.stop)


## Ambiance sonore continue (vent, gouttes dans la caverne).
func play_ambience(name: String) -> void:
	var stream := _stream(name)
	if stream == null or _ambience.stream == stream and _ambience.playing:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_ambience.stream = stream
	_ambience.volume_db = -30.0
	_ambience.play()
	create_tween().tween_property(_ambience, "volume_db", 0.0, 2.0)


func stop_ambience(fade := 1.0) -> void:
	if not _ambience.playing:
		return
	var t := create_tween()
	t.tween_property(_ambience, "volume_db", -40.0, fade)
	t.tween_callback(_ambience.stop)


## Effet sonore ; légère variation de hauteur pour éviter la monotonie.
## Un même son n'est pas rejoué plus d'une fois toutes les 40 ms.
func sfx(name: String, pitch_var := 0.06, volume_db := 0.0) -> void:
	var key := name if name.begins_with("jingle") else "sfx_" + name
	var stream := _stream(key)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(key, -1000)) < 40:
		return
	_last_play[key] = now
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = volume_db
	p.play()


## Son d'une compétence selon son élément.
func element(element_id: int, volume_db := 0.0) -> void:
	sfx(ELEMENT_SFX[clampi(element_id, 0, ELEMENT_SFX.size() - 1)], 0.05, volume_db)


## Jingle de révélation selon la rareté (0 = Commun … 3 = Légendaire et plus).
func reveal(rarity: int) -> void:
	sfx("jingle_reveal_%d" % clampi(rarity, 0, 3), 0.0)
