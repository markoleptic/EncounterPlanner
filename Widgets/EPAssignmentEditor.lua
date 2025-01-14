local Type = "EPAssignmentEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local getmetatable = getmetatable
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
local containerSpacing = { 4, 2 }
local closeButtonIconPadding = { 2, 2 }
local buttonWidth = 75
local title = "Assignment Editor"
local spacingBetweenOptions = 5
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
local lineBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = spacingBetweenOptions / 2.0, bottom = spacingBetweenOptions / 2.0 },
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
	{ text = "Fixed Time", itemValue = "Fixed Time" },
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
---@field enableSpellAssignmentCheckBox EPCheckBox
---@field assigneeTypeContainer EPContainer
---@field assigneeTypeDropdown EPDropdown
---@field assigneeTypeLabel EPLabel
---@field timeContainer EPContainer
---@field timeMinuteLineEdit EPLineEdit
---@field timeSecondLineEdit EPLineEdit
---@field enableTargetCheckBox EPCheckBox
---@field timeLabel EPLabel
---@field optionalTextContainer EPContainer
---@field optionalTextLineEdit EPLineEdit
---@field optionalTextLabel EPLabel
---@field targetContainer EPContainer
---@field targetDropdown EPDropdown
---@field previewContainer EPContainer
---@field previewLabel EPLabel
---@field windowBar Frame|table
---@field obj any
---@field assignmentID integer|nil
---@field FormatTime fun(number): string,string

---@param children any
---@param enable boolean
local function SetEnabled(children, enable)
	for _, child in ipairs(children) do
		if child.type == "EPContainer" then
			SetEnabled(child.children, enable)
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
	elseif value == "Fixed Time" or value == "Boss Phase" then
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

	do
		self.assignmentTypeContainer = AceGUI:Create("EPContainer")
		self.assignmentTypeContainer:SetLayout("EPVerticalLayout")
		self.assignmentTypeContainer:SetSpacing(unpack(containerSpacing))
		self.assignmentTypeContainer:SetFullWidth(true)

		self.assignmentTypeLabel = AceGUI:Create("EPLabel")
		self.assignmentTypeLabel:SetText("Trigger:")
		self.assignmentTypeLabel:SetFrameHeightFromText()
		self.assignmentTypeLabel:SetFullWidth(true)

		self.assignmentTypeDropdown = AceGUI:Create("EPDropdown")
		self.assignmentTypeDropdown:SetFullWidth(true)
		self.assignmentTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleAssignmentTypeDropdownValueChanged(self, value)
		end)
		self.assignmentTypeDropdown:AddItems(assignmentTriggers, "EPDropdownItemToggle")

		self.assignmentTypeContainer:AddChildren(self.assignmentTypeLabel, self.assignmentTypeDropdown)
	end

	do
		local maxLabelWidth = 0.0
		self.combatLogEventContainer = AceGUI:Create("EPContainer")
		self.combatLogEventContainer:SetLayout("EPVerticalLayout")
		self.combatLogEventContainer:SetSpacing(0, 4)
		self.combatLogEventContainer:SetFullWidth(true)
		self.combatLogEventContainer:SetPadding(indentWidth, 0, 0, 0)

		local leftContainer = AceGUI:Create("EPContainer")
		leftContainer:SetLayout("EPHorizontalLayout")
		leftContainer:SetSpacing(unpack(containerSpacing))
		leftContainer:SetFullWidth(true)

		self.combatLogEventSpellIDLabel = AceGUI:Create("EPLabel")
		self.combatLogEventSpellIDLabel:SetText("Spell:")
		self.combatLogEventSpellIDLabel:SetFullHeight(true)
		self.combatLogEventSpellIDLabel:SetFrameWidthFromText()
		maxLabelWidth = max(maxLabelWidth, self.combatLogEventSpellIDLabel.frame:GetWidth())

		self.combatLogEventSpellIDDropdown = AceGUI:Create("EPDropdown")
		self.combatLogEventSpellIDDropdown:SetFullWidth(true)
		self.combatLogEventSpellIDDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", "CombatLogEventSpellID", value)
		end)

		local rightContainer = AceGUI:Create("EPContainer")
		rightContainer:SetLayout("EPHorizontalLayout")
		rightContainer:SetSpacing(unpack(containerSpacing))
		rightContainer:SetFullWidth(true)

		self.combatLogEventSpellCountLabel = AceGUI:Create("EPLabel")
		self.combatLogEventSpellCountLabel:SetText("Count:")
		self.combatLogEventSpellCountLabel:SetFullHeight(true)
		self.combatLogEventSpellCountLabel:SetFrameWidthFromText()
		maxLabelWidth = max(maxLabelWidth, self.combatLogEventSpellCountLabel.frame:GetWidth())

		self.combatLogEventSpellCountLineEdit = AceGUI:Create("EPLineEdit")
		self.combatLogEventSpellCountLineEdit:SetFullWidth(true)
		self.combatLogEventSpellCountLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", "CombatLogEventSpellCount", value)
		end)

		self.combatLogEventSpellIDLabel:SetWidth(maxLabelWidth)
		self.combatLogEventSpellCountLabel:SetWidth(maxLabelWidth)

		leftContainer:AddChildren(self.combatLogEventSpellIDLabel, self.combatLogEventSpellIDDropdown)
		rightContainer:AddChildren(self.combatLogEventSpellCountLabel, self.combatLogEventSpellCountLineEdit)
		self.combatLogEventContainer:AddChildren(leftContainer, rightContainer)
	end

	do
		self.timeContainer = AceGUI:Create("EPContainer")
		self.timeContainer:SetLayout("EPVerticalLayout")
		self.timeContainer:SetSpacing(unpack(containerSpacing))
		self.timeContainer:SetFullWidth(true)

		self.timeLabel = AceGUI:Create("EPLabel")
		self.timeLabel:SetText("Time:")
		self.timeLabel:SetFrameHeightFromText()
		self.timeLabel:SetFullWidth(true)

		local doubleLineEditContainer = AceGUI:Create("EPContainer")
		doubleLineEditContainer:SetFullWidth(true)
		doubleLineEditContainer:SetLayout("EPHorizontalLayout")
		doubleLineEditContainer:SetSpacing(0, 0)

		self.timeMinuteLineEdit = AceGUI:Create("EPLineEdit")
		self.timeMinuteLineEdit:SetRelativeWidth(0.475)
		self.timeMinuteLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", "Time", value)
		end)

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":")
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)
		separatorLabel:SetFullHeight(true)

		self.timeSecondLineEdit = AceGUI:Create("EPLineEdit")
		self.timeSecondLineEdit:SetRelativeWidth(0.475)
		self.timeSecondLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", "Time", value)
		end)

		doubleLineEditContainer:AddChildren(self.timeMinuteLineEdit, separatorLabel, self.timeSecondLineEdit)
		self.timeContainer:AddChildren(self.timeLabel, doubleLineEditContainer)
	end

	local triggerContainer = AceGUI:Create("EPContainer")
	triggerContainer:SetLayout("EPVerticalLayout")
	triggerContainer:SetSpacing(0, 4)
	triggerContainer:SetFullWidth(true)
	triggerContainer:AddChildren(self.assignmentTypeContainer, self.combatLogEventContainer, self.timeContainer)

	do
		self.assigneeTypeContainer = AceGUI:Create("EPContainer")
		self.assigneeTypeContainer:SetLayout("EPVerticalLayout")
		self.assigneeTypeContainer:SetSpacing(unpack(containerSpacing))
		self.assigneeTypeContainer:SetFullWidth(true)

		self.assigneeTypeLabel = AceGUI:Create("EPLabel")
		self.assigneeTypeLabel:SetText("Type:")
		self.assigneeTypeLabel:SetFrameHeightFromText()
		self.assigneeTypeLabel:SetFullWidth(true)

		self.assigneeTypeDropdown = AceGUI:Create("EPDropdown")
		self.assigneeTypeDropdown:SetFullWidth(true)
		self.assigneeTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleAssigneeTypeDropdownValueChanged(self, value)
		end)

		self.assigneeTypeContainer:AddChildren(self.assigneeTypeLabel, self.assigneeTypeDropdown)
	end

	local spellContainer = AceGUI:Create("EPContainer")
	spellContainer:SetLayout("EPVerticalLayout")
	spellContainer:SetSpacing(0, 4)
	spellContainer:SetFullWidth(true)

	do
		self.spellAssignmentContainer = AceGUI:Create("EPContainer")
		self.spellAssignmentContainer:SetLayout("EPVerticalLayout")
		self.spellAssignmentContainer:SetSpacing(unpack(containerSpacing))
		self.spellAssignmentContainer:SetFullWidth(true)

		self.enableSpellAssignmentCheckBox = AceGUI:Create("EPCheckBox")
		self.enableSpellAssignmentCheckBox:SetText("Spell:")
		self.enableSpellAssignmentCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.spellAssignmentDropdown:SetEnabled(checked)
			if not checked then
				self.spellAssignmentDropdown:SetValue("0")
				self.spellAssignmentDropdown:SetText("")
				self:Fire("DataChanged", "SpellAssignment", "0")
			end
		end)
		self.enableSpellAssignmentCheckBox:SetCheckSize(18)

		self.spellAssignmentDropdown = AceGUI:Create("EPDropdown")
		self.spellAssignmentDropdown:SetFullWidth(true)
		self.spellAssignmentDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleSpellAssignmentDropdownValueChanged(self, value)
		end)
		self.spellAssignmentDropdown:AddItem("Recent", "Recent", "EPDropdownItemMenu", {}, true)
		self.spellAssignmentDropdown:SetItemEnabled("Recent", false)

		self.spellAssignmentContainer:AddChildren(self.enableSpellAssignmentCheckBox, self.spellAssignmentDropdown)
	end

	do
		self.targetContainer = AceGUI:Create("EPContainer")
		self.targetContainer:SetLayout("EPVerticalLayout")
		self.targetContainer:SetSpacing(unpack(containerSpacing))
		self.targetContainer:SetFullWidth(true)
		self.targetContainer:SetPadding(indentWidth, 0, 0, 0)

		self.enableTargetCheckBox = AceGUI:Create("EPCheckBox")
		self.enableTargetCheckBox:SetText("Targeted?")
		self.enableTargetCheckBox:SetFullWidth(true)
		self.enableTargetCheckBox:SetCheckSize(18)
		self.enableTargetCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.targetDropdown:SetEnabled(checked)
			if not checked then
				self.targetDropdown:SetValue("")
				self.targetDropdown:SetText("")
				self:Fire("DataChanged", "Target", "")
			end
		end)

		self.targetDropdown = AceGUI:Create("EPDropdown")
		self.targetDropdown:SetFullWidth(true)
		self.targetDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", "Target", value)
		end)

		self.targetContainer:AddChildren(self.enableTargetCheckBox, self.targetDropdown)
	end

	spellContainer:AddChildren(self.spellAssignmentContainer, self.targetContainer)

	do
		self.optionalTextContainer = AceGUI:Create("EPContainer")
		self.optionalTextContainer:SetLayout("EPVerticalLayout")
		self.optionalTextContainer:SetSpacing(unpack(containerSpacing))
		self.optionalTextContainer:SetFullWidth(true)

		self.optionalTextLabel = AceGUI:Create("EPLabel")
		self.optionalTextLabel:SetText("Text:")
		self.optionalTextLabel:SetFrameHeightFromText()
		self.optionalTextLabel:SetFullWidth(true)

		self.optionalTextLineEdit = AceGUI:Create("EPLineEdit")
		self.optionalTextLineEdit:SetFullWidth(true)
		self.optionalTextLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", "OptionalText", value)
		end)

		self.optionalTextContainer:AddChildren(self.optionalTextLabel, self.optionalTextLineEdit)
	end

	do
		self.previewContainer = AceGUI:Create("EPContainer")
		self.previewContainer:SetLayout("EPVerticalLayout")
		self.previewContainer:SetSpacing(unpack(containerSpacing))
		self.previewContainer:SetFullWidth(true)

		local previewLabelLabel = AceGUI:Create("EPLabel")
		previewLabelLabel:SetText("Preview:")
		previewLabelLabel:SetFrameHeightFromText()

		self.previewLabel = AceGUI:Create("EPLabel")
		self.previewLabel:SetText("")
		self.previewLabel:SetFullWidth(true)

		self.previewContainer:AddChildren(previewLabelLabel, self.previewLabel)
	end

	local line = AceGUI:Create("EPSpacer")
	line.frame:SetBackdrop(lineBackdrop)
	line.frame:SetBackdropColor(unpack(backdropBorderColor))
	line:SetFullWidth(true)
	line:SetHeight(2 + spacingBetweenOptions)

	local line2 = AceGUI:Create("EPSpacer")
	line2.frame:SetBackdrop(lineBackdrop)
	line2.frame:SetBackdropColor(unpack(backdropBorderColor))
	line2:SetFullWidth(true)
	line2:SetHeight(2 + spacingBetweenOptions)

	self:AddChildren(
		triggerContainer,
		self.assigneeTypeContainer,
		line,
		spellContainer,
		self.optionalTextContainer,
		line2,
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
		self:Fire("CloseButtonClicked")
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
	self.FormatTime = nil
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
	self.enableSpellAssignmentCheckBox = nil
	self.assigneeTypeContainer = nil
	self.assigneeTypeDropdown = nil
	self.assigneeTypeLabel = nil
	self.timeContainer = nil
	self.timeMinuteLineEdit = nil
	self.timeSecondLineEdit = nil
	self.enableTargetCheckBox = nil
	self.timeLabel = nil
	self.optionalTextContainer = nil
	self.optionalTextLineEdit = nil
	self.optionalTextLabel = nil
	self.targetContainer = nil
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
	self.assigneeTypeDropdown:SetValue(assigneeNameOrRole)

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
		local minutes, seconds = self.FormatTime(assignment.time)
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	elseif getmetatable(assignment) == metaTables.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		self:SetAssignmentType("TimedAssignment")
		self.assignmentTypeDropdown:SetValue("Fixed Time")
		local minutes, seconds = self.FormatTime(assignment.time)
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	elseif getmetatable(assignment) == metaTables.TimedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		self:SetAssignmentType("PhasedAssignment")
		self.assignmentTypeDropdown:SetValue("Boss Phase")
		local minutes, seconds = self.FormatTime(assignment.time)
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
		SetAssignmentID = SetAssignmentID,
		GetAssignmentID = GetAssignmentID,
		PopulateFields = PopulateFields,
		buttonFrame = buttonFrame,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
