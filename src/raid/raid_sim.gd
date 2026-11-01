class_name RaidSim
extends RefCounted
## Assaut en temps réel (inspiré des jeux de stratégie mobiles) : le joueur
## dépense de l'énergie pour déployer ses cartes (héros et créatures) autour
## d'une base ennemie ; les unités marchent, brisent les remparts et détruisent
## les bâtiments pendant que les défenses tirent. Simulation pure (sans
## affichage), à pas fixe, testable sans écran.
##
## Mode « défense » : la base est la cité du joueur, des vagues ennemies
## l'attaquent et le joueur déploie ses héros pour la protéger.

const TICK := 0.05
const ELIXIR_MAX := 10.0
const ELIXIR_PER_SEC := 1.0 / 2.4
const HAND_SIZE := 4
const DEPLOY_MARGIN := 2
const RANGED_HERO := [GameEnums.HeroClass.ARCHER, GameEnums.HeroClass.MAGE, GameEnums.HeroClass.PRIEST,
	GameEnums.HeroClass.SUMMONER, GameEnums.HeroClass.CONTROLLER, GameEnums.HeroClass.SUPPORT]
const HEALER_HERO := [GameEnums.HeroClass.PRIEST, GameEnums.HeroClass.SUPPORT]
const RANGED_MONSTER := [GameEnums.MonsterCategory.MAGICAL, GameEnums.MonsterCategory.ELEMENTAL]
const HERO_COST := [3, 4, 5, 6, 7]
const MONSTER_COST := [2, 3, 4, 5, 6]
const SWARM := [3, 2, 1, 1, 1]
const SWARM_SCALE := [0.55, 0.75, 1.0, 1.0, 1.0]


class Structure:
	var id := 0
	var data_id := ""
	var name := ""
	var cell := Vector2i.ZERO
	var size := Vector2i(2, 2)
	var level := 1
	var hp := 1.0
	var max_hp := 1.0
	var is_wall := false
	var is_keep := false
	var damage := 0.0
	var range := 0.0
	var rate := 1.0
	var splash := 0.0
	var air := true
	var ground := true
	var projectile := "arrow"
	var cooldown := 0.0
	var target: Unit
	var loot := {}

	func alive() -> bool:
		return hp > 0.0

	func is_defense() -> bool:
		return damage > 0.0

	func center() -> Vector2:
		return Vector2(cell) + Vector2(size) * 0.5

	## Distance d'un point au rectangle du bâtiment (0 à l'intérieur).
	func dist_to(p: Vector2) -> float:
		var dx := maxf(maxf(cell.x - p.x, 0.0), p.x - (cell.x + size.x))
		var dy := maxf(maxf(cell.y - p.y, 0.0), p.y - (cell.y + size.y))
		return sqrt(dx * dx + dy * dy)


class Unit:
	var id := 0
	var side := 0  # 0 attaquant, 1 défenseur
	var source_id := ""
	var is_hero := false
	var name := ""
	var element := 0
	var card := -1
	var pos := Vector2.ZERO
	var hp := 1.0
	var max_hp := 1.0
	var damage := 1.0
	var rate := 1.0
	var range := 0.8
	var speed := 1.0
	var flying := false
	var healer := false
	var prefers_defense := false
	var cooldown := 0.0
	var target: Structure
	var foe: Unit
	var wall: Structure
	var path: PackedVector2Array = []
	var path_i := 0
	var repath := 0.0

	func alive() -> bool:
		return hp > 0.0


var width := 34
var height := 24
var structures: Array = []
var units: Array = []
var events: Array = []
var time_left := 180.0
var elapsed := 0.0
var elixir := 5.0
var deck: Array = []  # cartes : { kind, id, uid, name, cost, level, stars, portrait, rarity }
var queue: Array = []  # ordre de pioche (indices de deck)
var defense_mode := false
## Vagues ennemies (mode défense) : [{ at, units: [{ id, level }] , side_edge }]
var waves: Array = []
var _wave_i := 0
var _astar := AStarGrid2D.new()
var _accum := 0.0
var _next_id := 1
var _initial_count := 0
var _over := false
var _rng := RandomNumberGenerator.new()


# --- Mise en place -----------------------------------------------------------------

## base : { width, height, structures: [{ data_id, cell, level, loot? }] }
func setup(base: Dictionary, cards: Array, duration := 180.0, p_defense := false, seed := 0) -> void:
	width = int(base.get("width", 34))
	height = int(base.get("height", 24))
	time_left = duration
	defense_mode = p_defense
	_rng.seed = seed if seed != 0 else randi()
	for s in base.structures:
		_add_structure(s)
	_initial_count = structures.filter(func(s): return not s.is_wall).size()
	deck = cards.slice(0, 8)
	queue.clear()
	for i in deck.size():
		queue.append(i)
	_build_grid()


func _add_structure(s: Dictionary) -> void:
	var st := Structure.new()
	st.id = _next_id
	_next_id += 1
	st.data_id = s.data_id
	st.cell = s.cell
	st.level = int(s.get("level", 1))
	st.loot = s.get("loot", {})
	if s.data_id == "raid_keep":
		st.name = "Donjon"
		st.size = Vector2i(4, 4)
		st.is_keep = true
		st.max_hp = 4200.0 * pow(1.14, st.level - 1)
		st.damage = 30.0 * pow(1.16, st.level - 1)
		st.range = 7.0
		st.rate = 1.0
	else:
		var d := DataRegistry.building(s.data_id)
		st.name = d.display_name
		st.size = d.footprint
		st.is_wall = d.no_builder
		st.is_keep = s.data_id == CityState.TEMPLE_ID
		st.max_hp = d.raid_hp_at(st.level) * (2.4 if st.is_keep else 1.0)
		if d.is_defense():
			st.damage = d.defense_damage_at(st.level)
			st.range = d.defense_range
			st.rate = d.defense_rate
			st.splash = d.defense_splash
			st.air = d.defense_air
			st.ground = d.defense_ground
			st.projectile = d.defense_projectile
		elif st.is_keep:
			st.damage = 26.0 * pow(1.16, st.level - 1)
			st.range = 7.0
			st.rate = 1.0
	st.hp = st.max_hp
	structures.append(st)


func _build_grid() -> void:
	_astar.region = Rect2i(0, 0, width, height)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for s in structures:
		_mark(s, true)


func _mark(s: Structure, on: bool) -> void:
	for x in range(s.cell.x, s.cell.x + s.size.x):
		for y in range(s.cell.y, s.cell.y + s.size.y):
			var c := Vector2i(x, y)
			if not _astar.is_in_boundsv(c):
				continue
			if s.is_wall:
				_astar.set_point_weight_scale(c, 7.0 if on else 1.0)
			else:
				_astar.set_point_solid(c, on)


# --- Cartes et énergie ----------------------------------------------------------------

static func card_for_hero(id: String, coll: CollectionState) -> Dictionary:
	var h := DataRegistry.hero(id)
	return {"kind": "h", "id": id, "uid": 0, "name": h.display_name, "cost": HERO_COST[h.rarity], "rarity": h.rarity,
		"portrait": h.portrait, "level": coll.hero_level(id), "stars": coll.hero_stars(id)}


static func card_for_monster(uid: int, coll: CollectionState) -> Dictionary:
	var m: Dictionary = coll.monsters[uid]
	var d := DataRegistry.monster(m.id)
	return {"kind": "m", "id": m.id, "uid": uid, "name": d.display_name, "cost": MONSTER_COST[d.rarity], "rarity": d.rarity,
		"portrait": d.portrait, "level": int(m.level), "stars": 2 if m.get("variant", "") != "" else 1, "count": SWARM[d.rarity]}


## Paquet du joueur : l'équipe, complétée par les meilleurs personnages (8 cartes).
static func build_deck(coll: CollectionState, now: float) -> Array:
	var out := []
	var seen := {}
	for e in coll.team:
		if e.kind == "h" and coll.owns_hero(e.id) and not coll.is_wounded(e.id, now):
			out.append(card_for_hero(e.id, coll))
			seen["h" + e.id] = true
		elif e.kind == "m" and coll.monsters.has(e.uid):
			out.append(card_for_monster(e.uid, coll))
			seen["m%d" % e.uid] = true
	var hs: Array = coll.heroes.keys().filter(func(id): return not seen.has("h" + id) and not coll.is_wounded(id, now))
	hs.sort_custom(func(a, b): return coll.hero_power(a) > coll.hero_power(b))
	var ms: Array = coll.monsters.keys().filter(func(u): return not seen.has("m%d" % u))
	ms.sort_custom(func(a, b): return coll.monster_power(a) > coll.monster_power(b))
	while out.size() < 8 and (not hs.is_empty() or not ms.is_empty()):
		if not hs.is_empty() and (out.size() % 2 == 0 or ms.is_empty()):
			out.append(card_for_hero(hs.pop_front(), coll))
		elif not ms.is_empty():
			out.append(card_for_monster(ms.pop_front(), coll))
	return out


func hand() -> Array:
	return queue.slice(0, HAND_SIZE)


func next_card() -> int:
	return queue[HAND_SIZE] if queue.size() > HAND_SIZE else -1


func hero_on_field(card: Dictionary) -> bool:
	return card.kind == "h" and units.any(func(u): return u.alive() and u.side == (1 if defense_mode else 0) and u.is_hero and u.source_id == card.id)


func card_reason(hand_slot: int) -> String:
	var h := hand()
	if hand_slot < 0 or hand_slot >= h.size():
		return "Carte inconnue"
	var card: Dictionary = deck[h[hand_slot]]
	if hero_on_field(card):
		return "%s est déjà sur le terrain" % card.name
	if elixir + 1e-6 < card.cost:
		return "Pas assez d'énergie"
	return ""


## Zone de déploiement : hors de la base (au moins DEPLOY_MARGIN cases de tout
## bâtiment) en attaque ; près du donjon en défense.
func can_deploy_at(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	var p := Vector2(cell) + Vector2(0.5, 0.5)
	if defense_mode:
		if _astar.is_point_solid(cell):
			return false
		var keep: Structure = _keep()
		return keep != null and keep.dist_to(p) <= 6.0
	for s in structures:
		if s.alive() and s.dist_to(p) < DEPLOY_MARGIN:
			return false
	return true


func deploy(hand_slot: int, cell: Vector2i) -> String:
	var r := card_reason(hand_slot)
	if r != "":
		return r
	if not can_deploy_at(cell):
		return "Impossible de déployer ici"
	var idx: int = hand()[hand_slot]
	var card: Dictionary = deck[idx]
	elixir -= card.cost
	queue.erase(idx)
	queue.append(idx)
	var side := 1 if defense_mode else 0
	var count: int = 1 if card.kind == "h" else int(card.get("count", 1))
	for i in count:
		var off := Vector2(0, 0) if count == 1 else Vector2(cos(TAU * i / count), sin(TAU * i / count)) * 0.45
		var u := _make_unit(card, side)
		u.pos = Vector2(cell) + Vector2(0.5, 0.5) + off
		u.card = idx
		units.append(u)
		events.append({"type": "spawn", "unit": u})
	return ""


func _make_unit(card: Dictionary, side: int) -> Unit:
	var u := Unit.new()
	u.id = _next_id
	_next_id += 1
	u.side = side
	u.source_id = card.id
	u.is_hero = card.kind == "h"
	u.name = card.name
	var c: Combatant
	if u.is_hero:
		var h := DataRegistry.hero(card.id)
		c = Combatant.from_hero(h, maxi(int(card.level), 1), maxi(int(card.stars), 1))
		u.range = 3.6 if h.hero_class in RANGED_HERO else 0.8
		u.healer = h.hero_class in HEALER_HERO
		u.prefers_defense = h.hero_class == GameEnums.HeroClass.ASSASSIN
		u.element = h.element
	else:
		var m := DataRegistry.monster(card.id)
		c = Combatant.from_monster(m, maxi(int(card.level), 1), maxi(int(card.stars), 1))
		u.flying = m.category == GameEnums.MonsterCategory.FLYING
		u.range = 2.8 if m.category in RANGED_MONSTER else 0.8
		u.prefers_defense = u.flying
		u.element = m.element
	var scale: float = 1.0 if u.is_hero else SWARM_SCALE[DataRegistry.monster(card.id).rarity]
	u.max_hp = c.max_hp * 2.2 * scale
	u.hp = u.max_hp
	u.damage = c.attack * 1.7 * scale
	u.rate = 1.15 if u.range > 1.0 else 1.0
	u.speed = clampf(0.95 + (c.speed - 90) / 90.0, 0.7, 1.9)
	return u


# --- Simulation ------------------------------------------------------------------------

func is_over() -> bool:
	return _over


func step(dt: float) -> void:
	if _over:
		return
	_accum += dt
	while _accum >= TICK and not _over:
		_accum -= TICK
		_tick(TICK)


func _tick(dt: float) -> void:
	elapsed += dt
	time_left -= dt
	elixir = minf(ELIXIR_MAX, elixir + ELIXIR_PER_SEC * dt)
	if defense_mode:
		_spawn_waves()
	for u in units:
		if u.alive():
			_update_unit(u, dt)
	for s in structures:
		if s.alive() and s.is_defense():
			_update_defense(s, dt)
	_check_end()


func _spawn_waves() -> void:
	while _wave_i < waves.size() and elapsed >= float(waves[_wave_i].at):
		var w: Dictionary = waves[_wave_i]
		_wave_i += 1
		var edge: int = int(w.get("edge", 0))
		for i in w.units.size():
			var e: Dictionary = w.units[i]
			var card := {"kind": "m", "id": e.id, "name": DataRegistry.monster(e.id).display_name, "level": e.level, "stars": 1, "count": 1}
			var u := _make_unit(card, 0)
			var t: float = (i + 0.5) / w.units.size()
			match edge:
				0: u.pos = Vector2(1.0, lerpf(4.0, height - 4.0, t))
				1: u.pos = Vector2(width - 1.0, lerpf(4.0, height - 4.0, t))
				2: u.pos = Vector2(lerpf(4.0, width - 4.0, t), 1.0)
				_: u.pos = Vector2(lerpf(4.0, width - 4.0, t), height - 1.0)
			units.append(u)
			events.append({"type": "spawn", "unit": u})
		events.append({"type": "wave", "index": _wave_i})


func _keep() -> Structure:
	for s in structures:
		if s.is_keep:
			return s
	return null


func _update_unit(u: Unit, dt: float) -> void:
	u.cooldown = maxf(0.0, u.cooldown - dt)
	# Soigneurs : soignent l'allié le plus blessé à portée.
	if u.healer:
		var best: Unit = null
		for o in units:
			if o.alive() and o.side == u.side and o != u and o.hp < o.max_hp and o.pos.distance_to(u.pos) <= 4.0:
				if best == null or o.hp / o.max_hp < best.hp / best.max_hp:
					best = o
		if best:
			if u.cooldown <= 0.0:
				u.cooldown = u.rate
				var amount := u.damage * 0.9
				best.hp = minf(best.max_hp, best.hp + amount)
				events.append({"type": "heal", "unit": best, "from": u, "amount": amount})
			return
	# Duel entre unités (défenseurs contre attaquants).
	var foe := _nearest_foe(u, 1.6 if u.side == 0 else 99.0)
	if foe:
		u.foe = foe
		if u.pos.distance_to(foe.pos) <= maxf(u.range, 0.8) + 0.2:
			_attack_unit(u, foe)
		else:
			_move_towards(u, foe.pos, dt)
		return
	if u.side == 1:
		return
	# Attaquants : bâtiments.
	if u.wall and u.wall.alive():
		_attack_struct(u, u.wall)
		return
	u.wall = null
	if u.target == null or not u.target.alive():
		u.target = _choose_target(u)
		u.path = PackedVector2Array()
		if u.target == null:
			return
	if u.target.dist_to(u.pos) <= u.range + 0.15:
		_attack_struct(u, u.target)
		return
	if u.flying:
		_move_towards(u, u.target.center(), dt)
		return
	u.repath -= dt
	if u.path.is_empty() or u.repath <= 0.0:
		_compute_path(u)
	_follow_path(u, dt)


func _nearest_foe(u: Unit, reach: float) -> Unit:
	var best: Unit = null
	var bd := reach
	for o in units:
		if o.alive() and o.side != u.side:
			var d: float = o.pos.distance_to(u.pos)
			if d < bd:
				bd = d
				best = o
	return best


func _choose_target(u: Unit) -> Structure:
	var best: Structure = null
	var bd := INF
	for pass_i in 2:
		for s in structures:
			if not s.alive() or s.is_wall:
				continue
			if pass_i == 0 and u.prefers_defense and not s.is_defense():
				continue
			var d: float = s.dist_to(u.pos)
			if d < bd:
				bd = d
				best = s
		if best or not u.prefers_defense:
			break
	return best


func _compute_path(u: Unit) -> void:
	u.repath = 2.0
	var start := Vector2i(clampi(int(u.pos.x), 0, width - 1), clampi(int(u.pos.y), 0, height - 1))
	var t: Structure = u.target
	var goal := Vector2i(-1, -1)
	var gd := INF
	for x in range(t.cell.x - 1, t.cell.x + t.size.x + 1):
		for y in range(t.cell.y - 1, t.cell.y + t.size.y + 1):
			var c := Vector2i(x, y)
			if not _astar.is_in_boundsv(c) or _astar.is_point_solid(c):
				continue
			var d := Vector2(c).distance_squared_to(u.pos)
			if d < gd:
				gd = d
				goal = c
	if goal.x < 0 or _astar.is_point_solid(start):
		u.path = PackedVector2Array([t.center()])
		u.path_i = 0
		return
	var cells := _astar.get_id_path(start, goal)
	var pts := PackedVector2Array()
	for c in cells:
		pts.append(Vector2(c) + Vector2(0.5, 0.5))
	u.path = pts
	u.path_i = 1 if pts.size() > 1 else 0


func _follow_path(u: Unit, dt: float) -> void:
	if u.path.is_empty() or u.path_i >= u.path.size():
		_move_towards(u, u.target.center(), dt)
		return
	var wp := u.path[u.path_i]
	var c := Vector2i(int(wp.x), int(wp.y))
	var w := _wall_at(c)
	if w:
		u.wall = w
		events.append({"type": "blocked", "unit": u, "wall": w})
		return
	if _move_towards(u, wp, dt):
		u.path_i += 1


func _wall_at(c: Vector2i) -> Structure:
	for s in structures:
		if s.is_wall and s.alive() and s.cell == c:
			return s
	return null


## Avance vers p ; retourne true une fois arrivé.
func _move_towards(u: Unit, p: Vector2, dt: float) -> bool:
	var d := p - u.pos
	var step := u.speed * dt
	if d.length() <= step:
		u.pos = p
		return true
	u.pos += d.normalized() * step
	return false


func _attack_struct(u: Unit, s: Structure) -> void:
	if u.cooldown > 0.0:
		return
	u.cooldown = u.rate
	s.hp -= u.damage
	events.append({"type": "hit", "unit": u, "struct": s, "amount": u.damage, "ranged": u.range > 1.0})
	if s.hp <= 0.0:
		_destroy(s)


func _attack_unit(u: Unit, foe: Unit) -> void:
	if u.cooldown > 0.0:
		return
	u.cooldown = u.rate
	foe.hp -= u.damage * 0.6
	events.append({"type": "duel", "unit": u, "foe": foe, "amount": u.damage * 0.6, "ranged": u.range > 1.0})
	if foe.hp <= 0.0:
		events.append({"type": "unit_dead", "unit": foe})


func _destroy(s: Structure) -> void:
	s.hp = 0.0
	_mark(s, false)
	events.append({"type": "destroyed", "struct": s})
	for u in units:
		if u.target == s:
			u.target = null
		if u.wall == s:
			u.wall = null


func _update_defense(s: Structure, dt: float) -> void:
	s.cooldown = maxf(0.0, s.cooldown - dt)
	var c := s.center()
	var reach := s.range + maxf(s.size.x, s.size.y) * 0.5
	if s.target == null or not s.target.alive() or s.target.pos.distance_to(c) > reach or s.target.side == 1:
		s.target = null
		var bd := INF
		for u in units:
			if not u.alive() or u.side != 0:
				continue
			if (u.flying and not s.air) or (not u.flying and not s.ground):
				continue
			var d: float = u.pos.distance_to(c)
			if d <= reach and d < bd:
				bd = d
				s.target = u
	if s.target == null or s.cooldown > 0.0:
		return
	s.cooldown = s.rate
	var hit_pos: Vector2 = s.target.pos
	events.append({"type": "shot", "struct": s, "unit": s.target, "pos": hit_pos, "projectile": s.projectile})
	if s.splash > 0.0:
		for u in units:
			if u.alive() and u.side == 0 and u.pos.distance_to(hit_pos) <= s.splash:
				_damage_unit(u, s.damage)
	else:
		_damage_unit(s.target, s.damage)


func _damage_unit(u: Unit, amount: float) -> void:
	u.hp -= amount
	if u.hp <= 0.0:
		u.hp = 0.0
		events.append({"type": "unit_dead", "unit": u})


func _check_end() -> void:
	if defense_mode:
		var keep := _keep()
		var waves_done := _wave_i >= waves.size() and not units.any(func(u): return u.alive() and u.side == 0)
		if (keep and not keep.alive()) or time_left <= 0.0 or waves_done:
			_end()
		return
	if destruction() >= 1.0 or time_left <= 0.0:
		_end()
		return
	# Aucune carte à jouer et plus personne sur le terrain : fin anticipée.
	if deck.is_empty() and elapsed > 3.0 and not units.any(func(u): return u.alive() and u.side == 0):
		_end()


func surrender() -> void:
	_end()


func _end() -> void:
	if _over:
		return
	_over = true
	events.append({"type": "end"})


# --- Résultat -------------------------------------------------------------------------

## Part des bâtiments détruits (hors remparts), de 0 à 1.
func destruction() -> float:
	if _initial_count == 0:
		return 0.0
	var dead := structures.filter(func(s): return not s.is_wall and not s.alive()).size()
	return float(dead) / _initial_count


func keep_destroyed() -> bool:
	var k := _keep()
	return k != null and not k.alive()


func stars() -> int:
	var n := 0
	if destruction() >= 0.5:
		n += 1
	if keep_destroyed():
		n += 1
	if destruction() >= 1.0:
		n += 1
	return n


## Butin des bâtiments détruits.
func loot() -> Dictionary:
	var out := {}
	for s in structures:
		if not s.alive():
			for k in s.loot:
				out[k] = int(out.get(k, 0)) + int(s.loot[k])
	return out


func drain_events() -> Array:
	var e := events
	events = []
	return e
