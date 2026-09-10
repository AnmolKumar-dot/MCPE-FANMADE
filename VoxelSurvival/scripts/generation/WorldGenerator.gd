class_name WorldGenerator
extends RefCounted

## Procedural world generation system
## Generates terrain, biomes, caves, and ores

const CHUNK_SIZE = 16

# Noise generators
var height_noise: FastNoise2D
var temperature_noise: FastNoise2D
var humidity_noise: FastNoise2D
var cave_noise: FastNoise3D
var detail_noise: FastNoise2D

# Generation settings
var seed: int = 12345
var sea_level: int = 62
var terrain_scale: float = 0.02
var height_multiplier: float = 40.0
var cave_threshold: float = 0.45

func _init(s: int = 12345):
	set_seed(s)

func set_seed(s: int):
	seed = s
	height_noise = FastNoise2D.new(s)
	temperature_noise = FastNoise2D.new(s + 1)
	humidity_noise = FastNoise2D.new(s + 2)
	cave_noise = FastNoise3D.new(s + 3)
	detail_noise = FastNoise2D.new(s + 4)

func generate_chunk(chunk: VoxelChunk):
	if chunk.is_generated:
		return
	
	var chunk_world_pos = chunk.get_world_position()
	
	# Generate terrain for each column in the chunk
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var world_x = chunk.chunk_x * CHUNK_SIZE + x
			var world_z = chunk.chunk_z * CHUNK_SIZE + z
			
			# Get terrain height at this position
			var height = get_terrain_height(world_x, world_z)
			
			# Get biome data
			var temp = temperature_noise.octave_noise(world_x * 0.01, world_z * 0.01, 3)
			var humid = humidity_noise.octave_noise(world_x * 0.01, world_z * 0.01, 3)
			var biome = BiomeRegistry.get_biome_for_conditions(height / 128.0, (temp + 1) / 2.0, (humid + 1) / 2.0)
			
			# Fill column with blocks
			for y in range(CHUNK_SIZE):
				var world_y = chunk.chunk_y * CHUNK_SIZE + y
				var block_id = get_block_at(world_x, world_y, world_z, height, biome)
				
				if block_id != VoxelRegistry.BLOCK_AIR:
					chunk.set_block(x, y, z, block_id)
	
	# Generate structures (trees, etc.)
	generate_structures(chunk, chunk_world_pos)
	
	chunk.is_generated = true
	chunk.is_dirty = true

func get_terrain_height(world_x: int, world_z: int) -> int:
	# Base terrain using octave noise
	var base_height = height_noise.octave_noise(
		world_x * terrain_scale, 
		world_z * terrain_scale, 
		4, 0.5
	)
	
	# Add detail
	var detail = detail_noise.octave_noise(
		world_x * terrain_scale * 2, 
		world_z * terrain_scale * 2, 
		2, 0.3
	)
	
	# Combine and scale
	var height = sea_level + (base_height * height_multiplier) + (detail * height_multiplier * 0.2)
	return int(height)

func get_block_at(world_x: int, world_y: int, world_z: int, surface_height: int, biome: BiomeData) -> int:
	# Check for caves first
	var cave_value = cave_noise.octave_noise(
		world_x * 0.05, 
		world_y * 0.05, 
		world_z * 0.05, 
		3, 0.5
	)
	
	if cave_value > cave_threshold and world_y < surface_height - 5:
		return VoxelRegistry.BLOCK_AIR
	
	# Below surface
	if world_y < surface_height:
		# Surface block
		if world_y == surface_height - 1:
			return biome.get_surface_block()
		
		# Subsurface layers
		var depth = surface_height - world_y
		if depth <= biome.subsurface_depth:
			return biome.get_subsurface_block()
		
		# Deep underground - check for ores
		if world_y < sea_level - 10:
			var ore = get_ore_at(world_x, world_y, world_z, biome)
			if ore != VoxelRegistry.BLOCK_AIR:
				return ore
		
		# Stone layer
		return biome.get_underground_block()
	
	# At surface
	elif world_y == surface_height:
		return biome.get_surface_block()
	
	# Water
	elif world_y < sea_level:
		return VoxelRegistry.BLOCK_WATER
	
	# Air above surface
	return VoxelRegistry.BLOCK_AIR

func get_ore_at(world_x: int, world_y: int, world_z: int, biome: BiomeData) -> int:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(world_x, world_y, world_z)) + seed
	
	# Copper ore - spawns at mid depths
	if world_y < sea_level - 5 and world_y >= sea_level - 30:
		if rng.randf() < 0.02 * biome.ore_multiplier:
			return VoxelRegistry.BLOCK_COPPER_ORE
	
	# Iron ore - spawns deeper
	if world_y < sea_level - 15 and world_y >= sea_level - 50:
		if rng.randf() < 0.015 * biome.ore_multiplier:
			return VoxelRegistry.BLOCK_IRON_ORE
	
	# Crystal ore - spawns very deep
	if world_y < sea_level - 40:
		if rng.randf() < 0.008 * biome.ore_multiplier:
			return VoxelRegistry.BLOCK_CRYSTAL_ORE
	
	return VoxelRegistry.BLOCK_AIR

func generate_structures(chunk: VoxelChunk, chunk_pos: Vector3):
	var biome = BiomeRegistry.get_biome_by_id(0)  # Default biome
	
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var world_x = chunk.chunk_x * CHUNK_SIZE + x
			var world_z = chunk.chunk_z * CHUNK_SIZE + z
			
			# Find surface
			var surface_y = get_terrain_height(world_x, world_z)
			
			# Check if we should place a tree
			if rng_should_place_tree(world_x, world_z, biome.tree_frequency):
				# Verify surface is grass
				var surface_block = chunk.get_block(x, surface_y - chunk.chunk_y * CHUNK_SIZE, z)
				if surface_block == VoxelRegistry.BLOCK_GRASS or surface_block == VoxelRegistry.BLOCK_DIRT:
					generate_tree(chunk, x, surface_y - chunk.chunk_y * CHUNK_SIZE + 1, z, biome)

func rng_should_place_tree(world_x: int, world_z: int, frequency: float) -> bool:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(world_x, world_z)) + seed
	return rng.randf() < frequency

func generate_tree(chunk: VoxelChunk, local_x: int, local_y: int, local_z: int, biome: BiomeData):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(local_x, local_y, local_z)) + seed
	
	var tree_height = rng.randi_range(biome.min_tree_height, biome.max_tree_height)
	
	# Place trunk
	for y in range(tree_height):
		if local_y + y < CHUNK_SIZE:
			chunk.set_block(local_x, local_y + y, local_z, VoxelRegistry.BLOCK_WOOD)
	
	# Place leaves
	var leaf_start = local_y + tree_height - 2
	for ly in range(leaf_start, leaf_start + 3):
		for lx in range(-2, 3):
			for lz in range(-2, 3):
				if abs(lx) + abs(lz) <= 3:  # Diamond shape
					var nx = local_x + lx
					var ny = ly
					var nz = local_z + lz
					if nx >= 0 and nx < CHUNK_SIZE and ny >= 0 and ny < CHUNK_SIZE and nz >= 0 and nz < CHUNK_SIZE:
						var existing = chunk.get_block(nx, ny, nz)
						if existing == VoxelRegistry.BLOCK_AIR:
							chunk.set_block(nx, ny, nz, VoxelRegistry.BLOCK_LEAVES)
