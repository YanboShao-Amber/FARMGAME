# GreenhouseManager autoload singleton.
# Registered in project.godot as autoload "GreenhouseManager"; therefore this
# script intentionally has NO `class_name` to avoid a naming conflict.
extends Node

signal greenhouse_registered(greenhouse_id: StringName)
signal greenhouse_state_changed(greenhouse_id: StringName, previous_state: int, current_state: int)
signal greenhouse_restored(greenhouse_id: StringName)
signal greenhouse_reset(greenhouse_id: StringName)

# greenhouse_id -> GreenhouseProfileData
var _profiles: Dictionary = {}
# greenhouse_id -> GreenhouseProfileData.GreenhouseState
var _greenhouse_states: Dictionary = {}


func register_profile(profile: GreenhouseProfileData) -> bool:
	if profile == null:
		return false
	if not profile.is_valid_profile():
		return false

	var greenhouse_id: StringName = profile.greenhouse_id
	if String(greenhouse_id).strip_edges().is_empty():
		return false

	if _profiles.has(greenhouse_id):
		var existing: GreenhouseProfileData = _profiles[greenhouse_id] as GreenhouseProfileData
		if existing == profile:
			return true
		push_warning("GreenhouseManager: greenhouse_id '%s' is already registered with a different greenhouse profile; registration rejected." % String(greenhouse_id))
		return false

	_profiles[greenhouse_id] = profile
	_greenhouse_states[greenhouse_id] = profile.initial_state
	greenhouse_registered.emit(greenhouse_id)
	return true


func unregister_profile(greenhouse_id: StringName) -> bool:
	if not is_profile_registered(greenhouse_id):
		return false
	_profiles.erase(greenhouse_id)
	_greenhouse_states.erase(greenhouse_id)
	return true


func is_profile_registered(greenhouse_id: StringName) -> bool:
	return _profiles.has(greenhouse_id)


func get_profile(greenhouse_id: StringName) -> GreenhouseProfileData:
	if _profiles.has(greenhouse_id):
		return _profiles[greenhouse_id] as GreenhouseProfileData
	return null


func get_state(greenhouse_id: StringName) -> int:
	if _greenhouse_states.has(greenhouse_id):
		return int(_greenhouse_states[greenhouse_id])
	return GreenhouseProfileData.GreenhouseState.ABANDONED


func get_state_name(greenhouse_id: StringName) -> String:
	var profile: GreenhouseProfileData = get_profile(greenhouse_id)
	if profile == null:
		return ""
	return profile.get_state_name(get_state(greenhouse_id))


func get_state_description(greenhouse_id: StringName) -> String:
	var profile: GreenhouseProfileData = get_profile(greenhouse_id)
	if profile == null:
		return ""
	return profile.get_state_description(get_state(greenhouse_id))


func is_state(greenhouse_id: StringName, state: int) -> bool:
	if not is_profile_registered(greenhouse_id):
		return false
	return get_state(greenhouse_id) == state


func is_abandoned(greenhouse_id: StringName) -> bool:
	return is_state(greenhouse_id, GreenhouseProfileData.GreenhouseState.ABANDONED)


func is_repairing(greenhouse_id: StringName) -> bool:
	return is_state(greenhouse_id, GreenhouseProfileData.GreenhouseState.REPAIRING)


func is_restored(greenhouse_id: StringName) -> bool:
	return is_state(greenhouse_id, GreenhouseProfileData.GreenhouseState.RESTORED)


func set_state(greenhouse_id: StringName, new_state: int, allow_regression: bool = false) -> bool:
	var profile: GreenhouseProfileData = get_profile(greenhouse_id)
	if profile == null:
		return false
	if not profile.is_valid_state(new_state):
		return false

	var previous_state: int = get_state(greenhouse_id)
	if previous_state == new_state:
		return false
	if new_state < previous_state and not allow_regression:
		push_warning("GreenhouseManager: greenhouse_id '%s' cannot regress from state %d to %d without allow_regression." % [String(greenhouse_id), previous_state, new_state])
		return false

	_greenhouse_states[greenhouse_id] = new_state
	greenhouse_state_changed.emit(greenhouse_id, previous_state, new_state)

	var final_state: int = profile.get_final_state()
	if previous_state < final_state and new_state == final_state:
		greenhouse_restored.emit(greenhouse_id)

	return true


func advance_state(greenhouse_id: StringName) -> bool:
	var current_state: int = get_state(greenhouse_id)
	match current_state:
		GreenhouseProfileData.GreenhouseState.ABANDONED:
			return set_state(greenhouse_id, GreenhouseProfileData.GreenhouseState.REPAIRING)
		GreenhouseProfileData.GreenhouseState.REPAIRING:
			return set_state(greenhouse_id, GreenhouseProfileData.GreenhouseState.RESTORED)
		_:
			return false


func reset_greenhouse(greenhouse_id: StringName) -> bool:
	var profile: GreenhouseProfileData = get_profile(greenhouse_id)
	if profile == null:
		return false

	var previous_state: int = get_state(greenhouse_id)
	var initial_state: int = profile.initial_state
	if previous_state == initial_state:
		return true

	_greenhouse_states[greenhouse_id] = initial_state
	greenhouse_state_changed.emit(greenhouse_id, previous_state, initial_state)
	greenhouse_reset.emit(greenhouse_id)
	return true


func reset_all_greenhouses() -> void:
	for greenhouse_id: StringName in _profiles.keys():
		reset_greenhouse(greenhouse_id)
