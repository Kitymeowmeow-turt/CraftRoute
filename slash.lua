-- CraftRoute slash commands.
--
--   /craftroute <profession>                  - calculate & show the cheapest 1-300 path
--   /craftroute <profession> <target>         - calculate 1 up to a specific skill cap
--   /craftroute <profession> <start> <target> - calculate between any two skill levels
--                                               (e.g. already at 150, just want 150-300)
--   /craftroute list                          - list available profession keys
--
-- Recommended workflow: open the Auction House, click the "CraftRoute" tab,
-- click a profession to scan every reagent it needs (captures real listings
-- with quantities, not just a single price), then run /craftroute <profession>
-- for a report with TRUE depletion-aware costs and AH-supply shortfall warnings.

CraftRoute = CraftRoute or {}

local function profession_list()
	local names = {}
	for k in pairs(CraftRoute_Data) do
		table.insert(names, k)
	end
	table.sort(names)
	return names
end

--------------------------------------------------------------------------
-- Report text builder
--------------------------------------------------------------------------

local BANDS = {{1, 50}, {50, 125}, {125, 200}, {200, 300}}
-- Survival's own recipe thresholds land much more evenly across the full
-- 1-300 range than the other professions' do -- the default bands (sized
-- around where most professions' content actually clusters) don't fit it
-- well, so it gets its own even quarters instead.
local PROFESSION_BANDS = {
	survival = {{1, 75}, {75, 150}, {150, 225}, {225, 300}},
}

-- Splits steps across the fixed skill bands, prorating expected craft count
-- and cost linearly across a step's skill range if it straddles a boundary.
local function split_into_bands(steps, maxSkill, professionKey)
	local bands = (professionKey and PROFESSION_BANDS[professionKey]) or BANDS
	local banded = {}
	-- Tracks whole crafts already allocated to a step's earlier fragments
	-- when it spans a band boundary -- see the comment below for why.
	local allocatedSoFar = {}
	for b = 1, getn(bands) do
		local bandFrom, bandTo = bands[b][1], bands[b][2]
		if bandTo > maxSkill then bandTo = maxSkill end
		if bandFrom < maxSkill then
			local entries, bandTotal = {}, 0
			for i = 1, getn(steps) do
				local s = steps[i]
				local overlapFrom = math.max(s.fromSkill, bandFrom)
				local overlapTo = math.min(s.toSkill, bandTo)
				if overlapTo > overlapFrom then
					local stepRange = s.toSkill - s.fromSkill
					local frac = stepRange > 0 and ((overlapTo - overlapFrom) / stepRange) or 1

					-- A step spanning a band boundary gets split into
					-- fragments here for display, but ShoppingList later
					-- rounds EACH fragment's craft count up separately to
					-- know how many reagents to buy. ceil(a) + ceil(b) is
					-- always >= ceil(a+b) -- rounding fractional fragments
					-- up independently can only ever need as many or more
					-- total reagents than rounding the whole, unsplit step
					-- up once, never fewer. Fixed by allocating whole
					-- crafts up front instead: every fragment except the
					-- last gets floor() of its share, and the last
					-- fragment absorbs whatever's left -- guaranteeing the
					-- fragments always sum to exactly ceil(s.expectedCrafts),
					-- the same total a whole-route calculation would use,
					-- with nothing left for ShoppingList's own ceil() to
					-- inflate further (ceil of an already-whole number is
					-- a no-op).
					local isLastFragment = (overlapTo == s.toSkill)
					local crafts
					if isLastFragment then
						local wholeTotal = math.ceil(s.expectedCrafts)
						crafts = wholeTotal - (allocatedSoFar[i] or 0)
						if crafts < 0 then crafts = 0 end
					else
						crafts = math.floor(s.expectedCrafts * frac)
						allocatedSoFar[i] = (allocatedSoFar[i] or 0) + crafts
					end

					local cost = s.subtotal * frac
					local learnCost = nil
					local learnCostConfidence = nil
					if overlapFrom == s.fromSkill then
						learnCost = s.learnCost
						learnCostConfidence = s.learnCostConfidence
					end
					table.insert(entries, {
						name = s.name,
						recipeIndex = s.recipeIndex,
						fromSkill = overlapFrom,
						toSkill = overlapTo,
						expectedCrafts = crafts,
						subtotal = cost,
						learnCost = learnCost,
						learnCostConfidence = learnCostConfidence,
						scrollName = s.scrollName,
						questObtained = s.questObtained,
						bossObtained = s.bossObtained,
					})
					bandTotal = bandTotal + cost
				end
			end
			table.insert(banded, {from = bandFrom, to = bandTo, total = bandTotal, entries = entries})
		end
	end
	return banded
end

-- Tools some professions need before certain recipes can be crafted at all.
-- Unlike reagents these aren't consumed -- you buy/craft them once and keep
-- them forever. Nothing in ReagentData or AtlasLoot ever tracked this, so
-- rather than pretend to know which specific recipe needs which tool (data
-- we don't actually have), this surfaces the small, well-known set of tools
-- each profession commonly needs so you're not caught without one mid-path.
local PROFESSION_TOOLS = {
	blacksmithing = {
		{name = "Blacksmith Hammer", how = "buy from a Blacksmithing supply vendor (~16c, one-time)"},
	},
	engineering = {
		{name = "Blacksmith Hammer", how = "buy from an Engineering/Blacksmithing supply vendor (~16c, one-time)"},
		{name = "Arclight Spanner", how = "craft it yourself once you hit skill 50 (it's in the list below), or buy off the AH"},
		{name = "Gyromatic Micro-Adjustor", how = "craft it yourself once you hit skill 175 (it's in the list below), or buy off the AH"},
	},
	jewelcrafting = {
		{name = "Jeweler's Kit", how = "buy from a Jewelcrafting supply vendor (2s, one-time)"},
		{name = "Jewelry Lens", how = "buy off the Auction House (one-time, price varies)"},
		{name = "Jewelry Scope", how = "buy off the Auction House (one-time, price varies)"},
		{name = "Precision Jewelry Kit", how = "buy off the Auction House (one-time, price varies)"},
	},
	survival = {
		{name = "Whittle", how = "buy from a Survival supply vendor (54c, one-time)"},
		{name = "Blacksmith Hammer", how = "buy from a Blacksmithing/Engineering supply vendor (~16c, one-time)"},
	},
}

-- Internal guide key (CraftRoute_GuideSteps table key) -> display name shown
-- in reports. Falls back to the raw key itself for any guide added without
-- an entry here.
local GUIDE_DISPLAY_NAMES = {
	wowprofessions = "Wow-Professions.com",
}
local function guide_display_name(guideKey)
	return GUIDE_DISPLAY_NAMES[guideKey] or guideKey
end

local function build_report(professionKey, total_cost, steps, missing, reached, stuckAt, total_learn_cost, any_learn_cost_estimated, startSkill, candidates, chosen, normalComparison)
	startSkill = startSkill or 1
	local lines = {}
	local titleSuffix = (candidates and getn(candidates) > 1 and chosen) and ("  [" .. chosen.label .. "]") or ""
	local capitalizedProf = string.upper(string.sub(professionKey, 1, 1)) .. string.sub(professionKey, 2)
	table.insert(lines, capitalizedProf .. " -- cheapest " .. startSkill .. " to " .. reached .. " route" .. titleSuffix)
	table.insert(lines, "")

	if CraftRoute_Settings and CraftRoute_Settings.orangeOnlySkillups then
		table.insert(lines, "|cffffcc00Mode: Orange leveling recipes only (guaranteed skill-ups).|r")
		table.insert(lines, "")
	end

	if candidates and getn(candidates) > 1 then
		table.insert(lines, "|cffffcc00Guide comparisons (each priced with real AH data, buying lowest first):|r")
		local anyGuideLooksLower = false
		for i = 1, getn(candidates) do
			local c = candidates[i]
			local marker = ""
			if c == chosen then
				marker = "  <- shown below"
			elseif c.total < chosen.total then
				marker = "  <- lower total, see note below"
				anyGuideLooksLower = true
			end
			table.insert(lines, "  " .. c.label .. ": " .. CraftRoute.MoneyString(c.total) .. marker)
		end
		if anyGuideLooksLower then
			table.insert(lines, "|cffffcc00Note: a guide's lower total doesn't always mean a cheaper route --|r")
			table.insert(lines, "|cffffcc00it isn't checked against what's actually available to buy, unlike|r")
			table.insert(lines, "|cffffcc00the route below, which never picks something it can't source.|r")
		end
		table.insert(lines, "")
	end

	local tools = PROFESSION_TOOLS[professionKey]
	if tools then
		table.insert(lines, "|cffffcc00Tools you'll need (one-time, not consumed):|r")
		for i = 1, getn(tools) do
			local tool = tools[i]
			local inPath = false
			for j = 1, getn(steps) do
				if strlower(steps[j].name) == strlower(tool.name) then
					inPath = true
					break
				end
			end
			if inPath then
				table.insert(lines, "  - " .. tool.name .. " -- covered automatically, it's in the route below")
			else
				table.insert(lines, "  - " .. tool.name .. " -- " .. tool.how)
			end
		end
		table.insert(lines, "")
	end

	if stuckAt then
		if CraftRoute_Settings and CraftRoute_Settings.orangeOnlySkillups then
			table.insert(lines, "|cffff4444Route stops at skill " .. stuckAt .. "|r -- no priced orange recipe covers this skill.")
		else
			table.insert(lines, "|cffff4444Route stops at skill " .. stuckAt .. "|r -- no priced recipe covers this range.")
		end
		table.insert(lines, "")
	end

	local sellBackCredit, sellBackItems = CraftRoute.SellBackCredit(professionKey, steps)

	-- Per-band shopping lists, computed with one continuous depletion
	-- timeline across bands (pathConsumed threaded from one call to the
	-- next) -- NOT four independent "fresh order book" scenarios. Doing
	-- them independently would under-count the true total, since band 2
	-- would price its reagents as if band 1 hadn't already bought any of
	-- the cheap listings. Summing these gives exactly the same total as
	-- pricing the whole route in one call would.
	--
	-- supply (byproduct credit) is threaded the same way, for the
	-- opposite reason: without it, a surplus a recipe produces in an
	-- earlier band couldn't credit a reagent NEED in a later band, so
	-- the later band would price itself as if it had to buy that
	-- reagent fresh -- systematically OVER-counting the true total
	-- (confirmed against a real user report where the banded "Total AH
	-- cost" came out consistently higher than the whole-route guide-
	-- comparison total for the identical route -- see DEVNOTES §5).
	local banded = split_into_bands(steps, stuckAt or reached, professionKey)
	local pathConsumed = {}
	local supply = nil
	local trueCost = 0
	local anyShortfall = false
	local bandShopping = {}
	-- Safety net for VISIBILITY_TIE_EPSILON (see core.lua) -- aggregated
	-- across every band into one combined list for the whole route.
	-- Expected to stay empty; see the "Also craft along the way" section
	-- below for what happens if it isn't.
	local allHiddenCrafts = {}
	local allHiddenOrder = {}
	for b = 1, getn(banded) do
		local band = banded[b]
		if getn(band.entries) > 0 then
			local bandCost, bandPerReagent, bandShortfall, bandHiddenCrafts, bandHiddenOrder
			bandCost, bandPerReagent, bandShortfall, pathConsumed, supply, bandHiddenCrafts, bandHiddenOrder = CraftRoute.TrueShoppingCost(professionKey, band.entries, pathConsumed, supply)
			trueCost = trueCost + bandCost
			if bandShortfall then anyShortfall = true end
			bandShopping[b] = bandPerReagent
			if bandHiddenOrder then
				for h = 1, getn(bandHiddenOrder) do
					local hname = bandHiddenOrder[h]
					if not allHiddenCrafts[hname] then
						allHiddenCrafts[hname] = 0
						table.insert(allHiddenOrder, hname)
					end
					allHiddenCrafts[hname] = allHiddenCrafts[hname] + bandHiddenCrafts[hname]
				end
			end
		end
	end
	-- trueCost from the loop above is reagent-only (that's all
	-- TrueShoppingCost/ShoppingList ever deal with) -- training costs are
	-- a separate, one-time, whole-route concept tracked by total_learn_cost,
	-- added in here exactly once rather than per-band. Without this,
	-- "Total AH cost" and the "includes one-time recipe/training costs"
	-- line right below it would be inconsistent with each other -- the
	-- label claims training is already included, but nothing actually put
	-- it there.
	trueCost = trueCost + (total_learn_cost or 0)
	local netCost = trueCost - sellBackCredit

	table.insert(lines, "Total AH cost (actual scanned listings, cheapest first): " .. CraftRoute.MoneyString(trueCost))
	table.insert(lines, "  includes one-time recipe/training costs: " .. CraftRoute.MoneyString(total_learn_cost or 0))
	if sellBackCredit > 0 then
		local checkAH = CraftRoute_Settings and CraftRoute_Settings.includeSellbackScan
		local sellBackLabel = checkAH
			and "  minus selling leftover crafted items (AH or vendor, whichever's better): -"
			or "  Returned money after selling crafts back to vendor: -"
		table.insert(lines, sellBackLabel .. CraftRoute.MoneyString(sellBackCredit))
		local netCostLabel = checkAH and "Total cost after vendor/AH: " or "Total cost after vendoring: "
		table.insert(lines, "|cffFA0C0C" .. netCostLabel .. CraftRoute.MoneyString(netCost) .. "|r")
	end

	-- When strict orange-only leveling is enabled, also price the exact same
	-- reachable skill range using CraftRoute's normal chance-aware optimizer.
	-- This deliberately compares TRUE shopping costs (actual scanned listing
	-- depletion + learn costs), not the greedy loop's internal expected-cost
	-- heuristic. If either route returns money from leftover crafts, compare
	-- the post-sellback net totals too, because that's the number the player
	-- ultimately cares about rather than the gross checkout receipt.
	if normalComparison and normalComparison.total then
		local useNet = sellBackCredit > 0 or (normalComparison.sellBackCredit or 0) > 0
		local orangeCompare = useNet and netCost or trueCost
		local normalCompare = useNet and normalComparison.netTotal or normalComparison.total
		local diff = orangeCompare - normalCompare
		local pct = nil
		if normalCompare > 0 then
			pct = (diff / normalCompare) * 100
		end

		table.insert(lines, "")
		local basis = useNet and ", after sellback" or ""
		table.insert(lines, string.format(
			"|cffffcc00Orange Only vs normal optimized (%d-%d%s):|r",
			startSkill, normalComparison.rangeEnd or reached, basis))
		table.insert(lines, "  Normal optimized: " .. CraftRoute.MoneyString(normalCompare))
		table.insert(lines, "  Orange only:      " .. CraftRoute.MoneyString(orangeCompare))

		if diff >= 0 then
			local pctText = pct and string.format(" (+%.1f%%)", pct) or ""
			table.insert(lines, "  |cffffcc00Extra for guaranteed skill-ups: +" .. CraftRoute.MoneyString(diff) .. pctText .. "|r")
		else
			local saving = -diff
			local pctText = pct and string.format(" (%.1f%%)", pct) or ""
			table.insert(lines, "  |cff00ff00Orange Only is cheaper here: -" .. CraftRoute.MoneyString(saving) .. pctText .. "|r")
		end

		if normalComparison.partial then
			table.insert(lines, "  |cffaaaaaaCompared only through skill " .. (normalComparison.rangeEnd or reached) .. " because Orange Only stops there.|r")
		end
		table.insert(lines, "")
	end
	if any_learn_cost_estimated then
		table.insert(lines, "  |cffffcc00Note: Trainer training costs above are rough guesses at the threshholds 1-100, 100-200, and 200-300.|r")
	end
	if anyShortfall then
		table.insert(lines, "|cffff4444Warning: the AH doesn't have enough of some reagents scanned -- see below.|r")
	end
	if getn(allHiddenOrder) > 0 then
		-- Safety net firing: something is still being crafted invisibly
		-- despite the tie-breaking fix in ApplyDownstreamExtensions/
		-- ApplyRecipeInsertion/ApplyPureProductionExtensions. Surface it
		-- explicitly rather than let the player discover it only by
		-- running short on materials mid-route.
		table.insert(lines, "|cffffcc00Also craft along the way (not shown as its own route step):|r")
		for h = 1, getn(allHiddenOrder) do
			local hname = allHiddenOrder[h]
			table.insert(lines, string.format("  %dx %s", math.ceil(allHiddenCrafts[hname]), hname))
		end
	end
	table.insert(lines, "")
	table.insert(lines, "-- Step-by-step --")

	local function insert_shopping_line(pr)
		if pr.shortfall > 0 then
			table.insert(lines, string.format(
				"  |cffff4444%dx %s -- only %d available on AH! (%s, short %d)|r",
				pr.qty, pr.name, pr.covered, CraftRoute.MoneyString(pr.cost), pr.shortfall
			))
		elseif pr.vendorCovered and pr.vendorCovered > 0 then
			table.insert(lines, string.format(
				"  %dx %s  (%s -- %d from AH, %d from vendor)",
				pr.qty, pr.name, CraftRoute.MoneyString(pr.cost), pr.qty - pr.vendorCovered, pr.vendorCovered
			))
		elseif pr.craftedCovered and pr.craftedCovered > 0 then
			table.insert(lines, string.format(
				"  %dx %s  (%s -- %d from AH, %d crafted)",
				pr.qty, pr.name, CraftRoute.MoneyString(pr.cost), pr.qty - pr.craftedCovered, pr.craftedCovered
			))
		else
			table.insert(lines, string.format("  %dx %s  (%s)", pr.qty, pr.name, CraftRoute.MoneyString(pr.cost)))
		end
	end

	for b = 1, getn(banded) do
		local band = banded[b]
		if getn(band.entries) > 0 then
			table.insert(lines, "")
			table.insert(lines, string.format("%d-%d Shopping list", band.from, band.to))
			local bandPerReagent = bandShopping[b] or {}
			for i = 1, getn(bandPerReagent) do
				insert_shopping_line(bandPerReagent[i])
			end
			table.insert(lines, "")
			table.insert(lines, string.format("[%d-%d]", band.from, band.to))
			for i = 1, getn(band.entries) do
				local e = band.entries[i]
				local learnNote = ""
				if e.learnCost and e.learnCost > 0 then
					local tag = (e.learnCostConfidence == "confirmed" or e.learnCostConfidence == "scanned") and "" or "~"
					learnNote = " +" .. CraftRoute.MoneyString(e.learnCost) .. tag
				end
				local sourceNote
				if e.questObtained then
					sourceNote = " |cffff8000Quest|r"
				elseif e.bossObtained then
					sourceNote = " |cffa335eeBoss|r"
				elseif e.scrollName then
					sourceNote = " |cffffff00Recipe|r"
				else
					sourceNote = " |cff00ff00Trainer|r"
				end
				local nameText = (e.questObtained and ("|cffff8000" .. e.name .. "|r"))
					or (e.bossObtained and ("|cffa335ee" .. e.name .. "|r"))
					or e.name
				table.insert(lines, string.format(
					"  [%d-%d] %s  x%d  (%s)%s%s",
					e.fromSkill, e.toSkill, nameText, math.ceil(e.expectedCrafts),
					CraftRoute.MoneyString(e.subtotal), learnNote, sourceNote
				))
			end
		end
	end

	if getn(sellBackItems) > 0 then
		table.insert(lines, "")
		table.insert(lines, "-- Sell off leftover crafted items --")
		for i = 1, getn(sellBackItems) do
			local si = sellBackItems[i]
			table.insert(lines, string.format(
				"  %dx %s  -> sell to %s  (%s each, %s total)",
				si.qty, si.name, si.sellAt or "?", CraftRoute.MoneyString(si.unitPrice), CraftRoute.MoneyString(si.credit)
			))
		end
	end

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- Slash command handler
--------------------------------------------------------------------------

SLASH_CRAFTROUTE1 = "/craftroute"
SlashCmdList["CRAFTROUTE"] = function(msg)
	if not (CraftRoute.IsAuthorized and CraftRoute.IsAuthorized()) then
		return
	end

	msg = msg or ""
	local args = {}
	for word in string.gfind(msg, "%S+") do
		table.insert(args, strlower(word))
	end

	if getn(args) == 0 or args[1] == "list" then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: available professions:")
		local list = profession_list()
		for i = 1, getn(list) do
			DEFAULT_CHAT_FRAME:AddMessage("  " .. list[i])
		end
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /craftroute <profession> [target skill] OR /craftroute <profession> <start skill> <target skill>")
		return
	end

	local prof = args[1]
	local start = 1
	local target = 300
	if tonumber(args[2]) and tonumber(args[3]) then
		start = tonumber(args[2])
		target = tonumber(args[3])
	elseif tonumber(args[2]) then
		target = tonumber(args[2])
	end
	if not CraftRoute_Data[prof] then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: unknown profession '" .. prof .. "'. Try /craftroute list")
		return
	end

	local total_cost, steps, missing, reached, stuckAt, total_learn_cost, any_learn_cost_estimated = CraftRoute.CalculatePath(prof, target, start)
	if not total_cost then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: " .. tostring(stuckAt))
		return
	end

	-- Orange-only cost comparison. Re-run CraftRoute's own optimizer with the
	-- strict filter temporarily disabled, but only to the exact same skill
	-- level the orange route actually reached. That keeps a route which stops
	-- at an orange gap (for example 1-250 of a requested 1-300) from being
	-- misleadingly compared against a full normal 1-300 route. The setting is
	-- restored immediately before any report/guide logic runs.
	local normalComparison = nil
	if CraftRoute_Settings and CraftRoute_Settings.orangeOnlySkillups and reached and reached > start then
		local compareTarget = reached
		local oldOrangeOnly = CraftRoute_Settings.orangeOnlySkillups
		CraftRoute_Settings.orangeOnlySkillups = false
		local normalCost, normalSteps, normalMissing, normalReached, normalStuckAt, normalLearnCost =
			CraftRoute.CalculatePath(prof, compareTarget, start)
		CraftRoute_Settings.orangeOnlySkillups = oldOrangeOnly

		-- Normal mode is a superset of orange-only choices, so it should always
		-- be able to reach at least this far. Keep the guard anyway; strange scan
		-- data deserves a missing comparison, not an invented percentage.
		if normalCost and normalSteps and normalReached == compareTarget and not normalStuckAt then
			local normalTrue = CraftRoute.TrueShoppingCost(prof, normalSteps) + (normalLearnCost or 0)
			local normalSellBackCredit = CraftRoute.SellBackCredit(prof, normalSteps)
			normalComparison = {
				total = normalTrue,
				sellBackCredit = normalSellBackCredit or 0,
				netTotal = normalTrue - (normalSellBackCredit or 0),
				rangeEnd = compareTarget,
				partial = stuckAt and true or false,
			}
		end
	end

	-- Compare CraftRoute's own optimized route against every static guide
	-- available for this profession. Each candidate is priced with its OWN
	-- fresh order-book state (CalculatePath and CalculateGuidePath each
	-- start pathConsumed empty) -- these are independent "what if I
	-- followed this whole route" scenarios being priced side by side, not
	-- one continuous depletion across all of them.
	local candidates = {}
	local ownTrue = CraftRoute.TrueShoppingCost(prof, steps)
	table.insert(candidates, {
		label = "CraftRoute (optimized)", total = ownTrue + (total_learn_cost or 0),
		total_cost = total_cost, steps = steps, missing = missing, reached = reached,
		stuckAt = stuckAt, total_learn_cost = total_learn_cost,
		any_learn_cost_estimated = any_learn_cost_estimated,
	})

	-- Static guides freely use yellow/green recipes, so their totals are not
	-- comparable to a strict guaranteed-skillup route. Hide that comparison
	-- while orange-only mode is active instead of presenting apples vs RNG.
	if CraftRoute_GuideSteps and not (CraftRoute_Settings and CraftRoute_Settings.orangeOnlySkillups) then
		for guideKey, guideProfs in pairs(CraftRoute_GuideSteps) do
			if guideProfs[prof] then
				local gCost, gSteps, gMissing, gReached, gStuckAt, gLearnCost, gLearnEstimated =
					CraftRoute.CalculateGuidePath(prof, guideKey, target, start)
				if gCost then
					local gTrue = CraftRoute.TrueShoppingCost(prof, gSteps)
					table.insert(candidates, {
						label = guide_display_name(guideKey), total = gTrue + (gLearnCost or 0),
						total_cost = gCost, steps = gSteps, missing = gMissing, reached = gReached,
						stuckAt = gStuckAt, total_learn_cost = gLearnCost,
						any_learn_cost_estimated = gLearnEstimated,
					})
				end
			end
		end
	end

	-- Always show CraftRoute's own route, never auto-switch to a guide
	-- just because its total comes out lower. CraftRoute's main loop
	-- refuses to choose a recipe it can't actually source (see
	-- depletion_aware_reagent_cost_detailed's achievability check) --
	-- a static guide has no such check at all, it's a fixed list
	-- regardless of what's scanned. A guide total that comes out lower
	-- can mean the guide is genuinely cheaper, or it can mean the guide
	-- is quietly relying on more of some scarce reagent than actually
	-- exists, priced at a scarcity-penalty estimate that still
	-- understates the real cost of something that's not really
	-- obtainable in that quantity at all. The comparison itself is
	-- still shown in full below -- this only decides which one gets
	-- used as the actual displayed route.
	local chosen = candidates[1]

	local report = build_report(prof, chosen.total_cost, chosen.steps, chosen.missing, chosen.reached,
		chosen.stuckAt, chosen.total_learn_cost, chosen.any_learn_cost_estimated, start, candidates, chosen, normalComparison)
	CraftRoute.ShowReport("CraftRoute - " .. prof, report)
	DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: " .. prof .. " (" .. chosen.label .. ") total cost "
		.. CraftRoute.MoneyString(chosen.total) .. (chosen.stuckAt and (" (stopped at skill " .. chosen.stuckAt .. ")") or ""))
end
