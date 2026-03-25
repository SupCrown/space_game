extends ToreWorldBody
class_name Laser
	
var is_moving = false
@export var lifetime = 1.0
@export var direction : Vector2

func _ready() -> void:
	add_to_group("projectiles")

func _process(delta: float) -> void:
	lifetime = lifetime - delta
	if (lifetime <= 0) :
		call_deferred("queue_free")

func _physics_process(delta: float) -> void:
	if !is_moving : 
		apply_impulse(direction * 800)
		is_moving = true
	

func _on_body_entered(body: Node) -> void:
	if body is Ennemi :
		body.kill_node()
		call_deferred("queue_free")
