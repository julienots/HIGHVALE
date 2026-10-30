class_name BuildingState
extends RefCounted
## État sauvegardé d'un bâtiment posé dans la cité.

enum Task { NONE, CONSTRUCTING, UPGRADING }

var uid := 0
var data_id := ""
## Niveau atteint. 0 pendant la construction initiale.
var level := 0
## Coin (x, y) minimal de l'emprise sur la grille.
var cell := Vector2i.ZERO
var task := Task.NONE
var task_start := 0.0
var task_end := 0.0
## Ressources dépensées pour le chantier en cours (remboursables en cas d'annulation).
var task_cost := {}
## La production s'accumule depuis prod_since ; prod_carry contient le reste déjà produit.
var prod_since := 0.0
var prod_carry := 0.0


func data() -> BuildingData:
	return DataRegistry.building(data_id)


func footprint() -> Vector2i:
	return data().footprint


func rect() -> Rect2i:
	return Rect2i(cell, footprint())


func is_busy() -> bool:
	return task != Task.NONE


func task_remaining(now: float) -> float:
	return maxf(task_end - now, 0.0) if is_busy() else 0.0


func task_progress(now: float) -> float:
	if not is_busy() or task_end <= task_start:
		return 1.0
	return clampf((now - task_start) / (task_end - task_start), 0.0, 1.0)


## Quantité produite en attente de collecte. La production est en pause pendant un chantier.
func stored_production(now: float) -> float:
	var d := data()
	if level < 1 or d.produces.is_empty():
		return 0.0
	var cap := float(d.internal_capacity(level))
	if is_busy():
		return minf(prod_carry, cap)
	var produced := d.production_per_hour(level) / 3600.0 * maxf(now - prod_since, 0.0)
	return minf(prod_carry + produced, cap)


func to_dict() -> Dictionary:
	return {
		"uid": uid, "id": data_id, "level": level, "x": cell.x, "y": cell.y,
		"task": task, "task_start": task_start, "task_end": task_end, "task_cost": task_cost,
		"prod_since": prod_since, "prod_carry": prod_carry,
	}


static func from_dict(d: Dictionary) -> BuildingState:
	var b := BuildingState.new()
	b.uid = int(d.get("uid", 0))
	b.data_id = str(d.get("id", ""))
	b.level = int(d.get("level", 0))
	b.cell = Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
	b.task = int(d.get("task", Task.NONE)) as Task
	b.task_start = float(d.get("task_start", 0.0))
	b.task_end = float(d.get("task_end", 0.0))
	b.task_cost = {}
	var tc: Dictionary = d.get("task_cost", {})
	for k in tc:
		b.task_cost[str(k)] = int(tc[k])
	b.prod_since = float(d.get("prod_since", 0.0))
	b.prod_carry = float(d.get("prod_carry", 0.0))
	return b
