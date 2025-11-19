extends Node3D

@export var grid_width: int = 50
@export var grid_height: int = 50
@export var cell_size: float = 1.0
@export var num_mines: int = 300

var cell_scene = preload("res://cell.tscn")
var grid: Array = []
var generator: MineSweeper
var board: Array = []
var is_first_click: bool = true
var is_generating: bool = false
var is_finish: bool = false
var pyramid: Pyramid
var grid_root : Node3D
var win_label: Label3D = null

func get_is_finish():
	return is_finish
	
func set_is_finish(finish: Dictionary):
	is_finish = finish["finished"]
	
	if finish["won"]:
		show_win_label()
	else:
		show_lose_label()
	

func show_win_label():
	if win_label:
		win_label.queue_free()
	
	win_label = Label3D.new()
	add_child(win_label)
	
	# Position au centre de la grille, en hauteur
	var center_x = (grid_width * cell_size) / 2.0
	var center_z = (grid_height * cell_size) / 2.0
	win_label.position = Vector3(center_x, 3.0, center_z)
	
	# Texte et style
	win_label.text = "🎉 VICTORY! 🎉"
	win_label.font_size = 128
	win_label.modulate = Color(0, 1, 0)  # Vert
	win_label.outline_size = 8
	win_label.outline_modulate = Color(0, 0, 0)
	win_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func show_lose_label():
	if win_label:
		win_label.queue_free()
	
	win_label = Label3D.new()
	add_child(win_label)
	
	# Position au centre de la grille, en hauteur
	var center_x = (grid_width * cell_size) / 2.0
	var center_z = (grid_height * cell_size) / 2.0
	win_label.position = Vector3(center_x, 3.0, center_z)
	
	# Texte et style
	win_label.text = "💥 GAME OVER 💥"
	win_label.font_size = 128
	win_label.modulate = Color(1, 0, 0)  # Rouge
	win_label.outline_size = 8
	win_label.outline_modulate = Color(0, 0, 0)
	win_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
func restart_after_delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	restart_game()

func restart_game():
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")


func _ready():
	grid_root = Node3D.new()
	generator = MineSweeper.new()
	add_child(generator)
	add_child(grid_root)
	pyramid = Pyramid.new()
	pyramid.create(grid_width, grid_height , cell_size, self)
	pyramid.pyramid_body.position.y = pyramid.pyramid_body.position.y + 0.1
	await generate_empty_grid_3d()

# Génère une grille vide (sans mines)
func generate_empty_grid_3d() -> void:
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell = cell_scene.instantiate()
			grid_root.add_child(cell)
			cell.position = Vector3(x * cell_size, 0, y * cell_size)
			
			# IMPORTANT: Réinitialiser TOUS les paramètres de la cellule
			cell.grid_pos = Vector2i(x, y)
			cell.parent_grid = self
			cell.is_dark = (x + y) % 2 == 1
			cell.state = 0
			cell.value = 0
			cell.board = []  # Réinitialiser le board
			cell.generator = null  # Réinitialiser le generator
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
	
	var safe_radius = 1
	var max_zero_ratio = 0.5
	
	var first_click_rowcol = Vector2i(first_click.y, first_click.x)
	
	
	board = generator.create_board(grid_height, grid_width, num_mines, first_click_rowcol, safe_radius, max_zero_ratio, false)
	
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
	
	var clicked_cell = grid[first_click.y][first_click.x]
	clicked_cell.reveal()

func on_cell_clicked(cell: Cell):
	if is_finish:
		return
	if is_generating:
		return
	
	if is_first_click:
		await generate_board_from_first_click(cell.grid_pos)
	else:
		cell.reveal()

func on_cell_right_clicked(cell: Cell):
	if is_finish:
		return
	if is_first_click or is_generating:
		return
	
	cell.toggle_flag()

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
