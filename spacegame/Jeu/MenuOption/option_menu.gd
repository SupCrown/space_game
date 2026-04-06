extends Control

@onready var volume_slider: Slider = $%MenuAudio/VolumeSlider
@onready var resolution_option: OptionButton = $%MenuVideo/ChoixOption
@onready var speed_control_btn: Button = $%MenuControle/Controls/ControlContainer/SpeedControleKey
@onready var right_control_btn: Button = $%MenuControle/Controls/ControlContainer2/RightControlKey
@onready var left_control_btn: Button = $%MenuControle/Controls/ControlContainer3/LeftControlKey
@onready var shoot_control_btn: Button = $%MenuControle/Controls/ControlContainer4/ShootControlKey
@onready var pause_control_btn: Button = $%MenuControle/Controls/ControlContainer5/PauseControlKey
var is_listening_for_speed_key: bool = false
var is_listening_for_right_key: bool = false
var is_listening_for_left_key: bool = false
var is_listening_for_shoot_key: bool = false
var is_listening_for_pause_key: bool = false

@onready var ship_preview: Sprite2D = get_node_or_null("%Sprite2DVaisseauChoix")
@onready var laser_preview: Sprite2D = get_node_or_null("%Sprite2DLazerChoix")

const BACK_SCENE := "res://Jeu/Menu/Systeme.tscn"

const SHIP_SKINS := [
	{ "path": "res://Ressources/Vaisseau/Statique/perseus_1.png", "scale": Vector2(0.3, 0.3) },
	{ "path": "res://Ressources/Vaisseau/spaceship.png", "scale": Vector2(0.2, 0.2) },
	{ "path": "res://Ressources/Vaisseau/ultraship.png", "scale": Vector2(0.3, 0.3) }
]

const LASER_SKINS := [
	{ "path": "res://Ressources/Laser/laz_3.png", "scale": Vector2(1.0, 1.0) },
	{ "path": "res://Ressources/Laser/lazer_type_2.png", "scale": Vector2(0.1, 0.1) },
	{ "path": "res://Ressources/Laser/lazer_type_3.png", "scale": Vector2(0.4, 0.4) }
]

func _ready() -> void:
	Settings.load_from_disk()
	apply_settings_to_ui()
	update_ship_preview()
	update_laser_preview()

func apply_settings_to_ui() -> void:
	if volume_slider == null or resolution_option == null or speed_control_btn == null :
		push_error("❌ Node UI introuvable: vérifie PanelCon/VolumeSlider, PanelCon/ChoixOption, PanelCon/SpeedControle")
		return

	volume_slider.value = Settings.volume
	resolution_option.selected = Settings.resolution_index
	speed_control_btn.text = OS.get_keycode_string(Settings.keys["accelerer"])
	right_control_btn.text = OS.get_keycode_string(Settings.keys["droite"])
	left_control_btn.text = OS.get_keycode_string(Settings.keys["gauche"])
	shoot_control_btn.text = OS.get_keycode_string(Settings.keys["tirer"])
	pause_control_btn.text = OS.get_keycode_string(Settings.keys["pause"])
	show_panel("audio")

func show_panel(which: String) -> void:
	var audio = get_node_or_null("%MenuAudio")
	var video = get_node_or_null("%MenuVideo")
	var controle = get_node_or_null("%MenuControle")
	var joueur_vais = get_node_or_null("%MenuJoueurVaisseau")
	var joueur_laz = get_node_or_null("%MenuJoueurLazer")
	if audio: audio.visible = (which == "audio")
	if video: video.visible = (which == "video")
	if controle: controle.visible = (which == "controle")
	if joueur_vais: joueur_vais.visible = (which == "joueur")
	if joueur_laz: joueur_laz.visible = (which == "joueur")

func read_ui_to_settings() -> void:
	Settings.volume = float(volume_slider.value)
	Settings.resolution_index = int(resolution_option.selected)

func update_ship_preview() -> void:
	if ship_preview == null:
		return
	Settings.ship_skin_index = wrapi(Settings.ship_skin_index, 0, SHIP_SKINS.size())
	var skin = SHIP_SKINS[Settings.ship_skin_index]
	if not ResourceLoader.exists(skin["path"]):
		return
	var tex = load(skin["path"])
	if tex == null:
		return
	ship_preview.texture = tex
	ship_preview.scale = skin["scale"]

func update_laser_preview() -> void:
	if laser_preview == null:
		return
	Settings.laser_skin_index = wrapi(Settings.laser_skin_index, 0, LASER_SKINS.size())
	var skin = LASER_SKINS[Settings.laser_skin_index]
	if not ResourceLoader.exists(skin["path"]):
		return
	var tex = load(skin["path"])
	if tex == null:
		return
	laser_preview.texture = tex
	laser_preview.scale = skin["scale"]

func _on_speed_controle_pressed() -> void:
	is_listening_for_speed_key = true
	speed_control_btn.text = "Appuyez sur une touche..."

func _on_right_control_pressed() -> void:
	is_listening_for_right_key = true
	right_control_btn.text = "Appuyez sur une touche..."

func _on_left_control_pressed() -> void:
	is_listening_for_left_key = true
	left_control_btn.text = "Appuyez sur une touche..."

func _on_shoot_control_pressed() -> void:
	is_listening_for_shoot_key = true
	shoot_control_btn.text = "Appuyez sur une touche..."

func _on_pause_control_pressed() -> void:
	is_listening_for_pause_key = true
	pause_control_btn.text = "Appuyez sur une touche..."

# Godot lit cette fonction automatiquement à chaque fois qu'une touche ou un clic est détecté
func _input(event: InputEvent) -> void:
	if is_listening_for_speed_key and event is InputEventKey and event.pressed:
		Settings.keys["accelerer"] = event.keycode
		speed_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_speed_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche("accelerer")
		
	if is_listening_for_right_key and event is InputEventKey and event.pressed:
		Settings.keys["droite"] = event.keycode
		right_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_right_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche("droite")
		
	if is_listening_for_left_key and event is InputEventKey and event.pressed:
		Settings.keys["gauche"] = event.keycode
		left_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_left_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche("gauche")
		
	if is_listening_for_shoot_key and event is InputEventKey and event.pressed:
		Settings.keys["tirer"] = event.keycode
		shoot_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_shoot_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche("tirer")
		
	if is_listening_for_pause_key and event is InputEventKey and event.pressed:
		Settings.keys["pause"] = event.keycode
		pause_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_pause_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche("pause")

# ----- Onglets -----
func _on_AudioButton_pressed() -> void:
	show_panel("audio")

func _on_VideoButton_pressed() -> void:
	show_panel("video")

func _on_ControlButton_pressed() -> void:
	show_panel("controle")

func _on_JoueurButton_pressed() -> void:
	show_panel("joueur")

# ----- Choix skin vaisseau/laser -----
func _on_ChoixGaucheVais_pressed() -> void:
	Settings.ship_skin_index -= 1
	update_ship_preview()

func _on_ChoixDroiteVaiss_pressed() -> void:
	Settings.ship_skin_index += 1
	update_ship_preview()

func _on_ChoixGaucheLaz_pressed() -> void:
	Settings.laser_skin_index -= 1
	update_laser_preview()

func _on_ChoixDroiteLazer_pressed() -> void:
	Settings.laser_skin_index += 1
	update_laser_preview()

# ----- Boutons globaux -----
func _on_SaveButton_pressed() -> void:
	read_ui_to_settings()
	if Settings.save_to_disk():
		get_tree().change_scene_to_file(BACK_SCENE)
	else:
		push_error("❌ Erreur: impossible de sauvegarder settings.cfg")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(BACK_SCENE)
