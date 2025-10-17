extends Node3D

@export var grid_width: int = 15
@export var grid_height: int = 15
@export var cell_size: float = 1.0
@export var num_mines: int = 15

var cell_scene = preload("res://cell.tscn")
var grid : Array = [] # 2D Array de nodes Cell
var generator : MineSweeper = MineSweeper.new()
var board : Dictionary = {}

func _ready():
	
	# Générer la board via le générateur
	var first_click = Vector2i(5, 5)
	board = generator.create_board(grid_height, grid_width, num_mines, first_click)
	
	# Générer la grille 3D
	generate_grid_3d()
	
	# Révéler la première cellule centrale
	
	for i in range(grid_height):
		for j in range(grid_width):
			reveal_cell(i,j)

func generate_grid_3d():
	# Nettoyer la grille existante
	for row in grid:
		for cell in row:
			cell.queue_free()
	grid.clear()
	
	# Créer la grille 3D
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell = cell_scene.instantiate()
			add_child(cell)
			cell.position = Vector3(x * cell_size, 0, y * cell_size)
			cell.is_dark = (x + y) % 2 == 1
			cell.state = 0
			var key = Vector2i(y, x)
			cell.value = board[key]["num"] if board.has(key) else 0
			if board.has(key) and board[key]["mine"]:
				cell.value = -1
			cell.update_color()
			row.append(cell)
		grid.append(row)

# Révéler une cellule et propager si zéro
func reveal_cell(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	
	var cell = grid[y][x]
	if cell.state != 0:
		return
	
	cell.state = 1
	cell.update_color()
	
	# Mettre à jour le board logique
	var key = Vector2i(y, x)
	if board.has(key):
		board[key]["revealed"] = true
	
	# Si zéro, flood fill
	if cell.value == 0:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				reveal_cell(x + dx, y + dy)

# Marquer ou enlever un drapeau
func toggle_flag(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	var cell = grid[y][x]
	if cell.state == 0:
		cell.state = 2
		board[Vector2i(y, x)]["flag"] = true
	elif cell.state == 2:
		cell.state = 0
		board[Vector2i(y, x)]["flag"] = false
	cell.update_color()
