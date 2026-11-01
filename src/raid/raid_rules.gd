class_name RaidRules
extends RefCounted
## Trophées, ligues, coût de recherche et récompenses des assauts et défenses.

const LEAGUES := [[0, "Bronze", Color("c8844a")], [400, "Argent", Color("c8d0e0")], [800, "Or", Color("ffc93c")],
	[1200, "Cristal", Color("7fdcff")], [1600, "Maître", Color("b464ff")], [2000, "Légende", Color("ff5a7a")]]
const DEFENSE_INTERVAL := 3 * 3600.0


static func trophies(profile: Dictionary) -> int:
	return int(profile.get("trophies", 0))


static func league(t: int) -> Array:
	var cur: Array = LEAGUES[0]
	for l in LEAGUES:
		if t >= int(l[0]):
			cur = l
	return cur


static func search_cost(level: int) -> Dictionary:
	return {"gold": 50 * level}


static func trophy_change(stars: int, base_level: int) -> int:
	if stars == 0:
		return -12
	return 6 + stars * 7 + base_level


## Butin des bâtiments détruits + prime par étoile.
static func raid_rewards(sim: RaidSim, base_level: int) -> Dictionary:
	var out := sim.loot()
	var st := sim.stars()
	out["gold"] = int(out.get("gold", 0)) + 250 * base_level * st
	if st == 3:
		out["prisms"] = int(out.get("prisms", 0)) + 10 + base_level
	return out


static func defense_rewards(won: bool, level: int, wallet: Wallet) -> Dictionary:
	if won:
		return {"gold": 400 * level, "prisms": 5 + level, "ancient_shards": 2 * level}
	var lost := {}
	for k in ["gold", "stone", "fungal_wood"]:
		lost[k] = -int(wallet.amount(k) * 0.08)
	return lost
