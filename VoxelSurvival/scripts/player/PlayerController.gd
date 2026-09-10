class_name PlayerController
extends CharacterBody3D

## First-person player controller with mobile touch support

# Movement settings
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var crouch_speed: float = 2.0
@export var gravity: float = 20.0

# Camera settings
@export var camera_sensitivity: float = 0.003
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

# Ground detection
@export var ground_ray_length: float = 1.1

# References
@onready var camera: Camera3D = $Camera3D
@onready var ground_ray: RayCast3D = $GroundRay

# State
var is_grounded: bool = false
var is_crouching: bool = false
var is_running: bool = false

# Touch input state
var touch_delta: Vector2 = Vector2.ZERO
var move_input: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var crouch_pressed: bool = false

# Head bob
var head_bob_timer: float = 0.0
var head_bob_frequency: float = 10.0
var head_bob_amplitude: float = 0.1

func _ready():
	# Initialize camera rotation from current rotation
	camera.rotation = rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_mouse_look(event.relative)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Cycle hotbar slot (will be handled by UI)
			pass
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pass

func handle_mouse_look(delta: Vector2):
	rotate_y(-delta.x * camera_sensitivity)
	
	var new_pitch = camera.rotation_degrees.x - delta.y * camera_sensitivity
	new_pitch = clamp(new_pitch, min_pitch, max_pitch)
	camera.rotation_degrees = Vector3(new_pitch, 0, 0)

func _physics_process(delta):
	handle_movement(delta)
	apply_gravity(delta)
	handle_jumping()
	handle_head_bob(delta)
	
	move_and_slide()
	
	is_grounded = is_on_floor() or ground_ray.is_colliding()

func handle_movement(delta):
	# Get input direction
	var input_dir = get_input_direction()
	
	if input_dir.length() > 0:
		# Calculate speed based on running and crouching
		var speed = walk_speed
		if is_running and not is_crouching:
			speed = run_speed
		elif is_crouching:
			speed = crouch_speed
		
		# Move player
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		# Slow down when no input
		velocity.x = lerp(velocity.x, 0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0, delta * 10.0)

func get_input_direction() -> Vector3:
	var input_dir = Vector3.ZERO
	
	# Keyboard input
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	# Touch joystick input
	input_dir.x += move_input.x
	input_dir.z += move_input.y
	
	# Normalize
	if input_dir.length() > 1:
		input_dir = input_dir.normalized()
	
	# Convert to world space relative to camera
	var direction = transform.basis * Vector3(input_dir.x, 0, input_dir.z)
	direction = direction.rotated(Vector3.UP, rotation.y)
	
	return direction

func apply_gravity(delta):
	if not is_grounded:
		velocity.y -= gravity * delta

func handle_jumping():
	if jump_pressed and is_grounded:
		velocity.y = jump_velocity
		jump_pressed = false

func handle_head_bob(delta):
	if is_grounded and velocity.length() > 0.5:
		head_bob_timer += delta * head_bob_frequency
		camera.transform.origin.y = sin(head_bob_timer) * head_bob_amplitude
	else:
		camera.transform.origin.y = lerp(camera.transform.origin.y, 0, delta * 5.0)

func set_move_input(dir: Vector2):
	move_input = dir

func set_jump(pressed: bool):
	jump_pressed = pressed

func set_crouch(pressed: bool):
	is_crouching = pressed

func set_run(pressed: bool):
	is_running = pressed

func take_damage(amount: float):
	# Will be called by survival system
	pass

func get_camera_transform() -> Transform3D:
	return camera.global_transform

func reset_player():
	velocity = Vector3.ZERO
	is_crouching = false
	is_running = false
	move_input = Vector2.ZERO
