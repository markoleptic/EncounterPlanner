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
				key = key:gsub("%s", "")
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

-- Creates unsorted timeline assignments from assignments and sets the timeline assignments' start times.
---@param assignments table<integer, Assignment> Assignments to create timeline assignments from
---@param boss Boss? The boss to obtain cast times from if the assignment requires it
---@return table<integer, TimelineAssignment> -- Unsorted timeline assignments
function Utilities.CreateTimelineAssignments(assignments, boss)
	local timelineAssignments = {}
	local allSucceeded = true
	for _, assignment in pairs(assignments) do
		local timelineAssignment = Private.classes.TimelineAssignment:New(assignment)
		local success = Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, boss)
		if success == true then
			tinsert(timelineAssignments, timelineAssignment)
		elseif allSucceeded == true then
			allSucceeded = false
		end
	end
	if allSucceeded == false then
		print(format("%s: An assignment attempted to update without a boss or boss phase table.", AddOnName))
	end
	return timelineAssignments
end

-- Sorts the assignees based on the order of the timeline assignments, taking spellID into account.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@return table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
function Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments)
	local order = 1
	local assigneeMap = {}
	local assigneeOrder = {}

	for _, entry in ipairs(sortedTimelineAssignments) do
		local assignee = entry.assignment.assigneeNameOrRole
		local spellID = entry.assignment.spellInfo.spellID

		if not assigneeMap[assignee] then
			assigneeMap[assignee] = {
				order = order,
				spellIDs = {},
			}
			tinsert(assigneeOrder, { assigneeNameOrRole = assignee, spellID = nil })
			order = order + 1
		end
		if not assigneeMap[assignee].spellIDs[spellID] then
			assigneeMap[assignee].spellIDs[spellID] = order
			tinsert(assigneeOrder, { assigneeNameOrRole = assignee, spellID = spellID })
			order = order + 1
		end
		entry.order = assigneeMap[assignee].spellIDs[spellID]
	end

	return assigneeOrder
end

-- Creates a Timeline Assignment comparator function.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@return fun(a:TimelineAssignment, b:TimelineAssignment):boolean
local function compareAssignments(roster, assignmentSortType)
	local function rolePriority(role)
		if role == "role:healer" then
			return 1
		elseif role == "role:tank" then
			return 2
		elseif role == "role:damager" then
			return 3
		elseif role == nil or role == "" then
			return 4
		else
			print(format('%s: Invalid role type "%s"', AddOnName, role))
			return 4
		end
	end

	---@param a TimelineAssignment
	---@param b TimelineAssignment
	return function(a, b)
		local nameOrRoleA, nameOrRoleB = a.assignment.assigneeNameOrRole, b.assignment.assigneeNameOrRole
		local spellIDA, spellIDB = a.assignment.spellInfo.spellID, b.assignment.spellInfo.spellID
		if assignmentSortType == "Alphabetical" then
			if nameOrRoleA == nameOrRoleB then
				return spellIDA < spellIDB
			end
			return nameOrRoleA < nameOrRoleB
		elseif assignmentSortType == "First Appearance" then
			if a.startTime == b.startTime then
				if nameOrRoleA == nameOrRoleB then
					return spellIDA < spellIDB
				end
				return nameOrRoleA < nameOrRoleB
			end
			return a.startTime < b.startTime
		elseif assignmentSortType:match("^Role") then
			local rolePriorityA, rolePriorityB =
				rolePriority(roster[nameOrRoleA].role), rolePriority(roster[nameOrRoleB].role)
			if rolePriorityA == rolePriorityB then
				if assignmentSortType == "Role > Alphabetical" then
					if nameOrRoleA == nameOrRoleB then
						return spellIDA < spellIDB
					end
					return nameOrRoleA < nameOrRoleB
				elseif assignmentSortType == "Role > First Appearance" then
					if a.startTime == b.startTime then
						if nameOrRoleA == nameOrRoleB then
							return spellIDA < spellIDB
						end
						return nameOrRoleA < nameOrRoleB
					end
					return a.startTime < b.startTime
				end
			end
			return rolePriorityA < rolePriorityB
		else
			print(format('%s: Invalid assignment sort type "%s"', AddOnName, assignmentSortType))
			return false
		end
	end
end

-- Creates and sorts a table of TimelineAssignments and sets the start time used for each assignment on the timeline.
-- Sorts assignments based on the assignmentSortType.
---@param assignments table<integer, Assignment> Assignments to sort
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@param boss Boss? Used to get boss timers to set the proper timeline assignment start time for combat log assignments
---@return table<integer, TimelineAssignment>
function Utilities.SortAssignments(assignments, roster, assignmentSortType, boss)
	local timelineAssignments = Utilities.CreateTimelineAssignments(assignments, boss)
	sort(timelineAssignments, compareAssignments(roster, assignmentSortType))
	return timelineAssignments
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
---@return boolean -- Whether or not the update succeeded
function Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, boss)
	local assignment = timelineAssignment.assignment
	local bossPhaseTable = nil
	if boss then
		bossPhaseTable = bossUtilities.CreateBossPhaseTable(boss)
	end
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

-- Creates a sorted table used to populate the assignment list.
---@param sortedAssigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}> Sorted assignment list
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster for the assignments
---@return table<integer, {assigneeNameOrRole:string, text:string, spells:table<integer, integer>}>
function Utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
	local visited = {}
	local map = {}
	for _, nameAndSpell in ipairs(sortedAssigneesAndSpells) do
		local assigneeNameOrRole = nameAndSpell.assigneeNameOrRole
		local abilityEntryText = assigneeNameOrRole
		if assigneeNameOrRole == "{everyone}" then
			abilityEntryText = "Everyone"
		else
			local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
			local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
			local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
			if classMatch then
				classMatch = classMatch:match("^(.*):") or classMatch
				local prettyClassName = Private.prettyClassNames[classMatch]
				if prettyClassName then
					abilityEntryText = prettyClassName
				else
					abilityEntryText = classMatch:sub(1, 1):upper() .. classMatch:sub(2):lower()
				end
			elseif roleMatch then
				roleMatch = roleMatch:match("^(.*):") or roleMatch
				abilityEntryText = roleMatch:sub(1, 1):upper() .. roleMatch:sub(2):lower()
			elseif groupMatch then
				groupMatch = groupMatch:match("^(.*):") or groupMatch
				abilityEntryText = "Group " .. groupMatch
			elseif roster and roster[assigneeNameOrRole] then
				if roster[assigneeNameOrRole].classColoredName then
					abilityEntryText = roster[assigneeNameOrRole].classColoredName or assigneeNameOrRole
				end
			end
		end
		if not visited[abilityEntryText] then
			tinsert(map, {
				assigneeNameOrRole = assigneeNameOrRole,
				text = abilityEntryText,
				spells = {},
			})
			visited[abilityEntryText] = map[#map]
		end
		if nameAndSpell.spellID then
			tinsert(visited[abilityEntryText].spells, nameAndSpell.spellID)
		end
	end
	return map
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

-- Creates a table where keys are character names and the values are tables with class and role fields. Dependent on the
-- group the player is in.
---@return table<string, {class:string, role:string, classColoredName: string}>
function Utilities.GetDataFromGroup()
	local groupData = {}
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if unit then
			local role = UnitGroupRolesAssigned(unit)
			local _, classFileName, _ = UnitClass(unit)
			local unitName, unitServer = UnitName(unit)
			if classFileName then
				groupData[unitName] = {}
				groupData[unitName].class = classFileName
				groupData[unitName].role = role
				local colorMixin = GetClassColor(classFileName)
				if colorMixin then
					local classColoredName = colorMixin:WrapTextInColorCode(unitName)
					groupData[unitName].classColoredName = classColoredName
					if unitServer then -- nil if on same server
						local unitNameAndServer = unitName .. "-" .. unitServer
						groupData[unitNameAndServer] = groupData[unitName]
					end
				end
			end
		end
	end
	return groupData
end

---@param unitName string Character name for the roster entry
---@param rosterEntry EncounterPlannerDbRosterEntry Roster entry to update
local function UpdateRosterEntryClassColoredName(unitName, rosterEntry)
	local hasValidClass = rosterEntry.class and rosterEntry.class ~= ""
	if hasValidClass then
		local className = rosterEntry.class:match("class:%s*(%a+)")
		if className then
			className = className:upper()
			if Private.spellDB.classes[className] then
				local colorMixin = GetClassColor(className)
				rosterEntry.classColoredName = colorMixin:WrapTextInColorCode(unitName)
			end
		end
	end
end

-- Updates class, class colored name, and role from the group if they do not exist.
---@param rosterEntry EncounterPlannerDbRosterEntry Roster entry to update
---@param unitData {class:string, role:string, classColoredName: string}
local function UpdateRosterEntryFromUnitData(rosterEntry, unitData)
	if not rosterEntry.class or rosterEntry.class ~= "" then
		local className = unitData.class
		local actualClassName
		if className == "DEATHKNIGHT" then
			actualClassName = "DeathKnight"
		elseif className == "DEMONHUNTER" then
			actualClassName = "DemonHunter"
		else
			actualClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		rosterEntry.class = "class:" .. actualClassName:gsub("%s", "")
	end

	if not rosterEntry.classColoredName or rosterEntry.classColoredName == "" then
		rosterEntry.classColoredName = unitData.classColoredName
	end

	if not rosterEntry.role or rosterEntry.role == "" then
		if unitData.role == "DAMAGER" then
			rosterEntry.role = "role:damager"
		elseif unitData.role == "HEALER" then
			rosterEntry.role = "role:healer"
		elseif unitData.role == "TANK" then
			rosterEntry.role = "role:tank"
		end
	end
end

-- Imports all characters in the group if they do not already exist.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to update
function Utilities.ImportGroupIntoRoster(roster)
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if unit then
			local unitName, _ = UnitName(unit)
			if unitName then
				roster[unitName] = {}
			end
		end
	end
end

-- Updates class, class colored name, and role from the current raid or party group.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to update
function Utilities.UpdateRosterDataFromGroup(roster)
	local groupData = Utilities.GetDataFromGroup()
	for unitName, data in pairs(groupData) do
		if roster[unitName] then
			UpdateRosterEntryFromUnitData(roster[unitName], data)
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
				UpdateRosterEntryClassColoredName(nameOrRole, roster[nameOrRole])
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
