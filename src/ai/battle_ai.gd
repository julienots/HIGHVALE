class_name BattleAI
extends RefCounted
## IA tactique : choisit compétence et cible selon l'énergie, les recharges,
## l'état de l'équipe, l'avantage élémentaire et une stratégie.

static func choose(battle: BattleState, actor: Combatant, strategy := "balanced") -> Dictionary:
	var usable := actor.skills.filter(func(s): return actor.can_use(s))
	if usable.is_empty():
		usable = [actor.skills[0]]
	var allies := battle.team(actor.side, true)
	var hurt := allies.filter(func(c): return c.hp_ratio() < 0.5)
	# 1. Soigner si un allié est en danger
	for s: SkillData in usable:
		if s.heal_power > 0.0 and not hurt.is_empty() and s.power <= 0.0:
			hurt.sort_custom(func(a, b): return a.hp_ratio() < b.hp_ratio())
			return {"skill": s, "target": hurt[0]}
	# 2. Protéger l'équipe quand elle souffre (ou dès le début pour un gardien)
	for s: SkillData in usable:
		if s.shield_power > 0.0 and s.power <= 0.0 and (hurt.size() > 0 or battle.round <= 1):
			return {"skill": s, "target": actor}
	# 3. Attaque : ultime, puis zone si plusieurs ennemis, puis spéciale, puis base
	var foes := battle.team(1 - actor.side, true)
	var attacks := usable.filter(func(s): return s.power > 0.0)
	if attacks.is_empty():
		attacks = usable
	attacks.sort_custom(func(a, b): return _score(a, foes.size()) > _score(b, foes.size()))
	var skill: SkillData = attacks[0]
	return {"skill": skill, "target": pick_target(battle, actor, skill, strategy)}


static func _score(s: SkillData, foes: int) -> float:
	var aoe := s.target in [SkillData.Target.ALL_ENEMIES, SkillData.Target.ROW_ENEMIES, SkillData.Target.RANDOM_ENEMIES]
	var total := s.power * maxi(s.hits, 1) * (mini(foes, 3) if aoe else 1)
	return total + s.kind * 0.5 + (0.3 if s.status_effect != GameEnums.StatusEffect.NONE else 0.0)


static func pick_target(battle: BattleState, actor: Combatant, skill: SkillData, strategy: String) -> Combatant:
	var options := battle.valid_targets(actor, skill)
	if options.is_empty():
		return null
	if skill.target == SkillData.Target.SINGLE_ALLY:
		options.sort_custom(func(a, b): return a.hp_ratio() < b.hp_ratio())
		return options[0]
	var best: Combatant = options[0]
	var best_score := -INF
	for c: Combatant in options:
		var score := BattleState.element_multiplier(skill.element, c.element) * 2.0
		match strategy:
			"focus_weak":
				score += (1.0 - c.hp_ratio()) * 3.0
			"aggressive":
				score += c.attack / 50.0
			_:
				score += (1.0 - c.hp_ratio()) * 1.5 + c.attack / 100.0
		if score > best_score:
			best_score = score
			best = c
	return best
