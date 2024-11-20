---@module "NerubarPalace"
---@module "Options"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local format = format
local getmetatable = getmetatable
local GetSpellInfo = C_Spell.GetSpellInfo
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local unpack = unpack

local assignmentPadding = 2
local bossAbilityPadding = 4
local bottomLeftContainerSpacing = { 0, 6 }
local bottomLeftContainerWidth = 200
local dropdownContainerLabelSpacing = { 2, 2 }
local dropdownContainerSpacing = { 2, 2 }
local noteContainerSpacing = { 5, 2 }
local topContainerDropdownWidth = 150
local topContainerHeight = 36
local spellDropdownItems = utilities.CreateSpellAssignmentDropdownItems()
local assignmentTypeDropdownItems = utilities.CreateAssignmentTypeDropdownItems()
local classDropdownItems = utilities.CreateClassDropdownItemData()

---@return table<string, EncounterPlannerDbRosterEntry>
local function GetCurrentRoster()
	local lastOpenNote = AddOn.db.profile.lastOpenNote
	local note = AddOn.db.profile.notes[lastOpenNote]
	return note.roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	local lastOpenNote = AddOn.db.profile.lastOpenNote
	local note = AddOn.db.profile.notes[lastOpenNote]
	return note.assignments
end

---@param currentRosterMap table<integer, RosterWidgetMapping>
---@param sharedRosterMap table<integer, RosterWidgetMapping>
local function HandleRosterEditingFinished(_, _, currentRosterMap, sharedRosterMap)
	local lastOpenNote = AddOn.db.profile.lastOpenNote
	if lastOpenNote then
		local tempRoster = {}
		for _, rosterWidgetMapping in ipairs(currentRosterMap) do
			tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		AddOn.db.profile.notes[lastOpenNote].roster = tempRoster
	end

	local tempRoster = {}
	for _, rosterWidgetMapping in ipairs(sharedRosterMap) do
		tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
	end
	AddOn.db.profile.sharedRoster = tempRoster

	Private.rosterEditor:Release()
	utilities.UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster(), false)
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	interfaceUpdater.UpdateAllAssignments(true, boss)
end

---@param rosterTab EPRosterEditorTab
local function HandleImportCurrentRaidButtonClicked(_, _, rosterTab)
	local currentRoster = nil
	if rosterTab == "SharedRoster" then
		currentRoster = AddOn.db.profile.sharedRoster
	elseif rosterTab == "CurrentBossRoster" then
		currentRoster = GetCurrentRoster()
	end
	if currentRoster then
		utilities.UpdateRosterDataFromGroup(currentRoster, true)
		if rosterTab == "CurrentBossRoster" then
			interfaceUpdater.UpdateAddAssigneeDropdown()
		end
		Private.rosterEditor:SetRosters(GetCurrentRoster(), AddOn.db.profile.sharedRoster)
	end
	Private.rosterEditor:SetCurrentTab(rosterTab)
end

local function HandleImportRosterButtonClicked(_, _, rosterTab)
	local fromRoster = nil
	local toRoster = nil
	if rosterTab == "SharedRoster" then
		fromRoster = GetCurrentRoster()
		toRoster = AddOn.db.profile.sharedRoster
	elseif rosterTab == "CurrentBossRoster" then
		fromRoster = AddOn.db.profile.sharedRoster
		toRoster = GetCurrentRoster()
	end
	if fromRoster and toRoster then
		for name, rosterMember in pairs(fromRoster) do
			if not toRoster[name] then
				toRoster[name] = Private.DeepCopy(rosterMember)
			else
				if (not toRoster[name].class or toRoster[name].class == "") and rosterMember.class then
					toRoster[name].class = rosterMember.class
					toRoster[name].classColoredName = nil
				end
				if (not toRoster[name].role or toRoster[name].role == "") and rosterMember.role then
					toRoster[name].role = rosterMember.role
				end
			end
		end
	end
	utilities.UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster(), false)
	interfaceUpdater.UpdateAddAssigneeDropdown()
	Private.rosterEditor:SetRosters(GetCurrentRoster(), AddOn.db.profile.sharedRoster)
	Private.rosterEditor:SetCurrentTab(rosterTab)
end

local function CreateRosterEditor()
	if not Private.rosterEditor then
		Private.rosterEditor = AceGUI:Create("EPRosterEditor")
		Private.rosterEditor:SetCallback("OnRelease", function()
			Private.rosterEditor = nil
		end)
		Private.rosterEditor:SetCallback("EditingFinished", HandleRosterEditingFinished)
		Private.rosterEditor:SetCallback("ImportCurrentRaidButtonClicked", HandleImportCurrentRaidButtonClicked)
		Private.rosterEditor:SetCallback("ImportRosterButtonClicked", HandleImportRosterButtonClicked)
		Private.rosterEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.rosterEditor.frame:SetFrameLevel(25)
		local yPos = -(Private.mainFrame.frame:GetHeight() / 2) + (Private.rosterEditor.frame:GetHeight() / 2)
		Private.rosterEditor.frame:SetPoint("TOP", Private.mainFrame.frame, "TOP", 0, yPos)

		Private.rosterEditor:SetLayout("EPVerticalLayout")
		Private.rosterEditor:SetClassDropdownData(classDropdownItems)
		Private.rosterEditor:SetRosters(GetCurrentRoster(), AddOn.db.profile.sharedRoster)
		Private.rosterEditor:SetCurrentTab("CurrentBossRoster")
		yPos = -(Private.mainFrame.frame:GetHeight() / 2) + (Private.rosterEditor.frame:GetHeight() / 2)
		Private.rosterEditor.frame:SetPoint("TOP", Private.mainFrame.frame, "TOP", 0, yPos)
		Private.rosterEditor:DoLayout()
	end
end

---@param value number|string
local function HandleBossDropdownValueChanged(value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local bossIndex = tonumber(value)
	if bossIndex then
		local bossDef = bossUtilities.GetBossDefinition(bossIndex)
		if bossDef then
			AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].bossName = bossDef.name
			interfaceUpdater.UpdateBossAbilityList(bossDef.name)
			interfaceUpdater.UpdateTimelineBossAbilities(bossDef.name)
		end
	end
end

---@param value number|string
local function HandleBossAbilitySelectDropdownValueChanged(value, selected)
	local bossIndex = Private.mainFrame:GetBossSelectDropdown():GetValue()
	local bossDef = bossUtilities.GetBossDefinition(bossIndex)
	if bossDef then
		AddOn.db.profile.activeBossAbilities[bossDef.name][value] = selected
		interfaceUpdater.UpdateBossAbilityList(bossDef.name, false)
		interfaceUpdater.UpdateTimelineBossAbilities(bossDef.name)
	end
end

---@param value string
local function HandleAssignmentSortDropdownValueChanged(_, _, value)
	AddOn.db.profile.assignmentSortType = value
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	interfaceUpdater.UpdateAllAssignments(false, boss)
end

---@param value string
local function HandleNoteDropdownValueChanged(_, _, value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	AddOn.db.profile.lastOpenNote = value
	local note = AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote]
	local bossName = note.bossName
	if not bossName then
		bossName = utilities.SearchStringTableForBossName(note.content)
	end
	local boss = nil
	if bossName then
		interfaceUpdater.UpdateBossAbilityList(bossName)
		interfaceUpdater.UpdateTimelineBossAbilities(bossName)
		boss = bossUtilities.GetBoss(bossName)
	end
	interfaceUpdater.UpdateAllAssignments(true, boss)
	local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
	if renameNoteLineEdit then
		renameNoteLineEdit:SetText(value)
	end
end

---@param lineEdit EPLineEdit
---@param value string
local function HandleNoteTextChanged(lineEdit, _, value)
	local currentNoteName = AddOn.db.profile.lastOpenNote
	if value == currentNoteName then
		return
	elseif AddOn.db.profile.notes[value] then
		lineEdit:SetText(currentNoteName)
		return
	end
	AddOn.db.profile.notes[value] = AddOn.db.profile.notes[currentNoteName]
	AddOn.db.profile.notes[currentNoteName] = nil
	AddOn.db.profile.lastOpenNote = value
	local noteDropdown = Private.mainFrame:GetNoteDropdown()
	if noteDropdown then
		noteDropdown:EditItemText(currentNoteName, value, value)
	end
end

local function HandleAssignmentEditorDeleteButtonClicked()
	local assignmentID = Private.assignmentEditor:GetAssignmentID()
	Private.assignmentEditor:Release()
	for i, v in ipairs(GetCurrentAssignments()) do
		if v.uniqueID == assignmentID then
			tremove(GetCurrentAssignments(), i)
			break
		end
	end
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	interfaceUpdater.UpdateAllAssignments(true, boss)
end

local function HandleAssignmentEditorOkayButtonClicked()
	Private.assignmentEditor:Release()
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	interfaceUpdater.UpdateAllAssignments(true, boss)
end

---@param assignmentEditor EPAssignmentEditor
---@param dataType string
---@param value string
local function HandleAssignmentEditorDataChanged(assignmentEditor, _, dataType, value)
	local assignmentID = assignmentEditor:GetAssignmentID()
	if not assignmentID then
		return
	end
	local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
	if not assignment then
		return
	end
	if dataType == "AssignmentType" then
		if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
			if getmetatable(assignment) ~= Private.classes.CombatLogEventAssignment then
				assignment = Private.classes.CombatLogEventAssignment:New(assignment)
			end
		elseif value == "Absolute Time" then
			if getmetatable(assignment) ~= Private.classes.TimedAssignment then
				assignment = Private.classes.TimedAssignment:New(assignment)
			end
		elseif value == "Boss Phase" then
			if getmetatable(assignment) ~= Private.classes.PhasedAssignment then
				assignment = Private.classes.PhasedAssignment:New(assignment)
			end
		end
		assignment--[[@as CombatLogEventAssignment]].combatLogEventType = value
	elseif dataType == "CombatLogEventSpellID" then
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID = tonumber(value)
		end
	elseif dataType == "CombatLogEventSpellCount" then
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			assignment--[[@as CombatLogEventAssignment]].spellCount = tonumber(value)
		end
	elseif dataType == "PhaseNumber" then
		if
			getmetatable(assignment) == Private.classes.CombatLogEventAssignment
			or getmetatable(assignment) == Private.classes.PhasedAssignment
		then
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment]].phase = tonumber(value)
		end
	elseif dataType == "SpellAssignment" then
		local spellInfo = GetSpellInfo(value)
		if spellInfo then
			assignment.spellInfo.iconID = spellInfo.iconID
			assignment.spellInfo.spellID = spellInfo.spellID
			assignment.spellInfo.name = spellInfo.name
		end
	elseif dataType == "AssigneeType" then
		if value ~= "Individual" then
			assignment.assigneeNameOrRole = value
		end
	elseif dataType == "Assignee" then
		assignment.assigneeNameOrRole = value
	elseif dataType == "Time" then
		if not tonumber(value) then
			return
		end
		if
			getmetatable(assignment) == Private.classes.CombatLogEventAssignment
			or getmetatable(assignment) == Private.classes.PhasedAssignment
			or getmetatable(assignment) == Private.classes.TimedAssignment
		then
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time = tonumber(value)
		end
	elseif dataType == "OptionalText" then
		assignment.text = value -- TODO: update textWithIconReplacements
	elseif dataType == "Target" then
		assignment.targetName = value
	end

	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	local timeline = Private.mainFrame:GetTimeline()
	if timeline and boss then
		local bossPhaseTable = bossUtilities.CreateBossPhaseTable(boss)
		for _, timelineAssignment in pairs(timeline:GetAssignments()) do
			if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
				utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, boss, bossPhaseTable)
				break
			end
		end
		timeline:UpdateTimeline()
	end
end

---@param uniqueID integer
local function HandleTimelineAssignmentClicked(_, _, uniqueID)
	if not Private.assignmentEditor then
		Private.assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		Private.assignmentEditor.obj = Private.mainFrame
		Private.assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.assignmentEditor.frame:SetFrameLevel(10)
		Private.assignmentEditor.frame:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
		Private.assignmentEditor:SetLayout("EPVerticalLayout")
		Private.assignmentEditor:SetCallback("OnRelease", function()
			Private.assignmentEditor = nil
		end)
		Private.assignmentEditor:SetCallback("DataChanged", HandleAssignmentEditorDataChanged)
		Private.assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
		Private.assignmentEditor:SetCallback("OkayButtonClicked", HandleAssignmentEditorOkayButtonClicked)
		Private.assignmentEditor.spellAssignmentDropdown:AddItems(spellDropdownItems, "EPDropdownItemToggle")
		Private.assignmentEditor.assigneeTypeDropdown:AddItems(assignmentTypeDropdownItems, "EPDropdownItemToggle")
		local assigneeDropdownItems = utilities.CreateAssigneeDropdownItems(GetCurrentRoster())
		Private.assignmentEditor.assigneeDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		Private.assignmentEditor.targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		local dropdownItems = {}
		local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
		if boss then
			for _, ID in pairs(boss.sortedAbilityIDs) do
				local spellInfo = GetSpellInfo(ID)
				if spellInfo then
					local iconText = format("|T%s:16|t %s", spellInfo.iconID, spellInfo.name)
					tinsert(dropdownItems, {
						itemValue = ID,
						text = iconText,
						dropdownItemMenuData = {},
					})
				end
			end
		end
		Private.assignmentEditor.combatLogEventSpellIDDropdown:AddItems(dropdownItems, "EPDropdownItemToggle")
		Private.assignmentEditor:DoLayout()
	end
	Private.assignmentEditor:SetAssignmentID(uniqueID)
	local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), uniqueID)
	if not assignment then
		return
	end

	if assignment.assigneeNameOrRole == "{everyone}" then
		Private.assignmentEditor:SetAssigneeType("Everyone")
		Private.assignmentEditor.assigneeTypeDropdown:SetValue(assignment.assigneeNameOrRole)
		Private.assignmentEditor.assigneeDropdown:SetValue("")
	else
		local classMatch = assignment.assigneeNameOrRole:match("class:%s*(%a+)")
		local roleMatch = assignment.assigneeNameOrRole:match("role:%s*(%a+)")
		if classMatch then
			Private.assignmentEditor:SetAssigneeType("Class")
			Private.assignmentEditor.assigneeTypeDropdown:SetValue(assignment.assigneeNameOrRole)
			Private.assignmentEditor.assigneeDropdown:SetValue("")
		elseif roleMatch then
			Private.assignmentEditor:SetAssigneeType("Role")
			Private.assignmentEditor.assigneeTypeDropdown:SetValue(assignment.assigneeNameOrRole)
			Private.assignmentEditor.assigneeDropdown:SetValue("")
		else
			Private.assignmentEditor:SetAssigneeType("Individual")
			Private.assignmentEditor.assigneeTypeDropdown:SetValue("Individual")
			Private.assignmentEditor.assigneeDropdown:SetValue(assignment.assigneeNameOrRole)
		end
	end

	Private.assignmentEditor.previewLabel:SetText(assignment.strWithIconReplacements)
	Private.assignmentEditor.targetDropdown:SetValue(assignment.targetName)
	Private.assignmentEditor.optionalTextLineEdit:SetText(assignment.text)
	Private.assignmentEditor.spellAssignmentDropdown:SetValue(assignment.spellInfo.spellID)

	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		Private.assignmentEditor:SetAssignmentType("CombatLogEventAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue(assignment.combatLogEventType)
		Private.assignmentEditor.combatLogEventSpellIDDropdown:SetValue(assignment.combatLogEventSpellID)
		Private.assignmentEditor.combatLogEventSpellCountLineEdit:SetText(assignment.spellCount)
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		Private.assignmentEditor:SetAssignmentType("TimedAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue("Absolute Time")
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		Private.assignmentEditor:SetAssignmentType("PhasedAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue("Boss Phase")
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	end
end

local function HandleAddAssigneeRowDropdownValueChanged(dropdown, _, value)
	if value == "Add Assignee" then
		return
	end

	local alreadyExists = false
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.assignmentSortType,
		boss
	)
	local sortedAssignees = utilities.SortAssignees(sorted)
	for _, assigneeNameOrRole in ipairs(sortedAssignees) do
		if assigneeNameOrRole == value then
			alreadyExists = true
			break
		end
	end
	if not alreadyExists then
		local assignment = Private.classes.Assignment:New()
		assignment.assigneeNameOrRole = value
		tinsert(GetCurrentAssignments(), assignment)
		interfaceUpdater.UpdateAllAssignments(true, boss)
	end

	dropdown:SetText("Add Assignee")
end

---@param abilityInstance BossAbilityInstance
---@param assigneeIndex integer
local function HandleCreateNewAssignment(_, _, abilityInstance, assigneeIndex)
	if not assigneeIndex then
		return
	end
	local assignment = Private.classes.Assignment:New()
	local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.assignmentSortType,
		boss
	)
	local sortedAssignees = utilities.SortAssignees(sorted)
	assignment.assigneeNameOrRole = sortedAssignees[assigneeIndex] or ""
	if abilityInstance.combatLogEventType and abilityInstance.triggerSpellID and abilityInstance.triggerCastIndex then
		-- if abilityInstance.repeatInstance and abilityInstance.repeatCastIndex then
		-- else
		local combatLogEventAssignment = Private.classes.CombatLogEventAssignment:New(assignment)
		combatLogEventAssignment.combatLogEventType = abilityInstance.combatLogEventType
		combatLogEventAssignment.time = abilityInstance.castTime
		combatLogEventAssignment.phase = abilityInstance.phase
		combatLogEventAssignment.spellCount = abilityInstance.triggerCastIndex
		combatLogEventAssignment.combatLogEventSpellID = abilityInstance.triggerSpellID
		tinsert(GetCurrentAssignments(), combatLogEventAssignment)
		-- end
		-- elseif abilityInstance.repeatInstance then
	else
		local timedAssignment = Private.classes.TimedAssignment:New(assignment)
		timedAssignment.time = abilityInstance.castTime
		tinsert(GetCurrentAssignments(), timedAssignment)
	end
	interfaceUpdater.UpdateAllAssignments(false, boss)
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
end

local function HandleCreateNewEPNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local newNoteName = utilities.CreateUniqueNoteName(AddOn.db.profile.notes)
	AddOn.db.profile.notes[newNoteName] = Private.classes.EncounterPlannerDbNote:New()
	AddOn.db.profile.lastOpenNote = newNoteName

	local bossDef = bossUtilities.GetBossDefinition(Private.mainFrame:GetBossSelectDropdown():GetValue())
	if bossDef then
		AddOn.db.profile.notes[newNoteName].bossName = bossDef.name
	end

	interfaceUpdater.UpdateAllAssignments(true)
	local noteDropdown = Private.mainFrame:GetNoteDropdown()
	if noteDropdown then
		noteDropdown:AddItem(newNoteName, newNoteName, "EPDropdownItemToggle")
		noteDropdown:SetValue(newNoteName)
	end
	local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
	if renameNoteLineEdit then
		renameNoteLineEdit:SetText(newNoteName)
	end
end

local function HandleDeleteCurrentEPNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local beforeRemovalCount = 0
	for _, _ in pairs(AddOn.db.profile.notes) do
		beforeRemovalCount = beforeRemovalCount + 1
	end
	local noteDropdown = Private.mainFrame:GetNoteDropdown()
	if noteDropdown then
		local lastOpenNote = AddOn.db.profile.lastOpenNote
		if lastOpenNote then
			AddOn.db.profile.notes[lastOpenNote] = nil
			noteDropdown:RemoveItem(lastOpenNote)
		end
		if beforeRemovalCount > 1 then
			for name, _ in pairs(AddOn.db.profile.notes) do
				AddOn.db.profile.lastOpenNote = name
				local bossName = AddOn.db.profile.notes[name].bossName
				if bossName then
					interfaceUpdater.UpdateBossAbilityList(bossName)
					interfaceUpdater.UpdateTimelineBossAbilities(bossName)
				end
				break
			end
		else
			local newNoteName = utilities.CreateUniqueNoteName(AddOn.db.profile.notes)
			AddOn.db.profile.notes[newNoteName] = Private.classes.EncounterPlannerDbNote:New()
			AddOn.db.profile.lastOpenNote = newNoteName
			noteDropdown:AddItem(newNoteName, newNoteName, "EPDropdownItemToggle")
			local bossDef = bossUtilities.GetBossDefinition(Private.mainFrame:GetBossSelectDropdown():GetValue())
			if bossDef then
				AddOn.db.profile.notes[newNoteName].bossName = bossDef.name
			end
		end
		noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
		local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
		if renameNoteLineEdit then
			renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)
		end
		local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
		interfaceUpdater.UpdateAllAssignments(true, boss)
	end
end

---@param importDropdown EPDropdown
---@param value any
local function HandleImportMRTNoteDropdownValueChanged(importDropdown, _, value)
	if value == "Import" then
		return
	end
	if Private.importEditBox then
		importDropdown:SetText("Import")
		return
	end

	if value == "FromMRTOverwrite" or value == "FromMRTNew" then
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		local bossName = nil
		if value == "FromMRTOverwrite" then
			bossName = Private:Note(AddOn.db.profile.lastOpenNote, true)
		elseif value == "FromMRTNew" then
			local newNoteName = utilities.CreateUniqueNoteName(AddOn.db.profile.notes)
			bossName = Private:Note(newNoteName, true)
			AddOn.db.profile.lastOpenNote = newNoteName
			local noteDropdown = Private.mainFrame:GetNoteDropdown()
			if noteDropdown then
				noteDropdown:AddItem(newNoteName, newNoteName, "EPDropdownItemToggle")
				noteDropdown:SetValue(newNoteName)
			end
			local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
			if renameNoteLineEdit then
				renameNoteLineEdit:SetText(newNoteName)
			end
		end
		local boss = nil
		if bossName then
			interfaceUpdater.UpdateBossAbilityList(bossName)
			interfaceUpdater.UpdateTimelineBossAbilities(bossName)
			boss = bossUtilities.GetBoss(bossName)
		end
		interfaceUpdater.UpdateAllAssignments(true, boss)
	elseif value == "FromStringOverwrite" or value == "FromStringNew" then
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		Private.importEditBox = AceGUI:Create("EPEditBox")
		Private.importEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.importEditBox.frame:SetFrameLevel(30)
		Private.importEditBox.frame:SetPoint("CENTER")
		Private.importEditBox:SetTitle("Import Text")
		local buttonText
		if value == "FromStringOverwrite" then
			buttonText = "Overwrite " .. AddOn.db.profile.lastOpenNote
		else
			buttonText = "Import As New EP note"
		end
		Private.importEditBox:ShowOkayButton(true, buttonText)
		Private.importEditBox:SetCallback("OnRelease", function()
			Private.importEditBox = nil
		end)
		local valueCopy = value
		Private.importEditBox:SetCallback("OkayButtonClicked", function()
			local text = Private.importEditBox:GetText()
			local textTable = utilities.SplitStringIntoTable(text)
			Private.importEditBox:Release()
			local bossName = nil
			local lastOpenNote = AddOn.db.profile.lastOpenNote
			local notes = AddOn.db.profile.notes

			if valueCopy == "FromStringOverwrite" then
				notes[lastOpenNote].content = textTable
				bossName = Private:Note(lastOpenNote)
			elseif valueCopy == "FromStringNew" then
				local newNoteName = utilities.CreateUniqueNoteName(notes)
				notes[newNoteName] = Private.classes.EncounterPlannerDbNote:New()
				notes[newNoteName].content = textTable
				bossName = Private:Note(newNoteName)
				AddOn.db.profile.lastOpenNote = newNoteName
				local noteDropdown = Private.mainFrame:GetNoteDropdown()
				if noteDropdown then
					noteDropdown:AddItem(newNoteName, newNoteName, "EPDropdownItemToggle")
					noteDropdown:SetValue(newNoteName)
				end
				local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
				if renameNoteLineEdit then
					renameNoteLineEdit:SetText(newNoteName)
				end
			end

			local boss = nil
			if bossName then
				interfaceUpdater.UpdateBossAbilityList(bossName)
				interfaceUpdater.UpdateTimelineBossAbilities(bossName)
				boss = bossUtilities.GetBoss(bossName)
			end
			interfaceUpdater.UpdateAllAssignments(true, boss)
		end)
		Private.importEditBox:HightlightTextAndFocus()
	end

	importDropdown:SetText("Import")
end

local function HandleExportEPNoteButtonClicked()
	if not Private.exportEditBox then
		Private.exportEditBox = AceGUI:Create("EPEditBox")
		Private.exportEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.exportEditBox.frame:SetFrameLevel(12)
		Private.exportEditBox.frame:SetPoint("CENTER")
		Private.exportEditBox:SetTitle("Export")
		Private.exportEditBox:SetCallback("OnRelease", function()
			Private.exportEditBox = nil
		end)
	end
	local text = Private:ExportNote(AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote])
	if text then
		Private.exportEditBox:SetText(text)
		Private.exportEditBox:HightlightTextAndFocus()
	end
end

function Private:CreateGUI()
	local bossName = nil
	if not AddOn.db.profile.lastOpenNote or AddOn.db.profile.lastOpenNote == "" then
		local defaultNoteName = "SharedMRTNote"
		bossName = Private:Note(defaultNoteName, true)
		if not AddOn.db.profile.notes[defaultNoteName] then -- MRT not loaded
			defaultNoteName = utilities.CreateUniqueNoteName(AddOn.db.profile.notes)
			AddOn.db.profile.notes[defaultNoteName] = Private.classes.EncounterPlannerDbNote:New()
		end
		AddOn.db.profile.lastOpenNote = defaultNoteName
	end

	if bossName == nil then
		local note = AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote]
		if note.bossName then
			bossName = note.bossName
		else
			bossName = "Ulgrax the Devourer"
			note.bossName = bossName
		end
	end

	Private.mainFrame = AceGUI:Create("EPMainFrame")

	Private.mainFrame:SetLayout("EPContentFrameLayout")
	Private.mainFrame:SetCallback("OnRelease", function()
		Private.mainFrame = nil
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		if Private.exportEditBox then
			Private.exportEditBox:Release()
		end
		if Private.importEditBox then
			Private.importEditBox:Release()
		end
		if Private.rosterEditor then
			Private.rosterEditor:Release()
		end
	end)

	local bossContainer = AceGUI:Create("EPContainer")
	bossContainer:SetLayout("EPVerticalLayout")
	bossContainer:SetSpacing(unpack(dropdownContainerSpacing))
	bossContainer:SetWidth(topContainerDropdownWidth)

	local bossSelectContainer = AceGUI:Create("EPContainer")
	bossSelectContainer:SetAlignment("center")
	bossSelectContainer:SetLayout("EPHorizontalLayout")
	bossSelectContainer:SetFullWidth(true)
	bossSelectContainer:SetSpacing(unpack(noteContainerSpacing))

	local bossDropdown = AceGUI:Create("EPDropdown")
	local bossDropdownData = {}
	for index, instance in ipairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterID)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterID)
		local iconText = format("|T%s:16|t %s", iconImage, instance.name)
		tinsert(bossDropdownData, index, iconText)
	end
	bossDropdown:AddItems(bossDropdownData, "EPDropdownItemToggle")
	bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleBossDropdownValueChanged(value)
	end)

	local bossAbilitySelectContainer = AceGUI:Create("EPContainer")
	bossAbilitySelectContainer:SetAlignment("center")
	bossAbilitySelectContainer:SetLayout("EPHorizontalLayout")
	bossAbilitySelectContainer:SetFullWidth(true)
	bossAbilitySelectContainer:SetSpacing(unpack(noteContainerSpacing))

	local bossAbilitySelectDropdown = AceGUI:Create("EPDropdown")
	bossAbilitySelectDropdown:SetCallback("OnValueChanged", function(_, _, value, selected)
		HandleBossAbilitySelectDropdownValueChanged(value, selected)
	end)
	bossAbilitySelectDropdown:SetMultiselect(true)
	bossAbilitySelectDropdown:SetText("Active Boss Abilities")
	local assignmentSortContainer = AceGUI:Create("EPContainer")
	assignmentSortContainer:SetLayout("EPVerticalLayout")
	assignmentSortContainer:SetSpacing(unpack(dropdownContainerSpacing))
	assignmentSortContainer:SetFullHeight(true)
	assignmentSortContainer:SetWidth(topContainerDropdownWidth)

	local assignmentSortSpacer = AceGUI:Create("EPSpacer")
	assignmentSortSpacer:SetFillSpace(true)

	local assignmentSortLabel = AceGUI:Create("EPLabel")
	assignmentSortLabel:SetText("Assignment Sort Priority:")
	assignmentSortLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))
	assignmentSortLabel:SetFullWidth(true)

	local assignmentSortDropdown = AceGUI:Create("EPDropdown")
	assignmentSortDropdown:SetWidth(topContainerDropdownWidth)
	assignmentSortDropdown:AddItems({
		{ itemValue = "Alphabetical", text = "Alphabetical", dropdownItemMenuData = {} },
		{ itemValue = "First Appearance", text = "First Appearance", dropdownItemMenuData = {} },
		{ itemValue = "Role > Alphabetical", text = "Role > Alphabetical", dropdownItemMenuData = {} },
		{ itemValue = "Role > First Appearance", text = "Role > First Appearance", dropdownItemMenuData = {} },
	}, "EPDropdownItemToggle")
	assignmentSortDropdown:SetCallback("OnValueChanged", HandleAssignmentSortDropdownValueChanged)

	local editRosterContainer = AceGUI:Create("EPContainer")
	editRosterContainer:SetLayout("EPVerticalLayout")
	editRosterContainer:SetSpacing(unpack(dropdownContainerSpacing))
	editRosterContainer:SetFullHeight(true)
	editRosterContainer:SetWidth(topContainerDropdownWidth)

	local editRosterSpacer = AceGUI:Create("EPSpacer")
	editRosterSpacer:SetFillSpace(true)

	local editRosterButton = AceGUI:Create("EPButton")
	editRosterButton:SetFullWidth(true)
	editRosterButton:SetCallback("Clicked", CreateRosterEditor)
	editRosterButton:SetText("Edit Roster")

	local spacer = AceGUI:Create("EPSpacer")
	spacer:SetFillSpace(true)

	local outerNoteContainer = AceGUI:Create("EPContainer")
	outerNoteContainer:SetLayout("EPVerticalLayout")
	outerNoteContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local noteContainer = AceGUI:Create("EPContainer")
	noteContainer:SetAlignment("center")
	noteContainer:SetLayout("EPHorizontalLayout")
	noteContainer:SetFullWidth(true)
	noteContainer:SetSpacing(unpack(noteContainerSpacing))

	local noteLabel = AceGUI:Create("EPLabel")
	noteLabel:SetText("Current:")
	noteLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

	local noteDropdown = AceGUI:Create("EPDropdown")
	noteDropdown:SetWidth(topContainerDropdownWidth)
	local noteDropdownData = {}
	noteDropdown:SetCallback("OnValueChanged", HandleNoteDropdownValueChanged)
	for noteName, _ in pairs(AddOn.db.profile.notes) do
		tinsert(noteDropdownData, { itemValue = noteName, text = noteName, dropdownItemMenuData = {} })
	end
	noteDropdown:AddItems(noteDropdownData, "EPDropdownItemToggle")

	local renameNoteLineEdit = AceGUI:Create("EPLineEdit")
	renameNoteLineEdit:SetWidth(topContainerDropdownWidth)
	renameNoteLineEdit:SetCallback("OnTextChanged", HandleNoteTextChanged)

	local renameNoteContainer = AceGUI:Create("EPContainer")
	renameNoteContainer:SetAlignment("center")
	renameNoteContainer:SetLayout("EPHorizontalLayout")
	renameNoteContainer:SetSpacing(unpack(noteContainerSpacing))

	local renameNoteLabel = AceGUI:Create("EPLabel")
	renameNoteLabel:SetText("Rename current:")
	renameNoteLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

	local noteButtonContainer = AceGUI:Create("EPContainer")
	noteButtonContainer:SetAlignment("center")
	noteButtonContainer:SetLayout("EPVerticalLayout")
	noteButtonContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local createNewButton = AceGUI:Create("EPButton")
	createNewButton:SetCallback("Clicked", HandleCreateNewEPNoteButtonClicked)
	createNewButton:SetText("New EP note")

	local deleteButton = AceGUI:Create("EPButton")
	deleteButton:SetCallback("Clicked", HandleDeleteCurrentEPNoteButtonClicked)
	deleteButton:SetText("Delete EP note")

	local importExportContainer = AceGUI:Create("EPContainer")
	importExportContainer:SetAlignment("center")
	importExportContainer:SetLayout("EPVerticalLayout")
	importExportContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local importDropdown = AceGUI:Create("EPDropdown")
	importDropdown:SetWidth(topContainerDropdownWidth)
	importDropdown:SetTextCentered(true)
	importDropdown:SetCallback("OnValueChanged", HandleImportMRTNoteDropdownValueChanged)
	importDropdown:SetText("Import")
	local importDropdownData = {
		{
			itemValue = "From MRT",
			text = "From MRT",
			dropdownItemMenuData = {
				{
					itemValue = "FromMRTOverwrite",
					text = "Overwrite current EP note",
					dropdownItemMenuData = {},
				},
				{ itemValue = "FromMRTNew", text = "Create new EP note", dropdownItemMenuData = {} },
			},
		},
		{
			itemValue = "From String",
			text = "From String",
			dropdownItemMenuData = {
				{
					itemValue = "FromStringOverwrite",
					text = "Overwrite current EP note",
					dropdownItemMenuData = {},
				},
				{ itemValue = "FromStringNew", text = "Create new EP note", dropdownItemMenuData = {} },
			},
		},
	}
	importDropdown:AddItems(importDropdownData, "EPDropdownItemToggle", true)

	local exportButton = AceGUI:Create("EPButton")
	exportButton:SetWidth(topContainerDropdownWidth)
	exportButton:SetCallback("Clicked", HandleExportEPNoteButtonClicked)
	exportButton:SetText("Export")

	bossSelectContainer:AddChild(bossDropdown)
	bossAbilitySelectContainer:AddChild(bossAbilitySelectDropdown)

	bossContainer:AddChild(bossSelectContainer)
	bossContainer:AddChild(bossAbilitySelectContainer)
	assignmentSortContainer:AddChild(assignmentSortSpacer)
	assignmentSortContainer:AddChild(assignmentSortLabel)
	assignmentSortContainer:AddChild(assignmentSortDropdown)
	editRosterContainer:AddChild(editRosterSpacer)
	editRosterContainer:AddChild(editRosterButton)
	noteContainer:AddChild(noteLabel)
	noteContainer:AddChild(noteDropdown)
	renameNoteContainer:AddChild(renameNoteLabel)
	renameNoteContainer:AddChild(renameNoteLineEdit)
	outerNoteContainer:AddChild(noteContainer)
	outerNoteContainer:AddChild(renameNoteContainer)
	noteButtonContainer:AddChild(createNewButton)
	noteButtonContainer:AddChild(deleteButton)
	importExportContainer:AddChild(importDropdown)
	importExportContainer:AddChild(exportButton)

	local topContainer = AceGUI:Create("EPContainer")
	topContainer:SetLayout("EPHorizontalLayout")
	topContainer:SetHeight(topContainerHeight)
	topContainer:SetFullWidth(true)

	topContainer:AddChild(bossContainer)
	topContainer:AddChild(assignmentSortContainer)
	topContainer:AddChild(editRosterContainer)
	topContainer:AddChild(spacer)
	topContainer:AddChild(outerNoteContainer)
	topContainer:AddChild(noteButtonContainer)
	topContainer:AddChild(importExportContainer)

	local bottomLeftContainer = AceGUI:Create("EPContainer")
	bottomLeftContainer:SetLayout("EPVerticalLayout")
	bottomLeftContainer:SetWidth(bottomLeftContainerWidth)
	bottomLeftContainer:SetSpacing(unpack(bottomLeftContainerSpacing))

	local bossAbilityContainer = AceGUI:Create("EPContainer")
	bossAbilityContainer:SetLayout("EPVerticalLayout")
	bossAbilityContainer:SetFullWidth(true)
	bossAbilityContainer:SetSpacing(0, bossAbilityPadding)

	local addAssigneeDropdown = AceGUI:Create("EPDropdown")
	addAssigneeDropdown:SetFullWidth(true)
	addAssigneeDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeDropdown:SetText("Add Assignee")
	addAssigneeDropdown:AddItems(
		utilities.CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster()),
		"EPDropdownItemToggle",
		true
	)

	local assignmentListContainer = AceGUI:Create("EPContainer")
	assignmentListContainer:SetLayout("EPVerticalLayout")
	assignmentListContainer:SetFullWidth(true)
	assignmentListContainer:SetSpacing(0, assignmentPadding)

	bottomLeftContainer:AddChild(bossAbilityContainer)
	bottomLeftContainer:AddChild(addAssigneeDropdown)
	bottomLeftContainer:AddChild(assignmentListContainer)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)

	Private.mainFrame:AddChild(topContainer)
	Private.mainFrame:AddChild(bottomLeftContainer)
	Private.mainFrame:AddChild(timeline)

	local boss = bossUtilities.GetBoss(bossName)
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.assignmentSortType,
		boss
	)
	local sortedAssignees = utilities.SortAssignees(sorted)
	interfaceUpdater.UpdateAssignmentList(sortedAssignees)
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster(), false)

	-- Set default values
	interfaceUpdater.UpdateBossAbilityList(bossName)
	interfaceUpdater.UpdateTimelineBossAbilities(bossName)
	assignmentSortDropdown:SetValue(AddOn.db.profile.assignmentSortType)
	noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
	renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)

	-- Center frame in middle of screen
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	local xPos = (screenWidth / 2) - (Private.mainFrame.frame:GetWidth() / 2)
	local yPos = -(screenHeight / 2) + (Private.mainFrame.frame:GetHeight() / 2)
	Private.mainFrame.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xPos, yPos)

	interfaceUpdater.UpdateTimelineAssignments(sorted, sortedAssignees)
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults --[[,true]])
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	local profile = self.db.profile
	if profile then
		if profile.roster then
			profile.sharedRoster = profile.roster
			profile.roster = nil
		end
		local convertToNewNoteTable = nil
		if profile.notes and type(profile.notes) == "table" then
			for _, note in pairs(profile.notes) do
				if note and type(note) == "table" then
					for _, line in pairs(note) do
						if type(line) == "string" then
							convertToNewNoteTable = true
						end
						break
					end
				end
			end
		end
		if convertToNewNoteTable then
			local newNotesTable = {}
			for noteName, stringNote in pairs(profile.notes) do
				local noteTable = {
					content = stringNote,
					roster = {},
					assignments = {},
				}
				newNotesTable[noteName] = noteTable
			end
			profile.notes = newNotesTable
		end
		for _, note in pairs(profile.notes) do
			if type(note) == "table" then
				if not note.content then
					note.content = {}
				end
				if not note.roster then
					note.roster = {}
				end
				if not note.assignments then
					note.assignments = {}
				end
			end
		end
		if not profile.activeBossAbilities then
			profile.activeBossAbilities = {}
		end

		-- Convert tables from DB into classes
		for _, note in pairs(profile.notes) do
			for _, assignment in pairs(note.assignments) do
				assignment = Private.classes.Assignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				if assignment.combatLogEventType then
					assignment = Private.classes.CombatLogEventAssignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				elseif assignment.phase then
					assignment = Private.classes.PhasedAssignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				elseif assignment.time then
					assignment = Private.classes.TimedAssignment:New(assignment)
				end
			end
		end
	end
	--self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	--self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	utilities.CreatePrettyClassNames()
	self.OnInitialize = nil
end

function AddOn:OnEnable()
	--self:Refresh()
end

function AddOn:Refresh(db, newProfile) end

-- Slash command functionality
function AddOn:SlashCommand(input)
	if DevTool then
		DevTool:AddData(Private)
	end
	if not Private.mainFrame then
		Private:CreateGUI()
	end
end

-- Loads all the set options after game loads and player enters world
function AddOn:PLAYER_ENTERING_WORLD(eventName) end
