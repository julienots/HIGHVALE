extends TestCase

const T0 := 1_000_000.0


func _city_with_temple(level := 1) -> CityState:
	var c := new_city()
	c.add_built("primordial_temple", Vector2i(18, 18), level, T0)
	c.add_built("inhabitants_hall", Vector2i(13, 18), 1, T0)
	return c


func test_placement_rules() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 1500, "fungal_wood": 1500, "stone": 1500})
	var mine := DataRegistry.building("stone_mine")
	check(c.place_new(mine, Vector2i(19, 19), w, T0) == null, "chevauchement refusé")
	check(c.place_new(mine, Vector2i(1, 1), w, T0) == null, "hors zone refusé")
	check(c.place_new(mine, Vector2i(35, 35), w, T0) == null, "dépassement du bord refusé")
	var b := c.place_new(mine, Vector2i(5, 5), w, T0)
	check(b != null, "placement valide accepté")
	eq(b.level, 0, "niveau 0 pendant la construction")
	eq(w.amount("gold"), 1500 - mine.cost_for_level(1)["gold"], "coût payé")


func test_builders_limit() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 3000, "fungal_wood": 3000, "stone": 3000})
	eq(c.builders_total(), 2, "1 de base + 1 par Hôtel")
	var mine := DataRegistry.building("stone_mine")
	var grove := DataRegistry.building("fungal_grove")
	check(c.place_new(mine, Vector2i(4, 4), w, T0) != null, "1er chantier")
	check(c.place_new(grove, Vector2i(8, 4), w, T0) != null, "2e chantier")
	eq(c.can_build_reason(grove, w), "Aucun bâtisseur disponible", "3e chantier bloqué")


func test_max_count_and_temple_lock() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 3000, "fungal_wood": 3000, "stone": 3000})
	check(c.can_build_reason(DataRegistry.building("crystal_mine"), w).begins_with("Temple"), "mine cristalline verrouillée au Temple 1")
	check(c.can_build_reason(DataRegistry.building("primordial_temple"), w).begins_with("Nombre maximal"), "un seul Temple")
	check(c.can_build_reason(DataRegistry.building("infirmary"), w).begins_with("Temple"), "Infirmerie verrouillée au Temple 1")
	for b in DataRegistry.all_buildings():
		check(b.feature == "" or FeatureFlags.is_enabled(b.feature), "module livré : %s" % b.id)


func test_construction_completes_in_order() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 3000, "fungal_wood": 3000, "stone": 3000})
	var mine := DataRegistry.building("stone_mine")
	var b := c.place_new(mine, Vector2i(5, 5), w, T0)
	eq(c.update(T0 + 1.0).size(), 0, "pas encore terminé")
	var done := c.update(T0 + mine.build_seconds_for_level(1))
	eq(done.size(), 1, "terminé à l'échéance")
	eq(b.level, 1, "niveau 1 atteint")
	eq(b.prod_since, T0 + mine.build_seconds_for_level(1), "production démarre à la fin réelle du chantier")


func test_production_accumulates_and_caps() -> void:
	var c := _city_with_temple()
	var b := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	c.inhabitants = 2
	c.auto_assign(T0)
	var d := b.data()
	var half_hour := b.stored_production(T0 + 1800.0)
	check(absf(half_hour - d.production_per_hour(1) / 2.0) < 0.01, "production proportionnelle au temps")
	eq(b.stored_production(T0 + 100000.0), float(d.internal_capacity(1)), "réserve interne plafonnée")


func test_collect_respects_wallet_space() -> void:
	var c := _city_with_temple()
	var b := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	c.inhabitants = 2
	c.auto_assign(T0)
	var w := new_wallet(c)
	var cap := w.capacity("stone")
	w.set_amount("stone", cap - 100)
	var got := c.collect(b, w, T0 + 3600.0)
	eq(got, 100, "collecte limitée à la place libre")
	check(b.stored_production(T0 + 3600.0) > 0.0, "le reste demeure dans la mine")


func test_upgrade_pauses_production_and_level_cap() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 2000, "fungal_wood": 2000, "stone": 2000})
	var b := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	eq(c.start_upgrade(b, w, T0 + 600.0), "", "amélioration lancée")
	var frozen := b.stored_production(T0 + 600.0)
	eq(b.stored_production(T0 + 700.0), frozen, "production en pause pendant le chantier")
	c.update(T0 + 600.0 + b.data().build_seconds_for_level(2))
	eq(b.level, 2, "niveau 2")
	eq(c.can_upgrade_reason(b, w), "Améliorez le Temple Primordial", "plafond lié au Temple")


func test_cancel_refunds_half() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 1000, "fungal_wood": 1000})
	var mine := DataRegistry.building("stone_mine")
	var b := c.place_new(mine, Vector2i(5, 5), w, T0)
	var cost := mine.cost_for_level(1)
	c.cancel_task(b, w, T0 + 1.0)
	eq(w.amount("gold"), 1000 - cost["gold"] + cost["gold"] / 2, "50 % remboursé")
	check(c.get_building(b.uid) == null, "construction annulée retirée")
	check(c.is_area_free(Vector2i(5, 5), mine.footprint), "emplacement libéré")


func test_speedup_cost() -> void:
	var c := _city_with_temple()
	var cfg := DataRegistry.config
	var w := new_wallet(c, {"gold": 5000, "stone": 5000, "fungal_wood": 5000, "prisms": 10})
	var temple := c.building_at(Vector2i(18, 18))
	c.start_upgrade(temple, w, T0)
	eq(c.speedup_cost(temple, temple.task_end - 10.0, cfg), 0, "gratuit sous 30 s")
	var cost := c.speedup_cost(temple, T0, cfg)
	check(cost > 0, "payant sinon")
	check(c.speed_up(temple, w, T0, cfg) == (cost <= 10), "accélération selon les prismes disponibles")


func test_move() -> void:
	var c := _city_with_temple()
	var b := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	check(not c.move(b, Vector2i(17, 17)), "déplacement sur le Temple refusé")
	check(c.move(b, Vector2i(6, 5)), "déplacement chevauchant sa propre emprise accepté")
	check(c.building_at(Vector2i(5, 5)) == null, "ancienne case libérée")
	eq(c.building_at(Vector2i(8, 7)), b, "nouvelle emprise occupée")


func test_storage_capacity_from_buildings() -> void:
	var c := _city_with_temple()
	var base := c.storage_capacity("gold")
	c.add_built("treasury", Vector2i(5, 5), 1, T0)
	eq(c.storage_capacity("gold"), base + 1500, "la Trésorerie augmente la capacité d'or")


func test_serialization_roundtrip() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 2000, "fungal_wood": 2000, "stone": 2000})
	var b := c.place_new(DataRegistry.building("stone_mine"), Vector2i(5, 5), w, T0)
	var data: Dictionary = JSON.parse_string(JSON.stringify(c.to_dict()))
	var c2 := new_city()
	c2.from_dict(data)
	eq(c2.buildings.size(), c.buildings.size(), "même nombre de bâtiments")
	var b2 := c2.get_building(b.uid)
	eq(b2.task, BuildingState.Task.CONSTRUCTING, "chantier conservé")
	eq(b2.task_cost, b.task_cost, "coût du chantier conservé")
	eq(c2.building_at(Vector2i(6, 6)), b2, "occupation reconstruite")
	var b3 := c2.add_built("fungal_grove", Vector2i(9, 9), 1, T0)
	check(b3.uid > b.uid, "identifiants uniques après chargement")


func test_population_grows_to_capacity() -> void:
	var c := _city_with_temple()
	c.inhabitants = 2
	c.growth_since = T0
	var cap := c.population_capacity()
	c.update_population(T0 + c.growth_interval(T0) * 3 + 1.0)
	eq(c.inhabitants, 5, "trois arrivées en trois intervalles")
	c.update_population(T0 + 100000.0)
	eq(c.inhabitants, cap, "plafonné par les logements (y compris hors ligne)")
	eq(c.next_arrival_in(T0 + 100000.0), -1.0, "plus d'arrivée quand c'est plein")


func test_workers_assigned_and_efficiency() -> void:
	var c := _city_with_temple()
	var mine := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	var grove := c.add_built("fungal_grove", Vector2i(9, 5), 1, T0)
	eq(mine.efficiency(), 0.25, "25 % sans ouvrier")
	c.inhabitants = 3
	c.auto_assign(T0)
	eq(mine.workers + grove.workers, 3, "habitants libres affectés")
	check(absi(mine.workers - grove.workers) <= 1, "répartition équilibrée")
	c.inhabitants = 10
	c.auto_assign(T0)
	eq(mine.workers, mine.worker_slots(), "postes pourvus")
	eq(mine.efficiency(), 1.0, "100 % avec tous les postes")
	eq(c.idle_inhabitants(), 10 - mine.workers - grove.workers, "le reste est libre")


func test_efficiency_changes_production_rate() -> void:
	var c := _city_with_temple()
	var mine := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	var rate := mine.data().production_per_hour(1)
	check(absf(mine.stored_production(T0 + 360.0) - rate * 0.1 * 0.25) < 0.01, "production réduite sans ouvrier")
	c.inhabitants = 2
	c.auto_assign(T0 + 360.0)
	var before := mine.stored_production(T0 + 360.0)
	check(absf(mine.stored_production(T0 + 720.0) - before - rate * 0.1) < 0.01, "production complète ensuite, l'acquis est conservé")


func test_desired_workers_and_capacity_drop() -> void:
	var c := _city_with_temple()
	var mine := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
	c.inhabitants = 2
	c.auto_assign(T0)
	c.set_desired_workers(mine, 1, T0)
	eq(mine.workers, 1, "le joueur retire un ouvrier")
	eq(c.idle_inhabitants(), 1, "il redevient libre")
	c.set_desired_workers(mine, 5, T0)
	eq(mine.workers, mine.worker_slots(), "borné aux postes disponibles")
	c.inhabitants = c.population_capacity()
	c.remove(c.building_at(Vector2i(13, 18)))
	check(c.inhabitants <= c.population_capacity(), "habitants réduits si des logements disparaissent")
	check(c.workers_total() <= c.inhabitants, "jamais plus d'ouvriers que d'habitants")


func test_happiness_and_feast() -> void:
	var c := _city_with_temple()
	var cfg := DataRegistry.config
	var h0 := c.happiness(T0)
	eq(h0, cfg.base_happiness + 5, "base + confort du Temple")
	c.add_built("fountain", Vector2i(5, 5), 1, T0)
	eq(c.happiness(T0), h0 + 6, "la fontaine ajoute du bien-être")
	var slow := c.growth_interval(T0)
	var w := new_wallet(c, {"underground_nectar": 200})
	eq(c.start_feast(w, T0, cfg), "", "festin lancé")
	check(c.growth_interval(T0) < slow, "le festin accélère les arrivées")
	eq(c.start_feast(w, T0, cfg), "Un festin est déjà en cours", "pas de cumul")
	check(not c.feast_active(T0 + cfg.feast_seconds + 1.0), "le festin se termine")


func test_wilds_spawn_block_and_harvest() -> void:
	var c := _city_with_temple()
	c.next_wild_at = T0
	c.update_wilds(T0 + c.wild_spawn_seconds * 20)
	eq(c.wilds.size(), c.max_wilds, "apparitions hors ligne plafonnées")
	for cell in c.wilds:
		check(c.building_at(cell) == null, "jamais sur un bâtiment")
		check(not c.is_area_free(cell, Vector2i.ONE), "bloque la construction")
	var cell: Vector2i = c.wilds.keys()[0]
	var w := new_wallet(c)
	var got := c.harvest_wild(cell, w, "prisms", T0)
	check(not got.is_empty(), "récolte non vide")
	check(c.wild_at(cell) == "", "ressource retirée")
	var data: Dictionary = JSON.parse_string(JSON.stringify(c.to_dict()))
	var c2 := new_city()
	c2.from_dict(data)
	eq(c2.wilds.size(), c.wilds.size(), "ressources sauvages sauvegardées")


func test_research_effects() -> void:
	var c := _city_with_temple()
	var w := new_wallet(c, {"gold": 50000, "stone": 50000, "fungal_wood": 50000})
	var r := c.research
	check(r.reason("extraction", c, w).begins_with("Construisez"), "Bibliothèque requise")
	c.add_built("library", Vector2i(5, 28), 2, T0)
	var mine := c.add_built("stone_mine", Vector2i(10, 28), 1, T0)
	var base_rate := mine.stored_production(T0 + 3600)
	var base_cap := c.storage_capacity("stone")
	var base_time := c.build_seconds(DataRegistry.building("stone_mine"), 2)
	eq(r.start("extraction", c, w, T0), "", "recherche lancée")
	eq(r.reason("warehouses", c, w), "Une recherche est déjà en cours", "une seule recherche par bâtiment")
	c.update(T0 + r.seconds("extraction") + 1)
	eq(r.level("extraction"), 1, "recherche terminée")
	check(is_equal_approx(mine.prod_mult, 1.05), "production +5 %")
	r.levels["warehouses"] = 2
	r.levels["architecture"] = 2
	check(c.storage_capacity("stone") > base_cap, "stockage augmenté")
	check(c.build_seconds(DataRegistry.building("stone_mine"), 2) < base_time, "chantiers plus courts")
	check(base_rate > 0.0, "la mine produit")
	r.levels["extraction"] = 2
	eq(r.reason("extraction", c, w), "Améliorez le bâtiment (niveau 3 requis)", "plafond lié au niveau du bâtiment")
	var c2 := CityState.new()
	c2.configure(DataRegistry.config)
	c2.from_dict(c.to_dict())
	eq(c2.research.level("warehouses"), 2, "recherches sauvegardées")


func test_surface_buildings() -> void:
	var c := _city_with_temple(5)
	var w := new_wallet(c, {"gold": 50000, "stone": 50000, "fungal_wood": 50000, "abyssal_crystal": 1000})
	for id in ["dark_ore_pit", "light_well", "surface_lift"]:
		var d := DataRegistry.building(id)
		check(d != null and d.model_scene != null, "bâtiment et modèle : " + id)
	eq(DataRegistry.building("dark_ore_pit").produces, "dark_ore", "la fosse produit du minerai sombre")
	var pit := c.add_built("dark_ore_pit", Vector2i(5, 28), 1, T0)
	check(pit.stored_production(T0 + 3600) > 0.0, "minerai sombre produit")
	check(c.storage_capacity("dark_ore") > DataRegistry.resource_type("dark_ore").base_capacity, "la fosse stocke le minerai")
	var before := c.happiness(T0)
	c.add_built("light_well", Vector2i(10, 28), 1, T0)
	check(c.happiness(T0) > before, "le Puits de lumière réjouit la cité")
	c.add_built("explorer_tower", Vector2i(28, 5), 1, T0)
	var slots := ExplorationState.slots(c)
	var long := ExplorationState.duration(8, c)
	c.add_built("surface_lift", Vector2i(31, 5), 3, T0)
	eq(ExplorationState.slots(c), slots + 1, "une équipe d'exploration de plus")
	check(ExplorationState.duration(8, c) < long, "expéditions raccourcies")
