class_name QuestState
extends RefCounted
## Missions quotidiennes et hebdomadaires, récompenses de connexion et passe saisonnier.
## Les missions du jour sont tirées de façon déterministe à partir de la date.

signal changed

const DAY := 86400.0
## id : [libellé, action suivie, objectif, récompense]
const POOL := {
	"collect": ["Collecter %d ressources", "collect", 800, {"gold": 300}],
	"build": ["Lancer %d chantiers", "build", 2, {"prisms": 10}],
	"harvest": ["Récolter %d ressources sauvages", "harvest", 2, {"ancient_shards": 5}],
	"battle": ["Remporter %d combats", "battle_win", 2, {"gold": 400, "prisms": 5}],
	"lab": ["Lancer %d expérience au Laboratoire", "lab", 1, {"vital_essence": 20}],
	"feed": ["Nourrir %d fois une créature", "feed", 2, {"underground_nectar": 60}],
	"hero_level": ["Améliorer %d fois un héros", "hero_level", 2, {"abyssal_crystal": 10}],
	"summon": ["Faire %d invocation", "summon", 1, {"ancient_shards": 10}],
}
const DAILY_COUNT := 4
const WEEKLY := {
	"w_battle": ["Remporter %d combats", "battle_win", 15, {"prisms": 60}],
	"w_build": ["Lancer %d chantiers", "build", 10, {"prisms": 40, "gold": 2000}],
	"w_collect": ["Collecter %d ressources", "collect", 8000, {"ancient_shards": 30}],
}
const LOGIN_REWARDS := [{"gold": 500}, {"prisms": 20}, {"ancient_shards": 15}, {"underground_nectar": 150},
	{"abyssal_crystal": 40}, {"prisms": 40}, {"divine_dust": 5, "prisms": 50}]
const PASS_XP_PER_TIER := 100
const PASS_TIERS := 20
const DAILY_XP := 20
const WEEKLY_XP := 80

var day := -1
var week := -1
var counters := {}  # action -> valeur (jour)
var week_counters := {}
var claimed := []  # missions récupérées (jour + semaine)
var login_day := -1
var login_streak := 0
var pass_xp := 0
var pass_claimed := 0


static func day_index(now: float) -> int:
	return int(now / DAY)


## Remet les compteurs à zéro au changement de jour ou de semaine.
func roll(now: float) -> void:
	var d := day_index(now)
	if d != day:
		day = d
		counters.clear()
		claimed = claimed.filter(func(id): return id.begins_with("w_"))
	var w := d / 7
	if w != week:
		week = w
		week_counters.clear()
		claimed = claimed.filter(func(id): return not id.begins_with("w_"))


func daily_ids() -> Array:
	var ids: Array = POOL.keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 13
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	return ids.slice(0, DAILY_COUNT)


func track(action: String, amount := 1) -> void:
	counters[action] = int(counters.get(action, 0)) + amount
	week_counters[action] = int(week_counters.get(action, 0)) + amount
	changed.emit()


func mission(id: String) -> Array:
	return WEEKLY[id] if id.begins_with("w_") else POOL[id]


func progress_of(id: String) -> int:
	var m := mission(id)
	return int((week_counters if id.begins_with("w_") else counters).get(m[1], 0))


func can_claim(id: String) -> bool:
	return not id in claimed and progress_of(id) >= int(mission(id)[2])


func claim(id: String, wallet: Wallet) -> Dictionary:
	if not can_claim(id):
		return {}
	claimed.append(id)
	var rew: Dictionary = mission(id)[3]
	for k in rew:
		wallet.add(k, rew[k])
	pass_xp += WEEKLY_XP if id.begins_with("w_") else DAILY_XP
	changed.emit()
	return rew


# --- Connexion -------------------------------------------------------------------

func login_available(now: float) -> bool:
	return day_index(now) != login_day


func claim_login(wallet: Wallet, now: float) -> Dictionary:
	if not login_available(now):
		return {}
	var d := day_index(now)
	login_streak = login_streak + 1 if d == login_day + 1 else 1
	login_day = d
	var rew: Dictionary = LOGIN_REWARDS[(login_streak - 1) % LOGIN_REWARDS.size()]
	for k in rew:
		wallet.add(k, rew[k])
	changed.emit()
	return rew


# --- Passe saisonnier ------------------------------------------------------------

func pass_tier() -> int:
	return mini(pass_xp / PASS_XP_PER_TIER, PASS_TIERS)


static func pass_reward(tier: int) -> Dictionary:
	if tier % 5 == 4:
		return {"prisms": 80, "divine_dust": 3}
	return [{"gold": 1000}, {"ancient_shards": 15}, {"abyssal_crystal": 30}, {"underground_nectar": 120}][tier % 4]


func claim_pass(wallet: Wallet) -> Dictionary:
	if pass_claimed >= pass_tier():
		return {}
	var rew := pass_reward(pass_claimed)
	pass_claimed += 1
	for k in rew:
		wallet.add(k, rew[k])
	changed.emit()
	return rew


func to_dict() -> Dictionary:
	return {"day": day, "week": week, "counters": counters.duplicate(), "week_counters": week_counters.duplicate(), "claimed": claimed.duplicate(),
		"login_day": login_day, "login_streak": login_streak, "pass_xp": pass_xp, "pass_claimed": pass_claimed}


func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", -1))
	week = int(d.get("week", -1))
	counters = d.get("counters", {}).duplicate()
	week_counters = d.get("week_counters", {}).duplicate()
	claimed = d.get("claimed", []).duplicate()
	login_day = int(d.get("login_day", -1))
	login_streak = int(d.get("login_streak", 0))
	pass_xp = int(d.get("pass_xp", 0))
	pass_claimed = int(d.get("pass_claimed", 0))
