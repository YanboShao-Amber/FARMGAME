extends Resource
class_name DialogueSequenceData

@export var sequence_id: StringName = &""
@export var lines: Array[DialogueLineData] = []
@export var one_shot: bool = false


func is_valid_sequence() -> bool:
	if String(sequence_id).strip_edges().is_empty():
		return false
	return get_valid_line_count() > 0


func get_valid_line_count() -> int:
	var valid_line_count: int = 0
	for line: DialogueLineData in lines:
		if line != null and line.is_valid_line():
			valid_line_count += 1
	return valid_line_count


func get_line(index: int) -> DialogueLineData:
	if index < 0 or index >= lines.size():
		return null

	var line: DialogueLineData = lines[index]
	if line == null or not line.is_valid_line():
		return null
	return line
