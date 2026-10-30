extends Node
## Système de sauvegarde (autoload « SaveSystem »).
## Écriture atomique (fichier temporaire puis renommage), copie de secours
## et migration de version pour ne jamais corrompre la progression du joueur.

const SAVE_PATH := "user://highvale_save.json"
const BACKUP_PATH := "user://highvale_save.bak.json"
const TEMP_PATH := "user://highvale_save.tmp.json"
const SAVE_VERSION := 1

## Permet aux tests d'utiliser un autre emplacement.
var save_path := SAVE_PATH
var backup_path := BACKUP_PATH
var temp_path := TEMP_PATH


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)


func save_game(data: Dictionary) -> bool:
	var envelope := {
		"version": SAVE_VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version", "0"),
		"saved_at": Time.get_unix_time_from_system(),
		"data": data,
	}
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem : écriture impossible (%s)" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(envelope))
	f.close()
	var dir := DirAccess.open("user://")
	if FileAccess.file_exists(save_path):
		dir.copy(save_path, backup_path)
	var err := dir.rename(temp_path, save_path)
	if err != OK:
		push_error("SaveSystem : renommage impossible (%s)" % error_string(err))
		return false
	return true


## Charge la partie. Retourne {} si aucune sauvegarde valide n'existe.
func load_game() -> Dictionary:
	for path in [save_path, backup_path]:
		var envelope := _read(path)
		if not envelope.is_empty():
			return _migrate(envelope).get("data", {})
	return {}


func delete_save() -> void:
	for path in [save_path, backup_path, temp_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		push_warning("SaveSystem : sauvegarde illisible %s" % path)
		return {}
	return parsed


## Convertit les anciennes versions de sauvegarde vers la version actuelle.
func _migrate(envelope: Dictionary) -> Dictionary:
	var v := int(envelope.get("version", 1))
	# Exemple pour les futures versions :
	# if v < 2:
	#     envelope.data["heroes"] = []
	#     v = 2
	envelope["version"] = v
	return envelope
