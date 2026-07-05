extends Resource
class_name QuestData

@export_group("Identity")
@export var quest_id: StringName = &""
@export var giver_npc_id: StringName = &""
@export var title_cn: String = ""
@export var title_en: String = ""
@export_multiline var description_cn: String = ""
@export_multiline var description_en: String = ""

@export_group("Objectives")
@export var objectives: Array[QuestObjectiveData] = []

@export_group("Flow")
@export var next_quest_id: StringName = &""
@export var repeatable: bool = false

@export_group("Rewards")
@export_range(0, 999999, 1) var reward_coins: int = 0
@export var reward_item_id: StringName = &""
@export_range(0, 9999, 1) var reward_item_amount: int = 0


func is_valid_quest() -> bool:
	if String(quest_id).strip_edges().is_empty():
		return false
	if String(giver_npc_id).strip_edges().is_empty():
		return false
	return get_valid_objective_count() > 0


func get_title() -> String:
	if not title_cn.strip_edges().is_empty():
		return title_cn
	if not title_en.strip_edges().is_empty():
		return title_en
	return String(quest_id)


func get_description() -> String:
	if not description_cn.strip_edges().is_empty():
		return description_cn
	if not description_en.strip_edges().is_empty():
		return description_en
	return ""


func get_objective(objective_id: StringName) -> QuestObjectiveData:
	if String(objective_id).strip_edges().is_empty():
		return null
	for objective: QuestObjectiveData in objectives:
		if objective != null and objective.is_valid_objective() and objective.objective_id == objective_id:
			return objective
	return null


func get_valid_objective_count() -> int:
	var count: int = 0
	for objective: QuestObjectiveData in objectives:
		if objective != null and objective.is_valid_objective():
			count += 1
	return count
