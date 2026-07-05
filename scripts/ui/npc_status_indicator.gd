extends Node2D
class_name NPCStatusIndicator

enum QuestMarkerState {
	NONE,
	AVAILABLE,
	ACTIVE,
	READY,
}

@export var available_quest_icon: Texture2D
@export var active_quest_icon: Texture2D

@onready var quest_marker: Sprite2D = $QuestMarker

var _quest_state: QuestMarkerState = QuestMarkerState.NONE


func _ready() -> void:
	_set_mouse_filter_recursive(self)
	hide_all()


func set_quest_state(state: QuestMarkerState) -> void:
	_quest_state = state

	match _quest_state:
		QuestMarkerState.NONE:
			quest_marker.hide()
		QuestMarkerState.AVAILABLE:
			quest_marker.texture = available_quest_icon
			quest_marker.show()
		QuestMarkerState.ACTIVE:
			quest_marker.hide()
		QuestMarkerState.READY:
			quest_marker.texture = active_quest_icon
			quest_marker.show()


func get_quest_state() -> QuestMarkerState:
	return _quest_state


func show_interaction_prompt() -> void:
	pass


func hide_interaction_prompt() -> void:
	pass


func hide_all() -> void:
	quest_marker.hide()


func is_interaction_prompt_visible() -> bool:
	return false


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in node.get_children():
		_set_mouse_filter_recursive(child)
