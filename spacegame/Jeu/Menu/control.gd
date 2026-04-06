extends MarginContainer
class_name Menu

const COLLECTIBLE_TEXTURES := [
	"res://Ressources/Collectibles/Collectible_1.png",
	"res://Ressources/Collectibles/Collectible_2.png",
	"res://Ressources/Collectibles/Collectible_3.png",
	"res://Ressources/Collectibles/Collectible_4.png",
	"res://Ressources/Collectibles/Collectible_5.png",
	"res://Ressources/Collectibles/Collectible_6.png",
	"res://Ressources/Collectibles/Collectible_7.png",
]

const COLLECTIBLE_AUDIO := {
	4: "res://Ressources/Collectibles/Collectible_4_audio.mp3",
	7: "res://Ressources/Collectibles/Collectible_7_audio.mp3",
}

var _viewer_overlay : ColorRect = null
var _viewer_audio : AudioStreamPlayer = null

func _ready() -> void:
	$DescriptionNiveau.hide()
	Settings.load_from_disk()

func _on_option_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Jeu/MenuOption/option_menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func add_planete(planete : Planet) -> void:
	# --- EXCLUSION DU SOLEIL ---
	# On vérifie si le nom est "Sol" (en minuscules pour être sûr)
	if planete.name.to_lower() == "sol" or planete.name.to_lower() == "soleil":
		return # Stop ! On ne crée rien, on passe à la planète suivante
	# ---------------------------

	var button = Button.new()
	button.text = planete.name
	button.pressed.connect(get_parent()._planet_button_pressed.bind(planete.name))
	
	var container = MarginContainer.new()
	container.add_child(button)
	$Planetes.add_child(container)


func display_level_desc(desc : String, planetName : String) -> void:
	$%Description.text = desc
	$%TargetPlanetName.text = planetName
	
	print("Planète sélectionnée : ", planetName)

	# On gère les variantes pour être SUR que Piranha active le mode 1
	match planetName:
		"Sombreros":
			Settings.game_mode = 2
		"Planete Piranha": 
			Settings.game_mode = 1
		"Tequiland":
			Settings.game_mode = 0
		_:
			Settings.game_mode = 0
			
	$DescriptionNiveau.show()

# Le bouton Play lance juste le jeu avec le mode déjà choisi au-dessus
func _on_play_button_pressed() -> void:
	# On a supprimé ModeSelector, donc on retire les lignes qui l'utilisaient
	get_tree().change_scene_to_file("res://Jeu/jeu.tscn")

func _on_collection_button_pressed() -> void:
	_populate_collection_grid()
	$CollectionPanel.visible = true

func _on_close_collection_pressed() -> void:
	$CollectionPanel.visible = false

func _populate_collection_grid() -> void:
	var grid : GridContainer = $CollectionPanel/VBox/CollectionGrid
	for child in grid.get_children():
		child.queue_free()

	for i in range(COLLECTIBLE_TEXTURES.size()):
		var collectible_id := i + 1
		var path : String = COLLECTIBLE_TEXTURES[i]
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		if ResourceLoader.exists(path):
			btn.texture_normal = load(path)
		if Settings.has_collectible(collectible_id):
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.pressed.connect(_on_collectible_clicked.bind(collectible_id))
		else:
			btn.modulate = Color(0.15, 0.15, 0.15, 1.0)
			btn.disabled = true
		btn.tooltip_text = "Collectible #" + str(collectible_id)
		grid.add_child(btn)

func _on_collectible_clicked(collectible_id: int) -> void:
	_show_collectible_viewer(collectible_id)

func _show_collectible_viewer(collectible_id: int) -> void:
	_close_viewer()
	# Dark overlay
	_viewer_overlay = ColorRect.new()
	_viewer_overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	_viewer_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer_overlay.gui_input.connect(_on_viewer_input)
	add_child(_viewer_overlay)
	# Large image
	var idx := collectible_id - 1
	if idx >= 0 and idx < COLLECTIBLE_TEXTURES.size():
		var path : String = COLLECTIBLE_TEXTURES[idx]
		if ResourceLoader.exists(path):
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(path)
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.set_anchors_preset(Control.PRESET_CENTER)
			tex_rect.custom_minimum_size = Vector2(300, 300)
			tex_rect.offset_left = -150
			tex_rect.offset_top = -150
			tex_rect.offset_right = 150
			tex_rect.offset_bottom = 150
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_viewer_overlay.add_child(tex_rect)
	# Label
	var label := Label.new()
	label.text = "Collectible #" + str(collectible_id) + "\n(cliquer pour fermer)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -60
	label.offset_bottom = -20
	label.offset_left = -150
	label.offset_right = 150
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer_overlay.add_child(label)
	# Audio
	if COLLECTIBLE_AUDIO.has(collectible_id):
		var audio_path : String = COLLECTIBLE_AUDIO[collectible_id]
		if ResourceLoader.exists(audio_path):
			_viewer_audio = AudioStreamPlayer.new()
			_viewer_audio.stream = load(audio_path)
			_viewer_audio.volume_db = 5.0
			_viewer_overlay.add_child(_viewer_audio)
			_viewer_audio.play()

func _on_viewer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_viewer()

func _close_viewer() -> void:
	if _viewer_audio != null:
		_viewer_audio.stop()
		_viewer_audio = null
	if _viewer_overlay != null:
		_viewer_overlay.queue_free()
		_viewer_overlay = null
