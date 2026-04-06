extends Node

const SETTINGS_PATH := "user://settings.cfg"
const COLLECTION_PATH := "user://collection.cfg"

var volume: float = 50.0
var resolution_index: int = 0
var speed_key: int = KEY_SPACE

var ship_skin_index: int = 0
var laser_skin_index: int = 0

# 0 = Classique, 1 = Boss Rush, 2 = Shooter
var game_mode: int = 0

# Collectibles (IDs 1-7) that the player has found
var collected_items: Array[int] = []

func appliquer_touche_acceleration() -> void:
	var nouvel_event = InputEventKey.new()
	nouvel_event.keycode = speed_key
	InputMap.action_erase_events("accelerer")
	InputMap.action_add_event("accelerer", nouvel_event)

func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		volume = float(cfg.get_value("audio", "volume", volume))
		resolution_index = int(cfg.get_value("video", "resolution_index", resolution_index))
		speed_key = int(cfg.get_value("keys", "accelerer", speed_key))
		ship_skin_index = int(cfg.get_value("player", "ship_skin_index", ship_skin_index))
		laser_skin_index = int(cfg.get_value("player", "laser_skin_index", laser_skin_index))
		appliquer_touche_acceleration()
	_load_collection()

func save_to_disk() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("keys", "accelerer", speed_key)
	cfg.set_value("player", "ship_skin_index", ship_skin_index)
	cfg.set_value("player", "laser_skin_index", laser_skin_index)
	return cfg.save(SETTINGS_PATH) == OK

func add_collectible(id: int) -> bool:
	if id in collected_items:
		return false
	collected_items.append(id)
	_save_collection()
	return true

func has_collectible(id: int) -> bool:
	return id in collected_items

func _load_collection() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(COLLECTION_PATH) != OK:
		return
	var raw = cfg.get_value("data", "items", [])
	collected_items.clear()
	for item in raw:
		collected_items.append(int(item))

func _save_collection() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("data", "items", collected_items)
	cfg.save(COLLECTION_PATH)
