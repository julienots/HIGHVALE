class_name ShopScreen
extends ModalScreen
## Boutique HIGHVALE : offres du jour, ressources et coffres (monnaies du jeu).

var _tab := 0
var _tabs: HBoxContainer
var _grid: GridContainer


func _ready() -> void:
	_build_shell("Boutique")
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	header.add_child(_tabs)
	header.move_child(_tabs, 1)
	for i in 3:
		var b := UiTheme.button(["Offres du jour", "Ressources", "Coffres"][i], "TabButton", null, 20)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func():
			_tab = i
			refresh())
		_tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	Events.inventory_changed.connect(func():
		if visible:
			refresh())


func refresh() -> void:
	var shop := GameState.shop
	shop.roll(GameClock.now())
	for i in _tabs.get_child_count():
		_tabs.get_child(i).button_pressed = i == _tab
	clear(_grid)
	match _tab:
		0:
			for o in shop.daily_offers():
				var sold: bool = o.id in shop.bought
				_offer(o.icon, o.name, o.rarity, o.price, "Acheté" if sold else "Acheter", sold, func():
					_result(shop.buy_daily(o, GameState.wallet, GameState.inventory, GameState.collection), o.name))
		1:
			for id in ShopState.PERMANENT:
				var p: Array = ShopState.PERMANENT[id]
				var rid: String = p[2].keys()[0]
				_offer(DataRegistry.resource_type(rid).icon, "%s (+%s)" % [p[0], Fmt.amount(p[2][rid])], 0, p[1], "Acheter", false, func():
					_result(shop.buy_permanent(id, GameState.wallet), p[0]))
		2:
			for id in ShopState.CHESTS:
				var c: Array = ShopState.CHESTS[id]
				_offer(preload("res://assets/icons/ui/collect.svg"), "%s\n%s" % [c[0], c[2]], 2 if id == "hero_chest" else 1, c[1], "Ouvrir", false, func():
					var rng := RandomNumberGenerator.new()
					rng.randomize()
					var got := shop.open_chest(id, GameState.wallet, GameState.inventory, GameState.collection, rng)
					if got.has("error"):
						Events.toast_requested.emit(got.error, "error")
						return
					GameState.save()
					var lines := []
					for k in got:
						lines.append("%s ×%d" % [k, got[k]])
					DialogBox.open(get_parent(), c[0], "\n".join(lines)))


func _offer(icon: Texture2D, text: String, rarity: int, price: Dictionary, action: String, disabled: bool, cb: Callable) -> void:
	var card := PanelContainer.new()
	var sb := UiTheme.box(GameEnums.rarity_color(rarity).darkened(0.6), GameEnums.rarity_color(rarity), 16, 3, 5)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(360, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	row.add_child(UiTheme.icon_rect(icon, 84))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var l := UiTheme.label(text, "HeaderLabel", 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	v.add_child(UiTheme.cost_row(price, GameState.wallet, 18))
	var b := UiTheme.button(action, "PrimaryButton", null, 18)
	b.disabled = disabled or not GameState.wallet.can_afford(price)
	b.pressed.connect(cb)
	v.add_child(b)
	_grid.add_child(card)


func _result(reason: String, what: String) -> void:
	Events.toast_requested.emit(reason if reason != "" else "%s : acheté !" % what, "error" if reason != "" else "success")
	if reason == "":
		GameState.save()
