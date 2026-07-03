extends Node2D

@onready var tile_map_ground = $LandLayer
@onready var tile_map_farm = $FarmLayer
@onready var ui = $GameUI 

# --- 加载你的水壶场景 ---
# 确保你刚才保存的路径是 scenes/water_icon.tscn
var water_icon_scene = preload("res://water_icon.tscn")

enum ItemType { NONE, HOE, WATER, SEED_TOMATO, SEED_WHEAT, CROP_TOMATO, CROP_WHEAT }
const PLANT_SOURCE_ID = 0 

var crop_configs = {
	"tomato": {
		"stages": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
		"harvest_item": ItemType.CROP_TOMATO, 
		"grow_time": 3.0, 
		"needs_water_at": [0, 2] 
	},
	"wheat": {
		"stages": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)], 
		"harvest_item": ItemType.CROP_WHEAT,
		"grow_time": 2.0,
		"needs_water_at": [1] 
	}
}

var farm_data = {}

func _process(delta):
	for pos in farm_data.keys():
		var crop = farm_data[pos]
		if not crop["is_mature"] and not crop["is_thirsty"]:
			crop["timer"] += delta
			var config = crop_configs[crop["type"]]
			if crop["timer"] >= config["grow_time"]:
				crop["timer"] = 0.0
				try_advance_stage(pos, crop, config)

func try_advance_stage(pos, crop, config):
	var current_stage = crop["stage"]
	if current_stage in config["needs_water_at"]:
		crop["is_thirsty"] = true
		print("植物渴了: ", pos)
		
		# --- 新逻辑：生成图标场景 ---
		if not crop.has("icon_node") or crop["icon_node"] == null:
			# 1. 实例化场景
			var icon_instance = water_icon_scene.instantiate()
			# 2. 设置位置 (把格子坐标转回世界坐标，并居中)
			# map_to_local 会返回格子的中心点
			icon_instance.position = tile_map_ground.map_to_local(pos)
			# 3. 加到场景里
			add_child(icon_instance)
			# 4. 记录下来，方便以后删除
			crop["icon_node"] = icon_instance
	else:
		grow_to_next_stage(pos, crop, config)

func grow_to_next_stage(pos, crop, config):
	var max_stage = config["stages"].size() - 1
	if crop["stage"] < max_stage:
		crop["stage"] += 1
		if crop["stage"] == max_stage:
			crop["is_mature"] = true
			print("成熟了！")
		update_plant_visual(pos)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			use_tool(get_global_mouse_position())

func use_tool(mouse_global_pos):
	var grid_pos = tile_map_ground.local_to_map(mouse_global_pos)
	var current_type = ui.get_current_item_type()
	
	if current_type == ItemType.HOE:
		harvest_plant(grid_pos)
	elif current_type == ItemType.WATER:
		water_plant(grid_pos)
	elif current_type == ItemType.SEED_TOMATO:
		plant_seed(grid_pos, "tomato")
	elif current_type == ItemType.SEED_WHEAT:
		plant_seed(grid_pos, "wheat")

func plant_seed(grid_pos, type):
	if farm_data.has(grid_pos): return
	var tile_data = tile_map_ground.get_cell_tile_data(grid_pos)
	if not tile_data or tile_data.get_custom_data("can_farm") == false: return
	
	if ui.has_current_item():
		ui.consume_current_item()
		farm_data[grid_pos] = {
			"type": type,
			"stage": 0,
			"timer": 0.0,
			"is_thirsty": false,
			"is_mature": false,
			"icon_node": null # 初始化为空
		}
		update_plant_visual(grid_pos)
	else:
		print("种子没了！")

func water_plant(grid_pos):
	if not farm_data.has(grid_pos): return
	var crop = farm_data[grid_pos]
	
	if crop["is_thirsty"]:
		print("浇水成功！")
		crop["is_thirsty"] = false
		
		# --- 新逻辑：删除图标 ---
		if crop["icon_node"] != null:
			crop["icon_node"].queue_free() # 从游戏里删除
			crop["icon_node"] = null # 清空记录
		
		var config = crop_configs[crop["type"]]
		grow_to_next_stage(grid_pos, crop, config)

func harvest_plant(grid_pos):
	if not farm_data.has(grid_pos): return
	var crop = farm_data[grid_pos]
	
	if crop["is_mature"]:
		var config = crop_configs[crop["type"]]
		ui.add_item(config["harvest_item"], 1)
		
		# 防止意外：如果有图标没删掉，这里也删一次
		if crop.has("icon_node") and crop["icon_node"] != null:
			crop["icon_node"].queue_free()
			
		farm_data.erase(grid_pos)
		tile_map_farm.erase_cell(grid_pos)

func update_plant_visual(pos):
	var crop = farm_data[pos]
	var config = crop_configs[crop["type"]]
	var coords = config["stages"][crop["stage"]]
	tile_map_farm.set_cell(pos, PLANT_SOURCE_ID, coords)
