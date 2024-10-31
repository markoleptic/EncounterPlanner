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
local FrameBackdrop = {
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
local ButtonFrameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local buttonBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local function FlashButton_OnLeave(self)
	local fadeIn = self.fadeIn
	if fadeIn:IsPlaying() then
		fadeIn:Stop()
	end
	self.fadeOut:Play()
end

local function FlashButton_OnEnter(self)
	local fadeOut = self.fadeOut
	if fadeOut:IsPlaying() then
		fadeOut:Stop()
	end
	self.fadeIn:Play()
end

local function CreateFlashButton(parent, text, width, height)
	local Button = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	Button:SetSize(width or 80, height or 20)
	Button:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 1,
	})
	Button:SetBackdropColor(0.725, 0.008, 0.008)
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnEnter", FlashButton_OnEnter)
	Button:SetScript("OnLeave", FlashButton_OnLeave)
	Button:SetNormalFontObject("GameFontNormal")
	Button:SetText(text or "")

	Button.bg = Button:CreateTexture(nil, "BORDER")
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		Button.bg:SetAllPoints()
	else
		Button.bg:SetTexelSnappingBias(0.0)
		Button.bg:SetSnapToPixelGrid(false)
		Button.bg:SetPoint("TOPLEFT", Button.TopEdge, "BOTTOMLEFT")
		Button.bg:SetPoint("BOTTOMRIGHT", Button.BottomEdge, "TOPRIGHT")
	end
	Button.bg:SetColorTexture(0.0, 0.6, 0.4)
	Button.bg:Hide()

	Button.fadeIn = Button.bg:CreateAnimationGroup()
	Button.fadeIn:SetScript("OnPlay", function()
		Button.bg:Show()
	end)
	local fadeIn = Button.fadeIn:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	Button.fadeOut = Button.bg:CreateAnimationGroup()
	Button.fadeOut:SetScript("OnFinished", function()
		Button.bg:Hide()
	end)
	local fadeOut = Button.fadeOut:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")

	return Button
end

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
	{
		text = "Boss Phase",
		itemValue = "Boss Phase",
		dropdownItemMenuData = {},
	},
}

---@class EPAssignmentEditor : AceGUIContainer
---@field type string
---@field count number
---@field frame Frame|BackdropTemplate|table
---@field buttonFrame Frame|BackdropTemplate|table
---@field okayButton Button|BackdropTemplate|table
---@field deleteButton Button|BackdropTemplate|table
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
---@field phaseNumberContainer EPContainer
---@field phaseNumberLabel EPLabel
---@field phaseNumberDropdown EPDropdown
---@field optionalTextContainer EPContainer
---@field optionalTextLineEdit EPLineEdit
---@field optionalTextLabel EPLabel
---@field targetContainer EPContainer
---@field targetLabel EPLabel
---@field targetDropdown EPDropdown
---@field previewContainer EPContainer
---@field previewLabel EPLabel
---@field obj any

local function HandleOkayButtonClicked(frame, mouseButtonType, down) end

local function HandleOkayButtonEnter(frame, motion) end

local function HandleOkayButtonLeave(frame, motion) end

local function HandleDeleteButtonClicked(frame, mouseButtonType, down) end

local function HandleDeleteButtonEnter(frame, motion) end

local function HandleDeleteButtonLeave(frame, motion) end

local function HandleAssignmentTypeDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
		self.combatLogEventContainer.frame:Show()
		self.phaseNumberContainer.frame:Show()
	elseif value == "Absolute Time" then
		self.combatLogEventContainer.frame:Hide()
		self.phaseNumberContainer.frame:Hide()
	elseif value == "Boss Phase" then
		self.combatLogEventContainer.frame:Hide()
		self.phaseNumberContainer.frame:Show()
	end
	self:Fire("DataChanged", "AssignmentType", value)
end

local function HandleCombatLogEventSpellIDDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "CombatLogEventSpellID", value)
end

local function HandleCombatLogEventSpellCountValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "CombatLogEventSpellCount", value)
end

local function HandlePhaseNumberDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "PhaseNumber", value)
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

local function HandleTimeLineEditValueChanged(frame, callbackName, value)
	local self = frame.obj
	self:Fire("DataChanged", "Time", value)
end

local function HandleOptionalTextLineEditValueChanged(frame, callbackName, value)
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
		self.phaseNumberContainer.frame:Show()
	elseif assignmentType == "TimedAssignment" then
		self.combatLogEventContainer.frame:Hide()
		self.phaseNumberContainer.frame:Hide()
	elseif assignmentType == "PhasedAssignment" then
		self.combatLogEventContainer.frame:Hide()
		self.phaseNumberContainer.frame:Show()
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
	self.combatLogEventSpellCountLineEdit:SetCallback("OnValueChanged", HandleCombatLogEventSpellCountValueChanged)
	self.combatLogEventSpellCountLineEdit.obj = self
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellCountLabel)
	self.combatLogEventContainer:AddChild(self.combatLogEventSpellCountLineEdit)
	self:AddChild(self.combatLogEventContainer)

	self.phaseNumberContainer = AceGUI:Create("EPContainer")
	self.phaseNumberContainer:SetLayout("EPVerticalLayout")
	self.phaseNumberContainer:SetSpacing(0, 2)
	self.phaseNumberLabel = AceGUI:Create("EPLabel")
	self.phaseNumberLabel:SetText("Phase Number")
	self.phaseNumberLabel:SetTextPadding(0, 2)
	self.phaseNumberDropdown = AceGUI:Create("EPDropdown")
	self.phaseNumberDropdown:SetCallback("OnValueChanged", HandlePhaseNumberDropdownValueChanged)
	self.phaseNumberDropdown.obj = self
	self.phaseNumberContainer:AddChild(self.phaseNumberLabel)
	self.phaseNumberContainer:AddChild(self.phaseNumberDropdown)
	self:AddChild(self.phaseNumberContainer)

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
	self.timeEditBox:SetCallback("OnValueChanged", HandleTimeLineEditValueChanged)
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
	self.optionalTextLineEdit:SetCallback("OnValueChanged", HandleOptionalTextLineEditValueChanged)
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

	self.frame:Show()
	self:DoLayout()
end

---@param self EPAssignmentEditor
local function OnRelease(self) end

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
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0.05, 0.05, 0.05, 1.0)
	windowBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
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
	buttonFrame:SetBackdrop(ButtonFrameBackdrop)
	buttonFrame:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
	buttonFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
	buttonFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	buttonFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	buttonFrame:SetHeight(buttonFrameHeight)

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

	local deleteButton = CreateFrame("Button", Type .. "DeleteButton" .. count, buttonFrame, "BackdropTemplate")
	deleteButton:EnableMouse(true)
	deleteButton:SetScript("OnClick", HandleOkayButtonClicked)
	deleteButton:SetScript("OnEnter", HandleOkayButtonEnter)
	deleteButton:SetScript("OnLeave", HandleOkayButtonLeave)
	deleteButton:SetPoint("LEFT")
	deleteButton:SetBackdrop(buttonBackdrop)
	deleteButton:SetBackdropColor(1, 0, 0, 1)
	deleteButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	local deleteText = deleteButton:CreateFontString(Type .. "DeleteText" .. count, "OVERLAY", "GameFontNormal")
	deleteText:ClearAllPoints()
	deleteText:SetPoint("CENTER")
	deleteText:SetJustifyV("MIDDLE")
	deleteText:SetJustifyH("CENTER")
	if fPath then
		deleteText:SetFont(fPath, 14)
	end
	deleteText:SetText("Delete")
	deleteButton:SetSize(75, 24)

	local okayButton = CreateFrame("Button", Type .. "OkButton" .. count, buttonFrame, "BackdropTemplate")
	okayButton:EnableMouse(true)
	okayButton:SetScript("OnClick", HandleDeleteButtonClicked)
	okayButton:SetScript("OnEnter", HandleDeleteButtonEnter)
	okayButton:SetScript("OnLeave", HandleDeleteButtonLeave)
	okayButton:SetPoint("RIGHT")
	okayButton:SetBackdrop(buttonBackdrop)
	okayButton:SetBackdropColor(0, 1, 0, 1)
	okayButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	local text = okayButton:CreateFontString(Type .. "OkText" .. count, "OVERLAY", "GameFontNormal")
	text:ClearAllPoints()
	text:SetPoint("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetJustifyH("CENTER")
	if fPath then
		text:SetFont(fPath, 14)
	end
	text:SetText("Okay")
	okayButton:SetSize(75, 24)

	local closebutton = CreateFlashButton(windowBar, "X", 20, 20)

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
		okayButton = okayButton,
		deleteButton = deleteButton,
	}

	closebutton:SetPoint("TOPRIGHT", -2, -2)
	closebutton:SetScript("OnClick", function()
		widget:Release()
	end)

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
