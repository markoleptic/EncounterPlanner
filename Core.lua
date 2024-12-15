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
local tostring = tostring
local tremove = tremove
local unpack = unpack

local assignmentMetaTables = {
	CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
	TimedAssignment = Private.classes.TimedAssignment,
	PhasedAssignment = Private.classes.PhasedAssignment,
}
local dropdownContainerLabelSpacing = { 2, 2 }
local dropdownContainerSpacing = { 2, 2 }
local noteContainerSpacing = { 5, 2 }
local topContainerDropdownWidth = 150
local topContainerHeight = 36
local spellDropdownItems = {}
local assignmentTypeDropdownItems = {}
local classDropdownItems = {}
local maxNumberOfRecentItems = 10

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

---@return Boss|nil
local function GetCurrentBoss()
	return bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
end

---@return string
local function GetCurrentBossName()
	return bossUtilities.GetBossDefinition(Private.mainFrame:GetBossSelectDropdown():GetValue()).name
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
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster())
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossName())
end

---@param rosterTab EPRosterEditorTab
local function HandleImportCurrentGroupButtonClicked(_, _, rosterTab)
	local importRosterWidgetMapping = nil
	local noChangeRosterWidgetMapping = nil
	if rosterTab == "SharedRoster" then
		noChangeRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		importRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
	elseif rosterTab == "CurrentBossRoster" then
		noChangeRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
		importRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
	end
	if importRosterWidgetMapping and noChangeRosterWidgetMapping then
		local importRoster = {}
		local noChangeRoster = {}
		for _, rosterWidgetMapping in ipairs(importRosterWidgetMapping) do
			importRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		for _, rosterWidgetMapping in ipairs(noChangeRosterWidgetMapping) do
			noChangeRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		utilities.ImportGroupIntoRoster(importRoster)
		utilities.UpdateRosterDataFromGroup(importRoster)
		if rosterTab == "SharedRoster" then
			Private.rosterEditor:SetRosters(noChangeRoster, importRoster)
		elseif rosterTab == "CurrentBossRoster" then
			Private.rosterEditor:SetRosters(importRoster, noChangeRoster)
		end
		Private.rosterEditor:SetCurrentTab(rosterTab)
	end
end

---@param rosterTab EPRosterEditorTab
---@param fill boolean
local function HandleFillOrUpdateRosterButtonClicked(_, _, rosterTab, fill)
	local fromRosterWidgetMapping = nil
	local toRosterWidgetMapping = nil
	if rosterTab == "SharedRoster" then
		fromRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		toRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
	elseif rosterTab == "CurrentBossRoster" then
		fromRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
		toRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
	end
	if fromRosterWidgetMapping and toRosterWidgetMapping then
		local fromRoster = {}
		local toRoster = {}
		for _, rosterWidgetMapping in ipairs(fromRosterWidgetMapping) do
			fromRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		for _, rosterWidgetMapping in ipairs(toRosterWidgetMapping) do
			toRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		for name, dbEntry in pairs(fromRoster) do
			if fill and not toRoster[name] then
				toRoster[name] = Private.DeepCopy(dbEntry)
			elseif toRoster[name] then
				if dbEntry.class then
					if not toRoster[name].class or toRoster[name].class == "" then
						toRoster[name].class = dbEntry.class
						toRoster[name].classColoredName = nil
					end
				end
				if dbEntry.role then
					if not toRoster[name].role or toRoster[name].role == "" then
						toRoster[name].role = dbEntry.role
					end
				end
			end
		end
		if rosterTab == "SharedRoster" then
			Private.rosterEditor:SetRosters(fromRoster, toRoster)
		elseif rosterTab == "CurrentBossRoster" then
			Private.rosterEditor:SetRosters(toRoster, fromRoster)
		end
		Private.rosterEditor:SetCurrentTab(rosterTab)
	end
end

local function CreateRosterEditor()
	if not Private.rosterEditor then
		Private.rosterEditor = AceGUI:Create("EPRosterEditor")
		Private.rosterEditor:SetCallback("OnRelease", function()
			Private.rosterEditor = nil
		end)
		Private.rosterEditor:SetCallback("EditingFinished", HandleRosterEditingFinished)
		Private.rosterEditor:SetCallback("ImportCurrentGroupButtonClicked", HandleImportCurrentGroupButtonClicked)
		Private.rosterEditor:SetCallback("FillRosterButtonClicked", function(_, _, tabName)
			HandleFillOrUpdateRosterButtonClicked(_, _, tabName, true)
		end)
		Private.rosterEditor:SetCallback("UpdateRosterButtonClicked", function(_, _, tabName)
			HandleFillOrUpdateRosterButtonClicked(_, _, tabName, false)
		end)
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

local function HandleAssignmentEditorDeleteButtonClicked()
	local assignmentID = Private.assignmentEditor:GetAssignmentID()
	Private.assignmentEditor:Release()
	for i, v in ipairs(GetCurrentAssignments()) do
		if v.uniqueID == assignmentID then
			tremove(GetCurrentAssignments(), i)
			break
		end
	end
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossName())
end

local function HandleAssignmentEditorOkayButtonClicked()
	Private.assignmentEditor:Release()
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossName())
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

	local updateFields = false
	local updatePreviewText = false

	if dataType == "AssignmentType" then
		if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
			if getmetatable(assignment) ~= Private.classes.CombatLogEventAssignment then
				local combatLogEventSpellID, spellCount, minTime = nil, nil, nil
				if getmetatable(assignment) == Private.classes.TimedAssignment then
					combatLogEventSpellID, spellCount, minTime =
						utilities.FindNearestCombatLogEvent(assignment.time, GetCurrentBossName(), value)
				end
				assignment = Private.classes.CombatLogEventAssignment:New(assignment, true)
				if combatLogEventSpellID and spellCount and minTime then
					assignment.time = utilities.Round(minTime, 1)
					assignment.combatLogEventSpellID = combatLogEventSpellID
					assignment.spellCount = spellCount
				end
				updateFields = true
			end
			assignment--[[@as CombatLogEventAssignment]].combatLogEventType = value
		elseif value == "Absolute Time" then
			if getmetatable(assignment) ~= Private.classes.TimedAssignment then
				local convertedTime = nil
				if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
					convertedTime = utilities.ConvertCombatLogEventTimeToAbsoluteTime(
						assignment.time,
						GetCurrentBossName(),
						assignment.combatLogEventSpellID,
						assignment.spellCount,
						assignment.combatLogEventType
					)
				end
				assignment = Private.classes.TimedAssignment:New(assignment, true)
				if convertedTime then
					assignment.time = utilities.Round(convertedTime, 1)
				end
				updateFields = true
			end
		elseif value == "Boss Phase" then
			if getmetatable(assignment) ~= Private.classes.PhasedAssignment then
				assignment = Private.classes.PhasedAssignment:New(assignment, true)
				updateFields = true
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
			assignment.spellInfo = spellInfo
			updatePreviewText = true
		end
	elseif dataType == "AssigneeType" then
		if value ~= "Individual" then
			assignment.assigneeNameOrRole = value
			updatePreviewText = true
		end
	elseif dataType == "Assignee" then
		assignment.assigneeNameOrRole = value
		updatePreviewText = true
	elseif dataType == "Time" then
		local timeValue = tonumber(value)
		if timeValue then
			if timeValue < 0 then
				assignmentEditor.timeEditBox:SetText(assignment.time)
			elseif
				getmetatable(assignment) == Private.classes.CombatLogEventAssignment
				or getmetatable(assignment) == Private.classes.PhasedAssignment
				or getmetatable(assignment) == Private.classes.TimedAssignment
			then
				assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time = tonumber(value)
			end
		end
	elseif dataType == "OptionalText" then
		assignment.text = value
		updatePreviewText = true
	elseif dataType == "Target" then
		assignment.targetName = value
		updatePreviewText = true
	end

	if updateFields then
		local previewText = Private:CreateNotePreviewText(assignment, GetCurrentRoster())
		assignmentEditor:PopulateFields(assignment, previewText, assignmentMetaTables)
	elseif updatePreviewText then
		local previewText = Private:CreateNotePreviewText(assignment, GetCurrentRoster())
		assignmentEditor.previewLabel:SetText(previewText)
	end

	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		for _, timelineAssignment in pairs(timeline:GetAssignments()) do
			if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
				utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, GetCurrentBossName())
				break
			end
		end
		timeline:UpdateTimeline()
		if
			assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
			and assignment--[[@as CombatLogEventAssignment]].spellCount
		then
			timeline:SelectBossAbility(
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
				assignment--[[@as CombatLogEventAssignment]].spellCount
			)
		else
			timeline:ClearSelectedBossAbilities()
		end
	end
end

---@return EPAssignmentEditor
local function CreateAssignmentEditor()
	local assignmentEditor = AceGUI:Create("EPAssignmentEditor")
	assignmentEditor.obj = Private.mainFrame
	assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
	assignmentEditor.frame:SetFrameLevel(10)
	assignmentEditor.frame:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
	assignmentEditor:SetLayout("EPVerticalLayout")
	assignmentEditor:SetCallback("OnRelease", function()
		local recent = Private.assignmentEditor.spellAssignmentDropdown:GetItemsFromDropdownItemMenu("Recent")
		for _, dropdownItemData in ipairs(recent) do
			tinsert(AddOn.db.profile.recentSpellAssignments, dropdownItemData)
		end
		while #AddOn.db.profile.recentSpellAssignments > maxNumberOfRecentItems do
			tremove(AddOn.db.profile.recentSpellAssignments, 1)
		end
		if Private.mainFrame then
			local timeline = Private.mainFrame:GetTimeline()
			if timeline then
				timeline:ClearSelectedAssignments()
				timeline:ClearSelectedBossAbilities()
			end
		end
		Private.assignmentEditor = nil
	end)
	assignmentEditor:SetCallback("DataChanged", HandleAssignmentEditorDataChanged)
	assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
	assignmentEditor:SetCallback("OkayButtonClicked", HandleAssignmentEditorOkayButtonClicked)
	assignmentEditor.spellAssignmentDropdown:AddItems(spellDropdownItems, "EPDropdownItemToggle")
	assignmentEditor.assigneeTypeDropdown:AddItems(assignmentTypeDropdownItems, "EPDropdownItemToggle")
	local assigneeDropdownItems = utilities.CreateAssigneeDropdownItems(GetCurrentRoster())
	assignmentEditor.assigneeDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
	assignmentEditor.targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
	assignmentEditor.spellAssignmentDropdown:SetItemDisabled("Recent", #AddOn.db.profile.recentSpellAssignments == 0)
	assignmentEditor.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu(
		"Recent",
		AddOn.db.profile.recentSpellAssignments
	)
	local dropdownItems = {}
	local boss = GetCurrentBoss()
	if boss then
		for _, ID in pairs(boss.sortedAbilityIDs) do
			local spellInfo = GetSpellInfo(ID)
			if spellInfo then
				local iconText = format("|T%s:16|t %s", spellInfo.iconID, spellInfo.name)
				tinsert(dropdownItems, { itemValue = ID, text = iconText })
			end
		end
	end
	assignmentEditor.combatLogEventSpellIDDropdown:AddItems(dropdownItems, "EPDropdownItemToggle")
	assignmentEditor:DoLayout()
	return assignmentEditor
end

local function CreateOptionsMenu()
	local optionsMenu = AceGUI:Create("EPOptions")
	optionsMenu.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
	optionsMenu.frame:SetFrameLevel(25)
	optionsMenu:SetLayout("EPVerticalLayout")
	optionsMenu:SetCallback("OnRelease", function()
		Private.optionsMenu = nil
	end)

	local keyBindingOptions = {
		{
			label = "Pan",
			type = "dropdown",
			description = "Pans the timeline to the left and right when holding this key.",
			category = "Timeline",
			values = {
				{ itemValue = "LeftButton", text = "Left Click" },
				{ itemValue = "Alt-LeftButton", text = "Alt + Left Click" },
				{ itemValue = "Ctrl-LeftButton", text = "Ctrl + Left Click" },
				{ itemValue = "Shift-LeftButton", text = "Shift + Left Click" },
				{ itemValue = "MiddleButton", text = "Middle Mouse Button" },
				{ itemValue = "Alt-MiddleButton", text = "Alt + Middle Mouse Button" },
				{ itemValue = "Ctrl-MiddleButton", text = "Ctrl + Middle Mouse Button" },
				{ itemValue = "Shift-MiddleButton", text = "Shift + Middle Mouse Button" },
				{ itemValue = "RightButton", text = "Right Click" },
				{ itemValue = "Alt-RightButton", text = "Alt + Right Click" },
				{ itemValue = "Ctrl-RightButton", text = "Ctrl + Right Click" },
				{ itemValue = "Shift-RightButton", text = "Shift + Right Click" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.pan
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.pan = key
			end,
			validate = function(key)
				if
					AddOn.db.profile.preferences.keyBindings.editAssignment == key
					or AddOn.db.profile.preferences.keyBindings.newAssignment == key
				then
					return false, AddOn.db.profile.preferences.keyBindings.pan
				end
				return true
			end,
		},
		{
			label = "Scroll",
			type = "dropdown",
			description = "Scrolls the timeline up and down.",
			category = "Timeline",
			values = {
				{ itemValue = "MouseScroll", text = "Mouse Scroll" },
				{ itemValue = "Alt-MouseScroll", text = "Alt + Mouse Scroll" },
				{ itemValue = "Ctrl-MouseScroll", text = "Ctrl + Mouse Scroll" },
				{ itemValue = "Shift-MouseScroll", text = "Shift + Mouse Scroll" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.scroll
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.scroll = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.zoom == key then
					return false, AddOn.db.profile.preferences.keyBindings.scroll
				end
				return true
			end,
		},
		{
			label = "Zoom",
			type = "dropdown",
			description = "Zooms in horizontally on the timeline.",
			category = "Timeline",
			values = {
				{ itemValue = "MouseScroll", text = "Mouse Scroll" },
				{ itemValue = "Alt-MouseScroll", text = "Alt + Mouse Scroll" },
				{ itemValue = "Ctrl-MouseScroll", text = "Ctrl + Mouse Scroll" },
				{ itemValue = "Shift-MouseScroll", text = "Shift + Mouse Scroll" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.zoom
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.zoom = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.scroll == key then
					return false, AddOn.db.profile.preferences.keyBindings.zoom
				end
				return true
			end,
		},
		{
			label = "Add Assignment",
			type = "dropdown",
			description = "Creates a new assignment when this key is pressed when hovering over the timeline.",
			category = "Assignment",
			values = {
				{ itemValue = "LeftButton", text = "Left Click" },
				{ itemValue = "Alt-LeftButton", text = "Alt + Left Click" },
				{ itemValue = "Ctrl-LeftButton", text = "Ctrl + Left Click" },
				{ itemValue = "Shift-LeftButton", text = "Shift + Left Click" },
				{ itemValue = "MiddleButton", text = "Middle Mouse Button" },
				{ itemValue = "Alt-MiddleButton", text = "Alt + Middle Mouse Button" },
				{ itemValue = "Ctrl-MiddleButton", text = "Ctrl + Middle Mouse Button" },
				{ itemValue = "Shift-MiddleButton", text = "Shift + Middle Mouse Button" },
				{ itemValue = "RightButton", text = "Right Click" },
				{ itemValue = "Alt-RightButton", text = "Alt + Right Click" },
				{ itemValue = "Ctrl-RightButton", text = "Ctrl + Right Click" },
				{ itemValue = "Shift-RightButton", text = "Shift + Right Click" },
			},
			get = function(_)
				return AddOn.db.profile.preferences.keyBindings.newAssignment
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.newAssignment = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.pan == key then
					return false, AddOn.db.profile.preferences.keyBindings.newAssignment
				end
				return true
			end,
		},
		{
			label = "Edit Assignment",
			type = "dropdown",
			description = "Opens the assignment editor when this key is pressed when hovering over an assignment spell icon.",
			category = "Assignment",
			values = {
				{ itemValue = "LeftButton", text = "Left Click" },
				{ itemValue = "Alt-LeftButton", text = "Alt + Left Click" },
				{ itemValue = "Ctrl-LeftButton", text = "Ctrl + Left Click" },
				{ itemValue = "Shift-LeftButton", text = "Shift + Left Click" },
				{ itemValue = "MiddleButton", text = "Middle Mouse Button" },
				{ itemValue = "Alt-MiddleButton", text = "Alt + Middle Mouse Button" },
				{ itemValue = "Ctrl-MiddleButton", text = "Ctrl + Middle Mouse Button" },
				{ itemValue = "Shift-MiddleButton", text = "Shift + Middle Mouse Button" },
				{ itemValue = "RightButton", text = "Right Click" },
				{ itemValue = "Alt-RightButton", text = "Alt + Right Click" },
				{ itemValue = "Ctrl-RightButton", text = "Ctrl + Right Click" },
				{ itemValue = "Shift-RightButton", text = "Shift + Right Click" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.editAssignment
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.editAssignment = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.pan == key then
					return false, AddOn.db.profile.preferences.keyBindings.editAssignment
				end
				return true
			end,
		},
	}

	local rowValues = {
		{ itemValue = "1", text = "1" },
		{ itemValue = "2", text = "2" },
		{ itemValue = "3", text = "3" },
		{ itemValue = "4", text = "4" },
		{ itemValue = "5", text = "5" },
		{ itemValue = "6", text = "6" },
		{ itemValue = "7", text = "7" },
		{ itemValue = "8", text = "8" },
		{ itemValue = "9", text = "9" },
		{ itemValue = "10", text = "10" },
		{ itemValue = "11", text = "11" },
		{ itemValue = "12", text = "12" },
	}

	local viewOptions = {
		{
			label = "Preferred Number of Assignments to Show",
			type = "dropdown",
			description = "The assignment timeline will attempt to expand or shrink to show this many rows.",
			category = nil,
			values = rowValues,
			get = function()
				return tostring(AddOn.db.profile.preferences.timelineRows.numberOfAssignmentsToShow)
			end,
			set = function(key)
				AddOn.db.profile.preferences.timelineRows.numberOfAssignmentsToShow = tonumber(key)
				local timeline = Private.mainFrame:GetTimeline()
				if timeline then
					timeline:UpdateHeight()
					Private.mainFrame:DoLayout()
				end
			end,
			validate = function(key)
				return true
			end,
		},
		{
			label = "Preferred Number of Boss Abilities to Show",
			type = "dropdown",
			description = "The boss ability timeline will attempt to expand or shrink to show this many rows.",
			category = nil,
			values = rowValues,
			get = function()
				return tostring(AddOn.db.profile.preferences.timelineRows.numberOfBossAbilitiesToShow)
			end,
			set = function(key)
				AddOn.db.profile.preferences.timelineRows.numberOfBossAbilitiesToShow = tonumber(key)
				local timeline = Private.mainFrame:GetTimeline()
				if timeline then
					timeline:UpdateHeight()
					Private.mainFrame:DoLayout()
				end
			end,
			validate = function(key)
				return true
			end,
		},
		{
			label = "Timeline Zoom Center",
			type = "radioButtonGroup",
			description = "Where to center the zoom when zooming in on the timeline.",
			category = "Assignment",
			values = {
				{ itemValue = "At cursor", text = "At cursor" },
				{ itemValue = "Middle of timeline", text = "Middle of timeline" },
			},
			get = function()
				if AddOn.db.profile.preferences.zoomCenteredOnCursor == true then
					return "At cursor"
				else
					return "Middle of timeline"
				end
			end,
			set = function(key)
				if key == "At cursor" then
					AddOn.db.profile.preferences.zoomCenteredOnCursor = true
				else
					AddOn.db.profile.preferences.zoomCenteredOnCursor = false
				end
			end,
		},
	}

	optionsMenu:AddOptionTab("Keybindings", keyBindingOptions, { "Assignment", "Timeline" })
	optionsMenu:AddOptionTab("View", viewOptions)
	optionsMenu:SetCurrentTab("Keybindings")

	local yPos = -(Private.mainFrame.frame:GetHeight() / 2) + (optionsMenu.frame:GetHeight() / 2)
	optionsMenu.frame:SetPoint("TOP", Private.mainFrame.frame, "TOP", 0, yPos)
	yPos = -(Private.mainFrame.frame:GetHeight() / 2) + (optionsMenu.frame:GetHeight() / 2)
	optionsMenu.frame:SetPoint("TOP", Private.mainFrame.frame, "TOP", 0, yPos)
	optionsMenu:DoLayout()

	return optionsMenu
end

local function HandleImportNoteFromString(importType)
	local text = Private.importEditBox:GetText()
	local textTable = utilities.SplitStringIntoTable(text)
	Private.importEditBox:Release()
	local bossName = nil
	local lastOpenNote = AddOn.db.profile.lastOpenNote
	local notes = AddOn.db.profile.notes

	if importType == "FromStringOverwrite" then
		notes[lastOpenNote].content = textTable
		bossName = Private:Note(lastOpenNote)
	elseif importType == "FromStringNew" then
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

	if bossName then
		interfaceUpdater.UpdateBossAbilityList(bossName, true)
		interfaceUpdater.UpdateTimelineBossAbilities(bossName)
		interfaceUpdater.UpdateAllAssignments(true, bossName)
	end
end

local function CreateImportEditBox(importType)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	Private.importEditBox = AceGUI:Create("EPEditBox")
	Private.importEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
	Private.importEditBox.frame:SetFrameLevel(30)
	Private.importEditBox.frame:SetPoint("CENTER")
	Private.importEditBox:SetTitle("Import Text")
	local buttonText
	if importType == "FromStringOverwrite" then
		buttonText = "Overwrite " .. AddOn.db.profile.lastOpenNote
	else
		buttonText = "Import As New EP note"
	end
	Private.importEditBox:ShowOkayButton(true, buttonText)
	Private.importEditBox:SetCallback("OnRelease", function()
		Private.importEditBox = nil
	end)
	Private.importEditBox:SetCallback("OkayButtonClicked", function()
		HandleImportNoteFromString(importType)
	end)
	Private.importEditBox:HighlightTextAndFocus()
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
			interfaceUpdater.UpdateBoss(bossDef.name, true)
		end
	end
end

---@param dropdown EPDropdown
---@param value number|string
---@param selected boolean
local function HandleBossAbilitySelectDropdownValueChanged(dropdown, value, selected)
	local bossIndex = Private.mainFrame:GetBossSelectDropdown():GetValue()
	local bossDef = bossUtilities.GetBossDefinition(bossIndex)
	if bossDef then
		local atLeastOneSelected = false
		for currentAbilityID, currentSelected in pairs(AddOn.db.profile.activeBossAbilities[bossDef.name]) do
			if currentAbilityID ~= value and currentSelected then
				atLeastOneSelected = true
				break
			end
		end
		if atLeastOneSelected then
			AddOn.db.profile.activeBossAbilities[bossDef.name][value] = selected
			interfaceUpdater.UpdateBoss(bossDef.name, false)
		else
			dropdown:SetItemIsSelected(value, true)
			AddOn.db.profile.activeBossAbilities[bossDef.name][value] = true
		end
	end
end

---@param value string
local function HandleAssignmentSortDropdownValueChanged(_, _, value)
	AddOn.db.profile.preferences.assignmentSortType = value
	interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossName())
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
	if bossName then
		interfaceUpdater.UpdateBoss(bossName, true)
		interfaceUpdater.UpdateAllAssignments(true, bossName)
	end
	local renameNoteLineEdit = Private.mainFrame:GetNoteLineEdit()
	if renameNoteLineEdit then
		renameNoteLineEdit:SetText(value)
	end
	Private.mainFrame:DoLayout()
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

---@param uniqueID integer
local function HandleTimelineAssignmentClicked(_, _, uniqueID)
	local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), uniqueID)
	if assignment then
		if not Private.assignmentEditor then
			Private.assignmentEditor = CreateAssignmentEditor()
		end
		local previewText = Private:CreateNotePreviewText(assignment, GetCurrentRoster())
		Private.assignmentEditor:PopulateFields(assignment, previewText, assignmentMetaTables)
		local timeline = Private.mainFrame:GetTimeline()
		if timeline then
			timeline:ClearSelectedAssignments()
			timeline:ClearSelectedBossAbilities()
			timeline:SelectAssignment(uniqueID)
			if
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				and assignment--[[@as CombatLogEventAssignment]].spellCount
			then
				timeline:SelectBossAbility(
					assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
					assignment--[[@as CombatLogEventAssignment]].spellCount
				)
			end
		end
	end
end

local function HandleAddAssigneeRowDropdownValueChanged(dropdown, _, value)
	if value == "Add Assignee" then
		return
	end

	for _, assignment in pairs(GetCurrentAssignments()) do
		if assignment.assigneeNameOrRole == value then
			dropdown:SetText("Add Assignee")
			return
		end
	end

	local assignment = Private.classes.TimedAssignment:New()
	assignment.assigneeNameOrRole = value
	tinsert(GetCurrentAssignments(), assignment)
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossName())
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	dropdown:SetText("Add Assignee")
end

---@param abilityInstance BossAbilityInstance
---@param assigneeIndex integer
---@param relativeAssignmentStartTime number
local function HandleCreateNewAssignment(_, _, abilityInstance, assigneeIndex, relativeAssignmentStartTime)
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.preferences.assignmentSortType,
		GetCurrentBossName()
	)
	local sortedAssigneesAndSpells =
		utilities.SortAssigneesWithSpellID(sorted, AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].collapsed)
	local nameAndSpell = sortedAssigneesAndSpells[assigneeIndex]
	if nameAndSpell then
		local assignment = Private.classes.Assignment:New()
		assignment.assigneeNameOrRole = nameAndSpell.assigneeNameOrRole
		if nameAndSpell.spellID then
			local spellInfo = GetSpellInfo(nameAndSpell.spellID)
			if spellInfo then
				assignment.spellInfo = spellInfo
			else
				assignment.spellInfo.spellID = nameAndSpell.spellID
			end
		end
		local createCombatLogAssignment = true -- TODO: Allow user to choose
		if createCombatLogAssignment then
			-- if abilityInstance.repeatInstance and abilityInstance.repeatCastIndex then
			-- else
			local combatLogEventAssignment = Private.classes.CombatLogEventAssignment:New(assignment)
			combatLogEventAssignment.combatLogEventType = "SCS"
			combatLogEventAssignment.time = utilities.Round(relativeAssignmentStartTime, 1)
			combatLogEventAssignment.phase = abilityInstance.phase
			combatLogEventAssignment.spellCount = abilityInstance.spellOccurrence
			combatLogEventAssignment.combatLogEventSpellID = abilityInstance.spellID
			tinsert(GetCurrentAssignments(), combatLogEventAssignment)
			-- end
			-- elseif abilityInstance.repeatInstance then
		else
			local timedAssignment = Private.classes.TimedAssignment:New(assignment)
			timedAssignment.time = abilityInstance.castTime
			tinsert(GetCurrentAssignments(), timedAssignment)
		end
		interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossName())
		HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	end
end

local function HandleCreateNewNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local notes = AddOn.db.profile.notes
	local newNoteName = utilities.CreateUniqueNoteName(notes)

	notes[newNoteName] = Private.classes.EncounterPlannerDbNote:New()
	AddOn.db.profile.lastOpenNote = newNoteName

	local bossDef = bossUtilities.GetBossDefinition(Private.mainFrame:GetBossSelectDropdown():GetValue())
	if bossDef then
		notes[newNoteName].bossName = bossDef.name
	end

	interfaceUpdater.UpdateAllAssignments(true, notes[newNoteName].bossName)

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

local function HandleDeleteCurrentNoteButtonClicked()
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
					interfaceUpdater.UpdateBoss(bossName, true)
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
		interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossName())
	end
end

---@param importDropdown EPDropdown
---@param value any
local function HandleImportDropdownValueChanged(importDropdown, _, value)
	if value == "Import" then
		return
	end
	if not Private.importEditBox then
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
			if bossName then
				interfaceUpdater.UpdateBoss(bossName, true)
				interfaceUpdater.UpdateAllAssignments(true, bossName)
			end
		elseif value == "FromStringOverwrite" or value == "FromStringNew" then
			CreateImportEditBox(value)
		end
	end
	importDropdown:SetText("Import")
end

local function HandleExportButtonClicked()
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
		Private.exportEditBox:HighlightTextAndFocus()
	end
end

function Private:CreateGUI()
	local bossName = nil
	local notes = AddOn.db.profile.notes
	local lastOpenNote = AddOn.db.profile.lastOpenNote
	if not lastOpenNote or lastOpenNote == "" then
		local defaultNoteName = "SharedMRTNote"
		bossName = Private:Note(defaultNoteName, true)
		if not notes[defaultNoteName] then -- MRT not loaded
			defaultNoteName = utilities.CreateUniqueNoteName(notes)
			notes[defaultNoteName] = Private.classes.EncounterPlannerDbNote:New()
		end
		AddOn.db.profile.lastOpenNote = defaultNoteName
	end

	if bossName == nil then
		local note = notes[lastOpenNote]
		if note.bossName then
			bossName = note.bossName
		else
			bossName = "Ulgrax the Devourer"
			note.bossName = bossName
		end
	end

	Private.mainFrame = AceGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("EPVerticalLayout")
	Private.mainFrame:SetCallback("SettingsButtonClicked", function()
		if not Private.optionsMenu then
			Private.optionsMenu = CreateOptionsMenu()
		end
	end)
	Private.mainFrame:SetCallback("CloseButtonClicked", function()
		local width, height = Private.mainFrame.frame:GetSize()
		AddOn.db.profile.windowSize = { x = width, y = height }
		Private.mainFrame:Release()
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
		if Private.optionsMenu then
			Private.optionsMenu:Release()
		end
	end)
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
		if Private.optionsMenu then
			Private.optionsMenu:Release()
		end
	end)
	Private.mainFrame:SetCallback("CollapseAllButtonClicked", function()
		local currentBossName = GetCurrentBossName()
		local sortedTimelineAssignments = utilities.SortAssignments(
			GetCurrentAssignments(),
			GetCurrentRoster(),
			AddOn.db.profile.preferences.assignmentSortType,
			currentBossName
		)
		local collapsed = AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].collapsed
		for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
			collapsed[timelineAssignment.assignment.assigneeNameOrRole] = true
		end
		interfaceUpdater.UpdateAllAssignments(true, currentBossName)
	end)
	Private.mainFrame:SetCallback("ExpandAllButtonClicked", function()
		local currentBossName = GetCurrentBossName()
		local sortedTimelineAssignments = utilities.SortAssignments(
			GetCurrentAssignments(),
			GetCurrentRoster(),
			AddOn.db.profile.preferences.assignmentSortType,
			currentBossName
		)
		local collapsed = AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].collapsed
		for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
			collapsed[timelineAssignment.assignment.assigneeNameOrRole] = false
		end
		interfaceUpdater.UpdateAllAssignments(false, currentBossName)
		Private.mainFrame:GetTimeline():SetMaxAssignmentHeight()
		Private.mainFrame:DoLayout()
	end)

	local bossContainer = AceGUI:Create("EPContainer")
	bossContainer:SetLayout("EPVerticalLayout")
	bossContainer:SetSpacing(unpack(dropdownContainerSpacing))
	bossContainer:SetWidth(topContainerDropdownWidth)

	local bossSelectContainer = AceGUI:Create("EPContainer")
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
	bossAbilitySelectContainer:SetLayout("EPHorizontalLayout")
	bossAbilitySelectContainer:SetFullWidth(true)
	bossAbilitySelectContainer:SetSpacing(unpack(noteContainerSpacing))

	local bossAbilitySelectDropdown = AceGUI:Create("EPDropdown")
	bossAbilitySelectDropdown:SetCallback("OnValueChanged", function(dropdown, _, value, selected)
		HandleBossAbilitySelectDropdownValueChanged(dropdown, value, selected)
	end)
	bossAbilitySelectDropdown:SetMultiselect(true)
	bossAbilitySelectDropdown:SetText("Active Boss Abilities")

	local assignmentSortAndEditRosterContainer = AceGUI:Create("EPContainer")
	assignmentSortAndEditRosterContainer:SetLayout("EPVerticalLayout")
	assignmentSortAndEditRosterContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local assignmentSortContainer = AceGUI:Create("EPContainer")
	assignmentSortContainer:SetLayout("EPHorizontalLayout")
	assignmentSortContainer:SetSpacing(dropdownContainerSpacing[1] * 2, dropdownContainerSpacing[2])

	local assignmentSortLabel = AceGUI:Create("EPLabel")
	assignmentSortLabel:SetText("Assignment Sort Priority:", 0)
	assignmentSortLabel:SetFrameWidthFromText()
	assignmentSortLabel:SetFullWidth(true)

	local assignmentSortDropdown = AceGUI:Create("EPDropdown")
	assignmentSortDropdown:SetWidth(topContainerDropdownWidth)
	assignmentSortDropdown:AddItems({
		{ itemValue = "Alphabetical", text = "Alphabetical" },
		{ itemValue = "First Appearance", text = "First Appearance" },
		{ itemValue = "Role > Alphabetical", text = "Role > Alphabetical" },
		{ itemValue = "Role > First Appearance", text = "Role > First Appearance" },
	}, "EPDropdownItemToggle")
	assignmentSortDropdown:SetCallback("OnValueChanged", HandleAssignmentSortDropdownValueChanged)

	local editRosterButton = AceGUI:Create("EPButton")
	editRosterButton:SetCallback("Clicked", CreateRosterEditor)
	editRosterButton:SetText("Edit Roster")
	editRosterButton:SetWidthFromText()

	local spacer = AceGUI:Create("EPSpacer")
	spacer:SetFillSpace(true)

	local outerNoteContainer = AceGUI:Create("EPContainer")
	outerNoteContainer:SetLayout("EPVerticalLayout")
	outerNoteContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local noteContainer = AceGUI:Create("EPContainer")
	noteContainer:SetLayout("EPHorizontalLayout")
	noteContainer:SetFullWidth(true)
	noteContainer:SetSpacing(unpack(noteContainerSpacing))

	local noteLabel = AceGUI:Create("EPLabel")
	noteLabel:SetText("Current:", unpack(dropdownContainerLabelSpacing))

	local noteDropdown = AceGUI:Create("EPDropdown")
	noteDropdown:SetWidth(topContainerDropdownWidth)
	local noteDropdownData = {}
	noteDropdown:SetCallback("OnValueChanged", HandleNoteDropdownValueChanged)
	for noteName, _ in pairs(AddOn.db.profile.notes) do
		tinsert(noteDropdownData, { itemValue = noteName, text = noteName })
	end
	noteDropdown:AddItems(noteDropdownData, "EPDropdownItemToggle")

	local renameNoteLineEdit = AceGUI:Create("EPLineEdit")
	renameNoteLineEdit:SetWidth(topContainerDropdownWidth)
	renameNoteLineEdit:SetCallback("OnTextChanged", HandleNoteTextChanged)

	local renameNoteContainer = AceGUI:Create("EPContainer")
	renameNoteContainer:SetLayout("EPHorizontalLayout")
	renameNoteContainer:SetSpacing(unpack(noteContainerSpacing))

	local renameNoteLabel = AceGUI:Create("EPLabel")
	renameNoteLabel:SetText("Rename current:", unpack(dropdownContainerLabelSpacing))
	renameNoteLabel:SetFrameWidthFromText()
	noteLabel:SetWidth(renameNoteLabel.frame:GetWidth())

	local noteButtonContainer = AceGUI:Create("EPContainer")
	noteButtonContainer:SetLayout("EPVerticalLayout")
	noteButtonContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local createNewButton = AceGUI:Create("EPButton")
	createNewButton:SetCallback("Clicked", HandleCreateNewNoteButtonClicked)
	createNewButton:SetText("New EP note")

	local deleteButton = AceGUI:Create("EPButton")
	deleteButton:SetCallback("Clicked", HandleDeleteCurrentNoteButtonClicked)
	deleteButton:SetText("Delete EP note")

	local importExportContainer = AceGUI:Create("EPContainer")
	importExportContainer:SetLayout("EPVerticalLayout")
	importExportContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local importDropdown = AceGUI:Create("EPDropdown")
	importDropdown:SetWidth(topContainerDropdownWidth)
	importDropdown:SetTextCentered(true)
	importDropdown:SetCallback("OnValueChanged", HandleImportDropdownValueChanged)
	importDropdown:SetText("Import")
	local importDropdownData = {
		{
			itemValue = "From MRT",
			text = "From MRT",
			dropdownItemMenuData = {
				{ itemValue = "FromMRTOverwrite", text = "Overwrite current EP note" },
				{ itemValue = "FromMRTNew", text = "Create new EP note" },
			},
		},
		{
			itemValue = "From String",
			text = "From String",
			dropdownItemMenuData = {
				{ itemValue = "FromStringOverwrite", text = "Overwrite current EP note" },
				{ itemValue = "FromStringNew", text = "Create new EP note" },
			},
		},
	}
	importDropdown:AddItems(importDropdownData, "EPDropdownItemToggle", true)

	local exportButton = AceGUI:Create("EPButton")
	exportButton:SetWidth(topContainerDropdownWidth)
	exportButton:SetCallback("Clicked", HandleExportButtonClicked)
	exportButton:SetText("Export")

	bossSelectContainer:AddChild(bossDropdown)
	bossAbilitySelectContainer:AddChild(bossAbilitySelectDropdown)

	bossContainer:AddChild(bossSelectContainer)
	bossContainer:AddChild(bossAbilitySelectContainer)
	assignmentSortContainer:AddChild(assignmentSortLabel)
	assignmentSortContainer:AddChild(assignmentSortDropdown)
	assignmentSortAndEditRosterContainer:AddChild(assignmentSortContainer)
	assignmentSortAndEditRosterContainer:AddChild(editRosterButton)
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

	local topLeftContainer = AceGUI:Create("EPContainer")
	topLeftContainer:SetLayout("EPHorizontalLayout")
	topLeftContainer:SetHeight(topContainerHeight)
	topLeftContainer:AddChild(outerNoteContainer)
	topLeftContainer:AddChild(noteButtonContainer)
	topLeftContainer:AddChild(importExportContainer)
	topLeftContainer:SetSelfAlignment("right")

	topContainer:AddChild(bossContainer)
	topContainer:AddChild(assignmentSortAndEditRosterContainer)
	topContainer:AddChild(topLeftContainer)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetPreferences(AddOn.db.profile.preferences)
	timeline.CalculateAssignmentTimeFromStart = function(assignment)
		return utilities.ConvertAbsoluteTimeToCombatLogEventTime(
			assignment.startTime,
			GetCurrentBossName(),
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.combatLogEventSpellID,
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.spellCount,
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.combatLogEventType
		)
	end
	timeline.GetMinimumCombatLogEventTime = function(assignment)
		return utilities.GetMinimumCombatLogEventTime(
			GetCurrentBossName(),
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.combatLogEventSpellID,
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.spellCount,
			assignment
				.assignment--[[@as CombatLogEventAssignment]]
				.combatLogEventType
		)
	end

	timeline:SetFullWidth(true)
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)
	timeline:SetCallback("ResizeBoundsCalculated", function(_, _, minHeight, maxHeight)
		local heightDiff = Private.mainFrame.frame:GetHeight() - timeline.frame:GetHeight()
		local minWidth = 0
		for _, child in pairs(topContainer.children) do
			if child.type ~= "EPSpacer" then
				minWidth = minWidth + child.frame:GetWidth() + 10
			end
		end
		Private.mainFrame.frame:SetResizeBounds(minWidth + 20 - 10, minHeight + heightDiff, nil, maxHeight + heightDiff)
	end)
	local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
	addAssigneeDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeDropdown:SetText("Add Assignee")
	addAssigneeDropdown:AddItems(
		utilities.CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster()),
		"EPDropdownItemToggle",
		true
	)

	Private.mainFrame:AddChild(topContainer)
	Private.mainFrame:AddChild(timeline)

	-- Set default values
	assignmentSortDropdown:SetValue(AddOn.db.profile.preferences.assignmentSortType)
	noteDropdown:SetValue(AddOn.db.profile.lastOpenNote)
	renameNoteLineEdit:SetText(AddOn.db.profile.lastOpenNote)

	interfaceUpdater.UpdateBoss(bossName, true)
	utilities.UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
	interfaceUpdater.UpdateAllAssignments(true, bossName)
	if AddOn.db.profile.windowSize then
		Private.mainFrame:SetWidth(AddOn.db.profile.windowSize.x)
		Private.mainFrame:SetHeight(AddOn.db.profile.windowSize.y)
	end
	Private.mainFrame.frame:SetPoint("CENTER")
	local x, y = Private.mainFrame.frame:GetLeft(), Private.mainFrame.frame:GetTop()
	Private.mainFrame.frame:ClearAllPoints()
	Private.mainFrame.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
	Private.mainFrame:DoLayout()
	timeline:UpdateTimeline()
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
				if not note.collapsed then
					note.collapsed = {}
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
	spellDropdownItems = utilities.CreateSpellAssignmentDropdownItems()
	assignmentTypeDropdownItems = utilities.CreateAssignmentTypeDropdownItems()
	classDropdownItems = utilities.CreateClassDropdownItemData()
	self.OnInitialize = nil
end

function AddOn:OnEnable()
	--self:Refresh()
end

function AddOn:Refresh(db, newProfile) end

---@param input string|nil
function AddOn:SlashCommand(input)
	if not input or input:trim() == "" then
		if DevTool then
			DevTool:AddData(Private)
		end
		if not Private.mainFrame then
			Private:CreateGUI()
		end
	elseif input then
		local trimmed = input:trim():lower()
		if trimmed == "close" then
			if Private.mainFrame then
				Private.mainFrame:Release()
			end
		elseif trimmed == "dolayout" then
			if Private.mainFrame then
				Private.mainFrame:DoLayout()
			end
		elseif trimmed == "updatetimeline" then
			if Private.mainFrame then
				local timeline = Private.mainFrame:GetTimeline()
				if timeline then
					timeline:UpdateTimeline()
				end
			end
		end
	end
end
