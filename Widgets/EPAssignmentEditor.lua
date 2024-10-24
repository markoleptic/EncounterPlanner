local Type        = "EPAssignmentEditor"
local Version     = 1
local AceGUI      = LibStub("AceGUI-3.0")
local LSM         = LibStub("LibSharedMedia-3.0")
local frameWidth  = 200
local frameHeight = 100
local title       = "Assignment Editor"
local backdrop    = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}

---@class EPAssignmentEditor : AceGUIWidget
---@field frame Frame|BackdropTemplate|table
---@field type string
---@field count number
---@field titleText FontString
---@field assignmentTypeDropdown EPDropdown|AceGUIWidget
---@field spellAssignmentDropdown EPDropdown|AceGUIWidget
---@field assigneeTypeDropdown EPDropdown|AceGUIWidget
---@field assigneeDropdown EPDropdown|AceGUIWidget
---@field timeEditBox AceGUIEditBox|AceGUIWidget
---@field assignment Assignment

local function HandleAssignmentDataChanged(frame)
	local self = frame.obj
	self:Fire("assignmentDataChanged", self.assignment)
end

local function HandleAssignmentTypeDropdownValueChanged(frame, callbackName, value)
	DevTool:AddData(frame)
	-- TODO: Find way to access EPAssignmentEditor object from dropdown, probably GetParent or parent field of sorts
end

local function HandleSpellAssignmentDropdownValueChanged(frame, callbackName, value)
	DevTool:AddData(frame)
	-- TODO: Find way to access EPAssignmentEditor object from dropdown, probably GetParent or parent field of sorts
end

local function HandleAssigneeTypeDropdownValueChanged(frame, callbackName, value)
	DevTool:AddData(frame)
	-- TODO: Find way to access EPAssignmentEditor object from dropdown, probably GetParent or parent field of sorts
end

local function HandleAssigneeDropdownValueChanged(frame, callbackName, value)
	DevTool:AddData(frame)
	-- TODO: Find way to access EPAssignmentEditor object from dropdown, probably GetParent or parent field of sorts
end

---@param self EPAssignmentEditor
local function OnAcquire(self)
	self.assignment = self.assignment or {}
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	wipe(self.assignment)
end

---@param self EPAssignmentEditor
---@param assignment Assignment Should be a deep of the assignment since it is nilled on release.
local function SetAssignmentData(self, assignment)
	self.assignment = assignment
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
	titleText:SetText(title)

	local assignmentTypeDropdown = AceGUI:Create("EPDropdown"); --[[@as EPDropdown]]
	assignmentTypeDropdown:SetCallback("OnValueChanged", HandleAssignmentTypeDropdownValueChanged)

	local assigneeTypeDropdown = AceGUI:Create("EPDropdown"); --[[@as EPDropdown]]
	assigneeTypeDropdown:SetCallback("OnValueChanged", HandleAssigneeTypeDropdownValueChanged)

	local assigneeDropdown = AceGUI:Create("EPDropdown"); --[[@as EPDropdown]]
	assigneeDropdown:SetCallback("OnValueChanged", HandleAssigneeDropdownValueChanged)

	local spellAssignmentDropdown = AceGUI:Create("EPDropdown"); --[[@as EPDropdown]]
	spellAssignmentDropdown:SetCallback("OnValueChanged", HandleSpellAssignmentDropdownValueChanged)

	local timeEditBox = AceGUI:Create("EditBox");

	---@class EPAssignmentEditor
	local widget = {
		OnAcquire               = OnAcquire,
		OnRelease               = OnRelease,
		frame                   = frame,
		type                    = Type,
		count                   = count,
		titleText               = titleText,
		assignmentTypeDropdown  = assignmentTypeDropdown,
		spellAssignmentDropdown = spellAssignmentDropdown,
		assigneeTypeDropdown    = spellAssignmentDropdown,
		assigneeDropdown        = assigneeDropdown,
		timeEditBox             = timeEditBox
	}
	widget.assignmentTypeDropdown.obj = widget
	widget.spellAssignmentDropdown.obj = widget
	widget.assigneeTypeDropdown.obj = widget
	widget.assigneeDropdown.obj = widget
	---@diagnostic disable-next-line: inject-field
	widget.timeEditBox.obj = widget

	widget.assignmentTypeDropdown:SetParent(frame --[[@as Frame]])
	widget.spellAssignmentDropdown:SetParent(frame --[[@as Frame]])
	widget.assigneeTypeDropdown:SetParent(frame --[[@as Frame]])
	widget.assigneeDropdown:SetParent(frame --[[@as Frame]])
	widget.timeEditBox:SetParent(frame --[[@as Frame]])

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
