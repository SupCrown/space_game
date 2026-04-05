extends MarginContainer

func display_pause_menu() :
	$PauseMenu.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	$PauseMenu.visible = false
	get_tree().paused = false

func display_lose_menu() :
	$LoseMenu.visible = true
	get_tree().paused = true

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Jeu/Menu/Systeme_Sol.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Jeu/jeu.tscn")
