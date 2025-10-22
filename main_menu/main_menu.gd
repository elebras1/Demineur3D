extends Node

@onready var play_button = $CanvasLayer/VBoxContainer/Button

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_button.pressed.connect(_on_PlayButton_pressed)

func _on_PlayButton_pressed():
	var minesweeper_scene = load("res://minesweeper.tscn").instantiate()
	
	get_tree().current_scene.queue_free()
	get_tree().current_scene = minesweeper_scene
	get_tree().root.add_child(minesweeper_scene)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var player = minesweeper_scene.get_node("CharacterBody3D")
	var player_cam = player.get_node("Camera3D")
	player_cam.current = true
