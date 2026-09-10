# Voxel Survival - Godot 4.7 Android

A mobile-first voxel survival sandbox game built from scratch in Godot 4.7.

## Installation

### Requirements
- Godot Engine 4.7 or later
- Android SDK and NDK (for Android export)
- Java JDK 17+

### Opening the Project
1. Open Godot 4.7
2. Click "Import" and navigate to the `project.godot` file
3. The project will import automatically

### Running the Game
- Press F5 in Godot editor to run in desktop mode
- For Android: Export → Android → Run on Device

## Architecture

### Core Systems

#### Voxel System (`scripts/voxel/`)
- **VoxelBlock**: Data structure for block properties
- **VoxelRegistry**: Central registry for all block types
- **VoxelChunk**: 16×16×16 chunk data storage
- **VoxelMesher**: Mesh generation with face culling

#### World Generation (`scripts/generation/`)
- **FastNoise2D/FastNoise3D**: Custom Perlin noise implementation
- **BiomeData/BiomeRegistry**: Biome definitions and selection
- **WorldGenerator**: Terrain, caves, ores, and structures

#### World Management (`scripts/world/`)
- **WorldManager**: Chunk streaming, loading, unloading
- **DayNightCycle**: Time progression and lighting

#### Player (`scripts/player/`)
- **PlayerController**: Movement, camera, physics
- **BlockInteraction**: Block breaking/placement raycasting
- **SurvivalSystem**: Health, hunger, damage

#### Inventory & Crafting (`scripts/inventory/`, `scripts/crafting/`)
- **Inventory**: Hotbar + main inventory system
- **CraftingManager**: Recipe-based crafting

#### UI (`scripts/ui/`)
- **MobileControls**: Touch joystick and buttons
- **HotbarUI**: Block selection display
- **PauseMenu**: Game pause interface
- **DebugOverlay**: Performance info

### Key Design Decisions

1. **Chunk-based World**: 16³ blocks per chunk for optimal memory/performance
2. **Face Culling**: Only visible block faces are rendered
3. **Lazy Generation**: Chunks generated only when needed
4. **Save Efficiency**: Only modified chunks saved, not entire world
5. **Mobile First**: Touch controls designed before keyboard/mouse

## Controls

### Desktop
- WASD: Move
- Space: Jump
- Shift: Crouch
- Mouse: Look around
- Left Click: Break block
- Right Click: Place block
- 1-9: Select hotbar slot
- I/Esc: Inventory/Pause
- F3: Toggle debug overlay

### Mobile
- Left Joystick: Move
- Right Screen Drag: Look
- Jump Button: Jump
- Crouch Button: Crouch
- Break Button: Hold to break
- Place Button: Place block
- Run Toggle: Sprint mode
- Inventory Button: Pause menu

## Adding Content

### Adding a New Block

1. Add block ID constant in `VoxelRegistry.gd`:
```gdscript
const BLOCK_MYBLOCK = 14
```

2. Add creation function in `VoxelRegistry.gd`:
```gdscript
static func create_myblock() -> VoxelBlock:
    var block = VoxelBlock.new()
    block.id = BLOCK_MYBLOCK
    block.name = "My Block"
    block.is_solid = true
    block.hardness = 1.0
    block.texture_coords = [Vector2i(12, 0)] * 6
    block.drops = [{"item_id": BLOCK_MYBLOCK, "count_min": 1, "count_max": 1}]
    return block
```

3. Register in `initialize()`:
```gdscript
register_block(create_myblock())
```

### Adding a New Biome

1. Create biome in `BiomeRegistry.gd`:
```gdscript
static func create_new_biome() -> BiomeData:
    var biome = BiomeData.new()
    biome.name = "New Biome"
    biome.id = BIOME_NEW
    biome.min_height = 0.0
    biome.max_height = 0.5
    biome.surface_block = VoxelRegistry.BLOCK_GRASS
    # ... configure other properties
    return biome
```

2. Add to `initialize()` biomes array

### Adding a New Recipe

In `CraftingManager.gd`, `register_default_recipes()`:
```gdscript
var recipe = CraftingRecipe.new()
recipe.recipe_id = "my_recipe"
recipe.output_item_id = VoxelRegistry.BLOCK_MYBLOCK
recipe.output_count = 1
recipe.ingredients = {str(VoxelRegistry.BLOCK_STONE): 2}
register_recipe(recipe)
```

## Android Export

1. Go to Project → Export
2. Add Android preset if not exists
3. Configure:
   - Package name: com.yourname.voxelsurvival
   - Version: 1.0.0
   - Target API: 33
   - Minimum API: 24
4. Under Options → Android:
   - Enable ARM64
   - Enable Vulkan (Mobile renderer)
5. Click "Export Project" or "Run on Device"

## Debug Mode

Press F3 in-game to toggle debug overlay showing:
- FPS counter
- Player position
- Current chunk coordinates
- Loaded chunk count
- Current biome

## Save System

Saves are stored in `user://`:
- `world_save.json`: Modified chunks and world seed
- `player_save.json`: Player position, inventory, health/hunger

The world uses seed-based generation, so only player modifications are saved.

## Known Limitations

1. **Greedy Meshing**: Not yet implemented; using basic face culling
2. **Entity AI**: Basic creature AI is simplified for mobile performance
3. **Multiplayer**: Not implemented (single-player only)
4. **Texture Atlas**: Uses procedural colors; real textures need asset creation
5. **Sound**: Audio manager placeholder; no actual sounds included

## Performance Tips

For lower-end devices:
1. Set graphics preset to "Very Low" in settings
2. Reduce render distance to 2-3 chunks
3. Limit entity count in spawn settings
4. Use mobile renderer (default)

## License

This project is original code created from scratch. You may use it as a learning resource or base for your own projects.

## Credits

Built with Godot Engine 4.7
https://godotengine.org/
