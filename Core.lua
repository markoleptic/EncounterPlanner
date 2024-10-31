---@module "Options"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

local AddOn = Private.AddOn
local AceGUI = Private.Libs.AGUI
local ipairs = ipairs
local min = math.min
local pairs = pairs
local rawget = rawget
local rawset = rawset
local getmetatable = getmetatable
local setmetatable = setmetatable
local sort = sort
local tinsert = tinsert
local type = type
local wipe = wipe
local GetClassColor = C_ClassColor.GetClassColor
local GetSpellInfo = C_Spell.GetSpellInfo
local format = format

local currentAssignmentIndex = 0
local firstAppearanceSortedAssignments = {} --[[@as table<integer, TimelineAssignment>]]
local firstAppearanceAssigneeOrder = {} --[[@as table<integer, TimelineAssignment>]]

local function NewBoss(name, bossIds, journalEncounterId, dungeonEncounterId)
	return {
		name = name,
		bossIds = bossIds,
		journalEncounterId = journalEncounterId,
		dungeonEncounterId = dungeonEncounterId,
	}
end

AddOn.Defaults = {
	profile = {
		instances = {
			["Nerub'ar Palace"] = {
				name = "Nerub'ar Palace",
				journalInstanceId = 1273, -- all bosses share same JournalInstanceID
				instanceId = 2657, -- the instance id for the zone the boss is located in (?)
				bosses = {
					NewBoss("Ulgrax the Devourer", 215657, 2607, 2902),
					NewBoss("The Bloodbound Horror", 214502, 2611, 2917),
					NewBoss("Sikran, Captain of the Sureki", 214503, 2599, 2898),
					NewBoss("Rasha'nan", 214504, 2609, 2918),
					NewBoss("Broodtwister Ovi'nax", 214506, 2612, 2919),
					NewBoss("Nexus-Princess Ky'veza", 217748, 2601, 2920),
					NewBoss("The Silken Court", { 217489, 217491 }, 2608, 2921),
					NewBoss("Queen Ansurek", 218370, 2602, 2922),
				},
				order = { 1, 2, 3, 4, 5, 6, 7, 8 },
			},
		},
	},
}

local bosses = {
	["Ulgrax the Devourer"] = {
		abilities = {
			[435136] = { -- Venomous Lash
				phases = {
					[1] = {
						castTimes = { 5.0, 25.0, 28.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[435138] = { -- Digestive Acid
				phases = {
					[1] = {
						castTimes = { 20.0, 47.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[434803] = { -- Carnivorous Contest
				phases = {
					[1] = {
						castTimes = { 38.0, 36.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 4.0,
			},
			[445123] = { -- Hulking Crash
				phases = {
					[1] = {
						castTimes = { 90.0 },
						repeatInterval = nil,
					},
				},
				duration = 0.0,
				castTime = 5.0,
			},
			[436200] = { -- Juggernaut Charge
				phases = {
					[2] = {
						castTimes = { 16.7, 7.1, 7.1, 7.1 },
						repeatInterval = nil,
					},
				},
				duration = 8.0,
				castTime = 4.0,
			},
			[438012] = { -- Hungering Bellows
				phases = {
					[2] = {
						castTimes = { 60.8 },
						repeatInterval = 7,
					},
				},
				duration = 3.0,
				castTime = 3.0,
			},
			[445052] = { -- Chittering Swarm
				phases = {
					[2] = {
						castTimes = { 6 },
						repeatInterval = nil,
					},
				},
				duration = 0.0,
				castTime = 3.0,
			},
		},
		phases = {
			[1] = {
				duration = 90,
				defaultDuration = 90,
				count = 3,
				defaultCount = 3,
				repeatAfter = 2,
			},
			[2] = {
				duration = 80,
				defaultDuration = 80,
				count = 3,
				defaultCount = 3,
				repeatAfter = 1,
			},
		},
	},
	["Broodtwister Ovi'nax"] = {
		abilities = {
			[441362] = { -- Volatile Concoction
				phases = {
					[1] = {
						castTimes = { 2.0 },
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 20.0 },
						},
					},
				},
				duration = 0.0,
				castTime = 1.5,
			},
			[446349] = { -- Sticky Web
				phases = {
					[1] = {
						castTimes = { 15.0 },
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 30.0, 30.0, 30.0, 30.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 30.0 },
						},
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[442432] = { -- Ingest Black Blood
				phases = {
					[1] = {
						castTimes = { 19.0, 171.0, 172.0 },
						repeatInterval = nil,
					},
				},
				duration = 15.0,
				castTime = 1.0,
			},
			[442526] = { -- Experimental Dosage
				phases = {
					[1] = {
						castTimes = nil,
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 16.0, 50.0, 50.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 50.0 },
						},
					},
				},
				duration = 8.0,
				castTime = 1.5,
			},
		},
		phases = {
			[1] = {
				duration = 600,
				defaultDuration = 600,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			},
		},
	},
} --[[@as table<integer, Boss>]]

-- Generate a list of abilities for each boss sorted by their first cast time
for _, boss in pairs(bosses) do
	local firstAppearances = {}
	local firstAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		for phaseNumber, phase in pairs(data.phases) do
			if phase.castTimes then
				for _, castTime in ipairs(phase.castTimes) do
					if phaseNumber > 1 then
						local phaseTimeOffset = boss.phases[phaseNumber].duration
						earliestCastTime = min(earliestCastTime, phaseTimeOffset + castTime)
					else
						earliestCastTime = min(earliestCastTime, castTime)
					end
				end
			end
		end
		firstAppearancesMap[spellID] = earliestCastTime
		tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
	end
	local firstEventTriggerAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		if data.eventTriggers then
			for triggerSpellID, eventTrigger in pairs(data.eventTriggers) do
				local earliestTriggerCastTime = firstAppearancesMap[triggerSpellID]
				local castTime = earliestTriggerCastTime
					+ boss.abilities[triggerSpellID].castTime
					+ eventTrigger.castTimes[1]
				earliestCastTime = min(earliestCastTime, castTime)
			end
			firstEventTriggerAppearancesMap[spellID] = earliestCastTime
		end
	end

	for _, data in pairs(firstAppearances) do
		if firstEventTriggerAppearancesMap[data.spellID] then
			data.earliestCastTime = min(data.earliestCastTime, firstEventTriggerAppearancesMap[data.spellID])
		end
	end

	for spellID, earliestCastTime in pairs(firstEventTriggerAppearancesMap) do
		local found = false
		for _, data in pairs(firstAppearances) do
			if data.spellID == spellID then
				found = true
				break
			end
		end
		if not found then
			tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
		end
	end

	sort(firstAppearances, function(a, b)
		return a.earliestCastTime < b.earliestCastTime
	end)
	boss.sortedAbilityIDs = {}
	for _, entry in ipairs(firstAppearances) do
		tinsert(boss.sortedAbilityIDs, entry.spellID)
	end
end

---comment
---@param spellID number
---@return Boss|nil,BossAbility|nil
local function findBossAbility(spellID)
	for _, boss in pairs(bosses) do
		if boss.abilities[spellID] then
			return boss, boss.abilities[spellID]
		end
	end
	return nil, nil
end

---@generic T
---@param inTable table<number, T>
---@return table<number, number>
local function CreateSortedTable(inTable)
	local sorted = {}
	for entry in pairs(inTable) do
		tinsert(sorted, entry)
	end
	sort(sorted)
	return sorted
end

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

-- Sorts assignments based on first appearance in the fight.
---@param assignments table<integer, Assignment>
---@return table<integer, TimelineAssignment>, table<integer, string>
local function CreateSortedAssignmentTables(assignments)
	local sortedAssignments = {} --[[@as table<integer, TimelineAssignment>]]
	for _, assignment in pairs(assignments) do
		if getmetatable(assignment) == Private.CombatLogEventAssignment then
			assignment = assignment --[[@as CombatLogEventAssignment]]
			local _, ability = findBossAbility(assignment.combatLogEventSpellID)
			if ability then
				local startTime = assignment.time
				if assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SCS" then
					for i = 1, min(assignment.spellCount, #ability.phases[1].castTimes) do
						startTime = startTime + ability.phases[1].castTimes[i]
					end
				end
				if assignment.combatLogEventType == "SCC" then
					startTime = startTime + ability.castTime
				end
				-- TODO: Implement other combat log event types
				tinsert(
					sortedAssignments,
					Private.TimelineAssignment:new({
						assignment = assignment,
						startTime = startTime,
						offset = nil,
						order = nil,
					})
				)
			end
		elseif getmetatable(assignment) == Private.TimedAssignment then
			assignment = assignment --[[@as TimedAssignment]]
			tinsert(
				sortedAssignments,
				Private.TimelineAssignment:new({
					assignment = assignment,
					startTime = assignment.time,
					offset = nil,
					order = nil,
				})
			)
		elseif getmetatable(assignment) == Private.PhasedAssignment then
			assignment = assignment --[[@as PhasedAssignment]]
			local boss = bosses["Broodtwister Ovi'nax"]
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
						tinsert(
							sortedAssignments,
							Private.TimelineAssignment:new({
								assignment = assignment,
								startTime = runningStartTime,
								offset = nil,
								order = nil,
							})
						)
					end
					runningStartTime = runningStartTime + boss.phases[currentPhase].duration
					currentPhase = boss.phases[currentPhase].repeatAfter
				end
			end
		end
	end

	-- Sort by first appearance
	sort(sortedAssignments --[[@as table<integer, TimelineAssignment>]], function(a, b)
		return a.startTime < b.startTime
	end)

	local order = 1
	local orderAndOffsets = {}
	local assigneeOrder = {}

	for _, entry in
		ipairs(sortedAssignments --[[@as table<integer, TimelineAssignment>]])
	do
		if orderAndOffsets[entry.assignment.assigneeNameOrRole] == nil then
			local offset = 0
			if order ~= 1 then
				offset = (order - 1) * (30 + 2)
			end
			orderAndOffsets[entry.assignment.assigneeNameOrRole] = { order = order, offset = offset }
			entry.order = order
			entry.offset = offset
			assigneeOrder[order] = entry.assignment.assigneeNameOrRole
			order = order + 1
		end
		entry.offset = orderAndOffsets[entry.assignment.assigneeNameOrRole].offset
		entry.order = orderAndOffsets[entry.assignment.assigneeNameOrRole].order
	end
	return sortedAssignments, assigneeOrder
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
	for _, item in ipairs(data) do
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
		for _, spell in ipairs(classSpells) do
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
local function createAssignmentTypeDropdownItems()
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
local function createAssigneeDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]

	for name, coloredName in pairs(Private.roster) do
		local assigneeDropdownData = {
			itemValue = name,
			text = coloredName,
			dropdownItemMenuData = {},
		}
		tinsert(dropdownItems, assigneeDropdownData)
	end

	SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

---@param value number|string
---@param timeline EPTimeline
---@param listFrame AceGUIContainer
local function HandleBossDropdownValueChanged(value, timeline, listFrame)
	if AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[value] then
		local boss = bosses[AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[value].name]
		if boss then
			listFrame:ReleaseChildren()
			for index = 1, #boss.sortedAbilityIDs do
				local abilityEntry = AceGUI:Create("EPAbilityEntry")
				abilityEntry:SetFullWidth(true)
				abilityEntry:SetAbility(boss.sortedAbilityIDs[index])
				listFrame:AddChild(abilityEntry)
				if index ~= #boss.sortedAbilityIDs then
					local spacer = AceGUI:Create("EPSpacer")
					spacer:SetHeight(4)
					spacer:SetFullWidth(true)
					listFrame:AddChild(spacer)
				end
			end
			listFrame:DoLayout()
			timeline:SetEntries(
				boss.abilities,
				boss.sortedAbilityIDs,
				boss.phases,
				firstAppearanceSortedAssignments,
				firstAppearanceAssigneeOrder
			)
		end
	end
end

local function HandleAssignmentEditorDataChanged(dataType, value)
	local assignment = firstAppearanceSortedAssignments[currentAssignmentIndex].assignment --[[@as Assignment]]
	if dataType == "AssignmentType" then
		if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
			if getmetatable(assignment) ~= Private.CombatLogEventAssignment then
				assignment = Private.CombatLogEventAssignment:new(assignment)
			end
		elseif value == "Absolute Time" then
			if getmetatable(assignment) ~= Private.TimedAssignment then
				assignment = Private.TimedAssignment:new(assignment)
			end
		elseif value == "Boss Phase" then
			if getmetatable(assignment) ~= Private.PhasedAssignment then
				assignment = Private.PhasedAssignment:new(assignment)
			end
		end
	elseif dataType == "CombatLogEventSpellID" then
		if getmetatable(assignment) == Private.CombatLogEventAssignment then
			assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID = value
		end
	elseif dataType == "CombatLogEventSpellCount" then
		if getmetatable(assignment) == Private.CombatLogEventAssignment then
			assignment--[[@as CombatLogEventAssignment]].spellCount = value
		end
	elseif dataType == "PhaseNumber" then
		if
			getmetatable(assignment) == Private.CombatLogEventAssignment
			or getmetatable(assignment) == Private.PhasedAssignment
		then
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment]].phase = value
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
		if
			getmetatable(assignment) == Private.CombatLogEventAssignment
			or getmetatable(assignment) == Private.PhasedAssignment
			or getmetatable(assignment) == Private.TimedAssignment
		then
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time = value
		end
	elseif dataType == "OptionalText" then
		assignment.text = value -- TODO: update textWithIconReplacements
	elseif dataType == "Target" then
		assignment.targetName = value
	end
end

local function HandleTimelineAssignmentClicked()
	if not Private.assignmentEditor then
		Private.assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		Private.assignmentEditor.obj = Private.mainFrame
		Private.assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.assignmentEditor.frame:SetFrameLevel(10)
		Private.assignmentEditor:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -6, 0)
		Private.assignmentEditor:SetLayout("EPVerticalLayout")
		Private.assignmentEditor:DoLayout()
		Private.assignmentEditor:SetCallback("OnRelease", function()
			Private.assignmentEditor = nil
		end)
		Private.assignmentEditor:SetCallback("DataChanged", function(_, _, dataType, value)
			HandleAssignmentEditorDataChanged(dataType, value)
		end)
		Private.assignmentEditor.spellAssignmentDropdown:AddItems(
			{ CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() },
			"EPDropdownItemToggle"
		)
		Private.assignmentEditor.assigneeTypeDropdown:AddItems(
			createAssignmentTypeDropdownItems(),
			"EPDropdownItemToggle"
		)
		Private.assignmentEditor.assigneeDropdown:AddItems(createAssigneeDropdownItems(), "EPDropdownItemToggle")
		Private.assignmentEditor.targetDropdown:AddItems(createAssigneeDropdownItems(), "EPDropdownItemToggle")
	end
	local assignment = firstAppearanceSortedAssignments[currentAssignmentIndex].assignment
	local assigneeName = string.match(assignment.assigneeNameOrRole, "class:%s*(%a+)")
	-- todo: handle more types of groups
	if assigneeName then
		Private.assignmentEditor:SetAssigneeType("Class")
		Private.assignmentEditor.assigneeTypeDropdown:SetValue(assignment.assigneeNameOrRole)
		Private.assignmentEditor.assigneeDropdown:SetValue("")
	else
		Private.assignmentEditor:SetAssigneeType("Individual")
		Private.assignmentEditor.assigneeTypeDropdown:SetValue("Individual")
		Private.assignmentEditor.assigneeDropdown:SetValue(assignment.assigneeNameOrRole)
	end
	Private.assignmentEditor.previewLabel:SetText(assignment.strWithIconReplacements)
	Private.assignmentEditor.targetDropdown:SetValue(assignment.targetName)
	Private.assignmentEditor.optionalTextLineEdit:SetText(assignment.text)
	Private.assignmentEditor.spellAssignmentDropdown:SetValue(assignment.spellInfo.spellID)

	if getmetatable(assignment) == Private.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		Private.assignmentEditor:SetAssignmentType("CombatLogEventAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue(assignment.combatLogEventType)
		Private.assignmentEditor.combatLogEventSpellIDDropdown:SetValue(assignment.combatLogEventSpellID)
		Private.assignmentEditor.combatLogEventSpellCountLineEdit:SetText(assignment.spellCount)
		Private.assignmentEditor.phaseNumberDropdown:SetValue(assignment.phase)
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	elseif getmetatable(assignment) == Private.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		Private.assignmentEditor:SetAssignmentType("TimedAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue("Absolute Time")
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	elseif getmetatable(assignment) == Private.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		Private.assignmentEditor:SetAssignmentType("PhasedAssignment")
		Private.assignmentEditor.assignmentTypeDropdown:SetValue("Boss Phase")
		Private.assignmentEditor.timeEditBox:SetText(assignment.time)
	end
end

function AddOn:CreateGUI()
	Private.mainFrame = AceGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("EPContentFrameLayout")
	Private.mainFrame:SetCallback("OnRelease", function()
		Private.mainFrame = nil
	end)

	local leftSideFrame = AceGUI:Create("SimpleGroup")
	leftSideFrame:SetRelativeWidth(0.2)
	leftSideFrame:SetAutoAdjustHeight(true)
	leftSideFrame:SetLayout("List")

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetFullWidth(true)
	local dropdownData = {}
	for index, instance in ipairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = format("|T%s:16|t %s", iconImage, instance.name)
		tinsert(dropdownData, index, iconText)
	end
	dropdown:AddItems(dropdownData, "EPDropdownItemToggle")
	leftSideFrame:AddChild(dropdown)

	local dropdownSpacer = AceGUI:Create("EPSpacer")
	dropdownSpacer:SetHeight(11)
	leftSideFrame:AddChild(dropdownSpacer)

	local listFrame = AceGUI:Create("SimpleGroup")
	listFrame:SetLayout("List")
	listFrame:SetAutoAdjustHeight(true)
	listFrame:SetFullWidth(true)
	leftSideFrame:AddChild(listFrame)

	local listFrameSpacer = AceGUI:Create("EPSpacer")
	listFrameSpacer:SetHeight(30)
	leftSideFrame:AddChild(listFrameSpacer)

	local assignmentListFrame = AceGUI:Create("SimpleGroup")
	assignmentListFrame:SetLayout("List")
	assignmentListFrame:SetAutoAdjustHeight(true)
	assignmentListFrame:SetFullWidth(true)

	Private:Note()
	CreatePrettyClassNames()

	firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder = CreateSortedAssignmentTables(Private.assignments)

	for index = 1, #firstAppearanceAssigneeOrder do
		local assigneeNameOrRole = string.match(firstAppearanceAssigneeOrder[index], "class:%s*(%a+)")
		if not assigneeNameOrRole or assigneeNameOrRole == "" then
			assigneeNameOrRole = Private.roster[firstAppearanceAssigneeOrder[index]]
		else
			assigneeNameOrRole = Private.prettyClassNames[assigneeNameOrRole] or assigneeNameOrRole
		end
		-- todo: handle more types of groups
		local abilityEntry = AceGUI:Create("EPAbilityEntry")
		abilityEntry:SetText(assigneeNameOrRole)
		abilityEntry:SetFullWidth(true)
		abilityEntry:SetHeight(30)
		assignmentListFrame:AddChild(abilityEntry)
		if index ~= #firstAppearanceAssigneeOrder then
			local spacer = AceGUI:Create("EPSpacer")
			spacer:SetHeight(2)
			spacer:SetFullWidth(true)
			assignmentListFrame:AddChild(spacer)
		end
	end
	assignmentListFrame:DoLayout()
	leftSideFrame:AddChild(assignmentListFrame)

	local timelineSpacer = AceGUI:Create("EPSpacer")
	timelineSpacer:SetHeight(37)
	timelineSpacer:SetRelativeWidth(0.8)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetCallback("AssignmentClicked", function(_, _, sortedAssignmentIndex)
		currentAssignmentIndex = sortedAssignmentIndex
		HandleTimelineAssignmentClicked()
	end)
	timeline:SetRelativeWidth(0.8)

	Private.mainFrame:AddChild(leftSideFrame)
	Private.mainFrame:AddChild(timelineSpacer)
	Private.mainFrame:AddChild(timeline)

	dropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleBossDropdownValueChanged(value, timeline, listFrame)
	end)

	dropdown:SetValue(5)
	HandleBossDropdownValueChanged(5, timeline, listFrame)
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.DB = LibStub("AceDB-3.0"):New(AddOnName .. "DB", self.Defaults)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self.OnInitialize = nil
end

function AddOn:OnEnable()
	self:Refresh()
end

function AddOn:Refresh() end

-- Slash command functionality
function AddOn:SlashCommand(input)
	DevTool:AddData(Private)
	if not Private.mainFrame then
		self:CreateGUI()
		-- if AddOn:GetModule("Options") then
		-- 	AddOn.OptionsModule:OpenOptions()
		-- end
	end
end

-- Loads all the set options after game loads and player enters world
function AddOn:PLAYER_ENTERING_WORLD(eventName) end
