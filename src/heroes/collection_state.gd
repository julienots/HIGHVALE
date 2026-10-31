class_name CollectionState
extends RefCounted
## Collection du joueur : héros (un exemplaire chacun, niveaux, étoiles,
## fragments) et monstres (plusieurs exemplaires possibles).

signal changed

## Étoiles de départ selon la rareté, et fragments pour passer à l'étoile suivante.
const BASE_STARS := [1, 2, 3, 4, 5]
const MAX_STARS := 6
const STAR_UP_FRAGMENTS := [0, 10, 20, 40, 80, 120, 0]
const BASE_MONSTER_CAPACITY := 4

## id -> { level, stars }
var heroes := {}
## id -> fragments en attente (héros possédés ou non)
var fragments := {}
## uid -> { id, level }
var monsters := {}
## Invocations sans Épique par bannière (garantie) et recettes de fusion découvertes.
var pity := {}
var discovered_recipes: Array = []
var _next_monster_uid := 1


# --- Héros -------------------------------------------------------------------

func owns_hero(id: String) -> bool:
	return heroes.has(id)


func hero_level(id: String) -> int:
	return heroes.get(id, {}).get("level", 0)


func hero_stars(id: String) -> int:
	return heroes.get(id, {}).get("stars", 0)


static func level_cap_for_stars(stars: int) -> int:
	return 10 + stars * 10


func unlock_hero(id: String) -> bool:
	var d := DataRegistry.hero(id)
	if d == null or owns_hero(id):
		return false
	heroes[id] = {"level": 1, "stars": BASE_STARS[d.rarity]}
	changed.emit()
	return true


## Ajoute des fragments ; débloque le héros quand le seuil est atteint.
## Retourne true si le héros vient d'être débloqué.
func add_fragments(id: String, count: int) -> bool:
	var d := DataRegistry.hero(id)
	if d == null or count <= 0:
		return false
	fragments[id] = int(fragments.get(id, 0)) + count
	if not owns_hero(id) and fragments[id] >= d.fragments_to_unlock:
		fragments[id] -= d.fragments_to_unlock
		unlock_hero(id)
		return true
	changed.emit()
	return false


func hero_level_cost(id: String) -> Dictionary:
	var d := DataRegistry.hero(id)
	var lvl := hero_level(id)
	var mult := 1.0 + d.rarity * 0.35
	var cost := {"gold": BuildingData.nice_round(80.0 * pow(1.17, lvl - 1) * mult)}
	if lvl >= 10:
		cost["abyssal_crystal"] = BuildingData.nice_round(4.0 * pow(1.12, lvl - 10) * mult)
	return cost


func hero_level_reason(id: String, wallet: Wallet) -> String:
	if not owns_hero(id):
		return "Héros non débloqué"
	var d := DataRegistry.hero(id)
	var lvl := hero_level(id)
	if lvl >= d.max_level:
		return "Niveau maximal"
	if lvl >= level_cap_for_stars(hero_stars(id)):
		return "Faites évoluer le héros (étoiles)"
	if not wallet.can_afford(hero_level_cost(id)):
		return "Ressources insuffisantes"
	return ""


func level_up_hero(id: String, wallet: Wallet) -> String:
	var reason := hero_level_reason(id, wallet)
	if reason != "":
		return reason
	wallet.spend(hero_level_cost(id))
	heroes[id]["level"] += 1
	changed.emit()
	return ""


func star_up_cost(id: String) -> int:
	return STAR_UP_FRAGMENTS[mini(hero_stars(id), MAX_STARS)]


func star_up_reason(id: String) -> String:
	if not owns_hero(id):
		return "Héros non débloqué"
	if hero_stars(id) >= MAX_STARS:
		return "Étoiles maximales"
	if int(fragments.get(id, 0)) < star_up_cost(id):
		return "Fragments insuffisants"
	return ""


func star_up_hero(id: String) -> String:
	var reason := star_up_reason(id)
	if reason != "":
		return reason
	fragments[id] -= star_up_cost(id)
	heroes[id]["stars"] += 1
	changed.emit()
	return ""


## Statistiques effectives : niveau, puis +10 % par étoile au-delà de la première.
static func effective_stats(base: CharacterStats, level: int, stars: int) -> Dictionary:
	var s := base.at_level(maxi(level, 1))
	var bonus := 1.0 + 0.1 * maxi(stars - 1, 0)
	for k in ["max_hp", "attack", "defense"]:
		s[k] = int(s[k] * bonus)
	return s


static func power(stats: Dictionary) -> int:
	return int(stats.max_hp / 10.0 + stats.attack * 2.0 + stats.defense * 1.5 + stats.speed * 0.5)


func hero_power(id: String) -> int:
	var d := DataRegistry.hero(id)
	return power(effective_stats(d.stats, maxi(hero_level(id), 1), maxi(hero_stars(id), BASE_STARS[d.rarity])))


# --- Monstres ----------------------------------------------------------------

func monster_capacity(city: CityState) -> int:
	var n := BASE_MONSTER_CAPACITY
	for b in city.buildings.values():
		n += b.data().monster_capacity_for_level(b.level)
	return n


func add_monster(id: String, level := 1, variant := "") -> int:
	if DataRegistry.monster(id) == null:
		return 0
	var uid := _next_monster_uid
	_next_monster_uid += 1
	monsters[uid] = {"id": id, "level": level, "variant": variant}
	changed.emit()
	return uid


func owns_monster_species(id: String) -> bool:
	for m in monsters.values():
		if m.id == id:
			return true
	return false


func monster_level_cost(uid: int) -> Dictionary:
	var m: Dictionary = monsters[uid]
	var d := DataRegistry.monster(m.id)
	var cost := {}
	for food in d.food_per_hour:
		cost[food] = BuildingData.nice_round(d.food_per_hour[food] * 5.0 * pow(1.15, m.level - 1))
	cost["gold"] = BuildingData.nice_round(40.0 * pow(1.15, m.level - 1) * (1.0 + d.rarity * 0.3))
	return cost


func monster_level_reason(uid: int, wallet: Wallet) -> String:
	if not monsters.has(uid):
		return "Créature inconnue"
	var m: Dictionary = monsters[uid]
	if m.level >= DataRegistry.monster(m.id).max_level:
		return "Niveau maximal"
	if not wallet.can_afford(monster_level_cost(uid)):
		return "Nourriture insuffisante"
	return ""


func feed_monster(uid: int, wallet: Wallet) -> String:
	var reason := monster_level_reason(uid, wallet)
	if reason != "":
		return reason
	wallet.spend(monster_level_cost(uid))
	monsters[uid]["level"] += 1
	changed.emit()
	return ""


func monster_power(uid: int) -> int:
	var m: Dictionary = monsters[uid]
	var d := DataRegistry.monster(m.id)
	return power(effective_stats(d.stats, m.level, 2 if m.get("variant", "") != "" else 1))


func release_monster(uid: int) -> bool:
	if not monsters.has(uid) or monsters.size() <= 1:
		return false
	monsters.erase(uid)
	changed.emit()
	return true


# --- Trouvailles ---------------------------------------------------------------

const FRAGMENT_WEIGHTS := [6.0, 3.0, 1.0, 0.3, 0.0]


## Bonus éventuel d'une ressource sauvage récoltée : fragments de héros dans les
## cristaux, œuf de créature dans les champignons. Retourne ce qui a été obtenu.
func roll_wild_bonus(kind_id: String, rng: RandomNumberGenerator, city: CityState) -> Dictionary:
	if kind_id == "crystal" and rng.randf() < 0.6:
		var id := _weighted_pick(DataRegistry.all_heroes().filter(func(h): return not h.is_god), rng)
		if id != "":
			var n := rng.randi_range(3, 6)
			var unlocked := add_fragments(id, n)
			return {"fragments": {id: n}, "unlocked": id if unlocked else ""}
	elif kind_id == "shrooms" and rng.randf() < 0.08 and monsters.size() < monster_capacity(city):
		var candidates := DataRegistry.all_monsters().filter(func(m): return m.rarity <= GameEnums.Rarity.RARE and m.lab_weight > 0.0)
		var id := _weighted_pick(candidates, rng)
		if id != "":
			add_monster(id)
			return {"monster": id}
	return {}


func _weighted_pick(list: Array, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for d in list:
		total += FRAGMENT_WEIGHTS[d.rarity]
	var roll := rng.randf() * total
	for d in list:
		roll -= FRAGMENT_WEIGHTS[d.rarity]
		if roll <= 0.0 and FRAGMENT_WEIGHTS[d.rarity] > 0.0:
			return d.id
	return ""


# --- Sauvegarde --------------------------------------------------------------

func to_dict() -> Dictionary:
	var mons := []
	for uid in monsters:
		mons.append({"uid": uid, "id": monsters[uid].id, "level": monsters[uid].level, "variant": monsters[uid].get("variant", "")})
	return {"heroes": heroes.duplicate(true), "fragments": fragments.duplicate(), "monsters": mons, "next_monster_uid": _next_monster_uid,
		"pity": pity.duplicate(), "recipes": discovered_recipes.duplicate()}


func from_dict(d: Dictionary) -> void:
	heroes.clear()
	fragments.clear()
	monsters.clear()
	for id in d.get("heroes", {}):
		if DataRegistry.hero(str(id)):
			var h: Dictionary = d.heroes[id]
			heroes[str(id)] = {"level": int(h.get("level", 1)), "stars": int(h.get("stars", 1))}
	for id in d.get("fragments", {}):
		fragments[str(id)] = int(d.fragments[id])
	_next_monster_uid = int(d.get("next_monster_uid", 1))
	pity = d.get("pity", {}).duplicate()
	discovered_recipes = d.get("recipes", []).duplicate()
	for m in d.get("monsters", []):
		if DataRegistry.monster(str(m.get("id", ""))):
			var uid := int(m.get("uid", 0))
			monsters[uid] = {"id": str(m.id), "level": int(m.get("level", 1)), "variant": str(m.get("variant", ""))}
			_next_monster_uid = maxi(_next_monster_uid, uid + 1)
