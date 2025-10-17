extends Node3D

@export var grid_width : int = 10
@export var grid_height : int = 10
@export var cell_size : float = 1.0
@export var num_mines : int = 15

var cell_scene = preload("res://cell.tscn")
var grid : Array = []
var mine_matrix : Array = []  # Matrice des mines (-1 = mine, sinon = nombre de mines voisines)

func _ready():
	# Matrice par défaut en dur (pour test)
	# 0 = case vide/nombre, -1 = mine
	set_mine_matrix([
		[0, 0, 0, -1, 0, 0, 0, 0, 0, 0],
		[0, -1, 0, 0, 0, 0, -1, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[-1, 0, 0, 0, -1, 0, 0, 0, -1, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, -1, 0, 0, 0, 0, -1, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, -1, 0, 0, 0, -1, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, -1, 0],
		[0, 0, 0, -1, 0, 0, 0, 0, 0, 0]
	])
	
	# Appliquer une matrice de test avec des cases révélées et des drapeaux
	apply_test_game_state()

# Setter pour la matrice des mines
func set_mine_matrix(matrix: Array):
	mine_matrix = matrix
	
	# Mettre à jour les dimensions en fonction de la matrice
	if matrix.size() > 0:
		grid_height = matrix.size()
		grid_width = matrix[0].size()
	
	# Régénérer la grille
	clear_grid()
	generate_grid()
	apply_mine_matrix()
	calculate_numbers()

# Nettoyer la grille existante
func clear_grid():
	for row in grid:
		for cell in row:
			cell.queue_free()
	grid.clear()

func generate_grid():
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			# Créer la cellule
			var cell = cell_scene.instantiate()
			add_child(cell)
			
			# Positionner la cellule
			cell.position = Vector3(x * cell_size, 0, y * cell_size)
			
			# Définir l'effet damier
			cell.is_dark = (x + y) % 2 == 1
			
			# Initialiser les valeurs
			cell.state = 0  # hidden
			cell.value = 0  # pas de mine
			cell.update_color()
			
			row.append(cell)
		grid.append(row)

# Appliquer la matrice de mines
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
			# Vérifier les 8 cases autour
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

# Fonction pour appliquer un état de jeu de test (partie en cours)
func apply_test_game_state():
	# Matrice d'état : 0 = cachée, 1 = révélée, 2 = drapeau
	var state_matrix = [
		[1, 1, 1, 0, 1, 1, 1, 1, 0, 0],
		[1, 0, 1, 1, 1, 1, 0, 2, 0, 0],
		[1, 1, 1, 0, 0, 1, 1, 1, 0, 0],
		[0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
		[1, 1, 0, 0, 0, 1, 0, 0, 0, 0],
		[1, 1, 0, 0, 0, 1, 1, 0, 1, 1],
		[1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
		[1, 0, 1, 0, 0, 0, 1, 0, 1, 1],
		[1, 1, 1, 0, 0, 0, 1, 1, 0, 1],
		[0, 0, 1, 0, 0, 0, 0, 1, 1, 1]
	]
	
	for y in range(min(grid_height, state_matrix.size())):
		for x in range(min(grid_width, state_matrix[y].size())):
			grid[y][x].state = state_matrix[y][x]
			grid[y][x].update_color()

# Fonction pour révéler une cellule (à appeler au clic)
func reveal_cell(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	
	var cell = grid[y][x]
	
	if cell.state != 0:  # Déjà révélée ou marquée
		return
	
	cell.state = 1  # revealed
	cell.update_color()
	
	# Si c'est une case vide (0), révéler les voisins automatiquement
	if cell.value == 0:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				reveal_cell(x + dx, y + dy)

# Fonction pour marquer/démarquer un drapeau
func toggle_flag(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	
	var cell = grid[y][x]
	
	if cell.state == 0:  # hidden -> flagged
		cell.state = 2
	elif cell.state == 2:  # flagged -> hidden
		cell.state = 0
	
	cell.update_color()
