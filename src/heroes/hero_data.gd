class_name HeroData
extends Resource
## Définition d'un héros (ou d'un dieu si is_god est vrai).

@export var id := ""
@export var display_name := ""
@export var title := ""
@export_multiline var lore := ""
@export var rarity := GameEnums.Rarity.COMMON
@export var element := GameEnums.Element.NEUTRAL
@export var hero_class := GameEnums.HeroClass.WARRIOR
@export var is_god := false
@export var stats: CharacterStats
@export var skills: Array[SkillData] = []
@export var max_level := 60
## Fragments nécessaires pour débloquer / faire évoluer le héros.
@export var fragments_to_unlock := 30
@export_group("Visuel")
@export var portrait: Texture2D
@export var model_scene: PackedScene
@export var signature_color := Color.WHITE
