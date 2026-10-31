class_name SummonRules
extends RefCounted
## Invocations : tirage de rareté selon les taux affichés, garantie Épique,
## doublons convertis en fragments, Éveil divin pour les dieux.

const DUPLICATE_FRAGMENTS := [10, 20, 40, 80, 160]
const GOD_AWAKEN_CHANCE := 0.05


## Élément mis en avant par l'invocation élémentaire (change chaque jour).
static func element_of_day(now: float) -> int:
	var elements := []
	for h in DataRegistry.all_heroes():
		if not h.is_god and not h.element in elements:
			elements.append(h.element)
	elements.sort()
	return elements[int(now / 86400.0) % elements.size()]


static func pool(banner: SummonBannerData, rarity: int, now: float) -> Array:
	var el := element_of_day(now) if banner.element == -2 else banner.element
	var out := []
	for h in DataRegistry.all_heroes():
		if h.is_god != banner.gods_only or h.rarity != rarity:
			continue
		if el >= 0 and h.element != el:
			continue
		out.append(h)
	return out


## Taux réellement appliqués : une rareté sans héros disponible est redistribuée.
static func effective_rates(banner: SummonBannerData, now: float) -> PackedFloat32Array:
	var rates := PackedFloat32Array([0, 0, 0, 0, 0])
	var total := 0.0
	for r in 5:
		if banner.rarity_rates[r] > 0.0 and not pool(banner, r, now).is_empty():
			rates[r] = banner.rarity_rates[r]
			total += rates[r]
	for r in 5:
		rates[r] = rates[r] / total * 100.0 if total > 0.0 else 0.0
	return rates


static func summon(banner: SummonBannerData, collection: CollectionState, wallet: Wallet, rng: RandomNumberGenerator, now: float) -> Dictionary:
	if not wallet.can_afford(banner.cost):
		return {"error": "Ressources insuffisantes"}
	var rates := effective_rates(banner, now)
	var total := 0.0
	for v in rates:
		total += v
	if total <= 0.0:
		return {"error": "Aucun héros disponible"}
	wallet.spend(banner.cost)
	if banner.gods_only:
		return _awaken(banner, collection, rng, now)
	var pity: int = collection.pity.get(banner.id, 0)
	var epic_total := 0.0
	for r in range(GameEnums.Rarity.EPIC, 5):
		epic_total += rates[r]
	# La garantie ne s'applique que si un héros Épique ou mieux est disponible.
	var forced := banner.pity_epic > 0 and pity >= banner.pity_epic - 1 and epic_total > 0.0
	var roll := rng.randf() * 100.0
	var rarity := 0
	if forced:
		roll = rng.randf() * epic_total
		rarity = GameEnums.Rarity.EPIC
		for r in range(GameEnums.Rarity.EPIC, 5):
			roll -= rates[r]
			if roll <= 0.0 and rates[r] > 0.0:
				rarity = r
				break
	else:
		for r in 5:
			roll -= rates[r]
			if roll <= 0.0 and rates[r] > 0.0:
				rarity = r
				break
	collection.pity[banner.id] = 0 if rarity >= GameEnums.Rarity.EPIC else pity + 1
	var candidates := pool(banner, rarity, now)
	var hero: HeroData = candidates[rng.randi() % candidates.size()]
	var result := {"hero": hero.id, "rarity": rarity, "pity_used": forced}
	if collection.owns_hero(hero.id):
		var n: int = DUPLICATE_FRAGMENTS[rarity]
		collection.add_fragments(hero.id, n)
		result["fragments"] = n
	else:
		collection.unlock_hero(hero.id)
		result["new"] = true
	return result


static func _awaken(banner: SummonBannerData, collection: CollectionState, rng: RandomNumberGenerator, now: float) -> Dictionary:
	var gods := pool(banner, GameEnums.Rarity.DIVINE, now)
	var god: HeroData = gods[rng.randi() % gods.size()]
	if not collection.owns_hero(god.id) and rng.randf() < GOD_AWAKEN_CHANCE:
		collection.unlock_hero(god.id)
		return {"hero": god.id, "rarity": GameEnums.Rarity.DIVINE, "new": true}
	var n := rng.randi_range(10, 20)
	var unlocked := collection.add_fragments(god.id, n)
	return {"hero": god.id, "rarity": GameEnums.Rarity.DIVINE, "fragments": n, "new": unlocked}
