class_name BuildingData
extends Resource
## Définition d'un type de bâtiment. Les valeurs par niveau sont calculées par
## formules de croissance afin qu'un bâtiment complet tienne dans un seul fichier.

enum Category { CORE, RESOURCE, STORAGE, POPULATION, CREATURES, HEROES, MILITARY, KNOWLEDGE, TRADE, EXPLORATION }

const CATEGORY_NAMES := ["Cœur", "Ressources", "Stockage", "Population", "Créatures", "Héros", "Militaire", "Savoir", "Commerce", "Exploration"]

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var category := Category.RESOURCE
@export var sort_order := 0
## Module de jeu requis (ex. « laboratory »). Vide = disponible dès maintenant.
## Tant que le module n'est pas livré, le bâtiment est visible mais verrouillé.
@export var feature := ""

@export_group("Grille")
@export var footprint := Vector2i(3, 3)

@export_group("Progression")
@export var max_level := 10
@export var unlock_temple_level := 1
## Nombre maximal d'exemplaires selon le niveau du Temple (index 0 = Temple niv. 1).
@export var max_count_by_temple := PackedInt32Array([1])
## Niveau maximal autorisé = level_cap_base + (niveau du Temple - 1) * level_cap_per_temple.
@export var level_cap_base := 2
@export var level_cap_per_temple := 2
## Coût de construction (niveau 1). Les niveaux suivants sont multipliés par cost_growth.
@export var base_cost := {}
@export var cost_growth := 1.7
@export var base_build_seconds := 10.0
@export var build_time_growth := 2.0
@export var max_build_seconds := 172800.0

@export_group("Production")
@export var produces := ""
@export var base_production_per_hour := 0.0
@export var production_growth := 1.3
## Durée de production que le bâtiment peut contenir avant collecte.
@export var internal_storage_hours := 1.0

@export_group("Stockage")
## Capacité ajoutée au niveau 1 : { resource_id: quantité }.
@export var storage := {}
@export var storage_growth := 1.6

@export_group("Population")
@export var population_base := 0
@export var population_growth := 1.35
## Bâtisseurs fournis (chantiers simultanés).
@export var builders_provided := 0

@export_group("Visuel")
## Modèle 3D définitif (glTF importé). Si absent, le modèle procédural « model_recipe » est utilisé.
@export var model_scene: PackedScene
@export var model_recipe := ""
@export var primary_color := Color("6b7a8f")
@export var accent_color := Color("ffc93c")


func cost_for_level(level: int) -> Dictionary:
	var out := {}
	var mult := pow(cost_growth, level - 1)
	for id in base_cost:
		out[id] = nice_round(base_cost[id] * mult)
	return out


func build_seconds_for_level(level: int) -> float:
	return minf(round(base_build_seconds * pow(build_time_growth, level - 1)), max_build_seconds)


func production_per_hour(level: int) -> float:
	if produces.is_empty() or level < 1:
		return 0.0
	return round(base_production_per_hour * pow(production_growth, level - 1))


func internal_capacity(level: int) -> int:
	return int(production_per_hour(level) * internal_storage_hours)


func storage_for_level(level: int) -> Dictionary:
	var out := {}
	if level < 1:
		return out
	var mult := pow(storage_growth, level - 1)
	for id in storage:
		out[id] = nice_round(storage[id] * mult)
	return out


func population_for_level(level: int) -> int:
	if level < 1 or population_base <= 0:
		return 0
	return int(round(population_base * pow(population_growth, level - 1)))


func max_count(temple_level: int) -> int:
	if temple_level < unlock_temple_level or max_count_by_temple.is_empty():
		return 0
	return max_count_by_temple[clampi(temple_level - 1, 0, max_count_by_temple.size() - 1)]


func level_cap(temple_level: int) -> int:
	return clampi(level_cap_base + (temple_level - 1) * level_cap_per_temple, 1, max_level)


func is_available() -> bool:
	return feature.is_empty() or FeatureFlags.is_enabled(feature)


func category_name() -> String:
	return CATEGORY_NAMES[category]


## Arrondit à des valeurs « propres » pour l'affichage (125, 1 300, 48 000…).
static func nice_round(v: float) -> int:
	if v < 100.0:
		return int(round(v / 5.0) * 5)
	var magnitude := pow(10.0, floor(log(v) / log(10.0)) - 1)
	return int(round(v / magnitude) * magnitude)
