extends toreWorldBody
class_name Bonus

const BONUS_SLOW := 0
const BONUS_FAST := 1
const BONUS_TRIPLE_LASER := 2
const BONUS_ASTEROID_SPAWN := 3
const BONUS_POWERFUL_LASER := 4
const BONUS_SLOW_MOTION := 5
const BONUS_AUTO_FIRE := 6
const BONUS_SUPER_6 := 7
const BONUS_SLOW_FIRE := 8
const BONUS_RANDOM_CONTROLS := 9
const BONUS_CRAZY_ROTATION := 10

var asteroid_scene = preload("res://Asteroids/asteroids.tscn")

var config: BonusConfig

@export var spriteScale: Vector2 = Vector2(0.1, 0.1)
@export var widthCollisionShape: float = 40.0
@export var heightCollisionShape: float = 40.0

var exploded := false
var is_moving := false
var speed: Vector2 = Vector2.ZERO
var bonus_type: int = BONUS_FAST

func _ready() -> void:
	randomize()

	if config == null:
		push_error("BonusConfig NON ASSIGNE dans Bonus !")
		return

	setup_body()
	setup_visuals()
	setup_collision()
	setup_spawn()

	bonus_type = choose_bonus_type()

	print("BONUS READY :", name, " type =", bonus_type, " position =", global_position)

func setup_body() -> void:
	contact_monitor = true
	max_contacts_reported = 10

func setup_visuals() -> void:
	$AnimatedSprite2D.scale = spriteScale
	$AnimatedSprite2D.play("bonus")

func setup_collision() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(widthCollisionShape, heightCollisionShape)
	$CollisionShape2D.shape = rect

func setup_spawn() -> void:
	var side := randi() % 4

	match side:
		0:
			position = Vector2(-30, randf_range(0, config.zone_height))
			speed = Vector2(
				randf_range(config.bonus_min_speed, config.bonus_max_speed),
				randf_range(-80.0, 80.0)
			)
		1:
			position = Vector2(config.zone_width + 30, randf_range(0, config.zone_height))
			speed = Vector2(
				randf_range(-config.bonus_max_speed, -config.bonus_min_speed),
				randf_range(-80.0, 80.0)
			)
		2:
			position = Vector2(randf_range(0, config.zone_width), -30)
			speed = Vector2(
				randf_range(-80.0, 80.0),
				randf_range(config.bonus_min_speed, config.bonus_max_speed)
			)
		3:
			position = Vector2(randf_range(0, config.zone_width), config.zone_height + 30)
			speed = Vector2(
				randf_range(-80.0, 80.0),
				randf_range(-config.bonus_max_speed, -config.bonus_min_speed)
			)

func _physics_process(delta: float) -> void:
	if not is_moving:
		apply_impulse(speed)
		is_moving = true

func impact_laser() -> void:
	if config == null:
		push_error("Impact laser sur Bonus sans config")
		explode()
		return

	apply_bonus_to_player()
	explode()

func apply_bonus_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("Aucun joueur trouve")
		return

	match bonus_type:
		BONUS_SLOW:
			if config.enable_slow_speed:
				print("MALUS OBTENU : Vaisseau lent")
				player.set_slow_mode(config.slow_speed_value, config.effect_duration)

		BONUS_FAST:
			if config.enable_fast_speed:
				print("BONUS OBTENU : Vaisseau rapide")
				player.set_fast_mode(config.fast_speed_value, config.effect_duration)

		BONUS_TRIPLE_LASER:
			if config.enable_triple_laser:
				print("BONUS OBTENU : Triple laser")
				player.add_extra_laser(config.effect_duration)

		BONUS_ASTEROID_SPAWN:
			if config.enable_asteroid_spawn:
				print("MALUS OBTENU :", config.asteroid_spawn_count, "asteroides")
				spawn_asteroids(config.asteroid_spawn_count)

		BONUS_POWERFUL_LASER:
			if config.enable_powerful_laser:
				print("BONUS OBTENU : Laser puissant")
				player.set_powerful_laser(config.effect_duration)

		BONUS_SLOW_MOTION:
			if config.enable_slow_motion:
				print("BONUS OBTENU : Slow motion")
				player.set_slow_motion(config.effect_duration)

		BONUS_AUTO_FIRE:
			if config.enable_auto_fire:
				print("BONUS OBTENU : Tir automatique")
				player.set_auto_fire(config.effect_duration)

		BONUS_SUPER_6:
			if config.enable_super_6:
				print("BONUS OBTENU : Super 6")
				player.activate_super_6(config.effect_duration, config.fast_speed_value)

		BONUS_SLOW_FIRE:
			if config.enable_slow_fire:
				print("MALUS OBTENU : Tir lent")
				player.set_slow_fire(config.effect_duration)

		BONUS_RANDOM_CONTROLS:
			if config.enable_random_controls:
				print("MALUS OBTENU : Controles randomises")
				player.set_random_controls(config.effect_duration)

		BONUS_CRAZY_ROTATION:
			if config.enable_crazy_rotation:
				print("MALUS OBTENU : Rotation folle")
				player.set_crazy_rotation(config.effect_duration)

func spawn_asteroids(count: int) -> void:
	var parent_node = get_parent()

	if parent_node == null:
		return

	for i in range(count):
		var asteroid: Asteroid = asteroid_scene.instantiate()
		setup_spawned_asteroid(asteroid)
		parent_node.call_deferred("add_child", asteroid)

func setup_spawned_asteroid(asteroid: Asteroid) -> void:
	var side := randi() % 4

	match side:
		0:
			asteroid.position = Vector2(-30, randf_range(0, config.zone_height))
			asteroid.speed = Vector2(
				randf_range(150.0, 250.0),
				randf_range(-80.0, 80.0)
			)
		1:
			asteroid.position = Vector2(config.zone_width + 30, randf_range(0, config.zone_height))
			asteroid.speed = Vector2(
				randf_range(-250.0, -150.0),
				randf_range(-80.0, 80.0)
			)
		2:
			asteroid.position = Vector2(randf_range(0, config.zone_width), -30)
			asteroid.speed = Vector2(
				randf_range(-80.0, 80.0),
				randf_range(150.0, 250.0)
			)
		3:
			asteroid.position = Vector2(randf_range(0, config.zone_width), config.zone_height + 30)
			asteroid.speed = Vector2(
				randf_range(-80.0, 80.0),
				randf_range(-250.0, -150.0)
			)

func choose_bonus_type() -> int:
	if config.enable_super_6 and randf() <= config.super_6_chance:
		return BONUS_SUPER_6

	var available_types: Array[int] = []

	if config.enable_slow_speed:
		available_types.append(BONUS_SLOW)
	if config.enable_fast_speed:
		available_types.append(BONUS_FAST)
	if config.enable_triple_laser:
		available_types.append(BONUS_TRIPLE_LASER)
	if config.enable_asteroid_spawn:
		available_types.append(BONUS_ASTEROID_SPAWN)
	if config.enable_powerful_laser:
		available_types.append(BONUS_POWERFUL_LASER)
	if config.enable_slow_motion:
		available_types.append(BONUS_SLOW_MOTION)
	if config.enable_auto_fire:
		available_types.append(BONUS_AUTO_FIRE)
	if config.enable_slow_fire:
		available_types.append(BONUS_SLOW_FIRE)
	if config.enable_random_controls:
		available_types.append(BONUS_RANDOM_CONTROLS)
	if config.enable_crazy_rotation:
		available_types.append(BONUS_CRAZY_ROTATION)

	if available_types.is_empty():
		return BONUS_FAST

	return available_types[randi() % available_types.size()]

func explode() -> void:
	if exploded:
		return

	exploded = true
	$CollisionShape2D.set_deferred("disabled", true)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	$AnimatedSprite2D.play("explosion")
	await get_tree().create_timer(0.2).timeout
	queue_free()
