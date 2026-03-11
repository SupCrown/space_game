extends Node3D
class_name Systeme_solaire

var planete_scene = preload("res://Menu/Planete.tscn")
var vaisseau_scene = preload("res://Menu/Vaisseau.tscn")
var camera_scene = preload("res://Menu/CameraRig.tscn")

# Listes
var liste_planetes_camera = []   # Pour la caméra
var liste_planetes_vaisseau = [] # Pour le vaisseau 
var dictionnaire_planetes = {}

var camera_instance = null
var vaisseau_instance = null

var index_camera = 0

func _ready():
	generer_systeme_solaire()

func generer_systeme_solaire():
	var config = ConfigFile.new()
	var err = config.load("res://data.cfg")
	if err != OK: return

	var liste_noms = config.get_value("PLANETS", "PLANETS", [])

	# 1. CRÉATION DES PLANÈTES
	for planet_name in liste_noms:
		var p = planete_scene.instantiate()
		p.name = planet_name
		
		# Configuration
		var taille = config.get_value(planet_name, "SIZE", 1.0)
		p.PlanetScale = Vector3(taille, taille, taille)
		p.Orbit = config.get_value(planet_name, "ORBIT_DIST", 10.0)
		p.rotation_speed_Planete = config.get_value(planet_name, "SPEED", 1.0)
		p.isSun = config.get_value(planet_name, "ISSUN", false)
		p.LevelDescription = config.get_value(planet_name, "LEVEL_DESCRIPTION", "No desc. Un peu tristounet quand-même.")
		
		var path_mat = config.get_value(planet_name, "MATERIAL", "")
		if path_mat != "" and ResourceLoader.exists(path_mat):
			p.PlanetMat = load(path_mat)
		
		dictionnaire_planetes[planet_name] = p
		
		# Remplissage des listes
		liste_planetes_camera.append(p)
		if not p.isSun:
			liste_planetes_vaisseau.append(p)

	# 2. HIÉRARCHIE
	for planet_name in liste_noms:
		var p = dictionnaire_planetes[planet_name]
		var nom_parent = config.get_value(planet_name, "PARENT", "None")
		
		$Menu.add_planete(p);
		if nom_parent == "None" or nom_parent == "Null":
			add_child(p)
		elif dictionnaire_planetes.has(nom_parent):
			dictionnaire_planetes[nom_parent].add_child(p)

	# 3. CRÉATION DU VAISSEAU
	if vaisseau_scene:
		vaisseau_instance = vaisseau_scene.instantiate()
		add_child(vaisseau_instance)
		if liste_planetes_vaisseau.size() > 0:
			# On met le vaisseau sur la première planète (ex: Terre)
			vaisseau_instance.planete_courante = liste_planetes_vaisseau[0]

	# 4. CRÉATION DE LA CAMÉRA
	if camera_scene:
		camera_instance = camera_scene.instantiate()
		add_child(camera_instance)
		if liste_planetes_camera.size() > 0:
			# La caméra regarde le Soleil (ou la première planète)
			camera_instance.definir_cible(liste_planetes_camera[0])


# --- GESTION DES TOUCHES SÉPARÉES ---
func _unhandled_input(event):
	
	# TOUCHE ESPACE -> Change la cible de la CAMÉRA
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		changer_cible_camera()
		
	# TOUCHE ENTRÉE (ENTER) -> Change la cible du VAISSEAU
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		deplacer_vaisseau_aleatoire()


func changer_cible_camera():
	if liste_planetes_camera.is_empty() or camera_instance == null: return
	
	index_camera = (index_camera + 1) % liste_planetes_camera.size()
	var cible = liste_planetes_camera[index_camera]
	
	camera_instance.definir_cible(cible)
	print("Caméra regarde : ", cible.name)


func deplacer_vaisseau_aleatoire():
	if liste_planetes_vaisseau.is_empty() or vaisseau_instance == null: return
	
	# Choisir une planète au hasard qui n'est pas l'actuelle
	var destination = liste_planetes_vaisseau.pick_random()
	
	# Sécurité pour éviter de voyager vers soi-même
	var tentatives = 0
	while destination == vaisseau_instance.planete_courante and tentatives < 10:
		destination = liste_planetes_vaisseau.pick_random()
		tentatives += 1
		
	vaisseau_instance.aller_vers(destination)

func _planet_button_pressed(planet_name : String) -> void:
	if planet_name.is_empty(): return
	
	var cible : Planet = dictionnaire_planetes[planet_name]
	
	camera_instance.definir_cible(cible)
	print("Caméra regarde : ", cible.name)
	
	$Menu.display_level_desc(cible.LevelDescription, cible.name)
