extends ToreWorldBody
class_name Entity

@export var spriteTexture : String
@export var spriteScale : Vector2
@export var widthColissionShape : float
@export var heightColissionShape : float
@export var positionXColissionShape : float = 0.0
@export var positionYColissionShape : float = 0.0

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite :
		sprite.texture = load(spriteTexture)
		sprite.scale = spriteScale;
	else :
		sprite = get_node_or_null("AnimatedSprite2D")
		if sprite :
			sprite.scale = spriteScale;
	
	var rect = RectangleShape2D.new()
	rect.size = Vector2(widthColissionShape, heightColissionShape)
	
	var collision = get_node_or_null("CollisionShape2D")
	if sprite :
		collision.shape = rect;
		collision.transform.origin = Vector2(positionXColissionShape, positionYColissionShape)
	
