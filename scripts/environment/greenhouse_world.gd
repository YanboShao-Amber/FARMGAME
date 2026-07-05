extends Node2D
class_name GreenhouseWorld

@export_group("Greenhouse Data")
@export var greenhouse_profile: GreenhouseProfileData

@export_group("State Textures")
@export var abandoned_texture: Texture2D
@export var repairing_texture: Texture2D
@export var restored_texture: Texture2D

@export_group("Visual Settings")
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_z_index: int = 0
@export var hide_when_texture_missing: bool = true
@export var warn_when_texture_missing: bool = true

@onready var greenhouse_sprite: Sprite2D = $GreenhouseSprite
@onready var debug_state_label: Label = get_node_or_null("DebugStateLabel") as Label

var _greenhouse_id: StringName = &""
var _current_state: int = -1
var _has_warned_missing_profile: bool = false
var _warned_missing_texture_states: Dictionary = {}


func _ready() -> void:
	_apply_visual_settings()
	_hide_debug_label()

	if not _has_valid_profile():
		_hide_sprite()
		_warn_missing_profile_once()
		return

	_greenhouse_id = greenhouse_profile.greenhouse_id
	_connect_greenhouse_manager_signals()
	_refresh_visual()


func get_greenhouse_id() -> StringName:
	return _greenhouse_id


func get_displayed_state() -> int:
	return _current_state


func get_displayed_texture() -> Texture2D:
	if greenhouse_sprite == null:
		return null
	return greenhouse_sprite.texture


func refresh_visual() -> void:
	_refresh_visual()


func _apply_visual_settings() -> void:
	if greenhouse_sprite == null:
		return
	greenhouse_sprite.position = sprite_offset
	greenhouse_sprite.scale = sprite_scale
	greenhouse_sprite.z_index = sprite_z_index


func _hide_debug_label() -> void:
	if debug_state_label != null:
		debug_state_label.hide()


func _connect_greenhouse_manager_signals() -> void:
	var manager: Node = _get_greenhouse_manager()
	if manager == null:
		return

	_connect_manager_signal(manager, &"greenhouse_registered", _on_greenhouse_registered)
	_connect_manager_signal(manager, &"greenhouse_state_changed", _on_greenhouse_state_changed)
	_connect_manager_signal(manager, &"greenhouse_reset", _on_greenhouse_reset)
	_connect_manager_signal(manager, &"greenhouse_restored", _on_greenhouse_restored)


func _connect_manager_signal(manager: Node, signal_name: StringName, handler: Callable) -> void:
	if not manager.has_signal(signal_name):
		return
	if not manager.is_connected(signal_name, handler):
		manager.connect(signal_name, handler)


func _refresh_visual() -> void:
	_apply_visual_settings()
	_hide_debug_label()

	if greenhouse_sprite == null:
		return

	if not _has_valid_profile():
		_current_state = -1
		_hide_sprite()
		_warn_missing_profile_once()
		return

	if String(_greenhouse_id).strip_edges().is_empty():
		_greenhouse_id = greenhouse_profile.greenhouse_id

	if String(_greenhouse_id).strip_edges().is_empty():
		_current_state = -1
		_hide_sprite()
		_warn_missing_profile_once()
		return

	var manager: Node = _get_greenhouse_manager()
	if manager == null:
		_current_state = -1
		_hide_sprite()
		return
	if not manager.has_method("is_profile_registered") or not manager.has_method("get_state"):
		_current_state = -1
		_hide_sprite()
		return
	if not bool(manager.call("is_profile_registered", _greenhouse_id)):
		_current_state = -1
		_hide_sprite()
		return

	var state: int = int(manager.call("get_state", _greenhouse_id))
	if not greenhouse_profile.is_valid_state(state):
		_current_state = -1
		_hide_sprite()
		return

	var state_texture: Texture2D = _get_texture_for_state(state)
	_current_state = state

	if state_texture != null:
		greenhouse_sprite.texture = state_texture
		greenhouse_sprite.show()
		return

	greenhouse_sprite.texture = null
	if hide_when_texture_missing:
		greenhouse_sprite.hide()
	else:
		greenhouse_sprite.show()
	_warn_missing_texture_once(state)


func _get_texture_for_state(state: int) -> Texture2D:
	match state:
		GreenhouseProfileData.GreenhouseState.ABANDONED:
			return abandoned_texture
		GreenhouseProfileData.GreenhouseState.REPAIRING:
			return repairing_texture
		GreenhouseProfileData.GreenhouseState.RESTORED:
			return restored_texture
		_:
			return null


func _on_greenhouse_registered(greenhouse_id: StringName) -> void:
	if greenhouse_id != _greenhouse_id:
		return
	_refresh_visual()


func _on_greenhouse_state_changed(greenhouse_id: StringName, _previous_state: int, _current_state_value: int) -> void:
	if greenhouse_id != _greenhouse_id:
		return
	_refresh_visual()


func _on_greenhouse_reset(greenhouse_id: StringName) -> void:
	if greenhouse_id != _greenhouse_id:
		return
	_refresh_visual()


func _on_greenhouse_restored(greenhouse_id: StringName) -> void:
	if greenhouse_id != _greenhouse_id:
		return


func _get_greenhouse_manager() -> Node:
	return get_node_or_null("/root/GreenhouseManager")


func _has_valid_profile() -> bool:
	if greenhouse_profile == null:
		return false
	return greenhouse_profile.is_valid_profile()


func _hide_sprite() -> void:
	if greenhouse_sprite != null:
		greenhouse_sprite.hide()


func _warn_missing_profile_once() -> void:
	if _has_warned_missing_profile:
		return
	_has_warned_missing_profile = true
	push_warning("GreenhouseWorld requires a valid GreenhouseProfileData resource before it can display a greenhouse.")


func _warn_missing_texture_once(state: int) -> void:
	if not warn_when_texture_missing:
		return
	if _warned_missing_texture_states.has(state):
		return

	_warned_missing_texture_states[state] = true
	var state_name: String = _get_state_warning_name(state)
	push_warning("GreenhouseWorld is missing the %s texture for greenhouse '%s'." % [state_name, String(_greenhouse_id)])


func _get_state_warning_name(state: int) -> String:
	if greenhouse_profile != null:
		var profile_state_name: String = greenhouse_profile.get_state_name(state)
		if not profile_state_name.strip_edges().is_empty():
			return profile_state_name

	match state:
		GreenhouseProfileData.GreenhouseState.ABANDONED:
			return "ABANDONED"
		GreenhouseProfileData.GreenhouseState.REPAIRING:
			return "REPAIRING"
		GreenhouseProfileData.GreenhouseState.RESTORED:
			return "RESTORED"
		_:
			return "UNKNOWN"
