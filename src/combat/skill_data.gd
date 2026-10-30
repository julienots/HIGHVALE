class_name SkillData
extends Resource
## Compétence utilisable en combat. Les effets sont décrits par des données
## pour que le moteur de combat (étape 8) les exécute sans code spécifique.

enum Kind { BASIC, SPECIAL, ULTIMATE, PASSIVE }
enum Target { SINGLE_ENEMY, ALL_ENEMIES, ROW_ENEMIES, SELF, SINGLE_ALLY, ALL_ALLIES, RANDOM_ENEMIES }

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var kind := Kind.BASIC
@export var element := GameEnums.Element.NEUTRAL
@export var target := Target.SINGLE_ENEMY
@export var hits := 1
## Multiplicateur appliqué à l'attaque du lanceur. 0 = pas de dégâts.
@export var power := 1.0
@export var heal_power := 0.0
@export var shield_power := 0.0
@export var energy_cost := 0
@export var energy_gain := 25
@export var cooldown_turns := 0
@export var status_effect := GameEnums.StatusEffect.NONE
@export_range(0.0, 1.0) var status_chance := 0.0
@export var status_turns := 2
## Animation / effet visuel joué par la scène de combat.
@export var vfx_scene: PackedScene
@export var cinematic := false
