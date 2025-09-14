local Type = "EPSpacer"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local k = {
	DefaultHeight = 4,
	DefaultWidth = 1,
}

---@param self EPSpacer
local function OnAcquire(self)
	self.frame:Show()
	self:SetHeight(k.DefaultHeight)
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
	frame:SetWidth(k.DefaultWidth)
	frame:Hide()

	---@class EPSpacer : AceGUIWidget
	---@field fillSpace boolean
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetFillSpace = SetFillSpace,
		frame = frame,
		type = Type,
		count = count,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
