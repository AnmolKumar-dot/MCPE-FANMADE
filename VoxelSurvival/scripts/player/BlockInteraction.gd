class_name BlockInteraction
extends Node

## Handles block breaking and placement interactions

const MAX_REACH_DISTANCE = 5.0

# References
var player: PlayerController = null
var world_manager: WorldManager = null

# Current interaction state
var is_breaking: bool = false
var is_placing: bool = false
var break_progress: float = 0.0
var current_target: Vector3i = Vector3i.ZERO
var target_face: int = -1

# Selected block for placement
var selected_block_id: int = VoxelRegistry.BLOCK_DIRT

# Debug highlight mesh
var highlight_mesh: MeshInstance3D = null

func _ready():
	create_highlight_mesh()

func set_references(new_player: PlayerController, new_world: WorldManager):
	player = new_player
	world_manager = new_world

func set_selected_block(block_id: int):
	selected_block_id = block_id

func _process(delta):
	update_target()
	
	if is_breaking:
		handle_breaking(delta)

func update_target():
	var camera_transform = player.get_camera_transform()
	var from = camera_transform.origin
	var to = from + camera_transform.basis * Vector3(0, 0, -MAX_REACH_DISTANCE)
	
	# Simple raycast through blocks
	var hit = raycast_blocks(from, to)
	
	if hit.found:
		current_target = hit.position
		target_face = hit.face
		
		# Update highlight position
		if highlight_mesh != null:
			highlight_mesh.global_position = Vector3(hit.position.x, hit.position.y, hit.position.z) + Vector3(0.5, 0.5, 0.5)
			highlight_mesh.visible = true
	else:
		current_target = Vector3i.ZERO
		target_face = -1
		
		if highlight_mesh != null:
			highlight_mesh.visible = false

func raycast_blocks(from: Vector3, to: Vector3) -> Dictionary:
	var result = {
		"found": false,
		"position": Vector3i.ZERO,
		"face": -1
	}
	
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	var step = 0.1
	var current = from
	
	var last_solid_pos = Vector3i.ZERO
	
	while current.distance_to(from) < distance:
		var pos = Vector3i(floori(current.x), floori(current.y), floori(current.z))
		var block_id = world_manager.get_block(pos)
		
		if block_id != VoxelRegistry.BLOCK_AIR:
			var block = VoxelRegistry.get_block_by_id(block_id)
			if block != null and block.is_solid:
				result.found = true
				result.position = pos
				result.face = get_hit_face(last_solid_pos, pos, direction)
				return result
		
		last_solid_pos = pos
		current += direction * step
	
	return result

func get_hit_face(from_pos: Vector3i, to_pos: Vector3i, direction: Vector3) -> int:
	var diff = Vector3(to_pos) - Vector3(from_pos)
	
	if abs(diff.x) > abs(diff.y) and abs(diff.x) > abs(diff.z):
		return 0 if diff.x > 0 else 1  # Right or Left
	elif abs(diff.y) > abs(diff.z):
		return 2 if diff.y > 0 else 3  # Top or Bottom
	else:
		return 4 if diff.z > 0 else 5  # Front or Back

func start_breaking():
	is_breaking = true
	break_progress = 0.0

func stop_breaking():
	is_breaking = false
	break_progress = 0.0

func handle_breaking(delta):
	if current_target == Vector3i.ZERO:
		return
	
	var block_id = world_manager.get_block(current_target)
	if block_id == VoxelRegistry.BLOCK_AIR:
		return
	
	var block = VoxelRegistry.get_block_by_id(block_id)
	if block == null:
		return
	
	# Increase break progress
	break_progress += delta / block.hardness
	
	if break_progress >= 1.0:
		break_block()

func break_block():
	if current_target == Vector3i.ZERO:
		return
	
	var block_id = world_manager.get_block(current_target)
	var block = VoxelRegistry.get_block_by_id(block_id)
	
	# Remove block
	world_manager.set_block(current_target, VoxelRegistry.BLOCK_AIR)
	
	# Spawn drop items (simplified - just add to inventory)
	if block != null and block.drops.size() > 0:
		var drop = block.drops[0]
		var count = randi_range(drop.get("count_min", 1), drop.get("count_max", 1))
		# Signal to inventory system to add item
		item_dropped.emit(drop.get("item_id", 0), count)
	
	break_progress = 0.0
	is_breaking = false

func place_block():
	if current_target == Vector3i.ZERO or target_face == -1:
		return
	
	# Calculate placement position based on face
	var place_pos = current_target
	match target_face:
		0: place_pos.x += 1  # Right
		1: place_pos.x -= 1  # Left
		2: place_pos.y += 1  # Top
		3: place_pos.y -= 1  # Bottom
		4: place_pos.z += 1  # Front
		5: place_pos.z -= 1  # Back
	
	# Check if placement is valid (not inside player)
	if not is_position_inside_player(place_pos):
		world_manager.set_block(place_pos, selected_block_id)

func is_position_inside_player(pos: Vector3i) -> bool:
	if player == null:
		return false
	
	var player_pos = player.global_position
	var player_box_min = player_pos + Vector3(-0.4, 0, -0.4)
	var player_box_max = player_pos + Vector3(0.4, 1.8, 0.4)
	
	var block_min = Vector3(pos.x, pos.y, pos.z)
	var block_max = block_min + Vector3.ONE
	
	return block_min.x < player_box_max.x and block_max.x > player_box_min.x and \
		   block_min.y < player_box_max.y and block_max.y > player_box_min.y and \
		   block_min.z < player_box_max.z and block_max.z > player_box_min.z

func create_highlight_mesh():
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 1.0, 1.0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	highlight_mesh = MeshInstance3D.new()
	highlight_mesh.mesh = mesh
	highlight_mesh.material_override = material
	highlight_mesh.visible = false
	
	add_child(highlight_mesh)

signal item_dropped(item_id: int, count: int)
