# QuestManager autoload singleton.
# Registered in project.godot as autoload "QuestManager"; therefore this script
# intentionally has NO `class_name` to avoid a naming conflict with the global.
extends Node

enum QuestState {
	INACTIVE,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED,
}

signal quest_registered(quest_id: StringName)
signal quest_started(quest_id: StringName)
signal objective_progress_changed(quest_id: StringName, objective_id: StringName, current_amount: int, required_amount: int)
signal quest_ready_to_turn_in(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_reset(quest_id: StringName)

# quest_id -> QuestData
var _registered_quests: Dictionary = {}
# quest_id -> QuestState
var _quest_states: Dictionary = {}
# quest_id -> Dictionary(objective_id -> current_amount:int)
var _quest_progress: Dictionary = {}


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------
func register_quest(quest_data: QuestData) -> bool:
	if quest_data == null:
		return false
	if not quest_data.is_valid_quest():
		return false

	var quest_id: StringName = quest_data.quest_id
	if String(quest_id).strip_edges().is_empty():
		return false

	if _registered_quests.has(quest_id):
		var existing: QuestData = _registered_quests[quest_id]
		if existing == quest_data:
			# Same resource re-registered: no-op, keep progress, no re-emit.
			return true
		push_warning("QuestManager: quest_id '%s' is already registered with a different resource; registration rejected." % String(quest_id))
		return false

	_registered_quests[quest_id] = quest_data
	if not _quest_states.has(quest_id):
		_quest_states[quest_id] = QuestState.INACTIVE
	_quest_progress[quest_id] = _build_progress_dictionary(quest_data)

	quest_registered.emit(quest_id)
	return true


func unregister_quest(quest_id: StringName) -> bool:
	if not is_quest_registered(quest_id):
		return false
	_registered_quests.erase(quest_id)
	_quest_states.erase(quest_id)
	_quest_progress.erase(quest_id)
	return true


# ---------------------------------------------------------------------------
# Starting
# ---------------------------------------------------------------------------
func start_quest(quest_data: QuestData) -> bool:
	if quest_data == null or not quest_data.is_valid_quest():
		return false
	if not register_quest(quest_data):
		return false

	var quest_id: StringName = quest_data.quest_id
	var state: QuestState = get_quest_state(quest_id)

	match state:
		QuestState.ACTIVE, QuestState.READY_TO_TURN_IN:
			# Already in progress; do not reset or re-emit.
			return true
		QuestState.COMPLETED:
			if not quest_data.repeatable:
				return false
			_reset_progress(quest_id)
			_quest_states[quest_id] = QuestState.ACTIVE
			quest_started.emit(quest_id)
			return true
		_:
			# INACTIVE
			_ensure_progress_entries(quest_id)
			_quest_states[quest_id] = QuestState.ACTIVE
			quest_started.emit(quest_id)
			return true


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
func is_quest_registered(quest_id: StringName) -> bool:
	return _registered_quests.has(quest_id)


func get_quest_data(quest_id: StringName) -> QuestData:
	if _registered_quests.has(quest_id):
		return _registered_quests[quest_id]
	return null


func get_quest_state(quest_id: StringName) -> QuestState:
	if _quest_states.has(quest_id):
		return _quest_states[quest_id]
	return QuestState.INACTIVE


func is_quest_active(quest_id: StringName) -> bool:
	return get_quest_state(quest_id) == QuestState.ACTIVE


func is_quest_ready_to_turn_in(quest_id: StringName) -> bool:
	return get_quest_state(quest_id) == QuestState.READY_TO_TURN_IN


func is_quest_completed(quest_id: StringName) -> bool:
	return get_quest_state(quest_id) == QuestState.COMPLETED


func get_objective_progress(quest_id: StringName, objective_id: StringName) -> int:
	if not _quest_progress.has(quest_id):
		return 0
	var progress: Dictionary = _quest_progress[quest_id]
	if progress.has(objective_id):
		return int(progress[objective_id])
	return 0


func get_objective_required_amount(quest_id: StringName, objective_id: StringName) -> int:
	var quest_data: QuestData = get_quest_data(quest_id)
	if quest_data == null:
		return 0
	var objective: QuestObjectiveData = quest_data.get_objective(objective_id)
	if objective == null:
		return 0
	return objective.required_amount


func get_active_quest_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for quest_id: StringName in _quest_states.keys():
		if _quest_states[quest_id] == QuestState.ACTIVE:
			ids.append(quest_id)
	return ids


# ---------------------------------------------------------------------------
# Progress mutation
# ---------------------------------------------------------------------------
func add_objective_progress(quest_id: StringName, objective_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not is_quest_registered(quest_id):
		return false
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return false

	var quest_data: QuestData = get_quest_data(quest_id)
	var objective: QuestObjectiveData = quest_data.get_objective(objective_id)
	if objective == null:
		return false

	var current: int = get_objective_progress(quest_id, objective_id)
	var new_value: int = clampi(current + amount, 0, objective.required_amount)
	if new_value == current:
		return false

	_set_progress_value(quest_id, objective_id, new_value)
	objective_progress_changed.emit(quest_id, objective_id, new_value, objective.required_amount)

	if get_quest_state(quest_id) == QuestState.ACTIVE and _are_all_objectives_complete(quest_id):
		_quest_states[quest_id] = QuestState.READY_TO_TURN_IN
		quest_ready_to_turn_in.emit(quest_id)
	return true


# NOTE: set_objective_progress shares add_objective_progress's *existence* checks
# (known quest, known/valid objective) but intentionally differs in two ways so
# it can support later inventory-delivery re-checks (Step 15 of the brief):
#   * It is allowed while state is ACTIVE or READY_TO_TURN_IN (so progress can be
#     reduced back out of readiness), whereas add_* requires ACTIVE.
#   * It accepts any amount and clamps to [0, required] (setting 0 is valid),
#     whereas add_* rejects amount <= 0.
func set_objective_progress(quest_id: StringName, objective_id: StringName, amount: int) -> bool:
	if not is_quest_registered(quest_id):
		return false

	var state: QuestState = get_quest_state(quest_id)
	if state != QuestState.ACTIVE and state != QuestState.READY_TO_TURN_IN:
		return false

	var quest_data: QuestData = get_quest_data(quest_id)
	var objective: QuestObjectiveData = quest_data.get_objective(objective_id)
	if objective == null:
		return false

	var current: int = get_objective_progress(quest_id, objective_id)
	var new_value: int = clampi(amount, 0, objective.required_amount)
	if new_value == current:
		return false

	_set_progress_value(quest_id, objective_id, new_value)
	objective_progress_changed.emit(quest_id, objective_id, new_value, objective.required_amount)

	# Recalculate readiness after setting progress.
	var all_complete: bool = _are_all_objectives_complete(quest_id)
	if state == QuestState.ACTIVE and all_complete:
		_quest_states[quest_id] = QuestState.READY_TO_TURN_IN
		quest_ready_to_turn_in.emit(quest_id)
	elif state == QuestState.READY_TO_TURN_IN and not all_complete:
		# Reduced below completion: fall back to ACTIVE without emitting ready/completed.
		_quest_states[quest_id] = QuestState.ACTIVE
	return true


# ---------------------------------------------------------------------------
# Generic gameplay event interface (later systems call this).
# ---------------------------------------------------------------------------
func report_event(objective_type: QuestObjectiveData.ObjectiveType, target_id: StringName, amount: int = 1) -> int:
	if String(target_id).strip_edges().is_empty():
		return 0
	if amount <= 0:
		return 0

	var changed_count: int = 0
	for quest_id: StringName in _registered_quests.keys():
		if get_quest_state(quest_id) != QuestState.ACTIVE:
			continue
		var quest_data: QuestData = _registered_quests[quest_id]
		if quest_data == null:
			continue
		for objective: QuestObjectiveData in quest_data.objectives:
			if objective == null or not objective.is_valid_objective():
				continue
			if objective.objective_type != objective_type:
				continue
			if objective.target_id != target_id:
				continue
			if add_objective_progress(quest_id, objective.objective_id, amount):
				changed_count += 1
	return changed_count


# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
func complete_quest(quest_id: StringName) -> bool:
	if not is_quest_registered(quest_id):
		return false
	if get_quest_state(quest_id) != QuestState.READY_TO_TURN_IN:
		return false
	if not _are_all_objectives_complete(quest_id):
		return false

	_quest_states[quest_id] = QuestState.COMPLETED
	quest_completed.emit(quest_id)
	return true


# ---------------------------------------------------------------------------
# Reset (runtime-only)
# ---------------------------------------------------------------------------
func reset_quest(quest_id: StringName) -> bool:
	if not is_quest_registered(quest_id):
		return false

	var old_state: QuestState = get_quest_state(quest_id)
	var had_progress: bool = _has_any_nonzero_progress(_get_progress_map(quest_id))

	_reset_progress(quest_id)
	_quest_states[quest_id] = QuestState.INACTIVE

	if old_state != QuestState.INACTIVE or had_progress:
		quest_reset.emit(quest_id)
	return true


func reset_all_runtime_quests() -> void:
	for quest_id: StringName in _registered_quests.keys():
		reset_quest(quest_id)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _build_progress_dictionary(quest_data: QuestData) -> Dictionary:
	var progress: Dictionary = {}
	if quest_data == null:
		return progress
	for objective: QuestObjectiveData in quest_data.objectives:
		if objective != null and objective.is_valid_objective():
			progress[objective.objective_id] = 0
	return progress


func _reset_progress(quest_id: StringName) -> void:
	var quest_data: QuestData = get_quest_data(quest_id)
	_quest_progress[quest_id] = _build_progress_dictionary(quest_data)


func _ensure_progress_entries(quest_id: StringName) -> void:
	var quest_data: QuestData = get_quest_data(quest_id)
	if quest_data == null:
		return
	var progress: Dictionary = _get_progress_map(quest_id)
	for objective: QuestObjectiveData in quest_data.objectives:
		if objective != null and objective.is_valid_objective():
			if not progress.has(objective.objective_id):
				progress[objective.objective_id] = 0
	_quest_progress[quest_id] = progress


func _get_progress_map(quest_id: StringName) -> Dictionary:
	if _quest_progress.has(quest_id):
		return _quest_progress[quest_id]
	return {}


func _set_progress_value(quest_id: StringName, objective_id: StringName, value: int) -> void:
	var progress: Dictionary = _get_progress_map(quest_id)
	progress[objective_id] = value
	_quest_progress[quest_id] = progress


func _are_all_objectives_complete(quest_id: StringName) -> bool:
	if not is_quest_registered(quest_id):
		return false
	var quest_data: QuestData = get_quest_data(quest_id)
	if quest_data == null or not quest_data.is_valid_quest():
		return false

	var valid_found: bool = false
	for objective: QuestObjectiveData in quest_data.objectives:
		if objective == null or not objective.is_valid_objective():
			continue
		valid_found = true
		if get_objective_progress(quest_id, objective.objective_id) < objective.required_amount:
			return false
	return valid_found


func _has_any_nonzero_progress(progress: Dictionary) -> bool:
	for key in progress.keys():
		if int(progress[key]) != 0:
			return true
	return false
