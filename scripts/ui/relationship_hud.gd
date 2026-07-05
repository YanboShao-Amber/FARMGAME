extends CanvasLayer
class_name RelationshipHUD

@export_group("Tracked NPC")
@export var npc_data: NPCData

@export_group("Feedback")
@export_range(0.1, 5.0, 0.1) var feedback_duration: float = 1.5
@export_range(0.0, 32.0, 1.0) var feedback_vertical_offset: float = 8.0
@export var maxed_text_cn: String = "\u5df2\u8fbe\u6ee1\u5fc3"
@export var no_change_text_cn: String = "\u597d\u611f\u672a\u53d8\u5316"

@export_group("Visuals")
@export var heart_texture: Texture2D

@onready var root: Control = $Root
@onready var relationship_panel: NinePatchRect = $Root/SafeMargin/RelationshipPanel
@onready var npc_name_label: Label = $Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeaderRow/NPCNameLabel
@onready var relationship_icon: TextureRect = $Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeaderRow/RelationshipIcon
@onready var heart_slots: Array[TextureRect] = [
	$Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeartRow/Heart1,
	$Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeartRow/Heart2,
	$Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeartRow/Heart3,
	$Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeartRow/Heart4,
	$Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/HeartRow/Heart5,
]
@onready var heart_level_label: Label = $Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/ProgressRow/HeartLevelLabel
@onready var points_label: Label = $Root/SafeMargin/RelationshipPanel/PanelMargin/ContentColumn/ProgressRow/PointsLabel
@onready var feedback_layer: Control = $Root/SafeMargin/RelationshipPanel/FeedbackLayer
@onready var feedback_label: Label = $Root/SafeMargin/RelationshipPanel/FeedbackLayer/FeedbackLabel

var _tracked_npc_id: StringName = &""
var _relationship_ui_unlocked: bool = false
var _feedback_tween: Tween = null
var _feedback_original_position: Vector2 = Vector2.ZERO
var _relationship_manager: Node = null
var _gift_manager: Node = null
var _missing_npc_warning_pushed: bool = false
var _missing_relationship_manager_warning_pushed: bool = false
var _missing_gift_manager_warning_pushed: bool = false
var _max_heart_warning_pushed: bool = false


func _ready() -> void:
	root.hide()
	_set_mouse_filter_recursive(root)
	relationship_panel.hide()
	feedback_label.hide()
	_feedback_original_position = feedback_label.position

	_relationship_manager = get_node_or_null("/root/RelationshipManager")
	_gift_manager = get_node_or_null("/root/GiftManager")
	_validate_tracked_npc()
	_connect_relationship_manager_signals()
	_connect_gift_manager_signals()
	_relationship_ui_unlocked = _should_be_unlocked_from_runtime_state()
	_refresh()


func _exit_tree() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null


func _validate_tracked_npc() -> bool:
	if npc_data == null:
		if not _missing_npc_warning_pushed:
			push_warning("RelationshipHUD cannot initialize because npc_data is missing.")
			_missing_npc_warning_pushed = true
		_tracked_npc_id = &""
		return false

	_tracked_npc_id = npc_data.npc_id
	if String(_tracked_npc_id).strip_edges().is_empty():
		if not _missing_npc_warning_pushed:
			push_warning("RelationshipHUD cannot initialize because npc_data.npc_id is empty.")
			_missing_npc_warning_pushed = true
		return false

	return true


func _connect_relationship_manager_signals() -> void:
	if _relationship_manager == null:
		if not _missing_relationship_manager_warning_pushed:
			push_warning("RelationshipHUD cannot connect because RelationshipManager is unavailable.")
			_missing_relationship_manager_warning_pushed = true
		return

	_connect_manager_signal(_relationship_manager, &"relationship_registered", _on_relationship_registered)
	_connect_manager_signal(_relationship_manager, &"relationship_points_changed", _on_relationship_points_changed)
	_connect_manager_signal(_relationship_manager, &"relationship_heart_changed", _on_relationship_heart_changed)
	_connect_manager_signal(_relationship_manager, &"relationship_maxed", _on_relationship_maxed)
	_connect_manager_signal(_relationship_manager, &"relationship_reset", _on_relationship_reset)


func _connect_gift_manager_signals() -> void:
	if _gift_manager == null:
		if not _missing_gift_manager_warning_pushed:
			push_warning("RelationshipHUD cannot connect because GiftManager is unavailable.")
			_missing_gift_manager_warning_pushed = true
		return

	_connect_manager_signal(_gift_manager, &"gift_profile_registered", _on_gift_profile_registered)
	_connect_manager_signal(_gift_manager, &"gift_given", _on_gift_given)
	_connect_manager_signal(_gift_manager, &"gift_history_reset", _on_gift_history_reset)


func _connect_manager_signal(manager: Node, signal_name: StringName, handler: Callable) -> void:
	if manager == null:
		return
	if not manager.has_signal(signal_name):
		return
	if not manager.is_connected(signal_name, handler):
		manager.connect(signal_name, handler)


func _on_relationship_registered(npc_id: StringName) -> void:
	if npc_id != _tracked_npc_id:
		return
	if _should_be_unlocked_from_runtime_state():
		_relationship_ui_unlocked = true
	_refresh()


func _on_relationship_points_changed(npc_id: StringName, _previous_points: int, _current_points: int, _delta: int) -> void:
	if npc_id != _tracked_npc_id:
		return
	if not _relationship_ui_unlocked and _points_differ_from_starting():
		_relationship_ui_unlocked = true
	_refresh()


func _on_relationship_heart_changed(npc_id: StringName, _previous_hearts: int, _current_hearts: int) -> void:
	if npc_id != _tracked_npc_id:
		return
	_refresh()


func _on_relationship_maxed(npc_id: StringName) -> void:
	if npc_id != _tracked_npc_id:
		return
	_refresh()


func _on_relationship_reset(npc_id: StringName) -> void:
	if npc_id != _tracked_npc_id:
		return
	_refresh()


func _on_gift_profile_registered(npc_id: StringName) -> void:
	if npc_id != _tracked_npc_id:
		return
	if _should_be_unlocked_from_runtime_state():
		_relationship_ui_unlocked = true
	_refresh()


func _on_gift_given(npc_id: StringName, _item_id: StringName, _reaction: int, _relationship_points: int, _day_id: int) -> void:
	if npc_id != _tracked_npc_id:
		return

	var previous_points: int = _get_current_points()
	_relationship_ui_unlocked = true
	_refresh()
	call_deferred("_show_deferred_gift_feedback", previous_points)


func _on_gift_history_reset(npc_id: StringName) -> void:
	if npc_id != _tracked_npc_id:
		return

	_relationship_ui_unlocked = _should_be_unlocked_from_runtime_state()
	_refresh()


func _show_deferred_gift_feedback(previous_points: int) -> void:
	if not is_inside_tree():
		return
	var current_points: int = _get_current_points()
	_refresh()
	_show_relationship_feedback(previous_points, current_points)


func _should_be_unlocked_from_runtime_state() -> bool:
	if String(_tracked_npc_id).strip_edges().is_empty():
		return false
	if _points_differ_from_starting():
		return true
	return _has_valid_last_gift_day()


func _points_differ_from_starting() -> bool:
	var profile: RelationshipProfileData = _get_profile()
	if profile == null:
		return false
	return _get_current_points() != profile.clamp_points(profile.starting_points)


func _has_valid_last_gift_day() -> bool:
	if _gift_manager == null:
		return false
	if not _gift_manager.has_method("get_last_gift_day"):
		return false
	return int(_gift_manager.call("get_last_gift_day", _tracked_npc_id)) >= 1


func _refresh() -> void:
	if not _validate_tracked_npc():
		_hide_hud()
		return

	if not _is_relationship_registered():
		_hide_hud()
		return

	var profile: RelationshipProfileData = _get_profile()
	if profile == null or not profile.is_valid_profile():
		_hide_hud()
		return

	var current_points: int = _get_current_points()
	var maximum_points: int = _get_max_points()
	var current_hearts: int = _get_heart_level()
	var maximum_hearts: int = _get_max_hearts()
	if maximum_hearts != 5 and not _max_heart_warning_pushed:
		push_warning("RelationshipHUD is designed for five heart slots, but npc_id '%s' has %d max hearts." % [String(_tracked_npc_id), maximum_hearts])
		_max_heart_warning_pushed = true

	var displayed_hearts: int = clampi(current_hearts, 0, heart_slots.size())
	npc_name_label.text = npc_data.get_display_name()
	heart_level_label.text = "%d / %d \u5fc3" % [current_hearts, maximum_hearts]
	points_label.text = "%d / %d" % [current_points, maximum_points]

	for index in range(heart_slots.size()):
		_set_heart_filled(heart_slots[index], index < displayed_hearts)

	if _relationship_ui_unlocked:
		root.show()
		relationship_panel.show()
	else:
		_hide_hud()


func _hide_hud() -> void:
	if root != null:
		root.hide()
	if relationship_panel != null:
		relationship_panel.hide()


func _show_relationship_feedback(previous_points: int, current_points: int) -> void:
	if feedback_label == null:
		return
	if not _relationship_ui_unlocked:
		return

	var actual_delta: int = current_points - previous_points
	if actual_delta > 0:
		feedback_label.text = "+%d" % actual_delta
	elif actual_delta < 0:
		feedback_label.text = "%d" % actual_delta
	elif _is_relationship_maxed():
		feedback_label.text = maxed_text_cn
	else:
		feedback_label.text = no_change_text_cn

	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	feedback_label.position = _feedback_original_position
	feedback_label.modulate = Color(0.35, 0.18, 0.11, 1.0)
	feedback_label.show()

	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(feedback_label, "position:y", _feedback_original_position.y - feedback_vertical_offset, feedback_duration)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, min(0.45, feedback_duration)).set_delay(max(0.0, feedback_duration - 0.45))
	_feedback_tween.chain().tween_callback(Callable(self, "_hide_feedback_label"))


func _hide_feedback_label() -> void:
	if feedback_label == null:
		return
	feedback_label.hide()
	feedback_label.position = _feedback_original_position
	feedback_label.modulate.a = 1.0


func _set_heart_filled(heart_node: TextureRect, filled: bool) -> void:
	if heart_node == null:
		return
	heart_node.texture = heart_texture
	heart_node.modulate = Color(1.0, 1.0, 1.0, 1.0) if filled else Color(1.0, 1.0, 1.0, 0.35)


func _is_relationship_registered() -> bool:
	if _relationship_manager == null:
		return false
	if not _relationship_manager.has_method("is_profile_registered"):
		return false
	return bool(_relationship_manager.call("is_profile_registered", _tracked_npc_id))


func _get_profile() -> RelationshipProfileData:
	if _relationship_manager == null:
		return null
	if not _relationship_manager.has_method("get_profile"):
		return null
	return _relationship_manager.call("get_profile", _tracked_npc_id) as RelationshipProfileData


func _get_current_points() -> int:
	if _relationship_manager == null:
		return 0
	if not _relationship_manager.has_method("get_points"):
		return 0
	return int(_relationship_manager.call("get_points", _tracked_npc_id))


func _get_max_points() -> int:
	if _relationship_manager == null:
		return 0
	if not _relationship_manager.has_method("get_max_points"):
		return 0
	return int(_relationship_manager.call("get_max_points", _tracked_npc_id))


func _get_heart_level() -> int:
	if _relationship_manager == null:
		return 0
	if not _relationship_manager.has_method("get_heart_level"):
		return 0
	return int(_relationship_manager.call("get_heart_level", _tracked_npc_id))


func _get_max_hearts() -> int:
	if _relationship_manager == null:
		return 0
	if not _relationship_manager.has_method("get_max_hearts"):
		return 0
	return int(_relationship_manager.call("get_max_hearts", _tracked_npc_id))


func _is_relationship_maxed() -> bool:
	if _relationship_manager == null:
		return false
	if not _relationship_manager.has_method("is_relationship_maxed"):
		return false
	return bool(_relationship_manager.call("is_relationship_maxed", _tracked_npc_id))


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in node.get_children():
		_set_mouse_filter_recursive(child)
