extends MarginContainer
class_name HUD

const LOW_FUEL_THRESHOLD : float = 0.35

const FUEL_TEX_FULL : Texture2D = preload("res://Ressources/HUD/jauge_pleine.svg")
const FUEL_TEX_HALF : Texture2D = preload("res://Ressources/HUD/jauge_moitie.svg")
const FUEL_TEX_LOW : Texture2D = preload("res://Ressources/HUD/jauge_vide.svg")
const FUEL_TEX_EMPTY : Texture2D = preload("res://Ressources/HUD/jauge_vide_total.svg")

@onready var fuel_bar : TextureRect = $FuelBar
@onready var edge_vignette : ColorRect = $EdgeVignette
@onready var death_mask : ColorRect = $DeathMask

var _blink_time : float = 0.0
var _edge_material : ShaderMaterial

func _ready() -> void:
	_edge_material = edge_vignette.material as ShaderMaterial
	_reset_damage_overlay()
	_set_edge_intensity(0.0)
	fuel_bar.texture = FUEL_TEX_FULL

func _process(delta: float) -> void:
	_blink_time += delta

func update_fuel(fuel_percent: float) -> void:
	var clamped_percent : float = clampf(fuel_percent, 0.0, 1.0)
	fuel_bar.texture = _fuel_texture_for(clamped_percent)

	var danger : float = clampf((LOW_FUEL_THRESHOLD - clamped_percent) / LOW_FUEL_THRESHOLD, 0.0, 1.0)
	if danger <= 0.0:
		_set_edge_intensity(0.0)
		return

	var pulse : float = 0.5 + 0.5 * sin(_blink_time * (8.0 + danger * 12.0))
	var final_intensity : float = lerpf(0.2, 0.9, danger) * pulse
	_set_edge_intensity(final_intensity)

func play_hit_effect(ship_screen_pos: Vector2, lives_remaining: int = 3) -> void:
	var material := death_mask.material as ShaderMaterial
	if material == null:
		return

	var rect_size : Vector2 = death_mask.size
	if rect_size.x <= 0.0 or rect_size.y <= 0.0:
		rect_size = get_viewport_rect().size
	var center_uv : Vector2 = ship_screen_pos / rect_size

	var close_radius : float = _close_radius_for_lives(lives_remaining)
	var open_radius : float = 0.9

	material.set_shader_parameter("hole_center_uv", center_uv)
	material.set_shader_parameter("hole_radius_uv", open_radius)
	material.set_shader_parameter("overlay_alpha", 0.0)
	death_mask.visible = true

	var tween := create_tween()
	# fermeture
	tween.set_parallel(true)
	tween.tween_property(material, "shader_parameter/overlay_alpha", 1.0, 0.25)
	tween.tween_property(material, "shader_parameter/hole_radius_uv", close_radius, 0.5)
	# maintien fermé autour du vaisseau (temps de voir combien de vies il reste)
	tween.chain().tween_interval(0.65)
	# ré-ouverture
	tween.chain().set_parallel(true)
	tween.tween_property(material, "shader_parameter/overlay_alpha", 0.0, 0.55)
	tween.tween_property(material, "shader_parameter/hole_radius_uv", open_radius, 0.55)

func _close_radius_for_lives(lives_remaining: int) -> float:
	# Plus il reste peu de vies, plus le trou se resserre près du vaisseau.
	match lives_remaining:
		3:
			return 0.22
		2:
			return 0.14
		1:
			return 0.07
		_:
			return 0.03

func _fuel_texture_for(percent: float) -> Texture2D:
	if percent >= 0.75:
		return FUEL_TEX_FULL
	if percent >= 0.40:
		return FUEL_TEX_HALF
	if percent >= 0.10:
		return FUEL_TEX_LOW
	return FUEL_TEX_EMPTY

func _set_edge_intensity(intensity: float) -> void:
	if _edge_material != null:
		_edge_material.set_shader_parameter("intensity", intensity)

func _reset_damage_overlay() -> void:
	var material := death_mask.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("overlay_alpha", 0.0)
		material.set_shader_parameter("hole_radius_uv", 0.8)
	death_mask.visible = true

func display_pause_menu() :
	$PauseMenu.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	$PauseMenu.visible = false
	get_tree().paused = false

func display_lose_menu() :
	$LoseMenu.visible = true
	get_tree().paused = true

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Jeu/Menu/Systeme_Sol.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Jeu/jeu.tscn")
