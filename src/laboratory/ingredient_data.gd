class_name IngredientData
extends Resource
## Ingrédient du laboratoire. Ses affinités pondèrent les créatures possibles
## sans jamais garantir un résultat (voir docs/ARCHITECTURE.md).

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var rarity := GameEnums.Rarity.COMMON
@export var element := GameEnums.Element.NEUTRAL
@export var power := 1
## Bonus de poids par tag génétique : { "vegetal": 0.5, "igne": 0.3 }.
@export var genetic_affinities := {}
## Bonus multiplicatif appliqué aux tirages de rareté supérieure.
@export var rarity_boost := 0.0
