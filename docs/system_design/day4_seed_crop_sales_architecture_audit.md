# Day 4 Seed/Crop/Sales Architecture Audit

Scope: read-only architecture audit plus this new document. No gameplay code,
scene, resource, telemetry, price, or existing design document was intentionally
changed in this phase.

## 1. Current Architecture

### Runtime Files Inspected

Primary runtime autoloads:

| Area | Runtime Source | Notes |
| --- | --- | --- |
| Enum autoload | `project.godot`, `scripts/global/enums.gd` | Autoload name is `Enum`. The requested `scripts/global/enum.gd` does not exist; the actual file is `enums.gd`. |
| Data autoload | `project.godot`, `scripts/global/data.gd` | Autoload name is `Data`. Root `global/data.gd` is an older duplicate and is not the runtime autoload. |
| Quest autoload | `project.godot`, `scripts/systems/quest_manager.gd` | Receives harvest events through `QuestManager.report_event`. |

Gameplay/runtime files inspected:

| Area | Files |
| --- | --- |
| Plant resource | `resources/plant_res.gd`, `resources/tomato_res.tres` |
| Plant scene/logic | `scenes/objects/plant.tscn`, `scripts/objects/plant.gd` |
| Player seed selection/fishing | `scripts/characters/player.gd`, `scenes/characters/player.tscn` |
| Level planting/building logic | `scripts/level.gd`, `scenes/levels/level.tscn` |
| Inventory/hotbar UI | `scripts/ui/inventory.gd`, `scripts/ui/resourse_texture.gd`, `scripts/ui/tool_ui.gd`, `scripts/ui/tool_ui_texture.gd`, `scenes/ui/tool_ui.tscn` |
| Shop UI | `scripts/ui/shop_button.gd`, `scripts/ui/shop_ui.gd` |
| Quest | `data/quests/mira_still_sprouts_quest.tres`, `scripts/data/quest_objective_data.gd`, `scripts/systems/quest_manager.gd` |
| Mira | `scripts/characters/mira_npc.gd`, `data/relationships/mira_gift_preferences.tres` |
| Machines/resources | `scripts/machines/machine.gd`, `scripts/machines/fisherman.gd`, `scripts/objects/tree.gd`, `scripts/objects/dropped_apple.gd` |

### Enum Values

`Enum.Seed` currently contains:

| Enum.Seed | Meaning |
| --- | --- |
| `TOMATO` | Tomato seed selection |
| `CORN` | Corn seed selection |
| `PUMPKIN` | Pumpkin seed selection |
| `WHEAT` | Wheat seed selection |

`Enum.Item` currently contains:

| Enum.Item | Current Runtime Meaning |
| --- | --- |
| `WOOD` | Resource |
| `APPLE` | Resource |
| `TOMATO` | Used as both tomato seed stock and harvested tomato crop |
| `CORN` | Used as both corn seed stock and harvested corn crop |
| `WHEAT` | Used as both wheat seed stock and harvested wheat crop |
| `PUMPKIN` | Used as both pumpkin seed stock and harvested pumpkin crop |
| `FISH` | Fish item from manual and automatic fishing |
| `COIN` | Coin balance key in `Data.ITEMS_AMOUNT` |

There are no `WHEAT_SEED`, `CORN_SEED`, `TOMATO_SEED`, or `PUMPKIN_SEED`
Item enum values yet.

### Current `SEED_TO_ITEM`

Runtime source: `scripts/global/data.gd`.

```gdscript
var SEED_TO_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT
}
```

This is the central bridge that collapses seed identity into crop item identity.
The project does have a separate `Enum.Seed`, but every seed resolves to the
same `Enum.Item` currently used for harvested crop inventory, style costs,
machine recipes, telemetry, gift checks, and item display.

### Runtime Seed Selection

`scripts/characters/player.gd` stores:

| Variable | Type | Meaning |
| --- | --- | --- |
| `current_seed` | `Enum.Seed` | Selected seed species for planting |
| `current_tool` | `Enum.Tool` | Tool mode, including `Enum.Tool.SEED` |

Seed cycling changes `current_seed` and emits `Enum.KEYBOARD.CHANGE_SEED`.
So the player selection itself is a Seed enum, not an Item enum.

### Planting Inventory Mutation

Runtime source: `scripts/level.gd`, `Enum.Tool.SEED` branch.

Current flow:

```text
current_seed: Enum.Seed
-> Data.SEED_TO_ITEM[current_seed]
-> Data.ITEMS_AMOUNT[that crop item] -= 1
-> PlantResource.setup(current_seed)
-> plant is created
```

Example today:

```text
Plant Wheat
-> current_seed = Enum.Seed.WHEAT
-> SEED_TO_ITEM[WHEAT] = Enum.Item.WHEAT
-> Data.ITEMS_AMOUNT[Enum.Item.WHEAT] -= 1
```

This means planting consumes mature Wheat item stock, not Wheat Seed stock.

### Harvest Inventory Mutation

Runtime source: `scripts/objects/plant.gd`.

Current flow:

```text
PlantResource.curr_seed_enum
-> Data.SEED_TO_ITEM[curr_seed_enum]
-> Data.ITEMS_AMOUNT[that crop item] += 2
-> Data.CROP_COIN_REWARDS[that crop item]
-> Data.add_coins(...)
-> QuestManager.report_event(HARVEST_CROP, seed name, harvested amount)
```

Example today:

```text
Harvest Wheat
-> curr_seed_enum = Enum.Seed.WHEAT
-> SEED_TO_ITEM[WHEAT] = Enum.Item.WHEAT
-> Data.ITEMS_AMOUNT[Enum.Item.WHEAT] += 2
-> Data.add_coins(20)
```

This means the same `Enum.Item.WHEAT` key is both the input consumed by planting
and the output produced by harvest.

### Inventory

Runtime sources: `scripts/ui/inventory.gd`, `scripts/ui/resourse_texture.gd`.

Inventory loops over `Data.ITEMS_AMOUNT.keys()` and renders every key through
`Data.get_item_texture(item)`. Because there are no Seed Item keys, inventory
cannot display seed stock and mature crop stock separately.

### Plant Resource

Runtime source: `resources/plant_res.gd`.

`PlantResource` stores `curr_seed_enum: Enum.Seed`, loads plant sprite and icon
from `Data.PLANT_DATA[seed_enum]`, and does not store a seed item id or crop item
id. It knows which seed species started the plant, but not which inventory key
should be consumed or produced.

### Quest

Mira quest resource:

```text
data/quests/mira_still_sprouts_quest.tres
objective_type = HARVEST_CROP
target_id = "WHEAT"
required_amount = 3
```

Plant harvest reports:

```text
QuestManager.report_event(HARVEST_CROP, _get_harvested_crop_id(), actual_harvested_amount)
```

`_get_harvested_crop_id()` converts `res.curr_seed_enum` back to the string name
from `Enum.Seed.keys()`, so Mira currently listens to the seed enum name
`"WHEAT"`. It is not listening to `Enum.Item.WHEAT` directly, but the string is
ambiguous because it also matches the current crop item id.

### Shop, Machines, Styles, and Telemetry

Current crop item keys are used by multiple systems:

| System | Crop/Item Dependencies |
| --- | --- |
| Machine blueprint shop | Coin cost only after current changes; product list still comes from `Data.MACHINE_UPGRADE_COST`. |
| Machine placement recipes | Sprinkler uses `Enum.Item.TOMATO`, `Enum.Item.WHEAT`; Scarecrow uses `Enum.Item.PUMPKIN`, `Enum.Item.CORN`; Fisher uses `Enum.Item.WOOD`, `Enum.Item.FISH`. |
| Style purchases | Several styles use `Enum.Item.CORN`, `Enum.Item.TOMATO`, `Enum.Item.PUMPKIN`, `Enum.Item.WHEAT`, plus `WOOD`, `APPLE`, `FISH`. |
| Inventory snapshots | `ITEM_TELEMETRY_KEYS` records `corn`, `wheat`, `pumpkin`, `tomato`, `fish`, `wood`, `apple`, `coin`. |
| Crop income telemetry | `CROP_TELEMETRY_SOURCES` maps crop items to `crop_wheat`, `crop_corn`, `crop_tomato`, `crop_pumpkin`. |
| Gift system | Mira preferences use item ids `"TOMATO"`, `"WHEAT"`, `"CORN"`, `"PUMPKIN"`. |

### Apple, Fish, Wood Coupling

| Item | Source | Coupled to Seed/Crop System? | Notes |
| --- | --- | --- | --- |
| `WOOD` | `scripts/objects/tree.gd` | No direct coupling | Added directly to `Data.ITEMS_AMOUNT[Enum.Item.WOOD]`; used in shop/style/machine costs. |
| `APPLE` | `scripts/objects/dropped_apple.gd` | No direct coupling | Added directly to `Data.ITEMS_AMOUNT[Enum.Item.APPLE]`; used in style/house costs and gifts if configured later. |
| `FISH` | `scripts/characters/player.gd`, `scripts/machines/fisherman.gd` | Not coupled to Seed/Crop | Manual fishing also grants direct coins today; auto Fisher only adds fish. |

These can stay ordinary resources/items during the seed/crop split.

## 2. Root Cause of Seed/Crop Confusion

The true root cause is not that the project lacks an `Enum.Seed`. It does have
one. The root cause is that inventory, recipes, economy, and display are all
built around `Enum.Item`, and there are no seed-specific Item keys.

The collapse happens here:

```text
Enum.Seed.WHEAT -> Data.SEED_TO_ITEM -> Enum.Item.WHEAT
```

Then the same item key is used by both sides of the farming loop:

```text
Planting consumes Enum.Item.WHEAT
Harvesting produces Enum.Item.WHEAT
Machines/styles/gifts/telemetry also read Enum.Item.WHEAT
```

Affected assumptions:

| Assumption | Current Location |
| --- | --- |
| Seed stock can be represented by mature crop item stock | `scripts/level.gd`, `Data.SEED_TO_ITEM`, `Data.ITEMS_AMOUNT` |
| Harvest output can be resolved from seed through `SEED_TO_ITEM` | `scripts/objects/plant.gd` |
| Plant resource only needs seed enum, not separate seed/crop item ids | `resources/plant_res.gd` |
| Inventory does not need seed/crop distinction | `scripts/ui/inventory.gd`, `scripts/ui/resourse_texture.gd`, `Data.ITEMS_AMOUNT` |
| Item id `"WHEAT"` can mean harvested crop and also selected seed context | `Data.ITEM_IDS`, Mira gift code, Mira quest target string |
| Existing crop item icons can also represent seed icons | `Data.PLANT_DATA`, `Data.SEED_TEXTURES`, `Data.TEXTURES`, `scripts/ui/tool_ui.gd` |

## 3. Target Data Model

Recommended Item enum model:

```text
WOOD
APPLE
FISH
COIN

TOMATO_SEED
CORN_SEED
PUMPKIN_SEED
WHEAT_SEED

TOMATO
CORN
PUMPKIN
WHEAT
```

`Enum.Seed` can remain as the player selection/species enum:

```text
Enum.Seed.TOMATO
Enum.Seed.CORN
Enum.Seed.PUMPKIN
Enum.Seed.WHEAT
```

But the Data mappings should split into two explicit directions:

```gdscript
SEED_TO_SEED_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO_SEED,
	Enum.Seed.CORN: Enum.Item.CORN_SEED,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN_SEED,
	Enum.Seed.WHEAT: Enum.Item.WHEAT_SEED,
}

SEED_TO_CROP_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT,
}
```

Rules:

| Rule | Target Behavior |
| --- | --- |
| Planting | Consumes exactly 1 `*_SEED` Item. |
| Harvest | Produces exactly 2 mature crop Items. |
| Replanting | Requires seed stock; harvested crop stock cannot be planted directly. |
| Hotbar | Uses `Enum.Seed` for selection, displays seed icon from a seed-specific texture map. |
| Inventory | Displays `*_SEED` and crop Items as separate rows/slots. |
| Mira harvest quest | Tracks harvested mature crop events; target can remain `"WHEAT"` if event means crop harvest, but should be documented as crop target. |
| Machine recipes | Continue to use mature crop Items, not `*_SEED`. |
| Selling NPC | Accepts mature crop Items and `FISH`, not `*_SEED`. |
| Wood/Apple | Stay ordinary resource Items. |

Recommended crop sale eligibility:

```gdscript
SELLABLE_ITEMS = {
	Enum.Item.WHEAT: true,
	Enum.Item.CORN: true,
	Enum.Item.TOMATO: true,
	Enum.Item.PUMPKIN: true,
	Enum.Item.FISH: true,
}
```

Seeds should be buyable or grantable, but not sellable in Phase F unless a later
design explicitly allows seed resale.

## 4. Icon Mapping Audit

### Current Texture Findings

Current crop icons exist:

| Texture | Exists |
| --- | --- |
| `res://graphics/icons/wheat.png` | Yes |
| `res://graphics/icons/corn.png` | Yes |
| `res://graphics/icons/tomato.png` | Yes |
| `res://graphics/icons/pumpkin.png` | Yes |

Distinct generic seed textures also exist in the Ninja Adventure asset folder:

```text
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/Seed1.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/Seed2.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/Seed3.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/SeedBig1.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/SeedBig2.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/SeedBig3.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/SeedLarge.png
res://graphics/Ninja Adventure - Asset Pack/.../Items/Food/SeedLargeWhite.png
```

They are not currently mapped to specific crop seeds.

### Seed/Crop Icon Table

| Type | Existing Texture | Correct Texture Available | Required Action |
| --- | --- | --- | --- |
| Wheat Seed | Currently uses `res://graphics/icons/wheat.png` in seed UI data; main Seed tool icon also uses wheat. | Generic seed textures exist; no wheat-specific seed icon is mapped. | Add `WHEAT_SEED` item texture and seed hotbar texture. Prefer a distinct seed icon/tint/atlas region. |
| Wheat Crop | `res://graphics/icons/wheat.png` | Yes | Keep as mature Wheat crop icon. |
| Corn Seed | Seed submenu maps to `res://graphics/icons/corn.png`. | Generic seed textures exist; no corn-specific seed icon is mapped. | Add `CORN_SEED` item texture and seed hotbar texture distinct from crop. |
| Corn Crop | `res://graphics/icons/corn.png` | Yes | Keep as mature Corn crop icon. |
| Tomato Seed | Seed submenu maps to `res://graphics/icons/tomato.png`. | Generic seed textures exist; no tomato-specific seed icon is mapped. | Add `TOMATO_SEED` item texture and seed hotbar texture distinct from crop. |
| Tomato Crop | `res://graphics/icons/tomato.png` | Yes | Keep as mature Tomato crop icon. |
| Pumpkin Seed | Seed submenu maps to `res://graphics/icons/pumpkin.png`. | Generic seed textures exist; no pumpkin-specific seed icon is mapped. | Add `PUMPKIN_SEED` item texture and seed hotbar texture distinct from crop. |
| Pumpkin Crop | `res://graphics/icons/pumpkin.png` | Yes | Keep as mature Pumpkin crop icon. |

### Why Seed UI Appears as Wheat

There are two separate UI paths:

1. Main tool icon path:

```text
scripts/ui/tool_ui.gd
TOOL_TEXTURES[Enum.Tool.SEED] = res://graphics/icons/wheat.png
```

and duplicated in:

```text
scripts/global/data.gd
TOOL_TEXTURES[Enum.Tool.SEED] = res://graphics/icons/wheat.png
KEYBOARD_TO_ICONS[Enum.KEYBOARD.CHANGE_TOOL] = TOOL_TEXTURES
```

This guarantees that the Seed tool itself displays as Wheat.

2. Seed species submenu path:

```text
scripts/ui/tool_ui.gd
SEED_TEXTURES[Enum.Seed.CORN] = corn.png
SEED_TEXTURES[Enum.Seed.PUMPKIN] = pumpkin.png
SEED_TEXTURES[Enum.Seed.TOMATO] = tomato.png
SEED_TEXTURES[Enum.Seed.WHEAT] = wheat.png
```

This path does have four different crop icons. However, those are crop icons
standing in for seed icons, not distinct seed icons.

True root cause:

```text
The main selected Seed tool icon is hardcoded to Wheat.
The seed submenu maps different species, but uses mature crop icons as seed icons.
There is no separate seed item texture map yet.
```

This is not caused by every seed entry in `SEED_TEXTURES` referencing Wheat.
It is not caused by an atlas region error in the inspected files.

## 5. Direct Coin Removal Impact

Current direct coin sources to remove or migrate later:

| Direct Income | Current Runtime Source | What It Does Today | Future Handling |
| --- | --- | --- | --- |
| Crop harvest coins | `scripts/objects/plant.gd` | Reads `Data.CROP_COIN_REWARDS`, calls `Data.add_coins`, records `crop_*` income telemetry. | Remove direct coin grant after selling NPC exists. Crop harvest should only add crop inventory and quest progress. |
| Manual fishing coins | `scripts/characters/player.gd` | On success, adds `Enum.Item.FISH`, reads `Data.MANUAL_FISHING_COIN_REWARD`, calls `Data.add_coins`, records `manual_fishing` income telemetry. | Remove direct coin grant after selling NPC exists. Manual fishing should only add Fish; sale records `sale_fish`. |

Data/config to migrate:

| Data Field | Current Role | Future Role |
| --- | --- | --- |
| `Data.CROP_COIN_REWARDS` | Direct harvest coin reward table | Replace or retire after sale price table exists. If kept temporarily, mark deprecated. |
| `Data.MANUAL_FISHING_COIN_REWARD` | Direct manual fishing coin reward | Replace or retire after fish sale price exists. |
| `Data.CROP_TELEMETRY_SOURCES` | Direct crop income source labels | Replace with sale telemetry sources such as `sale_wheat`, `sale_corn`, etc. |
| `Data.record_playtest_coin_income("manual_fishing", ...)` | Direct fishing income metric | Replace with sale income metric after sale UI/NPC. |

Direct coin sources to keep:

| Source | Keep? | Reason |
| --- | --- | --- |
| Mira quest reward | Yes | Quest reward remains direct 100 coins by design. |
| Initial coins | Yes | Starting economy remains in `Data.ITEMS_AMOUNT[Enum.Item.COIN]`. |
| Shop spending | Yes | Existing blueprint/style coin spending should remain until rebalanced after sale loop. |

## 6. Dependency Matrix

| System | Current Dependency | Seed/Crop Split Impact | Migration Risk |
| --- | --- | --- | --- |
| Enum | `Enum.Item` lacks seed item values. | Add seed item enum values without reordering existing values if possible. | High if enum integer values shift and existing dictionaries/scenes rely on them. |
| Data inventory | `ITEMS_AMOUNT` stores crop items as both seed stock and crop stock. | Add seed item keys and starting seed amounts. | High; missing keys cause UI and planting failures. |
| Item IDs | `ITEM_IDS`/`ITEM_ID_TO_ENUM` only know crop ids like `"WHEAT"`. | Add `"WHEAT_SEED"` etc. | Medium; gift/quest/item helper code depends on ids. |
| Display names | No seed display names. | Add seed display names. | Low. |
| Textures | Crop icons are reused for seeds. | Add seed textures and keep crop textures. | Medium; missing texture map keys can crash UI setup. |
| Planting | `scripts/level.gd` consumes `SEED_TO_ITEM[current_seed]`. | Consume `SEED_TO_SEED_ITEM[current_seed]`. | High; wrong map destroys crop stock or blocks planting. |
| Harvest | `scripts/objects/plant.gd` adds `SEED_TO_ITEM[curr_seed]`. | Add `SEED_TO_CROP_ITEM[curr_seed]`. | High; must preserve quest progress and duplicate harvest guard. |
| PlantResource | Stores only `curr_seed_enum`. | Can keep seed enum, but Data should own seed/crop item maps. | Low if maps live in Data. |
| Hotbar | `current_seed` is `Enum.Seed`; Seed tool icon hardcoded Wheat. | Keep `Enum.Seed`, update seed texture path. | Medium; UI has duplicated texture maps. |
| Inventory | Loops `ITEMS_AMOUNT.keys()`. | Will automatically show seed items if keys/textures exist. | Medium; order/noise may need filtering or grouping. |
| Shop | Blueprint/style costs use crop items and coins. | Ensure seed items are not accidentally used in machine/style costs. | Medium. |
| Machine recipes | Placement recipes use mature crop items. | Keep crop items. | Low if enum values and keys stay stable. |
| Telemetry | Inventory snapshot knows crop keys, not seed keys. | Add seed telemetry keys or intentionally omit seed stock. | Medium; missing visibility can hide seed economy issues. |
| Quest | Mira harvest target `"WHEAT"` is emitted from seed enum name. | Keep event target for crop harvest, or move to crop item id `"WHEAT"`. | Medium; avoid counting seed planting as harvest. |
| Gift system | Mira gift selected seed tool maps via `SEED_TO_ITEM` and consumes crop item. | Decide whether gifting seeds should be disabled or seed/crop specific. | Medium; current gift flow can consume crop stock while player holds seed tool. |
| Fishing | Manual success adds Fish and coins; auto Fisher adds Fish only. | Remove manual direct coins later; Fish remains sellable item. | Medium. |
| Apple/Wood | Ordinary resources. | No seed/crop impact. | Low. |
| Root duplicate data | `global/data.gd` duplicates old values but is not autoload. | Do not edit unless deliberately removing duplicate later. | Medium; accidental edits will not affect runtime. |
| Save system | No persistent save system found. | No save migration needed right now. | Low now, higher later if save arrives. |

## 7. Safe Migration Plan

### Phase A - Add Seed Item enum/data without switching runtime logic

Goal: introduce seed item identities while preserving current behavior.

Modify:

| File | Change |
| --- | --- |
| `scripts/global/enums.gd` | Add `TOMATO_SEED`, `CORN_SEED`, `PUMPKIN_SEED`, `WHEAT_SEED`. Prefer appending values to avoid shifting existing enum integers. |
| `scripts/global/data.gd` | Add seed entries to `ITEMS_AMOUNT`, `ITEM_IDS`, `ITEM_ID_TO_ENUM`, `ITEM_DISPLAY_NAMES`, `TEXTURES`/`ICON_PATHS`, `ITEM_TELEMETRY_KEYS`. |
| `scripts/global/data.gd` | Add `SEED_TO_SEED_ITEM` and `SEED_TO_CROP_ITEM`; keep old `SEED_TO_ITEM` temporarily as compatibility alias. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Project starts | No parse errors. |
| Inventory opens | Seed and crop rows both render textures. |
| Existing planting still works | Because business logic still uses old map in this phase. |
| Existing machine/style purchases still work | Crop enum keys unchanged. |

Rollback risk: low if enum values are appended and old maps remain.

Compatibility: keep `SEED_TO_ITEM` until Phase C is complete.

### Phase B - Switch Hotbar icon and seed selection display

Goal: fix seed display without changing inventory economy.

Modify:

| File | Change |
| --- | --- |
| `scripts/ui/tool_ui.gd` | Remove duplicated hardcoded seed icon map or make it read from `Data`. |
| `scripts/global/data.gd` | Add canonical seed texture map for `Enum.Seed` and/or `Enum.Item.*_SEED`. |
| `scripts/ui/tool_ui_texture.gd` | Loosen misleading `tool_enum: Enum.Tool` naming if needed, because it stores Seed values too. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Switch tool to Seed | Main Seed tool no longer always looks like Wheat unless intentionally using generic seed icon. |
| Cycle Seed | Tomato/Corn/Pumpkin/Wheat show correct seed-specific icons. |
| Tool cycling | Other tool icons unchanged. |

Rollback risk: low; UI only.

Compatibility: do not change planting consumption yet.

### Phase C - Planting consumes Seed; harvest produces Crop

Goal: make farming loop semantically correct.

Modify:

| File | Change |
| --- | --- |
| `scripts/level.gd` | In `Enum.Tool.SEED` branch, check and deduct `Data.SEED_TO_SEED_ITEM[current_seed]`. |
| `scripts/objects/plant.gd` | On harvest, add `Data.SEED_TO_CROP_ITEM[res.curr_seed_enum]`. |
| `scripts/global/data.gd` | Mark old `SEED_TO_ITEM` deprecated or remove after all references are gone. |
| `scripts/characters/mira_npc.gd` | Update gift selected-item logic so holding Seed tool does not accidentally gift mature Crop unless design says it should. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Plant Wheat | `WHEAT_SEED -1`, `WHEAT` unchanged. |
| Harvest Wheat | `WHEAT +2`, `WHEAT_SEED` unchanged. |
| No seed stock | Cannot plant even if mature crop stock exists. |
| Mature harvest quest | Mira progress increments from harvest event. |

Rollback risk: medium/high; this changes the core loop.

Compatibility: keep crop item names and quest target ids stable.

### Phase D - Confirm Quest and machine recipes use Crop

Goal: prevent recipes/objectives from accidentally moving to seed items.

Modify:

| File | Change |
| --- | --- |
| `scripts/global/data.gd` | Review `MACHINE_PLACEMENT_COSTS`, `STYLE_RESOURCE_COSTS`, `ITEM_TELEMETRY_KEYS`. |
| `data/quests/mira_still_sprouts_quest.tres` | Only change if target naming needs explicit crop id. |
| `scripts/objects/plant.gd` | Ensure harvest event target represents crop harvest, not seed planting. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Place Sprinkler | Costs mature Tomato/Wheat crop, not seed. |
| Place Scarecrow | Costs mature Pumpkin/Corn crop, not seed. |
| Mira harvest quest | Still completes from mature Wheat harvest. |

Rollback risk: medium; quest and recipe regressions affect progression.

Compatibility: keep existing crop item ids `"WHEAT"`, `"CORN"`, `"TOMATO"`, `"PUMPKIN"`.

### Phase E - Remove Crop/Fishing direct coin rewards

Goal: inventory first, coins only from sale or quest reward.

Modify:

| File | Change |
| --- | --- |
| `scripts/objects/plant.gd` | Remove direct `Data.add_coins` and `Data.record_playtest_coin_income(crop_*)` from harvest. |
| `scripts/characters/player.gd` | Remove direct `Data.add_coins` and `manual_fishing` income from fishing success. |
| `scripts/global/data.gd` | Deprecate or remove `CROP_COIN_REWARDS`, `MANUAL_FISHING_COIN_REWARD`, `CROP_TELEMETRY_SOURCES` after sale config exists. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Harvest crop | Crop inventory increases, coins unchanged, quest progress preserved. |
| Manual fishing success | Fish inventory increases, coins unchanged. |
| Auto Fisher | Fish inventory increases, coins unchanged. |
| Mira quest completion | 100 coins still awarded. |

Rollback risk: medium; economy pacing temporarily lacks sale income until Phase F.

Compatibility: keep telemetry attempt/duration counters for fishing.

### Phase F - Add Selling NPC and Sale UI

Goal: make crops/fish convertible to coins through NPC sale.

Modify:

| File | Change |
| --- | --- |
| New NPC scene/script | Seller NPC interaction and dialogue entry. |
| New sale UI scene/script | List sellable inventory, quantity, price, confirm sale. |
| `scripts/global/data.gd` | Add `SELLABLE_ITEMS`, sale price table, `SALE_TELEMETRY_SOURCES`. |
| `scripts/level.gd`/scene | Place seller NPC and connect UI if needed. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Sell Wheat | `WHEAT -n`, coins increase by sale price * n, telemetry source `sale_wheat`. |
| Sell Fish | `FISH -n`, coins increase, telemetry source `sale_fish`. |
| Try sell seed | Not shown or rejected. |
| Try sell Wood/Apple | Not shown unless design later allows. |

Rollback risk: medium/high; new UI and NPC path.

Compatibility: keep shop spending and quest reward direct coin logic.

### Phase G - Rebalance sale prices, seed prices, and machine prices

Goal: rebalance after the real sale loop exists.

Modify:

| File | Change |
| --- | --- |
| `scripts/global/data.gd` | Sale prices, seed purchase prices, blueprint prices, placement costs if needed. |
| Shop/seller configs | Move seed purchasing to proper shop/seller if added. |
| Documentation | Update economy design docs after measured test. |

Runtime validation:

| Test | Expected |
| --- | --- |
| Day 1-5 playtest | Income source mix reflects sale loop. |
| Machine progression | Sprinkler/Fisher/Scarecrow appear at intended days. |
| Fishing vs farming | Neither dominates only because of direct coin grants. |

Rollback risk: medium; numeric tuning only after structure is stable.

Compatibility: do not tune from V1 direct-coin data as if it were final sale-loop data.

## 8. Selling NPC Prerequisites

Before creating the selling NPC, the following must exist:

| Prerequisite | Why |
| --- | --- |
| Separate seed and crop item ids | Seller must reject seeds and accept crops. |
| Stable crop inventory keys | Sale UI needs safe item lookup and quantity changes. |
| Sale price table | Direct `CROP_COIN_REWARDS` cannot be reused blindly because sale may support quantity and Fish. |
| Sale telemetry source map | Income should migrate from `crop_*`/`manual_fishing` to `sale_*`. |
| Item display names and textures | Sale UI must show readable names/icons for crops and Fish. |
| Interaction rules | Seller NPC should not conflict with Mira dialogue/quest UI input. |

Pixel Plains note:

If the seller NPC uses Pixel Plains paid content, add credits:

```text
Pixel Plains - Top-Down Asset Pack by SnowHex
Used and modified under the asset pack license.
```

Do not package raw Pixel Plains source assets into a separately downloadable
template bundle.

## 9. Recommended Next Coding Step

Start with Phase A.

First files to modify:

1. `scripts/global/enums.gd`
2. `scripts/global/data.gd`

Minimum Phase A change set:

| Change | Reason |
| --- | --- |
| Add `*_SEED` Item enum values by appending. | Avoid enum integer shifts for existing crop items. |
| Add seed item ids/display names/textures/inventory keys. | Inventory and helper APIs must parse before logic switches. |
| Add `SEED_TO_SEED_ITEM` and `SEED_TO_CROP_ITEM`. | Prepares explicit split while keeping old behavior alive. |
| Keep `SEED_TO_ITEM` temporarily. | Prevent immediate breakage in `level.gd`, `plant.gd`, and `mira_npc.gd`. |

Do not start with the seller NPC. If sale UI is added before seed/crop identity
is split, it will either sell seed stock as if it were crops or require another
round of rewiring immediately afterward.

## Appendix: Affected Files List

High priority for migration:

| File | Reason |
| --- | --- |
| `scripts/global/enums.gd` | Add seed item enum values. |
| `scripts/global/data.gd` | Core item ids, inventory, textures, seed/crop maps, prices, telemetry. |
| `scripts/level.gd` | Planting currently consumes crop item through `SEED_TO_ITEM`. |
| `scripts/objects/plant.gd` | Harvest currently produces crop item through `SEED_TO_ITEM` and grants direct coins. |
| `scripts/characters/player.gd` | Stores current seed; manual fishing grants direct coins. |
| `scripts/ui/tool_ui.gd` | Seed tool icon hardcoded Wheat; seed submenu uses crop icons as seed icons. |
| `scripts/ui/inventory.gd` | Inventory will need to display seed and crop item keys cleanly. |
| `scripts/ui/resourse_texture.gd` | Uses `Data.get_item_texture`; needs seed textures to exist. |
| `scripts/characters/mira_npc.gd` | Gift logic maps selected seed to mature crop item through `SEED_TO_ITEM`; quest reward direct coins remain. |

Medium priority:

| File | Reason |
| --- | --- |
| `data/quests/mira_still_sprouts_quest.tres` | Target id currently `"WHEAT"`; should remain crop harvest semantic. |
| `data/relationships/mira_gift_preferences.tres` | Crop gift ids currently use `"TOMATO"`, `"WHEAT"`, etc. |
| `scripts/ui/shop_button.gd` | Renders costs using `Data.get_item_texture`; seed/crop items must be parseable if shops later sell seeds. |
| `scripts/machines/machine.gd` | Base placement unaffected, but recipes are crop item dependent. |
| `scripts/machines/fisherman.gd` | Fish item production; future Fish sale path depends on it. |
| `scripts/objects/tree.gd` | Wood production ordinary resource. |
| `scripts/objects/dropped_apple.gd` | Apple production ordinary resource. |
| `resources/plant_res.gd` | Stores seed enum and loads visual data; may stay stable with explicit maps in Data. |

Do not use as runtime source:

| File | Reason |
| --- | --- |
| `global/data.gd` | Duplicate older data file; project autoload uses `scripts/global/data.gd`. |

