local Type = "EPCheckBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultFrameHeight = 24
local defaultFrameWidth = 100
local padding = { x = 2, y = 2 }

local checkBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	tileSize = nil,
	edgeSize = 1,
}

---@class EPCheckBox : AceGUIWidget
---@field frame Frame
---@field label EPLabel
---@field button EPButton
---@field type string
---@field disabled boolean
---@field checked boolean

---@param self EPCheckBox
local function SetDisabled(self, disable)
	self.disabled = disable
	self.button:SetDisabled(disable)
end

---@param self EPCheckBox
local function OnAcquire(self)
	self.checked = true

	self.button = AceGUI:Create("EPButton")
	self.button:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	self.button.frame:SetParent(self.checkBackground --[[@as Frame]])
	self.button.frame:SetPoint("TOPLEFT", 1, -1)
	self.button.frame:SetPoint("BOTTOMRIGHT", -1, 1)
	self.button:SetWidth(defaultFrameHeight - 6)
	self.button:SetBackdropColor(0, 0, 0, 0)
	self.button:SetColor(74 / 255.0, 174 / 255.0, 242 / 255.0, 0.5)
	self.button:SetCallback("Clicked", function()
		if not self.disabled then
			self:SetChecked(not self.checked)
			self:Fire("OnValueChanged", self.checked)
		end
	end)
	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame --[[@as Frame]])
	self.label.frame:SetPoint("LEFT", self.checkBackground, "RIGHT", 4, 0)
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")
	self.label:SetHeight(defaultFrameHeight)
	self.label:SetFontSize(14)
	self.label.text:SetTextColor(1, 0.82, 0, 1)

	self.frame:Show()
	self:SetDisabled(false)
end

---@param self EPCheckBox
local function OnRelease(self)
	self.label:Release()
	self.label = nil
	self.button:Release()
	self.button = nil
	self.checked = nil
end

---@param self EPCheckBox
---@param text string
local function SetText(self, text)
	self.label:SetText(text)
end

---@param self EPCheckBox
---@param checked boolean
local function SetChecked(self, checked)
	self.checked = checked
	if checked then
		self.button:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	else
		self.button:SetIcon(nil)
	end
end

---@param self EPCheckBox
local function IsChecked(self)
	return self.checked
end

---@param self EPCheckBox
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height) end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:EnableMouse(true)

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(checkBackdrop)
	checkBackground:SetBackdropColor(0, 0, 0, 0)
	checkBackground:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	checkBackground:SetPoint("TOPLEFT", 2, -2)
	checkBackground:SetPoint("BOTTOMLEFT", 2, 2)
	checkBackground:SetWidth(defaultFrameHeight - 4)

	---@class EPCheckBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetDisabled = SetDisabled,
		SetText = SetText,
		LayoutFinished = LayoutFinished,
		SetChecked = SetChecked,
		IsChecked = IsChecked,
		frame = frame,
		type = Type,
		checkBackground = checkBackground,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
