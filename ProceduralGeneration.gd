@tool
class_name MineSweeper

## ------------------------------------------------------------
##  MineSweeper
##  A utility class providing logic and generation functions 
##  for a fully solvable Minesweeper board.
## ------------------------------------------------------------

## 8-directional neighbor offsets (N, NE, E, SE, S, SW, W, NW)
const DIRS8 = [
	Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
	Vector2i(0, -1),  Vector2i(0, 1),
	Vector2i(1, -1),  Vector2i(1, 0),  Vector2i(1, 1)
]

## Checks whether (r, c) is inside the board boundaries.
func in_bounds(r: int, c: int, rows: int, cols: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

## Returns all valid neighboring cell coordinates around (r, c).
func neighbors(r: int, c: int, rows: int, cols: int) -> Array:
	var result: Array = []
	for dir in DIRS8:
		var rr = r + dir.x
		var cc = c + dir.y
		if in_bounds(rr, cc, rows, cols):
			result.append(Vector2i(rr, cc))
	return result

## Creates an empty Minesweeper board with the given size.
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

## Calculates adjacent mine counts for all non-mine cells.
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

## Reveals cells recursively using a flood fill (for zero-number areas).
func flood_fill_reveal(board: Array, r: int, c: int, rows: int, cols: int) -> void:
	if board[r][c]["revealed"] or board[r][c]["flag"]:
		return
	board[r][c]["revealed"] = true
	if board[r][c]["mine"]:
		return
	if board[r][c]["num"] == 0:
		var q: Array = [Vector2i(r, c)]
		while q.size() > 0:
			var cur: Vector2i = q.pop_front()
			for nb in neighbors(cur.x, cur.y, rows, cols):
				if not board[nb.x][nb.y]["revealed"] and not board[nb.x][nb.y]["flag"]:
					board[nb.x][nb.y]["revealed"] = true
					if board[nb.x][nb.y]["num"] == 0:
						q.append(nb)

## Applies one logical deduction pass (flagging or revealing safe cells).
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

## Determines whether the board can be logically solved without guessing.
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

## Creates a deep copy of the board array to avoid reference issues.
func deep_copy_board(board: Array, rows: int, cols: int) -> Array:
	var copy: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(board[r][c].duplicate())
		copy.append(row)
	return copy

## Generates a fully solvable Minesweeper board with safe first click.
func generate_mines_solvable(rows: int, cols: int, n_mines: int, first_click: Vector2i, safe_radius := 1, max_zero_block_ratio := 0.25) -> Array:
	var all_cells = get_all_cells(rows, cols)
	var safe_zone = compute_safe_zone(first_click, rows, cols, safe_radius)
	var available = filter_available_cells(all_cells, safe_zone)

	return generate_valid_board(rows, cols, n_mines, first_click, available, max_zero_block_ratio)

## Returns all board cell coordinates as Vector2i positions.
func get_all_cells(rows: int, cols: int) -> Array:
	var cells: Array = []
	for r in range(rows):
		for c in range(cols):
			cells.append(Vector2i(r, c))
	return cells

## Computes a dictionary of "safe" cells around the first click.
func compute_safe_zone(first_click: Vector2i, rows: int, cols: int, safe_radius: int) -> Dictionary:
	var safe_zone: Dictionary = {}
	var frontier: Array = [first_click]
	safe_zone[first_click] = true
	for i in range(safe_radius):
		var new_frontier: Array = []
		for cell in frontier:
			for nb in neighbors(cell.x, cell.y, rows, cols):
				if not safe_zone.has(nb):
					safe_zone[nb] = true
					new_frontier.append(nb)
		frontier = new_frontier
	return safe_zone

## Filters out safe-zone cells from the list of all possible mine locations.
func filter_available_cells(all_cells: Array, safe_zone: Dictionary) -> Array:
	var available: Array = []
	for cell in all_cells:
		if not safe_zone.has(cell):
			available.append(cell)
	return available

## Repeatedly generates random boards until one is solvable.
func generate_valid_board(rows: int, cols: int, n_mines: int, first_click: Vector2i, available: Array, max_zero_block_ratio: float) -> Array:
	var board: Array
	var attempts := 0
	var max_attempts := 1000

	while attempts < max_attempts:
		attempts += 1
		board = create_empty_board(rows, cols)

		# Random mine placement
		for i in range(n_mines):
			var m = available.pick_random()
			board[m.x][m.y]["mine"] = true

		calculate_numbers(board, rows, cols)

		# Validate zero-block size
		if not is_zero_block_valid(board, rows, cols, first_click, max_zero_block_ratio):
			continue

		# Check solvability
		if is_solvable(deep_copy_board(board, rows, cols), rows, cols, first_click):
			return board

	return board

## Ensures that the connected area of zero-number cells is not too large.
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

## Main entry point: creates a solvable board ready for play.
func create_board(rows: int, cols: int, n_mines: int, first_click := Vector2i(0, 0), safe_radius := 1, max_zero_block_ratio := 0.25) -> Array:
	return generate_mines_solvable(rows, cols, n_mines, first_click, safe_radius, max_zero_block_ratio)
