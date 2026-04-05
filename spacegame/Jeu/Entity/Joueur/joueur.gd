extends Entity
class_name Joueur

@export var markerPosition : Vector2
@export var speed : float
@export var torque : float

signal hit_by_asteroid(ship_global_position: Vector2, lives_remaining: int)

var laser_scene = preload("res://Jeu/Laser/laser.tscn")
@export var max_fuel : float = 100.0
@export var fuel_consumption_per_second : float = 25.0
@export var max_lives : int = 3
@export var invincibility_duration : float = 2.0
var fuel : float = max_fuel
var lives : int = max_lives
var invincible : bool = false
var _invincible_remaining : float = 0.0
var _blink_accum : float = 0.0

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
	
	if invincible:
		_invincible_remaining -= delta
		_blink_accum += delta
		var visible_phase : bool = fmod(_blink_accum, 0.2) < 0.1
		$AnimatedSprite2D.modulate.a = 1.0 if visible_phase else 0.25
		if _invincible_remaining <= 0.0:
			invincible = false
			_blink_accum = 0.0
			$AnimatedSprite2D.modulate.a = 1.0
			
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("accelerer"):
		fuel = max(0.0, fuel - fuel_consumption_per_second * delta)
	
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

func kill() :
	get_parent().end_game()

func get_fuel_percent() -> float:
	if max_fuel <= 0.0:
		return 0.0
	return clamp(fuel / max_fuel, 0.0, 1.0)

func on_hit_by_asteroid() -> void:
	if invincible:
		return
	lives = max(0, lives - 1)
	hit_by_asteroid.emit(global_position, lives)
	if lives <= 0:
		call_deferred("queue_free")
		return
	invincible = true
	_invincible_remaining = invincibility_duration
	_blink_accum = 0.0
