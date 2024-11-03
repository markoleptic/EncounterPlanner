---@module "NerubarPalace"
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
local tremove = tremove
local sort = sort
local tinsert = tinsert
local type = type
local wipe = wipe
local GetClassColor = C_ClassColor.GetClassColor
local GetSpellInfo = C_Spell.GetSpellInfo
local format = format
local tonumber = tonumber

local bossAbilityPadding = 4
local assignmentPadding = 2
local paddingBetweenBossAbilitiesAndAssignments = 36
local bottomLeftContainerWidth = 200
local topContainerHeight = 36
local dropdownContainerSpacing = { 0, 2 }
local dropdownContainerLabelSpacing = { 0, 2 }

local currentAssignmentIndex = 0
local firstAppearanceSortedAssignments = {} --[[@as table<integer, TimelineAssignment>]]
local firstAppearanceAssigneeOrder = {} --[[@as table<integer, string>]]
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

---@param assignment Assignment
---@return TimelineAssignment|nil
local function calculateTimelineAssignment(assignment)
	if getmetatable(assignment) == Private.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = AddOn:FindBossAbility(assignment.combatLogEventSpellID)
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
			return Private.TimelineAssignment:new({
				assignment = assignment,
				startTime = startTime,
				offset = nil,
				order = nil,
			})
		end
	elseif getmetatable(assignment) == Private.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		return Private.TimelineAssignment:new({
			assignment = assignment,
			startTime = assignment.time,
			offset = nil,
			order = nil,
		})
	elseif getmetatable(assignment) == Private.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		local boss = AddOn:GetBoss("Broodtwister Ovi'nax")
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
					return Private.TimelineAssignment:new({
						assignment = assignment,
						startTime = runningStartTime,
						offset = nil,
						order = nil,
					})
				end
				runningStartTime = runningStartTime + boss.phases[currentPhase].duration
				currentPhase = boss.phases[currentPhase].repeatAfter
			end
		end
	end
	return nil
end

---@param timelineAssignment TimelineAssignment
local function UpdateTimelineAssignment(timelineAssignment)
	local assignment = timelineAssignment.assignment
	if getmetatable(assignment) == Private.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = AddOn:FindBossAbility(assignment.combatLogEventSpellID)
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
	elseif getmetatable(assignment) == Private.TimedAssignment then
		assignment = assignment --[[@as TimedAssignment]]
		timelineAssignment.startTime = assignment.time
	elseif getmetatable(assignment) == Private.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		local boss = AddOn:GetBoss("Broodtwister Ovi'nax")
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

local function createAssigneeOrder(sortedAssignments)
	-- Clear and rebuild the order and offset mappings
	local order = 1
	local orderAndOffsets = {}
	local assigneeOrder = {}

	for _, entry in ipairs(sortedAssignments) do
		local assignee = entry.assignment.assigneeNameOrRole
		if not orderAndOffsets[assignee] then
			local offset = (order - 1) * (30 + 2)
			orderAndOffsets[assignee] = { order = order, offset = offset }
			assigneeOrder[order] = assignee
			order = order + 1
		end
		entry.order = orderAndOffsets[assignee].order
		entry.offset = orderAndOffsets[assignee].offset
	end

	return assigneeOrder
end

-- Sorts assignments based on first appearance in the fight.
---@param assignments table<integer, Assignment>
---@param assignmentSortType AssignmentSortType|nil
---@return table<integer, TimelineAssignment>, table<integer, string>
local function SortAssignments(assignments, assignmentSortType)
	if assignmentSortType then
		lastAssignmentSortType = assignmentSortType
	end

	local sortedAssignments = {} --[[@as table<integer, TimelineAssignment>]]

	for _, assignment in pairs(assignments) do
		local timelineAssignment = calculateTimelineAssignment(assignment)
		if timelineAssignment then
			tinsert(sortedAssignments, timelineAssignment)
		end
	end

	if not assignmentSortType then
		assignmentSortType = lastAssignmentSortType
	end

	if assignmentSortType == "Alphabetical" then
		sort(sortedAssignments --[[@as table<integer, TimelineAssignment>]], function(a, b)
			return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
		end)
	elseif assignmentSortType == "First Appearance" then
		sort(sortedAssignments --[[@as table<integer, TimelineAssignment>]], function(a, b)
			return a.startTime < b.startTime
		end)
	elseif assignmentSortType == "Role" then
		-- TODO: Implement a way to find a class and spec from spellIDs
	end

	return sortedAssignments, createAssigneeOrder(sortedAssignments)
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

---@param assigneeOrder table<integer, string>]]
---@param assignmentListContainer EPContainer
local function updateAssignmentListEntries(assigneeOrder, assignmentListContainer)
	assignmentListContainer:ReleaseChildren()
	for index = 1, #assigneeOrder do
		local abilityEntryText
		local assigneeNameOrRole = assigneeOrder[index]
		if assigneeNameOrRole == "{everyone}" then
			abilityEntryText = "Everyone"
		else
			local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
			local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
			if classMatch then
				local prettyClassName = Private.prettyClassNames[classMatch]
				if prettyClassName then
					abilityEntryText = prettyClassName
				else
					abilityEntryText = classMatch:sub(1, 1):upper() .. classMatch:sub(2):lower()
				end
			elseif roleMatch then
				abilityEntryText = roleMatch:sub(1, 1):upper() .. roleMatch:sub(2):lower()
			else
				abilityEntryText = Private.roster[assigneeOrder[index]]
			end
		end
		local assigneeEntry = AceGUI:Create("EPAbilityEntry")
		assigneeEntry:SetText(abilityEntryText)
		assigneeEntry:SetHeight(30)
		assignmentListContainer:AddChild(assigneeEntry)
	end
	assignmentListContainer:DoLayout()
end

---@param value number|string
---@param timeline EPTimeline
---@param listFrame AceGUIContainer
local function HandleBossDropdownValueChanged(value, timeline, listFrame)
	local boss = AddOn:GetBoss(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[value].name)
	if boss then
		listFrame:ReleaseChildren()
		for index = 1, #boss.sortedAbilityIDs do
			local abilityEntry = AceGUI:Create("EPAbilityEntry")
			abilityEntry:SetFullWidth(true)
			abilityEntry:SetAbility(boss.sortedAbilityIDs[index])
			listFrame:AddChild(abilityEntry)
		end
		listFrame:DoLayout()
		timeline:SetBossAbilities(boss.abilities, boss.sortedAbilityIDs, boss.phases)
		timeline:SetAssignments(firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder)
		timeline:UpdateTimeline()
	end
end

---@param value string
local function HandleAssignmentSortDropdownValueChanged(value)
	firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder = SortAssignments(Private.assignments, value)
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		updateAssignmentListEntries(firstAppearanceAssigneeOrder, assignmentContainer)
	end
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder)
		timeline:UpdateTimeline()
	end
end

local function HandleAssignmentEditorDeleteButtonClicked(frame, _)
	Private.assignmentEditor:Release()
	local assignmentToRemove = uniqueAssignmentTable[currentAssignmentIndex]
	currentAssignmentIndex = 0
	for i, v in ipairs(Private.assignments) do
		if v == assignmentToRemove then
			table.remove(Private.assignments, i)
			break
		end
	end
	tremove(uniqueAssignmentTable, currentAssignmentIndex)
	firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder = SortAssignments(Private.assignments)
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		updateAssignmentListEntries(firstAppearanceAssigneeOrder, assignmentContainer)
	end
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder)
		timeline:UpdateTimeline()
	end
end

local function HandleAssignmentEditorOkayButtonClicked(_, _)
	firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder = SortAssignments(Private.assignments)
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		updateAssignmentListEntries(firstAppearanceAssigneeOrder, assignmentContainer)
	end
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder)
		timeline:UpdateTimeline()
	end
end

---@param dataType string
---@param value string
---@param timeline EPTimeline
local function HandleAssignmentEditorDataChanged(dataType, value, timeline)
	local assignment = uniqueAssignmentTable[currentAssignmentIndex] --[[@as Assignment]]
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
			assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID = tonumber(value)
		end
	elseif dataType == "CombatLogEventSpellCount" then
		if getmetatable(assignment) == Private.CombatLogEventAssignment then
			assignment--[[@as CombatLogEventAssignment]].spellCount = tonumber(value)
		end
	elseif dataType == "PhaseNumber" then
		if
			getmetatable(assignment) == Private.CombatLogEventAssignment
			or getmetatable(assignment) == Private.PhasedAssignment
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
			getmetatable(assignment) == Private.CombatLogEventAssignment
			or getmetatable(assignment) == Private.PhasedAssignment
			or getmetatable(assignment) == Private.TimedAssignment
		then
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time = tonumber(value)
		end
	elseif dataType == "OptionalText" then
		assignment.text = value -- TODO: update textWithIconReplacements
	elseif dataType == "Target" then
		assignment.targetName = value
	end

	for _, timelineAssignment in ipairs(firstAppearanceSortedAssignments) do
		if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
			UpdateTimelineAssignment(timelineAssignment)
			break
		end
	end

	timeline:UpdateTimeline()
end

---@param timeline EPTimeline
local function HandleTimelineAssignmentClicked(timeline, _, uniqueID)
	currentAssignmentIndex = uniqueID
	if not Private.assignmentEditor then
		Private.assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		Private.assignmentEditor.obj = Private.mainFrame
		Private.assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.assignmentEditor.frame:SetFrameLevel(10)
		Private.assignmentEditor:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
		Private.assignmentEditor:SetLayout("EPVerticalLayout")
		Private.assignmentEditor:DoLayout()

		Private.assignmentEditor:SetCallback("OnRelease", function()
			Private.assignmentEditor = nil
		end)
		Private.assignmentEditor:SetCallback("DataChanged", function(_, _, dataType, value)
			HandleAssignmentEditorDataChanged(dataType, value, timeline)
		end)
		Private.assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
		Private.assignmentEditor:SetCallback("OkayButtonClicked", HandleAssignmentEditorOkayButtonClicked)
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

---@param timeline EPTimeline
local function HandleCreateNewAssignment(timeline, _, abilityData)
	-- TODO: Find the boss ability using abilityData to create a new assignment and open assignment editor
end

---@param topContainer EPContainer
---@param bossContainer EPContainer
---@param bossDropdown EPDropdown
---@param timeline EPTimeline
---@param bossAbilityContainer EPContainer
---@param assignmentSortDropdown EPDropdown
local function SetupTopContainer(
	topContainer,
	bossContainer,
	bossDropdown,
	timeline,
	bossAbilityContainer,
	assignmentSortDropdown
)
	topContainer:SetLayout("EPHorizontalLayout")
	topContainer:SetHeight(topContainerHeight)
	topContainer:SetFullWidth(true)

	bossContainer:SetLayout("EPVerticalLayout")
	bossContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetText("Boss:")
	bossLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

	local bossDropdownData = {}
	for index, instance in ipairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = format("|T%s:16|t %s", iconImage, instance.name)
		tinsert(bossDropdownData, index, iconText)
	end
	bossDropdown:AddItems(bossDropdownData, "EPDropdownItemToggle")
	bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleBossDropdownValueChanged(value, timeline, bossAbilityContainer)
	end)

	local assignmentSortContainer = AceGUI:Create("EPContainer")
	assignmentSortContainer:SetLayout("EPVerticalLayout")
	assignmentSortContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local assignmentSortLabel = AceGUI:Create("EPLabel")
	assignmentSortLabel:SetText("Assignment Sort Priority:")
	assignmentSortLabel:SetTextPadding(unpack(dropdownContainerLabelSpacing))

	assignmentSortDropdown:AddItems({
		{ itemValue = "First Appearance", text = "First Appearance", dropdownItemMenuData = {} },
		{ itemValue = "Alphabetical", text = "Alphabetical", dropdownItemMenuData = {} },
		{ itemValue = "Role", text = "Role", dropdownItemMenuData = {} },
	}, "EPDropdownItemToggle")
	assignmentSortDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleAssignmentSortDropdownValueChanged(value)
	end)

	bossContainer:AddChild(bossLabel)
	bossContainer:AddChild(bossDropdown)
	assignmentSortContainer:AddChild(assignmentSortLabel)
	assignmentSortContainer:AddChild(assignmentSortDropdown)
	topContainer:AddChild(bossContainer)
	topContainer:AddChild(assignmentSortContainer)
end

---@param bottomLeftContainer EPContainer
---@param bossAbilityContainer EPContainer
---@param assignmentListContainer EPContainer
local function SetupBottomLeftContainer(bottomLeftContainer, bossAbilityContainer, assignmentListContainer)
	bottomLeftContainer:SetLayout("EPVerticalLayout")
	bottomLeftContainer:SetWidth(bottomLeftContainerWidth)
	bottomLeftContainer:SetSpacing(0, paddingBetweenBossAbilitiesAndAssignments)

	bossAbilityContainer:SetLayout("EPVerticalLayout")
	bossAbilityContainer:SetFullWidth(true)
	bossAbilityContainer:SetSpacing(0, bossAbilityPadding)

	assignmentListContainer:SetLayout("EPVerticalLayout")
	assignmentListContainer:SetFullWidth(true)
	assignmentListContainer:SetSpacing(0, assignmentPadding)

	bottomLeftContainer:AddChild(bossAbilityContainer)
	bottomLeftContainer:AddChild(assignmentListContainer)
end

function AddOn:CreateGUI()
	Private:Note()
	for _, ass in ipairs(Private.assignments) do
		uniqueAssignmentTable[ass.uniqueID] = ass
	end
	firstAppearanceSortedAssignments, firstAppearanceAssigneeOrder =
		SortAssignments(Private.assignments, "First Appearance")

	Private.mainFrame = AceGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("EPContentFrameLayout")
	Private.mainFrame:SetCallback("OnRelease", function()
		Private.mainFrame = nil
	end)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)

	local topContainer = AceGUI:Create("EPContainer")
	local bossContainer = AceGUI:Create("EPContainer")
	local bottomLeftContainer = AceGUI:Create("EPContainer")
	local bossAbilityContainer = AceGUI:Create("EPContainer")
	local bossDropdown = AceGUI:Create("EPDropdown")
	local assignmentListContainer = AceGUI:Create("EPContainer")
	local assignmentSortDropdown = AceGUI:Create("EPDropdown")

	SetupTopContainer(topContainer, bossContainer, bossDropdown, timeline, bossAbilityContainer, assignmentSortDropdown)
	SetupBottomLeftContainer(bottomLeftContainer, bossAbilityContainer, assignmentListContainer)
	updateAssignmentListEntries(firstAppearanceAssigneeOrder, assignmentListContainer)

	Private.mainFrame:AddChild(topContainer)
	Private.mainFrame:AddChild(bottomLeftContainer)
	Private.mainFrame:AddChild(timeline)

	-- Set default values
	bossDropdown:SetValue(1)
	HandleBossDropdownValueChanged(1, timeline, bossAbilityContainer)
	assignmentSortDropdown:SetValue("First Appearance")

	-- Center frame in middle of screen
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	local xPos = (screenWidth / 2) - (Private.mainFrame.frame:GetWidth() / 2)
	local yPos = -(screenHeight / 2) + (Private.mainFrame.frame:GetHeight() / 2)
	Private.mainFrame.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xPos, yPos)
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.DB = LibStub("AceDB-3.0"):New(AddOnName .. "DB", self.Defaults)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")
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
		self:CreateGUI()
		-- if AddOn:GetModule("Options") then
		-- 	AddOn.OptionsModule:OpenOptions()
		-- end
	end
end

-- Loads all the set options after game loads and player enters world
function AddOn:PLAYER_ENTERING_WORLD(eventName) end
