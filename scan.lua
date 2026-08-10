-- CraftRoute scan.lua -- CraftRoute's own Auction House scanner, independent of
-- aux-addon. Uses the same Blizzard AH API calls (and matching field order)
-- that aux-addon itself uses in this client, so results should agree.
--
-- Stores a lightweight "order book" per item: a list of {unitPrice, qty}
-- listings, most recent scan only (each scan replaces the previous one for
-- that item). This lets CraftRoute compute TRUE depletion-aware costs --
-- "buy the 40 cheapest units available" -- instead of assuming unlimited
-- supply at a single lowest price.

CraftRoute = CraftRoute or {}
CraftRoute_Scans = CraftRoute_Scans or {}

-- Fast path: as soon as every row on the current AH page has a resolved
-- item name, the page is safe to consume immediately. Some external tools
-- clear the client-side browse throttle before AUCTION_ITEM_LIST_UPDATE
-- fires, which lets a scan advance at actual server round-trip/cache speed
-- instead of imposing an extra fixed delay on every item/page. Nothing
-- here requires such a tool -- CanSendAuctionQuery() just reports the
-- real client state either way, so a stock client behaves exactly as
-- before.
--
-- Keep the old 0.6s quiet-period behavior only as a fallback. Vanilla 1.12 can
-- briefly expose auction rows whose item names are still waiting on the local
-- item cache; if those never finish resolving, we eventually process the page
-- exactly as the old scanner did rather than hanging forever.
local QUIET_PERIOD = 0.6
local PAGE_SIZE = 50

local scanFrame = CreateFrame("Frame")

-- Deferred-callback queue: anything that needs to call a scan-completion
-- callback (onDone) does it through here instead of calling it directly.
-- This guarantees completion ALWAYS happens on a later OnUpdate tick, never
-- synchronously/reentrantly inside whatever call started the scan -- e.g.
-- Scan All's onDone is scan_all_step itself, which starts the NEXT scan;
-- if that happened synchronously (nested inside the current StartScan call,
-- which is itself possibly nested inside an even earlier deferred call),
-- multiple scans could end up mutating the single shared `state` table
-- from different points in the same call stack at once. Routing every
-- completion through this queue means there's exactly one call site
-- (the OnUpdate handler below) that ever actually invokes an onDone.
local pendingCallbacks = {}
local function defer_callback(fn)
	if fn then
		table.insert(pendingCallbacks, fn)
	end
end

--------------------------------------------------------------------------
-- Scan state machine
--------------------------------------------------------------------------

local state = {
	active = false,
	mode = "exact",   -- "exact" (one queue item = one exact item name, materials scan)
	                  -- or "prefix" (one queue item = a search prefix like "plans",
	                  -- recipe scan -- a single query can surface many different
	                  -- scrolls at once instead of one query per scroll name)
	queue = {},       -- list of item names (lowercase), or prefixes in prefix mode
	queueIndex = 0,
	currentName = nil,
	page = 0,
	collected = {},        -- exact mode: listings collected so far for currentName across pages
	collectedByName = {},  -- prefix mode: {[discoveredName] = {listings...}} across all pages of the current prefix
	knownNames = nil,      -- prefix mode: set of exact scroll names (lowercase) we're allowed to keep
	lastUpdateTime = nil,
	awaitingUpdate = false,
	professionKey = nil,
	totalItems = 0,
	onProgress = nil, -- optional callback(currentIndex, totalItems, currentName)
	onDone = nil,     -- optional callback()
}

local function reset_state()
	state.active = false
	state.mode = "exact"
	state.queue = {}
	state.queueIndex = 0
	state.currentName = nil
	state.page = 0
	state.collected = {}
	state.collectedByName = {}
	state.knownNames = nil
	state.lastUpdateTime = nil
	state.awaitingUpdate = false
end

function CraftRoute.IsScanning()
	return state.active
end

function CraftRoute.CancelScan()
	reset_state()
end

-- Shared: kicks off a scan across an arbitrary list of item names (already
-- lowercased, deduped, sorted), or a list of search prefixes in "prefix" mode.
-- advance_queue is called from here but defined further down (used by
-- multiple functions in between) -- forward-declared as local so the
-- reference below resolves to the real upvalue once it's assigned, rather
-- than silently compiling as a nil global lookup.
local advance_queue
local function start_scan_with_queue(professionKey, queue, onProgress, onDone, mode, knownNames)
	if state.active then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: a scan is already running.")
		return
	end
	reset_state()
	state.active = true
	state.mode = mode or "exact"
	state.queue = queue
	state.totalItems = getn(queue)
	state.professionKey = professionKey
	state.onProgress = onProgress
	state.onDone = onDone
	state.knownNames = knownNames
	state.queueIndex = 0
	advance_queue()
end

-- Starts scanning every unique reagent used by a profession, and (only if
-- CraftRoute_Settings.includeSellbackScan is checked) also every recipe's
-- own crafted output -- needed so the "sell leftover items" recommendation
-- can compare a real AH price against the vendor price instead of
-- defaulting to vendor for lack of any market data. Leaving the box
-- unchecked (the default) skips this extra half of the queue for a faster
-- scan, at the cost of always just recommending vendor-selling leftovers
-- without checking if the AH would pay more.
-- onProgress(currentIndex, totalItems, currentName) is called as each item finishes.
-- onDone() is called when the whole queue completes.
-- startSkill (optional): if given, skips reagents that are only needed by
-- recipes already entirely grey at that skill -- e.g. starting a route at
-- 250 has no use for a recipe that goes grey at 200, so there's no reason
-- to scan its reagents. Materials still needed as a substitution source for
-- a genuinely relevant recipe are kept regardless of that sub-recipe's own
-- grey status (see CraftRoute.GetReachableMaterialNames).
function CraftRoute.StartProfessionScan(professionKey, onProgress, onDone, startSkill)
	local recipes = CraftRoute_Data[professionKey]
	if not recipes then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: no data for '" .. tostring(professionKey) .. "'")
		return
	end

	local checkAH = CraftRoute.SELLBACK_ENABLED and CraftRoute_Settings and CraftRoute_Settings.includeSellbackScan
	local reachable = CraftRoute.GetReachableMaterialNames(professionKey, startSkill, checkAH)
	local queue = {}
	for name in pairs(reachable) do
		table.insert(queue, name)
	end
	table.sort(queue)

	start_scan_with_queue(professionKey, queue, onProgress, onDone)
end

-- Starts scanning every unique "recipe scroll" (Plans:/Pattern:/Schematic:/
-- Formula:/Recipe:) needed to LEARN a profession's non-trainer recipes.
-- These can be very expensive (sometimes 1000g+) but are one-time purchases,
-- and are priced/consumed exactly like a reagent by CraftRoute's cost model --
-- just against the recipe's own scrollName instead of a crafting reagent.
--
-- Rather than one exact-name AH query per scroll (50+ round trips for a
-- profession like Blacksmithing), this searches by PREFIX instead --
-- "Plans:", "Pattern:", etc -- since the Auction House's own search already
-- does substring matching and returns every matching listing across as many
-- pages as needed. One prefix search can surface dozens of different scrolls
-- in a handful of queries instead of one query per scroll. Most professions
-- use a single prefix; Blacksmithing is a rare exception with one item
-- ("Inlaid Mithril Cylinder") under "Recipe:" instead of "Plans:", so both
-- get searched. A prefix search naturally also picks up other professions'
-- scrolls sharing the same prefix (e.g. Jewelcrafting also uses "Plans:") --
-- those are simply ignored since they aren't in this profession's knownNames.
--
-- No skill-range filtering here (unlike StartProfessionScan) -- it wouldn't
-- actually save any scan time. A prefix query still has to page through
-- every result for that prefix regardless of how many specific scroll
-- names are relevant; filtering only changes what gets stored afterward,
-- not how many queries or pages are needed to get there.
function CraftRoute.StartRecipeScan(professionKey, onProgress, onDone)
	local recipes = CraftRoute_Data[professionKey]
	if not recipes then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: no data for '" .. tostring(professionKey) .. "'")
		return
	end

	local knownNames = {}
	local prefixSeen, prefixQueue = {}, {}
	for i = 1, getn(recipes) do
		local recipe = recipes[i]
		local scrollName = recipe.scrollName
		if scrollName and not recipe.excluded then
			local lname = strlower(scrollName)
			knownNames[lname] = true
			local colonPos = strfind(scrollName, ":", 1, true)
			if colonPos then
				local prefix = strlower(string.sub(scrollName, 1, colonPos))
				if not prefixSeen[prefix] then
					prefixSeen[prefix] = true
					table.insert(prefixQueue, prefix)
				end
			end
		end
	end
	table.sort(prefixQueue)

	if getn(prefixQueue) == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("CraftRoute: no known recipe scrolls to scan for '" .. professionKey .. "' (either everything's trainer-taught, or scroll names aren't known yet).")
		defer_callback(onDone)
		return
	end

	start_scan_with_queue(professionKey, prefixQueue, onProgress, onDone, "prefix", knownNames)
end

-- Starts ONE combined materials scan across MULTIPLE professions at once --
-- a single deduplicated queue (a material shared by several professions,
-- e.g. Copper Bar, only gets scanned once) instead of running each
-- profession's own StartProfessionScan back-to-back as separate chained
-- jobs. Built for "Scan All" specifically, replacing an earlier approach
-- that chained 9 professions x 2 kinds = 18 separate onDone hops together
-- -- the suspected source of an earlier, never-fully-confirmed "restarts
-- partway through" symptom. Fewer chained jobs means less surface area
-- for that class of problem, on top of being strictly faster (no
-- re-scanning the same shared material once per profession that uses it).
-- professionKeys: list of profession keys to include (caller's
-- responsibility to exclude any disabled ones -- scan.lua doesn't know
-- about that UI-level concept).
function CraftRoute.StartCombinedMaterialsScan(professionKeys, onProgress, onDone)
	local checkAH = CraftRoute.SELLBACK_ENABLED and CraftRoute_Settings and CraftRoute_Settings.includeSellbackScan
	local reachable = {}
	for i = 1, getn(professionKeys) do
		local prof = professionKeys[i]
		if CraftRoute_Data[prof] then
			local profReachable = CraftRoute.GetReachableMaterialNames(prof, nil, checkAH)
			for name in pairs(profReachable) do
				reachable[name] = true
			end
		end
	end
	local queue = {}
	for name in pairs(reachable) do
		table.insert(queue, name)
	end
	table.sort(queue)

	if getn(queue) == 0 then
		defer_callback(onDone)
		return
	end

	start_scan_with_queue("all", queue, onProgress, onDone)
end

-- Starts ONE combined recipe-scroll scan across MULTIPLE professions at
-- once -- one deduplicated set of prefixes (e.g. "plans:" only searched
-- once even though both Jewelcrafting and Blacksmithing use it) and known
-- scroll names, instead of a separate StartRecipeScan job per profession.
-- Same reasoning as StartCombinedMaterialsScan above.
function CraftRoute.StartCombinedRecipeScan(professionKeys, onProgress, onDone)
	local knownNames = {}
	local prefixSeen, prefixQueue = {}, {}
	for i = 1, getn(professionKeys) do
		local prof = professionKeys[i]
		local recipes = CraftRoute_Data[prof]
		if recipes then
			for j = 1, getn(recipes) do
				local recipe = recipes[j]
				local scrollName = recipe.scrollName
				if scrollName and not recipe.excluded then
					local lname = strlower(scrollName)
					knownNames[lname] = true
					local colonPos = strfind(scrollName, ":", 1, true)
					if colonPos then
						local prefix = strlower(string.sub(scrollName, 1, colonPos))
						if not prefixSeen[prefix] then
							prefixSeen[prefix] = true
							table.insert(prefixQueue, prefix)
						end
					end
				end
			end
		end
	end
	table.sort(prefixQueue)

	if getn(prefixQueue) == 0 then
		defer_callback(onDone)
		return
	end

	start_scan_with_queue("all", prefixQueue, onProgress, onDone, "prefix", knownNames)
end

advance_queue = function()
	state.queueIndex = state.queueIndex + 1
	if state.queueIndex > getn(state.queue) then
		state.active = false
		defer_callback(state.onDone)
		return
	end
	state.currentName = state.queue[state.queueIndex]
	state.page = 0
	state.collected = {}
	state.collectedByName = {}
	if state.onProgress then
		state.onProgress(state.queueIndex, state.totalItems, state.currentName)
	end
	-- CanSendAuctionQuery gate happens in the OnUpdate loop
end

local function send_query()
	QueryAuctionItems(state.currentName, nil, nil, nil, nil, nil, state.page, nil, nil)
	state.awaitingUpdate = true
	state.lastUpdateTime = GetTime()
end

-- Returns true once every row currently reported by the AH has enough item
-- cache data for CraftRoute to safely identify it. Price/count fields come
-- from the auction result itself; the item name is the part that may lag while
-- the 1.12 client resolves its item cache.
local function current_page_ready()
	local numBatch = GetNumAuctionItems("list")
	for i = 1, numBatch do
		local name = GetAuctionItemInfo("list", i)
		if not name then
			return false
		end
	end
	return true
end

local function finalize_current_page()
	local numBatch, totalAuctions = GetNumAuctionItems("list")

	if state.mode == "prefix" then
		for i = 1, numBatch do
			local name, _, count, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
			if name and count and count > 0 and buyoutPrice and buyoutPrice > 0 then
				local lname = strlower(name)
				if state.knownNames[lname] then
					local unitPrice = math.ceil(buyoutPrice / count)
					if not state.collectedByName[lname] then
						state.collectedByName[lname] = {}
					end
					table.insert(state.collectedByName[lname], {unitPrice = unitPrice, qty = count})
				end
			end
		end

		if totalAuctions and numBatch == PAGE_SIZE and (state.page + 1) * PAGE_SIZE < totalAuctions then
			state.page = state.page + 1
			state.awaitingUpdate = false
			return
		end

		-- done with this prefix across all its pages: store every scroll we
		-- matched along the way. A prefix scan might legitimately match zero
		-- new scrolls this pass (nobody's selling any right now) -- that's
		-- fine, just move on to the next prefix.
		for lname, listings in pairs(state.collectedByName) do
			table.sort(listings, function(a, b) return a.unitPrice < b.unitPrice end)
			CraftRoute_Scans[lname] = {
				timestamp = time(),
				listings = listings,
			}
		end
		state.awaitingUpdate = false
		advance_queue()
		return
	end

	-- exact mode (materials scan): unchanged from before
	for i = 1, numBatch do
		local name, _, count, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
		if name and count and count > 0 and buyoutPrice and buyoutPrice > 0 then
			if strlower(name) == state.currentName then
				local unitPrice = math.ceil(buyoutPrice / count)
				table.insert(state.collected, {unitPrice = unitPrice, qty = count})
			end
		end
	end

	if totalAuctions and numBatch == PAGE_SIZE and (state.page + 1) * PAGE_SIZE < totalAuctions then
		state.page = state.page + 1
		state.awaitingUpdate = false
		-- next OnUpdate tick will send the next page once throttle allows
		return
	end

	-- done with this item: consolidate and store
	table.sort(state.collected, function(a, b) return a.unitPrice < b.unitPrice end)
	CraftRoute_Scans[state.currentName] = {
		timestamp = time(),
		listings = state.collected,
	}
	state.awaitingUpdate = false
	advance_queue()
end

scanFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
scanFrame:SetScript("OnEvent", function()
	if state.active and state.awaitingUpdate then
		state.lastUpdateTime = GetTime()

		-- Do not impose QUIET_PERIOD when the page is already complete. If
		-- something has cleared the browse throttle before this event is
		-- dispatched, CanSendAuctionQuery() is already true here, so finalize
		-- now and send the next item/page immediately instead of waiting out
		-- the fallback period for nothing. On a stock client this check simply
		-- fails (the throttle isn't clear yet) and the normal OnUpdate path
		-- below runs exactly as before.
		if CanSendAuctionQuery() and current_page_ready() then
			finalize_current_page()

			if state.active and not state.awaitingUpdate and state.currentName and CanSendAuctionQuery() then
				send_query()
			end
		end
	end
end)

scanFrame:SetScript("OnUpdate", function()
	if getn(pendingCallbacks) > 0 then
		-- Drain one per tick, oldest first. In practice there's only ever
		-- one pending at a time (a scan can't finish twice before this
		-- runs), but processing the queue rather than assuming exactly one
		-- entry costs nothing and is safer if that ever changes.
		local fn = table.remove(pendingCallbacks, 1)
		fn()
	end
	if not state.active then return end
	if state.awaitingUpdate then
		if state.lastUpdateTime and (GetTime() - state.lastUpdateTime) >= QUIET_PERIOD then
			finalize_current_page()
		end
	else
		if state.currentName and CanSendAuctionQuery() then
			send_query()
		end
	end
end)

--------------------------------------------------------------------------
-- Order-book pricing
--------------------------------------------------------------------------

-- Cheapest single unit price currently on the AH for an item, or nil if
-- CraftRoute has never scanned it (or found nothing).
function CraftRoute.ScannedUnitPrice(itemName)
	local rec = CraftRoute_Scans[strlower(itemName)]
	if not rec or getn(rec.listings) == 0 then return nil end
	return rec.listings[1].unitPrice
end

-- Depletion-aware cost of buying `qty` units: consumes the cheapest listings
-- first, summing true cost. `alreadyConsumed` (optional, default 0) skips
-- that many units from the front of the listings first -- used to price
-- "the next N units after what's already spoken for elsewhere in this same
-- path calculation" rather than always assuming the cheapest listings are
-- untouched. Returns:
--   cost       -- total copper cost of whatever could be covered
--   covered    -- how many units were actually available to price
--   shortfall  -- qty - covered (0 if fully covered)
function CraftRoute.OrderBookCost(itemName, qty, alreadyConsumed)
	local rec = CraftRoute_Scans[strlower(itemName)]
	if not rec or getn(rec.listings) == 0 then
		return 0, 0, qty
	end
	local toSkip = alreadyConsumed or 0
	local remaining = qty
	local cost = 0
	local covered = 0
	for i = 1, getn(rec.listings) do
		if remaining <= 0 then break end
		local listing = rec.listings[i]
		local available = listing.qty
		if toSkip > 0 then
			local skipHere = math.min(toSkip, available)
			toSkip = toSkip - skipHere
			available = available - skipHere
		end
		if available > 0 then
			local take = math.min(remaining, available)
			cost = cost + take * listing.unitPrice
			covered = covered + take
			remaining = remaining - take
		end
	end
	return cost, covered, qty - covered
end

function CraftRoute.ScanTimestamp(itemName)
	local rec = CraftRoute_Scans[strlower(itemName)]
	return rec and rec.timestamp or nil
end
