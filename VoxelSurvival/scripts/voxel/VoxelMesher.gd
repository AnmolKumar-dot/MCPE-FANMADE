class_name VoxelMesher
extends RefCounted

## Generates meshes from voxel chunk data
## Implements face culling to avoid rendering hidden faces

const CHUNK_SIZE = 16

# Face normals: right, left, top, bottom, front, back
const FACE_NORMALS = [
	Vector3(1, 0, 0),   # Right (0)
	Vector3(-1, 0, 0),  # Left (1)
	Vector3(0, 1, 0),   # Top (2)
	Vector3(0, -1, 0),  # Bottom (3)
	Vector3(0, 0, 1),   # Front (4)
	Vector3(0, 0, -1)   # Back (5)
]

# UV coordinates for each face (clockwise quad)
# Format: [bottom-left, bottom-right, top-right, top-left]
const FACE_UVS = [
	# Right face
	[Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 0)],
	# Left face  
	[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],
	# Top face
	[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)],
	# Bottom face
	[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],
	# Front face
	[Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)],
	# Back face
	[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
]

static func generate_mesh(chunk: VoxelChunk, neighbor_chunks: Dictionary = {}) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var tangents: PackedFloat32Array = []
	var uvs: PackedVector2Array = []
	var colors: PackedColorArray = []
	var indices: PackedInt32Array = []
	
	var vertex_count = 0
	
	# Iterate through all blocks in the chunk
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var block_id = chunk.get_block(x, y, z)
				
				# Skip air blocks
				if block_id == VoxelRegistry.BLOCK_AIR:
					continue
				
				var block = VoxelRegistry.get_block_by_id(block_id)
				if block == null or not block.is_solid:
					continue
				
				# Check each face
				for face in range(6):
					var normal = FACE_NORMALS[face]
					var nx = x + normal.x
					var ny = y + normal.y
					var nz = z + normal.z
					
					# Determine if face should be culled
					var should_cull = false
					
					if nx >= 0 and nx < CHUNK_SIZE and ny >= 0 and ny < CHUNK_SIZE and nz >= 0 and nz < CHUNK_SIZE:
						# Neighbor is within same chunk
						var neighbor_id = chunk.get_block(nx, ny, nz)
						if neighbor_id != VoxelRegistry.BLOCK_AIR:
							var neighbor_block = VoxelRegistry.get_block_by_id(neighbor_id)
							if neighbor_block != null and neighbor_block.is_solid and not neighbor_block.is_transparent:
								if not block.is_transparent:
									should_cull = true
					else:
						# Neighbor is in adjacent chunk - would need neighbor chunk data
						# For now, don't cull edges (conservative approach)
						pass
					
					if not should_cull:
						# Add face vertices
						add_face_vertices(vertices, normals, tangents, uvs, colors, indices, 
										x, y, z, face, block, vertex_count)
						vertex_count += 4
	
	if vertices.size() == 0:
		return mesh
	
	# Build the mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

static func add_face_vertices(vertices: PackedVector3Array, normals: PackedVector3Array, 
							  tangents: PackedFloat32Array, uvs: PackedVector2Array,
							  colors: PackedColorArray, indices: PackedInt32Array,
							  x: int, y: int, z: int, face: int, block: VoxelBlock, 
							  vertex_offset: int):
	var base_pos = Vector3(x, y, z)
	var normal = FACE_NORMALS[face]
	
	# Calculate corner offsets based on face direction
	var corners = get_face_corners(face)
	
	var texture_coord = block.get_texture_index(face)
	var uv_base = Vector2(texture_coord.x, texture_coord.y)
	var uv_size = Vector2(1.0/16.0, 1.0/16.0)  # Assuming 16x16 atlas
	
	for i in range(4):
		var corner = corners[i]
		var pos = base_pos + corner
		vertices.append(pos)
		normals.append(normal)
		# Tangent (bitangent would be calculated from normal and tangent)
		tangents.append_array([1.0, 0.0, 0.0, 1.0])
		
		# Calculate UV with atlas offset
		var face_uv = FACE_UVS[face][i]
		var uv = Vector2(uv_base.x + face_uv.x * uv_size.x, uv_base.y + face_uv.y * uv_size.y)
		uvs.append(uv)
		
		# White color (tint)
		colors.append(Color.WHITE)
	
	# Add indices for two triangles
	indices.append_array([vertex_offset, vertex_offset + 1, vertex_offset + 2,
						 vertex_offset, vertex_offset + 2, vertex_offset + 3])

static func get_face_corners(face: int) -> Array:
	match face:
		0: # Right face (+X)
			return [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]
		1: # Left face (-X)
			return [Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1)]
		2: # Top face (+Y)
			return [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)]
		3: # Bottom face (-Y)
			return [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)]
		4: # Front face (+Z)
			return [Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
		5: # Back face (-Z)
			return [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]
		_:
			return []

static func generate_collision_mesh(chunk: VoxelChunk) -> ConcavePolygonShape3D:
	var shape = ConcavePolygonShape3D.new()
	var faces: PackedVector3Array = []
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var block_id = chunk.get_block(x, y, z)
				if block_id == VoxelRegistry.BLOCK_AIR:
					continue
				
				var block = VoxelRegistry.get_block_by_id(block_id)
				if block == null or not block.is_solid:
					continue
				
				# Add cube faces for collision
				var base_pos = Vector3(x, y, z)
				add_collision_faces(faces, base_pos)
	
	shape.set_faces(faces)
	return shape

static func add_collision_faces(faces: PackedVector3Array, pos: Vector3):
	# Simple cube collision - 12 triangles (2 per face)
	var size = 1.0
	
	# Front face
	faces.append_array([
		pos + Vector3(0, 0, size), pos + Vector3(size, 0, size), pos + Vector3(size, size, size),
		pos + Vector3(0, 0, size), pos + Vector3(size, size, size), pos + Vector3(0, size, size)
	])
	
	# Back face
	faces.append_array([
		pos + Vector3(size, 0, 0), pos + Vector3(0, 0, 0), pos + Vector3(0, size, 0),
		pos + Vector3(size, 0, 0), pos + Vector3(0, size, 0), pos + Vector3(size, size, 0)
	])
	
	# Left face
	faces.append_array([
		pos + Vector3(0, 0, 0), pos + Vector3(0, 0, size), pos + Vector3(0, size, size),
		pos + Vector3(0, 0, 0), pos + Vector3(0, size, size), pos + Vector3(0, size, 0)
	])
	
	# Right face
	faces.append_array([
		pos + Vector3(size, 0, size), pos + Vector3(size, 0, 0), pos + Vector3(size, size, 0),
		pos + Vector3(size, 0, size), pos + Vector3(size, size, 0), pos + Vector3(size, size, size)
	])
	
	# Top face
	faces.append_array([
		pos + Vector3(0, size, size), pos + Vector3(size, size, size), pos + Vector3(size, size, 0),
		pos + Vector3(0, size, size), pos + Vector3(size, size, 0), pos + Vector3(0, size, 0)
	])
	
	# Bottom face
	faces.append_array([
		pos + Vector3(0, 0, 0), pos + Vector3(size, 0, 0), pos + Vector3(size, 0, size),
		pos + Vector3(0, 0, 0), pos + Vector3(size, 0, size), pos + Vector3(0, 0, size)
	])
