extends TestCase
## Assauts en temps réel : bases aléatoires, déploiement, remparts, défenses, étoiles.


func _deck(coll: CollectionState) -> Array:
	return RaidSim.build_deck(coll, 0.0)


func _strong_collection() -> CollectionState:
	var c := CollectionState.new()
	for id in ["bram", "lysa", "mirela", "noctis", "magnus"]:
		c.unlock_hero(id)
		c.heroes[id].level = 30
		c.heroes[id].stars = 5
	c.add_monster("plains_wolf", 20)
	c.add_monster("storm_eagle", 20)
	c.default_team()
	return c


func test_random_bases_are_valid() -> void:
	var names := {}
	for lvl in range(1, 11):
		for seed in [1, 2, 3]:
			var base := RaidBaseGen.generate(lvl, lvl * 100 + seed)
			names[base.name] = true
			var occ := {}
			var keeps := 0
			var walls := 0
			var defs := 0
			for s in base.structures:
				var fp := RaidBaseGen._size(s.data_id)
				check(s.cell.x >= 2 and s.cell.y >= 2 and s.cell.x + fp.x <= base.width - 2 and s.cell.y + fp.y <= base.height - 2, "dans la carte")
				for x in range(s.cell.x, s.cell.x + fp.x):
					for y in range(s.cell.y, s.cell.y + fp.y):
						check(not occ.has(Vector2i(x, y)), "pas de chevauchement (niveau %d)" % lvl)
						occ[Vector2i(x, y)] = true
				keeps += 1 if s.data_id == "raid_keep" else 0
				walls += 1 if s.data_id == "wall" else 0
				defs += 1 if DataRegistry.building(s.data_id) and DataRegistry.building(s.data_id).is_defense() else 0
			eq(keeps, 1, "un donjon")
			check(walls >= 8, "des remparts (niveau %d : %d)" % [lvl, walls])
			check(defs >= 3, "des défenses")
	check(names.size() >= 10, "bases variées (%d noms)" % names.size())


func test_deploy_rules_and_elixir() -> void:
	var sim := RaidSim.new()
	sim.setup(RaidBaseGen.generate(1, 7), _deck(_strong_collection()), 180.0, false, 1)
	check(sim.hand().size() == 4, "4 cartes en main")
	check(not sim.can_deploy_at(Vector2i(17, 12)), "pas de déploiement dans la base")
	check(sim.can_deploy_at(Vector2i(0, 0)), "déploiement au bord")
	sim.elixir = 0.0
	eq(sim.deploy(0, Vector2i(0, 0)), "Pas assez d'énergie", "énergie requise")
	sim.elixir = 10.0
	var first: int = sim.hand()[0]
	eq(sim.deploy(0, Vector2i(0, 0)), "", "déploiement")
	check(sim.units.size() >= 1, "unité sur le terrain")
	check(sim.hand()[0] != first or sim.deck.size() <= 4, "la carte jouée retourne au fond du paquet")
	sim.step(2.0)
	check(sim.elixir > 10.0 - sim.deck[first].cost, "l'énergie se recharge")


func test_attack_destroys_and_walls_block() -> void:
	var sim := RaidSim.new()
	var base := RaidBaseGen.generate(1, 42)
	sim.setup(base, _deck(_strong_collection()), 180.0, false, 3)
	var blocked := false
	var shots := 0
	var t := 0.0
	while not sim.is_over() and t < 180.0:
		sim.elixir = 10.0
		for slot in 4:
			sim.deploy(slot, Vector2i(1, 1 + (int(t) % 20)))
		sim.step(0.5)
		t += 0.5
		for e in sim.drain_events():
			blocked = blocked or e.type == "blocked"
			shots += 1 if e.type == "shot" else 0
	check(sim.destruction() > 0.3, "la base est en partie détruite (%.0f %%)" % (sim.destruction() * 100))
	check(shots > 0, "les défenses tirent")
	check(blocked or sim.structures.any(func(s): return s.is_wall and not s.alive()), "les remparts arrêtent les unités")
	check(sim.stars() >= 1, "au moins une étoile avec une armée forte (%d)" % sim.stars())
	check(not sim.loot().is_empty(), "butin")


func test_weak_army_fails_against_strong_base() -> void:
	var c := CollectionState.new()
	c.unlock_hero("bram")
	c.default_team()
	var sim := RaidSim.new()
	sim.setup(RaidBaseGen.generate(10, 5), _deck(c), 60.0, false, 4)
	sim.deploy(0, Vector2i(0, 0))
	for i in 1300:
		sim.step(0.05)
	check(sim.is_over(), "fin du temps")
	eq(sim.stars(), 0, "aucune étoile")
	check(RaidRules.trophy_change(0, 10) < 0, "trophées perdus")


func test_city_defense_mode() -> void:
	var city := CityState.new()
	city.configure(DataRegistry.config)
	city.add_built("primordial_temple", Vector2i(18, 18), 3, 0.0)
	city.add_built("archer_tower", Vector2i(14, 18), 3, 0.0)
	city.add_built("cannon", Vector2i(23, 18), 3, 0.0)
	for x in range(13, 26):
		city.add_built("wall", Vector2i(x, 16), 2, 0.0)
	var sim := RaidSim.new()
	sim.waves = RaidBaseGen.defense_waves(1, 9)
	sim.setup(RaidBaseGen.from_city(city), _deck(_strong_collection()), 120.0, true, 5)
	check(sim.can_deploy_at(Vector2i(19, 23)), "défenseurs près du Temple")
	check(not sim.can_deploy_at(Vector2i(1, 1)), "pas loin du Temple")
	sim.elixir = 10.0
	eq(sim.deploy(0, Vector2i(19, 23)), "", "défenseur déployé")
	var kills := 0
	for i in 2600:
		sim.step(0.05)
		for e in sim.drain_events():
			kills += 1 if e.type == "unit_dead" else 0
		if sim.is_over():
			break
	check(sim.is_over(), "défense terminée")
	check(kills > 0, "des assaillants tombent")
