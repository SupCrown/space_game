extends Node3D

# Cible actuelle (Planète)
var cible_a_suivre : Node3D = null

# Paramètres de Zoom
var distance_zoom : float = 20.0
var min_zoom : float = 5.0
var max_zoom : float = 100.0

@onready var cam = $Camera3D

func _ready():
	set_as_top_level(true)

func _unhandled_input(event):
	# Gestion du Zoom avec la molette
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance_zoom -= 2.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance_zoom += 2.0
		
		distance_zoom = clamp(distance_zoom, min_zoom, max_zoom)

func _process(delta):
	# 1. SUIVI DE LA PLANÈTE CIBLE (Position du Rig)
	if cible_a_suivre != null:
		global_position = global_position.lerp(cible_a_suivre.global_position, delta * 5.0)
	
	# 2. APPLICATION DU ZOOM (Position locale de la caméra enfant)
	if cam:
		# La caméra recule sur son axe Z local
		cam.position.z = lerp(cam.position.z, distance_zoom, delta * 5.0)
		
		# La caméra regarde toujours le centre du Rig (la planète)
		cam.look_at(global_position)

# Fonction appelée par le Main pour changer de planète
func definir_cible(nouvelle_cible):
	cible_a_suivre = nouvelle_cible
