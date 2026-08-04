-- CraftRoute: cheapest-1-to-300 profession leveling calculator
-- Reads scan data saved by the "aux-addon" Auction House addon (must be installed
-- and must have scanned the AH at least once; SavedVariables: aux).
--
-- This file only depends on Lua 5.0 / vanilla WoW 1.12 API (getn, strlower, etc.)
-- since Turtle WoW is a 1.12-based client.

CraftRoute = CraftRoute or {}
CraftRoute_Data = CraftRoute_Data or {}
CraftRoute_Settings = CraftRoute_Settings or {}
if CraftRoute_Settings.includeSellbackScan == nil then
	CraftRoute_Settings.includeSellbackScan = false
end

--------------------------------------------------------------------------
-- Guild restriction
--------------------------------------------------------------------------
-- CraftRoute is restricted to every race EXCEPT this one. Checked at the
-- point of use (opening the tab, running /craftroute) rather than cached
-- once at load time, in case that ever needs to change -- though unlike
-- guild roster data, race is known immediately at login with no
-- server-sync delay, so there's no timing edge case to work around here.
CraftRoute.EXCLUDED_RACE = "Gnome"

function CraftRoute.IsAuthorized()
	local _, raceFile = UnitRace("player")
	return raceFile ~= CraftRoute.EXCLUDED_RACE
end

--------------------------------------------------------------------------
-- aux SavedVariables access
--------------------------------------------------------------------------
-- Only remaining touch point: GetItemId below, a name->itemId lookup into
-- aux's own item_ids cache. Used by ResolveReagent (reagent metadata, not
-- pricing) and GetItemName's itemId->name fallback path. Does NOT feed
-- any price/availability decision -- that dependency (aux's saved price
-- history) was removed entirely; see DEVNOTES §5.

-- Returns item id for an item name (case-insensitive), or nil if aux hasn't
-- seen that item name yet (i.e. it's never appeared in a scan/tooltip).
function CraftRoute.GetItemId(itemName)
	if not aux or not aux.account or not aux.account.item_ids then return nil end
	return aux.account.item_ids[strlower(itemName)]
end

-- Returns the display name for an item id using the client's own item cache
-- (GetItemInfo). On a 1.12-based client this is synchronous/reliable for any
-- valid item id, no need to wait on GET_ITEM_INFO_RECEIVED. Falls back to a
-- placeholder if the id is somehow unknown to this client.
function CraftRoute.GetItemName(itemId)
	if not itemId then return nil end
	local name = GetItemInfo(itemId)
	if name then return name end
	return "Item #" .. itemId
end

-- Resolves a reagent table ({name=...} and/or {itemId=...}) to a
-- (name, itemId) pair. Prefers the itemId path when available since it's
-- more robust than name matching (no typos/variant spelling, and doesn't
-- depend on aux having already seen the item).
function CraftRoute.ResolveReagent(r)
	if r.itemId then
		local name = r.name or CraftRoute.GetItemName(r.itemId)
		return name, r.itemId
	end
	local id = CraftRoute.GetItemId(r.name)
	return r.name, id
end

-- Returns the current AH market price only (CraftRoute's OWN scan data)
-- -- NOT including any vendor price, and NOT falling back to aux-addon's
-- saved history. If CraftRoute hasn't scanned it, the honest answer is
-- "unknown", not "guess from a secondary data source" -- if it isn't on
-- the AH (i.e. not in a real CraftRoute scan), you can't buy it. Used
-- both by GetPriceFor (buying decisions) and by sell-side logic
-- (currently disabled, see SELLBACK_ENABLED).
function CraftRoute.GetMarketPrice(name, itemId)
	if not name and itemId then
		name = CraftRoute.GetItemName(itemId)
	end
	if name and CraftRoute.ScannedUnitPrice then
		return CraftRoute.ScannedUnitPrice(name)
	end
	return nil
end

-- Materials always bought from a vendor rather than the AH, even if the AH
-- happens to be cheaper at some moment -- confirmed and approved list
-- (user-reviewed against real vendor prices, not guessed). Vendors never
-- run out of stock and the price never fluctuates, so once an item's real
-- vendor price is confirmed reliable, comparing it against a fluctuating,
-- possibly-stale AH scan adds risk without meaningfully saving gold on
-- these specific (mostly cheap, high-volume) materials. Deliberately a
-- fixed, reviewed list rather than "always prefer vendor when available"
-- as a blanket rule -- some vendor-sold items are still worth AH-checking.
local VENDOR_PREFERRED_MATERIALS = {
	["black dye"] = true, ["blacksmith hammer"] = true, ["blank parchment"] = true,
	["bleach"] = true, ["blue dye"] = true, ["coal"] = true, ["coarse thread"] = true,
	["copper rod"] = true, ["crystal vial"] = true, ["elemental flux"] = true,
	["empty vial"] = true, ["engineer's ink"] = true, ["fine thread"] = true,
	["flint and tinder"] = true, ["gemstone oil"] = true, ["gray dye"] = true,
	["green dye"] = true, ["heavy silken thread"] = true, ["heavy stock"] = true,
	["holy candle"] = true, ["hot spices"] = true, ["ice cold milk"] = true,
	["imbued vial"] = true, ["jeweler's kit"] = true, ["junglevine wine"] = true,
	["leaded vial"] = true, ["mild spices"] = true, ["mining pick"] = true,
	["molasses firewater"] = true, ["northwind flour"] = true, ["orange dye"] = true,
	["pink dye"] = true, ["polishing oil"] = true, ["purple dye"] = true, ["red dye"] = true,
	["refreshing spring water"] = true, ["remedy herbs"] = true, ["rugged string"] = true,
	["rune thread"] = true, ["salt"] = true, ["shimmering oil"] = true,
	["shiny red apple"] = true, ["silken thread"] = true, ["skinning knife"] = true,
	["soothing spices"] = true, ["springy rope"] = true, ["strong flux"] = true,
	["sturdy rope"] = true, ["unlit poor torch"] = true, ["weak flux"] = true,
	["whittle"] = true, ["wooden stock"] = true, ["yellow dye"] = true
}
CraftRoute.VENDOR_PREFERRED_MATERIALS = VENDOR_PREFERRED_MATERIALS

-- Core price lookup for BUYING a reagent. Either name or itemId may be nil
-- going in; at least one must resolve to something usable. Checks two
-- sources and returns whichever is cheapest:
--   1. the current AH market price (GetMarketPrice above)
--   2. a fixed vendor price (data_vendorprices.lua), if this item is sold by
--      an NPC vendor -- vendors never run out of stock, so a market price
--      above the vendor price is never worth paying
function CraftRoute.GetPriceFor(name, itemId)
	if not name and itemId then
		name = CraftRoute.GetItemName(itemId)
	end

	if name and CraftRoute_VendorPrices and VENDOR_PREFERRED_MATERIALS[strlower(name)] then
		local forcedVendorPrice = CraftRoute_VendorPrices[strlower(name)]
		if forcedVendorPrice then
			return forcedVendorPrice
		end
	end

	local marketPrice = CraftRoute.GetMarketPrice(name, itemId)

	local vendorPrice = nil
	if name and CraftRoute_VendorPrices then
		vendorPrice = CraftRoute_VendorPrices[strlower(name)]
	end

	if marketPrice and vendorPrice then
		return math.min(marketPrice, vendorPrice)
	end
	return marketPrice or vendorPrice
end

-- Returns the copper unit price for an item name, or nil if there's no price
-- data for it yet (caller should treat this as "need to scan the AH").
-- Kept for backwards compatibility with name-only recipe data.
function CraftRoute.GetPrice(itemName)
	return CraftRoute.GetPriceFor(itemName, nil)
end

-- Same idea but starting from a known item id (preferred for new data).
function CraftRoute.GetPriceById(itemId)
	return CraftRoute.GetPriceFor(nil, itemId)
end

--------------------------------------------------------------------------
-- Skill-up probability model
--------------------------------------------------------------------------

-- chance of a skill-up on a single craft attempt at current skill `s`,
-- for a recipe with thresholds orange/yellow/green/grey
local function skillup_chance(s, orange, yellow, green, grey)
	if s < orange or s >= grey then
		return 0
	elseif s < yellow then
		return 1
	elseif s < green then
		return (grey - s) / (grey - yellow)
	else
		return 0.5 * (grey - s) / (grey - green)
	end
end

--------------------------------------------------------------------------
-- Reagent cost calculation (with make-vs-buy substitution)
--------------------------------------------------------------------------

-- Some reagents are themselves craftable within the same profession (e.g.
-- Engineering's Bronze Tube is both a skill-up recipe AND a reagent used by
-- later recipes). Buying every reagent from the AH ignores that you can
-- often make an intermediate item cheaper than its market price. This
-- builds a name -> recipe lookup once per profession so reagent costing can
-- recursively check "would crafting this myself be cheaper than buying it."
local function build_recipe_lookup(recipes)
	local lookup = {}
	for i = 1, getn(recipes) do
		lookup[strlower(recipes[i].name)] = recipes[i]
	end
	return lookup
end

-- Lazily-built lookup spanning EVERY loaded profession's recipes (name ->
-- recipe), used as a fallback when an item isn't craftable within the
-- current profession -- e.g. Enchanting's Runed Arcanite Rod needs
-- Blacksmithing's Arcanite Rod as a reagent. Same-profession matches are
-- always preferred (checked first); this only kicks in when nothing local
-- has that name. Rebuilt if CraftRoute_Data's profession count changes
-- (cheap sanity check against stale data across reloads/dev iteration).
--
-- IMPORTANT: only ever consult this through CROSS_PROFESSION_ALLOWED (see
-- below) -- this lookup on its own has no concept of which profession the
-- player is actually training, so treating every name-match here as "the
-- player could just craft this instead" is wrong. Real bug this caused:
-- Blacksmithing weapon recipes needing "Light Leather" (a grip-wrap
-- reagent, stored as a bare itemId at the time) matched Leatherworking's
-- own "Light Leather" tanning recipe here and "crafted" it from Ruined
-- Leather Scraps -- something a Blacksmith literally cannot do. This
-- lookup is only safe to use for a small, explicit, hand-verified list of
-- items that are genuinely always sourced via one specific other
-- profession regardless of what you're leveling (Arcanite Rod is the only
-- known case: it's essentially never listed on the AH, so pricing Runed
-- Arcanite Rod requires resolving Blacksmithing's own craft cost for it).
local CROSS_PROFESSION_ALLOWED = {
	["arcanite rod"] = true,
}
local globalRecipeLookup = nil
local globalRecipeLookupProfCount = nil
local function get_global_recipe_lookup()
	local profCount = 0
	for _ in pairs(CraftRoute_Data) do profCount = profCount + 1 end
	if not globalRecipeLookup or globalRecipeLookupProfCount ~= profCount then
		globalRecipeLookup = {}
		for _, recipes in pairs(CraftRoute_Data) do
			for i = 1, getn(recipes) do
				local key = strlower(recipes[i].name)
				if not globalRecipeLookup[key] then
					globalRecipeLookup[key] = recipes[i]
				end
			end
		end
		globalRecipeLookupProfCount = profCount
	end
	return globalRecipeLookup
end

-- A recipe is relevant for skill-up starting at `startSkill` if it can still
-- award skill past that point -- i.e. it isn't already entirely grey. No
-- startSkill (nil) means "everything is relevant", matching a plain 1-300 scan.
local function is_relevant_for_start(recipe, startSkill)
	if not startSkill then return true end
	return recipe.grey > startSkill
end

-- Every reagent name reachable from a profession's skill-relevant recipes,
-- expanded recursively through substitution chains: if a relevant recipe
-- needs an item that's itself craftable (in this profession or any other,
-- same fallback used by get_item_cost), that recipe's own reagents count as
-- reachable too, EVEN IF that sub-recipe is itself entirely grey for this
-- player -- it's still worth having material prices for. Note this doesn't
-- extend to scroll/learn-cost scanning (CraftRoute.StartRecipeScan) -- that
-- scans every scroll regardless of skill range, since prefix-based recipe
-- scanning pages through all matching results either way, so filtering
-- wouldn't save any actual scan time there.
-- Returns a set: {[lowercase reagent name] = true, ...}
-- WoW lets you right-click 3 of a "Lesser" enchanting essence on the AH into
-- 1 "Greater" essence -- one-way, no converting back. Treated as an alternate
-- acquisition path for these 5 Greater essences, same idea as make-vs-buy
-- substitution against a recipe, except there's no recipe (no skill-up, no
-- orange/yellow/green/grey) -- it's a flat conversion, so it lives here as
-- its own table rather than in any data_<profession>.lua file. Defined
-- before GetReachableMaterialNames (which also uses it) rather than down by
-- get_item_cost_detailed, since a local referenced before its definition in
-- this file silently resolves as a global -- see the DEVNOTES entry on this.
local ESSENCE_CONVERSIONS = {
	["greater astral essence"] = "Lesser Astral Essence",
	["greater eternal essence"] = "Lesser Eternal Essence",
	["greater magic essence"] = "Lesser Magic Essence",
	["greater mystic essence"] = "Lesser Mystic Essence",
	["greater nether essence"] = "Lesser Nether Essence",
}
local ESSENCE_CONVERSION_RATIO = 3

-- Reachable materials = everything a fresh scan needs to cover: every
-- reagent (and sub-reagent) of every recipe still relevant from startSkill
-- onward, plus -- for any reachable Greater essence -- its Lesser
-- counterpart, since that's a real alternate way to obtain it that the cost
-- calculation will actually consider (see ESSENCE_CONVERSIONS above). Skill
-- relevance is inherited for free: the Lesser essence only gets added when
-- its Greater counterpart was itself found reachable at this startSkill.
function CraftRoute.GetReachableMaterialNames(professionKey, startSkill, checkAH)
	local recipes = CraftRoute_Data[professionKey]
	if not recipes then return {} end

	local reachable = {}
	local queue = {}

	for i = 1, getn(recipes) do
		local r = recipes[i]
		if is_relevant_for_start(r, startSkill) and not r.excludeFromMakeVsBuy then
			for j = 1, getn(r.reagents) do
				local name = CraftRoute.ResolveReagent(r.reagents[j])
				if name then
					local n = strlower(name)
					if not reachable[n] then
						reachable[n] = true
						table.insert(queue, n)
					end
				end
			end
			if checkAH and r.name and not r.excluded then
				local n = strlower(r.name)
				if not reachable[n] then
					reachable[n] = true
					table.insert(queue, n)
				end
			end
		end
	end

	local globalLookup = get_global_recipe_lookup()
	local qi = 1
	while qi <= getn(queue) do
		local name = queue[qi]
		qi = qi + 1
		local subRecipe = CROSS_PROFESSION_ALLOWED[name] and globalLookup[name]
		if subRecipe and subRecipe.excludeFromMakeVsBuy then
			subRecipe = nil
		end
		if subRecipe then
			for j = 1, getn(subRecipe.reagents) do
				local srName = CraftRoute.ResolveReagent(subRecipe.reagents[j])
				if srName then
					local n = strlower(srName)
					if not reachable[n] then
						reachable[n] = true
						table.insert(queue, n)
					end
				end
			end
		end
	end

	-- Essence companions: for every reachable Greater essence, also scan its
	-- Lesser counterpart -- it's iterated separately from the main queue
	-- above (rather than folded into it) since ESSENCE_CONVERSIONS keys are
	-- Greater-essence names, not reagents, and don't need the sub-recipe
	-- expansion the main queue does.
	for n, _ in pairs(reachable) do
		local lesserName = ESSENCE_CONVERSIONS[n]
		if lesserName then
			reachable[strlower(lesserName)] = true
		end
	end

	-- Vendor-preferred materials are never bought from the AH (see
	-- GetPriceFor/depletion_aware_reagent_cost_detailed/TrueShoppingCost),
	-- so there's no reason to spend scan time on them -- removed from every
	-- profession's scan set here rather than filtered later, so both the
	-- per-profession scan button and Scan All (which just loops this same
	-- function per profession) skip them automatically.
	for n, _ in pairs(VENDOR_PREFERRED_MATERIALS) do
		reachable[n] = nil
	end

	return reachable
end

-- get_item_cost and get_item_cost_detailed are mutually recursive (detailed
-- calls the plain one for sub-costs and memoization; the plain one calls
-- detailed to do the actual work) -- forward-declared together so each
-- reference resolves to the shared local/upvalue regardless of definition
-- order, rather than one half accidentally compiling as a global lookup.
local get_item_cost, get_item_cost_detailed

-- Returns the cheapest way to obtain one unit of an item, AND how that price
-- was reached -- off the AH, crafted from its own reagents, or (for the 5
-- Greater essences) converted from Lesser essences -- so callers that need to
-- act on the decision (shopping list expansion, depletion tracking) don't
-- have to re-derive it separately and risk disagreeing with this function.
-- `visiting` guards against a circular recipe chain in bad data.
-- Returns: cost, source ("ah"|"craft"|"convert"|nil), detail (subRecipe
-- table for "craft", lesser essence name for "convert", nil otherwise),
-- missingName (only set if cost is nil)
get_item_cost_detailed = function(name, itemId, recipeLookup, cache, visiting)
	local key = name and strlower(name) or ("#" .. tostring(itemId))
	local ahPrice = CraftRoute.GetPriceFor(name, itemId)
	local craftCost, craftSubRecipe = nil, nil
	local conversionCost, conversionLesserName = nil, nil

	if name and not visiting[key] then
		local subRecipe = recipeLookup[strlower(name)]
		local subRecipeLookup = recipeLookup
		if not subRecipe and CROSS_PROFESSION_ALLOWED[strlower(name)] then
			subRecipe = get_global_recipe_lookup()[strlower(name)]
			subRecipeLookup = get_global_recipe_lookup()
		end
		if subRecipe and subRecipe.excludeFromMakeVsBuy then
			-- This item IS craftable, but deliberately not offered as a
			-- make-vs-buy substitute for some other recipe's reagent need
			-- (e.g. Light Leather from Ruined Leather Scraps -- technically
			-- cheaper by the numbers, but Ruined Leather Scraps isn't
			-- realistically available on the AH in the bulk quantities a
			-- full leveling route needs, and a low-value near-vendor-trash
			-- item like this isn't worth the trouble either way). Still
			-- fully usable as CraftRoute's own skill-up recipe choice --
			-- this only blocks it from being silently substituted in when
			-- SOMETHING ELSE needs it as a reagent.
			subRecipe = nil
		end
		if subRecipe then
			visiting[key] = true
			local sum, ok = 0, true
			for i = 1, getn(subRecipe.reagents) do
				local sr = subRecipe.reagents[i]
				local srName, srItemId = CraftRoute.ResolveReagent(sr)
				local srCost, srMissing = get_item_cost(srName, srItemId, subRecipeLookup, cache, visiting)
				if not srCost then
					ok = false
					break
				end
				sum = sum + srCost * sr.qty
			end
			visiting[key] = nil
			if ok then
				craftCost = sum
				craftSubRecipe = subRecipe
			end
		end

		local lesserName = ESSENCE_CONVERSIONS[strlower(name)]
		if lesserName then
			visiting[key] = true
			local lesserUnitCost = get_item_cost(lesserName, nil, recipeLookup, cache, visiting)
			visiting[key] = nil
			if lesserUnitCost then
				conversionCost = lesserUnitCost * ESSENCE_CONVERSION_RATIO
				conversionLesserName = lesserName
			end
		end
	end

	local best, source, detail = nil, nil, nil
	if ahPrice and (not best or ahPrice < best) then
		best, source, detail = ahPrice, "ah", nil
	end
	if craftCost and (not best or craftCost < best) then
		best, source, detail = craftCost, "craft", craftSubRecipe
	end
	if conversionCost and (not best or conversionCost < best) then
		best, source, detail = conversionCost, "convert", conversionLesserName
	end

	if not best then
		return nil, nil, nil, name or ("Item #" .. tostring(itemId))
	end
	return best, source, detail, nil
end

-- Thin wrapper over get_item_cost_detailed for callers that only need the
-- number -- also where the memoization cache actually lives, since the
-- detailed version is called recursively (including by itself, for craft/
-- convert sub-costs) and re-deriving cached items every time would be
-- wasteful.
-- Returns: cost (or nil if truly unobtainable), missingName (if nil)
get_item_cost = function(name, itemId, recipeLookup, cache, visiting)
	local key = name and strlower(name) or ("#" .. tostring(itemId))
	local cached = cache[key]
	if cached ~= nil then
		if cached == false then
			return nil, name or ("Item #" .. tostring(itemId))
		end
		return cached, nil
	end

	local best, _, _, missing = get_item_cost_detailed(name, itemId, recipeLookup, cache, visiting)

	if not best then
		cache[key] = false
		return nil, missing
	end
	cache[key] = best
	return best, nil
end

-- Returns total copper cost of one craft (using make-vs-buy substitution for
-- any reagent that's itself craftable), or nil (and the display name of the
-- first reagent with no price data) if any reagent hasn't been scanned yet.
local function recipe_cost(recipe, recipeLookup, cache)
	local total = 0
	for i = 1, getn(recipe.reagents) do
		local r = recipe.reagents[i]
		local name, itemId = CraftRoute.ResolveReagent(r)
		local price, missing = get_item_cost(name, itemId, recipeLookup, cache, {})
		if not price then
			return nil, missing
		end
		total = total + price * r.qty
	end
	return total
end

-- Depletion-aware cost for ONE reagent need of `qty` units: walks
-- CraftRoute's own real AH listings in price order (same mechanism the
-- shopping list already uses via OrderBookCost) for whatever's actually
-- covered, and falls back to the existing best-price logic (which also
-- checks aux/vendor/make-vs-buy) for whatever isn't -- either because
-- CraftRoute hasn't scanned this item specifically (not necessarily
-- scarce, just unscanned by us), or because the AH genuinely doesn't have
-- enough listed. Capped against the flat fallback price so this can never
-- come out worse than the old always-cheapest-listing assumption.
-- How much more expensive to treat reagent units beyond what's actually
-- listed on the AH right now -- a heuristic, not a measured number, since
-- there's no way to know the real price of buying more than what's
-- currently available. Without some penalty here, "shortfall" units would
-- just get priced the same as genuinely abundant ones (via the flat
-- fallback), which defeats the entire point of this function.
local SCARCITY_PENALTY_MULTIPLIER = 3

-- Same decision as depletion_aware_reagent_cost, but also reports which AH
-- pool(s) the winning price actually draws from -- needed so pathConsumed
-- can track the pool that's really being depleted. Without this, converting
-- Greater Eternal Essence from Lesser would still (wrongly) mark the
-- GREATER essence's listings as consumed, understating how cheap later
-- Greater-essence needs look and overstating how cheap later Lesser-essence
-- needs look.
--
-- Compares THREE depletion-aware alternatives for obtaining `qty` units:
-- buying off the AH directly, essence-converting (if applicable), and
-- CRAFTING from the item's own recipe (if it has one in this profession,
-- or in CROSS_PROFESSION_ALLOWED). The craft alternative recurses into
-- each of ITS OWN reagents with the same pathConsumed, so a multi-level
-- craft chain (e.g. Engineering's Hi-Explosive Bomb needs Mithril Casing
-- needs Mithril Bar) gets real AH depletion applied at every level, not
-- just the top one. Before this, the craft option here was only a FLAT,
-- non-depletion per-unit price folded into the shortfall penalty -- never
-- compared against the real depletion-aware buy cost for the full
-- quantity needed, which could make "buy" look artificially cheap when
-- only a couple of cheap listings existed for a much larger need.
--
-- Each candidate also tracks whether it's genuinely ACHIEVABLE -- real
-- supply actually exists (AH still has something left, or a vendor sells
-- it -- vendors never run dry) -- versus merely "prices at a scarcity
-- penalty but doesn't actually exist in that quantity." The scarcity
-- penalty alone was found to not be a strong enough deterrent: a recipe
-- whose other reagents are cheap enough can still look "cheapest" even
-- at 3x markup on a shortfall, no matter how large that shortfall gets,
-- which let a real report recommend buying 128 of something with only
-- 34 ever listed. Once a candidate has ZERO real remaining supply (AH
-- exhausted AND no vendor price), it's marked unachievable and excluded
-- from consideration; only cheapest-among-ACHIEVABLE wins. If nothing
-- achievable exists at all, this returns nil -- genuinely infeasible,
-- not just expensive -- which makes the calling recipe ineligible
-- (recipe_selection_cost already treats a nil reagent cost this way),
-- so CalculatePath's greedy loop naturally switches to the next-best
-- alternative for the rest of that skill range, rather than committing
-- to a route that can't actually be completed. This does mean the very
-- last transitional craft, right at the boundary where real supply runs
-- out mid-craft, can still show a small penalty-priced overage (at most
-- one craft's worth) -- full whole-craft quantization wasn't worth the
-- added complexity for that edge.
-- `visiting` guards against a cyclic recipe chain (shouldn't exist in
-- real data, but a genuine infinite loop here would hang the client).
-- Returns: cost (or nil), consumption ({{name=, qty=}, ...} or nil),
-- achievable (bool -- callers that only want cost/consumption can safely
-- ignore this third value)
local function depletion_aware_reagent_cost_detailed(name, itemId, qty, recipeLookup, cache, pathConsumed, visiting)
	visiting = visiting or {}
	local fallbackUnitPrice = get_item_cost(name, itemId, recipeLookup, cache, {})
	if not fallbackUnitPrice then
		return nil, nil
	end
	if not name or not CraftRoute.OrderBookCost then
		return fallbackUnitPrice * qty, {{name = name, qty = qty}}, true
	end

	if VENDOR_PREFERRED_MATERIALS[strlower(name)] then
		-- Vendor supply is unlimited and the price never fluctuates -- no
		-- AH order-book walk, no depletion/pathConsumed tracking needed,
		-- no scarcity penalty. Just qty * vendor price.
		return fallbackUnitPrice * qty, {{name = name, qty = qty}}, true
	end

	local key = strlower(name)
	local alreadyConsumed = (pathConsumed and pathConsumed[key]) or 0
	local ahCost, covered, shortfall = CraftRoute.OrderBookCost(name, qty, alreadyConsumed)
	local vendorPrice = CraftRoute_VendorPrices and CraftRoute_VendorPrices[key]
	local shortfallUnitPrice = fallbackUnitPrice * SCARCITY_PENALTY_MULTIPLIER
	local directCost = ahCost + shortfall * shortfallUnitPrice
	-- Achievable as long as SOME real supply remains (even partial -- lets
	-- the algorithm ride a scarce recipe right up to the edge of real
	-- supply, maximizing how much of it actually gets used, matching
	-- "craft the max we can with what's really there") or a vendor exists.
	local directAchievable = (shortfall == 0) or (covered > 0) or (vendorPrice ~= nil)

	local candidates = {{cost = directCost, consumption = {{name = name, qty = qty}}, achievable = directAchievable}}

	if not visiting[key] then
		local lesserName = ESSENCE_CONVERSIONS[key]
		if lesserName then
			visiting[key] = true
			local convertedCost, convertedConsumption, convertedAchievable = depletion_aware_reagent_cost_detailed(
				lesserName, nil, qty * ESSENCE_CONVERSION_RATIO, recipeLookup, cache, pathConsumed, visiting)
			visiting[key] = nil
			if convertedCost then
				table.insert(candidates, {cost = convertedCost, consumption = convertedConsumption, achievable = convertedAchievable})
			end
		end

		local craftRecipe = recipeLookup[key]
		if not craftRecipe and CROSS_PROFESSION_ALLOWED[key] then
			craftRecipe = get_global_recipe_lookup()[key]
		end
		if craftRecipe and craftRecipe.excludeFromMakeVsBuy then
			craftRecipe = nil
		end
		if craftRecipe then
			visiting[key] = true
			local total, ok, consumption, allAchievable = 0, true, {}, true
			for i = 1, getn(craftRecipe.reagents) do
				local cr = craftRecipe.reagents[i]
				local crName, crItemId = CraftRoute.ResolveReagent(cr)
				local c, cons, ach = depletion_aware_reagent_cost_detailed(
					crName, crItemId, cr.qty * qty, recipeLookup, cache, pathConsumed, visiting)
				if c == nil then
					ok = false
					break
				end
				total = total + c
				if not ach then
					allAchievable = false
				end
				for j = 1, getn(cons) do
					table.insert(consumption, cons[j])
				end
			end
			visiting[key] = nil
			if ok then
				table.insert(candidates, {cost = total, consumption = consumption, achievable = allAchievable})
			end
		end
	end

	-- Cheapest among genuinely achievable candidates wins. If nothing is
	-- achievable, this reagent is out of real supply everywhere it could
	-- plausibly come from -- return nil (infeasible), not a penalized
	-- guess, so the caller can treat the recipe needing it as unusable.
	local best = nil
	for i = 1, getn(candidates) do
		local c = candidates[i]
		if c.achievable and (not best or c.cost < best.cost) then
			best = c
		end
	end

	if not best then
		return nil, nil, false
	end
	return best.cost, best.consumption, true
end

-- Thin wrapper for callers (recipe_selection_cost) that only need the price,
-- not the consumption breakdown.
local function depletion_aware_reagent_cost(name, itemId, qty, recipeLookup, cache, pathConsumed)
	local cost = depletion_aware_reagent_cost_detailed(name, itemId, qty, recipeLookup, cache, pathConsumed)
	return cost
end

-- Selection-time cost estimate for a recipe: prices exactly one craft's
-- worth of each reagent against real, live AH depletion (see
-- depletion_aware_reagent_cost above), offset by pathConsumed -- everything
-- already committed to earlier, already-finalized steps in this same path.
-- Called fresh at every skill point (see recompute_costs in CalculatePath),
-- so this always reflects an accurate marginal price for "the next craft
-- right now," not a speculative future-usage estimate. This is what makes
-- selection genuinely path-wide: a reagent shared by many different
-- recipes across the whole profession correctly gets more expensive for
-- later candidates once earlier, already-chosen steps have used up the
-- cheap supply -- not just within one recipe's own repeated use.
local function recipe_selection_cost(recipe, recipeLookup, cache, pathConsumed)
	local total = 0
	for i = 1, getn(recipe.reagents) do
		local r = recipe.reagents[i]
		local name, itemId = CraftRoute.ResolveReagent(r)
		local cost = depletion_aware_reagent_cost(name, itemId, r.qty, recipeLookup, cache, pathConsumed)
		if not cost then
			return nil, name or ("Item #" .. tostring(itemId))
		end
		total = total + cost
	end
	return total
end

-- Resolves the actual one-time cost to learn a recipe. Checks, in order of
-- reliability: a scanned market price for its "scroll" item (Plans:/Pattern:/
-- Schematic:/etc, via scan.lua's StartRecipeScan), a fixed vendor price
-- (data_vendorprices.lua) if this scroll happens to be vendor-sold, and
-- falls back to the static learnCost estimate/confirmed-price baked into the
-- recipe data if neither is available. If both a scan and a vendor price
-- exist, uses whichever is cheaper (a vendor never runs out, so an inflated
-- AH price for a vendor-sold scroll is never worth paying).
function CraftRoute.GetRecipeLearnCost(recipe)
	if recipe.scrollName then
		local scanned = CraftRoute.ScannedUnitPrice and CraftRoute.ScannedUnitPrice(recipe.scrollName)
		local vendorPrice = CraftRoute_VendorPrices and CraftRoute_VendorPrices[strlower(recipe.scrollName)]
		if scanned and vendorPrice then
			return math.min(scanned, vendorPrice), "scanned"
		elseif vendorPrice then
			return vendorPrice, "confirmed"
		elseif scanned then
			return scanned, "scanned"
		elseif recipe.requiresScan then
			-- Genuinely hard to acquire any other way -- no vendor, no
			-- static guess. A guessed price could recommend something the
			-- player literally can't get if it isn't really on the AH.
			-- Only usable once a real Recipes scan confirms it's there.
			return nil, "unpriced"
		end
	end
	return recipe.learnCost or 0, recipe.learnCostConfidence or "estimated"
end

--------------------------------------------------------------------------
-- Path calculation
--------------------------------------------------------------------------

-- Computes the cheapest 1->300 path for a profession.
-- Each recipe's one-time learn cost (learnCost field: trainer fee or scroll
-- price) is added exactly once, the first time that recipe is ever selected
-- -- never again after that, matching how learning actually works in-game.
-- Known simplification: the greedy per-skill-point recipe choice is based on
-- reagent cost alone (not learn cost), so it won't occasionally trade a tiny
-- reagent saving for a recipe that costs more to unlock than it saves. Since
-- learn costs are typically small relative to reagent costs accumulated over
-- many crafts, this is a minor approximation, not a major one.
-- Returns:
--   total_cost (copper, includes learn costs),
--   steps: ordered list of {name=, fromSkill=, toSkill=, expectedCrafts=, unitCost=, subtotal=, learnCost=},
--   missing: set of reagent names that need to be scanned (no price data)
--   maxSkillReached: highest skill actually reachable with currently-priced recipes
--   stuckAt: skill level where the path got stuck, if any
--   total_learn_cost (copper, sum of all one-time recipe costs paid)
function CraftRoute.CalculatePath(professionKey, targetSkill, startSkill)
	targetSkill = targetSkill or 300
	startSkill = startSkill or 1
	local recipes = CraftRoute_Data[professionKey]
	if not recipes then
		return nil, nil, nil, 0, "No recipe data loaded for '" .. professionKey .. "'"
	end
	if startSkill >= targetSkill then
		return nil, nil, nil, 0, "Starting skill (" .. startSkill .. ") must be lower than target skill (" .. targetSkill .. ")"
	end

	-- Learn costs and unscanned-scroll exclusions aren't path-dependent
	-- (a recipe's one-time learn price doesn't change based on how much of
	-- its reagents have been bought elsewhere in this same path), so these
	-- are still safe to compute once, up front.
	local costs, missingReagent = {}, {}
	local missingSet = {}
	local recipeLearnCost, recipeLearnConfidence = {}, {}
	local recipeLookup = build_recipe_lookup(recipes)
	local costCache = {}
	local recipeUnusable = {}
	for i = 1, getn(recipes) do
		if recipes[i].excluded then
			recipeUnusable[i] = true
		end
		recipeLearnCost[i], recipeLearnConfidence[i] = CraftRoute.GetRecipeLearnCost(recipes[i])
		if not recipeLearnCost[i] then
			-- requiresScan and never scanned -- can't safely guess a price,
			-- so this recipe is entirely unusable until scanned.
			recipeUnusable[i] = true
			recipeLearnCost[i] = 0
			if recipes[i].scrollName then
				missingSet[recipes[i].scrollName] = true
			end
		end
	end

	-- Reagent costs ARE path-dependent -- depletion_aware_reagent_cost prices
	-- against whatever's already been committed to earlier, already-finalized
	-- steps (pathConsumed, below), so this needs to be called fresh at each
	-- skill point rather than computed once and cached for the whole run.
	local pathConsumed = {}
	local function recompute_costs()
		for i = 1, getn(recipes) do
			if recipeUnusable[i] then
				costs[i] = nil
			else
				local c, missing = recipe_selection_cost(recipes[i], recipeLookup, costCache, pathConsumed)
				costs[i] = c
				if missing then
					missingSet[missing] = true
				end
			end
		end
	end
	recompute_costs()

	local total_cost = 0
	local total_learn_cost = 0
	local any_learn_cost_estimated = false
	local steps = {}
	local current_step = nil -- {recipeIndex, fromSkill, expectedCrafts, unitCost}
	local learned = {}
	local skill = startSkill
	local stuckAt = nil

	-- A switch away from whatever recipe you're currently using only happens
	-- if the alternative is at least this much cheaper (10%). Without this,
	-- the greedy algorithm chases every momentary price dip and switches
	-- back and forth for savings too small to be worth the real-world
	-- hassle of buying different materials -- a pattern that shows up as
	-- short-lived "flicker" segments sandwiched between two uses of the
	-- same recipe. This stays fully dynamic: it's evaluated fresh against
	-- live prices every time you run the calculation, it just refuses to
	-- switch for noise-level savings.
	local SWITCH_THRESHOLD = 0.90

	while skill < targetSkill do
		recompute_costs()

		-- Find the best usable recipe at this skill level. "Best" weighs in
		-- the one-time learn cost too (amortized over however much of the
		-- recipe's remaining skill range is left), not just reagent cost --
		-- a recipe that's expensive to unlock can still be the right choice
		-- if it saves enough over the stretch you'd actually use it for.
		-- Already-learned recipes have zero amortized term since the cost is
		-- sunk. This amortization is a heuristic (it assumes you'll use the
		-- recipe all the way to its grey point, which is usually close to
		-- true but not guaranteed), not a full lookahead optimizer.
		local best_idx, best_expected_cost, best_chance = nil, nil, nil
		local best_effective_cost = nil
		local current_idx = current_step and current_step.recipeIndex or nil
		local current_effective_cost, current_expected_cost, current_chance = nil, nil, nil

		for i = 1, getn(recipes) do
			local r = recipes[i]
			if costs[i] then
				local chance = skillup_chance(skill, r.orange, r.yellow, r.green, r.grey)
				if chance > 0 then
					local expected_cost = costs[i] / chance
					local effective_cost = expected_cost
					if not learned[i] then
						local remaining = r.grey - skill
						if remaining > 0 then
							effective_cost = expected_cost + (recipeLearnCost[i] / remaining)
						end
					end
					if i == current_idx then
						current_effective_cost, current_expected_cost, current_chance = effective_cost, expected_cost, chance
					end
					if not best_effective_cost or effective_cost < best_effective_cost then
						best_idx, best_expected_cost, best_chance = i, expected_cost, chance
						best_effective_cost = effective_cost
					end
				end
			end
		end

		-- Stick with the current recipe unless something else is clearly better.
		if current_effective_cost and best_idx ~= current_idx
			and best_effective_cost >= current_effective_cost * SWITCH_THRESHOLD then
			best_idx, best_expected_cost, best_chance, best_effective_cost =
				current_idx, current_expected_cost, current_chance, current_effective_cost
		end

		if not best_idx then
			stuckAt = skill
			break
		end

		-- Commit this skill point's reagent usage to the path-wide tracker
		-- BEFORE moving on, so the next iteration's recompute_costs() sees
		-- accurate remaining AH supply -- this is the actual fix: earlier
		-- steps' consumption now genuinely affects what later steps see as
		-- available, instead of every skill point independently assuming
		-- the cheapest listings are untouched.
		local craftsThisPoint = 1 / best_chance
		local chosenRecipe = recipes[best_idx]
		for i = 1, getn(chosenRecipe.reagents) do
			local r = chosenRecipe.reagents[i]
			local rname, ritemId = CraftRoute.ResolveReagent(r)
			if rname then
				-- Re-run the same direct-vs-convert decision used for pricing
				-- (state hasn't changed since recompute_costs() ran this same
				-- iteration), so whatever's actually committed to pathConsumed
				-- matches whatever the price just charged for.
				local _, consumption = depletion_aware_reagent_cost_detailed(
					rname, ritemId, r.qty * craftsThisPoint, recipeLookup, costCache, pathConsumed)
				if consumption then
					for c = 1, getn(consumption) do
						local centry = consumption[c]
						local ckey = strlower(centry.name)
						pathConsumed[ckey] = (pathConsumed[ckey] or 0) + centry.qty
					end
				else
					local key = strlower(rname)
					pathConsumed[key] = (pathConsumed[key] or 0) + r.qty * craftsThisPoint
				end
			end
		end

		-- one-time cost to learn this recipe (trainer fee or scroll), charged
		-- only the first time it's ever selected across the whole path
		local addedLearnCost = 0
		local learnCostConfidence = recipeLearnConfidence[best_idx]
		if not learned[best_idx] then
			learned[best_idx] = true
			addedLearnCost = recipeLearnCost[best_idx]
			total_learn_cost = total_learn_cost + addedLearnCost
			if learnCostConfidence ~= "confirmed" and learnCostConfidence ~= "scanned" then
				any_learn_cost_estimated = true
			end
		end

		if current_step and current_step.recipeIndex == best_idx then
			current_step.expectedCrafts = current_step.expectedCrafts + (1 / best_chance)
			current_step.toSkill = skill + 1
			current_step.subtotal = current_step.subtotal + best_expected_cost + addedLearnCost
			current_step.learnCost = (current_step.learnCost or 0) + addedLearnCost
		else
			if current_step then
				table.insert(steps, current_step)
			end
			current_step = {
				recipeIndex = best_idx,
				name = recipes[best_idx].name,
				fromSkill = skill,
				toSkill = skill + 1,
				expectedCrafts = 1 / best_chance,
				unitCost = costs[best_idx],
				subtotal = best_expected_cost + addedLearnCost,
				learnCost = addedLearnCost,
				learnCostConfidence = learnCostConfidence,
				scrollName = recipes[best_idx].scrollName,
				questObtained = recipes[best_idx].questObtained,
				bossObtained = recipes[best_idx].bossObtained,
			}
		end

		total_cost = total_cost + best_expected_cost + addedLearnCost
		skill = skill + 1
	end

	if current_step then
		table.insert(steps, current_step)
	end

	local missingList = {}
	for name in pairs(missingSet) do
		table.insert(missingList, name)
	end
	table.sort(missingList)

	-- Post-process: three passes that can feed each other, so they run in
	-- a loop until a full cycle changes nothing (bounded, as a safety net
	-- against any unforeseen oscillation -- in practice this should always
	-- converge quickly, since trimming only ever shrinks or removes steps,
	-- never grows the route, so there's a hard ceiling on how many times
	-- anything can meaningfully change).
	--
	-- 1. ApplyDownstreamExtensions: check whether extending a recipe
	--    further than its raw per-point cost would suggest (into its own
	--    green/grey zone) pays off once you account for a KNOWN later
	--    reagent need for its own output. Crafting always succeeds
	--    regardless of skill-up chance -- grey just means no more skill
	--    gained, not that the craft fails -- so "extra" crafts past a
	--    recipe's normal stopping point still produce real, usable items
	--    at flat reagent cost. If a later step needs that item and would
	--    otherwise pay to craft/buy it fresh, stretching the earlier run
	--    to cover that demand can beat switching to a cheaper-per-point
	--    recipe and paying for a separate batch later.
	-- 2. ApplyPureProductionExtensions: catches reagent shortfalls pass 1
	--    couldn't reach because the need falls beyond the producing
	--    recipe's own grey point -- see its own comment for the full
	--    reasoning. Always prices what it adds as flat/zero-skill.
	-- 3. ApplyTrimming: pass 2's "zero-skill" assumption is only true if
	--    the recipe had genuinely reached its own grey already -- if it
	--    hadn't, those flat-added units still had real skill-up chance,
	--    unconditionally free since the units were being made anyway.
	--    This collects that free skill and shrinks/removes whatever
	--    step(s) immediately follow to the extent it's no longer needed.
	--    Trimming a step can itself create a NEW reagent shortfall (if
	--    the trimmed step was also supplying something later) -- that's
	--    exactly what sends this back through passes 1-2 again.
	if not stuckAt and getn(steps) > 1 then
		local MAX_ITERATIONS = 10
		local iteration = 0
		local changed = true
		while changed and iteration < MAX_ITERATIONS do
			changed = false
			iteration = iteration + 1

			local newSteps, extTotalCost, improved = CraftRoute.ApplyDownstreamExtensions(
				professionKey, steps, total_cost, targetSkill, recipeLookup, costCache)
			if improved then
				steps = newSteps
				total_cost = extTotalCost
				changed = true
			end

			if getn(steps) > 1 then
				local newStepsP, prodTotalCost, prodImproved, extensions = CraftRoute.ApplyPureProductionExtensions(
					professionKey, steps, total_cost, recipeLookup, costCache)
				if prodImproved then
					steps = newStepsP
					total_cost = prodTotalCost
					changed = true
				end

				if extensions and getn(extensions) > 0 then
					local trimmedSteps, trimTotalCost, trimmed = CraftRoute.ApplyTrimming(
						professionKey, steps, extensions, total_cost, recipeLookup, costCache)
					if trimmed then
						steps = trimmedSteps
						total_cost = trimTotalCost
						changed = true
					end
				end
			end
		end
	end

	-- Post-process: some professions need a permanent tool (Arclight
	-- Spanner, Gyromatic Micro-Adjustor) that's ALSO one of the profession's
	-- own leveling recipes. That creates a real "craft it now, getting a
	-- skill point AND the tool at once, vs. use a cheaper recipe here and
	-- buy the tool separately" decision -- exactly the kind of question a
	-- player can't answer just by looking at reagent prices alone. This
	-- swaps in one single-point craft of the tool at its own orange
	-- threshold (where it always succeeds) if that beats paying for both a
	-- cheaper recipe AND a separate tool purchase.
	if not stuckAt then
		local newSteps2, toolTotalCost, toolImproved = CraftRoute.ApplyToolAcquisition(
			professionKey, steps, total_cost, startSkill, targetSkill, recipeLookup, costCache)
		if toolImproved then
			steps = newSteps2
			total_cost = toolTotalCost
		end
	end

	-- Enchanting rods (Copper/Silver/Golden/Truesilver) are required
	-- equipment to cast most enchants past a certain skill, not just
	-- another cost-optimized skill-up choice -- unconditionally inserted
	-- if not already naturally present in the path. See
	-- ApplyMandatoryRods's own comment for why Arcanite Rod is excluded.
	if not stuckAt then
		local newSteps3, rodsInserted = CraftRoute.ApplyMandatoryRods(
			professionKey, steps, startSkill, targetSkill, recipeLookup, costCache)
		if rodsInserted then
			steps = newSteps3
		end
	end

	-- total_learn_cost was accumulated once during the main loop above and
	-- never touched by any post-processing pass -- fine for
	-- ApplyDownstreamExtensions/ApplyPureProductionExtensions/
	-- ApplyToolAcquisition/ApplyMandatoryRods, since none of them can ever
	-- fully remove a step's recipe from the route. ApplyTrimming can, so
	-- that stale accumulator could now overstate the true total if a
	-- learn-cost-bearing step gets trimmed away entirely. Recomputed fresh
	-- from the final step list instead of trusting the earlier running
	-- total.
	total_learn_cost = 0
	for i = 1, getn(steps) do
		total_learn_cost = total_learn_cost + (steps[i].learnCost or 0)
	end

	return total_cost, steps, missingList, skill, stuckAt, total_learn_cost, any_learn_cost_estimated
end

-- Sums a real, priced total for a full shopping list (make-vs-buy and
-- supply-crediting already baked in via ShoppingList itself). Used to make
-- an apples-to-apples true-cost comparison between two candidate step
-- lists. Prices each reagent's full aggregated need against real listing
-- depletion (OrderBookCost) rather than a flat per-unit price times
-- quantity -- the same principle as the main path calculation: buying 40
-- of something isn't 40x the cheapest listing's price if only 10 are
-- actually available at that price.
local function shopping_list_true_cost(professionKey, steps)
	local totals, order = CraftRoute.ShoppingList(professionKey, steps)
	local total = 0
	for i = 1, getn(order) do
		local name = order[i]
		local qty = totals[name]
		if CraftRoute.OrderBookCost then
			local ahCost, covered, shortfall = CraftRoute.OrderBookCost(name, qty)
			total = total + ahCost
			if shortfall > 0 then
				local fallbackUnitPrice = CraftRoute.GetPriceFor(name, nil)
				if fallbackUnitPrice then
					total = total + shortfall * fallbackUnitPrice * SCARCITY_PENALTY_MULTIPLIER
				end
			end
		else
			local price = CraftRoute.GetPriceFor(name, nil)
			if price then
				total = total + price * qty
			end
		end
	end
	return total
end

-- Looks for opportunities to extend an earlier recipe run further than its
-- raw per-skill-point cost alone would justify, when doing so covers a
-- known later reagent need "for free" as a byproduct -- see the comment
-- above where this is called from CalculatePath for the full reasoning.
-- Bounded/local: only considers extending a step into the immediately
-- following step(s) up to its own grey point, not a full path search. Each
-- candidate extension is verified by actually recomputing the true shopping
-- cost (via ShoppingList, which already does supply-crediting and
-- make-vs-buy correctly) for both the extended and un-extended version,
-- rather than trusting an approximate estimate of the benefit -- a cheaper
-- estimate that doesn't match what's actually computed elsewhere would be
-- worse than not extending at all.
-- Returns: newSteps, newTotalCost, improved (bool)
function CraftRoute.ApplyDownstreamExtensions(professionKey, steps, total_cost, targetSkill, recipeLookup, cache)
	local recipes = CraftRoute_Data[professionKey]

	-- raw (pre-make-vs-buy) production vs demand for every item name, so we
	-- know which recipes' outputs are falling short and being paid for
	-- again later instead of covered by extending the original run.
	local produced, demanded = {}, {}
	for i = 1, getn(steps) do
		local key = strlower(steps[i].name)
		produced[key] = (produced[key] or 0) + math.ceil(steps[i].expectedCrafts)
	end
	for i = 1, getn(steps) do
		local recipe = recipes[steps[i].recipeIndex]
		local crafts = math.ceil(steps[i].expectedCrafts)
		for j = 1, getn(recipe.reagents) do
			local r = recipe.reagents[j]
			local name = CraftRoute.ResolveReagent(r)
			if name then
				local key = strlower(name)
				demanded[key] = (demanded[key] or 0) + r.qty * crafts
			end
		end
	end

	local newSteps = {}
	local totalDelta = 0
	local improved = false
	local i = 1
	while i <= getn(steps) do
		local s = steps[i]
		local key = strlower(s.name)
		local shortfall = (demanded[key] or 0) - (produced[key] or 0)
		local recipe = recipes[s.recipeIndex]
		local canExtend = shortfall > 0 and s.toSkill < recipe.grey and s.toSkill < targetSkill and i < getn(steps)

		if canExtend then
			-- how far do the immediately-following step(s) reach before this
			-- recipe's own grey point (or the target skill) cuts things off?
			-- If the extension boundary falls in the middle of a step, that
			-- step is split: the consumed prefix folds into the merge, the
			-- leftover suffix is preserved as its own step afterward (same
			-- proration technique split_into_bands uses for band display).
			local j = i + 1
			local coveredTo = s.toSkill
			local originalSubCost = 0
			local leftoverStep = nil
			local extensionEnd = math.min(recipe.grey, targetSkill)
			while j <= getn(steps) do
				local nj = steps[j]
				if nj.fromSkill >= extensionEnd then
					break
				end
				if nj.toSkill <= extensionEnd then
					originalSubCost = originalSubCost + nj.subtotal
					coveredTo = nj.toSkill
					j = j + 1
				else
					local frac = (extensionEnd - nj.fromSkill) / (nj.toSkill - nj.fromSkill)
					originalSubCost = originalSubCost + nj.subtotal * frac
					coveredTo = extensionEnd
					leftoverStep = {
						recipeIndex = nj.recipeIndex,
						name = nj.name,
						fromSkill = extensionEnd,
						toSkill = nj.toSkill,
						expectedCrafts = nj.expectedCrafts * (1 - frac),
						unitCost = nj.unitCost,
						subtotal = nj.subtotal * (1 - frac),
						learnCost = nj.learnCost,
						learnCostConfidence = nj.learnCostConfidence,
						scrollName = nj.scrollName,
						questObtained = nj.questObtained,
						bossObtained = nj.bossObtained,
					}
					j = j + 1
					break
				end
			end

			if coveredTo > s.toSkill then
				local reagentCost = recipe_cost(recipe, recipeLookup, cache)
				if reagentCost then
					local extendedCost, extraUnits = 0, 0
					local sk = s.toSkill
					while sk < coveredTo do
						local chance = skillup_chance(sk, recipe.orange, recipe.yellow, recipe.green, recipe.grey)
						if chance <= 0 then
							extendedCost = extendedCost + reagentCost
							extraUnits = extraUnits + 1
						else
							extendedCost = extendedCost + reagentCost / chance
							extraUnits = extraUnits + (1 / chance)
						end
						sk = sk + 1
					end

					local mergedStep = {
						recipeIndex = s.recipeIndex,
						name = s.name,
						fromSkill = s.fromSkill,
						toSkill = coveredTo,
						expectedCrafts = s.expectedCrafts + extraUnits,
						unitCost = s.unitCost,
						subtotal = s.subtotal + extendedCost,
						learnCost = s.learnCost,
						learnCostConfidence = s.learnCostConfidence,
						scrollName = s.scrollName,
						questObtained = s.questObtained,
						bossObtained = s.bossObtained,
					}

					-- Build both full candidate step lists (everything decided
					-- so far, then this specific choice, then the rest of the
					-- ORIGINAL path unchanged) and compare their real,
					-- recomputed true shopping costs -- not an estimate.
					local baselineFull, extendedFull = {}, {}
					for k = 1, getn(newSteps) do
						table.insert(baselineFull, newSteps[k])
						table.insert(extendedFull, newSteps[k])
					end
					table.insert(baselineFull, s)
					table.insert(extendedFull, mergedStep)
					if leftoverStep then
						table.insert(extendedFull, leftoverStep)
					end
					for k = i + 1, getn(steps) do
						table.insert(baselineFull, steps[k])
					end
					for k = j, getn(steps) do
						table.insert(extendedFull, steps[k])
					end

					local baselineCost = shopping_list_true_cost(professionKey, baselineFull)
					local extendedCostTrue = shopping_list_true_cost(professionKey, extendedFull)

					if extendedCostTrue < baselineCost then
						table.insert(newSteps, mergedStep)
						if leftoverStep then
							table.insert(newSteps, leftoverStep)
						end
						produced[key] = (produced[key] or 0) + extraUnits
						totalDelta = totalDelta + (extendedCost - originalSubCost)
						improved = true
						i = j
						canExtend = "consumed"
					end
				end
			end
		end

		if canExtend ~= "consumed" then
			table.insert(newSteps, s)
			i = i + 1
		end
	end

	if improved then
		return newSteps, total_cost + totalDelta, true
	end
	return steps, total_cost, false
end

-- Handles reagent shortfalls the skill-up-preserving pass above can't
-- reach -- specifically, when a later step's reagent need falls beyond the
-- producing recipe's own grey point, where it stops contributing skill-up
-- entirely (ApplyDownstreamExtensions can only extend a recipe run while
-- it's still capable of skill-up; it has no way to justify crafting
-- something purely for the byproduct with zero skill value).
--
-- This is a much simpler decision by contrast: no skill-range reasoning at
-- all, just "would crafting `shortfall` more of this recipe's own output,
-- at flat reagent cost, beat buying `shortfall` more separately via the
-- real depletion-aware shopping cost." If so, those extra crafts get added
-- directly onto that recipe's EXISTING step wherever it already sits in the
-- path (never introducing a brand new recipe purely for material
-- production -- that would be a bigger, more speculative decision than
-- this pass is meant to make) -- expectedCrafts and subtotal grow, but the
-- step's own skill range is untouched, since these crafts don't represent
-- any additional skill progression.
function CraftRoute.ApplyPureProductionExtensions(professionKey, steps, total_cost, recipeLookup, cache)
	local recipes = CraftRoute_Data[professionKey]

	local produced, demanded = {}, {}
	for i = 1, getn(steps) do
		local key = strlower(steps[i].name)
		produced[key] = (produced[key] or 0) + math.ceil(steps[i].expectedCrafts)
	end
	for i = 1, getn(steps) do
		local recipe = recipes[steps[i].recipeIndex]
		local crafts = math.ceil(steps[i].expectedCrafts)
		for j = 1, getn(recipe.reagents) do
			local r = recipe.reagents[j]
			local name = CraftRoute.ResolveReagent(r)
			if name then
				local key = strlower(name)
				demanded[key] = (demanded[key] or 0) + r.qty * crafts
			end
		end
	end

	local newSteps = {}
	for i = 1, getn(steps) do
		table.insert(newSteps, steps[i])
	end

	local improved = false
	local extensions = {}

	for key, demand in pairs(demanded) do
		local have = produced[key] or 0
		local shortfall = demand - have
		if shortfall > 0 then
			local producingRecipe = recipeLookup[key]
			if producingRecipe then
				local stepIdx = nil
				for i = 1, getn(newSteps) do
					if strlower(newSteps[i].name) == key then
						stepIdx = i
						break
					end
				end
				if stepIdx then
					local reagentCost = recipe_cost(producingRecipe, recipeLookup, cache)
					if reagentCost then
						local craftCost = reagentCost * shortfall

						-- Cheap pre-check before paying for the full real
						-- comparison below -- if flat-crafting the shortfall
						-- already costs more than the recipe's own reagents
						-- would via a plain AH buy, there's no way the real
						-- comparison could favor it either.
						local roughBuyCost = nil
						if CraftRoute.OrderBookCost then
							local ahCost, covered, sf = CraftRoute.OrderBookCost(producingRecipe.name, shortfall)
							if sf > 0 then
								local fallback = CraftRoute.GetPriceFor(producingRecipe.name, nil)
								roughBuyCost = fallback and (ahCost + sf * fallback * SCARCITY_PENALTY_MULTIPLIER) or nil
							else
								roughBuyCost = ahCost
							end
						else
							local fallback = CraftRoute.GetPriceFor(producingRecipe.name, nil)
							roughBuyCost = fallback and (fallback * shortfall) or nil
						end

						if roughBuyCost and craftCost < roughBuyCost then
							local s = newSteps[stepIdx]
							local extended = {
								recipeIndex = s.recipeIndex,
								name = s.name,
								fromSkill = s.fromSkill,
								toSkill = s.toSkill,
								expectedCrafts = s.expectedCrafts + shortfall,
								unitCost = s.unitCost,
								subtotal = s.subtotal + craftCost,
								learnCost = s.learnCost,
								learnCostConfidence = s.learnCostConfidence,
								scrollName = s.scrollName,
								questObtained = s.questObtained,
								bossObtained = s.bossObtained,
							}

							-- Real comparison, not an invented credit: build
							-- the candidate with this step extended, and
							-- price BOTH candidates from scratch via the
							-- same real shopping-cost function used
							-- everywhere else. Choosing the cheaper of two
							-- real options isn't a "gain" over the option
							-- not taken -- it's just paying the lower
							-- price -- so there's nothing to redistribute
							-- to other steps. ShoppingList's own leftover-
							-- supply tracking already correctly credits
							-- this step's extra production against what
							-- other steps need to buy, with no manual
							-- bookkeeping required here.
							local extendedSteps = {}
							for k = 1, getn(newSteps) do
								table.insert(extendedSteps, newSteps[k])
							end
							extendedSteps[stepIdx] = extended

							local baselineCost = shopping_list_true_cost(professionKey, newSteps)
							local extendedCost = shopping_list_true_cost(professionKey, extendedSteps)

							if extendedCost < baselineCost then
								newSteps = extendedSteps
								improved = true
								-- Record this specific extension (which step,
								-- how many flat-cost units got added to it)
								-- so ApplyTrimming can check afterward
								-- whether those units actually had real,
								-- uncredited skill-up value -- true whenever
								-- the recipe hadn't reached its own grey yet
								-- at this step's current toSkill. This pass
								-- never checks that itself; it always treats
								-- the shortfall as flat/zero-skill.
								table.insert(extensions, {step = extended, extraUnits = shortfall})
							end
						end
					end
				end
			end
		end
	end

	if improved then
		local newTotal = shopping_list_true_cost(professionKey, newSteps)
		local totalLearnCost = 0
		for i = 1, getn(newSteps) do
			totalLearnCost = totalLearnCost + (newSteps[i].learnCost or 0)
		end
		return newSteps, newTotal + totalLearnCost, true, extensions
	end
	return steps, total_cost, false, {}
end

-- Given `extraCrafts` worth of a recipe's crafts already committed to
-- (added flat by ApplyPureProductionExtensions, priced at zero skill-up
-- value), walks the recipe's REAL, decaying skillup_chance curve forward
-- from `fromSkill` to find how far those crafts would have actually
-- carried skill if credited properly -- capped at the recipe's own grey,
-- since no further real progress is possible past that regardless of
-- leftover budget. Only claims a skill point if the full 1/chance cost
-- for it is covered by the remaining budget -- never rounds up, so this
-- can only under-claim free progress, never overstate it.
local function simulate_forward_landing(recipe, fromSkill, extraCrafts)
	local sk = fromSkill
	local budget = extraCrafts
	while sk < recipe.grey and budget > 0 do
		local chance = skillup_chance(sk, recipe.orange, recipe.yellow, recipe.green, recipe.grey)
		local pointCost = (chance > 0) and (1 / chance) or 1
		if budget < pointCost then
			break
		end
		budget = budget - pointCost
		sk = sk + 1
	end
	return sk
end

-- Real expectedCrafts/cost for one recipe over an arbitrary [fromSkill,
-- toSkill) range, walking its actual decaying skillup_chance curve point
-- by point -- same math the main loop and ApplyDownstreamExtensions each
-- already do inline, factored out here so ApplyTrimming can recompute a
-- shrunk step's numbers the same way rather than reinventing it.
local function simulate_recipe_range_cost(recipe, fromSkill, toSkill, reagentCost)
	local crafts, cost = 0, 0
	local sk = fromSkill
	while sk < toSkill do
		local chance = skillup_chance(sk, recipe.orange, recipe.yellow, recipe.green, recipe.grey)
		if chance <= 0 then
			crafts = crafts + 1
			cost = cost + reagentCost
		else
			crafts = crafts + (1 / chance)
			cost = cost + reagentCost / chance
		end
		sk = sk + 1
	end
	return crafts, cost
end

-- ApplyPureProductionExtensions always treats its flat-added units as
-- zero-skill -- true only if the producing recipe had genuinely already
-- reached its own grey at the point those units got tacked on. If it
-- hadn't, those units DO have real, decaying skillup_chance during that
-- stretch, exactly like any other craft of that recipe -- and since
-- they're being made anyway (the shortfall demands it regardless of
-- cost), any skill they happen to grant is genuinely free. This pass
-- collects that free skill and reduces (or fully removes) whatever
-- step(s) immediately follow to the extent it's no longer needed --
-- called "trimming" through the design conversation that led to this.
-- No cost-comparison decision here, unlike every other extension pass:
-- crafting those units was already locked in by ApplyPureProductionExtensions,
-- so any skill they grant is unconditionally free, nothing to weigh
-- against a cheaper alternative.
function CraftRoute.ApplyTrimming(professionKey, steps, extensions, total_cost, recipeLookup, cache)
	local recipes = CraftRoute_Data[professionKey]
	local newSteps = {}
	for i = 1, getn(steps) do
		table.insert(newSteps, steps[i])
	end

	local totalDelta = 0
	local trimmed = false

	for e = 1, getn(extensions) do
		local ext = extensions[e]
		local step = ext.step
		local recipe = recipes[step.recipeIndex]

		if step.toSkill < recipe.grey then
			local landing = simulate_forward_landing(recipe, step.toSkill, ext.extraUnits)
			if landing > step.toSkill then
				local idx = nil
				for k = 1, getn(newSteps) do
					if newSteps[k] == step then
						idx = k
						break
					end
				end
				if idx then
					local remaining = landing - step.toSkill
					local k = idx + 1
					while k <= getn(newSteps) and remaining > 0 do
						local victim = newSteps[k]
						local span = victim.toSkill - victim.fromSkill
						if span <= remaining then
							-- Fully covered by the free skill -- remove
							-- this step entirely, no partial remainder.
							totalDelta = totalDelta - victim.subtotal
							remaining = remaining - span
							table.remove(newSteps, k)
							trimmed = true
							-- don't advance k -- the next step slid into
							-- position k after the removal
						else
							-- Only partially covered -- shrink it from
							-- the front, recompute its real numbers for
							-- the new (shorter) range from scratch.
							local vRecipe = recipes[victim.recipeIndex]
							local newFrom = victim.fromSkill + remaining
							local vReagentCost = recipe_cost(vRecipe, recipeLookup, cache)
							if vReagentCost then
								local newCrafts, newCost = simulate_recipe_range_cost(vRecipe, newFrom, victim.toSkill, vReagentCost)
								-- subtotal includes any one-time learnCost
								-- baked in (see CalculatePath's main loop) --
								-- shrinking the craft count doesn't remove
								-- the need to learn the recipe at all, so
								-- that has to be added back in here, not
								-- just replaced by the new reagent-only cost.
								local newSubtotal = newCost + (victim.learnCost or 0)
								totalDelta = totalDelta - victim.subtotal + newSubtotal
								newSteps[k] = {
									recipeIndex = victim.recipeIndex,
									name = victim.name,
									fromSkill = newFrom,
									toSkill = victim.toSkill,
									expectedCrafts = newCrafts,
									unitCost = victim.unitCost,
									subtotal = newSubtotal,
									learnCost = victim.learnCost,
									learnCostConfidence = victim.learnCostConfidence,
									scrollName = victim.scrollName,
									questObtained = victim.questObtained,
									bossObtained = victim.bossObtained,
								}
								trimmed = true
							end
							remaining = 0
						end
					end
				end
			end
		end
	end

	if trimmed then
		return newSteps, total_cost + totalDelta, true
	end
	return steps, total_cost, false
end

-- Small, curated list of tools that are ALSO one of the profession's own
-- leveling recipes (Blacksmith Hammer isn't here since it's vendor-only,
-- not something you can craft -- see PROFESSION_TOOLS in slash.lua for the
-- full display list including vendor-only ones).
local PROFESSION_CRAFTABLE_TOOLS = {
	engineering = {"Arclight Spanner", "Gyromatic Micro-Adjustor"},
}

-- Checks whether crafting a required tool AT its own orange threshold
-- (where it always succeeds, so it costs exactly 1 craft) -- swapped in
-- place of whatever recipe currently covers that single skill point --
-- beats using that recipe there and buying the tool separately afterward.
-- This is exactly the "should I use this skill point on the tool and get
-- it for free, or use it on something cheaper and buy the tool separately"
-- question a player can't answer from reagent prices alone. Only applies
-- if the tool isn't already naturally present somewhere in the path (in
-- which case it's already free, nothing to check).
-- Returns: newSteps, newTotalCost, improved (bool)
function CraftRoute.ApplyToolAcquisition(professionKey, steps, total_cost, startSkill, targetSkill, recipeLookup, cache)
	local tools = PROFESSION_CRAFTABLE_TOOLS[professionKey]
	if not tools then
		return steps, total_cost, false
	end
	local recipes = CraftRoute_Data[professionKey]

	local currentSteps = steps
	local anyImproved = false

	for t = 1, getn(tools) do
		local toolName = tools[t]
		local toolKey = strlower(toolName)

		local alreadyPresent = false
		for i = 1, getn(currentSteps) do
			if strlower(currentSteps[i].name) == toolKey then
				alreadyPresent = true
				break
			end
		end

		if not alreadyPresent then
			local toolRecipe = recipeLookup[toolKey]
			local toolRecipeIdx = nil
			if toolRecipe then
				for i = 1, getn(recipes) do
					if recipes[i] == toolRecipe then
						toolRecipeIdx = i
						break
					end
				end
			end

			if toolRecipe and toolRecipeIdx and toolRecipe.orange >= startSkill and toolRecipe.orange < targetSkill then
				local orangePoint = toolRecipe.orange
				local coveringIdx = nil
				for i = 1, getn(currentSteps) do
					if currentSteps[i].fromSkill <= orangePoint and orangePoint < currentSteps[i].toSkill then
						coveringIdx = i
						break
					end
				end

				if coveringIdx then
					local covering = currentSteps[coveringIdx]
					local coveringRecipe = recipes[covering.recipeIndex]
					local coveringChance = skillup_chance(orangePoint, coveringRecipe.orange, coveringRecipe.yellow, coveringRecipe.green, coveringRecipe.grey)
					local toolReagentCost = recipe_cost(toolRecipe, recipeLookup, cache)

					if coveringChance and coveringChance > 0 and covering.unitCost and toolReagentCost then
						local removedCrafts = 1 / coveringChance
						-- only safe if the covering step has "room" to lose one craft
						-- without going negative
						if covering.expectedCrafts - removedCrafts >= 0 then
							local craftCandidate = {}
							for i = 1, getn(currentSteps) do
								table.insert(craftCandidate, currentSteps[i])
							end

							-- Split the covering step into up to 3 pieces so the
							-- displayed order is chronological (no overlapping
							-- ranges): whatever came before the tool's skill
							-- point, the tool itself, then whatever comes after.
							-- Handles the tool's threshold landing anywhere in
							-- the covering step's range, not just at its start.
							local coveringRange = covering.toSkill - covering.fromSkill
							local beforeFrac = coveringRange > 0 and (orangePoint - covering.fromSkill) / coveringRange or 0
							local beforeCrafts = covering.expectedCrafts * beforeFrac
							local beforeCost = covering.subtotal * beforeFrac
							local afterCrafts = covering.expectedCrafts - beforeCrafts - removedCrafts
							local afterCost = covering.subtotal - beforeCost - (covering.unitCost * removedCrafts)

							local replacement = {}
							local hasBefore = orangePoint > covering.fromSkill
							if hasBefore then
								table.insert(replacement, {
									recipeIndex = covering.recipeIndex, name = covering.name,
									fromSkill = covering.fromSkill, toSkill = orangePoint,
									expectedCrafts = beforeCrafts, unitCost = covering.unitCost,
									subtotal = beforeCost,
									learnCost = covering.learnCost, learnCostConfidence = covering.learnCostConfidence,
									scrollName = covering.scrollName,
									questObtained = covering.questObtained,
									bossObtained = covering.bossObtained,
								})
							end
							table.insert(replacement, {
								recipeIndex = toolRecipeIdx, name = toolName,
								fromSkill = orangePoint, toSkill = orangePoint + 1,
								expectedCrafts = 1, unitCost = toolReagentCost, subtotal = toolReagentCost,
								learnCost = 0, learnCostConfidence = "confirmed",
								scrollName = toolRecipe.scrollName,
								questObtained = toolRecipe.questObtained,
								bossObtained = toolRecipe.bossObtained,
							})
							if orangePoint + 1 < covering.toSkill then
								table.insert(replacement, {
									recipeIndex = covering.recipeIndex, name = covering.name,
									fromSkill = orangePoint + 1, toSkill = covering.toSkill,
									expectedCrafts = afterCrafts, unitCost = covering.unitCost,
									subtotal = afterCost,
									-- learn cost already attributed to the "before" piece
									-- (or nowhere, if the tool sits right at the start)
									learnCost = hasBefore and 0 or covering.learnCost,
									learnCostConfidence = covering.learnCostConfidence,
									scrollName = covering.scrollName,
									questObtained = covering.questObtained,
									bossObtained = covering.bossObtained,
								})
							end

							table.remove(craftCandidate, coveringIdx)
							for k = getn(replacement), 1, -1 do
								table.insert(craftCandidate, coveringIdx, replacement[k])
							end

							local craftCost = shopping_list_true_cost(professionKey, craftCandidate)
							local buyPrice = nil
							if CraftRoute.OrderBookCost then
								local ahCost, covered, shortfall = CraftRoute.OrderBookCost(toolName, 1)
								if shortfall > 0 then
									local fallback = CraftRoute.GetPriceFor(toolName, nil)
									buyPrice = fallback and (ahCost + fallback * SCARCITY_PENALTY_MULTIPLIER) or nil
								else
									buyPrice = ahCost
								end
							else
								buyPrice = CraftRoute.GetPriceFor(toolName, nil)
							end
							if buyPrice then
								local buyCost = shopping_list_true_cost(professionKey, currentSteps) + buyPrice
								if craftCost < buyCost then
									currentSteps = craftCandidate
									anyImproved = true
								end
							end
						end
					end
				end
			end
		end
	end

	return currentSteps, total_cost, anyImproved
end

-- Enchanting rods (Runed Copper/Silver/Golden/Truesilver Rod) aren't just
-- another skill-up option competing on cost -- they're required equipment
-- to cast most enchants past a certain skill, the same way Engineering
-- needs its own tools. Unlike ApplyToolAcquisition above, this is
-- unconditional: always insert each rod at its own orange threshold
-- (where it always succeeds) if it isn't already naturally present,
-- regardless of whether that's the cheapest possible choice for that skill
-- point. Runed Arcanite Rod is deliberately excluded -- its Arcanite Rod
-- reagent alone runs 100g+, so forcing it in unconditionally would badly
-- hurt route cost for comparatively little benefit; players can decide for
-- themselves whether to pick it up separately.
local MANDATORY_ENCHANTING_RODS = {
	"Runed Copper Rod", "Runed Silver Rod", "Runed Golden Rod", "Runed Truesilver Rod",
}

-- Returns: newSteps, anyInserted (bool)
function CraftRoute.ApplyMandatoryRods(professionKey, steps, startSkill, targetSkill, recipeLookup, cache)
	if professionKey ~= "enchanting" then
		return steps, false
	end
	local recipes = CraftRoute_Data[professionKey]

	local currentSteps = steps
	local anyInserted = false

	for r = 1, getn(MANDATORY_ENCHANTING_RODS) do
		local rodName = MANDATORY_ENCHANTING_RODS[r]
		local rodKey = strlower(rodName)

		local alreadyPresent = false
		for i = 1, getn(currentSteps) do
			if strlower(currentSteps[i].name) == rodKey then
				alreadyPresent = true
				break
			end
		end

		if not alreadyPresent then
			local rodRecipe = recipeLookup[rodKey]
			local rodRecipeIdx = nil
			if rodRecipe then
				for i = 1, getn(recipes) do
					if recipes[i] == rodRecipe then
						rodRecipeIdx = i
						break
					end
				end
			end

			if rodRecipe and rodRecipeIdx and rodRecipe.orange >= startSkill and rodRecipe.orange < targetSkill then
				local orangePoint = rodRecipe.orange
				local coveringIdx = nil
				for i = 1, getn(currentSteps) do
					if currentSteps[i].fromSkill <= orangePoint and orangePoint < currentSteps[i].toSkill then
						coveringIdx = i
						break
					end
				end

				if coveringIdx then
					local covering = currentSteps[coveringIdx]
					local coveringRecipe = recipes[covering.recipeIndex]
					local coveringChance = skillup_chance(orangePoint, coveringRecipe.orange, coveringRecipe.yellow, coveringRecipe.green, coveringRecipe.grey)
					local rodReagentCost = recipe_cost(rodRecipe, recipeLookup, cache)

					if coveringChance and coveringChance > 0 and covering.unitCost and rodReagentCost then
						local removedCrafts = 1 / coveringChance
						if covering.expectedCrafts - removedCrafts >= 0 then
							local craftCandidate = {}
							for i = 1, getn(currentSteps) do
								table.insert(craftCandidate, currentSteps[i])
							end

							local coveringRange = covering.toSkill - covering.fromSkill
							local beforeFrac = coveringRange > 0 and (orangePoint - covering.fromSkill) / coveringRange or 0
							local beforeCrafts = covering.expectedCrafts * beforeFrac
							local beforeCost = covering.subtotal * beforeFrac
							local afterCrafts = covering.expectedCrafts - beforeCrafts - removedCrafts
							local afterCost = covering.subtotal - beforeCost - (covering.unitCost * removedCrafts)

							local replacement = {}
							local hasBefore = orangePoint > covering.fromSkill
							if hasBefore then
								table.insert(replacement, {
									recipeIndex = covering.recipeIndex, name = covering.name,
									fromSkill = covering.fromSkill, toSkill = orangePoint,
									expectedCrafts = beforeCrafts, unitCost = covering.unitCost,
									subtotal = beforeCost,
									learnCost = covering.learnCost, learnCostConfidence = covering.learnCostConfidence,
									scrollName = covering.scrollName,
									questObtained = covering.questObtained,
									bossObtained = covering.bossObtained,
								})
							end
							table.insert(replacement, {
								recipeIndex = rodRecipeIdx, name = rodName,
								fromSkill = orangePoint, toSkill = orangePoint + 1,
								expectedCrafts = 1, unitCost = rodReagentCost, subtotal = rodReagentCost,
								learnCost = 0, learnCostConfidence = "confirmed",
								scrollName = rodRecipe.scrollName,
								questObtained = rodRecipe.questObtained,
								bossObtained = rodRecipe.bossObtained,
							})
							if orangePoint + 1 < covering.toSkill then
								table.insert(replacement, {
									recipeIndex = covering.recipeIndex, name = covering.name,
									fromSkill = orangePoint + 1, toSkill = covering.toSkill,
									expectedCrafts = afterCrafts, unitCost = covering.unitCost,
									subtotal = afterCost,
									learnCost = hasBefore and 0 or covering.learnCost,
									learnCostConfidence = covering.learnCostConfidence,
									scrollName = covering.scrollName,
									questObtained = covering.questObtained,
									bossObtained = covering.bossObtained,
								})
							end

							table.remove(craftCandidate, coveringIdx)
							for k = getn(replacement), 1, -1 do
								table.insert(craftCandidate, coveringIdx, replacement[k])
							end

							-- Unconditional -- unlike ApplyToolAcquisition, no cost
							-- comparison here. The rod is required equipment, not
							-- an optional cost tradeoff.
							currentSteps = craftCandidate
							anyInserted = true
						end
					end
				end
			end
		end
	end

	return currentSteps, anyInserted
end

-- Recursively adds `qty` units of an item's TRUE shopping needs into `totals`/`order`:
-- first satisfies as much as possible from free "byproduct supply" (units
-- already produced as a side effect of the skill-up phase itself -- every
-- craft attempt yields 1 unit of output whether or not it results in a
-- skill-up, so if you're already grinding out 221 Bronze Tubes to skill up,
-- the 30 a later recipe needs are genuinely free, not an extra cost).
-- Whatever isn't covered by supply falls through to make-vs-buy: if it's
-- cheaper to craft this item than buy it, expands into its own reagents
-- instead (recursively, also checking their own supply); otherwise adds it
-- directly as something to buy.
local function expand_shopping_need(name, itemId, qty, recipeLookup, cache, totals, order, visiting, supply)
	if name and supply then
		local skey = strlower(name)
		local avail = supply[skey]
		if avail and avail > 0 then
			local covered = math.min(avail, qty)
			supply[skey] = avail - covered
			qty = qty - covered
			if qty <= 0 then return end
		end
	end

	local key = name and strlower(name) or ("#" .. tostring(itemId))

	if name and not visiting[key] then
		-- Reuse the exact same decision the cost calculation made (buy off
		-- the AH, craft it, or -- for the 5 Greater essences -- convert from
		-- Lesser), rather than re-deriving "does crafting beat buying"
		-- separately here. Two independent implementations of the same
		-- decision risk disagreeing (shopping list says one thing, quoted
		-- total assumed another); this keeps them structurally the same call.
		local _, source, detail = get_item_cost_detailed(name, itemId, recipeLookup, cache, {})
		if source == "craft" and detail then
			visiting[key] = true
			for i = 1, getn(detail.reagents) do
				local sr = detail.reagents[i]
				local srName, srItemId = CraftRoute.ResolveReagent(sr)
				expand_shopping_need(srName, srItemId, sr.qty * qty, recipeLookup, cache, totals, order, visiting, supply)
			end
			visiting[key] = nil
			return
		elseif source == "convert" and detail then
			visiting[key] = true
			expand_shopping_need(detail, nil, qty * ESSENCE_CONVERSION_RATIO, recipeLookup, cache, totals, order, visiting, supply)
			visiting[key] = nil
			return
		end
	end

	local displayName = name or ("Item #" .. tostring(itemId))
	if not totals[displayName] then
		totals[displayName] = 0
		table.insert(order, displayName)
	end
	totals[displayName] = totals[displayName] + qty
end

-- Prices a FIXED step sequence (from a static leveling guide) using the same
-- depletion-aware/make-vs-buy engine CalculatePath uses for its own
-- optimizer -- but instead of choosing recipes, it just walks the guide's
-- own {name, fromSkill, toSkill, crafts} sequence and prices each step.
-- Every recipe's reagents/thresholds/learnCost/scrollName/questObtained
-- still come from CraftRoute_Data (the guide only supplies which recipe,
-- what range, how many crafts) -- single source of truth, no reagent
-- lists duplicated in guide data.
-- Uses its OWN fresh pathConsumed, deliberately independent from whatever
-- CalculatePath's own optimizer run consumed -- these are two alternative
-- scenarios being priced side by side, not one continuous depletion across
-- both, so the guide's order-book state must start clean.
-- Returns: total_cost, steps, missing, reached, stuckAt, total_learn_cost,
-- any_learn_cost_estimated (same shape as CalculatePath, so it can be fed
-- into the same ShoppingList/TrueShoppingCost/SellBackCredit/build_report
-- machinery without changes).
function CraftRoute.CalculateGuidePath(professionKey, guideKey, targetSkill, startSkill)
	targetSkill = targetSkill or 300
	startSkill = startSkill or 1
	local recipes = CraftRoute_Data[professionKey]
	if not recipes then
		return nil, nil, nil, 0, "No recipe data loaded for '" .. professionKey .. "'"
	end
	local guideData = CraftRoute_GuideSteps and CraftRoute_GuideSteps[guideKey]
	local guideSteps = guideData and guideData[professionKey]
	if not guideSteps then
		return nil, nil, nil, 0, "No '" .. guideKey .. "' guide data for '" .. professionKey .. "'"
	end

	local recipeLookup = build_recipe_lookup(recipes)
	local recipeIndexByName = {}
	for ri = 1, getn(recipes) do
		recipeIndexByName[strlower(recipes[ri].name)] = ri
	end
	local costCache = {}
	local pathConsumed = {} -- fresh, independent of CalculatePath's own run
	local missingSet = {}
	local steps = {}
	local total_cost, total_learn_cost = 0, 0
	local any_learn_cost_estimated = false
	local reached = startSkill

	for i = 1, getn(guideSteps) do
		local gs = guideSteps[i]
		local fromSkill = math.max(gs.fromSkill, startSkill)
		local toSkill = math.min(gs.toSkill, targetSkill)
		if toSkill > fromSkill then
			local recipe = recipeLookup[strlower(gs.name)]
			if not recipe then
				missingSet[gs.name .. " (recipe not found in data)"] = true
			else
				local stepRange = gs.toSkill - gs.fromSkill
				local frac = stepRange > 0 and ((toSkill - fromSkill) / stepRange) or 1
				local crafts = gs.crafts * frac
				local subtotal = 0
				for j = 1, getn(recipe.reagents) do
					local r = recipe.reagents[j]
					local rname, ritemId = CraftRoute.ResolveReagent(r)
					local cost, consumption = depletion_aware_reagent_cost_detailed(
						rname, ritemId, r.qty * crafts, recipeLookup, costCache, pathConsumed)
					if cost then
						subtotal = subtotal + cost
						for k = 1, getn(consumption) do
							local c = consumption[k]
							local ck = strlower(c.name)
							pathConsumed[ck] = (pathConsumed[ck] or 0) + c.qty
						end
					else
						missingSet[rname or ("Item #" .. tostring(ritemId))] = true
					end
				end
				local learnCost, learnCostConfidence
				if recipe.questObtained or recipe.bossObtained then
					learnCost, learnCostConfidence = 0, "confirmed"
				else
					learnCost, learnCostConfidence = CraftRoute.GetRecipeLearnCost(recipe)
					if not learnCost then
						-- requiresScan and never scanned -- same "can't safely
						-- guess" situation CalculatePath treats as unusable.
						-- The guide still names this recipe, so flag it as
						-- missing price data rather than silently pricing it free.
						if recipe.scrollName then
							missingSet[recipe.scrollName] = true
						end
						learnCost, learnCostConfidence = 0, "estimated"
					end
				end
				if learnCostConfidence ~= "confirmed" and learnCostConfidence ~= "scanned" then
					any_learn_cost_estimated = true
				end
				total_cost = total_cost + subtotal + learnCost
				total_learn_cost = total_learn_cost + learnCost
				table.insert(steps, {
					name = recipe.name, recipeIndex = recipeIndexByName[strlower(recipe.name)],
					fromSkill = fromSkill, toSkill = toSkill,
					expectedCrafts = crafts, unitCost = crafts > 0 and (subtotal / crafts) or 0,
					subtotal = subtotal, learnCost = learnCost, learnCostConfidence = learnCostConfidence,
					scrollName = recipe.scrollName, questObtained = recipe.questObtained,
					bossObtained = recipe.bossObtained,
				})
				reached = toSkill
			end
		end
	end

	local missing = {}
	for name in pairs(missingSet) do
		table.insert(missing, name)
	end
	table.sort(missing)

	return total_cost, steps, missing, reached, nil, total_learn_cost, any_learn_cost_estimated
end

-- Aggregates the TRUE reagent shopping list (rounded up craft counts) across
-- all steps, with:
--   1. byproduct supply credit -- items you're already producing as a side
--      effect of skill-up get subtracted from later reagent needs for free
--   2. make-vs-buy substitution -- anything (after supply credit) cheaper
--      to craft than buy is expanded down into its own base-material needs
-- both matching the same logic the cost calculation used, so the shopping
-- list and total cost stay consistent with each other.
function CraftRoute.ShoppingList(professionKey, steps, incomingSupply)
	local recipes = CraftRoute_Data[professionKey]
	local recipeLookup = build_recipe_lookup(recipes)
	local cache = {}
	local totals = {}
	local order = {}

	-- every craft attempt during a step produces 1 unit of that recipe's
	-- own output, success or not -- this is the free byproduct pool.
	-- Starts from `incomingSupply` (whatever's still left over from an
	-- EARLIER call on a different step subset, e.g. an earlier band) if
	-- given, so a surplus from one call can still credit a need in a
	-- LATER call instead of each one only ever seeing its own steps'
	-- production -- without this, splitting a route into separate calls
	-- (banded shopping lists) would systematically overstate what needs
	-- to be bought, since byproduct credit could never cross that split.
	local supply = {}
	if incomingSupply then
		for k, v in pairs(incomingSupply) do
			supply[k] = v
		end
	end
	for i = 1, getn(steps) do
		local s = steps[i]
		local skey = strlower(s.name)
		supply[skey] = (supply[skey] or 0) + math.ceil(s.expectedCrafts)
	end

	for i = 1, getn(steps) do
		local step = steps[i]
		local recipe = recipes[step.recipeIndex]
		local crafts = math.ceil(step.expectedCrafts)
		for j = 1, getn(recipe.reagents) do
			local r = recipe.reagents[j]
			local name, itemId = CraftRoute.ResolveReagent(r)
			expand_shopping_need(name, itemId, r.qty * crafts, recipeLookup, cache, totals, order, {}, supply)
		end
	end
	table.sort(order)
	return totals, order, supply
end

-- Professions whose crafted output has nothing physical to sell back to a
-- vendor (Enchanting applies directly to gear, no item is produced).
local NO_SELLBACK_PROFESSIONS = {enchanting = true}

-- Estimates the gold recouped by selling off crafted items that were
-- produced during skill-up but never ended up needed as a reagent by a
-- later recipe (i.e. genuine leftover supply, not units that got consumed
-- via the byproduct-credit system). For each leftover item, compares the
-- current AH market price against the vendor sell price (tooltip-scanned
-- live, since it's not something that can be pre-gathered for every recipe)
-- and recommends AH selling only when it beats the vendor price by at least
-- the configured percentage (default 50%, i.e. 1.5x) -- otherwise the
-- hassle/fees of the AH aren't worth it over just vendoring it. Adjustable
-- via CraftRoute_Settings.sellBackThresholdPercent (the "AH selling" box in
-- the CraftRoute tab). Unless CraftRoute_Settings.includeSellbackScan is checked,
-- skips the AH price check entirely and always uses the vendor price --
-- faster, since it means the "Recipes"/output scan isn't needed at all if
-- you don't care about squeezing out AH value and just want the simple
-- vendor-sell number.
-- Returns: totalCredit (copper), perItem (list of {name, qty, unitPrice, credit, sellAt})
-- Enabled (v2.1.26) -- vendor sell prices now come from
-- data_vendorsellprices.lua, a real user-verified table, not the old
-- unreliable aux-itemId tooltip mechanism. Coverage isn't total yet (642
-- standard vanilla crafted outputs across 6 professions still unverified,
-- see DEVNOTES) -- those correctly show no sell-back credit rather than
-- falling back to a guess.
CraftRoute.SELLBACK_ENABLED = true

function CraftRoute.SellBackCredit(professionKey, steps)
	if not CraftRoute.SELLBACK_ENABLED then
		return 0, {}
	end
	if NO_SELLBACK_PROFESSIONS[professionKey] then
		return 0, {}
	end
	local checkAH = CraftRoute_Settings and CraftRoute_Settings.includeSellbackScan
	local totals, order, leftoverSupply = CraftRoute.ShoppingList(professionKey, steps)

	local totalCredit = 0
	local perItem = {}
	local names = {}
	for k in pairs(leftoverSupply) do
		table.insert(names, k)
	end
	table.sort(names)

	for i = 1, getn(names) do
		local lowerName = names[i]
		local qty = leftoverSupply[lowerName]
		if qty and qty > 0 then
			-- Vendor sell price comes ONLY from CraftRoute's own verified
			-- table now -- no live tooltip scan, no aux itemId lookup at
			-- all (see DEVNOTES, the Rough Gemstone Cluster bug this
			-- replaced). An item absent from the table has an unverified
			-- sell price and is treated as unknown (nil), never guessed.
			-- A price of 0 means confirmed not sellable to any vendor.
			local vendorPrice = CraftRoute_VendorSellPrices and CraftRoute_VendorSellPrices[lowerName]
			local marketPrice = checkAH and CraftRoute.GetMarketPrice(lowerName) or nil

			-- AH selling has fees/hassle/uncertainty vendor selling doesn't,
			-- so only worth recommending when it clearly beats the vendor --
			-- by at least the configured percentage (default 50%, i.e. 1.5x),
			-- adjustable via the "AH selling" box in the CraftRoute tab.
			local thresholdPercent = (CraftRoute_Settings and CraftRoute_Settings.sellBackThresholdPercent) or 50
			local thresholdMultiplier = 1 + (thresholdPercent / 100)
			local useMarket = marketPrice and vendorPrice and marketPrice >= vendorPrice * thresholdMultiplier
			local unitPrice = useMarket and marketPrice or vendorPrice
			local sellAt = useMarket and "AH" or (vendorPrice and vendorPrice > 0 and "vendor" or nil)

			if not unitPrice and marketPrice then
				-- no known vendor price, but it does have a market price --
				-- still worth flagging as AH-sellable
				unitPrice = marketPrice
				sellAt = "AH"
			end

			if unitPrice and unitPrice > 0 then
				local credit = unitPrice * qty
				totalCredit = totalCredit + credit
				table.insert(perItem, {name = lowerName, qty = qty, unitPrice = unitPrice, credit = credit, sellAt = sellAt})
			end
		end
	end

	return totalCredit, perItem
end

-- True depletion-aware cost of the shopping list: for each reagent, buys the
-- cheapest scanned listings first, up to the quantity needed. Requires
-- CraftRoute's own scan data (scan.lua) -- aux-addon's saved history doesn't
-- retain enough info (quantities) to do this. Any amount the AH can't cover
-- falls back first to vendor price (if vendor-sold -- a vendor never runs
-- out), then to crafting cost (if the item is itself one of this
-- profession's own recipes -- you can always just make more, at flat
-- reagent cost, regardless of AH supply). Only reports a genuine shortfall
-- if none of those three sources can cover the remaining need.
-- Returns: totalCost, perReagent (list of {name, qty, cost, covered, shortfall, vendorCovered, craftedCovered}), anyShortfall (bool)
-- pathConsumed (optional): AH depletion state to continue from, keyed by
-- lowercase item name -> units already treated as bought from the AH by
-- an EARLIER call. Lets multiple calls over different step subsets (e.g.
-- one per skill band, for a per-band shopping list) share one continuous
-- depletion timeline instead of each pretending to be the only draw on
-- the order book -- without this, splitting a route into bands and
-- summing their individual costs would UNDER-count the true total,
-- since each band would see the full undepleted book. Returns the
-- updated pathConsumed as a 4th value so the next call can continue from
-- it; existing callers that only capture 3 values are unaffected.
--
-- incomingSupply (optional): byproduct-credit state to continue from,
-- passed straight through to ShoppingList -- same reasoning as
-- pathConsumed above, but for crafted-item byproducts rather than AH
-- listings. Without this, splitting a route into bands would OVER-count
-- the true total instead: a surplus produced in an earlier band
-- couldn't credit a need in a later one, so the later band would price
-- itself as if it had to buy that reagent fresh. Returns the updated
-- supply as a 5th value for the same reason pathConsumed is returned.
function CraftRoute.TrueShoppingCost(professionKey, steps, pathConsumed, incomingSupply)
	pathConsumed = pathConsumed or {}
	local totals, order, supply = CraftRoute.ShoppingList(professionKey, steps, incomingSupply)
	local recipes = CraftRoute_Data[professionKey]
	local recipeLookup = build_recipe_lookup(recipes)
	local cache = {}
	local perReagent = {}
	local totalCost = 0
	local anyShortfall = false

	for i = 1, getn(order) do
		local name = order[i]
		local key = strlower(name)
		local qty = totals[name]
		local cost, covered, shortfall = 0, 0, qty
		local vendorCovered = 0

		if VENDOR_PREFERRED_MATERIALS[key] and CraftRoute_VendorPrices and CraftRoute_VendorPrices[key] then
			-- Always vendor for this item -- skip the AH order-book walk
			-- entirely, no shortfall is possible.
			local vendorPrice = CraftRoute_VendorPrices[key]
			cost = qty * vendorPrice
			covered = qty
			vendorCovered = qty
			shortfall = 0
		else
			local alreadyConsumed = pathConsumed[key] or 0
			if CraftRoute.OrderBookCost then
				cost, covered, shortfall = CraftRoute.OrderBookCost(name, qty, alreadyConsumed)
			end
			-- Record only what was actually drawn from the AH pool itself,
			-- captured before any vendor/craft fallback below adjusts
			-- `covered` further -- those don't touch AH depletion at all.
			pathConsumed[key] = alreadyConsumed + covered

			if shortfall > 0 then
				local vendorPrice = CraftRoute_VendorPrices and CraftRoute_VendorPrices[key]
				if vendorPrice then
					vendorCovered = shortfall
					cost = cost + shortfall * vendorPrice
					covered = covered + shortfall
					shortfall = 0
				end
			end
		end

		local craftedCovered = 0
		if shortfall > 0 then
			local subRecipe = recipeLookup[key]
			if subRecipe and subRecipe.excludeFromMakeVsBuy then
				subRecipe = nil
			end
			if subRecipe then
				local craftUnitCost = recipe_cost(subRecipe, recipeLookup, cache)
				if craftUnitCost then
					craftedCovered = shortfall
					cost = cost + shortfall * craftUnitCost
					covered = covered + shortfall
					shortfall = 0
				end
			end
		end

		if shortfall > 0 then
			anyShortfall = true
		end
		totalCost = totalCost + cost
		table.insert(perReagent, {name = name, qty = qty, cost = cost, covered = covered, shortfall = shortfall, vendorCovered = vendorCovered, craftedCovered = craftedCovered})
	end

	return totalCost, perReagent, anyShortfall, pathConsumed, supply
end
