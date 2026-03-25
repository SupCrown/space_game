extends toreWorldBody
class_name Vaisseau

var laser_scene = preload("res://Laser/laser.tscn")

@export var base_speed: float = 300.0
@export var shoot_cooldown: float = 0.2
@export var slow_shoot_cooldown: float = 0.6
@export var crazy_rotation_force: float = 250.0
@export var rotation_torque: float = 100.0

var current_speed: float = base_speed
var can_shoot := true

var triple_laser := false
var auto_fire := false
var powerful_laser := false
var crazy_rotation := false
var randomized_controls := false

var speed_bonus_id := 0
var laser_bonus_id := 0
var laser_power_bonus_id := 0
var slow_motion_bonus_id := 0
var auto_fire_bonus_id := 0
var fire_rate_bonus_id := 0
var crazy_rotation_bonus_id := 0
var random_controls_bonus_id := 0

var control_map := {
	"accelerer": "accelerer",
	"droite": "droite",
	"gauche": "gauche"
}

func _ready() -> void:
	add_to_group("player")
	current_speed = base_speed

func _process(delta: float) -> void:
	handle_shoot()

func _physics_process(delta: float) -> void:
	handle_movement()
	handle_rotation()
	update_animation()

func handle_shoot() -> void:
	if not can_shoot:
		return

	if Input.is_action_pressed("tirer") or auto_fire:
		shoot()
		start_shoot_cooldown()

func start_shoot_cooldown() -> void:
	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func handle_movement() -> void:
	var accel_pressed = Input.is_action_pressed(get_action_for("accelerer"))

	if accel_pressed:
		apply_force(-transform.y * current_speed)

func handle_rotation() -> void:
	var right_pressed = Input.is_action_pressed(get_action_for("droite"))
	var left_pressed = Input.is_action_pressed(get_action_for("gauche"))

	if right_pressed:
		apply_torque(rotation_torque)

	if left_pressed:
		apply_torque(-rotation_torque)

	if crazy_rotation:
		apply_torque(crazy_rotation_force)

func update_animation() -> void:
	var accel_pressed = Input.is_action_pressed(get_action_for("accelerer"))
	var right_pressed = Input.is_action_pressed(get_action_for("droite"))
	var left_pressed = Input.is_action_pressed(get_action_for("gauche"))

	if accel_pressed or right_pressed or left_pressed or crazy_rotation:
		$Sprite2D.play("mouvement")
	else:
		$Sprite2D.play("stop")

func shoot() -> void:
	spawn_laser($LaserSpawnCenter)

	if triple_laser:
		spawn_laser($LaserSpawnLeft)
		spawn_laser($LaserSpawnRight)

func spawn_laser(marker: Marker2D) -> void:
	var laser: Laser = laser_scene.instantiate()
	laser.global_position = marker.global_position
	laser.direction = -transform.y
	laser.rotation = rotation
	laser.is_powerful = powerful_laser
	get_parent().add_child(laser)

func get_action_for(action_name: String) -> String:
	if randomized_controls and control_map.has(action_name):
		return control_map[action_name]
	return action_name

func randomize_controls() -> void:
	var actions = ["accelerer", "droite", "gauche"]
	var shuffled = actions.duplicate()
	shuffled.shuffle()

	control_map["accelerer"] = shuffled[0]
	control_map["droite"] = shuffled[1]
	control_map["gauche"] = shuffled[2]

	print("MALUS ACTIVE : controles randomises")
	print("accelerer -> ", control_map["accelerer"])
	print("droite -> ", control_map["droite"])
	print("gauche -> ", control_map["gauche"])

func reset_controls() -> void:
	control_map["accelerer"] = "accelerer"
	control_map["droite"] = "droite"
	control_map["gauche"] = "gauche"

func set_slow_mode(speed_value: float, duration: float) -> void:
	speed_bonus_id += 1
	var my_id = speed_bonus_id

	current_speed = speed_value
	print("MALUS ACTIVE : vitesse lente")

	await get_tree().create_timer(duration).timeout

	if my_id == speed_bonus_id:
		current_speed = base_speed
		print("MALUS TERMINE : vitesse normale")

func set_fast_mode(speed_value: float, duration: float) -> void:
	speed_bonus_id += 1
	var my_id = speed_bonus_id

	current_speed = speed_value
	print("BONUS ACTIVE : vitesse rapide")

	await get_tree().create_timer(duration).timeout

	if my_id == speed_bonus_id:
		current_speed = base_speed
		print("BONUS TERMINE : vitesse normale")

func add_extra_laser(duration: float) -> void:
	laser_bonus_id += 1
	var my_id = laser_bonus_id

	triple_laser = true
	print("BONUS ACTIVE : triple laser")

	await get_tree().create_timer(duration).timeout

	if my_id == laser_bonus_id:
		triple_laser = false
		print("BONUS TERMINE : tir normal")

func set_powerful_laser(duration: float) -> void:
	laser_power_bonus_id += 1
	var my_id = laser_power_bonus_id

	powerful_laser = true
	print("BONUS ACTIVE : laser puissant")

	await get_tree().create_timer(duration).timeout

	if my_id == laser_power_bonus_id:
		powerful_laser = false
		print("BONUS TERMINE : laser normal")

func set_slow_motion(duration: float) -> void:
	slow_motion_bonus_id += 1
	var my_id = slow_motion_bonus_id

	Engine.time_scale = 0.5
	print("BONUS ACTIVE : slow motion")

	await get_tree().create_timer(duration * 2.0).timeout

	if my_id == slow_motion_bonus_id:
		Engine.time_scale = 1.0
		print("BONUS TERMINE : vitesse normale")

func set_auto_fire(duration: float) -> void:
	auto_fire_bonus_id += 1
	var my_id = auto_fire_bonus_id

	auto_fire = true
	print("BONUS ACTIVE : tir automatique")

	await get_tree().create_timer(duration).timeout

	if my_id == auto_fire_bonus_id:
		auto_fire = false
		print("BONUS TERMINE : tir manuel")

func activate_super_6(duration: float, fast_speed_value: float) -> void:
	print("BONUS ACTIVE : SUPER 6")

	set_fast_mode(fast_speed_value, duration)
	add_extra_laser(duration)
	set_powerful_laser(duration)
	set_auto_fire(duration)
	set_slow_motion(duration)

func set_slow_fire(duration: float) -> void:
	fire_rate_bonus_id += 1
	var my_id = fire_rate_bonus_id

	shoot_cooldown = slow_shoot_cooldown
	print("MALUS ACTIVE : tir lent")

	await get_tree().create_timer(duration).timeout

	if my_id == fire_rate_bonus_id:
		shoot_cooldown = 0.2
		print("MALUS TERMINE : tir normal")

func set_random_controls(duration: float) -> void:
	random_controls_bonus_id += 1
	var my_id = random_controls_bonus_id

	randomized_controls = true
	randomize_controls()

	await get_tree().create_timer(duration).timeout

	if my_id == random_controls_bonus_id:
		randomized_controls = false
		reset_controls()
		print("MALUS TERMINE : controles normaux")

func set_crazy_rotation(duration: float) -> void:
	crazy_rotation_bonus_id += 1
	var my_id = crazy_rotation_bonus_id

	crazy_rotation = true
	print("MALUS ACTIVE : rotation folle")

	await get_tree().create_timer(duration).timeout

	if my_id == crazy_rotation_bonus_id:
		crazy_rotation = false
		print("MALUS TERMINE : rotation normale")
