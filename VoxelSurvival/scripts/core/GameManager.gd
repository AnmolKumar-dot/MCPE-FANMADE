class_name GameManager
extends Node

## Central game manager - handles game state, settings, and coordination

signal world_created
signal world_loaded
signal game_paused
signal game_resumed

# Singleton instance
static var instance: GameManager = null

# Game state
var is_game_active: bool = false
var is_paused: bool = false
var current_world_seed: int = 12345
var current_world_name: String = ""

# Settings
var render_distance: int = 4
var graphics_preset: String = "Medium"
var camera_sensitivity: float = 0.003
var joystick_sensitivity: float = 1.0
var button_size: float = 1.0
var button_opacity: float = 0.7

# Debug mode
var debug_mode: bool = false

func _ready():
if instance == null:
instance = self
# Don't free on scene change
# add_to_group("persistent")
else:
queue_free()
return

# Initialize registries
VoxelRegistry.initialize()
BiomeRegistry.initialize()

# Load saved settings
load_settings()

func _notification(what):
if what == NOTIFICATION_WM_QUIT_REQUEST:
save_settings()

static func get_instance() -> GameManager:
return instance

func create_new_world(world_name: String, seed: int, difficulty: String = "Normal", render_dist: int = 4):
current_world_name = world_name
current_world_seed = seed
render_distance = render_dist
is_game_active = true
is_paused = false

# Signal that world creation started
world_created.emit()

# The WorldManager will handle actual world creation
return true

func load_world(world_name: String):
# Load world from save
current_world_name = world_name
is_game_active = true
is_paused = false

world_loaded.emit()
return true

func pause_game():
if not is_paused:
is_paused = true
get_tree().paused = true
game_paused.emit()

func resume_game():
if is_paused:
is_paused = false
get_tree().paused = false
game_resumed.emit()

func toggle_pause():
if is_paused:
resume_game()
else:
pause_game()

func quit_to_menu():
is_game_active = false
is_paused = false
get_tree().paused = false

# Save current world if needed
var world_manager = get_node_or_null("/root/Main/WorldManager")
if world_manager != null:
world_manager.save_world()

# Change to main menu scene
get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func save_settings():
var config = ConfigFile.new()
config.set_value("graphics", "render_distance", render_distance)
config.set_value("graphics", "preset", graphics_preset)
config.set_value("controls", "camera_sensitivity", camera_sensitivity)
config.set_value("controls", "joystick_sensitivity", joystick_sensitivity)
config.set_value("controls", "button_size", button_size)
config.set_value("controls", "button_opacity", button_opacity)
config.save("user://settings.cfg")

func load_settings():
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
if err == OK:
render_distance = config.get_value("graphics", "render_distance", 4)
graphics_preset = config.get_value("graphics", "preset", "Medium")
camera_sensitivity = config.get_value("controls", "camera_sensitivity", 0.003)
joystick_sensitivity = config.get_value("controls", "joystick_sensitivity", 1.0)
button_size = config.get_value("controls", "button_size", 1.0)
button_opacity = config.get_value("controls", "button_opacity", 0.7)

func apply_graphics_preset(preset: String):
graphics_preset = preset

match preset:
"Very Low":
render_distance = 2
ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")
ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
"Low":
render_distance = 3
ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")
ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
"Medium":
render_distance = 4
ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 2)
"High":
render_distance = 6
ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 4)

save_settings()
