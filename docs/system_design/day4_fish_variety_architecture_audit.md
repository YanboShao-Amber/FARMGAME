# Day 4 Fish Variety System Architecture Audit

Phase H3A is a read-only architecture audit and design pass. This document records the current generic fish architecture, the real runtime dependencies, available art assets, and a safe staged plan for H3B. No runtime code, scenes, resources, prices, probabilities, or assets were modified in this phase.

## 1. Current Generic Fish Architecture

The project currently has two separate fish concepts:

| Layer | Current Data | Runtime Meaning |
| --- | --- | --- |
| Inventory item | `Enum.Item.FISH` | The only fish item that enters inventory, trade, telemetry snapshots, and machine recipes. |
| Fishing minigame fish | `Enum.Fish {GOLD, SILVER, GRAY}` and `Data.FISH_DATA` | Visual/minigame difficulty variants selected when manual fishing starts. The selected minigame fish is not preserved after success. |

Current manual fishing flow:

```text
Player uses Fish tool
-> scripts/level.gd starts Player.start_fishing()
-> scripts/ui/fishing_game.gd picks one Enum.Fish at equal random
-> success signal reaches scripts/characters/player.gd
-> Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1
-> Data.record_manual_fishing_finished(is_success)
```

Current automatic Fisher flow:

```text
scripts/machines/fisherman.gd timer completes
-> Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1
-> timer restarts
```

Current trade flow:

```text
Data.TRADEABLE_ITEMS includes Enum.Item.FISH
Data.ITEM_BUY_PRICES[Enum.Item.FISH] = 22
Data.ITEM_SELL_PRICES[Enum.Item.FISH] = 15
Shared MerchantTradeUI displays FISH as one row
```

The important design gap is that minigame species currently affect only icon/difficulty inside the minigame. Inventory, sale value, recipes, and telemetry all collapse to one generic `FISH` item.

## 2. All FISH Dependencies

| Category | File / Path | Current Reference | Migration Need |
| --- | --- | --- | --- |
| Enum stability | `scripts/global/enums.gd` | `Enum.Item.FISH = 6`; `Enum.Fish {GOLD, SILVER, GRAY}` | Append new fish item enums after existing item values. Do not reorder existing items. |
| Manual Fishing Reward | `scripts/characters/player.gd` | On success, `Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1` | Replace with weighted species roll and add the rolled species item. Preserve `fishing_result_resolved`. |
| Manual Fishing Minigame | `scripts/ui/fishing_game.gd` | `Enum.Fish.values().pick_random()`; reads `Data.FISH_DATA` | Decide whether minigame fish and rewarded item are unified. Current equal random selection is not suitable for final reward probability. |
| Automatic Fisher Reward | `scripts/machines/fisherman.gd` | Timer adds `Enum.Item.FISH +1` | Replace with restricted species drop table. No direct coins. |
| Fishing Tool | `scripts/level.gd`, `scripts/characters/player.gd`, `scenes/characters/player.tscn` | `Enum.Tool.FISH`, fishing animations/audio/UI | No species migration required; keep tool and state unchanged. |
| Inventory | `scripts/global/data.gd`, `scripts/ui/inventory.gd`, `scripts/ui/resourse_texture.gd` | `ITEMS_AMOUNT[Enum.Item.FISH] = 0`; inventory iterates all `ITEMS_AMOUNT.keys()` | Add species keys. Exclude deprecated generic `FISH` from visible inventory once runtime no longer produces it. |
| Trade | `scripts/global/data.gd`, `scripts/ui/sell_ui.gd` | `TRADEABLE_ITEMS`, `ITEM_BUY_PRICES`, `ITEM_SELL_PRICES`, `MERCHANT_CATALOGS`, `SALE_TELEMETRY_SOURCES`, `BUY_TELEMETRY_SOURCES` include generic `FISH` | Replace generic `FISH` in active trade whitelist/catalogs with fish species items. |
| Machine Recipe | `scripts/global/data.gd`, `scripts/level.gd`, `scripts/ui/machine_build_selector.gd` | Fisher placement cost currently `Wood 6`, `Fish 3`; both validation and deduction iterate concrete item costs | Add category costs so Fisher can require `Any Fish x3`. |
| Machine Blueprint Legacy Cost | `scripts/global/data.gd` | `MACHINE_UPGRADE_COST[Enum.Machine.FISHER].cost` still has `WOOD 25`, `FISH 15`; H2 runtime uses coin blueprint costs, not this old material cost | Mark as legacy/display-risk. Avoid using generic `FISH` if this table is revived. |
| Style Cost Legacy | `scripts/global/data.gd` | `STYLE_UPGRADES[Enum.Style.STRAW].cost` uses `FISH 8`, but current H2 shop only sells Cowboy/Baseball/Beanie | If Straw ever becomes purchasable again, migrate to Any Fish or a specific species. |
| Telemetry Snapshot | `scripts/global/data.gd` | `ITEM_TELEMETRY_KEYS[Enum.Item.FISH] = "fish"` | Add one key per species. Keep `"fish"` only for old log compatibility. |
| Fishing Telemetry | `scripts/global/data.gd` | Attempts, successes, failures, duration, average duration | Preserve existing counters. Add species catch events and cumulative species counts. |
| Sale Telemetry | `scripts/global/data.gd` | `sale_fish`, `buy_fish`; sale events include `item_id` | Add `sale_<fish_id>` and `buy_<fish_id>`. Do not generate new generic `sale_fish` events after migration. |
| Gift | `data/relationships/mira_gift_preferences.tres`, `scripts/systems/gift_manager.gd` | Mira gift preferences do not include `FISH` | No current fish gift dependency. Future fish gifts should use species or category explicitly. |
| Quest | `data/quests/mira_still_sprouts_quest.tres`, `scripts/systems/quest_manager.gd` | Current quest target is `WHEAT`; no fish target | No current fish quest dependency. Future fish quests should specify species or Any Fish category. |
| UI Icon Data | `Data.ICON_PATHS`, `Data.TEXTURES`, `Data.ITEM_DISPLAY_NAMES`, `Data.ITEM_IDS`, `Data.ITEM_ID_TO_ENUM` | Generic `FISH` maps to `goldfish.png` and display name `"Fish"` | Add entries per species. Generic `FISH` should not appear in active UI/trade once deprecated. |

## 3. Existing Fish Asset Audit

Files and atlases inspected:

| Candidate | Path | Region / Frame | Visual Description | Distinguishable | Style Fit |
| --- | --- | --- | --- | --- | --- |
| Gray Fish | `res://graphics/icons/grayfish.png` | Full image, 24x14 | Pale green-gray side-view fish, soft outline. | Yes | High. Already used by `Data.FISH_DATA[Enum.Fish.GRAY]`. |
| Silver Fish | `res://graphics/icons/silverfish.png` | Full image, 24x15 | Silver/purple outline fish with orange body center. | Yes | High. Already used by `Data.FISH_DATA[Enum.Fish.SILVER]`. |
| Gold Fish | `res://graphics/icons/goldfish.png` | Full image, 22x16 | Bright gold/orange fish. | Yes | High. Already used by generic inventory `FISH` and `Data.FISH_DATA[Enum.Fish.GOLD]`. |
| Red Fish | `res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetRed.png` | Recommended first frame `Rect2(0, 0, 16, 16)`; full sheet is 32x16 | Small red fish with heavier black outline. | Yes | Medium. Usable as a fourth fish, but style differs from the three current icons. |
| Yellow Ninja Fish | `res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetYellow.png` | First frame `Rect2(0, 0, 16, 16)`; full sheet is 32x16 | Small peach/yellow fish with heavy outline. | Yes | Medium/low because it overlaps visually with Gold Fish. |
| White Ninja Fish | `res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetWhite.png` | First frame `Rect2(0, 0, 16, 16)`; full sheet is 32x16 | Small white/pink fish with heavy outline. | Yes | Medium, but close in concept to Silver Fish. |
| Fish tool icon | `res://graphics/icons/fish.png` | Full image, 16x16 | Fishing rod, not a fish species. | No | Tool icon only. Not a species candidate. |
| Sprout Lands All Icons | `res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Icons/All Icons.png` | Inspected visually | UI symbols, coins, trophy, house, check/cross, etc. No fish. | No | Not applicable. |
| Sprout Lands Emoji Sheet | `res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/Emoji_Spritesheet_Free.png` | Inspected visually | Faces, animals, crops, tools, weather. No fish icon found. | No | Not applicable. |

Conclusion: the project has three high-fit fish icons already in active use. A fourth species can be supported from the existing Ninja Adventure red fish asset, but it should be treated as an art-risk until a fourth matching icon is available.

## 4. Proposed Fish Species

The names below are based on visual appearance, not real-world simulation accuracy. They are stable item IDs suitable for save/log data.

| Fish | Item Enum | String ID | Display Name | Rarity | Texture |
| --- | --- | --- | --- | --- | --- |
| Common Fish | `GRAY_CARP` | `GRAY_CARP` | Gray Carp | Common | `res://graphics/icons/grayfish.png` |
| Common/Uncommon Fish | `SILVER_PERCH` | `SILVER_PERCH` | Silver Perch | Common/Uncommon | `res://graphics/icons/silverfish.png` |
| Uncommon/Rare Fish | `GOLDEN_KOI` | `GOLDEN_KOI` | Golden Koi | Uncommon/Rare | `res://graphics/icons/goldfish.png` |
| Rare Fish | `RED_SNAPPER` | `RED_SNAPPER` | Red Snapper | Rare | `res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Actor/Animals/Fish/SpriteSheetRed.png`, region `Rect2(0, 0, 16, 16)` |

Naming notes:

- Do not reuse generic `FISH` for any species.
- Do not rename or remove `Enum.Fish` during the first migration phase.
- If a matching fourth fish icon is later added, `RED_SNAPPER` can keep the same enum/ID and only swap texture.

## 5. Enum and Item IDs

Current `Enum.Item` order from `scripts/global/enums.gd`:

| Existing Item | Current Integer |
| --- | ---: |
| `WOOD` | 0 |
| `APPLE` | 1 |
| `TOMATO` | 2 |
| `CORN` | 3 |
| `WHEAT` | 4 |
| `PUMPKIN` | 5 |
| `FISH` | 6 |
| `COIN` | 7 |
| `TOMATO_SEED` | 8 |
| `CORN_SEED` | 9 |
| `PUMPKIN_SEED` | 10 |
| `WHEAT_SEED` | 11 |

Recommended append-only additions:

| New Item | Proposed Integer |
| --- | ---: |
| `GRAY_CARP` | 12 |
| `SILVER_PERCH` | 13 |
| `GOLDEN_KOI` | 14 |
| `RED_SNAPPER` | 15 |

Do not insert new fish values before `COIN` or any existing seed item. Existing logs, saves, and serialized enum integers rely on stable order.

## 6. Catch Probability Tables

Manual fishing should roll the reward species only after the minigame succeeds. The total weight is exactly 100.

| Fish | Weight | Actual Chance | Expected per 100 Successful Catches |
| --- | ---: | ---: | ---: |
| `GRAY_CARP` | 50 | 50% | 50 |
| `SILVER_PERCH` | 30 | 30% | 30 |
| `GOLDEN_KOI` | 15 | 15% | 15 |
| `RED_SNAPPER` | 5 | 5% | 5 |
| Total | 100 | 100% | 100 |

Suggested data shape:

```gdscript
const MANUAL_FISHING_DROP_TABLE = [
	{"item": Enum.Item.GRAY_CARP, "weight": 50},
	{"item": Enum.Item.SILVER_PERCH, "weight": 30},
	{"item": Enum.Item.GOLDEN_KOI, "weight": 15},
	{"item": Enum.Item.RED_SNAPPER, "weight": 5},
]
```

Automatic Fisher should use a restricted table so passive production cannot create rare fish.

| Fish | Weight | Actual Chance | Expected per 100 Automatic Fisher Cycles |
| --- | ---: | ---: | ---: |
| `GRAY_CARP` | 70 | 70% | 70 |
| `SILVER_PERCH` | 30 | 30% | 30 |
| `GOLDEN_KOI` | 0 | 0% | 0 |
| `RED_SNAPPER` | 0 | 0% | 0 |
| Total | 100 | 100% | 100 |

Suggested data shape:

```gdscript
const AUTOMATIC_FISHER_DROP_TABLE = [
	{"item": Enum.Item.GRAY_CARP, "weight": 70},
	{"item": Enum.Item.SILVER_PERCH, "weight": 30},
]
```

The current V2 telemetry note was 17 attempts and 15 successes. Because the success rate can be high, the rare fish sell price should remain modest and the rare weight should stay low.

## 7. Buy/Sell Price Tables

Current generic fish is `Buy 22`, `Sell 15`.

Recommended species prices:

| Fish | Rarity | Catch Chance | Buy | Sell | Weighted Contribution |
| --- | --- | ---: | ---: | ---: | ---: |
| `GRAY_CARP` | Common | 50% | 16 | 9 | 4.50 |
| `SILVER_PERCH` | Common/Uncommon | 30% | 24 | 14 | 4.20 |
| `GOLDEN_KOI` | Uncommon/Rare | 15% | 38 | 24 | 3.60 |
| `RED_SNAPPER` | Rare | 5% | 65 | 42 | 2.10 |

All species satisfy:

```text
Buy Price > Sell Price > 0
```

## 8. Weighted Average Fish Value

Manual weighted average sell value:

```text
(0.50 x 9) + (0.30 x 14) + (0.15 x 24) + (0.05 x 42)
= 4.50 + 4.20 + 3.60 + 2.10
= 14.40 coins per successful catch
```

This stays slightly below the current generic fish sell value of 15, so fish variety adds texture without increasing average manual fishing income.

Automatic Fisher restricted weighted average sell value:

```text
(0.70 x 9) + (0.30 x 14)
= 6.30 + 4.20
= 10.50 coins per automatic cycle
```

This intentionally makes passive fish production weaker than successful manual fishing.

## 9. Generic FISH Migration Strategy

Recommendation: Option B, keep deprecated `Enum.Item.FISH`.

```text
Enum.Item.FISH remains stable at integer 6
Starting amount remains 0 during early migration
It is not catchable after manual/automatic rewards switch to species
It is removed from active trade/catalog paths
It is excluded from visible inventory once species are active
It is retained only for old save/log/code compatibility
```

Why not remove it:

- Existing enum integer stability is valuable.
- Current runtime references are spread across recipes, trade, inventory, telemetry, and old configuration.
- Removing it outright risks breaking old logs, old saves, and scripts that still use `ITEM_ID_TO_ENUM["FISH"]`.

Required safeguards:

- Do not include `Enum.Item.FISH` in `TRADEABLE_ITEMS` after species migration.
- Do not include `Enum.Item.FISH` in merchant buy catalogs after species migration.
- Do not generate new `sale_fish` or `buy_fish` events after species migration.
- Inventory display should either skip deprecated items or derive display rows from an explicit visible inventory whitelist instead of `ITEMS_AMOUNT.keys()`.

## 10. Manual Fishing Integration

Target flow:

```text
Manual fishing starts
-> Attempt telemetry starts
-> Minigame runs with existing input/state/feedback
-> Success signal received once
-> Roll MANUAL_FISHING_DROP_TABLE
-> Add specific species item +1
-> Record fish_catch_events entry with source "manual"
-> Record existing success/duration telemetry
-> Restore player state
```

Preserve:

- `fishing_result_resolved` duplicate guard.
- Attempt/success/failure/duration telemetry.
- No direct coin reward.
- Existing success/failure feedback.
- Input/state restoration after the minigame.

Important architecture choice:

- The selected `Enum.Fish` in `fishing_game.gd` currently controls minigame icon/difficulty and is selected equally.
- The final reward table should be separate from that current minigame random until the design intentionally links difficulty to species.
- If minigame fish and reward species are unified later, the signal should emit the fish identity, not just `is_success`.

Suggested future signal:

```gdscript
signal fish_game_finish(is_success: bool, fish_item: Enum.Item)
```

or:

```gdscript
signal fish_game_finish(is_success: bool, fish_data_id: StringName)
```

## 11. Automatic Fisher Integration

Recommendation: Option B, restricted drop table.

```text
Automatic Fisher timer completes
-> Roll AUTOMATIC_FISHER_DROP_TABLE
-> Add species item +1
-> Record fish_catch_events entry with source "automatic_fisher"
-> Restart production
```

Why restricted:

- Passive rare fish can quietly out-scale manual play.
- The current Fisher has no active skill check.
- Keeping rare fish manual-only gives fishing gameplay a reason to exist.

Automatic Fisher must not directly generate coins. Coins should still come from selling fish through the shared trade panel.

## 12. Any-Fish Machine Recipe Design

Current Fisher placement recipe:

```text
Wood 6
Generic Fish 3
```

Target Fisher placement recipe:

```text
Wood 6
Any Fish x3
```

Recommended data structure:

```gdscript
const ITEM_CATEGORIES = {
	"fish": [
		Enum.Item.GRAY_CARP,
		Enum.Item.SILVER_PERCH,
		Enum.Item.GOLDEN_KOI,
		Enum.Item.RED_SNAPPER,
	]
}

const MACHINE_CATEGORY_COSTS = {
	Enum.Machine.FISHER: {
		"fish": 3
	}
}
```

Recommended helper API:

```gdscript
func get_total_category_amount(category_id: StringName) -> int
func can_afford_category_cost(category_id: StringName, required_amount: int) -> bool
func consume_category_items(category_id: StringName, required_amount: int) -> Dictionary
```

Consumption order:

```text
Lowest sell price
-> Highest owned amount
-> Stable enum order
```

For the proposed prices, this means consume `GRAY_CARP` before `SILVER_PERCH`, then `GOLDEN_KOI`, then `RED_SNAPPER`. This protects rare fish from automatic consumption.

UI display:

```text
Any Fish 2/3
```

or:

```text
Fish 2/3
```

The build selector can show a category icon using the most common fish icon (`GRAY_CARP`) or a small stacked fish icon later. It should not require one specific fish species.

Atomic placement requirements:

- Invalid placement should consume no wood and no fish.
- Insufficient category amount should consume no wood and no fish.
- Successful placement should deduct concrete fish species according to the deterministic order.
- Machine placement telemetry should record both category cost and actual species consumed.

Suggested telemetry field:

```json
"category_materials_consumed": {
	"fish": {
		"gray_carp": 2,
		"silver_perch": 1
	}
}
```

## 13. Shared Trade Panel Migration

Final trade behavior:

```text
Generic FISH: not shown
GRAY_CARP: own row
SILVER_PERCH: own row
GOLDEN_KOI: own row
RED_SNAPPER: own row
```

Data updates required:

| Data Map | Required Change |
| --- | --- |
| `TRADEABLE_ITEMS` | Remove `Enum.Item.FISH`; add all fish species. |
| `ITEM_BUY_PRICES` | Remove active generic `FISH`; add species prices. |
| `ITEM_SELL_PRICES` | Remove active generic `FISH`; add species prices. |
| `MERCHANT_CATALOGS["courier"]["items"]` | If still points at `TRADEABLE_ITEMS`, species are automatically listed. |
| `SALE_TELEMETRY_SOURCES` | Add `sale_gray_carp`, `sale_silver_perch`, `sale_golden_koi`, `sale_red_snapper`. |
| `BUY_TELEMETRY_SOURCES` | Add `buy_gray_carp`, `buy_silver_perch`, `buy_golden_koi`, `buy_red_snapper`. |
| `ITEM_TELEMETRY_KEYS` | Add `gray_carp`, `silver_perch`, `golden_koi`, `red_snapper`. Keep `fish` only for compatibility if generic remains in snapshots. |

The current `MerchantTradeUI` already reads names, textures, prices, and owned quantities from `Data`, so it should not need fish-specific row logic.

## 14. Inventory Migration

Current inventory:

```gdscript
for item: Enum.Item in Data.ITEMS_AMOUNT.keys():
	...
```

Risk:

- If deprecated `Enum.Item.FISH` remains in `ITEMS_AMOUNT`, it will keep appearing in inventory even after it is no longer catchable/tradeable.

Recommended migration:

```gdscript
const VISIBLE_INVENTORY_ITEMS = [
	Enum.Item.WOOD,
	Enum.Item.APPLE,
	Enum.Item.TOMATO,
	Enum.Item.CORN,
	Enum.Item.WHEAT,
	Enum.Item.PUMPKIN,
	Enum.Item.TOMATO_SEED,
	Enum.Item.CORN_SEED,
	Enum.Item.PUMPKIN_SEED,
	Enum.Item.WHEAT_SEED,
	Enum.Item.GRAY_CARP,
	Enum.Item.SILVER_PERCH,
	Enum.Item.GOLDEN_KOI,
	Enum.Item.RED_SNAPPER,
]
```

Then inventory should iterate `VISIBLE_INVENTORY_ITEMS` instead of all `ITEMS_AMOUNT.keys()`. This preserves deprecated data without showing it as an active item.

Species requirements:

- Each species needs a texture entry.
- Each species needs an item ID and display name.
- Each species should exist in `ITEMS_AMOUNT` with starting amount `0`.
- UI should read `Data.get_item_texture()` and `Data.get_item_display_name()`, not fish-specific hardcoded names.
- Coin HUD is unaffected.
- Seed/Crop entries are unaffected.

## 15. Telemetry Migration

Add to playtest metrics:

```gdscript
"fish_catches_by_species": {},
"fish_catch_events": [],
```

Suggested event:

```json
{
	"day_id": 2,
	"elapsed_seconds": 300.5,
	"source": "manual",
	"item_id": "SILVER_PERCH",
	"rarity": "common_uncommon",
	"inventory_amount_after": 4
}
```

Sources:

| Source | Meaning |
| --- | --- |
| `manual` | Manual fishing minigame success. |
| `automatic_fisher` | Automatic Fisher timer production. |

Sale and buy sources:

| Fish | Sale Source | Buy Source |
| --- | --- | --- |
| `GRAY_CARP` | `sale_gray_carp` | `buy_gray_carp` |
| `SILVER_PERCH` | `sale_silver_perch` | `buy_silver_perch` |
| `GOLDEN_KOI` | `sale_golden_koi` | `buy_golden_koi` |
| `RED_SNAPPER` | `sale_red_snapper` | `buy_red_snapper` |

Compatibility:

- Existing V1/V2 logs remain unchanged.
- `sale_fish` and `buy_fish` should be kept only as historical names or compatibility readers.
- New catches should not be recorded as coin income.
- Coin income occurs only when fish species are sold.

## 16. Gift and Quest Impact

Current audit:

| System | Current Fish Dependency | Migration Recommendation |
| --- | --- | --- |
| Mira gifts | None. `mira_gift_preferences.tres` uses Tomato, Wheat, Corn, Pumpkin. | No change required. Future fish gifts should use species or category explicitly. |
| Quests | None. `mira_still_sprouts_quest.tres` target is `WHEAT`. | No change required. Future fish quest objectives should choose specific species or an Any Fish objective category. |
| Style cost legacy | `STYLE_UPGRADES[Enum.Style.STRAW]` uses `FISH 8`, but current H2 shop does not sell Straw. | Before re-enabling Straw purchases, migrate to Any Fish or remove the generic cost. |
| Blueprint legacy cost | `MACHINE_UPGRADE_COST[Enum.Machine.FISHER].cost` uses `FISH 15`, but current H2 blueprint purchase uses coin costs. | Treat old table as display/legacy risk. Do not revive generic fish material cost. |

## 17. Safe Implementation Phases

### H3B Phase 1: Append fish item enums and inert Data entries

Modified files:

- `scripts/global/enums.gd`
- `scripts/global/data.gd`

Work:

- Append `GRAY_CARP`, `SILVER_PERCH`, `GOLDEN_KOI`, `RED_SNAPPER`.
- Add item IDs, display names, starting amounts, texture entries.
- Do not switch manual fishing, automatic Fisher, trade, or recipes yet.

Runtime tests:

- Project loads.
- Existing generic `FISH` still works.
- Inventory/trade behavior unchanged unless visible item list is intentionally introduced as inert.

Compatibility requirements:

- Existing enum integers unchanged.
- `Enum.Item.FISH` remains valid.

Rollback risk:

- Low. Remove appended entries if no runtime paths use them yet.

### H3B Phase 2: Add fish textures, prices, catalogs, and telemetry keys

Modified files:

- `scripts/global/data.gd`

Work:

- Add species buy/sell prices.
- Add species telemetry source names.
- Add species rarity data and drop tables.
- Keep generic `FISH` active until reward switching is ready.

Runtime tests:

- Merchant UI can render species if manually included.
- No missing texture/name warnings.

Compatibility requirements:

- Generic `FISH` prices remain available until removed from active trade.

Rollback risk:

- Low/medium. Data-only change, but bad texture paths can break load.

### H3B Phase 3: Switch manual fishing to weighted species catches

Modified files:

- `scripts/characters/player.gd`
- `scripts/ui/fishing_game.gd` if the success signal needs fish identity
- `scripts/global/data.gd`

Work:

- On manual success, roll species table.
- Add species item +1.
- Add catch event telemetry.
- Preserve existing attempt/success/failure/duration telemetry.

Runtime tests:

- Success adds exactly one species.
- Failure adds nothing.
- Duplicate finish signal adds only once.
- No direct coins.

Compatibility requirements:

- Generic `FISH` no longer produced by manual fishing.

Rollback risk:

- Medium. Reward settlement path changes.

### H3B Phase 4: Switch Automatic Fisher to restricted species table

Modified files:

- `scripts/machines/fisherman.gd`
- `scripts/global/data.gd`

Work:

- Timer production rolls restricted table.
- Only common/common-uncommon species can be produced.
- Add catch telemetry source `automatic_fisher`.

Runtime tests:

- Timer adds one species.
- Rare fish never produced by automatic table.
- No direct coins.

Compatibility requirements:

- Generic `FISH` no longer produced by automatic Fisher.

Rollback risk:

- Medium. Passive production path changes.

### H3B Phase 5: Add Any-Fish category recipe support

Modified files:

- `scripts/global/data.gd`
- `scripts/level.gd`
- `scripts/ui/machine_build_selector.gd`

Work:

- Add `ITEM_CATEGORIES` and category-cost helpers.
- Move Fisher from concrete `Enum.Item.FISH: 3` to category `fish: 3`.
- Display `Any Fish x3`.
- Deduct lowest-sell-price fish first.
- Record actual species consumed in machine placement telemetry.

Runtime tests:

- Total fish count across species satisfies Fisher recipe.
- Invalid placement consumes nothing.
- Insufficient materials consume nothing.
- Successful placement consumes wood and concrete fish species once.

Compatibility requirements:

- If old generic `FISH` exists in inventory, decide whether it counts. Recommendation: do not count deprecated generic fish unless a one-time migration converts it.

Rollback risk:

- Medium/high. Placement validation and deduction are shared economy-critical code.

### H3B Phase 6: Remove Generic FISH from active UI/Trade paths

Modified files:

- `scripts/global/data.gd`
- `scripts/ui/inventory.gd`
- Possibly `scripts/ui/resourse_texture.gd`

Work:

- Remove `Enum.Item.FISH` from `TRADEABLE_ITEMS` and merchant catalogs.
- Add visible inventory whitelist excluding deprecated `FISH`.
- Keep compatibility maps for old IDs.

Runtime tests:

- Generic Fish no longer appears in trade or inventory.
- Species appear as separate rows.
- Old logs/saves that mention `FISH` do not crash.

Compatibility requirements:

- Keep `ITEM_ID_TO_ENUM["FISH"]`.
- Keep display name/texture for defensive reads.

Rollback risk:

- Medium. UI visibility and trade paths change.

### H3B Phase 7: Runtime migration tests and economy validation

Modified files:

- Test protocols/docs as needed.

Work:

- Run focused tests for manual fishing, automatic Fisher, trade, Any Fish recipe, inventory, telemetry.
- Verify weighted average fish sale value stays near 14-18 and does not exceed old generic value substantially.

Runtime tests:

- 100+ manual successful catches in a debug harness or deterministic simulation.
- 100+ automatic Fisher rolls in a deterministic simulation.
- Buy/sell all species.
- Place Fisher with mixed fish inventory.
- Verify telemetry JSON.

Compatibility requirements:

- Existing Day 4 economy remains stable.

Rollback risk:

- Low if previous phases are already stable.

## 18. Risks and Rollback Plan

| Risk | Impact | Mitigation | Rollback |
| --- | --- | --- | --- |
| Fourth fish asset style mismatch | UI looks inconsistent | Use Red Ninja fish only as temporary fourth species; replace texture later without changing enum/ID | Keep three species temporarily if art quality blocks release. |
| Enum reorder accident | Save/log breakage | Append only; never insert | Revert enum change before shipping if no saves were produced. |
| Generic `FISH` remains visible | Confusing duplicate fish rows | Add visible inventory whitelist and remove generic from trade | Re-add generic to visible lists temporarily if migration breaks inventory. |
| Machine recipe consumes rare fish | Player frustration/economy loss | Deterministic consume order by lowest sell price first | Revert category consumption and require common fish only if needed. |
| Passive Fisher produces rare fish | Economy inflation | Use restricted automatic table | Set rare weights to zero or disable automatic species roll. |
| Telemetry loses old fish comparability | Harder V2 comparison | Preserve old counters and add species fields | Keep generic summary fields in reports while adding species details. |
| Minigame fish identity conflicts with reward species | Player sees one fish, receives another | Either keep minigame display generic until unified, or emit/reward the same species | Use separate reward roll temporarily and document UX caveat. |

## 19. Recommended First Coding Step

Start H3B with the lowest-risk data foundation:

1. Append fish item enums in `scripts/global/enums.gd`.
2. Add inert species entries to `scripts/global/data.gd`:
   - `ITEMS_AMOUNT`
   - `ITEM_IDS`
   - `ITEM_ID_TO_ENUM`
   - `ITEM_DISPLAY_NAMES`
   - `TEXTURES` or atlas texture helper data
   - `ITEM_TELEMETRY_KEYS`
3. Add `FISH_SPECIES_ITEMS` and `FISH_RARITIES` constants.
4. Do not yet change manual fishing, automatic Fisher, recipes, trade, or inventory visibility.

This creates a stable base that can be loaded and inspected before any reward path changes.
