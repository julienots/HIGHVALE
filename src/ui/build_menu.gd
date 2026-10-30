class_name BuildMenu
extends Control
## Menu de construction : catégories, cartes avec vignette 3D, coût, durée,
## limites et raisons de verrouillage.

signal build_requested(data: BuildingData)

const ICON_LOCK := preload("res://assets/icons/ui/lock.svg")
const ICON_CLOCK := preload("res://assets/icons/ui/clock.svg")
const ICON_CROSS := preload("res://assets/icons/ui/cross.svg")
const ICON_TEMPLE := preload("res://assets/icons/ui/temple.svg")

var _grid: GridContainer
var _tabs: HBoxContainer
var _category := -1
var _thumbs: ThumbnailRenderer
var _thumb_rects := {}  # id -> TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := UiTheme.label("Construire", "TitleLabel", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UiTheme.button("", "DangerButton", ICON_CROSS)
	close.custom_minimum_size = Vector2(64, 64)
	close.pressed.connect(hide_menu)
	head.add_child(close)
	var tab_scroll := ScrollContainer.new()
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.custom_minimum_size = Vector2(0, 72)
	col.add_child(tab_scroll)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	tab_scroll.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	_thumbs = ThumbnailRenderer.new()
	add_child(_thumbs)
	_thumbs.thumbnail_ready.connect(_on_thumbnail)
	resized.connect(_update_columns)
	visible = false


func show_menu() -> void:
	visible = true
	_build_tabs()
	_populate()
	_update_columns()
	UiSfx.pop_in(get_child(1), 0.22)


func hide_menu() -> void:
	visible = false


func _update_columns() -> void:
	if _grid:
		_grid.columns = clampi(int((size.x - 100) / 230), 2, 7)


func _build_tabs() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	var cats := [-1]
	for d in DataRegistry.all_buildings():
		if not d.category in cats:
			cats.append(d.category)
	for cat in cats:
		var cat_name: String = "Tout" if cat < 0 else BuildingData.CATEGORY_NAMES[cat]
		var b := UiTheme.button(cat_name, "TabButton", null, 20)
		b.toggle_mode = true
		b.button_pressed = cat == _category
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func():
			_category = cat
			for t in _tabs.get_children():
				t.button_pressed = t == b
			_populate())
		_tabs.add_child(b)


func _populate() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_thumb_rects.clear()
	var list := DataRegistry.all_buildings()
	# Disponibles d'abord, puis verrouillés.
	var city := GameState.city
	list.sort_custom(func(a, b):
		var la := _lock_rank(a, city)
		var lb := _lock_rank(b, city)
		return a.sort_order < b.sort_order if la == lb else la < lb)
	for d in list:
		if _category >= 0 and d.category != _category:
			continue
		_grid.add_child(_card(d))


func _lock_rank(d: BuildingData, city: CityState) -> int:
	if not d.is_available():
		return 3
	if city.temple_level() < d.unlock_temple_level:
		return 2
	if city.count_of(d.id) >= d.max_count(city.temple_level()):
		return 1
	return 0


func _card(d: BuildingData) -> Control:
	var city := GameState.city
	var wallet := GameState.wallet
	var reason := city.can_build_reason(d, wallet)
	var hard_locked := not d.is_available() or city.temple_level() < d.unlock_temple_level
	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	card.custom_minimum_size = Vector2(212, 300)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var title := UiTheme.label(d.display_name, "HeaderLabel", 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(190, 0)
	col.add_child(title)
	var thumb_holder := Control.new()
	thumb_holder.custom_minimum_size = Vector2(150, 140)
	thumb_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(thumb_holder)
	var thumb := TextureRect.new()
	thumb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = ThumbnailRenderer.cached(d.id)
	if thumb.texture == null:
		thumb.texture = ICON_TEMPLE if d.id == CityState.TEMPLE_ID else null
		_thumbs.request(d)
	_thumb_rects[d.id] = thumb
	thumb_holder.add_child(thumb)
	if hard_locked:
		thumb.modulate = Color(0.3, 0.3, 0.4)
		var lock := UiTheme.icon_rect(ICON_LOCK, 56)
		thumb_holder.add_child(lock)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var tl := city.temple_level()
	if hard_locked:
		var why := UiTheme.label(reason, "DimLabel", 16)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		why.custom_minimum_size = Vector2(190, 0)
		col.add_child(why)
	else:
		var count := UiTheme.label("Construits : %d / %d" % [city.count_of(d.id), d.max_count(tl)], "DimLabel", 16)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(count)
		var cost := UiTheme.cost_row(d.cost_for_level(1), wallet, 18)
		cost.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(cost)
		var time_row := HBoxContainer.new()
		time_row.alignment = BoxContainer.ALIGNMENT_CENTER
		time_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		time_row.add_child(UiTheme.icon_rect(ICON_CLOCK, 20))
		time_row.add_child(UiTheme.label(Fmt.duration(d.build_seconds_for_level(1)), "DimLabel", 16))
		col.add_child(time_row)
		if reason != "":
			card.modulate = Color(0.75, 0.75, 0.8)
	# Un glissé (défilement de la liste) ne doit pas déclencher la construction.
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				card.set_meta("press_pos", e.global_position)
			elif e.global_position.distance_to(card.get_meta("press_pos", e.global_position)) < 14.0:
				_on_card_pressed(d, card))
	return card


func _on_card_pressed(d: BuildingData, card: Control) -> void:
	UiSfx.click(card)
	var reason := GameState.city.can_build_reason(d, GameState.wallet)
	if reason != "":
		Events.toast_requested.emit(reason, "error")
		return
	hide_menu()
	build_requested.emit(d)


func _on_thumbnail(id: String, tex: Texture2D) -> void:
	var rect: TextureRect = _thumb_rects.get(id)
	if is_instance_valid(rect):
		rect.texture = tex
