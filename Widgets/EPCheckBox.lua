local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPCheckBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local k = {
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 100,
	SpacingBetweenCheckAndLabel = 4,
	ButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	ButtonBackdropColor = { 0, 0, 0, 0 },
	CheckBackdropColor = { 0, 0, 0, 0 },
	CheckBackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	CheckTexture = Private.constants.textures.kCheck,
	TextColor = { 1, 0.82, 0, 1 },
	ButtonPadding = 1,
	DefaultFontSize = 14,
	CheckBackdrop = {
		bgFile = nil,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = false,
		tileSize = nil,
		edgeSize = 1,
	},
}

---@param self EPCheckBox
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self.autoCheckSize = true

	self.button = AceGUI:Create("EPButton")
	self.button:SetIcon(k.CheckTexture)
	self.button.frame:SetParent(self.checkBackground)
	self.button.frame:SetPoint("TOPLEFT", k.ButtonPadding, -k.ButtonPadding)
	self.button.frame:SetPoint("BOTTOMRIGHT", -k.ButtonPadding, k.ButtonPadding)
	self.button:SetWidth(k.DefaultFrameHeight - 2 * k.ButtonPadding)
	self.button:SetBackdropColor(unpack(k.ButtonBackdropColor))
	self.button:SetColor(unpack(k.ButtonColor))
	self.button:SetCallback("Clicked", function()
		if self.enabled then
			self:SetChecked(not self.checked)
			self:Fire("OnValueChanged", self.checked)
		end
	end)
	self.button:SetCallback("OnEnter", function()
		if self.enabled or self.fireEventsIfDisabled then
			self:Fire("OnEnter")
		end
	end)
	self.button:SetCallback("OnLeave", function()
		self:Fire("OnLeave")
	end)

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame)
	self.label.frame:SetPoint("LEFT", self.checkBackground, "RIGHT", k.SpacingBetweenCheckAndLabel, 0)
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")
	self.label:SetHeight(k.DefaultFrameHeight)
	self.label:SetFontSize(k.DefaultFontSize)
	self.label.text:SetTextColor(unpack(k.TextColor))

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
	self.fireEventsIfDisabled = nil
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
		self.button:SetIcon(k.CheckTexture)
	else
		self.button:SetIcon(nil)
	end
end

---@param self EPCheckBox
local function IsChecked(self)
	return self.checked
end

---@param self EPCheckBox
---@param size number
local function SetCheckSize(self, size)
	if type(size) == "number" then
		self.autoCheckSize = false
		self.checkBackground:SetSize(size, size)
	end
end

---@param self EPCheckBox
local function SetFrameWidthFromText(self)
	self.label:SetFrameWidthFromText()
	self:SetWidth(
		(self.autoCheckSize and self.frame:GetHeight() or self.checkBackground:GetWidth())
			+ k.SpacingBetweenCheckAndLabel
			+ self.label.frame:GetWidth()
	)
end

---@param self EPCheckBox
local function SetFrameHeightFromText(self)
	self.label:SetFrameHeightFromText()
	self:SetHeight(self.label.frame:GetHeight())
end

---@param self EPCheckBox
local function OnHeightSet(self, height)
	if height > 0 and self.autoCheckSize then
		if self.checkBackground:GetWidth() ~= height then
			self.checkBackground:SetSize(height, height)
		end
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	frame:EnableMouse(true)

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(k.CheckBackdrop)
	checkBackground:SetBackdropColor(unpack(k.CheckBackdropColor))
	checkBackground:SetBackdropBorderColor(unpack(k.CheckBackdropBorderColor))
	checkBackground:SetPoint("LEFT")
	checkBackground:SetSize(k.DefaultFrameHeight, k.DefaultFrameHeight)

	---@class EPCheckBox : AceGUIWidget
	---@field label EPLabel
	---@field button EPButton
	---@field enabled boolean
	---@field checked boolean
	---@field checkBackground Frame|BackdropTemplate|table
	---@field autoCheckSize boolean
	---@field fireEventsIfDisabled boolean|nil
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetText = SetText,
		OnHeightSet = OnHeightSet,
		SetChecked = SetChecked,
		IsChecked = IsChecked,
		SetFrameWidthFromText = SetFrameWidthFromText,
		SetFrameHeightFromText = SetFrameHeightFromText,
		SetCheckSize = SetCheckSize,
		frame = frame,
		type = Type,
		count = count,
		checkBackground = checkBackground,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
