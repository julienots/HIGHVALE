class_name ItemData
extends Resource
## Objet d'inventaire : équipement, matériau d'évolution, consommable, coffre…

enum Kind { MATERIAL, EQUIPMENT, CONSUMABLE, CHEST, FRAGMENT, DECORATION }
enum Slot { NONE, WEAPON, ARMOR, HELMET, BOOTS, RING, AMULET }

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var kind := Kind.MATERIAL
@export var rarity := GameEnums.Rarity.COMMON
@export var slot := Slot.NONE
@export var stat_bonus := {}
@export var max_stack := 999
