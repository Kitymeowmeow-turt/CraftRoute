# CraftRoute v2.13.0
Addon for OctoWow

CraftRoute is a OctoWow addon that calculates the cheapest possible route to level any of the game's 9 crafting professions (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Jewelcrafting, Leatherworking, Survival, Tailoring) from any level to any other level, using real, live Auction House prices rather than guesses.

The core problem it solves: leveling a profession efficiently means knowing, at every single skill point, which recipe is actually cheapest to craft right now — not which one a guide from years ago said was cheapest, and not which one looks cheap until you learn that its 3rd ingredient is 250% over the typical price. CraftRoute answers that by scanning the AH itself, storing every single relevant post for the profession in question, and calculating from scratch.

It covers all 9 professions (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Jewelcrafting, Leatherworking, Survival, Tailoring), with every recipe's thresholds, reagents, and learn-source individually verified from the OctoWow database rather than assumed — and 856 vendor sell prices and 170 vendor buy prices confirmed the same way, not estimated.

I haven't seen CraftRoute lose to Wow-professions in over a week, only leaving it in for now to re-assure players that this is better **BUT** I know it is possible for CraftRoute to lose when there are low amounts of materials. (example: If there are no iron and thorium bars on the auction house then Wow-professions will look cheap, but be 100% impossible.)

Scan data from 5/8/2026

Alchemy: **CraftRoute 28.4g** Wow-professions 58.4g

Blacksmithing: **CraftRoute 144g** Wow-professions 177g

Cooking: **2.2g**

Enchanting: **CraftRoute 138.1g** Wow-professions 370g (Arcanite rod)

Engineering: **CraftRoute 41.5g** Wow-professions 71.5g

Jewelcrafting: **175.6g**

Leatherworking: **CraftRoute 125.1g** Wow-professions 156.2g

Survival: **56.3g**

Tailoring: **CraftRoute 85.5g** Wow-professions 209.5g


## Use

I'd like to show you in game screenshots, but I'm wary of game assets, so I'm going to describe using it and provide a copy and pasted report.

Using CraftRoutes for non-gnomes is simple, you go to the auction house, scan by hitting the button with the name of the profession, hit the create route button. The **copy and pastable report** (Ctrl+A Ctrl+C) you receive has a cost breakdown with comparison to the total cost breakdown of the static guide website many use, wow-professions. Below is the text you would see in game when you generate a report without selling to auction house checkbox enabled.

```
Alchemy -- cheapest 1 to 300 route  [CraftRoute (optimized)]

Guide comparisons (each priced with real AH data, buying lowest first):
  CraftRoute (optimized): 21g 90s 59c  <- cheapest, shown below
  Wow-Professions.com: 50g 52s 70c

Total AH cost (actual scanned listings, cheapest first): 21g 90s 59c
  includes one-time recipe/training costs: 6g 20s 44c
  Returned money after selling crafts back to vendor: -5g 45s 31c
Total cost after vendoring: 16g 45s 28c
  Note: Trainer training costs above are rough guesses at the threshholds 1-100, 100-200, and 200-300.

-- Step-by-step --

1-50 Shopping list
  49x Empty Vial  (0g 1s 96c -- 0 from AH, 49 from vendor)
  41x Peacebloom  (0g 7s 22c)
  57x Silverleaf  (0g 12s 27c)

[1-50]
  [1-9] Elixir of Minor Defense  x8  (0g 4s 27c) +0g 2s 0c~ Trainer
  [9-50] Minor Healing Potion  x41  (0g 21s 57c) +0g 2s 0c~ Trainer

50-125 Shopping list
  21x Bruiseweed  (0g 9s 66c)
  78x Earthroot  (0g 21s 76c)
  91x Empty Vial  (0g 3s 64c -- 0 from AH, 91 from vendor)
  20x Mageroyal  (0g 3s 87c)
  50x Peacebloom  (0g 13s 11c)
  31x Silverleaf  (0g 9s 17c)
  21x Swiftthistle  (0g 30s 59c)

[50-125]
  [50-60] Minor Healing Potion  x11  (0g 5s 26c) Trainer
  [60-77] Minor Mana Potion  x20  (0g 12s 1c) +0g 2s 0c~ Trainer
  [77-104] Elixir of Minor Fortitude  x39  (0g 35s 75c) +0g 2s 0c~ Trainer
  [104-125] Holy Protection Potion  x21  (0g 45s 24c) +0g 5s 0c~ Trainer

125-200 Shopping list
  30x Bruiseweed  (0g 13s 80c)
  37x Earthroot  (0g 10s 80c)
  27x Empty Vial  (0g 1s 8c -- 0 from AH, 27 from vendor)
  26x Firefin Snapper  (0g 26s 0c)
  37x Kingsblood  (0g 41s 98c)
  53x Leaded Vial  (0g 21s 20c -- 0 from AH, 53 from vendor)
  16x Liferoot  (0g 23s 19c)
  14x Swiftthistle  (0g 20s 54c)

[125-200]
  [125-138] Holy Protection Potion  x14  (0g 28s 0c) Trainer
  [138-151] Fire Oil  x13  (0g 31s 52c) +0g 5s 0c~ Trainer
  [151-186] Elixir of Ogre's Strength  x37  (0g 71s 91c) +0g 4s 97c Recipe
  [186-200] Mighty Troll's Blood Potion  x16  (0g 39s 65c) +0g 5s 0c~ Trainer

200-300 Shopping list
  64x Arthas' Tears  (1g 70s 24c)
  20x Bruiseweed  (0g 9s 38c)
  87x Crystal Vial  (4g 35s 0c -- 0 from AH, 87 from vendor)
  13x Dreamfoil  (1g 66s 44c)
  10x Elemental Water  (0g 46s 78c)
  46x Fadeleaf  (0g 61s 6c)
  9x Goldthorn  (0g 15s 96c)
  10x Icecap  (0g 54s 87c)
  37x Khadgar's Whisker  (0g 58s 86c)
  66x Leaded Vial  (0g 26s 40c -- 0 from AH, 66 from vendor)
  20x Liferoot  (0g 29s 0c)
  26x Plaguebloom  (2g 24s 32c)

[200-300]
  [200-217] Mighty Troll's Blood Potion  x20  (0g 48s 15c) Trainer
  [217-240] Elixir of Detect Lesser Invisibility  x37  (1g 31s 77c) +0g 11s 48c Recipe
  [240-244] Catseye Elixir  x9  (0g 57s 36c) +0g 27s 0c~ Trainer
  [244-277] Elixir of Detect Undead  x64  (5g 12s 85c) +0g 27s 0c~ Trainer
  [277-290] Mageblood Potion  x13  (4g 82s 76c) +0g 27s 0c~ Trainer
  [290-300] Greater Frost Protection Potion  x10  (6g 51s 64c) +4g 99s 99c Recipe

-- Sell off leftover crafted items --
  9x catseye elixir  -> sell to vendor  (0g 1s 50c each, 0g 13s 50c total)
  37x elixir of detect lesser invisibility  -> sell to vendor  (0g 1s 50c each, 0g 55s 50c total)
  64x elixir of detect undead  -> sell to vendor  (0g 3s 0c each, 1g 92s 0c total)
  8x elixir of minor defense  -> sell to vendor  (0g 0s 5c each, 0g 0s 40c total)
  39x elixir of minor fortitude  -> sell to vendor  (0g 0s 15c each, 0g 5s 85c total)
  37x elixir of ogre's strength  -> sell to vendor  (0g 0s 20c each, 0g 7s 40c total)
  13x fire oil  -> sell to vendor  (0g 0s 12c each, 0g 1s 56c total)
  10x greater frost protection potion  -> sell to vendor  (0g 7s 50c each, 0g 75s 0c total)
  35x holy protection potion  -> sell to vendor  (0g 0s 62c each, 0g 21s 70c total)
  13x mageblood potion  -> sell to vendor  (0g 10s 0c each, 1g 30s 0c total)
  36x mighty troll's blood potion  -> sell to vendor  (0g 1s 5c each, 0g 37s 80c total)
  52x minor healing potion  -> sell to vendor  (0g 0s 5c each, 0g 2s 60c total)
  20x minor mana potion  -> sell to vendor  (0g 0s 10c each, 0g 2s 0c total)
...
```
## Version History


v2.13.1
-------
Fix: Orange/Yellow-only mode (v2.13.0) was silently wasting real skill-up
value on any recipe with downstream reagent demand -- e.g. Tailoring's
Bolt of Linen Cloth would stop being used as a route step partway through
its own yellow band (a plain greedy switch to a cheaper-per-point recipe),
and the rest of the route's real demand for it fell through entirely to a
flat, zero-skill-credit "Also craft along the way" line instead of a real,
credited route step. Root cause: this mode disabled the ENTIRE extend/
insert/produce/trim cascade, the same treatment Orange-only mode uses --
but Orange-only's reasoning (any extension at all risks reaching past its
100%-guaranteed orange window) doesn't apply here, since extending within
yellow is exactly what this mode is supposed to allow. Fix: the cascade
now runs for this mode too, with every extension/insertion capped at each
recipe's own green instead of grey, so a real credited extension can still
happen anywhere within orange+yellow, while never producing a route step
that reaches into green. Orange-only mode's own handling (full cascade
skip) is unchanged.


v2.13.0
-------
Feature: added an "Orange/Yellow leveling recipes only (no green crafts)"
checkbox to the Auction House panel, above the existing "Orange leveling
recipes only" checkbox. Same idea, one band wider: the optimized leveling
path only selects a recipe while the current skill is inside that
recipe's orange or yellow window ([orange, green)) -- green crafts (and
the low-odds grey ones) are skipped entirely, but yellow's real, decaying
skill-up chance is used as-is, not inflated to look like a guarantee.
The two checkboxes are mutually exclusive (checking one unchecks the
other) since orange-only is already a subset of this wider mode. Reuses
the same guardrails the orange-only mode already had: the extension
cascade and optional custom insertions are disabled (both can stretch a
recipe into green), the guide comparison is hidden (guides freely use
green), and the report shows the same "vs normal optimized" cost
comparison, reworded for whichever strict mode is active. Setting is
saved in CraftRoute_Settings and defaults to off.


v2.12.3
-------
Guardian Gloves (Leatherworking) thresholds corrected to
orange=190/yellow=210/green=220/grey=230 (were orange=185/yellow=205/
green=215/grey=225 -- a uniform off-by-5 against every threshold).
Now matches its two neighboring recipes, Barbaric Harness and Gloves
of the Greatfather, both already 190/210/220/230. User-confirmed.


v2.12.2
-------
Fine Leather Gloves (Leatherworking) thresholds corrected to
orange=75/yellow=105/green=120/grey=135 (were orange=1/yellow=40/
green=55/grey=70, matching two unrelated neighboring recipes -- a
copy-paste error, not a real outlier). User-confirmed.


v2.12.1
-------
Performance: Auction House scanning no longer waits a fixed 0.6 seconds
after every item/page when the current result is already fully resolved.
The scanner now advances immediately once every auction row on the current
page has a usable item name. This only ever fires early when something
outside CraftRoute has already cleared the client's own browse-query
throttle before the update event arrives -- CanSendAuctionQuery() reports
the real client state either way, so a stock client scans exactly as
before. The previous 0.6-second quiet-period remains as a fallback for
vanilla item-cache rows that are still unresolved, preserving the old
behavior instead of risking missing listings or hanging a scan.


v2.12.0
-------
Feature: added an "Orange leveling recipes only" checkbox to the Auction
House panel. When enabled, the optimized leveling path only selects a
recipe while the current skill is inside that recipe's guaranteed orange
window ([orange, yellow)) -- the downstream passes that intentionally
stretch leveling crafts into yellow/green to save money (extension
cascade, optional stockpiling insertions) are disabled in this mode, since
that would violate the guaranteed-skillup promise. Mandatory profession
tools are still always included. When this mode stops a route at a skill
gap (no recipe has an orange window there), the report also shows what the
same reachable range would cost under CraftRoute's normal chance-aware
optimizer, so the real gold cost of insisting on guaranteed skill-ups is
visible rather than implied. The setting is saved in CraftRoute_Settings
and defaults to off, preserving the existing behavior for everyone who
doesn't touch it.

v2.11.8
-------
Fix: two reagents had wrong itemIds in the data. Swift Boots
(leatherworking) referenced itemId 2359 instead of 2459 (Swiftness
Potion); Crimson Silk Shoulders (tailoring) referenced 6271 instead of
6371 (Fire Oil). Both now use the correct item directly by name.


v2.11.7
-------
Removed the aux-addon dependency completely -- down to zero, not just
narrowed. The one remaining touch point (a name->itemId lookup into
aux's own cache) is gone entirely; a reagent with no itemId in its own
data just has no itemId now, no external lookup attempted. Prompted by
a real incident: aux silently handed the addon a wrong item for a real
reagent name (Aquamarine). Also dropped the OptionalDeps line from the
.toc, since there's no reason to care about aux's load order anymore.


v2.11.6
-------
Removed the "Missing AH price data for..." section from the displayed
report -- players were reading it as a bug rather than the normal,
expected note it actually was. The underlying tracking is untouched;
this only changes what gets printed. Route selection and cost were
never affected by whether this got displayed.


v2.11.5
-------
Confirmed vendor prices for 5 of the 36 recipes fixed in v2.11.4 --
these are actually reliably vendor-purchasable, not AH-only:
Pattern: Enchanted Runecloth Bag (2g), Pattern: Heavy Scorpid Helm
(2g50s), Pattern: Runic Leather Headband (2g20s), Pattern: Nightscape
Shoulders (40s), Schematic: Snake Burst Firework (50s). Their
requiresScan gate is removed accordingly -- the vendor price already
takes priority over that check, so it was no longer doing anything for
these five. The other 31 recipes from v2.11.4 are unchanged, still
correctly gated until scanned.


v2.11.4
-------
Fix: 36 recipes across Blacksmithing (8), Engineering (18),
Leatherworking (7), and Tailoring (3) could get chosen as route steps
while genuinely unscanned and unavailable, because they were missing a
flag needed to correctly block that -- an unscanned recipe meant to say
"don't guess" was silently defaulting to "free" instead. Found from a
report of Blue Rocket Cluster being routed despite not existing
anywhere in the reporter's scan data. Added the missing flag to all 36;
full list in DEVNOTES.


v2.11.3
-------
Fix: Ez-Thro Dynamite II was incorrectly marked trainer-taught with a
rough estimated cost. It's actually scroll-taught (Schematic: EZ-Thro
Dynamite II) -- now priced from its scanned scroll cost like the base
Ez-Thro Dynamite already was, rather than guessed.


v2.11.2
-------
Engineering custom insertions: Solid Dynamite and Big Iron Bomb reduced
from 20 to 10 each.

v2.11.1
-------
Fix: a mandatory item (Enchanting's rods, Engineering's Arclight Spanner/
Gyromatic Micro-Adjustor) could get silently removed from the route by
the optimization pass that runs right after it's inserted -- that pass
has no way to know the item is required, and could extend a different
recipe back over its slot if that looked cheaper. Found from a real
report of Arclight Spanner missing entirely from an Engineering route.
Fixed by re-checking after that pass and re-inserting anything it
removed.

v2.11
-----
Fix: the guide comparison no longer auto-switches to whichever total
looks lower. A static guide isn't checked against what's actually
available to buy the way CraftRoute's own route is, so a lower guide
total could mean an unachievable route rather than a genuinely cheaper
one -- especially under a real reagent shortage. CraftRoute's own route
is always the one shown now; every candidate's total is still compared
and displayed, with a note explaining why a lower guide total isn't
automatically trustworthy.

v2.10
-----
New: no more invisible crafts. A recipe needed as a reagent could
previously get its shortfall covered silently -- crafted from raw
materials as part of a DIFFERENT recipe's cost, with no route step of
its own, even when the exact same craft was available to show visibly
at the exact same cost. The three extension/insertion passes now treat
a real cost tie as a win for the visible option, so these get pulled
onto their own step instead of staying hidden. Also fixed a real,
previously-latent bug this exposed: trimming credited free skill by
shrinking whatever came after an extension, but never extended the
original step's own range to match, which could leave a real gap in
the route. Added a safety net too -- if anything still resolves
invisibly despite the fix, it now gets printed as its own "Also craft
along the way" section rather than staying hidden.


v2.9.2
------
Survival custom insertions updated: Nutritious Rations reduced to 5
units (still @210), and a new one added -- Vine Cutter x2@215. Checked
first: Vine Cutter's real orange is exactly 215, and Nutritious
Rations at the new quantity lands at exactly 215 too, so the full
chain (Savory Fishing Lure -> Nutritious Rations -> Vine Cutter) lines
up with no gap or overlap.


v2.9.1
------
Fix: Nutritious Rations custom insertion moved back to skill 210, as
originally requested -- it had been changed to 205 (matching its own
recipe threshold) without realizing 210 was deliberate: Savory Fishing
Lure's own insertion (10 units from 200) already lands at 210 itself,
so 205 would have landed inside that range instead of after it. 210
was correct from the start.


v2.9
----
New: custom insertions -- a specific quantity of a specific recipe,
forced into the route starting at a specific skill point, for items
the player wants for their own reasons (stockpiling, personal use)
rather than anything the cost optimizer should second-guess. Distinct
from mandatory-crafts (always exactly 1 unit at the recipe's own
orange) -- this is user-specified quantity and starting point, still
gets real chance-aware skill-up credit for whatever portion actually
falls within the recipe's window. First entries: Engineering (Explosive
Sheep x5@150, Solid Dynamite x20@175, Big Iron Bomb x20@190) and
Survival (Savory Fishing Lure x10@200, Nutritious Rations x15@205).
Feeds into the same optimization cascade re-run as mandatory-crafts, so
an inserted item's own reagent needs get accounted for too.


v2.8
----
New: mandatory-crafts insertion (previously Enchanting-only, for its
required rods) now covers Engineering's own tools too (Arclight
Spanner, Gyromatic Micro-Adjustor) -- unconditionally inserted at their
own orange threshold like the rods always were, instead of the old
conditional "only if cheaper" check. And new for every profession this
applies to: after a mandatory item gets inserted, the full extend/
insert/produce/trim optimization cascade runs again, so the item's own
reagent needs get the same treatment as everything else in the route
instead of sitting there unoptimized. Removed the old conditional tool-
acquisition mechanism entirely, since nothing was left to use it once
Engineering moved to the unconditional one.


v2.7.1
------
Survival now uses its own report bands (1-75/75-150/150-225/225-300)
instead of the standard 1-50/50-125/125-200/200-300 split -- its recipe
thresholds land much more evenly across the full skill range than the
other professions', so the default split didn't group its steps well.
Display-only, doesn't affect route calculation or cost for any
profession.


v2.7
----
New: a recipe that's never chosen as a route step at all, but is needed
later as a reagent, used to always get flat-crafted at zero skill-up
value -- even when its own orange-grey window was sitting completely
open and unused somewhere earlier in the route. ApplyRecipeInsertion now
checks for that, and inserts a dedicated run at the earliest real
opportunity instead, absorbing whatever it displaces the same way an
extension does, only keeping the change if a real, whole-route cost
comparison says it's actually cheaper. Found from a real leveling report
(Sturdy Net crafted with zero skill gained) and built out over an
extended design conversation before any code was written. Not yet
verified against a live route.


v2.6.8
------
Excluded Thorium Spurs from Blacksmithing.


v2.6.7
------
"Scan All Professions" reworked instead of continuing to chase the old
loop symptom directly: replaced the previous 18-job chain (9 professions
x materials/recipes each) with just 2 combined, deduplicated scans --
every reachable material across every enabled profession once, then
every recipe-scroll prefix the same way. Faster (no re-scanning a
material shared by multiple professions once per profession) and
substantially shrinks whatever surface area existed for the earlier
unconfirmed reentrancy symptom, on top of directly matching how it was
asked to work.


v2.6.6
------
Fix (real cause, part 3): "Total AH cost" never actually had training
costs added to it, despite the "includes one-time recipe/training
costs" line directly below it claiming otherwise -- that line was never
true, just not visible until the previous two fixes stopped masking it
with unrelated inflation. Training is now added into the total exactly
once, correctly. "Total AH cost" and "CraftRoute (optimized)" should
now match exactly for the same route.


v2.6.5
------
Fix (real cause, part 2 -- v2.6.4's rounding fix was real but only a
minor contributor): "Total AH cost" priced band-by-band couldn't credit
a byproduct surplus from an earlier band against a reagent need in a
later one, since each band's shopping-list calculation only saw its own
steps. The whole-route guide-comparison total doesn't have this
limitation, which is why it always came out cheaper for the same route.
Byproduct credit now threads across bands the same way AH depletion
already did, closing the gap.


v2.6.4
------
Fix: "Total AH cost" could come out higher than the "CraftRoute
(optimized)" guide-comparison total for the same route. Root cause: a
recipe spanning a band boundary got split into fragments for the
step-by-step display, and each fragment's craft count was rounded up
independently -- which can only ever need as many or more total
reagents than rounding the whole, unsplit recipe up once, never fewer.
Fixed by allocating whole crafts across a step's fragments up front
instead, guaranteeing they sum to the same total a whole-route
calculation would use.


v2.6.3
------
Excluded two more Alchemy recipes: Gold Bar and Truesilver Bar. Both are
functionally the same as Transmute: Iron to Gold / Transmute: Mithril to
Truesilver (already excluded), just stored under bare names instead of
the "Transmute:" prefix, so the earlier exclusion pass missed them.


v2.6.2
------
The "Total cost after vendoring"/"Total cost after vendor/AH" line is
now colored (FA0C0C, red) to stand out as the final real number in the
report.


v2.6.1
------
Renamed the final report total line to "Total cost after vendoring"
(sell-back checkbox unchecked) or "Total cost after vendor/AH"
(checked), matching the same checkbox-dependent wording already used
for the line above it.


v2.6
----
New: "trimming" -- ApplyPureProductionExtensions always priced its
extra flat-added crafts as zero-skill, even when the recipe hadn't
actually reached its own grey yet, meaning real skill-up chance from
those crafts was being ignored entirely. ApplyTrimming now collects
that unconditionally-free skill (crafting those units was already
locked in regardless of cost) and shrinks or removes whatever step(s)
immediately follow to the extent that ground is already covered.
Cascades: trimming a step can create a new shortfall elsewhere, so the
extend/produce/trim sequence loops until a full cycle changes nothing.
Verified with isolated, hand-checked math against the exact scenario
this was designed around, both single-step and multi-step cascade
cases. Not yet tested against a live route with real fresh data.


v2.5.2
------
Skinning Knife confirmed at 82c, added to the vendor-preferred materials
list.


v2.5.1
------
Added 8 newly-confirmed vendor-buyable Survival reagents to the vendor-
preferred materials list (Junglevine Wine, Mining Pick, Molasses
Firewater, Remedy Herbs, Rugged String, Salt, Soothing Spices, Springy
Rope) -- always bought from vendor now, no longer AH-scanned or
AH-compared. 12 others in the same review round were already confirmed
from earlier profession work and matched exactly, no changes needed.


v2.5
----
New: Survival is enabled! All 9 professions now available. Real recipe
data (89 recipes) and a full learn-source review are both complete, no
known open data gaps -- same bar Cooking and Jewelcrafting met before
their own enables.


v2.4.14
-------
Survival's scroll-name prefix confirmed ("Outline:") and applied to
Jungle Remedy, its one AH-only recipe. All 89 Survival recipes now have
a confirmed learn-source. Still not enabled.


v2.4.13
-------
Survival learn-source review: 80 confirmed trainer-taught, 2 confirmed
quest rewards, 6 confirmed excluded. One recipe (Jungle Remedy) is
confirmed AH-only but still needs its real scroll name -- Survival
doesn't have an established scroll-name prefix convention documented
yet, so this one's left unset rather than guessed. Still not enabled.


v2.4.12
-------
Survival's real recipe data is in -- 89 recipes built from the
spreadsheet the user provided. Starfeather Arrows removed entirely (two
recipes shared a name, would have collided in lookup). Two real item
name collisions resolved: item #12361 is Blue Sapphire (not "Pure
Moonstone", which was already claimed by Jewelcrafting), and Survival's
own "Striped Melon Seeds" covered two different real items -- #51712 is
really Juicy Watermelon. Both tools (Whittle, Blacksmith Hammer)
confirmed and priced. Still not enabled -- learn-source data hasn't
been done yet, same as every other profession's rollout.


v2.4.11
-------
Survival profession scaffolding added -- button in place (taking
Tailoring's old position, Tailoring shifted down one slot), registered
in the toc, disabled until real recipe data arrives. No recipes yet:
only item ID/name lookups for crafted outputs and reagents have been
provided so far, not the recipe structure itself (which reagents, what
quantities, what skill thresholds) -- that's still needed before this
profession can actually be built out.


v2.4.10
-------
Fixed the negative-cost bug: ApplyPureProductionExtensions was crediting
a fabricated "savings" to other steps based on a disconnected price
lookup unrelated to what those steps actually paid, which could (and
did) push individual step costs negative. It now compares real,
recomputed total costs for the route with and without each proposed
extension and only keeps changes that are genuinely cheaper -- same
proven approach ApplyDownstreamExtensions already used. Verified with an
isolated before/after test on real scan data: the fabricated 78%
"discount" and all negative-cost steps are gone; the route correctly
lands back at its real total.


v2.4.9
------
Report summary line now correctly says "Returned money after selling
crafts back to vendor" when AH sell-back isn't enabled, instead of
implying AH was considered when it wasn't.


v2.4.8
------
Vendor sell-price coverage is complete -- confirmed all 7 remaining
items (Crafted Light/Heavy/Solid Shot, Green/Red Firework, Firework
Launcher, Heavy Leather Ball) cannot be sold to any vendor, added as 0
same as the earlier confirmed-zero items. 856 entries total. Every
non-excluded recipe across all 7 sellback-eligible professions now has
a real, user-verified vendor sell price on record.


v2.4.7
------
Vendor sell-price coverage completed to 849 items -- effectively full
coverage across all 7 sellback-eligible professions. Greenskeeper
(Engineering) and Refined Dwarven Necklace (Jewelcrafting) excluded
entirely rather than priced -- neither had a reliable confirmed item ID.
7 items (mostly Engineering ammo/fireworks) still pending confirmation
of a "not sellable" status before being marked 0.


v2.4.6
------
Sell-back is re-enabled, backed by real data this time. Built
data_vendorsellprices.lua from 217 vendor sell prices collected directly
by the user via octowow.st -- replaces the old live tooltip/aux-itemId
lookup entirely (removed, not just bypassed). Items confirmed not
sellable to any vendor (Elixir of Rapid Growth, Mighty Rage Potion,
Goblin Radio KABOOM-Box, Hypertech Battery Pack) are stored as a real
zero rather than guessed at. Coverage isn't total -- 642 standard
vanilla crafted items across the other 6 professions are still
unverified and correctly show no sell-back credit rather than a guess,
same as always.


v2.4.5
------
Corrected two recipe names to match their real in-game item names,
confirmed directly: Blacksmithing's "Thorium Hammer" is actually "Inlaid
Thorium Hammer", and Leatherworking's "Leather Helmet" is actually "Wild
Leather Helmet".


v2.4.4
------
Removed the aux-addon price-history fallback entirely. If CraftRoute's
own scan doesn't have a price for something, that's now treated as
genuinely unknown rather than filled in from a secondary data source --
if it isn't in a real CraftRoute scan, the addon no longer assumes you
can buy it. Also removed several helper functions that existed solely
to support the removed fallback and had no other callers left.


v2.4.3
------
Sell-back is temporarily disabled entirely -- reports no longer include
any leftover-crafted-item sell credit, the AH sell-back checkbox is
disabled, and the associated extra scan step is skipped. Crafted-output
vendor prices were never verified the way reagent prices have been
throughout this project; this stays off until that verification is done.


v2.4.2
------
Fix: a Jewelcrafting report recommended crafting Rough Gemstone Cluster
with a sell-back credit over 1g, despite it only vendoring for 20c.
Traced this to a real gap -- the vendor sell-back price comes from a
live tooltip lookup keyed by an item ID resolved from aux-addon's own
cache, which CraftRoute has no way to verify. A stale or wrong entry
there would silently price a completely different item with no way to
tell from the number shown. Added a cross-check in both the sell-back
calculation and the AH-history fallback used for buying decisions:
before trusting a resolved item ID, verify it actually maps back to the
expected item name. A mismatch is now treated as "no price available"
rather than "confidently show a wrong one."


v2.4.1
------
Added Shimmering Oil to the vendor-preferred materials list (5s) --
always bought from vendor now, no longer AH-scanned or AH-compared.


v2.4
----
Reports now show a separate shopping list for each skill band (1-50,
50-125, 125-200, 200-300), placed right above that band's step section
instead of one combined list at the end -- shop for the band you're
actually about to work through. The four band totals are priced with
one continuous AH depletion timeline, not four independent "fresh
market" scenarios, so they sum to exactly the same real total as
before -- the top summary is now derived directly from those same four
numbers, so it can never drift out of sync with what's shown below it.


v2.3.1
------
Jewelry Lens, Jewelry Scope, and Precision Jewelry Kit confirmed as
AH-purchasable -- all 4 Jewelcrafting tools now have confirmed sourcing
in the "Tools you'll need" report note. No open data gaps left on
Jewelcrafting.


v2.3
----
Jewelcrafting is enabled! All 8 professions now available. Full
recipe-level review complete (194/194 classified, no threshold-ordering
issues remaining). One informational gap still open, doesn't affect
cost correctness: 3 of Jewelcrafting's 4 tools still have no confirmed
vendor price, so they won't show in the "Tools you'll need" note yet.


v2.2.9
------
Opaline Illuminator confirmed AH-only, given the same treatment as the
other 64 AH recipes. Dense Gemstone Cluster's yellow threshold corrected
to 235 (was 230, below its own orange).


v2.2.8
------
Jewelcrafting learn-source review, first pass: 79 confirmed trainer-
taught, 71 confirmed real scroll names added (64 AH-only, 7 vendor-bought
with real prices), 27 excluded, 2 confirmed boss drops (new "Boss"
source, alongside Trainer/Recipe/Quest), 11 confirmed quest rewards.
Dense Gemstone Cluster removed from the exclusion list (confirmed
trainer-taught) -- its threshold data still has a known issue from the
original data audit though, flagged for a follow-up, not silently left
broken. One recipe (Opaline Illuminator) wasn't reviewed and is still
open. Still not enabled in the UI.


v2.2.7
------
Jewelcrafting's placeholder data replaced entirely with real data
extracted from Turtle WoW's own addon source (194 recipes, thresholds
and reagents solid). Found and resolved a handful of real data issues
along the way -- most notably 4 reagent names that each covered two
different real items (Star Ruby, Purple Lotus, Huge Emerald, Imperial
Topaz), which could have silently blended two items' AH prices together
had they gone in unresolved. Still not enabled -- learn-source data
(trainer/vendor/AH) and pricing for 3 of its 4 tools are still open,
same as Cooking's data before its own learn-source pass.


v2.2.6
------
Excluded all 9 Transmute recipes from Alchemy -- never chosen as a route
step, never substituted in as a cheaper way to obtain something else's
ingredient.


v2.2.5
------
Internal changes to addon initialization and feature availability checks.


v2.2.4
------
Internal changes to addon initialization and feature availability checks.


v2.2.3
------
Promoted Hot Spices and Shiny Red Apple to the vendor-preferred list --
always bought from vendor now, no longer AH-scanned or AH-compared.


v2.2.2
------
Fix: Thistle Tea's reagent was stored as "Swifthistle" (missing a T) --
a genuine typo, confirmed against the correct spelling already used
correctly in 4 Alchemy recipes and present in real scan data. The
scanner was faithfully querying the AH for an item that doesn't exist;
the real item never got scanned for Cooking. Also checked the rest of
Cooking's reagents for the same failure pattern -- no other typos found.
Added 2 confirmed vendor prices: Hot Spices (40c), Shiny Red Apple (25c).


v2.2.1
------
Cooking follow-up: reviewed all 41 recipes that were still defaulting to
an unconfirmed trainer-taught guess. 8 confirmed genuinely trainer-taught
(kept their existing cost estimates, nothing else needed). 33 excluded
entirely -- never chosen as a route step, never substituted in as a
cheaper way to obtain something else's ingredient.


v2.2
----
New: Cooking is enabled! Its recipe/reagent data was already complete,
but every recipe was modeled as a flat trainer-cost guess with no real
learn-source info -- fixed with confirmed data for all 43 recipes: 1
trainer-taught, 39 vendor-bought (real copper prices added), and 3
AH-only with no vendor (flagged to wait for a real scan rather than
guess a price, same as a few older gaps in other professions). Cooking
hasn't been through the same in-game verification other professions
have, so treat it as newer and less battle-tested for now, but it's no
longer blocked on a known data gap.


v2.1.7
------
Fix: Scan All was reported to loop back to the first profession and
restart the whole sequence after finishing the last one. Found and fixed
a real bug -- two places in the scanner could call a scan's completion
callback synchronously, nested inside whatever had started that scan,
instead of always going through the normal async update loop like every
other completion path does. For Scan All, that completion callback is
what starts the NEXT profession's scan, so it was possible for a new
scan to begin while an earlier one was still executing further up the
same call stack, both touching the same shared scanner state. All
completions now go through a proper deferred queue instead, so a new
scan can never start from inside an older one's call stack. This is a
real fix for a real bug -- worth saying plainly, though, that it wasn't
possible to fully confirm this is the entire explanation without a live
client to test against. If Scan All still loops after this, that's not
something to assume is already fixed -- it needs a fresh look.


v2.1.6
------
Removed the "Total estimated cost (approx, used to pick recipes)" line
from reports -- it's the algorithm's own internal decision-making number
(inflated by the scarcity penalty when applicable), not a real price,
and only ever created confusion sitting next to the actual "Total AH
cost" figure. Also updated the chat message shown after a report opens
to use the real total instead of this same internal number, so it
matches what the report itself and the guide-comparison totals show.


v2.1.5
------
Fix: a report recommended buying 128 of a reagent that only ever had 34
listed -- an impossible shopping list. The existing 3x scarcity penalty
on short-supply reagents was a soft deterrent, not a hard limit, so a
scarce-but-otherwise-cheap recipe could still look "cheapest" no matter
how large the real shortage got. Craft-vs-buy now tracks genuine
achievability (is there actually real supply left, from the AH or a
vendor) alongside cost, not just cost -- once a reagent's real supply is
truly exhausted, the recipe needing it becomes unusable at that point,
same as it already does for unscanned or unpriceable items, so the
route automatically switches to the next-best alternative for the rest
of that skill range. A scarce, cost-effective recipe now gets used for
as many crafts as real supply actually supports, then hands off --
instead of being recommended for a quantity that was never realistic to
begin with.


v2.1.4
------
Fix: a real Leatherworking 1-300 report recommended buying 13755 Ruined
Leather Scraps -- technically the cheapest way to get enough Light
Leather by the numbers, but Ruined Leather Scraps isn't realistically
available on the AH anywhere near that quantity, and it's a low-value
material not worth the trouble either way. Light Leather is now fully
excluded from both CraftRoute's own skill-up selection and from being
silently substituted in as a make-vs-buy source for anything else that
needs it -- it'll always be bought directly. Checked every place a
craft substitution decision happens in the code to make sure this is
enforced consistently, not just at the one place that first surfaced
the problem.


v2.1.3
------
Added Holy Candle (7s) to the vendor-preferred materials list -- missed
in the original v2.1 pass. Same treatment as the other 38: always bought
from vendor, no longer scanned on the AH.


v2.1.2
------
Fix: the make-vs-buy decision for regular craftable materials (grinding
stones, blasting powders, and similar reagent-chain items) wasn't
actually depletion-aware -- it compared a flat, single-price "cheapest
current listing" number against the craft cost, rather than checking
what buying the FULL quantity needed would really cost once cheaper
listings run out. A couple of cheap listings could make "buy" look
better than it really was for a larger need. Craft-vs-buy now applies
the same real order-book-walking logic already used for essence
conversion, so it correctly recurses through multi-level craft chains
(e.g. Engineering's Hi-Explosive Bomb needing Mithril Casing needing
Mithril Bar) with real AH depletion applied at every level.


v2.1.1
------
Fix: a real, live bug -- a Blacksmithing 1-300 report recommended buying
5040 Ruined Leather Scraps, a Leatherworking-only material. Blacksmithing
needs Light Leather for a handful of weapon grips; Leatherworking
separately has its own real recipe for crafting Light Leather. The
make-vs-buy logic's cross-profession fallback (designed narrow -- one
specific case, Enchanting needing Blacksmithing's own Arcanite Rod --
but never actually restricted to it in code) matched Leatherworking's
recipe and decided to "craft" Light Leather, despite a Blacksmith having
no way to actually perform that craft. Fixed with an explicit allowlist;
the only entry is the one confirmed-legitimate case, Arcanite Rod.


v2.1
----
New: a reviewed, approved list of 38 materials (dyes, threads, vials,
flux, and similar) that are always bought from a vendor instead of the
AH, even on the rare chance the AH is momentarily cheaper. Vendors never
run out of stock and never change price, so once a material's real
vendor price is confirmed, there's no reason to gamble on a
possibly-stale AH scan for it. These materials are also no longer
included in AH scans at all (per-profession or Scan All) -- there's
nothing to check the AH for anymore.


v2.0.1
------
Two bugs found the first time this was actually run in-game, both fixed:
  - A syntax error (an accidental deletion during the v2.0 work took the
    ShoppingList function's own declaration line out with it, leaving
    its body orphaned outside any function).
  - A runtime error right after (guide-priced routes were missing a
    field, recipeIndex, that ShoppingList/SellBackCredit depend on to
    look up a recipe's own reagent list).
Also: report window text polish (profession name capitalized, clearer
guide-comparison header wording, "wowprofessions" now displays as
"Wow-Professions.com", reworded the trainer-cost estimate note), and a
real fix for the report window's scrollbar, which wasn't scrolling at
all for long reports -- turned out the vanilla client doesn't reliably
auto-update a scrollbar's range when its EditBox content is resized
programmatically, so the range and mouse-wheel handling are now both
set explicitly instead of assumed.


v2.0
----
New: CraftRoute now compares its own optimized route against real
static leveling guides (starting with wow-professions.com, covering all
6 leveled professions) and shows you whichever one is actually cheaper.
Both routes get priced through the exact same depletion-aware engine,
each with its own independent, freshly-reset AH order-book state -- two
honest side-by-side scenarios, not one route's leftovers biasing the
other. The top of the report now shows every compared total, with the
winner marked and shown in full below.

Getting a static guide's route to a comparable state as CraftRoute's own
took real correction work, not just transcription -- multiple steps in
the source guide ran past a recipe's real point of obsolescence or
started before it was even usable, a couple of named recipes didn't
match anything in the data (one turned out to be a genuine gap in our
own data and got added; others didn't check out and were left out), and
one Blacksmithing recipe was wrongly assumed to be specialization-locked
before being confirmed available to everyone via a quest. All of that
verification work is preserved in DEVNOTES.md for the professions and
guides already checked.


v1.14
-----
New: recipes that come from a quest or reputation turn-in rather than a
trainer or an AH-buyable scroll now show up correctly -- orange text,
tagged "Quest" instead of "Trainer"/"Recipe", no fabricated gold learn
cost. Applied to Blacksmithing's 6 Imperial Plate recipes (Belt,
Shoulders, Bracers, Boots, Helm, Gauntlets), previously modeled as if
they were ordinary AH-buyable patterns.


v1.13.1
-------
Fix: hundreds of reagent references across Blacksmithing, Engineering,
Leatherworking, and Tailoring were stored as bare item IDs instead of
names. This wasn't just a readability problem -- an item stored this way
couldn't be recognized by the make-vs-buy logic as something craftable
in its own right, and couldn't be matched against scanned AH listings
(which are keyed by name) at all. All confirmed and converted to real
names.


v1.13
-----
New: three confirmed-real recipes added that were missing from the
data entirely -- Enchant Gloves - Agility (Enchanting), Azure Silk Hood
and Double-stitched Woolen Shoulders (Tailoring). Also added the
confirmed vendor price for Formula: Runed Arcanite Rod (2g 20s), so its
learn cost now reflects a real, cheaper number instead of a rough
estimate.


v1.12.1
-------
Fix: the essence conversion feature (v1.12) priced the 5 Greater essences
correctly but never actually scanned for their Lesser counterparts, so
the "convert" option could only ever be considered if you happened to
already have Lesser essence data from an unrelated scan. Scanning
(both the per-profession button and Scan All) now automatically includes
a Greater essence's Lesser counterpart whenever the Greater one is
itself reachable at your current skill.


v1.12
-----
New: essence conversion awareness for Enchanting. The 5 Greater essences
(Astral/Eternal/Magic/Mystic/Nether) can each be obtained by buying 3x the
matching Lesser essence off the AH and combining them -- one-way, no
converting back. The path calculation, shopping list, and true-cost totals
now all check this alongside the existing AH-price and make-vs-buy-craft
options, and pick whichever is actually cheapest. Depletion-aware: a
chosen conversion draws down the LESSER essence's own listings, not the
Greater's, so a shortage of Greater essences (or of Lesser ones) is
reflected accurately either way.


v1.11
-----
New: widened the downstream-extension pass to reach reagent needs the
previous version genuinely couldn't. The existing extension mechanism only
works by extending a recipe's own skill-up range further, so it could never
help once a later reagent need falls beyond the producing recipe's own grey
point -- past there, the recipe contributes zero skill-up, so there was
nothing for the old mechanism to extend.

Added a second pass for exactly this case: for any reagent still falling
short somewhere in the path after the existing extension pass runs, checks
whether crafting a few more units of it anyway -- flat cost, zero skill
value, added onto that recipe's existing step wherever it already sits --
would beat buying the shortfall separately. No skill-range reasoning
needed, just "is crafting this cheaper than buying it."

Two bugs caught and fixed during development, before ever shipping:
  - The first draft added the new craft cost directly to the running
    total without subtracting the cost it was replacing, double-counting
    against the downstream recipe's already-assumed buy cost.
  - Even after fixing the total, the individual downstream step's own
    displayed subtotal still showed its old, pre-credit cost -- so the
    report's per-step breakdown wouldn't add up to its own stated overall
    total. Fixed by crediting the savings back to whichever step(s)
    actually demand the reagent, proportional to how much each needs (a
    reagent can be shared by more than one step).

Verified with a constructed scenario the old pass couldn't reach: confirmed
the producing recipe correctly gained extra crafts, the real shopping list
correctly avoided a separate purchase entirely, and after both fixes, the
sum of every displayed step subtotal matches the report's overall total
exactly.


v1.10.1
-------
Fix: the "Total estimated cost" figure could come out wildly higher than
the real "Total AH cost" for professions with many recipes sharing common
reagents (e.g. Blacksmithing's Dense Stone, Mithril Bar, Rough Stone) --
seen as high as 945g estimated vs 184g actual on a real Blacksmithing run.

Root cause: a leftover redundancy from the v1.10 work. Before path-wide
tracking existed, recipe selection used a standalone heuristic assuming a
candidate recipe might get used across up to 50 skill points, since there
was no way to know what else might need the same reagent. v1.10 added a
real, accurate path-wide consumption tracker but left that old heuristic
running on top of it -- for a reagent shared by many recipes, every
candidate's own speculative 50-point assumption stacked on top of every
other candidate's, compounding the estimate far past what the route would
actually need.

Removed the now-redundant heuristic. Recipe selection now prices exactly
what one craft needs, right now, against the live path-wide tracker --
recomputed fresh every skill point, so this is an accurate marginal price
with no speculative stacking. Verified directly against the real
Blacksmithing case from the bug report: estimated and actual costs now
land within about 2% of each other (160g73s vs 157g72s), down from a 5x gap.


v1.10
-----
New: path-wide depletion-aware pricing. Previously, every part of the
calculator that compared costs -- picking which recipe to use at each skill
point, deciding whether to extend an earlier recipe run to cover a later
reagent need, and deciding whether to craft a required tool or buy one
pre-made -- priced reagents using only "today's single cheapest listing,"
with no concept of how much is actually available at that price, or
whether an earlier decision already bought up that same cheap supply. This
meant the algorithm could genuinely recommend routes that weren't buyable
as calculated: recipes needing more of a reagent than the Auction House
actually has listed, with the true cost only surfacing after the fact in
the final shopping list.

All three places now price against real, live listing depletion instead:
  - Recipe selection at each skill point recomputes costs using a running
    tracker of what earlier, already-locked-in steps have consumed, so
    later steps correctly see reduced remaining supply -- not just within
    one recipe's own usage, but across every different recipe competing
    for the same reagent anywhere in the path.
  - The "should I extend this recipe run" decision now compares real
    listing-depletion costs for both options instead of flat pricing.
  - The "craft this required tool or buy one pre-made" decision now prices
    the buy-it-premade option the same depletion-aware way.

Also removed the "Section total" line from the printed report -- it was
built from the same approximate per-step estimates used to pick recipes,
not the real Auction House cost, and being labeled a "total" was
misleading next to the report's actual true-cost figures.


v1.9.3
------
Fix: the report window's scrollable area was still capping out short of the
true bottom of the text, even after the v1.9.2 fix -- confirmed the actual
report text itself was always complete (fully retrievable via copy-paste),
so the bug was specifically in how the scroll area was being sized. Root
cause: GetHeight() can return a stale value (left over from the previous
report, or 0) if read on the same frame SetText() was just called on --
the game's layout system hasn't necessarily recomputed it yet. Deferred the
height read by a few OnUpdate ticks so it reflects the actual new content,
and added a 20% safety margin on top as an extra hedge, since undersizing
(cutting off content) is a much worse failure than a little unused scroll
space.


v1.9.2
------
Fix: the report window crashed with "attempt to call method 'GetStringHeight'"
every time it tried to open. GetStringHeight() was added to the WoW API in a
later client version and isn't actually part of the original 1.12/vanilla
API Turtle WoW runs on -- the same category of mistake as the EditBox
Disable() crash fixed earlier. Switched to GetHeight(), a basic method
available on every UI object, which reflects the same auto-computed wrapped
text height on a width-constrained FontString.


v1.9.1
------
Fix: /craftroute (and the Create CraftRoute button) refused to run at all
if aux-addon wasn't installed or hadn't been loaded yet, even though aux is
only ever used as an optional fallback price source -- CraftRoute's own AH
scan data and vendor prices are enough on their own. Removed the leftover
hard requirement check.


v1.9
----
Internal changes to addon initialization and feature availability checks.


v1.8.2
------
Fix: Scan All's status text showed each individual job's own item count
(e.g. "68" for Alchemy's materials) with no indication that Scan All chains
12 separate jobs together (6 enabled professions x materials+recipes) --
easy to misread as "Scan All only found 68 items total" when the other 11
jobs were still to come. Status text now shows "job N/12" alongside each
step so overall progress through the whole sequence is clear.


v1.8.1
------
Fix: the "Scan All Professions" button was missing its label text entirely
-- present and functional, just invisible.


v1.8
----
New: Configurable sell-back threshold. The previously hardcoded 1.5x
(50% above vendor price) threshold for recommending an Auction House sale
over a vendor sale is now a real, adjustable setting -- a percentage box in
the UI wired directly into the calculation, not just a cosmetic number.

New: Skill-range-aware materials scanning. Setting a starting skill above 1
now makes the materials scan skip reagents that are only needed by recipes
already entirely grey at that starting skill, genuinely reducing scan time
for a narrow-range route (e.g. 250-280) rather than always scanning for the
full 1-300 range. (The same filtering was initially also applied to recipe
scanning, but was reverted after review showed it didn't actually save any
time there -- a prefix-based recipe scan pages through every result for
that prefix regardless of how many specific scrolls are relevant, so
filtering only changed what got stored, not how many queries were needed.)


v1.7.2
------
Fix: EditBox widgets don't support a Disable() method in vanilla WoW's UI
API, unlike Button and CheckButton. Calling it on a disabled profession's
number boxes threw a runtime error that halted the entire panel-building
function partway through -- silently breaking the whole CraftRoute tab
every time (blank past a certain point, missing checkbox, missing Scan All
button) with no visible error unless other addons weren't suppressing it.
Switched to the correct vanilla-compatible approach: EnableMouse(false) plus
greying out the text color.


v1.7.1
------
Fix: the report window's scrollable area was sized by counting newline
characters in the report text, which didn't account for lines that visually
wrap to multiple lines at the window's width. Several genuinely long lines
in the report caused the calculated scroll height to fall short of the real
rendered height, capping scrolling before the true bottom of the text.


v1.7
----
New: "Create CraftRoute" button added to each profession's row, alongside
two editable number boxes (defaulting to 1 and 300), replacing the
standalone "Recipes" button. Runs the route calculation directly from the
UI, equivalent to typing /craftroute <profession> <start> <target> by hand.


v1.6
----
New: Materials and recipe scanning merged into one click. The main
profession button now automatically continues into recipe scanning as soon
as materials finish, instead of requiring a separate "Recipes" button click.

Fix: the recipe scan's completion callback wasn't being called for a
profession with zero recipe scrolls to scan (e.g. Cooking), which could
leave scan buttons permanently disabled once materials-then-recipes scans
were chained together.


v1.5
----
New: Recipe scanning rewritten to search by prefix (Plans:, Formula:,
Pattern:, Schematic:, Recipe:) instead of one exact-name Auction House query
per scroll. A single prefix search pages through every matching result at
once, cutting a 50+ query scan down to 1-2 queries for most professions.


v1.4
----
New: "Scan All Professions" button, chaining a materials-then-recipes scan
for every enabled profession in sequence, instead of scanning each one by
hand.


v1.3
----
New: "requiresScan" recipe status. A recipe confirmed to be genuinely real
and tradeable on the Auction House, but with no reliable fixed price to fall
back on, is now only usable by the route calculator once its scroll has
actually been scanned -- no guessed estimate is used in the meantime, so the
calculator can never recommend something that turns out to be unavailable.


v1.2
----
New: Recipe exclusion mechanism. Recipes that are extreme cost outliers (far
more expensive than any comparable recipe at a similar skill level) can now
be flagged as excluded from route consideration without deleting their
underlying data -- fully reversible, and still usable as a make-vs-buy
material source for other recipes if genuinely needed.


v1.1
----
New: Cross-profession recipe lookup. Previously, if a recipe needed another
profession's crafted item as a reagent (e.g. Enchanting's Runed Arcanite Rod
needing Blacksmithing's Arcanite Rod), the calculator had no way to price
that item at all. It now correctly resolves the cost by crafting it via the
other profession's own recipe when nothing local matches.


v1.0
----
Initial versioned release. At this point CraftRoute already had:
  - Full recipe and skill-threshold data for all 8 professions
  - Live Auction House price scanning, independent of aux-addon
  - The cost-optimal 1-300 route calculator (skill-up probability model,
    make-vs-buy reagent costing, recipe learn-cost handling)
  - The Auction House UI tab with per-profession scan buttons
  - The scrollable report window
  - Sell-back credit recommendations (AH vs vendor) for leftover crafted
    items

## The Algorithm 

<img width="2356" height="3900" alt="CraftRoute Algorithm Flowchart-selection - Copy" src="https://github.com/user-attachments/assets/e29eaedb-738e-4df4-877d-a56ddd4f6931" />

### Stage 2 Expanded
For this last picture it is the stage 2 loop from above expanded. What occurs here is a production has been extended because its cheaper to make, needed later, and you may as well get skillups for it. The problem is that now we need to do a trimming of the recipe that comes after the one where we chose to make more.

<img width="4524" height="1686" alt="CraftRoute Algorithm Flowchart-selection - Copy (2)" src="https://github.com/user-attachments/assets/bd7c71cc-fbe3-414c-a07b-2d64213a3a39" />


## **FAQ** In progress
### **Why does blacksmithing stop at level 235, wasn't the whole point to get around bottlenecks?**
   I wish I could squeeze you past the need for Iron, and everyone leveling their profession right now, but I can't because some things are impossible, like being a blacksmith without metal. The best route here would be to finish that last step it told you, then when there is more iron on the auction house change the bracket in the AH tab or type /craftroute 235 300 to start from there.
