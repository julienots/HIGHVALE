class_name LabMachine
extends Control
## Machine de développement biologique dessinée et animée : cuves aux liquides
## colorés par les ingrédients, bulles, arcs électriques et compte à rebours.

const ELEMENT_COLORS := [Color("c8d0e0"), Color("ff7a30"), Color("2a8ad8"), Color("b08850"), Color("9ae0f0"),
	Color("6ad04a"), Color("2fa8ff"), Color("ffe06a"), Color("8a5aff"), Color("b464ff")]

var colors: Array[Color] = []
var running := false
var progress := 0.0
var _t := 0.0
var _bubbles := []


func _ready() -> void:
	custom_minimum_size = Vector2(360, 240)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_ingredients(ings: Array) -> void:
	colors.clear()
	for ing: IngredientData in ings:
		colors.append(ELEMENT_COLORS[ing.element])


func _process(delta: float) -> void:
	_t += delta
	if running and randf() < delta * 14.0:
		_bubbles.append({"x": randf(), "tube": randi() % 3, "y": 0.0, "r": randf_range(3, 7)})
	for b in _bubbles:
		b.y += delta * (0.4 + b.r * 0.05)
	_bubbles = _bubbles.filter(func(b): return b.y < 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var base_y := h - 30.0
	draw_rect(Rect2(20, base_y, w - 40, 22), Color("3b3f4a"))
	draw_rect(Rect2(20, base_y, w - 40, 6), Color("5a6478"))
	var tube_w := (w - 100) / 3.0
	for i in 3:
		var x := 40.0 + i * (tube_w + 10)
		var top := 40.0 + (i % 2) * 18.0
		var rect := Rect2(x, top, tube_w, base_y - top)
		var col: Color = colors[i % colors.size()] if not colors.is_empty() else Color("46d66b")
		var level := 0.35 + 0.45 * (progress if running else 0.6) + 0.03 * sin(_t * 2.5 + i)
		var liquid_top := rect.end.y - rect.size.y * clampf(level, 0.1, 0.95)
		draw_rect(Rect2(rect.position.x, liquid_top, rect.size.x, rect.end.y - liquid_top), col.darkened(0.15))
		var glow := col
		glow.a = 0.35 + (0.25 * sin(_t * 4.0 + i) if running else 0.0)
		draw_rect(Rect2(rect.position.x + 4, liquid_top + 3, rect.size.x - 8, 6), glow.lightened(0.4))
		for b in _bubbles:
			if b.tube == i:
				var by: float = rect.end.y - (rect.end.y - liquid_top) * b.y
				draw_circle(Vector2(rect.position.x + 6 + b.x * (rect.size.x - 12), by), b.r, Color(1, 1, 1, 0.55))
		draw_rect(rect, Color(0.8, 0.95, 1.0, 0.18))
		draw_rect(rect, Color("1b1430"), false, 4.0)
		draw_rect(Rect2(rect.position.x - 6, top - 14, rect.size.x + 12, 14), Color("8a6a3a"))
		draw_rect(Rect2(rect.position.x + 6, rect.position.y + 6, 6, rect.size.y - 12), Color(1, 1, 1, 0.25))
	# Électrodes et arcs
	var e1 := Vector2(30, 20)
	var e2 := Vector2(w - 30, 20)
	for e in [e1, e2]:
		draw_circle(e, 10.0, Color("ffc531"))
		draw_circle(e, 5.0, Color("fff6c8"))
	if running:
		for k in 2:
			var pts := PackedVector2Array([e1])
			var n := 10
			for s in range(1, n):
				var p := e1.lerp(e2, float(s) / n)
				pts.append(p + Vector2(0, randf_range(-14, 14)))
			pts.append(e2)
			draw_polyline(pts, Color(0.7, 0.9, 1.0, 0.9) if k == 0 else Color(1, 1, 1, 0.6), 3.0 - k)
