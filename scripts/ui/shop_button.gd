extends Button

var item_enum: int
var shop_type: Enum.Shop

@onready var cost_parent: HBoxContainer = $VBoxContainer/VBoxContainer/Control/HBoxContainer
@onready var color_rect: ColorRect = $VBoxContainer/ColorRect
@onready var texture_rect: TextureRect = $VBoxContainer/ColorRect/TextureRect
@onready var name_label: Label = $VBoxContainer/VBoxContainer/Label

signal press(shop_type: Enum.Shop)

func setup(new_item_enum: int, parent_node: Node, new_shop_type: Enum.Shop) -> void:	
	item_enum = new_item_enum
	shop_type = new_shop_type
	
	parent_node.add_child(self)
	
	var source = Data.STYLE_UPGRADES if shop_type == Enum.Shop.HAT else Data.MACHINE_UPGRADE_COST
	var data = source[item_enum]
		
	
	texture_rect.texture = data["icon"]
	color_rect.color = data["color"]
	name_label.text = data["name"]

	var display_costs: Dictionary = _get_display_costs()
	for cost_item_enum in display_costs:
		var cost = display_costs[cost_item_enum]
		
		var hbox = HBoxContainer.new()
		var cost_texture = TextureRect.new()
		var cost_label = Label.new()
		
		cost_texture.texture = Data.get_item_texture(cost_item_enum as Enum.Item)
		cost_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_texture.custom_minimum_size = Vector2(30, 30)
		
		cost_label.text = str(cost)
		cost_label.add_theme_font_size_override("font_size", 30)  # 16 pixels
		
		hbox.add_child(cost_texture)
		hbox.add_child(cost_label)
		cost_parent.add_child(hbox)


func _on_focus_entered() -> void:
	$BG.theme_type_variation = "FocusPanel"


func _on_focus_exited() -> void:
	$BG.theme_type_variation = ""


func _on_pressed() -> void:
	var unlocked_list: Array = Data.shop_connection[shop_type]["tracker"]
	if item_enum in unlocked_list:
		push_warning("Product is already unlocked: %s" % item_enum)
		return

	if not _has_purchase_configuration():
		if shop_type == Enum.Shop.MAIN:
			push_warning("Missing machine blueprint coin cost for machine id: %s" % item_enum)
		else:
			push_warning("Missing style purchase configuration for style id: %s" % item_enum)
		return

	var coin_cost: int = _get_coin_cost()
	if coin_cost <= 0:
		return

	var resource_costs: Dictionary = _get_resource_costs()
	if not _can_afford_purchase(coin_cost, resource_costs):
		return

	if not _deduct_purchase_cost(coin_cost, resource_costs):
		return
		
	unlocked_list.append(item_enum)
	var telemetry_source: String = _get_purchase_telemetry_source()
	if not telemetry_source.is_empty():
		Data.record_playtest_purchase(telemetry_source, telemetry_source, coin_cost, resource_costs)
	press.emit(shop_type)


func _get_coin_cost() -> int:
	if shop_type == Enum.Shop.MAIN:
		if not Data.MACHINE_BLUEPRINT_COIN_COSTS.has(item_enum):
			push_warning("Missing machine blueprint coin cost for machine id: %s" % item_enum)
			return -1
		var machine_coin_cost: int = int(Data.MACHINE_BLUEPRINT_COIN_COSTS[item_enum])
		if machine_coin_cost <= 0:
			push_warning("Machine blueprint coin cost must be greater than zero for machine id: %s" % item_enum)
			return -1
		return machine_coin_cost

	if not Data.STYLE_COIN_COSTS.has(item_enum):
		push_warning("Missing style coin cost for style id: %s" % item_enum)
		return -1
	var style_coin_cost: int = int(Data.STYLE_COIN_COSTS[item_enum])
	if style_coin_cost <= 0:
		push_warning("Style coin cost must be greater than zero for style id: %s" % item_enum)
		return -1
	return style_coin_cost


func _has_purchase_configuration() -> bool:
	if shop_type == Enum.Shop.MAIN:
		return Data.MACHINE_BLUEPRINT_COIN_COSTS.has(item_enum)

	return Data.STYLE_COIN_COSTS.has(item_enum) and Data.STYLE_RESOURCE_COSTS.has(item_enum)


func _get_resource_costs() -> Dictionary:
	if shop_type == Enum.Shop.MAIN:
		return {}

	if not Data.STYLE_RESOURCE_COSTS.has(item_enum):
		push_warning("Missing style resource cost for style id: %s" % item_enum)
		return {}
	return Data.STYLE_RESOURCE_COSTS[item_enum]


func _get_purchase_telemetry_source() -> String:
	if shop_type == Enum.Shop.MAIN:
		return Data.MACHINE_BLUEPRINT_TELEMETRY_SOURCES.get(item_enum, "")
	return Data.STYLE_PURCHASE_TELEMETRY_SOURCES.get(item_enum, "")


func _get_display_costs() -> Dictionary:
	if not _has_purchase_configuration():
		if shop_type == Enum.Shop.MAIN:
			push_warning("Missing machine blueprint coin cost for machine id: %s" % item_enum)
		else:
			push_warning("Missing style purchase configuration for style id: %s" % item_enum)
		return {}

	var coin_cost: int = _get_coin_cost()
	if coin_cost <= 0:
		return {}

	var display_costs: Dictionary = {
		Enum.Item.COIN: coin_cost
	}

	var resource_costs: Dictionary = _get_resource_costs()
	for resource_item in resource_costs:
		display_costs[resource_item] = resource_costs[resource_item]

	return display_costs


func _can_afford_purchase(coin_cost: int, resource_costs: Dictionary) -> bool:
	if Data.get_coins() < coin_cost:
		print("Not enough coins to unlock product.")
		return false

	for item in resource_costs:
		var cost: int = int(resource_costs[item])
		if cost <= 0:
			push_warning("Resource cost must be greater than zero: item=%s, cost=%s" % [item, cost])
			return false
		var current_amount: int = int(Data.ITEMS_AMOUNT.get(item, 0))
		if current_amount < cost:
			print("Not enough resource: item=%s, required=%s, current=%s" % [item, cost, current_amount])
			return false

	return true


func _deduct_purchase_cost(coin_cost: int, resource_costs: Dictionary) -> bool:
	if not Data.spend_coins(coin_cost):
		return false

	for item in resource_costs:
		Data.ITEMS_AMOUNT[item] -= int(resource_costs[item])

	return true
