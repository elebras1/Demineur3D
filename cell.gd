extends Node3D
class_name Cell

@export var grid_pos: Vector2i
@export var value: int = 0
@export var board: Array
@export var generator: MineSweeper
@export var state: int = 0  # 0 = cachée, 1 = révélée, 2 = flag

var parent_grid: Node = null
var is_dark: bool = false
var flag_mesh = null


@onready var mesh_instance = $MeshInstance3D
@onready var label = $MeshInstance3D/Label3D
var flag = preload("res://flag.tscn")

func _ready():
	# Créer un matériau pour chaque cellule
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat
	update_color()

func update_color():
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	var mat = mesh_instance.material_override as StandardMaterial3D
	
	match state:
		0:  # Cachée - damier
			if is_dark:
				mat.albedo_color = Color(0.5, 0.5, 0.5)
			else:
				mat.albedo_color = Color(0.7, 0.7, 0.7)
			if label:
				label.text = ""
		1:  # Révélée
			if is_dark:
				mat.albedo_color = Color(0.9, 0.9, 0.9)
			else:
				mat.albedo_color = Color(1, 1, 1)
			if label:
				if value == -1:
					label.text = "💣"
				elif value > 0:
					label.text = str(value)
				else:
					label.text = ""
		2:  # Flag
			if is_dark:
				mat.albedo_color = Color(0.8, 0.2, 0.2)
			else:
				mat.albedo_color = Color(1, 0.3, 0.3)

func reveal():
	if parent_grid.get_is_finish():
		return
	if state != 0:
		return
	
	# Si board n'est pas encore initialisé, c'est un premier clic
	if not board or board.size() == 0:
		if parent_grid:
			parent_grid.on_cell_clicked(self)
		return
	
	# Vérifie que generator est initialisé
	if not generator:
		print("ERREUR: generator non initialisé pour la cellule ", grid_pos)
		return
	
	# Applique le flood fill et récupère les cellules modifiées
	var changed_cells = generator.flood_fill_reveal(board, grid_pos.y, grid_pos.x, board.size(), board[0].size())
	
	# Met à jour seulement les cellules qui ont changé
	if parent_grid:
		parent_grid.update_specific_cells(changed_cells)
	if board[grid_pos.y][grid_pos.x]["mine"] :
		var explosion = preload("res://explosion.tscn")
		var explosion_mesh = explosion.instantiate()
		add_child(explosion_mesh)
		parent_grid.set_is_finish(true)
		

func toggle_flag():
	if parent_grid.get_is_finish():
		return
	# Empêche le flag avant la génération
	if not board or board.size() == 0:
		if parent_grid:
			parent_grid.on_cell_right_clicked(self)
		return
	
	if state == 0:
		state = 2
		board[grid_pos.y][grid_pos.x]["flag"] = true
		flag_mesh = flag.instantiate()
		add_child(flag_mesh)
		
	elif state == 2:
		state = 0
		board[grid_pos.y][grid_pos.x]["flag"] = false
		
		flag_mesh.queue_free()
		
		
		
