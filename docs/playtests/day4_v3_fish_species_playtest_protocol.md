# Day 4 V3 Fish Species Playtest Protocol

## Goal

Validate the V3 fish species economy in real play:

```text
Manual Fishing -> four species
Automatic Fisher -> Gray/Silver only
Fisher Placement -> Wood 6 + Any Fish x3
Inventory -> species visible, Generic Fish hidden
Trade -> species buy/sell, Generic Fish unavailable
```

Use a fresh playtest log with:

```text
PLAYTEST_RUN_LABEL = V3_FISH_SPECIES
```

## Setup

Before testing, confirm:

- Game launches without errors.
- Inventory opens.
- Courier, Cat, and Mouse trade panels open and close.
- Fisher blueprint is available or can be unlocked for placement testing.
- Test player has enough coins and materials for trade and Fisher placement.

## Manual Fishing

Perform at least 20 successful manual catches.

Record:

| Catch # | Fish Received | Notes |
| ---: | --- | --- |
| 1 |  |  |
| 2 |  |  |
| 3 |  |  |
| 4 |  |  |
| 5 |  |  |
| 6 |  |  |
| 7 |  |  |
| 8 |  |  |
| 9 |  |  |
| 10 |  |  |
| 11 |  |  |
| 12 |  |  |
| 13 |  |  |
| 14 |  |  |
| 15 |  |  |
| 16 |  |  |
| 17 |  |  |
| 18 |  |  |
| 19 |  |  |
| 20 |  |  |

Check:

- Gray Carp and Silver Perch appear more often than rare fish.
- Golden Koi and Red Snapper feel meaningfully rarer.
- Generic Fish never appears as a new reward.
- Coins do not increase directly from catching fish.
- The minigame visual fish and final reward species mismatch does not feel too confusing.

## Trade

Open Courier Trade.

Check Buy tab:

- Gray Carp buy price: 16
- Silver Perch buy price: 24
- Golden Koi buy price: 38
- Red Snapper buy price: 65
- Generic Fish is not listed.
- Seeds, crops, Wood, and Apple are still listed.

Check Sell tab for Courier, Cat, and Mouse:

- Gray Carp sell price: 9
- Silver Perch sell price: 14
- Golden Koi sell price: 24
- Red Snapper sell price: 42
- Generic Fish is not listed.

For each fish species:

- Buy 1
- Sell 1
- Buy Max
- Sell All

Observe:

- Coin changes are correct.
- Owned counts refresh immediately.
- Buttons disable correctly when coins or inventory are insufficient.
- Focus does not disappear after a transaction.
- The list length and scrolling feel acceptable.

## Fisher Placement

Recipe shown should be:

```text
Wood owned/6
Any Fish owned/3
```

Test valid placement with:

```text
Wood 6
Gray Carp 2
Silver Perch 1
```

Expected:

```text
Fisher placed
Wood -6
Gray Carp -2
Silver Perch -1
```

Test mixed rare placement with:

```text
Wood 6
Gray Carp 1
Golden Koi 1
Red Snapper 1
```

Expected:

```text
Fisher placed
Gray Carp -1
Golden Koi -1
Red Snapper -1
```

Test rare protection with:

```text
Wood 6
Gray Carp 2
Silver Perch 2
Golden Koi 2
Red Snapper 2
```

Expected:

```text
Fisher placed
Gray Carp -2
Silver Perch -1
Golden Koi unchanged
Red Snapper unchanged
```

Invalid placement tests:

- Try placing Fisher with no adjacent water.
- Try placing Fisher on an occupied cell.
- Enter placement mode and cancel with right click.
- Enter placement mode and cancel with Escape.
- Enter placement mode and cancel with Xbox B.

Expected:

- No machine placed.
- No Wood deducted.
- No fish deducted.
- No telemetry placement event for failed/cancelled attempts.

## Automatic Fisher

Wait for at least 5 Fisher production cycles.

Record:

| Cycle # | Fish Produced | Notes |
| ---: | --- | --- |
| 1 |  |  |
| 2 |  |  |
| 3 |  |  |
| 4 |  |  |
| 5 |  |  |

Expected:

- Only Gray Carp or Silver Perch are produced.
- Golden Koi is never produced by Fisher.
- Red Snapper is never produced by Fisher.
- Generic Fish is never produced by Fisher.
- Coins do not increase directly.
- The production bar and animation still feel clear.

## Inventory

Set or reach a state with:

```text
Generic Fish > 0
Gray Carp > 0
Silver Perch > 0
Golden Koi > 0
Red Snapper > 0
```

Open Inventory.

Expected:

- Generic Fish row is absent.
- Four species rows are present.
- Quantities are correct.
- Red Snapper icon appears as the first sprite-sheet frame.
- No duplicate slots.
- Coin is not shown as a normal inventory row.

## Input Coverage

Repeat core flows with:

- Mouse
- Keyboard
- Xbox controller

Minimum checks:

- Inventory open/close.
- Trade tab switch.
- Trade buy/sell.
- Build Selector selection.
- Placement confirm.
- Placement cancel.

## Telemetry Check

After the run, inspect the V3 JSON log.

Confirm:

- `"run_label": "V3_FISH_SPECIES"`
- `fish_catches_by_species` increments only from catches.
- `fish_catch_events` include `manual` and `automatic_fisher`.
- `trade_buy_events` include species purchases.
- `sale_events` include species sales.
- No new `buy_fish`.
- No new `sale_fish`.
- Fisher placement event includes:

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

## Feedback Questions

Ask the tester:

- Are the four fish easy to distinguish?
- Does Red Snapper look too stylistically different?
- Are rare fish exciting enough when caught?
- Does manual fishing feel more meaningful than Automatic Fisher?
- Is `Any Fish x3` easy to understand?
- Does the Fisher consume the fish you expected it to consume?
- Is the Trade list too long?
- Is Generic Fish removal from Trade/Inventory confusing?
- Does the catch result need a dedicated popup?
- Is the minigame visual fish versus final reward mismatch confusing?

## Pass Criteria

V3 fish species playtest is ready to analyze when:

- Manual fishing produces only species.
- Automatic Fisher produces only Gray/Silver.
- Fisher placement accepts mixed species fish.
- Generic Fish is absent from active Inventory and Trade.
- Species buy/sell works.
- Telemetry records catch, buy, sale, and placement consumption correctly.
- No blocking UI or input issue appears.
