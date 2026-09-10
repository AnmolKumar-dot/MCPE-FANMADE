class_name Main
extends Node3D

## Main game scene - coordinates world initialization and game flow

@onready var game_manager: GameManager = $GameManager
@onready var world_manager: WorldManager = $WorldManager
@onready var player: PlayerController = $Player
@onready var block_interaction: BlockInteraction = $Player/BlockInteraction
@onready var survival_system: SurvivalSystem = $Player/SurvivalSystem
@onready var day_night_cycle: DayNightCycle = $DayNightCycle
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var mobile_controls: MobileControls = $UI/MobileControls
@onready var hotbar_ui: Control = $UI/Hotbar
@onready var pause_menu: Control = $UI/PauseMenu
@onready var debug_overlay: Control = $UI/DebugOverlay

var inventory: Inventory = null
var crafting_manager: CraftingManager = null
var is_game_initialized: bool = false

func _ready():
	# Connect signals
	game_manager.world_created.connect(_on_world_created)
	game_manager.world_loaded.connect(_on_world_loaded)
	
	# Setup day/night cycle
	day_night_cycle.set_sun_light(sun_light)
	
	# Initialize systems
	inventory = Inventory.new()
	crafting_manager = CraftingManager.new()
	
	# Connect mobile controls to player
	if mobile_controls:
		mobile_controls.move_input.connect(player.set_move_input)
		mobile_controls.jump_pressed.connect(player.set_jump.bind(true))
		mobile_controls.jump_released.connect(player.set_jump.bind(false))
		mobile_controls.crouch_pressed.connect(player.set_crouch.bind(true))
		mobile_controls.crouch_released.connect(player.set_crouch.bind(false))
		mobile_controls.break_pressed.connect(_on_break_pressed)
		mobile_controls.break_released.connect(_on_break_released)
		mobile_controls.place_pressed.connect(_on_place_pressed)
		mobile_controls.inventory_toggled.connect(_on_inventory_toggled)
		mobile_controls.run_toggled.connect(_on_run_toggled)
	
	# Connect block interaction drops to inventory
	block_interaction.item_dropped.connect(_on_item_dropped)
	
	# Set references
	block_interaction.set_references(player, world_manager)
	world_manager.set_player(player)
	
	# Check if we should load existing world or create new one
	var save_exists = FileAccess.file_exists("user://world_save.json")
	
	if save_exists:
		load_saved_world()
	else:
		create_new_world("New World", 12345)
	
	is_game_initialized = true

func create_new_world(world_name: String, seed: int):
	game_manager.create_new_world(world_name, seed)
	
	# Initialize world with starting position at surface
	var start_pos = Vector3(0, 80, 0)
	world_manager.initialize_world(seed, start_pos)
	
	# Position player above ground
	player.global_position = start_pos
	
	# Give starter items
	inventory.add_item(VoxelRegistry.BLOCK_DIRT, 10)
	inventory.add_item(VoxelRegistry.BLOCK_WOOD, 5)
	
	# Update UI
	update_hotbar()

func load_saved_world():
	if world_manager.load_world():
		game_manager.load_world(game_manager.current_world_name)
		
		# Load player position from save
		var player_data = load_player_data()
		if player_data.has("position"):
			player.global_position = player_data.position
		
		# Load inventory
		if player_data.has("inventory"):
			inventory.deserialize(player_data.inventory)
		
		# Load survival stats
		if player_data.has("survival"):
			survival_system.deserialize(player_data.survival)
		
		update_hotbar()

func save_current_world():
	world_manager.save_world()
	save_player_data()

func save_player_data():
	var player_data = {
		"position": player.global_position,
		"rotation": player.rotation,
		"inventory": inventory.serialize(),
		"survival": survival_system.serialize()
	}
	
	var json_string = JSON.stringify(player_data)
	var file = FileAccess.open("user://player_save.json", FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()

func load_player_data() -> Dictionary:
	var file = FileAccess.open("user://player_save.json", FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	return data if data != null else {}

func update_hotbar():
	if hotbar_ui and hotbar_ui.has_method("set_inventory"):
		hotbar_ui.set_inventory(inventory)

func _on_world_created():
	pass

func _on_world_loaded():
	pass

func _on_break_pressed():
	block_interaction.start_breaking()

func _on_break_released():
	block_interaction.stop_breaking()

func _on_place_pressed():
	block_interaction.place_block()

func _on_inventory_toggled():
	game_manager.toggle_pause()

func _on_run_toggled(is_running: bool):
	player.set_run(is_running)

func _on_item_dropped(item_id: int, count: int):
	inventory.add_item(item_id, count)
	update_hotbar()

func _input(event):
	if event.is_action_pressed("inventory_toggle"):
		game_manager.toggle_pause()
	
	if event.is_action_pressed("ui_cancel") and game_manager.is_paused:
		game_manager.resume_game()

func _process(delta):
	# Update debug info
	if debug_overlay and debug_overlay.visible:
		update_debug_info()

func update_debug_info():
	if not debug_overlay.has_method("update_info"):
		return
	
	var chunk_pos = world_manager.world_to_chunk_coords(player.global_position)
	var loaded_chunks = world_manager.chunks.size()
	
	debug_overlay.update_info({
		"fps": Engine.get_frames_per_second(),
		"player_pos": player.global_position,
		"chunk": chunk_pos,
		"loaded_chunks": loaded_chunks,
		"biome": "Plains",  # Would need biome lookup
		"entities": 0
	})

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_current_world()
		get_tree().quit()
