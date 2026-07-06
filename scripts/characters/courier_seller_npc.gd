extends CharacterBody2D
## Courier — a stationary seller NPC.
## Player interacts (same "action" key as other NPCs), Courier faces the player and
## shows a short dialogue with a top-right choice: "Sell" opens the Sell panel,
## "Leave" ends the conversation. The Courier does not give quests, take gifts, or
## participate in the relationship system.
##
## Sprite source: res://graphics/npcs/courier/Small-8-Direction-Characters_by_AxulArt.png
## 128x288 sheet = three 8x6 character blocks. This NPC uses block 1 (blue cap),
## direction columns: up=0, right=32, down=64, left=96. The 4 walk rows stack at
## y=128/144/160/176. Rows y=128 and y=176 are the two near-neutral poses (they
## differ only in the lower body, ~4-8 px), so the idle loops between them for a
## subtle, visible breathing motion; rows y=144/160 are the wide stride poses.

const SHEET: Texture2D = preload("res://graphics/npcs/courier/Small-8-Direction-Characters_by_AxulArt.png")
const FRAME_SIZE: int = 16
const IDLE_Y: int = 128            # neutral standing pose (first character row of block 1)
const IDLE_BOB_Y: int = 176        # near-neutral pose; subtle lower-body shift vs IDLE_Y
const IDLE_FPS: float = 2.5        # slow breathing cadence (2-4 FPS range)
const DIR_COLUMN_X: Dictionary = {"up": 0, "right": 32, "down": 64, "left": 96}
const WALK_ROW_Y: Array = [128, 144, 160, 176]

const GREETING_TEXT: String = "我可以收购你的作物和鱼。\nI can buy crops and fish from you."
const CHOICE_SELL: int = 0
const CHOICE_LEAVE: int = 1

enum Phase {IDLE, DIALOGUE, SELLING}

signal request_open_sell_panel
signal request_close_sell_panel

var facing_direction: Vector2 = Vector2.DOWN
var _phase: int = Phase.IDLE
var _original_facing: Vector2 = Vector2.DOWN
var _locked_player: Node = null

var can_interact: bool = false:
	set(value):
		can_interact = value
		if not is_node_ready():
			return
		if _interact_sign != null:
			_interact_sign.visible = can_interact and _phase == Phase.IDLE
		if not can_interact and _phase != Phase.IDLE:
			# Defensive: player left range mid-interaction (rare while locked).
			if _phase == Phase.SELLING:
				request_close_sell_panel.emit()
			_end_interaction()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var character_dialog: CharacterDialog = $CharacterDialog
@onready var _interact_sign: Node = get_node_or_null("InteractSign")


func _ready() -> void:
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play_idle(facing_direction)
	if not character_dialog.text_reveal_finished.is_connected(_on_text_reveal_finished):
		character_dialog.text_reveal_finished.connect(_on_text_reveal_finished)
	if not character_dialog.choice_selected.is_connected(_on_choice_selected):
		character_dialog.choice_selected.connect(_on_choice_selected)
	can_interact = false


func _exit_tree() -> void:
	if is_instance_valid(_locked_player) and _locked_player.has_method("end_dialogue_lock"):
		_locked_player.end_dialogue_lock(self)
	_locked_player = null


# =========================================================
# Interaction (mirrors Mira's action-key contract)
# =========================================================
func interact(player: Node2D) -> void:
	if not can_interact:
		return

	if _phase == Phase.SELLING:
		return  # Sell panel owns input; ignore the action key.

	if _phase == Phase.DIALOGUE:
		if character_dialog.is_revealing_text():
			character_dialog.reveal_all_text()
		# If choices are showing, the choice buttons handle selection.
		return

	if not is_instance_valid(player):
		return
	_begin_interaction(player)


func _begin_interaction(player: Node2D) -> void:
	_phase = Phase.DIALOGUE
	_original_facing = facing_direction
	_locked_player = player
	if _interact_sign != null:
		_interact_sign.visible = false
	play_idle(player.global_position - global_position)
	if player.has_method("begin_dialogue_lock"):
		player.begin_dialogue_lock(self)
	character_dialog.show_line("邮差 Courier", GREETING_TEXT, null)


func _on_text_reveal_finished() -> void:
	if _phase != Phase.DIALOGUE:
		return
	if character_dialog.is_dialogue_open() and not character_dialog.has_choices():
		character_dialog.show_choices(["出售 Sell", "离开 Leave"])


func _on_choice_selected(index: int) -> void:
	if _phase != Phase.DIALOGUE:
		return
	if index == CHOICE_SELL:
		_open_sell_panel()
	else:
		_end_interaction()


func _open_sell_panel() -> void:
	_phase = Phase.SELLING
	character_dialog.close_dialogue()  # hide the box; keep the player locked
	request_open_sell_panel.emit()


# Called by the level when the Sell panel is closed by the player.
func on_sell_panel_closed() -> void:
	if _phase != Phase.SELLING:
		return
	_end_interaction()


func _end_interaction() -> void:
	_phase = Phase.IDLE
	character_dialog.close_dialogue()
	play_idle(_original_facing)  # restore original facing (avoids the stuck-facing bug)
	if is_instance_valid(_locked_player) and _locked_player.has_method("end_dialogue_lock"):
		_locked_player.end_dialogue_lock(self)
	_locked_player = null
	if _interact_sign != null:
		_interact_sign.visible = can_interact


# =========================================================
# Facing / animation
# =========================================================
func play_idle(direction: Vector2 = facing_direction) -> void:
	facing_direction = _to_cardinal_direction(direction)
	_play_animation("idle_%s" % _direction_suffix(facing_direction))


func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return facing_direction
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "up"
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "down"


func _play_animation(animation_name: String) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for suffix in DIR_COLUMN_X:
		var x: int = int(DIR_COLUMN_X[suffix])
		# idle: two near-neutral poses looped slowly -> subtle, visible breathing.
		var idle_name := "idle_%s" % suffix
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.set_animation_speed(idle_name, IDLE_FPS)
		frames.add_frame(idle_name, _atlas(x, IDLE_Y))
		frames.add_frame(idle_name, _atlas(x, IDLE_BOB_Y))
		# walk: four frames stacked down the block
		var walk_name := "walk_%s" % suffix
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, 8.0)
		for row_y in WALK_ROW_Y:
			frames.add_frame(walk_name, _atlas(x, int(row_y)))
	# SpriteFrames always has a "default" animation; leave it empty/unused.
	return frames


func _atlas(x: int, y: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = SHEET
	tex.region = Rect2(x, y, FRAME_SIZE, FRAME_SIZE)
	return tex
