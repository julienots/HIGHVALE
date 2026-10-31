class_name Inventory
extends RefCounted
## Inventaire d'objets empilables (ingrédients, matériaux…).

signal changed

var _counts := {}


func count(id: String) -> int:
	return _counts.get(id, 0)


func add(id: String, n := 1) -> void:
	if n <= 0:
		return
	_counts[id] = count(id) + n
	changed.emit()


func remove(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	_counts[id] = count(id) - n
	if _counts[id] == 0:
		_counts.erase(id)
	changed.emit()
	return true


func ids() -> Array:
	return _counts.keys()


func to_dict() -> Dictionary:
	return _counts.duplicate()


func from_dict(d: Dictionary) -> void:
	_counts.clear()
	for k in d:
		if int(d[k]) > 0:
			_counts[str(k)] = int(d[k])
