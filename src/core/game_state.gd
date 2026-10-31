extends Node
## État global de la partie (autoload « GameState »).
## Possède le portefeuille et la cité, fait avancer les minuteries et sauvegarde.

const TICK_SECONDS := 0.25

const STARTER_HEROES := ["bram", "lysa", "mirela"]
const STARTER_MONSTERS := ["gloubi", "shroomling"]

var wallet := Wallet.new()
var collection := CollectionState.new()
var inventory := Inventory.new()
var lab := LaboratoryState.new()
var exploration := ExplorationState.new()
var quests := QuestState.new()
var shop := ShopState.new()
## Combat préparé hors des défis (zone d'exploration).
var pending_battle: EncounterData
var pending_zone := ""
var pending_stage := 0

const STARTER_INGREDIENTS := {"ember_stone": 3, "vital_drop": 3, "tide_scale": 2, "resonant_shard": 2}
## Récompense de chaque nouveau niveau du Temple Primordial.
const TEMPLE_REWARD := {"prisms": 50, "ancient_shards": 20, "divine_dust": 5}
var city := CityState.new()
var profile := {}
## Défi choisi avant d'ouvrir la scène de combat.
var pending_encounter := ""
var is_loaded := false

var _tick_accum := 0.0
var _autosave_accum := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	wallet.changed.connect(func(id, amount): Events.resource_changed.emit(id, amount))
	collection.changed.connect(func(): Events.collection_changed.emit())
	inventory.changed.connect(func(): Events.inventory_changed.emit())
	lab.changed.connect(func(): Events.inventory_changed.emit())
	exploration.changed.connect(func(): Events.inventory_changed.emit())
	quests.changed.connect(func(): Events.quests_changed.emit())
	shop.changed.connect(func(): Events.inventory_changed.emit())
	Events.action_done.connect(func(kind, n): quests.track(kind, n))
	_new_city()


func config() -> GameConfig:
	return DataRegistry.config


func start_or_load() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		new_game()
	else:
		_apply(data)
	is_loaded = true
	# Progression hors ligne : terminer les chantiers échus pendant l'absence.
	city.update(GameClock.now())
	quests.roll(GameClock.now())
	shop.roll(GameClock.now())
	Events.game_loaded.emit()


func new_game() -> void:
	var now := GameClock.now()
	_new_city()
	wallet.from_dict({})
	for id in config().starting_resources:
		wallet.set_amount(str(id), int(config().starting_resources[id]))
	for entry in config().starting_layout:
		city.add_built(entry.get("id", ""), entry.get("cell", Vector2i.ZERO), entry.get("level", 1), now)
	city.inhabitants = config().starting_inhabitants
	city.growth_since = now
	city.auto_assign(now)
	for i in config().starting_wilds:
		city.spawn_wild(int(now) + i * 7919)
	city.next_wild_at = now + config().wild_spawn_seconds
	collection.from_dict({})
	inventory.from_dict({})
	lab.from_dict({})
	exploration.from_dict({})
	quests.from_dict({})
	shop.from_dict({})
	_give_starters()
	profile = {"player_name": "Fondateur", "created_at": now, "story_seen": []}
	is_loaded = true
	save()


func reset_game() -> void:
	SaveSystem.delete_save()
	new_game()
	Events.game_loaded.emit()


## Lance le combat préparé (pending_*) si au moins un combattant est valide.
func launch_battle() -> bool:
	if collection.build_team_combatants(GameClock.now()).is_empty():
		Events.toast_requested.emit("Toute votre équipe est blessée : soignez-la à l'Infirmerie ou ajoutez des créatures.", "error")
		return false
	save()
	SceneRouter.go_to(SceneRouter.BATTLE)
	return true


func save() -> void:
	if not is_loaded:
		return
	SaveSystem.save_game(to_dict())
	_autosave_accum = 0.0


func to_dict() -> Dictionary:
	return {"profile": profile, "wallet": wallet.to_dict(), "city": city.to_dict(), "collection": collection.to_dict(),
		"inventory": inventory.to_dict(), "lab": lab.to_dict(), "exploration": exploration.to_dict(),
		"quests": quests.to_dict(), "shop": shop.to_dict()}


func _apply(data: Dictionary) -> void:
	_new_city()
	city.from_dict(data.get("city", {}))
	wallet.from_dict(data.get("wallet", {}))
	profile = data.get("profile", {})
	collection.from_dict(data.get("collection", {}))
	inventory.from_dict(data.get("inventory", {}))
	lab.from_dict(data.get("lab", {}))
	exploration.from_dict(data.get("exploration", {}))
	quests.from_dict(data.get("quests", {}))
	shop.from_dict(data.get("shop", {}))
	if not data.has("inventory"):
		for id in STARTER_INGREDIENTS:
			inventory.add(id, STARTER_INGREDIENTS[id])
	if not data.has("collection"):
		# Sauvegarde antérieure à la collection : héros et créatures de départ.
		_give_starters()
	if not profile.has("story_seen"):
		profile["story_seen"] = []


func _give_starters() -> void:
	for id in STARTER_HEROES:
		collection.unlock_hero(id)
	for id in STARTER_MONSTERS:
		collection.add_monster(id)
	for id in STARTER_INGREDIENTS:
		inventory.add(id, STARTER_INGREDIENTS[id])
	collection.default_team()


## Remplace la cité courante par une cité vide reliée aux signaux globaux.
func _new_city() -> CityState:
	city = CityState.new()
	city.configure(config())
	city.building_added.connect(_on_building_added)
	city.building_removed.connect(_on_building_removed)
	city.building_changed.connect(func(b): Events.building_changed.emit(b.uid))
	city.task_finished.connect(_on_task_finished)
	city.population_changed.connect(func(): Events.population_changed.emit())
	city.wilds_changed.connect(func(): Events.wilds_changed.emit())
	wallet.capacity_provider = city.storage_capacity
	return city


func _process(delta: float) -> void:
	if not is_loaded:
		return
	_tick_accum += delta
	if _tick_accum >= TICK_SECONDS:
		_tick_accum = 0.0
		var now := GameClock.now()
		city.update(now)
		quests.roll(now)
		shop.roll(now)
	_autosave_accum += delta
	if _autosave_accum >= config().autosave_seconds:
		save()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save()


# --- Histoire -------------------------------------------------------------

## Affiche le chapitre lié au niveau du Temple s'il n'a pas encore été lu.
func request_story_for_level(level: int) -> void:
	var chapter := DataRegistry.story_for_temple_level(level)
	if chapter == null or chapter.id in profile.get("story_seen", []):
		return
	profile["story_seen"].append(chapter.id)
	Events.story_chapter_requested.emit(chapter)


# --- Signaux de la cité ---------------------------------------------------

func _on_building_added(b: BuildingState) -> void:
	Events.building_added.emit(b.uid)
	Events.capacities_changed.emit()


func _on_building_removed(b: BuildingState) -> void:
	Events.building_removed.emit(b.uid)
	Events.capacities_changed.emit()


func _on_task_finished(b: BuildingState) -> void:
	Events.building_task_finished.emit(b.uid)
	Events.capacities_changed.emit()
	if b.data_id == CityState.TEMPLE_ID:
		for id in TEMPLE_REWARD:
			wallet.add(id, TEMPLE_REWARD[id])
		Events.toast_requested.emit("Le Temple récompense la cité : prismes, éclats antiques et poussière divine !", "reward")
		Events.temple_level_changed.emit(b.level)
		request_story_for_level(b.level)
