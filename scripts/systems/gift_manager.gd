# GiftManager autoload singleton.
# Registered in project.godot as autoload "GiftManager"; therefore this script
# intentionally has NO `class_name` to avoid a naming conflict.
extends Node

signal gift_profile_registered(npc_id: StringName)
signal gift_given(npc_id: StringName, item_id: StringName, reaction: int, relationship_points: int, day_id: int)
signal gift_limit_reached(npc_id: StringName, day_id: int)
signal gift_history_reset(npc_id: StringName)

# npc_id -> GiftPreferenceData
var _profiles: Dictionary = {}
# npc_id -> integer day ID of last successful gift
var _last_gift_day: Dictionary = {}


func register_profile(profile: GiftPreferenceData) -> bool:
	if profile == null:
		return false
	if not profile.is_valid_profile():
		return false

	var npc_id: StringName = profile.npc_id
	if String(npc_id).strip_edges().is_empty():
		return false

	if _profiles.has(npc_id):
		var existing: GiftPreferenceData = _profiles[npc_id] as GiftPreferenceData
		if existing == profile:
			return true
		push_warning("GiftManager: npc_id '%s' is already registered with a different gift profile; registration rejected." % String(npc_id))
		return false

	_profiles[npc_id] = profile
	gift_profile_registered.emit(npc_id)
	return true


func is_profile_registered(npc_id: StringName) -> bool:
	return _profiles.has(npc_id)


func get_profile(npc_id: StringName) -> GiftPreferenceData:
	if _profiles.has(npc_id):
		return _profiles[npc_id] as GiftPreferenceData
	return null


func is_known_gift(npc_id: StringName, item_id: StringName) -> bool:
	var profile: GiftPreferenceData = get_profile(npc_id)
	if profile == null:
		return false
	return profile.has_item(item_id)


func get_reaction(npc_id: StringName, item_id: StringName) -> int:
	var profile: GiftPreferenceData = get_profile(npc_id)
	if profile == null:
		return -1
	return profile.get_reaction(item_id)


func get_relationship_points(npc_id: StringName, item_id: StringName) -> int:
	var profile: GiftPreferenceData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.get_points_for_item(item_id)


func has_given_gift_on_day(npc_id: StringName, day_id: int) -> bool:
	if not _is_valid_day_id(day_id):
		return false
	if not _last_gift_day.has(npc_id):
		return false
	return int(_last_gift_day[npc_id]) == day_id


func can_give_gift_on_day(npc_id: StringName, day_id: int) -> bool:
	if not is_profile_registered(npc_id):
		return false
	if not _is_valid_day_id(day_id):
		return false
	return not has_given_gift_on_day(npc_id, day_id)


func get_last_gift_day(npc_id: StringName) -> int:
	if _last_gift_day.has(npc_id):
		return int(_last_gift_day[npc_id])
	return -1


func report_gift_limit_attempt(npc_id: StringName, day_id: int) -> bool:
	if not is_profile_registered(npc_id):
		return false
	if not _is_valid_day_id(day_id):
		return false
	if not has_given_gift_on_day(npc_id, day_id):
		return false
	gift_limit_reached.emit(npc_id, day_id)
	return true


func record_successful_gift(npc_id: StringName, item_id: StringName, day_id: int) -> bool:
	var profile: GiftPreferenceData = get_profile(npc_id)
	if profile == null:
		return false
	if String(item_id).strip_edges().is_empty():
		return false
	if not profile.has_item(item_id):
		return false
	if not _is_valid_day_id(day_id):
		return false
	if has_given_gift_on_day(npc_id, day_id):
		gift_limit_reached.emit(npc_id, day_id)
		return false

	var reaction: int = profile.get_reaction(item_id)
	var relationship_points: int = profile.get_points_for_reaction(reaction)
	_last_gift_day[npc_id] = day_id
	gift_given.emit(npc_id, item_id, reaction, relationship_points, day_id)
	return true


func reset_gift_history(npc_id: StringName) -> bool:
	if not is_profile_registered(npc_id):
		return false
	if not _last_gift_day.has(npc_id):
		return true
	_last_gift_day.erase(npc_id)
	gift_history_reset.emit(npc_id)
	return true


func reset_all_gift_history() -> void:
	for npc_id: StringName in _profiles.keys():
		reset_gift_history(npc_id)


func _is_valid_day_id(day_id: int) -> bool:
	return day_id >= 1
