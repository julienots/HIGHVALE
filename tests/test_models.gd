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


func test_every_building_has_a_3d_model() -> void:
	for d in DataRegistry.all_buildings():
		check(d.model_scene != null, "modèle glTF manquant : " + d.id)


func test_model_tiers_and_animation_tags() -> void:
	var d := DataRegistry.building("primordial_temple")
	var low := BuildingModels.build(d, 1)
	var high := BuildingModels.build(d, 8)
	check(_count_visible(low) < _count_visible(high), "le niveau 7+ ajoute des détails")
	var animated := _with_meta(high, "spin")
	check(animated > 0, "pièces animées détectées")
	check(_count_lights(high) > 0, "repères de lumière convertis")
	low.free()
	high.free()


func _count_visible(n: Node) -> int:
	var c := 1 if n is MeshInstance3D and n.visible else 0
	for ch in n.get_children():
		if not (ch is Node3D and not ch.visible):
			c += _count_visible(ch)
	return c


func _with_meta(n: Node, key: String) -> int:
	var c := 1 if n.has_meta(key) else 0
	for ch in n.get_children():
		c += _with_meta(ch, key)
	return c


func _count_lights(n: Node) -> int:
	var c := 1 if n is OmniLight3D else 0
	for ch in n.get_children():
		c += _count_lights(ch)
	return c


func _count_meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
