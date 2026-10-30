extends TestCase

var _paths := []


func _use_temp_paths() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.backup_path = "user://test_save.bak.json"
	SaveSystem.temp_path = "user://test_save.tmp.json"
	SaveSystem.delete_save()


func after_each() -> void:
	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	SaveSystem.backup_path = SaveSystem.BACKUP_PATH
	SaveSystem.temp_path = SaveSystem.TEMP_PATH


func test_save_and_load() -> void:
	_use_temp_paths()
	check(not SaveSystem.has_save(), "aucune sauvegarde au départ")
	check(SaveSystem.save_game({"hello": 1}), "écriture")
	eq(SaveSystem.load_game(), {"hello": 1.0}, "relecture")


func test_backup_used_when_main_corrupted() -> void:
	_use_temp_paths()
	SaveSystem.save_game({"v": 1})
	SaveSystem.save_game({"v": 2})
	var f := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	f.store_string("{corrompu")
	f.close()
	eq(SaveSystem.load_game(), {"v": 1.0}, "repli sur la copie de secours")
