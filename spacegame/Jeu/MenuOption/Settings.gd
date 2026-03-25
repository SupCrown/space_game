extends Node

const SETTINGS_PATH := "user://settings.cfg"

var volume: float = 50.0
var resolution_index: int = 0
var speed_key: int = KEY_SPACE 

func appliquer_touche_acceleration() -> void:
	# 1. On crée un "faux" événement clavier
	var nouvel_event = InputEventKey.new()
	nouvel_event.keycode = speed_key
	# 2. On efface toutes les touches actuellement liées à l'action "accelerer"
	InputMap.action_erase_events("accelerer")
	# 3. On ajoute notre nouvelle touche à l'action
	InputMap.action_add_event("accelerer", nouvel_event)

func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	volume = float(cfg.get_value("audio", "volume", volume))
	resolution_index = int(cfg.get_value("video", "resolution_index", resolution_index))
	speed_key = int(cfg.get_value("keys", "accelerer", resolution_index))
	appliquer_touche_acceleration()

func save_to_disk() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("keys", "accelerer", speed_key)
	return cfg.save(SETTINGS_PATH) == OK
