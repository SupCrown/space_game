extends toreWorldBody
class_name Laser

@export var lifetime: float = 1.0
@export var impulse_strength: float = 800.0
@export var direction: Vector2 = Vector2.ZERO

var is_moving := false
var is_powerful := false

func _ready() -> void:
	add_to_group("projectiles")

func _process(delta: float) -> void:
	update_lifetime(delta)

func _physics_process(delta: float) -> void:
	launch_once()

func update_lifetime(delta: float) -> void:
	lifetime -= delta

	if lifetime <= 0.0:
		call_deferred("queue_free")

func launch_once() -> void:
	if is_moving:
		return

	apply_impulse(direction * impulse_strength)
	is_moving = true

func _on_body_entered(body: Node) -> void:
	if not body.has_method("impact_laser"):
		return

	body.impact_laser()

	if not is_powerful:
		call_deferred("queue_free")
