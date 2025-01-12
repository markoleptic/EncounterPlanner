local Type = "EPCheckBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local defaultFrameHeight = 24
local defaultFrameWidth = 100
local spacingBetweenCheckAndLabel = 4
local buttonColor = { 74 / 255.0, 174 / 255.0, 242 / 255.0, 0.5 }
local buttonBackdropColor = { 0, 0, 0, 0 }
local checkBackdropColor = { 0, 0, 0, 0 }
local checkBackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local textColor = { 1, 0.82, 0, 1 }
local buttonPadding = 1
local defaultFontSize = 14

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
---@field enabled boolean
---@field checked boolean
---@field checkBackground Frame|BackdropTemplate|table

---@param self EPCheckBox
local function OnAcquire(self)
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	self.button = AceGUI:Create("EPButton")
	self.button:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	self.button.frame:SetParent(self.checkBackground --[[@as Frame]])
	self.button.frame:SetPoint("TOPLEFT", buttonPadding, -buttonPadding)
	self.button.frame:SetPoint("BOTTOMRIGHT", -buttonPadding, buttonPadding)
	self.button:SetWidth(defaultFrameHeight - 2 * buttonPadding)
	self.button:SetBackdropColor(unpack(buttonBackdropColor))
	self.button:SetColor(unpack(buttonColor))
	self.button:SetCallback("Clicked", function()
		if self.enabled then
			self:SetChecked(not self.checked)
			self:Fire("OnValueChanged", self.checked)
		end
	end)
	self.button:SetCallback("OnEnter", function()
		self:Fire("OnEnter")
	end)
	self.button:SetCallback("OnLeave", function()
		self:Fire("OnLeave")
	end)

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame)
	self.label.frame:SetPoint("LEFT", self.checkBackground, "RIGHT", spacingBetweenCheckAndLabel, 0)
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")
	self.label:SetHeight(defaultFrameHeight)
	self.label:SetFontSize(defaultFontSize)
	self.label.text:SetTextColor(unpack(textColor))

	self:SetEnabled(true)
	self:SetChecked(true)
	self.frame:Show()
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
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	self.label:SetEnabled(enabled)
	self.button:SetEnabled(enabled)
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
local function SetFrameWidthFromText(self)
	self.label:SetFrameWidthFromText()
	self:SetWidth(self.frame:GetHeight() + spacingBetweenCheckAndLabel + self.label.frame:GetWidth())
end

---@param self EPCheckBox
local function OnHeightSet(self, height)
	if height > 0 then
		local checkBackgroundHeight = self.checkBackground:GetHeight()
		if height == checkBackgroundHeight then
			if self.checkBackground:GetWidth() ~= checkBackgroundHeight then
				self.checkBackground:SetWidth(checkBackgroundHeight)
			end
		end
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:EnableMouse(true)

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(checkBackdrop)
	checkBackground:SetBackdropColor(unpack(checkBackdropColor))
	checkBackground:SetBackdropBorderColor(unpack(checkBackdropBorderColor))
	checkBackground:SetPoint("TOPLEFT")
	checkBackground:SetPoint("BOTTOMLEFT")
	checkBackground:SetWidth(defaultFrameHeight)

	---@class EPCheckBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetText = SetText,
		OnHeightSet = OnHeightSet,
		SetChecked = SetChecked,
		IsChecked = IsChecked,
		SetFrameWidthFromText = SetFrameWidthFromText,
		frame = frame,
		type = Type,
		checkBackground = checkBackground,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
