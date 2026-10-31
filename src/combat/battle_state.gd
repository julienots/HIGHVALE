class_name BattleState
extends RefCounted
## Moteur de combat au tour par tour, sans affichage : ordre par vitesse,
## compétences, éléments, critiques, boucliers, états, synergies et fin de combat.
## Chaque action renvoie une liste d'événements que la scène anime.

const ADVANTAGE := {
	GameEnums.Element.FIRE: [GameEnums.Element.NATURE, GameEnums.Element.CRYSTAL],
	GameEnums.Element.WATER: [GameEnums.Element.FIRE, GameEnums.Element.EARTH],
	GameEnums.Element.EARTH: [GameEnums.Element.AIR, GameEnums.Element.FIRE],
	GameEnums.Element.AIR: [GameEnums.Element.NATURE, GameEnums.Element.WATER],
	GameEnums.Element.NATURE: [GameEnums.Element.WATER, GameEnums.Element.EARTH],
	GameEnums.Element.CRYSTAL: [GameEnums.Element.AIR, GameEnums.Element.SHADOW],
	GameEnums.Element.LIGHT: [GameEnums.Element.SHADOW, GameEnums.Element.VOID],
	GameEnums.Element.SHADOW: [GameEnums.Element.LIGHT, GameEnums.Element.NATURE],
	GameEnums.Element.VOID: [GameEnums.Element.LIGHT, GameEnums.Element.CRYSTAL],
}
const ADV_MULT := 1.3
const DISADV_MULT := 0.8
const MAX_ROUNDS := 30

var units: Array = []  # Combatant
var round := 0
var winner := -1  # 0 joueur, 1 ennemi, 2 égalité (limite de tours)
var rng := RandomNumberGenerator.new()
var _queue: Array = []
var _next_uid := 1


func setup(player: Array, enemies: Array, seed := 0) -> void:
	rng.seed = seed if seed != 0 else randi()
	for side in 2:
		var list: Array = player if side == 0 else enemies
		for i in list.size():
			var c: Combatant = list[i]
			c.side = side
			c.slot = i
			c.uid = _next_uid
			_next_uid += 1
			units.append(c)
	_apply_synergies()


## Synergie élémentaire : +10 % d'attaque si au moins 3 membres partagent un élément.
func synergy(side: int) -> int:
	var counts := {}
	for c in team(side):
		counts[c.element] = int(counts.get(c.element, 0)) + 1
	for el in counts:
		if counts[el] >= 3:
			return el
	return -1


func _apply_synergies() -> void:
	for side in 2:
		var el := synergy(side)
		if el >= 0:
			for c in team(side):
				if c.element == el:
					c.attack = int(c.attack * 1.1)


func team(side: int, alive_only := false) -> Array:
	return units.filter(func(c): return c.side == side and (not alive_only or c.is_alive()))


func is_over() -> bool:
	return winner >= 0


## Passe au combattant suivant. Retourne { actor, events, skipped }.
func begin_turn() -> Dictionary:
	if is_over():
		return {}
	if _queue.is_empty():
		round += 1
		if round > MAX_ROUNDS:
			winner = 2
			return {}
		_queue = units.filter(func(c): return c.is_alive())
		_queue.sort_custom(func(a, b): return a.speed > b.speed if a.speed != b.speed else a.uid < b.uid)
	var actor: Combatant = _queue.pop_front()
	if not actor.is_alive():
		return begin_turn()
	var events := []
	# Effets de début de tour
	for s in actor.statuses:
		match s.effect:
			GameEnums.StatusEffect.BURN, GameEnums.StatusEffect.POISON:
				var pct := 0.05 if s.effect == GameEnums.StatusEffect.BURN else 0.06
				var dmg := maxi(1, int(actor.max_hp * pct))
				actor.hp = maxi(actor.hp - dmg, 0)
				events.append({"type": "dot", "target": actor, "amount": dmg, "effect": s.effect})
			GameEnums.StatusEffect.REGEN:
				var heal := int(actor.max_hp * 0.06)
				actor.hp = mini(actor.hp + heal, actor.max_hp)
				events.append({"type": "heal", "target": actor, "amount": heal})
	if not actor.is_alive():
		events.append({"type": "death", "target": actor})
		_check_end()
		return {"actor": actor, "events": events, "skipped": true}
	var skipped := false
	if actor.has_status(GameEnums.StatusEffect.FREEZE) or actor.has_status(GameEnums.StatusEffect.STUN):
		skipped = true
	elif actor.has_status(GameEnums.StatusEffect.PARALYSIS) and rng.randf() < 0.5:
		skipped = true
	if skipped:
		events.append({"type": "skip", "target": actor})
		_end_turn(actor)
	return {"actor": actor, "events": events, "skipped": skipped}


## Cibles possibles pour une compétence (pour l'interface et l'IA).
func valid_targets(actor: Combatant, skill: SkillData) -> Array:
	match skill.target:
		SkillData.Target.SINGLE_ALLY:
			return team(actor.side, true)
		SkillData.Target.SELF, SkillData.Target.ALL_ALLIES:
			return [actor]
		_:
			var foes := team(1 - actor.side, true)
			var taunters := foes.filter(func(c): return c.has_status(GameEnums.StatusEffect.TAUNT))
			if skill.target == SkillData.Target.SINGLE_ENEMY and not taunters.is_empty():
				return taunters
			return foes


## Exécute une compétence. Retourne la liste des événements.
func act(actor: Combatant, skill: SkillData, target: Combatant) -> Array:
	var events := [{"type": "cast", "source": actor, "skill": skill, "target": target}]
	var targets := _resolve_targets(actor, skill, target)
	var hits := maxi(skill.hits, 1)
	for h in hits:
		var list: Array = targets
		if skill.target == SkillData.Target.RANDOM_ENEMIES:
			var foes := team(1 - actor.side, true)
			if foes.is_empty():
				break
			list = [foes[rng.randi() % foes.size()]]
		for t: Combatant in list:
			if not t.is_alive():
				continue
			if skill.power > 0.0:
				events.append_array(_damage(actor, t, skill))
			if skill.heal_power > 0.0 and t.side == actor.side:
				var heal := int(actor.attack * 2.5 * skill.heal_power + t.max_hp * 0.1 * skill.heal_power)
				t.hp = mini(t.hp + heal, t.max_hp)
				events.append({"type": "heal", "source": actor, "target": t, "amount": heal})
	# Bouclier : aux alliés ciblés, ou au lanceur pour une attaque.
	if skill.shield_power > 0.0:
		var shielded: Array = targets if targets.size() > 0 and targets[0].side == actor.side else [actor]
		for t: Combatant in shielded:
			var amount := int(actor.max_hp * skill.shield_power * 0.3)
			t.shield += amount
			events.append({"type": "shield", "source": actor, "target": t, "amount": amount})
	# États
	if skill.status_effect != GameEnums.StatusEffect.NONE:
		var negative: bool = skill.status_effect in Combatant.NEGATIVE
		var affected: Array = targets if negative or (targets.size() > 0 and targets[0].side == actor.side) else [actor]
		for t: Combatant in affected:
			if t.is_alive() and rng.randf() < skill.status_chance:
				t.add_status(skill.status_effect, skill.status_turns)
				events.append({"type": "status", "target": t, "effect": skill.status_effect})
	actor.energy = clampi(actor.energy - skill.energy_cost + skill.energy_gain, 0, 100)
	if skill.cooldown_turns > 0:
		actor.cooldowns[skill.id] = skill.cooldown_turns + 1
	_end_turn(actor)
	_check_end()
	return events


func _resolve_targets(actor: Combatant, skill: SkillData, target: Combatant) -> Array:
	match skill.target:
		SkillData.Target.SINGLE_ENEMY, SkillData.Target.SINGLE_ALLY:
			var valid := valid_targets(actor, skill)
			return [target if target in valid else valid[0]] if not valid.is_empty() else []
		SkillData.Target.ALL_ENEMIES:
			return team(1 - actor.side, true)
		SkillData.Target.ROW_ENEMIES:
			var foes := team(1 - actor.side, true)
			foes.sort_custom(func(a, b): return a.slot < b.slot)
			return foes.slice(0, 3)
		SkillData.Target.ALL_ALLIES:
			return team(actor.side, true)
		SkillData.Target.SELF:
			return [actor]
	return []


static func element_multiplier(attacker: int, defender: int) -> float:
	if defender in ADVANTAGE.get(attacker, []):
		return ADV_MULT
	if attacker in ADVANTAGE.get(defender, []):
		return DISADV_MULT
	return 1.0


func _damage(actor: Combatant, t: Combatant, skill: SkillData) -> Array:
	var mult := element_multiplier(skill.element, t.element)
	var crit := rng.randf() < actor.crit_chance
	var dmg := actor.attack * skill.power * (100.0 / (100.0 + t.defense)) * mult * rng.randf_range(0.92, 1.08)
	if crit:
		dmg *= actor.crit_multiplier
	if actor.has_status(GameEnums.StatusEffect.WEAKEN):
		dmg *= 0.75
	var amount := maxi(1, int(dmg))
	var absorbed := mini(t.shield, amount)
	t.shield -= absorbed
	t.hp = maxi(t.hp - (amount - absorbed), 0)
	t.energy = mini(t.energy + 10, 100)
	var events := [{"type": "damage", "source": actor, "target": t, "amount": amount, "absorbed": absorbed, "crit": crit,
		"advantage": 1 if mult > 1.0 else (-1 if mult < 1.0 else 0), "element": skill.element}]
	if not t.is_alive():
		t.statuses.clear()
		events.append({"type": "death", "target": t})
	return events


func _end_turn(actor: Combatant) -> void:
	for id in actor.cooldowns.keys():
		actor.cooldowns[id] = maxi(int(actor.cooldowns[id]) - 1, 0)
	for s in actor.statuses:
		s.turns -= 1
	actor.statuses = actor.statuses.filter(func(s): return s.turns > 0)


func _check_end() -> void:
	if team(0, true).is_empty():
		winner = 1
	elif team(1, true).is_empty():
		winner = 0
