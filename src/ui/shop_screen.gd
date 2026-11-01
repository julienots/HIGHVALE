class_name ShopScreen
extends ModalScreen
## Boutique HIGHVALE : à la une (cadeau gratuit, pack du Fondateur, packs de la
## semaine), offres du jour, coffres, ressources et prismes.

const TABS := ["À la une", "Offres du jour", "Coffres", "Ressources", "Prismes"]
const ICON_GIFT := preload("res://assets/icons/ui/gift.svg")
const ICON_STAR := preload("res://assets/icons/ui/star.svg")

var _tab := 0
var _tabs: HBoxContainer
var _content: VBoxContainer
## Libellés à rafraîchir chaque seconde : [Label, Callable -> String]
var _timers: Array = []
var _tick := 0.0


func _ready() -> void:
	_build_shell("Boutique")
	music = "music_shop"
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	header.add_child(_tabs)
	header.move_child(_tabs, 1)
	for i in TABS.size():
		var b := UiTheme.button(TABS[i], "TabButton", null, 19)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func():
			_tab = i
			AudioManager.sfx("tab")
			refresh())
		_tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)
	Events.inventory_changed.connect(func():
		if visible:
			refresh())


func _process(delta: float) -> void:
	if not visible:
		return
	_tick += delta
	if _tick < 1.0:
		return
	_tick = 0.0
	for t in _timers:
		if is_instance_valid(t[0]):
			t[0].text = t[1].call()
	if _tab == 0 and GameState.shop.gift_ready(GameClock.now()) and _gift_waiting:
		refresh()


var _gift_waiting := false


func refresh() -> void:
	var shop := GameState.shop
	shop.roll(GameClock.now())
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	clear(_content)
	_timers.clear()
	match _tab:
		0:
			_featured()
		1:
			_section("Renouvelées chaque jour", func(): return "Nouvelles offres dans %s" % Fmt.duration(QuestState.DAY - fmod(GameClock.now(), QuestState.DAY)))
			var grid := _grid(3)
			for o in shop.daily_offers():
				var sold: bool = o.id in shop.bought
				grid.add_child(_card(o.icon, o.name, "", o.rarity, o.price, "Acheté" if sold else "Acheter", sold, func():
					_result(shop.buy_daily(o, GameState.wallet, GameState.inventory, GameState.collection), o.name)))
		2:
			_section("Coffres", Callable())
			var grid := _grid(2)
			for id in ShopState.CHESTS:
				var c: Array = ShopState.CHESTS[id]
				var icon: Texture2D = load(c[3])
				grid.add_child(_card(icon, c[0], c[2], c[4], c[1], "Ouvrir", false, func():
					var rng := RandomNumberGenerator.new()
					rng.randomize()
					var got := shop.open_chest(id, GameState.wallet, GameState.inventory, GameState.collection, rng)
					if got.has("error"):
						Events.toast_requested.emit(got.error, "error")
						return
					GameState.save()
					RewardOverlay.play(get_parent(), icon, c[0], got, c[4]), 130))
		3:
			_section("Ressources", Callable())
			var grid := _grid(3)
			for id in ShopState.PERMANENT:
				var p: Array = ShopState.PERMANENT[id]
				var rid: String = p[2].keys()[0]
				grid.add_child(_card(DataRegistry.resource_type(rid).icon, p[0], "+%s %s" % [Fmt.amount(p[2][rid]), DataRegistry.resource_type(rid).display_name.to_lower()],
					0, p[1], "Acheter", false, func():
					_result(shop.buy_permanent(id, GameState.wallet), p[0])))
		4:
			_prisms()


# --- À la une -------------------------------------------------------------------------

func _featured() -> void:
	var shop := GameState.shop
	var now := GameClock.now()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	_content.add_child(top)
	# Cadeau gratuit
	var ready := shop.gift_ready(now)
	_gift_waiting = not ready
	var gift := _card(ICON_GIFT, "Cadeau gratuit", "Or, prismes et parfois un ingrédient. Revient toutes les 4 heures.", 2, {},
		"Récupérer !" if ready else "Bientôt", not ready, func():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var got := shop.claim_gift(GameState.wallet, GameState.inventory, rng, GameClock.now())
		if got.has("error"):
			Events.toast_requested.emit(got.error, "error")
			return
		GameState.save()
		Events.action_done.emit("shop", 1)
		RewardOverlay.play(get_parent(), ICON_GIFT, "Cadeau gratuit", got, 2)
		refresh(), 120)
	gift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not ready:
		var lbl := UiTheme.label("", "HudLabel", 18, UiTheme.GOLD)
		gift.get_child(0).get_child(1).add_child(lbl)
		_timers.append([lbl, func(): return "Prochain cadeau dans %s" % Fmt.duration(GameState.shop.gift_left(GameClock.now()))])
		lbl.text = _timers[-1][1].call()
	else:
		_pulse(gift)
	top.add_child(gift)
	# Pack du Fondateur
	var st: Dictionary = ShopState.STARTER
	var hero := DataRegistry.hero(st.hero)
	var desc := "%s, %d fragments de %s (Épique). Une seule fois !" % [_list_text(st.resources), st.fragments, hero.display_name]
	var starter := _card(hero.portrait, st.name, desc, 3, st.price, "Acheté" if shop.starter_bought else "Acheter", shop.starter_bought, func():
		var r := shop.buy_starter(GameState.wallet, GameState.collection)
		if r != "":
			Events.toast_requested.emit(r, "error")
			return
		GameState.save()
		AudioManager.sfx("purchase", 0.0)
		var got := {}
		for k in st.resources:
			got[DataRegistry.resource_type(k).display_name] = st.resources[k]
		got["Fragments de " + hero.display_name] = st.fragments
		RewardOverlay.play(get_parent(), ICON_STAR, st.name, got, 3)
		refresh(), 120)
	starter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(starter)
	# Packs de la semaine
	_section("Packs de la semaine", func(): return "Se termine dans %s" % Fmt.duration(GameState.shop.week_left(GameClock.now())))
	var grid := _grid(2)
	for o in shop.weekly_offers():
		var sold: bool = o.id in shop.week_bought
		grid.add_child(_card(o.icon, o.name, o.desc, o.rarity, o.price, "Acheté" if sold else "Acheter", sold, func():
			var r := shop.buy_weekly(o, GameState.wallet, GameState.inventory, GameState.collection, GameState.city)
			if r != "":
				Events.toast_requested.emit(r, "error")
				return
			GameState.save()
			AudioManager.sfx("purchase", 0.0)
			if o.has("monster"):
				AudioManager.sfx("hatch", 0.0)
			Events.toast_requested.emit("%s : acheté !" % o.name, "reward")
			refresh(), 110))


func _prisms() -> void:
	_section("Prismes", Callable())
	var note := UiTheme.label("Les achats avec de l'argent réel ne sont pas encore activés dans cette version de test. "
		+ "Gagnez des prismes avec le cadeau gratuit, les missions, le passe saisonnier, les cristaux affleurants et les premières victoires.", "HudLabel", 18)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(note)
	var grid := _grid(3)
	var icon := DataRegistry.resource_type("prisms").icon
	for i in ShopState.PRISM_PACKS.size():
		var p: Array = ShopState.PRISM_PACKS[i]
		var title := "%s prismes" % Fmt.amount(p[0])
		if p[2] != "":
			title += "  (%s)" % p[2]
		var card := _card(icon, title, p[1], mini(i, 3), {}, "Bientôt", true, func(): pass)
		grid.add_child(card)


# --- Composants -------------------------------------------------------------------------

func _section(title: String, timer: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var t := UiTheme.label(title, "HeaderLabel", 26, UiTheme.GOLD)
	row.add_child(t)
	if timer.is_valid():
		var l := UiTheme.label(timer.call(), "HudLabel", 18)
		l.size_flags_vertical = Control.SIZE_SHRINK_END
		row.add_child(l)
		_timers.append([l, timer])
	_content.add_child(row)


func _grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	_content.add_child(g)
	return g


func _card(icon: Texture2D, title: String, desc: String, rarity: int, price: Dictionary, action: String, disabled: bool, cb: Callable, icon_size := 96) -> PanelContainer:
	var card := PanelContainer.new()
	var c := GameEnums.rarity_color(rarity)
	var sb := UiTheme.box(c.darkened(0.62), c, 18, 4, 6)
	sb.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(380, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var ic := UiTheme.icon_rect(icon, icon_size)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	row.add_child(v)
	var l := UiTheme.label(title, "HeaderLabel", 21)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	if desc != "":
		var d := UiTheme.label(desc, "HudLabel", 16)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	v.add_child(bottom)
	if not price.is_empty():
		bottom.add_child(UiTheme.cost_row(price, GameState.wallet, 20))
	var b := UiTheme.button(action, "PremiumButton" if not price.is_empty() and price.has("prisms") else "PrimaryButton", null, 19)
	b.custom_minimum_size = Vector2(150, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	b.disabled = disabled or (not price.is_empty() and not GameState.wallet.can_afford(price))
	b.pressed.connect(cb)
	bottom.add_child(b)
	return card


func _pulse(c: Control) -> void:
	var t := c.create_tween().set_loops()
	t.tween_property(c, "modulate", Color(1.15, 1.1, 0.9), 0.6)
	t.tween_property(c, "modulate", Color.WHITE, 0.6)


func _list_text(res: Dictionary) -> String:
	var parts := []
	for k in res:
		parts.append("%s %s" % [Fmt.amount(res[k]), DataRegistry.resource_type(k).display_name.to_lower()])
	return ", ".join(parts)


func _result(reason: String, what: String) -> void:
	Events.toast_requested.emit(reason if reason != "" else "%s : acheté !" % what, "error" if reason != "" else "success")
	if reason == "":
		AudioManager.sfx("purchase", 0.0)
		Events.action_done.emit("shop", 1)
		GameState.save()
