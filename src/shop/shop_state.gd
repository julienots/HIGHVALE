class_name ShopState
extends RefCounted
## Boutique HIGHVALE : offres du jour renouvelées, ressources et coffres.
## Tout s'achète avec les monnaies du jeu (or, prismes, éclats antiques).

signal changed

## Offres permanentes : id -> [libellé, prix, contenu]
const PERMANENT := {
	"gold_pack": ["Bourse d'or", {"prisms": 50}, {"gold": 2500}],
	"stone_pack": ["Chariot de pierre", {"prisms": 40}, {"stone": 2500}],
	"wood_pack": ["Fagots fongiques", {"prisms": 40}, {"fungal_wood": 2500}],
	"crystal_pack": ["Coffret de cristaux", {"prisms": 60}, {"abyssal_crystal": 80}],
	"nectar_pack": ["Jarres de nectar", {"gold": 1500}, {"underground_nectar": 150}],
	"essence_pack": ["Fioles d'essence", {"gold": 2000}, {"vital_essence": 60}],
}
## Coffres : contenu tiré au hasard.
const CHESTS := {
	"ingredient_chest": ["Coffre d'alchimiste", {"ancient_shards": 25}, "3 ingrédients au hasard"],
	"hero_chest": ["Coffre du héros", {"prisms": 150}, "15 à 30 fragments d'un héros"],
}
const DAILY_COUNT := 6

var day := -1
var bought := []  # offres achetées aujourd'hui


func roll(now: float) -> void:
	var d := QuestState.day_index(now)
	if d != day:
		day = d
		bought.clear()


## Offres du jour (déterministes) : [{ id, name, price, content, kind }]
func daily_offers() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 104729 + 7
	var out := []
	var ings := DataRegistry.all_ingredients()
	var items := DataRegistry.all_items().filter(func(i): return i.rarity <= GameEnums.Rarity.EPIC)
	var heroes := DataRegistry.all_heroes().filter(func(h): return not h.is_god and h.requires_temple == 0)
	for i in DAILY_COUNT:
		var kind := i % 3
		if kind == 0:
			var ing: IngredientData = ings[rng.randi() % ings.size()]
			out.append({"id": "d%d" % i, "name": "%s ×3" % ing.display_name, "price": {"gold": 400 * (ing.rarity + 1)}, "item": ing.id, "count": 3, "rarity": ing.rarity, "icon": ing.icon})
		elif kind == 1:
			var h: HeroData = heroes[rng.randi() % heroes.size()]
			out.append({"id": "d%d" % i, "name": "Fragments : %s ×10" % h.display_name, "price": {"prisms": 30 * (h.rarity + 1)}, "hero": h.id, "count": 10, "rarity": h.rarity, "icon": h.portrait})
		else:
			var it: ItemData = items[rng.randi() % items.size()]
			out.append({"id": "d%d" % i, "name": it.display_name, "price": {"ancient_shards": 20 * (it.rarity + 1)}, "item": it.id, "count": 1, "rarity": it.rarity, "icon": it.icon})
	return out


func buy_daily(offer: Dictionary, wallet: Wallet, inventory: Inventory, collection: CollectionState) -> String:
	if offer.id in bought:
		return "Déjà acheté aujourd'hui"
	if not wallet.spend(offer.price):
		return "Pas assez de monnaie"
	if offer.has("hero"):
		collection.add_fragments(offer.hero, offer.count)
	else:
		inventory.add(offer.item, offer.count)
	bought.append(offer.id)
	changed.emit()
	return ""


func buy_permanent(id: String, wallet: Wallet) -> String:
	var o: Array = PERMANENT[id]
	if not wallet.spend(o[1]):
		return "Pas assez de monnaie"
	for k in o[2]:
		wallet.add(k, o[2][k])
	changed.emit()
	return ""


func open_chest(id: String, wallet: Wallet, inventory: Inventory, collection: CollectionState, rng: RandomNumberGenerator) -> Dictionary:
	var c: Array = CHESTS[id]
	if not wallet.spend(c[1]):
		return {"error": "Pas assez de monnaie"}
	var got := {}
	if id == "ingredient_chest":
		var ings := DataRegistry.all_ingredients()
		for i in 3:
			var weights := [10.0, 4.0, 1.5, 0.3]
			var pick: IngredientData = ings[rng.randi() % ings.size()]
			for tries in 6:
				var cand: IngredientData = ings[rng.randi() % ings.size()]
				if rng.randf() * 10.0 < weights[cand.rarity]:
					pick = cand
					break
			inventory.add(pick.id)
			got[pick.display_name] = int(got.get(pick.display_name, 0)) + 1
	else:
		var heroes := DataRegistry.all_heroes().filter(func(h): return not h.is_god and h.requires_temple == 0)
		var h: HeroData = heroes[rng.randi() % heroes.size()]
		var n := rng.randi_range(15, 30)
		collection.add_fragments(h.id, n)
		got["Fragments de " + h.display_name] = n
	changed.emit()
	return got


func to_dict() -> Dictionary:
	return {"day": day, "bought": bought.duplicate()}


func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", -1))
	bought = d.get("bought", []).duplicate()
