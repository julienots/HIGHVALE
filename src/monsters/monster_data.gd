class_name MonsterData
extends Resource
## Définition d'une créature collectionnable.

@export var id := ""
@export var display_name := ""
@export_multiline var lore := ""
@export var rarity := GameEnums.Rarity.COMMON
@export var element := GameEnums.Element.NEUTRAL
@export var category := GameEnums.MonsterCategory.TERRESTRIAL
@export var family := ""
@export var stats: CharacterStats
@export var skills: Array[SkillData] = []
@export var max_level := 50
## Évolutions possibles : identifiant du monstre suivant et niveau requis.
@export var evolves_into := ""
@export var evolution_level := 0
@export_group("Habitat")
## Nourriture consommée par heure dans l'habitat : { resource_id: quantité }.
@export var food_per_hour := {}
@export var habitat_element := GameEnums.Element.NEUTRAL
@export_group("Laboratoire")
## Familles génétiques utilisées par le calcul de probabilités du laboratoire.
@export var genetic_tags: PackedStringArray = []
@export var lab_weight := 1.0
@export_group("Visuel")
@export var portrait: Texture2D
@export var model_scene: PackedScene
