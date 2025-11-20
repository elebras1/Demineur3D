# Crosshair.gd
extends Label

func _ready():
	text = "+"
	add_theme_font_size_override("font_size", 24)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -8
	offset_top = -12
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
