extends CharacterBody3D

@export var speed : float = 5.0
@export var jump_force : float = 4.5
@export var gravity : float = 9.8
@export var mouse_sensitivity : float = 0.003

var yaw : float = 0.0
var pitch : float = 0.0
@onready var cam = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.2, 1.2)
		rotation.y = yaw
		cam.rotation.x = pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_key_pressed(KEY_Z):
		direction.z -= 1
	if Input.is_key_pressed(KEY_S):
		direction.z += 1
	if Input.is_key_pressed(KEY_Q):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	direction = direction.normalized()
	var global_dir = transform.basis * direction
	velocity.x = global_dir.x * speed
	velocity.z = global_dir.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_force

	move_and_slide()
