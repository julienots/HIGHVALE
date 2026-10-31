class_name WildResourceData
extends Resource
## Ressource sauvage qui apparaît sur une case libre de la cité et se récolte
## d'un toucher (filon, champignons, cristaux affleurants).

@export var id := ""
@export var display_name := ""
## Tirage au sort de l'apparition (poids relatif).
@export var weight := 1.0
## Récompenses : { resource_id: Vector2i(min, max) }.
@export var rewards := {}
## Chance d'obtenir aussi de la monnaie premium.
@export_range(0.0, 1.0) var premium_chance := 0.0
@export var premium_amount := Vector2i(1, 3)
## Trouvailles éventuelles : { id: Vector3(chance, min, max) } — ressource ou ingrédient.
@export var item_drops := {}
@export var model_scene: PackedScene


func roll_items(rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	for id in item_drops:
		var d: Vector3 = item_drops[id]
		if rng.randf() < d.x:
			out[id] = rng.randi_range(int(d.y), int(d.z))
	return out
