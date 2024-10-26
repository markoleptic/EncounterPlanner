local Type          = "EPLineEdit"
local Version       = 1
local AceGUI        = LibStub("AceGUI-3.0")
local defaultHeight = 4

---@class EPLineEdit : AceGUIWidget
---@field frame table|Frame
---@field type string

---@param self EPSpacer
local function OnAcquire(self)
	self:SetHeight(defaultHeight)
end

---@param self EPSpacer
local function OnRelease(self)
end

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. num, UIParent)
	frame:SetWidth(1)
	frame:Hide()

	---@class EPLineEdit
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		frame     = frame,
		type      = Type,
	}
	frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
