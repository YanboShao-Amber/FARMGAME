extends CanvasLayer
## Independent Relationship Panel (Phase H5.1).
## Opened from the HUD relationship button. Shows one card per tracked NPC
## (米拉 / 猫咪 / 小鼠) with portrait, Chinese name, 5 hearts, title, points/500,
## and today's talk / gift status. Reads live from RelationshipManager and
## GiftManager every time it opens; refreshes in place while open.
##
## This panel does NOT modify any relationship values, thresholds, or gift
## preferences. It only registers additive profiles for cat/mouse if they are
## not already registered, so all three NPCs have a card to display.

signal closed

const HEART_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/emoji style ui/Inventory_Herat_Spritesheet.png")
# Same button/close-icon sheet the Sell panel uses.
const CLOSE_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Sprite sheet for Basic Pack.png")

# Colors copied from sell_ui.gd / sell_ui.tscn so the panel matches the Sell panel.
const DARK_TEXT := Color(0.23, 0.13, 0.08, 1)
const SUBTITLE_TEXT := Color(0.35, 0.21, 0.09, 1)
const MUTED_TEXT := Color(0.35, 0.21, 0.09, 1)
const PANEL_BG := Color(0.89, 0.72, 0.52, 1)
const CARD_BG := Color(0.82, 0.66, 0.47, 1)
const BORDER_COLOR := Color(0.48, 0.27, 0.15, 1)

# Player-facing NPCs shown in the panel. Internal ids stay English.
const NPCS: Array[Dictionary] = [
	{"id": &"mira", "name": "米拉", "portrait": "res://graphics/npcs/1-Bunny/portraits/mira_neutral.png"},
	{"id": &"cat", "name": "猫咪", "portrait": ""},
	{"id": &"mouse", "name": "小鼠", "portrait": ""},
]

var _root: Control
var _close_button: TextureButton
var _cards: Dictionary = {}
var _open: bool = false
var _rm: Node = null
var _gm: Node = null


func _ready() -> void:
	layer = 8
	_rm = get_node_or_null("/root/RelationshipManager")
	_gm = get_node_or_null("/root/GiftManager")
	_register_missing_profiles()
	_build_ui()
	_connect_manager_signals()
	_root.hide()


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	_root.show()
	refresh()
	await get_tree().process_frame
	if _close_button != null:
		_close_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.hide()
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	# Escape / Xbox B both map to ui_cancel.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	# While the panel owns the screen, swallow the quest-tracker toggle (J) so no
	# other panel can open behind it.
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_J:
		get_viewport().set_input_as_handled()


# =========================================================
# Additive cat/mouse registration (never overwrites existing profiles)
# =========================================================
func _register_missing_profiles() -> void:
	if _rm == null:
		return
	for entry in NPCS:
		var npc_id: StringName = entry["id"]
		# Mira owns her own profile (registered from her NPCData .tres); never
		# shadow it here. Only cat/mouse need an additive profile to display.
		if npc_id == &"mira":
			continue
		if _rm.has_method("is_profile_registered") and bool(_rm.call("is_profile_registered", npc_id)):
			continue
		var profile := RelationshipProfileData.new()
		profile.npc_id = npc_id
		profile.max_hearts = 5
		profile.points_per_heart = 100
		profile.starting_points = 0
		if profile.is_valid_profile():
			_rm.call("register_profile", profile)


func _connect_manager_signals() -> void:
	if _rm != null:
		_connect_signal(_rm, &"relationship_points_changed", _on_relationship_changed)
		_connect_signal(_rm, &"relationship_heart_changed", _on_relationship_changed)
		_connect_signal(_rm, &"relationship_registered", _on_registered)
	if _gm != null:
		_connect_signal(_gm, &"gift_given", _on_gift_changed)
		_connect_signal(_gm, &"gift_history_reset", _on_gift_changed)


func _connect_signal(source: Node, signal_name: StringName, handler: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, handler):
		source.connect(signal_name, handler)


func _on_relationship_changed(_a = null, _b = null, _c = null, _d = null) -> void:
	if _open:
		refresh()


func _on_registered(_npc_id: StringName = &"") -> void:
	if _open:
		refresh()


func _on_gift_changed(_a = null, _b = null, _c = null, _d = null, _e = null) -> void:
	if _open:
		refresh()


# =========================================================
# UI construction
# =========================================================
func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Dim backdrop that also blocks clicks to the world / HUD behind the panel.
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	# Flat tan panel with a dark border — same StyleBoxFlat recipe as the Sell panel.
	var panel := Panel.new()
	# Same size as the Quest panel (TrackerPanel is 750x450).
	panel.custom_minimum_size = Vector2(750, 450)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := _make_label("关系", 30, DARK_TEXT)
	column.add_child(title)

	var subtitle := _make_label("谷地伙伴的好感度", 20, SUBTITLE_TEXT)
	column.add_child(subtitle)

	var rows_column := VBoxContainer.new()
	rows_column.add_theme_constant_override("separation", 10)
	rows_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(rows_column)

	for entry in NPCS:
		rows_column.add_child(_make_row(entry))

	# Close button (mouse); Escape / B also close via _unhandled_input.
	# Same asset, regions, anchoring and stretch as sell_ui's CloseButton.
	_close_button = TextureButton.new()
	_close_button.texture_normal = _atlas(CLOSE_SHEET, Rect2(837, 5, 20, 21))
	_close_button.texture_pressed = _atlas(CLOSE_SHEET, Rect2(869, 5, 20, 21))
	_close_button.texture_hover = _atlas(CLOSE_SHEET, Rect2(837, 5, 20, 21))
	_close_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_close_button.ignore_texture_size = true
	_close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_close_button.anchor_left = 1.0
	_close_button.anchor_right = 1.0
	_close_button.offset_left = -45.0
	_close_button.offset_top = 9.0
	_close_button.offset_right = -9.0
	_close_button.offset_bottom = 45.0
	_close_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_close_button.pressed.connect(close)
	panel.add_child(_close_button)


func _make_row(entry: Dictionary) -> Control:
	var npc_id: StringName = entry["id"]

	# One horizontal row per NPC (Stardew social-menu style): portrait + name on
	# the left, hearts in the middle, points / status on the right.
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 78)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)

	# Portrait
	var portrait := TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(52, 52)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.texture = _load_portrait(entry)
	hbox.add_child(portrait)

	# Name (left, vertically centered) — the title label was removed per request.
	var name_label := _make_label(String(entry["name"]), 24, DARK_TEXT)
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)

	# Hearts (center, larger and spread out)
	var hearts_row := HBoxContainer.new()
	hearts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hearts_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hearts_row.add_theme_constant_override("separation", 12)
	hbox.add_child(hearts_row)
	var hearts: Array[TextureRect] = []
	for i in range(5):
		var heart := TextureRect.new()
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture = _heart_texture()
		hearts_row.add_child(heart)
		hearts.append(heart)

	# Points + status (right, vertically centered, right-aligned)
	var status := VBoxContainer.new()
	status.custom_minimum_size = Vector2(150, 0)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_theme_constant_override("separation", 2)
	hbox.add_child(status)
	var points_label := _make_label("", 16, MUTED_TEXT)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(points_label)
	var talk_label := _make_label("", 14, MUTED_TEXT)
	talk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(talk_label)
	var gift_label := _make_label("", 14, MUTED_TEXT)
	gift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(gift_label)

	_cards[npc_id] = {
		"hearts": hearts,
		"points": points_label,
		"talk": talk_label,
		"gift": gift_label,
	}
	return row


# =========================================================
# Refresh (reads live data)
# =========================================================
func refresh() -> void:
	var day_id: int = Data.get_current_game_day_id() if Data.has_method("get_current_game_day_id") else -1
	for entry in NPCS:
		var npc_id: StringName = entry["id"]
		if not _cards.has(npc_id):
			continue
		var card: Dictionary = _cards[npc_id]

		var hearts: int = 0
		var max_hearts: int = 5
		var points: int = 0
		var max_points: int = 500
		if _rm != null and _rm.has_method("is_profile_registered") and bool(_rm.call("is_profile_registered", npc_id)):
			hearts = int(_rm.call("get_heart_level", npc_id))
			max_hearts = int(_rm.call("get_max_hearts", npc_id))
			points = int(_rm.call("get_points", npc_id))
			max_points = int(_rm.call("get_max_points", npc_id))

		var heart_nodes: Array = card["hearts"]
		for i in range(heart_nodes.size()):
			var filled: bool = i < hearts
			(heart_nodes[i] as TextureRect).modulate = Color(1, 1, 1, 1.0) if filled else Color(1, 1, 1, 0.28)

		(card["points"] as Label).text = "好感度：%d / %d" % [points, max_points]

		# Talk status: the data model has no per-day talk tracking, so this is a
		# static availability line (kept in Chinese for consistency).
		(card["talk"] as Label).text = "今日可交谈"

		# Gift status: real, from GiftManager (only NPCs with a gift profile).
		if _gm != null and _gm.has_method("is_profile_registered") and bool(_gm.call("is_profile_registered", npc_id)):
			var gifted: bool = day_id >= 1 and bool(_gm.call("has_given_gift_on_day", npc_id, day_id))
			(card["gift"] as Label).text = "今日已送礼" if gifted else "今日可送礼"
		else:
			(card["gift"] as Label).text = "暂不可赠礼"


# =========================================================
# Helpers
# =========================================================
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	return style


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No font override: inherit the default theme font, same as the Quest panel.
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _heart_texture() -> AtlasTexture:
	return _atlas(HEART_SHEET, Rect2(0, 0, 16, 16))


func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = region
	return tex


func _load_portrait(entry: Dictionary) -> Texture2D:
	var path: String = String(entry.get("portrait", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	# Fall back to the heart icon when an NPC has no clean portrait.
	return _heart_texture()
