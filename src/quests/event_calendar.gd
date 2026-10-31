class_name EventCalendar
extends RefCounted
## Événements hebdomadaires tournants : bonus de récompenses et boss d'événement.

const EVENTS := [
	{"id": "crystal_week", "name": "Semaine des cristaux", "desc": "Les cristaux chantent : +50 % de récompenses en combat. Le Golem ancestral s'est réveillé !",
	 "boss": "crystal_golem", "adds": ["crystal_bat", "crystal_chimera"], "color": Color("7fdcff"), "reward": {"abyssal_crystal": 120, "prisms": 40}},
	{"id": "fire_festival", "name": "Fête des braises", "desc": "Les forges s'embrasent : +50 % de récompenses en combat. Le Dragonnet ardent attaque !",
	 "boss": "dragonling", "adds": ["fire_salamander", "magma_slime"], "color": Color("ff8a3a"), "reward": {"dark_ore": 25, "prisms": 40}},
	{"id": "spore_bloom", "name": "Floraison des spores", "desc": "La forêt fongique fleurit : +50 % de récompenses en combat. Un champignon colossal surgit !",
	 "boss": "shroomling", "adds": ["wisp", "gloubi"], "color": Color("6ff5e0"), "reward": {"underground_nectar": 300, "prisms": 40}},
	{"id": "shadow_moon", "name": "Lune d'ombre", "desc": "Les ténèbres montent : +50 % de récompenses en combat. Le Hibou des abysses chasse !",
	 "boss": "abyss_owl", "adds": ["crystal_bat", "wisp"], "color": Color("b48aff"), "reward": {"divine_dust": 6, "prisms": 40}},
]
const REWARD_BONUS := 1.5


static func current(now: float) -> Dictionary:
	return EVENTS[(QuestState.day_index(now) / 7) % EVENTS.size()]


static func ends_in(now: float) -> float:
	var week_start := float(QuestState.day_index(now) / 7 * 7) * QuestState.DAY
	return week_start + 7.0 * QuestState.DAY - now


## Boss d'événement, adapté à la progression (niveau selon les défis remportés).
static func boss_encounter(now: float, collection: CollectionState) -> EncounterData:
	var ev := current(now)
	var lvl := 4 + collection.stages_cleared * 2
	var e := EncounterData.new()
	e.id = "event_" + ev.id
	e.display_name = ev.name + " — Boss"
	e.description = ev.desc
	e.strategy = "aggressive"
	var list: Array[Dictionary] = [{"id": ev.boss, "level": lvl + 3, "boss": true}]
	for a in ev.adds:
		list.append({"id": a, "level": lvl, "boss": false})
	e.enemies = list
	e.rewards = ev.reward
	return e
