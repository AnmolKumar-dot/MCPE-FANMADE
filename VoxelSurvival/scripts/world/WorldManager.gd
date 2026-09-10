class_name WorldManager
extends Node

## Manages the voxel world - chunk loading, unloading, and streaming

const CHUNK_SIZE = 16

# Chunks stored by chunk coordinates (Vector3i -> VoxelChunk)
var chunks: Dictionary = {}

# Generator
var generator: WorldGenerator = null

# Player reference for chunk streaming
var player: Node3D = null

# Streaming settings
var render_distance: int = 4
var load_distance: int = 5
var unload_distance: int = 7

# Generation queue
var generation_queue: Array = []
var max_generations_per_frame: int = 2

# Mesh update queue  
var mesh_update_queue: Array = []

# Modified chunks (for saving)
var modified_chunks: Dictionary = {}

func _ready():
	generator = WorldGenerator.new(12345)
	set_process(true)

func initialize_world(seed: int, start_pos: Vector3):
	# Set seed and initialize registries
	VoxelRegistry.initialize()
	BiomeRegistry.initialize()
	
	generator.set_seed(seed)
	
	# Generate initial chunks around start position
	var start_chunk = world_to_chunk_coords(start_pos)
	
	for dx in range(-render_distance, render_distance + 1):
		for dz in range(-render_distance, render_distance + 1):
			for dy in range(-1, 2):
				var chunk_pos = start_chunk + Vector3i(dx, dy, dz)
				queue_chunk_generation(chunk_pos)
	
	# Force generate initial chunks immediately
	for i in range(min(20, generation_queue.size())):
		process_generation_queue()

func set_player(new_player: Node3D):
	player = new_player

func world_to_chunk_coords(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floori(world_pos.x / CHUNK_SIZE),
		floori(world_pos.y / CHUNK_SIZE),
		floori(world_pos.z / CHUNK_SIZE)
	)

func get_chunk(cx: int, cy: int, cz: int) -> VoxelChunk:
	var key = Vector3i(cx, cy, cz)
	return chunks.get(key, null)

func get_chunk_at_world_pos(world_pos: Vector3) -> VoxelChunk:
	var chunk_pos = world_to_chunk_coords(world_pos)
	return get_chunk(chunk_pos.x, chunk_pos.y, chunk_pos.z)

func get_block(world_pos: Vector3i) -> int:
	var chunk_pos = world_to_chunk_coords(Vector3(world_pos))
	var chunk = get_chunk(chunk_pos.x, chunk_pos.y, chunk_pos.z)
	
	if chunk == null:
		return VoxelRegistry.BLOCK_AIR
	
	var local = chunk.world_to_local(world_pos.x, world_pos.y, world_pos.z)
	return chunk.get_block(local.x, local.y, local.z)

func set_block(world_pos: Vector3i, block_id: int):
	var chunk_pos = world_to_chunk_coords(Vector3(world_pos))
	var chunk = get_chunk(chunk_pos.x, chunk_pos.y, chunk_pos.z)
	
	if chunk == null:
		# Need to generate/load this chunk first
		return
	
	var local = chunk.world_to_local(world_pos.x, world_pos.y, world_pos.z)
	chunk.set_block(local.x, local.y, local.z, block_id)
	
	# Mark chunk as modified for saving
	var key = Vector3i(chunk_pos.x, chunk_pos.y, chunk_pos.z)
	modified_chunks[key] = {
		"blocks": serialize_chunk_blocks(chunk)
	}
	
	# Queue mesh rebuild
	queue_mesh_rebuild(chunk)
	
	# Also rebuild neighboring chunks if block is on edge
	if local.x == 0 or local.x == CHUNK_SIZE - 1 or \
	   local.y == 0 or local.y == CHUNK_SIZE - 1 or \
	   local.z == 0 or local.z == CHUNK_SIZE - 1:
		rebuild_neighbor_chunks(chunk_pos)

func serialize_chunk_blocks(chunk: VoxelChunk) -> Dictionary:
	var data = {}
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var block_id = chunk.get_block(x, y, z)
				if block_id != VoxelRegistry.BLOCK_AIR:
					data["%d,%d,%d" % [x, y, z]] = block_id
	return data

func rebuild_neighbor_chunks(chunk_pos: Vector3i):
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for dir in directions:
		var neighbor_pos = chunk_pos + dir
		var neighbor = get_chunk(neighbor_pos.x, neighbor_pos.y, neighbor_pos.z)
		if neighbor != null:
			queue_mesh_rebuild(neighbor)

func queue_chunk_generation(chunk_pos: Vector3i):
	var key = Vector3i(chunk_pos.x, chunk_pos.y, chunk_pos.z)
	if not chunks.has(key) and not generation_queue.has(key):
		generation_queue.append(key)

func queue_mesh_rebuild(chunk: VoxelChunk):
	if not mesh_update_queue.has(chunk):
		mesh_update_queue.append(chunk)

func process_generation_queue():
	var count = 0
	while count < max_generations_per_frame and generation_queue.size() > 0:
		var chunk_key = generation_queue.pop_front()
		
		# Check if chunk already exists
		if chunks.has(chunk_key):
			continue
		
		# Create and generate chunk
		var chunk = VoxelChunk.new(chunk_key.x, chunk_key.y, chunk_key.z)
		generator.generate_chunk(chunk)
		
		# Create mesh instance
		create_chunk_mesh(chunk)
		
		chunks[chunk_key] = chunk
		count += 1

func process_mesh_updates():
	var count = 0
	while count < max_generations_per_frame and mesh_update_queue.size() > 0:
		var chunk = mesh_update_queue.pop_front()
		
		if chunk.is_dirty:
			rebuild_chunk_mesh(chunk)
			chunk.is_dirty = false
		count += 1

func create_chunk_mesh(chunk: VoxelChunk):
	# Create mesh
	var mesh = VoxelMesher.generate_mesh(chunk)
	
	if mesh.get_surface_count() == 0:
		return
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = chunk.get_world_position()
	mesh_instance.name = "Chunk_%d_%d_%d" % [chunk.chunk_x, chunk.chunk_y, chunk.chunk_z]
	
	# Add to world
	add_child(mesh_instance)
	chunk.mesh_instance = mesh_instance

func rebuild_chunk_mesh(chunk: VoxelChunk):
	if chunk.mesh_instance != null:
		chunk.mesh_instance.queue_free()
		chunk.mesh_instance = null
	
	create_chunk_mesh(chunk)

func _process(delta):
	if not Engine.is_editor_hint():
		process_generation_queue()
		process_mesh_updates()
		update_chunk_streaming()

func update_chunk_streaming():
	if player == null:
		return
	
	var player_chunk = world_to_chunk_coords(player.global_position)
	
	# Load chunks around player
	for dx in range(-load_distance, load_distance + 1):
		for dz in range(-load_distance, load_distance + 1):
			for dy in range(-1, 2):
				var chunk_pos = player_chunk + Vector3i(dx, dy, dz)
				
				# Calculate distance from player
				var dist = abs(dx) + abs(dz)
				
				if dist <= load_distance:
					queue_chunk_generation(chunk_pos)
	
	# Unload far chunks
	var chunks_to_unload: Array = []
	for key in chunks.keys():
		var chunk: VoxelChunk = chunks[key]
		var dist = abs(key.x - player_chunk.x) + abs(key.z - player_chunk.z)
		
		if dist > unload_distance:
			chunks_to_unload.append(key)
	
	for key in chunks_to_unload:
		unload_chunk(key)

func unload_chunk(chunk_key: Vector3i):
	var chunk: VoxelChunk = chunks.get(chunk_key)
	if chunk == null:
		return
	
	# Remove mesh
	if chunk.mesh_instance != null:
		chunk.mesh_instance.queue_free()
		chunk.mesh_instance = null
	
	# Keep chunk data if it was modified (for saving)
	if not modified_chunks.has(chunk_key):
		chunks.erase(chunk_key)

func save_world():
	# Save modified chunks
	var save_data = {
		"seed": generator.seed,
		"modified_chunks": modified_chunks
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open("user://world_save.json", FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()

func load_world():
	var file = FileAccess.open("user://world_save.json", FileAccess.READ)
	if file == null:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_json = JSON.parse_string(json_string)
	if parse_json == null:
		return false
	
	var save_data = parse_json as Dictionary
	generator.set_seed(save_data.get("seed", 12345))
	modified_chunks = save_data.get("modified_chunks", {})
	
	return true

func clear_world():
	# Clear all chunks
	for key in chunks.keys():
		var chunk: VoxelChunk = chunks[key]
		if chunk.mesh_instance != null:
			chunk.mesh_instance.queue_free()
	
	chunks.clear()
	modified_chunks.clear()
	generation_queue.clear()
	mesh_update_queue.clear()
