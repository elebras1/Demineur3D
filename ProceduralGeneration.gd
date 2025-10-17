@tool
class_name MineSweeper
extends Node3D

## Eight directional neighbor vectors (N, NE, E, SE, S, SW, W, NW)
var dirs8 = [
	Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
	Vector2i(0, -1),  Vector2i(0, 1),
	Vector2i(1, -1),  Vector2i(1, 0),  Vector2i(1, 1)
]

## Checks if a position is inside the grid boundaries.
## @param r Row index
## @param c Column index
## @param rows Total number of rows
## @param cols Total number of columns
## @return True if inside grid, False otherwise
func in_bounds(r: int, c: int, rows: int, cols: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols


## Returns all valid 8-directional neighbors for a given cell.
## @param r Row index
## @param c Column index
## @param rows Total number of rows
## @param cols Total number of columns
## @return Array of valid neighbor coordinates
func neighbors(r: int, c: int, rows: int, cols: int) -> Array:
	var result = []
	for dir in dirs8:
		var rr = r + dir.x
		var cc = c + dir.y
		if in_bounds(rr, cc, rows, cols):
			result.append(Vector2i(rr, cc))
	return result


## Creates an empty board with default cell data.
## Each cell is represented by a Dictionary containing:
## "mine", "num", "revealed", "flag".
## @param rows Number of rows
## @param cols Number of columns
## @return A Dictionary mapping Vector2i to cell data
func create_empty_board(rows: int, cols: int) -> Dictionary:
	var board = {}
	for r in range(rows):
		for c in range(cols):
			board[Vector2i(r, c)] = {
				"mine": false,
				"num": 0,
				"revealed": false,
				"flag": false
			}
	return board


## Calculates the number of adjacent mines for each cell.
## @param board The board dictionary
## @param rows Number of rows
## @param cols Number of columns
func calculate_numbers(board: Dictionary, rows: int, cols: int) -> void:
	for r in range(rows):
		for c in range(cols):
			var key = Vector2i(r, c)
			if board[key]["mine"]:
				board[key]["num"] = -1
			else:
				var count = 0
				for nb in neighbors(r, c, rows, cols):
					if board[nb]["mine"]:
						count += 1
				board[key]["num"] = count


## Reveals all connected zero-number cells recursively (flood fill).
## @param board The game board
## @param r Starting row
## @param c Starting column
## @param rows Number of rows
## @param cols Number of columns
func flood_fill_reveal(board: Dictionary, r: int, c: int, rows: int, cols: int) -> void:
	var key = Vector2i(r, c)
	if board[key]["revealed"] or board[key]["flag"]:
		return
	board[key]["revealed"] = true
	if board[key]["mine"]:
		return
	if board[key]["num"] == 0:
		var q = [key]
		while q.size() > 0:
			var current = q.pop_front()
			for nb in neighbors(current.x, current.y, rows, cols):
				if not board[nb]["revealed"] and not board[nb]["flag"]:
					board[nb]["revealed"] = true
					if board[nb]["num"] == 0:
						q.append(nb)


## Applies one step of basic logic deduction (auto-reveal or flagging).
## @param board Game board
## @param rows Number of rows
## @param cols Number of columns
## @return True if any cell changed state
func apply_logic_once(board: Dictionary, rows: int, cols: int) -> bool:
	var changed = false
	for r in range(rows):
		for c in range(cols):
			var cell = board[Vector2i(r, c)]
			if not cell["revealed"] or cell["mine"]:
				continue
			var n = cell["num"]
			var nb_list = neighbors(r, c, rows, cols)
			var flags = 0
			var unrevealed = []
			for nb in nb_list:
				if board[nb]["flag"]:
					flags += 1
				elif not board[nb]["revealed"]:
					unrevealed.append(nb)
			if n == flags and unrevealed.size() > 0:
				for nb in unrevealed:
					board[nb]["revealed"] = true
				changed = true
			elif n == flags + unrevealed.size() and unrevealed.size() > 0:
				for nb in unrevealed:
					if not board[nb]["flag"]:
						board[nb]["flag"] = true
						changed = true
	return changed


## Checks if a generated board is solvable from the first click.
## @param board Game board
## @param rows Number of rows
## @param cols Number of columns
## @param first_click Initial click position
## @return True if solvable
func is_solvable(board: Dictionary, rows: int, cols: int, first_click: Vector2i) -> bool:
	flood_fill_reveal(board, first_click.x, first_click.y, rows, cols)
	var max_iters = rows * cols
	for i in range(max_iters):
		if not apply_logic_once(board, rows, cols):
			break
	for pos in board.keys():
		if board[pos]["revealed"] and board[pos]["mine"]:
			return false
	return true


## Creates a deep copy of the given board.
## @param board Original board
## @return Duplicated board dictionary
func create_empty_board_copy(board: Dictionary) -> Dictionary:
	var copy = {}
	for k in board.keys():
		copy[k] = board[k].duplicate()
	return copy


## Generates a solvable minefield respecting a safe zone.
## @param rows Number of rows
## @param cols Number of columns
## @param n_mines Number of mines
## @param first_click Initial click position
## @param safe_radius Radius of guaranteed safe zone
## @param max_zero_block_ratio Max ratio of empty zero-number zones
## @return Solvable board dictionary
func generate_mines_solvable(rows: int, cols: int, n_mines: int, first_click: Vector2i, safe_radius := 1, max_zero_block_ratio := 0.25) -> Dictionary:
	var all_cells = []
	for r in range(rows):
		for c in range(cols):
			all_cells.append(Vector2i(r, c))
	
	var safe_zone = {}
	var frontier = [first_click]
	safe_zone[first_click] = true
	for i in range(safe_radius):
		var new_frontier = []
		for cell in frontier:
			for nb in neighbors(cell.x, cell.y, rows, cols):
				if not safe_zone.has(nb):
					safe_zone[nb] = true
					new_frontier.append(nb)
		frontier = new_frontier
	
	var available = []
	for cell in all_cells:
		if not safe_zone.has(cell):
			available.append(cell)
	
	var attempts = 0
	var max_attempts = 1000
	var board = create_empty_board(rows, cols)

	while attempts < max_attempts:
		attempts += 1
		var mines = []
		for i in range(n_mines):
			mines.append(available.pick_random())
		
		board = create_empty_board(rows, cols)
		for m in mines:
			board[m]["mine"] = true
		calculate_numbers(board, rows, cols)
		
		if board[first_click]["num"] == 0:
			var visited = {}
			var q = [first_click]
			while q.size() > 0:
				var cur = q.pop_front()
				visited[cur] = true
				for nb in neighbors(cur.x, cur.y, rows, cols):
					if not visited.has(nb) and board[nb]["num"] == 0:
						q.append(nb)
			if float(visited.size()) > float(rows * cols) * max_zero_block_ratio:
				continue
		
		if is_solvable(create_empty_board_copy(board), rows, cols, first_click):
			return board
	
	return board


## Creates a solvable board using default parameters.
func create_board(rows: int, cols: int, n_mines: int, first_click := Vector2i(0, 0), safe_radius := 1, max_zero_block_ratio := 0.25) -> Dictionary:
	return generate_mines_solvable(rows, cols, n_mines, first_click, safe_radius, max_zero_block_ratio)


## Prints the board in console for debugging.
func print_board(board: Dictionary, rows: int, cols: int, reveal_all := false) -> void:
	for r in range(rows):
		var row = []
		for c in range(cols):
			var cell = board[Vector2i(r, c)]
			if reveal_all or cell["revealed"]:
				row.append("*" if cell["mine"] else str(cell["num"]))
			else:
				row.append(".")
		print(" ".join(row))
	print("")


## Difficulty presets for multiple modes.
var difficulty_config = {
	"facile": {"rows": 10, "cols": 10, "n_mines": 10, "max_zero_block_ratio": 0.30},
	"moyen": {"rows": 18, "cols": 18, "n_mines": 40, "max_zero_block_ratio": 0.25},
	"difficile": {"rows": 24, "cols": 24, "n_mines": 99, "max_zero_block_ratio": 0.10},
	"extreme": {"rows": 50, "cols": 50, "n_mines": 900, "max_zero_block_ratio": 0.10}
}


## Called when node enters the scene tree.
## Generates and prints sample boards for all difficulty levels.
func _ready():
	for level in ["facile", "moyen", "difficile", "extreme"]:
		var config = difficulty_config[level]
		print("=== Génération %s ===" % level.to_upper())
		var board = create_board(
			config["rows"], 
			config["cols"], 
			config["n_mines"], 
			Vector2i(config["rows"] / 2, config["cols"] / 2),
			2,
			config["max_zero_block_ratio"]
		)
		flood_fill_reveal(board, config["rows"] / 2, config["cols"] / 2, config["rows"], config["cols"])
		
		print(">>> État après premier clic (partiel) :")
		print_board(board, config["rows"], config["cols"])
		
		print(">>> Grille complète (révélée) :")
		print_board(board, config["rows"], config["cols"], true)
