local Type = "EPAssignmentEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local getmetatable = getmetatable
local Round = Round
local tremove = tremove
local unpack = unpack

local frameWidth = 200
local frameHeight = 200
local buttonFrameHeight = 28
local windowBarHeight = 28
local maxNumberOfRecentItems = 10
local indentWidth = 20
local contentFramePadding = { x = 15, y = 15 }
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local buttonFrameBackdropColor = { 0.1, 0.1, 0.1, 1.0 }
local containerSpacing = { 0, 2 }
local closeButtonIconPadding = { 2, 2 }
local buttonWidth = 75
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
			{ text = "SPELL_CAST_SUCCESS", itemValue = "SCC" },
			{ text = "SPELL_CAST_START", itemValue = "SCS" },
			{ text = "SPELL_AURA_APPLIED", itemValue = "SAA" },
			{ text = "SPELL_AURA_REMOVED", itemValue = "SAR" },
		},
	},
	{ text = "Absolute Time", itemValue = "Absolute Time" },
}

---@class EPAssignmentEditor : AceGUIContainer
---@field type string
---@field count number
---@field frame Frame|BackdropTemplate|table
---@field buttonFrame Frame|table
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
---@field enableSpellAssignmentCheckBox EPCheckBox
---@field assigneeTypeContainer EPContainer
---@field assigneeTypeDropdown EPDropdown
---@field assigneeTypeLabel EPLabel
---@field assigneeContainer EPContainer
---@field assigneeDropdown EPDropdown
---@field assigneeLabel EPLabel
---@field timeContainer EPContainer
---@field timeMinuteLineEdit EPLineEdit
---@field timeSecondLineEdit EPLineEdit
---@field enableTargetCheckBox EPCheckBox
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
---@field assignmentID integer|nil

local function SetEnabled(children, enable)
	for _, child in ipairs(children) do
		if child.type == "EPContainer" then
			SetEnabled(child.children)
		else
			if child.SetEnabled then
				child:SetEnabled(enable)
			end
		end
	end
end

---@param self EPAssignmentEditor
local function HandleAssignmentTypeDropdownValueChanged(self, value)
	if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
		SetEnabled(self.combatLogEventContainer.children, true)
	elseif value == "Absolute Time" or value == "Boss Phase" then
		SetEnabled(self.combatLogEventContainer.children, false)
	end
	self:Fire("DataChanged", "AssignmentType", value)
end

---@param self EPAssignmentEditor
local function HandleSpellAssignmentDropdownValueChanged(self, value)
	local _, itemText = self.spellAssignmentDropdown:FindItemAndText(value)
	if itemText then
		local recent = self.spellAssignmentDropdown:GetItemsFromDropdownItemMenu("Recent")
		if #recent > 0 then
			for i = #recent, 1, -1 do
				if recent[i].itemValue == value then
					self.spellAssignmentDropdown:RemoveItemsFromExistingDropdownItemMenu("Recent", { recent[i] })
					tremove(recent, i)
				end
			end
		end
		while #recent >= maxNumberOfRecentItems do
			self.spellAssignmentDropdown:RemoveItemsFromExistingDropdownItemMenu("Recent", { recent[#recent] })
			tremove(recent, #recent)
		end
		self.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu(
			"Recent",
			{ { itemValue = value, text = itemText } },
			1
		)
	end
	self:Fire("DataChanged", "SpellAssignment", value)
end

---@param self EPAssignmentEditor
local function HandleAssigneeTypeDropdownValueChanged(self, value)
	if value ~= "Individual" then
		SetEnabled(self.assigneeContainer.children, false)
	else
		SetEnabled(self.assigneeContainer.children, true)
	end
	self:Fire("DataChanged", "AssigneeType", value)
end

---@param self EPAssignmentEditor
---@param assignmentType AssignmentType
local function SetAssignmentType(self, assignmentType)
	if assignmentType == "CombatLogEventAssignment" then
		SetEnabled(self.combatLogEventContainer.children, true)
	elseif assignmentType == "TimedAssignment" then
		SetEnabled(self.combatLogEventContainer.children, false)
	elseif assignmentType == "PhasedAssignment" then
		SetEnabled(self.combatLogEventContainer.children, false)
	end
end

---@param self EPAssignmentEditor
---@param assigneeType AssigneeType
local function SetAssigneeType(self, assigneeType)
	if assigneeType == "Individual" then
		SetEnabled(self.assigneeContainer.children, true)
	else
		SetEnabled(self.assigneeContainer.children, false)
	end
end

---@param self EPAssignmentEditor
---@param ID integer
local function SetAssignmentID(self, ID)
	self.assignmentID = ID
end

---@param self EPAssignmentEditor
---@return integer|nil
local function GetAssignmentID(self)
	return self.assignmentID
end

---@param self EPAssignmentEditor
local function OnAcquire(self)
	self.assignmentID = nil
	self:SetLayout("EPVerticalLayout")
	self.frame:Show()

	self.assignmentTypeContainer = AceGUI:Create("EPContainer")
	self.assignmentTypeContainer:SetLayout("EPVerticalLayout")
	self.assignmentTypeContainer:SetSpacing(unpack(containerSpacing))
	self.assignmentTypeContainer:SetFullWidth(true)
	self.assignmentTypeLabel = AceGUI:Create("EPLabel")
	self.assignmentTypeLabel:SetText("Assignment Trigger:")
	self.assignmentTypeLabel:SetFullWidth(true)
	self.assignmentTypeLabel:SetFrameHeightFromText()
	self.assignmentTypeDropdown = AceGUI:Create("EPDropdown")
	self.assignmentTypeDropdown:SetFullWidth(true)
	self.assignmentTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleAssignmentTypeDropdownValueChanged(self, value)
	end)
	self.assignmentTypeDropdown:AddItems(assignmentTriggers, "EPDropdownItemToggle")
	self.assignmentTypeContainer:AddChildren(self.assignmentTypeLabel, self.assignmentTypeDropdown)

	self.combatLogEventContainer = AceGUI:Create("EPContainer")
	self.combatLogEventContainer:SetLayout("EPVerticalLayout")
	self.combatLogEventContainer:SetSpacing(unpack(containerSpacing))
	self.combatLogEventContainer:SetFullWidth(true)
	self.combatLogEventContainer:SetPadding(indentWidth, 0, 0, 0)
	self.combatLogEventSpellIDLabel = AceGUI:Create("EPLabel")
	self.combatLogEventSpellIDLabel:SetText("Combat Log Event Spell:")
	self.combatLogEventSpellIDLabel:SetFullWidth(true)
	self.combatLogEventSpellIDLabel:SetFrameHeightFromText()
	self.combatLogEventSpellIDDropdown = AceGUI:Create("EPDropdown")
	self.combatLogEventSpellIDDropdown:SetFullWidth(true)
	self.combatLogEventSpellIDDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("DataChanged", "CombatLogEventSpellID", value)
	end)
	self.combatLogEventContainer:AddChildren(
		self.combatLogEventSpellIDLabel,
		self.combatLogEventSpellIDDropdown,
		AceGUI:Create("EPSpacer")
	)
	self.combatLogEventSpellCountLabel = AceGUI:Create("EPLabel")
	self.combatLogEventSpellCountLabel:SetText("Combat Log Event Spell Count:")
	self.combatLogEventSpellCountLabel:SetFullWidth(true)
	self.combatLogEventSpellCountLabel:SetFrameHeightFromText()
	self.combatLogEventSpellCountLineEdit = AceGUI:Create("EPLineEdit")
	self.combatLogEventSpellCountLineEdit:SetFullWidth(true)
	self.combatLogEventSpellCountLineEdit:SetCallback("OnTextChanged", function(_, _, value)
		self:Fire("DataChanged", "CombatLogEventSpellCount", value)
	end)
	self.combatLogEventContainer:AddChildren(self.combatLogEventSpellCountLabel, self.combatLogEventSpellCountLineEdit)

	self.assigneeTypeContainer = AceGUI:Create("EPContainer")
	self.assigneeTypeContainer:SetLayout("EPVerticalLayout")
	self.assigneeTypeContainer:SetSpacing(unpack(containerSpacing))
	self.assigneeTypeContainer:SetFullWidth(true)
	self.assigneeTypeLabel = AceGUI:Create("EPLabel")
	self.assigneeTypeLabel:SetText("Assignment Type:")
	self.assigneeTypeLabel:SetFullWidth(true)
	self.assigneeTypeLabel:SetFrameHeightFromText()
	self.assigneeTypeDropdown = AceGUI:Create("EPDropdown")
	self.assigneeTypeDropdown:SetFullWidth(true)
	self.assigneeTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleAssigneeTypeDropdownValueChanged(self, value)
	end)
	self.assigneeTypeContainer:AddChildren(self.assigneeTypeLabel, self.assigneeTypeDropdown)

	self.assigneeContainer = AceGUI:Create("EPContainer")
	self.assigneeContainer:SetLayout("EPVerticalLayout")
	self.assigneeContainer:SetSpacing(unpack(containerSpacing))
	self.assigneeContainer:SetFullWidth(true)
	self.assigneeContainer:SetPadding(indentWidth, 0, 0, 0)
	self.assigneeLabel = AceGUI:Create("EPLabel")
	self.assigneeLabel:SetText("Person to Assign:")
	self.assigneeLabel:SetFullWidth(true)
	self.assigneeLabel:SetFrameHeightFromText()
	self.assigneeDropdown = AceGUI:Create("EPDropdown")
	self.assigneeDropdown:SetFullWidth(true)
	self.assigneeDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("DataChanged", "Assignee", value)
	end)
	self.assigneeContainer:AddChildren(self.assigneeLabel, self.assigneeDropdown)

	self.spellAssignmentContainer = AceGUI:Create("EPContainer")
	self.spellAssignmentContainer:SetLayout("EPVerticalLayout")
	self.spellAssignmentContainer:SetSpacing(unpack(containerSpacing))
	self.spellAssignmentContainer:SetFullWidth(true)

	self.spellAssignmentLabel = AceGUI:Create("EPLabel")
	self.spellAssignmentLabel:SetText("Spell Assignment:")
	self.spellAssignmentLabel:SetFullWidth(true)
	self.spellAssignmentLabel:SetFrameHeightFromText()

	local spellAssignmentCheckBoxWithDropdownContainer = AceGUI:Create("EPContainer")
	spellAssignmentCheckBoxWithDropdownContainer:SetFullWidth(true)
	spellAssignmentCheckBoxWithDropdownContainer:SetLayout("EPHorizontalLayout")
	spellAssignmentCheckBoxWithDropdownContainer:SetSpacing(0, 0)

	local enableSpellAssignmentCheckBox = AceGUI:Create("EPCheckBox")
	enableSpellAssignmentCheckBox:SetFullHeight(true)
	enableSpellAssignmentCheckBox:SetRelativeWidth(0.35)
	enableSpellAssignmentCheckBox:SetText("Enable")
	enableSpellAssignmentCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
		self.spellAssignmentDropdown:SetEnabled(checked)
		if not checked then
			self.spellAssignmentDropdown:SetValue("0")
			self.spellAssignmentDropdown:SetText("")
			self:Fire("DataChanged", "SpellAssignment", "0")
		end
	end)
	self.enableSpellAssignmentCheckBox = enableSpellAssignmentCheckBox

	self.spellAssignmentDropdown = AceGUI:Create("EPDropdown")
	self.spellAssignmentDropdown:SetRelativeWidth(0.65)
	self.spellAssignmentDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleSpellAssignmentDropdownValueChanged(self, value)
	end)
	self.spellAssignmentDropdown:AddItem("Recent", "Recent", "EPDropdownItemMenu", {}, true)
	self.spellAssignmentDropdown:SetItemEnabled("Recent", false)

	spellAssignmentCheckBoxWithDropdownContainer:AddChildren(
		enableSpellAssignmentCheckBox,
		self.spellAssignmentDropdown
	)
	self.spellAssignmentContainer:AddChildren(self.spellAssignmentLabel, spellAssignmentCheckBoxWithDropdownContainer)

	self.timeContainer = AceGUI:Create("EPContainer")
	self.timeContainer:SetLayout("EPVerticalLayout")
	self.timeContainer:SetSpacing(unpack(containerSpacing))
	self.timeContainer:SetFullWidth(true)
	self.timeLabel = AceGUI:Create("EPLabel")
	self.timeLabel:SetText("Time:")
	self.timeLabel:SetFullWidth(true)
	self.timeLabel:SetFrameHeightFromText()

	local doubleLineEditContainer = AceGUI:Create("EPContainer")
	doubleLineEditContainer:SetFullWidth(true)
	doubleLineEditContainer:SetLayout("EPHorizontalLayout")
	doubleLineEditContainer:SetSpacing(0, 0)

	local lineEditMinute = AceGUI:Create("EPLineEdit")
	lineEditMinute:SetRelativeWidth(0.45)
	lineEditMinute:SetCallback("OnTextSubmitted", function(_, _, value)
		self:Fire("DataChanged", "Time", value)
	end)

	local labelMinute = AceGUI:Create("EPLabel")
	labelMinute:SetText(":")
	labelMinute:SetRelativeWidth(0.1)
	labelMinute:SetFullHeight(true)
	labelMinute:SetHorizontalTextAlignment("CENTER")

	local lineEditSecond = AceGUI:Create("EPLineEdit")
	lineEditSecond:SetRelativeWidth(0.45)
	lineEditSecond:SetCallback("OnTextSubmitted", function(_, _, value)
		self:Fire("DataChanged", "Time", value)
	end)
	doubleLineEditContainer:AddChildren(lineEditMinute, labelMinute, lineEditSecond)

	self.timeMinuteLineEdit = lineEditMinute
	self.timeSecondLineEdit = lineEditSecond
	self.timeContainer:AddChildren(self.timeLabel, doubleLineEditContainer)

	self.optionalTextContainer = AceGUI:Create("EPContainer")
	self.optionalTextContainer:SetLayout("EPVerticalLayout")
	self.optionalTextContainer:SetSpacing(unpack(containerSpacing))
	self.optionalTextContainer:SetFullWidth(true)
	self.optionalTextLabel = AceGUI:Create("EPLabel")
	self.optionalTextLabel:SetText("Text:")
	self.optionalTextLabel:SetFullWidth(true)
	self.optionalTextLabel:SetFrameHeightFromText()
	self.optionalTextLineEdit = AceGUI:Create("EPLineEdit")
	self.optionalTextLineEdit:SetFullWidth(true)
	self.optionalTextLineEdit:SetCallback("OnTextChanged", function(_, _, value)
		self:Fire("DataChanged", "OptionalText", value)
	end)
	self.optionalTextContainer:AddChildren(self.optionalTextLabel, self.optionalTextLineEdit)

	self.targetContainer = AceGUI:Create("EPContainer")
	self.targetContainer:SetLayout("EPVerticalLayout")
	self.targetContainer:SetSpacing(unpack(containerSpacing))
	self.targetContainer:SetFullWidth(true)

	self.targetLabel = AceGUI:Create("EPLabel")
	self.targetLabel:SetText("Spell Assignment Target:")
	self.targetLabel:SetFullWidth(true)
	self.targetLabel:SetFrameHeightFromText()

	local checkBoxWithDropdownContainer = AceGUI:Create("EPContainer")
	checkBoxWithDropdownContainer:SetFullWidth(true)
	checkBoxWithDropdownContainer:SetLayout("EPHorizontalLayout")
	checkBoxWithDropdownContainer:SetSpacing(0, 0)

	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetFullHeight(true)
	checkBox:SetRelativeWidth(0.35)
	checkBox:SetText("Enable")
	checkBox:SetCallback("OnValueChanged", function(_, _, checked)
		self.targetDropdown:SetEnabled(checked)
		if not checked then
			self.targetDropdown:SetValue("")
			self.targetDropdown:SetText("")
			self:Fire("DataChanged", "Target", "")
		end
	end)
	self.enableTargetCheckBox = checkBox

	self.targetDropdown = AceGUI:Create("EPDropdown")
	self.targetDropdown:SetRelativeWidth(0.65)
	self.targetDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("DataChanged", "Target", value)
	end)

	checkBoxWithDropdownContainer:AddChildren(checkBox, self.targetDropdown)
	self.targetContainer:AddChildren(self.targetLabel, checkBoxWithDropdownContainer)

	self.previewContainer = AceGUI:Create("EPContainer")
	self.previewContainer:SetLayout("EPVerticalLayout")
	self.previewContainer:SetSpacing(unpack(containerSpacing))
	self.previewContainer:SetFullWidth(true)
	local previewLabelLabel = AceGUI:Create("EPLabel")
	previewLabelLabel:SetText("Preview:")
	previewLabelLabel:SetFullWidth(true)
	previewLabelLabel:SetFrameHeightFromText()
	self.previewLabel = AceGUI:Create("EPLabel")
	self.previewLabel:SetText("Spell Target")
	self.previewLabel:SetFullWidth(true)
	self.previewLabel:SetFrameHeightFromText()
	self.previewContainer:AddChildren(previewLabelLabel, self.previewLabel)

	self:AddChildren(
		self.assignmentTypeContainer,
		self.combatLogEventContainer,
		self.assigneeTypeContainer,
		self.assigneeContainer,
		self.spellAssignmentContainer,
		self.timeContainer,
		self.optionalTextContainer,
		self.targetContainer,
		self.previewContainer
	)

	local edgeSize = frameBackdrop.edgeSize

	self.deleteButton = AceGUI:Create("EPButton")
	self.deleteButton:SetText("Delete")
	self.deleteButton:SetWidth(buttonWidth)
	self.deleteButton:SetBackdropColor(unpack(backdropColor))
	self.deleteButton:SetCallback("Clicked", function()
		self:Fire("DeleteButtonClicked")
	end)
	self.deleteButton.frame:SetParent(self.buttonFrame)
	self.deleteButton.frame:SetPoint("TOP", self.buttonFrame, "TOP", 0, -edgeSize)
	self.deleteButton.frame:SetPoint("BOTTOM", self.buttonFrame, "BOTTOM", 0, edgeSize)

	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(unpack(closeButtonIconPadding))
	self.closeButton:SetBackdropColor(unpack(backdropColor))
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Release()
	end)
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	if self.closeButton then
		self.closeButton:Release()
	end
	if self.deleteButton then
		self.deleteButton:Release()
	end
	self.deleteButton = nil
	self.closeButton = nil
	self.timeMinuteLineEdit = nil
	self.timeSecondLineEdit = nil
	self.assignmentTypeContainer = nil
	self.assignmentTypeDropdown = nil
	self.assignmentTypeLabel = nil
	self.combatLogEventContainer = nil
	self.combatLogEventSpellIDDropdown = nil
	self.combatLogEventSpellIDLabel = nil
	self.combatLogEventSpellCountLineEdit = nil
	self.combatLogEventSpellCountLabel = nil
	self.spellAssignmentContainer = nil
	self.spellAssignmentDropdown = nil
	self.spellAssignmentLabel = nil
	self.enableSpellAssignmentCheckBox = nil
	self.assigneeTypeContainer = nil
	self.assigneeTypeDropdown = nil
	self.assigneeTypeLabel = nil
	self.assigneeContainer = nil
	self.assigneeDropdown = nil
	self.assigneeLabel = nil
	self.timeContainer = nil
	self.timeMinuteLineEdit = nil
	self.timeSecondLineEdit = nil
	self.enableTargetCheckBox = nil
	self.timeLabel = nil
	self.optionalTextContainer = nil
	self.optionalTextLineEdit = nil
	self.optionalTextLabel = nil
	self.targetContainer = nil
	self.targetLabel = nil
	self.targetDropdown = nil
	self.previewContainer = nil
	self.previewLabel = nil
end

local function OnHeightSet(self, width)
	self.content:SetHeight(width)
	self.content.height = width
end

local function OnWidthSet(self, width)
	self.content:SetWidth(width)
	self.content.width = width
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

---@param self EPAssignmentEditor
---@param assignment Assignment
---@param previewText string
---@param metaTables {CombatLogEventAssignment: CombatLogEventAssignment, TimedAssignment:TimedAssignment, PhasedAssignment:PhasedAssignment}
local function PopulateFields(self, assignment, previewText, metaTables)
	self:SetAssignmentID(assignment.uniqueID)
	local assigneeNameOrRole = assignment.assigneeNameOrRole
	if assigneeNameOrRole == "{everyone}" then
		self:SetAssigneeType("Everyone")
		self.assigneeTypeDropdown:SetValue(assigneeNameOrRole)
		self.assigneeDropdown:SetValue("")
	else
		local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
		local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
		local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
		if classMatch then
			self:SetAssigneeType("Class")
			self.assigneeTypeDropdown:SetValue(assigneeNameOrRole)
			self.assigneeDropdown:SetValue("")
		elseif roleMatch then
			self:SetAssigneeType("Role")
			self.assigneeTypeDropdown:SetValue(assigneeNameOrRole)
			self.assigneeDropdown:SetValue("")
		elseif groupMatch then
			self:SetAssigneeType("GroupNumber")
			self.assigneeTypeDropdown:SetValue(assigneeNameOrRole)
			self.assigneeDropdown:SetValue("")
		else
			self:SetAssigneeType("Individual")
			self.assigneeTypeDropdown:SetValue("Individual")
			self.assigneeDropdown:SetValue(assigneeNameOrRole)
		end
	end

	self.previewLabel:SetText(previewText)

	local enableTargetCheckBox = assignment.targetName ~= nil and assignment.targetName ~= ""
	self.enableTargetCheckBox:SetChecked(enableTargetCheckBox)
	self.targetDropdown:SetEnabled(enableTargetCheckBox)
	self.targetDropdown:SetValue(assignment.targetName)

	self.optionalTextLineEdit:SetText(assignment.text)

	local enableSpellAssignmentCheckBox = assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID ~= 0
	self.enableSpellAssignmentCheckBox:SetChecked(enableSpellAssignmentCheckBox)
	self.spellAssignmentDropdown:SetEnabled(enableSpellAssignmentCheckBox)
	self.spellAssignmentDropdown:SetValue(assignment.spellInfo.spellID)

	if getmetatable(assignment) == metaTables.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		self:SetAssignmentType("CombatLogEventAssignment")
		self.assignmentTypeDropdown:SetValue(assignment.combatLogEventType)
		self.combatLogEventSpellIDDropdown:SetValue(assignment.combatLogEventSpellID)
		self.combatLogEventSpellCountLineEdit:SetText(assignment.spellCount)
		local minutes = floor(assignment.time / 60)
		local seconds = Round((assignment.time % 60) * 10) / 10
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	elseif getmetatable(assignment) == metaTables.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		self:SetAssignmentType("TimedAssignment")
		self.assignmentTypeDropdown:SetValue("Absolute Time")
		local minutes = floor(assignment.time / 60)
		local seconds = assignment.time % 60
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	elseif getmetatable(assignment) == metaTables.TimedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		self:SetAssignmentType("PhasedAssignment")
		self.assignmentTypeDropdown:SetValue("Boss Phase")
		local minutes = floor(assignment.time / 60)
		local seconds = assignment.time % 60
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	local buttonFrame = CreateFrame("Frame", Type .. "ButtonFrame" .. count, frame, "BackdropTemplate")
	buttonFrame:SetBackdrop(buttonFrameBackdrop)
	buttonFrame:SetBackdropColor(unpack(buttonFrameBackdropColor))
	buttonFrame:SetBackdropBorderColor(unpack(backdropBorderColor))
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
		OnHeightSet = OnHeightSet,
		OnWidthSet = OnWidthSet,
		LayoutFinished = LayoutFinished,
		SetAssignmentType = SetAssignmentType,
		SetAssigneeType = SetAssigneeType,
		SetAssignmentID = SetAssignmentID,
		GetAssignmentID = GetAssignmentID,
		PopulateFields = PopulateFields,
		buttonFrame = buttonFrame,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
