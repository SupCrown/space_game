extends Entity
class_name Joueur

@export var markerPosition : Vector2
@export var speed : float
@export var torque : float

var laser_scene = preload("res://Jeu/Laser/laser.tscn")

func _ready() -> void:
	super()
	$Marker2D.position = markerPosition
	$AnimatedSprite2D.play("default")
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("tirer"):
		var laser : Laser = laser_scene.instantiate();
		laser.global_position = $Marker2D.global_position
		laser.direction = -transform.y
		laser.rotation = rotation
		get_parent().add_child(laser)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("accelerer") || Input.is_action_pressed("droite") || Input.is_action_pressed("gauche") :
		$AnimatedSprite2D.play("mouvement")
		if Input.is_action_pressed("accelerer"):
			apply_force(-transform.y * speed)
		if Input.is_action_pressed("droite") :
			apply_torque(torque)
		if Input.is_action_pressed("gauche") :
			apply_torque(-torque)
	else: 
		$AnimatedSprite2D.play("stop")

func set_stop_animation(sprite_frames_directory : String) :
	set_animation("stop", sprite_frames_directory)
	
func set_moving_animation(sprite_frames_directory : String) :
	set_animation("mouvement", sprite_frames_directory)

func set_animation(animation_name : String, sprite_frames_directory : String) : 
	sprite_frames_directory = sprite_frames_directory.trim_suffix("/")
	var files := DirAccess.get_files_at(sprite_frames_directory)
	
	if files != null && !files.is_empty() :
		$AnimatedSprite2D.sprite_frames.add_animation(animation_name)
		for file in files:
			if (!file.contains(".import")) :
				$AnimatedSprite2D.sprite_frames.add_frame(animation_name, load(sprite_frames_directory + "/" + file))
		$AnimatedSprite2D.sprite_frames.set_animation_loop(animation_name, true)
