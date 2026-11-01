class_name FusionScreen
extends ModalScreen
## Fusionnerie : choisir deux créatures, voir la recette, fusionner.

var _picked: Array = []
var _parents: HBoxContainer
var _info: VBoxContainer
var _list: GridContainer


func _ready() -> void:
	_build_shell("Fusionnerie")
	music = "music_mystic"
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	body.add_child(main)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(440, 0)
	left.add_theme_constant_override("separation", 10)
	main.add_child(left)
	_parents = HBoxContainer.new()
	_parents.alignment = BoxContainer.ALIGNMENT_CENTER
	_parents.add_theme_constant_override("separation", 14)
	left.add_child(_parents)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 8)
	left.add_child(_info)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	_list = GridContainer.new()
	_list.columns = 5
	_list.add_theme_constant_override("h_separation", 10)
	_list.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_list)


func refresh() -> void:
	var coll := GameState.collection
	_picked = _picked.filter(func(u): return coll.monsters.has(u))
	clear(_parents)
	for i in 2:
		if i < _picked.size():
			var m: Dictionary = coll.monsters[_picked[i]]
			var d := DataRegistry.monster(m.id)
			var t := item_tile(d.portrait, "Niv. %d" % m.level, d.rarity, 140)
			var idx := i
			on_tap(t, func():
				_picked.remove_at(idx)
				refresh())
			_parents.add_child(t)
		else:
			var e := item_tile(preload("res://assets/icons/ui/egg.svg"), "Choisir", 0, 140)
			e.modulate = Color(1, 1, 1, 0.4)
			_parents.add_child(e)
		if i == 0:
			_parents.add_child(UiTheme.label("+", "TitleLabel", 48))
	clear(_info)
	if _picked.size() == 2:
		var a := DataRegistry.monster(coll.monsters[_picked[0]].id)
		var b := DataRegistry.monster(coll.monsters[_picked[1]].id)
		var recipe := FusionRules.recipe_for(a.id, b.id)
		if recipe and recipe.id in coll.discovered_recipes:
			_info.add_child(UiTheme.label("Recette connue : %s (%d %%)" % [DataRegistry.monster(recipe.result).display_name, roundi(recipe.chance * 100)], "HudLabel", 20, UiTheme.GOLD))
		elif recipe:
			_info.add_child(UiTheme.label("Ces deux créatures semblent réagir étrangement…", "HudLabel", 20, Color("d8b4ff")))
		else:
			_info.add_child(UiTheme.label("Résultat : une espèce apparentée, de rareté %s ou plus." % GameEnums.rarity_name(maxi(a.rarity, b.rarity)), "", 18))
		_info.add_child(UiTheme.label("Les deux créatures seront fusionnées. Rare : mutation en variante.", "DimLabel", 16))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var fuse := UiTheme.button("Fusionner", "PremiumButton", preload("res://assets/icons/ui/speedup.svg"), 24)
		fuse.custom_minimum_size = Vector2(0, 64)
		fuse.disabled = FusionRules.reason(coll, _picked[0], _picked[1], GameState.wallet) != ""
		fuse.pressed.connect(_fuse)
		row.add_child(fuse)
		row.add_child(UiTheme.cost_row(FusionRules.cost(coll, _picked[0], _picked[1]), GameState.wallet, 18))
		_info.add_child(row)
	else:
		_info.add_child(UiTheme.label("Choisissez deux créatures dans la liste. Certaines associations cachent des recettes secrètes.", "DimLabel", 17))
	clear(_list)
	for uid in coll.monsters:
		if uid in _picked:
			continue
		var m: Dictionary = coll.monsters[uid]
		var d := DataRegistry.monster(m.id)
		var t := item_tile(d.portrait, "Niv. %d" % m.level, d.rarity, 110)
		on_tap(t, func():
			if _picked.size() < 2:
				_picked.append(uid)
				refresh())
		_list.add_child(t)


func _fuse() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var a := DataRegistry.monster(GameState.collection.monsters[_picked[0]].id)
	var b := DataRegistry.monster(GameState.collection.monsters[_picked[1]].id)
	var r := FusionRules.fuse(GameState.collection, _picked[0], _picked[1], GameState.wallet, rng)
	if r.has("error"):
		Events.toast_requested.emit(r.error, "error")
		return
	_picked.clear()
	AudioManager.sfx("fusion", 0.0)
	GameState.save()
	var d := DataRegistry.monster(r.id)
	var lines := [("Variante " + FusionRules.VARIANT_NAMES[r.variant] + " !") if r.variant != "" else "Fusion de %s et %s" % [a.display_name, b.display_name]]
	if r.recipe:
		lines.append("Recette secrète découverte !")
	RevealOverlay.play(self, d.model_scene, d.rarity, "Nouvelle espèce !" if r.new else "Fusion réussie !", d.display_name, lines,
		FusionRules.VARIANT_COLORS.get(r.variant, Color("b464ff")))
	refresh()
