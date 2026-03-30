extends toreWorldBody
class_name Laser

@export var lifetime: float = 1.0
@export var impulse_strength: float = 800.0
@export var direction: Vector2 = Vector2.ZERO

var is_moving := false
var is_powerful := false

const LASER_SKINS := [
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_1.tres", "scale": Vector2(0.1, 0.1), "anim": "default" },
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_2.tres", "scale": Vector2(0.1, 0.1), "anim": "default" },
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_3.tres", "scale": Vector2(0.01, 0.01), "anim": "default" }
]

func _ready() -> void:
	add_to_group("projectiles")
	apply_laser_skin()

func apply_laser_skin() -> void:
	if Settings.laser_skin_index < 0 or Settings.laser_skin_index >= LASER_SKINS.size():
		push_error("Index laser invalide")
		return

	var skin = LASER_SKINS[Settings.laser_skin_index]
	var frames = load(skin["frames"])

	print("Laser index :", Settings.laser_skin_index)
	print("Laser frames :", skin["frames"])
	print("Frames chargees :", frames)

	if frames == null:
		push_error("Impossible de charger : " + skin["frames"])
		return

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.scale = skin["scale"]
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play(skin["anim"])

	print("Animations dispo :", frames.get_animation_names())

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		call_deferred("queue_free")

func _physics_process(delta: float) -> void:
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
