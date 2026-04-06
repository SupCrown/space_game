extends ToreWorldBody
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
const BONUS_EXTRA_LIFE := 11
const BONUS_MINUS_LIFE := 12
const BONUS_SHIELD := 13
const BONUS_GLUE := 14
const BONUS_HYPER_SPEED := 15
const BONUS_SCREAMER := 16
const BONUS_JERRICAN := 17
const BONUS_PACMAN := 18

const BONUS_NAMES := {
	BONUS_SLOW: "Vaisseau lent",
	BONUS_FAST: "Vaisseau rapide",
	BONUS_TRIPLE_LASER: "Triple laser",
	BONUS_ASTEROID_SPAWN: "Pluie d'asteroides",
	BONUS_POWERFUL_LASER: "Laser puissant",
	BONUS_SLOW_MOTION: "Slow motion",
	BONUS_AUTO_FIRE: "Tir automatique",
	BONUS_SUPER_6: "SUPER 6",
	BONUS_SLOW_FIRE: "Tir lent",
	BONUS_RANDOM_CONTROLS: "Controles inverses",
	BONUS_CRAZY_ROTATION: "Rotation folle",
	BONUS_EXTRA_LIFE: "+1 Vie",
	BONUS_MINUS_LIFE: "-1 Vie",
	BONUS_SHIELD: "Bouclier",
	BONUS_GLUE: "Glue",
	BONUS_HYPER_SPEED: "Hyper Vitesse",
	BONUS_SCREAMER: "SCREAMER",
	BONUS_JERRICAN: "Carburant",
	BONUS_PACMAN: "Pac-Man",
}

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
			position = Vector2(-config.zone_width / 2.0 - 30.0, randf_range(-config.zone_height / 2.0, config.zone_height / 2.0))
			speed = Vector2(randf_range(config.bonus_min_speed, config.bonus_max_speed), randf_range(-80.0, 80.0))
		1:
			position = Vector2(config.zone_width / 2.0 + 30.0, randf_range(-config.zone_height / 2.0, config.zone_height / 2.0))
			speed = Vector2(randf_range(-config.bonus_max_speed, -config.bonus_min_speed), randf_range(-80.0, 80.0))
		2:
			position = Vector2(randf_range(-config.zone_width / 2.0, config.zone_width / 2.0), -config.zone_height / 2.0 - 30.0)
			speed = Vector2(randf_range(-80.0, 80.0), randf_range(config.bonus_min_speed, config.bonus_max_speed))
		3:
			position = Vector2(randf_range(-config.zone_width / 2.0, config.zone_width / 2.0), config.zone_height / 2.0 + 30.0)
			speed = Vector2(randf_range(-80.0, 80.0), randf_range(-config.bonus_max_speed, -config.bonus_min_speed))

func _physics_process(_delta: float) -> void:
	if not is_moving:
		apply_impulse(speed)
		is_moving = true

func impact_laser() -> void:
	if config == null:
		explode()
		return
	apply_bonus_to_player()
	explode()

func apply_bonus_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var applied := true
	match bonus_type:
		BONUS_SLOW:
			if config.enable_slow_speed:
				player.set_slow_mode(config.slow_speed_value, config.effect_duration)
			else: applied = false
		BONUS_FAST:
			if config.enable_fast_speed:
				player.set_fast_mode(config.fast_speed_value, config.effect_duration)
			else: applied = false
		BONUS_TRIPLE_LASER:
			if config.enable_triple_laser:
				player.add_extra_laser(config.effect_duration)
			else: applied = false
		BONUS_ASTEROID_SPAWN:
			if config.enable_asteroid_spawn:
				spawn_asteroids(config.asteroid_spawn_count)
			else: applied = false
		BONUS_POWERFUL_LASER:
			if config.enable_powerful_laser:
				player.set_powerful_laser(config.effect_duration)
			else: applied = false
		BONUS_SLOW_MOTION:
			if config.enable_slow_motion:
				player.set_slow_motion(config.effect_duration, config.slow_motion_scale)
			else: applied = false
		BONUS_AUTO_FIRE:
			if config.enable_auto_fire:
				player.set_auto_fire(config.effect_duration)
			else: applied = false
		BONUS_SUPER_6:
			if config.enable_super_6:
				player.activate_super_6(config.effect_duration, config.fast_speed_value, config.slow_motion_scale)
			else: applied = false
		BONUS_SLOW_FIRE:
			if config.enable_slow_fire:
				player.set_slow_fire(config.effect_duration, config.slow_fire_cooldown)
			else: applied = false
		BONUS_RANDOM_CONTROLS:
			if config.enable_random_controls:
				player.set_random_controls(config.effect_duration)
			else: applied = false
		BONUS_CRAZY_ROTATION:
			if config.enable_crazy_rotation:
				player.set_crazy_rotation(config.effect_duration, config.crazy_rotation_force)
			else: applied = false
		BONUS_EXTRA_LIFE:
			if config.enable_extra_life:
				player.add_life()
			else: applied = false
		BONUS_MINUS_LIFE:
			if config.enable_minus_life:
				player.remove_life()
			else: applied = false
		BONUS_SHIELD:
			if config.enable_shield:
				player.set_shield(config.shield_duration)
			else: applied = false
		BONUS_GLUE:
			if config.enable_glue:
				player.set_glue(config.glue_speed_value, config.glue_torque_factor, config.effect_duration)
			else: applied = false
		BONUS_HYPER_SPEED:
			if config.enable_hyper_speed:
				player.set_hyper_speed(config.hyper_speed_value, config.effect_duration)
			else: applied = false
		BONUS_SCREAMER:
			if config.enable_screamer:
				player.trigger_screamer(config.screamer_duration)
			else: applied = false
		BONUS_JERRICAN:
			if config.enable_jerrican:
				player.add_fuel(config.jerrican_fuel_percent)
			else: applied = false
		BONUS_PACMAN:
			if config.enable_pacman:
				activate_pacman_mode(config.pacman_duration)
			else: applied = false

	if applied:
		_notify_bonus(BONUS_NAMES.get(bonus_type, "???"))

func _notify_bonus(text: String) -> void:
	var parent = get_parent()
	if parent and parent.has_method("show_bonus_notification"):
		parent.show_bonus_notification(text)

func activate_pacman_mode(duration: float) -> void:
	var jeu = get_parent()
	if jeu != null and jeu.has_method("set_pacman_mode"):
		jeu.set_pacman_mode(duration)

func spawn_asteroids(count: int) -> void:
	var parent_node = get_parent()
	if parent_node and parent_node.has_method("spawn_asteroids_from_bonus"):
		parent_node.spawn_asteroids_from_bonus(count)

func choose_bonus_type() -> int:
	if config.enable_super_6 and randf() <= config.super_6_chance:
		return BONUS_SUPER_6

	var available_types: Array[int] = []

	if config.enable_slow_speed: available_types.append(BONUS_SLOW)
	if config.enable_fast_speed: available_types.append(BONUS_FAST)
	if config.enable_triple_laser: available_types.append(BONUS_TRIPLE_LASER)
	if config.enable_asteroid_spawn: available_types.append(BONUS_ASTEROID_SPAWN)
	if config.enable_powerful_laser: available_types.append(BONUS_POWERFUL_LASER)
	if config.enable_slow_motion: available_types.append(BONUS_SLOW_MOTION)
	if config.enable_auto_fire: available_types.append(BONUS_AUTO_FIRE)
	if config.enable_slow_fire: available_types.append(BONUS_SLOW_FIRE)
	if config.enable_random_controls: available_types.append(BONUS_RANDOM_CONTROLS)
	if config.enable_crazy_rotation: available_types.append(BONUS_CRAZY_ROTATION)
	if config.enable_extra_life: available_types.append(BONUS_EXTRA_LIFE)
	if config.enable_minus_life: available_types.append(BONUS_MINUS_LIFE)
	if config.enable_shield: available_types.append(BONUS_SHIELD)
	if config.enable_glue: available_types.append(BONUS_GLUE)
	if config.enable_hyper_speed: available_types.append(BONUS_HYPER_SPEED)
	if config.enable_screamer: available_types.append(BONUS_SCREAMER)
	if config.enable_pacman: available_types.append(BONUS_PACMAN)
	# Jerrican appears 3 times for higher probability
	if config.enable_jerrican:
		available_types.append(BONUS_JERRICAN)
		available_types.append(BONUS_JERRICAN)
		available_types.append(BONUS_JERRICAN)

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
