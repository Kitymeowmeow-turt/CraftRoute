# CraftRoute

**Version: v2.9.2**

A Turtle WoW addon that calculates the cheapest 1→300 leveling route for a
profession, using live Auction House prices scanned by CraftRoute itself
(no other addon required — **aux-addon** is supported as an optional
fallback, not a dependency).

<!--
  Screenshot: the CraftRoute tab at the Auction House, mid-scan (progress
  bar visible, a couple of profession rows showing).
  ![CraftRoute scan window](./screenshots/scan-window.png)
-->

<!--
  Screenshot: a full generated report — the guide comparison, tools list,
  total cost line, and a chunk of the step-by-step breakdown.
  ![CraftRoute report window](./screenshots/report-window.png)
-->

---

## What it does

Point CraftRoute at a profession and a skill range, and it works out — from
real, currently-scanned Auction House prices, not static estimates — which
recipe to craft at every single skill point from 1 to 300, in what
quantity, to reach 300 as cheaply as possible. Not just "level with these
recipes in this order" — it re-derives the actual cheapest choice at every
point, accounting for:

- **Real reagent depletion.** The Auction House doesn't have infinite cheap
  stock — CraftRoute buys the cheapest listings first and prices the rest
  at what's actually left, not a flat average.
- **Make-vs-buy for craftable reagents.** If a reagent is itself craftable
  and that's cheaper than the AH price, CraftRoute recommends crafting it
  instead — recursively, and cross-profession where that's a real
  possibility (a small, explicit allowlist, not a blanket assumption).
- **Byproduct credit.** Every craft attempt produces the item regardless of
  whether it grants a skill-up. If a recipe you're already leveling with
  happens to produce more than the route strictly needs at that point, and
  something *later* in the route needs that same item, CraftRoute credits
  the surplus instead of pricing a second, separate purchase.
- **Extending a recipe's own range when it's genuinely cheaper.** If
  stretching a recipe a little further than its "natural" stopping point
  would cover a later reagent need for free (or close to it), CraftRoute
  checks whether that actually beats the alternative — a real, recomputed
  cost comparison, not a guess.
- **Sell-back.** Leftover crafted items (the inevitable surplus from
  probabilistic skill-ups) get priced for resale — vendor by default,
  Auction House too if you enable it and it's worth enough more — and
  credited against the total.
- **Guide comparison.** CraftRoute's own optimized route gets priced
  head-to-head against static community leveling guides, using the exact
  same real-cost math for both, and shows you whichever one is actually
  cheaper.

---

## Recent updates

*(Newest first — full history in [CHANGELOG.txt](./CHANGELOG.txt))*

- **v2.9** — New: custom insertions — a specific quantity of a specific
  recipe, forced into the route at a specific skill point, for items
  wanted for personal reasons rather than pure cost optimization.
- **v2.8** — Engineering's own tools (Arclight Spanner, Gyromatic
  Micro-Adjustor) now get inserted unconditionally at their earliest
  craftable point, like Enchanting's required rods always have — and
  after any mandatory item gets inserted, the full optimization cascade
  runs again to account for its own reagent needs.
- **v2.7.1** — Survival now uses its own report bands (1-75/75-150/
  150-225/225-300) instead of the standard split — its recipe
  thresholds cluster much more evenly across the full range.
- **v2.7** — New: a recipe that's never chosen as a route step, but is
  needed later as a reagent, no longer automatically wastes its own
  skill-up window — if there's a real opportunity earlier in the route,
  CraftRoute inserts it there instead of flat-crafting it for zero
  skill value.
- **v2.6.8** — Excluded Thorium Spurs from Blacksmithing.
- **v2.6.7** — "Scan All Professions" now does one combined, deduplicated
  scan across every profession instead of scanning each one separately —
  faster, and nothing gets scanned twice just because two professions
  share a reagent.
- **v2.6.4 – v2.6.6** — Fixed a real discrepancy between the report's
  "Total AH cost" and its own guide-comparison total for the same route —
  three separate contributing bugs found and fixed in turn (a
  band-splitting rounding issue, a byproduct-credit scope issue, and a
  missing training-cost addition).
- **v2.6** — New: "trimming" pass. A recipe that gets extra crafts tacked
  on to cover a later reagent need was always priced as if those extra
  crafts had zero skill-up value — only true if the recipe had genuinely
  hit its own skill cap already. If it hadn't, that skill was real and
  free; this pass collects it and shrinks whatever comes next in the
  route accordingly.
- **v2.5.2** — Skinning Knife (Survival) confirmed as a vendor-buyable
  reagent.
- **v2.5** — New: Survival is enabled! All 9 professions now available.
- **v2.4.6** — Sell-back re-enabled, now backed by a real, user-verified
  vendor sell-price table (856 items) instead of an unreliable live
  lookup.
- **v2.4** — New: reports now show a separate shopping list for each skill
  band, placed right above that band's step-by-step section, instead of
  one combined list at the very end.
- **v2.3** — New: Jewelcrafting is enabled.
- **v2.2** — New: Cooking is enabled.

---

## Requirements

- **aux-addon** ([github.com/shirsig/aux-addon-vanilla](https://github.com/shirsig/aux-addon-vanilla))
  is optional. CraftRoute has its own independent Auction House scanner and
  doesn't need aux-addon to function — it's only used as a name→item-ID
  lookup for a small number of internal, non-pricing purposes.

## Installation

1. Copy the `CraftRoute` folder into `Interface/AddOns/`
2. Make sure `CraftRoute` is enabled at the character-select AddOns screen.

## Usage

### 1. Scan reagents and recipes at the Auction House

Open the Auction House and click the new **CraftRoute** tab (added next to
Browse/Bid/Auctions). Each of the 9 professions gets its own row:

- **The profession name** (e.g. "Blacksmithing") — scans every reagent it
  needs, one at a time, then automatically continues into scanning that
  profession's own recipe scrolls (Plans:/Pattern:/Schematic:/Formula:/
  Recipe:/Outline:) by prefix — no separate click needed.
- **Two number boxes** next to each profession, defaulting to 1 and 300 —
  editable before clicking either the profession button or Create
  CraftRoute. Setting a higher starting skill also makes the materials
  scan skip reagents that are only needed by recipes already entirely
  grey at that skill, so a partial-range scan is genuinely faster.
- **Create CraftRoute** button — runs the calculation directly using
  whatever's in the two number boxes. Equivalent to
  `/craftroute <profession> <start box> <target box>`.
- **Scan All Professions** button — one combined, deduplicated scan
  across every enabled profession (materials first, then recipe scrolls),
  instead of clicking through each profession by hand.
- **Sell extra crafts back to AH if [X]% above vendor price** checkbox —
  unchecked, leftover crafted items are priced at their vendor sell value
  only. Checked, CraftRoute also scans each craftable item's own market
  price, and recommends AH sale instead of vendoring whenever it's worth
  enough more (the percentage threshold is editable).

A progress bar shows what's currently being scanned either way.

### 2. Calculate the route

```
/craftroute blacksmithing
```

(Or click **Create CraftRoute** on that profession's row in the AH tab.)

Opens a report window with:

- A **guide comparison** — CraftRoute's own optimized route priced
  head-to-head against any static community guides available for that
  profession, showing whichever is actually cheaper
- The **tools you'll need** — one-time, not consumed, with real vendor/AH
  sourcing info
- The **true AH cost** — what you'd actually pay, buying the cheapest
  scanned listings first, up to the real quantity each reagent needs
- A **step-by-step list** of which recipe to craft at which skill range
  and how many times, grouped into 1-50 / 50-125 / 125-200 / 200-300
  sections, each with its own shopping list directly above it
- **Sell-back credit** for leftover crafted items, and a final net total
- A clear warning if the Auction House doesn't currently have enough of
  something scanned, so you know before you commit rather than finding
  out mid-grind

### Other commands

```
/craftroute list                          -- show which professions have data loaded
/craftroute <profession> <target>         -- calculate 1 up to a specific skill cap
/craftroute <profession> <start> <target> -- calculate between any two skill levels
                                             (e.g. already at 150, just want 150-300)
```

---

## How the math works

Recipes have four skill thresholds — orange / yellow / green / grey —
sourced from Turtle WoW's own in-game data, not vanilla defaults. At a
given skill level, the chance of a skill-up on a single craft is:

- **Orange** (skill < yellow): 100%
- **Yellow band**: `(grey - skill) / (grey - yellow)`
- **Green band**: `0.5 * (grey - skill) / (grey - green)`
- **Grey** (skill ≥ grey): 0%

Expected number of craft attempts to gain one skill point = `1 / chance`.
At every skill point from 1→300, CraftRoute's main pass picks whichever
available recipe minimizes `reagent cost / chance` — then several
additional passes look for ways to do better than that greedy choice alone
would find: extending a recipe's own range to cover a later need for free,
catching reagent shortfalls that fall past a recipe's own skill cap, and
recovering real skill-up value that would otherwise get priced as zero.

**Note on cost accuracy:** the per-step dollar figures in the step-by-step
breakdown use a flat "cheapest current listing" price per reagent — this is
what decides *which* recipe wins at each skill point, and it's a reasonable
approximation since the choice of recipe rarely changes based on exact AH
depletion at the margin. The **shopping lists and final total AH cost**,
however, are fully depletion-aware: they sum the actual cheapest scanned
listings up to the real quantity needed for the whole route (with AH
depletion and byproduct credit both carried continuously across every skill
band, not reset at each section), and flag any reagent where scanned supply
falls short. That final number is the one to trust for "what will this
actually cost me."

---

## Data status (as of this build)

All 9 professions are enabled. Recipe counts below exclude anything marked
`excluded=true` (cost outliers, unresolvable data, or specifically flagged
as not worth recommending) — those recipes still exist in the data as
reagent sources, they're just never chosen as a route step.

| Profession | Recipes | Trainer-taught | AH/vendor scroll | Quest/boss |
|---|---:|---:|---:|---:|
| Alchemy | 89 | 55 | 34 | — |
| Blacksmithing | 169 | 94 | 69 | 6 |
| Cooking | 51 | 9 | 42 | — |
| Enchanting | 55 | 39 | 16 | — |
| Engineering | 121 | 64 | 57 | — |
| Jewelcrafting | 164 | 80 | 72 | 12 |
| Leatherworking | 109 | 54 | 55 | — |
| Survival | 83 | 80 | 1 | 2 |
| Tailoring | 150 | 90 | 60 | — |

Vendor pricing: **170** confirmed buy prices, **856** confirmed sell-back
prices, all directly verified rather than estimated.

## Adding a new profession

Add a `data_<profession>.lua` file following the same format as the
existing ones (see any `data_*.lua` for the exact shape), add it to
`CraftRoute.toc`, and it's automatically available via
`/craftroute <profession>`. The one hard requirement: every recipe needs
its **orange/yellow/green/grey** thresholds from actual in-game data —
there's no way around getting those, they aren't in any reagent database.

## For developers

See `DEVNOTES.md` for implementation notes, algorithm background, and a
detailed history of what's been found and fixed along the way, and
`CODEMAP.md` for a function-level map of the codebase.
