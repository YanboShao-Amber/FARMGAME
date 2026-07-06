# FarmGame System Design - Day 2 Scenario Economy Model v1

Engine: Godot 4.6

Document Type: Provisional Economy Scenario Model

Baseline Source: `docs/system_design/day1_raw_data_baseline.md`

Important Rule: This document proposes candidate design values only. It does not describe implemented runtime prices unless explicitly marked as runtime-confirmed.

## 1. Separate Facts from Assumptions

## Runtime-Confirmed Facts

| Parameter                     | Confirmed Value            |
| ----------------------------- | -------------------------- |
| Starting Coins                | 250                        |
| Starting Tomato               | 50                         |
| Starting Corn                 | 50                         |
| Starting Pumpkin              | 50                         |
| Starting Wheat                | 50                         |
| Starting Fish                 | 50                         |
| Starting Wood                 | 50                         |
| Starting Apple                | 50                         |
| Practical Starting Soil Tiles | 28                         |
| Tomato Growth                 | 4 days                     |
| Corn Growth                   | 3 days                     |
| Pumpkin Growth                | 12 days                    |
| Wheat Growth                  | 3 days                     |
| Harvest Amount                | 2 for every crop           |
| Crop Regrow                   | No                         |
| Fisher Cycle                  | Approximately 30.8 seconds |
| Enforced Day Duration         | None                       |
| Stamina Limit                 | None                       |
| Fishing Daily Limit           | None                       |
| Crop Sell Price               | Not Implemented            |
| Fish Sell Price               | Not Implemented            |
| Runtime Coin Sinks            | None                       |

## Provisional Design Assumptions

The following parameters are not current code facts. They are first-pass design assumptions for modeling only and must be calibrated during Day 4 playtesting:

- Crop sell prices.
- Generic Fish sell price.
- Quest reward target.
- Coin costs for shop purchases.
- Low / Expected / High player activity levels.
- Fishing success rate and average attempt duration.
- First 5-day planting mix.
- Suggested replacement starting inventory.

## 2. Core Economy Design Goals

1. Farming should be the most stable and predictable income source.
2. Manual fishing should provide faster active income but require player time and skill.
3. Quest rewards should create milestone bursts, not replace the repeatable economy.
4. No single repeatable activity should contribute more than 50% of total income in the Expected mixed-play scenario.
5. Different crops must have different economic roles.
6. Longer growth time must provide meaningfully higher return or another clear advantage.
7. The first meaningful coin purchase should occur around Day 2 or Day 3 in the Expected scenario.
8. The player should not be able to purchase every major unlock immediately.
9. Initial inventory must not allow the player to become rich simply by selling debug resources.
10. The economy should support visible choices between spending now and saving for a larger unlock.
11. Machines should function as investments rather than unlimited free production.
12. Values must remain simple enough to explain in a portfolio interview.

## 3. Important Crop Accounting Rule

Current planting consumes one mature crop from inventory and harvesting returns two mature crops.

```text
Harvested Amount = 2
Required Replant Reserve = 1
Saleable Net Yield = 1
```

## Gross Yield

```text
Gross Yield = 2 crops
```

## Sustainable Saleable Yield

```text
Sustainable Saleable Yield = 2 harvested - 1 reserved for replanting
Sustainable Saleable Yield = 1
```

The crop economy model uses `Sustainable Saleable Yield = 1`. It does not treat both harvested crops as profit, because one crop must be reserved for continued planting.

```text
Crop Net Coin Income per Cycle
= Sell Price x Sustainable Saleable Yield

Crop Net Coin Income per Tile per Day
= Crop Net Coin Income per Cycle / Growth Days
```

Because there is currently no separate seed coin cost:

```text
Coin Seed Cost = 0
```

This does not mean planting is free. The player pays one crop inventory item as an opportunity cost.

## 4. Three Activity Scenarios

All values in this section are `Provisional Assumption`.

| Parameter                            | Low Activity | Expected Activity | High Activity |
| ------------------------------------ | -----------: | ----------------: | ------------: |
| Real Play Time per Game Day          |    8 minutes |        15 minutes |    25 minutes |
| Active Crop Tiles                    |            8 |                16 |            28 |
| Manual Fishing Attempts per Day      |            2 |                 5 |            10 |
| Fishing Success Rate                 |          50% |               70% |           85% |
| Average Fishing Attempt Duration     |   25 seconds |        18 seconds |    14 seconds |
| Quests Completed across First 5 Days |            1 |                 1 |             1 |

Notes:

- 28 tiles comes from the current starting `SoilLayer` tilled area.
- Low and Expected are behavior assumptions, not code limits.
- Fishing duration and success rate must be replaced after Day 4 playtesting.
- The current game has no enforced day length, so these scenarios represent voluntary player activity levels rather than system caps.

## 5. Crop Role Definition

| Crop    | Growth Days | Intended Role                   | Target Daily Return Relationship |
| ------- | ----------: | ------------------------------- | -------------------------------- |
| Wheat   |           3 | Starter crop, fast and reliable | Lowest baseline                  |
| Corn    |           3 | Efficient general-purpose crop  | Slightly above Wheat             |
| Tomato  |           4 | Medium-cycle cash crop          | Above Corn                       |
| Pumpkin |          12 | Long-term capital commitment    | Highest daily return             |

Target relationship:

```text
Wheat Daily Return
< Corn Daily Return
< Tomato Daily Return
< Pumpkin Daily Return
```

Suggested relationship ranges:

- Corn should be about 10% to 35% above Wheat.
- Tomato should be about 10% to 35% above Corn.
- Pumpkin should be about 15% to 40% above Tomato on a per-day basis.

These ranges are design suggestions, not runtime data. Pumpkin can have the best daily return because it also has the highest waiting cost and does not mature within the first five-day model.

## 6. Candidate Economy Sets

## Conservative Economy

Design intent: slower progression, lower repeatable income, and stronger protection against early overbuying.

### A. Crop Sell Prices

| Crop    | Growth Days | Saleable Yield | Sell Price | Coin per Tile per Day |
| ------- | ----------: | -------------: | ---------: | --------------------: |
| Wheat   |           3 |              1 |         15 |                  5.00 |
| Corn    |           3 |              1 |         20 |                  6.67 |
| Tomato  |           4 |              1 |         30 |                  7.50 |
| Pumpkin |          12 |              1 |        110 |                  9.17 |

Check:

- Daily return order is Wheat < Corn < Tomato < Pumpkin.
- Pumpkin is best on daily return, but it locks capital for 12 days and creates no first-five-day income.
- There is no unconditional best crop in the first five days because Pumpkin does not mature in that window.

### B. Generic Fish Sell Price

Generic Fish price: 20 coins.

| Scenario | Attempts | Success Rate | Expected Fish | Fish Price | Expected Fishing Income |
| -------- | -------: | -----------: | ------------: | ---------: | ----------------------: |
| Low      |        2 |          50% |           1.0 |         20 |                      20 |
| Expected |        5 |          70% |           3.5 |         20 |                      70 |
| High     |       10 |          85% |           8.5 |         20 |                     170 |

### C. Quest Reward

Recommended quest reward: 80 coins.

```text
Expected Daily Repeatable Income
= (Expected Five-Day Farming Income + Expected Five-Day Fishing Income) / 5
= (275 + 350) / 5
= 125

Quest Reward / Expected Daily Repeatable Income
= 80 / 125
= 0.64
```

This makes the quest noticeable without replacing several days of normal repeatable income.

### D. Major Purchase Targets

| Purchase     | Current Resource Unlock Cost | Proposed Coin Price | Target Purchase Day |
| ------------ | ---------------------------- | ------------------: | ------------------- |
| Sprinkler    | Tomato 30 + Wheat 20         |                 450 | Day 3               |
| Fisher       | Wood 25 + Fish 15            |                 650 | Day 4               |
| Scarecrow    | Pumpkin 15 + Corn 15         |                 900 | Day 5               |
| Cowboy Hat   | Wood 8 + Corn 6              |                 350 | Day 2               |
| Baseball Hat | Tomato 8 + Apple 6           |                 350 | Day 2               |
| Beanie       | Pumpkin 8 + Wheat 6          |                 350 | Day 2               |

Machines cost more than hats because machines change production capacity while hats are cosmetic. Sprinkler is earlier than Fisher because it supports the farming loop without introducing unlimited automated sellable output. Under this set, the player should not buy all machines before Day 5 in the Expected scenario unless starting inventory remains too high and sellable.

## Balanced Economy

Design intent: middle-speed progression, readable prices, and a first meaningful purchase around Day 2.

### A. Crop Sell Prices

| Crop    | Growth Days | Saleable Yield | Sell Price | Coin per Tile per Day |
| ------- | ----------: | -------------: | ---------: | --------------------: |
| Wheat   |           3 |              1 |         20 |                  6.67 |
| Corn    |           3 |              1 |         25 |                  8.33 |
| Tomato  |           4 |              1 |         40 |                 10.00 |
| Pumpkin |          12 |              1 |        150 |                 12.50 |

Check:

- Daily return order is Wheat < Corn < Tomato < Pumpkin.
- Values use simple 5s and 10s.
- Pumpkin has the best long-run return but does not produce first-five-day crop income.

### B. Generic Fish Sell Price

Generic Fish price: 25 coins.

| Scenario | Attempts | Success Rate | Expected Fish | Fish Price | Expected Fishing Income |
| -------- | -------: | -----------: | ------------: | ---------: | ----------------------: |
| Low      |        2 |          50% |           1.0 |         25 |                    25.0 |
| Expected |        5 |          70% |           3.5 |         25 |                    87.5 |
| High     |       10 |          85% |           8.5 |         25 |                   212.5 |

### C. Quest Reward

Recommended quest reward: 100 coins.

```text
Expected Daily Repeatable Income
= (Expected Five-Day Farming Income + Expected Five-Day Fishing Income) / 5
= (360 + 437.5) / 5
= 159.5

Quest Reward / Expected Daily Repeatable Income
= 100 / 159.5
= 0.63
```

This keeps the current quest reward while giving it a clear milestone role.

### D. Major Purchase Targets

| Purchase     | Current Resource Unlock Cost | Proposed Coin Price | Target Purchase Day |
| ------------ | ---------------------------- | ------------------: | ------------------- |
| Sprinkler    | Tomato 30 + Wheat 20         |                 400 | Day 2               |
| Fisher       | Wood 25 + Fish 15            |                 600 | Day 3               |
| Scarecrow    | Pumpkin 15 + Corn 15         |                1000 | Day 5               |
| Cowboy Hat   | Wood 8 + Corn 6              |                 360 | Day 2               |
| Baseball Hat | Tomato 8 + Apple 6           |                 360 | Day 2               |
| Beanie       | Pumpkin 8 + Wheat 6          |                 360 | Day 2               |

Machines cost more than hats because they affect production or defense. Sprinkler comes before Fisher because it supports crop planning and does not create direct sellable output. Fisher is intentionally delayed because automatic output currently has major economy blockers.

## Fast Progression Economy

Design intent: fast early rewards and more frequent purchases, with higher risk of exhausting content too quickly.

### A. Crop Sell Prices

| Crop    | Growth Days | Saleable Yield | Sell Price | Coin per Tile per Day |
| ------- | ----------: | -------------: | ---------: | --------------------: |
| Wheat   |           3 |              1 |         25 |                  8.33 |
| Corn    |           3 |              1 |         35 |                 11.67 |
| Tomato  |           4 |              1 |         55 |                 13.75 |
| Pumpkin |          12 |              1 |        220 |                 18.33 |

Check:

- Daily return order is Wheat < Corn < Tomato < Pumpkin.
- Pumpkin is highly attractive long-term, but it still has a 12-day delay.
- This set has the highest risk of making progression too fast once selling exists.

### B. Generic Fish Sell Price

Generic Fish price: 35 coins.

| Scenario | Attempts | Success Rate | Expected Fish | Fish Price | Expected Fishing Income |
| -------- | -------: | -----------: | ------------: | ---------: | ----------------------: |
| Low      |        2 |          50% |           1.0 |         35 |                    35.0 |
| Expected |        5 |          70% |           3.5 |         35 |                   122.5 |
| High     |       10 |          85% |           8.5 |         35 |                   297.5 |

### C. Quest Reward

Recommended quest reward: 150 coins.

```text
Expected Daily Repeatable Income
= (Expected Five-Day Farming Income + Expected Five-Day Fishing Income) / 5
= (485 + 612.5) / 5
= 219.5

Quest Reward / Expected Daily Repeatable Income
= 150 / 219.5
= 0.68
```

This reward feels larger but still does not equal multiple days of repeatable Expected income.

### D. Major Purchase Targets

| Purchase     | Current Resource Unlock Cost | Proposed Coin Price | Target Purchase Day |
| ------------ | ---------------------------- | ------------------: | ------------------- |
| Sprinkler    | Tomato 30 + Wheat 20         |                 450 | Day 2               |
| Fisher       | Wood 25 + Fish 15            |                 700 | Day 3               |
| Scarecrow    | Pumpkin 15 + Corn 15         |                 950 | Day 4               |
| Cowboy Hat   | Wood 8 + Corn 6              |                 300 | Day 1               |
| Baseball Hat | Tomato 8 + Apple 6           |                 300 | Day 1               |
| Beanie       | Pumpkin 8 + Wheat 6          |                 300 | Day 1               |

This set gives faster early cosmetic access. The tradeoff is a higher chance that the player can buy too much before Day 5, especially if current starting inventory remains sellable.

## 7. Starting Inventory Problem

Current starting inventory:

- 50 Tomato
- 50 Corn
- 50 Pumpkin
- 50 Wheat
- 50 Fish
- 50 Wood
- 50 Apple
- 250 Coins

If selling is implemented, this inventory becomes a large opening liquid asset.

```text
Starting Liquid Asset Value
= Tomato Price x 50
+ Corn Price x 50
+ Pumpkin Price x 50
+ Wheat Price x 50
+ Fish Price x 50
+ Starting Coins
```

| Candidate Set    | Starting Liquid Asset Value | Total Machine Coin Cost | Ratio |
| ---------------- | --------------------------: | ----------------------: | ----: |
| Conservative     |                      10,000 |                   2,000 |  5.00 |
| Balanced         |                      13,250 |                   2,000 |  6.63 |
| Fast Progression |                      18,750 |                   2,100 |  8.93 |

Judgment:

- The current 50-per-item inventory behaves like debug inventory.
- If these resources become sellable, the player can afford all major machine coin costs immediately.
- Day 3 should adjust starting inventory before sell prices are connected.

Suggested starting inventory candidates:

| Item    | Current | Conservative | Balanced | Fast Progression |
| ------- | ------: | -----------: | -------: | ---------------: |
| Tomato  |      50 |            1 |        2 |                3 |
| Corn    |      50 |            1 |        2 |                3 |
| Pumpkin |      50 |            0 |        1 |                2 |
| Wheat   |      50 |            6 |        8 |               10 |
| Fish    |      50 |            0 |        0 |                2 |
| Wood    |      50 |           10 |       15 |               20 |
| Apple   |      50 |            5 |        8 |               10 |
| Coin    |     250 |          100 |      150 |              200 |

Principles:

- The player can immediately perform basic planting.
- The player cannot buy all machines at the start.
- At least one crop remains available as a beginner planting path.
- Pumpkin starts low because it has the longest growth time.
- Starting inventory changes are numeric tuning, not a new gameplay system.

## 8. Scenario Income Calculation

First-five-day planting assumptions:

## Low Scenario: 8 tiles

- Wheat 4
- Corn 2
- Tomato 2
- Pumpkin 0

## Expected Scenario: 16 tiles

- Wheat 5
- Corn 4
- Tomato 4
- Pumpkin 3

## High Scenario: 28 tiles

- Wheat 7
- Corn 7
- Tomato 7
- Pumpkin 7

Calculation assumptions:

- All crops are planted on Day 1.
- Every planted crop is watered every day.
- The model uses code-aligned harvest timing: 3-day crops first pay on Day 4, 4-day crops first pay on Day 5.
- Harvested crops reserve 1 crop for replanting.
- Pumpkin does not mature within the first five days.
- Quest is completed on Day 3.
- Automatic Fisher income is excluded.
- Apple and Wood selling is excluded.
- Cumulative Coins starts from 250 starting coins.

## Conservative x Low

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |             20 |            0 |                 20 |              270 |
| Day 2 |              0 |             20 |            0 |                 20 |              290 |
| Day 3 |              0 |             20 |           80 |                100 |              390 |
| Day 4 |            100 |             20 |            0 |                120 |              510 |
| Day 5 |             60 |             20 |            0 |                 80 |              590 |

## Conservative x Expected

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |             70 |            0 |                 70 |              320 |
| Day 2 |              0 |             70 |            0 |                 70 |              390 |
| Day 3 |              0 |             70 |           80 |                150 |              540 |
| Day 4 |            155 |             70 |            0 |                225 |              765 |
| Day 5 |            120 |             70 |            0 |                190 |              955 |

## Conservative x High

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |            170 |            0 |                170 |              420 |
| Day 2 |              0 |            170 |            0 |                170 |              590 |
| Day 3 |              0 |            170 |           80 |                250 |              840 |
| Day 4 |            245 |            170 |            0 |                415 |            1,255 |
| Day 5 |            210 |            170 |            0 |                380 |            1,635 |

## Balanced x Low

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |           25.0 |            0 |               25.0 |            275.0 |
| Day 2 |              0 |           25.0 |            0 |               25.0 |            300.0 |
| Day 3 |              0 |           25.0 |          100 |              125.0 |            425.0 |
| Day 4 |            130 |           25.0 |            0 |              155.0 |            580.0 |
| Day 5 |             80 |           25.0 |            0 |              105.0 |            685.0 |

## Balanced x Expected

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |           87.5 |            0 |               87.5 |            337.5 |
| Day 2 |              0 |           87.5 |            0 |               87.5 |            425.0 |
| Day 3 |              0 |           87.5 |          100 |              187.5 |            612.5 |
| Day 4 |            200 |           87.5 |            0 |              287.5 |            900.0 |
| Day 5 |            160 |           87.5 |            0 |              247.5 |          1,147.5 |

## Balanced x High

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |          212.5 |            0 |              212.5 |            462.5 |
| Day 2 |              0 |          212.5 |            0 |              212.5 |            675.0 |
| Day 3 |              0 |          212.5 |          100 |              312.5 |            987.5 |
| Day 4 |            315 |          212.5 |            0 |              527.5 |          1,515.0 |
| Day 5 |            280 |          212.5 |            0 |              492.5 |          2,007.5 |

## Fast Progression x Low

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |           35.0 |            0 |               35.0 |            285.0 |
| Day 2 |              0 |           35.0 |            0 |               35.0 |            320.0 |
| Day 3 |              0 |           35.0 |          150 |              185.0 |            505.0 |
| Day 4 |            170 |           35.0 |            0 |              205.0 |            710.0 |
| Day 5 |            110 |           35.0 |            0 |              145.0 |            855.0 |

## Fast Progression x Expected

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |          122.5 |            0 |              122.5 |            372.5 |
| Day 2 |              0 |          122.5 |            0 |              122.5 |            495.0 |
| Day 3 |              0 |          122.5 |          150 |              272.5 |            767.5 |
| Day 4 |            265 |          122.5 |            0 |              387.5 |          1,155.0 |
| Day 5 |            220 |          122.5 |            0 |              342.5 |          1,497.5 |

## Fast Progression x High

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |          297.5 |            0 |              297.5 |            547.5 |
| Day 2 |              0 |          297.5 |            0 |              297.5 |            845.0 |
| Day 3 |              0 |          297.5 |          150 |              447.5 |          1,292.5 |
| Day 4 |            420 |          297.5 |            0 |              717.5 |          2,010.0 |
| Day 5 |            385 |          297.5 |            0 |              682.5 |          2,692.5 |

## 9. Income Share Check

## Conservative Expected Scenario

| Source  | Five-Day Income | Income Share |
| ------- | --------------: | -----------: |
| Farming |             275 |        39.0% |
| Fishing |             350 |        49.6% |
| Quest   |              80 |        11.3% |
| Total   |             705 |       100.0% |

Result: Pass. No repeatable activity exceeds 50%.

## Balanced Expected Scenario

| Source  | Five-Day Income | Income Share |
| ------- | --------------: | -----------: |
| Farming |           360.0 |        40.1% |
| Fishing |           437.5 |        48.7% |
| Quest   |           100.0 |        11.1% |
| Total   |           897.5 |       100.0% |

Result: Pass. Fishing is active and valuable but remains below 50%.

## Fast Progression Expected Scenario

| Source  | Five-Day Income | Income Share |
| ------- | --------------: | -----------: |
| Farming |           485.0 |        38.9% |
| Fishing |           612.5 |        49.1% |
| Quest   |           150.0 |        12.0% |
| Total   |         1,247.5 |       100.0% |

Result: Pass, but barely. Fishing is close to the 50% ceiling.

## 10. Purchase Timing Check

These checks use the Expected scenario and single-item saving behavior. Existing resource costs are still required. Current starting resource inventory is high enough to satisfy every current resource cost, which is a separate starting inventory problem.

## Conservative

| Purchase  | Suggested Price | Earliest Affordable Day | Intended Day | Result |
| --------- | --------------: | ----------------------: | -----------: | ------ |
| First Hat |             350 |                   Day 2 |        Day 2 | Pass |
| Sprinkler |             450 |                   Day 3 |        Day 3 | Pass |
| Fisher    |             650 |                   Day 4 |        Day 4 | Pass |
| Scarecrow |             900 |                   Day 5 |        Day 5 | Pass |

## Balanced

| Purchase  | Suggested Price | Earliest Affordable Day | Intended Day | Result |
| --------- | --------------: | ----------------------: | -----------: | ------ |
| First Hat |             360 |                   Day 2 |        Day 2 | Pass |
| Sprinkler |             400 |                   Day 2 |        Day 2 | Pass |
| Fisher    |             600 |                   Day 3 |        Day 3 | Pass |
| Scarecrow |           1,000 |                   Day 5 |        Day 5 | Pass |

## Fast Progression

| Purchase  | Suggested Price | Earliest Affordable Day | Intended Day | Result |
| --------- | --------------: | ----------------------: | -----------: | ------ |
| First Hat |             300 |                   Day 1 |        Day 1 | Fast but risky |
| Sprinkler |             450 |                   Day 2 |        Day 2 | Pass |
| Fisher    |             700 |                   Day 3 |        Day 3 | Pass |
| Scarecrow |             950 |                   Day 4 |        Day 4 | Fast |

Resource note: because current starting inventory contains 50 of every relevant item, the existing resource costs do not meaningfully delay any purchase. This is caused by high starting inventory, not by the coin model alone.

## 11. Machine Economy Blocker

The automatic Fisher cannot be safely included in the first-five-day economy model yet.

Reasons:

1. Fisher requires only one unlock payment.
2. After unlock, each machine can be placed for free.
3. There is no machine count limit.
4. Each Fisher produces 1 Fish every approximately 30.8 seconds.
5. There is no fuel, capacity or collection cost.
6. Multiple Fishers stack linearly.
7. Therefore theoretical production can expand without a reliable economy cap.

Formula:

```text
Fish per Minute
= Number of Fishers x (60 / 30.8)
```

Examples:

| Number of Fishers | Fish per Minute |
| ----------------: | --------------: |
|                 1 |            1.95 |
|                 5 |            9.74 |
|                10 |           19.48 |

Automatic Fisher income is excluded from this model.

Day 3 should choose at least one minimal fix:

- Machine placement consumes resources each time.
- Each machine type has a quantity cap.
- Purchase grants one machine instance rather than permanent unlimited placement.

This document records the design requirement only. It does not modify code.

## 12. Comparison of Candidate Sets

| Metric                             | Conservative | Balanced | Fast Progression |
| ---------------------------------- | -----------: | -------: | ---------------: |
| Expected Day 5 Cumulative Coins    |          955 |  1,147.5 |          1,497.5 |
| First Hat Affordable Day           |        Day 2 |    Day 2 |            Day 1 |
| Sprinkler Affordable Day           |        Day 3 |    Day 2 |            Day 2 |
| Fisher Affordable Day              |        Day 4 |    Day 3 |            Day 3 |
| Farming Income Share               |        39.0% |    40.1% |            38.9% |
| Fishing Income Share               |        49.6% |    48.7% |            49.1% |
| Quest Income Share                 |        11.3% |    11.1% |            12.0% |
| Starting Liquid Asset Risk         |         High |     High |             High |
| Risk of Buying Everything Too Soon |          Low |   Medium |             High |
| Interview Explainability           |         High |     High |           Medium |

## 13. Recommendation

```text
Recommended Candidate:
Balanced
```

Recommendation reasons:

1. It is neither the slowest nor the fastest model.
2. It creates a meaningful Day 2 purchase without making every major unlock immediately affordable.
3. Farming and fishing both matter in the Expected scenario.
4. Fishing remains below the 50% repeatable-income ceiling.
5. Crop prices are simple and easy to explain.
6. The current 100-coin quest reward can be retained as a milestone reward.
7. It leaves room for Day 4 playtest calibration.

Largest risk:

- The current starting inventory can completely break the model if those 50-count debug stacks become sellable.

Top Day 4 validation needs:

1. Real fishing success rate and average attempt duration.
2. Real crop tile count used by a normal player per day.
3. Real purchase timing after starting inventory is reduced.

Values most likely to need second-pass tuning:

- Generic Fish sell price.
- Scarecrow and Fisher coin prices.
- Starting crop and Fish inventory.
- Pumpkin sell price after longer play sessions include its first harvest.

Why Balanced is best for portfolio presentation:

- It shows clear economic reasoning without extreme tuning.
- It preserves tradeoffs between active fishing and stable farming.
- It explains the machine economy blocker honestly instead of hiding it.
- It uses simple numbers that can be defended in an interview.

## 14. Restrictions Followed

- No game code was modified.
- No runtime data values were modified.
- Day 1 documentation was not modified.
- Assumptions are clearly marked as design assumptions.
- No external game prices were copied.
- No new fish, seed, stamina or season systems were added.
- Automatic Fisher output is not included in the five-day economy model.
- The current 50-item starting inventory issue is explicitly included.
