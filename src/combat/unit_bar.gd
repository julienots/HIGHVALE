class_name UnitBar
extends Control
## Jauges au-dessus d'un combattant : vie, bouclier, énergie et états.

const STATUS_COLORS := {1: Color("ff7a30"), 2: Color("7fdcff"), 3: Color("8ad84a"), 4: Color("ffe06a"), 5: Color("b48aff"),
	6: Color("e8f4ff"), 7: Color("5bd36b"), 8: Color("ffd24a"), 9: Color("ff5a5a")}

var unit: Combatant
var shown_hp := 1.0
var selectable := false
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(110, 30)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if unit:
		shown_hp = move_toward(shown_hp, unit.hp_ratio(), delta * 1.5)
	queue_redraw()


func _draw() -> void:
	if unit == null or not unit.is_alive():
		return
	var w := size.x
	var col := Color("5bd36b") if unit.side == 0 else Color("ff5a5a")
	draw_rect(Rect2(0, 0, w, 12), Color("1b1430"))
	draw_rect(Rect2(2, 2, (w - 4) * shown_hp, 8), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(2, 2, (w - 4) * unit.hp_ratio(), 8), col)
	if unit.shield > 0:
		draw_rect(Rect2(2, 2, (w - 4) * minf(float(unit.shield) / unit.max_hp, 1.0), 4), Color(0.85, 0.95, 1.0, 0.9))
	draw_rect(Rect2(0, 13, w, 6), Color("1b1430"))
	draw_rect(Rect2(2, 14, (w - 4) * unit.energy / 100.0, 4), Color("ffc531") if unit.energy < 100 else Color("fff1a8"))
	var x := 0.0
	for s in unit.statuses:
		draw_circle(Vector2(x + 6, 26), 5.5, Color("1b1430"))
		draw_circle(Vector2(x + 6, 26), 4.0, STATUS_COLORS.get(s.effect, Color.WHITE))
		x += 13
	if selectable:
		var a := 0.5 + 0.5 * sin(_t * 8.0)
		draw_rect(Rect2(-4, -4, w + 8, 34), Color(1, 0.85, 0.3, a), false, 3.0)
