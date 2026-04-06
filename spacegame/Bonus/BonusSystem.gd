extends Node
class_name BonusSystem

@export var config: BonusConfig

@onready var spawner = $BonusSpawner

func _ready() -> void:
	if spawner != null:
		spawner.config = config

func add_score(value: int) -> void:
	if spawner != null:
		spawner.add_score(value)
