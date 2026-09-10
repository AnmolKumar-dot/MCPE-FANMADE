class_name VoxelBlock
extends Resource

## Unique identifier for this block type
@export var id: int = 0

## Display name
@export var name: String = "Air"

## Whether this block is solid (has collision)
@export var is_solid: bool = true

## Whether this block is transparent (affects light/face culling)
@export var is_transparent: bool = false

## How hard this block is to break (seconds with bare hands)
@export var hardness: float = 1.0

## Minimum tool tier required to mine this block
@export var min_tool_tier: int = 0

## What items this block drops when broken
@export var drops: Array[Dictionary] = []

## Light emission level (0-15)
@export var light_level: int = 0

## Whether this block can catch fire
@export var flammable: bool = false

## Material type for sound/effects
@export_enum("Stone", "Dirt", "Wood", "Metal", "Glass", "Plant", "Sand", "Snow") var material_type: String = "Stone"

## Texture atlas coordinates [x, y] for each face: [right, left, top, bottom, front, back]
@export var texture_coords: Array[Vector2i] = []

func _init():
	pass

func get_texture_index(face: int) -> Vector2i:
	if texture_coords.is_empty():
		return Vector2i(0, 0)
	if face < texture_coords.size():
		return texture_coords[face]
	return texture_coords[0]

func get_drop_amount() -> int:
	return 1

func can_be_mined_with(tool_tier: int) -> bool:
	return tool_tier >= min_tool_tier
