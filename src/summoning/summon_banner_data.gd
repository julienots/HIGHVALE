class_name SummonBannerData
extends Resource
## Type d'invocation : coût, taux par rareté (affichés au joueur), filtres et garantie.

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var sort_order := 0
@export var cost := {}
## Taux en % par rareté : Commun, Rare, Épique, Légendaire, Divin.
@export var rarity_rates := PackedFloat32Array([70, 24, 5, 1, 0])
## -1 : tous les éléments ; -2 : élément du jour ; sinon GameEnums.Element.
@export var element := -1
## Autel divin : uniquement les dieux.
@export var gods_only := false
## Héros Épique ou mieux garanti après N invocations sans en obtenir (0 = aucune garantie).
@export var pity_epic := 0
@export var accent_color := Color.WHITE
