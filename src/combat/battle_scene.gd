class_name BattleScene
extends Node3D
## Arène de combat 3D : met en scène le BattleState (déplacements, projectiles,
## chiffres de dégâts, caméra cinématique), interface manuelle ou automatique.

const STATUS_NAMES := {1: "Brûlure", 2: "Gel", 3: "Poison", 4: "Paralysie", 5: "Affaibli", 6: "Bouclier", 7: "Régénération", 8: "Étourdi", 9: "Provocation"}
const ELEMENT_COLORS := LabMachine.ELEMENT_COLORS
const MELEE_CLASSES := [GameEnums.HeroClass.WARRIOR, GameEnums.HeroClass.GUARDIAN, GameEnums.HeroClass.ASSASSIN, GameEnums.HeroClass.BERSERKER]
const PLAYER_SLOTS := [Vector3(-2.4, 0, 0), Vector3(-2.9, 0, -1.4), Vector3(-2.9, 0, 1.4), Vector3(-3.9, 0, -0.7), Vector3(-3.9, 0, 0.7)]

var battle := BattleState.new()
var encounter: EncounterData
var zone: ZoneData
var auto := false
var speed := 1
var _rigs := {}  # uid -> CharacterRig
var _bars := {}  # uid -> UnitBar
var _shields := {}  # uid -> MeshInstance3D
var _camera: Camera3D
var _cam_home := Transform3D()
var _ui: Control
var _skill_bar: HBoxContainer
var _actor_label: Label
var _round_label: Label
var _order_row: HBoxContainer
var _auto_btn: Button
var _speed_btn: Button
var _pending_choice := {}
var _picking_skill: SkillData
var _waiting_input := false


func _ready() -> void:
	encounter = DataRegistry.encounters()[0]
	if GameState.pending_battle != null:
		encounter = GameState.pending_battle
	elif GameState.pending_zone != "":
		zone = DataRegistry.zone(GameState.pending_zone)
		encounter = zone.encounter(GameState.pending_stage)
	else:
		for e in DataRegistry.encounters():
			if e.id == GameState.pending_encounter:
				encounter = e
	_build_arena()
	var team := GameState.collection.build_team_combatants()
	BattleSetup.apply_city_bonus(team, GameState.city)
	battle.setup(team, BattleSetup.enemies_for(encounter))
	_build_ui()
	_spawn_units()
	AudioManager.play_music("music_battle")
	_run.call_deferred()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# --- Arène ---------------------------------------------------------------------

func _build_arena() -> void:
	var surface := zone != null and zone.is_surface
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = zone.sky_color if zone else Color("070a16")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c8d8ff") if surface else Color("5060a0")
	env.ambient_light_energy = 0.55 if surface else 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = Settings.glow_enabled()
	env.glow_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = zone.sky_color if zone else Color("0c1430")
	env.fog_density = 0.003 if surface else 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.15 if surface else 1.0
	sun.light_color = zone.light_color if zone else Color.WHITE
	sun.shadow_enabled = Settings.shadows_enabled and Settings.quality > 0
	add_child(sun)
	var ground := PlaneMesh.new()
	ground.size = Vector2(60, 60)
	var gm := ShaderMaterial.new()
	gm.shader = preload("res://assets/shaders/cave_ground.gdshader")
	gm.set_shader_parameter("buildable", Vector4(-5.5, -3.5, 5.5, 3.5))
	if zone:
		gm.set_shader_parameter("rock_light", zone.ground_color)
		gm.set_shader_parameter("rock_dark", zone.ground_color.darkened(0.5))
		if surface:
			gm.set_shader_parameter("moss_color", Color("5aa040"))
			gm.set_shader_parameter("floor_color", Color("8a7a5a"))
	MeshKit.part(self, ground, gm)
	var props := PropScatter.new()
	add_child(props)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(encounter.id)
	for i in 22:
		var a := TAU * i / 22.0
		var r := rng.randf_range(9.0, 12.0)
		var p := Vector3(cos(a) * r * 1.3, 0, sin(a) * r)
		if p.z > 4.0 and absf(p.x) < 6.0:
			continue  # dégage la vue de la caméra
		var kinds := ["tree_pine", "tree_round", "boulder"] if surface else ["cliff_a", "cliff_b", "cliff_c"]
		props.add(kinds[i % 3], p, rng.randf_range(0.8, 1.3) * (1.6 if surface else 1.0), rng.randf() * TAU)
	for i in 8:
		var a := rng.randf() * TAU
		var p := Vector3(cos(a) * 7.5, 0, sin(a) * 5.2 - 1.0)
		if p.z > 1.5:
			p.z = -p.z  # rien entre la caméra et l'arène
		var inner := ["tree_round", "boulder", "tree_pine", "ruin_pillar"] if surface else ["crystals_blue", "crystals_violet", "mushrooms_teal", "stalagmite"]
		props.add(inner[i % 4], p, rng.randf_range(0.6, 1.0), rng.randf() * TAU)
		if i % 2 == 0 and not surface:
			var l := OmniLight3D.new()
			l.light_color = Color("7fdcff") if i % 4 == 0 else Color("c2b4ff")
			l.light_energy = 1.4
			l.omni_range = 6.0
			l.position = p + Vector3(0, 1.5, 0)
			add_child(l)
	props.build()
	_camera = Camera3D.new()
	_camera.fov = 42
	add_child(_camera)
	_camera.position = Vector3(0, 5.2, 8.6)
	_camera.look_at(Vector3(0, 0.6, -0.2))
	_cam_home = _camera.transform


func _slot_pos(c: Combatant) -> Vector3:
	var p: Vector3 = PLAYER_SLOTS[c.slot % PLAYER_SLOTS.size()]
	return Vector3(-p.x, 0, p.z) if c.side == 1 else p


func _spawn_units() -> void:
	for c: Combatant in battle.units:
		var rig := CharacterRig.new()
		add_child(rig)
		rig.setup(c.model_scene)
		# Taille homogène : hauteur cible, sans que les créatures allongées deviennent géantes.
		var box := BuildingNode.model_aabb(rig)
		var horiz := maxf(box.size.x, box.size.z)
		var s := minf(1.05 / maxf(box.size.y, 0.05), 1.15 / maxf(horiz, 0.05))
		rig.scale = Vector3.ONE * s * (1.35 if c.is_boss else 1.0)
		rig.position = _slot_pos(c)
		rig.rotation.y = PI / 2.0 if c.side == 0 else -PI / 2.0
		_rigs[c.uid] = rig
		var bar := UnitBar.new()
		bar.unit = c
		_ui.add_child(bar)
		_ui.move_child(bar, 0)
		_bars[c.uid] = bar


func _process(_delta: float) -> void:
	for uid in _bars:
		var rig: CharacterRig = _rigs[uid]
		var bar: UnitBar = _bars[uid]
		var top := rig.global_position + Vector3(0, 1.3, 0)
		bar.position = _camera.unproject_position(rig.global_position + Vector3(0, 1.3 * (1.4 if bar.unit.is_boss else 1.0), 0)) - Vector2(55, 30)
		bar.visible = bar.unit.is_alive() and not _camera.is_position_behind(top)


# --- Boucle de combat ------------------------------------------------------------

func _run() -> void:
	await get_tree().create_timer(0.6).timeout
	while not battle.is_over():
		var turn := battle.begin_turn()
		if turn.is_empty():
			break
		_refresh_hud(turn.actor)
		await _play(turn.events)
		if turn.skipped or battle.is_over():
			continue
		var actor: Combatant = turn.actor
		var choice := {}
		if actor.side == 0 and not auto:
			choice = await _player_choice(actor)
		else:
			await get_tree().create_timer(0.35).timeout
			choice = BattleAI.choose(battle, actor, encounter.strategy if actor.side == 1 else "balanced")
		_skill_bar.visible = false
		await _play(battle.act(actor, choice.skill, choice.target))
	_finish()


func _player_choice(actor: Combatant) -> Dictionary:
	_pending_choice = {}
	_waiting_input = true
	_build_skill_buttons(actor)
	while _pending_choice.is_empty():
		if auto:
			_waiting_input = false
			_clear_selection()
			return BattleAI.choose(battle, actor)
		await get_tree().process_frame
	_waiting_input = false
	return _pending_choice


func _build_skill_buttons(actor: Combatant) -> void:
	for c in _skill_bar.get_children():
		c.queue_free()
	_skill_bar.visible = true
	for s: SkillData in actor.skills:
		var cd := int(actor.cooldowns.get(s.id, 0))
		var text := s.display_name
		if s.energy_cost > 0:
			text += "\n%d énergie" % s.energy_cost
		if cd > 0:
			text += "\n(%d tour%s)" % [cd, "s" if cd > 1 else ""]
		var b := UiTheme.button(text, ["SecondaryButton", "PrimaryButton", "PremiumButton", "Button"][s.kind], null, 17)
		b.custom_minimum_size = Vector2(190, 76)
		b.disabled = not actor.can_use(s)
		b.tooltip_text = s.description
		b.pressed.connect(func(): _select_skill(actor, s))
		_skill_bar.add_child(b)


func _select_skill(actor: Combatant, s: SkillData) -> void:
	var targets := battle.valid_targets(actor, s)
	var needs_pick := s.target in [SkillData.Target.SINGLE_ENEMY, SkillData.Target.SINGLE_ALLY] and targets.size() > 1
	if not needs_pick:
		_pending_choice = {"skill": s, "target": targets[0] if not targets.is_empty() else actor}
		return
	_picking_skill = s
	_clear_selection()
	for t in targets:
		_bars[t.uid].selectable = true
	_actor_label.text = "Choisissez une cible pour %s" % s.display_name


func _clear_selection() -> void:
	for b in _bars.values():
		b.selectable = false


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_input or _picking_skill == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var best: Combatant = null
		var best_d := 90.0
		for uid in _bars:
			var bar: UnitBar = _bars[uid]
			if not bar.selectable:
				continue
			var p := _camera.unproject_position(_rigs[uid].global_position + Vector3(0, 0.6, 0))
			var d := p.distance_to(event.position)
			if d < best_d:
				best_d = d
				best = bar.unit
		if best:
			_pending_choice = {"skill": _picking_skill, "target": best}
			_picking_skill = null
			_clear_selection()


# --- Mise en scène ---------------------------------------------------------------

func _play(events: Array) -> void:
	for e in events:
		match e.type:
			"cast":
				await _animate_cast(e.source, e.skill, e.target)
			"damage":
				_hit(e.target, e.amount, e.crit, e.advantage)
				await get_tree().create_timer(0.12).timeout
			"dot":
				_float(e.target, "-%d" % e.amount, Color("ff9a4a"), 1.0)
				_flash(e.target)
				await get_tree().create_timer(0.35).timeout
			"heal":
				AudioManager.sfx("heal")
				Fx.burst(self, _rigs[e.target.uid].global_position + Vector3(0, 0.3, 0), Color("7aff8a"), 16, 1.5, 0.07, 1.0, 1.1)
				_float(e.target, "+%d" % e.amount, Color("7aff8a"), 1.1)
				_glow(e.target, Color("5bd36b"))
				await get_tree().create_timer(0.15).timeout
			"shield":
				_float(e.target, "Bouclier", Color("cfe8ff"), 0.9)
				_set_shield(e.target)
			"status":
				_float(e.target, STATUS_NAMES.get(e.effect, ""), UnitBar.STATUS_COLORS.get(e.effect, Color.WHITE), 0.9, 0.5)
			"phase":
				_float(e.target, "Phase %d : le boss s'enrage !" % e.phase, Color("ff5a5a"), 1.2)
				_glow(e.target, Color("ff5a5a"))
				_shake(0.15)
				_set_shield(e.target)
				await get_tree().create_timer(0.7).timeout
			"skip":
				_float(e.target, "Passe son tour", Color("c8d0e0"), 0.9)
				await get_tree().create_timer(0.5).timeout
			"death":
				_die(e.target)
				await get_tree().create_timer(0.3).timeout
	for c: Combatant in battle.units:
		_set_shield(c)


func _is_melee(c: Combatant) -> bool:
	if c.is_hero:
		return DataRegistry.hero(c.source_id).hero_class in MELEE_CLASSES
	return DataRegistry.monster(c.source_id).category in [GameEnums.MonsterCategory.TERRESTRIAL, GameEnums.MonsterCategory.ANCIENT, GameEnums.MonsterCategory.PLANT]


func _animate_cast(actor: Combatant, skill: SkillData, target: Combatant) -> void:
	var rig: CharacterRig = _rigs[actor.uid]
	_actor_label.text = "%s : %s" % [actor.name, skill.display_name]
	if skill.cinematic:
		await _cinematic(rig, skill)
	var color: Color = ELEMENT_COLORS[skill.element]
	var support := skill.power <= 0.0
	var home := rig.position
	if support:
		_glow(actor, color)
		await get_tree().create_timer(0.35).timeout
		return
	var aoe := skill.target in [SkillData.Target.ALL_ENEMIES, SkillData.Target.ROW_ENEMIES]
	var t_rig: CharacterRig = _rigs[target.uid] if target and _rigs.has(target.uid) else null
	if _is_melee(actor) and t_rig and not aoe:
		AudioManager.sfx("whoosh")
		var dest := t_rig.position + (home - t_rig.position).normalized() * 0.9
		var tw := create_tween()
		tw.tween_property(rig, "position", dest, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(rig, "position", dest + (t_rig.position - dest) * 0.25, 0.06)
		await tw.finished
		var back := create_tween()
		back.tween_property(rig, "position", home, 0.3).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		var from := rig.global_position + Vector3(0, 0.7, 0)
		var dest := (t_rig.global_position if t_rig and not aoe else _side_center(1 - actor.side)) + Vector3(0, 0.6, 0)
		AudioManager.sfx("magic")
		var orb := MeshKit.part(self, MeshKit.sphere(0.18 if not aoe else 0.32, false, 12), MeshKit.glow_mat(color, 4.0), from)
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 2.0
		light.omni_range = 3.0
		orb.add_child(light)
		var tw := create_tween()
		tw.tween_property(orb, "position", dest, 0.32).set_trans(Tween.TRANS_SINE)
		await tw.finished
		orb.queue_free()
		if aoe:
			_shockwave(dest - Vector3(0, 0.6, 0), color)


func _cinematic(rig: CharacterRig, skill: SkillData) -> void:
	var color: Color = ELEMENT_COLORS[skill.element]
	var focus := rig.global_position + Vector3(0, 0.7, 0)
	var tw := create_tween()
	var close := Transform3D(Basis(), focus + Vector3(1.6 * signf(-rig.position.x) * -1.0, 0.9, 2.4)).looking_at(focus)
	tw.tween_property(_camera, "transform", close, 0.35).set_trans(Tween.TRANS_CUBIC)
	_glow_by_rig(rig, color)
	var title := Label3D.new()
	title.text = skill.display_name
	title.font = BuildingNode.TITLE_FONT
	title.font_size = 96
	title.outline_size = 22
	title.modulate = color.lightened(0.3)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = true
	title.pixel_size = 0.004
	title.position = focus + Vector3(0, 0.9, 0)
	add_child(title)
	await tw.finished
	await get_tree().create_timer(0.55).timeout
	title.queue_free()
	var back := create_tween()
	back.tween_property(_camera, "transform", _cam_home, 0.3).set_trans(Tween.TRANS_CUBIC)
	await back.finished


func _side_center(side: int) -> Vector3:
	return Vector3(3.2 if side == 1 else -3.2, 0, 0)


func _hit(t: Combatant, amount: int, crit: bool, adv: int) -> void:
	_flash(t)
	AudioManager.sfx("crit" if crit else "hit")
	Fx.burst(self, _rigs[t.uid].global_position + Vector3(0, 0.6, 0), Color("fff1c0") if crit else Color("ffd0a0"), 26 if crit else 14, 3.0)
	var text := "%s%d" % ["CRITIQUE ! " if crit else "-", amount]
	_float(t, text, Color("ffe04a") if crit else Color.WHITE, 1.4 if crit else 1.1)
	if adv > 0:
		_float(t, "Efficace !", Color("ff9a4a"), 0.8, 0.35)
	elif adv < 0:
		_float(t, "Peu efficace", Color("9aa8c8"), 0.7, 0.35)
	var rig: CharacterRig = _rigs[t.uid]
	var base := _slot_pos(t)
	var tw := create_tween()
	tw.tween_property(rig, "position", base + Vector3(0.18 if t.side == 1 else -0.18, 0, 0), 0.05)
	tw.tween_property(rig, "position", base, 0.12)
	if crit or t.is_boss:
		_shake(0.12 if crit else 0.06)


func _shake(strength: float) -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(_camera, "position", _cam_home.origin + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * strength, 0.04)
	tw.tween_property(_camera, "position", _cam_home.origin, 0.05)


func _flash(t: Combatant) -> void:
	var rig: CharacterRig = _rigs[t.uid]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_set_overlay(rig, m)
	await get_tree().create_timer(0.09).timeout
	if is_instance_valid(rig):
		_set_overlay(rig, null)


func _glow(c: Combatant, color: Color) -> void:
	_glow_by_rig(_rigs[c.uid], color)


func _glow_by_rig(rig: CharacterRig, color: Color) -> void:
	var ring := MeshKit.part(self, MeshKit.torus(0.45, 0.55), MeshKit.glow_mat(color, 3.0), rig.global_position + Vector3(0, 0.05, 0))
	ring.scale = Vector3(0.3, 1, 0.3)
	var tw := ring.create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector3(1.6, 1, 1.6), 0.5)
	tw.tween_property(ring, "position:y", 1.2, 0.5)
	tw.chain().tween_callback(ring.queue_free)


func _shockwave(at: Vector3, color: Color) -> void:
	var ring := MeshKit.part(self, MeshKit.torus(0.8, 1.0), MeshKit.glow_mat(color, 3.5), at + Vector3(0, 0.1, 0))
	ring.scale = Vector3(0.2, 1, 0.2)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3(3.2, 1, 2.4), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_callback(ring.queue_free)
	_shake(0.08)


func _set_shield(c: Combatant) -> void:
	var has: bool = c.shield > 0 and c.is_alive()
	if has and not _shields.has(c.uid):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.6, 0.85, 1.0, 0.22)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(0.4, 0.7, 1.0)
		m.emission_energy_multiplier = 0.6
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shields[c.uid] = MeshKit.part(self, MeshKit.sphere(0.75, false, 18), m, _rigs[c.uid].global_position + Vector3(0, 0.55, 0), Vector3.ZERO, Vector3(1, 1.1, 1))
	elif not has and _shields.has(c.uid):
		_shields[c.uid].queue_free()
		_shields.erase(c.uid)


func _die(c: Combatant) -> void:
	var rig: CharacterRig = _rigs[c.uid]
	var tw := rig.create_tween().set_parallel()
	tw.tween_property(rig, "rotation:z", 1.4 * (1 if c.side == 0 else -1), 0.4)
	tw.tween_property(rig, "scale", rig.scale * 0.01, 0.5).set_delay(0.4)
	_set_shield(c)


func _float(c: Combatant, text: String, color: Color, size_k := 1.0, delay := 0.0) -> void:
	var rig: CharacterRig = _rigs[c.uid]
	var l := Label3D.new()
	l.text = text
	l.font = BuildingNode.TITLE_FONT
	l.font_size = int(64 * size_k)
	l.outline_size = 16
	l.outline_modulate = Color("1b1430")
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	l.render_priority = 10
	l.position = rig.global_position + Vector3(randf_range(-0.2, 0.2), 1.5 + delay, 0)
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 0.9, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


func _set_overlay(n: Node, m: Material) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			c.material_overlay = m
		_set_overlay(c, m)


# --- Interface ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.theme = UiTheme.get_theme()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 12)
	top.add_theme_constant_override("separation", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(top)
	var title := UiTheme.label(encounter.display_name, "TitleLabel", 30)
	top.add_child(title)
	_round_label = UiTheme.label("", "HudLabel", 22)
	top.add_child(_round_label)
	_order_row = HBoxContainer.new()
	_order_row.add_theme_constant_override("separation", 4)
	_order_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_order_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(_order_row)
	_auto_btn = UiTheme.button("Auto : non", "SecondaryButton", null, 20)
	_auto_btn.custom_minimum_size = Vector2(150, 56)
	_auto_btn.pressed.connect(func():
		auto = not auto
		_auto_btn.text = "Auto : oui" if auto else "Auto : non"
		_auto_btn.theme_type_variation = "SuccessButton" if auto else "SecondaryButton")
	top.add_child(_auto_btn)
	_speed_btn = UiTheme.button("Vitesse ×1", "SecondaryButton", null, 20)
	_speed_btn.custom_minimum_size = Vector2(150, 56)
	_speed_btn.pressed.connect(func():
		speed = speed % 3 + 1
		Engine.time_scale = speed
		_speed_btn.text = "Vitesse ×%d" % speed)
	top.add_child(_speed_btn)
	var quit := UiTheme.button("Fuir", "DangerButton", null, 20)
	quit.custom_minimum_size = Vector2(100, 56)
	quit.pressed.connect(func(): DialogBox.open(_ui, "Abandonner le combat ?", "Aucune récompense ne sera obtenue.", [
		{"text": "Continuer", "variation": "SecondaryButton"},
		{"text": "Fuir", "variation": "DangerButton", "action": func(): SceneRouter.go_to(SceneRouter.CITY)}]))
	top.add_child(quit)
	var syn_box := VBoxContainer.new()
	syn_box.position = Vector2(14, 80)
	_ui.add_child(syn_box)
	for side in 2:
		var el := battle.synergy(side)
		if el >= 0:
			syn_box.add_child(UiTheme.label("%s : synergie %s (+10 %% attaque)" % ["Équipe" if side == 0 else "Ennemis", GameEnums.element_name(el)], "HudLabel", 17, UiTheme.GOLD))
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.alignment = BoxContainer.ALIGNMENT_END
	_ui.add_child(bottom)
	_actor_label = UiTheme.label("", "HeaderLabel", 24)
	_actor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_actor_label)
	_skill_bar = HBoxContainer.new()
	_skill_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_skill_bar.add_theme_constant_override("separation", 12)
	_skill_bar.visible = false
	bottom.add_child(_skill_bar)


func _refresh_hud(actor: Combatant) -> void:
	_round_label.text = "Tour %d" % battle.round
	_actor_label.text = "%s %s" % ["À vous :" if actor.side == 0 and not auto else "", actor.name]
	for c in _order_row.get_children():
		c.queue_free()
	var upcoming := [actor] + battle._queue.filter(func(c): return c.is_alive())
	for c: Combatant in upcoming.slice(0, 8):
		var t := ModalScreen.item_tile(c.portrait, "", c.rarity, 48)
		t.custom_minimum_size = Vector2(48, 52)
		t.modulate = Color(1, 1, 1) if c.side == 0 else Color(1, 0.75, 0.75)
		_order_row.add_child(t)


func _finish() -> void:
	Engine.time_scale = 1.0
	_skill_bar.visible = false
	var won := battle.winner == 0
	AudioManager.stop_music(0.3)
	AudioManager.sfx("jingle_victory" if won else "jingle_defeat", 0.0)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	if won:
		Events.action_done.emit("battle_win", 1)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		if GameState.pending_zone == "" and encounter.id.begins_with("event_"):
			GameState.profile["event_day"] = QuestState.day_index(GameClock.now())
			for id in encounter.rewards:
				GameState.wallet.add(id, encounter.rewards[id])
			GameState.save()
			body.add_child(UiTheme.label("Récompenses de l'événement", "HeaderLabel", 24))
			body.add_child(UiTheme.cost_row(encounter.rewards, null, 24))
			_end_dialog(body, won)
			return
		var mult := EventCalendar.REWARD_BONUS
		var got := GameState.exploration.grant(zone, GameState.pending_stage, GameState.collection, GameState.wallet, rng) if zone \
			else BattleSetup.grant_victory(encounter, GameState.collection, GameState.wallet, rng)
		# Bonus de l'événement de la semaine (+50 % des ressources gagnées).
		for id in got.resources:
			var extra := int(got.resources[id] * (mult - 1.0))
			got.resources[id] += GameState.wallet.add(id, extra)
		GameState.save()
		body.add_child(UiTheme.label("Récompenses" + (" (première victoire !)" if got.first else ""), "HeaderLabel", 24))
		body.add_child(UiTheme.cost_row(got.resources, null, 24))
		for id in got.fragments:
			body.add_child(UiTheme.label("+%d fragments : %s" % [got.fragments[id], DataRegistry.hero(id).display_name], "HudLabel", 20, Color("d8b4ff")))
	else:
		body.add_child(UiTheme.label("Votre équipe a été repoussée. Améliorez vos héros, nourrissez vos créatures ou changez de composition.", "", 20))
		body.get_child(0).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_dialog(body, won)


func _end_dialog(body: Control, won: bool) -> void:
	DialogBox.open(_ui, "Victoire !" if won else ("Défaite…" if battle.winner == 1 else "Match nul"), body, [
		{"text": "Rejouer", "variation": "SecondaryButton", "action": func(): SceneRouter.go_to(SceneRouter.BATTLE)},
		{"text": "Retour à la cité", "variation": "PrimaryButton", "action": func(): SceneRouter.go_to(SceneRouter.CITY)}], 620)
