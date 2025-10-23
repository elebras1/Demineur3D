extends Node3D

@export var grid_width: int = 50
@export var grid_height: int = 50
@export var cell_size: float = 1.0
@export var num_mines: int = 300

var cell_scene = preload("res://cell.tscn")
var grid: Array = []
var generator: MineSweeper = MineSweeper.new()
var board: Array = []
var is_first_click: bool = true
var is_generating: bool = false

func _ready():
	await generate_empty_grid_3d()
	print("Grille prête - Cliquez pour commencer !")

# Génère une grille vide (sans mines)
func generate_empty_grid_3d() -> void:
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell = cell_scene.instantiate()
			add_child(cell)
			cell.position = Vector3(x * cell_size, 0, y * cell_size)
			
			cell.grid_pos = Vector2i(x, y)  # Format (x, y)
			cell.parent_grid = self
			cell.is_dark = (x + y) % 2 == 1
			cell.state = 0
			cell.value = 0
			cell.update_color()
			
			row.append(cell)
		grid.append(row)
		if y % 5 == 0:
			await get_tree().process_frame

# Génère le board après le premier clic
func generate_board_from_first_click(first_click: Vector2i):
	if is_generating:
		return
	
	is_generating = true
	print("Génération du board à partir de (x=", first_click.x, ", y=", first_click.y, ")")
	
	var safe_radius = 1
	var max_zero_ratio = 0.5
	
	# CRITIQUE : Convertir (x, y) en (row, col)
	# first_click.x = colonne, first_click.y = ligne
	# Le générateur attend Vector2i(row, col)
	var first_click_rowcol = Vector2i(first_click.y, first_click.x)
	
	print("Conversion en (row, col) = (", first_click_rowcol.x, ", ", first_click_rowcol.y, ")")
	
	# Génère le board
	# use_solvable = false pour génération rapide garantissant un 0
	# use_solvable = true pour grille garantie solvable (plus lent)
	board = generator.create_board(grid_height, grid_width, num_mines, first_click_rowcol, safe_radius, max_zero_ratio, false)
	
	# Vérifie qu'il n'y a pas de mine à la position cliquée
	if board[first_click.y][first_click.x]["mine"]:
		print("ERREUR : Mine détectée au premier clic !")
	else:
		print("OK : Pas de mine au premier clic")
	
	# Met à jour toutes les cellules avec les vraies valeurs
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = grid[y][x]
			cell.board = board
			cell.generator = generator
			cell.value = board[y][x]["num"]
			if board[y][x]["mine"]:
				cell.value = -1
	
	is_generating = false
	is_first_click = false
	print("Board généré ! Révélation de la première case...")
	
	# Révèle automatiquement la case cliquée
	var clicked_cell = grid[first_click.y][first_click.x]
	clicked_cell.reveal()

# Appelé par les cellules lors d'un clic
func on_cell_clicked(cell: Cell):
	if is_generating:
		return
	
	if is_first_click:
		await generate_board_from_first_click(cell.grid_pos)
	else:
		cell.reveal()

# Appelé par les cellules lors d'un clic droit
func on_cell_right_clicked(cell: Cell):
	if is_first_click or is_generating:
		return
	
	cell.toggle_flag()

# Met à jour seulement les cellules spécifiées
func update_specific_cells(changed_cells: Array):
	for pos in changed_cells:
		var x = pos.x
		var y = pos.y
		if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
			continue
		
		var cell = grid[y][x]
		var cell_data = board[y][x]
		
		if cell_data["revealed"]:
			cell.state = 1
		elif cell_data["flag"]:
			cell.state = 2
		else:
			cell.state = 0
		
		cell.update_color()
