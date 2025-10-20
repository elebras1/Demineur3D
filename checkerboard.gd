extends Node3D

@export var grid_width : int = 50
@export var grid_height : int = 50
@export var cell_size : float = 5.0
@export var num_mines : int = 200

var cell_scene = preload("res://cell.tscn")
var grid: Array = [] # 2D Array de nodes Cell
var generator: MineSweeper = MineSweeper.new()
var board: Array = []

func _ready():
	randomize()
	set_mine_matrix(generate_random_mine_matrix(grid_width, grid_height, num_mines))
	# Optionnel : appliquer un état de test aléatoire
	# apply_test_game_state()

# Génération aléatoire de la matrice
func generate_random_mine_matrix(width: int, height: int, mines: int) -> Array:
	var matrix = []
	
	# Créer une matrice vide
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(0)
		matrix.append(row)
	
	# Placer les mines
	var mines_placed = 0
	while mines_placed < mines:
		var rx = randi() % width
		var ry = randi() % height
		if matrix[ry][rx] != -1:
			matrix[ry][rx] = -1
			mines_placed += 1
	
	# Calculer les nombres autour des mines
	for y in range(height):
		for x in range(width):
			if matrix[y][x] == -1:
				continue
			
			var count = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx = x + dx
					var ny = y + dy
					if nx >= 0 and nx < width and ny >= 0 and ny < height:
						if matrix[ny][nx] == -1:
							count += 1
			matrix[y][x] = count
	
	return matrix

# Setter pour la matrice des mines
func set_mine_matrix(matrix: Array):
	mine_matrix = matrix
	
	if matrix.size() > 0:
		grid_height = matrix.size()
		grid_width = matrix[0].size()
	
	clear_grid()
	generate_grid()
	apply_mine_matrix()
	calculate_numbers()

func clear_grid():
	for row in grid:
		for cell in row:
			cell.queue_free()
	grid.clear()

	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell = cell_scene.instantiate()
			add_child(cell)
			cell.position = Vector3(x * cell_size, 0, y * cell_size)
			cell.is_dark = (x + y) % 2 == 1
			cell.state = 0
			cell.value = 0
			cell.update_color()
			row.append(cell)
		grid.append(row)
		if y % 5 == 0:
			await get_tree().process_frame

func apply_mine_matrix():
	if mine_matrix.size() == 0:
		return
	
	for y in range(min(grid_height, mine_matrix.size())):
		for x in range(min(grid_width, mine_matrix[y].size())):
			if mine_matrix[y][x] == -1:
				grid[y][x].value = -1

func calculate_numbers():
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x].value == -1:
				continue
			
			var count = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx = x + dx
					var ny = y + dy
					if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
						if grid[ny][nx].value == -1:
							count += 1
			grid[y][x].value = count

func reveal_cell(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	var cell = grid[y][x]
	if cell.state != 0:
		return
	
	cell.state = 1
	cell.update_color()
	
	if cell.value == 0:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				reveal_cell(x + dx, y + dy)

func toggle_flag(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	var cell = grid[y][x]
	if cell.state == 0:
		cell.state = 2
	elif cell.state == 2:
		cell.state = 0
	cell.update_color()
