class_name GameConfig
extends Resource
## Paramètres globaux d'équilibrage, modifiables dans l'inspecteur.

@export_group("Nouvelle partie")
@export var starting_resources: Dictionary = {}
## Disposition initiale : [{ "id": String, "cell": Vector2i, "level": int }]
@export var starting_layout: Array[Dictionary] = []

@export_group("Cité")
@export var grid_size := Vector2i(40, 40)
@export var buildable_rect := Rect2i(3, 3, 34, 34)
@export var base_builders := 1

@export_group("Population")
@export var starting_inhabitants := 6
## Un nouvel habitant arrive à cet intervalle tant qu'il reste des logements.
@export var population_growth_seconds := 20.0

@export_group("Accélération")
## En dessous de ce temps restant, la fin de chantier est gratuite.
@export var free_speedup_seconds := 30.0
@export var speedup_factor := 1.2
@export var speedup_exponent := 0.75
@export var premium_resource := "prisms"

@export_group("Sauvegarde")
@export var autosave_seconds := 20.0
