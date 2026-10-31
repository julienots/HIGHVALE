extends TestCase
## Moteur de combat, IA, défis et équipe.


func _skill(power := 1.0, status := GameEnums.StatusEffect.NONE, chance := 0.0, target := SkillData.Target.SINGLE_ENEMY) -> SkillData:
	var s := SkillData.new()
	s.id = "test_%d" % randi()
	s.power = power
	s.status_effect = status
	s.status_chance = chance
	s.target = target
	return s


func _unit(hp := 500, atk := 50, def := 20, spd := 100, el := 0) -> Combatant:
	var c := Combatant.new()
	c.name = "u"
	c.max_hp = hp
	c.hp = hp
	c.attack = atk
	c.defense = def
	c.speed = spd
	c.element = el
	c.skills = [_skill()]
	return c


func test_turn_order_by_speed() -> void:
	var b := BattleState.new()
	var fast := _unit(500, 50, 20, 150)
	var slow := _unit(500, 50, 20, 80)
	b.setup([slow], [fast], 1)
	eq(b.begin_turn().actor, fast, "le plus rapide joue en premier")


func test_damage_elements_shield_and_death() -> void:
	eq(BattleState.element_multiplier(GameEnums.Element.WATER, GameEnums.Element.FIRE), BattleState.ADV_MULT, "l'eau bat le feu")
	eq(BattleState.element_multiplier(GameEnums.Element.FIRE, GameEnums.Element.WATER), BattleState.DISADV_MULT, "le feu craint l'eau")
	var b := BattleState.new()
	var a := _unit(500, 80)
	var t := _unit(40, 10, 0)
	b.setup([a], [t], 2)
	t.shield = 30
	var ev := b.act(a, a.skills[0], t)
	var dmg: Dictionary = ev.filter(func(e): return e.type == "damage")[0]
	eq(dmg.absorbed, 30, "le bouclier absorbe d'abord")
	check(not t.is_alive(), "cible vaincue")
	eq(b.winner, 0, "victoire détectée")


func test_statuses() -> void:
	var b := BattleState.new()
	var a := _unit(500, 10)
	var t := _unit(1000, 10)
	b.setup([a], [t], 3)
	b.act(a, _skill(0.1, GameEnums.StatusEffect.STUN, 1.0), t)
	check(t.has_status(GameEnums.StatusEffect.STUN), "étourdissement appliqué")
	var hp := t.hp
	t.add_status(GameEnums.StatusEffect.BURN, 2)
	var turn := b.begin_turn()
	while turn.actor != t:
		turn = b.begin_turn()
	check(turn.skipped, "un combattant étourdi passe son tour")
	check(t.hp < hp, "la brûlure inflige des dégâts en début de tour")


func test_taunt_forces_target() -> void:
	var b := BattleState.new()
	var a := _unit()
	var t1 := _unit()
	var t2 := _unit()
	b.setup([a], [t1, t2], 4)
	t2.add_status(GameEnums.StatusEffect.TAUNT, 2)
	eq(b.valid_targets(a, a.skills[0]), [t2], "la provocation impose la cible")


func test_ai_heals_wounded_ally() -> void:
	var b := BattleState.new()
	var healer := Combatant.from_hero(DataRegistry.hero("mirela"), 5, 1)
	var friend := Combatant.from_hero(DataRegistry.hero("bram"), 5, 1)
	var foe := Combatant.from_monster(DataRegistry.monster("gloubi"), 1)
	b.setup([healer, friend], [foe], 5)
	friend.hp = int(friend.max_hp * 0.2)
	healer.energy = 100
	var choice := BattleAI.choose(b, healer)
	check(choice.skill.heal_power > 0.0, "l'IA soigne un allié en danger")


func test_full_auto_battle_and_rewards() -> void:
	var coll := CollectionState.new()
	coll.unlock_hero("bram")
	coll.unlock_hero("lysa")
	coll.unlock_hero("mirela")
	coll.add_monster("gloubi", 3)
	coll.default_team()
	eq(coll.team.size(), 4, "équipe par défaut")
	var enc: EncounterData = DataRegistry.encounters()[0]
	check(BattleSetup.is_unlocked(enc, coll), "premier défi débloqué")
	check(not BattleSetup.is_unlocked(DataRegistry.encounters()[2], coll), "défis suivants verrouillés")
	var b := BattleState.new()
	b.setup(coll.build_team_combatants(), BattleSetup.enemies_for(enc), 6)
	var guard := 0
	while not b.is_over() and guard < 500:
		guard += 1
		var turn := b.begin_turn()
		if turn.is_empty() or turn.skipped:
			continue
		var c := BattleAI.choose(b, turn.actor, enc.strategy if turn.actor.side == 1 else "balanced")
		b.act(turn.actor, c.skill, c.target)
	eq(b.winner, 0, "l'équipe de départ gagne le premier défi")
	var w := Wallet.new()
	var got := BattleSetup.grant_victory(enc, coll, w, b.rng)
	check(got.first and coll.stages_cleared == 1, "première victoire enregistrée")
	check(w.amount("gold") > 0, "récompenses versées")
	eq(DataRegistry.encounters().size(), 10, "10 défis")
	var boss := BattleSetup.enemies_for(DataRegistry.encounters()[9])
	check(boss[0].is_boss and boss[0].max_hp > Combatant.from_monster(DataRegistry.monster("dragonling"), 15).max_hp, "boss renforcé")
