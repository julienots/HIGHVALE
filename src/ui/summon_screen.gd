class_name SummonScreen
extends ModalScreen
## Sanctuaire des héros et Autel divin : bannières, taux affichés, garantie.

var divine := false
var _banner: SummonBannerData
var _list: VBoxContainer
var _detail: VBoxContainer


func _ready() -> void:
	_build_shell("Sanctuaire des héros")
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	body.add_child(main)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(360, 0)
	_list.add_theme_constant_override("separation", 10)
	main.add_child(_list)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	main.add_child(_detail)


func open_for(p_divine: bool) -> void:
	divine = p_divine
	title_label.text = "Autel divin" if divine else "Sanctuaire des héros"
	_banner = null
	open_screen()


func refresh() -> void:
	clear(_list)
	var banners := DataRegistry.banners().filter(func(b): return b.gods_only == divine)
	if _banner == null or not _banner in banners:
		_banner = banners[0]
	for b: SummonBannerData in banners:
		var card := PanelContainer.new()
		var sb := UiTheme.box(b.accent_color.darkened(0.55), b.accent_color if b == _banner else b.accent_color.darkened(0.3), 14, 4 if b == _banner else 2, 4)
		card.add_theme_stylebox_override("panel", sb)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		v.add_child(UiTheme.label(b.display_name, "HeaderLabel", 22))
		v.add_child(UiTheme.cost_row(b.cost, GameState.wallet, 18))
		on_tap(card, func():
			_banner = b
			refresh())
		_list.add_child(card)
	_fill_detail()


func _fill_detail() -> void:
	clear(_detail)
	var b := _banner
	var now := GameClock.now()
	_detail.add_child(UiTheme.label(b.display_name, "TitleLabel", 32, b.accent_color.lightened(0.3)))
	var desc := UiTheme.label(b.description, "", 19)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(desc)
	if b.element == -2:
		var el := SummonRules.element_of_day(now)
		var row := HBoxContainer.new()
		row.add_child(UiTheme.icon_rect(load("res://assets/icons/elements/%s.svg" % CollectionScreen.ELEMENT_ICONS[el]), 32))
		row.add_child(UiTheme.label("Élément du jour : " + GameEnums.element_name(el), "HudLabel", 22))
		_detail.add_child(row)
	# Taux affichés
	_detail.add_child(UiTheme.label("Probabilités", "HeaderLabel", 22))
	var rates := SummonRules.effective_rates(b, now)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 16)
	for r in 5:
		if rates[r] <= 0.0:
			continue
		var cell := VBoxContainer.new()
		cell.add_child(UiTheme.label(GameEnums.rarity_name(r), "HudLabel", 17, GameEnums.rarity_color(r).lightened(0.3)))
		cell.add_child(UiTheme.label("%.1f %%" % rates[r], "HudLabel", 24))
		grid.add_child(cell)
	_detail.add_child(grid)
	if b.gods_only:
		_detail.add_child(UiTheme.label("Chaque éveil offre 10 à 20 fragments d'un dieu ; %d %% de chances d'éveil complet." % roundi(SummonRules.GOD_AWAKEN_CHANCE * 100), "DimLabel", 17))
	elif b.pity_epic > 0:
		var left := b.pity_epic - int(GameState.collection.pity.get(b.id, 0))
		_detail.add_child(UiTheme.label("Épique ou mieux garanti dans %d invocation(s)." % left, "HudLabel", 19, UiTheme.GOLD))
	_detail.add_child(UiTheme.label("Les héros déjà possédés sont convertis en fragments d'évolution.", "DimLabel", 16))
	# Héros possibles
	var pool_row := HBoxContainer.new()
	pool_row.add_theme_constant_override("separation", 6)
	for r in range(4, -1, -1):
		for h in SummonRules.pool(b, r, now):
			var t := item_tile(h.portrait, "", h.rarity, 64)
			if not GameState.collection.owns_hero(h.id):
				t.get_child(0).get_child(0).modulate = Color(0.1, 0.1, 0.16)
			pool_row.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 100)
	scroll.add_child(pool_row)
	_detail.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var go := UiTheme.button("Éveiller" if b.gods_only else "Invoquer", "PremiumButton", preload("res://assets/icons/ui/star.svg"), 26)
	go.custom_minimum_size = Vector2(240, 72)
	go.disabled = not GameState.wallet.can_afford(b.cost)
	go.pressed.connect(_summon)
	row.add_child(go)
	row.add_child(UiTheme.cost_row(b.cost, GameState.wallet, 22))
	_detail.add_child(row)


func _summon() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var r := SummonRules.summon(_banner, GameState.collection, GameState.wallet, rng, GameClock.now())
	if r.has("error"):
		Events.toast_requested.emit(r.error, "error")
		return
	GameState.save()
	var h := DataRegistry.hero(r.hero)
	var lines := ["%s • %s" % [GameEnums.HERO_CLASS_NAMES[h.hero_class], GameEnums.element_name(h.element)]]
	if r.has("fragments"):
		lines.append("+%d fragments de %s" % [r.fragments, h.display_name])
	var title := "Un dieu s'éveille !" if h.is_god and r.get("new", false) else ("Nouveau héros !" if r.get("new", false) else h.title)
	RevealOverlay.play(self, h.model_scene, h.rarity, title, h.display_name, lines, _banner.accent_color)
	refresh()
