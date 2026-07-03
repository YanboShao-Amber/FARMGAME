extends Node2D

enum ItemType { NONE, HOE, WATER, AXE, SEED_TOMATO, SEED_WHEAT, CROP_TOMATO, CROP_WHEAT }

const PLANT_SOURCE_ID := 0
const TILLED_SOURCE_ID := 1
const TILLED_ATLAS_COORDS := Vector2i(1, 1)
const TREE_SOURCE_ID := 1
const TREE_ATLAS_COORDS := [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(3, 0),
]
const PLAYER_FOOT_OFFSET := Vector2(0, 7)

@onready var tile_map_ground: TileMapLayer = $LandLayer
@onready var tile_map_farm: TileMapLayer = $FarmLayer
@onready var tile_map_env: TileMapLayer = $EnvLayer
@onready var ui: CanvasLayer = $GameUI

var water_icon_scene := preload("res://water_icon.tscn")

var crop_configs := {
	"tomato": {
		"stages": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
		"harvest_item": ItemType.CROP_TOMATO,
		"grow_time": 3.0,
		"needs_water_at": [0, 2],
	},
	"wheat": {
		"stages": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)],
		"harvest_item": ItemType.CROP_WHEAT,
		"grow_time": 2.0,
		"needs_water_at": [1],
	},
}

var farm_data := {}
var tilled_cells := {}

func _process(delta: float) -> void:
	for pos in farm_data.keys():
		var crop: Dictionary = farm_data[pos]
		if crop["is_mature"] or crop["is_thirsty"]:
			continue

		crop["timer"] += delta
		var config: Dictionary = crop_configs[crop["type"]]
		if crop["timer"] >= config["grow_time"]:
			crop["timer"] = 0.0
			try_advance_stage(pos, crop, config)

func use_current_tool_from_player(player: Node2D) -> String:
	var current_type: int = ui.get_current_item_type()
	var target_cell := get_player_target_cell(player)

	if current_type == ItemType.HOE:
		if harvest_plant(target_cell):
			return "tilling_state"
		if till_ground(target_cell):
			return "tilling_state"
	elif current_type == ItemType.WATER:
		if water_ground_or_plant(target_cell):
			return "watering_state"
	elif current_type == ItemType.AXE:
		if chop_tree(target_cell):
			return "chopping_state"
	elif current_type == ItemType.SEED_TOMATO:
		if plant_seed(target_cell, "tomato"):
			return "planting_state"
	elif current_type == ItemType.SEED_WHEAT:
		if plant_seed(target_cell, "wheat"):
			return "planting_state"

	return ""

func get_player_target_cell(player: Node2D) -> Vector2i:
	var foot_position := player.global_position + PLAYER_FOOT_OFFSET
	var current_cell := tile_map_ground.local_to_map(tile_map_ground.to_local(foot_position))
	var facing := Vector2.DOWN
	var player_facing = player.get("player_direction")
	if player_facing is Vector2:
		facing = player_facing

	return current_cell + _direction_to_cell_offset(facing)

func try_advance_stage(pos: Vector2i, crop: Dictionary, config: Dictionary) -> void:
	var current_stage: int = crop["stage"]
	if current_stage in config["needs_water_at"]:
		crop["is_thirsty"] = true
		_show_water_icon(pos, crop)
	else:
		grow_to_next_stage(pos, crop, config)

func grow_to_next_stage(pos: Vector2i, crop: Dictionary, config: Dictionary) -> void:
	var max_stage: int = config["stages"].size() - 1
	if crop["stage"] >= max_stage:
		return

	crop["stage"] += 1
	if crop["stage"] == max_stage:
		crop["is_mature"] = true
	update_plant_visual(pos)

func till_ground(grid_pos: Vector2i) -> bool:
	if farm_data.has(grid_pos) or not _can_till_cell(grid_pos):
		return false

	tile_map_ground.set_cell(grid_pos, TILLED_SOURCE_ID, TILLED_ATLAS_COORDS)
	tilled_cells[grid_pos] = { "watered": false }
	return true

func plant_seed(grid_pos: Vector2i, type: String) -> bool:
	if farm_data.has(grid_pos) or not _can_plant_at(grid_pos) or not ui.has_current_item():
		return false

	if not ui.consume_current_item():
		return false

	farm_data[grid_pos] = {
		"type": type,
		"stage": 0,
		"timer": 0.0,
		"is_thirsty": false,
		"is_mature": false,
		"icon_node": null,
	}
	update_plant_visual(grid_pos)
	return true

func water_ground_or_plant(grid_pos: Vector2i) -> bool:
	if water_plant(grid_pos):
		return true

	if _can_plant_at(grid_pos):
		var tilled_data: Dictionary = tilled_cells.get(grid_pos, {})
		tilled_data["watered"] = true
		tilled_cells[grid_pos] = tilled_data
		return true

	return false

func water_plant(grid_pos: Vector2i) -> bool:
	if not farm_data.has(grid_pos):
		return false

	var crop: Dictionary = farm_data[grid_pos]
	if not crop["is_thirsty"]:
		return false

	crop["is_thirsty"] = false
	if crop["icon_node"] != null:
		crop["icon_node"].queue_free()
		crop["icon_node"] = null

	var config: Dictionary = crop_configs[crop["type"]]
	grow_to_next_stage(grid_pos, crop, config)
	return true

func harvest_plant(grid_pos: Vector2i) -> bool:
	if not farm_data.has(grid_pos):
		return false

	var crop: Dictionary = farm_data[grid_pos]
	if not crop["is_mature"]:
		return false

	var config: Dictionary = crop_configs[crop["type"]]
	ui.add_item(config["harvest_item"], 1)

	if crop.has("icon_node") and crop["icon_node"] != null:
		crop["icon_node"].queue_free()

	farm_data.erase(grid_pos)
	tile_map_farm.erase_cell(grid_pos)
	return true

func chop_tree(grid_pos: Vector2i) -> bool:
	var tree_cell = _find_tree_cell(grid_pos)
	if tree_cell == null:
		return false

	tile_map_env.erase_cell(tree_cell)
	return true

func update_plant_visual(pos: Vector2i) -> void:
	var crop: Dictionary = farm_data[pos]
	var config: Dictionary = crop_configs[crop["type"]]
	var coords: Vector2i = config["stages"][crop["stage"]]
	tile_map_farm.set_cell(pos, PLANT_SOURCE_ID, coords)

func _show_water_icon(pos: Vector2i, crop: Dictionary) -> void:
	if crop.has("icon_node") and crop["icon_node"] != null:
		return

	var icon_instance := water_icon_scene.instantiate()
	icon_instance.global_position = tile_map_ground.to_global(tile_map_ground.map_to_local(pos))
	add_child(icon_instance)
	crop["icon_node"] = icon_instance

func _can_till_cell(grid_pos: Vector2i) -> bool:
	if tile_map_ground.get_cell_source_id(grid_pos) == -1:
		return false

	return tile_map_ground.get_cell_source_id(grid_pos) != 4

func _can_plant_at(grid_pos: Vector2i) -> bool:
	if tilled_cells.has(grid_pos):
		return true

	var tile_data := tile_map_ground.get_cell_tile_data(grid_pos)
	return tile_data != null and tile_data.get_custom_data("can_farm") == true

func _find_tree_cell(grid_pos: Vector2i):
	var possible_anchor_offsets: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(-1, -1),
	]

	for offset: Vector2i in possible_anchor_offsets:
		var cell: Vector2i = grid_pos + offset
		if tile_map_env.get_cell_source_id(cell) != TREE_SOURCE_ID:
			continue

		var atlas_coords: Vector2i = tile_map_env.get_cell_atlas_coords(cell)
		if atlas_coords in TREE_ATLAS_COORDS:
			return cell

	return null

func _direction_to_cell_offset(direction: Vector2) -> Vector2i:
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			return Vector2i.RIGHT
		return Vector2i.LEFT

	if direction.y < 0.0:
		return Vector2i.UP
	return Vector2i.DOWN
