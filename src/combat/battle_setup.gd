class_name BattleSetup
extends RefCounted
## Préparation et récompenses des défis des profondeurs.

const BOSS_HP := 2.5
const BOSS_ATK := 1.25


## Entraînement de la Caserne : +3 % d'attaque par niveau.
static func apply_city_bonus(team: Array, city: CityState) -> float:
	var lvl := 0
	for b in city.buildings.values():
		if b.data_id == "barracks":
			lvl = maxi(lvl, b.level)
	var mult := (1.0 + 0.03 * lvl) * (1.0 + city.research.value("tactics"))
	var hp_mult := 1.0 + city.research.value("vitality")
	for c: Combatant in team:
		c.attack = int(c.attack * mult)
		c.max_hp = int(c.max_hp * hp_mult)
		c.hp = c.max_hp
	return mult


static func enemies_for(enc: EncounterData) -> Array:
	var out := []
	for e in enc.enemies:
		var c := Combatant.from_monster(DataRegistry.monster(e.id), int(e.level))
		if e.get("boss", false):
			c.is_boss = true
			c.max_hp = int(c.max_hp * BOSS_HP)
			c.hp = c.max_hp
			c.attack = int(c.attack * BOSS_ATK)
			c.name += " (boss)"
		out.append(c)
	return out


static func enemy_power(enc: EncounterData) -> int:
	var p := 0
	for c in enemies_for(enc):
		p += c.power_rating()
	return p


static func is_unlocked(enc: EncounterData, collection: CollectionState) -> bool:
	return enc.order <= collection.stages_cleared + 1


## Applique les récompenses d'une victoire ; retourne le détail obtenu.
static func grant_victory(enc: EncounterData, collection: CollectionState, wallet: Wallet, rng: RandomNumberGenerator) -> Dictionary:
	var got := {}
	for id in enc.rewards:
		got[id] = wallet.add(id, enc.rewards[id])
	var first := enc.order > collection.stages_cleared
	if first:
		for id in enc.first_clear_rewards:
			got[id] = int(got.get(id, 0)) + wallet.add(id, enc.first_clear_rewards[id])
		collection.stages_cleared = enc.order
	var frag := {}
	if enc.fragment_reward > 0:
		var pool := DataRegistry.all_heroes().filter(func(h): return not h.is_god)
		var h: HeroData = pool[rng.randi() % pool.size()]
		collection.add_fragments(h.id, enc.fragment_reward)
		frag[h.id] = enc.fragment_reward
	return {"resources": got, "fragments": frag, "first": first}
