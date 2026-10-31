class_name ForgeRules
extends RefCounted
## Fabrication des équipements à la Forge.


static func forge_level(city: CityState) -> int:
	var lvl := 0
	for b in city.buildings.values():
		if b.data_id == "forge":
			lvl = maxi(lvl, b.level)
	return lvl


static func craft_reason(item: ItemData, city: CityState, wallet: Wallet) -> String:
	var lvl := forge_level(city)
	if lvl < 1:
		return "Construisez une Forge"
	if lvl < item.forge_level_required():
		return "Forge niveau %d requise" % item.forge_level_required()
	if not wallet.can_afford(item.craft_cost):
		return "Ressources insuffisantes"
	return ""


static func craft(item: ItemData, city: CityState, wallet: Wallet, inventory: Inventory) -> String:
	var reason := craft_reason(item, city, wallet)
	if reason != "":
		return reason
	wallet.spend(item.craft_cost)
	inventory.add(item.id)
	return ""
