extends Node
## Enregistre la sortie audio réelle (bus Master) pendant le menu et un clic.

var rec := AudioEffectRecord.new()


func _ready() -> void:
	AudioServer.add_bus_effect(0, rec)
	rec.set_recording_active(true)
	AudioManager.play_music("music_menu")
	await get_tree().create_timer(3.0).timeout
	AudioManager.sfx("click")
	await get_tree().create_timer(1.0).timeout
	rec.set_recording_active(false)
	var s := rec.get_recording()
	var peak := 0.0
	if s:
		var d := s.data
		for i in range(0, d.size() - 1, 2):
			var v := absf(float(d.decode_s16(i)) / 32768.0)
			peak = maxf(peak, v)
		s.save_to_wav("user://probe.wav")
	print("AUDIO_PEAK=", peak, " bytes=", s.data.size() if s else 0, " music_bus_db=", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	get_tree().quit()
