local Type        = "EPAssignmentEditor"
local Version     = 1
local AceGUI      = LibStub("AceGUI-3.0")
local LSM         = LibStub("LibSharedMedia-3.0")
local frameWidth  = 200
local frameHeight = 100
local backdrop    = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}

---@class EPAssignmentEditor : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field titleText FontString

---@param self EPAssignmentEditor
local function OnAcquire(self)
end

---@param self EPAssignmentEditor
local function OnRelease(self)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:SetSize(frameWidth, frameHeight)

	local titleText = frame:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormal")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then titleText:SetFont(fPath, 12) end
	titleText:SetPoint("TOP", frame, "TOP", 0, 0)

	---@class EPAssignmentEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		frame     = frame,
		type      = Type,
		count     = count,
		titleText = titleText,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
