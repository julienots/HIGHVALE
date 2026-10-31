class_name CityNav
extends RefCounted
## Grille de déplacement des habitants (A*) : cases de la zone constructible
## non occupées par un bâtiment. Les portes sont en façade (côté +Z).

var astar := AStarGrid2D.new()
var buildable := Rect2i()


func rebuild(city: CityState) -> void:
	buildable = city.buildable_rect
	astar.region = Rect2i(Vector2i.ZERO, city.grid_size)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for x in city.grid_size.x:
		for y in city.grid_size.y:
			var c := Vector2i(x, y)
			astar.set_point_solid(c, not buildable.has_point(c) or city.building_at(c) != null)


func is_walkable(c: Vector2i) -> bool:
	return astar.is_in_boundsv(c) and not astar.is_point_solid(c)


## Case devant la porte d'un bâtiment (ou la case libre la plus proche de la façade).
func door_cell(b: BuildingState) -> Vector2i:
	var r := b.rect()
	var front := Vector2i(r.position.x + r.size.x / 2, r.end.y)
	return nearest_walkable(front)


func nearest_walkable(c: Vector2i, max_radius := 8) -> Vector2i:
	if is_walkable(c):
		return c
	for radius in range(1, max_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) == radius and is_walkable(c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
	return c


## Chemin en points monde (centres de cases) ; vide si inaccessible.
func path(from: Vector2i, to: Vector2i) -> PackedVector3Array:
	var out := PackedVector3Array()
	var a := nearest_walkable(from)
	var b := nearest_walkable(to)
	if not is_walkable(a) or not is_walkable(b):
		return out
	for c in astar.get_id_path(a, b):
		out.append(Vector3(c.x + 0.5, 0, c.y + 0.5))
	return out


func random_cell_near(center: Vector2i, radius: int, rng: RandomNumberGenerator) -> Vector2i:
	for i in 12:
		var c := center + Vector2i(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))
		if is_walkable(c):
			return c
	return nearest_walkable(center)


static func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.z))
