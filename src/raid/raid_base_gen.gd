class_name RaidBaseGen
extends RefCounted
## Bases ennemies aléatoires : donjon au centre, défenses autour, enceinte de
## remparts (et une seconde enceinte aux niveaux élevés), bâtiments à piller.
## Le niveau de la base suit les trophées du joueur.

const WIDTH := 34
const HEIGHT := 24
const LOOT_BUILDINGS := ["treasury", "warehouse", "stone_mine", "fungal_grove", "nectar_hive", "inhabitants_hall", "crystal_mine", "forge", "market", "barracks"]
const CHIEFS := ["Gorvak", "Ysmera", "Brannoc", "Kethra", "Morgul", "Vael", "Torgrim", "Saskia", "Drozek", "Ilvane", "Harrok", "Zelda",
	"Ombrecroc", "Rasmus", "Nyrah", "Balthor"]
const PLACES := ["Forteresse", "Bastion", "Camp", "Citadelle", "Repaire", "Fort", "Avant-poste", "Donjon"]


static func level_for_trophies(trophies: int) -> int:
	return clampi(1 + trophies / 120, 1, 12)


static func generate(level: int, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var occ := {}
	var out := []
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	var keep_cell := Vector2i(cx - 2 + rng.randi_range(-1, 1), cy - 2 + rng.randi_range(-1, 1))
	_place(out, occ, "raid_keep", keep_cell, Vector2i(4, 4), level, {"gold": 300 * level, "prisms": 2 + level})
	# Défenses autour du donjon
	var kinds := ["archer_tower"]
	if level >= 2:
		kinds.append("cannon")
	if level >= 4:
		kinds.append("crystal_tower")
	if level >= 6:
		kinds.append("ballista")
	var n_def := mini(3 + level / 2 + rng.randi_range(0, 1), 12)
	var tries := 0
	while n_def > 0 and tries < 400:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(3.6, 6.2)
		var c := keep_cell + Vector2i(2, 2) + Vector2i(roundi(cos(a) * r * 1.3) - 1, roundi(sin(a) * r) - 1)
		if _free(occ, c, Vector2i(2, 2), 1):
			_place(out, occ, kinds[rng.randi() % kinds.size()], c, Vector2i(2, 2), _lvl(level, rng), {})
			n_def -= 1
	# Enceinte intérieure : rectangle autour du donjon et des défenses
	var bounds := Rect2i(keep_cell, Vector2i(4, 4))
	for s in out:
		bounds = bounds.merge(Rect2i(s.cell, _size(s.data_id)))
	bounds = bounds.grow(1)
	var budget := 10 + level * 14
	budget -= _wall_ring(out, occ, bounds, level, rng, budget, 0.12 if level < 3 else 0.04)
	# Bâtiments à piller à l'extérieur
	var n_res := 4 + level / 2 + rng.randi_range(0, 2)
	tries = 0
	while n_res > 0 and tries < 600:
		tries += 1
		var id: String = LOOT_BUILDINGS[rng.randi() % LOOT_BUILDINGS.size()]
		var fp := _size(id)
		var c := Vector2i(rng.randi_range(4, WIDTH - 4 - fp.x), rng.randi_range(3, HEIGHT - 3 - fp.y))
		if bounds.grow(1).intersects(Rect2i(c, fp)):
			continue
		if _free(occ, c, fp, 1):
			_place(out, occ, id, c, fp, _lvl(level, rng), _loot_for(id, level, rng))
			n_res -= 1
	# Seconde enceinte (niveaux élevés)
	if level >= 5 and budget > 20:
		var outer := bounds.grow(3 + rng.randi_range(0, 1))
		_wall_ring(out, occ, outer, level, rng, budget, 0.25)
	var name := "%s de %s" % [PLACES[rng.randi() % PLACES.size()], CHIEFS[rng.randi() % CHIEFS.size()]]
	return {"width": WIDTH, "height": HEIGHT, "level": level, "name": name, "structures": out, "seed": seed}


static func _lvl(level: int, rng: RandomNumberGenerator) -> int:
	return clampi(level + rng.randi_range(-1, 0), 1, 10)


static func _size(id: String) -> Vector2i:
	return Vector2i(4, 4) if id == "raid_keep" else DataRegistry.building(id).footprint


static func _free(occ: Dictionary, c: Vector2i, fp: Vector2i, margin := 0) -> bool:
	if c.x < 3 or c.y < 3 or c.x + fp.x > WIDTH - 3 or c.y + fp.y > HEIGHT - 3:
		return false
	for x in range(c.x - margin, c.x + fp.x + margin):
		for y in range(c.y - margin, c.y + fp.y + margin):
			if occ.has(Vector2i(x, y)):
				return false
	return true


static func _place(out: Array, occ: Dictionary, id: String, c: Vector2i, fp: Vector2i, level: int, loot: Dictionary) -> void:
	for x in range(c.x, c.x + fp.x):
		for y in range(c.y, c.y + fp.y):
			occ[Vector2i(x, y)] = true
	out.append({"data_id": id, "cell": c, "level": level, "loot": loot})


## Rectangle de remparts (avec quelques brèches aux bas niveaux). Retourne le nombre posé.
static func _wall_ring(out: Array, occ: Dictionary, rect: Rect2i, level: int, rng: RandomNumberGenerator, budget: int, gap_chance: float) -> int:
	var n := 0
	var cells := []
	for x in range(rect.position.x, rect.end.x):
		cells.append(Vector2i(x, rect.position.y))
		cells.append(Vector2i(x, rect.end.y - 1))
	for y in range(rect.position.y + 1, rect.end.y - 1):
		cells.append(Vector2i(rect.position.x, y))
		cells.append(Vector2i(rect.end.x - 1, y))
	for c in cells:
		if n >= budget:
			break
		if rng.randf() < gap_chance or occ.has(c):
			continue
		if c.x < 2 or c.y < 2 or c.x >= WIDTH - 2 or c.y >= HEIGHT - 2:
			continue
		_place(out, occ, "wall", c, Vector2i.ONE, clampi(level, 1, 10), {})
		n += 1
	return n


static func _loot_for(id: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var k := level * rng.randf_range(0.8, 1.2)
	match id:
		"treasury", "market":
			return {"gold": int(450 * k)}
		"stone_mine":
			return {"stone": int(350 * k)}
		"fungal_grove":
			return {"fungal_wood": int(350 * k)}
		"warehouse":
			return {"stone": int(250 * k), "fungal_wood": int(250 * k)}
		"crystal_mine":
			return {"abyssal_crystal": int(25 * k)}
		"nectar_hive":
			return {"underground_nectar": int(20 * k)}
		"forge":
			return {"dark_ore": int(10 * k)}
	return {"gold": int(150 * k)}


## Base du joueur (mode défense) : la cité entière, le Temple sert de donjon.
static func from_city(city: CityState) -> Dictionary:
	var out := []
	for b in city.buildings.values():
		if b.level < 1:
			continue
		out.append({"data_id": b.data_id, "cell": b.cell, "level": b.level, "loot": {}})
	return {"width": city.grid_size.x, "height": city.grid_size.y, "level": city.temple_level(), "name": "HIGHVALE", "structures": out}


## Vagues ennemies d'un raid contre la cité.
static func defense_waves(level: int, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool := DataRegistry.all_monsters().filter(func(m): return m.rarity <= mini(GameEnums.Rarity.EPIC, 1 + level / 3))
	var waves := []
	for w in 3 + level / 3:
		var units := []
		for i in 3 + level + w * 2:
			var m: MonsterData = pool[rng.randi() % pool.size()]
			units.append({"id": m.id, "level": maxi(1, level * 3 + rng.randi_range(-2, 2))})
		waves.append({"at": 3.0 + w * 22.0, "edge": rng.randi_range(0, 3), "units": units})
	return waves
