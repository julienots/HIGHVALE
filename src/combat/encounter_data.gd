class_name EncounterData
extends Resource
## Défi de combat : équipe ennemie, stratégie de l'IA et récompenses.

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var order := 0
## [{ "id": monster_id, "level": int, "boss": bool }]
@export var enemies: Array[Dictionary] = []
## « balanced », « aggressive » (frappe les plus dangereux) ou « focus_weak » (achève les blessés).
@export var strategy := "balanced"
@export var rewards := {}
## Récompense supplémentaire à la première victoire.
@export var first_clear_rewards := {}
@export var fragment_reward := 0
