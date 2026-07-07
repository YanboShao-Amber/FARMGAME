class_name MerchantTradeUI
extends CanvasLayer

signal closed

const UI_FONT: Font = preload("res://graphics/fonts/HomeVideo-Regular.ttf")
const DARK_TEXT := Color(0.23, 0.13, 0.08, 1)
const MUTED_TEXT := Color(0.35, 0.21, 0.09, 1)
const QUEST_TOGGLE_KEYCODE: int = KEY_J

enum TradeTab {BUY, SELL}

const TAB_BUY := "buy"
const TAB_SELL := "sell"

@onready var root: Control = $Root
@onready var column: VBoxContainer = $Root/Center/Panel/ContentMargin/Column
@onready var title_label: Label = $Root/Center/Panel/ContentMargin/Column/Title
@onready var subtitle_label: Label = $Root/Center/Panel/ContentMargin/Column/Subtitle
@onready var rows_scroll: ScrollContainer = $Root/Center/Panel/ContentMargin/Column/RowsScroll
@onready var rows_box: VBoxContainer = $Root/Center/Panel/ContentMargin/Column/RowsScroll/RowsBox
@onready var close_button: TextureButton = $Root/Center/Panel/CloseButton

var _merchant_id: String = "courier"
var _current_tab: int = TradeTab.BUY
var _tab_bar: HBoxContainer
var _buy_tab_button: Button
var _sell_tab_button: Button
var _status_label: Label
var _coin_label: Label
var _tab_scroll_positions: Dictionary = {
	TAB_BUY: 0,
	TAB_SELL: 0
}
var _visited_tabs: Dictionary = {}


func _ready() -> void:
	_ensure_runtime_controls()
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	close_button.focus_mode = Control.FOCUS_ALL


func is_open() -> bool:
	return root.visible


func reveal(merchant_id: String = "courier", initial_tab: String = TAB_BUY) -> void:
	open_for_merchant(merchant_id, initial_tab)


func open_for_merchant(merchant_id: String = "courier", initial_tab: String = TAB_BUY) -> void:
	if not Data.MERCHANT_CATALOGS.has(merchant_id):
		push_warning("Unknown merchant id: %s" % merchant_id)
		merchant_id = "courier"
	_merchant_id = merchant_id
	_current_tab = _tab_from_name(initial_tab)
	_tab_scroll_positions = {
		TAB_BUY: 0,
		TAB_SELL: 0
	}
	_visited_tabs = {_tab_name(_current_tab): true}
	root.show()
	_rebuild(false)
	await get_tree().process_frame
	_grab_default_focus()


func request_close() -> void:
	_on_close_pressed()


func force_close() -> void:
	root.hide()
	remove_items()


func remove_items() -> void:
	for child in rows_box.get_children():
		rows_box.remove_child(child)
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
		return
	if event is InputEventKey and (event as InputEventKey).physical_keycode == QUEST_TOGGLE_KEYCODE:
		get_viewport().set_input_as_handled()


func _ensure_runtime_controls() -> void:
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 8)
	column.add_child(_tab_bar)
	column.move_child(_tab_bar, 2)

	_buy_tab_button = _make_action_button("Buy")
	_buy_tab_button.pressed.connect(func() -> void: _switch_tab(TradeTab.BUY))
	_tab_bar.add_child(_buy_tab_button)

	_sell_tab_button = _make_action_button("Sell")
	_sell_tab_button.pressed.connect(func() -> void: _switch_tab(TradeTab.SELL))
	_tab_bar.add_child(_sell_tab_button)

	_status_label = _make_label("", 18, MUTED_TEXT)
	column.add_child(_status_label)
	column.move_child(_status_label, 3)

	_coin_label = _make_label("", 20, DARK_TEXT)
	column.add_child(_coin_label)


func _switch_tab(tab: int) -> void:
	if _current_tab == tab:
		return
	_tab_scroll_positions[_tab_name(_current_tab)] = rows_scroll.scroll_vertical
	_current_tab = tab
	var tab_name := _tab_name(_current_tab)
	var has_visited: bool = bool(_visited_tabs.get(tab_name, false))
	_visited_tabs[tab_name] = true
	_status_label.text = ""
	_rebuild(false)
	_restore_view_state({
		"scroll": int(_tab_scroll_positions.get(tab_name, 0)) if has_visited else 0,
		"focus_item": -1,
		"focus_action": "",
		"focus_row": 0
	})


func _rebuild(preserve_state: bool = true) -> void:
	var view_state: Dictionary = _capture_view_state() if preserve_state else {
		"scroll": int(_tab_scroll_positions.get(_tab_name(_current_tab), 0)),
		"focus_item": -1,
		"focus_action": "",
		"focus_row": 0
	}
	_tab_scroll_positions[_tab_name(_current_tab)] = int(view_state.get("scroll", 0))
	remove_items()
	var catalog: Dictionary = Data.MERCHANT_CATALOGS[_merchant_id]
	var merchant_name: String = catalog.get("name", _merchant_id)
	title_label.text = "%s Trade" % merchant_name
	subtitle_label.text = "Buy and sell goods"
	_coin_label.text = "Coins: %d" % Data.get_coins()
	_buy_tab_button.disabled = _current_tab == TradeTab.BUY
	_sell_tab_button.disabled = _current_tab == TradeTab.SELL

	var row_count: int = 0
	if _current_tab == TradeTab.BUY:
		for item in catalog.get("items", []):
			_make_item_row(item, true)
			row_count += 1
		for unlock in catalog.get("unlocks", []):
			_make_unlock_row(unlock)
			row_count += 1
	else:
		for item in Data.TRADEABLE_ITEMS:
			_make_item_row(item, false)
			row_count += 1

	if row_count == 0:
		rows_box.add_child(_make_label("No goods available.", 22, DARK_TEXT))
	_restore_view_state(view_state)


func _make_item_row(item: int, is_buy: bool) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)
	row.add_theme_constant_override("separation", 8)
	rows_box.add_child(row)

	var unit_price: int = Data.get_buy_price(item) if is_buy else Data.get_sell_price(item)
	var owned: int = int(Data.ITEMS_AMOUNT.get(item, 0))
	var can_transact: bool = false
	if unit_price > 0:
		if is_buy:
			can_transact = Data.get_coins() >= unit_price
		else:
			can_transact = owned > 0

	var primary := _make_action_button("")
	_tag_focus_target(primary, item, "primary", rows_box.get_child_count() - 1)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = not can_transact
	primary.pressed.connect(func() -> void: _trade_item(item, 1, is_buy))
	row.add_child(primary)

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_right = -10.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	primary.add_child(content)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = Data.get_item_texture(item)
	content.add_child(icon)

	var name_label := _make_label(Data.get_item_display_name(Data.get_item_id(item)), 21, DARK_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size = Vector2(190, 0)
	content.add_child(name_label)

	var owned_label := _make_label("Owned: %d" % owned, 20, DARK_TEXT)
	owned_label.custom_minimum_size = Vector2(125, 0)
	content.add_child(owned_label)

	var price_label := _make_label(("%s: %d" % ["Buy" if is_buy else "Sell", unit_price]), 20, DARK_TEXT)
	price_label.custom_minimum_size = Vector2(105, 0)
	content.add_child(price_label)

	var coin_icon := TextureRect.new()
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.custom_minimum_size = Vector2(20, 20)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_icon.texture = Data.get_item_texture(Enum.Item.COIN)
	content.add_child(coin_icon)

	var secondary := _make_action_button("Max" if is_buy else "All")
	_tag_focus_target(secondary, item, "secondary", rows_box.get_child_count() - 1)
	secondary.custom_minimum_size = Vector2(96, 0)
	if is_buy:
		secondary.disabled = _max_buy_quantity(item) <= 0
	else:
		secondary.disabled = owned <= 0
	secondary.pressed.connect(func() -> void:
		var amount: int = _max_buy_quantity(item) if is_buy else int(Data.ITEMS_AMOUNT.get(item, 0))
		_trade_item(item, amount, is_buy)
	)
	row.add_child(secondary)


func _make_unlock_row(unlock: Dictionary) -> void:
	var unlock_type: String = unlock.get("type", "")
	var product_id: int = int(unlock.get("id", -1))
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.add_theme_constant_override("separation", 8)
	rows_box.add_child(row)

	var owned: bool = Data.is_unlock_owned(unlock_type, product_id)
	var can_afford: bool = _can_afford_unlock(unlock_type, product_id)
	var buy_button := _make_action_button("")
	_tag_focus_target(buy_button, product_id, "unlock", rows_box.get_child_count() - 1)
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button.disabled = owned or not can_afford
	buy_button.pressed.connect(func() -> void: _buy_unlock(unlock_type, product_id))
	row.add_child(buy_button)

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_right = -10.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	buy_button.add_child(content)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = Data.get_unlock_texture(unlock_type, product_id)
	content.add_child(icon)

	var name_label := _make_label(Data.get_unlock_display_name(unlock_type, product_id), 22, DARK_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(name_label)

	var cost_label := _make_label(_format_unlock_cost(unlock_type, product_id), 18, DARK_TEXT)
	cost_label.custom_minimum_size = Vector2(230, 0)
	content.add_child(cost_label)


func _trade_item(item: int, quantity: int, is_buy: bool) -> void:
	if quantity <= 0:
		return
	if is_buy:
		var bought: int = Data.try_buy_item(item, quantity, _merchant_id)
		if bought > 0:
			_status_label.text = "Bought %d %s." % [bought, Data.get_item_display_name(Data.get_item_id(item))]
		else:
			_status_label.text = "Cannot buy."
	else:
		var earned: int = Data.try_sell_item(item, quantity, _merchant_id)
		if earned > 0:
			_status_label.text = "Sold for %d coins." % earned
		else:
			_status_label.text = "Cannot sell."
	_rebuild()


func _buy_unlock(unlock_type: String, product_id: int) -> void:
	var bought: bool = Data.try_buy_unlock(_merchant_id, unlock_type, product_id)
	_status_label.text = "Purchased." if bought else "Cannot purchase."
	_rebuild()


func _max_buy_quantity(item: int) -> int:
	var unit_price: int = Data.get_buy_price(item)
	if unit_price <= 0:
		return 0
	return int(floor(float(Data.get_coins()) / float(unit_price)))


func _can_afford_unlock(unlock_type: String, product_id: int) -> bool:
	var coin_cost: int = Data.get_unlock_coin_cost(unlock_type, product_id)
	if coin_cost <= 0 or Data.get_coins() < coin_cost:
		return false
	var resource_costs: Dictionary = Data.get_unlock_resource_costs(unlock_type, product_id)
	for item in resource_costs:
		if int(Data.ITEMS_AMOUNT.get(item, 0)) < int(resource_costs[item]):
			return false
	return true


func _format_unlock_cost(unlock_type: String, product_id: int) -> String:
	var parts: Array[String] = ["%d Coin" % Data.get_unlock_coin_cost(unlock_type, product_id)]
	var resources: Dictionary = Data.get_unlock_resource_costs(unlock_type, product_id)
	for item in resources:
		parts.append("%d %s" % [int(resources[item]), Data.get_item_display_name(Data.get_item_id(item))])
	return " + ".join(PackedStringArray(parts))


func _grab_default_focus() -> void:
	for row in rows_box.get_children():
		if row is HBoxContainer and row.get_child_count() > 0:
			var button := row.get_child(0) as Button
			if button != null and not button.disabled:
				button.grab_focus()
				return
	if not _buy_tab_button.disabled:
		_buy_tab_button.grab_focus()
	elif not _sell_tab_button.disabled:
		_sell_tab_button.grab_focus()
	else:
		close_button.grab_focus()


func _capture_view_state() -> Dictionary:
	var focus_owner := get_viewport().gui_get_focus_owner()
	var focus_item: int = -1
	var focus_action: String = ""
	var focus_row: int = 0
	if focus_owner != null:
		focus_item = int(focus_owner.get_meta("trade_item", -1))
		focus_action = String(focus_owner.get_meta("trade_action", ""))
		focus_row = int(focus_owner.get_meta("trade_row", 0))
	return {
		"scroll": rows_scroll.scroll_vertical,
		"focus_item": focus_item,
		"focus_action": focus_action,
		"focus_row": focus_row
	}


func _restore_view_state(view_state: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll_bar := rows_scroll.get_v_scroll_bar()
	var max_scroll: int = int(maxf(0.0, scroll_bar.max_value - scroll_bar.page))
	rows_scroll.scroll_vertical = clampi(int(view_state.get("scroll", 0)), 0, max_scroll)
	if not _restore_focus(view_state):
		_grab_nearby_focus(int(view_state.get("focus_row", 0)))


func _restore_focus(view_state: Dictionary) -> bool:
	var focus_item: int = int(view_state.get("focus_item", -1))
	var focus_action: String = String(view_state.get("focus_action", ""))
	if focus_item == -1:
		return false

	var same_item_fallback: Button = null
	for row in rows_box.get_children():
		for child in row.get_children():
			var button := child as Button
			if button == null or button.disabled:
				continue
			if int(button.get_meta("trade_item", -1)) != focus_item:
				continue
			if String(button.get_meta("trade_action", "")) == focus_action:
				button.grab_focus()
				return true
			if same_item_fallback == null:
				same_item_fallback = button
	if same_item_fallback != null:
		same_item_fallback.grab_focus()
		return true
	return false


func _grab_nearby_focus(row_index: int) -> void:
	var rows: Array = rows_box.get_children()
	if rows.is_empty():
		_grab_default_focus()
		return
	var start_index: int = clampi(row_index, 0, rows.size() - 1)
	for offset in range(rows.size()):
		var lower_index: int = start_index - offset
		if lower_index >= 0 and _grab_focus_in_row(rows[lower_index]):
			return
		var upper_index: int = start_index + offset
		if upper_index != lower_index and upper_index < rows.size() and _grab_focus_in_row(rows[upper_index]):
			return
	_grab_default_focus()


func _grab_focus_in_row(row: Node) -> bool:
	for child in row.get_children():
		var button := child as Button
		if button != null and not button.disabled:
			button.grab_focus()
			return true
	return false


func _tag_focus_target(button: Button, item: int, action: String, row_index: int) -> void:
	button.set_meta("trade_item", item)
	button.set_meta("trade_action", action)
	button.set_meta("trade_row", row_index)


func _tab_name(tab: int) -> String:
	return TAB_SELL if tab == TradeTab.SELL else TAB_BUY


func _tab_from_name(tab_name: String) -> int:
	return TradeTab.SELL if tab_name.to_lower() == TAB_SELL else TradeTab.BUY


func _on_close_pressed() -> void:
	if not root.visible:
		return
	root.hide()
	remove_items()
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	closed.emit()


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	_style_button(button)
	return button


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
