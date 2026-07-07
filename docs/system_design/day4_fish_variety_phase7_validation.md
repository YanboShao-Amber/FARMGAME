# Day 4 Fish Variety Phase 7 Validation

## 1. Final Fish Architecture

Final runtime state:

```text
Manual Fishing -> Gray Carp / Silver Perch / Golden Koi / Red Snapper
Automatic Fisher -> Gray Carp / Silver Perch
Fisher Placement -> Wood 6 + Any Fish x3
Inventory -> four species visible, Generic Fish hidden
Trade -> four species buyable/sellable, Generic Fish unavailable
Generic FISH -> deprecated compatibility data only
```

`PLAYTEST_RUN_LABEL` is now `V3_FISH_SPECIES`, so new playtest logs should use:

```text
farmgame_day4_V3_FISH_SPECIES_<timestamp>.json
```

## 2. Enum and Compatibility Status

Generic `Enum.Item.FISH` remains for compatibility and old logs/data:

- `Enum.Item.FISH`
- `ITEMS_AMOUNT[Enum.Item.FISH]`
- `ITEM_IDS[Enum.Item.FISH] = "FISH"`
- `ITEM_ID_TO_ENUM["FISH"]`
- `ITEM_DISPLAY_NAMES["FISH"] = "Fish"`
- Generic Fish icon/texture
- `ITEM_TELEMETRY_KEYS[Enum.Item.FISH] = "fish"`
- `ITEM_BUY_PRICES[Enum.Item.FISH] = 22`
- `ITEM_SELL_PRICES[Enum.Item.FISH] = 15`
- `BUY_TELEMETRY_SOURCES[Enum.Item.FISH] = "buy_fish"`
- `SALE_TELEMETRY_SOURCES[Enum.Item.FISH] = "sale_fish"`

Generic Fish is not in:

- `FISH_SPECIES_ITEMS`
- `TRADEABLE_ITEMS`
- `VISIBLE_INVENTORY_ITEMS`
- `ITEM_CATEGORIES["fish"]`
- `MACHINE_PLACEMENT_COSTS[Enum.Machine.FISHER]`

## 3. Manual Fishing Results

Manual fishing uses `MANUAL_FISHING_DROP_TABLE`:

| Fish | Weight | Roll Range |
| --- | ---: | --- |
| Gray Carp | 50 | 1-50 |
| Silver Perch | 30 | 51-80 |
| Golden Koi | 15 | 81-95 |
| Red Snapper | 5 | 96-100 |

Static integration checks:

- Success path calls `Data.roll_manual_fish_species()`.
- Success path adds exactly one specific species.
- Success path calls `Data.record_fish_catch(caught_fish, "manual")`.
- Generic Fish is not incremented.
- Coin is not incremented.
- `fishing_result_resolved` remains before reward and telemetry logic.

## 4. Automatic Fisher Results

Automatic Fisher uses `AUTOMATIC_FISHER_DROP_TABLE`:

| Fish | Weight | Roll Range |
| --- | ---: | --- |
| Gray Carp | 70 | 1-70 |
| Silver Perch | 30 | 71-100 |

Static integration checks:

- Fisher timeout calls `Data.roll_automatic_fish_species()`.
- Fisher adds exactly one Gray Carp or Silver Perch.
- Fisher calls `Data.record_fish_catch(caught_fish, "automatic_fisher")`.
- Fisher saves telemetry once with `automatic_fisher_catch`.
- Generic Fish, Golden Koi, and Red Snapper are not produced by Automatic Fisher.
- Manual fishing attempt/success/failure counters are not touched by Fisher production.

## 5. Probability Simulation

Independent 100,000-roll simulations were run outside inventory and telemetry state.

Manual:

| Fish | Count | Result | Target |
| --- | ---: | ---: | ---: |
| Gray Carp | 49,855 | 49.86% | 50% |
| Silver Perch | 30,057 | 30.06% | 30% |
| Golden Koi | 15,191 | 15.19% | 15% |
| Red Snapper | 4,897 | 4.90% | 5% |

Automatic:

| Fish | Count | Result | Target |
| --- | ---: | ---: | ---: |
| Gray Carp | 70,251 | 70.25% | 70% |
| Silver Perch | 29,749 | 29.75% | 30% |
| Golden Koi | 0 | 0.00% | 0% |
| Red Snapper | 0 | 0.00% | 0% |
| Generic Fish | 0 | 0.00% | 0% |

Boundary resolver checks passed for manual rolls `1, 50, 51, 80, 81, 95, 96, 100` and automatic rolls `1, 70, 71, 100`. Invalid roll/table cases returned safe failure in the independent harness.

## 6. Inventory Validation

Inventory now uses `Data.get_visible_inventory_items()` instead of `Data.ITEMS_AMOUNT.keys()`.

Visible fish:

- Gray Carp
- Silver Perch
- Golden Koi
- Red Snapper

Hidden compatibility item:

- Generic Fish

Coin is also not part of normal inventory rows. Visual verification of icons, focus order, and refresh behavior remains a manual UI test.

## 7. Trade Validation

Trade UI reads:

- Buy rows from `MERCHANT_CATALOGS[merchant_id]["items"]`.
- Sell rows from `Data.TRADEABLE_ITEMS`.

Four species remain tradeable:

| Fish | Buy | Sell |
| --- | ---: | ---: |
| Gray Carp | 16 | 9 |
| Silver Perch | 24 | 14 |
| Golden Koi | 38 | 24 |
| Red Snapper | 65 | 42 |

Generic Fish remains in compatibility price maps, but direct `try_buy_item(Enum.Item.FISH, ...)` and `try_sell_item(Enum.Item.FISH, ...)` are rejected by the tradeable whitelist.

## 8. Any-Fish Recipe Validation

Final Fisher placement recipe:

```text
Wood 6
Any Fish 3
```

`Any Fish` includes only the four specific fish species. Generic Fish does not count.

Consumption priority:

```text
Lowest Sell Price -> Highest Owned Amount -> Stable Enum Integer
```

Verified deterministic examples:

```text
Gray 2, Silver 2, Golden 2, Red 2
-> consume Gray 2, Silver 1
```

```text
Gray 1, Silver 0, Golden 1, Red 5
-> consume Gray 1, Golden 1, Red 1
```

```text
Gray 0, Silver 4, Golden 1, Red 1
-> consume Silver 3
```

## 9. Telemetry Validation

Catch telemetry:

- `fish_catches_by_species`
- `fish_catch_events`
- Event fields include `source`, `item_id`, `rarity`, `inventory_amount_after`, `day_id`, and `elapsed_seconds`.

Trade telemetry:

- Species buys write `buy_gray_carp`, `buy_silver_perch`, `buy_golden_koi`, `buy_red_snapper`.
- Species sales write `sale_gray_carp`, `sale_silver_perch`, `sale_golden_koi`, `sale_red_snapper`.
- New runtime should not generate `buy_fish` or `sale_fish`.

Placement telemetry:

```json
{
  "resource_costs": {
    "wood": 6
  },
  "category_costs": {
    "fish": 3
  },
  "category_materials_consumed": {
    "fish": {
      "gray_carp": 2,
      "silver_perch": 1
    }
  }
}
```

Machine placement consumption is not recorded as sale telemetry and does not change catch aggregates.

## 10. Economy Value Analysis

Manual weighted sell value:

```text
0.50 * 9 + 0.30 * 14 + 0.15 * 24 + 0.05 * 42 = 14.40
```

Automatic Fisher weighted sell value:

```text
0.70 * 9 + 0.30 * 14 = 10.50
```

Using the V2 reference success rate:

```text
15 successes / 17 attempts = 88.24%
```

Expected manual fishing value:

```text
Per attempt: 14.40 * 15 / 17 = 12.71 coins
5 attempts/day: 63.53 coins/day
```

The old Generic Fish sell value baseline was:

```text
15 * 15 / 17 * 5 = 66.18 coins/day
```

So the new manual fishing expected value is close to the old Generic Fish baseline, slightly lower by about 2.65 coins/day under the V2 success-rate assumption.

Any Fish x3 opportunity cost:

- Minimum: 3 Gray Carp = 27 coins
- Common mixed case: Gray 2 + Silver 1 = 32 coins
- Maximum if only Red Snapper is available: 126 coins

The deterministic low-price-first consumption order protects rare and high-value fish when lower-value fish are available. Rare fish can still create payout spikes, but their 5% and 15% weights keep average value close to the old 15-coin Generic Fish baseline.

## 11. Known Limitations

- Fishing minigame visual fish type is still independent from final inventory reward species.
- Red Snapper uses the first frame of a sprite sheet and may visually differ from the other fish icons.
- No automated UI interaction test was performed for mouse, keyboard, or Xbox focus behavior.
- No live 30-second Automatic Fisher wait test was performed in this validation pass.
- Legacy configs still reference Generic Fish:
  - `MACHINE_UPGRADE_COST[Enum.Machine.FISHER]["cost"]`
  - `STYLE_UPGRADES[Enum.Style.STRAW]["cost"]`

## 12. Manual UI Tests Still Required

- Inventory visual check with Generic Fish > 0 and all four species > 0.
- Courier/Cat/Mouse Trade tab visual checks.
- Buy 1, Sell 1, Buy Max, and Sell All for all four fish.
- Fisher placement with mouse.
- Fisher placement with keyboard.
- Fisher placement with Xbox controller.
- Trade list scrolling/focus after Generic Fish removal.
- Fishing reward feedback clarity.

## 13. Final H3B Status

Automated/static validation and Godot headless loading passed. The fish variety system is technically ready for the V3 manual playtest, with UI and controller behavior still requiring manual confirmation.
