class_name InventoryItem
extends RefCounted

## Represents a single item stack in inventory

var item_id: int = 0
var count: int = 1
var max_stack: int = 64

func _init(id: int = 0, c: int = 1, max_s: int = 64):
	item_id = id
	count = c
	max_stack = max_s

func is_empty() -> bool:
	return count <= 0 or item_id == 0

func is_full() -> bool:
	return count >= max_stack

func can_stack_with(other: InventoryItem) -> bool:
	return other.item_id == item_id and not is_full()

func add(amount: int) -> int:
	# Returns amount that couldn't be added
	var space = max_stack - count
	if amount <= space:
		count += amount
		return 0
	else:
		count = max_stack
		return amount - space

func remove(amount: int) -> int:
	# Returns actual amount removed
	var actual = min(amount, count)
	count -= actual
	return actual

func get_block_id() -> int:
	return item_id
