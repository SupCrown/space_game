extends ToreWorldBody
class_name Vaisseau

var laser_scene = preload("res://Jeu/Laser/laser.tscn")

func _process(delta: float) -> void:
	if Input.is_action_pressed("tirer"):
		var laser : Laser = laser_scene.instantiate();
		laser.global_position = $Marker2D.global_position
		laser.direction = -transform.y
		laser.rotation = rotation
		get_parent().add_child(laser)
		
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("accelerer") || Input.is_action_pressed("droite") || Input.is_action_pressed("gauche") :
		$Sprite2D.play("mouvement")
		if Input.is_action_pressed("accelerer"):
			apply_force(-transform.y * 250)
		if Input.is_action_pressed("droite") :
			apply_torque(100.0)
		if Input.is_action_pressed("gauche") :
			apply_torque(-100.0)
	else: 
		$Sprite2D.play("stop")
