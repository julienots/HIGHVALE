class_name ExplorationState
extends RefCounted
## Progression dans les zones (profondeurs et surface) et expéditions.

signal changed

const EXPEDITION_HOURS := [1, 4, 8]

## zone id -> combats remportés (0 à 3)
var progress := {}
## [{ zone, hero, start, end, hours }]
var expeditions: Array = []


func zone_progress(zone: ZoneData) -> int:
	return int(progress.get(zone.id, 0))


func is_cleared(zone: ZoneData) -> bool:
	return zone_progress(zone) >= ZoneData.STAGES


## Surface : accessible au Temple niveau 5. Chaque zone exige la précédente de sa couche.
func unlock_reason(zone: ZoneData, city: CityState) -> String:
	if city.temple_level() < zone.unlock_temple_level:
		return ("Passage vers la surface : Temple niveau %d" if zone.is_surface else "Temple niveau %d requis") % zone.unlock_temple_level
	for z in DataRegistry.zones():
		if z.is_surface == zone.is_surface and z.order == _previous_order(zone) and not is_cleared(z):
			return "Terminez « %s »" % z.display_name
	return ""


func _previous_order(zone: ZoneData) -> int:
	var prev := -1
	for z in DataRegistry.zones():
		if z.is_surface == zone.is_surface and z.order < zone.order:
			prev = maxi(prev, z.order)
	return prev


func stage_unlocked(zone: ZoneData, stage: int) -> bool:
	return stage <= zone_progress(zone)


## Récompenses d'une victoire en zone ; retourne le détail obtenu.
const RECRUIT_CHANCE := [0.25, 0.3, 0.5]


func grant(zone: ZoneData, stage: int, collection: CollectionState, wallet: Wallet, rng: RandomNumberGenerator, city: CityState = null) -> Dictionary:
	var enc := zone.encounter(stage)
	var got := {}
	for id in enc.rewards:
		got[id] = wallet.add(id, enc.rewards[id])
	var first := stage >= zone_progress(zone)
	if first:
		for id in enc.first_clear_rewards:
			got[id] = int(got.get(id, 0)) + wallet.add(id, enc.first_clear_rewards[id])
		progress[zone.id] = stage + 1
	var frag := {}
	var pool := DataRegistry.all_heroes().filter(func(h): return not h.is_god and (h.requires_temple == 0 or zone.is_surface))
	var h: HeroData = pool[rng.randi() % pool.size()]
	collection.add_fragments(h.id, enc.fragment_reward)
	frag[h.id] = enc.fragment_reward
	# Une créature de la zone peut rejoindre la cité (s'il reste de la place).
	var recruit := ""
	var wild := Array(zone.monster_ids).filter(func(id): return DataRegistry.monster(id) != null and DataRegistry.monster(id).lab_weight > 0.0)
	if not wild.is_empty() and rng.randf() < RECRUIT_CHANCE[clampi(stage, 0, 2)] \
			and (city == null or collection.monsters.size() < collection.monster_capacity(city)):
		recruit = wild[rng.randi() % wild.size()]
		collection.add_monster(recruit, maxi(1, zone.base_level / 2))
	changed.emit()
	return {"resources": got, "fragments": frag, "first": first, "recruit": recruit}


# --- Expéditions ----------------------------------------------------------------

static func slots(city: CityState) -> int:
	var lvl := 0
	for b in city.buildings.values():
		if b.data_id == "explorer_tower":
			lvl = maxi(lvl, b.level)
	if lvl < 1:
		return 0
	return 1 + (lvl - 1) / 3 + (1 if city.best_level("surface_lift") > 0 else 0)


## Durée d'une expédition, raccourcie par l'Ascenseur de surface (−6 % par niveau).
static func duration(hours: int, city: CityState) -> float:
	return hours * 3600.0 * (1.0 - 0.06 * city.best_level("surface_lift"))


func hero_busy(hero_id: String) -> bool:
	return expeditions.any(func(e): return e.hero == hero_id)


func start_reason(zone: ZoneData, hero_id: String, city: CityState, collection: CollectionState) -> String:
	if slots(city) < 1:
		return "Construisez une Tour des explorateurs"
	if expeditions.size() >= slots(city):
		return "Toutes les équipes d'exploration sont parties"
	if zone_progress(zone) < 1:
		return "Remportez d'abord un combat dans cette zone"
	if not collection.owns_hero(hero_id) or hero_busy(hero_id):
		return "Héros indisponible"
	return ""


func start(zone: ZoneData, hero_id: String, hours: int, city: CityState, collection: CollectionState, now: float) -> String:
	var reason := start_reason(zone, hero_id, city, collection)
	if reason != "":
		return reason
	expeditions.append({"zone": zone.id, "hero": hero_id, "start": now, "end": now + duration(hours, city), "hours": hours})
	changed.emit()
	return ""


## Butin attendu : ressources de la zone × durée, bonus selon la puissance du héros.
static func expected_loot(zone: ZoneData, hours: int, hero_power: int) -> Dictionary:
	var k := hours * 0.6 * (1.0 + hero_power / 2000.0)
	var out := {}
	for id in zone.resource_drops:
		out[id] = maxi(1, int(zone.resource_drops[id] * k))
	return out


func claim(index: int, collection: CollectionState, wallet: Wallet, now: float) -> Dictionary:
	if index < 0 or index >= expeditions.size() or now < float(expeditions[index].end):
		return {"error": "Expédition en cours"}
	var e: Dictionary = expeditions[index]
	var zone := DataRegistry.zone(e.zone)
	var loot := expected_loot(zone, int(e.hours), collection.hero_power(e.hero))
	var got := {}
	for id in loot:
		got[id] = wallet.add(id, loot[id])
	expeditions.remove_at(index)
	changed.emit()
	return {"resources": got, "hero": e.hero, "zone": e.zone}


func to_dict() -> Dictionary:
	return {"progress": progress.duplicate(), "expeditions": expeditions.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	progress = {}
	for k in d.get("progress", {}):
		progress[str(k)] = int(d.progress[k])
	expeditions = d.get("expeditions", []).filter(func(e): return DataRegistry.zone(str(e.get("zone", ""))) != null)
