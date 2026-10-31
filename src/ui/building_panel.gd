class_name BuildingPanel
extends PanelContainer
## Panneau du bâtiment sélectionné : statistiques, chantier et actions.

const ICON_UPGRADE := preload("res://assets/icons/ui/upgrade.svg")
const ICON_MOVE := preload("res://assets/icons/ui/move.svg")
const ICON_COLLECT := preload("res://assets/icons/ui/collect.svg")
const ICON_INFO := preload("res://assets/icons/ui/info.svg")
const ICON_SPEED := preload("res://assets/icons/ui/speedup.svg")
const ICON_CROSS := preload("res://assets/icons/ui/cross.svg")

var controller: Node  # CityScene
var uid := 0
var _title: Label
var _subtitle: Label
var _stats: HBoxContainer
var _progress: ProgressBar
var _progress_label: Label
var _actions: HBoxContainer
var _collect_btn: Button
var _speed_btn: Button
var _workers_row: HBoxContainer
var _workers_label: Label
var _workers_minus: Button
var _workers_plus: Button
var _signature := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -4)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	_title = UiTheme.label("", "TitleLabel", 32)
	titles.add_child(_title)
	_subtitle = UiTheme.label("", "DimLabel", 18)
	titles.add_child(_subtitle)
	var info := UiTheme.button("", "RoundButton", ICON_INFO)
	info.custom_minimum_size = Vector2(56, 56)
	info.pressed.connect(_show_info)
	head.add_child(info)
	var close := UiTheme.button("", "RoundButton", ICON_CROSS)
	close.custom_minimum_size = Vector2(56, 56)
	close.pressed.connect(func(): controller.deselect())
	head.add_child(close)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 22)
	col.add_child(_stats)
	var prog_row := HBoxContainer.new()
	col.add_child(prog_row)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog_row.add_child(_progress)
	_progress_label = UiTheme.label("", "HudLabel", 22)
	prog_row.add_child(_progress_label)
	_workers_row = HBoxContainer.new()
	_workers_row.add_theme_constant_override("separation", 10)
	col.add_child(_workers_row)
	_workers_row.add_child(UiTheme.icon_rect(preload("res://assets/icons/ui/population.svg"), 30))
	_workers_label = UiTheme.label("", "HudLabel", 22)
	_workers_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workers_row.add_child(_workers_label)
	_workers_minus = UiTheme.button("−", "RoundButton", null, 26)
	_workers_minus.custom_minimum_size = Vector2(52, 48)
	_workers_minus.pressed.connect(func(): controller.change_workers(uid, -1))
	_workers_row.add_child(_workers_minus)
	_workers_plus = UiTheme.button("+", "RoundButton", null, 26)
	_workers_plus.custom_minimum_size = Vector2(52, 48)
	_workers_plus.pressed.connect(func(): controller.change_workers(uid, 1))
	_workers_row.add_child(_workers_plus)
	_actions = HBoxContainer.new()
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions.add_theme_constant_override("separation", 12)
	col.add_child(_actions)


func show_building(p_uid: int) -> void:
	uid = p_uid
	_signature = ""
	visible = true
	refresh()
	UiSfx.pop_in(self, 0.2)


func refresh() -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		visible = false
		return
	var d := b.data()
	var now := GameClock.now()
	_title.text = d.display_name
	_subtitle.text = "Niveau %d  •  %s" % [b.level, d.category_name()] if b.level > 0 else "En construction"
	var sig := "%d|%d" % [b.level, b.task]
	if sig != _signature:
		_signature = sig
		_rebuild_stats(d, b)
		_rebuild_actions(b)
	var busy := b.is_busy()
	_progress.get_parent().visible = busy
	if busy:
		_progress.value = b.task_progress(now) * 100.0
		_progress_label.text = "  " + Fmt.duration(b.task_remaining(now))
		if _speed_btn:
			var cost := GameState.city.speedup_cost(b, now, GameState.config())
			_speed_btn.text = "Gratuit" if cost == 0 else str(cost)
	var slots := b.worker_slots()
	_workers_row.visible = slots > 0
	if slots > 0:
		_workers_label.text = "Ouvriers %d / %d   •   Efficacité %d %%" % [b.workers, slots, roundi(b.efficiency() * 100)]
		_workers_label.add_theme_color_override("font_color", UiTheme.TEXT if b.workers >= slots else UiTheme.GOLD)
		_workers_minus.disabled = b.workers <= 0
		_workers_plus.disabled = b.workers >= slots
	if _collect_btn:
		var stored := int(b.stored_production(now))
		_collect_btn.text = "Collecter  %s" % Fmt.amount(stored)
		_collect_btn.disabled = stored < 1


func _rebuild_stats(d: BuildingData, b: BuildingState) -> void:
	for c in _stats.get_children():
		c.queue_free()
	for line in BuildingStats.lines(d, b.level):
		var cell := HBoxContainer.new()
		cell.add_child(UiTheme.icon_rect(line[2], 28))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -6)
		v.add_child(UiTheme.label(line[0], "DimLabel", 16))
		v.add_child(UiTheme.label(line[1], "HudLabel", 22))
		cell.add_child(v)
		_stats.add_child(cell)
	if _stats.get_child_count() == 0:
		_stats.add_child(UiTheme.label(_short_desc(d), "DimLabel", 18))


func _rebuild_actions(b: BuildingState) -> void:
	for c in _actions.get_children():
		c.queue_free()
	_collect_btn = null
	_speed_btn = null
	var d := b.data()
	if not d.produces.is_empty() and b.level >= 1:
		_collect_btn = _action("Collecter", "SuccessButton", ICON_COLLECT, func(): controller.collect(uid))
	if b.is_busy():
		_speed_btn = _action("", "PremiumButton", DataRegistry.resource_type(GameState.config().premium_resource).icon, func(): controller.speed_up(uid))
		_action("Annuler", "DangerButton", ICON_CROSS, func(): controller.confirm_cancel_task(uid))
	else:
		_action("Améliorer", "PrimaryButton", ICON_UPGRADE, func(): controller.open_upgrade(uid))
	_action("Déplacer", "SecondaryButton", ICON_MOVE, func(): controller.start_move(uid))
	if b.level >= 1 and controller.has_screen(b.data_id):
		_action("Ouvrir", "PremiumButton", preload("res://assets/icons/ui/collection.svg"), func(): controller.open_building_screen(uid))


func _action(text: String, variation: String, icon: Texture2D, cb: Callable) -> Button:
	var btn := UiTheme.button(text, variation, icon, 22)
	btn.custom_minimum_size = Vector2(0, 60)
	btn.pressed.connect(cb)
	_actions.add_child(btn)
	return btn


func _short_desc(d: BuildingData) -> String:
	var s := d.description
	return s if s.length() < 90 else s.substr(0, 87) + "…"


func _show_info() -> void:
	var b := GameState.city.get_building(uid)
	if b == null:
		return
	var d := b.data()
	var body := VBoxContainer.new()
	var desc := RichTextLabel.new()
	desc.fit_content = true
	desc.text = d.description
	desc.add_theme_font_size_override("normal_font_size", 22)
	body.add_child(desc)
	var tl := GameState.city.temple_level()
	var cap := d.max_level if d.id == CityState.TEMPLE_ID else d.level_cap(tl)
	body.add_child(UiTheme.label("Niveau %d / %d  (max. actuel avec le Temple : %d)" % [b.level, d.max_level, cap], "DimLabel", 18))
	body.add_child(UiTheme.label("Emprise : %d × %d cases" % [d.footprint.x, d.footprint.y], "DimLabel", 18))
	DialogBox.open(controller.dialog_parent(), d.display_name, body, [], 700)
