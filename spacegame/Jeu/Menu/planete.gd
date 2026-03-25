extends Node3D
class_name Planet

@export var Orbit : float
@export var rotation_speed_Planete : float 
@export var PlanetMat : StandardMaterial3D = load("res://Ressources/purplered.tres")
@export var PlanetScale : Vector3
@export var isSun : bool = false
@export var LevelDescription : String

func _ready() -> void:

	if not isSun:
		set_as_top_level(true)
		
		if get_parent():
			global_position = get_parent().global_position + (Vector3.BACK * Orbit)
		if Orbit > 0.001 and not isSun:
			look_at(get_parent().global_position)
		
	scale = PlanetScale
	if has_node("Planete"):
		$Planete.material_override = PlanetMat
		
	if isSun and has_node("OmniLight3D"):
		$Planete/OmniLight3D.visible = true

func _process(delta: float) -> void:

	if has_node("Planete"):
		$Planete.rotate_y(rotation_speed_Planete * delta)

	if isSun or Orbit <= 0.001:
		return 

	translate(Vector3.LEFT * (delta * rotation_speed_Planete))
	look_at(get_parent().global_position)

	var distance_actuelle = global_position.distance_to(get_parent().global_position)
	var ecart = distance_actuelle - Orbit
	
	if abs(ecart) > 0.001:
		var direction_vers_centre = global_position.direction_to(get_parent().global_position)
		global_translate(direction_vers_centre * ecart)
