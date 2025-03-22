local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPMessageBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local ipairs = ipairs
local max = math.max
local unpack = unpack

local defaultFrameHeight = 200
local defaultFrameWidth = 400
local windowBarHeight = 28
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1.0 }
local defaultButtonHeight = 24
local framePadding = 15
local defaultFontSize = 14
local neutralButtonColor = Private.constants.colors.kNeutralButtonActionColor
local title = "Export as MRT Note"
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

---@param container EPContainer
local function SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		maxWidth = max(maxWidth, child.frame:GetWidth())
	end
	for _, child in ipairs(container.children) do
		child:SetWidth(maxWidth)
	end
end

---@class EPMessageBox : AceGUIWidget
---@field frame table|Frame
---@field type string
---@field text FontString
---@field buttonContainer EPContainer
---@field windowBar Frame|table
---@field isCommunicationsMessage boolean|nil

---@param self EPMessageBox
local function OnAcquire(self)
	self:SetTitle("")
	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(framePadding / 2.0, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, framePadding)

	local acceptButton = AceGUI:Create("EPButton")
	acceptButton:SetText(L["Okay"])
	acceptButton:SetWidthFromText()
	acceptButton:SetHeight(defaultButtonHeight)
	acceptButton:SetColor(unpack(neutralButtonColor))
	acceptButton:SetCallback("Clicked", function()
		self:Fire("Accepted")
	end)

	local rejectButton = AceGUI:Create("EPButton")
	rejectButton:SetText(L["Cancel"])
	rejectButton:SetWidthFromText()
	rejectButton:SetHeight(defaultButtonHeight)
	rejectButton:SetCallback("Clicked", function()
		self:Fire("Rejected")
	end)

	self.buttonContainer:AddChildNoDoLayout(acceptButton)
	self.buttonContainer:AddChildNoDoLayout(rejectButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	local currentContentWidth = self.frame:GetWidth() - 2 * framePadding
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * framePadding)
	end
	self.frame:Show()
end

---@param self EPMessageBox
local function OnRelease(self)
	self.buttonContainer:Release()
	self.buttonContainer = nil
	self.isCommunicationsMessage = nil
end

---@param self EPMessageBox
---@param text string
local function SetAcceptButtonText(self, text)
	self.buttonContainer.children[1]:SetText(text)
	self.buttonContainer.children[1]:SetWidthFromText()
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
end

---@param self EPMessageBox
---@param text string
local function SetRejectButtonText(self, text)
	self.buttonContainer.children[2]:SetText(text)
	self.buttonContainer.children[2]:SetWidthFromText()
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
end

---@param self EPMessageBox
---@param text string
local function SetText(self, text)
	self.text:ClearAllPoints()
	self.text:SetText(text)
	self.text:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -framePadding)
	self.text:SetWidth(self.frame:GetWidth() - 2 * framePadding)
	self:SetHeight(self.windowBar:GetHeight() + self.text:GetStringHeight() + defaultButtonHeight + framePadding * 3)
end

---@param self EPMessageBox
---@param text string
local function SetTitle(self, text)
	self.windowBarText:SetText(text or "")
end

---@param self EPMessageBox
---@param text string
---@param beforeWidget AceGUIWidget|nil
local function AddButton(self, text, beforeWidget)
	local button = AceGUI:Create("EPButton")
	button:SetText(text)
	button:SetWidthFromText()
	button:SetHeight(defaultButtonHeight)
	button:SetColor(unpack(neutralButtonColor))
	button:SetCallback("Clicked", function()
		self:Fire(text .. "Clicked")
	end)
	if beforeWidget then
		self.buttonContainer:InsertChildren(beforeWidget, button)
	else
		self.buttonContainer:AddChild(button)
	end
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
	local currentContentWidth = self.frame:GetWidth() - 2 * framePadding
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * framePadding)
		self.text:SetWidth(self.frame:GetWidth() - 2 * framePadding)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetWordWrap(true)
	text:SetSpacing(4)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, defaultFontSize)
	end
	text:SetPoint("TOP", windowBar, "BOTTOM", 0, -framePadding)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	---@class EPMessageBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		SetTitle = SetTitle,
		AddButton = AddButton,
		SetAcceptButtonText = SetAcceptButtonText,
		SetRejectButtonText = SetRejectButtonText,
		frame = frame,
		type = Type,
		windowBar = windowBar,
		windowBarText = windowBarText,
		text = text,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
