extends TestCase
## Vérifie que tous les scripts du projet se chargent sans erreur.


func test_all_scripts_load() -> void:
	var scripts := _find("res://src", [])
	check(scripts.size() > 20, "trop peu de scripts trouvés")
	for path in scripts:
		var s: Script = load(path)
		check(s != null and s.can_instantiate() or (s != null and s.is_abstract()), "script invalide : " + path)


func test_scenes_load() -> void:
	for path in ["res://scenes/boot/splash.tscn", "res://scenes/menu/main_menu.tscn", "res://scenes/city/city.tscn"]:
		var p: PackedScene = load(path)
		check(p != null and p.can_instantiate(), "scène invalide : " + path)


func _find(dir_path: String, out: Array) -> Array:
	var dir := DirAccess.open(dir_path)
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		_find(dir_path.path_join(d), out)
	return out
