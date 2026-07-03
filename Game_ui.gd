extends CanvasLayer

# --- 1. 密码本 (Enum) ---
# 必须和 World.gd 保持一致
enum ItemType { NONE, HOE, WATER, SEED_TOMATO, SEED_WHEAT, CROP_TOMATO, CROP_WHEAT }

# --- 2. 物品栏配置 ---
# 顺序：Slot1(锄头) -> Slot2(水壶) -> Slot3(番茄种) -> Slot4(小麦种) -> Slot5(番茄果) -> Slot6(小麦果)
var inventory = [
	{ "type": ItemType.HOE, "count": 1 },          # Slot 1
	{ "type": ItemType.WATER, "count": 1 },        # Slot 2
	{ "type": ItemType.SEED_TOMATO, "count": 15 }, # Slot 3 (起始15个)
	{ "type": ItemType.SEED_WHEAT, "count": 15 },  # Slot 4 (起始15个)
	{ "type": ItemType.CROP_TOMATO, "count": 0 },  # Slot 5 (收获用，起始0)
	{ "type": ItemType.CROP_WHEAT, "count": 0 }    # Slot 6 (收获用，起始0)
]

var current_index = 0
@onready var slots = $HotbarContainer/HBoxContainer.get_children()
@onready var selector = $HotbarContainer/Selector

func _ready():
	update_all_slots()
	update_selector_position()

func _input(event):
	# 鼠标滚轮切换物品
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_index = (current_index - 1 + slots.size()) % slots.size()
			update_selector_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_index = (current_index + 1) % slots.size()
			update_selector_position()

func update_selector_position():
	selector.global_position = slots[current_index].global_position

func update_all_slots():
	for i in range(inventory.size()):
		var data = inventory[i]
		var slot_node = slots[i]
		
		# 获取格子下的 Icon 和 Label 节点
		# 请确保你的 Slot1 到 Slot6 下面都有 "Label" 和 "Icon" 节点
		var label = slot_node.get_node("Label")
		var icon = slot_node.get_node("Icon")
		
		# --- 显示/隐藏逻辑 ---
		
		# 1. 如果是工具 (永远显示图标，永远隐藏数字)
		if data["type"] == ItemType.HOE or data["type"] == ItemType.WATER:
			icon.visible = true
			label.visible = false
			
		# 2. 如果是 种子 或 作物 (根据数量决定显示)
		else:
			if data["count"] > 0:
				# 有东西：显示图标和数字
				icon.visible = true
				label.visible = true
				label.text = str(data["count"])
			else:
				# 没东西(数量0)：全部隐藏，假装是空的
				icon.visible = false
				label.visible = false

# --- 供 World.gd 调用的接口 ---

func get_current_item_type():
	return inventory[current_index]["type"]

func consume_current_item():
	var data = inventory[current_index]
	if data["count"] > 0:
		data["count"] -= 1
		update_all_slots() # 消耗后刷新界面，如果变0了会自动隐藏
		return true
	return false

func has_current_item():
	return inventory[current_index]["count"] > 0

func add_item(type, amount):
	# 遍历背包，找到对应的类型加数字
	for data in inventory:
		if data["type"] == type:
			data["count"] += amount
			update_all_slots() # 增加后刷新界面，如果从0变1了会自动显示
			return
