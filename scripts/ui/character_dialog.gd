class_name CharacterDialog
extends CanvasLayer

signal dialogue_opened
signal dialogue_closed
signal text_reveal_started
signal text_reveal_finished
signal choice_selected(index: int)

const CHOICE_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")

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
@onready var choice_box: VBoxContainer = $Root/BottomMargin/CenterContainer/DialoguePanel/ChoiceBox


func _ready() -> void:
	if not text_reveal_timer.timeout.is_connected(_on_text_reveal_timer_timeout):
		text_reveal_timer.timeout.connect(_on_text_reveal_timer_timeout)
	close_dialogue()


# --- Player dialogue choices (top-right of the dialogue box) ---
# Optional: NPCs that offer branching choices (e.g. Courier "Sell"/"Leave")
# call show_choices() after their line; NPCs that don't (e.g. Mira) never do,
# so this is fully non-breaking.
func show_choices(labels: Array) -> void:
	hide_choices()
	if labels.is_empty():
		return
	for i in range(labels.size()):
		var button := Button.new()
		button.text = str(labels[i])
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_override("font", CHOICE_FONT)
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", Color(0.23, 0.13, 0.08, 1))
		button.add_theme_color_override("font_hover_color", Color(0.12, 0.07, 0.04, 1))
		button.add_theme_color_override("font_focus_color", Color(0.12, 0.07, 0.04, 1))
		button.add_theme_stylebox_override("normal", _make_choice_stylebox(Color(0.89, 0.72, 0.52, 1)))
		button.add_theme_stylebox_override("hover", _make_choice_stylebox(Color(0.95, 0.82, 0.62, 1)))
		button.add_theme_stylebox_override("pressed", _make_choice_stylebox(Color(0.82, 0.64, 0.44, 1)))
		button.add_theme_stylebox_override("focus", _make_choice_stylebox(Color(0.95, 0.82, 0.62, 1)))
		var index := i
		button.pressed.connect(func() -> void: _on_choice_pressed(index))
		choice_box.add_child(button)
	choice_box.show()
	await get_tree().process_frame
	if choice_box.get_child_count() > 0:
		(choice_box.get_child(0) as Control).grab_focus()


func hide_choices() -> void:
	if choice_box == null:
		return
	for child in choice_box.get_children():
		child.queue_free()
	choice_box.hide()


func has_choices() -> bool:
	return choice_box != null and choice_box.visible and choice_box.get_child_count() > 0


func _on_choice_pressed(index: int) -> void:
	hide_choices()
	choice_selected.emit(index)


func _make_choice_stylebox(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.48, 0.27, 0.15, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


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
	hide_choices()
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
