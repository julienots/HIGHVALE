class_name LaboratoryState
extends RefCounted
## Expérience en cours au Laboratoire et synthèse d'ingrédients.

signal changed

## Ingrédients fabricables à partir des ressources de la cité.
const SYNTHESIS := {
	"ember_stone": {"stone": 100, "gold": 50},
	"vital_drop": {"underground_nectar": 60},
	"tide_scale": {"fungal_wood": 80, "gold": 40},
	"glow_spore": {"fungal_wood": 60, "underground_nectar": 20},
	"resonant_shard": {"abyssal_crystal": 15},
}

## { ingredients: [ids], start, end, result }
var experiment := {}


static func laboratory_level(city: CityState) -> int:
	var lvl := 0
	for b in city.buildings.values():
		if b.data_id == "laboratory":
			lvl = maxi(lvl, b.level)
	return lvl


## Emplacements d'ingrédients : 2, puis 3 au niveau 3 et 4 au niveau 6.
static func slots(city: CityState) -> int:
	var lvl := laboratory_level(city)
	if lvl < 1:
		return 0
	return 2 + (1 if lvl >= 3 else 0) + (1 if lvl >= 6 else 0)


func is_running() -> bool:
	return not experiment.is_empty()


func remaining(now: float) -> float:
	return maxf(float(experiment.get("end", 0.0)) - now, 0.0) if is_running() else 0.0


func is_ready(now: float) -> bool:
	return is_running() and now >= float(experiment.end)


func start_reason(ids: Array, wallet: Wallet, inventory: Inventory, city: CityState) -> String:
	if laboratory_level(city) < 1:
		return "Construisez un Laboratoire"
	if is_running():
		return "Une expérience est déjà en cours"
	if ids.is_empty():
		return "Ajoutez au moins un ingrédient"
	if ids.size() > slots(city):
		return "Trop d'ingrédients pour ce Laboratoire"
	var need := {}
	for id in ids:
		need[id] = int(need.get(id, 0)) + 1
	for id in need:
		if inventory.count(id) < need[id]:
			return "Ingrédients manquants"
	if not wallet.can_afford(LabRules.cost(ids.size())):
		return "Ressources insuffisantes"
	return ""


## Lance l'expérience. Le résultat est tiré dès le départ (pas de nouvel essai
## en rechargeant la partie) et révélé à la fin du compte à rebours.
func start(ids: Array, wallet: Wallet, inventory: Inventory, city: CityState, now: float, rng: RandomNumberGenerator) -> String:
	var reason := start_reason(ids, wallet, inventory, city)
	if reason != "":
		return reason
	var ings := ingredients_of(ids)
	wallet.spend(LabRules.cost(ids.size()))
	for id in ids:
		inventory.remove(id)
	experiment = {"ingredients": ids.duplicate(), "start": now, "end": now + LabRules.duration(ings), "result": LabRules.roll(ings, rng)}
	changed.emit()
	return ""


## Récupère la créature. Retourne { uid, id, new } ou { error }.
func claim(collection: CollectionState, city: CityState, now: float) -> Dictionary:
	if not is_ready(now):
		return {"error": "L'expérience n'est pas terminée"}
	if collection.monsters.size() >= collection.monster_capacity(city):
		return {"error": "Plus de place : agrandissez l'Habitat des monstres"}
	var id: String = experiment.result
	var is_new := not collection.owns_monster_species(id)
	var uid := collection.add_monster(id)
	experiment = {}
	changed.emit()
	return {"uid": uid, "id": id, "new": is_new}


func speed_up_cost(now: float, config: GameConfig) -> int:
	var r := remaining(now)
	if r <= config.free_speedup_seconds:
		return 0
	return maxi(1, int(ceil(config.speedup_factor * pow(r / 60.0, config.speedup_exponent))))


func speed_up(wallet: Wallet, now: float, config: GameConfig) -> bool:
	if not is_running() or is_ready(now):
		return false
	var cost := speed_up_cost(now, config)
	if cost > 0 and not wallet.spend({config.premium_resource: cost}):
		return false
	experiment.end = now
	changed.emit()
	return true


func synthesize(id: String, wallet: Wallet, inventory: Inventory) -> String:
	if not SYNTHESIS.has(id):
		return "Synthèse impossible"
	if not wallet.spend(SYNTHESIS[id]):
		return "Ressources insuffisantes"
	inventory.add(id)
	changed.emit()
	return ""


static func ingredients_of(ids: Array) -> Array:
	var out := []
	for id in ids:
		out.append(DataRegistry.ingredient(id))
	return out


func to_dict() -> Dictionary:
	return {"experiment": experiment.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	experiment = d.get("experiment", {})
	if not experiment.is_empty() and DataRegistry.monster(str(experiment.get("result", ""))) == null:
		experiment = {}
