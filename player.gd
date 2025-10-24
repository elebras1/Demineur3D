extends CharacterBody3D

@export var base_speed: float = 7.5
@export var max_air_speed: float = 12.0
@export var air_accel: float = 85.0
@export var ground_accel: float = 15.0
@export var friction: float = 8.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.0
@export var mouse_sensitivity: float = 0.005

var yaw: float = 0.0
var pitch: float = 0.0

@onready var cam: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/RayCast3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ray.enabled = true

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.5, 1.5)
		rotation.y = yaw
		cam.rotation.x = pitch

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_click_left()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_click_right()

func _physics_process(delta):
	var input_dir = get_input_direction()
	
	# Gravité
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_force

	if is_on_floor():
		apply_ground_movement(input_dir, delta)
	else:
		apply_air_movement(input_dir, delta)

	move_and_slide()

# -------------------------------------
# Mouvement au sol
# -------------------------------------
func apply_ground_movement(input_dir: Vector3, delta: float) -> void:
	if input_dir != Vector3.ZERO:
		var target_velocity = input_dir * base_speed
		velocity.x = lerp(velocity.x, target_velocity.x, ground_accel * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ground_accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

# -------------------------------------
# Mouvement aérien (air-strafe)
# -------------------------------------
func apply_air_movement(input_dir: Vector3, delta: float) -> void:
	if input_dir == Vector3.ZERO:
		return

	# accélération progressive dans la direction du mouvement
	var wishdir = input_dir.normalized()
	var wishspeed = max_air_speed
	var current_speed = velocity.dot(wishdir)

	var add_speed = wishspeed - current_speed
	if add_speed <= 0:
		return

	var accel = air_accel * delta
	if accel > add_speed:
		accel = add_speed

	velocity += wishdir * accel

	# limite la vitesse max horizontale
	var horizontal_vel = velocity
	horizontal_vel.y = 0
	if horizontal_vel.length() > max_air_speed:
		horizontal_vel = horizontal_vel.normalized() * max_air_speed
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.z

# -------------------------------------
# Gestion de la direction input caméra
# -------------------------------------
func get_input_direction() -> Vector3:
	var dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_Z):
		dir.z -= 1
	if Input.is_key_pressed(KEY_S):
		dir.z += 1
	if Input.is_key_pressed(KEY_Q):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		dir.x += 1
	dir = dir.normalized()
	return (transform.basis * dir).normalized()

# -------------------------------------
# Interaction via RayCast3D
# -------------------------------------
func _find_cell_from_collider(collider) -> Node:
	var cur = collider
	for i in range(8):
		if cur == null:
			break
		if cur is Cell:
			return cur
		cur = cur.get_parent()
	return null

func handle_click_left():
	if ray.is_colliding():
		var collider = ray.get_collider()
		var cell = _find_cell_from_collider(collider)
		if cell:
			cell.reveal()
			print("Clicked on cell:", cell, " at position:", ray.get_collision_point())

func handle_click_right():
	if ray.is_colliding():
		var collider = ray.get_collider()
		var cell = _find_cell_from_collider(collider)
		if cell:
			cell.toggle_flag()
