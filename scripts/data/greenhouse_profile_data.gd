extends Resource
class_name GreenhouseProfileData

enum GreenhouseState {
	ABANDONED,
	REPAIRING,
	RESTORED,
}

@export_group("Identity")
@export var greenhouse_id: StringName = &""
@export var steward_npc_id: StringName = &""
@export var display_name_cn: String = ""
@export var display_name_en: String = ""

@export_group("State")
@export var initial_state: GreenhouseState = GreenhouseState.ABANDONED

@export_group("Abandoned")
@export var abandoned_name_cn: String = "废弃"
@export var abandoned_name_en: String = "Abandoned"
@export_multiline var abandoned_description_cn: String = ""
@export_multiline var abandoned_description_en: String = ""

@export_group("Repairing")
@export var repairing_name_cn: String = "修复中"
@export var repairing_name_en: String = "Repairing"
@export_multiline var repairing_description_cn: String = ""
@export_multiline var repairing_description_en: String = ""

@export_group("Restored")
@export var restored_name_cn: String = "已恢复"
@export var restored_name_en: String = "Restored"
@export_multiline var restored_description_cn: String = ""
@export_multiline var restored_description_en: String = ""


func is_valid_profile() -> bool:
	if String(greenhouse_id).strip_edges().is_empty():
		return false
	if String(steward_npc_id).strip_edges().is_empty():
		return false
	return is_valid_state(initial_state)


func is_valid_state(state: int) -> bool:
	match state:
		GreenhouseState.ABANDONED, GreenhouseState.REPAIRING, GreenhouseState.RESTORED:
			return true
		_:
			return false


func get_display_name() -> String:
	var cn_name: String = display_name_cn.strip_edges()
	var en_name: String = display_name_en.strip_edges()

	if not cn_name.is_empty():
		return cn_name
	if not en_name.is_empty():
		return en_name
	return String(greenhouse_id)


func get_state_name(state: int) -> String:
	match state:
		GreenhouseState.ABANDONED:
			return _preferred_text(abandoned_name_cn, abandoned_name_en, "Abandoned")
		GreenhouseState.REPAIRING:
			return _preferred_text(repairing_name_cn, repairing_name_en, "Repairing")
		GreenhouseState.RESTORED:
			return _preferred_text(restored_name_cn, restored_name_en, "Restored")
		_:
			return "Unknown"


func get_state_description(state: int) -> String:
	match state:
		GreenhouseState.ABANDONED:
			return _preferred_text(abandoned_description_cn, abandoned_description_en, "")
		GreenhouseState.REPAIRING:
			return _preferred_text(repairing_description_cn, repairing_description_en, "")
		GreenhouseState.RESTORED:
			return _preferred_text(restored_description_cn, restored_description_en, "")
		_:
			return ""


func get_final_state() -> GreenhouseState:
	return GreenhouseState.RESTORED


func _preferred_text(cn_text: String, en_text: String, fallback: String) -> String:
	var normalized_cn: String = cn_text.strip_edges()
	if not normalized_cn.is_empty():
		return normalized_cn

	var normalized_en: String = en_text.strip_edges()
	if not normalized_en.is_empty():
		return normalized_en

	return fallback
