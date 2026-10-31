class_name ResearchState
extends RefCounted
## Recherches de la Bibliothèque (cité) et de l'Académie (héros).
## Une recherche à la fois par bâtiment ; le niveau d'une technologie ne peut
## pas dépasser celui du bâtiment qui la développe.

signal changed

## id -> { building, name, desc, max, per (effet par niveau), cost (niveau 1), seconds (niveau 1) }
const TECHS := {
	"extraction": {"building": "library", "name": "Extraction profonde", "desc": "+5 % de production des bâtiments par niveau",
		"max": 10, "per": 0.05, "cost": {"gold": 1200, "stone": 600}},
	"architecture": {"building": "library", "name": "Architecture", "desc": "−5 % de durée des chantiers par niveau",
		"max": 10, "per": 0.05, "cost": {"gold": 1400, "fungal_wood": 600}},
	"warehouses": {"building": "library", "name": "Entrepôts", "desc": "+8 % de capacité de stockage par niveau",
		"max": 10, "per": 0.08, "cost": {"gold": 1000, "stone": 800}},
	"festivities": {"building": "library", "name": "Arts et fêtes", "desc": "+3 de bien-être par niveau",
		"max": 5, "per": 3.0, "cost": {"gold": 1600, "abyssal_crystal": 60}},
	"training": {"building": "academy", "name": "Entraînement", "desc": "−6 % du coût d'amélioration des héros par niveau",
		"max": 8, "per": 0.06, "cost": {"gold": 1800, "abyssal_crystal": 80}},
	"tactics": {"building": "academy", "name": "Tactique", "desc": "+3 % d'attaque en combat par niveau",
		"max": 10, "per": 0.03, "cost": {"gold": 2000, "dark_ore": 120}},
	"vitality": {"building": "academy", "name": "Vitalité", "desc": "+4 % de PV en combat par niveau",
		"max": 10, "per": 0.04, "cost": {"gold": 2000, "vital_essence": 60}},
	"bestiary": {"building": "academy", "name": "Bestiaire", "desc": "+1 place de créature par niveau",
		"max": 5, "per": 1.0, "cost": {"gold": 2400, "underground_nectar": 80}},
}
const BASE_SECONDS := 240.0
const TIME_GROWTH := 1.75
const COST_GROWTH := 1.65
## Prismes par tranche de 2 minutes restantes pour terminer immédiatement.
const SPEEDUP_SECONDS_PER_PRISM := 120.0

## tech -> niveau atteint
var levels := {}
## bâtiment -> { "id": tech, "until": instant de fin }
var active := {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


## Effet cumulé d'une technologie (niveau × effet par niveau).
func value(id: String) -> float:
	return level(id) * float(TECHS.get(id, {}).get("per", 0.0))


static func techs_for(building_id: String) -> Array:
	return TECHS.keys().filter(func(t): return TECHS[t].building == building_id)


func cost(id: String) -> Dictionary:
	var out := {}
	var base: Dictionary = TECHS[id].cost
	for r in base:
		out[r] = BuildingData.nice_round(base[r] * pow(COST_GROWTH, level(id)))
	return out


func seconds(id: String) -> float:
	return BASE_SECONDS * pow(TIME_GROWTH, level(id))


func time_left(building_id: String, now: float) -> float:
	if not active.has(building_id):
		return 0.0
	return maxf(0.0, float(active[building_id].until) - now)


## "" si la recherche peut commencer, sinon la raison.
func reason(id: String, city: CityState, wallet: Wallet) -> String:
	if not TECHS.has(id):
		return "Recherche inconnue"
	var t: Dictionary = TECHS[id]
	if level(id) >= t.max:
		return "Niveau maximal atteint"
	var blvl := city.best_level(t.building)
	if blvl <= 0:
		return "Construisez d'abord : %s" % DataRegistry.building(t.building).display_name
	if level(id) >= blvl:
		return "Améliorez le bâtiment (niveau %d requis)" % (level(id) + 1)
	if active.has(t.building):
		return "Une recherche est déjà en cours"
	if not wallet.can_afford(cost(id)):
		return "Ressources insuffisantes"
	return ""


func start(id: String, city: CityState, wallet: Wallet, now: float) -> String:
	var r := reason(id, city, wallet)
	if r != "":
		return r
	wallet.spend(cost(id))
	active[TECHS[id].building] = {"id": id, "until": now + seconds(id)}
	changed.emit()
	return ""


## Termine les recherches échues. Retourne les technologies achevées.
func update(now: float) -> Array:
	var done := []
	for b in active.keys():
		if now >= float(active[b].until):
			var id: String = active[b].id
			levels[id] = level(id) + 1
			active.erase(b)
			done.append(id)
	if not done.is_empty():
		changed.emit()
	return done


func speedup_cost(building_id: String, now: float) -> int:
	var left := time_left(building_id, now)
	return 0 if left <= 0.0 else maxi(1, ceili(left / SPEEDUP_SECONDS_PER_PRISM))


func finish_now(building_id: String, wallet: Wallet, now: float) -> String:
	if not active.has(building_id):
		return "Aucune recherche en cours"
	var price := {"prisms": speedup_cost(building_id, now)}
	if not wallet.can_afford(price):
		return "Prismes insuffisants"
	wallet.spend(price)
	active[building_id].until = now
	update(now)
	return ""


func to_dict() -> Dictionary:
	return {"levels": levels.duplicate(), "active": active.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	levels.clear()
	active.clear()
	for id in d.get("levels", {}):
		if TECHS.has(str(id)):
			levels[str(id)] = clampi(int(d.levels[id]), 0, TECHS[str(id)].max)
	for b in d.get("active", {}):
		var a: Dictionary = d.active[b]
		if TECHS.has(str(a.get("id", ""))):
			active[str(b)] = {"id": str(a.id), "until": float(a.get("until", 0.0))}
