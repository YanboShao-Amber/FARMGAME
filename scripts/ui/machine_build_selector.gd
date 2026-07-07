extends CanvasLayer
## Machine Build Selector (Phase H1). Lists the three placeable machines with icon,
## name, and per-material owned/required counts. A row is selectable only when its
## blueprint is unlocked AND the player owns enough materials; otherwise it is shown
## disabled (locked or short on materials). All state is read from Data — no prices,
## recipes, or inventory counts are duplicated here.
##
## Selecting a machine emits `machine_selected`; the level then enters placement mode
## (this panel hides and shows the placement hint). Closing emits `closed`.

signal machine_selected(machine_id: int)
signal closed

const UI_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")
const DARK_TEXT := Color(0.23, 0.13, 0.08, 1)
const MUTED_TEXT := Color(0.5, 0.42, 0.34, 1)
const SHORT_TEXT := Color(0.7, 0.18, 0.12, 1)
const QUEST_TOGGLE_KEYCODE: int = KEY_J

# Placement priority order: Sprinkler, Fisher, Scarecrow.
const MACHINES: Array = [Enum.Machine.SPRINKLER, Enum.Machine.FISHER, Enum.Machine.SCARECROW]

@onready var root: Control = $Root
@onready var rows_box: VBoxContainer = $Root/Center/Panel/ContentMargin/Column/RowsBox
@onready var close_button: TextureButton = $Root/Center/Panel/CloseButton
@onready var placement_hint: Control = $PlacementHint

var _row_buttons: Array = []


func _ready() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	close_button.focus_mode = Control.FOCUS_ALL


func is_open() -> bool:
	return root.visible


func reveal() -> void:
	placement_hint.hide()
	_build_rows()
	root.show()
	await get_tree().process_frame
	_grab_default_focus()


# Panel hides; a compact "place / cancel / move" hint shows during placement mode.
func show_placement_hint() -> void:
	root.hide()
	placement_hint.show()


func hide_all() -> void:
	root.hide()
	placement_hint.hide()
	_clear_rows()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
		return
	# Don't let the quest tracker toggle while this modal is open.
	if event is InputEventKey and (event as InputEventKey).physical_keycode == QUEST_TOGGLE_KEYCODE:
		get_viewport().set_input_as_handled()


# =========================================================
# Rows
# =========================================================
func _build_rows() -> void:
	_clear_rows()
	for machine in MACHINES:
		_make_row(machine)


func _clear_rows() -> void:
	for child in rows_box.get_children():
		child.queue_free()
	_row_buttons.clear()


func _make_row(machine: int) -> void:
	var unlocked: bool = machine in Data.unlocked_machines
	var costs: Dictionary = Data.MACHINE_PLACEMENT_COSTS.get(machine, {})
	var category_costs: Dictionary = Data.MACHINE_CATEGORY_COSTS.get(machine, {})
	var affordable: bool = Data.can_afford_machine_placement_costs(machine)
	var selectable: bool = unlocked and affordable

	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.focus_mode = Control.FOCUS_ALL
	row.disabled = not selectable
	_style_button(row)
	row.pressed.connect(func() -> void: _on_row_pressed(machine))
	rows_box.add_child(row)
	_row_buttons.append(row)

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_right = -10.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	row.add_child(content)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = _machine_icon(machine)
	content.add_child(icon)

	var name_label := _make_label(_machine_name(machine), 22, DARK_TEXT if selectable else MUTED_TEXT)
	name_label.custom_minimum_size = Vector2(140, 0)
	content.add_child(name_label)

	# Material chips: [item icon][owned/required], red when short.
	for item in costs:
		var required: int = int(costs[item])
		_add_item_cost_chip(content, item, required, selectable)
	for category_id in category_costs:
		var required: int = int(category_costs[category_id])
		_add_category_cost_chip(content, category_id, required, selectable)

	var status := _make_label("", 20, MUTED_TEXT)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not unlocked:
		status.text = "未解锁"
	elif not affordable:
		status.text = "材料不足"
	content.add_child(status)


func _can_afford(costs: Dictionary) -> bool:
	for item in costs:
		if int(Data.ITEMS_AMOUNT.get(item, 0)) < int(costs[item]):
			return false
	return true


func _add_item_cost_chip(content: HBoxContainer, item: int, required: int, selectable: bool) -> void:
	var owned: int = int(Data.ITEMS_AMOUNT.get(item, 0))
	var chip := _make_cost_chip()
	var mat_icon := _make_cost_icon()
	mat_icon.texture = Data.get_item_texture(item)
	chip.add_child(mat_icon)
	var enough: bool = owned >= required
	var chip_color: Color = (DARK_TEXT if selectable else MUTED_TEXT) if enough else SHORT_TEXT
	chip.add_child(_make_label("%d/%d" % [owned, required], 20, chip_color))
	content.add_child(chip)


func _add_category_cost_chip(content: HBoxContainer, category_id: StringName, required: int, selectable: bool) -> void:
	var owned: int = Data.get_total_category_amount(category_id)
	var chip := _make_cost_chip()
	var mat_icon := _make_cost_icon()
	var icon_item: int = Data.get_category_icon_item(category_id)
	if icon_item != -1:
		mat_icon.texture = Data.get_item_texture(icon_item)
	chip.add_child(mat_icon)
	var enough: bool = owned >= required
	var chip_color: Color = (DARK_TEXT if selectable else MUTED_TEXT) if enough else SHORT_TEXT
	chip.add_child(_make_label("%s %d/%d" % [
		Data.get_category_display_name(category_id),
		owned,
		required
	], 20, chip_color))
	content.add_child(chip)


func _make_cost_chip() -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_constant_override("separation", 3)
	return chip


func _make_cost_icon() -> TextureRect:
	var mat_icon := TextureRect.new()
	mat_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mat_icon.custom_minimum_size = Vector2(20, 20)
	mat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mat_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return mat_icon


func _machine_icon(machine: int) -> Texture2D:
	if Data.MACHINE_UPGRADE_COST.has(machine) and Data.MACHINE_UPGRADE_COST[machine].has("icon"):
		return Data.MACHINE_UPGRADE_COST[machine]["icon"]
	return Data.MACHINE_TEXTURES.get(machine, null)


func _machine_name(machine: int) -> String:
	if Data.MACHINE_UPGRADE_COST.has(machine) and Data.MACHINE_UPGRADE_COST[machine].has("name"):
		return Data.MACHINE_UPGRADE_COST[machine]["name"]
	return String(Enum.Machine.keys()[machine]).capitalize()


func _grab_default_focus() -> void:
	for btn in _row_buttons:
		if is_instance_valid(btn) and not (btn as Button).disabled:
			(btn as Button).grab_focus()
			return
	close_button.grab_focus()


func _on_row_pressed(machine: int) -> void:
	machine_selected.emit(machine)


func _on_close_pressed() -> void:
	hide_all()
	closed.emit()


# =========================================================
# Helpers (shared visual language with the Sell / Quest panels)
# =========================================================
func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", DARK_TEXT)
	button.add_theme_color_override("font_hover_color", Color(0.12, 0.07, 0.04, 1))
	button.add_theme_color_override("font_focus_color", Color(0.12, 0.07, 0.04, 1))
	button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
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
