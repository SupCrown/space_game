extends Control

@onready var volume_slider: Slider = $%MenuAudio/VolumeSlider
@onready var resolution_option: OptionButton = $%MenuVideo/ChoixOption
@onready var speed_control_btn: Button = $%MenuControle/SpeedControleKey
var is_listening_for_speed_key: bool = false

const BACK_SCENE := "res://Menu/Systeme_Sol.tscn"

func _ready() -> void:
	Settings.load_from_disk()
	apply_settings_to_ui()


func apply_settings_to_ui() -> void:
	if volume_slider == null or resolution_option == null or speed_control_btn == null :
		push_error("❌ Node UI introuvable: vérifie PanelCon/VolumeSlider, PanelCon/ChoixOption, PanelCon/SpeedControle")
		return

	volume_slider.value = Settings.volume
	resolution_option.selected = Settings.resolution_index
	speed_control_btn.text = OS.get_keycode_string(Settings.speed_key)
	$%MenuAudio.visible = true
	$%MenuVideo.visible = false
	$%MenuControle.visible = false
	

func read_ui_to_settings() -> void:
	Settings.volume = float(volume_slider.value)
	Settings.resolution_index = int(resolution_option.selected)
	#Settings.speed = float(speed_control.value)
	
	# Quand le joueur clique sur le bouton pour changer la touche
func _on_speed_controle_pressed() -> void:
	is_listening_for_speed_key = true
	speed_control_btn.text = "Appuyez sur une touche..."

# Godot lit cette fonction automatiquement à chaque fois qu'une touche ou un clic est détecté
func _input(event: InputEvent) -> void:
	if is_listening_for_speed_key and event is InputEventKey and event.pressed:
		Settings.speed_key = event.keycode
		speed_control_btn.text = OS.get_keycode_string(event.keycode)
		is_listening_for_speed_key = false
		get_viewport().set_input_as_handled()
		
		# ---> LA NOUVEAUTÉ EST ICI <---
		# On dit au jeu de mettre à jour ses contrôles immédiatement
		Settings.appliquer_touche_acceleration()

# ----- Onglets (si tu veux juste afficher/cacher des groupes, tu peux ajouter après) -----
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

# ----- Boutons globaux -----
func _on_SaveButton_pressed() -> void:
	read_ui_to_settings()
	if Settings.save_to_disk():
		get_tree().change_scene_to_file(BACK_SCENE)
	else:
		push_error("❌ Erreur: impossible de sauvegarder settings.cfg")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(BACK_SCENE)
