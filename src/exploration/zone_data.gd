class_name ZoneData
extends Resource
## Zone explorable (profondeurs ou surface) : trois combats dont un boss,
## ambiance de l'arène et ressources rapportées.

const STAGES := 3

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var order := 0
@export var is_surface := false
@export var unlock_temple_level := 1
@export var base_level := 1
@export var recommended_power := 100
@export var resource_drops := {}
@export var monster_ids: PackedStringArray = []
@export var boss_id := ""
@export_group("Ambiance")
@export var ground_color := Color("6b7a9a")
@export var sky_color := Color("0c1a3a")
@export var light_color := Color("7fdcff")
@export var environment_scene: PackedScene


## Combat n° stage (0, 1, 2) de la zone ; le dernier est le boss.
func encounter(stage: int) -> EncounterData:
	var e := EncounterData.new()
	e.id = "%s_%d" % [id, stage]
	e.order = stage + 1
	e.strategy = ["balanced", "focus_weak", "aggressive"][stage]
	var lvl := base_level + stage * 2
	var list: Array[Dictionary] = []
	if stage == STAGES - 1:
		e.display_name = "%s — Gardien" % display_name
		e.description = "Le gardien de la zone attend, entouré de sa garde."
		list.append({"id": boss_id, "level": lvl + 2, "boss": true})
		list.append({"id": monster_ids[0], "level": lvl, "boss": false})
		list.append({"id": monster_ids[1 % monster_ids.size()], "level": lvl, "boss": false})
	else:
		e.display_name = "%s — Étape %d" % [display_name, stage + 1]
		e.description = description
		for i in 3 + stage:
			list.append({"id": monster_ids[(i + stage) % monster_ids.size()], "level": lvl, "boss": false})
	e.enemies = list
	var rew := {}
	for k in resource_drops:
		rew[k] = int(resource_drops[k] * (1 + stage))
	e.rewards = rew
	e.first_clear_rewards = {"prisms": 20 + stage * 15}
	e.fragment_reward = 4 + stage * 3
	return e
