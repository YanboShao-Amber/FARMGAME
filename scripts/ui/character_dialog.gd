class_name CharacterDialog
extends CanvasLayer

signal dialogue_opened
signal dialogue_closed
signal text_reveal_started
signal text_reveal_finished

@export_group("Text Reveal")
@export_range(5.0, 120.0, 1.0)
var characters_per_second: float = 35.0

var _is_revealing: bool = false
var _visible_character_count: int = 0
var _total_character_count: int = 0
var _current_full_text: String = ""

@onready var root: Control = $Root
@onready var text_reveal_timer: Timer = $TextRevealTimer
@onready var portrait_frame: Control = $Root/BottomMargin/CenterContainer/DialoguePanel/PortraitFrame
@onready var portrait: TextureRect = $Root/BottomMargin/CenterContainer/DialoguePanel/PortraitFrame/Portrait
@onready var speaker_name: Label = $Root/BottomMargin/CenterContainer/DialoguePanel/SpeakerName
@onready var dialogue_text: RichTextLabel = $Root/BottomMargin/CenterContainer/DialoguePanel/DialogueText
@onready var continue_indicator: TextureRect = $Root/BottomMargin/CenterContainer/DialoguePanel/ContinueIndicator


func _ready() -> void:
	if not text_reveal_timer.timeout.is_connected(_on_text_reveal_timer_timeout):
		text_reveal_timer.timeout.connect(_on_text_reveal_timer_timeout)
	close_dialogue()


func show_line(speaker_name_text: String, text: String, portrait_texture: Texture2D = null) -> void:
	var was_open: bool = is_dialogue_open()
	speaker_name.text = speaker_name_text
	_set_portrait(portrait_texture)
	root.show()
	_start_text_reveal(text)
	if not was_open:
		dialogue_opened.emit()


func update_line(text: String, portrait_texture: Texture2D = null) -> void:
	_set_portrait(portrait_texture)
	root.show()
	_start_text_reveal(text)


func close_dialogue() -> void:
	var was_open: bool = is_dialogue_open()
	if text_reveal_timer != null:
		text_reveal_timer.stop()
	_is_revealing = false
	_visible_character_count = 0
	_total_character_count = 0
	_current_full_text = ""
	root.hide()
	speaker_name.text = ""
	dialogue_text.text = ""
	dialogue_text.visible_characters = -1
	_set_portrait(null)
	continue_indicator.hide()
	if was_open:
		dialogue_closed.emit()


func is_dialogue_open() -> bool:
	return is_node_ready() and root != null and root.visible


func is_revealing_text() -> bool:
	return is_dialogue_open() and _is_revealing and _visible_character_count < _total_character_count


func reveal_all_text() -> void:
	if not is_revealing_text():
		return

	_complete_text_reveal()


func _set_portrait(portrait_texture: Texture2D) -> void:
	portrait.texture = portrait_texture
	portrait_frame.visible = portrait_texture != null


func _start_text_reveal(text: String) -> void:
	text_reveal_timer.stop()
	_current_full_text = text
	dialogue_text.text = _current_full_text
	dialogue_text.visible_characters = 0
	_visible_character_count = 0
	_total_character_count = _current_full_text.length()
	continue_indicator.hide()

	if _total_character_count <= 0:
		dialogue_text.visible_characters = -1
		_is_revealing = false
		continue_indicator.show()
		text_reveal_finished.emit()
		return

	_is_revealing = true
	text_reveal_timer.wait_time = 1.0 / max(characters_per_second, 1.0)
	text_reveal_timer.start()
	text_reveal_started.emit()


func _on_text_reveal_timer_timeout() -> void:
	if not is_dialogue_open() or not _is_revealing:
		return

	_visible_character_count = clampi(_visible_character_count + 1, 0, _total_character_count)
	dialogue_text.visible_characters = _visible_character_count

	if _visible_character_count >= _total_character_count:
		_complete_text_reveal()


func _complete_text_reveal() -> void:
	if not _is_revealing:
		return

	text_reveal_timer.stop()
	_visible_character_count = _total_character_count
	dialogue_text.visible_characters = -1
	_is_revealing = false
	continue_indicator.show()
	text_reveal_finished.emit()
