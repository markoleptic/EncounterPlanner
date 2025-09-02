local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants

local Type = "EPWindowBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack
local wipe = table.wipe

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	BackdropColor = { 0, 0, 0, 0.9 },
	CloseIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]],
	DefaultHeight = 28,
	DefaultWidth = 100,
	FontPath = LSM:Fetch("font", "PT Sans Narrow"),
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	IconPadding = 2,
	NeutralButtonColor = constants.colors.kNeutralButtonActionColor,
}

---@param self EPWindowBar
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	self:AddButton(k.CloseIcon, "CloseButtonClicked")
	self.frame:Show()
end

---@param self EPWindowBar
local function OnRelease(self)
	self:RemoveButtons()
end

---@param self EPWindowBar
---@param title string
local function SetTitle(self, title)
	self.title:SetText(title)
end

-- Adds a button to the left of the furthest left button.
---@param self EPWindowBar
---@param icon string|integer
---@param clickedCallbackName string
local function AddButton(self, icon, clickedCallbackName)
	local buttonSize = self.frame:GetHeight() - 2 * k.FrameBackdrop.edgeSize
	local button = AceGUI:Create("EPButton")
	button:SetIcon(icon)
	button:SetIconPadding(k.IconPadding, k.IconPadding)
	button:SetWidth(buttonSize)
	button:SetHeight(buttonSize)
	button:SetBackdropColor(unpack(k.BackdropColor))
	button.frame:SetParent(self.frame)

	if #self.buttons == 0 then
		button.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.FrameBackdrop.edgeSize, 0)
	else
		button.frame:SetPoint("RIGHT", self.buttons[1].frame, "LEFT")
	end

	button:SetCallback("Clicked", function()
		self:Fire(clickedCallbackName)
	end)

	tinsert(self.buttons, 1, button)
end

-- Removes all buttons from the window bar.
---@param self EPWindowBar
local function RemoveButtons(self)
	for i = #self.buttons, -1, 1 do
		local button = self.buttons[i]
		button:Release()
	end
	wipe(self.buttons)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:EnableMouse(true)
	frame:SetFrameStrata("DIALOG")

	local title = frame:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	title:SetText("Title")
	title:SetPoint("CENTER", frame, "CENTER")
	local h = title:GetStringHeight()
	if k.FontPath then
		title:SetFont(k.FontPath, h)
	end

	---@class EPWindowBar : AceGUIWidget
	---@field buttons table<integer, EPButton>
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetTitle = SetTitle,
		AddButton = AddButton,
		RemoveButtons = RemoveButtons,
		frame = frame,
		type = Type,
		title = title,
		buttons = {},
	}

	frame:SetScript("OnMouseDown", function()
		widget:Fire("OnMouseDown")
	end)
	frame:SetScript("OnMouseUp", function()
		widget:Fire("OnMouseUp")
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
