class_name BuildingModels
extends RefCounted
## Fabrique de modèles 3D procéduraux des bâtiments.
## Chaque bâtiment a sa propre silhouette et gagne des détails avec les niveaux
## (paliers 3, 5 et 7). Si BuildingData.model_scene est renseigné (modèle glTF
## définitif), il est utilisé à la place.
##
## Métadonnées reconnues par BuildingNode pour animer les pièces :
##  - "spin" : Vector3 en degrés/seconde ;  - "bob" : amplitude verticale.

const K = preload("res://src/city/mesh_kit.gd")

const STONE := Color("8d97a8")
const STONE_D := Color("5f687a")
const STONE_L := Color("b8c1cf")
const WOOD := Color("9a6b40")
const WOOD_D := Color("6b4a2e")
const PLASTER := Color("eadfc4")
const GOLD := Color("ffc531")
const ROOF_BLUE := Color("3a63c8")
const ROOF_RED := Color("c8443a")
const WINDOW := Color("ffcf6a")
const CRYSTAL := Color("2fa8ff")
const CRYSTAL_GLOW := Color("7fdcff")


static func build(data: BuildingData, level: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var lvl := maxi(level, 1)
	var tier := tier_for_level(lvl)
	if data.model_scene:
		var model: Node3D = data.model_scene.instantiate()
		ModelRig.apply(model, tier)
		root.add_child(model)
		return root
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(data.id)
	var fn := "_" + data.model_recipe
	_base(root, data)
	if _has_recipe(fn):
		(BuildingModels as Script).call(fn, root, data, lvl, tier, rng)
	else:
		_generic(root, data, lvl, tier, rng)
	_tier_decor(root, data, tier, rng)
	return root


## Palier visuel : niveaux 1-2 = 0, 3-4 = 1, 5-6 = 2, 7+ = 3.
static func tier_for_level(level: int) -> int:
	return 0 if level < 3 else (1 if level < 5 else (2 if level < 7 else 3))


static var _recipes := {}


static func _has_recipe(fn: String) -> bool:
	if _recipes.is_empty():
		for m in (BuildingModels as Script).get_script_method_list():
			_recipes[m.name] = true
	return _recipes.has(fn)


# --- Éléments communs -------------------------------------------------------

static func _base(r: Node3D, d: BuildingData) -> void:
	var fp := d.footprint
	K.part(r, K.box(Vector3(fp.x - 0.12, 0.18, fp.y - 0.12)), K.mat(STONE_D), Vector3(0, 0.09, 0))
	K.part(r, K.box(Vector3(fp.x - 0.32, 0.08, fp.y - 0.32)), K.mat(STONE), Vector3(0, 0.22, 0))


static func _tier_decor(r: Node3D, d: BuildingData, tier: int, rng: RandomNumberGenerator) -> void:
	var hx := d.footprint.x / 2.0 - 0.25
	var hz := d.footprint.y / 2.0 - 0.25
	if tier >= 1:
		for c in [Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]:
			_banner(r, c + Vector3(0, 0.25, 0), d.accent_color, 1.4)
	if tier >= 2:
		var trim := K.mat(GOLD, 0.35, 0.7)
		K.part(r, K.box(Vector3(d.footprint.x - 0.1, 0.06, 0.08)), trim, Vector3(0, 0.2, hz + 0.2))
		K.part(r, K.box(Vector3(0.08, 0.06, d.footprint.y - 0.1)), trim, Vector3(hx + 0.2, 0.2, 0))
	if tier >= 3:
		for c in [Vector3(hx, 0.25, -hz), Vector3(-hx, 0.25, -hz)]:
			K.crystal_cluster(r, c, 0.5, CRYSTAL, CRYSTAL_GLOW, rng, 3)


static func _banner(r: Node3D, pos: Vector3, color: Color, h := 1.2) -> void:
	K.part(r, K.cylinder(0.035, h, -1, 6), K.mat(WOOD_D), pos + Vector3(0, h / 2, 0))
	K.part(r, K.box(Vector3(0.02, 0.5, 0.32)), K.mat(color), pos + Vector3(0, h - 0.3, 0.17))
	K.part(r, K.sphere(0.06, false, 8), K.mat(GOLD, 0.3, 0.8), pos + Vector3(0, h + 0.04, 0))


static func _roof(r: Node3D, pos: Vector3, size: Vector3, color: Color, rot_y := 0.0) -> MeshInstance3D:
	return K.part(r, K.prism(size), K.mat(color, 0.7), pos, Vector3(0, rot_y, 0))


static func _house(r: Node3D, pos: Vector3, w: float, d: float, h: float, wall: Color, roof: Color) -> void:
	K.part(r, K.box(Vector3(w, h, d)), K.mat(wall), pos + Vector3(0, h / 2, 0))
	_roof(r, pos + Vector3(0, h + 0.3, 0), Vector3(w + 0.15, 0.6, d + 0.15), roof)
	# Fenêtres éclairées et porte.
	K.part(r, K.box(Vector3(0.22, 0.26, 0.04)), K.glow_mat(WINDOW, 1.4), pos + Vector3(-w * 0.25, h * 0.6, d / 2 + 0.01))
	K.part(r, K.box(Vector3(0.22, 0.26, 0.04)), K.glow_mat(WINDOW, 1.4), pos + Vector3(w * 0.25, h * 0.6, d / 2 + 0.01))
	K.part(r, K.box(Vector3(0.04, 0.26, 0.22)), K.glow_mat(WINDOW, 1.4), pos + Vector3(w / 2 + 0.01, h * 0.6, 0))
	K.part(r, K.box(Vector3(0.28, 0.42, 0.05)), K.mat(WOOD_D), pos + Vector3(0, 0.21, d / 2 + 0.01))


static func _torch(r: Node3D, pos: Vector3) -> void:
	K.part(r, K.cylinder(0.04, 0.6, 0.05, 6), K.mat(WOOD_D), pos + Vector3(0, 0.3, 0))
	var flame := K.part(r, K.sphere(0.08, false, 8), K.glow_mat(Color("ff9a2f"), 3.0), pos + Vector3(0, 0.66, 0))
	flame.set_meta("bob", 0.03)


static func _crate(r: Node3D, pos: Vector3, s := 0.3, rot := 0.0) -> void:
	K.part(r, K.box(Vector3(s, s, s)), K.mat(WOOD), pos + Vector3(0, s / 2, 0), Vector3(0, rot, 0))
	K.part(r, K.box(Vector3(s + 0.02, s * 0.15, s + 0.02)), K.mat(WOOD_D), pos + Vector3(0, s / 2, 0), Vector3(0, rot, 0))


static func _barrel(r: Node3D, pos: Vector3) -> void:
	K.part(r, K.cylinder(0.14, 0.34, 0.12, 10), K.mat(WOOD), pos + Vector3(0, 0.17, 0))
	K.part(r, K.cylinder(0.145, 0.04, -1, 10), K.mat(STONE_D, 0.4, 0.6), pos + Vector3(0, 0.25, 0))


static func _generic(r: Node3D, d: BuildingData, _lvl: int, _tier: int, _rng: RandomNumberGenerator) -> void:
	_house(r, Vector3(0, 0.26, 0), d.footprint.x * 0.6, d.footprint.y * 0.6, 1.0, PLASTER, d.primary_color)


# --- Recettes ---------------------------------------------------------------

static func _primordial_temple(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	var stone := K.mat(Color("a7b0c0"))
	var dark := K.mat(STONE_D)
	var h := 0.26
	var steps := [3.5, 2.9, 2.3]
	for i in steps.size():
		var s: float = steps[i]
		K.part(r, K.box(Vector3(s, 0.38, s)), stone if i % 2 == 0 else dark, Vector3(0, h + 0.19, 0))
		h += 0.38
	# Escalier frontal
	for i in 4:
		K.part(r, K.box(Vector3(0.8, 0.12, 0.25)), stone, Vector3(0, 0.32 + i * 0.24, 1.72 - i * 0.28))
	# Colonnes et toit
	var col_h := 1.1 + 0.08 * lvl
	for c in [Vector2(-0.85, -0.85), Vector2(0.85, -0.85), Vector2(-0.85, 0.85), Vector2(0.85, 0.85)]:
		K.part(r, K.cylinder(0.14, col_h, -1, 10), K.mat(STONE_L), Vector3(c.x, h + col_h / 2, c.y))
		K.part(r, K.box(Vector3(0.36, 0.1, 0.36)), K.mat(GOLD, 0.35, 0.7) if tier >= 1 else dark, Vector3(c.x, h + 0.05, c.y))
	K.part(r, K.box(Vector3(2.3, 0.2, 2.3)), dark, Vector3(0, h + col_h + 0.1, 0))
	_roof(r, Vector3(0, h + col_h + 0.45, 0), Vector3(2.4, 0.5, 2.4), Color("4b5f9c"))
	# Grand cristal flottant au cœur du temple
	var core := Node3D.new()
	core.position = Vector3(0, h + 0.75, 0)
	core.set_meta("spin", Vector3(0, 35, 0))
	core.set_meta("bob", 0.08)
	r.add_child(core)
	var cm := K.crystal_mat(CRYSTAL, CRYSTAL_GLOW, 2.2)
	var cs := 0.9 + 0.06 * lvl
	K.part(core, K.cylinder(0.0, 0.35 * cs, 0.22 * cs, 6), cm, Vector3(0, -0.18 * cs, 0))
	K.part(core, K.cylinder(0.22 * cs, 0.5 * cs, 0.0, 6), cm, Vector3(0, 0.25 * cs, 0))
	var light := OmniLight3D.new()
	light.light_color = CRYSTAL_GLOW
	light.light_energy = 1.4 + 0.1 * lvl
	light.omni_range = 5.0
	light.position = Vector3(0, h + 0.8, 0)
	r.add_child(light)
	for c in [Vector3(-1.6, 0.25, 1.6), Vector3(1.6, 0.25, 1.6)]:
		_torch(r, c)
	if tier >= 2:
		for i in 4:
			var a := TAU * i / 4.0 + PI / 4.0
			var orb := K.part(r, K.sphere(0.1, false, 8), K.glow_mat(CRYSTAL_GLOW, 3.0), Vector3(cos(a) * 1.6, h + 0.5, sin(a) * 1.6))
			orb.set_meta("bob", 0.12)


static func _inhabitants_hall(r: Node3D, d: BuildingData, lvl: int, tier: int, _rng: RandomNumberGenerator) -> void:
	var floors := 1.0 + 0.35 * tier
	_house(r, Vector3(-0.45, 0.26, -0.35), 1.5, 1.4, 0.9 * floors, PLASTER, ROOF_BLUE)
	_house(r, Vector3(0.75, 0.26, 0.55), 1.0, 1.0, 0.7, Color("d8c7a0"), d.accent_color.darkened(0.2))
	K.part(r, K.box(Vector3(0.2, 0.6, 0.2)), K.mat(STONE_D), Vector3(-0.85, 0.9 * floors + 0.6, -0.6))
	_barrel(r, Vector3(-1.1, 0.26, 0.9))
	_torch(r, Vector3(0.0, 0.26, 1.15))
	if lvl >= 2:
		_crate(r, Vector3(1.1, 0.26, -0.8), 0.28, 20)


static func _stone_mine(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.rock(2), K.mat(Color("7c8698")), Vector3(-0.3, 0.2, -0.4), Vector3(0, 20, 0), Vector3(1.3, 1.1 + 0.08 * lvl, 1.1))
	# Entrée de galerie avec charpente
	K.part(r, K.box(Vector3(0.8, 0.8, 0.1)), K.mat(Color("15121c")), Vector3(-0.1, 0.62, 0.55))
	for x in [-0.5, 0.3]:
		K.part(r, K.box(Vector3(0.12, 0.95, 0.12)), K.mat(WOOD), Vector3(x, 0.7, 0.62))
	K.part(r, K.box(Vector3(1.0, 0.12, 0.16)), K.mat(WOOD), Vector3(-0.1, 1.2, 0.62))
	# Rails et wagonnet
	for x in [-0.28, 0.08]:
		K.part(r, K.box(Vector3(0.05, 0.04, 1.0)), K.mat(STONE_D, 0.4, 0.7), Vector3(x, 0.28, 1.0))
	var cart := Node3D.new()
	cart.position = Vector3(-0.1, 0.3, 1.05)
	r.add_child(cart)
	K.part(cart, K.box(Vector3(0.5, 0.26, 0.38)), K.mat(WOOD_D), Vector3(0, 0.18, 0))
	K.part(cart, K.rock(5), K.mat(STONE_L), Vector3(0, 0.33, 0), Vector3.ZERO, Vector3(0.22, 0.2, 0.18))
	# Treuil animé
	var wheel := K.part(r, K.torus(0.22, 0.3), K.mat(WOOD), Vector3(0.95, 1.0, -0.2), Vector3(0, 0, 90))
	wheel.set_meta("spin", Vector3(90, 0, 0))
	K.part(r, K.box(Vector3(0.1, 1.0, 0.1)), K.mat(WOOD_D), Vector3(0.95, 0.65, -0.45))
	K.part(r, K.box(Vector3(0.1, 1.0, 0.1)), K.mat(WOOD_D), Vector3(0.95, 0.65, 0.05))
	# Tas de pierres
	for i in 3 + tier:
		K.part(r, K.rock(i), K.mat(STONE_L), Vector3(0.9 + rng.randf_range(-0.2, 0.2), 0.3, 0.8 + rng.randf_range(-0.25, 0.25)), Vector3(0, rng.randf() * 360, 0), Vector3.ONE * 0.2)
	_torch(r, Vector3(-1.1, 0.26, 0.9))


static func _fungal_grove(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	var caps := [Color("3fd6c0"), Color("7a5cff"), Color("2fc4e0")]
	var spots := [Vector3(-0.5, 0.26, -0.45), Vector3(0.6, 0.26, -0.2), Vector3(-0.2, 0.26, 0.6)]
	for i in spots.size():
		var s := (1.0 if i == 0 else 0.7) * (1.0 + 0.07 * lvl)
		var p: Vector3 = spots[i]
		K.part(r, K.cylinder(0.12 * s, 1.0 * s, 0.09 * s, 10), K.mat(Color("e8e0cc")), p + Vector3(0, 0.5 * s, 0))
		var cap := K.part(r, K.sphere(0.55 * s, true, 14), K.mat(caps[i], 0.6), p + Vector3(0, 0.95 * s, 0))
		cap.scale = Vector3(1, 0.7, 1)
		K.part(r, K.sphere(0.5 * s, true, 14), K.glow_mat(caps[i].lightened(0.3), 1.2), p + Vector3(0, 0.94 * s, 0), Vector3(180, 0, 0), Vector3(1, 0.2, 1))
		for j in 3:
			var a := rng.randf() * TAU
			K.part(r, K.sphere(0.06 * s, false, 6), K.mat(Color("f5fff9")), p + Vector3(cos(a) * 0.3 * s, 1.18 * s, sin(a) * 0.3 * s))
	# Bûches récoltées
	for i in 2 + tier:
		K.part(r, K.cylinder(0.1, 0.7, -1, 8), K.mat(Color("8a5a3a")), Vector3(0.75, 0.36 + i * 0.16, 0.85 - (i % 2) * 0.05), Vector3(0, 0, 90))
	# Clôture
	for i in 5:
		K.part(r, K.box(Vector3(0.06, 0.35, 0.06)), K.mat(WOOD), Vector3(-1.25, 0.43, -1.0 + i * 0.5))
	K.part(r, K.box(Vector3(0.04, 0.05, 2.1)), K.mat(WOOD), Vector3(-1.25, 0.52, 0.0))


static func _treasury(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(2.0, 1.0, 1.8)), K.mat(Color("d8cdb0")), Vector3(0, 0.76, -0.2))
	K.part(r, K.box(Vector3(2.2, 0.14, 2.0)), K.mat(STONE_D), Vector3(0, 1.32, -0.2))
	var dome := K.part(r, K.sphere(0.75 + 0.03 * lvl, true, 16), K.mat(GOLD, 0.25, 0.85), Vector3(0, 1.38, -0.2))
	dome.scale = Vector3(1, 0.9, 1)
	K.part(r, K.sphere(0.1, false, 8), K.glow_mat(Color("fff1a8"), 2.5), Vector3(0, 2.15 + 0.03 * lvl, -0.2))
	for x in [-0.7, -0.25, 0.25, 0.7]:
		K.part(r, K.cylinder(0.08, 0.95, -1, 8), K.mat(STONE_L), Vector3(x, 0.74, 0.78))
	K.part(r, K.box(Vector3(0.5, 0.6, 0.06)), K.mat(Color("6b4a2e")), Vector3(0, 0.56, 0.72))
	# Pièces d'or empilées
	for i in 4 + tier * 2:
		var a := rng.randf() * TAU
		K.part(r, K.cylinder(0.12, 0.04, -1, 12), K.mat(GOLD, 0.3, 0.8), Vector3(1.05 + cos(a) * 0.15, 0.3 + (i % 4) * 0.045, 0.95 + sin(a) * 0.15))
	_barrel(r, Vector3(-1.05, 0.26, 0.95))


static func _warehouse(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	var h := 1.1 + 0.08 * lvl
	K.part(r, K.box(Vector3(2.2, h, 1.6)), K.mat(WOOD), Vector3(0, 0.26 + h / 2, -0.3))
	for x in [-1.05, 0.0, 1.05]:
		K.part(r, K.box(Vector3(0.12, h, 0.12)), K.mat(WOOD_D), Vector3(x, 0.26 + h / 2, 0.52))
	_roof(r, Vector3(0, 0.26 + h + 0.4, -0.3), Vector3(2.4, 0.8, 1.8), Color("8a3a2e"), 90)
	K.part(r, K.box(Vector3(0.8, 0.8, 0.05)), K.mat(WOOD_D), Vector3(0, 0.66, 0.51))
	K.part(r, K.box(Vector3(0.84, 0.06, 0.06)), K.mat(STONE_D, 0.4, 0.6), Vector3(0, 0.66, 0.54), Vector3(0, 0, 45))
	for i in 3 + tier:
		_crate(r, Vector3(-1.0 + i * 0.32, 0.26, 1.0), 0.3, rng.randf_range(-15, 15))
	_barrel(r, Vector3(1.1, 0.26, 1.0))
	K.part(r, K.rock(1), K.mat(STONE_L), Vector3(0.7, 0.35, 0.95), Vector3.ZERO, Vector3.ONE * 0.22)


static func _crystal_mine(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	# Tour de forage
	var h := 1.8 + 0.1 * lvl
	for c in [Vector2(-0.45, -0.45), Vector2(0.45, -0.45), Vector2(-0.45, 0.45), Vector2(0.45, 0.45)]:
		K.part(r, K.box(Vector3(0.1, h, 0.1)), K.mat(WOOD_D), Vector3(c.x * 0.8, 0.26 + h / 2, c.y * 0.8), Vector3(-c.y * 8, 0, c.x * 8))
	K.part(r, K.box(Vector3(0.9, 0.1, 0.9)), K.mat(WOOD), Vector3(0, 0.26 + h * 0.5, 0))
	K.part(r, K.box(Vector3(0.7, 0.3, 0.7)), K.mat(STONE_D, 0.4, 0.6), Vector3(0, 0.26 + h, 0))
	var drill := Node3D.new()
	drill.position = Vector3(0, 0.6, 0)
	drill.set_meta("spin", Vector3(0, 220, 0))
	r.add_child(drill)
	K.part(drill, K.cylinder(0.06, h - 0.4, -1, 8), K.mat(STONE_L, 0.3, 0.8), Vector3(0, (h - 0.4) / 2, 0))
	K.part(drill, K.cylinder(0.0, 0.5, 0.22, 8), K.mat(GOLD, 0.3, 0.8), Vector3(0, -0.05, 0))
	# Veine de cristaux
	K.crystal_cluster(r, Vector3(-0.95, 0.26, 0.7), 0.8, CRYSTAL, CRYSTAL_GLOW, rng, 4 + tier)
	K.crystal_cluster(r, Vector3(0.95, 0.26, -0.8), 0.6, Color("5a5cff"), Color("a9a2ff"), rng, 3)
	K.crystal_cluster(r, Vector3(0.9, 0.26, 0.85), 0.45, CRYSTAL, CRYSTAL_GLOW, rng, 3)
	var light := OmniLight3D.new()
	light.light_color = CRYSTAL_GLOW
	light.light_energy = 1.0
	light.omni_range = 3.0
	light.position = Vector3(0, 0.8, 0.6)
	r.add_child(light)


static func _forge(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(1.8, 1.0, 1.5)), K.mat(Color("5a4a44")), Vector3(-0.2, 0.76, -0.3))
	_roof(r, Vector3(-0.2, 1.56, -0.3), Vector3(2.0, 0.6, 1.7), Color("3a3238"))
	K.part(r, K.cylinder(0.25, 1.4, 0.2, 8), K.mat(STONE_D), Vector3(0.45, 1.6, -0.75))
	K.part(r, K.box(Vector3(0.7, 0.45, 0.05)), K.glow_mat(Color("ff7a2f"), 3.0), Vector3(-0.2, 0.55, 0.46))
	K.part(r, K.box(Vector3(0.45, 0.2, 0.22)), K.mat(Color("3b3f4a"), 0.3, 0.9), Vector3(0.6, 0.62, 0.85))
	K.part(r, K.box(Vector3(0.2, 0.3, 0.16)), K.mat(Color("3b3f4a"), 0.3, 0.9), Vector3(0.6, 0.41, 0.85))
	var ember := K.part(r, K.sphere(0.1, false, 8), K.glow_mat(Color("ffb02f"), 3.5), Vector3(0.45, 2.4, -0.75))
	ember.set_meta("bob", 0.1)


static func _market(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	var colors := [Color("ff5a5a"), Color("3d9bff"), Color("ffc531")]
	for i in 3:
		var p := Vector3(-0.85 + i * 0.85, 0.26, -0.2 + (i % 2) * 0.5)
		for c in [Vector2(-0.3, -0.25), Vector2(0.3, -0.25), Vector2(-0.3, 0.25), Vector2(0.3, 0.25)]:
			K.part(r, K.box(Vector3(0.06, 0.9, 0.06)), K.mat(WOOD_D), p + Vector3(c.x, 0.45, c.y))
		K.part(r, K.box(Vector3(0.7, 0.3, 0.5)), K.mat(WOOD), p + Vector3(0, 0.15, 0))
		_roof(r, p + Vector3(0, 1.05, 0), Vector3(0.8, 0.3, 0.65), colors[i])
		K.part(r, K.sphere(0.08, false, 8), K.mat(colors[(i + 1) % 3]), p + Vector3(-0.15, 0.36, 0))
		K.part(r, K.sphere(0.08, false, 8), K.mat(GOLD), p + Vector3(0.12, 0.36, 0.05))
	_crate(r, Vector3(1.05, 0.26, 1.0), 0.28)
	_barrel(r, Vector3(-1.05, 0.26, 1.0))


static func _infirmary(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	_house(r, Vector3(0, 0.26, -0.2), 2.0, 1.6, 1.0, Color("f2efe8"), Color("d14a4a"))
	K.part(r, K.box(Vector3(0.5, 0.14, 0.04)), K.glow_mat(Color("ff4a4a"), 1.5), Vector3(0, 1.0, 0.62))
	K.part(r, K.box(Vector3(0.14, 0.5, 0.04)), K.glow_mat(Color("ff4a4a"), 1.5), Vector3(0, 1.0, 0.62))
	K.part(r, K.box(Vector3(0.7, 0.12, 0.3)), K.mat(Color("f2efe8")), Vector3(0.9, 0.38, 1.0))


static func _laboratory(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(1.6, 1.0, 1.4)), K.mat(Color("4a5872")), Vector3(-0.3, 0.76, -0.4))
	var dome := K.part(r, K.sphere(0.7, true, 16), K.glass_mat(Color(0.5, 1.0, 0.7, 0.45)), Vector3(-0.3, 1.26, -0.4))
	dome.scale = Vector3(1, 0.8, 1)
	for i in 3:
		var p := Vector3(0.6 + i * 0.25, 0.26, 0.4 + (i % 2) * 0.3)
		K.part(r, K.cylinder(0.1, 0.8, -1, 10), K.glass_mat(Color(0.8, 1.0, 0.9, 0.3)), p + Vector3(0, 0.4, 0))
		var liquid := K.part(r, K.cylinder(0.08, 0.5, -1, 10), K.glow_mat([Color("46d66b"), Color("b464ff"), Color("2fa8ff")][i], 2.0), p + Vector3(0, 0.25, 0))
		liquid.set_meta("bob", 0.03)


static func _monster_habitat(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(3.5, 0.06, 3.5)), K.mat(Color("4f8a3a")), Vector3(0, 0.29, 0))
	K.part(r, K.rock(3), K.mat(Color("6b6f80")), Vector3(-0.8, 0.3, -0.8), Vector3.ZERO, Vector3(1.0, 1.1, 1.0))
	K.part(r, K.box(Vector3(0.5, 0.5, 0.1)), K.mat(Color("15121c")), Vector3(-0.6, 0.5, -0.05))
	K.part(r, K.cylinder(0.6, 0.04, -1, 16), K.mat(Color("2a8fd0"), 0.1), Vector3(0.8, 0.33, 0.7))
	for i in 12:
		var a := TAU * i / 12.0
		K.part(r, K.box(Vector3(0.08, 0.5, 0.08)), K.mat(WOOD), Vector3(cos(a) * 1.65, 0.5, sin(a) * 1.65))


static func _library(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(1.6, 1.3, 1.6)), K.mat(Color("7a5a44")), Vector3(-0.3, 0.91, -0.3))
	_roof(r, Vector3(-0.3, 1.86, -0.3), Vector3(1.8, 0.6, 1.8), Color("6a3fa0"))
	K.part(r, K.cylinder(0.45, 2.2, -1, 12), K.mat(Color("8a6a54")), Vector3(0.8, 1.36, 0.7))
	K.part(r, K.cylinder(0.55, 0.7, 0.0, 12), K.mat(Color("6a3fa0")), Vector3(0.8, 2.8, 0.7))
	K.part(r, K.box(Vector3(0.6, 0.3, 0.04)), K.glow_mat(Color("b25cff"), 1.6), Vector3(-0.3, 1.0, 0.51))


static func _barracks(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(2.2, 1.0, 1.6)), K.mat(Color("7a6a5a")), Vector3(0, 0.76, -0.4))
	for i in 5:
		K.part(r, K.box(Vector3(0.25, 0.25, 0.25)), K.mat(Color("7a6a5a")), Vector3(-0.9 + i * 0.45, 1.38, 0.3))
	_banner(r, Vector3(-0.6, 1.26, -0.4), Color("c8443a"))
	_banner(r, Vector3(0.6, 1.26, -0.4), Color("c8443a"))
	K.part(r, K.cylinder(0.08, 0.8, -1, 8), K.mat(WOOD), Vector3(0.8, 0.66, 0.9))
	K.part(r, K.sphere(0.16, false, 8), K.mat(Color("d8c7a0")), Vector3(0.8, 1.12, 0.9))


static func _fusion_forge(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.cylinder(0.8, 0.8, 0.6, 16), K.mat(Color("3b2d55")), Vector3(0, 0.66, 0))
	var brew := K.part(r, K.cylinder(0.72, 0.05, -1, 16), K.glow_mat(Color("b464ff"), 2.2), Vector3(0, 1.05, 0))
	brew.set_meta("bob", 0.03)
	for x in [-1.1, 1.1]:
		K.part(r, K.cylinder(0.15, 1.6, 0.1, 8), K.mat(STONE_D), Vector3(x, 1.06, -0.6))
		var orb := K.part(r, K.sphere(0.18, false, 10), K.glow_mat(Color("e09bff"), 2.5), Vector3(x, 2.05, -0.6))
		orb.set_meta("bob", 0.1)


static func _hero_sanctuary(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.cylinder(1.35, 0.2, -1, 24), K.mat(STONE_L), Vector3(0, 0.36, 0))
	for i in 6:
		var a := TAU * i / 6.0
		K.part(r, K.cylinder(0.1, 1.3, -1, 8), K.mat(Color("e8e2d0")), Vector3(cos(a) * 1.15, 1.11, sin(a) * 1.15))
	var ring := K.part(r, K.torus(0.55, 0.68), K.glow_mat(Color("3d9bff"), 2.5), Vector3(0, 1.3, 0), Vector3(90, 0, 0))
	ring.set_meta("spin", Vector3(0, 0, 60))


static func _academy(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	_house(r, Vector3(-0.2, 0.26, -0.2), 2.0, 1.5, 1.2, Color("d8d0c0"), Color("3a4a7a"))
	K.part(r, K.cylinder(0.3, 1.8, -1, 10), K.mat(Color("d8d0c0")), Vector3(0.95, 1.16, 0.85))
	K.part(r, K.cylinder(0.38, 0.6, 0.0, 10), K.mat(Color("3a4a7a")), Vector3(0.95, 2.36, 0.85))
	K.part(r, K.sphere(0.14, false, 10), K.mat(GOLD, 0.3, 0.8), Vector3(-0.2, 2.1, -0.2))


static func _arena(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.cylinder(1.5, 0.05, -1, 24), K.mat(Color("d9c08a")), Vector3(0, 0.3, 0))
	for i in 16:
		var a := TAU * i / 16.0
		K.part(r, K.box(Vector3(0.6, 0.7 + (i % 2) * 0.15, 0.25)), K.mat(Color("8a7a5a")), Vector3(cos(a) * 1.6, 0.6, sin(a) * 1.6), Vector3(0, -rad_to_deg(a) + 90, 0))
	_banner(r, Vector3(0, 0.26, -1.6), Color("ff5a5a"), 1.8)


static func _ancient_portal(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	for x in [-0.8, 0.8]:
		K.part(r, K.box(Vector3(0.4, 2.0, 0.4)), K.mat(Color("6a6478")), Vector3(x, 1.26, 0))
	K.part(r, K.box(Vector3(2.1, 0.35, 0.5)), K.mat(Color("6a6478")), Vector3(0, 2.4, 0))
	var swirl := K.part(r, K.cylinder(0.6, 0.04, -1, 24), K.glow_mat(Color("59e0ff"), 2.4), Vector3(0, 1.26, 0), Vector3(90, 0, 0), Vector3(1, 1, 1.4))
	swirl.set_meta("spin", Vector3(0, 90, 0))
	K.crystal_cluster(r, Vector3(-1.1, 0.26, 0.8), 0.5, Color("59e0ff"), Color("b8f6ff"), rng, 3)


static func _explorer_tower(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	for c in [Vector2(-0.4, -0.4), Vector2(0.4, -0.4), Vector2(-0.4, 0.4), Vector2(0.4, 0.4)]:
		K.part(r, K.box(Vector3(0.1, 2.4, 0.1)), K.mat(WOOD_D), Vector3(c.x, 1.46, c.y))
	K.part(r, K.box(Vector3(1.1, 0.12, 1.1)), K.mat(WOOD), Vector3(0, 2.6, 0))
	_roof(r, Vector3(0, 3.05, 0), Vector3(1.2, 0.7, 1.2), Color("3d6bd0"))
	_banner(r, Vector3(0.45, 2.6, 0.45), Color("3d9bff"), 1.2)


static func _divine_altar(r: Node3D, d: BuildingData, lvl: int, tier: int, rng: RandomNumberGenerator) -> void:
	K.part(r, K.box(Vector3(2.4, 0.3, 2.4)), K.mat(Color("f2eee2")), Vector3(0, 0.41, 0))
	K.part(r, K.box(Vector3(1.6, 0.3, 1.6)), K.mat(Color("e8e2d0")), Vector3(0, 0.71, 0))
	K.part(r, K.box(Vector3(0.8, 0.6, 0.6)), K.mat(GOLD, 0.3, 0.8), Vector3(0, 1.16, 0))
	var orb := K.part(r, K.sphere(0.3, false, 16), K.glow_mat(Color("fff1a8"), 3.0), Vector3(0, 2.0, 0))
	orb.set_meta("bob", 0.12)
	var halo := K.part(r, K.torus(0.45, 0.52), K.glow_mat(GOLD, 2.0), Vector3(0, 2.0, 0), Vector3(70, 0, 0))
	halo.set_meta("spin", Vector3(0, 50, 0))
