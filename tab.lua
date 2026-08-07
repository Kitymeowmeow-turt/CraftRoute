-- CraftRoute tab.lua -- injects a "CraftRoute" tab into the default Blizzard
-- Auction House frame, with one-click buttons to scan every reagent a
-- profession needs.

CraftRoute = CraftRoute or {}

local tab, panel
local statusText, progressBar
local profButtons = {}

-- Professions temporarily disabled in the UI (not confident in their data
-- yet) -- shown greyed out and unclickable rather than removed entirely.
local DISABLED_PROFESSIONS = {}

local function profession_list()
	local names = {}
	for k in pairs(CraftRoute_Data) do
		table.insert(names, k)
	end
	table.sort(names)
	return names
end

local function set_status(text)
	if statusText then statusText:SetText(text or "") end
end

local function on_scan_progress(index, total, name)
	set_status(string.format("Scanning %d/%d: %s", index, total, name))
	if progressBar then
		progressBar:SetValue(total > 0 and (index / total) or 0)
	end
	for i = 1, getn(profButtons) do
		profButtons[i]:Disable()
	end
end

local function on_scan_done(professionKey)
	return function()
		set_status("Done scanning " .. professionKey .. ". Use the Create CraftRoute button, or run /craftroute " .. professionKey .. " to see the route.")
		if progressBar then progressBar:SetValue(1) end
		local list = profession_list()
		for i = 1, getn(profButtons) do
			if not DISABLED_PROFESSIONS[list[i]] then profButtons[i]:Enable() end
		end
	end
end

local function start_scan(professionKey, startSkill)
	if CraftRoute.IsScanning and CraftRoute.IsScanning() then
		set_status("A scan is already running.")
		return
	end
	if startSkill then
		set_status("Starting scan of " .. professionKey .. " (from skill " .. startSkill .. ")...")
	else
		set_status("Starting scan of " .. professionKey .. "...")
	end
	CraftRoute.StartProfessionScan(professionKey, on_scan_progress, function()
		set_status("Materials done for " .. professionKey .. ", starting recipes...")
		CraftRoute.StartRecipeScan(professionKey, on_scan_progress, on_scan_done(professionKey))
	end, startSkill)
end

-- Scan-all: one combined materials scan across every enabled profession
-- (deduplicated -- a material used by several professions only gets
-- scanned once), then one combined recipe-scroll scan the same way.
-- Replaces an earlier approach that chained 9 professions x 2 kinds = 18
-- separate jobs together -- see StartCombinedMaterialsScan's own comment
-- in scan.lua for why that got simplified down to just these two stages.
local scanAllButton
local scanAllStage = 0 -- 0 = not running, 1 = materials in progress, 2 = recipes in progress

local function enabled_profession_list()
	local list = profession_list()
	local enabled = {}
	for i = 1, getn(list) do
		if not DISABLED_PROFESSIONS[list[i]] then
			table.insert(enabled, list[i])
		end
	end
	return enabled
end

local function scan_all_finish()
	scanAllStage = 0
	set_status("Scan All complete.")
	if progressBar then progressBar:SetValue(1) end
	local list = profession_list()
	for i = 1, getn(profButtons) do
		if not DISABLED_PROFESSIONS[list[i]] then profButtons[i]:Enable() end
	end
	if scanAllButton then scanAllButton:Enable() end
end

local function scan_all_step()
	if scanAllStage == 1 then
		scanAllStage = 2
		set_status("Scan All: starting combined recipe scan...")
		CraftRoute.StartCombinedRecipeScan(enabled_profession_list(), on_scan_progress, scan_all_step)
	else
		scan_all_finish()
	end
end

local function start_scan_all()
	if CraftRoute.IsScanning and CraftRoute.IsScanning() then
		set_status("A scan is already running.")
		return
	end
	local enabled = enabled_profession_list()
	if getn(enabled) == 0 then
		set_status("No enabled professions to scan.")
		return
	end
	scanAllStage = 1
	if scanAllButton then scanAllButton:Disable() end
	set_status("Scan All: starting combined materials scan...")
	CraftRoute.StartCombinedMaterialsScan(enabled, on_scan_progress, scan_all_step)
end

local function capitalize(s)
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

local function build_panel()
	panel = CreateFrame("Frame", "CraftRouteAuctionPanel", AuctionFrame)
	panel:SetPoint("TOPLEFT", AuctionFrame, "TOPLEFT", 0, 0)
	panel:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
	panel:SetFrameStrata("HIGH")
	panel:Hide()

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", panel, "TOP", 0, -60)
	title:SetText("CraftRoute -- v2.11.2 -- Scan Reagents")

	local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
	subtitle:SetText("Turdcutter's CraftRoute")

	-- Scroll frame removed -- back to plain direct children of panel so the
	-- raw positions are visible without a scroll wrapper in the mix.
	local list = profession_list()
	local buttonWidth, buttonHeight, spacing = 130, 20, 1
	local createButtonWidth = 150
	local boxWidth = 35
	local gap = 6
	-- Width of everything to the right of the main profession button: the
	-- Create CraftRoute button plus its two number boxes and the gaps
	-- between them. Used below to position the sellback checkbox correctly
	-- relative to this now-wider column.
	local rightColumnWidth = createButtonWidth + gap + boxWidth + gap + boxWidth
	local startY = -126
	for i = 1, getn(list) do
		local key = list[i]
		local rowY = startY - (i - 1) * (buttonHeight + spacing)
		local disabled = DISABLED_PROFESSIONS[key]

		local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		btn:SetWidth(buttonWidth)
		btn:SetHeight(buttonHeight)
		btn:SetPoint("TOP", panel, "TOP", -(rightColumnWidth + gap) / 2, rowY)
		btn:SetText(capitalize(key))
		if disabled then btn:Disable() end
		table.insert(profButtons, btn)

		local createBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		createBtn:SetWidth(createButtonWidth)
		createBtn:SetHeight(buttonHeight)
		createBtn:SetPoint("LEFT", btn, "RIGHT", gap - 5, 0)
		createBtn:SetText("Create CraftRoute")

		-- Two small number boxes, to the right of Create CraftRoute,
		-- defaulting to the full 1-300 range -- editable by the player
		-- before clicking the button.
		local startBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
		startBox:SetWidth(boxWidth)
		startBox:SetHeight(buttonHeight - 4)
		startBox:SetPoint("LEFT", createBtn, "RIGHT", gap + 5, 0)
		startBox:SetAutoFocus(false)
		startBox:SetNumeric(true)
		startBox:SetMaxLetters(3)
		startBox:SetText("1")

		local targetBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
		targetBox:SetWidth(boxWidth)
		targetBox:SetHeight(buttonHeight - 4)
		targetBox:SetPoint("LEFT", startBox, "RIGHT", gap + 5, 0)
		targetBox:SetAutoFocus(false)
		targetBox:SetNumeric(true)
		targetBox:SetMaxLetters(3)
		targetBox:SetText("300")

		btn:SetScript("OnClick", function() start_scan(key, tonumber(startBox:GetText())) end)

		createBtn:SetScript("OnClick", function()
			local startVal = startBox:GetText()
			local targetVal = targetBox:GetText()
			if not startVal or startVal == "" then startVal = "1" end
			if not targetVal or targetVal == "" then targetVal = "300" end
			SlashCmdList["CRAFTROUTE"](key .. " " .. startVal .. " " .. targetVal)
		end)
		if disabled then
			createBtn:Disable()
			startBox:EnableMouse(false)
			startBox:SetTextColor(0.5, 0.5, 0.5, 1)
			targetBox:EnableMouse(false)
			targetBox:SetTextColor(0.5, 0.5, 0.5, 1)
		end
	end

	local belowListY = startY - getn(list) * (buttonHeight + spacing) - 20
	local leftEdgeX = -(rightColumnWidth + gap) / 2  -- same anchor the profession buttons use

	local sellbackCheck = CreateFrame("CheckButton", "CraftRouteSellbackCheck", panel, "UICheckButtonTemplate")
	sellbackCheck:SetWidth(20)
	sellbackCheck:SetHeight(20)
	sellbackCheck:SetPoint("TOPLEFT", panel, "TOP", leftEdgeX - 65, belowListY)
	if CraftRoute.SELLBACK_ENABLED then
		sellbackCheck:SetChecked(CraftRoute_Settings and CraftRoute_Settings.includeSellbackScan)
		sellbackCheck:SetScript("OnClick", function()
			CraftRoute_Settings.includeSellbackScan = (sellbackCheck:GetChecked() and true) or false
		end)
	else
		sellbackCheck:SetChecked(false)
		sellbackCheck:Disable()
	end

	local sellbackLabel1 = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sellbackLabel1:SetJustifyH("LEFT")
	sellbackLabel1:SetPoint("LEFT", sellbackCheck, "RIGHT", 4, 0)
	if CraftRoute.SELLBACK_ENABLED then
		sellbackLabel1:SetText("Sell extra crafts back to AH if ")
	else
		sellbackLabel1:SetText("Sell-back disabled (vendor prices being verified)")
		sellbackLabel1:SetTextColor(0.5, 0.5, 0.5, 1)
	end

	local thresholdBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	thresholdBox:SetWidth(35)
	thresholdBox:SetHeight(16)
	thresholdBox:SetPoint("LEFT", sellbackLabel1, "RIGHT", 8, 0)
	thresholdBox:SetAutoFocus(false)
	thresholdBox:SetNumeric(true)
	thresholdBox:SetMaxLetters(3)
	thresholdBox:SetText(tostring((CraftRoute_Settings and CraftRoute_Settings.sellBackThresholdPercent) or 50))
	local function save_threshold()
		local val = tonumber(thresholdBox:GetText())
		if not val or val < 0 then val = 50 end
		CraftRoute_Settings.sellBackThresholdPercent = val
	end
	thresholdBox:SetScript("OnEnterPressed", function() save_threshold(); thresholdBox:ClearFocus() end)
	thresholdBox:SetScript("OnEditFocusLost", save_threshold)

	local sellbackLabel2 = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sellbackLabel2:SetJustifyH("LEFT")
	sellbackLabel2:SetPoint("LEFT", thresholdBox, "RIGHT", 8, 0)
	sellbackLabel2:SetText("% above vendor price")
	if not CraftRoute.SELLBACK_ENABLED then
		thresholdBox:Hide()
		sellbackLabel2:Hide()
	end

	scanAllButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	scanAllButton:SetWidth(160)
	scanAllButton:SetHeight(20)
	scanAllButton:SetPoint("LEFT", sellbackLabel2, "RIGHT", 12, 0)
	scanAllButton:SetText("Scan All Professions")
	scanAllButton:SetScript("OnClick", start_scan_all)

	-- Warning row: aligned with the label text after the checkbox (not the
	-- checkbox itself), red, sitting between the checkbox row and the
	-- progress bar/cancel row below it.
	local sellbackWarning = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sellbackWarning:SetJustifyH("LEFT")
	sellbackWarning:SetTextColor(1, 0.2, 0.2)
	sellbackWarning:SetPoint("TOPLEFT", sellbackLabel1, "BOTTOMLEFT", 0, -8)
	sellbackWarning:SetText("The check box above increases scan time significantly, every item you can make has to be scanned.")

	local barBg = CreateFrame("Frame", nil, panel)
	barBg:SetWidth(300)
	barBg:SetHeight(20)
	-- X and Y controlled independently: horizontal shift is measured from
	-- where this row already was (scanAllButton), vertical position stacks
	-- below the new warning text row.
	barBg:SetPoint("LEFT", scanAllButton, "LEFT", -325, 0)
	barBg:SetPoint("TOP", sellbackWarning, "BOTTOM", 0, -20)
	barBg:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
	})
	barBg:SetBackdropColor(0, 0, 0, 0.5)

	progressBar = CreateFrame("StatusBar", nil, barBg)
	progressBar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 2, -2)
	progressBar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", -2, 2)
	progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	progressBar:SetStatusBarColor(0.2, 0.6, 0.9)
	progressBar:SetMinMaxValues(0, 1)
	progressBar:SetValue(0)

	statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusText:SetPoint("TOP", barBg, "BOTTOM", 0, -4)
	statusText:SetText("")

	-- Cancel button sits beside the progress bar (to its right), not below
	-- it -- best-effort placement in that lower-right area near the bar;
	-- exact alignment with any pre-existing AuctionFrame chrome there
	-- hasn't been verified against a live client.
	local cancelBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	cancelBtn:SetWidth(100)
	cancelBtn:SetHeight(22)
	cancelBtn:SetPoint("LEFT", barBg, "RIGHT", 12, 0)
	cancelBtn:SetText("Cancel scan")
	cancelBtn:SetScript("OnClick", function()
		if CraftRoute.CancelScan then CraftRoute.CancelScan() end
		set_status("Scan cancelled.")
		for i = 1, getn(profButtons) do
			if not DISABLED_PROFESSIONS[list[i]] then profButtons[i]:Enable() end
		end
	end)

	CraftRoute.panel = panel
end

local function show_panel()
	if not (CraftRoute.IsAuthorized and CraftRoute.IsAuthorized()) then
		AuctionFrameBrowse:Show()
		return
	end
	if not panel then build_panel() end
	AuctionFrameBrowse:Hide()
	AuctionFrameBid:Hide()
	AuctionFrameAuctions:Hide()
	panel:Show()
end

local function hide_panel()
	if panel then panel:Hide() end
end

local originalTabClick = nil

local function install_tab()
	if tab then return end
	if not AuctionFrame then return end
	if not (CraftRoute.IsAuthorized and CraftRoute.IsAuthorized()) then return end

	local tabId = (AuctionFrame.numTabs or 3) + 1
	local tabName = "AuctionFrameTab" .. tabId
	tab = CreateFrame("Button", tabName, AuctionFrame, "AuctionTabTemplate")
	tab:SetID(tabId)
	tab:SetText("CraftRoute")
	tab:SetPoint("LEFT", _G["AuctionFrameTab" .. (tabId - 1)], "RIGHT", -8, 0)
	PanelTemplates_SetNumTabs(AuctionFrame, tabId)
	PanelTemplates_TabResize(0, tab)

	originalTabClick = AuctionFrameTab_OnClick
	AuctionFrameTab_OnClick = function(id)
		id = id or this:GetID()
		if id == tabId then
			PanelTemplates_SetTab(AuctionFrame, id)
			show_panel()
		else
			hide_panel()
			originalTabClick(id)
		end
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
	if arg1 == "Blizzard_AuctionUI" or (AuctionFrame and not tab) then
		install_tab()
	end
end)

-- In case Blizzard_AuctionUI is already loaded by the time CraftRoute loads
if AuctionFrame then
	install_tab()
end
