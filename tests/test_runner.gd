extends Node
## Lanceur de tests : godot --headless res://tests/test_runner.tscn
## Exécute toutes les méthodes test_* des scripts test_*.gd et quitte avec
## le code 0 (succès) ou 1 (échec).

const SUITES := [
	"res://tests/test_scripts_compile.gd",
	"res://tests/test_data.gd",
	"res://tests/test_wallet.gd",
	"res://tests/test_city_state.gd",
	"res://tests/test_save_system.gd",
	"res://tests/test_models.gd",
	"res://tests/test_collection.gd",
	"res://tests/test_lab_fusion_summon.gd",
]


func _ready() -> void:
	var failures := 0
	var total := 0
	for path in SUITES:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			failures += 1
			total += 1
			print("  FAIL %s : script invalide" % path)
			continue
		var suite: TestCase = script.new()
		suite.tree = get_tree()
		for m in suite.get_method_list():
			var test_name: String = m.name
			if not test_name.begins_with("test_"):
				continue
			total += 1
			suite.errors.clear()
			suite.call(test_name)
			if suite.has_method("after_each"):
				suite.call("after_each")
			if suite.errors.is_empty():
				print("  ok   %s::%s" % [path.get_file(), test_name])
			else:
				failures += 1
				print("  FAIL %s::%s" % [path.get_file(), test_name])
				for e in suite.errors:
					print("         - " + e)
	print("\n%d test(s), %d échec(s)" % [total, failures])
	get_tree().quit(1 if failures > 0 else 0)
