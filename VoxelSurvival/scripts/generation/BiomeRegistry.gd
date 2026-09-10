class_name BiomeRegistry
extends RefCounted

## Registry for all biomes in the game

static var biomes: Array = []
static var initialized: bool = false

# Biome IDs
const BIOME_PLAINS = 0
const BIOME_FOREST = 1
const BIOME_DESERT = 2
const BIOME_MOUNTAINS = 3

static func initialize():
	if initialized:
		return
	
	biomes.clear()
	
	# Create default biomes
	biomes.append(create_plains_biome())
	biomes.append(create_forest_biome())
	biomes.append(create_desert_biome())
	biomes.append(create_mountains_biome())
	
	initialized = true

static func get_biome_by_id(id: int) -> BiomeData:
	if not initialized:
		initialize()
	for biome in biomes:
		if biome.id == id:
			return biome
	return biomes[0]  # Return plains as default

static func get_biome_for_conditions(height: float, temperature: float, humidity: float) -> BiomeData:
	if not initialized:
		initialize()
	
	# Find best matching biome
	var best_biome = biomes[0]
	var best_score = -1.0
	
	for biome in biomes:
		if biome.is_in_biome(height, temperature, humidity):
			# Calculate how well this biome matches
			var height_mid = (biome.min_height + biome.max_height) / 2.0
			var temp_mid = (biome.min_temperature + biome.max_temperature) / 2.0
			var humid_mid = (biome.min_humidity + biome.max_humidity) / 2.0
			
			var score = 1.0 - abs(height - height_mid) / (biome.max_height - biome.min_height + 0.001)
			score += 1.0 - abs(temperature - temp_mid) / (biome.max_temperature - biome.min_temperature + 0.001)
			score += 1.0 - abs(humidity - humid_mid) / (biome.max_humidity - biome.min_humidity + 0.001)
			
			if score > best_score:
				best_score = score
				best_biome = biome
	
	return best_biome

static func get_all_biomes() -> Array:
	if not initialized:
		initialize()
	return biomes

static func create_plains_biome() -> BiomeData:
	var biome = BiomeData.new()
	biome.name = "Plains"
	biome.id = BIOME_PLAINS
	biome.min_height = -0.3
	biome.max_height = 0.3
	biome.min_temperature = 0.3
	biome.max_temperature = 0.7
	biome.min_humidity = 0.3
	biome.max_humidity = 0.6
	biome.surface_block = VoxelRegistry.BLOCK_GRASS
	biome.subsurface_block = VoxelRegistry.BLOCK_DIRT
	biome.subsurface_depth = 4
	biome.underground_block = VoxelRegistry.BLOCK_STONE
	biome.water_level = 62
	biome.tree_frequency = 0.05
	biome.grass_frequency = 0.3
	return biome

static func create_forest_biome() -> BiomeData:
	var biome = BiomeData.new()
	biome.name = "Forest"
	biome.id = BIOME_FOREST
	biome.min_height = -0.2
	biome.max_height = 0.4
	biome.min_temperature = 0.2
	biome.max_temperature = 0.6
	biome.min_humidity = 0.5
	biome.max_humidity = 1.0
	biome.surface_block = VoxelRegistry.BLOCK_GRASS
	biome.subsurface_block = VoxelRegistry.BLOCK_DIRT
	biome.subsurface_depth = 4
	biome.underground_block = VoxelRegistry.BLOCK_STONE
	biome.water_level = 62
	biome.tree_frequency = 0.3
	biome.grass_frequency = 0.2
	return biome

static func create_desert_biome() -> BiomeData:
	var biome = BiomeData.new()
	biome.name = "Desert"
	biome.id = BIOME_DESERT
	biome.min_height = -0.3
	biome.max_height = 0.2
	biome.min_temperature = 0.6
	biome.max_temperature = 1.0
	biome.min_humidity = 0.0
	biome.max_humidity = 0.3
	biome.surface_block = VoxelRegistry.BLOCK_SAND
	biome.subsurface_block = VoxelRegistry.BLOCK_SAND
	biome.subsurface_depth = 6
	biome.underground_block = VoxelRegistry.BLOCK_STONE
	biome.water_level = 60
	biome.tree_frequency = 0.0
	biome.grass_frequency = 0.0
	return biome

static func create_mountains_biome() -> BiomeData:
	var biome = BiomeData.new()
	biome.name = "Mountains"
	biome.id = BIOME_MOUNTAINS
	biome.min_height = 0.4
	biome.max_height = 1.0
	biome.min_temperature = 0.0
	biome.max_temperature = 0.5
	biome.min_humidity = 0.0
	biome.max_humidity = 1.0
	biome.surface_block = VoxelRegistry.BLOCK_STONE
	biome.subsurface_block = VoxelRegistry.BLOCK_STONE
	biome.subsurface_depth = 2
	biome.underground_block = VoxelRegistry.BLOCK_STONE
	biome.water_level = 58
	biome.tree_frequency = 0.02
	biome.grass_frequency = 0.05
	return biome
