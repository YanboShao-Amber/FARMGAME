extends CanvasLayer

const TOGGLE_KEY: int = KEY_J

@export_group("Tracked Quests")
@export var tracked_quest_id: StringName = &""
@export var tracked_quest_ids: Array[StringName] = []

@export_group("Panel Text")
@export var empty_text_cn: String = "当前没有进行中的任务"
@export var active_text_cn: String = "进行中"
@export var ready_text_cn: String = "可交付"
@export var npc_prefix_cn: String = "委托人："

@export_group("State Icons")
@export var active_status_texture: Texture2D
@export var ready_status_texture: Texture2D

@onready var root: Control = $Root
@onready var quest_button: TextureButton = $Root/ButtonMargin/QuestButton
@onready var tracker_panel: Panel = $Root/PanelCenter/TrackerPanel
@onready var quest_title: Label = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/HeaderRow/QuestTitle
@onready var page_label: Label = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/HeaderRow/PageLabel
@onready var npc_label: Label = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/NPCLabel
@onready var description_label: Label = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/DescriptionLabel
@onready var objectives_box: VBoxContainer = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/ObjectivesBox
@onready var status_icon: TextureRect = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/StatusRow/StatusIcon
@onready var status_text: Label = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/StatusRow/StatusText
@onready var prev_button: TextureButton = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/FooterRow/PrevButton
@onready var next_button: TextureButton = $Root/PanelCenter/TrackerPanel/ContentMargin/PanelColumn/FooterRow/NextButton
@onready var close_button: TextureButton = $Root/PanelCenter/TrackerPanel/CloseButton

var _quest_manager: Node = null
var _visible_quest_ids: Array[StringName] = []
var _page_index: int = 0
var _missing_manager_warning_pushed: bool = false


func _ready() -> void:
	root.show()
	tracker_panel.hide()
	_quest_manager = get_node_or_null("/root/QuestManager")
	_connect_buttons()
	_connect_quest_manager_signals()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == TOGGLE_KEY:
			_toggle_panel()
			get_viewport().set_input_as_handled()


func _connect_buttons() -> void:
	if not quest_button.pressed.is_connected(_toggle_panel):
		quest_button.pressed.connect(_toggle_panel)
	if not prev_button.pressed.is_connected(_show_previous_page):
		prev_button.pressed.connect(_show_previous_page)
	if not next_button.pressed.is_connected(_show_next_page):
		next_button.pressed.connect(_show_next_page)
	if not close_button.pressed.is_connected(_hide_panel):
		close_button.pressed.connect(_hide_panel)


func _connect_quest_manager_signals() -> void:
	if _quest_manager == null:
		return

	_connect_quest_signal(&"quest_registered", _on_quest_changed)
	_connect_quest_signal(&"quest_started", _on_quest_changed)
	_connect_quest_signal(&"objective_progress_changed", _on_objective_progress_changed)
	_connect_quest_signal(&"quest_ready_to_turn_in", _on_quest_changed)
	_connect_quest_signal(&"quest_completed", _on_quest_changed)
	_connect_quest_signal(&"quest_reset", _on_quest_changed)


func _connect_quest_signal(signal_name: StringName, handler: Callable) -> void:
	if _quest_manager == null:
		return
	if not _quest_manager.has_signal(signal_name):
		return
	if not _quest_manager.is_connected(signal_name, handler):
		_quest_manager.connect(signal_name, handler)


func _on_quest_changed(_quest_id: StringName) -> void:
	_refresh()


func _on_objective_progress_changed(_quest_id: StringName, _objective_id: StringName, _current_amount: int, _required_amount: int) -> void:
	_refresh()


func _toggle_panel() -> void:
	if tracker_panel.visible:
		_hide_panel()
	else:
		_show_panel()


func _show_panel() -> void:
	tracker_panel.show()
	_refresh()


func _hide_panel() -> void:
	tracker_panel.hide()


func _show_previous_page() -> void:
	if _visible_quest_ids.is_empty():
		return
	_page_index = wrapi(_page_index - 1, 0, _visible_quest_ids.size())
	_refresh_current_page()


func _show_next_page() -> void:
	if _visible_quest_ids.is_empty():
		return
	_page_index = wrapi(_page_index + 1, 0, _visible_quest_ids.size())
	_refresh_current_page()


func _refresh() -> void:
	if _quest_manager == null:
		_visible_quest_ids.clear()
		_refresh_current_page()
		if not _missing_manager_warning_pushed:
			push_warning("QuestTracker cannot refresh because QuestManager is unavailable.")
			_missing_manager_warning_pushed = true
		return

	_visible_quest_ids = _get_visible_quest_ids()
	if _page_index >= _visible_quest_ids.size():
		_page_index = maxi(_visible_quest_ids.size() - 1, 0)
	_refresh_current_page()


func _refresh_current_page() -> void:
	_clear_objective_rows()

	if _visible_quest_ids.is_empty():
		_show_empty_page()
		return

	var quest_id: StringName = _visible_quest_ids[_page_index]
	var quest_data: QuestData = _quest_manager.call("get_quest_data", quest_id) as QuestData
	if quest_data == null:
		_show_empty_page()
		return

	var quest_state: int = int(_quest_manager.call("get_quest_state", quest_id))
	quest_title.text = quest_data.get_title()
	page_label.text = "%d/%d" % [_page_index + 1, _visible_quest_ids.size()]
	npc_label.text = "%s%s" % [npc_prefix_cn, _get_npc_display_name(quest_data.giver_npc_id)]
	description_label.text = quest_data.get_description()
	_add_objective_rows(quest_id, quest_data)
	_show_status(quest_state)
	_update_page_buttons()


func _show_empty_page() -> void:
	quest_title.text = "任务"
	page_label.text = "0/0"
	npc_label.text = ""
	description_label.text = empty_text_cn
	status_text.text = ""
	status_icon.texture = null
	status_icon.hide()
	prev_button.disabled = true
	next_button.disabled = true


func _get_visible_quest_ids() -> Array[StringName]:
	var quest_ids: Array[StringName] = _get_configured_quest_ids()
	var visible_ids: Array[StringName] = []

	for quest_id: StringName in quest_ids:
		if String(quest_id).strip_edges().is_empty():
			continue
		if not _quest_manager.has_method("is_quest_registered") or not bool(_quest_manager.call("is_quest_registered", quest_id)):
			continue
		var state: int = int(_quest_manager.call("get_quest_state", quest_id))
		if state == QuestManager.QuestState.ACTIVE or state == QuestManager.QuestState.READY_TO_TURN_IN:
			visible_ids.append(quest_id)

	return visible_ids


func _get_configured_quest_ids() -> Array[StringName]:
	var quest_ids: Array[StringName] = []

	if not String(tracked_quest_id).strip_edges().is_empty():
		quest_ids.append(tracked_quest_id)

	for quest_id: StringName in tracked_quest_ids:
		if String(quest_id).strip_edges().is_empty():
			continue
		if quest_ids.has(quest_id):
			continue
		quest_ids.append(quest_id)

	return quest_ids


func _add_objective_rows(quest_id: StringName, quest_data: QuestData) -> void:
	for objective: QuestObjectiveData in quest_data.objectives:
		if objective == null or not objective.is_valid_objective():
			continue

		var current_amount: int = int(_quest_manager.call("get_objective_progress", quest_id, objective.objective_id))
		var required_amount: int = int(_quest_manager.call("get_objective_required_amount", quest_id, objective.objective_id))
		required_amount = maxi(required_amount, objective.required_amount)
		current_amount = clampi(current_amount, 0, required_amount)

		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 36)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)

		var objective_label: Label = Label.new()
		objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		objective_label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.1, 1.0))
		objective_label.add_theme_font_size_override("font_size", 23)
		objective_label.text = objective.get_description()
		objective_label.clip_text = true
		objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(objective_label)

		var progress_label: Label = Label.new()
		progress_label.custom_minimum_size = Vector2(96, 0)
		progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress_label.add_theme_color_override("font_color", Color(0.23, 0.13, 0.08, 1.0))
		progress_label.add_theme_font_size_override("font_size", 24)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		progress_label.text = "%d/%d" % [current_amount, required_amount]
		row.add_child(progress_label)

		objectives_box.add_child(row)


func _show_status(quest_state: int) -> void:
	var is_ready: bool = quest_state == QuestManager.QuestState.READY_TO_TURN_IN
	status_text.text = ready_text_cn if is_ready else active_text_cn
	status_icon.texture = ready_status_texture if is_ready else active_status_texture
	status_icon.visible = status_icon.texture != null


func _update_page_buttons() -> void:
	var has_multiple_pages: bool = _visible_quest_ids.size() > 1
	prev_button.disabled = not has_multiple_pages
	next_button.disabled = not has_multiple_pages


func _clear_objective_rows() -> void:
	for child: Node in objectives_box.get_children():
		objectives_box.remove_child(child)
		child.queue_free()


func _get_npc_display_name(npc_id: StringName) -> String:
	match npc_id:
		&"mira":
			return "米萝 Mira"
		_:
			return String(npc_id)
