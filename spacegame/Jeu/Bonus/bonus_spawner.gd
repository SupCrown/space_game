extends Node
class_name BonusSpawner

var bonus_scene = preload("res://Jeu/Bonus/bonus.tscn")

@export var config: BonusConfig
@export var spawn_parent: NodePath

var score := 0
var last_spawn_score := 0

func _ready() -> void:
	randomize()

	if config == null:
		push_error("BonusConfig non assigne dans BonusSpawner")
		return

	if config.spawn_mode == BonusConfig.SpawnMode.TIME:
		call_deferred("start_spawn_loop")

func start_spawn_loop() -> void:
	while is_inside_tree():
		var wait_time = config.spawn_interval

		if config.use_random_time:
			wait_time = randf_range(config.min_spawn_time, config.max_spawn_time)

		await get_tree().create_timer(wait_time).timeout
		if not is_inside_tree():
			return
		try_spawn_bonus()

func try_spawn_bonus() -> void:
	if count_bonus() >= config.max_bonus_on_screen:
		return

	if randf() <= config.spawn_chance:
		spawn_bonus()

func spawn_bonus() -> void:
	var bonus = bonus_scene.instantiate()
	bonus.config = config
	get_spawn_parent().add_child(bonus)

func add_score(value: int) -> void:
	score += value

	if config == null:
		return

	if config.spawn_mode == BonusConfig.SpawnMode.SCORE:
		if score - last_spawn_score >= config.points_between_spawn:
			last_spawn_score = score
			try_spawn_bonus()

func count_bonus() -> int:
	var count := 0

	for child in get_spawn_parent().get_children():
		if child is Bonus:
			count += 1

	return count

func get_spawn_parent() -> Node:
	if spawn_parent != NodePath():
		return get_node(spawn_parent)
	return get_parent()
