class_name Wallet
extends RefCounted
## Portefeuille de ressources du joueur. Les capacités sont fournies par la cité.

signal changed(resource_id: String, amount: int)

const UNLIMITED := -1

var _amounts := {}  # String -> int
## Callable(resource_id: String) -> int ; UNLIMITED si pas de plafond.
var capacity_provider := Callable()


func amount(id: String) -> int:
	return _amounts.get(id, 0)


func capacity(id: String) -> int:
	if capacity_provider.is_valid():
		return capacity_provider.call(id)
	return UNLIMITED


func free_space(id: String) -> int:
	var cap := capacity(id)
	if cap == UNLIMITED:
		return 1 << 40
	return maxi(cap - amount(id), 0)


## Ajoute dans la limite de la capacité. Retourne la quantité réellement ajoutée.
func add(id: String, qty: int) -> int:
	if qty <= 0:
		return 0
	var added := mini(qty, free_space(id))
	if added > 0:
		_amounts[id] = amount(id) + added
		changed.emit(id, _amounts[id])
	return added


func can_afford(cost: Dictionary) -> bool:
	return missing(cost).is_empty()


## Ressources manquantes pour payer un coût : { id: quantité manquante }.
func missing(cost: Dictionary) -> Dictionary:
	var m := {}
	for id in cost:
		var need: int = cost[id] - amount(id)
		if need > 0:
			m[id] = need
	return m


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for id in cost:
		if cost[id] <= 0:
			continue
		_amounts[id] = amount(id) - cost[id]
		changed.emit(id, _amounts[id])
	return true


## Remboursement : ignore la capacité pour ne jamais perdre une ressource payée.
func refund(cost: Dictionary) -> void:
	for id in cost:
		_amounts[id] = amount(id) + cost[id]
		changed.emit(id, _amounts[id])


func set_amount(id: String, value: int) -> void:
	_amounts[id] = maxi(value, 0)
	changed.emit(id, _amounts[id])


func to_dict() -> Dictionary:
	return _amounts.duplicate()


func from_dict(d: Dictionary) -> void:
	_amounts.clear()
	for id in d:
		_amounts[str(id)] = int(d[id])
