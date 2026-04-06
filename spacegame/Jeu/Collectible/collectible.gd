extends ToreWorldBody
class_name Collectible

const COLLECTIBLE_COUNT := 7
const TEXTURE_PATHS := [
	"res://Ressources/Collectibles/Collectible_1.png",
	"res://Ressources/Collectibles/Collectible_2.png",
	"res://Ressources/Collectibles/Collectible_3.png",
	"res://Ressources/Collectibles/Collectible_4.png",
	"res://Ressources/Collectibles/Collectible_5.png",
	"res://Ressources/Collectibles/Collectible_6.png",
	"res://Ressources/Collectibles/Collectible_7.png",
]
const AUDIO_MAP := {
	4: "res://Ressources/Collectibles/Collectible_4_audio.mp3",
	7: "res://Ressources/Collectibles/Collectible_7_audio.mp3",
}

var collectible_id: int = 1  # 1-7
var is_moving := false
var speed: Vector2 = Vector2.ZERO
var collected := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	var idx := collectible_id - 1
	if idx >= 0 and idx < TEXTURE_PATHS.size():
		var tex = load(TEXTURE_PATHS[idx])
		if tex:
			$Sprite2D.texture = tex
	$Sprite2D.scale = Vector2(0.12, 0.12)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30.0, 30.0)
	$CollisionShape2D.shape = rect

func _physics_process(_delta: float) -> void:
	if not is_moving:
		apply_impulse(speed)
		is_moving = true

func impact_laser() -> void:
	if collected:
		return
	collected = true
	var is_new := Settings.add_collectible(collectible_id)
	_play_audio()
	_notify_collected(is_new)
	$CollisionShape2D.set_deferred("disabled", true)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Quick fade out
	var tween := create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _play_audio() -> void:
	if not AUDIO_MAP.has(collectible_id):
		return
	var path : String = AUDIO_MAP[collectible_id]
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = 5.0
	# Add to scene root so it survives this node's queue_free
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _notify_collected(is_new: bool) -> void:
	var text := "Collectible #" + str(collectible_id)
	if is_new:
		text += " (NOUVEAU !)"
	var parent = get_parent()
	if parent and parent.has_method("show_bonus_notification"):
		parent.show_bonus_notification(text)

static func create_random(zone_w: float, zone_h: float) -> Collectible:
	var scene = load("res://Jeu/Collectible/collectible.tscn")
	var instance : Collectible = scene.instantiate()
	instance.collectible_id = (randi() % COLLECTIBLE_COUNT) + 1
	# Spawn from a random edge
	var side := randi() % 4
	match side:
		0:
			instance.position = Vector2(-zone_w / 2.0 - 30.0, randf_range(-zone_h / 2.0, zone_h / 2.0))
			instance.speed = Vector2(randf_range(80.0, 150.0), randf_range(-50.0, 50.0))
		1:
			instance.position = Vector2(zone_w / 2.0 + 30.0, randf_range(-zone_h / 2.0, zone_h / 2.0))
			instance.speed = Vector2(randf_range(-150.0, -80.0), randf_range(-50.0, 50.0))
		2:
			instance.position = Vector2(randf_range(-zone_w / 2.0, zone_w / 2.0), -zone_h / 2.0 - 30.0)
			instance.speed = Vector2(randf_range(-50.0, 50.0), randf_range(80.0, 150.0))
		3:
			instance.position = Vector2(randf_range(-zone_w / 2.0, zone_w / 2.0), zone_h / 2.0 + 30.0)
			instance.speed = Vector2(randf_range(-50.0, 50.0), randf_range(-150.0, -80.0))
	return instance
