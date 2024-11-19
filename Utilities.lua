--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local GetClassColor = C_ClassColor.GetClassColor
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local ipairs = ipairs
local pairs = pairs
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local sort = table.sort
local tinsert = table.insert
local type = type
local UnitClass = UnitClass
local UnitName = UnitName
local wipe = table.wipe

local lineMatchRegex = "([^\r\n]+)"
local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"

---@param notes table<integer, EncounterPlannerDbNote>
---@return string
function Utilities.CreateUniqueNoteName(notes)
	local newNoteName = "Unnamed"
	local num = 2
	if notes then
		while notes[newNoteName] do
			newNoteName = newNoteName:sub(1, 7) .. num
			num = num + 1
		end
	end
	return newNoteName
end

---@param assignments table<integer, Assignment>
---@param ID integer
---@return Assignment|nil
function Utilities.FindAssignmentByUniqueID(assignments, ID)
	for _, assignment in pairs(assignments) do
		if assignment.uniqueID == ID then
			return assignment
		end
	end
end

function Utilities.CreatePrettyClassNames()
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
	Utilities.SortDropdownDataByItemValue(dropdownItems)
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
	Utilities.SortDropdownDataByItemValue(dropdownItems)
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
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Trinket", text = "Trinket", dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
function Utilities.CreateSpellAssignmentDropdownItems()
	return { CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() }
end

---@return table<integer, DropdownItemData>
function Utilities.CreateClassDropdownItemData()
	local dropdownData = {}

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
		tinsert(dropdownData, classDropdownData)
	end

	Utilities.SortDropdownDataByItemValue(dropdownData)
	return dropdownData
end

---@return table<integer, DropdownItemData>
function Utilities.CreateAssignmentTypeDropdownItems()
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
							text = "Damager",
							itemValue = "role:damager",
							dropdownItemMenuData = {},
						},
						{
							text = "Healer",
							itemValue = "role:healer",
							dropdownItemMenuData = {},
						},
						{
							text = "Tank",
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
	} --[[@as table<integer, DropdownItemData>]]

	local classAssignmentTypes = {
		text = "Class",
		itemValue = "Class",
		dropdownItemMenuData = Utilities.CreateClassDropdownItemData(),
	}

	tinsert(assignmentTypes, classAssignmentTypes)

	Utilities.SortDropdownDataByItemValue(assignmentTypes)
	return assignmentTypes
end

-- Creates dropdown data with all assignments types including individual roster members.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to character names from
---@return table<integer, DropdownItemData>
function Utilities.CreateAssignmentTypeWithRosterDropdownItems(roster)
	local assignmentTypes = Utilities.CreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	if individualIndex and roster then
		for normalName, rosterTable in pairs(roster) do
			local memberDropdownData = {
				itemValue = normalName,
				text = rosterTable.classColoredName or normalName,
				dropdownItemMenuData = {},
			}
			tinsert(assignmentTypes[individualIndex].dropdownItemMenuData, memberDropdownData)
		end

		Utilities.SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	end
	return assignmentTypes
end

---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return table<integer, DropdownItemData>
function Utilities.CreateAssigneeDropdownItems(roster)
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	if roster then
		for normalName, rosterTable in pairs(roster) do
			tinsert(dropdownItems, {
				itemValue = normalName,
				text = rosterTable.classColoredName or normalName,
				dropdownItemMenuData = {},
			})
		end
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

-- Sorts the assignees based on the order of the timeline assignments.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@return table<integer, string>
function Utilities.SortAssignees(sortedTimelineAssignments)
	local order = 1
	local assigneeMap = {}
	local assigneeOrder = {}

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

-- Creates a table of sorted TimelineAssignments and sets the start time used for each assignment on the timeline. Sorts
-- assignments based on the assignmentSortType.
---@param assignments table<integer, Assignment> Assignments to sort
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@param boss Boss? Used to get boss timers to set the proper timeline assignment start time for combat log assignments
---@return table<integer, TimelineAssignment>
function Utilities.SortAssignments(assignments, roster, assignmentSortType, boss)
	local sorted = {} --[[@as table<integer, TimelineAssignment>]]
	local bossPhaseTable = nil
	if boss then
		bossPhaseTable = bossUtilities.CreateBossPhaseTable(boss)
	end

	local allSucceeded = true
	for _, assignment in pairs(assignments) do
		local timelineAssignment = Private.classes.TimelineAssignment:New(assignment)
		local success = Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, boss, bossPhaseTable)
		if success == false and allSucceeded == true then
			allSucceeded = false
		end
		tinsert(sorted, timelineAssignment)
	end
	if allSucceeded == false then
		print(AddOnName .. ":", "An assignment attempted to update without a boss or boss phase table.")
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
		sort(sorted --[[@as table<integer, TimelineAssignment>]], function(a, b)
			local nameOrRoleA = a.assignment.assigneeNameOrRole
			local nameOrRoleB = b.assignment.assigneeNameOrRole
			if not roster[nameOrRoleA] or not roster[nameOrRoleB] then
				if assignmentSortType == "Role > Alphabetical" then
					return nameOrRoleA < nameOrRoleB
				elseif assignmentSortType == "Role > First Appearance" then
					if a.startTime == b.startTime then
						return nameOrRoleA < nameOrRoleB
					end
					return a.startTime < b.startTime
				end
				return false
			end
			if roster[nameOrRoleA].role == roster[nameOrRoleB].role then
				if assignmentSortType == "Role > Alphabetical" then
					return nameOrRoleA < nameOrRoleB
				elseif assignmentSortType == "Role > First Appearance" then
					if a.startTime == b.startTime then
						return nameOrRoleA < nameOrRoleB
					end
					return a.startTime < b.startTime
				end
			elseif roster[nameOrRoleA].role == "role:healer" then
				return true
			elseif roster[nameOrRoleB].role == "role:healer" then
				return false
			elseif roster[nameOrRoleA].role == "role:tank" then
				return true
			elseif roster[nameOrRoleB].role == "role:tank" then
				return false
			end
			if assignmentSortType == "Role > First Appearance" then
				if a.startTime == b.startTime then
					return nameOrRoleA < nameOrRoleB
				end
				return a.startTime < b.startTime
			end
			return nameOrRoleA < nameOrRoleB
		end)
	end

	return sorted
end

-- Attempts to assign roles based on assignment spells. Currently only tries to assign healer roles.
---@param assignments table<integer, Assignment> Assignments to assign roles for
function Utilities.DetermineRolesFromAssignments(assignments)
	local assigneeAssignments = {}
	local healerClasses = {
		["DRUID"] = "role:healer",
		["EVOKER"] = "role:healer",
		["MONK"] = "role:healer",
		["PALADIN"] = "role:healer",
		["PRIEST"] = "role:healer",
		["SHAMAN"] = "role:healer",
	}
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
			if spellID == 98008 or spellID == 108280 then -- Shaman healing bc classified as raid defensive
				determinedRoles[assignee] = "role:healer"
				break
			end
			for className, classData in pairs(Private.spellDB.classes) do
				if determinedRoles[assignee] then
					break
				end
				for _, spellInfo in pairs(classData) do
					if spellInfo["spellID"] == spellID then
						if spellInfo["type"] == "heal" and healerClasses[className] then
							determinedRoles[assignee] = "role:healer"
							break
						end
					end
				end
			end
		end
		if not determinedRoles[assignee] then
			determinedRoles[assignee] = ""
		end
	end
	return determinedRoles
end

-- Sorts a table of possibly nested dropdown item data, removing any inline icons if present before sorting.
---@param data table<integer, DropdownItemData> Dropdown data to sort
function Utilities.SortDropdownDataByItemValue(data)
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
			Utilities.SortDropdownDataByItemValue(item.dropdownItemMenuData)
		end
	end
end

-- Updates a timeline assignment's start time.
---@param timelineAssignment TimelineAssignment
---@param boss Boss? The boss to obtain cast times from if the assignment requires it
---@param bossPhaseTable table<integer, integer>? A table of boss phases in the order in which they occur
---@return boolean -- Whether or not the update succeeded
function Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, boss, bossPhaseTable)
	local assignment = timelineAssignment.assignment
	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = bossUtilities.FindBossAbility(assignment.combatLogEventSpellID)
		local startTime = assignment.time
		if ability and boss and bossPhaseTable then
			local relativeStartTime, phaseNumberOffset =
				bossUtilities.GetRelativeBossAbilityStartTime(ability, assignment.spellCount)
			local phaseStartTime = bossUtilities.GetCumulativePhaseStartTime(boss, bossPhaseTable, phaseNumberOffset)
			startTime = startTime + phaseStartTime + relativeStartTime
			if assignment.combatLogEventType == "SAR" then
				startTime = startTime + ability.duration + ability.castTime
			elseif assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SAA" then
				startTime = startTime + ability.castTime
			end
			timelineAssignment.startTime = startTime
		else
			return false
		end
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		timelineAssignment.startTime = assignment--[[@as TimedAssignment]].time
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		if boss and bossPhaseTable then
			local phase = boss.phases[assignment.phase]
			if phase then
				for phaseCount = 1, #phase.count do
					local phaseStartTime = bossUtilities.GetCumulativePhaseStartTime(boss, bossPhaseTable, phaseCount)
					timelineAssignment.startTime = phaseStartTime
					break -- TODO: Only first phase appearance implemented
				end
			end
		else
			return false
		end
	end
	return true
end

-- Creates two tables used to populate the assignment list. The first is a sorted list of text for the list and the
-- second is a table that maps the text to the assigneeNameOrRole found in the assignments.
---@param sortedAssignees table<integer, string> Sorted list of assigneeNameOrRoles from assignments
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster for the assignments
---@return table<integer, string>, table<string, string>
function Utilities.GetAssignmentListTextFromAssignees(sortedAssignees, roster)
	local textTable = {}
	local map = {}
	for index = 1, #sortedAssignees do
		local assigneeNameOrRole = sortedAssignees[index]
		local abilityEntryText = assigneeNameOrRole
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
			elseif roster and roster[sortedAssignees[index]] then
				if roster[sortedAssignees[index]].classColoredName then
					abilityEntryText = roster[sortedAssignees[index]].classColoredName or assigneeNameOrRole
				end
			end
		end
		map[abilityEntryText] = assigneeNameOrRole
		tinsert(textTable, abilityEntryText)
	end

	return textTable, map
end

-- Creates a table of unit types for the current raid or party group.
---@param maxGroup? integer Maximum group number
---@return table<integer, string>
function Utilities.IterateRosterUnits(maxGroup)
	local units = {}
	maxGroup = maxGroup or 8
	local numMembers = GetNumGroupMembers()
	for i = 1, numMembers do
		if i == 1 and numMembers <= 4 then
			units[i] = "player"
		elseif IsInRaid() then
			local _, _, subgroup = GetRaidRosterInfo(i)
			if subgroup and subgroup <= maxGroup then
				units[i] = "raid" .. i
			end
		else
			units[i] = "party" .. (i - 1)
		end
	end
	return units
end

-- Creates a table where keys are character names and the values are tables with class and classColoredName fields.
---@return table
function Utilities.CreateClassColoredNamesFromCurrentGroup()
	local groupData = {}
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if unit then
			local _, classFileName, _ = UnitClass(unit)
			local unitName, unitServer = UnitName(unit)
			if classFileName then
				local colorMixin = GetClassColor(classFileName)
				if colorMixin then
					local classColoredName = colorMixin:WrapTextInColorCode(unitName)
					groupData[unitName] = {}
					groupData[unitName].class = classFileName
					groupData[unitName].classColoredName = classColoredName
					if unitServer then -- nil if on same server
						local unitNameAndServer = unitName.join("-", unitServer)
						groupData[unitNameAndServer] = groupData[unitName]
					end
				end
			end
		end
	end
	return groupData
end

-- Updates classes and class colored names from the current raid or party group.
---@param unitName string Character name for the roster entry
---@param rosterEntry EncounterPlannerDbRosterEntry Roster entry to update
---@param currentGroupClassData table Table containing class and class colored name
local function UpdateRosterEntryClassAndClassName(unitName, rosterEntry, currentGroupClassData)
	if rosterEntry.class and rosterEntry.class ~= "" then -- Manually entered class
		local className = rosterEntry.class:match("class:%s*(%a+)")
		if className then
			className = className:upper()
			if Private.spellDB.classes[className] then
				local colorMixin = GetClassColor(className)
				rosterEntry.classColoredName = colorMixin:WrapTextInColorCode(unitName)
			end
		end
	elseif currentGroupClassData and type(currentGroupClassData.class) == "string" then
		local className = currentGroupClassData.class
		local actualClassName
		if className == "DEATHKNIGHT" then
			actualClassName = "DeathKnight"
		elseif className == "DEMONHUNTER" then
			actualClassName = "DemonHunter"
		else
			actualClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		rosterEntry.class = "class:" .. actualClassName:gsub("%s", "")
		rosterEntry.classColoredName = currentGroupClassData.classColoredName
	else
		rosterEntry.class = nil
		rosterEntry.classColoredName = nil
	end
end

-- Updates classes and class colored names from the current raid or party group.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to update
---@param addIfMissing boolean? If true, units that do not exist in the roster are added
function Utilities.UpdateRosterClassesAndClassNames(roster, addIfMissing)
	local groupData = Utilities.CreateClassColoredNamesFromCurrentGroup()
	for unitName, data in pairs(groupData) do
		if not roster[unitName] and addIfMissing then
			roster[unitName] = {}
		end
		if roster[unitName] then
			UpdateRosterEntryClassAndClassName(unitName, roster[unitName], data)
		end
	end
end

-- Adds assignees from assignments not already present in roster, updates estimated roles if one was found and the entry
-- does not already have one.
---@param assignments table<integer, Assignment> Assignments to add assignees from
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to update
function Utilities.UpdateRosterFromAssignments(assignments, roster)
	local determinedRoles = Utilities.DetermineRolesFromAssignments(assignments)
	local visited = {}
	for _, assignment in ipairs(assignments) do
		if assignment.assigneeNameOrRole and not visited[assignment.assigneeNameOrRole] then
			local nameOrRole = assignment.assigneeNameOrRole
			if
				not nameOrRole:find("class:")
				and not nameOrRole:find("group:")
				and not nameOrRole:find("role:")
				and not nameOrRole:find("{everyone}")
			then
				if not roster[nameOrRole] then
					roster[nameOrRole] = {}
				end
				if not roster[nameOrRole].role or roster[nameOrRole].role == "" then
					if determinedRoles[nameOrRole] then
						roster[nameOrRole].role = determinedRoles[nameOrRole]
					end
				end
			end
			visited[nameOrRole] = true
		end
	end
end

-- Splits a string into table using new lines as separators.
---@param text string The text to use to create the table
---@return table<integer, string>
function Utilities.SplitStringIntoTable(text)
	local stringTable = {}
	for line in text:gmatch(lineMatchRegex) do
		tinsert(stringTable, line)
	end
	return stringTable
end

---@param stringTable table<integer, string>
---@return string|nil -- Boss name if found, otherwise nil
function Utilities.SearchStringTableForBossName(stringTable)
	for _, line in pairs(stringTable) do
		local spellID, _ = line:match(postOptionsPreDashRegex)
		if spellID then
			local spellIDNumber = tonumber(spellID)
			if spellIDNumber then
				local bossName = bossUtilities.GetBossNameFromSpellID(spellIDNumber)
				if bossName then
					return bossName
				end
			end
		end
	end
	return nil
end
