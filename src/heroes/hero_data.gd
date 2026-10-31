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
## Niveau du Temple requis pour l'invoquer (héros venus de la surface).
@export var requires_temple := 0
@export var stats: CharacterStats
@export var skills: Array[SkillData] = []
@export var max_level := 60
## Fragments nécessaires pour débloquer / faire évoluer le héros.
@export var fragments_to_unlock := 30
@export_group("Visuel")
@export var portrait: Texture2D
## Modèle 3D chargé à la demande (évite de charger toute la collection au démarrage).
@export_file("*.glb") var model_path := ""
var model_scene: PackedScene:
	get:
		if _model == null and model_path != "":
			_model = load(model_path)
		return _model
	set(value):
		_model = value
var _model: PackedScene
@export var signature_color := Color.WHITE
