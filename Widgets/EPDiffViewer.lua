local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPDiffViewer"
local Version = 1

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local format = string.format
local getmetatable = getmetatable
local GetSpellName = C_Spell.GetSpellName
local ipairs = ipairs
local max = math.max
local unpack = unpack

local PlanDiffType = Private.classes.PlanDiffType
local DifficultyType = Private.classes.DifficultyType

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	BackdropColor = { 0, 0, 0, 1 },
	ContentFramePadding = { x = 15, y = 15 },
	DefaultButtonHeight = 24,
	DefaultFontSize = 14,
	DefaultHeight = 400,
	DefaultWidth = 600,
	FrameBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 27, bottom = 0 },
	},
	LineColor = { 0.25, 0.25, 0.25, 1.0 },
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	OtherPadding = { x = 10, y = 10 },
	Title = L["Plan Change Request"],
}

local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment

---@param eventType CombatLogEventType
---@return string
local function GetCombatLogEventString(eventType)
	local returnString
	if eventType == "SCC" then
		returnString = L["Spell Cast Success"]
	elseif eventType == "SCS" then
		returnString = L["Spell Cast Start"]
	elseif eventType == "SAA" then
		returnString = L["Spell Aura Applied"]
	elseif eventType == "SAR" then
		returnString = L["Spell Aura Removed"]
	elseif eventType == "UD" then
		returnString = L["Unit Died"]
	end
	return returnString
end

---@param value Assignment|CombatLogEventAssignment|TimedAssignment
---@param roster table<string, RosterEntry>
---@param diffType? PlanDiffType
---@return string
local function CreateAssignmentDiffText(value, roster, diffType)
	local text = ""
	if diffType then
		if diffType == PlanDiffType.Delete then
			return L["Removed"]
		elseif diffType == PlanDiffType.Change then
			text = L["Changed"] .. "\n"
		end
	end
	local assignee = utilities.ConvertAssigneeToLegibleString(value.assignee, roster)
	text = text .. format("%s: %s", L["Assignee"], assignee)
	if value.spellID > Private.constants.kTextAssignmentSpellID then
		local spellName = GetSpellName(value.spellID)
		if spellName then
			text = text .. format("\n%s: %s", L["Spell"], spellName)
		else
			text = text .. format("\n%s: %s", L["Spell"], value.spellID)
		end
	end
	text = text .. format("\n%s: %s", L["Time"], value.time)
	text = text .. format("\n%s: %s", L["Text"], value.text)
	if value.targetName ~= "" then
		local targetName = utilities.ConvertAssigneeToLegibleString(value.targetName, roster)
		text = text .. format("\n%s: %s", L["Target"], targetName)
	end
	if getmetatable(value) == CombatLogEventAssignment then
		text = text .. format("\n%s: %s", L["Trigger"], GetCombatLogEventString(value.combatLogEventType))
		text = text .. format("\n%s %s: %s", L["Trigger"], L["Spell"], GetSpellName(value.combatLogEventSpellID))
		text = text .. format("\n%s %s: %s", L["Trigger"], L["Spell Count"], value.spellCount)
	end
	return text
end

---@param assignee string
---@param value AssigneeSpellSet|FlatAssigneeSpellSet
---@param roster table<string, RosterEntry>
---@param diffType? PlanDiffType
---@return string
local function CreateAssigneeSpellSetDiffText(assignee, value, roster, diffType)
	local text = ""
	if diffType then
		if diffType == PlanDiffType.Delete then
			return L["Removed"]
		elseif diffType == PlanDiffType.Change then
			text = L["Changed"] .. "\n"
		end
	end
	text = text .. format("%s: %s", L["Assignee"], utilities.ConvertAssigneeToLegibleString(value.assignee, roster))
	local spells = {}
	if value.spells then
		spells = value.spells
	else
		tinsert(spells, value.spellID)
	end
	for _, spellID in ipairs(spells) do
		local spellName = tostring(spellID)
		if spellID == Private.constants.kInvalidAssignmentSpellID then
			spellName = L["Unknown"]
		elseif spellID == Private.constants.kTextAssignmentSpellID then
			spellName = L["Text"]
		else
			local maybeSpellName = GetSpellName(spellID)
			if maybeSpellName then
				spellName = maybeSpellName
			end
		end
		text = text .. format("\n%s: %s", L["Spell"], spellName)
	end

	return text
end

---@param assignee string
---@param value RosterEntry
---@param roster table<string, RosterEntry>
---@param diffType? PlanDiffType
---@return string
local function CreateRosterDiffText(assignee, value, roster, diffType)
	local text = ""
	if diffType then
		if diffType == PlanDiffType.Delete then
			return L["Removed"]
		elseif diffType == PlanDiffType.Change then
			text = L["Changed"] .. "\n"
		end
	end

	local class, role = value.class, value.role
	text = text .. format("%s: %s", L["Assignee"], utilities.ConvertAssigneeToLegibleString(assignee, roster))
	local className = class:match("class:%s*(%a+)")
	if className then
		className = utilities.GetLocalizedPrettyClassName(className)
		text = text .. format("\n%s: %s", L["Class"], className)
	end
	local roleName = role:match("role:%s*(%a+)")
	if roleName then
		roleName = utilities.GetLocalizedRole(roleName)
		text = text .. format("\n%s: %s", L["Role"], roleName)
	end
	return text
end

---@param genericDiffEntry GenericDiffEntry
---@return any old
---@return any? new
local function GetOldAndNewValues(genericDiffEntry)
	local oldValue, newValue
	if genericDiffEntry.type == PlanDiffType.Insert then
		---@cast genericDiffEntry InsertDiffEntry<any>
		oldValue = genericDiffEntry.newValue
	elseif genericDiffEntry.type == PlanDiffType.Delete then
		---@cast genericDiffEntry DeleteDiffEntry<any>
		oldValue = genericDiffEntry.oldValue
	elseif genericDiffEntry.type == PlanDiffType.Change then
		---@cast genericDiffEntry ChangeDiffEntry<any>
		oldValue = genericDiffEntry.oldValue
		newValue = genericDiffEntry.newValue
	elseif genericDiffEntry.type == PlanDiffType.Conflict then
		---@cast genericDiffEntry ConflictDiffEntry<any>
		oldValue = genericDiffEntry.localValue
		newValue = genericDiffEntry.remoteValue
	end
	return oldValue, newValue
end

---@param container EPContainer
local function SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		maxWidth = max(maxWidth, child.frame:GetWidth())
	end
	for _, child in ipairs(container.children) do
		child:SetWidth(maxWidth)
	end
end

---@param container EPContainer
---@param func fun(entry: EPDiffViewerEntry)
local function IterateContainer(container, func)
	for _, containerChild in ipairs(container.children) do
		if containerChild.type == "EPDiffViewerEntry" then
			func(containerChild)
		elseif containerChild.type == "EPContainer" then
			IterateContainer(containerChild, func)
		end
	end
end

---@param self EPDiffViewer
---@param text string
---@param dividerLineIndex integer
---@return integer dividerLineIndex
---@return EPContainer container
local function AddSection(self, text, dividerLineIndex)
	local expanderHeader = AceGUI:Create("EPExpanderHeader")
	expanderHeader:SetText(text, false, 16)
	expanderHeader.frame:SetHeight(28)
	expanderHeader.frame:SetWidth(expanderHeader.label.frame:GetWidth() + expanderHeader.button:GetWidth())

	local horizontalContainer = AceGUI:Create("EPContainer")
	horizontalContainer:SetLayout("EPHorizontalLayout")
	horizontalContainer:SetSpacing(0, 0)
	horizontalContainer:AddChild(expanderHeader)

	local verticalContainerWrapper = AceGUI:Create("EPContainer")
	verticalContainerWrapper:SetLayout("EPVerticalLayout")
	verticalContainerWrapper:SetFullWidth(true)
	verticalContainerWrapper:SetSpacing(0, 0)
	verticalContainerWrapper:SetAlignment("center")
	verticalContainerWrapper:AddChild(horizontalContainer)
	self.mainContainer:AddChild(verticalContainerWrapper)

	if not self.dividerLines[dividerLineIndex] then
		local dividerLine = self.frame:CreateTexture(nil, "OVERLAY")
		dividerLine:SetColorTexture(unpack(k.LineColor))
		dividerLine:SetHeight(2)
		self.dividerLines[dividerLineIndex] = dividerLine
	end
	self.dividerLines[dividerLineIndex]:SetParent(self.mainContainer.frame)
	self.dividerLines[dividerLineIndex]:SetPoint("LEFT", self.mainContainer.frame, "LEFT")
	self.dividerLines[dividerLineIndex]:SetPoint("RIGHT", self.mainContainer.frame, "RIGHT")
	self.dividerLines[dividerLineIndex]:SetPoint("TOP", verticalContainerWrapper.frame, "BOTTOM")
	self.dividerLines[dividerLineIndex]:Show()

	local containerWrapper = AceGUI:Create("EPContainer")
	containerWrapper:SetLayout("EPVerticalLayout")
	containerWrapper:SetSpacing(0, 0)
	containerWrapper:SetFullWidth(true)

	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPVerticalLayout")
	container:SetSpacing(0, 0)
	container:SetFullWidth(true)
	container:SetIgnoreFromLayout(true)
	local emptyWidget = AceGUI:Create("EPSpacer")
	emptyWidget.frame:SetHeight(1)
	containerWrapper:AddChildren(container, emptyWidget)
	self.mainContainer:AddChild(containerWrapper)

	expanderHeader:SetCallback("Clicked", function(_, _, open)
		container:SetIgnoreFromLayout(not open)
		self.mainContainer:DoLayout()
	end)

	return dividerLineIndex + 1, container
end

---@param self EPDiffViewer
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle(k.Title)
	windowBar:RemoveButtons()
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
	end)
	self.windowBar = windowBar

	self.text:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
	self.text:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.text:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)

	self.mainContainer = AceGUI:Create("EPContainer")
	self.mainContainer:SetLayout("EPVerticalLayout")
	self.mainContainer:SetSpacing(0, 0)
	self.mainContainer:SetFullWidth(true)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(k.OtherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.ContentFramePadding.y)

	local acceptButton = AceGUI:Create("EPButton")
	acceptButton:SetText(L["Accept"])
	acceptButton:SetWidthFromText()
	acceptButton:SetHeight(k.DefaultButtonHeight)
	acceptButton:SetColor(unpack(k.NeutralButtonColor))
	acceptButton:SetCallback("Clicked", function()
		self:Fire("Accepted")
	end)

	local rejectButton = AceGUI:Create("EPButton")
	rejectButton:SetText(L["Reject"])
	rejectButton:SetWidthFromText()
	rejectButton:SetHeight(k.DefaultButtonHeight)
	rejectButton:SetColor(unpack(k.NeutralButtonColor))
	rejectButton:SetCallback("Clicked", function()
		self:Fire("Rejected")
	end)

	self.buttonContainer:AddChildren(acceptButton, rejectButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	local selectAllButton = AceGUI:Create("EPButton")
	selectAllButton:SetText(L["Toggle Select All"])
	selectAllButton:SetWidthFromText()
	selectAllButton:SetColor(unpack(k.NeutralButtonColor))
	local sChecked = false
	selectAllButton:SetCallback("Clicked", function()
		for _, child in ipairs(self.mainContainer.children) do
			if child.type == "EPDiffViewerEntry" then
				---@cast child EPDiffViewerEntry
				child.checkBox:SetChecked(sChecked)
			end
		end

		if self.planDiff.metaData.instanceID then
			self.planDiff.metaData.instanceID.result = sChecked
		end
		if self.planDiff.metaData.dungeonEncounterID then
			self.planDiff.metaData.dungeonEncounterID.result = sChecked
		end
		if self.planDiff.metaData.difficulty then
			self.planDiff.metaData.difficulty.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.assignments) do
			diff.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.roster) do
			diff.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.content) do
			diff.result = sChecked
		end

		sChecked = not sChecked
	end)
	selectAllButton.frame:SetParent(self.frame)
	selectAllButton.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.selectAllButton = selectAllButton

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.text, "BOTTOM", 0, -k.OtherPadding.y)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.scrollFrame:SetScrollChild(self.mainContainer.frame, true, false)

	selectAllButton.frame:SetPoint("BOTTOM", self.buttonContainer.frame, "TOP", 0, k.OtherPadding.y)
	self.scrollFrame.frame:SetPoint("BOTTOM", selectAllButton.frame, "TOP", 0, k.OtherPadding.y)

	self.frame:Show()
end

---@param self EPDiffViewer
local function OnRelease(self)
	self.windowBar:Release()
	self.windowBar = nil

	self.planDiff = nil
	self.mainContainer.frame:EnableMouse(false)
	self.mainContainer.frame:SetScript("OnMouseWheel", nil)
	self.mainContainer:Release()
	self.mainContainer = nil

	self.buttonContainer:Release()
	self.buttonContainer = nil

	self.scrollFrame:Release()
	self.scrollFrame = nil

	self.selectAllButton:Release()
	self.selectAllButton = nil

	for _, dividerLine in ipairs(self.dividerLines) do
		dividerLine:SetParent(self.frame)
		dividerLine:ClearAllPoints()
		dividerLine:Hide()
	end

	self.text:ClearAllPoints()
	self.text:SetText("")
end

---@param self EPDiffViewer
---@param diffs PlanDiff
---@param oldPlan Plan
---@param newPlan Plan
local function AddDiffs(self, diffs, oldPlan, newPlan)
	self.planDiff = diffs
	local metaDataContainer, assignmentContainer, rosterContainer = nil, nil, nil
	local addedMetaDataSection, addedAssignmentSection, addedRosterSection = nil, nil, nil
	local assigneeSpellSetsContainer, contentContainer = nil, nil
	local addedAssigneeSpellSetsSection, addedContentSection = nil, nil
	local dividerLineIndex = 1

	if diffs.metaData.instanceID then
		if not addedMetaDataSection then
			dividerLineIndex, metaDataContainer = AddSection(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		---@cast metaDataContainer EPContainer
		local oldDungeonInstance = bossUtilities.FindDungeonInstance(diffs.metaData.instanceID.oldValue)
		local newDungeonInstance = bossUtilities.FindDungeonInstance(diffs.metaData.instanceID.newValue)
		if oldDungeonInstance and newDungeonInstance then
			local oldText = format("%s: %s", L["Instance"], oldDungeonInstance.name)
			local newText = format("%s: %s", L["Instance"], newDungeonInstance.name)
			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			entry:SetMetaDataEntryData(oldText, newText)
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.metaData.instanceID.result = checked
			end)
			metaDataContainer:AddChild(entry)
		end
	end
	if diffs.metaData.dungeonEncounterID then
		if not addedMetaDataSection then
			dividerLineIndex, metaDataContainer = AddSection(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		---@cast metaDataContainer EPContainer
		local oldBoss = bossUtilities.GetBoss(diffs.metaData.dungeonEncounterID.oldValue)
		local newBoss = bossUtilities.GetBoss(diffs.metaData.dungeonEncounterID.newValue)
		local oldText = format("%s: %s", L["Boss"], oldBoss.name)
		local newText = format("%s: %s", L["Boss"], newBoss.name)
		local entry = AceGUI:Create("EPDiffViewerEntry")
		entry:SetFullWidth(true)
		entry:SetMetaDataEntryData(oldText, newText)
		entry:SetCallback("OnValueChanged", function(_, _, checked)
			self.planDiff.metaData.dungeonEncounterID.result = checked
		end)
		metaDataContainer:AddChild(entry)
	end
	if diffs.metaData.difficulty then
		if not addedMetaDataSection then
			dividerLineIndex, metaDataContainer = AddSection(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		---@cast metaDataContainer EPContainer
		local oldText = format(
			"%s: %s",
			L["Difficulty"],
			diffs.metaData.difficulty.oldValue == DifficultyType.Heroic and L["Heroic"] or L["Mythic"]
		)
		local newText = format(
			"%s: %s",
			L["Difficulty"],
			diffs.metaData.difficulty.newValue == DifficultyType.Heroic and L["Heroic"] or L["Mythic"]
		)
		local entry = AceGUI:Create("EPDiffViewerEntry")
		entry:SetFullWidth(true)
		entry:SetMetaDataEntryData(oldText, newText)
		entry:SetCallback("OnValueChanged", function(_, _, checked)
			self.planDiff.metaData.difficulty.result = checked
		end)
		metaDataContainer:AddChild(entry)
	end

	do
		---@param genericDiffEntry GenericDiffEntry
		---@return string
		---@return string?
		local function TextFunc(genericDiffEntry)
			local oldValue, newValue = GetOldAndNewValues(genericDiffEntry)
			local leftText, rightText = nil, nil
			if genericDiffEntry.type == PlanDiffType.Conflict then
				---@cast genericDiffEntry ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				leftText = CreateAssignmentDiffText(oldValue, oldPlan.roster, genericDiffEntry.localType)
				if newValue then
					rightText = CreateAssignmentDiffText(newValue, newPlan.roster, genericDiffEntry.remoteType)
				end
			else
				leftText = CreateAssignmentDiffText(oldValue, oldPlan.roster)
				if newValue then
					rightText = CreateAssignmentDiffText(newValue, newPlan.roster)
				end
			end
			return leftText, rightText
		end

		---@param index integer
		---@param checked boolean
		local function Callback(index, checked)
			if self.planDiff.assignments[index].type == PlanDiffType.Conflict then
				local conflictEntry = self.planDiff.assignments[index]
				---@cast conflictEntry ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				conflictEntry.chooseLocal = not checked
			else
				self.planDiff.assignments[index].result = checked
			end
		end

		for index, assignmentDiff in ipairs(diffs.assignments) do
			if assignmentDiff.type ~= PlanDiffType.Equal and not assignmentDiff.localOnlyChange then
				if not addedAssignmentSection then
					dividerLineIndex, assignmentContainer = AddSection(self, L["Assignments"], dividerLineIndex)
					addedAssignmentSection = true
				end
				---@cast assignmentContainer EPContainer

				local entry = AceGUI:Create("EPDiffViewerEntry")
				entry:SetFullWidth(true)
				entry:SetGenericDiffEntryData(assignmentDiff, TextFunc)
				entry:SetCallback("OnValueChanged", function(_, _, checked)
					Callback(index, checked)
				end)

				assignmentContainer:AddChild(entry)
			end
		end
	end

	do
		---@param genericDiffEntry GenericDiffEntry
		---@return string
		---@return string?
		local function TextFunc(genericDiffEntry)
			local oldValue, newValue = GetOldAndNewValues(genericDiffEntry)
			---@cast oldValue AssigneeSpellSet|FlatAssigneeSpellSet
			local assignee = genericDiffEntry.ID
			local leftText, rightText = nil, nil
			if genericDiffEntry.type == PlanDiffType.Conflict then
				---@cast genericDiffEntry ConflictDiffEntry<AssigneeSpellSet|FlatAssigneeSpellSet>
				leftText =
					CreateAssigneeSpellSetDiffText(assignee, oldValue, oldPlan.roster, genericDiffEntry.localType)
				if newValue then
					rightText =
						CreateAssigneeSpellSetDiffText(assignee, newValue, newPlan.roster, genericDiffEntry.remoteType)
				end
			else
				---@cast newValue AssigneeSpellSet|FlatAssigneeSpellSet
				leftText = CreateAssigneeSpellSetDiffText(assignee, oldValue, oldPlan.roster)
				if newValue then
					rightText = CreateAssigneeSpellSetDiffText(assignee, newValue, newPlan.roster)
				end
			end
			return leftText, rightText
		end

		---@param index integer
		---@param checked boolean
		local function Callback(index, checked)
			if self.planDiff.assigneeSpellSets[index].type == PlanDiffType.Conflict then
				local conflictEntry = self.planDiff.assigneeSpellSets[index]
				---@cast conflictEntry ConflictDiffEntry<AssigneeSpellSet>
				conflictEntry.chooseLocal = not checked
			else
				self.planDiff.assigneeSpellSets[index].result = checked
			end
		end

		for index, planTemplateDiff in ipairs(diffs.assigneeSpellSets) do
			if planTemplateDiff.type ~= PlanDiffType.Equal and not planTemplateDiff.localOnlyChange then
				if not addedAssigneeSpellSetsSection then
					dividerLineIndex, assigneeSpellSetsContainer = AddSection(self, L["Templates"], dividerLineIndex)
					addedAssigneeSpellSetsSection = true
				end
				---@cast assigneeSpellSetsContainer EPContainer

				local entry = AceGUI:Create("EPDiffViewerEntry")
				entry:SetFullWidth(true)
				entry:SetGenericDiffEntryData(planTemplateDiff, TextFunc)
				entry:SetCallback("OnValueChanged", function(_, _, checked)
					Callback(index, checked)
				end)

				assigneeSpellSetsContainer:AddChild(entry)
			end
		end
	end

	do
		---@param genericDiffEntry GenericDiffEntry
		---@return string
		---@return string?
		local function TextFunc(genericDiffEntry)
			local oldValue, newValue = GetOldAndNewValues(genericDiffEntry)
			---@cast oldValue RosterEntry
			local assignee = genericDiffEntry.ID
			local leftText, rightText = nil, nil
			if genericDiffEntry.type == PlanDiffType.Conflict then
				---@cast genericDiffEntry ConflictDiffEntry<RosterEntry>
				leftText = CreateRosterDiffText(assignee, oldValue, oldPlan.roster, genericDiffEntry.localType)
				if newValue then
					---@cast newValue RosterEntry
					rightText = CreateRosterDiffText(assignee, newValue, newPlan.roster, genericDiffEntry.remoteType)
				end
			else
				leftText = CreateRosterDiffText(assignee, oldValue, oldPlan.roster)
				if newValue then
					---@cast newValue RosterEntry
					rightText = CreateRosterDiffText(assignee, newValue, newPlan.roster)
				end
			end
			return leftText, rightText
		end

		---@param index integer
		---@param checked boolean
		local function Callback(index, checked)
			if self.planDiff.roster[index].type == PlanDiffType.Conflict then
				local conflictEntry = self.planDiff.roster[index]
				---@cast conflictEntry ConflictDiffEntry<RosterEntry>
				conflictEntry.chooseLocal = not checked
			else
				self.planDiff.roster[index].result = checked
			end
		end

		for index, planRosterDiff in ipairs(diffs.roster) do
			if planRosterDiff.type ~= PlanDiffType.Equal and not planRosterDiff.localOnlyChange then
				if not addedRosterSection then
					dividerLineIndex, rosterContainer = AddSection(self, L["Roster"], dividerLineIndex)
					addedRosterSection = true
				end
				---@cast rosterContainer EPContainer

				local entry = AceGUI:Create("EPDiffViewerEntry")
				entry:SetFullWidth(true)
				entry:SetGenericDiffEntryData(planRosterDiff, TextFunc)
				entry:SetCallback("OnValueChanged", function(_, _, checked)
					Callback(index, checked)
				end)
				rosterContainer:AddChild(entry)
			end
		end
	end

	for index, contentDiffEntry in ipairs(diffs.content) do
		if contentDiffEntry.type ~= PlanDiffType.Equal then
			if not addedContentSection then
				dividerLineIndex, contentContainer = AddSection(self, L["External Text"], dividerLineIndex)
				addedContentSection = true
			end
			---@cast contentContainer EPContainer

			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			if contentDiffEntry.type == PlanDiffType.Insert then
				---@cast contentDiffEntry IndexedInsertDiffEntry<string>
				entry:SetContentEntryData(PlanDiffType.Insert, contentDiffEntry.newValue)
			elseif contentDiffEntry.type == PlanDiffType.Delete then
				---@cast contentDiffEntry IndexedDeleteDiffEntry<string>
				entry:SetContentEntryData(PlanDiffType.Delete, contentDiffEntry.oldValue)
			elseif contentDiffEntry.type == PlanDiffType.Change then
				---@cast contentDiffEntry IndexedChangeDiffEntry<string>
				entry:SetContentEntryData(PlanDiffType.Change, contentDiffEntry.oldValue, contentDiffEntry.newValue)
			end
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.content[index].result = checked
			end)
			contentContainer:AddChild(entry)
		end
	end

	local maxTypeLabelWidth = 0
	IterateContainer(self.mainContainer, function(entry)
		maxTypeLabelWidth = max(maxTypeLabelWidth, entry.typeLabel.frame:GetWidth())
		if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
			entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
		elseif entry.valueLabelTwo then
			if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
			end
		end
	end)
	IterateContainer(self.mainContainer, function(entry)
		entry.typeLabel.frame:SetWidth(maxTypeLabelWidth)
	end)

	self.mainContainer:DoLayout()
	self.buttonContainer:DoLayout()
	self.scrollFrame:UpdateVerticalScroll()
	self.scrollFrame:UpdateThumbPositionAndSize()

	while self.dividerLines[dividerLineIndex] do
		self.dividerLines[dividerLineIndex]:ClearAllPoints()
		self.dividerLines[dividerLineIndex]:Hide()
		dividerLineIndex = dividerLineIndex + 1
	end
end

---@param self EPDiffViewer
---@param text string
local function SetText(self, text)
	self.text:SetText(text)
end

---@param self EPDiffViewer
---@param text string
---@param beforeWidget AceGUIWidget|nil
local function AddButton(self, text, beforeWidget)
	local button = AceGUI:Create("EPButton")
	button:SetText(text)
	button:SetWidthFromText()
	button:SetHeight(k.DefaultButtonHeight)
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetCallback("Clicked", function()
		self:Fire(text .. "Clicked")
	end)
	if beforeWidget then
		self.buttonContainer:InsertChildren(beforeWidget, button)
	else
		self.buttonContainer:AddChild(button)
	end
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
	local currentContentWidth = self.frame:GetWidth() - 2 * k.ContentFramePadding.x
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * k.ContentFramePadding.x)
		self.text:SetWidth(self.frame:GetWidth() - 2 * k.ContentFramePadding.x)
		self.mainContainer:DoLayout()
		self.scrollFrame:UpdateVerticalScroll()
		self.scrollFrame:UpdateThumbPositionAndSize()
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetWordWrap(true)
	text:SetSpacing(4)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.DefaultFontSize)
	end

	---@class EPDiffViewer : AceGUIWidget
	---@field mainContainer EPContainer
	---@field scrollFrame EPScrollFrame
	---@field buttonContainer EPContainer
	---@field selectAllButton EPButton
	---@field planDiff PlanDiff
	---@field windowBar EPWindowBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		AddDiffs = AddDiffs,
		AddButton = AddButton,
		SetText = SetText,
		frame = frame,
		type = Type,
		count = count,
		dividerLines = {},
		text = text,
		isCommunicationsMessage = true,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
