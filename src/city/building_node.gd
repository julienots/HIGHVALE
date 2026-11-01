class_name BuildingNode
extends Node3D
## Représentation 3D d'un bâtiment : modèle, échafaudage de chantier, minuterie,
## bulle de collecte, surbrillance de sélection et animations des pièces mobiles.

const SELECTION_SHADER := preload("res://assets/shaders/selection_glow.gdshader")
const BUBBLE_TEX := preload("res://assets/icons/ui/bubble.svg")
const TITLE_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")

static var _selection_mat: ShaderMaterial

var uid := 0
var _model: Node3D
var _model_level := -1
var _scaffold: Node3D
var _label: Label3D
var _bubble: Node3D
var _bubble_icon: Sprite3D
var _spinners: Array[Node3D] = []
var _bobbers: Array[Dictionary] = []
var _selected := false
var _producing := false
var _time := 0.0
var _model_height := 0.0


func setup(b: BuildingState) -> void:
	uid = b.uid
	name = "Building_%d" % uid
	_label = Label3D.new()
	_label.font = TITLE_FONT
	_label.font_size = 56
	_label.outline_size = 16
	_label.outline_modulate = Color("1b1430")
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 10
	_label.outline_render_priority = 9
	_label.visible = false
	add_child(_label)
	_build_bubble()
	refresh(GameClock.now())


func state() -> BuildingState:
	return GameState.city.get_building(uid)


func refresh(now: float) -> void:
	var b := state()
	if b == null:
		return
	var d := b.data()
	position = Vector3(b.cell.x + d.footprint.x / 2.0, 0, b.cell.y + d.footprint.y / 2.0)
	var shown_level := maxi(b.level, 1)
	if shown_level != _model_level:
		_rebuild_model(d, shown_level)
	var busy := b.is_busy()
	_set_scaffold(busy, d)
	if b.task == BuildingState.Task.CONSTRUCTING:
		_model.scale = Vector3(1, lerpf(0.15, 1.0, b.task_progress(now)), 1)
	else:
		_model.scale = Vector3.ONE
	_producing = not busy and b.level >= 1 and not d.produces.is_empty()
	_label.visible = busy
	if busy:
		var verb := "Construction" if b.task == BuildingState.Task.CONSTRUCTING else "Niveau %d" % (b.level + 1)
		_label.text = "%s  %d%%\n%s" % [verb, int(b.task_progress(now) * 100), Fmt.duration(b.task_remaining(now))]
		_label.position = Vector3(0, _top_height(d) + 0.6, 0)
	_update_bubble(b, d, now)


func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	_apply_overlay()
	if v:
		play_pop(1.06)


func play_pop(amount := 1.12) -> void:
	scale = Vector3.ONE
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(amount, 1.0 / amount, amount), 0.08)
	t.tween_property(self, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Texte flottant (« +350 ») qui s'élève et disparaît.
func float_text(text: String, color: Color) -> void:
	var l := Label3D.new()
	l.font = TITLE_FONT
	l.font_size = 72
	l.outline_size = 18
	l.outline_modulate = Color("1b1430")
	l.modulate = color
	l.pixel_size = 0.009
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 12
	l.outline_render_priority = 11
	l.text = text
	l.position = Vector3(0, _top_height(state().data()) + 0.3, 0)
	add_child(l)
	var t := l.create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y + 1.6, 1.1).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	t.chain().tween_callback(l.queue_free)


func _process(delta: float) -> void:
	_time += delta
	if _producing or _selected:
		for s in _spinners:
			if is_instance_valid(s):
				s.rotation_degrees += (s.get_meta("spin") as Vector3) * delta
	for bob in _bobbers:
		var n: Node3D = bob.node
		if is_instance_valid(n):
			n.position.y = bob.base + sin(_time * 2.2 + bob.phase) * bob.amp
	if _bubble.visible:
		_bubble.position.y = _bubble.get_meta("base_y", 2.0) + sin(_time * 3.0) * 0.08


func _rebuild_model(d: BuildingData, level: int) -> void:
	if _model:
		_model.queue_free()
	_model = BuildingModels.build(d, level)
	_model_level = level
	add_child(_model)
	_model_height = clampf(model_height(_model) - global_position.y, 1.2, 4.5)
	_spinners.clear()
	_bobbers.clear()
	_collect_animated(_model)
	_apply_overlay()
	update_links()


## Remparts : affiche les jonctions vers les remparts voisins.
func update_links() -> void:
	var b := state()
	if _model == null or b == null or not b.data().no_builder:
		return
	var city := GameState.city
	WallLinks.apply(_model, func(off: Vector2i) -> bool:
		var o := city.building_at(b.cell + off)
		return o != null and o.data_id == b.data_id)


func _collect_animated(n: Node) -> void:
	for c in n.get_children():
		if c is Node3D:
			if c.has_meta("spin"):
				_spinners.append(c)
			if c.has_meta("bob"):
				_bobbers.append({"node": c, "base": c.position.y, "amp": float(c.get_meta("bob")), "phase": randf() * TAU})
		_collect_animated(c)


func _apply_overlay() -> void:
	if _selection_mat == null:
		_selection_mat = ShaderMaterial.new()
		_selection_mat.shader = SELECTION_SHADER
	if _model:
		_set_overlay(_model, _selection_mat if _selected else null)


func _set_overlay(n: Node, m: Material) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			c.material_overlay = m
		_set_overlay(c, m)


func _set_scaffold(on: bool, d: BuildingData) -> void:
	if on and _scaffold == null:
		_scaffold = Node3D.new()
		add_child(_scaffold)
		var wood := MeshKit.mat(Color("b08850"))
		var hx := d.footprint.x / 2.0 - 0.2
		var hz := d.footprint.y / 2.0 - 0.2
		var h := _top_height(d) * 0.8 + 0.4
		for c in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(-hx, hz), Vector2(hx, hz)]:
			MeshKit.part(_scaffold, MeshKit.box(Vector3(0.08, h, 0.08)), wood, Vector3(c.x, h / 2, c.y))
		for y in [h * 0.45, h * 0.95]:
			MeshKit.part(_scaffold, MeshKit.box(Vector3(hx * 2, 0.06, 0.08)), wood, Vector3(0, y, hz))
			MeshKit.part(_scaffold, MeshKit.box(Vector3(hx * 2, 0.06, 0.08)), wood, Vector3(0, y, -hz))
			MeshKit.part(_scaffold, MeshKit.box(Vector3(0.08, 0.06, hz * 2)), wood, Vector3(hx, y, 0))
			MeshKit.part(_scaffold, MeshKit.box(Vector3(0.08, 0.06, hz * 2)), wood, Vector3(-hx, y, 0))
		MeshKit.part(_scaffold, MeshKit.box(Vector3(hx * 2.2, 0.06, 0.08)), wood, Vector3(0, h * 0.5, hz + 0.02), Vector3(0, 0, 28))
		BuildingModels._crate(_scaffold, Vector3(hx - 0.1, 0, hz + 0.35), 0.28, 15)
	elif not on and _scaffold:
		_scaffold.queue_free()
		_scaffold = null


func _build_bubble() -> void:
	_bubble = Node3D.new()
	_bubble.visible = false
	add_child(_bubble)
	var bg := Sprite3D.new()
	bg.texture = BUBBLE_TEX
	bg.pixel_size = 0.011
	bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bg.no_depth_test = true
	bg.render_priority = 5
	bg.shaded = false
	_bubble.add_child(bg)
	_bubble_icon = Sprite3D.new()
	_bubble_icon.pixel_size = 0.007
	_bubble_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble_icon.no_depth_test = true
	_bubble_icon.render_priority = 6
	_bubble_icon.position = Vector3(0, 0.08, 0)
	_bubble_icon.shaded = false
	_bubble.add_child(_bubble_icon)


func _update_bubble(b: BuildingState, d: BuildingData, now: float) -> void:
	if d.produces.is_empty() or b.level < 1:
		_bubble.visible = false
		return
	var stored := b.stored_production(now)
	var cap := float(d.internal_capacity(b.level))
	var show := stored >= maxf(1.0, cap * 0.1)
	if show and not _bubble.visible:
		var rt := DataRegistry.resource_type(d.produces)
		_bubble_icon.texture = rt.icon if rt else null
		_bubble.set_meta("base_y", _top_height(d) + 0.7)
	_bubble.visible = show and not b.is_busy()
	var full := stored >= cap - 0.5
	var s := 1.0 + (0.12 * sin(_time * 8.0) if full else 0.0)
	_bubble.scale = Vector3(s, s, s)


func _top_height(d: BuildingData) -> float:
	if _model_height > 0.0:
		return _model_height
	match d.footprint.x:
		4:
			return 3.4
		2:
			return 3.2
	return 2.0


## Boîte englobante (repère monde) des maillages visibles d'un modèle.
static func model_aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for c in n.get_children():
		if c is VisualInstance3D and c.visible and not c is Light3D:
			var a: AABB = c.global_transform * c.get_aabb()
			box = a if first else box.merge(a)
			first = false
		if c is Node3D and c.visible:
			var sub := model_aabb(c)
			if sub.size != Vector3.ZERO:
				box = sub if first else box.merge(sub)
				first = false
	return box


## Hauteur du modèle visible (pour placer minuterie et bulle au-dessus du toit).
static func model_height(n: Node) -> float:
	var top := 0.0
	for c in n.get_children():
		if c is VisualInstance3D and c.visible and not c is Light3D:
			var aabb: AABB = c.global_transform * c.get_aabb()
			top = maxf(top, aabb.end.y)
		if c is Node3D and c.visible:
			top = maxf(top, model_height(c))
	return top
