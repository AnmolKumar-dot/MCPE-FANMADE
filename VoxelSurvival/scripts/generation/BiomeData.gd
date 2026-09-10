class_name BiomeData
extends Resource

## Data defining a biome's properties

@export var name: String = "Plains"
@export var id: int = 0

# Noise parameters for biome selection
@export var min_height: float = -1.0
@export var max_height: float = 1.0
@export var min_temperature: float = 0.0
@export var max_temperature: float = 1.0
@export var min_humidity: float = 0.0
@export var max_humidity: float = 1.0

# Surface block configuration
@export var surface_block: int = VoxelRegistry.BLOCK_GRASS
@export var subsurface_block: int = VoxelRegistry.BLOCK_DIRT
@export var subsurface_depth: int = 3

# Underground block (below subsurface)
@export var underground_block: int = VoxelRegistry.BLOCK_STONE

# Water level for this biome
@export var water_level: int = 64

# Tree generation settings
@export var tree_frequency: float = 0.0  # 0-1 probability per valid position
@export var min_tree_height: int = 4
@export var max_tree_height: int = 7

# Vegetation settings
@export var grass_frequency: float = 0.2
@export var flower_frequency: float = 0.05

# Ore modifiers (multiplier for ore frequency in this biome)
@export var ore_multiplier: float = 1.0

func _init():
	pass

func is_in_biome(height: float, temperature: float, humidity: float) -> bool:
	return height >= min_height and height <= max_height and \
		   temperature >= min_temperature and temperature <= max_temperature and \
		   humidity >= min_humidity and humidity <= max_humidity

func get_surface_block() -> int:
	return surface_block

func get_subsurface_block() -> int:
	return subsurface_block

func get_underground_block() -> int:
	return underground_block
