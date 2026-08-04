-- Static leveling guide data, sourced from wow-professions.com, cross-checked
-- against this addon's own recipe data (thresholds/reagents) and corrected
-- where the source guide didn't match real skill-up mechanics -- see
-- DEVNOTES.md section 6 for the full reasoning behind every correction below.
--
-- Each entry is {name=<recipe name, must match CraftRoute_Data exactly>,
-- fromSkill=N, toSkill=N, crafts=N}. Reagents, thresholds, learn cost, and
-- scroll/quest status are NOT duplicated here -- they're looked up from the
-- profession's own CraftRoute_Data at calculation time, so this file only
-- ever needs to say which recipe, what range, how many crafts.
--
-- Corrections applied vs. the raw source guide text (see DEVNOTES §6):
--   - Blacksmithing/Tailoring/Leatherworking: several steps in the raw
--     guide ran past a recipe's real grey or started before its real
--     orange; those ranges were adjusted and, where a genuine gap opened
--     up, bridged with a legitimate substitute recipe (thresholds/reagents
--     confirmed, not guessed).
--   - Engineering's one dual-recipe bracket (135-150, Heavy Blasting Powder
--     + Whirring Bronze Gizmo) was split at each recipe's real
--     obsolescence point rather than trusting the guide's stated split.
--   - Tailoring's "Double-stitched Woolen Shoulders" and "Azure Silk Hood"
--     were confirmed as real recipes missing from CraftRoute's own data
--     and added there (data_tailoring.lua) rather than treated as guide
--     errors.
--   - Blacksmithing's Imperial Plate Belt/Shoulders/Bracers/Boots/Helm/
--     Gauntlets are quest-obtained, not specialization-locked as initially
--     assumed -- see questObtained in data_blacksmithing.lua.
--
-- Known gaps (flagged, not guessed): a handful of reagent itemIds across
-- these professions were unresolved at the time this was built. Check
-- DEVNOTES.md before assuming this list is exhaustive -- new gaps may
-- surface as scan data changes.

CraftRoute_GuideSteps = CraftRoute_GuideSteps or {}
CraftRoute_GuideSteps["wowprofessions"] = {

	alchemy = {
		{name="Minor Healing Potion", fromSkill=1, toSkill=60, crafts=65},
		{name="Lesser Healing Potion", fromSkill=60, toSkill=110, crafts=65},
		{name="Healing Potion", fromSkill=110, toSkill=140, crafts=35},
		{name="Lesser Mana Potion", fromSkill=140, toSkill=155, crafts=20},
		{name="Greater Healing Potion", fromSkill=155, toSkill=185, crafts=35},
		{name="Elixir of Agility", fromSkill=185, toSkill=210, crafts=30},
		{name="Elixir of Greater Defense", fromSkill=210, toSkill=215, crafts=5},
		{name="Superior Healing Potion", fromSkill=215, toSkill=230, crafts=15},
		{name="Elixir of Detect Undead", fromSkill=230, toSkill=265, crafts=45},
		{name="Superior Mana Potion", fromSkill=265, toSkill=285, crafts=30},
		{name="Major Healing Potion", fromSkill=285, toSkill=300, crafts=20},
	},

	blacksmithing = {
		{name="Rough Sharpening Stone", fromSkill=1, toSkill=30, crafts=40},
		{name="Rough Grinding Stone", fromSkill=30, toSkill=65, crafts=55},
		{name="Coarse Sharpening Stone", fromSkill=65, toSkill=75, crafts=25},
		{name="Coarse Grinding Stone", fromSkill=75, toSkill=90, crafts=35},
		{name="Runed Copper Belt", fromSkill=90, toSkill=100, crafts=10},
		{name="Silver Rod", fromSkill=100, toSkill=105, crafts=5},
		{name="Runed Copper Belt", fromSkill=105, toSkill=110, crafts=5},
		{name="Rough Bronze Leggings", fromSkill=110, toSkill=125, crafts=15},
		{name="Heavy Grinding Stone", fromSkill=125, toSkill=140, crafts=35},
		{name="Patterned Bronze Bracers", fromSkill=140, toSkill=150, crafts=10},
		{name="Golden Rod", fromSkill=150, toSkill=155, crafts=5},
		{name="Green Iron Leggings", fromSkill=155, toSkill=165, crafts=10},
		{name="Green Iron Bracers", fromSkill=165, toSkill=190, crafts=25},
		{name="Golden Scale Bracers", fromSkill=190, toSkill=200, crafts=10},
		{name="Solid Grinding Stone", fromSkill=200, toSkill=210, crafts=30},
		{name="Heavy Mithril Gauntlet", fromSkill=210, toSkill=225, crafts=15},
		{name="Steel Plate Helm", fromSkill=225, toSkill=235, crafts=10},
		{name="Mithril Coif", fromSkill=235, toSkill=250, crafts=15},
		{name="Dense Sharpening Stone", fromSkill=250, toSkill=260, crafts=20},
		{name="Mithril Spurs", fromSkill=260, toSkill=270, crafts=20},
		{name="Imperial Plate Bracers", fromSkill=270, toSkill=295, crafts=25},
		{name="Imperial Plate Boots", fromSkill=295, toSkill=300, crafts=5},
	},

	enchanting = {
		{name="Runed Copper Rod", fromSkill=1, toSkill=2, crafts=1},
		{name="Enchant Bracer - Minor Health", fromSkill=2, toSkill=50, crafts=48},
		{name="Enchant Bracer - Minor Health", fromSkill=50, toSkill=90, crafts=40},
		{name="Enchant Bracer - Minor Stamina", fromSkill=90, toSkill=100, crafts=10},
		{name="Runed Silver Rod", fromSkill=100, toSkill=101, crafts=1},
		{name="Greater Magic Wand", fromSkill=101, toSkill=110, crafts=9},
		{name="Enchant Cloak - Minor Agility", fromSkill=110, toSkill=135, crafts=25},
		{name="Enchant Bracer - Lesser Stamina", fromSkill=135, toSkill=155, crafts=20},
		{name="Runed Golden Rod", fromSkill=155, toSkill=156, crafts=1},
		{name="Enchant Bracer - Lesser Strength", fromSkill=156, toSkill=165, crafts=9},
		{name="Enchant Bracer - Spirit", fromSkill=165, toSkill=185, crafts=20},
		{name="Enchant Bracer - Strength", fromSkill=185, toSkill=200, crafts=15},
		{name="Runed Truesilver Rod", fromSkill=200, toSkill=201, crafts=1},
		{name="Enchant Bracer - Strength", fromSkill=201, toSkill=220, crafts=35},
		{name="Enchant Cloak - Greater Defense", fromSkill=220, toSkill=225, crafts=5},
		{name="Enchant Gloves - Agility", fromSkill=225, toSkill=230, crafts=5},
		{name="Enchant Boots - Stamina", fromSkill=230, toSkill=235, crafts=5},
		{name="Enchant Chest - Superior Health", fromSkill=235, toSkill=250, crafts=25},
		{name="Lesser Mana Oil", fromSkill=250, toSkill=265, crafts=20},
		{name="Enchant Shield - Greater Stamina", fromSkill=265, toSkill=294, crafts=30},
		{name="Runed Arcanite Rod", fromSkill=294, toSkill=295, crafts=1},
		{name="Enchant Cloak - Superior Defense", fromSkill=295, toSkill=300, crafts=5},
	},

	engineering = {
		{name="Rough Blasting Powder", fromSkill=1, toSkill=30, crafts=60},
		{name="Handful of Copper Bolts", fromSkill=30, toSkill=50, crafts=30},
		{name="Arclight Spanner", fromSkill=50, toSkill=51, crafts=1},
		{name="Rough Copper Bomb", fromSkill=51, toSkill=75, crafts=30},
		{name="Coarse Blasting Powder", fromSkill=75, toSkill=90, crafts=60},
		{name="Coarse Dynamite", fromSkill=90, toSkill=100, crafts=20},
		{name="Silver Contact", fromSkill=100, toSkill=105, crafts=5},
		{name="Bronze Tube", fromSkill=105, toSkill=125, crafts=25},
		{name="Standard Scope", fromSkill=125, toSkill=135, crafts=10},
		{name="Heavy Blasting Powder", fromSkill=135, toSkill=145, crafts=59},
		{name="Whirring Bronze Gizmo", fromSkill=145, toSkill=150, crafts=9},
		{name="Bronze Framework", fromSkill=150, toSkill=160, crafts=15},
		{name="Explosive Sheep", fromSkill=160, toSkill=175, crafts=15},
		{name="Solid Blasting Powder", fromSkill=175, toSkill=194, crafts=60},
		{name="Gyromatic Micro-Adjustor", fromSkill=194, toSkill=195, crafts=1},
		{name="Mithril Tube", fromSkill=195, toSkill=200, crafts=7},
		{name="Unstable Trigger", fromSkill=200, toSkill=215, crafts=20},
		{name="Mithril Casing", fromSkill=215, toSkill=238, crafts=40},
		{name="Hi-Explosive Bomb", fromSkill=238, toSkill=250, crafts=20},
		{name="Dense Blasting Powder", fromSkill=250, toSkill=260, crafts=30},
		{name="Thorium Widget", fromSkill=260, toSkill=285, crafts=35},
		{name="Thorium Tube", fromSkill=285, toSkill=300, crafts=20},
	},

	leatherworking = {
		{name="Light Armor Kit", fromSkill=1, toSkill=45, crafts=54},
		{name="Handstitched Leather Cloak", fromSkill=45, toSkill=55, crafts=20},
		{name="Embossed Leather Gloves", fromSkill=55, toSkill=100, crafts=50},
		{name="Cured Medium Hide", fromSkill=100, toSkill=122, crafts=15},
		{name="Fine Leather Belt", fromSkill=122, toSkill=125, crafts=6},
		{name="Dark Leather Boots", fromSkill=125, toSkill=137, crafts=15},
		{name="Dark Leather Pants", fromSkill=137, toSkill=150, crafts=20},
		{name="Heavy Leather", fromSkill=150, toSkill=155, crafts=7},
		{name="Cured Heavy Hide", fromSkill=155, toSkill=170, crafts=35},
		{name="Barbaric Leggings", fromSkill=170, toSkill=180, crafts=10},
		{name="Barbaric Shoulders", fromSkill=180, toSkill=190, crafts=10},
		{name="Guardian Gloves", fromSkill=190, toSkill=200, crafts=10},
		{name="Thick Armor Kit", fromSkill=200, toSkill=205, crafts=5},
		{name="Nightscape Headband", fromSkill=205, toSkill=235, crafts=40},
		{name="Nightscape Pants", fromSkill=235, toSkill=250, crafts=15},
		{name="Nightscape Boots", fromSkill=250, toSkill=260, crafts=13},
		{name="Wicked Leather Gauntlets", fromSkill=260, toSkill=290, crafts=33},
		{name="Runic Leather Headband", fromSkill=290, toSkill=300, crafts=10},
	},

	tailoring = {
		{name="Bolt of Linen Cloth", fromSkill=1, toSkill=40, crafts=102},
		{name="Linen Belt", fromSkill=40, toSkill=70, crafts=40},
		{name="Bolt of Woolen Cloth", fromSkill=70, toSkill=95, crafts=138},
		{name="Pearl-clasped Cloak", fromSkill=95, toSkill=100, crafts=5},
		{name="Gray Woolen Shirt", fromSkill=100, toSkill=110, crafts=10},
		{name="Double-stitched Woolen Shoulders", fromSkill=110, toSkill=125, crafts=15},
		{name="Bolt of Silk Cloth", fromSkill=125, toSkill=145, crafts=201},
		{name="Azure Silk Hood", fromSkill=145, toSkill=160, crafts=18},
		{name="Silk Headband", fromSkill=160, toSkill=170, crafts=10},
		{name="Formal White Shirt", fromSkill=170, toSkill=175, crafts=5},
		{name="Bolt of Mageweave", fromSkill=175, toSkill=185, crafts=94},
		{name="Crimson Silk Vest", fromSkill=185, toSkill=205, crafts=20},
		{name="Crimson Silk Pantaloons", fromSkill=205, toSkill=215, crafts=10},
		{name="Orange Mageweave Shirt", fromSkill=215, toSkill=220, crafts=5},
		{name="Black Mageweave Gloves", fromSkill=220, toSkill=225, crafts=5},
		{name="Diviner's Boots", fromSkill=225, toSkill=230, crafts=5},
		{name="Black Mageweave Headband", fromSkill=230, toSkill=250, crafts=23},
		{name="Bolt of Runecloth", fromSkill=250, toSkill=260, crafts=239},
		{name="Runecloth Belt", fromSkill=260, toSkill=280, crafts=25},
		{name="Runecloth Bag", fromSkill=280, toSkill=290, crafts=18},
		{name="Runecloth Gloves", fromSkill=290, toSkill=300, crafts=12},
	},
}
