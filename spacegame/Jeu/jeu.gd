extends Node2D

func _ready() -> void:
	Settings.load_from_disk()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is toreWorldBody:
		body.toreWorlBehaviour($Area2D/CollisionShape2D.shape.get_rect().size)
