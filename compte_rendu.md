# Compte Rendu de Projet — SpaceGame

**Projet R5A05** — Beroud, Bloise, Delbove, Kebaili  
**Moteur** : Godot 4.6 — Renderer : GL Compatibility

---

## 1. Presentation du jeu

SpaceGame est un jeu de type shoot'em up spatial dans lequel le joueur pilote un vaisseau, detruit des asteroides et collecte des bonus tout en gerant son carburant.

Le jeu s'articule autour de trois parties principales :

- **Un menu principal en 3D** representant un systeme solaire interactif ou le joueur choisit sa planete (niveau) avant de lancer une partie.
- **Le jeu en 2D** ou le vaisseau evolue dans un espace torique (les bords de l'ecran se rejoignent), affronte des vagues d'asteroides et collecte des bonus/malus.
- **Un menu d'options** permettant de configurer le volume, la resolution, les touches de controle et de personnaliser l'apparence du vaisseau et du laser.

### Modes de jeu

Le jeu propose trois modes :

- **Classique** : vagues d'asteroides regulieres avec subdivisions (les gros asteroides se divisent en plus petits), boss periodiques, et systeme de bonus/malus complet.
- **Boss Rush** : les boss apparaissent toutes les 3 vagues avec un rythme de spawn accelere.
- **Shooter** : le vaisseau est oriente vers le haut (direction inversee), les ennemis sont des plantes carnivores, avec un fond et une musique dedies.

### Systeme de bonus et malus

Le jeu comporte 19 effets differents activables par des capsules de bonus qui traversent l'ecran :

| Bonus | Malus |
|-------|-------|
| Vitesse rapide | Vitesse lente |
| Triple laser | Tir lent |
| Laser puissant | Controles aleatoires |
| Tir automatique | Rotation folle |
| Slow motion | Pluie d'asteroides |
| Bouclier | -1 Vie |
| +1 Vie | Glue (vitesse et rotation reduites) |
| Jerrican (carburant) | Hyper vitesse (incontrole) |
| Mode Pac-Man | Screamer |
| SUPER 6 (combine 5 bonus) | |

### Autres mecaniques

- **Carburant** : le vaisseau consomme du carburant en accelerant. La jauge est affichee dans le HUD et une vignette rouge pulse quand le niveau est bas.
- **Vies** : le joueur dispose de 3 vies. A chaque impact un cercle noir se referme sur le vaisseau puis se reouvre pour signaler le degat. Apres un impact le joueur est temporairement invincible (clignotement).
- **Collectibles** : 7 objets rares apparaissent periodiquement. Ils sont stockes de facon persistante et consultables dans un inventaire accessible depuis le menu principal. Certains declenchent un son unique a la collecte.
- **Score** : chaque ennemi detruit rapporte 10 points. Le score est affiche en temps reel et sur les ecrans de pause et de defaite.
- **Cheat codes** : le jeu detecte des sequences de touches (Konami Code, GOD, FUEL, DARK) pour activer des effets speciaux.

---

## 2. Fonctionnalites interessantes de Godot utilisees

### Shaders personnalises (GLSL)

Trois shaders custom ont ete ecrits :

- **death_mask.gdshader** : affiche un masque noir avec un trou circulaire centre sur le vaisseau. Le rayon du trou et l'opacite sont animes par tween pour creer l'effet de cercle qui se ferme puis se rouvre lors d'un impact. C'est un shader `canvas_item` qui utilise `smoothstep` pour le bord doux du cercle.
- **edge_vignette.gdshader** : vignette rouge sur les bords de l'ecran qui pulse proportionnellement au niveau de carburant restant. Utilise `SCREEN_UV` pour un rendu independant de la taille du ColorRect.
- **Systeme_Sol.gdshader** : shader de type `sky` qui genere un ciel etoile de maniere procedurale en partitionnant la sphere celeste en sections et en placant une etoile aleatoire par section.

### Monde torique (`ToreWorldBody`)

La classe `ToreWorldBody` etend `RigidBody2D` et reimplemente `_integrate_forces` pour teleporter les corps physiques qui sortent de l'ecran vers le cote oppose. Cela cree un espace de jeu "torique" ou asteroides, laser et vaisseau rebouclent naturellement. C'est la classe de base de toutes les entites physiques du jeu (joueur, ennemis, laser, bonus, collectibles).

### Configuration par fichiers `.cfg` (ConfigFile)

Le jeu et le systeme solaire sont entierement configurables via des fichiers `.cfg` (format natif Godot) :
- `jeu.cfg` : definit les proprietes du joueur (vitesse, taille, sprites), des ennemis (texture, subdivisions recursives) et du jeu (fond, musique).
- `data.cfg` : definit les planetes du systeme solaire (taille, orbite, vitesse, materiau, hierarchie parent-enfant).

Cela permet de modifier le contenu du jeu sans toucher au code.

### Resource custom (`BonusConfig`)

La classe `BonusConfig` etend `Resource`, ce qui permet d'exposer toute la configuration des bonus (effets actives, valeurs numeriques, mode de spawn) directement dans l'inspecteur Godot via les annotations `@export` et `@export_group`. La resource est instanciee en `SubResource` dans la scene `jeu.tscn`, rendant le parametrage visuel et immediat.

### Menu 3D avec systeme solaire

Le menu principal est une scene 3D (`Node3D`) qui genere dynamiquement un systeme solaire a partir du fichier `data.cfg`. Les planetes orbitent autour de leur parent avec une correction de distance (`direction_vers_centre * ecart`) pour maintenir une orbite stable. La camera suit la planete selectionnee avec un lerp, et un vaisseau 3D voyage entre les planetes via une trajectoire parabolique (interpolation lineaire au sol + sinus pour la hauteur).

### Systeme de signaux

L'architecture du jeu utilise les signaux Godot pour decoupler les composants. Par exemple, le signal `hit_by_asteroid` du joueur est emis lors d'un impact et capte par la scene principale (`jeu.gd`) qui delegue l'effet visuel au HUD. Cela evite que le joueur ait une reference directe au HUD.

### Tweens pour les animations d'interface

Les Tweens de Godot 4 sont utilises pour :
- L'animation du cercle de degat (fermeture, pause, reouverture en 3 etapes paralleles/sequentielles)
- L'apparition/disparition des notifications de bonus (fade out)
- Le fade out des collectibles a la collecte

### Process Mode

Le HUD utilise `process_mode = PROCESS_MODE_ALWAYS` pour continuer a fonctionner meme quand le jeu est en pause (ecran de pause ou de defaite). Cela permet aux animations du HUD et aux tweens de s'executer meme avec `get_tree().paused = true`.

### Autoload (Settings)

Le script `Settings.gd` est declare en Autoload, ce qui en fait un singleton global accessible depuis toute scene. Il gere la persistence des preferences utilisateur (volume, resolution, touches, skins) et de la collection de collectibles via des fichiers `user://`.

### CanvasModulate et PointLight2D

Le mode flashlight (active par le cheat code DARK) combine un `CanvasModulate` (qui assombrit toute la scene) avec un `PointLight2D` enfant du joueur dont la texture radiale est generee proceduralement pixel par pixel dans le code.

---

## 3. Points forts du code

### Architecture avec heritage

La hierarchie de classes est bien pensee :
```
RigidBody2D
  └─ ToreWorldBody (comportement torique)
       ├─ Entity (sprite, collision shape configurables)
       │    ├─ Joueur (controles, bonus, vies)
       │    └─ Ennemi (subdivision, boss)
       │         └─ Asteroid
       ├─ Laser (projectile)
       ├─ Bonus (capsule d'effet)
       └─ Collectible (objet rare)
```

Chaque classe ajoute une responsabilite claire sans dupliquer de code. Le `ToreWorldBody` est partage par toutes les entites physiques.

### Gestion des effets concurrents avec bumper IDs

Le probleme des bonus/malus concurrents (ex: deux bonus de vitesse actifs en meme temps) est resolu par un systeme de "bumper IDs". Chaque effet incremente un compteur (`speed_bonus_id`, `laser_bonus_id`, etc.) a son activation. A l'expiration du timer, l'effet ne se desactive que si son ID correspond toujours a l'ID courant. Si un nouvel effet du meme type a ete active entre-temps, l'ancien ne reset pas les valeurs. C'est un pattern elegant qui evite les conditions de course sur les `await`.

### Conception data-driven

Les fichiers `.cfg` et la `BonusConfig` Resource permettent de modifier le gameplay (vitesse du vaisseau, nombre de subdivisions d'asteroides, probabilite des bonus, etc.) sans modifier une seule ligne de code. C'est une approche professionnelle qui separe le contenu de la logique.

### Separation des responsabilites

- `jeu.gd` : orchestration generale (spawn, score, modes de jeu)
- `joueur.gd` : logique du joueur (controles, effets, vies)
- `hud.gd` : interface utilisateur (jauge, score, effets visuels, menus)
- `bonus_spawner.gd` : logique de spawn des bonus (temps ou score)
- `bonus.gd` : application des effets au joueur
- `ennemi.gd` : comportement ennemi et subdivisions

Chaque script a un role clair et communique avec les autres via des signaux ou des appels de methode explicites.

### Personnalisation du vaisseau et du laser

Le systeme de skins permet au joueur de choisir parmi plusieurs apparences pour le vaisseau et le laser. Les skins sont definis comme des tableaux de dictionnaires avec chemin et echelle, ce qui rend l'ajout de nouveaux skins trivial.

---

## 4. Difficultes rencontrees

### Effet visuel de cercle noir au hit

La plus grosse difficulte technique a ete l'implementation de l'effet de cercle noir qui se referme sur le vaisseau quand il se fait toucher puis se rouvre. L'effet utilise un shader custom avec des parametres animes par tween. Le probleme etait que l'animation des parametres du shader via `tween_property` sur l'objet `ShaderMaterial` directement ne declenchait pas correctement la mise a jour du rendu dans Godot 4.6. L'effet ne fonctionnait que lors de la mort du joueur (quand le jeu est en pause) mais pas lors des hits normaux.

### Merge du travail de l'equipe

Le projet etant developpe a quatre, la gestion des branches Git et des merges a ete une difficulte recurrente. L'historique Git montre des commits de merge ("fin merge", "merge hud") qui temoignent de la complexite de combiner le travail sur le HUD, le jeu de base, et les bonus/modes de jeu developpes en parallele.

### Melange 2D et 3D

Le jeu utilise une scene 3D pour le menu (systeme solaire) et une scene 2D pour le gameplay. Gerer la transition entre les deux contextes et s'assurer que les parametres (mode de jeu, settings) soient correctement transmis via le singleton `Settings` a demande un travail de coordination.

### Gestion des effets concurrents

Avant la mise en place des bumper IDs, les bonus/malus simultanes causaient des bugs (un timer d'effet qui expire resetait les valeurs meme si un nouvel effet du meme type etait en cours). Trouver un pattern correct pour gerer ces expirations concurrentes avec les `await` de Godot a necessite plusieurs iterations.

### Monde torique et physique

Faire fonctionner le monde torique (teleportation aux bords de l'ecran) avec le moteur physique de Godot (`RigidBody2D`) a necessite l'utilisation de `_integrate_forces` pour modifier directement la position du corps physique dans le callback du moteur, plutot que de modifier `position` directement ce qui aurait interfere avec la simulation.

---

## 5. Ce que nous n'avons pas reussi a faire

### Animation d'atterrissage pour le mode Shooter

L'idee originale prevoyait une animation de transition montrant le vaisseau atterrir sur la planete avant de commencer le mode Shooter. En l'etat, le changement de mode est instantane (changement de fond, de sprite et de direction du vaisseau).

### Mode flashlight complet comme mode de jeu

Le document d'idees prevoyait un mode de jeu entier base sur la flashlight (champ de vision limite, lampe lançable, piles comme carburant). En pratique, la flashlight n'est implementee que comme un cheat code (DARK) et non comme un mode de jeu a part entiere avec ses propres mecaniques.

### Screamer desactive

Le bonus screamer (image plein ecran + son effrayant) a ete implemente dans le code mais est desactive par defaut dans la configuration (`enable_screamer = false`), probablement juge trop intrusif pour le gameplay normal.

### Explosion du vaisseau a la mort

Le document d'idees mentionne que le vaisseau devrait exploser visuellement a la mort. En l'etat, le vaisseau est simplement supprime (`queue_free`) sans animation d'explosion.

### Systeme de vagues structure

Le spawn des ennemis est base sur un timer regulier plutot que sur un systeme de vagues numerotees avec difficulte progressive. Les boss apparaissent periodiquement (tous les N spawns) mais il n'y a pas de notion de "vague 1, vague 2..." avec des paliers de difficulte.
