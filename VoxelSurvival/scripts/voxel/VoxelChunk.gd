class_name VoxelChunk
extends RefCounted

## A single chunk of voxel data
## Chunk size is configurable (default 16x16x16)

const CHUNK_SIZE = 16

# 3D array storing block IDs [x][y][z]
var blocks: Array = []

# Chunk coordinates in world space (chunk position, not block position)
var chunk_x: int = 0
var chunk_y: int = 0
var chunk_z: int = 0

# Whether this chunk has been modified since last mesh build
var is_dirty: bool = true

# Whether this chunk has been generated
var is_generated: bool = false

# Mesh instance for rendering
var mesh_instance: MeshInstance3D = null

# Collision shape
var collision_shape: CollisionShape3D = null

func _init(cx: int = 0, cy: int = 0, cz: int = 0):
	chunk_x = cx
	chunk_y = cy
	chunk_z = cz
	initialize_blocks()

func initialize_blocks():
	# Create 3D array filled with air (0)
	blocks.clear()
	for x in range(CHUNK_SIZE):
		var column = []
		column.resize(CHUNK_SIZE)
		for y in range(CHUNK_SIZE):
			column[y] = 0
		blocks.append(column)

func get_block_index(x: int, y: int, z: int) -> int:
	if x < 0 or x >= CHUNK_SIZE or y < 0 or y >= CHUNK_SIZE or z < 0 or z >= CHUNK_SIZE:
		return -1
	return x + y * CHUNK_SIZE + z * CHUNK_SIZE * CHUNK_SIZE

func get_block(x: int, y: int, z: int) -> int:
	if x < 0 or x >= CHUNK_SIZE or y < 0 or y >= CHUNK_SIZE or z < 0 or z >= CHUNK_SIZE:
		return VoxelRegistry.BLOCK_AIR
	return blocks[x][y] if y < blocks[x].size() else 0

func set_block(x: int, y: int, z: int, block_id: int):
	if x < 0 or x >= CHUNK_SIZE or y < 0 or y >= CHUNK_SIZE or z < 0 or z >= CHUNK_SIZE:
		return
	if blocks[x].size() <= y:
		# Extend the column if needed
		while blocks[x].size() <= y:
			blocks[x].append(0)
	blocks[x][y] = block_id
	is_dirty = true

func get_world_position() -> Vector3:
	return Vector3(chunk_x * CHUNK_SIZE, chunk_y * CHUNK_SIZE, chunk_z * CHUNK_SIZE)

func world_to_local(wx: int, wy: int, wz: int) -> Vector3i:
	var local_x = wrapi(wx, CHUNK_SIZE)
	var local_y = wrapi(wy, CHUNK_SIZE)
	var local_z = wrapi(wz, CHUNK_SIZE)
	return Vector3i(local_x, local_y, local_z)

func is_block_solid(x: int, y: int, z: int) -> bool:
	var block_id = get_block(x, y, z)
	if block_id == VoxelRegistry.BLOCK_AIR:
		return false
	var block = VoxelRegistry.get_block_by_id(block_id)
	if block == null:
		return false
	return block.is_solid

func mark_dirty():
	is_dirty = true

func clear_mesh():
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null
	if collision_shape != null:
		collision_shape.queue_free()
		collision_shape = null
