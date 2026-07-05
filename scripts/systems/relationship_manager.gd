# RelationshipManager autoload singleton.
# Registered in project.godot as autoload "RelationshipManager"; therefore this
# script intentionally has NO `class_name` to avoid a naming conflict.
extends Node

signal relationship_registered(npc_id: StringName)
signal relationship_points_changed(npc_id: StringName, previous_points: int, current_points: int, delta: int)
signal relationship_heart_changed(npc_id: StringName, previous_hearts: int, current_hearts: int)
signal relationship_maxed(npc_id: StringName)
signal relationship_reset(npc_id: StringName)

# npc_id -> RelationshipProfileData
var _profiles: Dictionary = {}
# npc_id -> current relationship points
var _relationship_points: Dictionary = {}


func register_profile(profile: RelationshipProfileData) -> bool:
	if profile == null:
		return false
	if not profile.is_valid_profile():
		return false

	var npc_id: StringName = profile.npc_id
	if String(npc_id).strip_edges().is_empty():
		return false

	if _profiles.has(npc_id):
		var existing: RelationshipProfileData = _profiles[npc_id] as RelationshipProfileData
		if existing == profile:
			return true
		push_warning("RelationshipManager: npc_id '%s' is already registered with a different relationship profile; registration rejected." % String(npc_id))
		return false

	_profiles[npc_id] = profile
	_relationship_points[npc_id] = profile.clamp_points(profile.starting_points)
	relationship_registered.emit(npc_id)
	return true


func unregister_profile(npc_id: StringName) -> bool:
	if not is_profile_registered(npc_id):
		return false
	_profiles.erase(npc_id)
	_relationship_points.erase(npc_id)
	return true


func is_profile_registered(npc_id: StringName) -> bool:
	return _profiles.has(npc_id)


func get_profile(npc_id: StringName) -> RelationshipProfileData:
	if _profiles.has(npc_id):
		return _profiles[npc_id] as RelationshipProfileData
	return null


func get_points(npc_id: StringName) -> int:
	if _relationship_points.has(npc_id):
		return int(_relationship_points[npc_id])
	return 0


func get_max_points(npc_id: StringName) -> int:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.get_max_points()


func get_heart_level(npc_id: StringName) -> int:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.get_heart_level(get_points(npc_id))


func get_max_hearts(npc_id: StringName) -> int:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.max_hearts


func get_points_in_current_heart(npc_id: StringName) -> int:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.get_points_in_current_heart(get_points(npc_id))


func get_points_to_next_heart(npc_id: StringName) -> int:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0
	return profile.get_points_to_next_heart(get_points(npc_id))


func get_heart_progress_ratio(npc_id: StringName) -> float:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return 0.0
	return profile.get_heart_progress_ratio(get_points(npc_id))


func is_relationship_maxed(npc_id: StringName) -> bool:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return false
	return get_points(npc_id) >= profile.get_max_points()


func set_points(npc_id: StringName, points: int) -> bool:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return false

	var previous_points: int = get_points(npc_id)
	var current_points: int = profile.clamp_points(points)
	if current_points == previous_points:
		return false

	var previous_hearts: int = profile.get_heart_level(previous_points)
	_relationship_points[npc_id] = current_points
	var current_hearts: int = profile.get_heart_level(current_points)

	relationship_points_changed.emit(npc_id, previous_points, current_points, current_points - previous_points)

	if current_hearts != previous_hearts:
		relationship_heart_changed.emit(npc_id, previous_hearts, current_hearts)

	if previous_points < profile.get_max_points() and current_points >= profile.get_max_points():
		relationship_maxed.emit(npc_id)

	return true


func add_points(npc_id: StringName, amount: int) -> bool:
	if amount == 0:
		return false
	if not is_profile_registered(npc_id):
		return false
	return set_points(npc_id, get_points(npc_id) + amount)


func reset_relationship(npc_id: StringName) -> bool:
	var profile: RelationshipProfileData = get_profile(npc_id)
	if profile == null:
		return false

	var changed: bool = set_points(npc_id, profile.starting_points)
	if changed:
		relationship_reset.emit(npc_id)
	return true


func reset_all_relationships() -> void:
	for npc_id: StringName in _profiles.keys():
		reset_relationship(npc_id)
