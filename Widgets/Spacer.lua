local Type          = "EPSpacer"
local Version       = 1
local AceGUI        = LibStub("AceGUI-3.0")
local defaultHeight = 4

local methods       = {
	["OnAcquire"] = function(self)
		self:SetHeight(defaultHeight)
	end,

	["OnWidthSet"] = function(self, width)
	end,
}

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. num, UIParent)
	frame:SetWidth(1)
	frame:Hide()

	local widget = {
		frame = frame,
		type  = Type,
	}
	frame.obj = widget

	for method, func in pairs(methods) do
		---@diagnostic disable-next-line: assign-type-mismatch
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
