--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local ceil = math.ceil
local floor = math.floor
local format = string.format
local GetClassColor = C_ClassColor.GetClassColor
local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local hugeNumber = math.huge
local ipairs = ipairs
local IsInRaid = IsInRaid
local pairs = pairs
local print = print
local rawget = rawget
local rawset = rawset
local select = select
local setmetatable = setmetatable
local sort = table.sort
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitClass = UnitClass
local UnitName = UnitName
local wipe = table.wipe

local lineMatchRegex = "([^\r\n]+)"
local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"

local specIDToType = {
	-- Mage
	[62] = "ranged", -- Arcane
	[63] = "ranged", -- Fire
	[64] = "ranged", -- Frost
	-- Paladin
	[65] = "melee", -- Holy
	[66] = "melee", -- Protection
	[70] = "melee", -- Retribution
	-- Warrior
	[71] = "melee", -- Arms
	[72] = "melee", -- Fury
	[73] = "melee", -- Protection
	-- Druid
	[102] = "ranged", -- Balance
	[103] = "melee", -- Feral
	[104] = "melee", -- Guardian
	[105] = "ranged", -- Restoration
	-- Death Knight
	[250] = "melee", -- Blood
	[251] = "melee", -- Frost
	[252] = "melee", -- Unholy
	-- Hunter
	[253] = "ranged", -- Beast Mastery
	[254] = "ranged", -- Marksmanship
	[255] = "melee", -- Survival
	-- Priest
	[256] = "ranged", -- Discipline
	[257] = "ranged", -- Holy
	[258] = "ranged", -- Shadow
	-- Rogue
	[259] = "melee", -- Assassination
	[260] = "melee", -- Outlaw
	[261] = "melee", -- Subtlety
	-- Shaman
	[262] = "ranged", -- Elemental
	[263] = "melee", -- Enhancement
	[264] = "ranged", -- Restoration
	-- Warlock
	[265] = "ranged", -- Affliction
	[266] = "ranged", -- Demonology
	[267] = "ranged", -- Destruction
	-- Monk
	[268] = "melee", -- Brewmaster
	[270] = "melee", -- Mistweaver
	[269] = "melee", -- Windwalker
	-- Demon Hunter
	[577] = "melee", -- Havoc
	[581] = "melee", -- Vengeance
	-- Evoker
	[1467] = "ranged", -- Devastation
	[1468] = "ranged", -- Preservation
	[1473] = "ranged", -- Augmentation
}

---@type table<integer, table<integer, table<integer, number>>>
local absoluteSpellCastStartTables = {}
for _, boss in pairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
	absoluteSpellCastStartTables[boss.dungeonEncounterID] =
		bossUtilities.CreateAbsoluteSpellCastTimeTable(boss.dungeonEncounterID)
end

local specIDToName = {
	-- Mage
	[62] = "Arcane",
	[63] = "Fire",
	[64] = "Frost",
	-- Paladin
	[65] = "Holy",
	[66] = "Protection",
	[70] = "Retribution",
	-- Warrior
	[71] = "Arms",
	[72] = "Fury",
	[73] = "Protection",
	-- Druid
	[102] = "Balance",
	[103] = "Feral",
	[104] = "Guardian",
	[105] = "Restoration",
	-- Death Knight
	[250] = "Blood",
	[251] = "Frost",
	[252] = "Unholy",
	-- Hunter
	[253] = "Beast Mastery",
	[254] = "Marksmanship",
	[255] = "Survival",
	-- Priest
	[256] = "Discipline",
	[257] = "Holy",
	[258] = "Shadow",
	-- Rogue
	[259] = "Assassination",
	[260] = "Outlaw",
	[261] = "Subtlety",
	-- Shaman
	[262] = "Elemental",
	[263] = "Enhancement",
	[264] = "Restoration",
	-- Warlock
	[265] = "Affliction",
	[266] = "Demonology",
	[267] = "Destruction",
	-- Monk
	[268] = "Brewmaster",
	[270] = "Mistweaver",
	[269] = "Windwalker",
	-- Demon Hunter
	[577] = "Havoc",
	[581] = "Vengeance",
	-- Evoker
	[1467] = "Devastation",
	[1468] = "Preservation",
	[1473] = "Augmentation",
}

local specIDToIconAndName = {}

for specID, _ in pairs(specIDToName) do
	local _, name, _, icon, _ = GetSpecializationInfoByID(specID)
	specIDToIconAndName[specID] = format("|T%s:16|t %s", icon, name)
end

---@param value number
---@param precision integer
---@return number
function Utilities.Round(value, precision)
	local factor = 10 ^ precision
	if value > 0 then
		return floor(value * factor + 0.5) / factor
	else
		return ceil(value * factor - 0.5) / factor
	end
end

---@param value number
---@param minValue number
---@param maxValue number
---@return number
function Utilities.Clamp(value, minValue, maxValue)
	return min(maxValue, max(minValue, value))
end

---@param notes table<string, Plan>
---@param bossName string
---@param existingName string|nil
---@return string
function Utilities.CreateUniqueNoteName(notes, bossName, existingName)
	local newNoteName = existingName or bossName
	if notes then
		local num = 2
		if notes[newNoteName] then
			newNoteName = newNoteName .. " " .. num
		end
		local newNoteNameLength = newNoteName:len()
		while notes[newNoteName] do
			newNoteName = newNoteName:sub(1, newNoteNameLength) .. num
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

---@return table<integer, string>
function Utilities.GetSpecIDToNameTable()
	return specIDToName
end

---@param time number
---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.ConvertCombatLogEventTimeToAbsoluteTime(
	time,
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	if
		absoluteSpellCastStartTables[bossDungeonEncounterID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
	then
		local adjustedTime = absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
			+ time
		local ability = bossUtilities.FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
		if ability then
			if combatLogEventType == "SAR" then
				adjustedTime = adjustedTime + ability.duration + ability.castTime
			elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
				adjustedTime = adjustedTime + ability.castTime
			end
		end
		return adjustedTime
	end
	return nil
end

---@param absoluteTime number
---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.ConvertAbsoluteTimeToCombatLogEventTime(
	absoluteTime,
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	if
		absoluteSpellCastStartTables[bossDungeonEncounterID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
	then
		local adjustedTime = absoluteTime
			- absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
		local ability = bossUtilities.FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
		if ability then
			if combatLogEventType == "SAR" then
				adjustedTime = adjustedTime - ability.duration - ability.castTime
			elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
				adjustedTime = adjustedTime - ability.castTime
			end
		end
		return adjustedTime
	end
	return nil
end

---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.GetMinimumCombatLogEventTime(
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	if
		absoluteSpellCastStartTables[bossDungeonEncounterID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID]
		and absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
	then
		local time = absoluteSpellCastStartTables[bossDungeonEncounterID][combatLogEventSpellID][spellCount]
		local ability = bossUtilities.FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
		if ability then
			if combatLogEventType == "SAR" then
				time = time + ability.duration + ability.castTime
			elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
				time = time + ability.castTime
			end
		end
		return time
	end
	return nil
end

---@param absoluteTime number The time from the beginning of the boss encounter
---@param bossDungeonEncounterID integer
---@param combatLogEventType CombatLogEventType Type of combat log event for more accurate findings
---@return integer|nil, integer|nil, number|nil -- combat log event Spell ID, spell count, leftover time offset
function Utilities.FindNearestCombatLogEvent(absoluteTime, bossDungeonEncounterID, combatLogEventType)
	local minTime = hugeNumber
	local combatLogEventSpellIDForMinTime = nil
	local spellCountForMinTime = nil
	if absoluteSpellCastStartTables[bossDungeonEncounterID] then
		for combatLogEventSpellID, spellCountAndTime in pairs(absoluteSpellCastStartTables[bossDungeonEncounterID]) do
			local ability = bossUtilities.FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
			for spellCount, time in pairs(spellCountAndTime) do
				local adjustedTime = time
				if ability then
					if combatLogEventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime < absoluteTime then
					local difference = absoluteTime - adjustedTime
					if difference < minTime then
						minTime = difference
						combatLogEventSpellIDForMinTime = combatLogEventSpellID
						spellCountForMinTime = spellCount
					end
				end
			end
		end
	end
	if combatLogEventSpellIDForMinTime and spellCountForMinTime then
		return combatLogEventSpellIDForMinTime, spellCountForMinTime, minTime
	end
	return nil
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
		})
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Trinket", text = "Trinket", dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
function Utilities.CreateSpellAssignmentDropdownItems()
	return { CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() }
end

---@return DropdownItemData
local function CreateSpecDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for specID, iconAndName in pairs(specIDToIconAndName) do
		tinsert(dropdownItems, {
			itemValue = "spec:" .. tostring(specID),
			text = iconAndName,
		})
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Spec", text = "Spec", dropdownItemMenuData = dropdownItems }
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
			text = "Group Number",
			itemValue = "Group Number",
			dropdownItemMenuData = {
				{ text = "1", itemValue = "group:1" },
				{ text = "2", itemValue = "group:2" },
				{ text = "3", itemValue = "group:3" },
				{ text = "4", itemValue = "group:4" },
			},
		},
		{
			text = "Role",
			itemValue = "Role",
			dropdownItemMenuData = {
				{ text = "Damager", itemValue = "role:damager" },
				{ text = "Healer", itemValue = "role:healer" },
				{ text = "Tank", itemValue = "role:tank" },
			},
		},
		{
			text = "Type",
			itemValue = "Type",
			dropdownItemMenuData = {
				{ text = "Melee", itemValue = "type:melee" },
				{ text = "Ranged", itemValue = "type:ranged" },
			},
		},
		{ text = "Everyone", itemValue = "{everyone}" },
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
	tinsert(assignmentTypes, CreateSpecDropdownItems())

	Utilities.SortDropdownDataByItemValue(assignmentTypes)

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
				text = rosterTable.classColoredName ~= "" and rosterTable.classColoredName or normalName,
			})
		end
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

-- Creates dropdown data with all assignments types including individual roster members.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster to character names from
---@param assignmentTypeDropdownItems? table<integer, DropdownItemData>
---@param assigneeDropdownItems? table<integer, DropdownItemData>
---@return table<integer, DropdownItemData>
function Utilities.CreateAssignmentTypeWithRosterDropdownItems(
	roster,
	assignmentTypeDropdownItems,
	assigneeDropdownItems
)
	local assignmentTypes = assignmentTypeDropdownItems or Utilities.CreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	if individualIndex and roster then
		assignmentTypes[individualIndex].dropdownItemMenuData = assigneeDropdownItems
			or Utilities.CreateAssigneeDropdownItems(roster)
		Utilities.SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	end
	return assignmentTypes
end

-- Creates unsorted timeline assignments from assignments and sets the timeline assignments' start times.
---@param assignments table<integer, Assignment> Assignments to create timeline assignments from
---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it
---@return table<integer, TimelineAssignment> -- Unsorted timeline assignments
function Utilities.CreateTimelineAssignments(assignments, bossDungeonEncounterID)
	local timelineAssignments = {}
	local allSucceeded = true
	local warningStrings = {}
	for _, assignment in pairs(assignments) do
		local timelineAssignment = Private.classes.TimelineAssignment:New(assignment)
		local success, warningString =
			Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, bossDungeonEncounterID)
		if success == true then
			tinsert(timelineAssignments, timelineAssignment)
		else
			tinsert(warningStrings, warningString)
			allSucceeded = false
		end
	end
	if allSucceeded == false then
		local alreadyPrinted = {}
		local combinedString = format("%s: The following assignments failed to update:", AddOnName)
		for _, warningString in pairs(warningStrings) do
			if not alreadyPrinted[warningString] then
				combinedString = combinedString .. "\n" .. warningString
				alreadyPrinted[warningString] = true
			end
		end
		print(combinedString)
	end
	return timelineAssignments
end

-- Sorts the assignees based on the order of the timeline assignments, taking spellID into account.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@param collapsed table<string, boolean>
---@return table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
function Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
	local assigneeIndices = {}
	local groupedByAssignee = {}
	for _, entry in ipairs(sortedTimelineAssignments) do
		local assignee = entry.assignment.assigneeNameOrRole
		if not groupedByAssignee[assignee] then
			groupedByAssignee[assignee] = {}
			tinsert(assigneeIndices, assignee)
		end
		tinsert(groupedByAssignee[assignee], entry)
	end

	local order = 0
	local assigneeMap = {}
	local assigneeOrder = {}

	for _, assignee in ipairs(assigneeIndices) do
		for _, entry in ipairs(groupedByAssignee[assignee]) do
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
				if not collapsed[assignee] then
					order = order + 1
				end
				assigneeMap[assignee].spellIDs[spellID] = order
				tinsert(assigneeOrder, { assigneeNameOrRole = assignee, spellID = spellID })
			end
			entry.order = assigneeMap[assignee].spellIDs[spellID]
		end
	end

	return assigneeOrder
end

-- Creates a Timeline Assignment comparator function.
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@return fun(a:TimelineAssignment, b:TimelineAssignment):boolean
local function CompareAssignments(roster, assignmentSortType)
	local function RolePriority(role)
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
			local roleA, roleB = roster[nameOrRoleA], roster[nameOrRoleB]
			local rolePriorityA, rolePriorityB = RolePriority(roleA and roleA.role), RolePriority(roleB and roleB.role)
			if rolePriorityA == rolePriorityB then
				if assignmentSortType == "Role > Alphabetical" then
					if nameOrRoleA == nameOrRoleB then
						if spellIDA == spellIDB then
							return a.startTime < b.startTime
						end
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
---@param bossDungeonEncounterID integer Used to get boss timers to set the proper timeline assignment start time for combat log assignments
---@return table<integer, TimelineAssignment>
function Utilities.SortAssignments(assignments, roster, assignmentSortType, bossDungeonEncounterID)
	local timelineAssignments = Utilities.CreateTimelineAssignments(assignments, bossDungeonEncounterID)
	sort(timelineAssignments, CompareAssignments(roster, assignmentSortType))
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

---@param assigneeNameOrRole string
---@param roster table<string, EncounterPlannerDbRosterEntry> Roster for the assignments
---@return string
function Utilities.ConvertAssigneeNameOrRoleToLegibleString(assigneeNameOrRole, roster)
	local legibleString = assigneeNameOrRole
	if assigneeNameOrRole == "{everyone}" then
		return "Everyone"
	else
		local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
		local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
		local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
		local specMatch = assigneeNameOrRole:match("spec:%s*(%d+)")
		local typeMatch = assigneeNameOrRole:match("type:%s*(%a+)")
		if classMatch then
			local prettyClassName = Private.prettyClassNames[classMatch]
			if prettyClassName then
				legibleString = prettyClassName
			else
				legibleString = classMatch:sub(1, 1):upper() .. classMatch:sub(2):lower()
			end
		elseif roleMatch then
			legibleString = roleMatch:sub(1, 1):upper() .. roleMatch:sub(2):lower()
		elseif groupMatch then
			legibleString = "Group " .. groupMatch
		elseif specMatch then
			local specIDMatch = tonumber(specMatch)
			if specIDMatch then
				legibleString = specIDToIconAndName[specIDMatch]
			end
		elseif typeMatch then
			legibleString = typeMatch:sub(1, 1):upper() .. typeMatch:sub(2):lower()
		elseif roster and roster[assigneeNameOrRole] then
			if roster[assigneeNameOrRole].classColoredName ~= "" then
				legibleString = roster[assigneeNameOrRole].classColoredName
			end
		end
	end
	return legibleString
end

-- Sorts a table of possibly nested dropdown item data, removing any inline icons if present before sorting.
---@param data table<integer, DropdownItemData> Dropdown data to sort
function Utilities.SortDropdownDataByItemValue(data)
	-- Sort the top-level table
	sort(data, function(a, b)
		local itemValueA = a.itemValue
		local itemValueB = b.itemValue
		if type(itemValueA) == "number" or itemValueA:find("spec:") then
			local spellName = a.text:match("|T.-|t%s(.+)")
			if spellName then
				itemValueA = spellName
			end
		end
		if type(itemValueB) == "number" or itemValueB:find("spec:") then
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
---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it
---@return boolean, string|nil -- Whether or not the update succeeded, optional warning message
function Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, bossDungeonEncounterID)
	local assignment = timelineAssignment.assignment
	local warningString = nil

	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local bossTableSpellCastStartTable = absoluteSpellCastStartTables[bossDungeonEncounterID]
		if bossTableSpellCastStartTable then
			local spellIDSpellCastStartTable = bossTableSpellCastStartTable[assignment.combatLogEventSpellID] --[[@ as table<integer, number>]]
			if spellIDSpellCastStartTable then
				local spellCastStart = spellIDSpellCastStartTable[assignment.spellCount]--[[@ as number]]
				if spellCastStart then
					local startTime = spellCastStart + assignment.time
					local ability =
						bossUtilities.FindBossAbility(bossDungeonEncounterID, assignment.combatLogEventSpellID)
					if ability then
						if assignment.combatLogEventType == "SAR" then
							startTime = startTime + ability.duration + ability.castTime
						elseif assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SAA" then
							startTime = startTime + ability.castTime
						end
					end
					timelineAssignment.startTime = startTime
				else
					warningString = format(
						'No spell cast times found for boss %s with spell ID "%d" with spell count %d.',
						bossUtilities.GetBossName(bossDungeonEncounterID),
						assignment.combatLogEventSpellID,
						assignment.spellCount
					)
				end
			else
				warningString = format(
					'No spell cast times found for boss %s with spell ID "%d".',
					bossUtilities.GetBossName(bossDungeonEncounterID),
					assignment.combatLogEventSpellID
				)
			end
		else
			warningString =
				format("No spell cast times for boss: %s.", bossUtilities.GetBossName(bossDungeonEncounterID))
		end
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		timelineAssignment.startTime = assignment--[[@as TimedAssignment]].time
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		if bossDungeonEncounterID then
			local boss = bossUtilities.GetBoss(bossDungeonEncounterID)
			if boss then
				local bossPhaseTable = bossUtilities.CreateBossPhaseTable(bossDungeonEncounterID)
				local phase = boss.phases[assignment.phase]
				if bossPhaseTable and phase then
					for phaseCount = 1, #phase.count do
						local phaseStartTime = bossUtilities.GetCumulativePhaseStartTime(
							bossDungeonEncounterID,
							bossPhaseTable,
							phaseCount
						)
						timelineAssignment.startTime = phaseStartTime
						break -- TODO: Only first phase appearance implemented
					end
				end
			end
		else
			return false
		end
	end
	if warningString then
		return false, warningString
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
		local abilityEntryText = Utilities.ConvertAssigneeNameOrRoleToLegibleString(assigneeNameOrRole, roster)
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
---@return EncounterPlannerDbRosterEntry
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
				local classColoredName = colorMixin:WrapTextInColorCode(unitName)
				groupData[unitName].classColoredName = classColoredName
				if unitServer then -- nil if on same server
					local unitNameAndServer = unitName .. "-" .. unitServer
					groupData[unitNameAndServer] = groupData[unitName]
				end
			end
		end
	end
	return groupData
end

---@param unitName string Character name for the roster entry
---@param rosterEntry EncounterPlannerDbRosterEntry Roster entry to update
local function UpdateRosterEntryClassColoredName(unitName, rosterEntry)
	if rosterEntry.class ~= "" then
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
---@param unitData EncounterPlannerDbRosterEntry
local function UpdateRosterEntryFromUnitData(rosterEntry, unitData)
	if rosterEntry.class == "" then
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

	if rosterEntry.classColoredName == "" then
		rosterEntry.classColoredName = unitData.classColoredName
	end

	if rosterEntry.role == "" then
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
				roster[unitName] = Private.classes.EncounterPlannerDbRosterEntry:New({})
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
				and not nameOrRole:find("spec:")
				and not nameOrRole:find("type:")
				and not nameOrRole:find("{everyone}")
			then
				if not roster[nameOrRole] then
					roster[nameOrRole] = Private.classes.EncounterPlannerDbRosterEntry:New({})
				end
				if roster[nameOrRole].role == "" then
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

---@param iconID integer|string
---@param text string
---@param size? integer
---@return string
function Utilities.AddIconBeforeText(iconID, text, size)
	return format("|T%s:%d|t %s", iconID, size or 0, text)
end

---@param spellID integer
---@param size? integer
---@return string
function Utilities.SubSpellIconTextWithSpellIcon(spellID, size)
	local spellTexture = GetSpellTexture(spellID)
	return format("|T%s:%d|t", (spellTexture or [[Interface\Icons\INV_MISC_QUESTIONMARK]]), size or 0)
end

---@return integer
local function GetGroupNumber()
	local playerName, _ = UnitName("player")
	local myGroup = 1
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if name == playerName then
				myGroup = subgroup
				break
			end
		end
	end
	return myGroup
end

---@param timelineAssignments table<integer, TimelineAssignment>|table<integer, Assignment>
---@return table<integer, TimelineAssignment|Assignment>
function Utilities.FilterSelf(timelineAssignments)
	local filtered = {}
	local unitName = select(1, UnitName("player"))
	local unitClass = select(2, UnitClass("player"))
	local specID, spec, _, _, role = GetSpecializationInfo(GetSpecialization())
	local classType = specIDToType[specID]
	for _, timelineAssignment in ipairs(timelineAssignments) do
		local nameOrRole = timelineAssignment.assigneeNameOrRole or timelineAssignment.assignment.assigneeNameOrRole
		if nameOrRole:find("class:") then
			local classMatch = nameOrRole:match("class:%s*(%a+)")
			if classMatch then
				if classMatch:upper() == unitClass then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("group:") then
			if nameOrRole:find(tostring(GetGroupNumber())) then
				tinsert(filtered, timelineAssignment)
			end
		elseif nameOrRole:find("role:") then
			local roleMatch = nameOrRole:match("role:%s*(%a+)")
			if roleMatch then
				if roleMatch:upper() == role then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("type:") then
			local typeMatch = nameOrRole:match("type:%s*(%a+)")
			if typeMatch then
				if typeMatch:lower() == classType then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("spec:") then
			local specMatch = nameOrRole:match("spec:%s*(%d+)")
			if specMatch then
				local foundSpecID = tonumber(specMatch)
				if foundSpecID and foundSpecID == specID then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("{everyone}") then
			tinsert(filtered, timelineAssignment)
		elseif unitName == nameOrRole then
			tinsert(filtered, timelineAssignment)
		end
	end
	return filtered
end

---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return string
function Utilities.CreateReminderProgressBarText(assignment, roster)
	local reminderText = ""
	if assignment.text ~= nil and assignment.text ~= "" then
		reminderText = assignment.text
	elseif assignment.targetName ~= nil and assignment.targetName ~= "" then
		if assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID ~= 0 then
			if assignment.spellInfo.name then
				reminderText = assignment.spellInfo.name
			else
				local spellName = GetSpellName(assignment.spellInfo.spellID)
				if spellName then
					reminderText = spellName
				end
			end
		end
		local targetRosterEntry = roster[assignment.targetName]
		if targetRosterEntry and targetRosterEntry.classColoredName ~= "" then
			reminderText = reminderText .. " " .. targetRosterEntry.classColoredName
		else
			reminderText = reminderText .. " " .. assignment.targetName
		end
		-- TODO: Consider highlighting frame
	elseif assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID ~= 0 then
		if assignment.spellInfo.name then
			reminderText = assignment.spellInfo.name
		else
			local spellName = GetSpellName(assignment.spellInfo.spellID)
			if spellName then
				reminderText = spellName
			end
		end
	end
	return reminderText
end

---@param assignments table<integer, Assignment>
function Utilities.SetAssignmentMetaTables(assignments)
	for _, assignment in pairs(assignments) do
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

---@param regionName string|nil
---@return boolean
function Utilities.IsValidRegionName(regionName)
	if regionName then
		local region = _G[regionName]
		return region ~= nil and region.SetPoint ~= nil
	end
	return false
end
