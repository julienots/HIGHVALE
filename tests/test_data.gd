extends TestCase
## Cohérence des données de jeu.


func test_resources_loaded() -> void:
	var list := DataRegistry.all_resource_types()
	eq(list.size(), 11, "10 ressources + monnaie premium")
	for rt in list:
		check(rt.icon != null, "icône manquante : " + rt.id)
	check(DataRegistry.resource_type(DataRegistry.config.premium_resource).is_premium, "monnaie premium mal configurée")


func test_buildings_reference_valid_resources() -> void:
	var list := DataRegistry.all_buildings()
	check(list.size() >= 20, "au moins 20 bâtiments")
	for d in list:
		for id in d.base_cost:
			check(DataRegistry.resource_type(id) != null, "%s : ressource de coût inconnue %s" % [d.id, id])
		for id in d.storage:
			check(DataRegistry.resource_type(id) != null, "%s : ressource stockée inconnue %s" % [d.id, id])
		if not d.produces.is_empty():
			check(DataRegistry.resource_type(d.produces) != null, "%s : production inconnue" % d.id)
		check(d.max_count(10) >= 1, "%s : jamais constructible" % d.id)
		check(d.footprint.x >= 2 and d.footprint.y >= 2, "%s : emprise trop petite" % d.id)


func test_level_formulas_increase() -> void:
	var mine := DataRegistry.building("stone_mine")
	check(mine.production_per_hour(2) > mine.production_per_hour(1), "production croissante")
	check(mine.cost_for_level(3)["gold"] > mine.cost_for_level(2)["gold"], "coût croissant")
	check(mine.build_seconds_for_level(3) > mine.build_seconds_for_level(2), "durée croissante")
	eq(mine.level_cap(1), 2, "niveau max avec Temple 1")
	eq(mine.level_cap(3), 6, "niveau max avec Temple 3")


func test_starting_layout_valid() -> void:
	var city := new_city()
	for e in DataRegistry.config.starting_layout:
		check(city.add_built(e.id, e.cell, e.level, 0.0) != null, "placement initial invalide : %s" % e.id)


func test_story_chapters() -> void:
	check(DataRegistry.story_for_temple_level(1) != null, "chapitre d'introduction manquant")


func test_nice_round() -> void:
	eq(BuildingData.nice_round(152.0), 150, "arrondi 152")
	eq(BuildingData.nice_round(1337.0), 1300, "arrondi 1337")
	eq(BuildingData.nice_round(42.0), 40, "arrondi 42")
