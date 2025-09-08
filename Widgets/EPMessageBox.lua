local _, Namespace = ...

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

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1.0 },
	BackdropColor = { 0, 0, 0, 1 },
	DefaultButtonHeight = 24,
	DefaultFontSize = 14,
	DefaultFrameHeight = 200,
	DefaultFrameWidth = 400,
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	FramePadding = 15,
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
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

---@param self EPMessageBox
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle("")
	windowBar:RemoveButtons()
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
	end)
	self.windowBar = windowBar

	self.text:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.FramePadding)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(k.FramePadding / 2.0, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.FramePadding)

	local acceptButton = AceGUI:Create("EPButton")
	acceptButton:SetText(L["Okay"])
	acceptButton:SetWidthFromText()
	acceptButton:SetHeight(k.DefaultButtonHeight)
	acceptButton:SetColor(unpack(k.NeutralButtonColor))
	acceptButton:SetCallback("Clicked", function()
		self:Fire("Accepted")
	end)

	local rejectButton = AceGUI:Create("EPButton")
	rejectButton:SetText(L["Cancel"])
	rejectButton:SetWidthFromText()
	rejectButton:SetHeight(k.DefaultButtonHeight)
	rejectButton:SetCallback("Clicked", function()
		self:Fire("Rejected")
	end)

	self.buttonContainer:AddChildNoDoLayout(acceptButton)
	self.buttonContainer:AddChildNoDoLayout(rejectButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	local currentContentWidth = self.frame:GetWidth() - 2 * k.FramePadding
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * k.FramePadding)
	end
	self.frame:Show()
end

---@param self EPMessageBox
local function OnRelease(self)
	self.windowBar:Release()
	self.windowBar = nil
	self.buttonContainer:Release()
	self.buttonContainer = nil
	self.isCommunicationsMessage = nil
	self.text:ClearAllPoints()
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
	self.text:SetWidth(self.frame:GetWidth() - 2 * k.FramePadding)
	self.text:SetText(text)
	local textHeight = self.text:GetHeight()
	self.text:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.FramePadding)
	self:SetHeight(self.windowBar.frame:GetHeight() + textHeight + k.DefaultButtonHeight + k.FramePadding * 3)
end

---@param self EPMessageBox
---@return string
local function GetText(self)
	return self.text:GetText()
end

---@param self EPMessageBox
---@param text string
local function SetTitle(self, text)
	self.windowBar:SetTitle(text or "")
end

---@param self EPMessageBox
---@param text string
---@param beforeWidget AceGUIWidget|nil
local function AddButton(self, text, beforeWidget)
	local button = AceGUI:Create("EPButton")
	button:SetText(text)
	button:SetWidthFromText()
	button:SetHeight(k.DefaultButtonHeight)
	button:SetColor(unpack(k.NeutralButtonColor))
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
	local currentContentWidth = self.frame:GetWidth() - 2 * k.FramePadding
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * k.FramePadding)
		self.text:SetWidth(self.frame:GetWidth() - 2 * k.FramePadding)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetWordWrap(true)
	text:SetSpacing(4)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.DefaultFontSize)
	end

	---@class EPMessageBox : AceGUIWidget
	---@field buttonContainer EPContainer
	---@field windowBar EPWindowBar
	---@field isCommunicationsMessage boolean|nil
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
		text = text,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
