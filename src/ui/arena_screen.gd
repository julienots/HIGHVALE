class_name ArenaScreen
extends ModalScreen
## Assauts : ligue et trophées, adversaire tiré au hasard (attaquer ou en
## chercher un autre), défense de la cité contre les hordes, et accès aux défis
## au tour par tour.

const ICON_TROPHY := preload("res://assets/icons/ui/star.svg")

var stages: StagesScreen
var _content: VBoxContainer
var _seed := 0
var _base: Dictionary = {}
var _timer_label: Label
var _tick := 0.0


func _ready() -> void:
	_build_shell("Assauts")
	music = "music_explore"
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)


func open_screen() -> void:
	if _base.is_empty():
		_new_opponent()
	super.open_screen()


func _process(delta: float) -> void:
	if not visible or _timer_label == null:
		return
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		var left := _defense_left()
		if left <= 0.0 and _timer_label.text.begins_with("Prochaine"):
			refresh()
		elif left > 0.0:
			_timer_label.text = "Prochaine horde dans %s" % Fmt.duration(left)


func _level() -> int:
	return RaidBaseGen.level_for_trophies(RaidRules.trophies(GameState.profile))


func _new_opponent() -> void:
	_seed = randi()
	_base = RaidBaseGen.generate(_level(), _seed)


func _defense_left() -> float:
	return float(GameState.profile.get("next_defense_at", 0.0)) - GameClock.now()


func refresh() -> void:
	clear(_content)
	_timer_label = null
	var t := RaidRules.trophies(GameState.profile)
	var lg := RaidRules.league(t)
	# Ligue
	var head := PanelContainer.new()
	var hsb := UiTheme.box(lg[2].darkened(0.65), lg[2], 20, 4, 6)
	hsb.set_content_margin_all(14)
	head.add_theme_stylebox_override("panel", hsb)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 18)
	head.add_child(hrow)
	var icon := UiTheme.icon_rect(ICON_TROPHY, 84)
	icon.modulate = lg[2].lightened(0.2)
	hrow.add_child(icon)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UiTheme.label("Ligue %s" % lg[1], "TitleLabel", 34, lg[2].lightened(0.3)))
	hv.add_child(UiTheme.label("%d trophées • %d assauts gagnés" % [t, int(GameState.profile.get("raids_won", 0))], "HeaderLabel", 22))
	var nxt := -1
	for l in RaidRules.LEAGUES:
		if int(l[0]) > t:
			nxt = int(l[0])
			break
	if nxt > 0:
		var bar := ProgressBar.new()
		bar.min_value = int(lg[0])
		bar.max_value = nxt
		bar.value = t
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(380, 18)
		hv.add_child(bar)
	hrow.add_child(hv)
	_content.add_child(head)
	# Adversaire
	var counts := {}
	for s in _base.structures:
		counts[s.data_id] = int(counts.get(s.data_id, 0)) + 1
	var defs := 0
	for k in counts:
		var d := DataRegistry.building(k)
		if d and d.is_defense():
			defs += counts[k]
	var loot := {}
	for s in _base.structures:
		for k in s.loot:
			loot[k] = int(loot.get(k, 0)) + int(s.loot[k])
	var card := PanelContainer.new()
	var csb := UiTheme.box(Color(0.35, 0.08, 0.1, 0.9), Color("ff6a5a"), 20, 4, 6)
	csb.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", csb)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 18)
	card.add_child(crow)
	crow.add_child(UiTheme.icon_rect(preload("res://assets/icons/elements/fire.svg"), 110))
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 6)
	cv.add_child(UiTheme.label(_base.name, "TitleLabel", 32))
	cv.add_child(UiTheme.label("Base de niveau %d • %d défenses • %d remparts" % [_base.level, defs, int(counts.get("wall", 0))], "HeaderLabel", 20))
	cv.add_child(UiTheme.label("Butin disponible :", "HudLabel", 18, UiTheme.GOLD))
	cv.add_child(UiTheme.cost_row(loot, null, 22))
	var deck := RaidSim.build_deck(GameState.collection, GameClock.now())
	cv.add_child(UiTheme.label("Votre paquet : %d cartes (équipe puis meilleurs personnages)" % deck.size(), "DimLabel", 16))
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	var attack := UiTheme.button("ATTAQUER !", "DangerButton", null, 30)
	attack.custom_minimum_size = Vector2(280, 76)
	attack.disabled = deck.is_empty()
	attack.pressed.connect(func():
		GameState.pending_raid = {"mode": "attack", "seed": _seed, "base": _base}
		_base = {}
		AudioManager.sfx("horn", 0.0)
		GameState.save()
		SceneRouter.go_to(SceneRouter.RAID))
	brow.add_child(attack)
	var cost := RaidRules.search_cost(_level())
	var next := UiTheme.button("Suivant", "SecondaryButton", null, 22)
	next.custom_minimum_size = Vector2(170, 64)
	next.disabled = not GameState.wallet.can_afford(cost)
	next.pressed.connect(func():
		if GameState.wallet.spend(cost):
			_new_opponent()
			AudioManager.sfx("whoosh")
			refresh())
	brow.add_child(next)
	brow.add_child(UiTheme.cost_row(cost, GameState.wallet, 20))
	cv.add_child(brow)
	crow.add_child(cv)
	_content.add_child(card)
	_pulse(attack)
	# Défense de la cité
	var dcard := PanelContainer.new()
	var dsb := UiTheme.box(Color(0.08, 0.18, 0.35, 0.9), Color("5ab4ff"), 20, 4, 6)
	dsb.set_content_margin_all(16)
	dcard.add_theme_stylebox_override("panel", dsb)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 18)
	dcard.add_child(drow)
	drow.add_child(UiTheme.icon_rect(preload("res://assets/icons/ui/temple.svg"), 96))
	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_child(UiTheme.label("Défense de HIGHVALE", "TitleLabel", 28))
	var ndef := 0
	for b in GameState.city.buildings.values():
		if b.data().is_defense() and b.level > 0:
			ndef += 1
	dv.add_child(UiTheme.label("Vos défenses (%d) et vos remparts protègent le Temple. Repoussez la horde pour gagner une prime ; si le Temple tombe, les pillards emportent une partie de vos ressources." % ndef, "HudLabel", 18))
	dv.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var left := _defense_left()
	if ndef == 0:
		var hint := UiTheme.label("Construisez une Tour d'archers (catégorie Militaire) : les hordes viendront alors tester vos défenses.", "HeaderLabel", 20, UiTheme.GOLD)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dv.add_child(hint)
	elif left <= 0.0:
		_timer_label = UiTheme.label("Une horde approche de la cité !", "HeaderLabel", 22, Color("ff8a6a"))
		dv.add_child(_timer_label)
		var go := UiTheme.button("Défendre la cité", "PrimaryButton", null, 24)
		go.custom_minimum_size = Vector2(280, 66)
		go.pressed.connect(func():
			GameState.pending_raid = {"mode": "defense", "seed": randi()}
			AudioManager.sfx("horn", 0.0)
			GameState.save()
			SceneRouter.go_to(SceneRouter.RAID))
		dv.add_child(go)
		_pulse(go)
	else:
		_timer_label = UiTheme.label("Prochaine horde dans %s" % Fmt.duration(left), "HeaderLabel", 22, UiTheme.GOLD)
		dv.add_child(_timer_label)
	drow.add_child(dv)
	_content.add_child(dcard)
	# Défis au tour par tour
	var other := UiTheme.button("Défis des profondeurs (tour par tour)", "SecondaryButton", null, 22)
	other.custom_minimum_size = Vector2(0, 62)
	other.pressed.connect(func():
		close_screen()
		if stages:
			stages.open_screen())
	_content.add_child(other)
	# Entrée en cascade
	for i in _content.get_child_count():
		var c: Control = _content.get_child(i)
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_property(c, "modulate:a", 1.0, 0.25)


func _pulse(c: Control) -> void:
	var t := c.create_tween().set_loops()
	t.tween_property(c, "modulate", Color(1.2, 1.1, 1.0), 0.6)
	t.tween_property(c, "modulate", Color.WHITE, 0.6)
