--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local Utilities = Private.utilities

local GetClassColor = C_ClassColor.GetClassColor
local ipairs = ipairs
local pairs = pairs
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local sort = table.sort
local tinsert = table.insert
local type = type
local wipe = table.wipe

---@param notes table<integer, EncounterPlannerDbNote>
---@return string
function Utilities:CreateUniqueNoteName(notes)
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

function Utilities:CreatePrettyClassNames()
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

-- Sorts the assignees based on sortedTimelineAssignments. All empty assignees will appear before regular assignees.
---@param sortedTimelineAssignments table<integer, TimelineAssignment>
---@return table<integer, string>
function Utilities:SortAssignees(sortedTimelineAssignments)
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

-- Sorts assignments based on the assignmentSortType and updates sortedTimelineAssignments and sortedAssignees.
---@param assignments table<integer, Assignment>
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@param assignmentSortType AssignmentSortType
---@return table<integer, TimelineAssignment>
function Utilities:SortAssignments(assignments, roster, assignmentSortType)
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
			return roster[nameOrRoleA] < roster[nameOrRoleB]
		end)
	end

	return sorted
end

---@param assignments table<integer, Assignment>
function Utilities:DetermineRolesFromAssignments(assignments)
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

---@param data table<integer, DropdownItemData>
function Utilities:SortDropdownDataByItemValue(data)
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
			self:SortDropdownDataByItemValue(item.dropdownItemMenuData)
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
	Utilities:SortDropdownDataByItemValue(dropdownItems)
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
	Utilities:SortDropdownDataByItemValue(dropdownItems)
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
	Utilities:SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Trinket", text = "Trinket", dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
function Utilities:CreateSpellAssignmentDropdownItems()
	return { CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() }
end

---@return table<integer, DropdownItemData>
function Utilities:CreateClassDropdownItemData()
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

	self:SortDropdownDataByItemValue(dropdownData)
	return dropdownData
end

---@return table<integer, DropdownItemData>
function Utilities:CreateAssignmentTypeDropdownItems()
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
		dropdownItemMenuData = self:CreateClassDropdownItemData(),
	}

	tinsert(assignmentTypes, classAssignmentTypes)

	self:SortDropdownDataByItemValue(assignmentTypes)
	return assignmentTypes
end

---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return table<integer, DropdownItemData>
function Utilities:CreateAssignmentTypeWithRosterDropdownItems(roster)
	local assignmentTypes = self:CreateAssignmentTypeDropdownItems()

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

		self:SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	end
	return assignmentTypes
end

---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return table<integer, DropdownItemData>
function Utilities:CreateAssigneeDropdownItems(roster)
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
	self:SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

---@param sortedAssignees table<integer, string>
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return table<integer, string>
function Utilities:GetAssignmentListTextFromAssignees(sortedAssignees, roster)
	local textTable = {}

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
				if roster and roster[sortedAssignees[index]] and roster[sortedAssignees[index]].classColoredName then
					abilityEntryText = roster[sortedAssignees[index]].classColoredName
				else
					abilityEntryText = sortedAssignees[index]
				end
			end
		end
		tinsert(textTable, abilityEntryText)
	end

	return textTable
end

---@param assignments table<integer, Assignment>
---@param ID integer
---@return Assignment|nil
function Utilities:FindAssignmentByUniqueID(assignments, ID)
	for _, assignment in pairs(assignments) do
		if assignment.uniqueID == ID then
			return assignment
		end
	end
end
