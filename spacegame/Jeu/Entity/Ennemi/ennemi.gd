extends Entity
class_name Ennemi

@export var speed : Vector2
@export var velocity : float
@export var subDivisions : Array[Ennemi]

var changeSpeedFactor : Array[int] = [1,-1]

var is_moving = false

func _physics_process(delta: float) -> void:
	if !is_moving : 
		apply_impulse(speed, Vector2.ZERO)
		is_moving = true

func kill_node():
	var ennemi_scene = load("res://Jeu/Entity/Ennemi/ennemi.tscn")
	for ennemiDivision : Ennemi in subDivisions :
		var ennemi : Ennemi = ennemi_scene.instantiate()
		ennemi.spriteTexture = ennemiDivision.spriteTexture
		ennemi.spriteScale = ennemiDivision.spriteScale
		ennemi.widthColissionShape = ennemiDivision.widthColissionShape
		ennemi.heightColissionShape = ennemiDivision.heightColissionShape
		ennemi.positionXColissionShape = ennemiDivision.positionXColissionShape
		ennemi.positionYColissionShape = ennemiDivision.positionYColissionShape
		ennemi.transform.origin = transform.origin
		var xFactor : int = changeSpeedFactor.pick_random()
		var yFactor : int = changeSpeedFactor.pick_random()
		ennemi.speed = Vector2(xFactor * speed[1], yFactor * speed[0])
		ennemi.subDivisions = ennemiDivision.subDivisions
		get_parent().call_deferred("add_child", ennemi)
	call_deferred("queue_free")

func cloneDeep() -> Ennemi :
	var ennemi : Ennemi = Ennemi.new()
	
	ennemi.spriteTexture = spriteTexture
	ennemi.spriteScale = spriteScale
	ennemi.widthColissionShape = widthColissionShape
	ennemi.heightColissionShape = heightColissionShape
	ennemi.speed = speed
	ennemi.subDivisions = subDivisions.duplicate(true)
	
	return ennemi

func body_entered(body: Node) -> void:
	if body is Joueur :
		body.kill()
