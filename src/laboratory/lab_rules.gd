class_name LabRules
extends RefCounted
## Probabilités du Laboratoire. Chaque espèce a un poids de base selon sa rareté ;
## les affinités génétiques et l'élément des ingrédients le multiplient, et le
## bonus de rareté favorise les créatures rares — sans jamais rien garantir.

const RARITY_BASE := [100.0, 30.0, 8.0, 2.0, 0.3]
const ELEMENT_BONUS := 1.5


## Espèces disponibles : poids positif et niveau du Temple suffisant.
static func eligible(temple_level := -1) -> Array:
	var tl := temple_level if temple_level >= 0 else GameState.city.temple_level()
	return DataRegistry.all_monsters().filter(func(m): return m.lab_weight > 0.0 and m.requires_temple <= tl)


static func weights(ingredients: Array, temple_level := -1) -> Dictionary:
	var boost := 0.0
	for ing: IngredientData in ingredients:
		boost += ing.rarity_boost
	var pool := eligible(temple_level)
	# Les chances par rareté ne dépendent pas du nombre d'espèces : le poids de
	# base d'une rareté est partagé entre ses espèces.
	var per_rarity := [0.0, 0.0, 0.0, 0.0, 0.0]
	for m in pool:
		per_rarity[m.rarity] += m.lab_weight
	var out := {}
	for m in pool:
		var w: float = RARITY_BASE[m.rarity] * m.lab_weight / per_rarity[m.rarity]
		for ing: IngredientData in ingredients:
			for tag in ing.genetic_affinities:
				if tag in m.genetic_tags:
					w *= 1.0 + float(ing.genetic_affinities[tag])
			if ing.element == m.element:
				w *= ELEMENT_BONUS
		w *= pow(1.0 + boost, m.rarity)
		out[m.id] = w
	return out


static func probabilities(ingredients: Array, temple_level := -1) -> Dictionary:
	var w := weights(ingredients, temple_level)
	var total := 0.0
	for v in w.values():
		total += v
	var out := {}
	for id in w:
		out[id] = w[id] / total if total > 0.0 else 0.0
	return out


## Probabilité totale de chaque rareté (Commun → Divin).
static func rarity_distribution(probs: Dictionary) -> PackedFloat32Array:
	var dist := PackedFloat32Array([0, 0, 0, 0, 0])
	for id in probs:
		dist[DataRegistry.monster(id).rarity] += probs[id]
	return dist


static func roll(ingredients: Array, rng: RandomNumberGenerator) -> String:
	var probs := probabilities(ingredients)
	var r := rng.randf()
	var last := ""
	for id in probs:
		last = id
		r -= probs[id]
		if r <= 0.0:
			return id
	return last


static func duration(ingredients: Array) -> float:
	var s := 0
	for ing: IngredientData in ingredients:
		s += ing.rarity + 1
	return 60.0 + 45.0 * s


static func cost(count: int) -> Dictionary:
	return {"gold": 150 * count, "vital_essence": 10 * count}
