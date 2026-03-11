extends toreWorldBody
class_name Asteroid

@export var spriteTexture : String = "res://Ressources/Asteroids/trash_1.png"
@export var spriteScale : Vector2 = Vector2(0.2, 0.2)
@export var widthColissionShape : float = 123.0
@export var heightColissionShape : float = 20.0
@export var speed : Vector2 = Vector2(0.6, -0.3) * 100
var subDivisons : Array[Asteroid]

var is_moving = false
var asteroid_scene = preload("res://Asteroids/asteroids.tscn")

func _ready() -> void:
	$Sprite2D.texture = load(spriteTexture)
	$Sprite2D.scale = spriteScale;
	var rect = RectangleShape2D.new()
	rect.size = Vector2(widthColissionShape, heightColissionShape)
	$CollisionShape2D.shape = rect;

func _physics_process(delta: float) -> void:
	if !is_moving : 
		apply_impulse(speed, Vector2.ZERO)
		is_moving = true

func impact_laser() -> void:
	var asteroid1 : Asteroid = asteroid_scene.instantiate()
	asteroid1.spriteTexture = "res://Ressources/Asteroids/trash_3.png";
	asteroid1.widthColissionShape = 34.2
	asteroid1.heightColissionShape = 43.0
	asteroid1.transform.origin = transform.origin
	asteroid1.speed = Vector2(-speed[1], speed[0])
	var asteroid2 : Asteroid = asteroid_scene.instantiate()
	asteroid2.spriteTexture = "res://Ressources/Asteroids/trash_5.png";
	asteroid2.widthColissionShape = 42.0
	asteroid2.heightColissionShape = 18.3
	asteroid2.transform.origin = transform.origin
	asteroid2.speed = Vector2(speed[1], -speed[0])
	get_parent().call_deferred("add_child", asteroid1)
	get_parent().call_deferred("add_child", asteroid2)
	call_deferred("queue_free")

func _on_body_entered(body: Node) -> void:
	if body is Vaisseau :
		body.call_deferred("queue_free")
