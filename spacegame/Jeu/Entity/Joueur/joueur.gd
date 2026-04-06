extends Entity
class_name Joueur

@export var markerPosition : Vector2
@export var speed : float
@export var torque : float

signal hit_by_asteroid(ship_global_position: Vector2, lives_remaining: int)

var laser_scene = preload("res://Jeu/Laser/laser.tscn")
@export var max_fuel : float = 100.0
@export var fuel_consumption_per_second : float = 10.0
@export var max_lives : int = 3
@export var invincibility_duration : float = 2.0
var fuel : float = max_fuel
var lives : int = max_lives
var invincible : bool = false
var _invincible_remaining : float = 0.0
var _blink_accum : float = 0.0

# --- Bonus/Malus state ---
var base_speed : float = 0.0
var current_speed : float = 0.0
var normal_shoot_cooldown : float = 0.2
var slow_shoot_cooldown : float = 0.6
var shoot_cooldown : float = 0.2
var can_shoot : bool = true

var triple_laser : bool = false
var auto_fire : bool = false
var powerful_laser : bool = false
var crazy_rotation : bool = false
var randomized_controls : bool = false
var crazy_rotation_force : float = 250.0
var hyper_speed : bool = false
var glue_active : bool = false
var base_torque : float = 0.0
var shield_bonus_id : int = 0
var glue_bonus_id : int = 0
var hyper_speed_bonus_id : int = 0
var flashlight_active : bool = false
var flashlight_node : PointLight2D = null
var reverse_direction : bool = false

# Bumper IDs pour annuler les effets concurrents d'un meme type
var speed_bonus_id : int = 0
var laser_bonus_id : int = 0
var laser_power_bonus_id : int = 0
var slow_motion_bonus_id : int = 0
var auto_fire_bonus_id : int = 0
var fire_rate_bonus_id : int = 0
var crazy_rotation_bonus_id : int = 0
var random_controls_bonus_id : int = 0

var control_map := {
	"accelerer": "accelerer",
	"droite": "droite",
	"gauche": "gauche"
}

const SHIP_SKINS := [
	{ "frames": "res://Ressources/Vaisseau/ship_sprite_frames_1.tres", "scale": Vector2(0.2, 0.2) },
	{ "frames": "res://Ressources/Vaisseau/ship_sprite_frames_2.tres", "scale": Vector2(0.15, 0.15) },
	{ "frames": "res://Ressources/Vaisseau/ship_sprite_frames_3.tres", "scale": Vector2(0.15, 0.15) }
]

func _ready() -> void:
	super()
	$Marker2D.position = markerPosition
	add_to_group("player")
	base_speed = speed
	current_speed = base_speed
	base_torque = torque
	shoot_cooldown = normal_shoot_cooldown
	apply_ship_skin_if_needed()
	$AnimatedSprite2D.play("default")

func apply_ship_skin_if_needed() -> void:
	# Ne rien faire si Settings.ship_skin_index n'existe pas ou si le .tres est absent.
	# Permet de garder la retro-compatibilite avec jeu.cfg.
	if not ("ship_skin_index" in Settings):
		return
	var idx : int = Settings.ship_skin_index
	if idx < 0 or idx >= SHIP_SKINS.size():
		return
	var skin = SHIP_SKINS[idx]
	if not ResourceLoader.exists(skin["frames"]):
		return
	var frames : SpriteFrames = load(skin["frames"])
	if frames == null:
		return
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.scale = skin["scale"]

func _process(delta: float) -> void:
	handle_shoot()

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
	var accel_pressed = Input.is_action_pressed(get_action_for("accelerer"))
	var right_pressed = Input.is_action_pressed(get_action_for("droite"))
	var left_pressed = Input.is_action_pressed(get_action_for("gauche"))

	if accel_pressed:
		fuel = max(0.0, fuel - fuel_consumption_per_second * delta)

	var forward := transform.y if reverse_direction else -transform.y

	if hyper_speed:
		apply_force(forward * current_speed)
		$AnimatedSprite2D.play("mouvement")
	elif accel_pressed or right_pressed or left_pressed or crazy_rotation:
		$AnimatedSprite2D.play("mouvement")
		if accel_pressed:
			apply_force(forward * current_speed)
		if right_pressed:
			apply_torque(torque)
		if left_pressed:
			apply_torque(-torque)
	else:
		$AnimatedSprite2D.play("stop")

	if crazy_rotation:
		apply_torque(crazy_rotation_force)

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

func shoot() -> void:
	spawn_laser_at($Marker2D.global_position)
	if triple_laser:
		var offset_dir = transform.x  # perpendiculaire au sens du vaisseau
		spawn_laser_at($Marker2D.global_position + offset_dir * 20.0)
		spawn_laser_at($Marker2D.global_position - offset_dir * 20.0)

func spawn_laser_at(pos: Vector2) -> void:
	var laser : Laser = laser_scene.instantiate()
	laser.global_position = pos
	laser.direction = transform.y if reverse_direction else -transform.y
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

# --- Methodes d'effets bonus/malus ---

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

func set_slow_motion(duration: float, scale_value: float = 0.5) -> void:
	slow_motion_bonus_id += 1
	var my_id = slow_motion_bonus_id
	Engine.time_scale = scale_value
	print("BONUS ACTIVE : slow motion")
	# On multiplie la duree par l'inverse du scale pour compenser l'effet du time_scale sur le timer
	var real_duration = duration / scale_value if scale_value > 0.0 else duration
	await get_tree().create_timer(real_duration).timeout
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

func activate_super_6(duration: float, fast_speed_value: float, slow_motion_scale: float = 0.5) -> void:
	print("BONUS ACTIVE : SUPER 6")
	set_fast_mode(fast_speed_value, duration)
	add_extra_laser(duration)
	set_powerful_laser(duration)
	set_auto_fire(duration)
	set_slow_motion(duration, slow_motion_scale)

func set_slow_fire(duration: float, slow_cooldown: float = 0.6) -> void:
	fire_rate_bonus_id += 1
	var my_id = fire_rate_bonus_id
	slow_shoot_cooldown = slow_cooldown
	shoot_cooldown = slow_shoot_cooldown
	print("MALUS ACTIVE : tir lent")
	await get_tree().create_timer(duration).timeout
	if my_id == fire_rate_bonus_id:
		shoot_cooldown = normal_shoot_cooldown
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

func set_crazy_rotation(duration: float, force: float = 250.0) -> void:
	crazy_rotation_bonus_id += 1
	var my_id = crazy_rotation_bonus_id
	crazy_rotation = true
	crazy_rotation_force = force
	print("MALUS ACTIVE : rotation folle")
	await get_tree().create_timer(duration).timeout
	if my_id == crazy_rotation_bonus_id:
		crazy_rotation = false
		print("MALUS TERMINE : rotation normale")

func add_life() -> void:
	lives = min(lives + 1, max_lives)
	print("BONUS ACTIVE : +1 vie (", lives, "/", max_lives, ")")

func remove_life() -> void:
	if invincible:
		print("MALUS BLOQUE : joueur invincible")
		return
	lives = max(0, lives - 1)
	hit_by_asteroid.emit(global_position, lives)
	print("MALUS ACTIVE : -1 vie (", lives, "/", max_lives, ")")
	if lives <= 0:
		get_parent().end_game()
		call_deferred("queue_free")

func set_shield(duration: float) -> void:
	shield_bonus_id += 1
	var my_id = shield_bonus_id
	invincible = true
	_invincible_remaining = duration
	_blink_accum = 0.0
	# Teinte dorée pour distinguer le bouclier de l'invincibilité post-hit
	$AnimatedSprite2D.modulate = Color(1.0, 0.85, 0.3, 1.0)
	print("BONUS ACTIVE : bouclier")
	await get_tree().create_timer(duration).timeout
	if my_id == shield_bonus_id:
		$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
		# Ne pas désactiver invincibilité ici — le _process s'en charge via _invincible_remaining
		print("BONUS TERMINE : bouclier")

func set_glue(speed_value: float, torque_factor: float, duration: float) -> void:
	glue_bonus_id += 1
	var my_id = glue_bonus_id
	speed_bonus_id += 1
	current_speed = speed_value
	torque = base_torque * torque_factor
	glue_active = true
	print("MALUS ACTIVE : glue (vitesse=", speed_value, " torque=", torque, ")")
	await get_tree().create_timer(duration).timeout
	if my_id == glue_bonus_id:
		current_speed = base_speed
		torque = base_torque
		glue_active = false
		print("MALUS TERMINE : glue")

func set_hyper_speed(speed_value: float, duration: float) -> void:
	hyper_speed_bonus_id += 1
	var my_id = hyper_speed_bonus_id
	speed_bonus_id += 1
	hyper_speed = true
	current_speed = speed_value
	print("MALUS ACTIVE : hyper vitesse")
	await get_tree().create_timer(duration).timeout
	if my_id == hyper_speed_bonus_id:
		hyper_speed = false
		current_speed = base_speed
		print("MALUS TERMINE : hyper vitesse")

func trigger_screamer(duration: float) -> void:
	# Affiche une image plein ecran + joue un son effrayant
	var jeu = get_parent()
	if jeu != null and jeu.has_method("show_screamer"):
		jeu.show_screamer(duration)

func add_fuel(percent: float) -> void:
	fuel = min(fuel + max_fuel * percent, max_fuel)
	print("BONUS ACTIVE : +", int(percent * 100), "% carburant (", int(fuel), "/", int(max_fuel), ")")

func enable_flashlight() -> void:
	if flashlight_active:
		return
	flashlight_active = true
	# Creer un PointLight2D enfant du joueur
	flashlight_node = PointLight2D.new()
	flashlight_node.energy = 1.5
	flashlight_node.texture = _create_light_texture()
	flashlight_node.texture_scale = 4.0
	flashlight_node.shadow_enabled = true
	add_child(flashlight_node)
	print("FLASHLIGHT ACTIVE")

func disable_flashlight() -> void:
	if not flashlight_active:
		return
	flashlight_active = false
	if flashlight_node != null:
		flashlight_node.queue_free()
		flashlight_node = null
	print("FLASHLIGHT DESACTIVE")

func _create_light_texture() -> Texture2D:
	# Creer une texture de lumiere radiale proceduralement
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var center := Vector2(128, 128)
	for x in range(256):
		for y in range(256):
			var dist := Vector2(x, y).distance_to(center) / 128.0
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

# --- Animations depuis jeu.cfg (rétro-compat) ---

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
		get_parent().end_game()
		call_deferred("queue_free")
		return
	invincible = true
	_invincible_remaining = invincibility_duration
	_blink_accum = 0.0
