extends Ennemi
class_name Asteroid

var asteroid_scene = preload("res://Jeu/Entity/Ennemi/Asteroids/asteroids.tscn")

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
	body_entered(body)
