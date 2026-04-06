extends Node

const SETTINGS_PATH := "user://settings.cfg"
const COLLECTION_PATH := "user://collection.cfg"

var volume: float = 50.0
var resolution_index: int = 0
var keys: Dictionary[String, int] = {"accelerer" : KEY_Z, "gauche" : KEY_Q, "droite" : KEY_D, "tirer" : KEY_SPACE, "pause" : KEY_ESCAPE} 

var ship_skin_index: int = 0
var laser_skin_index: int = 0

# 0 = Classique, 1 = Boss Rush, 2 = Shooter
var game_mode: int = 0

# Collectibles (IDs 1-7) that the player has found
var collected_items: Array[int] = []

func _ready() -> void:
	Settings.load_from_disk()

func appliquer_touche(eventName : String) -> void:
	# 1. On crée un "faux" événement clavier
	var nouvel_event = InputEventKey.new()
	nouvel_event.keycode = keys[eventName]
	# 2. On efface toutes les touches actuellement liées à l'action "accelerer"
	InputMap.action_erase_events(eventName)
	# 3. On ajoute notre nouvelle touche à l'action
	InputMap.action_add_event(eventName, nouvel_event)

func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		volume = float(cfg.get_value("audio", "volume", volume))
		resolution_index = int(cfg.get_value("video", "resolution_index", resolution_index))
		keys["accelerer"] = int(cfg.get_value("keys", "accelerer", resolution_index))
		appliquer_touche("accelerer")
		keys["droite"] = int(cfg.get_value("keys", "droite", resolution_index))
		appliquer_touche("droite")
		keys["gauche"] = int(cfg.get_value("keys", "gauche", resolution_index))
		appliquer_touche("gauche")
		keys["tirer"] = int(cfg.get_value("keys", "tirer", resolution_index))
		appliquer_touche("tirer")
		keys["pause"] = int(cfg.get_value("keys", "pause", resolution_index))
		appliquer_touche("pause")
		ship_skin_index = int(cfg.get_value("player", "ship_skin_index", ship_skin_index))
		laser_skin_index = int(cfg.get_value("player", "laser_skin_index", laser_skin_index))
	_load_collection()

func save_to_disk() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("keys", "accelerer", keys["accelerer"])
	cfg.set_value("keys", "droite", keys["droite"])
	cfg.set_value("keys", "gauche", keys["gauche"])
	cfg.set_value("keys", "tirer", keys["tirer"])
	cfg.set_value("keys", "pause", keys["pause"])
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
