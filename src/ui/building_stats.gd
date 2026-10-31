class_name BuildingStats
extends RefCounted
## Statistiques lisibles d'un bâtiment à un niveau donné (panneau, amélioration, infos).


## Retourne [[libellé, valeur, icône], …].
static func lines(d: BuildingData, level: int) -> Array:
	var out := []
	if level < 1:
		return out
	if not d.produces.is_empty():
		var rt := DataRegistry.resource_type(d.produces)
		out.append(["Production", "+%s / h" % Fmt.amount(d.production_per_hour(level) * GameState.city.production_mult()), rt.icon])
		out.append(["Réserve interne", Fmt.amount(d.internal_capacity(level)), rt.icon])
	var st := d.storage_for_level(level)
	for id in st:
		var rt := DataRegistry.resource_type(id)
		out.append(["Stockage %s" % rt.display_name.to_lower(), "+%s" % Fmt.amount(st[id]), rt.icon])
	var pop := d.population_for_level(level)
	if pop > 0:
		out.append(["Habitants", "+%d" % pop, preload("res://assets/icons/ui/population.svg")])
	var comfort := d.comfort_for_level(level)
	if comfort > 0:
		out.append(["Bien-être", "+%d" % comfort, preload("res://assets/icons/ui/heart.svg")])
	if d.worker_slots(level) > 0:
		out.append(["Postes d'ouvriers", str(d.worker_slots(level)), preload("res://assets/icons/ui/population.svg")])
	if d.builders_provided > 0:
		out.append(["Bâtisseurs", "+%d" % d.builders_provided, preload("res://assets/icons/ui/builder.svg")])
	return out


## Grille « libellé : valeur actuelle → valeur suivante ».
static func comparison(d: BuildingData, from_level: int, to_level: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 6)
	var now_lines := lines(d, from_level)
	var next_lines := lines(d, to_level)
	for i in next_lines.size():
		var nl: Array = next_lines[i]
		g.add_child(UiTheme.icon_rect(nl[2], 30))
		g.add_child(UiTheme.label(nl[0], "", 20))
		var cur: String = now_lines[i][1] if i < now_lines.size() else "—"
		g.add_child(UiTheme.label(cur, "DimLabel", 20))
		g.add_child(UiTheme.label("→ " + nl[1], "HudLabel", 22, UiTheme.GREEN))
	return g
