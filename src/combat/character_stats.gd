class_name CharacterStats
extends Resource
## Statistiques de base d'un combattant (héros, monstre, dieu, ennemi) au niveau 1.

@export var max_hp := 100
@export var attack := 10
@export var defense := 5
@export var speed := 100
@export var max_energy := 100
@export_range(0.0, 1.0) var crit_chance := 0.05
@export var crit_multiplier := 1.5
## Multiplicateur de dégâts reçus par élément : { GameEnums.Element: float }.
@export var element_resistances := {}
## Croissance par niveau (multiplicateur appliqué à PV, attaque et défense).
@export var growth_per_level := 1.08


func at_level(level: int) -> Dictionary:
	var m := pow(growth_per_level, level - 1)
	return {
		"max_hp": int(max_hp * m), "attack": int(attack * m), "defense": int(defense * m),
		"speed": speed, "max_energy": max_energy, "crit_chance": crit_chance, "crit_multiplier": crit_multiplier,
	}
