extends CharacterBody2D

@export var test_dialogue: Array[String] = [
	"你好……请小心脚边的幼苗。",
	"这里以前是一座温室。",
	"我叫米萝。暂时负责照顾还留在这里的植物。"
]

var facing_direction: Vector2 = Vector2.DOWN
var dialogue_index: int = 0

var can_interact: bool = false:
	set(value):
		can_interact = value
		_update_interaction_state()

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var hand_overlay: AnimatedSprite2D = $HandOverlay
@onready var dialog: Control = get_node_or_null("Dialog") as Control
@onready var interact_sign: Sprite2D = get_node_or_null("InteractSign") as Sprite2D


func _ready() -> void:
	if animated_sprite != null and not animated_sprite.frame_changed.is_connected(_sync_hand_overlay):
		animated_sprite.frame_changed.connect(_sync_hand_overlay)
	play_idle(facing_direction)
	can_interact = false


func set_facing_direction(direction: Vector2) -> void:
	facing_direction = _to_cardinal_direction(direction)


func play_idle(direction: Vector2 = facing_direction) -> void:
	set_facing_direction(direction)
	_play_animation(StringName("idle_%s" % _direction_suffix(facing_direction)))


func play_walk(direction: Vector2 = facing_direction) -> void:
	set_facing_direction(direction)
	_play_animation(StringName("walk_%s" % _direction_suffix(facing_direction)))


func interact(player: Node2D) -> void:
	if not can_interact or not is_instance_valid(player):
		return

	play_idle(player.global_position - global_position)
	_advance_dialogue()


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


func _advance_dialogue() -> void:
	if dialog == null or test_dialogue.is_empty():
		_close_dialogue()
		return

	if dialogue_index < test_dialogue.size():
		dialog.show()
		if dialog.has_method("set_text"):
			dialog.call("set_text", test_dialogue[dialogue_index])
		dialogue_index += 1
		_update_interaction_state()
		return

	_close_dialogue()


func _close_dialogue() -> void:
	if dialog != null:
		dialog.hide()
	dialogue_index = 0
	_update_interaction_state()


func _update_interaction_state() -> void:
	if not is_node_ready():
		return

	var dialog_is_visible: bool = dialog != null and dialog.visible
	if interact_sign != null:
		interact_sign.visible = can_interact and not dialog_is_visible

	if not can_interact:
		if dialog != null:
			dialog.hide()
		dialogue_index = 0


func _direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "up"
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "down"
