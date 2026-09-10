class_name VoxelRegistry
extends RefCounted

## Central registry for all block types
## This is a data-driven system - add new blocks by creating resources

static var blocks: Dictionary = {}
static var block_by_id: Dictionary = {}
static var initialized: bool = false

const BLOCK_AIR = 0
const BLOCK_GRASS = 1
const BLOCK_DIRT = 2
const BLOCK_STONE = 3
const BLOCK_SAND = 4
const BLOCK_WOOD = 5
const BLOCK_LEAVES = 6
const BLOCK_WATER = 7
const BLOCK_COPPER_ORE = 8
const BLOCK_IRON_ORE = 9
const BLOCK_CRYSTAL_ORE = 10
const BLOCK_SNOW = 11
const BLOCK_PLANKS = 12
const BLOCK_COBBLESTONE = 13

static func initialize():
	if initialized:
		return
	
	blocks.clear()
	block_by_id.clear()
	
	# Register default blocks
	register_block(create_air_block())
	register_block(create_grass_block())
	register_block(create_dirt_block())
	register_block(create_stone_block())
	register_block(create_sand_block())
	register_block(create_wood_block())
	register_block(create_leaves_block())
	register_block(create_water_block())
	register_block(create_copper_ore())
	register_block(create_iron_ore())
	register_block(create_crystal_ore())
	register_block(create_snow_block())
	register_block(create_planks_block())
	register_block(create_cobblestone_block())
	
	initialized = true

static func register_block(block: VoxelBlock):
	blocks[block.name] = block
	block_by_id[block.id] = block

static func get_block(name: String) -> VoxelBlock:
	if not initialized:
		initialize()
	return blocks.get(name, null)

static func get_block_by_id(id: int) -> VoxelBlock:
	if not initialized:
		initialize()
	return block_by_id.get(id, null)

static func get_all_blocks() -> Array:
	if not initialized:
		initialize()
	var result: Array = []
	for key in blocks.keys():
		result.append(blocks[key])
	return result

static func create_air_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_AIR
	block.name = "Air"
	block.is_solid = false
	block.is_transparent = true
	block.hardness = 0.0
	return block

static func create_grass_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_GRASS
	block.name = "Grass"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 0.6
	block.material_type = "Dirt"
	# Texture coords: sides grass, top grass_top, bottom dirt
	block.texture_coords = [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 1)]
	block.drops = [{\"item_id\": BLOCK_DIRT, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_dirt_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_DIRT
	block.name = "Dirt"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 0.5
	block.material_type = "Dirt"
	block.texture_coords = [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2)]
	block.drops = [{\"item_id\": BLOCK_DIRT, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_stone_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_STONE
	block.name = "Stone"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 1.5
	block.material_type = "Stone"
	block.texture_coords = [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0)]
	block.drops = [{\"item_id\": BLOCK_COBBLESTONE, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_sand_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_SAND
	block.name = "Sand"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 0.5
	block.material_type = "Sand"
	block.texture_coords = [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0)]
	block.drops = [{\"item_id\": BLOCK_SAND, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_wood_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_WOOD
	block.name = "Wood"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 2.0
	block.material_type = "Wood"
	block.texture_coords = [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 0), Vector2i(3, 0)]
	block.drops = [{\"item_id\": BLOCK_WOOD, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_leaves_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_LEAVES
	block.name = "Leaves"
	block.is_solid = true
	block.is_transparent = true
	block.hardness = 0.2
	block.material_type = "Plant"
	block.texture_coords = [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0)]
	block.drops = []
	return block

static func create_water_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_WATER
	block.name = "Water"
	block.is_solid = false
	block.is_transparent = true
	block.hardness = 100.0
	block.material_type = "Water"
	block.texture_coords = [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0)]
	return block

static func create_copper_ore() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_COPPER_ORE
	block.name = "Copper Ore"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 3.0
	block.min_tool_tier = 1
	block.material_type = "Stone"
	block.texture_coords = [Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0)]
	block.drops = [{\"item_id\": BLOCK_COPPER_ORE, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_iron_ore() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_IRON_ORE
	block.name = "Iron Ore"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 4.0
	block.min_tool_tier = 2
	block.material_type = "Stone"
	block.texture_coords = [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0)]
	block.drops = [{\"item_id\": BLOCK_IRON_ORE, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_crystal_ore() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_CRYSTAL_ORE
	block.name = "Crystal Ore"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 5.0
	block.min_tool_tier = 3
	block.light_level = 3
	block.material_type = "Metal"
	block.texture_coords = [Vector2i(8, 0), Vector2i(8, 0), Vector2i(8, 0), Vector2i(8, 0), Vector2i(8, 0), Vector2i(8, 0)]
	block.drops = [{\"item_id\": BLOCK_CRYSTAL_ORE, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_snow_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_SNOW
	block.name = "Snow"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 0.3
	block.material_type = "Snow"
	block.texture_coords = [Vector2i(9, 0), Vector2i(9, 0), Vector2i(9, 0), Vector2i(9, 0), Vector2i(9, 0), Vector2i(9, 0)]
	block.drops = [{\"item_id\": BLOCK_SNOW, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_planks_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_PLANKS
	block.name = "Planks"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 2.0
	block.material_type = "Wood"
	block.texture_coords = [Vector2i(10, 0), Vector2i(10, 0), Vector2i(10, 0), Vector2i(10, 0), Vector2i(10, 0), Vector2i(10, 0)]
	block.drops = [{\"item_id\": BLOCK_PLANKS, \"count_min\": 1, \"count_max\": 1}]
	return block

static func create_cobblestone_block() -> VoxelBlock:
	var block = VoxelBlock.new()
	block.id = BLOCK_COBBLESTONE
	block.name = "Cobblestone"
	block.is_solid = true
	block.is_transparent = false
	block.hardness = 2.0
	block.material_type = "Stone"
	block.texture_coords = [Vector2i(11, 0), Vector2i(11, 0), Vector2i(11, 0), Vector2i(11, 0), Vector2i(11, 0), Vector2i(11, 0)]
	block.drops = [{\"item_id\": BLOCK_COBBLESTONE, \"count_min\": 1, \"count_max\": 1}]
	return block
