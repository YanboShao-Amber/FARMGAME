extends Resource
class_name QuestObjectiveData

enum ObjectiveType {
	HARVEST_CROP,
	COLLECT_ITEM,
	DELIVER_ITEM,
	DEFEAT_ENEMY,
	INTERACT_OBJECT,
	TALK_TO_NPC,
	PLANT_CROP,
	WATER_CROP,
}

@export_group("Identity")
@export var objective_id: StringName = &""
@export var objective_type: ObjectiveType = ObjectiveType.COLLECT_ITEM
@export var target_id: StringName = &""

@export_group("Requirements")
@export_range(1, 9999, 1) var required_amount: int = 1
@export var consume_on_turn_in: bool = false

@export_group("Display")
@export_multiline var description_cn: String = ""
@export_multiline var description_en: String = ""


func is_valid_objective() -> bool:
	if String(objective_id).strip_edges().is_empty():
		return false
	if String(target_id).strip_edges().is_empty():
		return false
	return required_amount > 0


func get_description() -> String:
	if not description_cn.strip_edges().is_empty():
		return description_cn
	if not description_en.strip_edges().is_empty():
		return description_en
	return "%s: 0/%d" % [String(target_id), required_amount]
