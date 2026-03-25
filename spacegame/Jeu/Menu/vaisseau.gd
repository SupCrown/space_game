extends Node3D

# --- PARAMÈTRES ---
@export var vitesse_voyage : float = 20.0
@export var hauteur_arc : float = 15.0   
@export var distance_orbite : float = 4.0
@export var vitesse_rotation : float = 1.5

enum Etat { ORBITE, VOYAGE }
var etat_actuel = Etat.ORBITE

var planete_courante : Node3D = null
var planete_destination : Node3D = null

# Variables de calcul
var angle_orbite : float = 0.0
var position_depart_voyage : Vector3
var progression_voyage : float = 0.0
var duree_voyage : float = 0.0

func _ready():
	set_as_top_level(true) 

func _process(delta: float):
	match etat_actuel:
		Etat.ORBITE:
			if planete_courante:
				# Rotation
				angle_orbite += delta * vitesse_rotation
				var offset = Vector3(cos(angle_orbite) * distance_orbite, 0, sin(angle_orbite) * distance_orbite)
				global_position = planete_courante.global_position + offset
				
				# Orientation (Regarde la tangente)
				var futur = planete_courante.global_position + Vector3(cos(angle_orbite + 0.1)*distance_orbite, 0, sin(angle_orbite + 0.1)*distance_orbite)
				look_at(futur)

		Etat.VOYAGE:
			if planete_destination:
				progression_voyage += delta / duree_voyage
				
				if progression_voyage >= 1.0:
					_arriver()
					return

				# Parabole : Lerp (Sol) + Sinus (Hauteur)
				var pos_sol = position_depart_voyage.lerp(planete_destination.global_position, progression_voyage)
				var hauteur = sin(progression_voyage * PI) * hauteur_arc
				global_position = Vector3(pos_sol.x, pos_sol.y + hauteur, pos_sol.z)
				
				# Orientation : Regarde un peu plus loin sur la courbe
				var t_look = min(progression_voyage + 0.05, 1.0)
				var p_look = position_depart_voyage.lerp(planete_destination.global_position, t_look)
				var h_look = sin(t_look * PI) * hauteur_arc
				look_at(Vector3(p_look.x, p_look.y + h_look, p_look.z))

func aller_vers(nouvelle_planete : Node3D):
	if nouvelle_planete == planete_courante: return
	
	planete_destination = nouvelle_planete
	position_depart_voyage = global_position
	var dist = position_depart_voyage.distance_to(planete_destination.global_position)
	duree_voyage = dist / vitesse_voyage
	
	progression_voyage = 0.0
	etat_actuel = Etat.VOYAGE
	print("Vaisseau part vers : ", nouvelle_planete.name)

func _arriver():
	planete_courante = planete_destination
	etat_actuel = Etat.ORBITE
	angle_orbite = 0.0
