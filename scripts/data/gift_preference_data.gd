extends Resource
class_name GiftPreferenceData

enum GiftReaction {
	LOVED,
	LIKED,
	NEUTRAL,
	DISLIKED,
}

@export_group("Identity")
@export var npc_id: StringName = &""

@export_group("Item Preferences")
@export var loved_item_ids: Array[StringName] = []
@export var liked_item_ids: Array[StringName] = []
@export var neutral_item_ids: Array[StringName] = []
@export var disliked_item_ids: Array[StringName] = []

@export_group("Relationship Points")
@export var loved_points: int = 80
@export var liked_points: int = 40
@export var neutral_points: int = 10
@export var disliked_points: int = -20


func is_valid_profile() -> bool:
	if String(npc_id).strip_edges().is_empty():
		return false
	if loved_item_ids.is_empty() and liked_item_ids.is_empty() and neutral_item_ids.is_empty() and disliked_item_ids.is_empty():
		return false

	var seen_item_ids: Dictionary = {}
	for item_id: StringName in _get_all_item_ids():
		if String(item_id).strip_edges().is_empty():
			return false
		if seen_item_ids.has(item_id):
			return false
		seen_item_ids[item_id] = true

	return true


func has_item(item_id: StringName) -> bool:
	if String(item_id).strip_edges().is_empty():
		return false
	return get_reaction(item_id) != -1


func get_reaction(item_id: StringName) -> int:
	if String(item_id).strip_edges().is_empty():
		return -1
	if loved_item_ids.has(item_id):
		return GiftReaction.LOVED
	if liked_item_ids.has(item_id):
		return GiftReaction.LIKED
	if neutral_item_ids.has(item_id):
		return GiftReaction.NEUTRAL
	if disliked_item_ids.has(item_id):
		return GiftReaction.DISLIKED
	return -1


func get_points_for_reaction(reaction: int) -> int:
	match reaction:
		GiftReaction.LOVED:
			return loved_points
		GiftReaction.LIKED:
			return liked_points
		GiftReaction.NEUTRAL:
			return neutral_points
		GiftReaction.DISLIKED:
			return disliked_points
		_:
			return 0


func get_points_for_item(item_id: StringName) -> int:
	var reaction: int = get_reaction(item_id)
	if reaction == -1:
		return 0
	return get_points_for_reaction(reaction)


func _get_all_item_ids() -> Array[StringName]:
	var item_ids: Array[StringName] = []
	item_ids.append_array(loved_item_ids)
	item_ids.append_array(liked_item_ids)
	item_ids.append_array(neutral_item_ids)
	item_ids.append_array(disliked_item_ids)
	return item_ids
