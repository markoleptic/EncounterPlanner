---@module "NerubarPalace"
---@module "Options"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local format = format
local GetClassColor = C_ClassColor.GetClassColor
local GetSpellInfo = C_Spell.GetSpellInfo
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local min = math.min
local pairs = pairs
local rawget = rawget
local rawset = rawset
local getmetatable = getmetatable
local setmetatable = setmetatable
local tremove = tremove
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local type = type
local unpack = unpack
local wipe = wipe

local bossAbilityPadding = 4
local assignmentPadding = 2
local paddingBetweenBossAbilitiesAndAssignments = 36
local bottomLeftContainerWidth = 200
local topContainerDropdownWidth = 150
local topContainerHeight = 36
local dropdownContainerSpacing = { 2, 2 }
local dropdownContainerLabelSpacing = { 2, 2 }
local noteContainerSpacing = { 5, 2 }

local currentAssignmentIndex = 0
local sortedTimelineAssignments = {} --[[@as table<integer, TimelineAssignment>]]
local emptyAssignees = {} --[[@as table<integer, string>]]
local sortedAssignees = {} --[[@as table<integer, string>]]
local uniqueAssignmentTable = {} --[[@as table<integer, Assignment>]]
local lastAssignmentSortType = "First Appearance" --[[@as AssignmentSortType]]

local function CreatePrettyClassNames()
	wipe(Private.prettyClassNames)
	setmetatable(Private.prettyClassNames, {
		__index = function(tbl, key)
			if type(key) == "string" then
				key = key:lower()
			end
			return rawget(tbl, key)
		end,
		__newindex = function(tbl, key, value)
			if type(key) == "string" then
				key = key:lower()
			end
			rawset(tbl, key, value)
		end,
	})
	for className, _ in pairs(Private.spellDB.classes) do
		local colorMixin = GetClassColor(className)
		local pascalCaseClassName
		if className == "DEATHKNIGHT" then
			pascalCaseClassName = "Death Knight"
		elseif className == "DEMONHUNTER" then
			pascalCaseClassName = "Demon Hunter"
		else
			pascalCaseClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		local prettyClassName = colorMixin:WrapTextInColorCode(pascalCaseClassName)
		if className == "DEATHKNIGHT" then
			Private.prettyClassNames["Death Knight"] = prettyClassName
		elseif className == "DEMONHUNTER" then
			Private.prettyClassNames["Demon Hunter"] = prettyClassName
		end
		Private.prettyClassNames[className] = prettyClassName
	end
end

---@return string
local function CreateUniqueNoteName()
	local newNoteName = "Unnamed"
	local num = 2
	while AddOn.db.profile.notes[newNoteName] do
		newNoteName = newNoteName:sub(1, 7) .. num
		num = num + 1
	end
	return newNoteName
end

-- Creates a timeline assignment from an assignment and calculates the start time of the timeline assignment.
---@param assignment Assignment
---@return TimelineAssignment|nil
local function CreateTimelineAssignment(assignment)
	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = Private:FindBossAbility(assignment.combatLogEventSpellID)
		if ability then
			local startTime = assignment.time or 0 -- TODO: Implement combat log events with no time
			if assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SCS" then
				for i = 1, min(assignment.spellCount, #ability.phases[1].castTimes) do
					startTime = startTime + ability.phases[1].castTimes[i]
				end
			end
			if assignment.combatLogEventType == "SCC" then
				startTime = startTime + ability.castTime
			end
			-- TODO: Implement other combat log event types
			return Private.classes.TimelineAssignment:new({
				assignment = assignment,
				startTime = startTime,
				order = 0,
			})
		end
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		return Private.classes.TimelineAssignment:new({
			assignment = assignment,
			startTime = assignment.time,
			order = 0,
		})
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		local boss = Private:GetBoss("Broodtwister Ovi'nax")
		if boss then
			local totalOccurances = 0
			for _, phaseData in pairs(boss.phases) do
				totalOccurances = totalOccurances + phaseData.count
			end
			local currentPhase = 1
			local bossPhaseOrder = {}
			local runningStartTime = 0
			while #bossPhaseOrder < totalOccurances and currentPhase ~= nil do
				tinsert(bossPhaseOrder, currentPhase)
				if currentPhase == assignment.phase then
					-- TODO: This should maybe return an array
					return Private.classes.TimelineAssignment:new({
						assignment = assignment,
						startTime = runningStartTime,
						order = 0,
					})
				end
				runningStartTime = runningStartTime + boss.phases[currentPhase].duration
				currentPhase = boss.phases[currentPhase].repeatAfter
			end
		end
	end
	return nil
end

-- Updates a timeline assignment's start time
---@param timelineAssignment TimelineAssignment
local function UpdateTimelineAssignment(timelineAssignment)
	local assignment = timelineAssignment.assignment
	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = Private:FindBossAbility(assignment.combatLogEventSpellID)
		local startTime = assignment.time
		if ability and startTime then
			if assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SCS" then
				for i = 1, min(assignment.spellCount, #ability.phases[1].castTimes) do
					startTime = startTime + ability.phases[1].castTimes[i]
				end
			end
			if assignment.combatLogEventType == "SCC" then
				startTime = startTime + ability.castTime
			end
			timelineAssignment.startTime = startTime
		end
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		timelineAssignment.startTime = assignment.time
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		local boss = Private:GetBoss("Broodtwister Ovi'nax")
		if boss then
			local totalOccurances = 0
			for _, phaseData in pairs(boss.phases) do
				totalOccurances = totalOccurances + phaseData.count
			end
			local currentPhase = 1
			local bossPhaseOrder = {}
			local runningStartTime = 0
			while #bossPhaseOrder < totalOccurances and currentPhase ~= nil do
				tinsert(bossPhaseOrder, currentPhase)
				if currentPhase == assignment.phase then
					timelineAssignment.startTime = runningStartTime
					return
				end
				runningStartTime = runningStartTime + boss.phases[currentPhase].duration
				currentPhase = boss.phases[currentPhase].repeatAfter
			end
		end
	end
end

-- Updates the order of timeline assignments based on sortedTimelineAssignments
local function CreateAssigneeOrder()
	local order = 1
	local assigneeMap = {}
	local assigneeOrder = {}

	sort(emptyAssignees, function(a, b)
		return a < b
	end)

	for _, entry in ipairs(emptyAssignees) do
		if not assigneeMap[entry] then
			assigneeMap[entry] = order
			assigneeOrder[order] = entry
			order = order + 1
		end
	end

	for _, entry in ipairs(sortedTimelineAssignments) do
		local assignee = entry.assignment.assigneeNameOrRole
		if not assigneeMap[assignee] then
			assigneeMap[assignee] = order
			assigneeOrder[order] = assignee
			order = order + 1
		end
		entry.order = assigneeMap[assignee]
	end

	return assigneeOrder
end

---@param assignments table<integer, Assignment>
local function DetermineRolesFromAssignments(assignments)
	local assigneeAssignments = {}
	local healerClasses =
		{ ["DRUID"] = 1, ["EVOKER"] = 1, ["MONK"] = 1, ["PALADIN"] = 1, ["PRIEST"] = 1, ["SHAMAN"] = 1 }
	for _, assignment in pairs(assignments) do
		local assignee = assignment.assigneeNameOrRole
		if not assigneeAssignments[assignee] then
			assigneeAssignments[assignee] = {}
		end
		tinsert(assigneeAssignments[assignee], assignment)
	end
	local determinedRoles = {}
	for assignee, currentAssigneeAssignments in pairs(assigneeAssignments) do
		for _, currentAssigneeAssignment in pairs(currentAssigneeAssignments) do
			if determinedRoles[assignee] then
				break
			end
			local spellID = currentAssigneeAssignment.spellInfo.spellID
			if spellID == 98008 or spellID == 108280 then -- Shaming healing bc classified as raid defensive
				determinedRoles[assignee] = 0
				break
			end
			for className, classData in pairs(Private.spellDB.classes) do
				if determinedRoles[assignee] then
					break
				end
				for _, spellInfo in pairs(classData) do
					if spellInfo["spellID"] == spellID then
						if spellInfo["type"] == "heal" and healerClasses[className] then
							determinedRoles[assignee] = 0
							break
						end
					end
				end
			end
		end
		if not determinedRoles[assignee] then
			determinedRoles[assignee] = 1
		end
	end
	return determinedRoles
end

---@param data table<integer, DropdownItemData>
local function SortDropdownDataByItemValue(data)
	-- Sort the top-level table
	sort(data, function(a, b)
		local itemValueA = a.itemValue
		local itemValueB = b.itemValue
		if type(itemValueA) == "number" then
			local spellName = a.text:match("|T.-|t%s(.+)")
			if spellName then
				itemValueA = spellName
			end
		end
		if type(itemValueB) == "number" then
			local spellName = b.text:match("|T.-|t%s(.+)")
			if spellName then
				itemValueB = spellName
			end
		end
		return itemValueA < itemValueB
	end)

	-- Recursively sort any nested dropdownItemMenuData tables
	for _, item in pairs(data) do
		if item.dropdownItemMenuData and #item.dropdownItemMenuData > 0 then
			SortDropdownDataByItemValue(item.dropdownItemMenuData)
		end
	end
end

---@return DropdownItemData
local function CreateSpellDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for className, classSpells in pairs(Private.spellDB.classes) do
		local classDropdownData = {
			itemValue = className,
			text = Private.prettyClassNames[className],
			dropdownItemMenuData = {},
		}
		local spellTypeIndex = 1
		local spellTypeIndexMap = {}
		for _, spell in pairs(classSpells) do
			if not spellTypeIndexMap[spell["type"]] then
				classDropdownData.dropdownItemMenuData[spellTypeIndex] = {
					itemValue = spell["type"],
					text = spell["type"],
					dropdownItemMenuData = {},
				}
				spellTypeIndexMap[spell["type"]] = spellTypeIndex
				spellTypeIndex = spellTypeIndex + 1
			end
			local iconText = format("|T%s:16|t %s", spell["icon"], spell["name"])
			local spellID = spell["commonSpellID"] or spell["spellID"]
			tinsert(classDropdownData.dropdownItemMenuData[spellTypeIndexMap[spell["type"]]].dropdownItemMenuData, {
				itemValue = spellID,
				text = iconText,
				dropdownItemMenuData = {},
			})
		end
		tinsert(dropdownItems, classDropdownData)
	end
	SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Class", text = "Class", dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
local function CreateRacialDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for _, racialInfo in pairs(Private.spellDB.other["RACIAL"]) do
		local iconText = format("|T%s:16|t %s", racialInfo["icon"], racialInfo["name"])
		tinsert(dropdownItems, {
			itemValue = racialInfo["spellID"],
			text = iconText,
			dropdownItemMenuData = {},
		})
	end
	SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Racial", text = "Racial", dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
local function CreateTrinketDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for _, trinketInfo in pairs(Private.spellDB.other["TRINKET"]) do
		local iconText = format("|T%s:16|t %s", trinketInfo["icon"], trinketInfo["name"])
		tinsert(dropdownItems, {
			itemValue = trinketInfo["spellID"],
			text = iconText,
			dropdownItemMenuData = {},
		})
	end
	SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Trinket", text = "Trinket", dropdownItemMenuData = dropdownItems }
end

---@return table<integer, DropdownItemData>
local function CreateAssignmentTypeDropdownItems()
	local assignmentTypes = {
		{
			text = "Group",
			itemValue = "Group",
			dropdownItemMenuData = {
				{
					text = "Everyone",
					itemValue = "{everyone}",
					dropdownItemMenuData = {},
				},
				{
					text = "Role",
					itemValue = "Role",
					dropdownItemMenuData = {
						{
							text = "Damagers",
							itemValue = "role:damager",
							dropdownItemMenuData = {},
						},
						{
							text = "Healers",
							itemValue = "role:healer",
							dropdownItemMenuData = {},
						},
						{
							text = "Tanks",
							itemValue = "role:tank",
							dropdownItemMenuData = {},
						},
					},
				},
				{
					text = "Group Number",
					itemValue = "Group Number",
					dropdownItemMenuData = {
						{
							text = "1",
							itemValue = "group:1",
							dropdownItemMenuData = {},
						},
						{
							text = "2",
							itemValue = "group:2",
							dropdownItemMenuData = {},
						},
						{
							text = "3",
							itemValue = "group:3",
							dropdownItemMenuData = {},
						},
						{
							text = "4",
							itemValue = "group:4",
							dropdownItemMenuData = {},
						},
					},
				},
			},
		},
		{
			text = "Individual",
			itemValue = "Individual",
			dropdownItemMenuData = {},
		},
		-- {
		-- 	text = "Personal",
		-- 	itemValue = "Personal",
		-- 	dropdownItemMenuData = {}
		-- }
	} --[[@as table<integer, DropdownItemData>]]

	local classAssignmentTypes = {
		text = "Class",
		itemValue = "Class",
		dropdownItemMenuData = {},
	} --[[@as DropdownItemData]]

	for className, _ in pairs(Private.spellDB.classes) do
		local actualClassName
		if className == "DEATHKNIGHT" then
			actualClassName = "DeathKnight"
		elseif className == "DEMONHUNTER" then
			actualClassName = "DemonHunter"
		else
			actualClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		local classDropdownData = {
			itemValue = "class:" .. actualClassName:gsub("%s", ""),
			text = Private.prettyClassNames[className],
			dropdownItemMenuData = {},
		}
		tinsert(classAssignmentTypes.dropdownItemMenuData, classDropdownData)
	end

	tinsert(assignmentTypes, classAssignmentTypes)

	SortDropdownDataByItemValue(assignmentTypes)
	return assignmentTypes
end

---@return table<integer, DropdownItemData>
local function CreateAssignmentTypeWithRosterDropdownItems()
	local assignmentTypes = CreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	for normalName, colorName in pairs(Private.roster) do
		local memberDropdownData = {
			itemValue = normalName,
			text = colorName,
			dropdownItemMenuData = {},
		}
		tinsert(assignmentTypes[individualIndex].dropdownItemMenuData, memberDropdownData)
	end

	SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	return assignmentTypes
end

---@return table<integer, DropdownItemData>
local function CreateAssigneeDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]

	for name, coloredName in pairs(Private.roster) do
		tinsert(dropdownItems, {
			itemValue = name,
			text = coloredName,
			dropdownItemMenuData = {},
		})
	end

	SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

-- Clears and repopulates the list of assignments based on sortedAssignees
local function UpdateAssignmentListEntries()
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		assignmentContainer:ReleaseChildren()
		for index = 1, #sortedAssignees do
			local abilityEntryText
			local assigneeNameOrRole = sortedAssignees[index]
			if assigneeNameOrRole == "{everyone}" then
				abilityEntryText = "Everyone"
			else
				local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
				local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
				local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
				if classMatch then
					local prettyClassName = Private.prettyClassNames[classMatch]
					if prettyClassName then
						abilityEntryText = prettyClassName
					else
						abilityEntryText = classMatch:sub(1, 1):upper() .. classMatch:sub(2):lower()
					end
				elseif roleMatch then
					abilityEntryText = roleMatch:sub(1, 1):upper() .. roleMatch:sub(2):lower()
				elseif groupMatch then
					abilityEntryText = "Group " .. groupMatch
				else
					abilityEntryText = Private.roster[sortedAssignees[index]]
				end
			end
			local assigneeEntry = AceGUI:Create("EPAbilityEntry")
			assigneeEntry:SetText(abilityEntryText)
			assigneeEntry:SetHeight(30)
			assignmentContainer:AddChild(assigneeEntry)
		end
		assignmentContainer:DoLayout()
	end
end

-- Clears and repopulates the boss ability container based on the boss name.
---@param bossName string The name of the boss
local function UpdateCurrentBoss(bossName)
	local boss = Private:GetBoss(bossName)
	local bossAbilityContainer = Private.mainFrame:GetBossAbilityContainer()
	local timeline = Private.mainFrame:GetTimeline()
	local bossDropdown = Private.mainFrame:GetBossDropdown()
	if boss and bossAbilityContainer and timeline and bossDropdown then
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
		timeline:SetBossAbilities(boss.abilities, boss.sortedAbilityIDs, boss.phases)
		timeline:UpdateTimeline()
	end
end

-- Sorts assignments based on the assignmentSortType and updates firstAppearanceSortedAssignments and
-- firstAppearanceAssigneeOrder
---@param assignments table<integer, Assignment>
---@param assignmentSortType AssignmentSortType|nil
local function SortAssignments(assignments, assignmentSortType)
	if assignmentSortType then
		lastAssignmentSortType = assignmentSortType
	else
		assignmentSortType = lastAssignmentSortType
	end

	local sorted = {} --[[@as table<integer, TimelineAssignment>]]

	for _, assignment in pairs(assignments) do
		local timelineAssignment = CreateTimelineAssignment(assignment)
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
		local determinedRoles = DetermineRolesFromAssignments(assignments)
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
	sortedAssignees = CreateAssigneeOrder()
end

-- Clears and updates the uniqueAssignmentTable from Private.assignments
local function UpdateUniqueAssignmentTable()
	wipe(uniqueAssignmentTable)
	for _, ass in pairs(Private.assignments) do
		uniqueAssignmentTable[ass.uniqueID] = ass
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
			UpdateCurrentBoss(bossDef.name)
		end
	end
end

---@param value string
local function HandleAssignmentSortDropdownValueChanged(_, _, value)
	AddOn.db.profile.assignmentSortType = value
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateAssignmentListEntries()

	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
end

---@param value string
local function HandleNoteDropdownValueChanged(_, _, value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	AddOn.db.profile.lastOpenNote = value
	local bossName = Private:Note(AddOn.db.profile.lastOpenNote)
	if bossName then
		UpdateCurrentBoss(bossName)
	end
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateUniqueAssignmentTable()
	UpdateAssignmentListEntries()

	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
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
	UpdateAssignmentListEntries()

	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
end

local function HandleAssignmentEditorOkayButtonClicked()
	SortAssignments(Private.assignments)
	UpdateAssignmentListEntries()

	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
end

---@param dataType string
---@param value string
local function HandleAssignmentEditorDataChanged(_, _, dataType, value)
	local assignment = uniqueAssignmentTable[currentAssignmentIndex] --[[@as Assignment]]
	if dataType == "AssignmentType" then
		if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
			if getmetatable(assignment) ~= Private.classes.CombatLogEventAssignment then
				assignment = Private.classes.CombatLogEventAssignment:new(assignment)
			end
		elseif value == "Absolute Time" then
			if getmetatable(assignment) ~= Private.classes.TimedAssignment then
				assignment = Private.classes.TimedAssignment:new(assignment)
			end
		elseif value == "Boss Phase" then
			if getmetatable(assignment) ~= Private.classes.PhasedAssignment then
				assignment = Private.classes.PhasedAssignment:new(assignment)
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
			UpdateTimelineAssignment(timelineAssignment)
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
			{ CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() },
			"EPDropdownItemToggle"
		)
		Private.assignmentEditor.assigneeTypeDropdown:AddItems(
			CreateAssignmentTypeDropdownItems(),
			"EPDropdownItemToggle"
		)
		Private.assignmentEditor.assigneeDropdown:AddItems(CreateAssigneeDropdownItems(), "EPDropdownItemToggle")
		Private.assignmentEditor.targetDropdown:AddItems(CreateAssigneeDropdownItems(), "EPDropdownItemToggle")
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
		Private.assignmentEditor.phaseNumberDropdown:SetValue(assignment.phase)
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
			UpdateAssignmentListEntries()

			local timeline = Private.mainFrame:GetTimeline()
			if timeline then
				timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
				timeline:UpdateTimeline()
			end
		end
	end

	dropdown:SetText("Add Assignee")
end

---@param abilityInstance BossAbilityInstance
---@param assigneeIndex integer
local function HandleCreateNewAssignment(_, _, abilityInstance, assigneeIndex)
	print(
		abilityInstance.spellID,
		abilityInstance.phase,
		abilityInstance.phaseCastTime,
		abilityInstance.triggerSpellID,
		abilityInstance.castOccurance,
		abilityInstance.repeatInstance,
		abilityInstance.castOccuranceRepeatInstance
	)
	if sortedAssignees[assigneeIndex] then
		print(sortedAssignees[assigneeIndex])
	end
	-- TODO: Find the boss ability using abilityInstance to create a new assignment and open assignment editor
end

local function HandleCreateNewEPNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local newNoteName = CreateUniqueNoteName()
	Private:Note(newNoteName)
	AddOn.db.profile.lastOpenNote = newNoteName
	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateUniqueAssignmentTable()
	UpdateAssignmentListEntries()
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
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
					UpdateCurrentBoss(bossName)
				end
				break
			end
		else
			local newNoteName = CreateUniqueNoteName()
			Private:Note(newNoteName)
			AddOn.db.profile.lastOpenNote = newNoteName
		end
		noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
		local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
		if renameNoteLineEdit then
			renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)
		end
		SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
		UpdateUniqueAssignmentTable()
		UpdateAssignmentListEntries()
		local timeline = Private.mainFrame:GetTimeline()
		if timeline then
			timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
			timeline:UpdateTimeline()
		end
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
		local newNoteName = CreateUniqueNoteName()
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
		UpdateCurrentBoss(bossName)
	end

	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateUniqueAssignmentTable()
	UpdateAssignmentListEntries()
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
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

	SortAssignments(Private.assignments, AddOn.db.profile.assignmentSortType)
	UpdateUniqueAssignmentTable()

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
	bottomLeftContainer:SetSpacing(0, 6)

	local bossAbilityContainer = AceGUI:Create("EPContainer")
	bossAbilityContainer:SetLayout("EPVerticalLayout")
	bossAbilityContainer:SetFullWidth(true)
	bossAbilityContainer:SetSpacing(0, bossAbilityPadding)

	local addAssigneeRowDropdown = AceGUI:Create("EPDropdown")
	addAssigneeRowDropdown:SetFullWidth(true)
	addAssigneeRowDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeRowDropdown:SetText("Add Assignee")
	addAssigneeRowDropdown:AddItems(CreateAssignmentTypeWithRosterDropdownItems(), "EPDropdownItemToggle", true)

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

	UpdateAssignmentListEntries()

	-- Set default values
	UpdateCurrentBoss(bossName or "Ulgrax the Devourer")
	timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
	assignmentSortDropdown:SetValue(AddOn.db.profile.assignmentSortType)
	noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
	renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)

	-- Center frame in middle of screen
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	local xPos = (screenWidth / 2) - (Private.mainFrame.frame:GetWidth() / 2)
	local yPos = -(screenHeight / 2) + (Private.mainFrame.frame:GetHeight() / 2)
	Private.mainFrame.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xPos, yPos)

	timeline:UpdateTimeline()
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	CreatePrettyClassNames()
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
