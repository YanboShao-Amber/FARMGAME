extends Node

signal game_day_changed(day_id: int)
signal coin_balance_changed(new_balance: int)

const PLAYER_SKINS = {
	Enum.Style.BASIC: preload("res://graphics/characters/main/main_basic.png"),
	Enum.Style.BASEBALL: preload("res://graphics/characters/main/main_blue.png"),
	Enum.Style.COWBOY: preload("res://graphics/characters/main/main_cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/characters/main/main_grey.png"),
	Enum.Style.STRAW: preload("res://graphics/characters/main/main_straw.png"),
	Enum.Style.BEANIE: preload("res://graphics/characters/main/main_red.png")}
const TILE_SIZE = 16
const PLANT_DATA = {
	Enum.Seed.TOMATO: {
		'texture': "res://graphics/plants/tomato.png",
		'icon_texture': "res://graphics/icons/tomato.png",
		'name':'Tomato',
		'h_frames': 3,
		'grow_speed': 0.75,
		'death_max': 3,
		'reward': Enum.Item.TOMATO},
	Enum.Seed.CORN: {
		'texture': "res://graphics/plants/corn.png",
		'icon_texture': "res://graphics/icons/corn.png",
		'name':'Corn',
		'h_frames': 3,
		'grow_speed': 1.0,
		'death_max': 2,
		'reward': Enum.Item.CORN},
	Enum.Seed.PUMPKIN: {
		'texture': "res://graphics/plants/pumpkin.png",
		'icon_texture': "res://graphics/icons/pumpkin.png",
		'name':'Pumpkin',
		'h_frames': 3,
		'grow_speed': 0.25,
		'death_max': 3,
		'reward': Enum.Item.PUMPKIN},
	Enum.Seed.WHEAT: {
		'texture': "res://graphics/plants/wheat.png",
		'icon_texture': "res://graphics/icons/wheat.png",
		'name':'Wheat',
		'h_frames': 3,
		'grow_speed': 1.0,
		'death_max': 3,
		'reward': Enum.Item.WHEAT}}
const MACHINE_UPGRADE_COST = {
	Enum.Machine.DELETE:{},
	Enum.Machine.SPRINKLER: {
		'name': 'Sprinkler',
		'cost' :{Enum.Item.TOMATO: 30, Enum.Item.WHEAT: 20},
		'icon': preload("res://graphics/icons/sprinkler.png"),
		'color': Color.SEA_GREEN},
	Enum.Machine.FISHER: {
		'name': 'Fisher',
		'cost' :{Enum.Item.WOOD: 25, Enum.Item.FISH: 15},
		'icon': preload("res://graphics/icons/fisher.png"),
		'color': Color.SLATE_GRAY},
	Enum.Machine.SCARECROW: {
		'name': 'Scarecrow',
		'cost' : {Enum.Item.PUMPKIN: 15, Enum.Item.CORN: 15},
		'icon': preload("res://graphics/icons/scarecrow.png"),
		'color': Color.BURLYWOOD}}
const HOUSE_COST = {
	1: {Enum.Item.WOOD: 30, Enum.Item.APPLE: 20},
	2: {Enum.Item.WOOD: 40, Enum.Item.APPLE: 30}}

# Deprecated after Phase E.
# Crop harvest no longer grants direct coins (no runtime references remain).
# Scheduled for removal or replacement by sale prices in Phase F.
const CROP_COIN_REWARDS: Dictionary = {
	Enum.Item.WHEAT: 20,
	Enum.Item.CORN: 25,
	Enum.Item.TOMATO: 40,
	Enum.Item.PUMPKIN: 150}

# Deprecated after Phase E.
# Manual fishing no longer grants direct coins (no runtime references remain).
# Fish value will be handled by the seller system in Phase F.
const MANUAL_FISHING_COIN_REWARD: int = 25

# =========================================================
# Phase F — Seller economy (Courier)
# Provisional sale prices; rebalanced in Phase G.
# NOT derived from the deprecated CROP_COIN_REWARDS / MANUAL_FISHING_COIN_REWARD.
# =========================================================
const SELL_PRICES: Dictionary = {
	Enum.Item.WHEAT: 10,
	Enum.Item.CORN: 12,
	Enum.Item.TOMATO: 20,
	Enum.Item.PUMPKIN: 75,
	Enum.Item.FISH: 25}

# Positive whitelist. Only these items may ever be sold. Seeds/wood/apple/coin
# are intentionally excluded so future items are never accidentally sellable.
const SELLABLE_ITEMS: Array[Enum.Item] = [
	Enum.Item.WHEAT,
	Enum.Item.CORN,
	Enum.Item.TOMATO,
	Enum.Item.PUMPKIN,
	Enum.Item.FISH]

const SALE_TELEMETRY_SOURCES: Dictionary = {
	Enum.Item.WHEAT: "sale_wheat",
	Enum.Item.CORN: "sale_corn",
	Enum.Item.TOMATO: "sale_tomato",
	Enum.Item.PUMPKIN: "sale_pumpkin",
	Enum.Item.FISH: "sale_fish"}

# One-time coin cost for permanently unlocking a machine blueprint.
const MACHINE_BLUEPRINT_COIN_COSTS: Dictionary = {
	Enum.Machine.SPRINKLER: 400,
	Enum.Machine.FISHER: 600,
	Enum.Machine.SCARECROW: 900}

# Material recipe consumed for every successfully placed machine instance.
const MACHINE_PLACEMENT_COSTS: Dictionary = {
	Enum.Machine.SPRINKLER: {
		Enum.Item.TOMATO: 2,
		Enum.Item.WHEAT: 4},
	Enum.Machine.FISHER: {
		Enum.Item.WOOD: 8,
		Enum.Item.FISH: 4},
	Enum.Machine.SCARECROW: {
		Enum.Item.PUMPKIN: 1,
		Enum.Item.CORN: 4}}

const STYLE_COIN_COSTS: Dictionary = {
	Enum.Style.COWBOY: 300,
	Enum.Style.BASEBALL: 300,
	Enum.Style.BEANIE: 300}

const STYLE_RESOURCE_COSTS: Dictionary = {
	Enum.Style.COWBOY: {
		Enum.Item.WOOD: 6,
		Enum.Item.CORN: 4},
	Enum.Style.BASEBALL: {
		Enum.Item.TOMATO: 6,
		Enum.Item.APPLE: 4},
	Enum.Style.BEANIE: {
		Enum.Item.PUMPKIN: 2,
		Enum.Item.WHEAT: 4}}

const PLAYTEST_TELEMETRY_ENABLED: bool = true
const PLAYTEST_RUN_LABEL: String = "V1"
const PLAYTEST_LOG_DIR: String = "user://playtest_logs"

# Deprecated after Phase E.
# Crop harvest no longer records coin income (no runtime references remain).
# Sale-based crop telemetry sources will be introduced in Phase F.
const CROP_TELEMETRY_SOURCES: Dictionary = {
	Enum.Item.WHEAT: "crop_wheat",
	Enum.Item.CORN: "crop_corn",
	Enum.Item.TOMATO: "crop_tomato",
	Enum.Item.PUMPKIN: "crop_pumpkin"}

const MACHINE_BLUEPRINT_TELEMETRY_SOURCES: Dictionary = {
	Enum.Machine.SPRINKLER: "blueprint_sprinkler",
	Enum.Machine.FISHER: "blueprint_fisher",
	Enum.Machine.SCARECROW: "blueprint_scarecrow"}

const STYLE_PURCHASE_TELEMETRY_SOURCES: Dictionary = {
	Enum.Style.COWBOY: "style_cowboy",
	Enum.Style.BASEBALL: "style_baseball",
	Enum.Style.BEANIE: "style_beanie"}

const MACHINE_PLACEMENT_TELEMETRY_SOURCES: Dictionary = {
	Enum.Machine.SPRINKLER: "placement_sprinkler",
	Enum.Machine.FISHER: "placement_fisher",
	Enum.Machine.SCARECROW: "placement_scarecrow"}

const ITEM_TELEMETRY_KEYS: Dictionary = {
	Enum.Item.WOOD: "wood",
	Enum.Item.APPLE: "apple",
	Enum.Item.FISH: "fish",
	Enum.Item.CORN: "corn",
	Enum.Item.WHEAT: "wheat",
	Enum.Item.PUMPKIN: "pumpkin",
	Enum.Item.TOMATO: "tomato",
	Enum.Item.COIN: "coin",
	Enum.Item.TOMATO_SEED: "tomato_seed",
	Enum.Item.CORN_SEED: "corn_seed",
	Enum.Item.PUMPKIN_SEED: "pumpkin_seed",
	Enum.Item.WHEAT_SEED: "wheat_seed"}
const STYLE_UPGRADES = {
	Enum.Style.BASIC: {
		'icon': null,
	},
	Enum.Style.COWBOY: {
		'name': 'Cowboy',
		'cost':{Enum.Item.WOOD: 8, Enum.Item.CORN: 6},
		'icon': preload("res://graphics/icons/cowboy.png"),
		'color': Color.SANDY_BROWN},
	Enum.Style.ENGLISH: {
		'name': 'Oldie',
		'cost':{Enum.Item.CORN: 8, Enum.Item.WHEAT: 6},
		'icon': preload("res://graphics/icons/english.png"),
		'color': Color.LIGHT_GRAY},
	Enum.Style.BASEBALL: {
		'name': 'Baseball',
		'cost':{Enum.Item.TOMATO: 8, Enum.Item.APPLE: 6},
		'icon': preload("res://graphics/icons/blue.png"),
		'color': Color.SKY_BLUE},
	Enum.Style.BEANIE: {
		'name': 'Beanie',
		'cost':{Enum.Item.PUMPKIN: 8, Enum.Item.WHEAT: 6},
		'icon': preload("res://graphics/icons/beanie.png"),
		'color': Color.INDIAN_RED},
	Enum.Style.STRAW: {
		'name': 'Straw',
		'cost':{Enum.Item.FISH: 8, Enum.Item.WOOD: 6},
		'icon': preload("res://graphics/icons/straw.png"),
		'color': Color.BURLYWOOD}}
const TOOL_STATE_ANIMATIONS = {
	Enum.Tool.HOE: 'Hoe',
	Enum.Tool.AXE: 'Axe',
	Enum.Tool.WATER: 'Water',
	Enum.Tool.SWORD: 'Sword',
	Enum.Tool.FISH: 'Fish',
	Enum.Tool.SEED: 'Seed',
	}
const FISH_DATA = {
	Enum.Fish.GRAY: {
		'icon_texture': "res://graphics/icons/grayfish.png",
		'name': "Gray Fish",
		'catch_speed': 20,
		'lose_speed': 10,
		'start_progress': 30,
		'frequency': "Common",
		'color': Color.PALE_GREEN
	},
	Enum.Fish.SILVER: {
		'icon_texture': "res://graphics/icons/silverfish.png",
		'name': "Silver Fish",
		'catch_speed': 15,
		'lose_speed': 15,
		'start_progress': 30,
		'frequency': "Rare",
		'color': Color.MEDIUM_PURPLE
	},
	Enum.Fish.GOLD: {
		'icon_texture': "res://graphics/icons/goldfish.png",
		'name': "Gold Fish",
		'catch_speed': 10,
		'lose_speed': 20,
		'start_progress': 30,
		'frequency': "Legendary",
		'color': Color.GOLDENROD
	}
	}
const MACHINE_SCENE = {
	Enum.Machine.SPRINKLER : {
		"scene": preload("res://scenes/machines/sprinkler.tscn"),
		},
	Enum.Machine.FISHER : {
		"scene": preload("res://scenes/machines/fisherman.tscn"),
		},
	Enum.Machine.SCARECROW :{
		"scene":preload("res://scenes/machines/scare_crow.tscn"),
	} ,
	Enum.Machine.DELETE : {
		"scene":preload("res://scenes/machines/scare_crow.tscn"),
		}
	}
const MACHINE_PREVIEW_TEXTURES = {
	Enum.Machine.SPRINKLER: {'texture':preload("res://graphics/icons/sprinkler.png"), 'offset': Vector2i(2,0)},
	Enum.Machine.FISHER: {'texture':preload("res://graphics/icons/fisher.png"), 'offset': Vector2i(2,-8)},
	Enum.Machine.SCARECROW: {'texture':preload("res://graphics/icons/scarecrow.png"), 'offset': Vector2i(1,-10)},
	Enum.Machine.DELETE: {'texture':preload("res://graphics/icons/delete.png"), 'offset': Vector2i(-8,-8)}}	
	
	
var TOOL_TEXTURES: Dictionary = {
	Enum.Tool.AXE: preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE: preload("res://graphics/icons/hoe.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.FISH: preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED: null
	}
	
var SEED_TEXTURES: Dictionary = {}

const STYLE_TEXTURES ={
	Enum.Style.STRAW: preload("res://graphics/icons/straw.png"),
	Enum.Style.BASIC: null,
	Enum.Style.COWBOY: preload("res://graphics/icons/cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/icons/english.png"),
	Enum.Style.BASEBALL: preload("res://graphics/icons/blue.png"),
	Enum.Style.BEANIE: preload("res://graphics/icons/beanie.png"),
	Enum.Style.CAP: null,}
	
const MACHINE_TEXTURES = {
	Enum.Machine.DELETE: preload("res://graphics/icons/delete.png"),
	Enum.Machine.SPRINKLER: preload("res://graphics/icons/sprinkler.png"),
	Enum.Machine.FISHER: preload("res://graphics/icons/fisher.png"),
	Enum.Machine.SCARECROW: preload("res://graphics/icons/scarecrow.png"),
}
	
var TARGET_HIGHLIGHTER: bool = false
var CURRENT_DAY_ID: int = 1

const APPLE_TREE_HEALTH = 4
const BLOB_ENEMY_HEALTH = 3
const BLOB_SPEED = 25.0
const PLAYER_SPEED = 70.0

# shop
const ICON_PATHS = {
	Enum.Item.WOOD: "res://graphics/icons/wood.png",
	Enum.Item.FISH: "res://graphics/icons/goldfish.png",
	Enum.Item.APPLE: "res://graphics/icons/apple.png",
	Enum.Item.CORN: "res://graphics/icons/corn.png",
	Enum.Item.WHEAT: "res://graphics/icons/wheat.png",
	Enum.Item.PUMPKIN: "res://graphics/icons/pumpkin.png",
	Enum.Item.TOMATO: "res://graphics/icons/tomato.png",
	Enum.Item.TOMATO_SEED: "res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png",
	Enum.Item.CORN_SEED: "res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png",
	Enum.Item.PUMPKIN_SEED: "res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png",
	Enum.Item.WHEAT_SEED: "res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png",
	Enum.Item.COIN: "res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Icons/special icons/Special Icons.png"}

var FORECAST_RAIN: bool

var unlocked_styles: Array[Enum.Style] = [Enum.Style.STRAW, Enum.Style.BASIC,  Enum.Style.ENGLISH]
var unlocked_machines: Array[Enum.Machine] = [Enum.Machine.DELETE]

var shop_connection = {
	Enum.Shop.HAT: {'tracker': unlocked_styles, 'all': STYLE_UPGRADES.keys()},
	Enum.Shop.MAIN: {'tracker': unlocked_machines,
					 'all': MACHINE_UPGRADE_COST.keys()}
	}

# item textures
const TEXTURES = {
	Enum.Item.WOOD: preload("res://graphics/icons/wood.png"),
	Enum.Item.APPLE: preload("res://graphics/icons/apple.png"),
	Enum.Item.FISH: preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT: preload("res://graphics/icons/wheat.png")}

const COIN_ICON_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Icons/special icons/Special Icons.png")
const SPROUT_LANDS_EMOJI_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png")

# Temporary Phase B seed icons.
# Uses Sprout Lands crop/farming emoji regions until dedicated seed artwork exists.
const SEED_ITEM_TEXTURE_REGIONS: Dictionary = {
	Enum.Item.TOMATO_SEED: Rect2(64, 352, 32, 32),
	Enum.Item.CORN_SEED: Rect2(96, 352, 32, 32),
	Enum.Item.PUMPKIN_SEED: Rect2(128, 352, 32, 32),
	Enum.Item.WHEAT_SEED: Rect2(32, 352, 32, 32)}


var ITEMS_AMOUNT = {
	Enum.Item.WOOD: 10,
	Enum.Item.APPLE: 5,
	Enum.Item.FISH: 0,
	Enum.Item.CORN: 0,
	Enum.Item.WHEAT: 0,
	Enum.Item.PUMPKIN: 0,
	Enum.Item.TOMATO: 0,
	Enum.Item.COIN: 150,
	Enum.Item.TOMATO_SEED: 6,
	Enum.Item.CORN_SEED: 8,
	Enum.Item.PUMPKIN_SEED: 3,
	Enum.Item.WHEAT_SEED: 10}

var playtest_log_path: String = ""
var playtest_metrics: Dictionary = {}
var _playtest_day_started_msec: int = 0
var _playtest_last_recorded_day_id: int = -1
var _playtest_active_fishing_start_msec: int = -1

const ITEM_IDS = {
	Enum.Item.WOOD: &"WOOD",
	Enum.Item.APPLE: &"APPLE",
	Enum.Item.TOMATO: &"TOMATO",
	Enum.Item.CORN: &"CORN",
	Enum.Item.WHEAT: &"WHEAT",
	Enum.Item.PUMPKIN: &"PUMPKIN",
	Enum.Item.FISH: &"FISH",
	Enum.Item.COIN: &"COIN",
	Enum.Item.TOMATO_SEED: &"TOMATO_SEED",
	Enum.Item.CORN_SEED: &"CORN_SEED",
	Enum.Item.PUMPKIN_SEED: &"PUMPKIN_SEED",
	Enum.Item.WHEAT_SEED: &"WHEAT_SEED"}

const ITEM_ID_TO_ENUM = {
	&"WOOD": Enum.Item.WOOD,
	&"APPLE": Enum.Item.APPLE,
	&"TOMATO": Enum.Item.TOMATO,
	&"CORN": Enum.Item.CORN,
	&"WHEAT": Enum.Item.WHEAT,
	&"PUMPKIN": Enum.Item.PUMPKIN,
	&"FISH": Enum.Item.FISH,
	&"COIN": Enum.Item.COIN,
	&"TOMATO_SEED": Enum.Item.TOMATO_SEED,
	&"CORN_SEED": Enum.Item.CORN_SEED,
	&"PUMPKIN_SEED": Enum.Item.PUMPKIN_SEED,
	&"WHEAT_SEED": Enum.Item.WHEAT_SEED}

const ITEM_DISPLAY_NAMES = {
	&"WOOD": "Wood",
	&"APPLE": "Apple",
	&"TOMATO": "Tomato",
	&"CORN": "Corn",
	&"WHEAT": "Wheat",
	&"PUMPKIN": "Pumpkin",
	&"FISH": "Fish",
	&"COIN": "Coin",
	&"TOMATO_SEED": "Tomato Seeds",
	&"CORN_SEED": "Corn Seeds",
	&"PUMPKIN_SEED": "Pumpkin Seeds",
	&"WHEAT_SEED": "Wheat Seeds"}


func _ready() -> void:
	_initialize_runtime_icon_textures()
	start_playtest_session()


func add_coins(amount: int) -> bool:
	if amount <= 0:
		return false
	if not ITEMS_AMOUNT.has(Enum.Item.COIN):
		ITEMS_AMOUNT[Enum.Item.COIN] = 0
	ITEMS_AMOUNT[Enum.Item.COIN] += amount
	coin_balance_changed.emit(int(ITEMS_AMOUNT[Enum.Item.COIN]))
	return true


func get_coins() -> int:
	if not ITEMS_AMOUNT.has(Enum.Item.COIN):
		return 0
	return int(ITEMS_AMOUNT[Enum.Item.COIN])


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		push_warning("Coin spend amount must be greater than zero.")
		return false

	var current_coins: int = get_coins()
	if current_coins < amount:
		return false

	ITEMS_AMOUNT[Enum.Item.COIN] = current_coins - amount
	coin_balance_changed.emit(int(ITEMS_AMOUNT[Enum.Item.COIN]))
	return true


# =========================================================
# Phase F — Seller transaction (single source of truth)
# =========================================================
func is_item_sellable(item: Enum.Item) -> bool:
	return SELLABLE_ITEMS.has(item)


func get_sell_price(item: Enum.Item) -> int:
	if not SELL_PRICES.has(item):
		return 0
	return int(SELL_PRICES[item])


# Atomic sale. Returns total coins earned, or 0 on any failure.
# On failure nothing changes: no item removed, no coin added, no telemetry.
func try_sell_item(item: Enum.Item, quantity: int) -> int:
	if not is_item_sellable(item):
		push_warning("Item is not sellable: %s" % item)
		return 0
	if not SELL_PRICES.has(item):
		push_warning("Missing sell price for item: %s" % item)
		return 0
	var unit_price: int = int(SELL_PRICES[item])
	if unit_price <= 0:
		push_warning("Sell unit price must be greater than zero: item=%s" % item)
		return 0
	if quantity <= 0:
		return 0
	var owned: int = int(ITEMS_AMOUNT.get(item, 0))
	if owned < quantity:
		return 0

	var total: int = unit_price * quantity
	ITEMS_AMOUNT[item] = owned - quantity
	if not add_coins(total):
		# Practically unreachable (total > 0); revert defensively on failure.
		ITEMS_AMOUNT[item] = owned
		return 0

	var telemetry_source: String = SALE_TELEMETRY_SOURCES.get(item, "")
	if not telemetry_source.is_empty():
		record_playtest_coin_income(telemetry_source, total)
	record_playtest_sale(item, quantity, unit_price, total)
	return total


func get_item_texture(item: Enum.Item) -> Texture2D:
	if item == Enum.Item.COIN:
		var coin_texture := AtlasTexture.new()
		coin_texture.atlas = COIN_ICON_SHEET
		coin_texture.region = Rect2(96, 0, 16, 16)
		return coin_texture

	if SEED_ITEM_TEXTURE_REGIONS.has(item):
		return _create_atlas_texture(SPROUT_LANDS_EMOJI_SHEET, SEED_ITEM_TEXTURE_REGIONS[item])

	if not TEXTURES.has(item):
		return null

	return TEXTURES[item]


func get_seed_texture(seed: Enum.Seed) -> Texture2D:
	if not SEED_TO_SEED_ITEM.has(seed):
		return null
	return get_item_texture(SEED_TO_SEED_ITEM[seed])


func get_tool_texture(tool: Enum.Tool) -> Texture2D:
	if tool == Enum.Tool.SEED:
		return TOOL_TEXTURES[Enum.Tool.SEED]
	return TOOL_TEXTURES.get(tool, null)


func set_current_seed_tool_texture(seed: Enum.Seed) -> void:
	TOOL_TEXTURES[Enum.Tool.SEED] = get_seed_texture(seed)


func _initialize_runtime_icon_textures() -> void:
	for seed: Enum.Seed in Enum.Seed.values():
		SEED_TEXTURES[seed] = get_seed_texture(seed)
	set_current_seed_tool_texture(Enum.Seed.TOMATO)


func _create_atlas_texture(atlas_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_region := AtlasTexture.new()
	atlas_region.atlas = atlas_texture
	atlas_region.region = region
	return atlas_region


func get_current_game_day_id() -> int:
	return CURRENT_DAY_ID


func advance_game_day() -> int:
	CURRENT_DAY_ID += 1
	game_day_changed.emit(CURRENT_DAY_ID)
	return CURRENT_DAY_ID


func get_item_id(item: Enum.Item) -> StringName:
	if ITEM_IDS.has(item):
		return ITEM_IDS[item]
	return &""


func get_item_enum_from_id(item_id: StringName) -> int:
	if ITEM_ID_TO_ENUM.has(item_id):
		return int(ITEM_ID_TO_ENUM[item_id])
	return -1


func has_item_id(item_id: StringName) -> bool:
	var item_enum: int = get_item_enum_from_id(item_id)
	return item_enum != -1 and ITEMS_AMOUNT.has(item_enum)


func get_item_display_name(item_id: StringName) -> String:
	if ITEM_DISPLAY_NAMES.has(item_id):
		return ITEM_DISPLAY_NAMES[item_id]
	return String(item_id)


func get_item_amount_by_id(item_id: StringName) -> int:
	var item_enum: int = get_item_enum_from_id(item_id)
	if item_enum == -1 or not ITEMS_AMOUNT.has(item_enum):
		return 0
	return int(ITEMS_AMOUNT[item_enum])


func remove_item_by_id(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var item_enum: int = get_item_enum_from_id(item_id)
	if item_enum == -1 or not ITEMS_AMOUNT.has(item_enum):
		return false
	if int(ITEMS_AMOUNT[item_enum]) < amount:
		return false
	ITEMS_AMOUNT[item_enum] -= amount
	return true


func start_playtest_session() -> void:
	if not PLAYTEST_TELEMETRY_ENABLED:
		return

	var unix_timestamp: int = int(Time.get_unix_time_from_system())
	playtest_log_path = "%s/farmgame_day4_%s_%s.json" % [
		PLAYTEST_LOG_DIR,
		PLAYTEST_RUN_LABEL,
		unix_timestamp
	]
	_playtest_day_started_msec = Time.get_ticks_msec()
	_playtest_last_recorded_day_id = -1
	_playtest_active_fishing_start_msec = -1

	var inventory_snapshot: Dictionary = get_playtest_inventory_snapshot()
	playtest_metrics = {
		"run_label": PLAYTEST_RUN_LABEL,
		"session_started_unix": unix_timestamp,
		"session_started_msec": _playtest_day_started_msec,
		"session_log_path": playtest_log_path,
		"current_day_id": CURRENT_DAY_ID,
		"first_income_elapsed_seconds": null,
		"starting_inventory": inventory_snapshot.duplicate(true),
		"current_inventory": inventory_snapshot.duplicate(true),
		"coin_income_by_source": {},
		"coin_spending_by_source": {},
		"total_coin_income": 0,
		"total_coin_spending": 0,
		"fishing_attempts": 0,
		"fishing_successes": 0,
		"fishing_failures": 0,
		"fishing_total_duration_seconds": 0.0,
		"fishing_average_duration_seconds": 0.0,
		"purchase_events": [],
		"machine_placement_events": [],
		"sale_events": [],
		"day_snapshots": [],
		"day5_final_snapshot": {},
		"last_save_reason": "",
		"last_saved_elapsed_seconds": 0.0
	}

	print("Playtest telemetry log: %s" % ProjectSettings.globalize_path(playtest_log_path))
	save_playtest_log("session_start")


func save_playtest_log(reason: String = "") -> void:
	if not PLAYTEST_TELEMETRY_ENABLED:
		return
	if playtest_log_path.is_empty() or playtest_metrics.is_empty():
		return

	playtest_metrics["current_day_id"] = CURRENT_DAY_ID
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	playtest_metrics["last_save_reason"] = reason
	playtest_metrics["last_saved_elapsed_seconds"] = _get_playtest_elapsed_seconds()

	var log_dir_absolute: String = ProjectSettings.globalize_path(PLAYTEST_LOG_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(log_dir_absolute)
	if dir_error != OK:
		push_warning("Could not create playtest log directory '%s': error %s" % [log_dir_absolute, dir_error])
		return

	var file := FileAccess.open(playtest_log_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write playtest log '%s': error %s" % [
			ProjectSettings.globalize_path(playtest_log_path),
			FileAccess.get_open_error()
		])
		return

	file.store_string(JSON.stringify(playtest_metrics, "\t"))
	file.close()


func get_playtest_inventory_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for item in ITEM_TELEMETRY_KEYS:
		snapshot[ITEM_TELEMETRY_KEYS[item]] = int(ITEMS_AMOUNT.get(item, 0))
	return snapshot


func record_playtest_coin_income(source: String, amount: int) -> void:
	if not _is_playtest_session_ready():
		return
	if amount <= 0:
		push_warning("Playtest coin income amount must be greater than zero: source=%s, amount=%s" % [source, amount])
		return
	if source.strip_edges().is_empty():
		push_warning("Playtest coin income source is empty.")
		return

	var income_by_source: Dictionary = playtest_metrics["coin_income_by_source"]
	income_by_source[source] = int(income_by_source.get(source, 0)) + amount
	playtest_metrics["coin_income_by_source"] = income_by_source
	playtest_metrics["total_coin_income"] = int(playtest_metrics["total_coin_income"]) + amount
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()

	if playtest_metrics["first_income_elapsed_seconds"] == null:
		playtest_metrics["first_income_elapsed_seconds"] = _get_playtest_elapsed_seconds()

	save_playtest_log("coin_income_%s" % source)


func record_playtest_sale(item: Enum.Item, quantity: int, unit_price: int, coin_earned: int) -> void:
	if not _is_playtest_session_ready():
		return
	if not playtest_metrics.has("sale_events"):
		playtest_metrics["sale_events"] = []

	var event: Dictionary = {
		"day_id": CURRENT_DAY_ID,
		"elapsed_seconds": _get_playtest_elapsed_seconds(),
		"item_id": String(get_item_id(item)),
		"quantity": quantity,
		"unit_price": unit_price,
		"coin_earned": coin_earned,
		"coin_balance_after": get_coins(),
		"inventory_amount_after": int(ITEMS_AMOUNT.get(item, 0))
	}
	var events: Array = playtest_metrics["sale_events"]
	events.append(event)
	playtest_metrics["sale_events"] = events
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("sale_%s" % String(get_item_id(item)).to_lower())


func record_manual_fishing_started() -> void:
	if not _is_playtest_session_ready():
		return
	if _playtest_active_fishing_start_msec >= 0:
		push_warning("Manual fishing telemetry start ignored because an attempt is already active.")
		return

	_playtest_active_fishing_start_msec = Time.get_ticks_msec()
	playtest_metrics["fishing_attempts"] = int(playtest_metrics["fishing_attempts"]) + 1


func record_manual_fishing_finished(is_success: bool) -> void:
	if not _is_playtest_session_ready():
		return

	var duration_seconds: float = 0.0
	if _playtest_active_fishing_start_msec >= 0:
		duration_seconds = float(Time.get_ticks_msec() - _playtest_active_fishing_start_msec) / 1000.0
	else:
		push_warning("Manual fishing telemetry finish received without an active start.")
	_playtest_active_fishing_start_msec = -1

	if is_success:
		playtest_metrics["fishing_successes"] = int(playtest_metrics["fishing_successes"]) + 1
	else:
		playtest_metrics["fishing_failures"] = int(playtest_metrics["fishing_failures"]) + 1

	playtest_metrics["fishing_total_duration_seconds"] = (
		float(playtest_metrics["fishing_total_duration_seconds"]) + duration_seconds
	)
	var settled_attempts: int = int(playtest_metrics["fishing_successes"]) + int(playtest_metrics["fishing_failures"])
	if settled_attempts > 0:
		playtest_metrics["fishing_average_duration_seconds"] = (
			float(playtest_metrics["fishing_total_duration_seconds"]) / float(settled_attempts)
		)
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("manual_fishing_finished")


func record_playtest_purchase(source: String, product_id, coin_cost: int, resource_costs: Dictionary) -> void:
	if not _is_playtest_session_ready():
		return
	if source.strip_edges().is_empty():
		push_warning("Playtest purchase source is empty.")
		return
	if coin_cost <= 0:
		push_warning("Playtest purchase coin cost must be greater than zero: source=%s, cost=%s" % [source, coin_cost])
		return

	var spending_by_source: Dictionary = playtest_metrics["coin_spending_by_source"]
	spending_by_source[source] = int(spending_by_source.get(source, 0)) + coin_cost
	playtest_metrics["coin_spending_by_source"] = spending_by_source
	playtest_metrics["total_coin_spending"] = int(playtest_metrics["total_coin_spending"]) + coin_cost

	var event: Dictionary = {
		"source": source,
		"product_id": _serialize_product_id(product_id),
		"day_id": CURRENT_DAY_ID,
		"elapsed_seconds": _get_playtest_elapsed_seconds(),
		"coin_cost": coin_cost,
		"resource_costs": _serialize_item_costs(resource_costs),
		"coin_balance_after": get_coins(),
		"inventory_after": get_playtest_inventory_snapshot()
	}
	var events: Array = playtest_metrics["purchase_events"]
	events.append(event)
	playtest_metrics["purchase_events"] = events
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("purchase_%s" % source)


func record_playtest_machine_placement(source: String, machine_id, material_costs: Dictionary, grid_coord: Vector2i) -> void:
	if not _is_playtest_session_ready():
		return
	if source.strip_edges().is_empty():
		push_warning("Playtest machine placement source is empty.")
		return

	var event: Dictionary = {
		"source": source,
		"machine_id": _serialize_product_id(machine_id),
		"day_id": CURRENT_DAY_ID,
		"elapsed_seconds": _get_playtest_elapsed_seconds(),
		"material_costs": _serialize_item_costs(material_costs),
		"inventory_after": get_playtest_inventory_snapshot(),
		"grid_coord": {
			"x": grid_coord.x,
			"y": grid_coord.y
		}
	}
	var events: Array = playtest_metrics["machine_placement_events"]
	events.append(event)
	playtest_metrics["machine_placement_events"] = events
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("machine_placement_%s" % source)


func record_playtest_day_end(day_id: int, active_crop_count: int, placed_machine_count: int) -> void:
	if not _is_playtest_session_ready():
		return
	if day_id == _playtest_last_recorded_day_id:
		push_warning("Playtest day end already recorded for day %s." % day_id)
		return

	var snapshot: Dictionary = _build_playtest_day_snapshot(day_id, active_crop_count, placed_machine_count)
	var snapshots: Array = playtest_metrics["day_snapshots"]
	snapshots.append(snapshot)
	playtest_metrics["day_snapshots"] = snapshots
	_playtest_last_recorded_day_id = day_id

	if day_id == 5:
		playtest_metrics["day5_final_snapshot"] = snapshot.duplicate(true)
		print("DAY 5 PLAYTEST COMPLETE")
		print("Playtest telemetry log: %s" % ProjectSettings.globalize_path(playtest_log_path))

	save_playtest_log("day_%s_end" % day_id)
	_playtest_day_started_msec = Time.get_ticks_msec()


func _build_playtest_day_snapshot(day_id: int, active_crop_count: int, placed_machine_count: int) -> Dictionary:
	return {
		"day_id": day_id,
		"real_day_duration_seconds": float(Time.get_ticks_msec() - _playtest_day_started_msec) / 1000.0,
		"coin_balance": get_coins(),
		"full_inventory": get_playtest_inventory_snapshot(),
		"active_crop_count": active_crop_count,
		"placed_machine_count": placed_machine_count,
		"cumulative_coin_income": int(playtest_metrics["total_coin_income"]),
		"cumulative_coin_spending": int(playtest_metrics["total_coin_spending"]),
		"coin_income_by_source": (playtest_metrics["coin_income_by_source"] as Dictionary).duplicate(true),
		"coin_spending_by_source": (playtest_metrics["coin_spending_by_source"] as Dictionary).duplicate(true),
		"fishing_attempts": int(playtest_metrics["fishing_attempts"]),
		"fishing_successes": int(playtest_metrics["fishing_successes"]),
		"fishing_failures": int(playtest_metrics["fishing_failures"]),
		"fishing_average_duration_seconds": float(playtest_metrics["fishing_average_duration_seconds"])
	}


func _is_playtest_session_ready() -> bool:
	if not PLAYTEST_TELEMETRY_ENABLED:
		return false
	if playtest_metrics.is_empty():
		start_playtest_session()
	return not playtest_metrics.is_empty()


func _get_playtest_elapsed_seconds() -> float:
	if playtest_metrics.is_empty() or int(playtest_metrics.get("session_started_msec", 0)) <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - int(playtest_metrics["session_started_msec"])) / 1000.0


func _serialize_item_costs(costs: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for item in costs:
		serialized[_get_item_telemetry_key(item)] = int(costs[item])
	return serialized


func _get_item_telemetry_key(item) -> String:
	if ITEM_TELEMETRY_KEYS.has(item):
		return ITEM_TELEMETRY_KEYS[item]
	return "item_%s" % item


func _serialize_product_id(product_id) -> String:
	if product_id is int:
		var product_int: int = int(product_id)
		if product_int >= 0 and product_int < Enum.Machine.keys().size():
			return "machine_%s" % String(Enum.Machine.keys()[product_int]).to_lower()
		if product_int >= 0 and product_int < Enum.Style.keys().size():
			return "style_%s" % String(Enum.Style.keys()[product_int]).to_lower()
	return str(product_id)


const SEED_TO_SEED_ITEM: Dictionary = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO_SEED,
	Enum.Seed.CORN: Enum.Item.CORN_SEED,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN_SEED,
	Enum.Seed.WHEAT: Enum.Item.WHEAT_SEED}


const SEED_TO_CROP_ITEM: Dictionary = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT}


# Deprecated compatibility map.
# Do not use for planting or harvesting.
# Scheduled for removal after Seed/Crop migration validation.
var SEED_TO_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT
}


var KEYBOARD_KEYS = {
	Enum.KEYBOARD.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyH.png"),
	Enum.KEYBOARD.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyM.png"),
	Enum.KEYBOARD.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.KEYBOARD.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyC.png"),
	Enum.KEYBOARD.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyT.png"),
	Enum.KEYBOARD.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.KEYBOARD.ACTION :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/Space.png"),
	Enum.KEYBOARD.CHANGE_DAY :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyTab.png"),
}

var KEYBOARD_CONTROLLER = {
	Enum.KEYBOARD.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusDown.png"),
	Enum.KEYBOARD.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusLeft.png"),
	Enum.KEYBOARD.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.KEYBOARD.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRight.png"),
	Enum.KEYBOARD.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonUp.png"),
	Enum.KEYBOARD.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.KEYBOARD.ACTION : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonDown.png"),
	Enum.KEYBOARD.CHANGE_DAY : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusUp.png"),
}

var MODE_TEXTURE = {
	Enum.State.DEFAULT : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.FISHING : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.SHOP : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.BUILDING : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Items/Tool/Hammer.png"),
	Enum.State.HOUSE : preload("res://graphics/characters/farming_mode.png")
	
}


var KEYBOARD_TO_ICONS = {
	Enum.KEYBOARD.CHANGE_MODE: MODE_TEXTURE,
	Enum.KEYBOARD.CHANGE_TOOL: TOOL_TEXTURES,
	Enum.KEYBOARD.CHANGE_MACHINE: MACHINE_TEXTURES,	
	Enum.KEYBOARD.CHANGE_SEED: SEED_TEXTURES,
	Enum.KEYBOARD.CHANGE_STYLE: STYLE_TEXTURES,
	Enum.KEYBOARD.ACTION: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Emote/emote21.png")},
	Enum.KEYBOARD.CHANGE_DAY: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Skill Icon/Meteo/Moon.png")},
	Enum.KEYBOARD.CHANGE_HIGHLIGHT: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_unchecked.png"),
									 1: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_checked.png")},
	
} 

var ControllerConnected = false
