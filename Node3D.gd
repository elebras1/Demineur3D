extends Node3D

var dirs8 = [
	Vector2(-1,-1), Vector2(-1,0), Vector2(-1,1),
	Vector2(0,-1),                Vector2(0,1),
	Vector2(1,-1),  Vector2(1,0), Vector2(1,1)
]

# === Helpers
func in_bounds(r, c, rows, cols):
	return r >= 0 and r < rows and c >= 0 and c < cols

func neighbors(r, c, rows, cols):
	var result = []
	for dir in dirs8:
		var rr = r + int(dir.x)
		var cc = c + int(dir.y)
		if in_bounds(rr, cc, rows, cols):
			result.append(Vector2(rr, cc))
	return result

func create_empty_board(rows, cols):
	var board = {}
	for r in range(rows):
		for c in range(cols):
			board[str(r)+","+str(c)] = {"mine": false, "num": 0, "revealed": false, "flag": false}
	return board

func calculate_numbers(board, rows, cols):
	for r in range(rows):
		for c in range(cols):
			var key = str(r)+","+str(c)
			if board[key]["mine"]:
				board[key]["num"] = -1
			else:
				var cnt = 0
				for nb in neighbors(r,c,rows,cols):
					var nkey = str(int(nb.x))+","+str(int(nb.y))
					if board[nkey]["mine"]:
						cnt += 1
				board[key]["num"] = cnt

# === Solveur logique pour test de solvabilité
func logic_solve(board, rows, cols):
	var changed = true
	while changed:
		changed = false
		for r in range(rows):
			for c in range(cols):
				var key = str(r)+","+str(c)
				var cell = board[key]
				if not cell["revealed"] or cell["mine"]:
					continue
				var n = cell["num"]
				var nb_list = neighbors(r,c,rows,cols)
				var flags = 0
				var unrevealed = []
				for nb in nb_list:
					var nkey = str(int(nb.x))+","+str(int(nb.y))
					if board[nkey]["flag"]:
						flags += 1
					elif not board[nkey]["revealed"]:
						unrevealed.append(nkey)
				if n == flags and unrevealed.size() > 0:
					for u in unrevealed:
						board[u]["revealed"] = true
						changed = true
				elif n == flags + unrevealed.size() and unrevealed.size() > 0:
					for u in unrevealed:
						board[u]["flag"] = true
						changed = true
	for key in board.keys():
		if not board[key]["mine"] and not board[key]["revealed"]:
			return false
	return true

func is_solvable(board, rows, cols, first_click):
	var test_board = {}
	for key in board.keys():
		test_board[key] = {}
		for k in board[key].keys():
			test_board[key][k] = board[key][k]
	var key_click = str(int(first_click.x))+","+str(int(first_click.y))
	test_board[key_click]["revealed"] = true
	return logic_solve(test_board, rows, cols)

# === Générateur solvable avec safe_radius pour placement
func place_mines_logic(rows, cols, n_mines, first_click, safe_radius=1):
	var board = create_empty_board(rows, cols)
	
	# Construire la zone sûre pour placement des mines
	var safe_zone = [first_click]
	var frontier = [first_click]
	for _i in range(safe_radius):
		var new_frontier = []
		for cell in frontier:
			for nb in neighbors(cell.x, cell.y, rows, cols):
				if not nb in safe_zone:
					safe_zone.append(nb)
					new_frontier.append(nb)
		frontier = new_frontier
	
	# Cases disponibles pour placer les mines
	var all_cells = []
	for r in range(rows):
		for c in range(cols):
			var pos = Vector2(r,c)
			if not pos in safe_zone:
				all_cells.append(pos)
	
	var attempts = 0
	while attempts < 10000:
		attempts += 1
		# Reset board
		for key in board.keys():
			board[key]["mine"] = false
			board[key]["revealed"] = false
			board[key]["flag"] = false
		# Choisir positions des mines
		var shuffled = all_cells.duplicate()
		shuffled.shuffle()
		for i in range(n_mines):
			var m = shuffled[i]
			board[str(int(m.x))+","+str(int(m.y))]["mine"] = true
		calculate_numbers(board, rows, cols)
		# Vérifier solvabilité
		if is_solvable(board, rows, cols, first_click):
			return board
	push_error("Impossible de générer une grille 100% solvable après beaucoup d'essais")
	return board

# === Flood-fill classique
func reveal(board, r, c, rows, cols):
	var key = str(r)+","+str(c)
	if board[key]["revealed"] or board[key]["flag"]:
		return
	board[key]["revealed"] = true
	if board[key]["mine"]:
		return
	if board[key]["num"] == 0:
		var q = [Vector2(r,c)]
		while q.size() > 0:
			var current = q.pop_front()
			for nb in neighbors(current.x, current.y, rows, cols):
				var nkey = str(int(nb.x))+","+str(int(nb.y))
				if not board[nkey]["revealed"] and not board[nkey]["flag"]:
					board[nkey]["revealed"] = true
					if board[nkey]["num"] == 0 and not board[nkey]["mine"]:
						q.append(nb)

# === Affichage console
func print_board(board, rows, cols, reveal_all=false):
	for r in range(rows):
		var rowstr = ""
		for c in range(cols):
			var cell = board[str(r)+","+str(c)]
			if reveal_all or cell["revealed"]:
				if cell["mine"]:
					rowstr += "* "
				else:
					rowstr += str(cell["num"]) + " "
			else:
				if cell["flag"]:
					rowstr += "F "
				else:
					rowstr += ". "
		print(rowstr)
	print("")

func count_revealed(board):
	var total = 0
	for key in board.keys():
		if board[key]["revealed"]:
			total += 1
	return total

# === Simulation
func _ready():
	randomize()
	var rows = 12
	var cols = 12
	var n_mines = 30
	var safe_radius = 1  # rayon maximal de la zone sûre pour le placement des mines
	var first_click = Vector2(rows/2, cols/2)
	
	var board = place_mines_logic(rows, cols, n_mines, first_click, safe_radius)
	
	# Révélation flood-fill classique à partir du premier clic
	reveal(board, int(first_click.x), int(first_click.y), rows, cols)
	
	print("=== État après premier clic ===")
	print_board(board, rows, cols)
	
	var total_revealed = count_revealed(board)
	print("Nombre total de cases révélées après premier clic : ", total_revealed)
	
	print("=== Grille complète (résultat final) ===")
	print_board(board, rows, cols, true)
