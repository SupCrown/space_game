extends ToreWorldBody
class_name Laser

var is_moving = false
@export var lifetime = 1.0
@export var direction : Vector2

var is_powerful : bool = false

const LASER_SKINS := [
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_1.tres", "scale": Vector2(0.1, 0.1) },
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_2.tres", "scale": Vector2(0.1, 0.1) },
	{ "frames": "res://Ressources/Laser/lazer_sprite_frames_3.tres", "scale": Vector2(0.1, 0.1) }
]

func _ready() -> void:
	add_to_group("projectiles")
	apply_laser_skin_if_needed()

func apply_laser_skin_if_needed() -> void:
	if not ("laser_skin_index" in Settings):
		return
	var idx : int = Settings.laser_skin_index
	if idx < 0 or idx >= LASER_SKINS.size():
		return
	var skin = LASER_SKINS[idx]
	if not ResourceLoader.exists(skin["frames"]):
		return
	var frames = load(skin["frames"])
	if frames == null:
		return
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	sprite.sprite_frames = frames
	sprite.scale = skin["scale"]
	sprite.play("default")

func _process(delta: float) -> void:
	lifetime = lifetime - delta
	if (lifetime <= 0) :
		call_deferred("queue_free")

func _physics_process(delta: float) -> void:
	if !is_moving :
		apply_impulse(direction * 800)
		is_moving = true


func _on_body_entered(body: Node) -> void:
	if body.has_method("impact_laser"):
		body.impact_laser()
		if not is_powerful:
			call_deferred("queue_free")
		return
	if body is Ennemi :
		body.kill_node()
		if not is_powerful:
			call_deferred("queue_free")
