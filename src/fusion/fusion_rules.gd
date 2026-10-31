class_name FusionRules
extends RefCounted
## Fusion de deux créatures : recettes secrètes, sinon une espèce apparentée
## (tags génétiques communs) de rareté égale ou supérieure. Mutations rares.

const TIER_UP_CHANCE := 0.25
const VARIANT_CHANCE := 0.12
const VARIANTS := ["gold", "shadow", "crystal"]
const VARIANT_NAMES := {"gold": "dorée", "shadow": "d'ombre", "crystal": "de cristal"}
const VARIANT_COLORS := {"gold": Color("ffd24a"), "shadow": Color("8a5aff"), "crystal": Color("7fdcff")}


static func recipe_for(a: String, b: String) -> FusionRecipeData:
	for r in DataRegistry.fusion_recipes():
		if (r.parent_a == a and r.parent_b == b) or (r.parent_a == b and r.parent_b == a):
			return r
	return null


static func cost(collection: CollectionState, uid_a: int, uid_b: int) -> Dictionary:
	var ra := DataRegistry.monster(collection.monsters[uid_a].id).rarity
	var rb := DataRegistry.monster(collection.monsters[uid_b].id).rarity
	return {"gold": 400 * (1 + ra + rb), "vital_essence": 20 * (1 + ra + rb)}


static func reason(collection: CollectionState, uid_a: int, uid_b: int, wallet: Wallet) -> String:
	if uid_a == uid_b or not collection.monsters.has(uid_a) or not collection.monsters.has(uid_b):
		return "Choisissez deux créatures"
	if not wallet.can_afford(cost(collection, uid_a, uid_b)):
		return "Ressources insuffisantes"
	return ""


## Espèces possibles hors recette : tags communs, rareté égale ou un cran au-dessus.
static func candidates(a: MonsterData, b: MonsterData, rarity: int) -> Array:
	var tags := {}
	for t in a.genetic_tags:
		tags[t] = true
	for t in b.genetic_tags:
		tags[t] = true
	var out := []
	for m in DataRegistry.all_monsters():
		if m.rarity != rarity or m.lab_weight <= 0.0:
			continue
		for t in m.genetic_tags:
			if tags.has(t):
				out.append(m)
				break
	return out


static func fuse(collection: CollectionState, uid_a: int, uid_b: int, wallet: Wallet, rng: RandomNumberGenerator) -> Dictionary:
	var why := reason(collection, uid_a, uid_b, wallet)
	if why != "":
		return {"error": why}
	var ma: Dictionary = collection.monsters[uid_a]
	var mb: Dictionary = collection.monsters[uid_b]
	var a := DataRegistry.monster(ma.id)
	var b := DataRegistry.monster(mb.id)
	wallet.spend(cost(collection, uid_a, uid_b))
	var result := ""
	var recipe := recipe_for(a.id, b.id)
	if recipe and rng.randf() < recipe.chance:
		result = recipe.result
		if not recipe.id in collection.discovered_recipes:
			collection.discovered_recipes.append(recipe.id)
	else:
		var rarity := maxi(a.rarity, b.rarity)
		var pool := []
		if rng.randf() < TIER_UP_CHANCE:
			pool = candidates(a, b, mini(rarity + 1, GameEnums.Rarity.LEGENDARY))
		if pool.is_empty():
			pool = candidates(a, b, rarity)
		result = pool[rng.randi() % pool.size()].id if not pool.is_empty() else (a.id if a.rarity >= b.rarity else b.id)
	var variant: String = VARIANTS[rng.randi() % VARIANTS.size()] if rng.randf() < VARIANT_CHANCE else ""
	var level := maxi(1, (int(ma.level) + int(mb.level)) / 2)
	var is_new := not collection.owns_monster_species(result)
	collection.monsters.erase(uid_a)
	collection.monsters.erase(uid_b)
	var uid := collection.add_monster(result, level, variant)
	return {"uid": uid, "id": result, "variant": variant, "new": is_new, "recipe": recipe != null and result == recipe.result}
