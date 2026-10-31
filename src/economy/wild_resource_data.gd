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
@export var model_scene: PackedScene
