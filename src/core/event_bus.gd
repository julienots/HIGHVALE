extends Node
## Bus d'événements global (autoload « Events »).
## Les modules communiquent par signaux pour rester découplés.

signal game_loaded
signal resource_changed(resource_id: String, amount: int)
signal capacities_changed
signal building_added(uid: int)
signal building_removed(uid: int)
signal building_changed(uid: int)
signal building_task_finished(uid: int)
signal temple_level_changed(level: int)
signal population_changed
signal wilds_changed
signal collection_changed
signal inventory_changed
signal quests_changed
signal research_changed
## Action du joueur suivie par les missions (collect, build, harvest, battle_win…).
signal action_done(kind: String, amount: int)
signal toast_requested(text: String, kind: String)
signal story_chapter_requested(chapter: StoryChapterData)
signal settings_changed
