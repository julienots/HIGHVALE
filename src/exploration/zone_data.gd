class_name ZoneData
extends Resource
## Zone explorable (profondeurs ou surface).

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var is_surface := false
@export var unlock_temple_level := 1
@export var recommended_power := 100
@export var resource_drops := {}
@export var monster_ids: PackedStringArray = []
@export var boss_id := ""
@export var environment_scene: PackedScene
