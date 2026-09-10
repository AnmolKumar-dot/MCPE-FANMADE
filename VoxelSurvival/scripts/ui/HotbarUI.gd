class_name HotbarUI
extends Control

## Hotbar UI display and interaction

@onready var slots_container: HBoxContainer = $SlotsContainer
var inventory: Inventory = null
var slot_buttons: Array = []

func _ready():
	create_hotbar_slots()

func create_hotbar_slots():
	if not slots_container:
		slots_container = HBoxContainer.new()
		slots_container.add_theme_constant_override("separation", 4)
		add_child(slots_container)
	
	# Create 9 hotbar slots
	for i in range(9):
		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(50, 50)
		button.name = "Slot%d" % i
		
		# Add count label
		var label = Label.new()
		label.name = "CountLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.offset_left = -40
		label.offset_top = -18
		label.offset_right = 40
		label.offset_bottom = 0
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 14)
		button.add_child(label)
		
		button.pressed.connect(_on_slot_pressed.bind(i))
		slot_buttons.append(button)
		slots_container.add_child(button)
	
	update_selection()

func set_inventory(new_inventory: Inventory):
	inventory = new_inventory
	if inventory:
		inventory.inventory_changed.connect(update_display)
		inventory.slot_selected.connect(update_selection)
	update_display()

func update_display():
	if not inventory:
		return
	
	for i in range(min(slot_buttons.size(), 9)):
		var item = inventory.get_slot(i)
		var button = slot_buttons[i]
		var label = button.get_node_or_null("CountLabel") as Label
		
		if item != null and not item.is_empty():
			# Set texture based on block type (placeholder colors)
			var color = get_block_color(item.item_id)
			var style = StyleBoxFlat.new()
			style.bg_color = color
			button.set("theme_override_styles/normal", style)
			
			if label:
				label.text = str(item.count)
		else:
			button.set("theme_override_styles/normal", null)
			if label:
				label.text = ""

func update_selection():
	if not inventory:
		return
	
	for i in range(slot_buttons.size()):
		var button = slot_buttons[i]
		var style = button.get("theme_override_styles/normal")
		
		if style == null:
			style = StyleBoxFlat.new()
		
		if i == inventory.selected_slot:
			# Highlight selected slot
			if style is StyleBoxFlat:
				style.border_color = Color.YELLOW
				style.border_width = 2
		else:
			if style is StyleBoxFlat:
				style.border_color = Color.TRANSPARENT
				style.border_width = 0

func get_block_color(block_id: int) -> Color:
	match block_id:
		VoxelRegistry.BLOCK_GRASS:
			return Color(0.3, 0.7, 0.2)
		VoxelRegistry.BLOCK_DIRT:
			return Color(0.5, 0.3, 0.1)
		VoxelRegistry.BLOCK_STONE:
			return Color(0.5, 0.5, 0.5)
		VoxelRegistry.BLOCK_SAND:
			return Color(0.9, 0.85, 0.6)
		VoxelRegistry.BLOCK_WOOD:
			return Color(0.6, 0.4, 0.2)
		VoxelRegistry.BLOCK_LEAVES:
			return Color(0.2, 0.5, 0.2)
		VoxelRegistry.BLOCK_WATER:
			return Color(0.2, 0.4, 0.8, 0.6)
		VoxelRegistry.BLOCK_PLANKS:
			return Color(0.7, 0.5, 0.3)
		VoxelRegistry.BLOCK_COBBLESTONE:
			return Color(0.4, 0.4, 0.4)
		_:
			return Color(0.8, 0.8, 0.8)

func _on_slot_pressed(slot_index: int):
	if inventory:
		inventory.set_selected_slot(slot_index)
		update_selection()
