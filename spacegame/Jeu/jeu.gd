extends Node2D

var player_scene = preload("res://Jeu/Entity/Joueur/joueur.tscn")
var ennemi_scene = preload("res://Jeu/Entity/Ennemi/ennemi.tscn")

var ennemi : Ennemi = Ennemi.new()
var divisions : Array[Ennemi] = []
var ennemi_cooldown : float = -1.0
var ennemi_spawn_interval : float = 6.0

@export var min_music_pitch : float = 1.0
@export var max_music_pitch : float = 1.45

@onready var hud : HUD = $HUD
@onready var joueur : Joueur
@onready var music_player : AudioStreamPlayer = $MusicPlayer

var rng = RandomNumberGenerator.new()

var xSpawnPositonValues : Array[int] = [-390, 390]
var ySpawnPositonValues : Array[int] = [-290, 290]

# --- Score ---
var score : int = 0

# --- Boss periodique ---
@export var boss_every_n_spawns : int = 10
var spawn_count : int = 0

# --- Collectible spawn ---
var collectible_cooldown : float = 45.0
var collectible_timer : float = 0.0

# --- Cheat codes ---
const KONAMI_CODE := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
const GOD_CODE := [KEY_G, KEY_O, KEY_D]
const FUEL_CODE := [KEY_F, KEY_U, KEY_E, KEY_L]
const DARK_CODE := [KEY_D, KEY_A, KEY_R, KEY_K]
var cheat_buffer : Array[int] = []
const CHEAT_BUFFER_MAX := 10

# --- Pac-Man ---
var pacman_active := false
var pacman_id := 0

# --- Flashlight ---
var flashlight_mode := false
var canvas_modulate : CanvasModulate = null

# ==========================================================================
#  LIFECYCLE
# ==========================================================================

func _ready():
	generer_jeu()
	if joueur != null:
		joueur.hit_by_asteroid.connect(_on_vaisseau_hit_by_asteroid)
	if music_player != null and music_player.stream != null and not music_player.playing:
		music_player.play()
	apply_game_mode()
	hud.update_score(score)

func _process(delta: float) -> void:
	_update_ennemi_spawn(delta)
	_update_collectible_spawn(delta)
	_update_pause()
	_update_hud()

# ==========================================================================
#  FRAME UPDATES
# ==========================================================================

func _update_ennemi_spawn(delta: float) -> void:
	ennemi_cooldown -= delta
	if ennemi_cooldown < 0.0:
		ennemi_cooldown = ennemi_spawn_interval
		spawn_count += 1
		if boss_every_n_spawns > 0 and spawn_count % boss_every_n_spawns == 0:
			spawn_boss()
		else:
			var rx = rng.randf_range(-1.0, 1.0)
			var ry = rng.randf_range(-1.0, 1.0)
			add_ennemi_to_scene(rx, ry)

func _update_collectible_spawn(delta: float) -> void:
	collectible_timer -= delta
	if collectible_timer < 0.0:
		collectible_timer = collectible_cooldown + rng.randf_range(-3.0, 5.0)
		var col = Collectible.create_random(800.0, 600.0)
		call_deferred("add_child", col)

func _update_pause() -> void:
	if Input.is_action_pressed("pause"):
		hud.display_pause_menu()

func _update_hud() -> void:
	if joueur == null or not is_instance_valid(joueur):
		return
	var fuel_percent := joueur.get_fuel_percent()
	hud.update_fuel(fuel_percent)
	if music_player != null:
		music_player.pitch_scale = lerp(max_music_pitch, min_music_pitch, fuel_percent)

# ==========================================================================
#  GAME GENERATION
# ==========================================================================

func generer_jeu():
	var config = ConfigFile.new()
	var err = config.load("res://Jeu/jeu.cfg")
	if err != OK: return

	# Background is set in jeu.tscn (earth animation). Don't reload from directory
	# because the Backgrounds/ folder also contains Fond_shooter.png now.

	var music_path : String = config.get_value("JEU", "Music", "")
	if music_path != "" and ResourceLoader.exists(music_path):
		set_music(music_path)

	joueur = player_scene.instantiate()
	var joueurScaleValue : float = config.get_value("JOUEUR", "Scale", 0.0)
	joueur.spriteScale = Vector2(joueurScaleValue, joueurScaleValue)
	joueur.widthColissionShape = config.get_value("JOUEUR", "WidthColissionShape", 0.0)
	joueur.heightColissionShape = config.get_value("JOUEUR", "HeightColissionShape", 0.0)
	joueur.positionXColissionShape = config.get_value("JOUEUR", "PositionXColissionShape", 0.0)
	joueur.positionYColissionShape = config.get_value("JOUEUR", "PositionYColissionShape", 0.0)
	joueur.speed = config.get_value("JOUEUR", "Speed", 0.0)
	joueur.torque = config.get_value("JOUEUR", "Torque", 0.0)
	var markerPositionX : float = config.get_value("JOUEUR", "MarkerPositionX", 0.0)
	var markerPositionY : float = config.get_value("JOUEUR", "MarkerPositionY", 0.0)
	joueur.markerPosition = Vector2(markerPositionX, markerPositionY)

	var path_player_sprites : String = config.get_value("JOUEUR", "DefaultSprites", "")
	if path_player_sprites != "" and DirAccess.dir_exists_absolute(path_player_sprites):
		joueur.set_stop_animation(path_player_sprites)

	var path_moving_player_sprites : String = config.get_value("JOUEUR", "MovingSprites", "")
	if path_moving_player_sprites != "" and DirAccess.dir_exists_absolute(path_moving_player_sprites):
		joueur.set_moving_animation(path_moving_player_sprites)

	add_child(joueur)

	_parse_enemy_subdivisions(config)

func _parse_enemy_subdivisions(config: ConfigFile) -> void:
	var toHandle : Array[String] = []
	var subDivision : String = config.get_value("ENNEMI", "SubDivison", "")
	while subDivision != "":
		toHandle.push_back(subDivision)
		subDivision = config.get_value(subDivision, "SubDivison", "")

	while toHandle.size() != 0:
		var divisionToHandel = toHandle.pop_back()
		var subDivisionEnnemi : Ennemi = Ennemi.new()
		subDivisionEnnemi.spriteTexture = config.get_value(divisionToHandel, "SpriteTexture", "")
		var subDivisionEnnemiScaleValue : float = config.get_value(divisionToHandel, "Scale", 0.0)
		subDivisionEnnemi.spriteScale = Vector2(subDivisionEnnemiScaleValue, subDivisionEnnemiScaleValue)
		subDivisionEnnemi.widthColissionShape = config.get_value(divisionToHandel, "WidthColissionShape", 0.0)
		subDivisionEnnemi.heightColissionShape = config.get_value(divisionToHandel, "HeightColissionShape", 0.0)
		subDivisionEnnemi.positionXColissionShape = config.get_value(divisionToHandel, "PositionXColissionShape", 0.0)
		subDivisionEnnemi.positionYColissionShape = config.get_value(divisionToHandel, "PositionYColissionShape", 0.0)

		if divisions.size() > 0:
			subDivisionEnnemi.subDivisions = divisions
			divisions = []

		var nombre : int = config.get_value(divisionToHandel, "Number", 0)
		for i in range(nombre):
			divisions.push_back(subDivisionEnnemi.cloneDeep())

	ennemi.spriteTexture = config.get_value("ENNEMI", "SpriteTexture", "")
	var ennemiScaleValue : float = config.get_value("ENNEMI", "Scale", 0.0)
	ennemi.spriteScale = Vector2(ennemiScaleValue, ennemiScaleValue)
	ennemi.widthColissionShape = config.get_value("ENNEMI", "WidthColissionShape", 0.0)
	ennemi.heightColissionShape = config.get_value("ENNEMI", "HeightColissionShape", 0.0)
	ennemi.positionXColissionShape = config.get_value("ENNEMI", "PositionXColissionShape", 0.0)
	ennemi.positionYColissionShape = config.get_value("ENNEMI", "PositionYColissionShape", 0.0)
	ennemi.velocity = config.get_value("ENNEMI", "Speed", 0.0)
	ennemi.speed = Vector2.UP * ennemi.velocity

# ==========================================================================
#  GAME MODES
# ==========================================================================

func apply_game_mode() -> void:
	match Settings.game_mode:
		1: # Boss Rush
			boss_every_n_spawns = 3
			ennemi_spawn_interval = 3.0
			ennemi_cooldown = 1.0
		2: # Shooter
			_setup_shooter_mode()

func _setup_shooter_mode() -> void:
	# Enemy: plante carnivore (no subdivisions)
	ennemi.spriteTexture = "res://Ressources/Enemies/plante carnivore.png"
	ennemi.spriteScale = Vector2(0.06, 0.06)
	ennemi.positionXColissionShape = 1.0
	ennemi.positionYColissionShape = 3.0
	ennemi.widthColissionShape = 54.0
	ennemi.heightColissionShape = 107.0
	divisions = []
	ennemi_spawn_interval = 5.0
	# Background
	_set_background_static("res://Ressources/Backgrounds/Fond_shooter.png")
	# Player: reversed direction, no glide, shooter sprite
	_override_player_sprite("res://Ressources/Vaisseau/Sprite_player.png")
	if joueur:
		joueur.reverse_direction = true
		joueur.linear_damp = 5.0
		# Move the laser spawn point to the "front" (reversed direction)
		var marker = joueur.get_node_or_null("Marker2D")
		if marker:
			marker.position.y = abs(joueur.markerPosition.y)
	# Music
	var shooter_music := "res://Ressources/Musiques/Shooter.mp3"
	if ResourceLoader.exists(shooter_music):
		set_music(shooter_music)
		if music_player != null:
			music_player.play()

func _set_background_static(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex : Texture2D = load(path)
	var sf = SpriteFrames.new()
	sf.add_frame("default", tex)
	sf.set_animation_loop("default", false)
	$Background.sprite_frames = sf
	$Background.play("default")
	# Scale to fill the 800x600 game area
	var tex_size := tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var scale_x := 800.0 / tex_size.x
		var scale_y := 600.0 / tex_size.y
		var s: float = max(scale_x, scale_y)
		$Background.scale = Vector2(s, s)

func _override_player_sprite(path: String) -> void:
	if joueur == null or not ResourceLoader.exists(path):
		return
	var tex = load(path)
	if tex == null:
		return
	var sf = SpriteFrames.new()
	sf.add_animation("stop")
	sf.add_frame("stop", tex)
	sf.set_animation_loop("stop", true)
	sf.add_animation("mouvement")
	sf.add_frame("mouvement", tex)
	sf.set_animation_loop("mouvement", true)
	var sprite = joueur.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.sprite_frames = sf
		sprite.scale = Vector2(0.15, 0.15)
		sprite.play("stop")

# ==========================================================================
#  ENEMY SPAWNING
# ==========================================================================

func add_ennemi_to_scene(changeXSpeedFactor : float, changeYSpeedFactor : float) :
	var new_ennemi = ennemi_scene.instantiate()
	new_ennemi.spriteTexture = ennemi.spriteTexture
	new_ennemi.spriteScale = ennemi.spriteScale
	new_ennemi.widthColissionShape = ennemi.widthColissionShape
	new_ennemi.heightColissionShape = ennemi.heightColissionShape
	new_ennemi.positionXColissionShape = ennemi.positionXColissionShape
	new_ennemi.positionYColissionShape = ennemi.positionYColissionShape
	new_ennemi.speed = Vector2(changeXSpeedFactor * ennemi.velocity, changeYSpeedFactor * ennemi.velocity)

	if divisions.size() > 0:
		new_ennemi.subDivisions = divisions.duplicate(true)

	new_ennemi.transform.origin = Vector2(xSpawnPositonValues.pick_random(), ySpawnPositonValues.pick_random())
	call_deferred("add_child", new_ennemi)

func spawn_asteroids_from_bonus(count: int) -> void:
	for i in range(count):
		var rx = rng.randf_range(-1.0, 1.0)
		var ry = rng.randf_range(-1.0, 1.0)
		add_ennemi_to_scene(rx, ry)

func spawn_boss() -> void:
	var boss = ennemi_scene.instantiate()
	boss.spriteTexture = ennemi.spriteTexture
	boss.spriteScale = ennemi.spriteScale * 3.0
	boss.widthColissionShape = ennemi.widthColissionShape * 3.0
	boss.heightColissionShape = ennemi.heightColissionShape * 3.0
	boss.hit_points = 5
	var rx = rng.randf_range(-1.0, 1.0)
	var ry = rng.randf_range(-1.0, 1.0)
	boss.speed = Vector2(rx * ennemi.velocity * 0.5, ry * ennemi.velocity * 0.5)
	if divisions.size() > 0:
		boss.subDivisions = divisions.duplicate(true)
	boss.transform.origin = Vector2(xSpawnPositonValues.pick_random(), ySpawnPositonValues.pick_random())
	boss.modulate = Color(1.0, 0.4, 0.4, 1.0)
	call_deferred("add_child", boss)

# ==========================================================================
#  SCORE
# ==========================================================================

func on_enemy_killed() -> void:
	score += 10
	hud.update_score(score)

# ==========================================================================
#  NOTIFICATIONS (bonus, collectibles)
# ==========================================================================

func show_bonus_notification(text: String) -> void:
	hud.show_bonus_text(text)

# ==========================================================================
#  VISUALS / AUDIO
# ==========================================================================

func set_background_animation(background_sprite_frames_directory : String) -> void :
	background_sprite_frames_directory = background_sprite_frames_directory.trim_suffix("/")
	var files := DirAccess.get_files_at(background_sprite_frames_directory)
	if files != null and not files.is_empty():
		var background_sprite_frames : SpriteFrames = SpriteFrames.new()
		for file in files:
			if not file.contains(".import"):
				background_sprite_frames.add_frame("default", load(background_sprite_frames_directory + "/" + file))
		background_sprite_frames.set_animation_loop("default", true)
		$Background.sprite_frames = background_sprite_frames
		$Background.play("default")

func set_music(music_path : String) -> void :
	$MusicPlayer.stream = load(music_path)
	$MusicPlayer.volume_db = (Settings.volume / 2) - 50

# ==========================================================================
#  HIT / GAME OVER
# ==========================================================================

func _on_vaisseau_hit_by_asteroid(ship_global_position: Vector2, lives_remaining: int) -> void:
	hud.play_hit_effect(_to_screen_position(ship_global_position), lives_remaining)

func _to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform * world_position

func end_game() :
	hud.display_lose_menu()

# ==========================================================================
#  TORE WORLD
# ==========================================================================

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is ToreWorldBody:
		body.toreWorlBehaviour($Area2D/CollisionShape2D.shape.get_rect().size)

# ==========================================================================
#  PAC-MAN MODE
# ==========================================================================

func set_pacman_mode(duration: float) -> void:
	pacman_id += 1
	var my_id = pacman_id
	pacman_active = true
	for child in get_children():
		if child is Ennemi:
			child.linear_velocity = -child.linear_velocity
			child.modulate = Color(0.3, 0.3, 1.0, 0.7)
	await get_tree().create_timer(duration).timeout
	if my_id == pacman_id:
		pacman_active = false
		for child in get_children():
			if child is Ennemi:
				child.modulate = Color(1.0, 1.0, 1.0, 1.0)

# ==========================================================================
#  SCREAMER
# ==========================================================================

func show_screamer(duration: float) -> void:
	var screamer_layer := CanvasLayer.new()
	screamer_layer.layer = 100
	add_child(screamer_layer)

	var screamer_img_path := "res://Jeu/Bonus/Screamer.png"
	if ResourceLoader.exists(screamer_img_path):
		var tex : Texture2D = load(screamer_img_path)
		var rect := TextureRect.new()
		rect.texture = tex
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		screamer_layer.add_child(rect)

	var screamer_audio_path := "res://Jeu/Bonus/screamer.mp3"
	# Fallback paths
	if not ResourceLoader.exists(screamer_audio_path):
		screamer_audio_path = "res://Ressources/Bonus/screamer.mp3"
	if ResourceLoader.exists(screamer_audio_path):
		var player := AudioStreamPlayer.new()
		player.stream = load(screamer_audio_path)
		player.volume_db = 10.0
		screamer_layer.add_child(player)
		player.play()

	await get_tree().create_timer(duration).timeout
	screamer_layer.queue_free()

# ==========================================================================
#  CHEAT CODES
# ==========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	cheat_buffer.append(event.keycode)
	if cheat_buffer.size() > CHEAT_BUFFER_MAX:
		cheat_buffer = cheat_buffer.slice(cheat_buffer.size() - CHEAT_BUFFER_MAX)
	check_cheat_codes()

func check_cheat_codes() -> void:
	if buffer_ends_with(KONAMI_CODE):
		cheat_buffer.clear()
		_activate_konami()
	elif buffer_ends_with(GOD_CODE):
		cheat_buffer.clear()
		_activate_god_mode()
	elif buffer_ends_with(FUEL_CODE):
		cheat_buffer.clear()
		_activate_fuel_cheat()
	elif buffer_ends_with(DARK_CODE):
		cheat_buffer.clear()
		toggle_flashlight_mode()

func buffer_ends_with(code: Array) -> bool:
	if cheat_buffer.size() < code.size():
		return false
	var start = cheat_buffer.size() - code.size()
	for i in range(code.size()):
		if cheat_buffer[start + i] != code[i]:
			return false
	return true

func _activate_konami() -> void:
	if joueur == null or not is_instance_valid(joueur):
		return
	joueur.activate_super_6(15.0, 600.0, 0.5)

func _activate_god_mode() -> void:
	if joueur == null or not is_instance_valid(joueur):
		return
	joueur.set_shield(60.0)

func _activate_fuel_cheat() -> void:
	if joueur == null or not is_instance_valid(joueur):
		return
	joueur.fuel = joueur.max_fuel

# ==========================================================================
#  FLASHLIGHT MODE
# ==========================================================================

func toggle_flashlight_mode() -> void:
	flashlight_mode = not flashlight_mode
	if flashlight_mode:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.color = Color(0.05, 0.05, 0.08, 1.0)
		add_child(canvas_modulate)
		if joueur != null and is_instance_valid(joueur):
			joueur.enable_flashlight()
	else:
		if canvas_modulate != null:
			canvas_modulate.queue_free()
			canvas_modulate = null
		if joueur != null and is_instance_valid(joueur):
			joueur.disable_flashlight()
