extends Resource
class_name RelationshipProfileData

@export_group("Identity")
@export var npc_id: StringName = &""

@export_group("Progression")
@export_range(1, 10, 1) var max_hearts: int = 5
@export_range(1, 10000, 1) var points_per_heart: int = 100
@export_range(0, 100000, 1) var starting_points: int = 0


func is_valid_profile() -> bool:
	if String(npc_id).strip_edges().is_empty():
		return false
	if max_hearts <= 0:
		return false
	if points_per_heart <= 0:
		return false
	if starting_points < 0:
		return false
	if starting_points > get_max_points():
		return false
	return true


func get_max_points() -> int:
	if max_hearts <= 0 or points_per_heart <= 0:
		return 0
	return max_hearts * points_per_heart


func clamp_points(points: int) -> int:
	return clampi(points, 0, get_max_points())


func get_heart_level(points: int) -> int:
	if max_hearts <= 0 or points_per_heart <= 0:
		return 0
	var clamped_points: int = clamp_points(points)
	if clamped_points >= get_max_points():
		return max_hearts
	return clampi(floori(float(clamped_points) / float(points_per_heart)), 0, max_hearts)


func get_points_in_current_heart(points: int) -> int:
	if max_hearts <= 0 or points_per_heart <= 0:
		return 0
	var clamped_points: int = clamp_points(points)
	if clamped_points >= get_max_points():
		return points_per_heart
	return clamped_points % points_per_heart


func get_points_to_next_heart(points: int) -> int:
	if max_hearts <= 0 or points_per_heart <= 0:
		return 0
	var clamped_points: int = clamp_points(points)
	if clamped_points >= get_max_points():
		return 0
	return points_per_heart - get_points_in_current_heart(clamped_points)


func get_heart_progress_ratio(points: int) -> float:
	if max_hearts <= 0 or points_per_heart <= 0:
		return 0.0
	if clamp_points(points) >= get_max_points():
		return 1.0
	return clampf(float(get_points_in_current_heart(points)) / float(points_per_heart), 0.0, 1.0)
