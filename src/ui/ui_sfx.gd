class_name UiSfx
extends RefCounted
## Retour visuel des boutons (petit « rebond »). Les sons seront branchés ici.


static func click(c: Control) -> void:
	if not c.is_inside_tree():
		return
	c.pivot_offset = c.size / 2.0
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2(0.92, 0.92), 0.05)
	t.tween_property(c, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func pop_in(c: Control, duration := 0.25) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(0.8, 0.8)
	c.modulate.a = 0.0
	var t := c.create_tween().set_parallel()
	t.tween_property(c, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, duration * 0.6)
