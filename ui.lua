-- CraftRoute UI: a simple scrollable report window.

CraftRoute = CraftRoute or {}

local function money_string(copper)
	if not copper then return "?" end
	copper = math.floor(copper + 0.5)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper - gold * 10000) / 100)
	local cop = copper - gold * 10000 - silver * 100
	return string.format("%dg %ds %dc", gold, silver, cop)
end
CraftRoute.MoneyString = money_string

local frame

local function create_frame()
	if frame then return frame end

	frame = CreateFrame("Frame", "CraftRouteFrame", UIParent)
	frame:SetWidth(520)
	frame:SetHeight(480)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	frame:Hide()

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -16)
	title:SetText("CraftRoute")
	frame.title = title

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	local scroll = CreateFrame("ScrollFrame", "CraftRouteScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -44)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 16)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function()
		local current = this:GetVerticalScroll()
		local maxScroll = this:GetVerticalScrollRange()
		local newScroll = current - (arg1 * 20)
		if newScroll < 0 then newScroll = 0 end
		if newScroll > maxScroll then newScroll = maxScroll end
		this:SetVerticalScroll(newScroll)
	end)
	frame.scroll = scroll

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetWidth(460)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEscapePressed", function() frame:Hide() end)
	scroll:SetScrollChild(edit)
	frame.edit = edit

	-- Hidden FontString used purely to measure the true rendered height of
	-- the report text, including word-wrapped lines. GetStringHeight()
	-- accounts for wrapping correctly; counting "\n" characters does not --
	-- any line longer than the box width silently becomes 2+ visual lines,
	-- and the scroll frame never finds out, so it caps out short of the
	-- real bottom of the text.
	local measure = frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	measure:SetWidth(460)
	measure:Hide()
	frame.measure = measure

	return frame
end

-- Shows the report window populated with `text`.
function CraftRoute.ShowReport(titleText, text)
	local f = create_frame()
	f.title:SetText(titleText or "CraftRoute")
	text = text or ""
	f.edit:SetText(text)
	if f.edit.SetCursorPosition then
		f.edit:SetCursorPosition(0)
	end

	f.measure:SetText(text)

	-- GetHeight() can return a stale value (from before this SetText call,
	-- or 0) if read on the same frame the text was just set -- the game's
	-- layout system hasn't necessarily recomputed it yet. Deferring the
	-- read by a couple of OnUpdate ticks gives it time to catch up before
	-- sizing the scrollable area, rather than sizing it too small based on
	-- outdated info.
	local waitFrames = 3
	f:SetScript("OnUpdate", function()
		waitFrames = waitFrames - 1
		if waitFrames > 0 then return end
		f:SetScript("OnUpdate", nil)

		local measuredHeight = f.measure:GetHeight() or 0
		local contentHeight = math.ceil(measuredHeight * 1.2) + 40
		local visibleHeight = f.scroll:GetHeight() or 400
		if contentHeight < visibleHeight then
			contentHeight = visibleHeight
		end
		f.edit:SetHeight(contentHeight)

		-- The scrollbar's range doesn't reliably auto-update when an EditBox
		-- scroll child is resized programmatically (known vanilla 1.12
		-- quirk) -- set it explicitly rather than trust the template's
		-- automatic OnScrollRangeChanged callback to fire.
		local scrollbar = getglobal(f.scroll:GetName() .. "ScrollBar")
		if scrollbar then
			local maxScroll = contentHeight - visibleHeight
			if maxScroll < 0 then maxScroll = 0 end
			scrollbar:SetMinMaxValues(0, maxScroll)
			scrollbar:SetValue(0)
		end
	end)

	f.scroll:SetVerticalScroll(0)
	f:Show()
end
