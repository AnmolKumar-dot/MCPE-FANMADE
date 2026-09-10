class_name CraftingRecipe
extends Resource

## A crafting recipe definition

@export var recipe_id: String = ""
@export var output_item_id: int = 0
@export var output_count: int = 1

# Ingredients as dictionary: {item_id: count}
@export var ingredients: Dictionary = {}

func _init():
	pass

func can_craft(inventory: Inventory) -> bool:
	for ingredient_id_str in ingredients.keys():
		var ingredient_id = int(ingredient_id_str)
		var required_count = ingredients[ingredient_id_str]
		if not inventory.has_item(ingredient_id, required_count):
			return false
	return true

func craft(inventory: Inventory) -> bool:
	if not can_craft(inventory):
		return false
	
	# Remove ingredients
	for ingredient_id_str in ingredients.keys():
		var ingredient_id = int(ingredient_id_str)
		var required_count = ingredients[ingredient_id_str]
		inventory.remove_item(ingredient_id, required_count)
	
	return true

func get_ingredients() -> Array:
	var result: Array = []
	for ingredient_id_str in ingredients.keys():
		result.append({
			"item_id": int(ingredient_id_str),
			"count": ingredients[ingredient_id_str]
		})
	return result
