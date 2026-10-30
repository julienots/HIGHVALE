class_name ResourceTypeData
extends Resource
## Définition d'une ressource (or, pierre, cristaux…).

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var color := Color.WHITE
@export var sort_order := 0
## Capacité de base sans entrepôt. -1 = illimitée (monnaie premium).
@export var base_capacity := 1000
@export var is_premium := false
## Affichée dans la barre du haut de la cité.
@export var show_in_hud := false
## Texte indiquant comment l'obtenir quand elle n'est pas encore produite.
@export var source_hint := ""
