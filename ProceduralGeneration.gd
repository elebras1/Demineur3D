@tool
class_name MineSweeper
extends Node

## Directions 8-voisines (N, NE, E, SE, S, SW, W, NW)
const DIRS8 = [
	Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
	Vector2i(0, -1),  Vector2i(0, 1),
	Vector2i(1, -1),  Vector2i(1, 0),  Vector2i(1, 1)
]

func in_bounds(r: int, c: int, rows: int, cols: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

func neighbors(r: int, c: int, rows: int, cols: int) -> Array:
	var result: Array = []
	for dir in DIRS8:
		var rr = r + dir.x
		var cc = c + dir.y
		if in_bounds(rr, cc, rows, cols):
			result.append(Vector2i(rr, cc))
	return result


func create_empty_board(rows: int, cols: int) -> Array:
	var board: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append({
				"mine": false,
				"num": 0,
				"revealed": false,
				"flag": false
			})
		board.append(row)
	return board


func calculate_numbers(board: Array, rows: int, cols: int) -> void:
	for r in range(rows):
		for c in range(cols):
			if board[r][c]["mine"]:
				board[r][c]["num"] = -1
				continue
			var count := 0
			for nb in neighbors(r, c, rows, cols):
				if board[nb.x][nb.y]["mine"]:
					count += 1
			board[r][c]["num"] = count


# VERSION ITÉRATIVE (pas de limite de récursion)
func flood_fill_reveal(board: Array, r: int, c: int, rows: int, cols: int) -> Array:
	var changed_cells: Array = []
	var stack: Array = [Vector2i(r, c)]
	
	while stack.size() > 0:
		var pos = stack.pop_back()
		var curr_r = pos.x
		var curr_c = pos.y
		
		# Vérifications
		if not in_bounds(curr_r, curr_c, rows, cols):
			continue
		if board[curr_r][curr_c]["revealed"]:
			continue
		
		# Révèle la cellule
		board[curr_r][curr_c]["revealed"] = true
		changed_cells.append(Vector2i(curr_c, curr_r))  # (x, y) = (col, row)
		
		# Si c'est une mine, stop ici
		if board[curr_r][curr_c]["mine"]:
			continue
		
		# Si c'est un 0, ajoute les voisins à la pile
		if board[curr_r][curr_c]["num"] == 0:
			for dir in DIRS8:
				var nr = curr_r + dir.x
				var nc = curr_c + dir.y
				if in_bounds(nr, nc, rows, cols) and not board[nr][nc]["revealed"]:
					stack.append(Vector2i(nr, nc))
	
	return changed_cells


func apply_logic_once(board: Array, rows: int, cols: int) -> bool:
	var changed := false
	for r in range(rows):
		for c in range(cols):
			var cell = board[r][c]
			if not cell["revealed"] or cell["mine"]:
				continue
			var n : int = cell["num"]
			var nb_list = neighbors(r, c, rows, cols)
			var flags := 0
			var unrevealed: Array = []
			for nb in nb_list:
				if board[nb.x][nb.y]["flag"]:
					flags += 1
				elif not board[nb.x][nb.y]["revealed"]:
					unrevealed.append(nb)
			if n == flags and unrevealed.size() > 0:
				for nb in unrevealed:
					board[nb.x][nb.y]["revealed"] = true
				changed = true
			elif n == flags + unrevealed.size() and unrevealed.size() > 0:
				for nb in unrevealed:
					if not board[nb.x][nb.y]["flag"]:
						board[nb.x][nb.y]["flag"] = true
						changed = true
	return changed


func is_solvable(board: Array, rows: int, cols: int, first_click: Vector2i) -> bool:
	flood_fill_reveal(board, first_click.x, first_click.y, rows, cols)
	var max_iters = rows * cols
	for i in range(max_iters):
		if not apply_logic_once(board, rows, cols):
			break
	for r in range(rows):
		for c in range(cols):
			if board[r][c]["revealed"] and board[r][c]["mine"]:
				return false
	return true


func deep_copy_board(board: Array, rows: int, cols: int) -> Array:
	var copy: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(board[r][c].duplicate())
		copy.append(row)
	return copy


# Génération classique rapide sans contrainte de solvabilité
func generate_mines_classic(rows: int, cols: int, n_mines: int, first_click: Vector2i, safe_radius := 1) -> Array:
	var board = create_empty_board(rows, cols)
	
	# Zone sûre autour du premier clic (garantit un 0)
	var safe_zone = compute_safe_zone_extended(first_click, rows, cols, safe_radius)
	
	# Placement aléatoire des mines
	var placed = 0
	var max_attempts = n_mines * 10
	var attempts = 0
	
	while placed < n_mines and attempts < max_attempts:
		attempts += 1
		var r = randi() % rows
		var c = randi() % cols
		var pos = Vector2i(r, c)
		
		# Ne place pas si déjà une mine ou dans la zone sûre
		if board[r][c]["mine"] or safe_zone.has(pos):
			continue
		
		board[r][c]["mine"] = true
		placed += 1
	
	if placed < n_mines:
		print("ATTENTION: Seulement ", placed, " mines placées sur ", n_mines, " demandées")
	
	calculate_numbers(board, rows, cols)
	
	# Vérifie que le premier clic est bien un 0
	print("Valeur au premier clic (", first_click.x, ",", first_click.y, ") = ", board[first_click.x][first_click.y]["num"])
	
	return board


# Génération avec contraintes strictes (solvable)
func generate_mines_solvable(rows: int, cols: int, n_mines: int, first_click: Vector2i, safe_radius := 1, max_zero_block_ratio := 0.25) -> Array:
	var all_cells = get_all_cells(rows, cols)
	var safe_zone = compute_safe_zone_extended(first_click, rows, cols, safe_radius)
	var available = filter_available_cells(all_cells, safe_zone)

	return generate_valid_board(rows, cols, n_mines, first_click, available, max_zero_block_ratio)


# --- Sous-fonctions --- #

func get_all_cells(rows: int, cols: int) -> Array:
	var cells: Array = []
	for r in range(rows):
		for c in range(cols):
			cells.append(Vector2i(r, c))
	return cells


# Zone sûre ÉTENDUE : garantit que le premier clic ET ses voisins n'ont pas de mine
func compute_safe_zone_extended(first_click: Vector2i, rows: int, cols: int, safe_radius: int) -> Dictionary:
	var safe_zone: Dictionary = {}
	var frontier: Array = [first_click]
	safe_zone[first_click] = true
	
	# Ajoute les voisins immédiats pour garantir un 0
	for nb in neighbors(first_click.x, first_click.y, rows, cols):
		safe_zone[nb] = true
		if safe_radius > 0:
			frontier.append(nb)
	
	# Étend la zone selon le safe_radius
	for i in range(safe_radius):
		var new_frontier: Array = []
		for cell in frontier:
			for nb in neighbors(cell.x, cell.y, rows, cols):
				if not safe_zone.has(nb):
					safe_zone[nb] = true
					new_frontier.append(nb)
		frontier = new_frontier
	
	return safe_zone


func filter_available_cells(all_cells: Array, safe_zone: Dictionary) -> Array:
	var available: Array = []
	for cell in all_cells:
		if not safe_zone.has(cell):
			available.append(cell)
	return available


func generate_valid_board(rows: int, cols: int, n_mines: int, first_click: Vector2i, available: Array, max_zero_block_ratio: float) -> Array:
	var board: Array
	var attempts := 0
	var max_attempts := 500  # Réduit pour éviter les longs freezes

	while attempts < max_attempts:
		attempts += 1
		board = create_empty_board(rows, cols)

		# Placement aléatoire des mines
		var placed_mines = available.duplicate()
		placed_mines.shuffle()
		for i in range(min(n_mines, placed_mines.size())):
			var m = placed_mines[i]
			board[m.x][m.y]["mine"] = true

		calculate_numbers(board, rows, cols)

		# Vérifie que le premier clic est un 0
		if board[first_click.x][first_click.y]["num"] != 0:
			continue

		# Vérifie le bloc de zéros
		if not is_zero_block_valid(board, rows, cols, first_click, max_zero_block_ratio):
			continue

		# Vérifie la solvabilité
		if is_solvable(deep_copy_board(board, rows, cols), rows, cols, first_click):
			print("Grille SOLVABLE trouvée en ", attempts, " tentatives")
			return board

	print("Limite de tentatives atteinte - génération en mode classique")
	return generate_mines_classic(rows, cols, n_mines, first_click, 1)


func is_zero_block_valid(board: Array, rows: int, cols: int, first_click: Vector2i, max_zero_block_ratio: float) -> bool:
	if board[first_click.x][first_click.y]["num"] != 0:
		return true

	var visited: Dictionary = {}
	var q: Array = [first_click]
	while q.size() > 0:
		var cur = q.pop_front()
		visited[cur] = true
		for nb in neighbors(cur.x, cur.y, rows, cols):
			if not visited.has(nb) and board[nb.x][nb.y]["num"] == 0:
				q.append(nb)
	return float(visited.size()) <= float(rows * cols) * max_zero_block_ratio


func create_board(rows: int, cols: int, n_mines: int, first_click := Vector2i(0, 0), safe_radius := 1, max_zero_block_ratio := 0.25, use_solvable := false) -> Array:
	if use_solvable:
		return generate_mines_solvable(rows, cols, n_mines, first_click, safe_radius, max_zero_block_ratio)
	else:
		return generate_mines_classic(rows, cols, n_mines, first_click, safe_radius)
