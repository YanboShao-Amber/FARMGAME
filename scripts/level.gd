extends Node2D

@onready var player: CharacterBody2D = $Objects/Player

@onready var waterGrassLayer := $Layers/WaterGrassLayer

var projectile_scene = preload("res://scenes/machines/projectile.tscn")
var machine_coord: Vector2
var machine_cells: Array[Vector2i]
signal delete_machine(coord: Vector2i)

# Phase H1: main-farm slime spawning is disabled (kept for future combat areas).
const FARM_SLIME_ENABLED: bool = false

# Phase H1: machine build/placement flow (Build Selector -> preview -> confirm/cancel).
var build_selector: CanvasLayer
var _placement_active: bool = false
var _placement_machine: int = Enum.Machine.DELETE
var _placement_cursor: Vector2i = Vector2i.ZERO
var _last_mouse_cell: Vector2i = Vector2i(-9999, -9999)
var _active_trade_merchant_id: String = ""
var _placement_ignore_confirm_until_mouse_release: bool = false
const PLACEMENT_VALID_TINT: Color = Color(0.5, 1.0, 0.5, 0.6)
const PLACEMENT_INVALID_TINT: Color = Color(1.0, 0.4, 0.4, 0.6)


# Refer to a tileset
const target_highlight_green: Vector2i = Vector2i(12, 1)
const target_highlight_red: Vector2i = Vector2i(1, 1)

# Plant
var plant_scene = preload("res://scenes/objects/plant.tscn")
var planted_cells: Array[Vector2i]
var plant_info_scene = preload("res://scenes/ui/plant_info.tscn")
var blob_scene = preload("res://scenes/characters/blob_enemy.tscn")


# Day and Weather
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@export var daytimer_color: Gradient
@export var rain_color: Color
var raining: bool = false:
	set(value):
		raining = value
		$Layers/RainFloorsParticles.emitting = value
		$Overlay/RainParticles2D.emitting = value
		
signal update_hint_ui_keys
		
func _process(_delta):
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytimer_color.sample(daytime_point)
	
	if raining:
		color = color.lerp(rain_color, 1 - daytime_point)
	$Overlay/CanvasModulate.color = color
	
	if Data.TARGET_HIGHLIGHTER:
		update_target_highlight()
	else:
		$Layers/TargetLayer.clear()
		
	var preview: Sprite2D = $Overlay/PreviewMachineSprite2D
	preview.visible = _placement_active
	if _placement_active:
		# Mouse drives the cursor when it moves; directional keys nudge it (see input).
		var mouse_cell: Vector2i = _world_to_grid(get_global_mouse_position())
		if mouse_cell != _last_mouse_cell:
			_last_mouse_cell = mouse_cell
			_placement_cursor = mouse_cell
		machine_coord = _placement_cursor
		preview.position = (Vector2i(_placement_cursor * Data.TILE_SIZE) +
							Data.MACHINE_PREVIEW_TEXTURES[_placement_machine]["offset"])
		preview.modulate = PLACEMENT_VALID_TINT if _can_place_machine(_placement_machine, _placement_cursor) else PLACEMENT_INVALID_TINT


# =========================================================
# Todo: Disable keys during day restart
# Day Night Cycle
# =========================================================
func _on_player_day_change() -> void:
	day_restart()


func day_restart():
	var tween = create_tween()
	
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_interval(0.5)
	tween.tween_callback(level_reset)
	tween.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset():
	Data.record_playtest_day_end(
		Data.CURRENT_DAY_ID,
		get_tree().get_nodes_in_group("Plants").size(),
		machine_cells.size()
	)
	Data.advance_game_day()
	for plant: StaticBody2D in get_tree().get_nodes_in_group("Plants"):
		plant.grow(plant.coord in $Layers/WetSoilLayer.get_used_cells())
			
	$Timers/DayTimer.start()
	$Layers/WetSoilLayer.clear()
	
	for object in get_tree().get_nodes_in_group("Objects"):
		# 50% that apples number not changing
		if not object.is_in_group("Tree") or [false, true].pick_random():
			continue
			
			
		object.create_apple()

	raining = Data.FORECAST_RAIN
	Data.FORECAST_RAIN = [true, false].pick_random()
	print("Tommorw will rain" if Data.FORECAST_RAIN else "Tommorow is sunny")
	
	if raining:
		waterSoils()


func waterSoils():
	for cell in $Layers/SoilLayer.get_used_cells():
		$Layers/WetSoilLayer.set_cell(
				cell,
				0,
				Vector2i(randi_range(0, 2), 0)
			)


func _on_water_all_button_pressed() -> void:
	waterSoils()


# =========================================================
# TOOL USE
# =========================================================
func _on_player_tool_use(tool: Enum.Tool, pos: Vector2, dir: Vector2) -> void:
	var grid_coord: Vector2i = get_target_grid(pos, dir)

	if grid_coord in machine_cells:
		return
	# already checked in _on_player_do_action
	#if not is_tool_valid(tool, grid_coord):
		#return

	match tool:
		Enum.Tool.HOE:
			#$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 0)
			$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 1)	
			if raining:
				$Layers/WetSoilLayer.set_cell(
					grid_coord,
					0,
					Vector2i(randi_range(0, 2), 0)
				)

		Enum.Tool.WATER:
			$Layers/WetSoilLayer.set_cell(
				grid_coord,
				0,
				Vector2i(randi_range(0, 2), 0)
			)

		Enum.Tool.FISH:
			$Objects/Player.start_fishing()
			
		Enum.Tool.SEED:
			var current_seed: int = %Player.current_seed
			var seed_item = Data.SEED_TO_SEED_ITEM.get(current_seed)
			if seed_item == null:
				push_warning("Missing seed item mapping for seed id: %s" % current_seed)
				return

			var seed_amount: int = int(Data.ITEMS_AMOUNT.get(seed_item, 0))
			if seed_amount <= 0:
				return

			if not is_tool_valid(Enum.Tool.SEED, grid_coord):
				return

			var plant_res = PlantResource.new()
			plant_res.setup(current_seed)
			var plant := plant_scene.instantiate()
			
			# Plant Info
			var plant_info = plant_info_scene.instantiate()
			plant_info.setup(plant_res)
			$Overlay/CanvasLayer/PlantInfoControl.add(plant_info)
			
			plant.setup(grid_coord, $Objects, plant_res, plant_info,
						 plant_death, plant_harvest)
			planted_cells.append(grid_coord)
			Data.ITEMS_AMOUNT[seed_item] -= 1
		Enum.Tool.AXE:
			for object in get_tree().get_nodes_in_group("Axe_able"):
				var to_object = (object.position - pos)
	
				if to_object.length() < 22:
					var to_object_dir = to_object.normalized()
					
					# dot > 0 means in front, closer to 1 means more aligned
					if dir.dot(to_object_dir) > 0.65:
						object.hit(tool, dir)
		Enum.Tool.SWORD:
			for object in get_tree().get_nodes_in_group("Sword_able"):
				var to_object = (object.position - pos)
	
				if to_object.length() < 26:
					var to_object_dir = to_object.normalized()
					
					# dot > 0 means in front, closer to 1 means more aligned
					if dir.dot(to_object_dir) > 0.65:
						object.hit(tool, dir)


func _on_player_diagnose() -> void:
	$Overlay/CanvasLayer/PlantInfoControl.visible = not $Overlay/CanvasLayer/PlantInfoControl.visible 


func _ready() -> void:
	Data.FORECAST_RAIN = [true, false].pick_random()
	if raining:
		waterSoils()
		
	# Add CanvasModulate for darkness
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.1, 0.1, 0.15)
	add_child(canvas_modulate)
	
	#$Objects/ScareCrow.connect("shoot_projectile", create_projectile)
	for character in get_tree().get_nodes_in_group("ShopCharacters"):
		character.connect("open_shop", open_shop)

	_connect_courier_seller()

	if not FARM_SLIME_ENABLED:
		$Timers/BlobTimer.stop()

	_setup_build_selector()

	# Connect to device connection signals
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	if Input.get_connected_joypads().size() > 0:
		print("True")
		Data.ControllerConnected = true

# Projectile
func create_projectile(start_pos: Vector2, dir: Vector2):
	var projectile = projectile_scene.instantiate()
	$Objects.add_child(projectile)
	projectile.setup(start_pos, dir)


# Legacy signal handler kept for the scene connection; the Phase H1 flow drives
# placement through _try_place_machine() instead.
func _on_player_build(curr_machine: int) -> void:
	pass


# Atomic placement. Order: valid position -> resources available -> scene instantiates
# -> register cell -> deduct materials once -> record telemetry. Any failure deducts
# nothing, occupies no cell, records no telemetry. Returns true only on success.
func _try_place_machine(curr_machine: int, grid_coord: Vector2i) -> bool:
	if curr_machine == Enum.Machine.DELETE:
		return false
	if not _can_place_machine(curr_machine, grid_coord):
		return false
	var cost_plan: Dictionary = Data.build_machine_placement_cost_plan(curr_machine)
	if not bool(cost_plan.get("success", false)):
		return false

	var machine = Data.MACHINE_SCENE[curr_machine]["scene"].instantiate()
	if not machine is Machine:
		push_warning("Machine scene did not instantiate a Machine for machine id: %s" % curr_machine)
		_discard_failed_machine_instance(machine)
		return false

	var setup_succeeded: bool = machine.setup(grid_coord, self, $Objects/Machines)
	if not setup_succeeded:
		_discard_failed_machine_instance(machine)
		return false

	self.connect("delete_machine", machine.delete)
	machine_cells.append(grid_coord)
	if not Data.consume_machine_placement_cost_plan(cost_plan):
		self.disconnect("delete_machine", machine.delete)
		machine_cells.erase(grid_coord)
		_discard_failed_machine_instance(machine)
		return false

	var telemetry_source: String = Data.MACHINE_PLACEMENT_TELEMETRY_SOURCES.get(curr_machine, "")
	if not telemetry_source.is_empty():
		Data.record_playtest_machine_placement(
			telemetry_source,
			curr_machine,
			cost_plan["item_costs"],
			grid_coord,
			cost_plan["category_costs"],
			cost_plan["category_consumption"]
		)
	return true


# =========================================================
# Phase H1 — Build Selector + Placement Mode
# =========================================================
func _setup_build_selector() -> void:
	var scene: PackedScene = load("res://scenes/ui/machine_build_selector.tscn")
	build_selector = scene.instantiate()
	add_child(build_selector)
	build_selector.machine_selected.connect(_on_build_machine_selected)
	build_selector.closed.connect(_on_build_selector_closed)
	if not player.open_build_selector.is_connected(_open_build_selector):
		player.open_build_selector.connect(_open_build_selector)


func _open_build_selector() -> void:
	# Only from normal play; never on top of another modal / locked state.
	if player.current_state != Enum.State.DEFAULT:
		return
	if _placement_active:
		return
	player.current_state = Enum.State.BUILDING
	Data.TARGET_HIGHLIGHTER = false
	$Layers/TargetLayer.clear()
	build_selector.reveal()


func _on_build_selector_closed() -> void:
	# Selector dismissed without choosing a machine -> back to normal play.
	if _placement_active:
		return
	player.current_state = Enum.State.DEFAULT


func _on_build_machine_selected(machine_id: int) -> void:
	_enter_placement(machine_id)


func _enter_placement(machine_id: int) -> void:
	_placement_active = true
	_placement_machine = machine_id
	_placement_ignore_confirm_until_mouse_release = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	$Overlay/PreviewMachineSprite2D.texture = Data.MACHINE_PREVIEW_TEXTURES[machine_id]["texture"]
	_placement_cursor = get_target_grid(player.position, player.animation_direction)
	_last_mouse_cell = Vector2i(-9999, -9999)
	build_selector.show_placement_hint()


func _confirm_placement() -> void:
	if not _placement_active:
		return
	if _try_place_machine(_placement_machine, _placement_cursor):
		# Success: exit placement so the player can't accidentally chain-place.
		_exit_build_mode()


func _cancel_placement() -> void:
	_exit_build_mode()


# Fully leaves the build flow: clears preview, selector, and restores control.
func _exit_build_mode() -> void:
	_placement_active = false
	_placement_machine = Enum.Machine.DELETE
	_placement_ignore_confirm_until_mouse_release = false
	$Overlay/PreviewMachineSprite2D.visible = false
	if build_selector != null:
		build_selector.hide_all()
	if player.current_state == Enum.State.BUILDING:
		player.current_state = Enum.State.DEFAULT


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / Data.TILE_SIZE), floor(world_pos.y / Data.TILE_SIZE))


func _input(event: InputEvent) -> void:
	if not _placement_active:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			if not mouse_event.pressed:
				_placement_ignore_confirm_until_mouse_release = false
				return
			if _placement_ignore_confirm_until_mouse_release:
				return
			_confirm_placement()
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			get_viewport().set_input_as_handled()
			_cancel_placement()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not _placement_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel_placement()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		_confirm_placement()
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_placement_cursor += Vector2i.LEFT
		_last_mouse_cell = _placement_cursor
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_placement_cursor += Vector2i.RIGHT
		_last_mouse_cell = _placement_cursor
	elif event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_placement_cursor += Vector2i.UP
		_last_mouse_cell = _placement_cursor
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_placement_cursor += Vector2i.DOWN
		_last_mouse_cell = _placement_cursor


func _can_place_machine(machine_id: int, grid_coord: Vector2i) -> bool:
	if machine_id == Enum.Machine.DELETE:
		return false

	if machine_id not in Data.unlocked_machines:
		push_warning("Machine blueprint is not unlocked for machine id: %s" % machine_id)
		return false

	if not Data.MACHINE_SCENE.has(machine_id):
		push_warning("Missing machine scene for machine id: %s" % machine_id)
		return false

	if not Data.MACHINE_PLACEMENT_COSTS.has(machine_id):
		push_warning("Missing machine placement cost for machine id: %s" % machine_id)
		return false

	if $Objects/House.is_point_inside_house(grid_coord):
		return false

	if is_object_near_cell(grid_coord):
		return false

	if grid_coord in machine_cells:
		return false

	if grid_coord in planted_cells:
		return false

	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)
	if not cell or cell.get_custom_data("water"):
		return false

	return _can_afford_machine_placement(machine_id)


func _can_afford_machine_placement(machine_id: int) -> bool:
	return Data.can_afford_machine_placement_costs(machine_id)


func _deduct_machine_placement_cost(machine_id: int) -> bool:
	var cost_plan: Dictionary = Data.build_machine_placement_cost_plan(machine_id)
	return Data.consume_machine_placement_cost_plan(cost_plan)


func _discard_failed_machine_instance(machine: Node) -> void:
	if machine == null:
		return

	if machine.is_inside_tree():
		machine.queue_free()
	else:
		machine.free()


func _on_player_change_machine(curr_machine: int) -> void:
	var machine_texture = Data.MACHINE_PREVIEW_TEXTURES[curr_machine]["texture"]
	$Overlay/PreviewMachineSprite2D.texture = machine_texture


func water_near_soils(sprinkler_coord: Vector2i):
	# Check the 3x3 area around the sprinkler
	for x in range(-1, 2):  # -1, 0, 1
		for y in range(-1, 2):  # -1, 0, 1
			var check_coord = Vector2i(sprinkler_coord.x + x, sprinkler_coord.y + y)
			
			# Check if this cell has soil
			var has_soil = $Layers/SoilLayer.get_cell_source_id(check_coord) != -1
			
			if has_soil:				
				# Add wet soil to WetSoilLayer
				$Layers/WetSoilLayer.set_cell(check_coord, 0, Vector2i(randi_range(0, 2), 0)
			)


# =========================================================
# TARGET HIGHLIGHT
# =========================================================
func update_target_highlight():
	var dir = player.animation_direction

	if dir == Vector2.ZERO:
		$Layers/TargetLayer.clear()
		return

	var grid_coord: Vector2i = get_target_grid(player.position, dir)

	$Layers/TargetLayer.clear()
	
	if is_tool_valid(player.current_tool, grid_coord):
		$Layers/TargetLayer.set_cell(grid_coord, 0, target_highlight_green)
	else:
		$Layers/TargetLayer.set_cell(grid_coord, 0, target_highlight_red)


# =========================================================
# VALIDATION (Single Terrain Authority)
# =========================================================
func is_tool_valid(tool: Enum.Tool, grid_coord: Vector2i) -> bool:
	if $Objects/House.is_point_inside_house(grid_coord):
		return false
		
	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)

	if not cell:
		return false

	var is_water = cell.get_custom_data("water")
	var is_farmable = cell.get_custom_data("farmable")
	var has_soil = $Layers/SoilLayer.get_cell_source_id(grid_coord) != -1

	match tool:

		Enum.Tool.HOE:
			if is_water or not is_farmable:
				return false

			if is_object_near_cell(grid_coord):
				return false

			return true

		Enum.Tool.WATER:
			return has_soil

		Enum.Tool.FISH:
			return is_water
			
		Enum.Tool.SEED:
			return has_soil and grid_coord not in planted_cells
			
		Enum.Tool.AXE, Enum.Tool.SWORD:
			return true

	return false


func is_object_near_cell(grid_coord: Vector2i) -> bool:
	for object in get_tree().get_nodes_in_group("Objects"):
		#if not object.is_in_group("Tree"):
			#continue

		# Tree top-left tile
		var object_top_left := Vector2i(
			floor(object.position.x / Data.TILE_SIZE),
			floor(object.position.y / Data.TILE_SIZE)
		)

		# Exact 2x2 footprint (4 tiles)
		if grid_coord.x >= object_top_left.x \
		and grid_coord.x <= object_top_left.x + 1 \
		and grid_coord.y >= object_top_left.y \
		and grid_coord.y <= object_top_left.y + 1:
			return true

	return false


# =========================================================
# GRID CALCULATION
# =========================================================
func get_target_grid(pos: Vector2, dir: Vector2) -> Vector2i:
	var base_cell = Vector2i(floor(pos.x / Data.TILE_SIZE), floor(pos.y / Data.TILE_SIZE))
	return base_cell + Vector2i(dir)


# =========================================================
# Signal Func for Plant Death and Harvest
func plant_death(coord: Vector2i):
	planted_cells.erase(coord)
	
	
func plant_harvest(coord: Vector2i):
	planted_cells.erase(coord)


# Tools animation
func _on_player_do_action(anim_tree: AnimationTree, property: StringName, tool: int, pos: Vector2, dir: Vector2) -> void:
	if is_tool_valid(tool, get_target_grid(pos, dir)):
		anim_tree.set(property, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_blob_timer_timeout() -> void:
	# Phase H1: slimes are temporarily disabled on the main farm (they had no clear
	# purpose and cluttered the crops). Scene, scripts, assets and combat code are
	# all preserved for future reuse in a dedicated combat area.
	if not FARM_SLIME_ENABLED:
		return
	var plants = get_tree().get_nodes_in_group("Plants")
	var spawn_points = $BlobSpawnPositions.get_children()
	
	if plants:
		var start_pos = spawn_points.pick_random().position
		var target_plant = plants.pick_random()
		var blob = blob_scene.instantiate()
		blob.setup(start_pos,$Objects/Enemies, target_plant)


func open_shop(shop_type: Enum.Shop):
	var merchant_id: String = "mouse" if shop_type == Enum.Shop.HAT else "cat"
	_open_trade_panel(merchant_id, "buy")
	player.current_state = Enum.State.SHOP


func _on_player_close_shop() -> void:
	var trade_ui: Node = get_node_or_null("SellUI")
	if trade_ui != null and trade_ui.has_method("is_open") and trade_ui.is_open():
		trade_ui.call("request_close")
		return
	$Overlay/CanvasLayer/ShopUI.hide()
	$Overlay/CanvasLayer/ShopUI.remove_items()
	player.current_state = Enum.State.DEFAULT
	# Phase H1: fixed shop NPCs settle facing Down after the shop closes.
	for character in get_tree().get_nodes_in_group("ShopCharacters"):
		if character.has_method("face_down"):
			character.face_down()


# =========================================================
# Courier seller (Phase F)
# =========================================================
func _connect_courier_seller() -> void:
	var courier: Node = get_node_or_null("Objects/CourierSellerNPC")
	var sell_ui: Node = get_node_or_null("SellUI")
	if courier == null or sell_ui == null:
		return
	var open_callable := Callable(self, "_open_sell_panel")
	if not courier.is_connected("request_open_sell_panel", open_callable):
		courier.connect("request_open_sell_panel", open_callable)
	var close_callable := Callable(self, "_force_close_sell_panel")
	if not courier.is_connected("request_close_sell_panel", close_callable):
		courier.connect("request_close_sell_panel", close_callable)
	var ui_closed_callable := Callable(self, "_on_sell_ui_closed")
	if not sell_ui.is_connected("closed", ui_closed_callable):
		sell_ui.connect("closed", ui_closed_callable)


func _open_sell_panel(initial_tab: String = "sell") -> void:
	_open_trade_panel("courier", initial_tab)


func _open_trade_panel(merchant_id: String, initial_tab: String = "buy") -> void:
	var trade_ui: Node = get_node_or_null("SellUI")
	if trade_ui == null:
		return
	_active_trade_merchant_id = merchant_id
	player.current_state = Enum.State.SHOP
	if trade_ui.has_method("open_for_merchant"):
		trade_ui.call("open_for_merchant", merchant_id, initial_tab)
	else:
		trade_ui.call("reveal", merchant_id)


# Player closed the Sell panel: hand control back to the Courier so it can
# restore its facing and release the player's dialogue lock.
func _on_sell_ui_closed() -> void:
	if _active_trade_merchant_id == "courier":
		var courier: Node = get_node_or_null("Objects/CourierSellerNPC")
		if is_instance_valid(courier):
			courier.on_sell_panel_closed()
		player.current_state = Enum.State.DEFAULT
	else:
		player.current_state = Enum.State.DEFAULT
		for character in get_tree().get_nodes_in_group("ShopCharacters"):
			if character.has_method("face_down"):
				character.face_down()
	_active_trade_merchant_id = ""


# Defensive teardown (e.g. player somehow left range mid-sale): hide the panel
# without re-notifying the Courier, which already ended the interaction.
func _force_close_sell_panel() -> void:
	var sell_ui: Node = get_node_or_null("SellUI")
	if sell_ui != null and sell_ui.is_open():
		sell_ui.call("force_close")
	if player.current_state == Enum.State.SHOP:
		player.current_state = Enum.State.DEFAULT
	_active_trade_merchant_id = ""


func _on_joy_connection_changed(device_id: int, connected: bool):
	update_hint_ui_keys.emit()
	if connected:
		Data.ControllerConnected = true
		print("Controller ", device_id, " connected!")
		var controller_name = Input.get_joy_name(device_id)
		print("Controller name: ", controller_name)
		var controller_guid = Input.get_joy_guid(device_id)
		print("GUID: ", controller_guid)
	else:
		Data.ControllerConnected = false
		print("Controller ", device_id, " disconnected!")
