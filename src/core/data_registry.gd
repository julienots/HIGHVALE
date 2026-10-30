extends Node
## Registre des données de jeu (autoload « DataRegistry »).
## Charge automatiquement toutes les ressources .tres des dossiers de data/.
## Ajouter un bâtiment, une ressource ou un chapitre = déposer un fichier, sans toucher au code.

const CONFIG_PATH := "res://data/config/game_config.tres"
const RESOURCE_TYPES_DIR := "res://data/resources"
const BUILDINGS_DIR := "res://data/buildings"
const STORY_DIR := "res://data/story"

var config: GameConfig
var _resource_types := {}  # id -> ResourceTypeData
var _buildings := {}  # id -> BuildingData
var _story: Array[StoryChapterData] = []


func _ready() -> void:
	reload()


func reload() -> void:
	config = load(CONFIG_PATH)
	_resource_types = _index_by_id(load_dir(RESOURCE_TYPES_DIR))
	_buildings = _index_by_id(load_dir(BUILDINGS_DIR))
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


func story_chapters() -> Array[StoryChapterData]:
	return _story


func story_for_temple_level(level: int) -> StoryChapterData:
	for c in _story:
		if c.temple_level == level:
			return c
	return null
