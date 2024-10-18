local Type             = "EPMainFrame"
local Version          = 1
local mainFrameWidth   = 1125
local mainFrameHeight  = 600
local windowBarHeight  = 27
local FrameBackdrop    = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 27, bottom = 0 }
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}
local AceGUI           = LibStub("AceGUI-3.0")
local LSM              = LibStub("LibSharedMedia-3.0")

local function FlashButton_OnLeave(self)
	local fadeIn = self.fadeIn
	if fadeIn:IsPlaying() then
		fadeIn:Stop()
	end
	self.fadeOut:Play()
end

local function FlashButton_OnEnter(self)
	local fadeOut = self.fadeOut
	if fadeOut:IsPlaying() then
		fadeOut:Stop()
	end
	self.fadeIn:Play()
end

local function CreateFlashButton(parent, text, width, height)
	local Button = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	Button:SetSize(width or 80, height or 20)
	Button:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 1,
	})
	Button:SetBackdropColor(0.725, 0.008, 0.008)
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnEnter", FlashButton_OnEnter)
	Button:SetScript("OnLeave", FlashButton_OnLeave)
	Button:SetNormalFontObject("GameFontNormal")
	Button:SetText(text or "")

	Button.bg = Button:CreateTexture(nil, "BORDER")
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		Button.bg:SetAllPoints()
	else
		Button.bg:SetTexelSnappingBias(0.0)
		Button.bg:SetSnapToPixelGrid(false)
		Button.bg:SetPoint("TOPLEFT", Button.TopEdge, "BOTTOMLEFT")
		Button.bg:SetPoint("BOTTOMRIGHT", Button.BottomEdge, "TOPRIGHT")
	end
	Button.bg:SetColorTexture(0.0, 0.6, 0.4)
	Button.bg:Hide()

	Button.fadeIn = Button.bg:CreateAnimationGroup()
	Button.fadeIn:SetScript("OnPlay", function() Button.bg:Show() end)
	local fadeIn = Button.fadeIn:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	Button.fadeOut = Button.bg:CreateAnimationGroup()
	Button.fadeOut:SetScript("OnFinished", function() Button.bg:Hide() end)
	local fadeOut = Button.fadeOut:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")

	return Button
end

local methods = {
	["OnAcquire"] = function(self)
	end,
	["OnRelease"] = function(self)
	end,
}

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local mainFrame = CreateFrame("Frame", "MainFrame" .. num, UIParent, "BackdropTemplate")
	mainFrame:EnableMouse(true)
	mainFrame:SetMovable(true)
	mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	mainFrame:SetFrameLevel(100)
	mainFrame:SetBackdrop(FrameBackdrop)
	mainFrame:SetBackdropColor(0, 0, 0, 0.9)
	mainFrame:SetBackdropBorderColor(0, 0, 0)
	mainFrame:SetSize(mainFrameWidth, mainFrameHeight)
	mainFrame:SetPoint("CENTER")

	local contentFrameName = "ContentFrame" .. num
	local contentFrame = CreateFrame("Frame", contentFrameName, mainFrame)
	contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -37)
	contentFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -10, -37)
	contentFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
	contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

	local windowBarName = "WindowBar" .. num
	local windowBar = CreateFrame("Frame", windowBarName, mainFrame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 0.9)
	windowBar:SetBackdropBorderColor(0, 0, 0)
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText("Encounter Planner")
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then windowBarText:SetFont(fPath, h) end
	windowBar:SetScript("OnMouseDown", function()
		mainFrame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		mainFrame:StopMovingOrSizing()
	end)

	local closebutton = CreateFlashButton(windowBar, "X", 25, 25)
	closebutton:SetPoint("TOPRIGHT", -1, -1)
	closebutton:SetScript("OnClick", function()
		mainFrame:Hide()
	end)

	local widget = {
		frame = mainFrame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
		closebutton = closebutton,
	}

	for method, func in pairs(methods) do
		---@diagnostic disable-next-line: assign-type-mismatch
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
