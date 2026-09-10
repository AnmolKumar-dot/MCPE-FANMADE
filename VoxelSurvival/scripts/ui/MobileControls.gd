class_name MobileControls
extends CanvasLayer

## Mobile touch controls - joystick and action buttons

signal move_input(dir: Vector2)
signal jump_pressed
signal jump_released
signal crouch_pressed
signal crouch_released
signal break_pressed
signal break_released
signal place_pressed
signal inventory_toggled
signal run_toggled

# References to control nodes
var joystick: TouchScreenJoystick = null
var jump_button: TextureButton = null
var crouch_button: TextureButton = null
var break_button: TextureButton = null
var place_button: TextureButton = null
var inventory_button: TextureButton = null
var run_button: TextureButton = null

# State
var is_running: bool = false

func _ready():
	setup_controls()

func setup_controls():
	# Find or create control nodes
	joystick = $Joystick as TouchScreenJoystick
	jump_button = $Buttons/JumpButton as TextureButton
	crouch_button = $Buttons/CrouchButton as TextureButton
	break_button = $Buttons/BreakButton as TextureButton
	place_button = $Buttons/PlaceButton as TextureButton
	inventory_button = $Buttons/InventoryButton as TextureButton
	run_button = $Buttons/RunButton as TextureButton
	
	if joystick:
		joystick.joystick_input.connect(_on_joystick_input)
	
	if jump_button:
		jump_button.pressed.connect(_on_jump_pressed)
		jump_button.released.connect(_on_jump_released)
	
	if crouch_button:
		crouch_button.pressed.connect(_on_crouch_pressed)
		crouch_button.released.connect(_on_crouch_released)
	
	if break_button:
		break_button.pressed.connect(_on_break_pressed)
		break_button.released.connect(_on_break_released)
	
	if place_button:
		place_button.pressed.connect(_on_place_pressed)
	
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_toggled)
	
	if run_button:
		run_button.toggled.connect(_on_run_toggled)

func _on_joystick_input(direction: Vector2):
	move_input.emit(direction)

func _on_jump_pressed():
	jump_pressed.emit()

func _on_jump_released():
	jump_released.emit()

func _on_crouch_pressed():
	crouch_pressed.emit()

func _on_crouch_released():
	crouch_released.emit()

func _on_break_pressed():
	break_pressed.emit()

func _on_break_released():
	break_released.emit()

func _on_place_pressed():
	place_pressed.emit()

func _on_inventory_toggled():
	inventory_toggled.emit()

func _on_run_toggled(toggled_on: bool):
	is_running = toggled_on
	run_toggled.emit()

func set_control_visibility(visible: bool):
	visible = visible

func set_button_size(size: float):
	if joystick:
		joystick.custom_minimum_size = Vector2(100 * size, 100 * size)
	
	var buttons = [jump_button, crouch_button, break_button, place_button, inventory_button, run_button]
	for btn in buttons:
		if btn:
			btn.custom_minimum_size = Vector2(60 * size, 60 * size)

func set_button_opacity(opacity: float):
	modulate.a = opacity

func save_layout() -> Dictionary:
	var layout = {}
	if joystick:
		layout["joystick_pos"] = joystick.position
		layout["joystick_size"] = joystick.custom_minimum_size
	
	var buttons = {
		"jump": jump_button,
		"crouch": crouch_button,
		"break": break_button,
		"place": place_button,
		"inventory": inventory_button,
		"run": run_button
	}
	
	for name in buttons.keys():
		if buttons[name]:
			layout[name + "_pos"] = buttons[name].position
			layout[name + "_size"] = buttons[name].custom_minimum_size
	
	return layout

func load_layout(layout: Dictionary):
	if layout.has("joystick_pos") and joystick:
		joystick.position = layout.joystick_pos
	if layout.has("joystick_size") and joystick:
		joystick.custom_minimum_size = layout.joystick_size
	
	var buttons = {
		"jump": jump_button,
		"crouch": crouch_button,
		"break": break_button,
		"place": place_button,
		"inventory": inventory_button,
		"run": run_button
	}
	
	for name in buttons.keys():
		if buttons[name]:
			if layout.has(name + "_pos"):
				buttons[name].position = layout[name + "_pos"]
			if layout.has(name + "_size"):
				buttons[name].custom_minimum_size = layout[name + "_size"]
