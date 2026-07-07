extends Resource
class_name NPCData

@export_group("Identity")
@export var npc_id: StringName = &""
@export var display_name_cn: String = ""
@export var display_name_en: String = ""
@export var occupation_cn: String = ""
@export var occupation_en: String = ""
@export_multiline var short_description_cn: String = ""
@export_multiline var short_description_en: String = ""

@export_group("Portraits")
@export var portrait_neutral: Texture2D
@export var portrait_happy: Texture2D
@export var portrait_worried: Texture2D
@export var portrait_surprised: Texture2D

@export_group("Dialogue")
@export var dialogue_sequences: Array[DialogueSequenceData] = []

@export_group("Relationship Dialogue")
@export var relationship_dialogue_tiers: Array[RelationshipDialogueTierData] = []

@export_group("Quests")
@export var quests: Array[QuestData] = []

@export_group("Relationship")
@export var relationship_profile: RelationshipProfileData

@export_group("Gifting")
@export var gift_preferences: GiftPreferenceData

@export_group("Associated Greenhouse")
@export var greenhouse_profile: GreenhouseProfileData


func get_display_name() -> String:
	# Player-facing name is Simplified Chinese only (no mixed CN/EN).
	# display_name_en is kept as internal metadata but never shown in-game.
	var cn_name: String = display_name_cn.strip_edges()
	if not cn_name.is_empty():
		return cn_name
	var en_name: String = display_name_en.strip_edges()
	if not en_name.is_empty():
		return en_name
	return String(npc_id)


func get_portrait(expression_id: StringName) -> Texture2D:
	var normalized_expression: String = String(expression_id).to_lower()

	match normalized_expression:
		"happy":
			return portrait_happy if portrait_happy != null else portrait_neutral
		"worried":
			return portrait_worried if portrait_worried != null else portrait_neutral
		"surprised":
			return portrait_surprised if portrait_surprised != null else portrait_neutral
		_:
			return portrait_neutral


func get_dialogue_sequence(sequence_id: StringName) -> DialogueSequenceData:
	if String(sequence_id).strip_edges().is_empty():
		return null

	for sequence: DialogueSequenceData in dialogue_sequences:
		if sequence != null and sequence.sequence_id == sequence_id and sequence.is_valid_sequence():
			return sequence
	return null


func has_dialogue_sequence(sequence_id: StringName) -> bool:
	return get_dialogue_sequence(sequence_id) != null


func get_first_valid_dialogue_sequence() -> DialogueSequenceData:
	for sequence: DialogueSequenceData in dialogue_sequences:
		if sequence != null and sequence.is_valid_sequence():
			return sequence
	return null


func get_relationship_dialogue_tier(heart_level: int) -> RelationshipDialogueTierData:
	var normalized_heart_level: int = maxi(heart_level, 0)
	var selected_tier: RelationshipDialogueTierData = null

	for tier: RelationshipDialogueTierData in relationship_dialogue_tiers:
		if tier == null or not tier.is_valid_tier():
			continue
		if tier.minimum_hearts > normalized_heart_level:
			continue
		if selected_tier == null or tier.minimum_hearts > selected_tier.minimum_hearts:
			selected_tier = tier

	return selected_tier


func get_relationship_dialogue_sequence(heart_level: int) -> DialogueSequenceData:
	var tier: RelationshipDialogueTierData = get_relationship_dialogue_tier(heart_level)
	if tier == null:
		return null
	return get_dialogue_sequence(tier.sequence_id)


func get_quest(quest_id: StringName) -> QuestData:
	if String(quest_id).strip_edges().is_empty():
		return null

	for quest: QuestData in quests:
		if quest != null and quest.is_valid_quest() and quest.quest_id == quest_id:
			return quest
	return null


func has_quest(quest_id: StringName) -> bool:
	return get_quest(quest_id) != null


func has_relationship_profile() -> bool:
	if relationship_profile == null:
		return false
	return relationship_profile.is_valid_profile()


func get_relationship_profile() -> RelationshipProfileData:
	if has_relationship_profile():
		return relationship_profile
	return null


func has_gift_preferences() -> bool:
	if gift_preferences == null:
		return false
	return gift_preferences.is_valid_profile()


func get_gift_preferences() -> GiftPreferenceData:
	if has_gift_preferences():
		return gift_preferences
	return null


func has_greenhouse_profile() -> bool:
	if greenhouse_profile == null:
		return false
	return greenhouse_profile.is_valid_profile()


func get_greenhouse_profile() -> GreenhouseProfileData:
	if has_greenhouse_profile():
		return greenhouse_profile
	return null
