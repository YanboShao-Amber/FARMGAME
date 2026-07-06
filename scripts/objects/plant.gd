extends StaticBody2D

var coord: Vector2i
var res: PlantResource
var plant_info: PanelContainer
var is_harvested: bool = false

signal plant_death(coord: Vector2i)
signal plant_harvest(coord: Vector2i)

func setup(grid_coord: Vector2i, parent: Node2D, plant_res: PlantResource,
		   plantInfo: PanelContainer, plant_death_func, plant_harvest_func):
	position = grid_coord * Data.TILE_SIZE + Vector2i(8, 5)
	parent.add_child(self)
	coord = grid_coord
	$Sprite2D.texture = plant_res.texture
	res = plant_res
	plant_info = plantInfo
	
	# Signal doesn't care where the function come from(So powerful)
	plant_death.connect(plant_death_func)
	plant_harvest.connect(plant_harvest_func)
	
	
func grow(watered: bool):
	if watered:
		res.grow($Sprite2D)
	else:
		if res.decay(self):
			plant_death.emit(coord)
			plant_info.queue_free()
			return
	
	plant_info.update_info()


func _on_collision_area_body_entered(_body: Node2D) -> void:
	if not res.get_complete():
		return
	if is_harvested:
		return

	var harvested_item = Data.SEED_TO_CROP_ITEM.get(res.curr_seed_enum)
	if harvested_item == null:
		push_warning("Missing seed to crop item mapping for seed id: %s" % res.curr_seed_enum)
		return

	is_harvested = true
	var harvested_amount: int = 2
	var previous_amount: int = Data.ITEMS_AMOUNT[harvested_item]
	Data.ITEMS_AMOUNT[harvested_item] += harvested_amount

	# Phase E: crop harvest no longer grants direct coins. Crops only add the
	# Crop Item (+2) and advance Mira quest progress. Coin value for crops will be
	# handled by the Phase F seller system.
	var actual_harvested_amount: int = Data.ITEMS_AMOUNT[harvested_item] - previous_amount
	if actual_harvested_amount > 0:
		QuestManager.report_event(
			QuestObjectiveData.ObjectiveType.HARVEST_CROP,
			_get_harvested_crop_id(),
			actual_harvested_amount
		)
	print(res.plant_name + " collected")
	plant_harvest.emit(coord)
	plant_info.queue_free()
	self.queue_free()


func _get_harvested_crop_id() -> StringName:
	var seed_names: Array = Enum.Seed.keys()
	var seed_index: int = int(res.curr_seed_enum)
	if seed_index < 0 or seed_index >= seed_names.size():
		return &""
	return StringName(seed_names[seed_index])
