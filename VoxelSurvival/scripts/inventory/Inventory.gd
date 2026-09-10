class_name Inventory
extends RefCounted

## Player inventory system with hotbar and main inventory

signal inventory_changed
signal hotbar_changed
signal slot_selected(slot_index: int)

const HOTBAR_SIZE = 9
const INVENTORY_SIZE = 27

# Hotbar slots (0-8)
var hotbar: Array = []

# Main inventory slots (9-35)
var inventory: Array = []

# Currently selected hotbar slot
var selected_slot: int = 0

func _init():
	# Initialize empty slots
	for i in range(HOTBAR_SIZE):
		hotbar.append(null)
	
	for i in range(INVENTORY_SIZE):
		inventory.append(null)

func get_hotbar() -> Array:
	return hotbar

func get_inventory() -> Array:
	return inventory

func get_selected_item() -> InventoryItem:
	if selected_slot < 0 or selected_slot >= HOTBAR_SIZE:
		return null
	return hotbar[selected_slot]

func set_selected_slot(slot: int):
	if slot >= 0 and slot < HOTBAR_SIZE:
		selected_slot = slot
		slot_selected.emit(slot)

func add_item(item_id: int, count: int = 1) -> bool:
	# Try to stack with existing items first
	for slot in hotbar:
		if slot != null and slot.item_id == item_id and not slot.is_full():
			var remaining = slot.add(count)
			count = remaining
			if count <= 0:
				inventory_changed.emit()
				return true
	
	for slot in inventory:
		if slot != null and slot.item_id == item_id and not slot.is_full():
			var remaining = slot.add(count)
			count = remaining
			if count <= 0:
				inventory_changed.emit()
				return true
	
	# Then try empty slots
	if count > 0:
		for slot in hotbar:
			if slot == null or slot.is_empty():
				slot = InventoryItem.new(item_id, count)
				inventory_changed.emit()
				return true
		
		for slot in inventory:
			if slot == null or slot.is_empty():
				slot = InventoryItem.new(item_id, count)
				inventory_changed.emit()
				return true
	
	inventory_changed.emit()
	return count <= 0

func remove_item(item_id: int, count: int) -> bool:
	var remaining = count
	
	# Remove from hotbar first
	for i in range(HOTBAR_SIZE):
		if remaining <= 0:
			break
		var slot = hotbar[i]
		if slot != null and slot.item_id == item_id:
			var removed = slot.remove(remaining)
			remaining -= removed
			if slot.count <= 0:
				hotbar[i] = null
	
	# Then from inventory
	for i in range(INVENTORY_SIZE):
		if remaining <= 0:
			break
		var slot = inventory[i]
		if slot != null and slot.item_id == item_id:
			var removed = slot.remove(remaining)
			remaining -= removed
			if slot.count <= 0:
				inventory[i] = null
	
	inventory_changed.emit()
	return remaining <= 0

func get_item_count(item_id: int) -> int:
	var total = 0
	
	for slot in hotbar:
		if slot != null and slot.item_id == item_id:
			total += slot.count
	
	for slot in inventory:
		if slot != null and slot.item_id == item_id:
			total += slot.count
	
	return total

func has_item(item_id: int, count: int) -> bool:
	return get_item_count(item_id) >= count

func clear():
	for i in range(HOTBAR_SIZE):
		hotbar[i] = null
	for i in range(INVENTORY_SIZE):
		inventory[i] = null
	selected_slot = 0
	inventory_changed.emit()

func get_slot(index: int) -> InventoryItem:
	if index < 0 or index >= HOTBAR_SIZE + INVENTORY_SIZE:
		return null
	
	if index < HOTBAR_SIZE:
		return hotbar[index]
	else:
		return inventory[index - HOTBAR_SIZE]

func set_slot(index: int, item: InventoryItem):
	if index < 0 or index >= HOTBAR_SIZE + INVENTORY_SIZE:
		return
	
	if index < HOTBAR_SIZE:
		hotbar[index] = item
	else:
		inventory[index - HOTBAR_SIZE] = item
	
	inventory_changed.emit()

func swap_slots(from_index: int, to_index: int):
	if from_index < 0 or from_index >= HOTBAR_SIZE + INVENTORY_SIZE:
		return
	if to_index < 0 or to_index >= HOTBAR_SIZE + INVENTORY_SIZE:
		return
	
	var temp: InventoryItem = null
	
	if from_index < HOTBAR_SIZE:
		temp = hotbar[from_index]
	else:
		temp = inventory[from_index - HOTBAR_SIZE]
	
	if to_index < HOTBAR_SIZE:
		inventory[to_index - HOTBAR_SIZE] = hotbar[to_index] if to_index >= HOTBAR_SIZE else temp
		hotbar[to_index] = temp
	else:
		hotbar[from_index] = inventory[from_index - HOTBAR_SIZE] if from_index < HOTBAR_SIZE else temp
		inventory[to_index - HOTBAR_SIZE] = temp
	
	inventory_changed.emit()

func serialize() -> Dictionary:
	var data = {
		"hotbar": [],
		"inventory": [],
		"selected_slot": selected_slot
	}
	
	for slot in hotbar:
		if slot != null:
			data.hotbar.append({"id": slot.item_id, "count": slot.count})
		else:
			data.hotbar.append(null)
	
	for slot in inventory:
		if slot != null:
			data.inventory.append({"id": slot.item_id, "count": slot.count})
		else:
			data.inventory.append(null)
	
	return data

func deserialize(data: Dictionary):
	if not data.has("hotbar") or not data.has("inventory"):
		return
	
	selected_slot = data.get("selected_slot", 0)
	
	for i in range(min(data.hotbar.size(), HOTBAR_SIZE)):
		var slot_data = data.hotbar[i]
		if slot_data != null:
			hotbar[i] = InventoryItem.new(slot_data.id, slot_data.count)
		else:
			hotbar[i] = null
	
	for i in range(min(data.inventory.size(), INVENTORY_SIZE)):
		var slot_data = data.inventory[i]
		if slot_data != null:
			inventory[i] = InventoryItem.new(slot_data.id, slot_data.count)
		else:
			inventory[i] = null
	
	inventory_changed.emit()
