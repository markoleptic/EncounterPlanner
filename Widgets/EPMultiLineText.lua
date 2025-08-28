local Type = "EPMultiLineText"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local k = {
	DefaultHeight = 100,
	DefaultWidth = 100,
	Padding = 10,
	TextColor = { 1, 1, 1, 1 },
	Font = LSM:Fetch("font", "PT Sans Narrow"),
}

---@class EPMultiLineText : AceGUIWidget
---@field frame table|Frame
---@field type string

---@param self EPMultiLineText
local function OnAcquire(self)
	self.text:SetTextColor(unpack(k.TextColor))
	self.text:SetFont(k.Font, self.defaultTextHeight)
	self.frame:Show()
end

---@param self EPMultiLineText
local function SetText(self, text)
	self.text:SetText(text)
	self.frame:SetSize(self.text:GetWidth() + k.Padding, self.text:GetStringHeight() + k.Padding)
end

---@param self EPMultiLineText
---@param size integer
local function SetFontSize(self, size)
	self.text:SetFont(k.Font, size)
end

---@param self EPMultiLineText
---@param r number
---@param g number
---@param b number
---@param a? number
local function SetTextColor(self, r, g, b, a)
	self.text:SetTextColor(r, g, b, a)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetText("Text")
	text:SetPoint("LEFT")
	text:SetPoint("RIGHT")
	local h = text:GetStringHeight()
	text:SetFont(k.Font, h)
	text:SetWordWrap(true)

	---@class EPMultiLineText
	local widget = {
		OnAcquire = OnAcquire,
		SetText = SetText,
		SetFontSize = SetFontSize,
		SetTextColor = SetTextColor,
		frame = frame,
		type = Type,
		text = text,
		defaultTextHeight = h,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
