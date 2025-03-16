local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPLabel"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local tooltip = Private.tooltip

local CreateFrame = CreateFrame
local unpack = unpack

local defaultHeight = 400
local defaultWidth = 400
local dropdownWidth = 200
local dropdownHeight = 26
local dropdownHorizontalPadding = 4
local defaultFontSize = 14
local contentFramePadding = { x = 15, y = 15 }
local otherPadding = { x = 10, y = 10 }
local windowBarHeight = 28
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local title = L["Quick Start"]
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
---@param self EPQuickStartDialog
local function HandleIconEnter(self) end

local function HandleIconLeave(_)
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()
end

---@param self EPQuickStartDialog
local function OnAcquire(self)
	self.frame:SetSize(defaultWidth, defaultHeight)

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar --[[@as Frame]])
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)
	self.frame:Show()

	self.container = AceGUI:Create("EPContainer")
	self.container:SetLayout("EPVerticalLayout")
	self.container:SetSpacing(otherPadding.x, otherPadding.y)
	self.container.frame:SetParent(self.frame --[[@as Frame]])
	self.container.frame:EnableMouse(true)
	self.container.frame:SetPoint(
		"TOPLEFT",
		self.windowBar,
		"BOTTOMLEFT",
		contentFramePadding.x,
		-contentFramePadding.y
	)
	self.frame:Show()
end

---@param self EPQuickStartDialog
local function OnRelease(self) end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultWidth, defaultHeight)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	---@class EPQuickStartDialog : AceGUIWidget
	---@field closeButton EPButton
	---@field container EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		frame = frame,
		type = Type,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
