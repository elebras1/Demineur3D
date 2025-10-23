extends Node

@onready var play_button: Button = $CanvasLayer/VBoxContainer/Button
@onready var option_button: OptionButton = $CanvasLayer/VBoxContainer/OptionButton

var difficulties: Dictionary = {
	0: {"rows": 10, "cols": 10, "mines": 10},    # Facile
	1: {"rows": 18, "cols": 18, "mines": 40},    # Moyen
	2: {"rows": 24, "cols": 24, "mines": 99},    # Difficile
	3: {"rows": 50, "cols": 50, "mines": 900}    # Extrême
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_button.pressed.connect(_on_PlayButton_pressed)

func _on_PlayButton_pressed() -> void:
	var minesweeper_scene: Node = load("res://minesweeper.tscn").instantiate() as Node

	var diff_index: int = int(option_button.selected)
	var cfg: Dictionary = difficulties.get(diff_index, difficulties[0])

	minesweeper_scene.set("grid_width", cfg["cols"])
	minesweeper_scene.set("grid_height", cfg["rows"])
	minesweeper_scene.set("num_mines", cfg["mines"])

	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = minesweeper_scene
	get_tree().root.add_child(minesweeper_scene)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player: Node = minesweeper_scene.get_node_or_null("CharacterBody3D")
	if player:
		var player_cam: Node = player.get_node_or_null("Camera3D")
		if player_cam:
			player_cam.current = true
