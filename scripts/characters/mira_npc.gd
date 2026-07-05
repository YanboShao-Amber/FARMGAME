extends CharacterBody2D

const FIRST_MEETING_SEQUENCE_ID: StringName = &"first_meeting"
const REPEAT_BEFORE_QUEST_SEQUENCE_ID: StringName = &"repeat_before_quest"
const MIRA_FIRST_QUEST_ID: StringName = &"mira_still_sprouts"
const QUEST_OFFER_SEQUENCE_ID: StringName = &"quest_offer_still_sprouts"
const QUEST_ACTIVE_SEQUENCE_ID: StringName = &"quest_active_still_sprouts"
const QUEST_READY_SEQUENCE_ID: StringName = &"quest_ready_still_sprouts"
const QUEST_COMPLETED_SEQUENCE_ID: StringName = &"quest_completed_still_sprouts"
const GIFT_LOVED_SEQUENCE_ID: StringName = &"gift_loved"
const GIFT_LIKED_SEQUENCE_ID: StringName = &"gift_liked"
const GIFT_NEUTRAL_SEQUENCE_ID: StringName = &"gift_neutral"
const GIFT_DISLIKED_SEQUENCE_ID: StringName = &"gift_disliked"
const GIFT_ALREADY_TODAY_SEQUENCE_ID: StringName = &"gift_already_today"

@export var npc_data: NPCData

var has_met_player: bool = false
var active_dialogue_sequence: DialogueSequenceData = null
var _dialogue_completed_naturally: bool = false
var _missing_day_warning_pushed: bool = false
var facing_direction: Vector2 = Vector2.DOWN
# dialogue_index is the currently displayed dialogue line; it resets to 0 outside a session.
var dialogue_index: int = 0
var current_dialogue_player: Node2D = null
var is_finishing_dialogue: bool = false

var can_interact: bool = false:
	set(value):
		can_interact = value
		if not is_node_ready():
			return
		if can_interact:
			_update_interaction_state()
		else:
			_dialogue_completed_naturally = false
			_finish_dialogue()

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var hand_overlay: AnimatedSprite2D = $HandOverlay
@onready var character_dialog: CharacterDialog = $CharacterDialog
@onready var status_indicator: NPCStatusIndicator = get_node_or_null("NPCStatusIndicator") as NPCStatusIndicator


func _ready() -> void:
	if not _has_valid_npc_data():
		push_warning("MiraNPC has missing or invalid NPCData; dialogue will not open.")
	else:
		_register_first_quest()
		_register_relationship_profile()
		_register_gift_preferences()
		_register_greenhouse_profile()
	if animated_sprite != null and not animated_sprite.frame_changed.is_connected(_sync_hand_overlay):
		animated_sprite.frame_changed.connect(_sync_hand_overlay)
	if character_dialog != null and not character_dialog.dialogue_closed.is_connected(_on_character_dialog_dialogue_closed):
		character_dialog.dialogue_closed.connect(_on_character_dialog_dialogue_closed)
	_connect_quest_manager_signals()
	play_idle(facing_direction)
	can_interact = false
	_refresh_quest_marker()


func _exit_tree() -> void:
	_dialogue_completed_naturally = false
	active_dialogue_sequence = null
	if status_indicator != null:
		status_indicator.hide_all()
	var player: Node2D = current_dialogue_player
	current_dialogue_player = null
	if is_instance_valid(player) and player.has_method("end_dialogue_lock"):
		player.end_dialogue_lock(self)


func set_facing_direction(direction: Vector2) -> void:
	facing_direction = _to_cardinal_direction(direction)


func play_idle(direction: Vector2 = facing_direction) -> void:
	set_facing_direction(direction)
	_play_animation(StringName("idle_%s" % _direction_suffix(facing_direction)))


func play_walk(direction: Vector2 = facing_direction) -> void:
	set_facing_direction(direction)
	_play_animation(StringName("walk_%s" % _direction_suffix(facing_direction)))


func interact(player: Node2D) -> void:
	if not can_interact:
		return

	if character_dialog == null:
		_finish_dialogue()
		return

	if character_dialog.is_dialogue_open() and character_dialog.is_revealing_text():
		character_dialog.reveal_all_text()
		return

	var facing_player: Node2D = player if is_instance_valid(player) else current_dialogue_player
	if is_instance_valid(facing_player):
		play_idle(facing_player.global_position - global_position)

	if character_dialog.is_dialogue_open():
		_advance_dialogue()
		return

	if not is_instance_valid(player):
		return

	if _can_gifting_override_dialogue() and _try_give_selected_item(player):
		return

	_start_dialogue(player)


func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return facing_direction

	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT

	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)
	_sync_hand_overlay()


func _sync_hand_overlay() -> void:
	if animated_sprite == null or hand_overlay == null:
		return

	var animation_name: StringName = animated_sprite.animation
	var hand_frames: SpriteFrames = hand_overlay.sprite_frames

	if hand_frames == null or not hand_frames.has_animation(animation_name):
		hand_overlay.hide()
		return

	var frame_count: int = hand_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		hand_overlay.hide()
		return

	hand_overlay.show()
	if hand_overlay.animation != animation_name:
		hand_overlay.animation = animation_name
	hand_overlay.frame = clampi(animated_sprite.frame, 0, frame_count - 1)


func _start_dialogue(player: Node2D) -> void:
	if character_dialog == null:
		_finish_dialogue()
		return

	if not _has_valid_npc_data():
		push_warning("MiraNPC cannot start dialogue because NPCData is missing or invalid.")
		return

	var selected_sequence: DialogueSequenceData = _select_dialogue_sequence()
	if selected_sequence == null:
		push_warning("MiraNPC cannot start dialogue because no valid dialogue sequence was found.")
		return

	_start_dialogue_sequence(player, selected_sequence)


func _start_dialogue_sequence(player: Node2D, selected_sequence: DialogueSequenceData) -> void:
	if character_dialog == null:
		_finish_dialogue()
		return

	if not _has_valid_npc_data():
		push_warning("MiraNPC cannot start dialogue because NPCData is missing or invalid.")
		return

	if selected_sequence == null:
		push_warning("MiraNPC cannot start dialogue because no valid dialogue sequence was found.")
		return

	var line: DialogueLineData = selected_sequence.get_line(0)
	if line == null or not line.is_valid_line():
		active_dialogue_sequence = null
		push_warning("MiraNPC cannot start dialogue because the first dialogue line is invalid.")
		return

	active_dialogue_sequence = selected_sequence
	_dialogue_completed_naturally = false
	current_dialogue_player = player
	play_idle(player.global_position - global_position)
	if player.has_method("begin_dialogue_lock"):
		player.begin_dialogue_lock(self)

	dialogue_index = 0
	if status_indicator != null:
		status_indicator.hide_all()

	character_dialog.show_line(
		npc_data.get_display_name(),
		line.text,
		npc_data.get_portrait(line.expression_id)
	)
	_update_interaction_state()


func _advance_dialogue() -> void:
	if character_dialog == null:
		_dialogue_completed_naturally = false
		_finish_dialogue()
		return

	var dialogue_count: int = _get_dialogue_count()
	if dialogue_index < 0 or dialogue_index >= dialogue_count:
		_dialogue_completed_naturally = false
		_finish_dialogue()
		return

	var next_dialogue_index: int = dialogue_index + 1
	if next_dialogue_index >= dialogue_count:
		_dialogue_completed_naturally = true
		_finish_dialogue()
		return

	var line: DialogueLineData = _get_dialogue_line(next_dialogue_index)
	if line == null or not line.is_valid_line():
		_dialogue_completed_naturally = false
		_finish_dialogue()
		return

	dialogue_index = next_dialogue_index
	character_dialog.update_line(line.text, npc_data.get_portrait(line.expression_id))
	_update_interaction_state()


func _finish_dialogue() -> void:
	if is_finishing_dialogue:
		return

	is_finishing_dialogue = true
	var completed_sequence_id: StringName = &""
	if active_dialogue_sequence != null:
		completed_sequence_id = active_dialogue_sequence.sequence_id
	var completed_naturally: bool = _dialogue_completed_naturally
	var player: Node2D = current_dialogue_player

	if completed_naturally:
		_apply_natural_completion_actions(completed_sequence_id)

	if character_dialog != null:
		character_dialog.close_dialogue()

	if is_instance_valid(player) and player.has_method("end_dialogue_lock"):
		player.end_dialogue_lock(self)

	dialogue_index = 0
	active_dialogue_sequence = null
	_dialogue_completed_naturally = false
	current_dialogue_player = null
	is_finishing_dialogue = false
	_update_interaction_state()


func _update_interaction_state() -> void:
	if not is_node_ready():
		return

	_refresh_quest_marker()


func _on_character_dialog_dialogue_closed() -> void:
	_finish_dialogue()


func _connect_quest_manager_signals() -> void:
	_connect_quest_signal(&"quest_registered", _on_quest_registered)
	_connect_quest_signal(&"quest_started", _on_quest_started)
	_connect_quest_signal(&"objective_progress_changed", _on_objective_progress_changed)
	_connect_quest_signal(&"quest_ready_to_turn_in", _on_quest_ready_to_turn_in)
	_connect_quest_signal(&"quest_completed", _on_quest_completed)
	_connect_quest_signal(&"quest_reset", _on_quest_reset)


func _connect_quest_signal(signal_name: StringName, handler: Callable) -> void:
	if not QuestManager.has_signal(signal_name):
		return
	if not QuestManager.is_connected(signal_name, handler):
		QuestManager.connect(signal_name, handler)


func _on_quest_registered(quest_id: StringName) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _on_quest_started(quest_id: StringName) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _on_objective_progress_changed(quest_id: StringName, _objective_id: StringName, _current_amount: int, _required_amount: int) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _on_quest_ready_to_turn_in(quest_id: StringName) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _on_quest_completed(quest_id: StringName) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _on_quest_reset(quest_id: StringName) -> void:
	if quest_id != MIRA_FIRST_QUEST_ID:
		return
	_refresh_quest_marker()


func _refresh_quest_marker() -> void:
	if status_indicator == null:
		return

	var dialogue_is_open: bool = character_dialog != null and character_dialog.is_dialogue_open()
	if dialogue_is_open:
		status_indicator.hide_all()
		return

	if not has_met_player:
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.NONE)
	elif QuestManager.is_quest_completed(MIRA_FIRST_QUEST_ID):
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.NONE)
	elif QuestManager.is_quest_ready_to_turn_in(MIRA_FIRST_QUEST_ID):
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.READY)
	elif QuestManager.is_quest_active(MIRA_FIRST_QUEST_ID):
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.ACTIVE)
	elif QuestManager.is_quest_registered(MIRA_FIRST_QUEST_ID):
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.AVAILABLE)
	else:
		status_indicator.set_quest_state(NPCStatusIndicator.QuestMarkerState.NONE)

	status_indicator.hide_interaction_prompt()


func _has_valid_npc_data() -> bool:
	if npc_data == null:
		return false
	if String(npc_data.npc_id).strip_edges().is_empty():
		return false
	if npc_data.get_first_valid_dialogue_sequence() == null:
		return false
	return true


func _select_dialogue_sequence() -> DialogueSequenceData:
	if npc_data == null:
		return null

	if not has_met_player:
		return _get_dialogue_sequence_with_fallback(FIRST_MEETING_SEQUENCE_ID)

	if _get_first_quest() == null:
		return _get_dialogue_sequence_with_fallback(REPEAT_BEFORE_QUEST_SEQUENCE_ID)

	if QuestManager.is_quest_completed(MIRA_FIRST_QUEST_ID):
		var heart_level: int = _get_current_relationship_heart_level()
		var relationship_sequence: DialogueSequenceData = npc_data.get_relationship_dialogue_sequence(heart_level)
		if relationship_sequence != null:
			return relationship_sequence
		return _get_dialogue_sequence_with_fallback(QUEST_COMPLETED_SEQUENCE_ID)

	if QuestManager.is_quest_ready_to_turn_in(MIRA_FIRST_QUEST_ID):
		return _get_dialogue_sequence_with_fallback(QUEST_READY_SEQUENCE_ID)

	if QuestManager.is_quest_active(MIRA_FIRST_QUEST_ID):
		return _get_dialogue_sequence_with_fallback(QUEST_ACTIVE_SEQUENCE_ID)

	return _get_dialogue_sequence_with_fallback(QUEST_OFFER_SEQUENCE_ID)


func _get_current_relationship_heart_level() -> int:
	if npc_data == null:
		return 0

	var npc_id: StringName = npc_data.npc_id
	if String(npc_id).strip_edges().is_empty():
		return 0

	var relationship_manager: Node = get_node_or_null("/root/RelationshipManager")
	if relationship_manager == null:
		return 0
	if not relationship_manager.has_method("is_profile_registered"):
		return 0
	if not bool(relationship_manager.call("is_profile_registered", npc_id)):
		return 0
	if not relationship_manager.has_method("get_heart_level"):
		return 0

	return int(relationship_manager.call("get_heart_level", npc_id))


func _get_dialogue_sequence_with_fallback(sequence_id: StringName) -> DialogueSequenceData:
	if npc_data == null:
		return null

	var requested_sequence: DialogueSequenceData = npc_data.get_dialogue_sequence(sequence_id)
	if requested_sequence != null:
		return requested_sequence

	var repeat_sequence: DialogueSequenceData = npc_data.get_dialogue_sequence(REPEAT_BEFORE_QUEST_SEQUENCE_ID)
	if repeat_sequence != null:
		return repeat_sequence

	var first_meeting_sequence: DialogueSequenceData = npc_data.get_dialogue_sequence(FIRST_MEETING_SEQUENCE_ID)
	if first_meeting_sequence != null:
		return first_meeting_sequence

	return npc_data.get_first_valid_dialogue_sequence()


func _register_first_quest() -> void:
	var quest_data: QuestData = _get_first_quest()
	if quest_data == null:
		push_warning("MiraNPC could not register quest '%s' because NPCData has no valid quest resource." % String(MIRA_FIRST_QUEST_ID))
		return

	if not QuestManager.register_quest(quest_data):
		push_warning("MiraNPC failed to register quest '%s'." % String(MIRA_FIRST_QUEST_ID))


func _register_relationship_profile() -> void:
	var relationship_profile: RelationshipProfileData = npc_data.get_relationship_profile()
	if relationship_profile == null:
		push_warning("MiraNPC could not register relationship because NPCData has no valid relationship profile for npc_id '%s'." % String(npc_data.npc_id))
		return

	if not RelationshipManager.register_profile(relationship_profile):
		push_warning("MiraNPC failed to register relationship profile for npc_id '%s'." % String(relationship_profile.npc_id))


func _register_gift_preferences() -> void:
	var gift_preferences: GiftPreferenceData = npc_data.get_gift_preferences()
	if gift_preferences == null:
		push_warning("MiraNPC could not register gifts because NPCData has no valid gift preferences for npc_id '%s'." % String(npc_data.npc_id))
		return

	if not GiftManager.register_profile(gift_preferences):
		push_warning("MiraNPC failed to register gift preferences for npc_id '%s'." % String(gift_preferences.npc_id))


func _register_greenhouse_profile() -> void:
	var greenhouse_profile: GreenhouseProfileData = npc_data.get_greenhouse_profile()
	if greenhouse_profile == null:
		push_warning("MiraNPC could not register greenhouse because NPCData has no valid greenhouse profile for npc_id '%s'." % String(npc_data.npc_id))
		return

	var greenhouse_manager: Node = get_node_or_null("/root/GreenhouseManager")
	if greenhouse_manager == null:
		push_warning("MiraNPC could not register greenhouse '%s' because GreenhouseManager is unavailable." % String(greenhouse_profile.greenhouse_id))
		return
	if not greenhouse_manager.has_method("register_profile"):
		push_warning("MiraNPC could not register greenhouse '%s' because GreenhouseManager has no register_profile method." % String(greenhouse_profile.greenhouse_id))
		return
	if not bool(greenhouse_manager.call("register_profile", greenhouse_profile)):
		push_warning("MiraNPC failed to register greenhouse profile for greenhouse_id '%s'." % String(greenhouse_profile.greenhouse_id))


func _get_first_quest() -> QuestData:
	if npc_data == null:
		return null
	return npc_data.get_quest(MIRA_FIRST_QUEST_ID)


func _apply_natural_completion_actions(completed_sequence_id: StringName) -> void:
	if completed_sequence_id == FIRST_MEETING_SEQUENCE_ID:
		has_met_player = true
	elif completed_sequence_id == QUEST_OFFER_SEQUENCE_ID:
		_start_first_quest_after_offer()
	elif completed_sequence_id == QUEST_READY_SEQUENCE_ID:
		_complete_first_quest_after_ready_dialogue()


func _start_first_quest_after_offer() -> void:
	var quest_data: QuestData = _get_first_quest()
	if quest_data == null:
		push_warning("MiraNPC cannot start quest '%s' because the quest resource is missing or invalid." % String(MIRA_FIRST_QUEST_ID))
		return

	if not QuestManager.start_quest(quest_data):
		push_warning("MiraNPC failed to start quest '%s'." % String(MIRA_FIRST_QUEST_ID))


func _complete_first_quest_after_ready_dialogue() -> void:
	if not QuestManager.is_quest_ready_to_turn_in(MIRA_FIRST_QUEST_ID):
		push_warning("MiraNPC cannot complete quest '%s' because it is no longer ready to turn in." % String(MIRA_FIRST_QUEST_ID))
		return

	var quest_data: QuestData = _get_first_quest()
	if quest_data == null:
		push_warning("MiraNPC cannot grant quest reward because quest '%s' is missing or invalid." % String(MIRA_FIRST_QUEST_ID))
		return

	var completed: bool = QuestManager.complete_quest(MIRA_FIRST_QUEST_ID)
	if not completed:
		push_warning("MiraNPC failed to complete quest '%s'." % String(MIRA_FIRST_QUEST_ID))
		return

	_grant_quest_rewards(quest_data)


func _grant_quest_rewards(quest_data: QuestData) -> void:
	if quest_data == null:
		return

	if quest_data.reward_coins > 0 and not Data.add_coins(quest_data.reward_coins):
		push_warning("MiraNPC could not grant %d coins for quest '%s'." % [quest_data.reward_coins, String(quest_data.quest_id)])


func _can_gifting_override_dialogue() -> bool:
	if not has_met_player:
		return false
	if QuestManager.is_quest_ready_to_turn_in(MIRA_FIRST_QUEST_ID):
		return false
	return QuestManager.is_quest_active(MIRA_FIRST_QUEST_ID) or QuestManager.is_quest_completed(MIRA_FIRST_QUEST_ID)


func _try_give_selected_item(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	if npc_data == null:
		return false
	if not npc_data.has_relationship_profile() or not npc_data.has_gift_preferences():
		return false

	var npc_id: StringName = npc_data.npc_id
	if not RelationshipManager.is_profile_registered(npc_id):
		return false
	if not GiftManager.is_profile_registered(npc_id):
		return false

	var item_id: StringName = _get_selected_gift_item_id(player)
	if String(item_id).strip_edges().is_empty():
		return false
	if not GiftManager.is_known_gift(npc_id, item_id):
		return false

	var day_id: int = _get_current_game_day_id()
	if day_id < 1:
		if not _missing_day_warning_pushed:
			push_warning("MiraNPC cannot process gifts because no valid game day ID is available.")
			_missing_day_warning_pushed = true
		return false

	if not GiftManager.can_give_gift_on_day(npc_id, day_id):
		GiftManager.report_gift_limit_attempt(npc_id, day_id)
		_start_gift_response_dialogue(player, GIFT_ALREADY_TODAY_SEQUENCE_ID)
		return true

	if _get_selected_gift_item_amount(player) < 1:
		return false

	var reaction: int = GiftManager.get_reaction(npc_id, item_id)
	var relationship_points: int = GiftManager.get_relationship_points(npc_id, item_id)
	if reaction == -1:
		return false

	if not _consume_selected_gift_item(player, item_id, 1):
		push_warning("MiraNPC could not consume selected gift item '%s'." % String(item_id))
		return true

	if not GiftManager.record_successful_gift(npc_id, item_id, day_id):
		push_error("MiraNPC consumed gift item '%s' but GiftManager refused to record the gift." % String(item_id))
		return true

	RelationshipManager.add_points(npc_id, relationship_points)
	_start_gift_response_dialogue(player, _get_gift_response_sequence_id(reaction))
	return true


func _start_gift_response_dialogue(player: Node, sequence_id: StringName) -> void:
	if not is_instance_valid(player) or String(sequence_id).strip_edges().is_empty():
		return
	var selected_sequence: DialogueSequenceData = npc_data.get_dialogue_sequence(sequence_id)
	if selected_sequence == null:
		push_warning("MiraNPC could not find gift response dialogue '%s'." % String(sequence_id))
		return
	_start_dialogue_sequence(player as Node2D, selected_sequence)


func _get_gift_response_sequence_id(reaction: int) -> StringName:
	match reaction:
		GiftPreferenceData.GiftReaction.LOVED:
			return GIFT_LOVED_SEQUENCE_ID
		GiftPreferenceData.GiftReaction.LIKED:
			return GIFT_LIKED_SEQUENCE_ID
		GiftPreferenceData.GiftReaction.NEUTRAL:
			return GIFT_NEUTRAL_SEQUENCE_ID
		GiftPreferenceData.GiftReaction.DISLIKED:
			return GIFT_DISLIKED_SEQUENCE_ID
		_:
			return &""


func _get_current_game_day_id() -> int:
	if Data.has_method("get_current_game_day_id"):
		return Data.get_current_game_day_id()
	return -1


func _get_selected_gift_item_id(player: Node) -> StringName:
	if not is_instance_valid(player):
		return &""
	var selected_tool: Variant = player.get("current_tool")
	var selected_seed: Variant = player.get("current_seed")
	if selected_tool == null or selected_seed == null:
		return &""
	if int(selected_tool) != Enum.Tool.SEED:
		return &""
	if not Data.SEED_TO_ITEM.has(int(selected_seed)):
		return &""
	return Data.get_item_id(Data.SEED_TO_ITEM[int(selected_seed)])


func _get_selected_gift_item_amount(player: Node) -> int:
	var item_id: StringName = _get_selected_gift_item_id(player)
	if String(item_id).strip_edges().is_empty():
		return 0
	return Data.get_item_amount_by_id(item_id)


func _consume_selected_gift_item(player: Node, item_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	if _get_selected_gift_item_id(player) != item_id:
		return false
	if _get_selected_gift_item_amount(player) < amount:
		return false
	return Data.remove_item_by_id(item_id, amount)


func _get_dialogue_line(index: int) -> DialogueLineData:
	if active_dialogue_sequence == null:
		return null
	return active_dialogue_sequence.get_line(index)


func _get_dialogue_count() -> int:
	if active_dialogue_sequence == null:
		return 0
	return active_dialogue_sequence.lines.size()


func _direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "up"
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "down"
