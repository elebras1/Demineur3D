extends Node3D

@export var grid_width: int = 50
@export var grid_height: int = 50
@export var cell_size: float = 1.0
@export var num_mines: int = 900

var cell_scene = preload("res://cell.tscn")
var grid: Array = [] # 2D Array de nodes Cell
var generator: MineSweeper = MineSweeper.new()
var board: Array = []

func _ready():
	var first_click = Vector2i(5, 5)
	board = generator.create_board(grid_height, grid_width, num_mines, first_click)
	await generate_grid_3d()
	for i in range(grid_height):
		for j in range(grid_width):
			reveal_cell(j, i)

func generate_grid_3d() -> void:
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
			cell.value = board[y][x]["num"]
			if board[y][x]["mine"]:
				cell.value = -1
			cell.update_color()
			row.append(cell)
		grid.append(row)
		if y % 5 == 0:
			await get_tree().process_frame

func reveal_cell(x: int, y: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	var cell = grid[y][x]
	if cell.state != 0:
		return
	cell.state = 1
	cell.update_color()
	board[y][x]["revealed"] = true
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
		board[y][x]["flag"] = true
	elif cell.state == 2:
		cell.state = 0
		board[y][x]["flag"] = false
	cell.update_color()
