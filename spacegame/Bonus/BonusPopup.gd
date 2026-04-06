extends Control

@onready var panel: PanelContainer = $BonusPanelContainer
@onready var label: Label = $BonusPanelContainer/BonusMarginContainer/BonusLabel

var message_id := 0

func _ready() -> void:
	visible = false
	add_to_group("bonus_ui")

	# position en haut-centre
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_top = 20

	# centrer le texte
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func show_message(text: String, is_malus: bool = false, duration: float = 2.0) -> void:
	if label == null or panel == null:
		push_error("UI Bonus mal configurée")
		return

	message_id += 1
	var my_id = message_id

	label.text = text
	visible = true

	# 🎨 couleur
	if is_malus:
		panel.modulate = Color(1.0, 0.3, 0.3)
	else:
		panel.modulate = Color(0.3, 0.8, 1.0)

	label.modulate = Color(1, 1, 1)

	# ✨ animation
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)

	var tween_in = create_tween()
	tween_in.parallel().tween_property(self, "modulate:a", 1.0, 0.15)
	tween_in.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

	await get_tree().create_timer(duration).timeout

	if my_id != message_id:
		return

	var tween_out = create_tween()
	tween_out.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween_out.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	await tween_out.finished

	visible = false
