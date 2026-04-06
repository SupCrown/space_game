# Intégration Bonus/Malus + personnalisation vaisseau/laser dans `main`

Date : 2026-04-06
Source : branche `origin/Bonus/Malus` (dernier commit `11132b7`)
Cible : branche `main` (tête `4046e6e`)

## Contexte

Les deux branches ont divergé depuis `55ea38f`. Sur `main`, toute la structure a été réorganisée dans `Jeu/` (fin jeu de base + merge HUD). Sur `Bonus/Malus`, les fichiers sont restés à la racine et de nouvelles fonctionnalités ont été ajoutées :

- Système de bonus/malus : 11 effets sur le joueur avec `BonusConfig` (Resource) + `BonusSpawner`
- Personnalisation : skin vaisseau et skin laser lus depuis `Settings`

Un `git merge` direct produirait des conflits massifs à cause des renommages. On fait un **port manuel adaptatif** : lire les fichiers de `Bonus/Malus`, les adapter à la structure de `main`, préserver toutes les fonctionnalités récentes de `main` (carburant, vies, HUD avec shader death_mask, pause menu, musique dynamique).

## Objectif

Intégrer dans `main` :
1. Le module complet bonus/malus
2. La personnalisation vaisseau/laser via le menu options

Sans régression sur : carburant, vies, HUD, pause, death_mask shader, musique, fin de partie, touches de test H/J/K/L, `Systeme_Sol.tscn`, invincibilité clignotante.

## Arborescence cible

```
spacegame/Jeu/Bonus/                       NOUVEAU
  bonus.gd, bonus.tscn, bonus_config.gd, bonus_spawner.gd
spacegame/Jeu/Entity/Joueur/joueur.gd       modifié
spacegame/Jeu/Entity/Joueur/joueur.tscn     modifié (+ LaserSpawnLeft/Right)
spacegame/Jeu/Entity/Ennemi/ennemi.gd       modifié (+ impact_laser())
spacegame/Jeu/Laser/laser.gd                modifié (+ is_powerful, + skin, duck-typing)
spacegame/Jeu/jeu.gd                        modifié (+ BonusSpawner hook, + spawn_asteroids_from_bonus)
spacegame/Jeu/jeu.tscn                      modifié (+ node BonusSpawner)
spacegame/Jeu/MenuOption/Settings.gd        modifié (+ ship_skin_index, laser_skin_index)
spacegame/Jeu/MenuOption/option_menu.gd     modifié (+ onglet Joueur)
spacegame/Jeu/MenuOption/option_menu.tscn   modifié (+ panels MenuJoueurVaisseau/Lazer)

spacegame/Ressources/Bonus/                 NOUVEAU (4 PNG)
spacegame/Ressources/Vaisseau/spaceship.png, ultraship.png    NOUVEAU
spacegame/Ressources/Vaisseau/ship_sprite_frames_{1,2,3}.tres NOUVEAU
spacegame/Ressources/Laser/lazer_type_2.png, lazer_type_3.png NOUVEAU
spacegame/Ressources/Laser/lazer_sprite_frames_{1,2,3}.tres   NOUVEAU
```

## Module Bonus (nouveaux fichiers)

### `Jeu/Bonus/bonus_config.gd`
Resource avec les 11 toggles d'effets et les paramètres :
- Général : `effect_duration` (5s)
- Vitesse : `enable_slow_speed`, `slow_speed_value`, `enable_fast_speed`, `fast_speed_value`
- Tir : `enable_triple_laser`, `enable_powerful_laser`, `enable_auto_fire`, `enable_slow_fire`, `slow_fire_cooldown`
- Contrôles : `enable_random_controls`, `enable_crazy_rotation`, `crazy_rotation_force`
- Monde : `enable_slow_motion`, `slow_motion_scale`
- Astéroïdes : `enable_asteroid_spawn`, `asteroid_spawn_count`
- Spécial : `enable_super_6`, `super_6_chance`
- Zone : `zone_width`, `zone_height`, `bonus_min_speed`, `bonus_max_speed`
- Spawn : `spawn_mode` (TIME|SCORE), `spawn_chance`, `max_bonus_on_screen`, `spawn_interval`, `use_random_time`, `min/max_spawn_time`, `points_between_spawn`

### `Jeu/Bonus/bonus.gd`
`class_name Bonus extends ToreWorldBody` (PascalCase). 11 constantes `BONUS_*`. Dans `_ready()` : setup body/visuals/collision, choix du type respectant les toggles, spawn en bord de zone avec vélocité aléatoire. Dans `impact_laser()` : récupère le joueur par groupe `"player"` et appelle la méthode d'effet correspondante, puis `explode()`.

**Adaptation critique** : `spawn_asteroids(count)` ne crée plus de `Asteroid` brut. Elle appelle `jeu.spawn_asteroids_from_bonus(count)` pour utiliser la config `jeu.cfg` (textures, scale, subdivisions).

### `Jeu/Bonus/bonus.tscn`
RigidBody2D + AnimatedSprite2D (2 animations : `bonus` clignotant 3 frames, `explosion` 1 frame) + CollisionShape2D RectangleShape2D. Chemins vers `res://Ressources/Bonus/...` et `res://Jeu/Bonus/bonus.gd`.

### `Jeu/Bonus/bonus_spawner.gd`
`class_name BonusSpawner extends Node`. Expose `@export var config: BonusConfig` et `spawn_parent: NodePath`. En mode TIME, boucle `await create_timer(spawn_interval).timeout` → `try_spawn_bonus()`. En mode SCORE, expose `add_score(value)` appelable par `jeu.gd`. `count_bonus()` limite le nombre simultané à `config.max_bonus_on_screen`.

## Modifications du Joueur

### `Jeu/Entity/Joueur/joueur.gd`

**Nouvel état** :
- `base_speed`, `current_speed`, `normal_shoot_cooldown`, `slow_shoot_cooldown`, `shoot_cooldown`, `can_shoot`
- Flags : `triple_laser`, `auto_fire`, `powerful_laser`, `crazy_rotation`, `randomized_controls`
- 8 bumper IDs pour gérer les overlaps d'effets du même type
- `control_map` dict pour malus random_controls
- `SHIP_SKINS` constante (3 entrées)

**`_ready()`** : ajoute `add_to_group("player")`, initialise `base_speed` et `current_speed` depuis `speed`, appelle `apply_ship_skin_if_needed()` (no-op si index invalide ou `.tres` absent — rétro-compatibilité avec `jeu.cfg`).

**`_process(delta)`** : le `if Input.is_action_pressed("tirer")` devient `handle_shoot()` qui respecte `can_shoot`, `shoot_cooldown` et `auto_fire`. `shoot()` spawne 1 ou 3 lasers (via markers `Marker2D`/`LaserSpawnLeft`/`LaserSpawnRight`) et affecte `laser.is_powerful = powerful_laser`.

**`_physics_process(delta)`** : les actions d'input passent par `get_action_for(name)` qui renvoie `control_map[name]` si `randomized_controls`. Accélération utilise `current_speed` (pas `speed`). Si `crazy_rotation`, `apply_torque(crazy_rotation_force)` en continu.

**10 nouvelles méthodes** :
`set_slow_mode`, `set_fast_mode`, `add_extra_laser`, `set_powerful_laser`, `set_slow_motion` (utilise `Engine.time_scale`), `set_auto_fire`, `set_slow_fire`, `set_random_controls` (shuffle `control_map`), `set_crazy_rotation`, `activate_super_6` (enchaîne fast + triple + powerful + auto_fire + slow_motion).

Pattern commun : chaque méthode incrémente un bumper ID, applique l'effet, `await create_timer(duration).timeout`, restaure seulement si le bumper n'a pas changé entretemps (gère les overlaps).

**Garde** : `set_slow_mode` ne modifie pas `modulate.a` — évite de casser le blink d'invincibilité.

### `Jeu/Entity/Joueur/joueur.tscn`
Ajouter `LaserSpawnLeft` et `LaserSpawnRight` (Marker2D) à côté du `Marker2D` existant, offset X ±20. Le `Marker2D` central reste en place.

## Modifications Laser et Ennemi

### `Jeu/Laser/laser.gd`
- Ajouter `var is_powerful : bool = false`
- Ajouter `LASER_SKINS` + `apply_laser_skin_if_needed()` dans `_ready()`
- Remplacer `_on_body_entered` par duck-typing : `if body.has_method("impact_laser"): body.impact_laser(); if not is_powerful: queue_free()`. Fallback `is Ennemi → kill_node()` conservé pour sécurité.

### `Jeu/Entity/Ennemi/ennemi.gd`
Ajouter une seule méthode : `func impact_laser(): kill_node()`. Héritée par `Asteroid`.

## Modifications jeu.gd / jeu.tscn

### `jeu.gd`
- `_ready()` : ajouter `Settings.load_from_disk()` en tête
- Nouvelle méthode publique `spawn_asteroids_from_bonus(count: int)` qui appelle `add_ennemi_to_scene(rx, ry)` en boucle avec random [-1, 1]

### `jeu.tscn`
- Nouveau node `BonusSpawner` (type `Node`) enfant de la racine `Jeu`
- Script `res://Jeu/Bonus/bonus_spawner.gd`
- `config` : Resource inline `BonusConfig` avec valeurs par défaut sensées (mode TIME, spawn_interval 5s, max 3, tous les toggles actifs sauf super_6 si on veut le garder en surprise)

## Personnalisation

### `Jeu/MenuOption/Settings.gd`
- Ajouter `ship_skin_index: int = 0`, `laser_skin_index: int = 0`
- `load_from_disk` / `save_to_disk` lisent et écrivent ces deux valeurs sous section `player`
- Fix au passage : ligne `speed_key = int(cfg.get_value("keys", "accelerer", resolution_index))` remplacée par `speed_key` comme valeur par défaut

### `Jeu/MenuOption/option_menu.gd`
- Ajouter constantes `SHIP_SKINS` (3 entrées, `path` + `scale`) et `LASER_SKINS` (3 entrées)
- Ajouter `@onready var ship_preview`, `laser_preview`
- `update_ship_preview()`, `update_laser_preview()` : `wrapi` sur l'index, charge la texture, maj preview
- 4 handlers `_on_ChoixGaucheVais/DroiteVaiss/GaucheLaz/DroiteLazer_pressed`
- `_on_JoueurButton_pressed()` : affiche `MenuJoueurVaisseau` + `MenuJoueurLazer`, masque les autres
- Les autres `_on_*Button_pressed` masquent aussi les deux panels joueur
- `_ready()` appelle `update_ship_preview()` + `update_laser_preview()`
- Corriger `BACK_SCENE` : `"res://Jeu/Menu/Systeme_Sol.tscn"` (chemin correct dans la structure actuelle)

### `Jeu/MenuOption/option_menu.tscn`
Modifications additives uniquement :
- Nouveau bouton `JoueurOption` dans `PanelOption` (TabBar), texte "Joueur"
- Nouveau `PanelContainer MenuJoueurVaisseau` (unique_name_in_owner) : Label + Sprite2D `Sprite2DVaisseauChoix` + 2 Button `ChoixGaucheVais`/`ChoixDroiteVaiss`
- Nouveau `PanelContainer MenuJoueurLazer` (unique_name_in_owner) : Label + Sprite2D `Sprite2DLazerChoix` + 2 Button `ChoixGaucheLaz`/`ChoixDroiteLazer`
- Connexions signal pressed → handlers
- Les deux panels démarrent `visible = false`

## Ressources

À copier depuis `origin/Bonus/Malus` via `git checkout origin/Bonus/Malus -- <path>` puis déplacement :
- `Ressources/Bonus/box power up.png` (+ clignote, + clignote jaune, + explosion)
- `Ressources/Vaisseau/spaceship.png`, `ultraship.png`
- `Ressources/Laser/lazer_type_2.png`, `lazer_type_3.png`
- `.import` sidecars associés

À créer directement (pour pointer vers les bons chemins dans main) :
- `Ressources/Vaisseau/ship_sprite_frames_{1,2,3}.tres` avec animations `stop` et `mouvement`
- `Ressources/Laser/lazer_sprite_frames_{1,2,3}.tres` avec animation `default`

**Note** : `perseus_1/2/3.png` existe déjà sur main (sous `Statique/` et `Deplacement/`), on ne duplique pas.

## Stratégie de commits

1. ressources (PNG + .import)
2. SpriteFrames .tres
3. module Bonus (4 fichiers)
4. hooks joueur (joueur.gd, joueur.tscn)
5. hooks laser + ennemi (laser.gd, ennemi.gd)
6. intégration jeu (jeu.gd, jeu.tscn)
7. personnalisation (Settings.gd, option_menu.gd, option_menu.tscn)

## Vérification post-intégration

- Aucun chemin `res://Bonus/`, `res://Asteroids/`, `res://Vaisseau/`, `res://Laser/`, `res://HUD/`, `res://MenuOption/`, `res://Menu/` à la racine ne doit subsister dans les fichiers modifiés/créés — tous doivent être sous `res://Jeu/...` ou `res://Ressources/...`
- `ToreWorldBody` en PascalCase partout
- Si aucune ressource skin n'est chargée, le comportement du joueur et du laser reste strictement celui de `main` actuel (fallback sur `jeu.cfg`)
- Les tests manuels H/J/K/L continuent de fonctionner
- Le menu pause, le death_mask et la fin de partie ne sont pas affectés
