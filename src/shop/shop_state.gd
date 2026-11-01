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
## Coffres : [nom, prix, description, icône, rareté d'affichage]. Contenu tiré au hasard.
const CHESTS := {
	"wood_chest": ["Coffre en bois", {"gold": 1500}, "Ressources et un ingrédient", "res://assets/icons/ui/chest_wood.svg", 0],
	"ingredient_chest": ["Coffre d'alchimiste", {"ancient_shards": 25}, "3 ingrédients au hasard", "res://assets/icons/ui/chest_alchemy.svg", 1],
	"hero_chest": ["Coffre du héros", {"prisms": 150}, "15 à 30 fragments d'un héros", "res://assets/icons/ui/chest_hero.svg", 2],
	"legend_chest": ["Coffre légendaire", {"prisms": 450}, "50 fragments d'un héros Épique ou Légendaire + un équipement rare", "res://assets/icons/ui/chest_legend.svg", 3],
}
## Cadeau gratuit renouvelé toutes les 4 heures.
const GIFT_SECONDS := 4 * 3600.0
## Pack du Fondateur : une seule fois par partie.
const STARTER := {"name": "Pack du Fondateur", "price": {"prisms": 200},
	"resources": {"gold": 10000, "stone": 4000, "fungal_wood": 4000, "abyssal_crystal": 250, "underground_nectar": 150},
	"hero": "isolde", "fragments": 80}
## Packs de prismes (paiement réel non activé dans cette version) : [prismes, prix affiché, bonus].
const PRISM_PACKS := [[80, "0,99 €", ""], [420, "4,99 €", "+5 %"], [880, "9,99 €", "+10 %"], [1850, "19,99 €", "+15 %"],
	[4800, "49,99 €", "+20 %"], [10000, "99,99 €", "+25 %"]]
const WEEK := 7 * 86400.0
const DAILY_COUNT := 6

var day := -1
var bought := []  # offres achetées aujourd'hui
var gift_at := 0.0  # prochain cadeau gratuit disponible (horodatage)
var starter_bought := false
var week := -1
var week_bought := []  # packs de la semaine déjà achetés


func roll(now: float) -> void:
	var d := QuestState.day_index(now)
	if d != day:
		day = d
		bought.clear()
	var w := int(now / WEEK)
	if w != week:
		week = w
		week_bought.clear()


# --- Cadeau gratuit ----------------------------------------------------------------

func gift_ready(now: float) -> bool:
	return now >= gift_at


func gift_left(now: float) -> float:
	return maxf(0.0, gift_at - now)


func claim_gift(wallet: Wallet, inventory: Inventory, rng: RandomNumberGenerator, now: float) -> Dictionary:
	if not gift_ready(now):
		return {"error": "Le prochain cadeau n'est pas encore prêt"}
	gift_at = now + GIFT_SECONDS
	var got := {}
	got["Or"] = wallet.add("gold", rng.randi_range(4, 10) * 100)
	got["Prismes"] = wallet.add("prisms", rng.randi_range(5, 15))
	if rng.randf() < 0.5:
		var ings := DataRegistry.all_ingredients().filter(func(i): return i.rarity <= GameEnums.Rarity.RARE)
		var ing: IngredientData = ings[rng.randi() % ings.size()]
		inventory.add(ing.id)
		got[ing.display_name] = 1
	changed.emit()
	return got


# --- Pack du Fondateur et packs de la semaine -----------------------------------------

func buy_starter(wallet: Wallet, collection: CollectionState) -> String:
	if starter_bought:
		return "Déjà acheté"
	if not wallet.spend(STARTER.price):
		return "Pas assez de prismes"
	for k in STARTER.resources:
		wallet.add(k, STARTER.resources[k])
	collection.add_fragments(STARTER.hero, STARTER.fragments)
	starter_bought = true
	changed.emit()
	return ""


func week_left(now: float) -> float:
	return (week + 1) * WEEK - now


## Packs limités de la semaine (une fois chacun) : héros vedette, œuf de créature,
## équipement et grand coffre de ressources. Déterministes selon la semaine.
func weekly_offers() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = week * 7919 + 3
	var out := []
	var stars := DataRegistry.all_heroes().filter(func(h): return not h.is_god and h.requires_temple == 0 and h.rarity >= GameEnums.Rarity.EPIC)
	var h: HeroData = stars[rng.randi() % stars.size()]
	out.append({"id": "w_hero", "name": "Héros vedette : %s" % h.display_name, "desc": "60 fragments et 2 000 or", "price": {"prisms": 280},
		"hero": h.id, "fragments": 60, "resources": {"gold": 2000}, "icon": h.portrait, "rarity": h.rarity})
	var mons := DataRegistry.all_monsters().filter(func(m): return m.lab_weight > 0.0 and m.requires_temple == 0 and m.rarity == GameEnums.Rarity.EPIC)
	var m: MonsterData = mons[rng.randi() % mons.size()]
	out.append({"id": "w_monster", "name": "Œuf rare : %s" % m.display_name, "desc": "La créature éclot aussitôt (place requise)", "price": {"prisms": 220},
		"monster": m.id, "icon": m.portrait, "rarity": m.rarity})
	var items := DataRegistry.all_items().filter(func(i): return i.rarity >= GameEnums.Rarity.RARE)
	var it: ItemData = items[rng.randi() % items.size()]
	out.append({"id": "w_item", "name": "Arsenal : %s" % it.display_name, "desc": "L'équipement et 40 éclats antiques", "price": {"prisms": 160},
		"item": it.id, "resources": {"ancient_shards": 40}, "icon": it.icon, "rarity": it.rarity})
	out.append({"id": "w_res", "name": "Caravane des profondeurs", "desc": "6 000 or, 3 000 pierre, 3 000 bois, 120 cristaux", "price": {"prisms": 120},
		"resources": {"gold": 6000, "stone": 3000, "fungal_wood": 3000, "abyssal_crystal": 120}, "icon": DataRegistry.resource_type("gold").icon, "rarity": 1})
	return out


func buy_weekly(offer: Dictionary, wallet: Wallet, inventory: Inventory, collection: CollectionState, city: CityState) -> String:
	if offer.id in week_bought:
		return "Déjà acheté cette semaine"
	if offer.has("monster") and collection.monsters.size() >= collection.monster_capacity(city):
		return "Plus de place dans l'Habitat des monstres"
	if not wallet.spend(offer.price):
		return "Pas assez de prismes"
	for k in offer.get("resources", {}):
		wallet.add(k, offer.resources[k])
	if offer.has("hero"):
		collection.add_fragments(offer.hero, offer.fragments)
	if offer.has("monster"):
		collection.add_monster(offer.monster)
	if offer.has("item"):
		inventory.add(offer.item)
	week_bought.append(offer.id)
	changed.emit()
	return ""


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
	if id == "wood_chest":
		for k in ["gold", "stone", "fungal_wood"]:
			var n := rng.randi_range(8, 20) * 100
			got[DataRegistry.resource_type(k).display_name] = wallet.add(k, n)
		var commons := DataRegistry.all_ingredients().filter(func(i): return i.rarity == GameEnums.Rarity.COMMON)
		var ing: IngredientData = commons[rng.randi() % commons.size()]
		inventory.add(ing.id)
		got[ing.display_name] = 1
	elif id == "legend_chest":
		var greats := DataRegistry.all_heroes().filter(func(h): return not h.is_god and h.requires_temple == 0 and h.rarity >= GameEnums.Rarity.EPIC)
		var hg: HeroData = greats[rng.randi() % greats.size()]
		collection.add_fragments(hg.id, 50)
		got["Fragments de " + hg.display_name] = 50
		var gear := DataRegistry.all_items().filter(func(i): return i.rarity >= GameEnums.Rarity.RARE)
		var it: ItemData = gear[rng.randi() % gear.size()]
		inventory.add(it.id)
		got[it.display_name] = 1
	elif id == "ingredient_chest":
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
	return {"day": day, "bought": bought.duplicate(), "gift_at": gift_at, "starter": starter_bought, "week": week,
		"week_bought": week_bought.duplicate()}


func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", -1))
	bought = d.get("bought", []).duplicate()
	gift_at = float(d.get("gift_at", 0.0))
	starter_bought = bool(d.get("starter", false))
	week = int(d.get("week", -1))
	week_bought = d.get("week_bought", []).duplicate()
