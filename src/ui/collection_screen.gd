class_name CollectionScreen
extends Control
## Collection des héros et des créatures : cartes par rareté, filtres et
## fiche détaillée avec vitrine 3D, statistiques, compétences et progression.

const ELEMENT_ICONS := ["neutral", "fire", "water", "earth", "air", "nature", "crystal", "light", "shadow", "void"]
const SKILL_KINDS := ["Attaque", "Spéciale", "Ultime", "Passive"]
const SKILL_KIND_COLORS := [Color("6a7aa8"), Color("3d9bff"), Color("ff7a2f"), Color("4fa86a")]
const TARGETS := ["un ennemi", "tous les ennemis", "une rangée", "soi-même", "un allié", "toute l'équipe", "ennemis au hasard"]
const ICON_STAR := preload("res://assets/icons/ui/star.svg")
const ICON_STAR_EMPTY := preload("res://assets/icons/ui/star_empty.svg")
const ICON_FRAGMENT := preload("res://assets/icons/ui/fragment.svg")
const ICON_CROSS := preload("res://assets/icons/ui/cross.svg")

var _tab := 0  # 0 héros, 1 créatures
var _rarity := -1
var _grid: GridContainer
var _tabs: HBoxContainer
var _rarity_tabs: HBoxContainer
var _counter: Label
var _detail: Control
var _detail_body: HBoxContainer
var _viewer: CharacterViewer
var _detail_info: VBoxContainer
var _detail_key := ""  # "h:<id>" ou "m:<uid>" ou "s:<id>"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(UiTheme.label("Collection", "TitleLabel", 40))
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	head.add_child(_tabs)
	for i in 2:
		var b := UiTheme.button(["Héros", "Créatures"][i], "TabButton", null, 22)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func():
			_tab = i
			_refresh())
		_tabs.add_child(b)
	_counter = UiTheme.label("", "DimLabel", 20)
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_counter)
	var close := UiTheme.button("", "DangerButton", ICON_CROSS)
	close.custom_minimum_size = Vector2(64, 64)
	close.pressed.connect(func(): visible = false)
	head.add_child(close)
	_rarity_tabs = HBoxContainer.new()
	_rarity_tabs.add_theme_constant_override("separation", 8)
	col.add_child(_rarity_tabs)
	for r in range(-1, 4):
		var b := UiTheme.button("Toutes" if r < 0 else GameEnums.rarity_name(r), "TabButton", null, 18)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 46)
		if r >= 0:
			b.add_theme_color_override("font_color", GameEnums.rarity_color(r).lightened(0.3))
		b.pressed.connect(func():
			_rarity = r
			_refresh())
		_rarity_tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	resized.connect(func(): _grid.columns = clampi(int((size.x - 90) / 200), 2, 8))
	_build_detail()
	Events.collection_changed.connect(func():
		if visible:
			_refresh())


func show_screen(tab := -1) -> void:
	if tab >= 0:
		_tab = tab
	visible = true
	_detail.visible = false
	_grid.columns = clampi(int((size.x - 90) / 200), 2, 8)
	_refresh()


## Retour Android : ferme la fiche, puis l'écran.
func back() -> void:
	if _detail.visible:
		_detail.visible = false
	else:
		visible = false


# --- Grille -----------------------------------------------------------------

func _refresh() -> void:
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	for i in _rarity_tabs.get_child_count():
		_rarity_tabs.get_child(i).button_pressed = (i - 1) == _rarity
	for c in _grid.get_children():
		c.queue_free()
	var coll := GameState.collection
	if _tab == 0:
		var list := DataRegistry.all_heroes()
		list.sort_custom(func(a, b):
			var oa := coll.owns_hero(a.id)
			var ob := coll.owns_hero(b.id)
			return (a.rarity > b.rarity if a.rarity != b.rarity else a.display_name < b.display_name) if oa == ob else oa)
		var owned := 0
		for h in list:
			owned += 1 if coll.owns_hero(h.id) else 0
			if _rarity < 0 or h.rarity == _rarity:
				_grid.add_child(_hero_card(h))
		_counter.text = "%d / %d héros" % [owned, list.size()]
	else:
		var uids: Array = coll.monsters.keys()
		uids.sort_custom(func(a, b):
			var da := DataRegistry.monster(coll.monsters[a].id)
			var db := DataRegistry.monster(coll.monsters[b].id)
			return da.rarity > db.rarity if da.rarity != db.rarity else coll.monsters[a].level > coll.monsters[b].level)
		for uid in uids:
			var d := DataRegistry.monster(coll.monsters[uid].id)
			if _rarity < 0 or d.rarity == _rarity:
				_grid.add_child(_monster_card(uid))
		var species := 0
		for m in DataRegistry.all_monsters():
			if coll.owns_monster_species(m.id):
				species += 1
			elif _rarity < 0 or m.rarity == _rarity:
				_grid.add_child(_species_card(m))
		_counter.text = "%d créatures (%d / %d) • %d espèces découvertes" % [coll.monsters.size(), coll.monsters.size(),
			coll.monster_capacity(GameState.city), species]


func _card_frame(rarity: int, owned: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var rc := GameEnums.rarity_color(rarity)
	sb.bg_color = rc.darkened(0.6) if owned else Color("1a1f33")
	sb.border_color = rc if owned else rc.darkened(0.5)
	sb.set_border_width_all(5)
	sb.border_width_bottom = 9
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 5
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(186, 268)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card


func _card_body(card: PanelContainer, portrait: Texture2D, element: int, rarity: int, title: String, subtitle: String, owned: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	top.add_child(UiTheme.icon_rect(load("res://assets/icons/elements/%s.svg" % ELEMENT_ICONS[element]), 30))
	var rl := UiTheme.label(GameEnums.rarity_name(rarity), "HudLabel", 16, GameEnums.rarity_color(rarity).lightened(0.35))
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(rl)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(160, 150)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)
	var glow := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, GameEnums.rarity_color(rarity).lightened(0.1) * Color(1, 1, 1, 0.55 if owned else 0.15))
	grad.gradient.set_color(1, Color(0, 0, 0, 0))
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.55)
	grad.fill_to = Vector2(0.5, 0.05)
	glow.texture = grad
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(glow)
	var pic := TextureRect.new()
	pic.texture = portrait
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not owned:
		pic.modulate = Color(0.08, 0.08, 0.14, 0.95)
	holder.add_child(pic)
	var title_label := UiTheme.label(title, "HeaderLabel", 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	title_label.custom_minimum_size = Vector2(160, 0)
	col.add_child(title_label)
	var sub := UiTheme.label(subtitle, "DimLabel", 15)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	return col


func _stars_row(count: int, total: int, size := 18) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in total:
		row.add_child(UiTheme.icon_rect(ICON_STAR if i < count else ICON_STAR_EMPTY, size))
	return row


func _hero_card(h: HeroData) -> Control:
	var coll := GameState.collection
	var owned := coll.owns_hero(h.id)
	var card := _card_frame(h.rarity, owned)
	var col := _card_body(card, h.portrait, h.element, h.rarity, h.display_name,
		GameEnums.HERO_CLASS_NAMES[h.hero_class] + ("  •  Niv. %d" % coll.hero_level(h.id) if owned else ""), owned)
	if owned:
		col.add_child(_stars_row(coll.hero_stars(h.id), CollectionState.MAX_STARS))
	else:
		col.add_child(_fragment_bar(int(coll.fragments.get(h.id, 0)), h.fragments_to_unlock))
	_clickable(card, "h:" + h.id)
	return card


func _monster_card(uid: int) -> Control:
	var m: Dictionary = GameState.collection.monsters[uid]
	var d := DataRegistry.monster(m.id)
	var card := _card_frame(d.rarity, true)
	var variant: String = m.get("variant", "")
	var col := _card_body(card, d.portrait, d.element, d.rarity, d.display_name,
		("Variante " + FusionRules.VARIANT_NAMES[variant]) if variant != "" else "%s  •  Niv. %d" % [GameEnums.MONSTER_CATEGORY_NAMES[d.category], m.level], true)
	if variant != "":
		col.get_child(1).get_child(1).modulate = FusionRules.VARIANT_COLORS[variant].lightened(0.3)
	col.add_child(UiTheme.label("Puissance %d" % GameState.collection.monster_power(uid), "HudLabel", 16, UiTheme.GOLD))
	_clickable(card, "m:%d" % uid)
	return card


func _species_card(d: MonsterData) -> Control:
	var card := _card_frame(d.rarity, false)
	var col := _card_body(card, d.portrait, d.element, d.rarity, "???", GameEnums.MONSTER_CATEGORY_NAMES[d.category], false)
	col.add_child(UiTheme.label("Non découverte", "DimLabel", 15))
	_clickable(card, "s:" + d.id)
	return card


func _fragment_bar(have: int, need: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiTheme.icon_rect(ICON_FRAGMENT, 22))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = need
	bar.value = have
	bar.custom_minimum_size = Vector2(90, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := UiTheme.box(Color("b464ff"), Color(0, 0, 0, 0), 6, 0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	row.add_child(UiTheme.label("%d/%d" % [have, need], "HudLabel", 15))
	return row


func _clickable(card: Control, key: String) -> void:
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				card.set_meta("press", e.global_position)
			elif e.global_position.distance_to(card.get_meta("press", e.global_position)) < 14.0:
				UiSfx.click(card)
				open_detail(key))


# --- Fiche détaillée ----------------------------------------------------------

func _build_detail() -> void:
	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail.visible = false
	add_child(_detail)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	_detail.add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	_detail_body = HBoxContainer.new()
	_detail_body.add_theme_constant_override("separation", 18)
	panel.add_child(_detail_body)
	_viewer = CharacterViewer.new()
	_viewer.custom_minimum_size = Vector2(380, 0)
	_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_body.add_child(_viewer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_body.add_child(scroll)
	_detail_info = VBoxContainer.new()
	_detail_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_info.add_theme_constant_override("separation", 10)
	scroll.add_child(_detail_info)


func open_detail(key: String) -> void:
	_detail_key = key
	_detail.visible = true
	var parts := key.split(":")
	match parts[0]:
		"h":
			var h := DataRegistry.hero(parts[1])
			_viewer.show_character(h.model_scene, GameEnums.rarity_color(h.rarity))
			_viewer.modulate = Color.WHITE if GameState.collection.owns_hero(h.id) else Color(0.25, 0.25, 0.35)
		"m":
			var d := DataRegistry.monster(GameState.collection.monsters[int(parts[1])].id)
			_viewer.show_character(d.model_scene, GameEnums.rarity_color(d.rarity))
			_viewer.modulate = Color.WHITE
		"s":
			var d := DataRegistry.monster(parts[1])
			_viewer.show_character(d.model_scene, GameEnums.rarity_color(d.rarity))
			_viewer.modulate = Color(0.05, 0.05, 0.1)
	_fill_detail()
	UiSfx.pop_in(_detail.get_child(1), 0.22)


func _fill_detail() -> void:
	for c in _detail_info.get_children():
		c.queue_free()
	var parts := _detail_key.split(":")
	var coll := GameState.collection
	var head := HBoxContainer.new()
	_detail_info.add_child(head)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	var close := UiTheme.button("", "DangerButton", ICON_CROSS)
	close.custom_minimum_size = Vector2(60, 60)
	close.pressed.connect(func(): _detail.visible = false)
	head.add_child(close)
	if parts[0] == "s":
		var d := DataRegistry.monster(parts[1])
		titles.add_child(UiTheme.label("Créature non découverte", "TitleLabel", 32))
		titles.add_child(UiTheme.label("%s • %s • %s" % [GameEnums.rarity_name(d.rarity), GameEnums.element_name(d.element), GameEnums.MONSTER_CATEGORY_NAMES[d.category]], "DimLabel", 20))
		_paragraph("Cette espèce n'a pas encore été rencontrée. Les œufs se trouvent parfois dans les champignons sauvages ; le Laboratoire (étape 6) permettra de faire naître toutes les créatures.")
		return
	var is_hero := parts[0] == "h"
	var data: Resource
	var stats := {}
	if is_hero:
		var h := DataRegistry.hero(parts[1])
		data = h
		var owned := coll.owns_hero(h.id)
		titles.add_child(UiTheme.label(h.display_name, "TitleLabel", 36))
		titles.add_child(UiTheme.label(h.title, "HeaderLabel", 22))
		titles.add_child(UiTheme.label("%s • %s • %s" % [GameEnums.rarity_name(h.rarity), GameEnums.element_name(h.element), GameEnums.HERO_CLASS_NAMES[h.hero_class]], "HudLabel", 20, GameEnums.rarity_color(h.rarity).lightened(0.3)))
		var lvl := maxi(coll.hero_level(h.id), 1)
		var stars: int = coll.hero_stars(h.id) if owned else CollectionState.BASE_STARS[h.rarity]
		stats = CollectionState.effective_stats(h.stats, lvl, stars)
		var prog := HBoxContainer.new()
		prog.add_theme_constant_override("separation", 14)
		_detail_info.add_child(prog)
		if owned:
			prog.add_child(UiTheme.label("Niveau %d / %d" % [lvl, CollectionState.level_cap_for_stars(stars)], "HudLabel", 24))
		prog.add_child(_stars_row(stars, CollectionState.MAX_STARS, 26))
		var frag := _fragment_bar(int(coll.fragments.get(h.id, 0)), coll.star_up_cost(h.id) if owned else h.fragments_to_unlock)
		frag.custom_minimum_size = Vector2(240, 0)
		prog.add_child(frag)
	else:
		var uid := int(parts[1])
		var m: Dictionary = coll.monsters[uid]
		var d := DataRegistry.monster(m.id)
		data = d
		titles.add_child(UiTheme.label(d.display_name, "TitleLabel", 36))
		titles.add_child(UiTheme.label("Famille : " + d.family, "HeaderLabel", 22))
		titles.add_child(UiTheme.label("%s • %s • %s" % [GameEnums.rarity_name(d.rarity), GameEnums.element_name(d.element), GameEnums.MONSTER_CATEGORY_NAMES[d.category]], "HudLabel", 20, GameEnums.rarity_color(d.rarity).lightened(0.3)))
		_detail_info.add_child(UiTheme.label("Niveau %d / %d" % [m.level, d.max_level], "HudLabel", 24))
		stats = CollectionState.effective_stats(d.stats, m.level, 1)
	# Statistiques
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	for row in [["PV", stats.max_hp], ["Attaque", stats.attack], ["Défense", stats.defense],
			["Vitesse", stats.speed], ["Critique", "%d %%" % roundi(stats.crit_chance * 100)], ["Puissance", CollectionState.power(stats)]]:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", -4)
		cell.add_child(UiTheme.label(row[0], "DimLabel", 16))
		cell.add_child(UiTheme.label(str(row[1]), "HudLabel", 24, UiTheme.GOLD if row[0] == "Puissance" else UiTheme.TEXT))
		grid.add_child(cell)
	_detail_info.add_child(grid)
	# Actions
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	_detail_info.add_child(actions)
	if is_hero:
		var id: String = parts[1]
		if coll.owns_hero(id):
			_action(actions, "Améliorer", "SuccessButton", coll.hero_level_cost(id), coll.hero_level_reason(id, GameState.wallet),
				func(): return coll.level_up_hero(id, GameState.wallet))
			var star_btn := UiTheme.button("Évoluer (%d fragments)" % coll.star_up_cost(id), "PremiumButton", ICON_STAR, 20)
			star_btn.disabled = coll.star_up_reason(id) != ""
			star_btn.custom_minimum_size = Vector2(0, 58)
			star_btn.pressed.connect(func(): _do(coll.star_up_hero(id), "Évolution réussie !"))
			actions.add_child(star_btn)
			_gear_and_talents(id)
		else:
			_paragraph("Héros non débloqué : réunissez %d fragments. On en trouve dans les cristaux affleurants de la cité ; le Sanctuaire des héros permettra bientôt de les invoquer (étape 7)." % data.fragments_to_unlock)
	else:
		var uid := int(parts[1])
		_action(actions, "Nourrir", "SuccessButton", coll.monster_level_cost(uid), coll.monster_level_reason(uid, GameState.wallet),
			func(): return coll.feed_monster(uid, GameState.wallet))
		var release := UiTheme.button("Libérer", "DangerButton", null, 20)
		release.custom_minimum_size = Vector2(0, 58)
		release.disabled = coll.monsters.size() <= 1
		release.pressed.connect(func():
			DialogBox.open(get_parent(), "Libérer la créature ?", "Elle retournera dans les profondeurs et libérera une place.", [
				{"text": "Garder", "variation": "SecondaryButton"},
				{"text": "Libérer", "variation": "DangerButton", "action": func():
					coll.release_monster(uid)
					GameState.save()
					_detail.visible = false}]))
		actions.add_child(release)
	# Compétences
	_detail_info.add_child(UiTheme.label("Compétences", "HeaderLabel", 24))
	for s: SkillData in data.skills:
		var box := PanelContainer.new()
		box.theme_type_variation = "CardPanel"
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		box.add_child(row)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		row.add_child(top)
		var tag := PanelContainer.new()
		var tsb := UiTheme.box(SKILL_KIND_COLORS[s.kind], UiTheme.INK, 8, 2)
		tsb.set_content_margin_all(4)
		tsb.content_margin_left = 10
		tsb.content_margin_right = 10
		tag.add_theme_stylebox_override("panel", tsb)
		tag.add_child(UiTheme.label(SKILL_KINDS[s.kind], "HudLabel", 15))
		top.add_child(tag)
		top.add_child(UiTheme.icon_rect(load("res://assets/icons/elements/%s.svg" % ELEMENT_ICONS[s.element]), 26))
		top.add_child(UiTheme.label(s.display_name, "HeaderLabel", 21))
		var cost := UiTheme.label(("Énergie %d" % s.energy_cost) if s.energy_cost > 0 else "", "DimLabel", 16)
		cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		top.add_child(cost)
		var desc := UiTheme.label("%s  (Cible : %s)" % [s.description, TARGETS[s.target]], "", 18)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		_detail_info.add_child(box)
	_detail_info.add_child(UiTheme.label("Histoire", "HeaderLabel", 24))
	_paragraph(data.lore)


func _gear_and_talents(id: String) -> void:
	var coll := GameState.collection
	_detail_info.add_child(UiTheme.label("Équipement", "HeaderLabel", 24))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_detail_info.add_child(row)
	for slot in CollectionState.EQUIP_SLOTS:
		var item_id: String = coll.gear(id).get(str(slot), "")
		var tile: PanelContainer
		if item_id != "":
			var it := DataRegistry.item(item_id)
			tile = ModalScreen.item_tile(it.icon, it.display_name.split(" ")[0], it.rarity, 86)
			tile.tooltip_text = "%s : %s" % [it.display_name, it.description]
		else:
			tile = ModalScreen.item_tile(preload("res://assets/icons/ui/info.svg"), ItemData.SLOT_NAMES[slot], 0, 86)
			tile.modulate = Color(1, 1, 1, 0.5)
		ModalScreen.on_tap(tile, func(): _choose_gear(id, slot))
		row.add_child(tile)
	var bonus := coll.hero_bonus(id)
	if not bonus.is_empty():
		var parts := []
		for k in bonus:
			parts.append({"atk_pct": "+%d %% ATQ", "hp_pct": "+%d %% PV", "def_pct": "+%d %% DÉF", "speed": "+%d VIT", "crit": "+%d %% CRIT", "energy": "+%d énergie"}[k] % bonus[k])
		_detail_info.add_child(UiTheme.label("Bonus : " + ", ".join(parts), "HudLabel", 17, UiTheme.GREEN))
	_detail_info.add_child(UiTheme.label("Talents", "HeaderLabel", 24))
	var chosen := coll.talents(id)
	for tier in CollectionState.TALENTS.size():
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 10)
		trow.add_child(UiTheme.label("Niv. %d" % CollectionState.TALENT_LEVELS[tier], "HudLabel", 18))
		for choice in ["a", "b"]:
			var t: Dictionary = CollectionState.TALENTS[tier][choice]
			var picked: bool = tier < chosen.size() and chosen[tier] == choice
			var b := UiTheme.button("%s\n%s" % [t.name, t.desc], "SuccessButton" if picked else "SecondaryButton", null, 15)
			b.custom_minimum_size = Vector2(200, 56)
			b.disabled = not picked and coll.talent_reason(id, tier) != ""
			if tier < chosen.size() and not picked:
				b.modulate = Color(1, 1, 1, 0.4)
			b.pressed.connect(func():
				if not picked:
					_do(coll.choose_talent(id, tier, choice), "Talent appris : " + t.name))
			trow.add_child(b)
		_detail_info.add_child(trow)


func _choose_gear(id: String, slot: int) -> void:
	var coll := GameState.collection
	var list := VBoxContainer.new()
	var any := false
	for it in DataRegistry.all_items():
		if it.slot != slot or GameState.inventory.count(it.id) < 1:
			continue
		any = true
		var b := UiTheme.button("%s (%s) — %s" % [it.display_name, GameEnums.rarity_name(it.rarity), it.description], "SecondaryButton", it.icon, 17)
		b.pressed.connect(func():
			for c in get_parent().get_children():
				if c is DialogBox:
					c.close()
			_do(coll.equip(id, it.id, GameState.inventory), it.display_name + " équipé"))
		list.add_child(b)
	if not any:
		list.add_child(UiTheme.label("Aucun objet de ce type. Fabriquez-en à la Forge.", "DimLabel", 18))
	var buttons := [{"text": "Fermer", "variation": "SecondaryButton"}]
	if coll.gear(id).has(str(slot)):
		buttons.push_front({"text": "Retirer", "variation": "DangerButton", "action": func():
			coll.unequip(id, slot, GameState.inventory)
			GameState.save()
			_fill_detail()})
	DialogBox.open(get_parent(), "Choisir : " + ItemData.SLOT_NAMES[slot], list, buttons, 720)


func _action(parent: Control, text: String, variation: String, cost: Dictionary, reason: String, cb: Callable) -> void:
	var box := VBoxContainer.new()
	var b := UiTheme.button(text, variation, preload("res://assets/icons/ui/upgrade.svg"), 22)
	b.custom_minimum_size = Vector2(200, 58)
	b.disabled = reason != ""
	b.pressed.connect(func(): _do(cb.call(), text + " : réussi !"))
	box.add_child(b)
	box.add_child(UiTheme.cost_row(cost, GameState.wallet, 18))
	if reason != "" and reason != "Ressources insuffisantes" and reason != "Nourriture insuffisante":
		box.add_child(UiTheme.label(reason, "DimLabel", 15))
	parent.add_child(box)


func _do(reason: String, success: String) -> void:
	if reason != "":
		Events.toast_requested.emit(reason, "error")
		return
	Events.toast_requested.emit(success, "success")
	if success.begins_with("Améliorer"):
		Events.action_done.emit("hero_level", 1)
	elif success.begins_with("Nourrir"):
		Events.action_done.emit("feed", 1)
	GameState.save()
	_fill_detail()


func _paragraph(text: String) -> void:
	var l := UiTheme.label(text, "", 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_info.add_child(l)


# --- Annonces -------------------------------------------------------------------

func announce_hero(id: String) -> void:
	var h := DataRegistry.hero(id)
	_announce("Nouveau héros !", h.portrait, "%s — %s" % [h.display_name, h.title], h.rarity, 0)


func announce_monster(id: String) -> void:
	var d := DataRegistry.monster(id)
	_announce("Un œuf a éclos !", d.portrait, d.display_name, d.rarity, 1)


func _announce(title: String, portrait: Texture2D, text: String, rarity: int, tab: int) -> void:
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var pic := TextureRect.new()
	pic.texture = portrait
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, 240)
	body.add_child(pic)
	var l := UiTheme.label(text, "HeaderLabel", 26, GameEnums.rarity_color(rarity).lightened(0.3))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(l)
	var r := UiTheme.label(GameEnums.rarity_name(rarity), "HudLabel", 20)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(r)
	DialogBox.open(get_parent(), title, body, [
		{"text": "Voir la collection", "variation": "PrimaryButton", "action": func(): show_screen(tab)},
		{"text": "Fermer", "variation": "SecondaryButton"}], 560)
