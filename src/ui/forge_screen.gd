class_name ForgeScreen
extends ModalScreen
## Forge : fabrication des armes, armures et amulettes.

var _grid: GridContainer


func _ready() -> void:
	_build_shell("Forge")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)
	Events.inventory_changed.connect(func():
		if visible:
			refresh())


func refresh() -> void:
	clear(_grid)
	title_label.text = "Forge (niveau %d)" % ForgeRules.forge_level(GameState.city)
	for item in DataRegistry.all_items():
		var card := PanelContainer.new()
		var sb := UiTheme.box(GameEnums.rarity_color(item.rarity).darkened(0.6), GameEnums.rarity_color(item.rarity), 14, 3, 4)
		card.add_theme_stylebox_override("panel", sb)
		card.custom_minimum_size = Vector2(270, 0)
		var v := VBoxContainer.new()
		card.add_child(v)
		var head := HBoxContainer.new()
		v.add_child(head)
		head.add_child(UiTheme.icon_rect(item.icon, 56))
		var t := VBoxContainer.new()
		t.add_child(UiTheme.label(item.display_name, "HeaderLabel", 19))
		t.add_child(UiTheme.label("%s • %s • possédés : %d" % [ItemData.SLOT_NAMES.get(item.slot, ""), GameEnums.rarity_name(item.rarity), GameState.inventory.count(item.id)], "DimLabel", 14))
		head.add_child(t)
		var d := UiTheme.label(item.description, "HudLabel", 16, UiTheme.GREEN)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		v.add_child(UiTheme.cost_row(item.craft_cost, GameState.wallet, 15))
		var reason := ForgeRules.craft_reason(item, GameState.city, GameState.wallet)
		var b := UiTheme.button("Forger", "PrimaryButton", null, 18)
		b.disabled = reason != ""
		b.pressed.connect(func():
			var r := ForgeRules.craft(item, GameState.city, GameState.wallet, GameState.inventory)
			Events.toast_requested.emit(r if r != "" else "%s forgé !" % item.display_name, "error" if r != "" else "success")
			GameState.save())
		v.add_child(b)
		if reason != "" and reason != "Ressources insuffisantes":
			v.add_child(UiTheme.label(reason, "DimLabel", 14))
		_grid.add_child(card)
