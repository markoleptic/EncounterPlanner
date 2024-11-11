local Type = "EPAssignmentEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local frameWidth = 200
local frameHeight = 200
local buttonFrameHeight = 24
local windowBarHeight = 24
local contentFramePadding = { x = 15, y = 15 }
local title = "Assignment Editor"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local buttonFrameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local assignmentTriggers = {
	{
		text = "Combat Log Event",
		itemValue = "Combat Log Event",
		dropdownItemMenuData = {
			{
				text = "SPELL_CAST_SUCCESS",
				itemValue = "SCC",
				dropdownItemMenuData = {},
			},
			{
				text = "SPELL_CAST_START",
				itemValue = "SCS",
				dropdownItemMenuData = {},
			},
			{
				text = "SPELL_AURA_APPLIED",
				itemValue = "SAA",
				dropdownItemMenuData = {},
			},
			{
				text = "SPELL_AURA_REMOVED",
				itemValue = "SAR",
				dropdownItemMenuData = {},
			},
		},
	},
	{
		text = "Absolute Time",
		itemValue = "Absolute Time",
		dropdownItemMenuData = {},
	},
}

---@class EPAssignmentEditor : AceGUIContainer
---@field type string
---@field count number
---@field frame Frame|BackdropTemplate|table
---@field buttonFrame Frame|table
---@field okayButton EPButton
---@field deleteButton EPButton
---@field closeButton EPButton
---@field titleText FontString
---@field assignmentTypeContainer EPContainer
---@field assignmentTypeDropdown EPDropdown
---@field assignmentTypeLabel EPLabel
---@field combatLogEventContainer EPContainer
---@field combatLogEventSpellIDDropdown EPDropdown
---@field combatLogEventSpellIDLabel EPLabel
---@field combatLogEventSpellCountLineEdit EPLineEdit
---@field combatLogEventSpellCountLabel EPLabel
---@field spellAssignmentContainer EPContainer
---@field spellAssignmentDropdown EPDropdown
---@field spellAssignmentLabel EPLabel
---@field assigneeTypeContainer EPContainer
---@field assigneeTypeDropdown EPDropdown
---@field assigneeTypeLabel EPLabel
---@field assigneeContainer EPContainer
---@field assigneeDropdown EPDropdown
---@field assigneeLabel EPLabel
---@field timeContainer EPContainer
---@field timeEditBox EPLineEdit
---@field timeLabel EPLabel
---@field optionalTextContainer EPContainer
---@field optionalTextLineEdit EPLineEdit
---@field optionalTextLabel EPLabel
---@field targetContainer EPContainer
---@field targetLabel EPLabel
---@field targetDropdown EPDropdown
---@field previewContainer EPContainer
---@field previewLabel EPLabel
---@field windowBar Frame|table
---@field obj any

local function HandleOkayButtonClicked(frame, mouseButtonType, down)
	local self = frame.obj
	self:Fire("OkayButtonClicked")
end

local function HandleDeleteButtonClicked(frame, mouseButtonType, down)
	local self = frame.obj
	self:Fire("DeleteButtonClicked")
end

local function HandleAssignmentTypeDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
		self.combatLogEventContainer.frame:Show()
	elseif value == "Absolute Time" then
		self.combatLogEventContainer.frame:Hide()
	elseif value == "Boss Phase" then
		self.combatLogEventContainer.frame:Hide()
	end
	self:Fire("DataChanged", "AssignmentType", value)
end

local function HandleCombatLogEventSpellIDDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "CombatLogEventSpellID", value)
end

local function HandleCombatLogEventSpellCountTextChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "CombatLogEventSpellCount", value)
end

local function HandleSpellAssignmentDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj --[[@as EPAssignmentEditor]]
	local _, itemText = self.spellAssignmentDropdown:FindItemAndText(value)
	if itemText then
		self.spellAssignmentDropdown:SetItemDisabled("Recent", false)
		self.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu(
			"Recent",
			{ { itemValue = value, text = itemText, dropdownItemMenuData = {} } }
		)
	end
	self:Fire("DataChanged", "SpellAssignment", value)
end

local function HandleAssigneeTypeDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj --[[@as EPAssignmentEditor]]
	if value ~= "Individual" then
		self.assigneeContainer.frame:Hide()
	else
		self.assigneeContainer.frame:Show()
	end
	self:Fire("DataChanged", "AssigneeType", value)
end

local function HandleAssigneeDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "Assignee", value)
end

local function HandleTimeTextChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "Time", value)
end

local function HandleOptionalTextChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "OptionalText", value)
end

local function HandleTargetDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "Target", value)
end

---@param self EPAssignmentEditor
---@param assignmentType AssignmentType
local function SetAssignmentType(self, assignmentType)
	if assignmentType == "CombatLogEventAssignment" then
		self.combatLogEventContainer.frame:Show()
	elseif assignmentType == "TimedAssignment" then
		self.combatLogEventContainer.frame:Hide()
	elseif assignmentType == "PhasedAssignment" then
		self.combatLogEventContainer.frame:Hide()
	end
	--self:DoLayout() -- todo make it ignore frames with a variable indicating they should be ignored
end

---@param assigneeType AssigneeType
local function SetAssigneeType(self, assigneeType)
	if assigneeType == "Individual" then
		self.assigneeContainer.frame:Show()
	else
		self.assigneeContainer.frame:Hide()
	end
	--self:DoLayout() -- todo make it ignore frames with a variable indicating they should be ignored
end

---@param self EPAssignmentEditor
local function OnAcquire(self)
	self:SetLayout("EPVerticalLayout")

	self.assignmentTypeContainer = AceGUI:Create("EPContainer")
	self.assignmentTypeContainer:SetLayout("EPVerticalLayout")
	self.assignmentTypeContainer:SetSpacing(0, 2)
	self.assignmentTypeLabel = AceGUI:Create("EPLabel")
	self.assignmentTypeLabel:SetText("Assignment Trigger")
	self.assignmentTypeLabel:SetTextPadding(0, 2)
	self.assignmentTypeDropdown = AceGUI:Create("EPDropdown")
	self.assignmentTypeDropdown:SetCallback("OnValueChanged", HandleAssignmentTypeDropdownValueChanged)
	self.assignmentTypeDropdown.obj = self
	self.assignmentTypeDropdown:AddItems(assignmentTriggers, "EPDropdownItemToggle")
	self.assignmentTypeContainer:AddChild(self.assignmentTypeLabel)
	self.assignmentTypeContainer:AddChild(self.assignmentTypeDropdown)
	self:AddChild(self.assignmentTypeContainer)

	self.combatLogEventContainer = AceGUI:Create("EPContainer")
	self.combatLogEventContainer:SetLayout("EPVerticalLayout")
	self.combatLogEventContainer:SetSpacing(0, 2)
	self.combatLogEventSpellIDLabel = AceGUI:Create("EPLabel")
	self.combatLogEventSpellIDLabel:SetText("Combat Log Event Spell ID")
	self.combatLogEventSpellIDLabel:SetTextPadding(0, 2)
	self.combatLogEventSpellIDDropdown = AceGUI:Create("EPDropdown")
	self.combatLogEventSpellIDDropdown:SetCallback("OnValueChanged", HandleCombatLogEventSpellIDDropdownValueChanged)
	self.combatLogEventSpellIDDropdown.obj = self
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellIDLabel)
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellIDDropdown)
	self.combatLogEventContainer:AddChild(AceGUI:Create("EPSpacer"))
	self.combatLogEventSpellCountLabel = AceGUI:Create("EPLabel")
	self.combatLogEventSpellCountLabel:SetText("Spell Count")
	self.combatLogEventSpellCountLabel:SetTextPadding(0, 2)
	self.combatLogEventSpellCountLineEdit = AceGUI:Create("EPLineEdit")
	self.combatLogEventSpellCountLineEdit:SetCallback("OnTextChanged", HandleCombatLogEventSpellCountTextChanged)
	self.combatLogEventSpellCountLineEdit.obj = self
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellCountLabel)
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellCountLineEdit)
	self:AddChild(self.combatLogEventContainer)

	self.assigneeTypeContainer = AceGUI:Create("EPContainer")
	self.assigneeTypeContainer:SetLayout("EPVerticalLayout")
	self.assigneeTypeContainer:SetSpacing(0, 2)
	self.assigneeTypeLabel = AceGUI:Create("EPLabel")
	self.assigneeTypeLabel:SetText("Assignment Type")
	self.assigneeTypeLabel:SetTextPadding(0, 2)
	self.assigneeTypeDropdown = AceGUI:Create("EPDropdown")
	self.assigneeTypeDropdown:SetCallback("OnValueChanged", HandleAssigneeTypeDropdownValueChanged)
	self.assigneeTypeDropdown.obj = self
	self.assigneeTypeContainer:AddChild(self.assigneeTypeLabel)
	self.assigneeTypeContainer:AddChild(self.assigneeTypeDropdown)
	self:AddChild(self.assigneeTypeContainer)

	self.assigneeContainer = AceGUI:Create("EPContainer")
	self.assigneeContainer:SetLayout("EPVerticalLayout")
	self.assigneeContainer:SetSpacing(0, 2)
	self.assigneeLabel = AceGUI:Create("EPLabel")
	self.assigneeLabel:SetText("Person to Assign")
	self.assigneeLabel:SetTextPadding(0, 2)
	self.assigneeDropdown = AceGUI:Create("EPDropdown")
	self.assigneeDropdown:SetCallback("OnValueChanged", HandleAssigneeDropdownValueChanged)
	self.assigneeDropdown.obj = self
	self.assigneeContainer:AddChild(self.assigneeLabel)
	self.assigneeContainer:AddChild(self.assigneeDropdown)
	self:AddChild(self.assigneeContainer)

	self.spellAssignmentContainer = AceGUI:Create("EPContainer")
	self.spellAssignmentContainer:SetLayout("EPVerticalLayout")
	self.spellAssignmentContainer:SetSpacing(0, 2)
	self.spellAssignmentLabel = AceGUI:Create("EPLabel")
	self.spellAssignmentLabel:SetText("Spell Assignment")
	self.spellAssignmentLabel:SetTextPadding(0, 2)
	self.spellAssignmentDropdown = AceGUI:Create("EPDropdown")
	self.spellAssignmentDropdown:SetCallback("OnValueChanged", HandleSpellAssignmentDropdownValueChanged)
	self.spellAssignmentDropdown.obj = self
	self.spellAssignmentDropdown:AddItem("Recent", "Recent", "EPDropdownItemMenu", {}, true)
	self.spellAssignmentDropdown:SetItemDisabled("Recent", true)
	self.spellAssignmentContainer:AddChild(self.spellAssignmentLabel)
	self.spellAssignmentContainer:AddChild(self.spellAssignmentDropdown)
	self:AddChild(self.spellAssignmentContainer)

	self.timeContainer = AceGUI:Create("EPContainer")
	self.timeContainer:SetLayout("EPVerticalLayout")
	self.timeContainer:SetSpacing(0, 2)
	self.timeLabel = AceGUI:Create("EPLabel")
	self.timeLabel:SetText("Time")
	self.timeLabel:SetTextPadding(0, 2)
	self.timeEditBox = AceGUI:Create("EPLineEdit")
	self.timeEditBox.obj = self
	self.timeEditBox:SetCallback("OnTextChanged", HandleTimeTextChanged)
	self.timeContainer:AddChild(self.timeLabel)
	self.timeContainer:AddChild(self.timeEditBox)
	self:AddChild(self.timeContainer)

	self.optionalTextContainer = AceGUI:Create("EPContainer")
	self.optionalTextContainer:SetLayout("EPVerticalLayout")
	self.optionalTextContainer:SetSpacing(0, 2)
	self.optionalTextLabel = AceGUI:Create("EPLabel")
	self.optionalTextLabel:SetText("Assignment Text (Optional)")
	self.optionalTextLabel:SetTextPadding(0, 2)
	self.optionalTextLineEdit = AceGUI:Create("EPLineEdit")
	self.optionalTextLineEdit.obj = self
	self.optionalTextLineEdit:SetCallback("OnTextChanged", HandleOptionalTextChanged)
	self.optionalTextContainer:AddChild(self.optionalTextLabel)
	self.optionalTextContainer:AddChild(self.optionalTextLineEdit)
	self:AddChild(self.optionalTextContainer)

	self.targetContainer = AceGUI:Create("EPContainer")
	self.targetContainer:SetLayout("EPVerticalLayout")
	self.targetContainer:SetSpacing(0, 2)
	self.targetLabel = AceGUI:Create("EPLabel")
	self.targetLabel:SetText("Spell Target")
	self.targetLabel:SetTextPadding(0, 2)
	self.targetDropdown = AceGUI:Create("EPDropdown")
	self.targetDropdown:SetCallback("OnValueChanged", HandleTargetDropdownValueChanged)
	self.targetDropdown.obj = self
	self.targetDropdown:AddItem("Recent", "Recent", "EPDropdownItemMenu", {}, true)
	self.targetDropdown:SetItemDisabled("Recent", true)
	self.targetContainer:AddChild(self.targetLabel)
	self.targetContainer:AddChild(self.targetDropdown)
	self:AddChild(self.targetContainer)

	self.previewContainer = AceGUI:Create("EPContainer")
	self.previewContainer:SetLayout("EPVerticalLayout")
	self.previewContainer:SetSpacing(0, 2)
	local previewLabelLabel = AceGUI:Create("EPLabel")
	previewLabelLabel:SetText("Preview")
	previewLabelLabel:SetTextPadding(0, 2)
	self.previewLabel = AceGUI:Create("EPLabel")
	self.previewLabel:SetText("Spell Target")
	self.previewLabel:SetTextPadding(0, 2)
	self.previewContainer:AddChild(previewLabelLabel)
	self.previewContainer:AddChild(self.previewLabel)
	self:AddChild(self.previewContainer)

	self.okayButton = AceGUI:Create("EPButton")
	self.okayButton:SetText("Okay")
	self.okayButton:SetWidth(75)
	self.okayButton:SetBackdropColor(0, 0, 0, 0.9)
	self.okayButton:SetCallback("Clicked", HandleOkayButtonClicked)
	self.okayButton.frame:SetParent(self.buttonFrame)
	self.okayButton:SetPoint(
		"TOPRIGHT",
		self.buttonFrame,
		"TOPRIGHT",
		-buttonFrameBackdrop.edgeSize,
		-buttonFrameBackdrop.edgeSize
	)
	self.okayButton:SetPoint(
		"BOTTOMRIGHT",
		self.buttonFrame,
		"BOTTOMRIGHT",
		-buttonFrameBackdrop.edgeSize,
		buttonFrameBackdrop.edgeSize
	)
	self.okayButton.obj = self

	self.deleteButton = AceGUI:Create("EPButton")
	self.deleteButton:SetText("Delete")
	self.deleteButton:SetWidth(75)
	self.deleteButton:SetBackdropColor(0, 0, 0, 0.9)
	self.deleteButton:SetCallback("Clicked", HandleDeleteButtonClicked)
	self.deleteButton.frame:SetParent(self.buttonFrame)
	self.deleteButton.frame:SetPoint(
		"TOPLEFT",
		self.buttonFrame,
		"TOPLEFT",
		buttonFrameBackdrop.edgeSize,
		-buttonFrameBackdrop.edgeSize
	)
	self.deleteButton.frame:SetPoint(
		"BOTTOMLEFT",
		self.buttonFrame,
		"BOTTOMLEFT",
		buttonFrameBackdrop.edgeSize,
		buttonFrameBackdrop.edgeSize
	)
	self.deleteButton.obj = self

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetText("X")
	self.closeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.closeButton:SetHeight(windowBarHeight - 2 * frameBackdrop.edgeSize)
	self.closeButton:SetWidth(windowBarHeight - 2 * frameBackdrop.edgeSize)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton:SetPoint("TOPRIGHT", self.windowBar, "TOPRIGHT", -frameBackdrop.edgeSize, -frameBackdrop.edgeSize)
	self.closeButton:SetCallback("Clicked", function()
		self:Release()
	end)

	self.frame:Show()
	self:DoLayout()
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	if self.okayButton then
		self.okayButton:Release()
	end
	if self.closeButton then
		self.closeButton:Release()
	end
	if self.deleteButton then
		self.deleteButton:Release()
	end
	self.okayButton = nil
	self.deleteButton = nil
	self.closeButton = nil
end

---@param self EPAssignmentEditor
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(
			width + contentFramePadding.x * 2,
			buttonFrameHeight + height + windowBarHeight + contentFramePadding.y * 2
		)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 0.9)
	windowBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		windowBarText:SetFont(fPath, 12)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	local buttonFrame = CreateFrame("Frame", Type .. "ButtonFrame" .. count, frame, "BackdropTemplate")
	buttonFrame:SetBackdrop(buttonFrameBackdrop)
	buttonFrame:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
	buttonFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	buttonFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	buttonFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	buttonFrame:SetHeight(buttonFrameHeight)
	buttonFrame:EnableMouse(true)

	local contentFrameName = Type .. "ContentFrame" .. count
	local contentFrame = CreateFrame("Frame", contentFrameName, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", contentFramePadding.x, -contentFramePadding.y - windowBarHeight)
	contentFrame:SetPoint(
		"BOTTOMRIGHT",
		frame,
		"BOTTOMRIGHT",
		-contentFramePadding.x,
		contentFramePadding.y + buttonFrameHeight
	)

	---@class EPAssignmentEditor
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		content = contentFrame,
		windowBar = windowBar,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetAssignmentType = SetAssignmentType,
		SetAssigneeType = SetAssigneeType,
		buttonFrame = buttonFrame,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
