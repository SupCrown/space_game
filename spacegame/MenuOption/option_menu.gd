extends Control

@onready var volume_slider: Slider = $%MenuAudio/VolumeSlider
@onready var resolution_option: OptionButton = $%MenuVideo/ChoixOption
@onready var speed_control_btn: Button = $%MenuControle/SpeedControleKey

@onready var ship_preview: Sprite2D = $%MenuJoueurVaisseau/Sprite2DVaisseauChoix
@onready var laser_preview: Sprite2D = $%MenuJoueurLazer/Sprite2DLazerChoix

var is_listening_for_speed_key: bool = false

const BACK_SCENE := "res://Menu/Systeme_Sol.tscn"

const SHIP_SKINS := [
	{ "path": "res://Ressources/Vaisseau/perseus_1.png", "scale": Vector2(0.3, 0.3) },
	{ "path": "res://Ressources/Vaisseau/spaceship.png", "scale": Vector2(0.12, 0.12) },
	{ "path": "res://Ressources/Vaisseau/ultraship.png", "scale": Vector2(0.3, 0.3) }
]

const LASER_SKINS := [
	{ "path": "res://Ressources/Laser/laz_3.png", "scale": Vector2(1.0, 1.0) },
	{ "path": "res://Ressources/Laser/lazer_type_2.png", "scale": Vector2(0.1, 0.2) },
	{ "path": "res://Ressources/Laser/lazer_type_3.jpeg", "scale": Vector2(0.2, 0.4) }
]

func _ready() -> void:
	Settings.load_from_disk()
	apply_settings_to_ui()
	update_ship_preview()
	update_laser_preview()

func apply_settings_to_ui() -> void:
	if volume_slider == null or resolution_option == null or speed_control_btn == null:
		push_error("Node UI introuvable")
		return

	volume_slider.value = Settings.volume
	resolution_option.selected = Settings.resolution_index
	speed_control_btn.text = OS.get_keycode_string(Settings.speed_key)

	$%MenuAudio.visible = true
	$%MenuVideo.visible = false
	$%MenuControle.visible = false
	$%MenuJoueurVaisseau.visible = false
	$%MenuJoueurLazer.visible = false

func read_ui_to_settings() -> void:
	Settings.volume = float(volume_slider.value)
	Settings.resolution_index = int(resolution_option.selected)

func update_ship_preview() -> void:
	if ship_preview == null:
		return

	Settings.ship_skin_index = wrapi(Settings.ship_skin_index, 0, SHIP_SKINS.size())

	var skin = SHIP_SKINS[Settings.ship_skin_index]
	var tex = load(skin["path"])

	if tex == null:
		push_error("Impossible de charger : " + skin["path"])
		return

	ship_preview.texture = tex
	ship_preview.scale = skin["scale"]

func update_laser_preview() -> void:
	if laser_preview == null:
		return

	Settings.laser_skin_index = wrapi(Settings.laser_skin_index, 0, LASER_SKINS.size())

	var skin = LASER_SKINS[Settings.laser_skin_index]
	var tex = load(skin["path"])

	if tex == null:
		push_error("Impossible de charger : " + skin["path"])
		return

	laser_preview.texture = tex
	laser_preview.scale = skin["scale"]

func _on_speed_controle_pressed() -> void:
	is_listening_for_speed_key = true
	speed_control_btn.text = "Appuyez sur une touche..."

func _input(event: InputEvent) -> void:
	if is_listening_for_speed_key and event is InputEventKey and event.pressed:
		Settings.speed_key = event.keycode
		speed_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_speed_key = false
		get_viewport().set_input_as_handled()
		Settings.appliquer_touche_acceleration()

func _on_AudioButton_pressed() -> void:
	$%MenuAudio.visible = true
	$%MenuVideo.visible = false
	$%MenuControle.visible = false
	$%MenuJoueurVaisseau.visible = false
	$%MenuJoueurLazer.visible = false

func _on_VideoButton_pressed() -> void:
	$%MenuAudio.visible = false
	$%MenuVideo.visible = true
	$%MenuControle.visible = false
	$%MenuJoueurVaisseau.visible = false
	$%MenuJoueurLazer.visible = false

func _on_ControlButton_pressed() -> void:
	$%MenuAudio.visible = false
	$%MenuVideo.visible = false
	$%MenuControle.visible = true
	$%MenuJoueurVaisseau.visible = false
	$%MenuJoueurLazer.visible = false

func _on_JoueurButton_pressed() -> void:
	$%MenuAudio.visible = false
	$%MenuVideo.visible = false
	$%MenuControle.visible = false
	$%MenuJoueurVaisseau.visible = true
	$%MenuJoueurLazer.visible = true

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

func _on_SaveButton_pressed() -> void:
	read_ui_to_settings()
	if Settings.save_to_disk():
		get_tree().change_scene_to_file(BACK_SCENE)
	else:
		push_error("Impossible de sauvegarder settings.cfg")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(BACK_SCENE)
