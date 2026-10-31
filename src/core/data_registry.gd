extends Node
## Registre des données de jeu (autoload « DataRegistry »).
## Charge automatiquement toutes les ressources .tres des dossiers de data/.
## Ajouter un bâtiment, une ressource ou un chapitre = déposer un fichier, sans toucher au code.

const CONFIG_PATH := "res://data/config/game_config.tres"
const RESOURCE_TYPES_DIR := "res://data/resources"
const BUILDINGS_DIR := "res://data/buildings"
const STORY_DIR := "res://data/story"
const WILDS_DIR := "res://data/wilds"
const HEROES_DIR := "res://data/heroes"
const MONSTERS_DIR := "res://data/monsters"
const INGREDIENTS_DIR := "res://data/ingredients"
const BANNERS_DIR := "res://data/banners"
const FUSION_DIR := "res://data/fusion"
const ENCOUNTERS_DIR := "res://data/encounters"
const ITEMS_DIR := "res://data/items"

var config: GameConfig
var _resource_types := {}  # id -> ResourceTypeData
var _buildings := {}  # id -> BuildingData
var _story: Array[StoryChapterData] = []
var _wilds := {}  # id -> WildResourceData
var _heroes := {}  # id -> HeroData
var _monsters := {}  # id -> MonsterData
var _ingredients := {}  # id -> IngredientData
var _banners: Array[SummonBannerData] = []
var _fusion: Array[FusionRecipeData] = []
var _encounters: Array[EncounterData] = []
var _items := {}


func _ready() -> void:
	reload()


func reload() -> void:
	config = load(CONFIG_PATH)
	_resource_types = _index_by_id(load_dir(RESOURCE_TYPES_DIR))
	_buildings = _index_by_id(load_dir(BUILDINGS_DIR))
	_wilds = _index_by_id(load_dir(WILDS_DIR))
	_heroes = _index_by_id(load_dir(HEROES_DIR))
	_monsters = _index_by_id(load_dir(MONSTERS_DIR))
	_ingredients = _index_by_id(load_dir(INGREDIENTS_DIR))
	_banners.assign(load_dir(BANNERS_DIR))
	_banners.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	_fusion.assign(load_dir(FUSION_DIR))
	_encounters.assign(load_dir(ENCOUNTERS_DIR))
	_items = _index_by_id(load_dir(ITEMS_DIR))
	_encounters.sort_custom(func(a, b): return a.order < b.order)
	_story.clear()
	for r in load_dir(STORY_DIR):
		if r is StoryChapterData:
			_story.append(r)
	_story.sort_custom(func(a, b): return a.temple_level < b.temple_level)


## Charge toutes les ressources d'un dossier (gère les fichiers .remap des exports).
static func load_dir(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("DataRegistry : dossier introuvable %s" % path)
		return out
	var files := dir.get_files()
	files.sort()
	for f in files:
		var file := f.trim_suffix(".remap")
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var res := load(path.path_join(file))
		if res:
			out.append(res)
		else:
			push_error("DataRegistry : impossible de charger %s" % file)
	return out


static func _index_by_id(list: Array[Resource]) -> Dictionary:
	var d := {}
	for r in list:
		var id: String = r.get("id")
		if id.is_empty() or d.has(id):
			push_error("DataRegistry : identifiant vide ou dupliqué « %s » (%s)" % [id, r.resource_path])
			continue
		d[id] = r
	return d


func resource_type(id: String) -> ResourceTypeData:
	return _resource_types.get(id)


func building(id: String) -> BuildingData:
	return _buildings.get(id)


func all_resource_types() -> Array[ResourceTypeData]:
	var list: Array[ResourceTypeData] = []
	list.assign(_resource_types.values())
	list.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	return list


func all_buildings() -> Array[BuildingData]:
	var list: Array[BuildingData] = []
	list.assign(_buildings.values())
	list.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	return list


func wild(id: String) -> WildResourceData:
	return _wilds.get(id)


func all_wilds() -> Array[WildResourceData]:
	var list: Array[WildResourceData] = []
	list.assign(_wilds.values())
	list.sort_custom(func(a, b): return a.id < b.id)
	return list


func hero(id: String) -> HeroData:
	return _heroes.get(id)


func monster(id: String) -> MonsterData:
	return _monsters.get(id)


## Triés par rareté décroissante puis par nom.
func all_heroes() -> Array[HeroData]:
	var list: Array[HeroData] = []
	list.assign(_heroes.values())
	list.sort_custom(func(a, b): return a.display_name < b.display_name if a.rarity == b.rarity else a.rarity > b.rarity)
	return list


func all_monsters() -> Array[MonsterData]:
	var list: Array[MonsterData] = []
	list.assign(_monsters.values())
	list.sort_custom(func(a, b): return a.display_name < b.display_name if a.rarity == b.rarity else a.rarity > b.rarity)
	return list


func ingredient(id: String) -> IngredientData:
	return _ingredients.get(id)


func all_ingredients() -> Array[IngredientData]:
	var list: Array[IngredientData] = []
	list.assign(_ingredients.values())
	list.sort_custom(func(a, b): return a.display_name < b.display_name if a.rarity == b.rarity else a.rarity < b.rarity)
	return list


func banners() -> Array[SummonBannerData]:
	return _banners


func banner(id: String) -> SummonBannerData:
	for b in _banners:
		if b.id == id:
			return b
	return null


func item(id: String) -> ItemData:
	return _items.get(id)


func all_items() -> Array[ItemData]:
	var list: Array[ItemData] = []
	list.assign(_items.values())
	list.sort_custom(func(a, b): return a.slot < b.slot if a.slot != b.slot else a.rarity < b.rarity)
	return list


func encounters() -> Array[EncounterData]:
	return _encounters


func fusion_recipes() -> Array[FusionRecipeData]:
	return _fusion


func story_chapters() -> Array[StoryChapterData]:
	return _story


func story_for_temple_level(level: int) -> StoryChapterData:
	for c in _story:
		if c.temple_level == level:
			return c
	return null
