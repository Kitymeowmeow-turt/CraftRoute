# CraftRoute

**Version: v2.6.8**

A Turtle WoW addon that calculates the cheapest 1→300 leveling route for a
profession, using live Auction House prices scanned by **aux-addon**.

## Requirements
- **aux-addon** (https://github.com/shirsig/aux-addon-vanilla) is optional but
  recommended as a fallback price source for reagents you haven't scanned with
  CraftRoute's own scanner yet.

## Installation
1. Copy the `CraftRoute` folder into `Interface/AddOns/`
2. Make sure `CraftRoute` is enabled at the character-select AddOns screen.

## Usage

### 1. Scan reagents and recipes at the Auction House
Open the Auction House and click the new **CraftRoute** tab (added next to
Browse/Bid/Auctions). Each enabled profession gets its own row:

- **The profession name** (e.g. "Blacksmithing") -- scans every reagent it
  needs, one at a time, using the same throttled AH-query approach any
  scanning addon uses, then automatically continues into scanning that
  profession's recipe scrolls (Plans:/Pattern:/Schematic:/Formula:/Recipe:)
  -- no separate click needed. Recipe scrolls are scanned by *prefix*
  ("Plans:", "Formula:", etc.) rather than one query per scroll, since the
  Auction House's own search already returns every matching listing across
  however many pages it takes -- far fewer queries than scanning each scroll
  by exact name.
- **Two number boxes** next to each profession, defaulting to 1 and 300 --
  editable before clicking either the profession button or Create CraftRoute.
  Setting a higher starting skill (e.g. 250) also makes the *materials* scan
  skip reagents that are only needed by recipes already entirely grey at
  that skill, so a partial-range scan is genuinely faster, not just a
  narrower calculation. (This optimization doesn't extend to recipe
  scanning -- prefix-based scans page through every result for that prefix
  regardless of skill range, so filtering there wouldn't save any time.)
- **Create CraftRoute** button -- runs the calculation directly using
  whatever's in the two number boxes, without needing to type the slash
  command. Equivalent to `/craftroute <profession> <start box> <target box>`.
- **Scan All Professions** button -- runs the materials-then-recipes scan
  described above for every enabled profession in sequence, so you don't
  have to click through each one by hand.
- **Sell back extra crafts to AH if [X]% above vendor price** checkbox --
  when checked, also scans every craftable item's own market price (not
  just its reagents), so leftover crafted items can be recommended for AH
  sale instead of vendoring when it's worth enough more. The percentage
  threshold is editable and feeds directly into that recommendation, not
  just a display number. Leaving this unchecked is faster, since it skips
  scanning the crafted items themselves -- only their reagents.

A progress bar shows what's currently being scanned either way.

### 2. Calculate the route
```
/craftroute blacksmithing
```
(Or click **Create CraftRoute** on that profession's row in the AH tab, using
whatever's in its start/target boxes -- equivalent to typing the command
above by hand.)

Opens a report window with:
- An approximate cost (used internally to decide which recipe is cheapest at
  each skill point)
- The **true AH cost**: what you'd actually pay, buying the cheapest scanned
  listings first, up to the quantity each reagent needs
- A step-by-step list of which recipe to spam at which skill range, and how
  many times, grouped into 1-50 / 50-125 / 125-200 / 200-300 sections with a
  per-section subtotal
- A shopping list with real AH cost per reagent -- and a clear warning if the
  Auction House doesn't currently have enough of something scanned, so you
  know before you commit rather than finding out mid-grind

### Other commands
```
/craftroute list                          -- show which professions have data loaded
/craftroute <profession> <target>         -- calculate 1 up to a specific skill cap
/craftroute <profession> <start> <target> -- calculate between any two skill levels
                                             (e.g. already at 150, just want 150-300)
```

## How the math works
Recipes have four skill thresholds — orange / yellow / green / grey — from
Turtle WoW's actual in-game trade skill window (not vanilla defaults, since
Turtle changes some of these). At a given skill level, the chance of a
skill-up on a single craft is:
- **Orange** (skill < yellow): 100%
- **Yellow band**: `(grey - skill) / (grey - yellow)`
- **Green band**: `0.5 * (grey - skill) / (grey - green)`
- **Grey** (skill ≥ grey): 0%

Expected number of craft attempts to gain one skill point = `1 / chance`.
At every skill point from 1→300, CraftRoute picks whichever available recipe
minimizes `reagent cost / chance`, exactly the same greedy method used to
hand-build the original Enchanting guide earlier in this project.

**Note on cost accuracy:** the per-step and per-section dollar figures in the
step-by-step breakdown use a flat "cheapest current listing" price per
reagent -- this is what decides *which* recipe wins at each skill point, and
it's a reasonable approximation since the choice of recipe rarely changes
based on exact AH depletion at the margin. The **shopping list and final
total AH cost**, however, are fully depletion-aware: they sum the actual
cheapest scanned listings up to the real quantity needed for the whole route,
and flag any reagent where scanned supply falls short. That final number is
the one to trust for "what will this actually cost me."

## Data status (as of this build)

| Profession | Status |
|---|---|
| Enchanting | ✅ 55 recipes, fully verified |
| Alchemy | ✅ Fully verified. Went through a full reversal-check pass against real Auction House data; only 2 recipes needed resolution (Goblin Rocket Fuel, Ghost Dye), both confirmed and priced |
| Blacksmithing | ✅ Fully verified. Went through a full reversal-check pass; 53 recipes resolved (6 confirmed vendor-purchasable, 47 confirmed real and AH-tradeable but requiring a live scan before being used -- see "requiresScan" below). One item (Inlaid Mithril Cylinder) intentionally excluded as low-value; one item (Copper Chain Vest) had its original BoP assumption overturned by fresh review |
| Engineering | ✅ Fully verified. 42 recipes resolved via the same reversal-check process (20 vendor-purchasable, 22 requiresScan) |
| Leatherworking | ✅ Fully verified. 50 recipes resolved (12 vendor-purchasable, 38 requiresScan) |
| Tailoring | ✅ Fully verified. 59 recipes resolved (18 vendor-purchasable, 41 requiresScan) |
| Cooking | 🟡 84 recipes, reagent data complete, but still marked disabled in the UI (not yet confident enough in it to enable) |
| Jewelcrafting | 🟡 179 recipes total. 73 were flagged as possibly-purchasable via a database cross-check, but only 1 (Blackrock Ironclamps) has actually been confirmed against real market data -- the other 72 remain unscreened. Deliberately deferred rather than guessed at. Still marked disabled in the UI |

**What "requiresScan" means:** a recipe confirmed to be genuinely real and tradeable on the Auction House (not bind-on-pickup, not sold by any vendor), but with no fixed price to fall back on since one hasn't been found and prices can vary. These recipes are only usable by the route calculator once you've actually scanned their scroll price -- no guessed estimate is used, so the calculator can never recommend something that turns out to be unavailable.

## Adding a new profession
Add a `data_<profession>.lua` file following the same format as the existing
ones (see any `data_*.lua` for the exact shape), add it to `CraftRoute.toc`,
and it's automatically available via `/craftroute <profession>`. The one hard
requirement: every recipe needs its **orange/yellow/green/grey** thresholds
from actual in-game screenshots — there's no way around getting those, they
aren't in any reagent database.

## For developers
See `DEVNOTES.md` for implementation notes, game/algorithm background, the
test approach used during development, a codebase map, and known open items.
