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
const ITEM_BUY_PRICES: Dictionary = {
	Enum.Item.WHEAT_SEED: 10,
	Enum.Item.CORN_SEED: 12,
	Enum.Item.TOMATO_SEED: 18,
	Enum.Item.PUMPKIN_SEED: 30,
	Enum.Item.WHEAT: 18,
	Enum.Item.CORN: 22,
	Enum.Item.TOMATO: 38,
	Enum.Item.PUMPKIN: 120,
	# Deprecated compatibility price. Generic FISH is not in TRADEABLE_ITEMS
	# and cannot be actively bought.
	Enum.Item.FISH: 22,
	Enum.Item.GRAY_CARP: 16,
	Enum.Item.SILVER_PERCH: 24,
	Enum.Item.GOLDEN_KOI: 38,
	Enum.Item.RED_SNAPPER: 65,
	Enum.Item.WOOD: 8,
	Enum.Item.APPLE: 10}

const ITEM_SELL_PRICES: Dictionary = {
	Enum.Item.WHEAT_SEED: 8,
	Enum.Item.CORN_SEED: 9,
	Enum.Item.TOMATO_SEED: 13,
	Enum.Item.PUMPKIN_SEED: 22,
	Enum.Item.WHEAT: 12,
	Enum.Item.CORN: 15,
	Enum.Item.TOMATO: 25,
	Enum.Item.PUMPKIN: 80,
	# Deprecated compatibility price. Generic FISH is not in TRADEABLE_ITEMS
	# and cannot be actively sold.
	Enum.Item.FISH: 15,
	Enum.Item.GRAY_CARP: 9,
	Enum.Item.SILVER_PERCH: 14,
	Enum.Item.GOLDEN_KOI: 24,
	Enum.Item.RED_SNAPPER: 42,
	Enum.Item.WOOD: 5,
	Enum.Item.APPLE: 6}

const TRADEABLE_ITEMS: Array[Enum.Item] = [
	Enum.Item.WHEAT_SEED,
	Enum.Item.CORN_SEED,
	Enum.Item.TOMATO_SEED,
	Enum.Item.PUMPKIN_SEED,
	Enum.Item.WHEAT,
	Enum.Item.CORN,
	Enum.Item.TOMATO,
	Enum.Item.PUMPKIN,
	Enum.Item.GRAY_CARP,
	Enum.Item.SILVER_PERCH,
	Enum.Item.GOLDEN_KOI,
	Enum.Item.RED_SNAPPER,
	Enum.Item.WOOD,
	Enum.Item.APPLE]

const VISIBLE_INVENTORY_ITEMS: Array[Enum.Item] = [
	Enum.Item.WOOD,
	Enum.Item.APPLE,
	Enum.Item.GRAY_CARP,
	Enum.Item.SILVER_PERCH,
	Enum.Item.GOLDEN_KOI,
	Enum.Item.RED_SNAPPER,
	Enum.Item.CORN,
	Enum.Item.WHEAT,
	Enum.Item.PUMPKIN,
	Enum.Item.TOMATO,
	Enum.Item.TOMATO_SEED,
	Enum.Item.CORN_SEED,
	Enum.Item.PUMPKIN_SEED,
	Enum.Item.WHEAT_SEED]

# Phase H3B: fishing now rolls concrete species. Generic Enum.Item.FISH remains
# only for deprecated compatibility metadata and old inventory snapshots.
const FISH_SPECIES_ITEMS: Array[Enum.Item] = [
	Enum.Item.GRAY_CARP,
	Enum.Item.SILVER_PERCH,
	Enum.Item.GOLDEN_KOI,
	Enum.Item.RED_SNAPPER]

const FISH_RARITIES: Dictionary = {
	Enum.Item.GRAY_CARP: "common",
	Enum.Item.SILVER_PERCH: "common_uncommon",
	Enum.Item.GOLDEN_KOI: "uncommon_rare",
	Enum.Item.RED_SNAPPER: "rare"}

const MANUAL_FISHING_DROP_TABLE: Array[Dictionary] = [
	{"item": Enum.Item.GRAY_CARP, "weight": 50},
	{"item": Enum.Item.SILVER_PERCH, "weight": 30},
	{"item": Enum.Item.GOLDEN_KOI, "weight": 15},
	{"item": Enum.Item.RED_SNAPPER, "weight": 5}]

const AUTOMATIC_FISHER_DROP_TABLE: Array[Dictionary] = [
	{"item": Enum.Item.GRAY_CARP, "weight": 70},
	{"item": Enum.Item.SILVER_PERCH, "weight": 30}]

const MANUAL_FISHING_PROFILES: Dictionary = {
	Enum.Item.GRAY_CARP: {
		"move_speed": 0.28,
		"retarget_min": 1.2,
		"retarget_max": 2.0,
		"dart_chance": 0.0,
		"jitter": 0.015},
	Enum.Item.SILVER_PERCH: {
		"move_speed": 0.38,
		"retarget_min": 0.8,
		"retarget_max": 1.4,
		"dart_chance": 0.08,
		"jitter": 0.035},
	Enum.Item.GOLDEN_KOI: {
		"move_speed": 0.52,
		"retarget_min": 0.45,
		"retarget_max": 0.9,
		"dart_chance": 0.18,
		"jitter": 0.055},
	Enum.Item.RED_SNAPPER: {
		"move_speed": 0.65,
		"retarget_min": 0.3,
		"retarget_max": 0.7,
		"dart_chance": 0.28,
		"jitter": 0.075}}

const ITEM_CATEGORIES: Dictionary = {
	&"fish": [
		Enum.Item.GRAY_CARP,
		Enum.Item.SILVER_PERCH,
		Enum.Item.GOLDEN_KOI,
		Enum.Item.RED_SNAPPER]}

const CATEGORY_DISPLAY_NAMES: Dictionary = {
	&"fish": "Any Fish"}

const CATEGORY_ICON_ITEMS: Dictionary = {
	&"fish": Enum.Item.GRAY_CARP}

# Backward-compatible aliases for the old Courier seller API.
const SELL_PRICES: Dictionary = ITEM_SELL_PRICES
const SELLABLE_ITEMS: Array[Enum.Item] = TRADEABLE_ITEMS

const SALE_TELEMETRY_SOURCES: Dictionary = {
	Enum.Item.WHEAT_SEED: "sale_wheat_seed",
	Enum.Item.CORN_SEED: "sale_corn_seed",
	Enum.Item.TOMATO_SEED: "sale_tomato_seed",
	Enum.Item.PUMPKIN_SEED: "sale_pumpkin_seed",
	Enum.Item.WHEAT: "sale_wheat",
	Enum.Item.CORN: "sale_corn",
	Enum.Item.TOMATO: "sale_tomato",
	Enum.Item.PUMPKIN: "sale_pumpkin",
	# Historical compatibility source only. New runtime transactions cannot
	# generate this source because Generic FISH is not tradeable.
	Enum.Item.FISH: "sale_fish",
	Enum.Item.GRAY_CARP: "sale_gray_carp",
	Enum.Item.SILVER_PERCH: "sale_silver_perch",
	Enum.Item.GOLDEN_KOI: "sale_golden_koi",
	Enum.Item.RED_SNAPPER: "sale_red_snapper",
	Enum.Item.WOOD: "sale_wood",
	Enum.Item.APPLE: "sale_apple"}

const BUY_TELEMETRY_SOURCES: Dictionary = {
	Enum.Item.WHEAT_SEED: "buy_wheat_seed",
	Enum.Item.CORN_SEED: "buy_corn_seed",
	Enum.Item.TOMATO_SEED: "buy_tomato_seed",
	Enum.Item.PUMPKIN_SEED: "buy_pumpkin_seed",
	Enum.Item.WHEAT: "buy_wheat",
	Enum.Item.CORN: "buy_corn",
	Enum.Item.TOMATO: "buy_tomato",
	Enum.Item.PUMPKIN: "buy_pumpkin",
	# Historical compatibility source only. New runtime transactions cannot
	# generate this source because Generic FISH is not tradeable.
	Enum.Item.FISH: "buy_fish",
	Enum.Item.GRAY_CARP: "buy_gray_carp",
	Enum.Item.SILVER_PERCH: "buy_silver_perch",
	Enum.Item.GOLDEN_KOI: "buy_golden_koi",
	Enum.Item.RED_SNAPPER: "buy_red_snapper",
	Enum.Item.WOOD: "buy_wood",
	Enum.Item.APPLE: "buy_apple"}

const MERCHANT_CATALOGS: Dictionary = {
	"courier": {
		"name": "Courier",
		"items": TRADEABLE_ITEMS,
		"unlocks": []},
	"cat": {
		"name": "Cat",
		"items": [],
		"unlocks": [
			{"type": "machine", "id": Enum.Machine.SPRINKLER},
			{"type": "machine", "id": Enum.Machine.FISHER},
			{"type": "machine", "id": Enum.Machine.SCARECROW}]},
	"mouse": {
		"name": "Mouse",
		"items": [],
		"unlocks": [
			{"type": "style", "id": Enum.Style.COWBOY},
			{"type": "style", "id": Enum.Style.BASEBALL},
			{"type": "style", "id": Enum.Style.BEANIE}]}}

# One-time coin cost for permanently unlocking a machine blueprint. (Phase G v3)
const MACHINE_BLUEPRINT_COIN_COSTS: Dictionary = {
	Enum.Machine.SPRINKLER: 250,
	Enum.Machine.FISHER: 350,
	Enum.Machine.SCARECROW: 500}

# Material recipe consumed for every successfully placed machine instance.
const MACHINE_PLACEMENT_COSTS: Dictionary = {
	Enum.Machine.SPRINKLER: {
		Enum.Item.WOOD: 10},
	Enum.Machine.FISHER: {
		Enum.Item.WOOD: 15},
	Enum.Machine.SCARECROW: {
		Enum.Item.WOOD: 20}}

const MACHINE_CATEGORY_COSTS: Dictionary = {}

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
const PLAYTEST_RUN_LABEL: String = "V3_FISH_SPECIES"
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
	Enum.Item.GRAY_CARP: "gray_carp",
	Enum.Item.SILVER_PERCH: "silver_perch",
	Enum.Item.GOLDEN_KOI: "golden_koi",
	Enum.Item.RED_SNAPPER: "red_snapper",
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
	Enum.Item.GRAY_CARP: "res://graphics/icons/grayfish.png",
	Enum.Item.SILVER_PERCH: "res://graphics/icons/silverfish.png",
	Enum.Item.GOLDEN_KOI: "res://graphics/icons/goldfish.png",
	Enum.Item.RED_SNAPPER: "res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetRed.png",
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
	Enum.Item.GRAY_CARP: preload("res://graphics/icons/grayfish.png"),
	Enum.Item.SILVER_PERCH: preload("res://graphics/icons/silverfish.png"),
	Enum.Item.GOLDEN_KOI: preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT: preload("res://graphics/icons/wheat.png")}

const COIN_ICON_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Icons/special icons/Special Icons.png")
const SPROUT_LANDS_EMOJI_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png")
const RED_SNAPPER_TEXTURE_SHEET: Texture2D = preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetRed.png")

# Temporary fourth fish icon. Keep the RED_SNAPPER item ID stable if the
# texture is replaced later.
const FISH_ITEM_TEXTURE_REGIONS: Dictionary = {
	Enum.Item.RED_SNAPPER: Rect2(0, 0, 16, 16)}

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
	Enum.Item.GRAY_CARP: 0,
	Enum.Item.SILVER_PERCH: 0,
	Enum.Item.GOLDEN_KOI: 0,
	Enum.Item.RED_SNAPPER: 0,
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
	Enum.Item.GRAY_CARP: &"GRAY_CARP",
	Enum.Item.SILVER_PERCH: &"SILVER_PERCH",
	Enum.Item.GOLDEN_KOI: &"GOLDEN_KOI",
	Enum.Item.RED_SNAPPER: &"RED_SNAPPER",
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
	&"GRAY_CARP": Enum.Item.GRAY_CARP,
	&"SILVER_PERCH": Enum.Item.SILVER_PERCH,
	&"GOLDEN_KOI": Enum.Item.GOLDEN_KOI,
	&"RED_SNAPPER": Enum.Item.RED_SNAPPER,
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
	&"GRAY_CARP": "Gray Carp",
	&"SILVER_PERCH": "Silver Perch",
	&"GOLDEN_KOI": "Golden Koi",
	&"RED_SNAPPER": "Red Snapper",
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
func is_item_tradeable(item: Enum.Item) -> bool:
	return TRADEABLE_ITEMS.has(item)


func is_item_sellable(item: Enum.Item) -> bool:
	return is_item_tradeable(item)


func get_buy_price(item: Enum.Item) -> int:
	if not ITEM_BUY_PRICES.has(item):
		return 0
	return int(ITEM_BUY_PRICES[item])


func get_sell_price(item: Enum.Item) -> int:
	if not ITEM_SELL_PRICES.has(item):
		return 0
	return int(ITEM_SELL_PRICES[item])


func try_buy_item(item: Enum.Item, quantity: int, merchant_id: String = "courier") -> int:
	if not is_item_tradeable(item):
		push_warning("Item is not tradeable: %s" % item)
		return 0
	if not ITEM_BUY_PRICES.has(item):
		push_warning("Missing buy price for item: %s" % item)
		return 0
	var unit_price: int = int(ITEM_BUY_PRICES[item])
	if unit_price <= 0:
		push_warning("Buy unit price must be greater than zero: item=%s" % item)
		return 0
	if quantity <= 0:
		return 0
	var total: int = unit_price * quantity
	if total <= 0:
		push_warning("Invalid buy total: item=%s, quantity=%s" % [item, quantity])
		return 0
	if get_coins() < total:
		return 0

	var owned: int = int(ITEMS_AMOUNT.get(item, 0))
	if not spend_coins(total):
		return 0
	ITEMS_AMOUNT[item] = owned + quantity

	var telemetry_source: String = BUY_TELEMETRY_SOURCES.get(item, "")
	if not telemetry_source.is_empty():
		record_playtest_coin_spending(telemetry_source, total)
	record_playtest_trade_buy(merchant_id, item, quantity, unit_price, total)
	return quantity


# Atomic sale. Returns total coins earned, or 0 on any failure.
# On failure nothing changes: no item removed, no coin added, no telemetry.
func try_sell_item(item: Enum.Item, quantity: int, merchant_id: String = "courier") -> int:
	if not is_item_sellable(item):
		push_warning("Item is not sellable: %s" % item)
		return 0
	if not ITEM_SELL_PRICES.has(item):
		push_warning("Missing sell price for item: %s" % item)
		return 0
	var unit_price: int = int(ITEM_SELL_PRICES[item])
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
		ITEMS_AMOUNT[item] = owned
		return 0

	var telemetry_source: String = SALE_TELEMETRY_SOURCES.get(item, "")
	if not telemetry_source.is_empty():
		record_playtest_coin_income(telemetry_source, total)
	record_playtest_sale(item, quantity, unit_price, total, merchant_id)
	return total


func get_unlock_display_name(unlock_type: String, product_id: int) -> String:
	var source: Dictionary = _get_unlock_source(unlock_type)
	if source.has(product_id) and source[product_id].has("name"):
		return source[product_id]["name"]
	return "%s %s" % [unlock_type, product_id]


func get_unlock_texture(unlock_type: String, product_id: int) -> Texture2D:
	var source: Dictionary = _get_unlock_source(unlock_type)
	if source.has(product_id) and source[product_id].has("icon"):
		return source[product_id]["icon"]
	return null


func get_unlock_coin_cost(unlock_type: String, product_id: int) -> int:
	if unlock_type == "machine":
		return int(MACHINE_BLUEPRINT_COIN_COSTS.get(product_id, 0))
	if unlock_type == "style":
		return int(STYLE_COIN_COSTS.get(product_id, 0))
	return 0


func get_unlock_resource_costs(unlock_type: String, product_id: int) -> Dictionary:
	if unlock_type == "style":
		return STYLE_RESOURCE_COSTS.get(product_id, {})
	return {}


func is_unlock_owned(unlock_type: String, product_id: int) -> bool:
	if unlock_type == "machine":
		return product_id in unlocked_machines
	if unlock_type == "style":
		return product_id in unlocked_styles
	return false


func try_buy_unlock(merchant_id: String, unlock_type: String, product_id: int) -> bool:
	if not MERCHANT_CATALOGS.has(merchant_id):
		push_warning("Unknown merchant id for unlock purchase: %s" % merchant_id)
		return false
	if unlock_type != "machine" and unlock_type != "style":
		push_warning("Unknown unlock type: %s" % unlock_type)
		return false
	if is_unlock_owned(unlock_type, product_id):
		return false
	var coin_cost: int = get_unlock_coin_cost(unlock_type, product_id)
	if coin_cost <= 0:
		push_warning("Missing unlock coin cost: type=%s, id=%s" % [unlock_type, product_id])
		return false
	var resource_costs: Dictionary = get_unlock_resource_costs(unlock_type, product_id)
	if get_coins() < coin_cost:
		return false
	for item in resource_costs:
		var required: int = int(resource_costs[item])
		if required <= 0:
			push_warning("Unlock resource cost must be greater than zero: item=%s" % item)
			return false
		if int(ITEMS_AMOUNT.get(item, 0)) < required:
			return false

	if not spend_coins(coin_cost):
		return false
	for item in resource_costs:
		ITEMS_AMOUNT[item] -= int(resource_costs[item])

	if unlock_type == "machine":
		unlocked_machines.append(product_id)
	elif unlock_type == "style":
		unlocked_styles.append(product_id)
	else:
		push_warning("Unknown unlock type after purchase validation: %s" % unlock_type)
		return false

	var telemetry_source: String = _get_unlock_telemetry_source(unlock_type, product_id)
	if not telemetry_source.is_empty():
		record_playtest_purchase(telemetry_source, "%s_%s" % [unlock_type, product_id], coin_cost, resource_costs)
	return true


func _get_unlock_source(unlock_type: String) -> Dictionary:
	if unlock_type == "machine":
		return MACHINE_UPGRADE_COST
	if unlock_type == "style":
		return STYLE_UPGRADES
	return {}


func _get_unlock_telemetry_source(unlock_type: String, product_id: int) -> String:
	if unlock_type == "machine":
		return MACHINE_BLUEPRINT_TELEMETRY_SOURCES.get(product_id, "")
	if unlock_type == "style":
		return STYLE_PURCHASE_TELEMETRY_SOURCES.get(product_id, "")
	return ""


func is_fish_species(item: Enum.Item) -> bool:
	return FISH_SPECIES_ITEMS.has(item)


func get_fish_rarity(item: Enum.Item) -> String:
	if not FISH_RARITIES.has(item):
		return ""
	return String(FISH_RARITIES[item])


func resolve_weighted_item(drop_table: Array, roll_value: int) -> int:
	var seen_items: Dictionary = {}
	var total_weight: int = 0
	for entry in drop_table:
		if not (entry is Dictionary):
			push_warning("Weighted drop entry must be a Dictionary.")
			return -1
		var entry_data: Dictionary = entry
		if not entry_data.has("item") or not entry_data.has("weight"):
			push_warning("Weighted drop entry is missing item or weight.")
			return -1
		var item = entry_data["item"]
		if not (item is int) or not ITEM_IDS.has(item):
			push_warning("Weighted drop entry has an invalid item: %s" % item)
			return -1
		if seen_items.has(item):
			push_warning("Weighted drop table contains duplicate item: %s" % item)
			return -1
		var weight = entry_data["weight"]
		if not (weight is int):
			push_warning("Weighted drop entry weight must be an integer: item=%s" % item)
			return -1
		var item_weight: int = int(weight)
		if item_weight <= 0:
			push_warning("Weighted drop entry weight must be greater than zero: item=%s" % item)
			return -1

		seen_items[item] = true
		total_weight += item_weight

	if total_weight <= 0:
		push_warning("Weighted drop table has no positive total weight.")
		return -1
	if roll_value < 1 or roll_value > total_weight:
		push_warning("Weighted roll out of range: roll=%s, total=%s" % [roll_value, total_weight])
		return -1

	var cumulative_weight: int = 0
	for entry in drop_table:
		var entry_data: Dictionary = entry
		cumulative_weight += int(entry_data["weight"])
		if roll_value <= cumulative_weight:
			return int(entry_data["item"])

	push_warning("Weighted roll failed to resolve despite valid range: roll=%s, total=%s" % [roll_value, total_weight])
	return -1


func roll_weighted_item(drop_table: Array) -> int:
	var total_weight: int = _get_weighted_drop_table_total(drop_table)
	if total_weight <= 0:
		return -1
	return resolve_weighted_item(drop_table, randi_range(1, total_weight))


func roll_manual_fish_species() -> int:
	var fish_item: int = roll_weighted_item(MANUAL_FISHING_DROP_TABLE)
	if is_fish_species(fish_item):
		return fish_item

	push_warning("Manual fishing roll failed; using Gray Carp fallback.")
	return Enum.Item.GRAY_CARP


func roll_automatic_fish_species() -> int:
	var fish_item: int = roll_weighted_item(AUTOMATIC_FISHER_DROP_TABLE)
	if fish_item == Enum.Item.GRAY_CARP or fish_item == Enum.Item.SILVER_PERCH:
		return fish_item

	push_warning("Automatic Fisher drop table failed; using Gray Carp fallback.")
	return Enum.Item.GRAY_CARP


func get_visible_inventory_items() -> Array:
	return VISIBLE_INVENTORY_ITEMS.duplicate()


func get_category_items(category_id: StringName) -> Array:
	if not ITEM_CATEGORIES.has(category_id):
		return []
	return (ITEM_CATEGORIES[category_id] as Array).duplicate()


func get_category_display_name(category_id: StringName) -> String:
	if CATEGORY_DISPLAY_NAMES.has(category_id):
		return String(CATEGORY_DISPLAY_NAMES[category_id])
	return String(category_id).capitalize()


func get_category_icon_item(category_id: StringName) -> int:
	if CATEGORY_ICON_ITEMS.has(category_id):
		return int(CATEGORY_ICON_ITEMS[category_id])
	return -1


func get_total_category_amount(category_id: StringName) -> int:
	var total_amount: int = 0
	for item in get_category_items(category_id):
		total_amount += int(ITEMS_AMOUNT.get(item, 0))
	return total_amount


func can_afford_category_cost(category_id: StringName, required_amount: int) -> bool:
	if required_amount <= 0:
		return false
	if get_category_items(category_id).is_empty():
		return false
	return get_total_category_amount(category_id) >= required_amount


func build_category_consumption_plan(category_id: StringName, required_amount: int) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"items": {}
	}
	if not can_afford_category_cost(category_id, required_amount):
		return result

	var sorted_items: Array = get_category_items(category_id)
	sorted_items.sort_custom(func(a, b) -> bool:
		var price_a: int = get_sell_price(a)
		var price_b: int = get_sell_price(b)
		if price_a != price_b:
			return price_a < price_b
		var owned_a: int = int(ITEMS_AMOUNT.get(a, 0))
		var owned_b: int = int(ITEMS_AMOUNT.get(b, 0))
		if owned_a != owned_b:
			return owned_a > owned_b
		return int(a) < int(b)
	)

	var remaining: int = required_amount
	var plan_items: Dictionary = {}
	for item in sorted_items:
		if remaining <= 0:
			break
		var owned: int = int(ITEMS_AMOUNT.get(item, 0))
		if owned <= 0:
			continue
		var consumed: int = min(owned, remaining)
		plan_items[item] = consumed
		remaining -= consumed

	if remaining != 0:
		return result

	result["success"] = true
	result["items"] = plan_items
	return result


func build_machine_placement_cost_plan(machine_id: int) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"item_costs": {},
		"category_costs": {},
		"category_consumption": {}
	}
	if not MACHINE_PLACEMENT_COSTS.has(machine_id):
		push_warning("Missing machine placement cost for machine id: %s" % machine_id)
		return result

	var item_costs: Dictionary = {}
	for item in MACHINE_PLACEMENT_COSTS[machine_id]:
		var required_amount: int = int(MACHINE_PLACEMENT_COSTS[machine_id][item])
		if required_amount <= 0:
			push_warning("Machine placement material cost must be greater than zero: item=%s, cost=%s" %
				[item, required_amount])
			return result
		if int(ITEMS_AMOUNT.get(item, 0)) < required_amount:
			return result
		item_costs[item] = required_amount

	var category_costs: Dictionary = {}
	var category_consumption: Dictionary = {}
	var machine_category_costs: Dictionary = MACHINE_CATEGORY_COSTS.get(machine_id, {})
	for category_id in machine_category_costs:
		var category_key: StringName = category_id
		var required_category_amount: int = int(machine_category_costs[category_id])
		if required_category_amount <= 0:
			push_warning("Machine category cost must be greater than zero: category=%s, cost=%s" %
				[category_key, required_category_amount])
			return result
		var category_plan: Dictionary = build_category_consumption_plan(category_key, required_category_amount)
		if not bool(category_plan.get("success", false)):
			return result
		category_costs[category_key] = required_category_amount
		category_consumption[category_key] = category_plan["items"]

	result["success"] = true
	result["item_costs"] = item_costs
	result["category_costs"] = category_costs
	result["category_consumption"] = category_consumption
	return result


func can_afford_machine_placement_costs(machine_id: int) -> bool:
	return bool(build_machine_placement_cost_plan(machine_id).get("success", false))


func consume_machine_placement_cost_plan(cost_plan: Dictionary) -> bool:
	if not bool(cost_plan.get("success", false)):
		return false

	var item_costs: Dictionary = cost_plan.get("item_costs", {})
	var category_costs: Dictionary = cost_plan.get("category_costs", {})
	var category_consumption: Dictionary = cost_plan.get("category_consumption", {})

	for item in item_costs:
		var required_amount: int = int(item_costs[item])
		if required_amount <= 0 or int(ITEMS_AMOUNT.get(item, 0)) < required_amount:
			return false

	for category_id in category_costs:
		var category_key: StringName = category_id
		var required_category_amount: int = int(category_costs[category_id])
		if required_category_amount <= 0:
			return false
		if not category_consumption.has(category_key):
			return false
		if not can_afford_category_cost(category_key, required_category_amount):
			return false
		var category_items: Array = get_category_items(category_key)
		var planned_items: Dictionary = category_consumption[category_key]
		var planned_total: int = 0
		for item in planned_items:
			var planned_amount: int = int(planned_items[item])
			if planned_amount <= 0:
				return false
			if not category_items.has(item):
				return false
			if int(ITEMS_AMOUNT.get(item, 0)) < planned_amount:
				return false
			planned_total += planned_amount
		if planned_total != required_category_amount:
			return false

	for item in item_costs:
		ITEMS_AMOUNT[item] = int(ITEMS_AMOUNT.get(item, 0)) - int(item_costs[item])
	for category_id in category_consumption:
		var planned_items: Dictionary = category_consumption[category_id]
		for item in planned_items:
			ITEMS_AMOUNT[item] = int(ITEMS_AMOUNT.get(item, 0)) - int(planned_items[item])
	return true


func get_item_texture(item: Enum.Item) -> Texture2D:
	if item == Enum.Item.COIN:
		var coin_texture := AtlasTexture.new()
		coin_texture.atlas = COIN_ICON_SHEET
		coin_texture.region = Rect2(96, 0, 16, 16)
		return coin_texture

	if FISH_ITEM_TEXTURE_REGIONS.has(item):
		return _create_atlas_texture(RED_SNAPPER_TEXTURE_SHEET, FISH_ITEM_TEXTURE_REGIONS[item])

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
		"fish_catches_by_species": {
			"gray_carp": 0,
			"silver_perch": 0,
			"golden_koi": 0,
			"red_snapper": 0
		},
		"fish_catch_events": [],
		"trade_buy_events": [],
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


func record_playtest_coin_spending(source: String, amount: int) -> void:
	if not _is_playtest_session_ready():
		return
	if amount <= 0:
		push_warning("Playtest coin spending amount must be greater than zero: source=%s, amount=%s" % [source, amount])
		return
	if source.strip_edges().is_empty():
		push_warning("Playtest coin spending source is empty.")
		return

	var spending_by_source: Dictionary = playtest_metrics["coin_spending_by_source"]
	spending_by_source[source] = int(spending_by_source.get(source, 0)) + amount
	playtest_metrics["coin_spending_by_source"] = spending_by_source
	playtest_metrics["total_coin_spending"] = int(playtest_metrics["total_coin_spending"]) + amount
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("coin_spending_%s" % source)


func record_playtest_trade_buy(merchant_id: String, item: Enum.Item, quantity: int, unit_price: int, coin_spent: int) -> void:
	if not _is_playtest_session_ready():
		return
	if not playtest_metrics.has("trade_buy_events"):
		playtest_metrics["trade_buy_events"] = []

	var event: Dictionary = {
		"merchant_id": merchant_id,
		"day_id": CURRENT_DAY_ID,
		"elapsed_seconds": _get_playtest_elapsed_seconds(),
		"item_id": String(get_item_id(item)),
		"quantity": quantity,
		"unit_price": unit_price,
		"coin_spent": coin_spent,
		"coin_balance_after": get_coins(),
		"inventory_amount_after": int(ITEMS_AMOUNT.get(item, 0))
	}
	var events: Array = playtest_metrics["trade_buy_events"]
	events.append(event)
	playtest_metrics["trade_buy_events"] = events
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()
	save_playtest_log("buy_%s" % String(get_item_id(item)).to_lower())


func record_playtest_sale(item: Enum.Item, quantity: int, unit_price: int, coin_earned: int, merchant_id: String = "courier") -> void:
	if not _is_playtest_session_ready():
		return
	if not playtest_metrics.has("sale_events"):
		playtest_metrics["sale_events"] = []

	var event: Dictionary = {
		"merchant_id": merchant_id,
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


func record_fish_catch(item: int, source: String) -> void:
	if not is_fish_species(item):
		push_warning("Fish catch telemetry ignored for non-species item: %s" % item)
		return
	if source != "manual" and source != "automatic_fisher":
		push_warning("Fish catch telemetry ignored for invalid source: %s" % source)
		return
	if not ITEM_TELEMETRY_KEYS.has(item):
		push_warning("Fish catch telemetry missing item key: %s" % item)
		return
	var rarity: String = get_fish_rarity(item)
	if rarity.is_empty():
		push_warning("Fish catch telemetry missing rarity: %s" % item)
		return
	if not _is_playtest_session_ready():
		return

	if not playtest_metrics.has("fish_catches_by_species") or not (playtest_metrics["fish_catches_by_species"] is Dictionary):
		playtest_metrics["fish_catches_by_species"] = _create_empty_fish_catch_totals()
	if not playtest_metrics.has("fish_catch_events") or not (playtest_metrics["fish_catch_events"] is Array):
		playtest_metrics["fish_catch_events"] = []

	var species_key: String = String(ITEM_TELEMETRY_KEYS[item])
	var catches_by_species: Dictionary = playtest_metrics["fish_catches_by_species"]
	for fish_item in FISH_SPECIES_ITEMS:
		var fish_key: String = String(ITEM_TELEMETRY_KEYS.get(fish_item, ""))
		if not fish_key.is_empty() and not catches_by_species.has(fish_key):
			catches_by_species[fish_key] = 0
	catches_by_species[species_key] = int(catches_by_species.get(species_key, 0)) + 1
	playtest_metrics["fish_catches_by_species"] = catches_by_species

	var event: Dictionary = {
		"day_id": CURRENT_DAY_ID,
		"elapsed_seconds": _get_playtest_elapsed_seconds(),
		"source": source,
		"item_id": String(get_item_id(item)),
		"rarity": rarity,
		"inventory_amount_after": int(ITEMS_AMOUNT.get(item, 0))
	}
	var events: Array = playtest_metrics["fish_catch_events"]
	events.append(event)
	playtest_metrics["fish_catch_events"] = events
	playtest_metrics["current_inventory"] = get_playtest_inventory_snapshot()


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


func record_playtest_machine_placement(
	source: String,
	machine_id,
	material_costs: Dictionary,
	grid_coord: Vector2i,
	category_costs: Dictionary = {},
	category_materials_consumed: Dictionary = {}
) -> void:
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
		"resource_costs": _serialize_item_costs(material_costs),
		"category_costs": _serialize_category_costs(category_costs),
		"category_materials_consumed": _serialize_category_materials_consumed(category_materials_consumed),
		"inventory_after": get_playtest_inventory_snapshot(),
		"grid_coord": {
			"x": grid_coord.x,
			"y": grid_coord.y
		},
		"position": {
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


func _get_weighted_drop_table_total(drop_table: Array) -> int:
	var seen_items: Dictionary = {}
	var total_weight: int = 0
	for entry in drop_table:
		if not (entry is Dictionary):
			push_warning("Weighted drop entry must be a Dictionary.")
			return 0
		var entry_data: Dictionary = entry
		if not entry_data.has("item") or not entry_data.has("weight"):
			push_warning("Weighted drop entry is missing item or weight.")
			return 0
		var item = entry_data["item"]
		if not (item is int) or not ITEM_IDS.has(item):
			push_warning("Weighted drop entry has an invalid item: %s" % item)
			return 0
		if seen_items.has(item):
			push_warning("Weighted drop table contains duplicate item: %s" % item)
			return 0
		var weight = entry_data["weight"]
		if not (weight is int):
			push_warning("Weighted drop entry weight must be an integer: item=%s" % item)
			return 0
		var item_weight: int = int(weight)
		if item_weight <= 0:
			push_warning("Weighted drop entry weight must be greater than zero: item=%s" % item)
			return 0

		seen_items[item] = true
		total_weight += item_weight

	if total_weight <= 0:
		push_warning("Weighted drop table has no positive total weight.")
	return total_weight


func _create_empty_fish_catch_totals() -> Dictionary:
	var totals: Dictionary = {}
	for fish_item in FISH_SPECIES_ITEMS:
		var species_key: String = String(ITEM_TELEMETRY_KEYS.get(fish_item, ""))
		if not species_key.is_empty():
			totals[species_key] = 0
	return totals


func _get_playtest_elapsed_seconds() -> float:
	if playtest_metrics.is_empty() or int(playtest_metrics.get("session_started_msec", 0)) <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - int(playtest_metrics["session_started_msec"])) / 1000.0


func _serialize_item_costs(costs: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for item in costs:
		serialized[_get_item_telemetry_key(item)] = int(costs[item])
	return serialized


func _serialize_category_costs(costs: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for category_id in costs:
		serialized[String(category_id)] = int(costs[category_id])
	return serialized


func _serialize_category_materials_consumed(category_materials: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for category_id in category_materials:
		var item_costs: Dictionary = category_materials[category_id]
		serialized[String(category_id)] = _serialize_item_costs(item_costs)
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
