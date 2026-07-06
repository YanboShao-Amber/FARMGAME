extends CanvasLayer
## Sell panel opened by the Courier. Lists every whitelisted sellable item as a row
## (icon | name | owned | unit price + coin). Clicking a row's "Sell" button sells one;
## "Sell All" sells the whole stack. All coin/inventory changes go through the single
## atomic Data.try_sell_item(); this UI never mutates ITEMS_AMOUNT or coins directly.
##
## Modal: own CanvasLayer (layer 21, above the quest tracker) with a full-screen Dim
## that stops mouse input, and it swallows the quest-panel toggle key while open.

signal closed

const UI_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")
const DARK_TEXT := Color(0.23, 0.13, 0.08, 1)
const QUEST_TOGGLE_KEYCODE: int = KEY_J  # mirror QuestTracker.TOGGLE_KEY to block conflicts

@onready var root: Control = $Root
@onready var rows_box: VBoxContainer = $Root/Center/Panel/ContentMargin/Column/RowsBox
@onready var close_button: TextureButton = $Root/Center/Panel/CloseButton

# item(Enum.Item) -> {"owned": Label, "sell_one": Button, "sell_all": Button}
var _row_widgets: Dictionary = {}


func _ready() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	close_button.focus_mode = Control.FOCUS_ALL


func is_open() -> bool:
	return root.visible


func reveal() -> void:
	_build_rows()
	root.show()
	_refresh()
	await get_tree().process_frame
	_grab_default_focus()


func remove_items() -> void:
	for child in rows_box.get_children():
		child.queue_free()
	_row_widgets.clear()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
		return
	# Prevent other HUD panels (e.g. the quest tracker) from toggling while the
	# sell panel is the active modal.
	if event is InputEventKey and (event as InputEventKey).physical_keycode == QUEST_TOGGLE_KEYCODE:
		get_viewport().set_input_as_handled()


# =========================================================
# Row construction
# =========================================================
func _build_rows() -> void:
	remove_items()
	for item in Data.SELLABLE_ITEMS:
		_row_widgets[item] = _make_row(item)


func _make_row(item: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)
	row.add_theme_constant_override("separation", 8)
	rows_box.add_child(row)

	# The row body is a "Sell one" button holding the icon/name/owned/price.
	var sell_one := Button.new()
	sell_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_one.focus_mode = Control.FOCUS_ALL
	_style_button(sell_one)
	sell_one.pressed.connect(func() -> void: _on_sell_one(item))
	row.add_child(sell_one)

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_right = -10.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	sell_one.add_child(content)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = Data.get_item_texture(item)
	content.add_child(icon)

	var name_label := _make_label(Data.get_item_display_name(Data.get_item_id(item)), 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(name_label)

	var owned_label := _make_label("", 22)
	owned_label.custom_minimum_size = Vector2(70, 0)
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(owned_label)

	var price_label := _make_label(str(Data.get_sell_price(item)), 24)
	price_label.custom_minimum_size = Vector2(56, 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(price_label)

	var coin_icon := TextureRect.new()
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.custom_minimum_size = Vector2(20, 20)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_icon.texture = Data.get_item_texture(Enum.Item.COIN)
	content.add_child(coin_icon)

	var sell_all := Button.new()
	sell_all.custom_minimum_size = Vector2(96, 0)
	sell_all.focus_mode = Control.FOCUS_ALL
	sell_all.text = "全卖 All"
	_style_button(sell_all)
	sell_all.pressed.connect(func() -> void: _on_sell_all(item))
	row.add_child(sell_all)

	return {"owned": owned_label, "sell_one": sell_one, "sell_all": sell_all}


# =========================================================
# Transactions (always via Data.try_sell_item)
# =========================================================
func _on_sell_one(item: int) -> void:
	Data.try_sell_item(item, 1)
	_refresh()


func _on_sell_all(item: int) -> void:
	var owned: int = int(Data.ITEMS_AMOUNT.get(item, 0))
	if owned <= 0:
		return
	Data.try_sell_item(item, owned)
	_refresh()


func _refresh() -> void:
	for item in _row_widgets:
		var widgets: Dictionary = _row_widgets[item]
		var owned: int = int(Data.ITEMS_AMOUNT.get(item, 0))
		(widgets["owned"] as Label).text = "x%d" % owned
		(widgets["sell_one"] as Button).disabled = owned <= 0
		(widgets["sell_all"] as Button).disabled = owned <= 0
	# If focus landed on a now-disabled button, move it somewhere valid.
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or (focused is Button and (focused as Button).disabled):
		_grab_default_focus()


func _grab_default_focus() -> void:
	for item in Data.SELLABLE_ITEMS:
		if _row_widgets.has(item):
			var btn := _row_widgets[item]["sell_one"] as Button
			if not btn.disabled:
				btn.grab_focus()
				return
	close_button.grab_focus()


func _on_close_pressed() -> void:
	root.hide()
	remove_items()
	closed.emit()


# Hide without emitting `closed` (used for defensive external teardown).
func force_close() -> void:
	root.hide()
	remove_items()


# =========================================================
# Helpers
# =========================================================
func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", DARK_TEXT)
	return label


func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", DARK_TEXT)
	button.add_theme_color_override("font_hover_color", Color(0.12, 0.07, 0.04, 1))
	button.add_theme_color_override("font_focus_color", Color(0.12, 0.07, 0.04, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.42, 0.34, 1))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.82, 0.66, 0.47, 1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.9, 0.76, 0.56, 1)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.74, 0.58, 0.4, 1)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.9, 0.76, 0.56, 1)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.78, 0.68, 0.56, 1)))


func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.48, 0.27, 0.15, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style
