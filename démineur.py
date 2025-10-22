import random
from collections import deque

dirs8 = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]

def in_bounds(r, c, rows, cols):
    return 0 <= r < rows and 0 <= c < cols

def neighbors(r, c, rows, cols):
    for dr, dc in dirs8:
        rr, cc = r+dr, c+dc
        if in_bounds(rr, cc, rows, cols):
            yield rr, cc

def create_empty_board(rows, cols):
    return {(r,c): {"mine": False, "num": 0, "revealed": False, "flag": False} 
            for r in range(rows) for c in range(cols)}

def calculate_numbers(board, rows, cols):
    for r in range(rows):
        for c in range(cols):
            if board[(r,c)]["mine"]:
                board[(r,c)]["num"] = -1
            else:
                board[(r,c)]["num"] = sum(1 for nb in neighbors(r,c,rows,cols) if board[nb]["mine"])

def flood_fill_reveal(board, r, c, rows, cols):
    key = (r,c)
    if board[key]["revealed"] or board[key]["flag"]:
        return
    board[key]["revealed"] = True
    if board[key]["mine"]:
        return
    if board[key]["num"] == 0:
        q = deque([key])
        while q:
            cr, cc = q.popleft()
            for nb in neighbors(cr, cc, rows, cols):
                if not board[nb]["revealed"] and not board[nb]["flag"]:
                    board[nb]["revealed"] = True
                    if board[nb]["num"] == 0:
                        q.append(nb)

def apply_logic_once(board, rows, cols):
    changed = False
    for r in range(rows):
        for c in range(cols):
            cell = board[(r,c)]
            if not cell["revealed"] or cell["mine"]:
                continue
            n = cell["num"]
            nb_list = list(neighbors(r,c,rows,cols))
            flags = sum(1 for nb in nb_list if board[nb]["flag"])
            unrevealed = [nb for nb in nb_list if not board[nb]["revealed"] and not board[nb]["flag"]]
            if n == flags and unrevealed:
                for nb in unrevealed:
                    board[nb]["revealed"] = True
                changed = True
            elif n == flags + len(unrevealed) and unrevealed:
                for nb in unrevealed:
                    if not board[nb]["flag"]:
                        board[nb]["flag"] = True
                        changed = True
    return changed

def is_solvable(board, rows, cols, first_click):
    flood_fill_reveal(board, first_click[0], first_click[1], rows, cols)
    max_iters = rows*cols
    for _ in range(max_iters):
        if not apply_logic_once(board, rows, cols):
            break
    exploded = any(board[pos]["revealed"] and board[pos]["mine"] for pos in board)
    return not exploded

def create_empty_board_copy(board):
    return {k: v.copy() for k,v in board.items()}

def generate_mines_solvable(rows, cols, n_mines, first_click, safe_radius=1, max_zero_block_ratio=0.25):
    all_cells = [(r,c) for r in range(rows) for c in range(cols)]
    
    safe_zone = set()
    frontier = [first_click]
    safe_zone.add(first_click)
    for _ in range(safe_radius):
        new_frontier = []
        for cell in frontier:
            for nb in neighbors(cell[0], cell[1], rows, cols):
                if nb not in safe_zone:
                    safe_zone.add(nb)
                    new_frontier.append(nb)
        frontier = new_frontier

    available = [cell for cell in all_cells if cell not in safe_zone]

    attempts = 0
    max_attempts = 1000
    while attempts < max_attempts:
        attempts += 1
        mines = set(random.sample(available, n_mines))
        board = create_empty_board(rows, cols)
        for (r,c) in mines:
            board[(r,c)]["mine"] = True
        calculate_numbers(board, rows, cols)

        if board[first_click]["num"] == 0:
            visited = set()
            q = deque([first_click])
            while q:
                cr, cc = q.popleft()
                visited.add((cr, cc))
                for nb in neighbors(cr, cc, rows, cols):
                    if nb not in visited and board[nb]["num"] == 0:
                        q.append(nb)
            if len(visited) > (rows*cols) * max_zero_block_ratio:
                continue
        
        if is_solvable(create_empty_board_copy(board), rows, cols, first_click):
            return board
    return board

def create_board(rows, cols, n_mines, first_click=(0,0), safe_radius=1, max_zero_block_ratio=0.25):
    return generate_mines_solvable(rows, cols, n_mines, first_click, safe_radius, max_zero_block_ratio)

def print_board(board, rows, cols, reveal_all=False):
    for r in range(rows):
        row = []
        for c in range(cols):
            cell = board[(r,c)]
            if reveal_all or cell["revealed"]:
                row.append("*" if cell["mine"] else str(cell["num"]))
            else:
                row.append(".")
        print(" ".join(row))
    print()

# === Définition des types de génération ===
difficulty_config = {
    "facile":    {"rows": 10, "cols": 10, "n_mines": 10, "max_zero_block_ratio": 0.30},
    "moyen":     {"rows": 18, "cols": 18, "n_mines": 40, "max_zero_block_ratio": 0.25},
    "difficile": {"rows": 24, "cols": 24, "n_mines": 99, "max_zero_block_ratio": 0.10},
    "extreme":   {"rows": 50, "cols": 50, "n_mines": 900, "max_zero_block_ratio": 0.10}
}
if __name__ == "__main__":

    for level in ["facile", "moyen", "difficile", "extreme"]:
        config = difficulty_config[level]
        print(f"=== Génération {level.upper()} ===")
        board = create_board(
            config["rows"], 
            config["cols"], 
            config["n_mines"], 
            first_click=(config["rows"]//2, config["cols"]//2),
            safe_radius=2,
            max_zero_block_ratio=config["max_zero_block_ratio"]
        )
        flood_fill_reveal(board, config["rows"]//2, config["cols"]//2, config["rows"], config["cols"])
        
        print(">>> État après premier clic (partiel) :")
        print_board(board, config["rows"], config["cols"])

        print(">>> Grille complète (révélée) :")
        print_board(board, config["rows"], config["cols"], reveal_all=True)
