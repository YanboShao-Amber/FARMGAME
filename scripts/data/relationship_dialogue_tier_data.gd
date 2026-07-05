extends Resource
class_name RelationshipDialogueTierData

@export_group("Relationship Requirement")
@export_range(0, 10, 1) var minimum_hearts: int = 0

@export_group("Dialogue")
@export var sequence_id: StringName = &""


func is_valid_tier() -> bool:
	if minimum_hearts < 0:
		return false
	if String(sequence_id).strip_edges().is_empty():
		return false
	return true
