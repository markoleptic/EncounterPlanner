local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants

local Type = "EPAssignmentEditor"
local Version = 1

local AssignmentEditorDataType = Private.classes.AssignmentEditorDataType
local sTooltip = Private.tooltip

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local getmetatable = getmetatable
local max = math.max
local tremove = table.remove
local unpack = unpack

local k = {
	AssignmentTriggers = {
		{
			text = L["Combat Log Event"],
			itemValue = "Combat Log Event",
			dropdownItemMenuData = {
				{ text = L["Spell Cast Start"], itemValue = "SCS" },
				{ text = L["Spell Cast Success"], itemValue = "SCC" },
				{ text = L["Spell Aura Applied"], itemValue = "SAA" },
				{ text = L["Spell Aura Removed"], itemValue = "SAR" },
				{ text = L["Unit Died"], itemValue = "UD" },
			},
		},
		{ text = L["Fixed Time"], itemValue = "Fixed Time" },
	},
	BackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	BackdropColor = { 0, 0, 0, 0.9 },
	ButtonFrameBackdrop = {
		bgFile = constants.textures.kGenericWhite,
		edgeFile = constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	ButtonFrameBackdropColor = { 0.1, 0.1, 0.1, 1.0 },
	ButtonFrameHeight = 28,
	ContainerContainerSpacing = { 0, 4 },
	ContentFramePadding = { x = 15, y = 15 },
	CloseTexture = constants.textures.kClose,
	DisabledTextColor = { 0.33, 0.33, 0.33, 1 },
	FavoriteFilledTexture = constants.textures.kFavoriteFilled,
	FavoriteOutlineTexture = constants.textures.kFavoriteOutlined,
	FrameBackdrop = {
		bgFile = constants.textures.kGenericWhite,
		edgeFile = constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	FrameHeight = 200,
	FrameWidth = 220,
	HalfDisabledTextColor = { 0.66, 0.66, 0.66, 1 },
	IndentWidth = 20,
	LabelWidgetSpacing = { 2, 2 },
	MaxNumberOfRecentItems = 10,
	SpacingBetweenOptions = 6,
	Title = L["Assignment Editor"],
	WindowBarHeight = 28,
}
k.LineBackdrop = {
	bgFile = constants.textures.kGenericWhite,
	tile = false,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = k.SpacingBetweenOptions, bottom = k.SpacingBetweenOptions },
}

---@param frame Frame
---@param label string
---@param description string
local function ShowTooltip(frame, label, description)
	sTooltip:SetOwner(frame, "ANCHOR_TOP")
	sTooltip:SetText(label, 1, 0.82, 0, true)
	sTooltip:AddLine(description, 1, 1, 1, true)
	sTooltip:Show()
end

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
	if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" or value == "UD" then -- Combat Log Event
		SetEnabled(self.combatLogEventContainer.children, true)
		self:Fire("DataChanged", AssignmentEditorDataType.AssignmentType, value)
	elseif value == "Fixed Time" then
		SetEnabled(self.combatLogEventContainer.children, false)
		self:Fire("DataChanged", AssignmentEditorDataType.AssignmentType, value)
	end
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
		while #recent >= k.MaxNumberOfRecentItems do
			self.spellAssignmentDropdown:RemoveItemsFromExistingDropdownItemMenu("Recent", { recent[#recent] })
			tremove(recent, #recent)
		end
		self.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu(
			"Recent",
			{ { itemValue = value, text = itemText } },
			1
		)
		self.spellAssignmentDropdown:SetItemEnabled("Recent", true)
	end
	self.spellAssignmentDropdown:ClearHighlightsForExistingDropdownItemMenu("Recent")
	self:Fire("RecentItemsChanged", self.spellAssignmentDropdown:GetItemsFromDropdownItemMenu("Recent"))
	self:Fire("DataChanged", AssignmentEditorDataType.SpellAssignment, value)
end

---@param self EPAssignmentEditor
---@param widget EPDropdownItemToggle
local function HandleCustomTextureClicked(self, widget, value)
	local favorites = self.spellAssignmentDropdown:GetItemsFromDropdownItemMenu("Favorite")
	local dropdownItemDataToRemove = nil
	if #favorites > 0 then
		for i = #favorites, 1, -1 do
			if favorites[i].itemValue == value then
				dropdownItemDataToRemove = favorites[i]
				break
			end
		end
	end

	if dropdownItemDataToRemove == nil then -- Add new favorite to favorite menu and update texture
		local _, itemText = self.spellAssignmentDropdown:FindItemAndText(value)
		self.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu("Favorite", {
			{
				itemValue = value,
				text = itemText,
				customTextureSelectable = true,
				customTexture = k.CloseTexture,
				customTextureVertexColor = { 1, 1, 1, 1 },
			},
		})
		self.spellAssignmentDropdown:Sort("Favorite", true)
		widget.customTexture:SetTexture(k.FavoriteFilledTexture)
	else -- Remove favorite from favorite menu and update texture
		local parentItemMenu = widget.parentDropdownItemMenu
		if parentItemMenu and parentItemMenu:GetValue() == "Favorite" then
			local item = self.spellAssignmentDropdown:FindItemAndText(value)
			if item then
				item.customTexture:SetTexture(k.FavoriteOutlineTexture)
			end
		else
			widget.customTexture:SetTexture(k.FavoriteOutlineTexture)
		end
		self.spellAssignmentDropdown:RemoveItemsFromExistingDropdownItemMenu("Favorite", { dropdownItemDataToRemove })
	end

	favorites = self.spellAssignmentDropdown:GetItemsFromDropdownItemMenu("Favorite")
	self.spellAssignmentDropdown:SetItemEnabled("Favorite", #favorites > 0)
	self:Fire("FavoriteItemsChanged", favorites)
end

---@param self EPAssignmentEditor
---@param assignee string
---@param roster table<string, RosterEntry>
---@param spellID integer
---@param favoritedSpellDropdownItems table<integer, DropdownItemData>
local function RepopulateSpellDropdown(self, assignee, roster, spellID, favoritedSpellDropdownItems)
	local class, role = nil, nil
	if roster then
		if roster[assignee] then
			if roster[assignee].class and roster[assignee].class:find("class:") then
				class = roster[assignee].class
			end
			if roster[assignee].role and roster[assignee].role:find("role:") then
				role = roster[assignee].role
			end
		end

		if not class then
			if assignee:find("class:") then
				class = assignee
				role = nil
			elseif assignee:find("spec:") then
				class, role = Private.utilities.GetClassAndRoleFromSpecID(assignee)
			end
		end
	end

	if self.lastClassDropdownValue ~= class or self.lastRoleDropdownValue ~= role then
		local favoritedItemsMap = {}
		if favoritedSpellDropdownItems then
			for _, v in ipairs(favoritedSpellDropdownItems) do
				favoritedItemsMap[v.itemValue] = true
			end
		end
		if class then
			self.spellAssignmentDropdown:RemoveItem("Class")
			self.spellAssignmentDropdown:RemoveItem("Core")
			self.spellAssignmentDropdown:RemoveItem("Group Utility")
			self.spellAssignmentDropdown:RemoveItem("Personal Defensive")
			self.spellAssignmentDropdown:RemoveItem("External Defensive")
			self.spellAssignmentDropdown:RemoveItem("Other")
			local dropdownItemData =
				Private.utilities.GetOrCreateSingleClassSpellDropdownItems(class, role, true, favoritedItemsMap)
			self.spellAssignmentDropdown:AddItems(dropdownItemData, "EPDropdownItemMenu", false, 3)
		else
			self.spellAssignmentDropdown:RemoveItem("Core")
			self.spellAssignmentDropdown:RemoveItem("Group Utility")
			self.spellAssignmentDropdown:RemoveItem("Personal Defensive")
			self.spellAssignmentDropdown:RemoveItem("External Defensive")
			self.spellAssignmentDropdown:RemoveItem("Other")

			local dropdownItemData = Private.utilities.GetOrCreateClassSpellDropdownItems(true, favoritedItemsMap)
			self.spellAssignmentDropdown:AddItems({ dropdownItemData }, "EPDropdownItemToggle", false, 3)
		end
	end

	self.lastClassDropdownValue, self.lastRoleDropdownValue = class, role
	self.spellAssignmentDropdown:SetValue(self.spellAssignmentDropdown.enabled and spellID or nil)
end

---@param self EPAssignmentEditor
local function RepopulateReminderOverridesFromPreferences(self)
	self.countdownLengthLineEdit:SetText(select(2, self.FormatTime(self.reminderPreferences.countdownLength)))
	self.cancelIfAlreadyCastedCheckBox:SetChecked(self.reminderPreferences.cancelIfAlreadyCasted)
	self.holdDurationLineEdit:SetText(select(2, self.FormatTime(self.reminderPreferences.messages.holdDuration)))
end

---@param self EPAssignmentEditor
---@param assignmentType AssignmentType
local function SetAssignmentType(self, assignmentType)
	if assignmentType == "CombatLogEventAssignment" then
		SetEnabled(self.combatLogEventContainer.children, true)
	elseif assignmentType == "TimedAssignment" then
		SetEnabled(self.combatLogEventContainer.children, false)
	end
end

---@param self EPAssignmentEditor
---@param assignment Assignment|CombatLogEventAssignment|TimedAssignment
local function SetAssignment(self, assignment)
	self.assignment = assignment
end

---@param self EPAssignmentEditor
---@return Assignment|CombatLogEventAssignment|TimedAssignment|nil
local function GetAssignment(self)
	return self.assignment
end

---@param self EPAssignmentEditor
local function OnAcquire(self)
	self.frame:SetSize(k.FrameWidth, k.FrameHeight)
	self:SetLayout("EPVerticalLayout")
	self.frame:Show()
	self.content.spacing = { x = 0, y = 0 }

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle(k.Title)
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("CloseButtonClicked", function()
		self:Fire("CloseButtonClicked")
	end)
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
	end)
	self.windowBar = windowBar

	local assignmentTypeContainer = AceGUI:Create("EPContainer")
	assignmentTypeContainer:SetLayout("EPVerticalLayout")
	assignmentTypeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	assignmentTypeContainer:SetFullWidth(true)

	do
		local assignmentTypeLabel = AceGUI:Create("EPLabel")
		assignmentTypeLabel:SetText(L["Trigger:"], 0)
		assignmentTypeLabel:SetFrameHeightFromText()
		assignmentTypeLabel:SetFullWidth(true)

		local assignmentTypeDropdown = AceGUI:Create("EPDropdown")
		assignmentTypeDropdown:SetFullWidth(true)
		assignmentTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleAssignmentTypeDropdownValueChanged(self, value)
		end)
		assignmentTypeDropdown:AddItems(k.AssignmentTriggers)
		self.assignmentTypeDropdown = assignmentTypeDropdown

		assignmentTypeContainer:AddChildren(assignmentTypeLabel, assignmentTypeDropdown)
	end

	do
		local combatLogEventContainer = AceGUI:Create("EPContainer")
		combatLogEventContainer:SetLayout("EPVerticalLayout")
		combatLogEventContainer:SetSpacing(unpack(k.ContainerContainerSpacing))
		combatLogEventContainer:SetFullWidth(true)
		combatLogEventContainer:SetPadding(k.IndentWidth, 0, 0, 0)
		self.combatLogEventContainer = combatLogEventContainer

		local combatLogEventSpellIDContainer = AceGUI:Create("EPContainer")
		combatLogEventSpellIDContainer:SetLayout("EPHorizontalLayout")
		combatLogEventSpellIDContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		combatLogEventSpellIDContainer:SetFullWidth(true)

		local combatLogEventSpellIDLabel = AceGUI:Create("EPLabel")
		combatLogEventSpellIDLabel:SetText(L["Spell"] .. ":", 0)
		combatLogEventSpellIDLabel:SetFullHeight(true)
		combatLogEventSpellIDLabel:SetFrameWidthFromText()

		local combatLogEventSpellIDDropdown = AceGUI:Create("EPDropdown")
		combatLogEventSpellIDDropdown:SetWidth(100)
		combatLogEventSpellIDDropdown:SetFullWidth(true)
		combatLogEventSpellIDDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.CombatLogEventSpellID, value)
		end)
		self.combatLogEventSpellIDDropdown = combatLogEventSpellIDDropdown

		local combatLogEventSpellCountContainer = AceGUI:Create("EPContainer")
		combatLogEventSpellCountContainer:SetLayout("EPHorizontalLayout")
		combatLogEventSpellCountContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		combatLogEventSpellCountContainer:SetFullWidth(true)

		local combatLogEventSpellCountLabel = AceGUI:Create("EPLabel")
		combatLogEventSpellCountLabel:SetText(L["Count:"], 0)
		combatLogEventSpellCountLabel:SetFullHeight(true)
		combatLogEventSpellCountLabel:SetFrameWidthFromText()

		local combatLogEventSpellCountLineEdit = AceGUI:Create("EPLineEdit")
		combatLogEventSpellCountLineEdit:SetWidth(100)
		combatLogEventSpellCountLineEdit:SetFullWidth(true)
		combatLogEventSpellCountLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.CombatLogEventSpellCount, value)
		end)
		self.combatLogEventSpellCountLineEdit = combatLogEventSpellCountLineEdit

		local maxLabelWidth =
			max(combatLogEventSpellIDLabel.frame:GetWidth(), combatLogEventSpellCountLabel.frame:GetWidth())
		combatLogEventSpellIDLabel:SetWidth(maxLabelWidth)
		combatLogEventSpellCountLabel:SetWidth(maxLabelWidth)

		combatLogEventSpellIDContainer:AddChildren(combatLogEventSpellIDLabel, combatLogEventSpellIDDropdown)
		combatLogEventSpellCountContainer:AddChildren(combatLogEventSpellCountLabel, combatLogEventSpellCountLineEdit)
		self.combatLogEventContainer:AddChildren(combatLogEventSpellIDContainer, combatLogEventSpellCountContainer)
	end

	local triggerContainer = AceGUI:Create("EPContainer")
	triggerContainer:SetLayout("EPVerticalLayout")
	triggerContainer:SetSpacing(unpack(k.ContainerContainerSpacing))
	triggerContainer:SetFullWidth(true)
	triggerContainer:AddChildren(assignmentTypeContainer, self.combatLogEventContainer)
	self.triggerContainer = triggerContainer

	local timeContainer = AceGUI:Create("EPContainer")
	timeContainer:SetLayout("EPVerticalLayout")
	timeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	timeContainer:SetFullWidth(true)
	self.timeContainer = timeContainer
	do
		local timeLabel = AceGUI:Create("EPLabel")
		timeLabel:SetText(L["Time:"], 0)
		timeLabel:SetFrameHeightFromText()
		timeLabel:SetFullWidth(true)

		local doubleLineEditContainer = AceGUI:Create("EPContainer")
		doubleLineEditContainer:SetFullWidth(true)
		doubleLineEditContainer:SetLayout("EPHorizontalLayout")
		doubleLineEditContainer:SetSpacing(0, 0)

		local timeMinuteLineEdit = AceGUI:Create("EPLineEdit")
		timeMinuteLineEdit:SetRelativeWidth(0.475)
		timeMinuteLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Time, value)
		end)
		self.timeMinuteLineEdit = timeMinuteLineEdit

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":", 0)
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)
		separatorLabel:SetFullHeight(true)

		local timeSecondLineEdit = AceGUI:Create("EPLineEdit")
		timeSecondLineEdit:SetRelativeWidth(0.475)
		timeSecondLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Time, value)
		end)
		self.timeSecondLineEdit = timeSecondLineEdit

		doubleLineEditContainer:AddChildren(timeMinuteLineEdit, separatorLabel, timeSecondLineEdit)
		timeContainer:AddChildren(timeLabel, doubleLineEditContainer)
	end

	local assigneeTypeContainer = AceGUI:Create("EPContainer")
	assigneeTypeContainer:SetLayout("EPVerticalLayout")
	assigneeTypeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	assigneeTypeContainer:SetFullWidth(true)
	do
		local assigneeTypeLabel = AceGUI:Create("EPLabel")
		assigneeTypeLabel:SetText(L["Assignee"] .. ":", 0)
		assigneeTypeLabel:SetFrameHeightFromText()
		assigneeTypeLabel:SetFullWidth(true)

		local assigneeTypeDropdown = AceGUI:Create("EPDropdown")
		assigneeTypeDropdown:SetFullWidth(true)
		assigneeTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.AssigneeType, value)
		end)
		assigneeTypeDropdown:SetShowPathText(true, { 1, 2 })
		self.assigneeTypeDropdown = assigneeTypeDropdown

		assigneeTypeContainer:AddChildren(assigneeTypeLabel, assigneeTypeDropdown)
	end

	local spellAssignmentContainer = AceGUI:Create("EPContainer")
	spellAssignmentContainer:SetLayout("EPVerticalLayout")
	spellAssignmentContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	spellAssignmentContainer:SetFullWidth(true)
	self.spellAssignmentContainer = spellAssignmentContainer
	do
		local enableSpellAssignmentCheckBox = AceGUI:Create("EPCheckBox")
		enableSpellAssignmentCheckBox:SetText(L["Spell"] .. ":")
		enableSpellAssignmentCheckBox:SetFullWidth(true)
		enableSpellAssignmentCheckBox:SetFrameHeightFromText()
		enableSpellAssignmentCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.spellAssignmentDropdown:SetEnabled(checked)
			self.cancelIfAlreadyCastedCheckBox:SetEnabled(
				checked and self.reminderOverridesLabel.labelAndCheckBox:IsChecked()
			)
			if not checked then
				self.spellAssignmentDropdown:SetValue(constants.kInvalidAssignmentSpellID)
				self.spellAssignmentDropdown:SetText("")
				self:Fire("DataChanged", AssignmentEditorDataType.SpellAssignment, constants.kInvalidAssignmentSpellID)
			end
		end)
		self.enableSpellAssignmentCheckBox = enableSpellAssignmentCheckBox

		local spellAssignmentDropdown = AceGUI:Create("EPDropdown")
		spellAssignmentDropdown:SetFullWidth(true)
		spellAssignmentDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleSpellAssignmentDropdownValueChanged(self, value)
		end)
		spellAssignmentDropdown:SetCallback("CustomTextureClicked", function(_, _, widget, value)
			HandleCustomTextureClicked(self, widget, value)
		end)
		spellAssignmentDropdown:AddItem(
			{ itemValue = "Favorite", text = L["Favorite"], notSelectable = true },
			"EPDropdownItemMenu",
			nil,
			true
		)
		spellAssignmentDropdown:SetItemEnabled("Favorite", false)
		spellAssignmentDropdown:AddItem(
			{ itemValue = "Recent", text = L["Recent"], notSelectable = true },
			"EPDropdownItemMenu",
			nil,
			true
		)
		spellAssignmentDropdown:SetItemEnabled("Recent", false)
		self.spellAssignmentDropdown = spellAssignmentDropdown

		spellAssignmentContainer:AddChildren(enableSpellAssignmentCheckBox, spellAssignmentDropdown)
	end

	local targetContainer = AceGUI:Create("EPContainer")
	targetContainer:SetLayout("EPVerticalLayout")
	targetContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	targetContainer:SetFullWidth(true)
	self.targetContainer = targetContainer
	do
		local enableTargetCheckBox = AceGUI:Create("EPCheckBox")
		enableTargetCheckBox:SetText(L["Target"] .. ":")
		enableTargetCheckBox:SetFullWidth(true)
		enableTargetCheckBox:SetFrameHeightFromText()
		enableTargetCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.targetDropdown:SetEnabled(checked)
			if not checked then
				self.targetDropdown:SetValue("")
				self.targetDropdown:SetText("")
				self:Fire("DataChanged", AssignmentEditorDataType.Target, "")
			end
		end)
		self.enableTargetCheckBox = enableTargetCheckBox

		local targetDropdown = AceGUI:Create("EPDropdown")
		targetDropdown:SetFullWidth(true)
		targetDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Target, value)
		end)
		self.targetDropdown = targetDropdown

		targetContainer:AddChildren(enableTargetCheckBox, targetDropdown)
	end

	local optionalTextContainer = AceGUI:Create("EPContainer")
	optionalTextContainer:SetLayout("EPVerticalLayout")
	optionalTextContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	optionalTextContainer:SetFullWidth(true)
	do
		local optionalTextLabel = AceGUI:Create("EPLabel")
		optionalTextLabel:SetText(L["Text"] .. ":", 0)
		optionalTextLabel:SetFrameHeightFromText()
		optionalTextLabel:SetFullWidth(true)

		local optionalTextLineEdit = AceGUI:Create("EPLineEdit")
		optionalTextLineEdit:SetFullWidth(true)
		optionalTextLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.OptionalText, value)
		end)
		self.optionalTextLineEdit = optionalTextLineEdit

		optionalTextContainer:AddChildren(optionalTextLabel, optionalTextLineEdit)
	end
	self.optionalTextContainer = optionalTextContainer

	local previewContainer = AceGUI:Create("EPContainer")
	previewContainer:SetLayout("EPVerticalLayout")
	previewContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	previewContainer:SetFullWidth(true)
	self.previewContainer = previewContainer
	do
		local previewLabelLabel = AceGUI:Create("EPLabel")
		previewLabelLabel:SetText(L["Preview:"], 0)
		previewLabelLabel:SetFullWidth(true)
		previewLabelLabel:SetFrameHeightFromText()

		local previewLabel = AceGUI:Create("EPLabel")
		previewLabel:SetText("", 0)
		previewLabel:SetFullWidth(true)
		previewLabel:SetFrameHeightFromText()
		self.previewLabel = previewLabel

		previewContainer:AddChildren(previewLabelLabel, previewLabel)
	end

	local reminderOverridesContainer = AceGUI:Create("EPContainer")
	reminderOverridesContainer:SetLayout("EPVerticalLayout")
	reminderOverridesContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	reminderOverridesContainer:SetPadding(k.IndentWidth, 0, 0, 0)
	reminderOverridesContainer:SetFullWidth(true)
	self.reminderOverridesContainer = reminderOverridesContainer

	local reminderOverridesLabel = AceGUI:Create("EPExpanderHeader")
	reminderOverridesLabel:SetText(L["Reminder Overrides"], true)
	reminderOverridesLabel:SetFullWidth(true)
	reminderOverridesLabel:SetCallback("OnValueChanged", function(_, _, checked)
		self:Fire("DataChanged", AssignmentEditorDataType.CancelIfAlreadyCasted, checked)
	end)
	reminderOverridesLabel.labelAndCheckBox:SetCallback("OnEnter", function()
		ShowTooltip(
			reminderOverridesLabel.labelAndCheckBox.frame,
			L["Reminder Overrides"],
			L["If checked, default reminder preferences for this assignment are overridden."]
		)
	end)
	reminderOverridesLabel.labelAndCheckBox:SetCallback("OnLeave", function()
		sTooltip:Hide()
	end)
	reminderOverridesLabel:SetCallback("Clicked", function(_, _, open)
		reminderOverridesContainer:SetIgnoreFromLayout(not open)
		self:DoLayout()
	end)
	reminderOverridesLabel:SetCallback("OnValueChanged", function(_, _, checked)
		reminderOverridesLabel:SetExpanded(checked)
		reminderOverridesContainer:SetIgnoreFromLayout(not checked)
		SetEnabled(reminderOverridesContainer.children, checked)
		local countdownLength, holdDuration, cancelIfAlreadyCasted = nil, nil, nil
		if checked then -- Set all three values from reminder preferences
			local reminderPreferences = self.reminderPreferences
			countdownLength = reminderPreferences.countdownLength
			holdDuration = reminderPreferences.messages.holdDuration
			cancelIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
		end
		self:Fire("DataChanged", AssignmentEditorDataType.CountdownLength, countdownLength)
		self:Fire("DataChanged", AssignmentEditorDataType.HoldDuration, holdDuration)
		self:Fire("DataChanged", AssignmentEditorDataType.CancelIfAlreadyCasted, cancelIfAlreadyCasted)
		RepopulateReminderOverridesFromPreferences(self) -- Display values from reminder preferences even if nil
		self.cancelIfAlreadyCastedCheckBox:SetEnabled(checked and self.spellAssignmentDropdown.enabled)
		self:DoLayout()
	end)
	self.reminderOverridesLabel = reminderOverridesLabel

	local countdownLengthContainer = AceGUI:Create("EPContainer")
	countdownLengthContainer:SetLayout("EPVerticalLayout")
	countdownLengthContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	countdownLengthContainer:SetFullWidth(true)

	do
		self.cancelIfAlreadyCastedCheckBox = AceGUI:Create("EPCheckBox")
		self.cancelIfAlreadyCastedCheckBox:SetText(L["Hide on Spell Cast"])
		self.cancelIfAlreadyCastedCheckBox:SetFullWidth(true)
		self.cancelIfAlreadyCastedCheckBox:SetFrameHeightFromText()
		self.cancelIfAlreadyCastedCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self:Fire("DataChanged", AssignmentEditorDataType.CancelIfAlreadyCasted, checked)
		end)
		self.cancelIfAlreadyCastedCheckBox:SetCallback("OnEnter", function()
			ShowTooltip(
				self.cancelIfAlreadyCastedCheckBox.frame,
				L["Hide on Spell Cast"],
				L["If an assignment has a spell and is cast during the countdown, reminders for it will be hidden."]
			)
		end)
		self.cancelIfAlreadyCastedCheckBox:SetCallback("OnLeave", function()
			sTooltip:Hide()
		end)

		local countdownLengthLabel = AceGUI:Create("EPLabel")
		countdownLengthLabel:SetText(L["Countdown Length"] .. ":", 0)
		countdownLengthLabel:SetFullWidth(true)
		countdownLengthLabel:SetFrameHeightFromText()

		self.countdownLengthLineEdit = AceGUI:Create("EPLineEdit")
		self.countdownLengthLineEdit:SetFullWidth(true)
		self.countdownLengthLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.CountdownLength, value)
		end)
		self.countdownLengthLineEdit:SetCallback("OnEnter", function()
			ShowTooltip(
				self.countdownLengthLineEdit.frame,
				L["Countdown Length"],
				L["How far in advance to begin showing reminders for an assignment."]
			)
		end)
		self.countdownLengthLineEdit:SetCallback("OnLeave", function()
			sTooltip:Hide()
		end)

		countdownLengthContainer:AddChildren(countdownLengthLabel, self.countdownLengthLineEdit)
	end

	local holdDurationContainer = AceGUI:Create("EPContainer")
	holdDurationContainer:SetLayout("EPVerticalLayout")
	holdDurationContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
	holdDurationContainer:SetFullWidth(true)

	do
		local holdDurationLabel = AceGUI:Create("EPLabel")
		holdDurationLabel:SetText(L["Message Hold Duration"] .. ":", 0)
		holdDurationLabel:SetFullWidth(true)
		holdDurationLabel:SetFrameHeightFromText()

		self.holdDurationLineEdit = AceGUI:Create("EPLineEdit")
		self.holdDurationLineEdit:SetFullWidth(true)
		self.holdDurationLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.HoldDuration, value)
		end)
		self.holdDurationLineEdit:SetCallback("OnEnter", function()
			ShowTooltip(
				self.holdDurationLineEdit.frame,
				L["Message Hold Duration"],
				L["How long to keep showing Messages after the countdown has completed."]
			)
		end)
		self.holdDurationLineEdit:SetCallback("OnLeave", function()
			sTooltip:Hide()
		end)

		holdDurationContainer:AddChildren(holdDurationLabel, self.holdDurationLineEdit)
	end

	local function CreateSpacer()
		local spacer = AceGUI:Create("EPSpacer")
		spacer:SetFullWidth(true)
		spacer:SetHeight(k.SpacingBetweenOptions)
		return spacer
	end

	local function CreateSpacer2()
		local spacer = AceGUI:Create("EPSpacer")
		spacer:SetFullWidth(true)
		spacer:SetHeight(4)
		return spacer
	end

	local function CreateLine()
		local line = AceGUI:Create("EPSpacer")
		line.frame:SetBackdrop(k.LineBackdrop)
		line.frame:SetBackdropColor(unpack(k.BackdropBorderColor))
		line:SetFullWidth(true)
		line:SetHeight(2 + 2 * k.SpacingBetweenOptions)
		return line
	end

	reminderOverridesContainer:AddChildren(
		CreateSpacer2(),
		self.cancelIfAlreadyCastedCheckBox,
		CreateSpacer2(),
		countdownLengthContainer,
		CreateSpacer2(),
		holdDurationContainer
	)
	reminderOverridesContainer:SetIgnoreFromLayout(true)

	self:AddChildren(
		triggerContainer,
		CreateSpacer(),
		timeContainer,
		CreateSpacer(),
		assigneeTypeContainer,
		CreateSpacer(),
		spellAssignmentContainer,
		CreateSpacer(),
		targetContainer,
		CreateSpacer(),
		optionalTextContainer,
		CreateLine(),
		previewContainer,
		CreateLine(),
		reminderOverridesLabel,
		reminderOverridesContainer
	)

	local edgeSize = k.FrameBackdrop.edgeSize

	local deleteButton = AceGUI:Create("EPButton")
	deleteButton:SetText(L["Delete Assignment"])
	deleteButton:SetWidthFromText()
	deleteButton:SetBackdropColor(unpack(k.BackdropColor))
	deleteButton:SetCallback("Clicked", function()
		self:Fire("DeleteButtonClicked")
	end)
	deleteButton.frame:SetParent(self.buttonFrame)
	deleteButton.frame:SetPoint("TOP", self.buttonFrame, "TOP", 0, -edgeSize)
	deleteButton.frame:SetPoint("BOTTOM", self.buttonFrame, "BOTTOM", 0, edgeSize)
	self.deleteButton = deleteButton
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	if self.windowBar then
		self.windowBar:Release()
	end
	if self.deleteButton then
		self.deleteButton:Release()
	end
	self.assigneeTypeDropdown = nil
	self.assignment = nil
	self.assignmentTypeDropdown = nil
	self.cancelIfAlreadyCastedCheckBox = nil
	self.combatLogEventContainer = nil
	self.combatLogEventSpellCountLineEdit = nil
	self.combatLogEventSpellIDDropdown = nil
	self.countdownLengthLineEdit = nil
	self.deleteButton = nil
	self.enableSpellAssignmentCheckBox = nil
	self.enableTargetCheckBox = nil
	self.FormatTime = nil
	self.holdDurationLineEdit = nil
	self.lastClassDropdownValue = nil
	self.lastRoleDropdownValue = nil
	self.optionalTextContainer = nil
	self.optionalTextLineEdit = nil
	self.previewContainer = nil
	self.previewLabel = nil
	self.reminderOverridesContainer = nil
	self.reminderOverridesLabel = nil
	self.reminderPreferences = nil
	self.spellAssignmentContainer = nil
	self.spellAssignmentDropdown = nil
	self.targetContainer = nil
	self.targetDropdown = nil
	self.timeContainer = nil
	self.timeMinuteLineEdit = nil
	self.timeSecondLineEdit = nil
	self.triggerContainer = nil
	self.windowBar = nil
end

---@param self EPAssignmentEditor
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(
			k.FrameWidth + k.ContentFramePadding.x * 2,
			k.ButtonFrameHeight + height + self.windowBar.frame:GetHeight() + k.ContentFramePadding.y * 2
		)
	end
end

---@param self EPAssignmentEditor
---@param reminderPreferences ReminderPreferences
local function SetReminderPreferences(self, reminderPreferences)
	self.reminderPreferences = reminderPreferences
end

---@param self EPAssignmentEditor
---@param assignment Assignment
---@param roster table<string, RosterEntry>
---@param previewText string
---@param metaTables {CombatLogEventAssignment: CombatLogEventAssignment, TimedAssignment:TimedAssignment}
---@param availableCombatLogEventTypes table<integer, CombatLogEventType>
---@param spellSpecificCombatLogEventTypes table<integer, CombatLogEventType>|nil
---@param favoritedSpellDropdownItems table<integer, DropdownItemData>
local function PopulateFields(
	self,
	assignment,
	roster,
	previewText,
	metaTables,
	availableCombatLogEventTypes,
	spellSpecificCombatLogEventTypes,
	favoritedSpellDropdownItems
)
	self:SetAssignment(assignment)
	local assignee = assignment.assignee
	self.assigneeTypeDropdown:SetValue(assignee)

	self.previewLabel:SetText(previewText, 0)

	local enableTargetCheckBox = assignment.targetName ~= nil and assignment.targetName ~= ""
	self.enableTargetCheckBox:SetChecked(enableTargetCheckBox)
	self.targetDropdown:SetEnabled(enableTargetCheckBox)
	self.targetDropdown:SetValue(assignment.targetName)

	self.optionalTextLineEdit:SetText(assignment.text)
	local spellID = assignment.spellID
	local enableSpellAssignmentCheckBox = spellID ~= nil and spellID > constants.kTextAssignmentSpellID
	self.enableSpellAssignmentCheckBox:SetChecked(enableSpellAssignmentCheckBox)
	self.spellAssignmentDropdown:SetEnabled(enableSpellAssignmentCheckBox)
	RepopulateSpellDropdown(self, assignee, roster, spellID, favoritedSpellDropdownItems)

	local enableCombatLogEvents = #availableCombatLogEventTypes > 0
	local combatLogEventItem, _ = self.assignmentTypeDropdown:FindItemAndText("Combat Log Event")
	if combatLogEventItem then
		combatLogEventItem:SetEnabled(enableCombatLogEvents)
	end

	local types = { ["SCS"] = 0, ["SCC"] = 0, ["SAA"] = 0, ["SAR"] = 0, ["UD"] = 0 }
	for _, combatLogEventType in ipairs(availableCombatLogEventTypes) do
		types[combatLogEventType] = 1
	end

	if spellSpecificCombatLogEventTypes then
		for _, combatLogEventType in ipairs(spellSpecificCombatLogEventTypes) do
			types[combatLogEventType] = types[combatLogEventType] + 1
		end
	end

	local isTimedAssignment = getmetatable(assignment) == metaTables.TimedAssignment

	-- Regular enabled event types
	for combatLogEventType, count in pairs(types) do
		local item, _ = self.assignmentTypeDropdown:FindItemAndText(combatLogEventType)
		if item then
			if count == 0 then -- Fully disabled
				item:SetEnabled(false)
				item:SetTextColor(k.DisabledTextColor)
			elseif count == 1 then -- Indicate that the current spell isn't compatible
				item:SetEnabled(true)
				if not isTimedAssignment then
					item:SetTextColor(k.HalfDisabledTextColor)
				end
			elseif count == 2 then -- Compatible with current spell
				item:SetEnabled(true)
			end
		end
	end

	if getmetatable(assignment) == metaTables.CombatLogEventAssignment then
		---@cast assignment CombatLogEventAssignment
		self:SetAssignmentType("CombatLogEventAssignment")
		self.assignmentTypeDropdown:SetValue(assignment.combatLogEventType)
		self.combatLogEventSpellIDDropdown:SetValue(assignment.combatLogEventSpellID)
		self.combatLogEventSpellCountLineEdit:SetText(assignment.spellCount)
		local minutes, seconds = self.FormatTime(assignment.time)
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	elseif isTimedAssignment then
		---@cast assignment TimedAssignment
		self:SetAssignmentType("TimedAssignment")
		self.assignmentTypeDropdown:SetValue(nil)
		self.combatLogEventSpellIDDropdown:SetValue(nil)
		self.combatLogEventSpellCountLineEdit:SetText()
		self.assignmentTypeDropdown:SetValue("Fixed Time")
		local minutes, seconds = self.FormatTime(assignment.time)
		self.timeMinuteLineEdit:SetText(minutes)
		self.timeSecondLineEdit:SetText(seconds)
	end

	if assignment.countdownLength and assignment.cancelIfAlreadyCasted ~= nil and assignment.holdDuration then
		self.countdownLengthLineEdit:SetText(select(2, self.FormatTime(assignment.countdownLength)))
		self.cancelIfAlreadyCastedCheckBox:SetChecked(assignment.cancelIfAlreadyCasted)
		self.holdDurationLineEdit:SetText(select(2, self.FormatTime(assignment.holdDuration)))

		self.reminderOverridesLabel:SetChecked(true)
		SetEnabled(self.reminderOverridesContainer.children, true)
		self.cancelIfAlreadyCastedCheckBox:SetEnabled(enableSpellAssignmentCheckBox)
	else
		RepopulateReminderOverridesFromPreferences(self)

		self.reminderOverridesLabel:SetChecked(false)
		SetEnabled(self.reminderOverridesContainer.children, false)
	end
end

---@param self EPAssignmentEditor
local function HandleRosterChanged(self)
	local targetValue = self.targetDropdown:GetValue()
	local item, _ = self.targetDropdown:FindItemAndText(targetValue, false)
	if not item then
		self.targetDropdown:SetEnabled(false)
		self.targetDropdown:SetValue("")
		self.targetDropdown:SetText("")
		self:Fire("DataChanged", AssignmentEditorDataType.Target, "")
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.FrameWidth, k.FrameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local buttonFrame = CreateFrame("Frame", Type .. "ButtonFrame" .. count, frame, "BackdropTemplate")
	buttonFrame:SetBackdrop(k.ButtonFrameBackdrop)
	buttonFrame:SetBackdropColor(unpack(k.ButtonFrameBackdropColor))
	buttonFrame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	buttonFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	buttonFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	buttonFrame:SetHeight(k.ButtonFrameHeight)
	buttonFrame:EnableMouse(true)

	local contentFrameName = Type .. "ContentFrame" .. count
	local contentFrame = CreateFrame("Frame", contentFrameName, frame)
	contentFrame:SetPoint(
		"TOPLEFT",
		frame,
		"TOPLEFT",
		k.ContentFramePadding.x,
		-k.ContentFramePadding.y - k.WindowBarHeight
	)
	contentFrame:SetPoint(
		"BOTTOMRIGHT",
		frame,
		"BOTTOMRIGHT",
		-k.ContentFramePadding.x,
		k.ContentFramePadding.y + k.ButtonFrameHeight
	)

	---@class EPAssignmentEditor : AceGUIContainer
	---@field assigneeTypeDropdown EPDropdown
	---@field assignment Assignment|CombatLogEventAssignment|TimedAssignment|nil
	---@field assignmentTypeDropdown EPDropdown
	---@field cancelIfAlreadyCastedCheckBox EPCheckBox
	---@field combatLogEventContainer EPContainer
	---@field combatLogEventSpellCountLineEdit EPLineEdit
	---@field combatLogEventSpellIDDropdown EPDropdown
	---@field countdownLengthLineEdit EPLineEdit
	---@field deleteButton EPButton
	---@field enableSpellAssignmentCheckBox EPCheckBox
	---@field enableTargetCheckBox EPCheckBox
	---@field FormatTime fun(number): string,string
	---@field holdDurationLineEdit EPLineEdit
	---@field lastClassDropdownValue string|nil
	---@field lastRoleDropdownValue string|nil
	---@field optionalTextContainer EPContainer
	---@field optionalTextLineEdit EPLineEdit
	---@field previewContainer EPContainer
	---@field previewLabel EPLabel
	---@field reminderOverridesContainer EPContainer
	---@field reminderOverridesLabel EPExpanderHeader
	---@field reminderPreferences ReminderPreferences
	---@field spellAssignmentContainer EPContainer
	---@field spellAssignmentDropdown EPDropdown
	---@field targetContainer EPContainer
	---@field targetDropdown EPDropdown
	---@field timeContainer EPContainer
	---@field timeMinuteLineEdit EPLineEdit
	---@field timeSecondLineEdit EPLineEdit
	---@field triggerContainer EPContainer
	---@field windowBar EPWindowBar
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		content = contentFrame,
		buttonFrame = buttonFrame,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetAssignmentType = SetAssignmentType,
		SetAssignment = SetAssignment,
		GetAssignment = GetAssignment,
		PopulateFields = PopulateFields,
		HandleRosterChanged = HandleRosterChanged,
		RepopulateSpellDropdown = RepopulateSpellDropdown,
		SetReminderPreferences = SetReminderPreferences,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
