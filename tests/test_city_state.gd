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
	check(c.can_build_reason(DataRegistry.building("laboratory"), w).begins_with("Prochainement"), "module non livré verrouillé")


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
	var d := b.data()
	var half_hour := b.stored_production(T0 + 1800.0)
	check(absf(half_hour - d.production_per_hour(1) / 2.0) < 0.01, "production proportionnelle au temps")
	eq(b.stored_production(T0 + 100000.0), float(d.internal_capacity(1)), "réserve interne plafonnée")


func test_collect_respects_wallet_space() -> void:
	var c := _city_with_temple()
	var b := c.add_built("stone_mine", Vector2i(5, 5), 1, T0)
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
