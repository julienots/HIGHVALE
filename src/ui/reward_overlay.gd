class_name RewardOverlay
extends Control
## Ouverture d'un coffre ou d'un cadeau : le coffre tremble, s'ouvre dans un
## éclair, puis les récompenses apparaissent une à une.

var _icon: TextureRect
var _rewards: Dictionary
var _rarity := 0
var _list: HFlowContainer
var _title: Label
var _done_btn: Button


static func play(parent: Node, icon: Texture2D, title: String, rewards: Dictionary, rarity := 1) -> RewardOverlay:
	var o := RewardOverlay.new()
	parent.add_child(o)
	o._setup(icon, title, rewards, rarity)
	return o


func _setup(icon: Texture2D, title: String, rewards: Dictionary, rarity: int) -> void:
	_rewards = rewards
	_rarity = rarity
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	add_child(col)
	_title = UiTheme.label(title, "TitleLabel", 44, GameEnums.rarity_color(rarity).lightened(0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 230)
	col.add_child(holder)
	_icon = UiTheme.icon_rect(icon, 210)
	holder.add_child(_icon)
	_list = HFlowContainer.new()
	_list.alignment = FlowContainer.ALIGNMENT_CENTER
	_list.add_theme_constant_override("h_separation", 14)
	_list.add_theme_constant_override("v_separation", 14)
	_list.custom_minimum_size = Vector2(900, 0)
	_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_list)
	_done_btn = UiTheme.button("Continuer", "PrimaryButton", null, 24)
	_done_btn.custom_minimum_size = Vector2(260, 68)
	_done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_done_btn.modulate.a = 0.0
	_done_btn.disabled = true
	_done_btn.pressed.connect(queue_free)
	col.add_child(_done_btn)
	_animate.call_deferred()


func _animate() -> void:
	_icon.pivot_offset = _icon.size / 2.0
	AudioManager.sfx("charge", 0.0, -4.0)
	var shake := create_tween()
	for i in 8:
		shake.tween_property(_icon, "rotation", 0.12 * (1 if i % 2 == 0 else -1) * (1.0 + i * 0.15), 0.07)
	shake.tween_property(_icon, "rotation", 0.0, 0.05)
	await shake.finished
	AudioManager.sfx("chest", 0.0)
	if _rarity >= 2:
		AudioManager.reveal(_rarity)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.45)
	var pop := create_tween()
	pop.tween_property(_icon, "scale", Vector2(1.25, 1.25), 0.12)
	pop.tween_property(_icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.35).timeout
	for k in _rewards:
		var tile := PanelContainer.new()
		var sb := UiTheme.box(GameEnums.rarity_color(_rarity).darkened(0.55), GameEnums.rarity_color(_rarity), 14, 3, 4)
		sb.set_content_margin_all(12)
		tile.add_theme_stylebox_override("panel", sb)
		var l := UiTheme.label("%s\n×%s" % [k, Fmt.amount(_rewards[k])], "HeaderLabel", 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(l)
		_list.add_child(tile)
		UiSfx.pop_in(tile, 0.22)
		AudioManager.sfx("coin", 0.12)
		await get_tree().create_timer(0.22).timeout
	_done_btn.disabled = false
	create_tween().tween_property(_done_btn, "modulate:a", 1.0, 0.25)
