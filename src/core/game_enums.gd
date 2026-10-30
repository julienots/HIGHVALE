class_name GameEnums
extends RefCounted
## Énumérations partagées par tous les modules de HIGHVALE.
## Les valeurs sont sauvegardées : ne jamais réordonner, seulement ajouter à la fin.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY, DIVINE }

enum Element { NEUTRAL, FIRE, WATER, EARTH, AIR, NATURE, CRYSTAL, LIGHT, SHADOW, VOID }

enum HeroClass { WARRIOR, GUARDIAN, ASSASSIN, MAGE, PRIEST, ARCHER, SUMMONER, CONTROLLER, BERSERKER, SUPPORT }

enum MonsterCategory { TERRESTRIAL, FLYING, AQUATIC, MAGICAL, PLANT, ELEMENTAL, ANCIENT, DIVINE }

enum StatusEffect { NONE, BURN, FREEZE, POISON, PARALYSIS, WEAKEN, SHIELD, REGEN, STUN, TAUNT }

const RARITY_NAMES := ["Commun", "Rare", "Épique", "Légendaire", "Divin"]
const RARITY_COLORS := [
	Color("9aa4b1"), Color("3d9bff"), Color("b25cff"), Color("ffb020"), Color("ff5ad1"),
]
const ELEMENT_NAMES := ["Neutre", "Feu", "Eau", "Terre", "Air", "Nature", "Cristal", "Lumière", "Ombre", "Néant"]
const HERO_CLASS_NAMES := ["Guerrier", "Gardien", "Assassin", "Mage", "Prêtre", "Archer", "Invocateur", "Contrôleur", "Berserker", "Support"]
const MONSTER_CATEGORY_NAMES := ["Terrestre", "Volante", "Aquatique", "Magique", "Végétale", "Élémentaire", "Antique", "Divine"]


static func rarity_name(r: int) -> String:
	return RARITY_NAMES[clampi(r, 0, RARITY_NAMES.size() - 1)]


static func rarity_color(r: int) -> Color:
	return RARITY_COLORS[clampi(r, 0, RARITY_COLORS.size() - 1)]


static func element_name(e: int) -> String:
	return ELEMENT_NAMES[clampi(e, 0, ELEMENT_NAMES.size() - 1)]
