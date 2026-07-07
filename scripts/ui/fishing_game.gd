extends Node2D

const UI_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")

const CATCH_BAR_HEIGHT_RATIO := 0.24
const UPWARD_ACCELERATION := 2.8
const DOWNWARD_GRAVITY := 2.2
const MAX_BAR_SPEED := 0.95
const VELOCITY_DAMPING := 1.8
const BOTTOM_BOUNCE_FACTOR := 0.22
const TOP_BOUNCE_FACTOR := 0.05

const START_PROGRESS := 0.35
const FILL_PER_SECOND := 0.34
const DRAIN_PER_SECOND := 0.24
const START_GRACE_SECONDS := 0.75

const TRACK_FALLBACK_HEIGHT := 100.0

signal fish_game_finish(is_success: bool, fish_item: int)

@onready var track_panel: NinePatchRect = $Control/NinePatchRect
@onready var progress_bar: TextureProgressBar = $Control/TextureProgressBar
@onready var catch_bar: Sprite2D = $BarSprite
@onready var fish_marker: Sprite2D = $FishSprite
@onready var fish_update_timer: Timer = $FishUpdateTimer

var selected_fish_item: int = Enum.Item.GRAY_CARP
var current_profile: Dictionary = {}
var track_height: float = TRACK_FALLBACK_HEIGHT
var catch_bar_position: float = 0.72
var catch_bar_velocity: float = 0.0
var fish_position: float = 0.5
var fish_target_position: float = 0.5
var progress: float = START_PROGRESS
var elapsed_seconds: float = 0.0
var is_fishing_control_held: bool = false
var _mouse_control_held: bool = false
var _result_resolved: bool = false
var _hint_label: Label


func _ready() -> void:
	hide()
	_configure_progress_bar()
	_create_hint_label()
	fish_update_timer.stop()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_control_held = mouse_event.pressed
			get_viewport().set_input_as_handled()
			return
	if event.is_action("action") or event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible or _result_resolved:
		return
	elapsed_seconds += delta
	is_fishing_control_held = _mouse_control_held or Input.is_action_pressed("action") or Input.is_action_pressed("ui_accept")
	_update_catch_bar(delta)
	_update_fish(delta)
	_update_progress(delta)
	_sync_visuals()
	_check_result()


func reveal(fish_item: int = -1) -> void:
	if fish_item == -1 or not Data.is_fish_species(fish_item):
		fish_item = Data.roll_manual_fish_species()
	selected_fish_item = fish_item
	current_profile = Data.MANUAL_FISHING_PROFILES.get(selected_fish_item, Data.MANUAL_FISHING_PROFILES[Enum.Item.GRAY_CARP])
	_reset_state()
	fish_marker.texture = Data.get_item_texture(selected_fish_item)
	_retarget_fish()
	fish_update_timer.start(_next_retarget_seconds())
	show()
	_sync_visuals()


func apply_bar_boost(boost_velocity: float = -0.12) -> void:
	catch_bar_velocity = boost_velocity


func _reset_state() -> void:
	_result_resolved = false
	_mouse_control_held = false
	is_fishing_control_held = false
	elapsed_seconds = 0.0
	progress = START_PROGRESS
	catch_bar_position = 0.72
	catch_bar_velocity = 0.0
	fish_position = randf_range(0.25, 0.75)
	fish_target_position = fish_position
	_configure_track_metrics()
	_configure_progress_bar()
	progress_bar.value = progress * 100.0


func _configure_track_metrics() -> void:
	track_height = track_panel.size.y
	if track_height <= 0.0:
		track_height = track_panel.custom_minimum_size.y
	if track_height <= 0.0:
		track_height = TRACK_FALLBACK_HEIGHT

	var texture_height: float = float(catch_bar.texture.get_height()) if catch_bar.texture != null else 1.0
	catch_bar.scale.y = maxf(0.1, (track_height * CATCH_BAR_HEIGHT_RATIO) / texture_height)


func _configure_progress_bar() -> void:
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = progress * 100.0


func _create_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.text = "Hold: Mouse / Space / A"
	_hint_label.add_theme_font_override("font", UI_FONT)
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85, 1))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	_hint_label.position = Vector2(-58, 58)
	$Control.add_child(_hint_label)


func _update_catch_bar(delta: float) -> void:
	if is_fishing_control_held:
		catch_bar_velocity -= UPWARD_ACCELERATION * delta
	else:
		catch_bar_velocity += DOWNWARD_GRAVITY * delta
	catch_bar_velocity = move_toward(catch_bar_velocity, 0.0, VELOCITY_DAMPING * delta)
	catch_bar_velocity = clampf(catch_bar_velocity, -MAX_BAR_SPEED, MAX_BAR_SPEED)
	catch_bar_position += catch_bar_velocity * delta

	var half_bar: float = CATCH_BAR_HEIGHT_RATIO * 0.5
	var top_limit: float = half_bar
	var bottom_limit: float = 1.0 - half_bar
	if catch_bar_position < top_limit:
		catch_bar_position = top_limit
		if catch_bar_velocity < 0.0:
			catch_bar_velocity = absf(catch_bar_velocity) * TOP_BOUNCE_FACTOR
	elif catch_bar_position > bottom_limit:
		catch_bar_position = bottom_limit
		if catch_bar_velocity > 0.0:
			catch_bar_velocity = -absf(catch_bar_velocity) * BOTTOM_BOUNCE_FACTOR


func _update_fish(delta: float) -> void:
	var move_speed: float = float(current_profile.get("move_speed", 0.28))
	fish_position = move_toward(fish_position, fish_target_position, move_speed * delta)
	var jitter: float = float(current_profile.get("jitter", 0.0))
	if jitter > 0.0:
		fish_position += randf_range(-jitter, jitter) * delta
	fish_position = clampf(fish_position, 0.0, 1.0)


func _update_progress(delta: float) -> void:
	if _fish_overlaps_catch_bar():
		progress += FILL_PER_SECOND * delta
	elif elapsed_seconds > START_GRACE_SECONDS:
		progress -= DRAIN_PER_SECOND * delta
	progress = clampf(progress, 0.0, 1.0)


func _fish_overlaps_catch_bar() -> bool:
	var half_bar: float = CATCH_BAR_HEIGHT_RATIO * 0.5
	return fish_position >= catch_bar_position - half_bar and fish_position <= catch_bar_position + half_bar


func _sync_visuals() -> void:
	progress_bar.value = progress * 100.0
	catch_bar.position.y = _track_y_from_normalized(catch_bar_position)
	fish_marker.position.y = _track_y_from_normalized(fish_position)


func _track_y_from_normalized(value: float) -> float:
	return lerpf(-track_height * 0.5, track_height * 0.5, clampf(value, 0.0, 1.0))


func _check_result() -> void:
	if progress >= 1.0:
		_finish(true)
	elif elapsed_seconds > START_GRACE_SECONDS and progress <= 0.0:
		_finish(false)


func _finish(is_success: bool) -> void:
	if _result_resolved:
		return
	_result_resolved = true
	_mouse_control_held = false
	is_fishing_control_held = false
	fish_update_timer.stop()
	hide()
	fish_game_finish.emit(is_success, selected_fish_item)


func _retarget_fish() -> void:
	var dart_chance: float = float(current_profile.get("dart_chance", 0.0))
	if randf() < dart_chance:
		fish_target_position = 0.08 if randf() < 0.5 else 0.92
	else:
		fish_target_position = randf_range(0.08, 0.92)


func _next_retarget_seconds() -> float:
	var min_seconds: float = float(current_profile.get("retarget_min", 1.0))
	var max_seconds: float = float(current_profile.get("retarget_max", 1.6))
	return randf_range(min_seconds, max_seconds)


func _on_timer_timeout() -> void:
	if not visible or _result_resolved:
		return
	_retarget_fish()
	fish_update_timer.start(_next_retarget_seconds())


func _on_texture_progress_bar_value_changed(_value: float) -> void:
	pass
