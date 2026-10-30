extends TestCase
## Chaque bâtiment possède un modèle procédural constructible à tous les niveaux.


func test_every_building_builds_a_model() -> void:
	for d in DataRegistry.all_buildings():
		check(BuildingModels._has_recipe("_" + d.model_recipe), "recette manquante : " + d.model_recipe)
		for level in [1, 3, 5, 7, d.max_level]:
			var m := BuildingModels.build(d, level)
			check(_count_meshes(m) > 4, "%s niv. %d : modèle vide" % [d.id, level])
			m.free()


func test_models_differ_between_buildings() -> void:
	var counts := {}
	for d in DataRegistry.all_buildings():
		var m := BuildingModels.build(d, 1)
		counts[d.id] = _count_meshes(m)
		m.free()
	var distinct := {}
	for v in counts.values():
		distinct[v] = true
	check(distinct.size() >= 8, "silhouettes trop similaires")


func _count_meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
