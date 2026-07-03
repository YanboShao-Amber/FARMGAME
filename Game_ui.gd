extends CanvasLayer

enum ItemType { NONE, HOE, WATER, AXE, SEED_TOMATO, SEED_WHEAT, CROP_TOMATO, CROP_WHEAT }

var inventory := [
	{ "type": ItemType.HOE, "count": 1 },
	{ "type": ItemType.WATER, "count": 1 },
	{ "type": ItemType.AXE, "count": 1 },
	{ "type": ItemType.SEED_TOMATO, "count": 15 },
	{ "type": ItemType.SEED_WHEAT, "count": 15 },
	{ "type": ItemType.CROP_TOMATO, "count": 0 },
	{ "type": ItemType.CROP_WHEAT, "count": 0 },
]

var current_index := 0

@onready var slots: Array = $HotbarContainer/HBoxContainer.get_children()
@onready var selector: TextureRect = $HotbarContainer/Selector

func _ready() -> void:
	update_all_slots()
	update_selector_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_index = (current_index - 1 + inventory.size()) % inventory.size()
			update_selector_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_index = (current_index + 1) % inventory.size()
			update_selector_position()

func update_selector_position() -> void:
	if slots.is_empty():
		return

	current_index = clampi(current_index, 0, min(inventory.size(), slots.size()) - 1)
	selector.global_position = slots[current_index].global_position

func update_all_slots() -> void:
	for i in range(min(inventory.size(), slots.size())):
		var data: Dictionary = inventory[i]
		var slot_node: Node = slots[i]
		var label: Label = slot_node.get_node("Label")
		var icon: TextureRect = slot_node.get_node("Icon")

		if _is_tool(data["type"]):
			icon.visible = true
			label.visible = false
		elif data["count"] > 0:
			icon.visible = true
			label.visible = true
			label.text = str(data["count"])
		else:
			icon.visible = false
			label.visible = false

func get_current_item_type() -> int:
	return inventory[current_index]["type"]

func consume_current_item() -> bool:
	var data: Dictionary = inventory[current_index]
	if _is_tool(data["type"]):
		return true

	if data["count"] <= 0:
		return false

	data["count"] -= 1
	update_all_slots()
	return true

func has_current_item() -> bool:
	var data: Dictionary = inventory[current_index]
	return _is_tool(data["type"]) or data["count"] > 0

func add_item(type: int, amount: int) -> void:
	for data in inventory:
		if data["type"] == type:
			data["count"] += amount
			update_all_slots()
			return

func _is_tool(type: int) -> bool:
	return type == ItemType.HOE or type == ItemType.WATER or type == ItemType.AXE
