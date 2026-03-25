extends Resource
class_name BonusConfig

enum SpawnMode {
	TIME,
	SCORE
}

@export_group("General")
@export var effect_duration: float = 5.0

@export_group("Player - Speed")
@export var enable_slow_speed: bool = true
@export var slow_speed_value: float = 120.0

@export var enable_fast_speed: bool = true
@export var fast_speed_value: float = 600.0

@export_group("Player - Shooting")
@export var enable_triple_laser: bool = true
@export var enable_powerful_laser: bool = true
@export var enable_auto_fire: bool = true

@export var enable_slow_fire: bool = true
@export var slow_fire_cooldown: float = 0.6

@export_group("Player - Controls")
@export var enable_random_controls: bool = true
@export var enable_crazy_rotation: bool = true
@export var crazy_rotation_force: float = 250.0

@export_group("World Effects")
@export var enable_slow_motion: bool = true
@export var slow_motion_scale: float = 0.5

@export_group("Asteroids")
@export var enable_asteroid_spawn: bool = true
@export var asteroid_spawn_count: int = 2

@export_group("Special Bonus")
@export var enable_super_6: bool = true
@export_range(0.0, 1.0) var super_6_chance: float = 0.05

@export_group("Bonus Movement")
@export var zone_width: float = 1000.0
@export var zone_height: float = 600.0
@export var bonus_min_speed: float = 150.0
@export var bonus_max_speed: float = 250.0

@export_group("Bonus Spawn")
@export var spawn_mode: SpawnMode = SpawnMode.TIME
@export_range(0.0, 1.0) var spawn_chance: float = 1.0
@export var max_bonus_on_screen: int = 3

@export_group("Bonus Spawn - Time")
@export var spawn_interval: float = 5.0
@export var use_random_time: bool = false
@export var min_spawn_time: float = 3.0
@export var max_spawn_time: float = 8.0

@export_group("Bonus Spawn - Score")
@export var points_between_spawn: int = 100
