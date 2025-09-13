local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants

local Type = "EPAssignmentEditor"
local Version = 1

local AssignmentEditorDataType = Private.classes.AssignmentEditorDataType

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
	FrameWidth = 200,
	HalfDisabledTextColor = { 0.66, 0.66, 0.66, 1 },
	IndentWidth = 20,
	LabelWidgetSpacing = { 2, 2 },
	MaxNumberOfRecentItems = 10,
	SpacingBetweenOptions = 8,
	Title = L["Assignment Editor"],
	WindowBarHeight = 28,
}
k.LineBackdrop = {
	bgFile = constants.textures.kGenericWhite,
	tile = false,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = k.SpacingBetweenOptions, bottom = k.SpacingBetweenOptions },
}

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
			self.spellAssignmentDropdown:AddItems(dropdownItemData, "EPDropdownItemMenu", nil, 3)
		else
			self.spellAssignmentDropdown:RemoveItem("Core")
			self.spellAssignmentDropdown:RemoveItem("Group Utility")
			self.spellAssignmentDropdown:RemoveItem("Personal Defensive")
			self.spellAssignmentDropdown:RemoveItem("External Defensive")
			self.spellAssignmentDropdown:RemoveItem("Other")

			local dropdownItemData = Private.utilities.GetOrCreateClassSpellDropdownItems(true, favoritedItemsMap)
			self.spellAssignmentDropdown:AddItems({ dropdownItemData }, "EPDropdownItemToggle", nil, 3)
		end
	end

	self.lastClassDropdownValue, self.lastRoleDropdownValue = class, role
	self.spellAssignmentDropdown:SetValue(self.spellAssignmentDropdown.enabled and spellID or nil)
end

---@param self EPAssignmentEditor
local function HandleAssigneeTypeDropdownValueChanged(self, value)
	self:Fire("DataChanged", AssignmentEditorDataType.AssigneeType, value)
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
---@param assignmentID integer
local function SetAssignmentID(self, assignmentID)
	self.assignmentID = assignmentID
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

	do
		self.assignmentTypeContainer = AceGUI:Create("EPContainer")
		self.assignmentTypeContainer:SetLayout("EPVerticalLayout")
		self.assignmentTypeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.assignmentTypeContainer:SetFullWidth(true)

		self.assignmentTypeLabel = AceGUI:Create("EPLabel")
		self.assignmentTypeLabel:SetText(L["Trigger:"], 0)
		self.assignmentTypeLabel:SetFrameHeightFromText()
		self.assignmentTypeLabel:SetFullWidth(true)

		self.assignmentTypeDropdown = AceGUI:Create("EPDropdown")
		self.assignmentTypeDropdown:SetFullWidth(true)
		self.assignmentTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleAssignmentTypeDropdownValueChanged(self, value)
		end)
		self.assignmentTypeDropdown:AddItems(k.AssignmentTriggers, "EPDropdownItemToggle")

		self.assignmentTypeContainer:AddChildren(self.assignmentTypeLabel, self.assignmentTypeDropdown)
	end

	do
		local maxLabelWidth = 0.0
		self.combatLogEventContainer = AceGUI:Create("EPContainer")
		self.combatLogEventContainer:SetLayout("EPVerticalLayout")
		self.combatLogEventContainer:SetSpacing(unpack(k.ContainerContainerSpacing))
		self.combatLogEventContainer:SetFullWidth(true)
		self.combatLogEventContainer:SetPadding(k.IndentWidth, 0, 0, 0)

		local leftContainer = AceGUI:Create("EPContainer")
		leftContainer:SetLayout("EPHorizontalLayout")
		leftContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		leftContainer:SetFullWidth(true)

		self.combatLogEventSpellIDLabel = AceGUI:Create("EPLabel")
		self.combatLogEventSpellIDLabel:SetText(L["Spell"] .. ":", 0)
		self.combatLogEventSpellIDLabel:SetFullHeight(true)
		self.combatLogEventSpellIDLabel:SetFrameWidthFromText()
		maxLabelWidth = max(maxLabelWidth, self.combatLogEventSpellIDLabel.frame:GetWidth())

		self.combatLogEventSpellIDDropdown = AceGUI:Create("EPDropdown")
		self.combatLogEventSpellIDDropdown:SetFullWidth(true)
		self.combatLogEventSpellIDDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.CombatLogEventSpellID, value)
		end)

		local rightContainer = AceGUI:Create("EPContainer")
		rightContainer:SetLayout("EPHorizontalLayout")
		rightContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		rightContainer:SetFullWidth(true)

		self.combatLogEventSpellCountLabel = AceGUI:Create("EPLabel")
		self.combatLogEventSpellCountLabel:SetText(L["Count:"], 0)
		self.combatLogEventSpellCountLabel:SetFullHeight(true)
		self.combatLogEventSpellCountLabel:SetFrameWidthFromText()
		maxLabelWidth = max(maxLabelWidth, self.combatLogEventSpellCountLabel.frame:GetWidth())

		self.combatLogEventSpellCountLineEdit = AceGUI:Create("EPLineEdit")
		self.combatLogEventSpellCountLineEdit:SetFullWidth(true)
		self.combatLogEventSpellCountLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.CombatLogEventSpellCount, value)
		end)

		self.combatLogEventSpellIDLabel:SetWidth(maxLabelWidth)
		self.combatLogEventSpellCountLabel:SetWidth(maxLabelWidth)

		leftContainer:AddChildren(self.combatLogEventSpellIDLabel, self.combatLogEventSpellIDDropdown)
		rightContainer:AddChildren(self.combatLogEventSpellCountLabel, self.combatLogEventSpellCountLineEdit)
		self.combatLogEventContainer:AddChildren(leftContainer, rightContainer)
	end

	local triggerContainer = AceGUI:Create("EPContainer")
	triggerContainer:SetLayout("EPVerticalLayout")
	triggerContainer:SetSpacing(unpack(k.ContainerContainerSpacing))
	triggerContainer:SetFullWidth(true)
	triggerContainer:AddChildren(self.assignmentTypeContainer, self.combatLogEventContainer)
	self.triggerContainer = triggerContainer

	do
		self.timeContainer = AceGUI:Create("EPContainer")
		self.timeContainer:SetLayout("EPVerticalLayout")
		self.timeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.timeContainer:SetFullWidth(true)

		self.timeLabel = AceGUI:Create("EPLabel")
		self.timeLabel:SetText(L["Time:"], 0)
		self.timeLabel:SetFrameHeightFromText()
		self.timeLabel:SetFullWidth(true)

		local doubleLineEditContainer = AceGUI:Create("EPContainer")
		doubleLineEditContainer:SetFullWidth(true)
		doubleLineEditContainer:SetLayout("EPHorizontalLayout")
		doubleLineEditContainer:SetSpacing(0, 0)

		self.timeMinuteLineEdit = AceGUI:Create("EPLineEdit")
		self.timeMinuteLineEdit:SetRelativeWidth(0.475)
		self.timeMinuteLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Time, value)
		end)

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":", 0)
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)
		separatorLabel:SetFullHeight(true)

		self.timeSecondLineEdit = AceGUI:Create("EPLineEdit")
		self.timeSecondLineEdit:SetRelativeWidth(0.475)
		self.timeSecondLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Time, value)
		end)

		doubleLineEditContainer:AddChildren(self.timeMinuteLineEdit, separatorLabel, self.timeSecondLineEdit)
		self.timeContainer:AddChildren(self.timeLabel, doubleLineEditContainer)
	end

	do
		self.assigneeTypeContainer = AceGUI:Create("EPContainer")
		self.assigneeTypeContainer:SetLayout("EPVerticalLayout")
		self.assigneeTypeContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.assigneeTypeContainer:SetFullWidth(true)

		self.assigneeTypeLabel = AceGUI:Create("EPLabel")
		self.assigneeTypeLabel:SetText(L["Assignee"] .. ":", 0)
		self.assigneeTypeLabel:SetFrameHeightFromText()
		self.assigneeTypeLabel:SetFullWidth(true)

		self.assigneeTypeDropdown = AceGUI:Create("EPDropdown")
		self.assigneeTypeDropdown:SetFullWidth(true)
		self.assigneeTypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleAssigneeTypeDropdownValueChanged(self, value)
		end)
		self.assigneeTypeDropdown:SetShowPathText(true, { 1, 2 })
		self.assigneeTypeContainer:AddChildren(self.assigneeTypeLabel, self.assigneeTypeDropdown)
	end

	do
		self.spellAssignmentContainer = AceGUI:Create("EPContainer")
		self.spellAssignmentContainer:SetLayout("EPVerticalLayout")
		self.spellAssignmentContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.spellAssignmentContainer:SetFullWidth(true)

		self.enableSpellAssignmentCheckBox = AceGUI:Create("EPCheckBox")
		self.enableSpellAssignmentCheckBox:SetText(L["Spell"] .. ":")
		self.enableSpellAssignmentCheckBox:SetFullWidth(true)
		self.enableSpellAssignmentCheckBox:SetFrameHeightFromText()
		self.enableSpellAssignmentCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.spellAssignmentDropdown:SetEnabled(checked)
			if not checked then
				self.spellAssignmentDropdown:SetValue(constants.kInvalidAssignmentSpellID)
				self.spellAssignmentDropdown:SetText("")
				self:Fire("DataChanged", AssignmentEditorDataType.SpellAssignment, constants.kInvalidAssignmentSpellID)
			end
		end)

		self.spellAssignmentDropdown = AceGUI:Create("EPDropdown")
		self.spellAssignmentDropdown:SetFullWidth(true)
		self.spellAssignmentDropdown:SetCallback("OnValueChanged", function(_, _, value)
			HandleSpellAssignmentDropdownValueChanged(self, value)
		end)
		self.spellAssignmentDropdown:SetCallback("CustomTextureClicked", function(_, _, widget, value)
			HandleCustomTextureClicked(self, widget, value)
		end)
		self.spellAssignmentDropdown:AddItem(
			{ itemValue = "Favorite", text = L["Favorite"], selectable = false },
			"EPDropdownItemMenu"
		)
		self.spellAssignmentDropdown:SetItemEnabled("Favorite", false)
		self.spellAssignmentDropdown:AddItem(
			{ itemValue = "Recent", text = L["Recent"], selectable = false },
			"EPDropdownItemMenu"
		)
		self.spellAssignmentDropdown:SetItemEnabled("Recent", false)

		self.spellAssignmentContainer:AddChildren(self.enableSpellAssignmentCheckBox, self.spellAssignmentDropdown)
	end

	do
		self.targetContainer = AceGUI:Create("EPContainer")
		self.targetContainer:SetLayout("EPVerticalLayout")
		self.targetContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.targetContainer:SetFullWidth(true)

		self.enableTargetCheckBox = AceGUI:Create("EPCheckBox")
		self.enableTargetCheckBox:SetText(L["Target?"])
		self.enableTargetCheckBox:SetFullWidth(true)
		self.enableTargetCheckBox:SetFrameHeightFromText()
		self.enableTargetCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self.targetDropdown:SetEnabled(checked)
			if not checked then
				self.targetDropdown:SetValue("")
				self.targetDropdown:SetText("")
				self:Fire("DataChanged", AssignmentEditorDataType.Target, "")
			end
		end)

		self.targetDropdown = AceGUI:Create("EPDropdown")
		self.targetDropdown:SetFullWidth(true)
		self.targetDropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.Target, value)
		end)

		self.targetContainer:AddChildren(self.enableTargetCheckBox, self.targetDropdown)
	end

	do
		self.optionalTextContainer = AceGUI:Create("EPContainer")
		self.optionalTextContainer:SetLayout("EPVerticalLayout")
		self.optionalTextContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.optionalTextContainer:SetFullWidth(true)

		self.optionalTextLabel = AceGUI:Create("EPLabel")
		self.optionalTextLabel:SetText(L["Text"] .. ":", 0)
		self.optionalTextLabel:SetFrameHeightFromText()
		self.optionalTextLabel:SetFullWidth(true)

		self.optionalTextLineEdit = AceGUI:Create("EPLineEdit")
		self.optionalTextLineEdit:SetFullWidth(true)
		self.optionalTextLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
			self:Fire("DataChanged", AssignmentEditorDataType.OptionalText, value)
		end)

		self.optionalTextContainer:AddChildren(self.optionalTextLabel, self.optionalTextLineEdit)
	end

	do
		self.previewContainer = AceGUI:Create("EPContainer")
		self.previewContainer:SetLayout("EPVerticalLayout")
		self.previewContainer:SetSpacing(unpack(k.LabelWidgetSpacing))
		self.previewContainer:SetFullWidth(true)

		local previewLabelLabel = AceGUI:Create("EPLabel")
		previewLabelLabel:SetText(L["Preview:"], 0)
		previewLabelLabel:SetFullWidth(true)
		previewLabelLabel:SetFrameHeightFromText()

		self.previewLabel = AceGUI:Create("EPLabel")
		self.previewLabel:SetText("", 0)
		self.previewLabel:SetFullWidth(true)
		self.previewLabel:SetFrameHeightFromText()

		self.previewContainer:AddChildren(previewLabelLabel, self.previewLabel)
	end

	local line = AceGUI:Create("EPSpacer")
	line.frame:SetBackdrop(k.LineBackdrop)
	line.frame:SetBackdropColor(unpack(k.BackdropBorderColor))
	line:SetFullWidth(true)
	line:SetHeight(2 + 2 * k.SpacingBetweenOptions)

	local triggerTimeSpacer = AceGUI:Create("EPSpacer")
	triggerTimeSpacer:SetFullWidth(true)
	triggerTimeSpacer:SetHeight(k.SpacingBetweenOptions)

	local timeTypeSpacer = AceGUI:Create("EPSpacer")
	timeTypeSpacer:SetFullWidth(true)
	timeTypeSpacer:SetHeight(k.SpacingBetweenOptions)

	local spellTargetSpacer = AceGUI:Create("EPSpacer")
	spellTargetSpacer:SetFullWidth(true)
	spellTargetSpacer:SetHeight(k.SpacingBetweenOptions)

	local spellTextSpacer = AceGUI:Create("EPSpacer")
	spellTextSpacer:SetFullWidth(true)
	spellTextSpacer:SetHeight(k.SpacingBetweenOptions)

	local line2 = AceGUI:Create("EPSpacer")
	line2.frame:SetBackdrop(k.LineBackdrop)
	line2.frame:SetBackdropColor(unpack(k.BackdropBorderColor))
	line2:SetFullWidth(true)
	line2:SetHeight(2 + 2 * k.SpacingBetweenOptions)

	self:AddChildren(
		triggerContainer,
		triggerTimeSpacer,
		self.timeContainer,
		timeTypeSpacer,
		self.assigneeTypeContainer,
		line,
		self.spellAssignmentContainer,
		spellTargetSpacer,
		self.targetContainer,
		spellTextSpacer,
		self.optionalTextContainer,
		line2,
		self.previewContainer
	)

	local edgeSize = k.FrameBackdrop.edgeSize

	self.deleteButton = AceGUI:Create("EPButton")
	self.deleteButton:SetText(L["Delete Assignment"])
	self.deleteButton:SetWidthFromText()
	self.deleteButton:SetBackdropColor(unpack(k.BackdropColor))
	self.deleteButton:SetCallback("Clicked", function()
		self:Fire("DeleteButtonClicked")
	end)
	self.deleteButton.frame:SetParent(self.buttonFrame)
	self.deleteButton.frame:SetPoint("TOP", self.buttonFrame, "TOP", 0, -edgeSize)
	self.deleteButton.frame:SetPoint("BOTTOM", self.buttonFrame, "BOTTOM", 0, edgeSize)
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	if self.windowBar then
		self.windowBar:Release()
	end
	if self.deleteButton then
		self.deleteButton:Release()
	end
	self.FormatTime = nil
	self.deleteButton = nil
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
	self.triggerContainer = nil
	self.enableTargetCheckBox = nil
	self.timeLabel = nil
	self.optionalTextContainer = nil
	self.optionalTextLineEdit = nil
	self.optionalTextLabel = nil
	self.targetContainer = nil
	self.targetDropdown = nil
	self.previewContainer = nil
	self.previewLabel = nil
	self.lastClassDropdownValue = nil
	self.lastRoleDropdownValue = nil
	self.windowBar = nil
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
			width + k.ContentFramePadding.x * 2,
			k.ButtonFrameHeight + height + self.windowBar.frame:GetHeight() + k.ContentFramePadding.y * 2
		)
	end
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
	self:SetAssignmentID(assignment.uniqueID)
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
	---@field buttonFrame Frame|table
	---@field deleteButton EPButton
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
	---@field triggerContainer EPContainer
	---@field enableTargetCheckBox EPCheckBox
	---@field timeLabel EPLabel
	---@field optionalTextContainer EPContainer
	---@field optionalTextLineEdit EPLineEdit
	---@field optionalTextLabel EPLabel
	---@field targetContainer EPContainer
	---@field targetDropdown EPDropdown
	---@field previewContainer EPContainer
	---@field previewLabel EPLabel
	---@field windowBar EPWindowBar
	---@field assignmentID integer|nil
	---@field FormatTime fun(number): string,string
	---@field lastClassDropdownValue string|nil
	---@field lastRoleDropdownValue string|nil
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		content = contentFrame,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		OnHeightSet = OnHeightSet,
		OnWidthSet = OnWidthSet,
		LayoutFinished = LayoutFinished,
		SetAssignmentType = SetAssignmentType,
		SetAssignmentID = SetAssignmentID,
		GetAssignmentID = GetAssignmentID,
		PopulateFields = PopulateFields,
		HandleRosterChanged = HandleRosterChanged,
		RepopulateSpellDropdown = RepopulateSpellDropdown,
		buttonFrame = buttonFrame,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
