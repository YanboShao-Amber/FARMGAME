# FarmGame System Design - Day 1 Raw Data Baseline

Engine: Godot 4.6

Document Type: Pre-Balance As-Is Audit

Runtime Data Source: `scripts/global/data.gd`

Purpose: Record the actual economy, production, shop and reward values before balance redesign.

Important Rule: Missing values remain marked as `Not Implemented` or `Not Found`. No estimated values are used.

## 1. Crop System Baseline

| Crop    |       Seed Cost |      Sell Price | Growth Days | Harvest Amount | Regrow | Runtime Source    |
| ------- | --------------: | --------------: | ----------: | -------------: | ------ | ----------------- |
| Tomato  | Not Implemented | Not Implemented |           4 |              2 | No     | `Data.PLANT_DATA` |
| Corn    | Not Implemented | Not Implemented |           3 |              2 | No     | `Data.PLANT_DATA` |
| Pumpkin | Not Implemented | Not Implemented |          12 |              2 | No     | `Data.PLANT_DATA` |
| Wheat   | Not Implemented | Not Implemented |           3 |              2 | No     | `Data.PLANT_DATA` |

```text
Growth Days = ceil(h_frames / grow_speed)
Runtime h_frames = 3
```

Crop growth speed values:

| Crop    | grow_speed |
| ------- | ---------: |
| Tomato  |       0.75 |
| Corn    |       1.0 |
| Pumpkin |       0.25 |
| Wheat   |       1.0 |

Runtime notes:

- All crops use `harvested_amount = 2`.
- All crops execute `queue_free()` after harvest, so repeat harvest is not implemented.
- Planting consumes one mature crop item from the same crop inventory, not a separate seed item.
- Planting does not spend coins.
- Crops currently cannot be sold.

Primary files:

- `scripts/global/data.gd`
- `resources/plant_res.gd`
- `scripts/objects/plant.gd`
- `scripts/level.gd`

## 2. Fishing System Baseline

| Fish        | Displayed Rarity | Selection Probability | Inventory Reward |      Sell Price | Catch Amount |
| ----------- | ---------------- | --------------------: | ---------------- | --------------: | -----------: |
| Gray Fish   | Common           |                33.33% | Generic Fish     | Not Implemented |            1 |
| Silver Fish | Rare             |                33.33% | Generic Fish     | Not Implemented |            1 |
| Gold Fish   | Legendary        |                33.33% | Generic Fish     | Not Implemented |            1 |

Runtime notes:

- The three fish use `Enum.Fish.values().pick_random()`, so the actual selection is equal probability.
- `Common`, `Rare` and `Legendary` currently do not affect selection probability.
- The specific fish type is not preserved after a successful manual catch.
- All successful manual catches increase the same generic inventory item:

```gdscript
Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1
```

- Fish currently cannot be sold or exchanged for coins.
- Manual fishing has no resource cost.
- Manual fishing has no fixed maximum duration.
- The player's real success rate and average completion time must be measured during Day 4 testing.

Theoretical minimum minigame completion time:

| Fish   |   Theoretical Minimum Time |
| ------ | -------------------------: |
| Gray   |                3.9 seconds |
| Silver | Approximately 5.07 seconds |
| Gold   |                7.4 seconds |

These times are theoretical values under ideal continuous-hit conditions. They do not represent the player's real average completion time.

## 3. Automatic Fishing Machine Baseline

| Field                   | Current Runtime Value |
| ----------------------- | --------------------- |
| Unlock Cost             | Wood 25 + Fish 15     |
| Placement Cost          | 0                     |
| Output                  | Generic Fish x1       |
| Output Probability      | 100%                  |
| Timer Duration          | 30 seconds            |
| Approximate Total Cycle | 30.8 seconds          |
| Capacity Limit          | Not Implemented       |
| Manual Collection       | Not Required          |
| Weather Dependency      | None                  |
| Day Dependency          | None                  |
| Placement Limit         | None Found            |

Runtime notes:

- Fisher cost is used only for the first unlock.
- After unlock, the Fisher can be placed repeatedly with no additional cost.
- Each placed Fisher produces independently.
- Output is added directly to global inventory.
- Player collection is not required.
- Capacity limit is not implemented.
- Automatic fishing does not use the Gray, Silver or Gold random selection logic.

## 4. Shop Baseline

### Main Shop

| Product   | Unlock Cost          | Currency Type | Coin Cost | Placement Cost |
| --------- | -------------------- | ------------- | --------: | -------------: |
| Sprinkler | Tomato 30 + Wheat 20 | Items         |         0 |              0 |
| Fisher    | Wood 25 + Fish 15    | Items         |         0 |              0 |
| Scarecrow | Pumpkin 15 + Corn 15 | Items         |         0 |              0 |

### Hat Shop

| Product  | Unlock Cost         | Currency Type | Coin Cost |
| -------- | ------------------- | ------------- | --------: |
| Cowboy   | Wood 8 + Corn 6     | Items         |         0 |
| Baseball | Tomato 8 + Apple 6  | Items         |         0 |
| Beanie   | Pumpkin 8 + Wheat 6 | Items         |         0 |

Runtime notes:

- Shop purchases check item inventory.
- Shop purchases deduct the configured item costs.
- Shops do not check coin balance.
- Shops do not deduct coins.
- A purchase is a permanent unlock, not a purchase of one machine instance.
- Already unlocked products are hidden from the shop UI.
- After a machine is unlocked, later placement has no resource cost.
- If the player lacks enough resources, feedback is console output only and is not visible in the game UI.

## 5. Other Configured Costs

| Content         | Configured Cost    | Runtime Status                            |
| --------------- | ------------------ | ----------------------------------------- |
| House Upgrade 1 | Wood 30 + Apple 20 | Config exists but not connected           |
| House Upgrade 2 | Wood 40 + Apple 30 | Config exists but not connected           |
| Old Greenhouse  | Not Found          | State system exists, cost not implemented |

Unconnected configuration should not be treated as an available runtime feature.

## 6. Quest Reward Baseline

| Quest ID             | Quest Name              | Objective     | Target | Coin Reward | Item Reward | Relationship Reward | Repeatable |
| -------------------- | ----------------------- | ------------- | -----: | ----------: | ----------- | ------------------: | ---------- |
| `mira_still_sprouts` | Seeds That Still Sprout | Harvest Wheat |      3 |         100 | Not Granted |           Not Found | No         |

Runtime notes:

- Completing the quest actually calls `Data.add_coins(100)`.
- `QuestData` has item reward fields.
- Current reward-granting logic does not handle item rewards.
- This is the only quest coin reward source found.

## 7. Coin Flow Baseline

### Coin Sources

| Source            | Amount | Repeatable |
| ----------------- | -----: | ---------- |
| Initial Inventory |    250 | No         |
| Mira Quest Reward |    100 | No         |

### Coin Sinks

```text
No runtime coin sinks were found.
```

### Runtime Coin Data

- Coin variable: `Data.ITEMS_AMOUNT[Enum.Item.COIN]`
- Initial amount: `250`
- Coin addition function: `Data.add_coins(amount)`
- Dedicated coin spending function: Not Implemented
- Shop coin balance check: Not Implemented
- Crop selling income: Not Implemented
- Fish selling income: Not Implemented
- Machine purchase coin cost: Not Implemented
- Cosmetic purchase coin cost: Not Implemented

## 8. Current Resource Loops

### Crop Loop

```text
Existing crop inventory
-> Plant one crop
-> Water across multiple days
-> Harvest two crops
-> Net gain of one crop
```

### Manual Fishing Loop

```text
Player time and skill
-> Fishing minigame
-> Generic Fish x1
```

### Machine Unlock Loop

```text
Accumulate required items
-> Spend items once
-> Permanently unlock machine
-> Place unlimited copies for free
```

### Automatic Fisher Loop

```text
Free machine placement after unlock
-> Wait approximately 30.8 seconds
-> Generic Fish x1
-> Repeat without capacity limit
```

### Coin Loop

```text
Start with 250 coins
-> Complete one Mira quest
-> Receive 100 coins
-> No implemented spending destination
```

## 9. As-Is System Diagnosis

1. The crop system currently has production values but no monetary value.
2. The fishing system has rarity labels but no rarity-based reward differences.
3. All manually caught fish become the same generic inventory item.
4. Coins are disconnected from shops, crops, fishing and machines.
5. The game currently has coin sources but no coin sinks.
6. Machine costs function as one-time unlock costs rather than construction costs.
7. Unlimited free placement makes machine quantity independent from the economy.
8. The automatic Fisher can create unlimited Fish without capacity, collection or operating costs.
9. Crop harvest amounts are identical across all crop types.
10. Corn and Wheat currently have identical growth and harvest values.
11. Pumpkin takes four times as long as Corn or Wheat but currently has no higher economic reward.
12. The existing economy cannot yet be evaluated using coin-per-day because crops and fish have no sell prices.
13. The current resource loops can be documented, but a monetary balance model requires new design values during Day 2 and implementation during Day 3.

## 10. Data Integrity Notes

- The actual Autoload data source is `scripts/global/data.gd`.
- Root-level `global/data.gd` is a duplicate old file.
- Some data in the old file differs from runtime data.
- Future balance design should reference only the actual Autoload data source.
- Current `0` formula results in the Excel workbook are not runtime data, because price fields are not implemented.
- Missing prices must remain `Not Implemented` and must not be written as `0`, because "free" and "not implemented" are different states.

## 11. Day 1 Completion Status

## Day 1 Result

Day 1 code and data auditing is complete.

The project contains functional production and resource systems, but it does not yet contain a connected monetary economy. Day 2 will therefore define a target economic model rather than merely rebalance existing sell prices.
