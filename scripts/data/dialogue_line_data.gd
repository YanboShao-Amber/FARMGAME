extends Resource
class_name DialogueLineData

@export_multiline var text: String = ""
@export var expression_id: StringName = &"neutral"


func is_valid_line() -> bool:
	return not text.strip_edges().is_empty()
