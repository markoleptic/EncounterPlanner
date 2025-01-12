local Type = "EPSpacer"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultHeight = 4

---@class EPSpacer : AceGUIWidget
---@field frame table|Frame|BackdropTemplate
---@field type string
---@field fillSpace boolean

---@param self EPSpacer
local function OnAcquire(self)
	self.frame:Show()
	self:SetHeight(defaultHeight)
	self.fillSpace = false
end

---@param self EPSpacer
local function OnRelease(self)
	self.frame:ClearBackdrop()
end

local function SetFillSpace(self, fill)
	self.fillSpace = fill
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetWidth(1)
	frame:Hide()

	---@class EPSpacer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetFillSpace = SetFillSpace,
		frame = frame,
		type = Type,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
