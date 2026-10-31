class_name FeatureFlags
extends RefCounted
## Modules de jeu livrés. Un bâtiment dont le module n'est pas listé ici est
## affiché comme « Prochainement » dans le menu de construction.
## À chaque étape du plan de développement, ajouter le module livré.

const ENABLED := {
	"city": true,
	"economy": true,
	"population": true,
	"heroes": true,
	"monsters": true,
	"laboratory": true,
	"fusion": true,
	"summoning": true,
	"divine": true,
}

const MODULE_NAMES := {
	"population": "Population (étape 4)",
	"heroes": "Collection des héros (étape 5)",
	"monsters": "Collection des monstres (étape 5)",
	"laboratory": "Laboratoire (étape 6)",
	"fusion": "Fusionnerie (étape 6)",
	"summoning": "Invocation (étape 7)",
	"divine": "Dieux (étape 7)",
	"combat": "Combats (étape 8)",
	"equipment": "Équipements (étape 9)",
	"research": "Recherches (étape 9)",
	"exploration": "Exploration (étape 9)",
	"shop": "Commerce (étape 10)",
}


static func is_enabled(feature: String) -> bool:
	return ENABLED.get(feature, false)


static func module_name(feature: String) -> String:
	return MODULE_NAMES.get(feature, feature)
