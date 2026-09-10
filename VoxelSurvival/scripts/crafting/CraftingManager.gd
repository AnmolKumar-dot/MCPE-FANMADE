class_name CraftingManager
extends RefCounted

## Manages crafting recipes and crafting operations

signal recipe_crafted(recipe_id: String)

var recipes: Dictionary = {}

func _init():
	register_default_recipes()

func register_recipe(recipe: CraftingRecipe):
	recipes[recipe.recipe_id] = recipe

func get_recipe(recipe_id: String) -> CraftingRecipe:
	return recipes.get(recipe_id, null)

func get_all_recipes() -> Array:
	var result: Array = []
	for key in recipes.keys():
		result.append(recipes[key])
	return result

func can_craft(recipe_id: String, inventory: Inventory) -> bool:
	var recipe = get_recipe(recipe_id)
	if recipe == null:
		return false
	return recipe.can_craft(inventory)

func craft(recipe_id: String, inventory: Inventory) -> bool:
	var recipe = get_recipe(recipe_id)
	if recipe == null:
		return false
	
	if recipe.craft(inventory):
		# Add output to inventory
		inventory.add_item(recipe.output_item_id, recipe.output_count)
		recipe_crafted.emit(recipe_id)
		return true
	
	return false

func register_default_recipes():
	# Wood -> Planks (4 planks per wood)
	var wood_to_planks = CraftingRecipe.new()
	wood_to_planks.recipe_id = "wood_to_planks"
	wood_to_planks.output_item_id = VoxelRegistry.BLOCK_PLANKS
	wood_to_planks.output_count = 4
	wood_to_planks.ingredients = {str(VoxelRegistry.BLOCK_WOOD): 1}
	register_recipe(wood_to_planks)
	
	# Planks -> Stick (simplified - using planks as stick equivalent)
	var planks_to_stick = CraftingRecipe.new()
	planks_to_stick.recipe_id = "planks_to_stick"
	planks_to_stick.output_item_id = VoxelRegistry.BLOCK_PLANKS
	planks_to_stick.output_count = 2
	planks_to_stick.ingredients = {str(VoxelRegistry.BLOCK_WOOD): 1}
	register_recipe(planks_to_stick)
	
	# Stone -> Cobblestone tools (simplified)
	var cobble_recipe = CraftingRecipe.new()
	cobble_recipe.recipe_id = "stone_to_cobble"
	cobble_recipe.output_item_id = VoxelRegistry.BLOCK_COBBLESTONE
	cobble_recipe.output_count = 1
	cobble_recipe.ingredients = {str(VoxelRegistry.BLOCK_STONE): 1}
	register_recipe(cobble_recipe)
	
	# Copper ore block (for building)
	var copper_block = CraftingRecipe.new()
	copper_block.recipe_id = "copper_block"
	copper_block.output_item_id = VoxelRegistry.BLOCK_COPPER_ORE
	copper_block.output_count = 1
	copper_block.ingredients = {str(VoxelRegistry.BLOCK_STONE): 4, str(VoxelRegistry.BLOCK_COPPER_ORE): 1}
	register_recipe(copper_block)

func get_recipes_for_item(item_id: int) -> Array:
	var result: Array = []
	for recipe in get_all_recipes():
		if recipe.output_item_id == item_id:
			result.append(recipe)
	return result
