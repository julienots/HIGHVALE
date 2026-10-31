class_name Combatant
extends RefCounted
## Combattant d'une bataille : statistiques, énergie, recharges, états.

const NEGATIVE := [GameEnums.StatusEffect.BURN, GameEnums.StatusEffect.FREEZE, GameEnums.StatusEffect.POISON,
	GameEnums.StatusEffect.PARALYSIS, GameEnums.StatusEffect.WEAKEN, GameEnums.StatusEffect.STUN]

var uid := 0
var name := ""
var side := 0  # 0 joueur, 1 ennemi
var slot := 0
var source_id := ""  # id de HeroData ou MonsterData
var is_hero := false
var is_boss := false
var phase := 0
var element := 0
var rarity := 0
var max_hp := 1
var hp := 1
var attack := 1
var defense := 0
var speed := 100
var crit_chance := 0.05
var crit_multiplier := 1.5
var energy := 0
var shield := 0
var skills: Array = []  # SkillData
var cooldowns := {}  # skill id -> tours restants
var statuses: Array = []  # { effect, turns }
var model_scene: PackedScene
var portrait: Texture2D


static func from_hero(h: HeroData, level: int, stars: int) -> Combatant:
	var c := Combatant.new()
	c._init_from(h.display_name, h.id, h.element, h.rarity, CollectionState.effective_stats(h.stats, level, stars), h.skills)
	c.is_hero = true
	c.model_scene = h.model_scene
	c.portrait = h.portrait
	return c


static func from_monster(m: MonsterData, level: int, bonus_stars := 1) -> Combatant:
	var c := Combatant.new()
	c._init_from(m.display_name, m.id, m.element, m.rarity, CollectionState.effective_stats(m.stats, level, bonus_stars), m.skills)
	c.model_scene = m.model_scene
	c.portrait = m.portrait
	return c


func _init_from(p_name: String, id: String, el: int, rar: int, s: Dictionary, p_skills: Array) -> void:
	name = p_name
	source_id = id
	element = el
	rarity = rar
	max_hp = s.max_hp
	hp = max_hp
	attack = s.attack
	defense = s.defense
	speed = s.speed
	crit_chance = s.crit_chance
	crit_multiplier = s.crit_multiplier
	skills = p_skills.duplicate()


func is_alive() -> bool:
	return hp > 0


func has_status(effect: int) -> bool:
	for s in statuses:
		if s.effect == effect:
			return true
	return false


func add_status(effect: int, turns: int) -> void:
	for s in statuses:
		if s.effect == effect:
			s.turns = maxi(s.turns, turns)
			return
	statuses.append({"effect": effect, "turns": turns})


func can_use(skill: SkillData) -> bool:
	return energy >= skill.energy_cost and int(cooldowns.get(skill.id, 0)) <= 0


func hp_ratio() -> float:
	return float(hp) / max_hp


func power_rating() -> int:
	return CollectionState.power({"max_hp": max_hp, "attack": attack, "defense": defense, "speed": speed})
