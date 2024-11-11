---@module "NerubarPalace"
---@module "Options"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]
---@class Utilities
local utilities = Private.utilities
local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local format = format
local getmetatable = getmetatable
local GetSpellInfo = C_Spell.GetSpellInfo
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local pairs = pairs
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local unpack = unpack
local wipe = wipe

local assignmentPadding = 2
local bossAbilityPadding = 4
local bottomLeftContainerSpacing = { 0, 6 }
local bottomLeftContainerWidth = 200
local dropdownContainerLabelSpacing = { 2, 2 }
local dropdownContainerSpacing = { 2, 2 }
local noteContainerSpacing = { 5, 2 }
local topContainerDropdownWidth = 150
local topContainerHeight = 36

local currentAssignmentIndex = 0
local sortedTimelineAssignments = {} --[[@as table<integer, TimelineAssignment>]]
local emptyAssignees = {} --[[@as table<integer, string>]]
local sortedAssignees = {} --[[@as table<integer, string>]]
local uniqueAssignmentTable = {} --[[@as table<integer, Assignment>]]
local lastAssignmentSortType = "First Appearance" --[[@as AssignmentSortType]]

-- Clears and repopulates the boss ability container based on the boss name.
---@param bossName string The name of the boss
local function UpdateBossAbilityList(bossName)
	local boss = Private:GetBoss(bossName)
	local bossAbilityContainer = Private.mainFrame:GetBossAbilityContainer()
	local bossDropdown = Private.mainFrame:GetBossDropdown()
	if boss and bossAbilityContainer and bossDropdown then
		local bossIndex = Private:GetBossDefinitionIndex(bossName)
		if bossIndex and bossDropdown:GetValue() ~= bossIndex then
			bossDropdown:SetValue(bossIndex)
		end
		bossAbilityContainer:ReleaseChildren()
		for _, ID in pairs(boss.sortedAbilityIDs) do
			local abilityEntry = AceGUI:Create("EPAbilityEntry")
			abilityEntry:SetFullWidth(true)
			abilityEntry:SetAbility(ID)
			bossAbilityContainer:AddChild(abilityEntry)
		end
		bossAbilityContainer:DoLayout()
	end
end

-- Sets the boss abilities for the timeline and rerenders it.
---@param bossName string The name of the boss
local function UpdateTimelineBossAbilities(bossName)
	local boss = Private:GetBoss(bossName)
	local timeline = Private.mainFrame:GetTimeline()
	if boss and timeline then
		timeline:SetBossAbilities(boss.abilities, boss.sortedAbilityIDs, boss.phases)
		timeline:UpdateTimeline()
	end
end

-- Clears and repopulates the list of assignments based on sortedAssignees
local function UpdateAssignmentList()
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		assignmentContainer:ReleaseChildren()
		local assignmentTextTable = utilities:GetAssignmentListTextFromAssignees(sortedAssignees)
		for _, text in ipairs(assignmentTextTable) do
			local assigneeEntry = AceGUI:Create("EPAbilityEntry")
			assigneeEntry:SetText(text)
			assigneeEntry:SetHeight(30)
			assignmentContainer:AddChild(assigneeEntry)
		end
		assignmentContainer:DoLayout()
	end
end

-- Sets the assignments and assignees for the timeline and rerenders it.
local function UpdateTimelineAssignments()
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
end

-- Sorts assignments based on the assignmentSortType and updates sortedTimelineAssignments and sortedAssignees.
---@param assignments table<integer, Assignment>
---@param assignmentSortType AssignmentSortType|nil
---@param updateUniqueAssignments boolean|nil
local function SortAssignments(assignments, assignmentSortType, updateUniqueAssignments)
	if assignmentSortType then
		lastAssignmentSortType = assignmentSortType
	else
		assignmentSortType = lastAssignmentSortType
	end

	local sorted = {} --[[@as table<integer, TimelineAssignment>]]

	for _, assignment in pairs(assignments) do
		local timelineAssignment = Private.classes.TimelineAssignment:New(assignment)
		if timelineAssignment then
			tinsert(sorted, timelineAssignment)
		end
	end

	if assignmentSortType == "Alphabetical" then
		sort(sorted --[[@as table<integer, TimelineAssignment>]], function(a, b)
			return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
		end)
	elseif assignmentSortType == "First Appearance" then
		sort(sorted --[[@as table<integer, TimelineAssignment>]], function(a, b)
			if a.startTime == b.startTime then
				return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
			end
			return a.startTime < b.startTime
		end)
	elseif assignmentSortType == "Role > Alphabetical" or assignmentSortType == "Role > First Appearance" then
		local determinedRoles = utilities:DetermineRolesFromAssignments(assignments)
		sort(sorted --[[@as table<integer, TimelineAssignment>]], function(a, b)
			if determinedRoles[a.assignment.assigneeNameOrRole] == determinedRoles[b.assignment.assigneeNameOrRole] then
				if assignmentSortType == "Role > Alphabetical" then
					return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
				elseif assignmentSortType == "Role > First Appearance" then
					if a.startTime == b.startTime then
						return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
					end
					return a.startTime < b.startTime
				end
			end
			return determinedRoles[a.assignment.assigneeNameOrRole] < determinedRoles[b.assignment.assigneeNameOrRole]
		end)
	end

	sortedTimelineAssignments = sorted
	sortedAssignees = utilities:SortAssignees(sortedTimelineAssignments, emptyAssignees)
	if updateUniqueAssignments then
		wipe(uniqueAssignmentTable)
		for _, ass in pairs(Private.assignments) do
			uniqueAssignmentTable[ass.uniqueID] = ass
		end
	end
end

---@param value number|string
local function HandleBossDropdownValueChanged(value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local bossIndex = tonumber(value)
	if bossIndex then
		local bossDef = Private:GetBossDefinition(bossIndex)
		if bossDef then
			UpdateBossAbilityList(bossDef.name)
			UpdateTimelineBossAbilities(bossDef.name)
		end
	end
end

---@param value string
local function HandleAssignmentSortDropdownValueChanged(_, _, value)
	AddOn.db.profile.assignmentSortType = value
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
end

---@param value string
local function HandleNoteDropdownValueChanged(_, _, value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	AddOn.db.profile.lastOpenNote = value
	local bossName = Private:Note(AddOn.db.profile.lastOpenNote)
	if bossName then
		UpdateBossAbilityList(bossName)
		UpdateTimelineBossAbilities(bossName)
	end
	wipe(emptyAssignees)
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
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
		noteDropdown:EditItemText(currentNoteName, currentNoteName, value, value)
	end
end

local function HandleAssignmentEditorDeleteButtonClicked()
	Private.assignmentEditor:Release()
	local assignmentToRemove = uniqueAssignmentTable[currentAssignmentIndex]
	currentAssignmentIndex = 0
	for i, v in pairs(Private.assignments) do
		if v == assignmentToRemove then
			tremove(Private.assignments, i)
			break
		end
	end
	tremove(uniqueAssignmentTable, currentAssignmentIndex)
	SortAssignments(Private.assignments)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
end

local function HandleAssignmentEditorOkayButtonClicked()
	Private.assignmentEditor:Release()
	SortAssignments(Private.assignments)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
end

---@param dataType string
---@param value string
local function HandleAssignmentEditorDataChanged(_, _, dataType, value)
	local assignment = uniqueAssignmentTable[currentAssignmentIndex] --[[@as Assignment]]
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

	for _, timelineAssignment in pairs(sortedTimelineAssignments) do
		if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
			timelineAssignment:Update()
			break
		end
	end
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:UpdateTimeline()
	end
end

---@param uniqueID integer
local function HandleTimelineAssignmentClicked(_, _, uniqueID)
	currentAssignmentIndex = uniqueID
	if not Private.assignmentEditor then
		Private.assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		Private.assignmentEditor.obj = Private.mainFrame
		Private.assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.assignmentEditor.frame:SetFrameLevel(10)
		Private.assignmentEditor.frame:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
		Private.assignmentEditor:SetLayout("EPVerticalLayout")
		Private.assignmentEditor:DoLayout()

		Private.assignmentEditor:SetCallback("OnRelease", function()
			Private.assignmentEditor = nil
		end)
		Private.assignmentEditor:SetCallback("DataChanged", HandleAssignmentEditorDataChanged)
		Private.assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
		Private.assignmentEditor:SetCallback("OkayButtonClicked", HandleAssignmentEditorOkayButtonClicked)
		Private.assignmentEditor.spellAssignmentDropdown:AddItems(
			utilities:CreateSpellAssignmentDropdownItems(),
			"EPDropdownItemToggle"
		)
		Private.assignmentEditor.assigneeTypeDropdown:AddItems(
			utilities:CreateAssignmentTypeDropdownItems(),
			"EPDropdownItemToggle"
		)
		local assigneeDropdownItems = utilities:CreateAssigneeDropdownItems()
		Private.assignmentEditor.assigneeDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		Private.assignmentEditor.targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		local dropdownItems = {}
		local boss = Private:GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossDropdown():GetValue())
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
	end

	local assignment = uniqueAssignmentTable[currentAssignmentIndex]

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
	for _, assigneeNameOrRole in ipairs(sortedAssignees) do
		if assigneeNameOrRole == value then
			alreadyExists = true
			break
		end
	end
	if not alreadyExists then
		for _, emptyAssignee in ipairs(emptyAssignees) do
			if emptyAssignee == value then
				alreadyExists = true
				break
			end
		end
		if not alreadyExists then
			tinsert(emptyAssignees, value)
			SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
			UpdateAssignmentList()
			UpdateTimelineAssignments()
		end
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
		tinsert(Private.assignments, combatLogEventAssignment)
		-- end
		-- elseif abilityInstance.repeatInstance then
	else
		local timedAssignment = Private.classes.TimedAssignment:New(assignment)
		timedAssignment.time = abilityInstance.castTime
		tinsert(Private.assignments, timedAssignment)
	end
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
end

local function HandleCreateNewEPNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local newNoteName = Private.utilities:CreateUniqueNoteName()
	Private:Note(newNoteName)
	AddOn.db.profile.lastOpenNote = newNoteName
	wipe(emptyAssignees)
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
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
				local bossName = Private:Note(AddOn.db.profile.lastOpenNote)
				if bossName then
					UpdateBossAbilityList(bossName)
					UpdateTimelineBossAbilities(bossName)
				end
				break
			end
		else
			local newNoteName = utilities:CreateUniqueNoteName()
			Private:Note(newNoteName)
			AddOn.db.profile.lastOpenNote = newNoteName
		end
		noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
		local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
		if renameNoteLineEdit then
			renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)
		end
		wipe(emptyAssignees)
		SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)
		UpdateAssignmentList()
		UpdateTimelineAssignments()
	end
end

---@param importDropdown EPDropdown
---@param value any
local function HandleImportMRTNoteDropdownValueChanged(importDropdown, _, value)
	if value == "Import MRT note" then
		return
	end
	local bossName = nil
	if value == "Override current EP note" then
		bossName = Private:Note(AddOn.db.profile.lastOpenNote, true)
	elseif value == "Create new EP note" then
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		local newNoteName = utilities:CreateUniqueNoteName()
		bossName = Private:Note(newNoteName, true)
		AddOn.db.profile.lastOpenNote = newNoteName
		local noteDropdown = Private.mainFrame:GetNoteDropdown()
		if noteDropdown then
			noteDropdown:AddItem(newNoteName, newNoteName, "EPDropdownItemToggle")
			noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
		end
		local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
		if renameNoteLineEdit then
			renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)
		end
	end
	if bossName then
		UpdateBossAbilityList(bossName)
		UpdateTimelineBossAbilities(bossName)
	end

	wipe(emptyAssignees)
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)
	UpdateAssignmentList()
	UpdateTimelineAssignments()
	importDropdown:SetText("Import MRT note")
end

local function HandleExportEPNoteButtonClicked()
	-- TODO: Open editbox widget with current note
end

function Private:CreateGUI()
	local bossName = nil
	if AddOn.db.profile.lastOpenNote and AddOn.db.profile.lastOpenNote ~= "" then
		local noteName = AddOn.db.profile.lastOpenNote
		bossName = Private:Note(noteName)
	else
		if not IsAddOnLoaded("MRT") then
			print(AddOnName, "No note was loaded due to MRT not being installed.")
			return
		end
		local defualtNoteName = "SharedMRTNote"
		bossName = Private:Note(defualtNoteName, true)
		AddOn.db.profile.lastOpenNote = defualtNoteName
	end

	Private.mainFrame = AceGUI:Create("EPMainFrame")

	Private.mainFrame:SetLayout("EPContentFrameLayout")
	Private.mainFrame:SetCallback("OnRelease", function()
		Private.mainFrame = nil
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
	end)

	wipe(emptyAssignees)
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType, true)

	local bossContainer = AceGUI:Create("EPContainer")
	bossContainer:SetLayout("EPVerticalLayout")
	bossContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetText("Boss:")
	bossLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

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

	local assignmentSortContainer = AceGUI:Create("EPContainer")
	assignmentSortContainer:SetLayout("EPVerticalLayout")
	assignmentSortContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local assignmentSortLabel = AceGUI:Create("EPLabel")
	assignmentSortLabel:SetText("Assignment Sort Priority:")
	assignmentSortLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

	local assignmentSortDropdown = AceGUI:Create("EPDropdown")
	assignmentSortDropdown:SetWidth(topContainerDropdownWidth)
	assignmentSortDropdown:AddItems({
		{ itemValue = "Alphabetical", text = "Alphabetical", dropdownItemMenuData = {} },
		{ itemValue = "First Appearance", text = "First Appearance", dropdownItemMenuData = {} },
		{ itemValue = "Role > Alphabetical", text = "Role > Alphabetical", dropdownItemMenuData = {} },
		{ itemValue = "Role > First Appearance", text = "Role > First Appearance", dropdownItemMenuData = {} },
	}, "EPDropdownItemToggle")
	assignmentSortDropdown:SetCallback("OnValueChanged", HandleAssignmentSortDropdownValueChanged)

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
	importDropdown:SetText("Import MRT note")
	importDropdown:AddItem("Override current EP note", "Override current EP note", "EPDropdownItemToggle", nil, true)
	importDropdown:AddItem("Create new EP note", "Create new EP note", "EPDropdownItemToggle", nil, true)

	local exportButton = AceGUI:Create("EPButton")
	exportButton:SetWidth(topContainerDropdownWidth)
	exportButton:SetCallback("Clicked", HandleExportEPNoteButtonClicked)
	exportButton:SetText("Export EP note")

	bossContainer:AddChild(bossLabel)
	bossContainer:AddChild(bossDropdown)
	assignmentSortContainer:AddChild(assignmentSortLabel)
	assignmentSortContainer:AddChild(assignmentSortDropdown)
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

	local addAssigneeRowDropdown = AceGUI:Create("EPDropdown")
	addAssigneeRowDropdown:SetFullWidth(true)
	addAssigneeRowDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeRowDropdown:SetText("Add Assignee")
	addAssigneeRowDropdown:AddItems(
		utilities:CreateAssignmentTypeWithRosterDropdownItems(),
		"EPDropdownItemToggle",
		true
	)

	local assignmentListContainer = AceGUI:Create("EPContainer")
	assignmentListContainer:SetLayout("EPVerticalLayout")
	assignmentListContainer:SetFullWidth(true)
	assignmentListContainer:SetSpacing(0, assignmentPadding)

	bottomLeftContainer:AddChild(bossAbilityContainer)
	bottomLeftContainer:AddChild(addAssigneeRowDropdown)
	bottomLeftContainer:AddChild(assignmentListContainer)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)

	Private.mainFrame:AddChild(topContainer)
	Private.mainFrame:AddChild(bottomLeftContainer)
	Private.mainFrame:AddChild(timeline)

	UpdateAssignmentList()

	-- Set default values
	UpdateBossAbilityList(bossName or "Ulgrax the Devourer")
	UpdateTimelineBossAbilities(bossName or "Ulgrax the Devourer")
	assignmentSortDropdown:SetValue(AddOn.db.profile.assignmentSortType)
	noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
	renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)

	-- Center frame in middle of screen
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	local xPos = (screenWidth / 2) - (Private.mainFrame.frame:GetWidth() / 2)
	local yPos = -(screenHeight / 2) + (Private.mainFrame.frame:GetHeight() / 2)
	Private.mainFrame.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xPos, yPos)

	UpdateTimelineAssignments()
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	utilities:CreatePrettyClassNames()
	self.OnInitialize = nil
end

function AddOn:OnEnable()
	self:Refresh()
end

function AddOn:Refresh() end

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
