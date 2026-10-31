class_name FusionRecipeData
extends Resource
## Recette secrète de fusion : deux espèces donnent une espèce précise (avec une chance).

@export var id := ""
@export var parent_a := ""
@export var parent_b := ""
@export var result := ""
@export_range(0.0, 1.0) var chance := 1.0
