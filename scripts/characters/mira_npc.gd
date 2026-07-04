extends CharacterBody2D

enum MiraExpression {
	NEUTRAL,
	HAPPY,
	WORRIED,
	SURPRISED
}

const SPEAKER_NAME: String = "绫宠悵 Mira"

@export_group("Dialogue Portraits")
@export var portrait_neutral: Texture2D
@export var portrait_happy: Texture2D
@export var portrait_worried: Texture2D
@export var portrait_surprised: Texture2D

var test_dialogue: Array[String] = [
	"浣犲ソ鈥︹€﹁灏忓績鑴氳竟鐨勫辜鑻椼€?",
	"杩欓噷浠ュ墠鏄竴搴ф俯瀹ゃ€?",
	"鎴戝彨绫宠悵銆傛殏鏃惰礋璐ｇ収椤捐繕鐣欏湪杩欓噷鐨勬鐗┿€?"
]

var dialogue_expressions: Array[MiraExpression] = [
	MiraExpression.NEUTRAL,
	MiraExpression.WORRIED,
	MiraExpression.NEUTRAL
]

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
			_finish_dialogue()

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var hand_overlay: AnimatedSprite2D = $HandOverlay
@onready var character_dialog: CharacterDialog = $CharacterDialog
@onready var interact_sign: Sprite2D = get_node_or_null("InteractSign") as Sprite2D


func _ready() -> void:
	if animated_sprite != null and not animated_sprite.frame_changed.is_connected(_sync_hand_overlay):
		animated_sprite.frame_changed.connect(_sync_hand_overlay)
	if character_dialog != null and not character_dialog.dialogue_closed.is_connected(_on_character_dialog_dialogue_closed):
		character_dialog.dialogue_closed.connect(_on_character_dialog_dialogue_closed)
	play_idle(facing_direction)
	can_interact = false


func _exit_tree() -> void:
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
	if character_dialog == null or test_dialogue.is_empty():
		_finish_dialogue()
		return

	current_dialogue_player = player
	if player.has_method("begin_dialogue_lock"):
		player.begin_dialogue_lock(self)

	dialogue_index = 0
	var expression: MiraExpression = _get_dialogue_expression(dialogue_index)
	var portrait_texture: Texture2D = _get_portrait(expression)
	var text: String = test_dialogue[dialogue_index]

	if interact_sign != null:
		interact_sign.hide()

	character_dialog.show_line(SPEAKER_NAME, text, portrait_texture)
	_update_interaction_state()


func _advance_dialogue() -> void:
	if character_dialog == null or test_dialogue.is_empty():
		_finish_dialogue()
		return

	if dialogue_index < 0 or dialogue_index >= test_dialogue.size():
		_finish_dialogue()
		return

	var next_dialogue_index: int = dialogue_index + 1
	if next_dialogue_index >= test_dialogue.size():
		_finish_dialogue()
		return

	dialogue_index = next_dialogue_index
	var expression: MiraExpression = _get_dialogue_expression(dialogue_index)
	var portrait_texture: Texture2D = _get_portrait(expression)
	var text: String = test_dialogue[dialogue_index]

	character_dialog.update_line(text, portrait_texture)
	_update_interaction_state()


func _finish_dialogue() -> void:
	if is_finishing_dialogue:
		return

	is_finishing_dialogue = true
	var player: Node2D = current_dialogue_player
	current_dialogue_player = null
	dialogue_index = 0

	if character_dialog != null:
		character_dialog.close_dialogue()

	if is_instance_valid(player) and player.has_method("end_dialogue_lock"):
		player.end_dialogue_lock(self)

	is_finishing_dialogue = false
	_update_interaction_state()


func _update_interaction_state() -> void:
	if not is_node_ready():
		return

	var dialogue_is_open: bool = character_dialog != null and character_dialog.is_dialogue_open()
	if interact_sign != null:
		interact_sign.visible = can_interact and not dialogue_is_open


func _on_character_dialog_dialogue_closed() -> void:
	_finish_dialogue()


func _get_dialogue_expression(index: int) -> MiraExpression:
	if index < 0 or index >= dialogue_expressions.size():
		return MiraExpression.NEUTRAL
	return dialogue_expressions[index]


func _get_portrait(expression: MiraExpression) -> Texture2D:
	match expression:
		MiraExpression.HAPPY:
			return portrait_happy if portrait_happy != null else portrait_neutral
		MiraExpression.WORRIED:
			return portrait_worried if portrait_worried != null else portrait_neutral
		MiraExpression.SURPRISED:
			return portrait_surprised if portrait_surprised != null else portrait_neutral
		_:
			return portrait_neutral


func _direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "up"
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "down"
