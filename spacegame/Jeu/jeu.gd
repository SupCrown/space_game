extends Node2D

var player_scene = preload("res://Jeu/Entity/Joueur/joueur.tscn")
var ennemi_scene = preload("res://Jeu/Entity/Ennemi/Asteroids/asteroids.tscn")

var ennemi : Ennemi = Ennemi.new()
var divisions : Array[Ennemi] = []
var ennemi_cooldown : float = -1.0

var rng = RandomNumberGenerator.new()
func _process(delta: float) -> void:
	ennemi_cooldown -= delta
	if (ennemi_cooldown < 0.0) :
		ennemi_cooldown = 4.0
		var randomNumerX = rng.randf_range(-1.0, 1.0)
		var randomNumerY = rng.randf_range(-1.0, 1.0)
		add_ennemi_to_scene(randomNumerX, randomNumerY)
	if Input.is_action_pressed("pause") : 
		$HUD.display_pause_menu()
		
func _ready():
	generer_jeu()

func generer_jeu():
	var config = ConfigFile.new()
	var err = config.load("res://Jeu/jeu.cfg")
	if err != OK: return
	
	var path_bg_sprites : String = config.get_value("JEU", "Background", "")
	if path_bg_sprites != "" and DirAccess.dir_exists_absolute(path_bg_sprites):
		set_background_animation(path_bg_sprites)
	
	var music_path : String = config.get_value("JEU", "Music", "")
	if music_path != "" and ResourceLoader.exists(music_path):
		set_music(music_path)
	
	var joueur : Joueur = player_scene.instantiate()
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
		
	add_child(joueur);

	var toHandle : Array[String] = []
	var subDivision : String = config.get_value("ENNEMI", "SubDivison", "")
	while subDivision != "" :
		toHandle.push_back(subDivision)
		subDivision = config.get_value(subDivision, "SubDivison", "")
	
	while toHandle.size() != 0 : 
		var divisionToHandel = toHandle.pop_back()
		var subDivisionEnnemi : Ennemi = Ennemi.new()
		subDivisionEnnemi.spriteTexture = config.get_value(divisionToHandel, "SpriteTexture", "")
		var subDivisionEnnemiScaleValue : float = config.get_value(divisionToHandel, "Scale", 0.0)
		subDivisionEnnemi.spriteScale = Vector2(subDivisionEnnemiScaleValue, subDivisionEnnemiScaleValue)
		subDivisionEnnemi.widthColissionShape = config.get_value(divisionToHandel, "WidthColissionShape", 0.0)
		subDivisionEnnemi.heightColissionShape = config.get_value(divisionToHandel, "HeightColissionShape", 0.0)
		subDivisionEnnemi.positionXColissionShape = config.get_value(divisionToHandel, "PositionXColissionShape", 0.0)
		subDivisionEnnemi.positionYColissionShape = config.get_value(divisionToHandel, "PositionYColissionShape", 0.0)
		
		if divisions.size() > 0 :
			subDivisionEnnemi.subDivisions = divisions
			divisions = []
		
		var nombre : int = config.get_value(divisionToHandel, "Number", 0)
		for i in range(nombre) :
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
	
func set_background_animation(background_sprite_frames_directory : String) -> void :
	background_sprite_frames_directory = background_sprite_frames_directory.trim_suffix("/")
	var files := DirAccess.get_files_at(background_sprite_frames_directory)
	
	if files != null && !files.is_empty() :
		var background_sprite_frames : SpriteFrames = SpriteFrames.new()
		for file in files:
			if (!file.contains(".import")) :
				background_sprite_frames.add_frame("default", load(background_sprite_frames_directory + "/" + file))
		background_sprite_frames.set_animation_loop("default", true)
		$Background.sprite_frames = background_sprite_frames
		$Background.play("default")

func set_music(music_path : String) -> void :
	$BackgourndMusic.stream = load(music_path)

func add_ennemi_to_scene(changeXSpeedFactor : float, changeYSpeedFactor : float) :
	var new_ennemi = ennemi_scene.instantiate()
	new_ennemi.spriteTexture = ennemi.spriteTexture
	new_ennemi.spriteScale = ennemi.spriteScale
	new_ennemi.widthColissionShape = ennemi.widthColissionShape
	new_ennemi.heightColissionShape = ennemi.heightColissionShape
	new_ennemi.positionXColissionShape = ennemi.positionXColissionShape
	new_ennemi.positionYColissionShape = ennemi.positionXColissionShape
	new_ennemi.speed = Vector2(changeXSpeedFactor * ennemi.velocity, changeYSpeedFactor * ennemi.velocity)

	if divisions.size() > 0 :
		new_ennemi.subDivisions = divisions.duplicate(true)
	
	new_ennemi.transform.origin = Vector2(-390.0, -290.0)
	
	call_deferred("add_child", new_ennemi)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is ToreWorldBody :
		body.toreWorlBehaviour($Area2D/CollisionShape2D.shape.get_rect().size)

func end_game() :
	$HUD.display_lose_menu()
