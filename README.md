# CraftRoute
Addon for OctoWow

CraftRoute is a OctoWow addon that calculates the cheapest possible route to level any of the game's 9 crafting professions (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Jewelcrafting, Leatherworking, Survival, Tailoring) from any level to any other level, using real, live Auction House prices rather than guesses.

The core problem it solves: leveling a profession efficiently means knowing, at every single skill point, which recipe is actually cheapest to craft right now — not which one a guide from years ago said was cheapest, and not which one looks cheap until you learn that its 3rd ingredient is 250% over the typical price. CraftRoute answers that by scanning the AH itself, storing every single relevant post for the profession in question, and calculating from scratch.

It covers all 9 professions (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Jewelcrafting, Leatherworking, Survival, Tailoring), with every recipe's thresholds, reagents, and learn-source individually verified from the OctoWow database rather than assumed — and 856 vendor sell prices and 170 vendor buy prices confirmed the same way, not estimated.

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

## The Algorithm 

<img width="2356" height="3900" alt="CraftRoute Algorithm Flowchart-selection - Copy" src="https://github.com/user-attachments/assets/e29eaedb-738e-4df4-877d-a56ddd4f6931" />

### Stage 2 Expanded
For this last picture it is the stage 2 loop from above expanded. What occurs here is a production has been extended because its cheaper to make, needed later, and you may as well get skillups for it. The problem is that now we need to do a trimming of the recipe that comes after the one where we chose to make more.

<img width="4524" height="1686" alt="CraftRoute Algorithm Flowchart-selection - Copy (2)" src="https://github.com/user-attachments/assets/bd7c71cc-fbe3-414c-a07b-2d64213a3a39" />


## **FAQ** In progress
