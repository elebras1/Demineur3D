extends Node3D

var state : int = 0  # 0 = hidden, 1 = revealed, 2 = flagged
var value : int = 0  # -1 = mine, 0 = vide, >0 = nombre de mines voisines
var is_dark : bool = false  # effet damier

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $MeshInstance3D/Label3D

func _ready():
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()
	update_color()

func update_color():
	var mat = mesh.material_override
	if mat == null:
		return

	match state:
		0:
			mat.albedo_color = Color(0.4, 0.5, 0.4) if is_dark else Color(0.5, 0.6, 0.5)
		1:
			if value == -1:
				mat.albedo_color = Color(0.8, 0.1, 0.1)
			else:
				mat.albedo_color = Color(0.8, 0.7, 0.6) if is_dark else Color(0.9, 0.85, 0.75)
		2:
			mat.albedo_color = Color(0.35, 0.45, 0.35) if is_dark else Color(0.45, 0.55, 0.45)
	update_label()

func update_label():
	if not label:
		return
	
	if state == 1 and value > 0:
		label.visible = true
		label.text = str(value)
	else:
		label.visible = false
