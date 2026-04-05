extends MarginContainer
class_name Menu

func _ready() -> void:
	$DescriptionNiveau.hide()
	

func _on_option_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MenuOption/option_menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit() 

func add_planete(planete : Planet) -> void:
	var button = Button.new()
	button.text = planete.name
	button.pressed.connect(get_parent()._planet_button_pressed.bind(planete.name))
	
	var container = MarginContainer.new()
	container.add_child(button)
	
	$Planetes.add_child(container)
	
	
func display_level_desc(desc : String, planetName : String) -> void:
	$%Description.text = desc
	$%TargetPlanetName.text = planetName
	$DescriptionNiveau.show()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Jeu/jeu.tscn")
