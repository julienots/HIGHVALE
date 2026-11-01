class_name RaidScene
extends Node3D
## Scène d'assaut en temps réel : base ennemie (ou cité du joueur en défense),
## unités, projectiles, destructions, barre d'énergie et cartes à déployer.

const KEEP_MODEL := preload("res://assets/models/buildings/raid_keep.glb")
const STAR := preload("res://assets/icons/ui/star.svg")
const STAR_EMPTY := preload("res://assets/icons/ui/star_empty.svg")
const PROJ_COLORS := {"arrow": Color("ffe0a0"), "cannonball": Color("2a2a32"), "bolt": Color("ffd890"), "lightning": Color("c8a0ff")}
const PROJ_SOUND := {"arrow": "arrow", "cannonball": "cannon", "bolt": "arrow", "lightning": "thunder"}
const ELIXIR_COLOR := Color("ff5ad2")

var sim := RaidSim.new()
var base: Dictionary = {}
var mode := "attack"
var seed := 0
var _structs := {}  # id -> { node, model, turret, bar }
var _units := {}  # id -> { rig, bar, ring }
var _walls := {}  # cellule -> Structure
var _camera: Camera3D
var _cam_home: Transform3D
var _shake := 0.0
var _ui: CanvasLayer
var _bars_layer: Control
var _cards_row: HBoxContainer
var _next_card: TextureRect
var _elixir_cells: Array = []
var _elixir_label: Label
var _timer_label: Label
var _pct_label: Label
var _stars_box: HBoxContainer
var _hint: Label
var _selected := -1
var _forbid: MeshInstance3D
var _ended := false
var _stars_shown := 0
var _hand_cache := []


func _ready() -> void:
	var p: Dictionary = GameState.pending_raid if not GameState.pending_raid.is_empty() else {"mode": "attack", "seed": randi()}
	mode = p.get("mode", "attack")
	seed = int(p.get("seed", randi()))
	if mode == "defense":
		base = RaidBaseGen.from_city(GameState.city)
		sim.waves = RaidBaseGen.defense_waves(base.level, seed)
	else:
		base = p.get("base", RaidBaseGen.generate(1, seed))
	var deck := RaidSim.build_deck(GameState.collection, GameClock.now())
	sim.setup(base, deck, 150.0 if mode == "defense" else 180.0, mode == "defense", seed)
	_build_world()
	_build_ui()
	AudioManager.stop_ambience(0.5)
	AudioManager.play_music("music_boss" if mode == "defense" else "music_battle")
	AudioManager.sfx("horn", 0.0)


# --- Monde ---------------------------------------------------------------------------

func _build_world() -> void:
	var env := CaveEnvironment.new()
	add_child(env)
	env.build(Vector2i(sim.width, sim.height), Rect2i(0, 0, sim.width, sim.height))
	for s: RaidSim.Structure in sim.structures:
		_spawn_structure(s)
	for s: RaidSim.Structure in sim.structures:
		if s.is_wall:
			_update_links(s)
	_camera = Camera3D.new()
	_camera.fov = 42.0
	var c := Vector3(sim.width * 0.5, 0, sim.height * 0.5)
	var span := maxf(sim.width / 1.6, sim.height)
	_camera.position = c + Vector3(0, span * 1.02, span * 0.66)
	add_child(_camera)
	# Cible un peu vers la caméra : la carte remonte au-dessus de la barre de cartes.
	_camera.look_at(c + Vector3(0, 0, span * 0.11))
	_cam_home = _camera.transform
	# Zone interdite au déploiement (affichée quand une carte est choisie)
	_forbid = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(sim.width, sim.height)
	_forbid.mesh = plane
	_forbid.position = Vector3(sim.width * 0.5, 0.04, sim.height * 0.5)
	_forbid.visible = false
	add_child(_forbid)


func _spawn_structure(s: RaidSim.Structure) -> void:
	var node := Node3D.new()
	node.position = Vector3(s.cell.x + s.size.x * 0.5, 0, s.cell.y + s.size.y * 0.5)
	add_child(node)
	var model: Node3D
	if s.data_id == "raid_keep":
		model = KEEP_MODEL.instantiate()
		ModelRig.apply(model, BuildingModels.tier_for_level(s.level))
	else:
		model = BuildingModels.build(DataRegistry.building(s.data_id), s.level)
	node.add_child(model)
	var turret: Node3D = _find_prefix(model, "turret")
	if turret and String(turret.name).contains("spin"):
		turret = null
	_structs[s.id] = {"node": node, "model": model, "turret": turret, "bar": null}
	if s.is_wall:
		_walls[s.cell] = s


func _update_links(s: RaidSim.Structure) -> void:
	if not _structs.has(s.id):
		return
	WallLinks.apply(_structs[s.id].model, func(off: Vector2i) -> bool:
		var o: RaidSim.Structure = _walls.get(s.cell + off)
		return o != null and o.alive())


func _find_prefix(n: Node, prefix: String) -> Node3D:
	for c in n.get_children():
		if String(c.name).begins_with(prefix) and c is Node3D:
			return c
		var r := _find_prefix(c, prefix)
		if r:
			return r
	return null


func _spawn_unit(u: RaidSim.Unit) -> void:
	var rig := CharacterRig.new()
	add_child(rig)
	var scene: PackedScene = DataRegistry.hero(u.source_id).model_scene if u.is_hero else DataRegistry.monster(u.source_id).model_scene
	rig.setup(scene)
	var box := BuildingNode.model_aabb(rig)
	var s := 2.1 if u.is_hero else clampf(1.0 / maxf(box.size.y, 0.05), 0.5, 4.0)
	if not u.is_hero:
		s = minf(s, 1.4 / maxf(maxf(box.size.x, box.size.z), 0.05))
	rig.scale = Vector3.ONE * s
	rig.position = Vector3(u.pos.x, 0.0 if not u.flying else 0.5, u.pos.y)
	var ring := MeshKit.part(self, _ring_mesh(), MeshKit.glow_mat(Color("4aa8ff") if u.side == (1 if mode == "defense" else 0) else Color("ff4a4a"), 1.5), rig.position + Vector3(0, 0.03, 0))
	ring.scale = Vector3.ONE * (1.5 if u.is_hero else 1.2)
	_units[u.id] = {"rig": rig, "ring": ring, "bar": null, "t": randf() * 10.0}
	Fx.burst(self, rig.position + Vector3(0, 0.3, 0), Color("bfe4ff"), 18, 2.0, 0.06, 1.0, 0.7)


var _ring_cache: Mesh


func _ring_mesh() -> Mesh:
	if _ring_cache == null:
		var t := TorusMesh.new()
		t.inner_radius = 0.26
		t.outer_radius = 0.33
		t.rings = 16
		t.ring_segments = 4
		_ring_cache = t
	return _ring_cache


# --- Boucle ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _ended:
		sim.step(delta)
		for e in sim.drain_events():
			_on_event(e)
	_update_units(delta)
	_update_turrets(delta)
	_update_bars()
	_update_ui()
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		_camera.transform = _cam_home
		_camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.5
	if sim.is_over() and not _ended:
		_finish()


func _on_event(e: Dictionary) -> void:
	match e.type:
		"spawn":
			_spawn_unit(e.unit)
		"shot":
			_projectile_from_struct(e.struct, e.unit, e.projectile)
		"hit":
			_unit_hits_struct(e.unit, e.struct, e.ranged)
		"duel":
			_unit_hits_unit(e.unit, e.foe, e.ranged)
		"heal":
			if _units.has(e.unit.id):
				Fx.burst(self, _units[e.unit.id].rig.position + Vector3(0, 0.5, 0), Color("7aff8a"), 10, 1.2, 0.05, 1.0, 0.8)
			AudioManager.sfx("heal", 0.05, -10.0)
		"destroyed":
			_destroy_struct(e.struct)
		"unit_dead":
			_kill_unit(e.unit)
		"wave":
			AudioManager.sfx("horn", 0.0)
			_toast("Vague %d !" % e.index, Color("ff8a6a"))


func _update_units(delta: float) -> void:
	for u: RaidSim.Unit in sim.units:
		if not _units.has(u.id) or not u.alive():
			continue
		var d: Dictionary = _units[u.id]
		var rig: CharacterRig = d.rig
		var target := Vector3(u.pos.x, 0.5 if u.flying else 0.0, u.pos.y)
		var move := target - rig.position
		move.y = 0
		if move.length() > 0.004:
			rig.rotation.y = lerp_angle(rig.rotation.y, atan2(move.x, move.z), minf(1.0, delta * 10.0))
			d.t += delta * 12.0
			target.y += absf(sin(d.t)) * 0.06
		rig.position = rig.position.lerp(target, minf(1.0, delta * 14.0))
		d.ring.position = Vector3(rig.position.x, 0.03, rig.position.z)


func _update_turrets(delta: float) -> void:
	for s: RaidSim.Structure in sim.structures:
		if not s.alive() or s.target == null or not _structs.has(s.id):
			continue
		var t: Node3D = _structs[s.id].turret
		if t == null:
			continue
		var node: Node3D = _structs[s.id].node
		var dir := Vector3(s.target.pos.x, 0, s.target.pos.y) - node.position
		t.rotation.y = lerp_angle(t.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 8.0))


# --- Effets ----------------------------------------------------------------------------

func _top_of(s: RaidSim.Structure) -> Vector3:
	var node: Node3D = _structs[s.id].node
	var h := 1.0 if s.is_wall else (2.6 if s.is_keep else 1.8)
	return node.position + Vector3(0, h, 0)


func _unit_world(u: RaidSim.Unit) -> Vector3:
	if _units.has(u.id):
		return _units[u.id].rig.position + Vector3(0, 0.35, 0)
	return Vector3(u.pos.x, 0.35, u.pos.y)


func _projectile_from_struct(s: RaidSim.Structure, u: RaidSim.Unit, kind: String) -> void:
	if not _structs.has(s.id):
		return
	var from := _top_of(s)
	var to := _unit_world(u)
	AudioManager.sfx(PROJ_SOUND.get(kind, "arrow"), 0.08, -6.0)
	if kind == "lightning":
		_lightning(from, to)
		return
	var color: Color = PROJ_COLORS.get(kind, Color.WHITE)
	var mesh := MeshKit.sphere(0.16 if kind == "cannonball" else 0.07, false, 8)
	var mat := MeshKit.glow_mat(color, 0.4 if kind == "cannonball" else 3.0)
	var p := MeshKit.part(self, mesh, mat, from)
	var dur := 0.35 if kind == "cannonball" else 0.22
	var arc := 1.4 if kind == "cannonball" else 0.3
	var tw := create_tween()
	tw.tween_method(func(k: float): p.position = from.lerp(to, k) + Vector3(0, sin(k * PI) * arc, 0), 0.0, 1.0, dur)
	tw.tween_callback(func():
		Fx.burst(self, to, color.lightened(0.4), 8, 1.6, 0.05, 1.0, 0.5)
		p.queue_free())


func _lightning(from: Vector3, to: Vector3) -> void:
	var mat := MeshKit.glow_mat(Color("d8b8ff"), 5.0)
	var nodes := []
	var prev := from
	for k in range(1, 7):
		var q := from.lerp(to, k / 6.0) + Vector3(randf_range(-0.15, 0.15), randf_range(-0.1, 0.1), randf_range(-0.15, 0.15))
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, prev.distance_to(q))
		seg.mesh = box
		seg.material_override = mat
		add_child(seg)
		seg.position = (prev + q) * 0.5
		if prev.distance_to(q) > 0.01:
			seg.look_at_from_position(seg.position, q, Vector3.UP if absf((q - prev).normalized().y) < 0.99 else Vector3.RIGHT)
		nodes.append(seg)
		prev = q
	Fx.burst(self, to, Color("d8b8ff"), 14, 2.2, 0.05, 1.0, 0.5)
	get_tree().create_timer(0.14).timeout.connect(func():
		for n in nodes:
			if is_instance_valid(n):
				n.queue_free())


func _unit_hits_struct(u: RaidSim.Unit, s: RaidSim.Structure, ranged: bool) -> void:
	if not _structs.has(s.id) or not _units.has(u.id):
		return
	var to: Vector3 = _structs[s.id].node.position + Vector3(0, 0.6, 0)
	var color: Color = BattleScene.ELEMENT_COLORS[u.element]
	if ranged:
		var from := _unit_world(u)
		var p := MeshKit.part(self, MeshKit.sphere(0.08, false, 8), MeshKit.glow_mat(color, 3.0), from)
		var tw := create_tween()
		tw.tween_property(p, "position", to, 0.2)
		tw.tween_callback(func():
			Fx.burst(self, to, color, 6, 1.4, 0.05, 1.0, 0.4)
			p.queue_free())
		AudioManager.element(u.element, -10.0)
	else:
		var rig: CharacterRig = _units[u.id].rig
		var lunge := create_tween()
		var dir := (to - rig.position)
		dir.y = 0
		lunge.tween_property(rig, "position", rig.position + dir.normalized() * 0.15, 0.06)
		Fx.burst(self, to, Color("ffd0a0"), 5, 1.4, 0.04, 1.0, 0.35)
		AudioManager.sfx("hit", 0.1, -12.0)
	var m: Node3D = _structs[s.id].model
	var pop := create_tween()
	pop.tween_property(m, "scale", Vector3(1.03, 0.97, 1.03), 0.04)
	pop.tween_property(m, "scale", Vector3.ONE, 0.08)


func _unit_hits_unit(u: RaidSim.Unit, foe: RaidSim.Unit, ranged: bool) -> void:
	if not _units.has(foe.id):
		return
	var to := _unit_world(foe)
	Fx.burst(self, to, Color("fff1c0"), 6, 1.6, 0.04, 1.0, 0.35)
	AudioManager.sfx("slash" if not ranged else "magic", 0.1, -10.0)


func _destroy_struct(s: RaidSim.Structure) -> void:
	if not _structs.has(s.id):
		return
	var d: Dictionary = _structs[s.id]
	var node: Node3D = d.node
	var model: Node3D = d.model
	var big := not s.is_wall
	Fx.dust(self, node.position, maxf(s.size.x, s.size.y) * 0.6)
	Fx.burst(self, node.position + Vector3(0, 0.8, 0), Color("ffb070"), 30 if big else 8, 3.0, 0.07, 1.2, 0.9)
	AudioManager.sfx("collapse" if big else "earth", 0.05, 0.0 if big else -8.0)
	if big:
		_shake = 0.35 if not s.is_keep else 0.7
		if not s.loot.is_empty():
			_float_loot(node.position + Vector3(0, 2.0, 0), s.loot)
	var tw := create_tween().set_parallel()
	tw.tween_property(model, "position:y", -2.2 if big else -0.8, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(model, "rotation:z", randf_range(-0.25, 0.25), 0.9)
	tw.chain().tween_callback(func():
		model.visible = false
		_rubble(node, s))
	if s.is_wall:
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var o: RaidSim.Structure = _walls.get(s.cell + off)
			if o:
				_update_links(o)
	if s.is_keep and mode == "attack":
		_toast("Donjon détruit !", UiTheme.GOLD)


func _rubble(node: Node3D, s: RaidSim.Structure) -> void:
	var mat := MeshKit.mat(Color("5a5560"))
	var n := 3 if s.is_wall else 8
	for i in n:
		var b := BoxMesh.new()
		var r := randf_range(0.12, 0.3) * (1.0 if s.is_wall else 1.6)
		b.size = Vector3(r, r * 0.6, r)
		var m := MeshInstance3D.new()
		m.mesh = b
		m.material_override = mat
		node.add_child(m)
		m.position = Vector3(randf_range(-0.45, 0.45) * s.size.x, r * 0.3, randf_range(-0.45, 0.45) * s.size.y)
		m.rotation = Vector3(randf() * 0.5, randf() * TAU, randf() * 0.5)


func _kill_unit(u: RaidSim.Unit) -> void:
	if not _units.has(u.id):
		return
	var d: Dictionary = _units[u.id]
	_units.erase(u.id)
	var rig: CharacterRig = d.rig
	Fx.burst(self, rig.position + Vector3(0, 0.3, 0), Color("c8c8d8"), 16, 2.0, 0.06, 1.0, 0.7)
	AudioManager.sfx("ko", 0.1, -6.0)
	if d.bar:
		d.bar.queue_free()
	d.ring.queue_free()
	var tw := create_tween()
	tw.tween_property(rig, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(rig.queue_free)


func _float_loot(pos: Vector3, loot: Dictionary) -> void:
	var parts := []
	for k in loot:
		parts.append("+%s %s" % [Fmt.amount(loot[k]), DataRegistry.resource_type(k).display_name.to_lower()])
	var l := Label3D.new()
	l.text = "\n".join(parts)
	l.font = BuildingNode.TITLE_FONT
	l.font_size = 64
	l.outline_size = 16
	l.modulate = UiTheme.GOLD
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	l.position = pos
	add_child(l)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", pos.y + 1.2, 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
	AudioManager.sfx("coin", 0.1, -6.0)


# --- Barres de vie (2D, au-dessus des modèles) ---------------------------------------------

func _bar(width: float, color: Color) -> Control:
	var bg := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	sb.set_corner_radius_all(4)
	bg.add_theme_stylebox_override("panel", sb)
	bg.size = Vector2(width, 9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2(1, 1)
	fill.size = Vector2(width - 2, 7)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fill)
	_bars_layer.add_child(bg)
	return bg


func _update_bars() -> void:
	for s: RaidSim.Structure in sim.structures:
		if not _structs.has(s.id):
			continue
		var d: Dictionary = _structs[s.id]
		var show: bool = s.alive() and s.hp < s.max_hp
		if show and d.bar == null:
			d.bar = _bar(70.0 if not s.is_wall else 36.0, Color("ff5a5a") if mode == "attack" else Color("5ad26a"))
		if d.bar:
			d.bar.visible = show
			if show:
				_place_bar(d.bar, _top_of(s) + Vector3(0, 0.4, 0), s.hp / s.max_hp)
	for u: RaidSim.Unit in sim.units:
		if not _units.has(u.id) or not u.alive():
			continue
		var d: Dictionary = _units[u.id]
		if d.bar == null:
			var friendly := u.side == (1 if mode == "defense" else 0)
			d.bar = _bar(44.0, Color("5ac8ff") if friendly else Color("ff5a5a"))
		_place_bar(d.bar, d.rig.position + Vector3(0, 1.45 if u.is_hero else 1.2, 0), u.hp / u.max_hp)


func _place_bar(bar: Control, world: Vector3, ratio: float) -> void:
	if _camera.is_position_behind(world):
		bar.visible = false
		return
	bar.position = _camera.unproject_position(world) - Vector2(bar.size.x * 0.5, 0)
	var fill: ColorRect = bar.get_child(0)
	fill.size.x = maxf(0.0, (bar.size.x - 2) * clampf(ratio, 0.0, 1.0))


# --- Interface ---------------------------------------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	_bars_layer = Control.new()
	_bars_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_bars_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	_ui.add_child(root)
	# En-tête
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 12)
	top.add_theme_constant_override("separation", 14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(UiTheme.label(base.get("name", "Base ennemie") if mode == "attack" else "Défense de HIGHVALE", "TitleLabel", 28))
	info.add_child(UiTheme.label("Niveau %d" % int(base.get("level", 1)), "HudLabel", 18, UiTheme.GOLD))
	top.add_child(info)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	_timer_label = UiTheme.label("3:00", "TitleLabel", 40)
	top.add_child(_timer_label)
	var spacer2 := spacer.duplicate()
	top.add_child(spacer2)
	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars_box = HBoxContainer.new()
	_stars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		_stars_box.add_child(UiTheme.icon_rect(STAR_EMPTY, 46))
	if mode == "attack":
		right.add_child(_stars_box)
	_pct_label = UiTheme.label("0 %", "HeaderLabel", 24)
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_pct_label)
	top.add_child(right)
	var end_btn := UiTheme.button("Terminer" if mode == "attack" else "Abandonner", "DangerButton", null, 20)
	end_btn.custom_minimum_size = Vector2(150, 54)
	end_btn.pressed.connect(func():
		if not _ended:
			sim.surrender())
	top.add_child(end_btn)
	# Cartes et énergie
	var bottom := PanelContainer.new()
	var sb := UiTheme.box(Color(0.06, 0.06, 0.14, 0.86), UiTheme.GOLD.darkened(0.3), 22, 3, 6)
	sb.set_content_margin_all(10)
	bottom.add_theme_stylebox_override("panel", sb)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 8)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(bottom)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	bottom.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var nextbox := VBoxContainer.new()
	nextbox.add_child(UiTheme.label("Suivante", "DimLabel", 14))
	_next_card = UiTheme.icon_rect(null, 60)
	nextbox.add_child(_next_card)
	row.add_child(nextbox)
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 10)
	row.add_child(_cards_row)
	var ebar := HBoxContainer.new()
	ebar.add_theme_constant_override("separation", 3)
	col.add_child(ebar)
	_elixir_label = UiTheme.label("5", "HeaderLabel", 24, ELIXIR_COLOR.lightened(0.3))
	_elixir_label.custom_minimum_size = Vector2(34, 0)
	ebar.add_child(_elixir_label)
	for i in int(RaidSim.ELIXIR_MAX):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(40, 14)
		cell.color = ELIXIR_COLOR
		ebar.add_child(cell)
		_elixir_cells.append(cell)
	_hint = UiTheme.label("Choisissez une carte puis touchez le terrain hors de la base." if mode == "attack" else "Déployez vos héros près du Temple pour repousser la horde !", "HudLabel", 20)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 96)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)
	_rebuild_cards()


func _rebuild_cards() -> void:
	for c in _cards_row.get_children():
		c.queue_free()
	_hand_cache = sim.hand().duplicate()
	for slot in _hand_cache.size():
		var card: Dictionary = sim.deck[_hand_cache[slot]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 122)
		b.focus_mode = Control.FOCUS_NONE
		var sb := UiTheme.box(GameEnums.rarity_color(card.rarity).darkened(0.55), GameEnums.rarity_color(card.rarity) if slot != _selected else UiTheme.GOLD,
			14, 3 if slot != _selected else 6, 4)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 0)
		b.add_child(v)
		var pic := UiTheme.icon_rect(card.portrait, 78)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(pic)
		var cost := UiTheme.label("%d" % int(card.cost), "HeaderLabel", 22, ELIXIR_COLOR.lightened(0.35))
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cost)
		var nm := UiTheme.label(card.name + ("" if int(card.get("count", 1)) <= 1 else " ×%d" % card.count), "DimLabel", 13)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		v.add_child(nm)
		if card.rarity >= GameEnums.Rarity.LEGENDARY:
			UiFx.shine(b, 0.3, 3.0)
		if slot == _selected:
			b.position.y = -10
		b.pressed.connect(func(): _select(slot))
		_cards_row.add_child(b)
	var nxt := sim.next_card()
	_next_card.texture = sim.deck[nxt].portrait if nxt >= 0 else null


func _select(slot: int) -> void:
	AudioManager.sfx("tab")
	_selected = -1 if _selected == slot else slot
	_rebuild_cards()
	_refresh_forbidden()


func _refresh_forbidden() -> void:
	_forbid.visible = _selected >= 0
	if not _forbid.visible:
		return
	var img := Image.create(sim.width, sim.height, false, Image.FORMAT_RGBA8)
	for x in sim.width:
		for y in sim.height:
			img.set_pixel(x, y, Color(0.2, 0.9, 0.4, 0.18) if sim.can_deploy_at(Vector2i(x, y)) else Color(1.0, 0.15, 0.15, 0.32))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_forbid.material_override = mat


func _update_ui() -> void:
	var t := maxi(0, ceili(sim.time_left))
	_timer_label.text = "%d:%02d" % [t / 60, t % 60]
	_timer_label.modulate = Color("ff6a6a") if t <= 20 else Color.WHITE
	if mode == "attack":
		_pct_label.text = "%d %%" % roundi(sim.destruction() * 100)
		var st := sim.stars()
		while _stars_shown < st:
			var icon: TextureRect = _stars_box.get_child(_stars_shown)
			icon.texture = STAR
			icon.pivot_offset = icon.size / 2
			icon.scale = Vector2(2, 2)
			create_tween().tween_property(icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
			AudioManager.sfx("star_get", 0.0)
			_stars_shown += 1
	else:
		var keep: RaidSim.Structure = null
		for s: RaidSim.Structure in sim.structures:
			if s.is_keep:
				keep = s
		_pct_label.text = "Temple : %d %%" % roundi(100.0 * keep.hp / keep.max_hp) if keep else ""
	_elixir_label.text = "%d" % floori(sim.elixir)
	for i in _elixir_cells.size():
		var cell: ColorRect = _elixir_cells[i]
		var fillv := clampf(sim.elixir - i, 0.0, 1.0)
		cell.color = ELIXIR_COLOR if fillv >= 1.0 else ELIXIR_COLOR.darkened(0.75).lerp(ELIXIR_COLOR.darkened(0.3), fillv)
	if sim.hand() != _hand_cache:
		_rebuild_cards()
	for slot in _cards_row.get_child_count():
		if slot < _hand_cache.size():
			var b: Button = _cards_row.get_child(slot)
			b.modulate = Color.WHITE if sim.card_reason(slot) == "" else Color(0.55, 0.55, 0.65)


func _unhandled_input(event: InputEvent) -> void:
	if _ended or _selected < 0:
		return
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	else:
		return
	var origin := _camera.project_ray_origin(pos)
	var dir := _camera.project_ray_normal(pos)
	if absf(dir.y) < 0.001:
		return
	var hit := origin + dir * (-origin.y / dir.y)
	var cell := Vector2i(floori(hit.x), floori(hit.z))
	var r := sim.deploy(_selected, cell)
	if r != "":
		AudioManager.sfx("error", 0.0, -6.0)
		_toast(r, Color("ff8a8a"))
		return
	AudioManager.sfx("deploy", 0.05)
	_hint.visible = false
	_selected = -1
	_rebuild_cards()
	_refresh_forbidden()


func _toast(text: String, color: Color) -> void:
	var l := UiTheme.label(text, "TitleLabel", 34, color)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(l)
	l.position.y -= 120
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 60, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


# --- Fin ------------------------------------------------------------------------------

func _finish() -> void:
	_ended = true
	_selected = -1
	_forbid.visible = false
	AudioManager.stop_music(0.4)
	var now := GameClock.now()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var title := ""
	var won := false
	if mode == "attack":
		var st := sim.stars()
		won = st > 0
		title = "Victoire !" if won else "Défaite…"
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in 3:
			var ic := UiTheme.icon_rect(STAR if i < st else STAR_EMPTY, 84)
			stars.add_child(ic)
		body.add_child(stars)
		body.add_child(UiTheme.label("Destruction : %d %%" % roundi(sim.destruction() * 100), "HeaderLabel", 24))
		var rew := RaidRules.raid_rewards(sim, int(base.level))
		var got := {}
		for k in rew:
			got[k] = GameState.wallet.add(k, rew[k])
		var dt := RaidRules.trophy_change(st, int(base.level))
		GameState.profile["trophies"] = maxi(0, RaidRules.trophies(GameState.profile) + dt)
		GameState.profile["raids_won"] = int(GameState.profile.get("raids_won", 0)) + (1 if won else 0)
		if not got.is_empty():
			body.add_child(UiTheme.label("Butin", "HudLabel", 20, UiTheme.GOLD))
			body.add_child(UiTheme.cost_row(got, null, 24))
		body.add_child(UiTheme.label("Trophées : %s%d  (total %d)" % ["+" if dt >= 0 else "", dt, RaidRules.trophies(GameState.profile)], "HeaderLabel", 22,
			UiTheme.GOLD if dt >= 0 else Color("ff8a8a")))
		Events.action_done.emit("raid", 1)
		if won:
			Events.action_done.emit("battle_win", 1)
		for i in st:
			get_tree().create_timer(0.5 + i * 0.35).timeout.connect(func(): AudioManager.sfx("star_get", 0.0))
	else:
		var keep_alive := not sim.keep_destroyed()
		won = keep_alive
		title = "HIGHVALE est sauvée !" if won else "Le Temple est tombé…"
		var rew := RaidRules.defense_rewards(won, int(base.level), GameState.wallet)
		if won:
			var got := {}
			for k in rew:
				got[k] = GameState.wallet.add(k, rew[k])
			body.add_child(UiTheme.label("Récompense de défense", "HudLabel", 20, UiTheme.GOLD))
			body.add_child(UiTheme.cost_row(got, null, 24))
		else:
			var lost := {}
			for k in rew:
				lost[k] = -int(rew[k])
			GameState.wallet.spend(lost)
			body.add_child(UiTheme.label("Les pillards ont emporté :", "HudLabel", 20, Color("ff8a8a")))
			body.add_child(UiTheme.cost_row(lost, null, 24))
		GameState.profile["next_defense_at"] = now + RaidRules.DEFENSE_INTERVAL
	AudioManager.sfx("jingle_victory" if won else "jingle_defeat", 0.0)
	GameState.pending_raid = {}
	GameState.save()
	var buttons := [{"text": "Retour à la cité", "variation": "PrimaryButton", "action": func(): SceneRouter.go_to(SceneRouter.CITY)}]
	if mode == "attack":
		buttons.push_front({"text": "Nouvel assaut", "variation": "SecondaryButton", "action": func():
			var lvl := RaidBaseGen.level_for_trophies(RaidRules.trophies(GameState.profile))
			var cost := RaidRules.search_cost(lvl)
			if not GameState.wallet.spend(cost):
				Events.toast_requested.emit("Pas assez d'or pour chercher un adversaire", "error")
				SceneRouter.go_to(SceneRouter.CITY)
				return
			var s := randi()
			GameState.pending_raid = {"mode": "attack", "seed": s, "base": RaidBaseGen.generate(lvl, s)}
			SceneRouter.go_to(SceneRouter.RAID)})
	var dlg_parent := Control.new()
	dlg_parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg_parent.theme = UiTheme.get_theme()
	_ui.add_child(dlg_parent)
	await get_tree().create_timer(1.2).timeout
	DialogBox.open(dlg_parent, title, body, buttons, 640)
