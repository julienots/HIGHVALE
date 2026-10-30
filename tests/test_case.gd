class_name TestCase
extends RefCounted
## Base minimale des suites de tests.

var errors: Array[String] = []
var tree: SceneTree


func check(cond: bool, msg: String) -> void:
	if not cond:
		errors.append(msg)


func eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		errors.append("%s (obtenu %s, attendu %s)" % [msg, str(actual), str(expected)])


## Cité vierge configurée comme une vraie partie, sans bâtiment.
func new_city() -> CityState:
	var c := CityState.new()
	c.configure(DataRegistry.config)
	return c


func new_wallet(city: CityState, amounts := {}) -> Wallet:
	var w := Wallet.new()
	w.capacity_provider = city.storage_capacity
	for id in amounts:
		w.set_amount(id, amounts[id])
	return w
