extends CanvasLayer
## Character Panel (Phase H5.1). Read-only player info opened from the HUD
## character button: portrait (current outfit), name, current outfit, coins, and
## unlocked outfit / machine counts. Purely informational — it changes no state.

signal closed

const UI_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")
const PANEL_TEXTURE: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Dialouge UI/dialog box medium.png")
const CLOSE_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Sprite sheet for Basic Pack.png")

const DARK_TEXT := Color(0.23, 0.13, 0.08, 1)
const MUTED_TEXT := Color(0.45, 0.34, 0.22, 1)

var _root: Control
var _close_button: TextureButton
var _portrait: TextureRect
var _outfit_label: Label
var _coin_label: Label
var _unlock_label: Label
var _open: bool = false


func _ready() -> void:
	layer = 8
	_build_ui()
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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_J:
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := NinePatchRect.new()
	panel.texture = PANEL_TEXTURE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.patch_margin_left = 16
	panel.patch_margin_top = 8
	panel.patch_margin_right = 8
	panel.patch_margin_bottom = 8
	panel.custom_minimum_size = Vector2(320, 260)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(column)

	var title := _make_label("人物", 30, DARK_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_portrait = TextureRect.new()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.custom_minimum_size = Vector2(64, 64)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_portrait)

	var name_label := _make_label("农场主", 22, DARK_TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)

	_outfit_label = _make_label("", 18, MUTED_TEXT)
	_outfit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_outfit_label)

	_coin_label = _make_label("", 18, MUTED_TEXT)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_coin_label)

	_unlock_label = _make_label("", 16, MUTED_TEXT)
	_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_unlock_label)

	_close_button = TextureButton.new()
	_close_button.texture_normal = _atlas(CLOSE_SHEET, Rect2(837, 5, 20, 21))
	_close_button.texture_pressed = _atlas(CLOSE_SHEET, Rect2(869, 5, 20, 21))
	_close_button.texture_hover = _atlas(CLOSE_SHEET, Rect2(837, 5, 20, 21))
	_close_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_close_button.ignore_texture_size = true
	_close_button.custom_minimum_size = Vector2(28, 30)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_close_button.position = Vector2(-34, 8)
	_close_button.pressed.connect(close)
	panel.add_child(_close_button)


func refresh() -> void:
	var player: Node = get_tree().get_first_node_in_group("Player")
	var style: int = int(player.current_style) if player != null and "current_style" in player else Enum.Style.BASIC

	if Data.PLAYER_SKINS.has(style):
		_portrait.texture = Data.PLAYER_SKINS[style]

	_outfit_label.text = "当前装扮：%s" % _style_name(style)
	_coin_label.text = "金币：%d" % (Data.get_coins() if Data.has_method("get_coins") else 0)
	_unlock_label.text = "已解锁装扮 %d · 已解锁机器 %d" % [
		Data.unlocked_styles.size(),
		maxi(Data.unlocked_machines.size() - 1, 0),  # DELETE is a built-in placeholder, not a real machine
	]


func _style_name(style: int) -> String:
	if Data.STYLE_UPGRADES.has(style) and Data.STYLE_UPGRADES[style].has("name"):
		return String(Data.STYLE_UPGRADES[style]["name"])
	return "基础"


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = region
	return tex
