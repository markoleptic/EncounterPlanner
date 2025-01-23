local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn
local L = Private.L
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")

local abs = math.abs
local EJ_GetCreatureInfo = EJ_GetCreatureInfo
local EJ_SelectEncounter = EJ_SelectEncounter
local format = format
local getmetatable = getmetatable
local GetSpellInfo = C_Spell.GetSpellInfo
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local min, max = math.min, math.max
local pairs = pairs
local sub = string.sub
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local UnitIsGroupAssistant, UnitIsGroupLeader = UnitIsGroupAssistant, UnitIsGroupLeader
local unpack = unpack
local wipe = wipe

local assignmentMetaTables = {
	CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
	TimedAssignment = Private.classes.TimedAssignment,
	PhasedAssignment = Private.classes.PhasedAssignment,
}
local dropdownContainerLabelSpacing = 4
local dropdownContainerSpacing = { 0, 4 }
local mainFrameSpacing = { 0, 20 }
local mainFramePadding = { 10, 10, 10, 10 }
local topContainerDropdownWidth = 200
local spellDropdownItems = {}
local assignmentTypeDropdownItems = {}
local classDropdownItems = {}
local maxNumberOfRecentItems = 10
local menuButtonFontSize = 16
local menuButtonHorizontalPadding = 8
local topContainerWidgetFontSize = 14
local topContainerWidgetHeight = 26
local assignmentEditorWidth = 240
local defaultMaxVisibleDropdownItems = 8
local preferencesMenuButtonBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}
local preferencesMenuButtonBackdropColor = { 0.1, 0.1, 0.1, 1 }
local preferencesMenuButtonBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local preferencesMenuButtonColor = { 0.25, 0.25, 0.5, 0.5 }

---@return table<string, RosterEntry>
local function GetCurrentRoster()
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	local plan = AddOn.db.profile.plans[lastOpenPlan]
	return plan.roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	local plan = AddOn.db.profile.plans[lastOpenPlan]
	return plan.assignments
end

---@return Boss|nil
local function GetCurrentBoss()
	return bossUtilities.GetBoss(Private.mainFrame.bossSelectDropdown:GetValue())
end

---@return integer
local function GetCurrentBossDungeonEncounterID()
	return Private.mainFrame.bossSelectDropdown:GetValue()
end

---@param currentRosterMap table<integer, RosterWidgetMapping>
---@param sharedRosterMap table<integer, RosterWidgetMapping>
local function HandleRosterEditingFinished(_, _, currentRosterMap, sharedRosterMap)
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	if lastOpenPlan then
		local tempRoster = {}
		for _, rosterWidgetMapping in ipairs(currentRosterMap) do
			tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
		end
		AddOn.db.profile.plans[lastOpenPlan].roster = tempRoster
	end

	local tempRoster = {}
	for _, rosterWidgetMapping in ipairs(sharedRosterMap) do
		tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
	end
	AddOn.db.profile.sharedRoster = tempRoster

	Private.rosterEditor:Release()
	utilities.UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster())
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())

	if Private.assignmentEditor then
		local assigneeTypeDropdown = Private.assignmentEditor.assigneeTypeDropdown
		local targetDropdown = Private.assignmentEditor.targetDropdown
		local assigneeDropdownItems = utilities.CreateAssigneeDropdownItems(GetCurrentRoster())
		local updatedDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems(
			GetCurrentRoster(),
			assignmentTypeDropdownItems,
			assigneeDropdownItems
		)
		local previousValue = assigneeTypeDropdown:GetValue()
		assigneeTypeDropdown:Clear()
		assigneeTypeDropdown:AddItems(updatedDropdownItems, "EPDropdownItemToggle")
		assigneeTypeDropdown:SetValue(previousValue)

		local previousTargetValue = targetDropdown:GetValue()
		targetDropdown:Clear()
		targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		targetDropdown:SetValue(previousTargetValue)
		Private.assignmentEditor:HandleRosterChanged()
	end
end

---@param rosterTab EPRosterEditorTab
local function HandleImportCurrentGroupButtonClicked(_, _, rosterTab)
	local importRosterWidgetMapping = nil
	local noChangeRosterWidgetMapping = nil
	if rosterTab == "Shared Roster" then
		noChangeRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		importRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
	elseif rosterTab == "Current Plan Roster" then
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
		if rosterTab == "Shared Roster" then
			Private.rosterEditor:SetRosters(noChangeRoster, importRoster)
		elseif rosterTab == "Current Plan Roster" then
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
	if rosterTab == "Shared Roster" then
		fromRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		toRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
	elseif rosterTab == "Current Plan Roster" then
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
					if toRoster[name].class == "" then
						toRoster[name].class = dbEntry.class
						toRoster[name].classColoredName = ""
					end
				end
				if dbEntry.role then
					if toRoster[name].role == "" then
						toRoster[name].role = dbEntry.role
					end
				end
			end
		end
		if rosterTab == "Shared Roster" then
			Private.rosterEditor:SetRosters(fromRoster, toRoster)
		elseif rosterTab == "Current Plan Roster" then
			Private.rosterEditor:SetRosters(toRoster, fromRoster)
		end
	end
end

---@param openToTab string
local function CreateRosterEditor(openToTab)
	if Private.IsSimulatingBoss() then
		return
	end
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
		Private.rosterEditor.frame:SetParent(UIParent)
		Private.rosterEditor.frame:SetFrameLevel(80)
		Private.rosterEditor:SetClassDropdownData(classDropdownItems)
		Private.rosterEditor:SetRosters(GetCurrentRoster(), AddOn.db.profile.sharedRoster)
		Private.rosterEditor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		Private.rosterEditor:SetCurrentTab(openToTab)
		Private.rosterEditor:SetPoint("TOP", UIParent, "TOP", 0, -Private.rosterEditor.frame:GetBottom())
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
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
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
	local updateAssignments = false

	if dataType == "AssignmentType" then
		if value == "SCC" or value == "SCS" or value == "SAA" or value == "SAR" then -- Combat Log Event
			if getmetatable(assignment) ~= Private.classes.CombatLogEventAssignment then
				local combatLogEventSpellID, spellCount, minTime = nil, nil, nil
				if getmetatable(assignment) == Private.classes.TimedAssignment then
					combatLogEventSpellID, spellCount, minTime = utilities.FindNearestCombatLogEvent(
						assignment.time,
						GetCurrentBossDungeonEncounterID(),
						value,
						true
					)
				end
				local boss = GetCurrentBoss()
				if boss then
					assignment = Private.classes.CombatLogEventAssignment:New(assignment, true)
					if combatLogEventSpellID and spellCount and minTime then
						local castTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable(boss.dungeonEncounterID)
						local bossPhaseTable = bossUtilities.GetOrderedBossPhases(boss.dungeonEncounterID)
						if castTimeTable and bossPhaseTable then
							if
								castTimeTable[combatLogEventSpellID]
								and castTimeTable[combatLogEventSpellID][spellCount]
							then
								local orderedBossPhaseIndex =
									castTimeTable[combatLogEventSpellID][spellCount].bossPhaseOrderIndex
								assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
								assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
							end
						end
						assignment.time = utilities.Round(minTime, 1)
						assignment.combatLogEventSpellID = combatLogEventSpellID
						assignment.spellCount = spellCount
					end
					updateFields = true
				end
			end
			assignment--[[@as CombatLogEventAssignment]].combatLogEventType = value
		elseif value == "Fixed Time" then
			if getmetatable(assignment) ~= Private.classes.TimedAssignment then
				local convertedTime = nil
				if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
					convertedTime = utilities.ConvertCombatLogEventTimeToAbsoluteTime(
						assignment.time,
						GetCurrentBossDungeonEncounterID(),
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
			local spellID = tonumber(value)
			if spellID then
				local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
				local spellCount = assignment--[[@as CombatLogEventAssignment]].spellCount
				if bossUtilities.IsValidSpellCount(bossDungeonEncounterID, spellID, spellCount) then
					assignment--[[@as CombatLogEventAssignment]].spellCount = spellCount
					assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID = spellID
				else
					local newSpellCount, newMinTime = utilities.FindNearestSpellCount(
						assignment.time,
						bossDungeonEncounterID,
						assignment.combatLogEventType,
						assignment.combatLogEventSpellID,
						spellCount,
						spellID,
						true
					)
					if newSpellCount and newMinTime then
						assignment--[[@as CombatLogEventAssignment]].time = newMinTime
						assignment--[[@as CombatLogEventAssignment]].spellCount = newSpellCount
						assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID = spellID
					end
				end
			end
			updateFields = true
		end
	elseif dataType == "CombatLogEventSpellCount" then
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			local spellCount = tonumber(value)
			if spellCount then
				local spellID = assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				if bossUtilities.IsValidSpellCount(GetCurrentBossDungeonEncounterID(), spellID, spellCount) then
					assignment--[[@as CombatLogEventAssignment]].spellCount = spellCount
				end
			end
			updateFields = true
		end
	elseif dataType == "PhaseNumber" then
		if getmetatable(assignment) == Private.classes.PhasedAssignment then
			local phase = tonumber(value, 10)
			if phase then
				assignment--[[@as PhasedAssignment]].phase = phase
			end
		end
	elseif dataType == "SpellAssignment" then
		if value == constants.kInvalidAssignmentSpellID then
			if assignment.text:len() > 0 then
				assignment.spellInfo = {
					name = "",
					iconID = 0,
					originalIconID = 0,
					castTime = 0,
					minRange = 0,
					maxRange = 0,
					spellID = constants.kTextAssignmentSpellID,
				}
			else
				assignment.spellInfo = {
					name = "",
					iconID = 0,
					originalIconID = 0,
					castTime = 0,
					minRange = 0,
					maxRange = 0,
					spellID = constants.kInvalidAssignmentSpellID,
				}
			end
		else
			local spellInfo = GetSpellInfo(value)
			if spellInfo then
				assignment.spellInfo = spellInfo
			end
		end
		updateAssignments = true
		updatePreviewText = true
	elseif dataType == "AssigneeType" then
		assignment.assigneeNameOrRole = value
		updatePreviewText = true
		updateAssignments = true
	elseif dataType == "Time" then
		local timeMinutes = tonumber(assignmentEditor.timeMinuteLineEdit:GetText())
		local timeSeconds = tonumber(assignmentEditor.timeSecondLineEdit:GetText())
		local newTime = assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time
		if timeMinutes and timeSeconds then
			local roundedMinutes = utilities.Round(timeMinutes, 0)
			local roundedSeconds = utilities.Round(timeSeconds, 1)
			local timeValue = roundedMinutes * 60 + roundedSeconds
			local maxTime = Private.mainFrame.timeline.GetTotalTimelineDuration()
			if timeValue < 0 or timeValue > maxTime then
				newTime = max(min(timeValue, maxTime), 0)
			else
				newTime = timeValue
			end
		end
		if
			getmetatable(assignment) == Private.classes.CombatLogEventAssignment
			or getmetatable(assignment) == Private.classes.PhasedAssignment
			or getmetatable(assignment) == Private.classes.TimedAssignment
		then
			newTime = utilities.Round(newTime, 1)
			assignment--[[@as CombatLogEventAssignment|PhasedAssignment|TimedAssignment]].time = newTime
		end
		local minutes, seconds = utilities.FormatTime(newTime)
		assignmentEditor.timeMinuteLineEdit:SetText(minutes)
		assignmentEditor.timeSecondLineEdit:SetText(seconds)
	elseif dataType == "OptionalText" then
		assignment.text = value
		if assignment.text:len() > 0 and assignment.spellInfo.spellID == constants.kInvalidAssignmentSpellID then
			assignment.spellInfo.spellID = constants.kTextAssignmentSpellID
			updateAssignments = true
		elseif assignment.text:len() == 0 and assignment.spellInfo.spellID == constants.kTextAssignmentSpellID then
			assignment.spellInfo.spellID = constants.kInvalidAssignmentSpellID
			updateAssignments = true
		end
		updatePreviewText = true
	elseif dataType == "Target" then
		assignment.targetName = value
		updatePreviewText = true
	end

	if updateFields or updatePreviewText then
		local previewText = utilities.CreateReminderText(assignment, GetCurrentRoster(), true)
		assignmentEditor:PopulateFields(assignment, previewText, assignmentMetaTables)
	elseif updatePreviewText then
		local previewText = utilities.CreateReminderText(assignment, GetCurrentRoster(), true)
		assignmentEditor.previewLabel:SetText(previewText, 0)
	end

	local timeline = Private.mainFrame.timeline
	if timeline then
		for _, timelineAssignment in pairs(timeline:GetAssignments()) do
			if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
				utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, GetCurrentBossDungeonEncounterID())
				break
			end
		end
		timeline:UpdateTimeline()
		timeline:ClearSelectedBossAbilities()
		if
			assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
			and assignment--[[@as CombatLogEventAssignment]].spellCount
		then
			timeline:SelectBossAbility(
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
				assignment--[[@as CombatLogEventAssignment]].spellCount,
				true
			)
		end
	end
	if updateAssignments then
		interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
		if timeline then
			timeline:ScrollAssignmentIntoView(assignment.uniqueID)
		end
	end
end

---@return EPAssignmentEditor
local function CreateAssignmentEditor()
	local assignmentEditor = AceGUI:Create("EPAssignmentEditor")
	assignmentEditor.FormatTime = utilities.FormatTime
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
			local timeline = Private.mainFrame.timeline
			if timeline then
				timeline:ClearSelectedAssignments()
				timeline:ClearSelectedBossAbilities()
			end
		end
		Private.assignmentEditor = nil
	end)
	assignmentEditor:SetCallback("DataChanged", HandleAssignmentEditorDataChanged)
	assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
	assignmentEditor:SetCallback("CloseButtonClicked", function()
		Private.assignmentEditor:Release()
		interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
	end)
	assignmentEditor.spellAssignmentDropdown:AddItems(spellDropdownItems, "EPDropdownItemToggle")
	local assigneeDropdownItems = utilities.CreateAssigneeDropdownItems(GetCurrentRoster())
	local updatedDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems(
		GetCurrentRoster(),
		assignmentTypeDropdownItems,
		assigneeDropdownItems
	)
	assignmentEditor.assigneeTypeDropdown:AddItems(updatedDropdownItems, "EPDropdownItemToggle")
	assignmentEditor.targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
	assignmentEditor.spellAssignmentDropdown:SetItemEnabled("Recent", #AddOn.db.profile.recentSpellAssignments > 0)
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
	assignmentEditor:SetWidth(assignmentEditorWidth)
	assignmentEditor:DoLayout()
	return assignmentEditor
end

local function HandleImportPlanFromString(importType)
	local text = Private.importEditBox:GetText()
	Private.importEditBox:Release()
	local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	local plans = AddOn.db.profile.plans

	if importType == "FromStringOverwrite" then
		bossDungeonEncounterID = Private:ImportPlanFromNote(lastOpenPlan, bossDungeonEncounterID, text)
			or bossDungeonEncounterID
	elseif importType == "FromStringNew" then
		local bossName = bossUtilities.GetBossName(bossDungeonEncounterID)
		local newPlanName = utilities.CreateUniquePlanName(plans, bossName --[[@as string]])
		plans[newPlanName] = Private.classes.Plan:New(nil, newPlanName)
		bossDungeonEncounterID = Private:ImportPlanFromNote(newPlanName, bossDungeonEncounterID, text)
			or bossDungeonEncounterID
		AddOn.db.profile.lastOpenPlan = newPlanName
		interfaceUpdater.AddPlanToDropdown(newPlanName, true)
	end

	interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
	interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
end

local function CreateImportEditBox(importType)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	Private.importEditBox = AceGUI:Create("EPEditBox")
	Private.importEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
	Private.importEditBox.frame:SetFrameLevel(30)
	Private.importEditBox.frame:SetPoint("CENTER")
	Private.importEditBox:SetTitle(L["Import Text"])
	local buttonText
	if importType == "FromStringOverwrite" then
		buttonText = L["Overwrite"] .. " " .. AddOn.db.profile.lastOpenPlan
	else
		buttonText = L["Import As New Plan"]
	end
	Private.importEditBox:ShowOkayButton(true, buttonText)
	Private.importEditBox:SetCallback("OnRelease", function()
		Private.importEditBox = nil
	end)
	Private.importEditBox:SetCallback("OkayButtonClicked", function()
		HandleImportPlanFromString(importType)
	end)
	Private.importEditBox:HighlightTextAndFocus()
end

---@param boss Boss
---@return table<integer, string>
local function GetLongPhaseNames(boss)
	local longPhaseNames = {}
	for index, phase in ipairs(boss.phases) do
		local bossPhaseName = phase.name or index
		if type(bossPhaseName) == "string" then
			local intMatch = bossPhaseName:match("^Int(%d+)")
			if intMatch then
				bossPhaseName = L["Intermission"] .. " " .. intMatch
			end
		elseif type(bossPhaseName) == "number" then
			bossPhaseName = L["Phase"] .. " " .. bossPhaseName
		end
		tinsert(longPhaseNames, bossPhaseName)
	end
	return longPhaseNames
end

local function CreatePhaseLengthEditor()
	if not Private.phaseLengthEditor then
		local phaseLengthEditor = AceGUI:Create("EPPhaseLengthEditor")
		phaseLengthEditor.FormatTime = utilities.FormatTime
		phaseLengthEditor:SetCallback("OnRelease", function()
			Private.phaseLengthEditor = nil
		end)
		phaseLengthEditor:SetCallback("CloseButtonClicked", function()
			Private.phaseLengthEditor:Release()
		end)
		phaseLengthEditor:SetCallback("ResetAllButtonClicked", function()
			local customPhaseDurations = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseDurations
			wipe(customPhaseDurations)
			local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
			interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
		end)
		phaseLengthEditor:SetCallback("DataChanged", function(_, _, phaseName, minLineEdit, secLineEdit)
			local boss = GetCurrentBoss()
			if boss then
				local previousDuration
				local totalBossDurationWithoutCurrent = 0.0
				local longPhaseNames = GetLongPhaseNames(boss)
				for index, phase in ipairs(boss.phases) do
					if phaseName == longPhaseNames[index] then
						previousDuration = phase.duration
					else
						totalBossDurationWithoutCurrent = totalBossDurationWithoutCurrent + phase.duration
					end
				end

				local formatAndReturn = false
				local newDuration = previousDuration
				local timeMinutes = tonumber(minLineEdit:GetText())
				local timeSeconds = tonumber(secLineEdit:GetText())

				if timeMinutes and timeSeconds then
					local roundedMinutes = utilities.Round(timeMinutes, 0)
					local roundedSeconds = utilities.Round(timeSeconds, 1)
					newDuration = roundedMinutes * 60 + roundedSeconds
					if abs(newDuration - previousDuration) < 0.01 then
						formatAndReturn = true
					end
					local maxTime = 1200 - totalBossDurationWithoutCurrent
					if newDuration < 1.0 or newDuration > maxTime then
						newDuration = max(min(newDuration, maxTime), 1.0)
					end
				end

				local minutes, seconds = utilities.FormatTime(newDuration)
				minLineEdit:SetText(minutes)
				secLineEdit:SetText(seconds)

				if formatAndReturn then
					return
				end

				local customPhaseDurations = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseDurations
				local cumulativePhaseTime = 0.0
				if boss.treatAsSinglePhase then
					for phaseIndex, phase in ipairs(boss.phases) do
						if cumulativePhaseTime + phase.defaultDuration <= newDuration then
							cumulativePhaseTime = cumulativePhaseTime + phase.defaultDuration
							phase.duration = phase.defaultDuration
						elseif cumulativePhaseTime < newDuration then
							phase.duration = newDuration - cumulativePhaseTime
							cumulativePhaseTime = cumulativePhaseTime + phase.duration
						else
							phase.duration = 0.0
						end
						customPhaseDurations[phaseIndex] = phase.duration
					end
				else
					for phaseIndex, phase in ipairs(boss.phases) do
						if phaseName == longPhaseNames[phaseIndex] then
							phase.duration = newDuration
							customPhaseDurations[phaseIndex] = phase.duration
							break
						end
					end
				end

				local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
				interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
				interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
		end)

		local boss = GetCurrentBoss()
		if boss then
			local phaseData = {}
			if boss.treatAsSinglePhase then
				local totalTime, defaultTotalTime = 0.0, 0.0
				for _, phase in ipairs(boss.phases) do
					totalTime = totalTime + phase.duration
					defaultTotalTime = defaultTotalTime + phase.defaultDuration
				end
				tinsert(phaseData, {
					name = "P1",
					defaultDuration = defaultTotalTime,
					fixedDuration = boss.phases[1].fixedDuration,
					duration = totalTime,
				})
			else
				local longPhaseNames = GetLongPhaseNames(boss)
				for phaseIndex, phase in ipairs(boss.phases) do
					tinsert(phaseData, {
						name = longPhaseNames[phaseIndex],
						defaultDuration = phase.defaultDuration,
						fixedDuration = phase.fixedDuration,
						duration = phase.duration,
					})
				end
			end
			phaseLengthEditor:AddEntries(phaseData)
		end

		phaseLengthEditor.frame:SetParent(UIParent)
		phaseLengthEditor.frame:SetFrameLevel(50)
		phaseLengthEditor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		phaseLengthEditor:Resize()
		phaseLengthEditor:SetPoint("TOP", UIParent, "TOP", 0, -phaseLengthEditor.frame:GetBottom())

		Private.phaseLengthEditor = phaseLengthEditor
	end
end

local function CreateNewPlanDialog(bossDropdownData)
	if not Private.newPlanDialog then
		local newPlanDialog = AceGUI:Create("EPNewPlanDialog")
		newPlanDialog:SetCallback("OnRelease", function()
			Private.newPlanDialog = nil
		end)
		newPlanDialog:SetCallback("CloseButtonClicked", function()
			Private.newPlanDialog:Release()
		end)
		newPlanDialog:SetCallback("CancelButtonClicked", function()
			Private.newPlanDialog:Release()
		end)
		newPlanDialog:SetCallback("CreateNewPlanName", function(widget, _, bossDungeonEncounterID)
			local newBossName = bossUtilities.GetBossName(bossDungeonEncounterID) --[[@as string]]
			widget:SetPlanNameLineEditText(utilities.CreateUniquePlanName(AddOn.db.profile.plans, newBossName))
			widget:SetCreateButtonEnabled(true)
		end)
		newPlanDialog:SetCallback("CreateButtonClicked", function(widget, _, bossDungeonEncounterID, planName)
			planName = planName:trim()
			if planName == "" or AddOn.db.profile.plans[planName] then
				widget:SetCreateButtonEnabled(false)
			else
				if Private.assignmentEditor then
					Private.assignmentEditor:Release()
				end
				if Private.rosterEditor then
					Private.rosterEditor:Release()
				end
				widget:Release()
				local plans = AddOn.db.profile.plans
				plans[planName] = Private.classes.Plan:New(nil, planName)
				AddOn.db.profile.lastOpenPlan = planName
				bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plans[planName])
				interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
				interfaceUpdater.AddPlanToDropdown(planName, true)
			end
		end)
		newPlanDialog:SetCallback("ValidatePlanName", function(widget, _, planName)
			planName = planName:trim()
			if planName == "" or AddOn.db.profile.plans[planName] then
				widget:SetCreateButtonEnabled(false)
			else
				widget:SetCreateButtonEnabled(true)
			end
		end)
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		newPlanDialog.frame:SetParent(UIParent)
		newPlanDialog.frame:SetFrameLevel(80)
		newPlanDialog:SetBossDropdownItems(bossDropdownData, bossDungeonEncounterID)
		newPlanDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		newPlanDialog:Resize()
		newPlanDialog:SetPoint("TOP", UIParent, "TOP", 0, -newPlanDialog.frame:GetBottom())
		local bossName = bossUtilities.GetBossName(bossDungeonEncounterID) --[[@as string]]
		newPlanDialog:SetPlanNameLineEditText(
			utilities.CreateUniquePlanName(AddOn.db.profile.plans, bossName, AddOn.db.profile.lastOpenPlan)
		)
		Private.newPlanDialog = newPlanDialog
	end
end

---@param value number|string
local function HandleBossDropdownValueChanged(value)
	if Private.messageBox then
		return
	end
	local bossDungeonEncounterID = tonumber(value)
	if bossDungeonEncounterID then
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan] --[[@as Plan]]
		local containsCombatLogEventAssignment = false
		for _, assignment in ipairs(plan.assignments) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				containsCombatLogEventAssignment = true
				break
			end
		end
		if containsCombatLogEventAssignment then
			local messageBox = interfaceUpdater.CreateMessageBox(
				L["Changing Boss with Combat Log Event Assignments"],
				L["The current plan includes combat log event assignments tied to this boss's spells. Choose an option:"]
					.. "\n\n"
					.. L["1. Convert all assignments to timed assignments for the new boss"]
					.. "\n"
					.. L["2. Replace spells with those of the new boss, matching the closest timing"]
					.. "\n"
					.. L["3. Cancel"]
					.. "\n\n"
					.. L["Note: Replacing spells may not be reversible and could result in changes if you revert to the original boss."]
			)
			if messageBox then
				local currentBoss = bossUtilities.GetBoss(plan.dungeonEncounterID)
				local newBoss = bossUtilities.GetBoss(bossDungeonEncounterID)
				local currentAssignments = plan.assignments
				if currentBoss and newBoss then
					messageBox:SetAcceptButtonText(L["Convert to Timed Assignments"])
					messageBox:SetRejectButtonText(L["Cancel"])
					local rejectButton = messageBox.buttonContainer.children[2]
					messageBox:AddButton(L["Replace Spells"], rejectButton)
					messageBox:SetCallback(L["Replace Spells"] .. "Clicked", function()
						if Private.assignmentEditor then
							Private.assignmentEditor:Release()
						end
						if Private.phaseLengthEditor then
							Private.phaseLengthEditor:Release()
						end
						utilities.ConvertAssignmentsToNewBoss(currentAssignments, currentBoss, newBoss, 2)
						bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plan)
						interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
						interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
					end)
					messageBox:SetCallback("Accepted", function()
						if Private.assignmentEditor then
							Private.assignmentEditor:Release()
						end
						if Private.phaseLengthEditor then
							Private.phaseLengthEditor:Release()
						end
						utilities.ConvertAssignmentsToNewBoss(currentAssignments, currentBoss, newBoss, 1)
						bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plan)
						interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
						interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
					end)
				end
			end
		else
			if Private.assignmentEditor then
				Private.assignmentEditor:Release()
			end
			if Private.phaseLengthEditor then
				Private.phaseLengthEditor:Release()
			end
			bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plan)
			interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
		end
	end
end

---@param dropdown EPDropdown
---@param value number|string
---@param selected boolean
local function HandleBossAbilitySelectDropdownValueChanged(dropdown, value, selected)
	if value == L["Filter Spells"] or type(value) ~= "number" then
		return
	end
	local boss = bossUtilities.GetBoss(Private.mainFrame.bossSelectDropdown:GetValue())
	if boss then
		local atLeastOneSelected = false
		for currentAbilityID, currentSelected in pairs(AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]) do
			if currentAbilityID ~= value and currentSelected then
				atLeastOneSelected = true
				break
			end
		end
		if atLeastOneSelected then
			AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID][value] = selected
			interfaceUpdater.UpdateBoss(boss.dungeonEncounterID, false)
		else
			dropdown:SetItemIsSelected(value, true, true)
			AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID][value] = true
		end
	end
end

---@param value string
local function HandlePlanDropdownValueChanged(_, _, value)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	AddOn.db.profile.lastOpenPlan = value
	local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan] --[[@as Plan]]
	local bossDungeonEncounterID = plan.dungeonEncounterID

	interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
	interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
	Private.mainFrame.planReminderEnableCheckBox:SetChecked(plan.remindersEnabled)
	Private.mainFrame:DoLayout()
end

---@param lineEdit EPLineEdit
---@param value string
local function HandlePlanTextSubmitted(lineEdit, _, value)
	local currentPlanName = AddOn.db.profile.lastOpenPlan
	if value:gsub("%s", "") == "" then
		lineEdit:SetText(currentPlanName)
		return
	elseif value == currentPlanName then
		return
	elseif AddOn.db.profile.plans[value] then
		lineEdit:SetText(currentPlanName)
		return
	end
	AddOn.db.profile.plans[value] = AddOn.db.profile.plans[currentPlanName]
	AddOn.db.profile.plans[currentPlanName] = nil
	AddOn.db.profile.plans[value].name = value
	AddOn.db.profile.lastOpenPlan = value
	local planDropdown = Private.mainFrame.planDropdown
	if planDropdown then
		planDropdown:EditItemText(currentPlanName, value, value)
		planDropdown:Sort()
	end
end

---@param uniqueID integer
local function HandleTimelineAssignmentClicked(_, _, uniqueID)
	if Private.IsSimulatingBoss() then
		return
	end
	local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), uniqueID)
	if assignment then
		if not Private.assignmentEditor then
			Private.assignmentEditor = CreateAssignmentEditor()
		end
		local previewText = utilities.CreateReminderText(assignment, GetCurrentRoster(), true)
		Private.assignmentEditor:PopulateFields(assignment, previewText, assignmentMetaTables)
		local timeline = Private.mainFrame.timeline
		if timeline then
			timeline:ClearSelectedAssignments()
			timeline:ClearSelectedBossAbilities()
			timeline:SelectAssignment(uniqueID, true)
			if
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				and assignment--[[@as CombatLogEventAssignment]].spellCount
			then
				timeline:SelectBossAbility(
					assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
					assignment--[[@as CombatLogEventAssignment]].spellCount,
					true
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
			dropdown:SetText(L["Add Assignee"])
			return
		end
	end

	local assignment = Private.classes.TimedAssignment:New()
	assignment.assigneeNameOrRole = value
	tinsert(GetCurrentAssignments(), assignment)
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	dropdown:SetText(L["Add Assignee"])
end

---@param abilityInstance BossAbilityInstance
---@param assigneesAndSpellIndex integer
---@param relativeAssignmentStartTime number
local function HandleCreateNewAssignment(_, _, abilityInstance, assigneesAndSpellIndex, relativeAssignmentStartTime)
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.preferences.assignmentSortType,
		GetCurrentBossDungeonEncounterID()
	)
	local sortedAssigneesAndSpells =
		utilities.SortAssigneesWithSpellID(sorted, AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed)
	local nameAndSpell = sortedAssigneesAndSpells[assigneesAndSpellIndex]
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
			combatLogEventAssignment.spellCount = abilityInstance.spellOccurrence
			combatLogEventAssignment.combatLogEventSpellID = abilityInstance.bossAbilitySpellID
			combatLogEventAssignment.bossPhaseOrderIndex = abilityInstance.bossPhaseOrderIndex
			combatLogEventAssignment.phase = abilityInstance.bossPhaseIndex
			tinsert(GetCurrentAssignments(), combatLogEventAssignment)
			-- end
			-- elseif abilityInstance.repeatInstance then
		else
			local timedAssignment = Private.classes.TimedAssignment:New(assignment)
			timedAssignment.time = abilityInstance.castStart
			tinsert(GetCurrentAssignments(), timedAssignment)
		end
		interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	end
end

---@param assigneesAndSpellIndex integer
---@param time number
local function HandleCreateNewTimedAssignment(_, _, assigneesAndSpellIndex, time)
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.preferences.assignmentSortType,
		GetCurrentBossDungeonEncounterID()
	)
	local sortedAssigneesAndSpells =
		utilities.SortAssigneesWithSpellID(sorted, AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed)
	local nameAndSpell = sortedAssigneesAndSpells[assigneesAndSpellIndex]
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
		local timedAssignment = Private.classes.TimedAssignment:New(assignment)
		timedAssignment.time = utilities.Round(time, 1)
		tinsert(GetCurrentAssignments(), timedAssignment)
		interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	end
end

local function HandleCreateNewPlanButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.rosterEditor then
		Private.rosterEditor:Release()
	end
	local plans = AddOn.db.profile.plans
	local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
	local bossName = bossUtilities.GetBossName(bossDungeonEncounterID)
	local newPlanName = utilities.CreateUniquePlanName(plans, bossName --[[@as string]])

	plans[newPlanName] = Private.classes.Plan:New(nil, newPlanName)
	AddOn.db.profile.lastOpenPlan = newPlanName
	bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plans[newPlanName])
	interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
	interfaceUpdater.AddPlanToDropdown(newPlanName, true)
end

local function HandleDuplicatePlanButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	local plans = AddOn.db.profile.plans
	local planToDuplicateName = AddOn.db.profile.lastOpenPlan
	local planToDuplicate = plans[planToDuplicateName]
	local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
	local bossName = bossUtilities.GetBossName(bossDungeonEncounterID) --[[@as string]]
	local newPlanName = utilities.CreateUniquePlanName(plans, bossName, planToDuplicateName)
	local newPlan = Private.classes.Plan:New(planToDuplicate, newPlanName, nil)
	plans[newPlanName] = newPlan
	AddOn.db.profile.lastOpenPlan = newPlanName
	bossUtilities.ChangePlanBoss(bossDungeonEncounterID, newPlan)
	interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
	interfaceUpdater.AddPlanToDropdown(newPlanName, true)
end

local function HandleDeleteCurrentNoteButtonClicked()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.rosterEditor then
		Private.rosterEditor:Release()
	end
	local beforeRemovalCount = 0
	local plans = AddOn.db.profile.plans
	for _, _ in pairs(plans) do
		beforeRemovalCount = beforeRemovalCount + 1
	end

	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	if lastOpenPlan then
		plans[lastOpenPlan] = nil
		interfaceUpdater.RemovePlanFromDropdown(lastOpenPlan)
	end
	if beforeRemovalCount > 1 then
		for name, _ in pairs(plans) do
			AddOn.db.profile.lastOpenPlan = name
			local bossDungeonEncounterID = plans[name].dungeonEncounterID
			if bossDungeonEncounterID then
				interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			end
			break
		end
	else
		local newPlanName = L["Default"]
		plans[newPlanName] = Private.classes.Plan:New({}, newPlanName)
		AddOn.db.profile.lastOpenPlan = newPlanName
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plans[newPlanName])
		interfaceUpdater.AddPlanToDropdown(newPlanName, true)
	end
	local newLastOpenPlan = AddOn.db.profile.lastOpenPlan
	interfaceUpdater.AddPlanToDropdown(newLastOpenPlan, true)
	interfaceUpdater.UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
end

---@param importType string
local function ImportPlan(importType)
	if not Private.importEditBox then
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		if Private.phaseLengthEditor then
			Private.phaseLengthEditor:Release()
		end

		if importType == "FromMRTOverwrite" or importType == "FromMRTNew" then
			local loadingOrLoaded, loaded = IsAddOnLoaded("MRT")
			if not loadingOrLoaded and not loaded then
				print(format("%s: %s", AddOnName, L["No note was loaded due to MRT not being installed."]))
			end
			if VMRT and VMRT.Note and VMRT.Note.Text1 then
				local text = VMRT.Note.Text1
				local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
				if importType == "FromMRTOverwrite" then
					bossDungeonEncounterID = Private:ImportPlanFromNote(
						AddOn.db.profile.lastOpenPlan,
						bossDungeonEncounterID,
						text
					) or bossDungeonEncounterID
				elseif importType == "FromMRTNew" then
					local bossName = bossUtilities.GetBossName(bossDungeonEncounterID)
					local newPlanName =
						utilities.CreateUniquePlanName(AddOn.db.profile.plans, bossName --[[@as string]])
					bossDungeonEncounterID = Private:ImportPlanFromNote(newPlanName, bossDungeonEncounterID, text)
						or bossDungeonEncounterID
					AddOn.db.profile.lastOpenPlan = newPlanName
					interfaceUpdater.AddPlanToDropdown(newPlanName, true)
					interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
					interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
				end
			end
		elseif importType == "FromStringOverwrite" or importType == "FromStringNew" then
			CreateImportEditBox(importType)
		end
	end
end

local function HandleExportPlanButtonClicked()
	if not Private.exportEditBox then
		Private.exportEditBox = AceGUI:Create("EPEditBox")
		Private.exportEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		Private.exportEditBox.frame:SetFrameLevel(12)
		Private.exportEditBox.frame:SetPoint("CENTER")
		Private.exportEditBox:SetTitle(L["Export"])
		Private.exportEditBox:SetCallback("OnRelease", function()
			Private.exportEditBox = nil
		end)
	end
	local text = Private:ExportPlanToNote(AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan])
	if text then
		Private.exportEditBox:SetText(text)
		Private.exportEditBox:HighlightTextAndFocus()
	end
end

local function CleanUp()
	Private.callbackTarget.UnregisterCallback(Private, "SimulationCompleted")
	if Private.IsSimulatingBoss() then
		Private:StopSimulatingBoss()
	end
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
	if Private.menuButtonContainer then
		Private.menuButtonContainer:Release()
	end
	if Private.phaseLengthEditor then
		Private.phaseLengthEditor:Release()
	end
	if Private.newPlanDialog then
		Private.newPlanDialog:Release()
	end
end

function Private:CreateInterface()
	local bossDungeonEncounterID = 2902
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan

	if lastOpenPlan and lastOpenPlan ~= "" and plans[lastOpenPlan] then
		bossDungeonEncounterID = plans[lastOpenPlan].dungeonEncounterID
	else
		local defaultPlanName = L["Default"]
		local loadingOrLoaded, loaded = IsAddOnLoaded("MRT")
		if not loadingOrLoaded and not loaded then
			print(format("%s: %s", L["No note was loaded due to MRT not being installed."]))
		end
		if VMRT and VMRT.Note and VMRT.Note.Text1 then
			local text = VMRT.Note.Text1
			bossDungeonEncounterID = Private:ImportPlanFromNote(defaultPlanName, bossDungeonEncounterID, text)
				or bossDungeonEncounterID
		end
		if not plans[defaultPlanName] then -- MRT not loaded
			plans[defaultPlanName] = Private.classes.Plan:New(nil, defaultPlanName)
			bossUtilities.ChangePlanBoss(bossDungeonEncounterID, plans[defaultPlanName])
		end
		AddOn.db.profile.lastOpenPlan = defaultPlanName
	end

	local bossDropdownData = {}
	for _, raidInstance in pairs(Private.raidInstances) do
		EJ_SelectInstance(raidInstance.journalInstanceID)
		local instanceName, _, _, _, _, buttonImage2, _, _, _, _ = EJ_GetInstanceInfo(raidInstance.journalInstanceID)
		local instanceIconText = format("|T%s:16|t %s", buttonImage2, instanceName)
		local instanceDropdownData =
			{ itemValue = raidInstance.instanceID, text = instanceIconText, dropdownItemMenuData = {} }
		for _, boss in ipairs(raidInstance.bosses) do
			EJ_SelectEncounter(boss.journalEncounterID)
			local _, bossName, _, _, iconImage, _ = EJ_GetCreatureInfo(1, boss.journalEncounterID)
			local iconText = format("|T%s:16|t %s", iconImage, bossName)
			tinsert(instanceDropdownData.dropdownItemMenuData, { itemValue = boss.dungeonEncounterID, text = iconText })
		end
		tinsert(bossDropdownData, instanceDropdownData)
	end

	Private.mainFrame = AceGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("EPVerticalLayout")
	Private.mainFrame:SetSpacing(unpack(mainFrameSpacing))
	Private.mainFrame:SetPadding(unpack(mainFramePadding))
	if AddOn.db.profile.minimizeFramePosition then
		Private.mainFrame:SetMinimizeFramePosition(
			AddOn.db.profile.minimizeFramePosition.x,
			AddOn.db.profile.minimizeFramePosition.y
		)
	end
	Private.mainFrame:SetCallback("CloseButtonClicked", function()
		local width, height = Private.mainFrame.frame:GetSize()
		AddOn.db.profile.windowSize = { x = width, y = height }
		Private.mainFrame:Release()
	end)
	Private.mainFrame:SetCallback("OnRelease", CleanUp)
	Private.mainFrame:SetCallback("CollapseAllButtonClicked", function()
		local currentBossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		local sortedTimelineAssignments = utilities.SortAssignments(
			GetCurrentAssignments(),
			GetCurrentRoster(),
			AddOn.db.profile.preferences.assignmentSortType,
			currentBossDungeonEncounterID
		)
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
			collapsed[timelineAssignment.assignment.assigneeNameOrRole] = true
		end
		interfaceUpdater.UpdateAllAssignments(true, currentBossDungeonEncounterID)
	end)
	Private.mainFrame:SetCallback("ExpandAllButtonClicked", function()
		local currentBossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		local sortedTimelineAssignments = utilities.SortAssignments(
			GetCurrentAssignments(),
			GetCurrentRoster(),
			AddOn.db.profile.preferences.assignmentSortType,
			currentBossDungeonEncounterID
		)
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
			collapsed[timelineAssignment.assignment.assigneeNameOrRole] = false
		end
		interfaceUpdater.UpdateAllAssignments(false, currentBossDungeonEncounterID)
		Private.mainFrame.timeline:SetMaxAssignmentHeight()
		Private.mainFrame:DoLayout()
	end)
	Private.mainFrame:SetCallback("MinimizeFramePointChanged", function(_, _, x, y)
		AddOn.db.profile.minimizeFramePosition = { x = x, y = y }
	end)

	Private.menuButtonContainer = AceGUI:Create("EPContainer")
	Private.menuButtonContainer:SetLayout("EPHorizontalLayout")
	Private.menuButtonContainer:SetSpacing(0, 0)
	Private.menuButtonContainer.frame:SetParent(Private.mainFrame.windowBar)
	Private.menuButtonContainer.frame:SetPoint("TOPLEFT", Private.mainFrame.windowBar, "TOPLEFT", 1, -1)
	Private.menuButtonContainer.frame:SetPoint("BOTTOMLEFT", Private.mainFrame.windowBar, "BOTTOMLEFT", 1, 1)
	Private.menuButtonContainer:SetCallback("OnRelease", function()
		Private.menuButtonContainer = nil
	end)

	local menuButtonHeight = Private.mainFrame.windowBar:GetHeight() - 2
	local planMenuButton = AceGUI:Create("EPDropdown")
	planMenuButton:SetTextFontSize(menuButtonFontSize)
	planMenuButton:SetItemTextFontSize(menuButtonFontSize)
	planMenuButton:SetText(L["Plan"])
	planMenuButton:SetTextCentered(true)
	planMenuButton:SetButtonVisibility(false)
	planMenuButton:SetAutoItemWidth(true)
	planMenuButton:SetShowHighlight(true)
	planMenuButton:SetItemHorizontalPadding(menuButtonHorizontalPadding)
	planMenuButton:SetWidth(planMenuButton.text:GetStringWidth() + 2 * menuButtonHorizontalPadding)
	planMenuButton:SetHeight(menuButtonHeight)
	planMenuButton:SetDropdownItemHeight(menuButtonHeight)
	planMenuButton:AddItems({
		{
			itemValue = "New Plan",
			text = utilities.AddIconBeforeText(
				[[Interface\AddOns\EncounterPlanner\Media\icons8-add-32]],
				L["New Plan"]
			),
		},
		{
			itemValue = "Duplicate Plan",
			text = utilities.AddIconBeforeText(
				[[Interface\AddOns\EncounterPlanner\Media\icons8-duplicate-32]],
				L["Duplicate Plan"]
			),
		},
		{
			itemValue = "Import",
			text = utilities.AddIconBeforeText([[Interface\AddOns\EncounterPlanner\Media\icons8-import-32]], "Import"),
			dropdownItemMenuData = {
				{
					itemValue = "From MRT",
					text = L["From"] .. "MRT",
					dropdownItemMenuData = {
						{ itemValue = "FromMRTOverwrite", text = L["Overwrite Current Plan"] },
						{ itemValue = "FromMRTNew", text = L["Create New Plan"] },
					},
				},
				{
					itemValue = "From String",
					text = L["From String"],
					dropdownItemMenuData = {
						{ itemValue = "FromStringOverwrite", text = L["Overwrite Current Plan"] },
						{ itemValue = "FromStringNew", text = L["Create New Plan"] },
					},
				},
			},
		},
		{
			itemValue = "Export Current Plan",
			text = utilities.AddIconBeforeText(
				[[Interface\AddOns\EncounterPlanner\Media\icons8-export-32]],
				L["Export Current Plan"]
			),
		},
		{
			itemValue = "Delete Current Plan",
			text = utilities.AddIconBeforeText(
				[[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]],
				L["Delete Current Plan"]
			),
		},
	}, "EPDropdownItemToggle", true)
	planMenuButton:SetCallback("OnValueChanged", function(_, _, value)
		if value == "Plan" then
			return
		end
		if value == "New Plan" then
			CreateNewPlanDialog(bossDropdownData)
		elseif value == "Duplicate Plan" then
			HandleDuplicatePlanButtonClicked()
		elseif value == "Export Current Plan" then
			HandleExportPlanButtonClicked()
		elseif value == "Delete Current Plan" then
			local messageBox = interfaceUpdater.CreateMessageBox(
				L["Delete Plan Confirmation"],
				format('%s "%s"?', L["Are you sure you want to delete the plan"], AddOn.db.profile.lastOpenPlan)
			)
			if messageBox then
				messageBox:SetCallback("Accepted", function()
					if Private.mainFrame then
						HandleDeleteCurrentNoteButtonClicked()
					end
				end)
			end
		elseif sub(value, 1, 4) == "From" then
			if string.find(value, "Overwrite") then
				local messageBox = interfaceUpdater.CreateMessageBox(
					L["Delete Plan Confirmation"],
					format('%s "%s"?', L["Are you sure you want to overwrite the plan"], AddOn.db.profile.lastOpenPlan)
				)
				if messageBox then
					messageBox:SetCallback("Accepted", function()
						if Private.mainFrame then
							ImportPlan(value)
						end
					end)
				end
			else
				ImportPlan(value)
			end
		end
		planMenuButton:SetValue("Plan")
		planMenuButton:SetText(L["Plan"])
	end)

	local bossMenuButton = AceGUI:Create("EPDropdown")
	bossMenuButton:SetTextFontSize(menuButtonFontSize)
	bossMenuButton:SetItemTextFontSize(menuButtonFontSize)
	bossMenuButton:SetText(L["Boss"])
	bossMenuButton:SetTextCentered(true)
	bossMenuButton:SetButtonVisibility(false)
	bossMenuButton:SetAutoItemWidth(true)
	bossMenuButton:SetShowHighlight(true)
	bossMenuButton:SetMultiselect(true)
	bossMenuButton:SetItemHorizontalPadding(menuButtonHorizontalPadding)
	bossMenuButton:SetWidth(bossMenuButton.text:GetStringWidth() + 2 * menuButtonHorizontalPadding)
	bossMenuButton:SetHeight(menuButtonHeight)
	bossMenuButton:SetDropdownItemHeight(menuButtonHeight)
	bossMenuButton:AddItems({
		{
			itemValue = "Edit Phase Timings",
			text = L["Edit Phase Timings"],
			selectable = false,
		},
		{
			itemValue = "Filter Spells",
			text = L["Filter Spells"],
			dropdownItemMenuData = {
				{
					itemValue = "",
					text = "",
				},
			},
		},
	}, "EPDropdownItemToggle")
	bossMenuButton:SetCallback("OnValueChanged", function(dropdown, _, value, selected)
		if value == "Boss" then
			return
		end
		if value == "Edit Phase Timings" then
			CreatePhaseLengthEditor()
			bossMenuButton:SetValue("Boss")
			bossMenuButton:SetText("Boss")
		else
			HandleBossAbilitySelectDropdownValueChanged(dropdown, value, selected)
		end
	end)

	local rosterMenuButton = AceGUI:Create("EPDropdown")
	rosterMenuButton:SetTextFontSize(menuButtonFontSize)
	rosterMenuButton:SetItemTextFontSize(menuButtonFontSize)
	rosterMenuButton:SetText(L["Roster"])
	rosterMenuButton:SetTextCentered(true)
	rosterMenuButton:SetButtonVisibility(false)
	rosterMenuButton:SetAutoItemWidth(true)
	rosterMenuButton:SetShowHighlight(true)
	rosterMenuButton:SetItemHorizontalPadding(menuButtonHorizontalPadding)
	rosterMenuButton:SetWidth(rosterMenuButton.text:GetStringWidth() + 2 * menuButtonHorizontalPadding)
	rosterMenuButton:SetHeight(menuButtonHeight)
	rosterMenuButton:SetDropdownItemHeight(menuButtonHeight)
	rosterMenuButton:AddItems({
		{ itemValue = "Edit Current Plan Roster", text = "Edit Current Plan Roster" },
		{ itemValue = "Edit Shared Roster", text = "Edit Shared Roster" },
	}, "EPDropdownItemToggle", true)
	rosterMenuButton:SetCallback("OnValueChanged", function(_, _, value)
		if value == "Roster" then
			return
		end
		if value == "Edit Current Plan Roster" then
			CreateRosterEditor("Current Plan Roster")
		elseif value == "Edit Shared Roster" then
			CreateRosterEditor("Shared Roster")
		end
		rosterMenuButton:SetValue("Roster")
		rosterMenuButton:SetText(L["Roster"])
	end)

	local preferencesMenuButton = AceGUI:Create("EPButton")
	preferencesMenuButton:SetText(L["Preferences"])
	preferencesMenuButton:SetFontSize(menuButtonFontSize)
	preferencesMenuButton:SetHeight(menuButtonHeight)
	preferencesMenuButton:SetWidth(
		preferencesMenuButton.button:GetFontString():GetStringWidth() + 2 * menuButtonHorizontalPadding
	)
	preferencesMenuButton:SetBackdrop(
		preferencesMenuButtonBackdrop,
		preferencesMenuButtonBackdropColor,
		preferencesMenuButtonBackdropBorderColor
	)
	preferencesMenuButton:SetColor(unpack(preferencesMenuButtonColor))
	Private.menuButtonContainer:AddChildren(planMenuButton, bossMenuButton, rosterMenuButton, preferencesMenuButton)

	local autoOpenNextEntered = nil
	local buttonToClose = nil
	for _, child in ipairs(Private.menuButtonContainer.children) do
		if child ~= preferencesMenuButton then
			child:SetCallback("OnEnter", function(frame, _)
				if frame.open then
					return
				end
				if autoOpenNextEntered and buttonToClose then
					buttonToClose:Close()
					frame:Open()
					buttonToClose = frame
				end
			end)
			child:SetCallback("OnOpened", function(frame, _)
				autoOpenNextEntered = true
				buttonToClose = frame
			end)
			child:SetCallback("OnClosed", function()
				autoOpenNextEntered = false
				buttonToClose = nil
			end)
		end
	end

	preferencesMenuButton:SetCallback("Clicked", function()
		if not Private.optionsMenu then
			Private:CreateOptionsMenu()
		end
		planMenuButton:Close()
		bossMenuButton:Close()
		rosterMenuButton:Close()
	end)

	local bossDropdown = AceGUI:Create("EPDropdown")
	bossDropdown:SetWidth(topContainerDropdownWidth)
	bossDropdown:SetTextFontSize(topContainerWidgetFontSize)
	bossDropdown:SetItemTextFontSize(topContainerWidgetFontSize)
	bossDropdown:SetTextHorizontalPadding(menuButtonHorizontalPadding / 2)
	bossDropdown:SetItemHorizontalPadding(menuButtonHorizontalPadding / 2)
	bossDropdown:SetHeight(topContainerWidgetHeight)
	bossDropdown:SetDropdownItemHeight(topContainerWidgetHeight)
	bossDropdown:AddItems(bossDropdownData, "EPDropdownItemToggle")
	bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
		HandleBossDropdownValueChanged(value)
	end)

	local planContainer = AceGUI:Create("EPContainer")
	planContainer:SetLayout("EPHorizontalLayout")
	planContainer:SetSpacing(unpack(dropdownContainerSpacing))

	local planLabel = AceGUI:Create("EPLabel")
	planLabel:SetText(L["Current Plan:"], dropdownContainerLabelSpacing)
	planLabel:SetFullHeight(true)
	planLabel:SetFrameWidthFromText()

	local planDropdown = AceGUI:Create("EPDropdown")
	planDropdown:SetWidth(topContainerDropdownWidth)
	planDropdown:SetAutoItemWidth(false)
	planDropdown:SetTextFontSize(topContainerWidgetFontSize)
	planDropdown:SetItemTextFontSize(topContainerWidgetFontSize)
	planDropdown:SetTextHorizontalPadding(menuButtonHorizontalPadding / 2)
	planDropdown:SetItemHorizontalPadding(menuButtonHorizontalPadding / 2)
	planDropdown:SetHeight(topContainerWidgetHeight)
	planDropdown:SetDropdownItemHeight(topContainerWidgetHeight)
	planDropdown:SetUseLineEditForDoubleClick(true)
	planDropdown:SetMaxVisibleItems(defaultMaxVisibleDropdownItems)
	planDropdown:SetCallback("OnLineEditTextSubmitted", HandlePlanTextSubmitted)
	planDropdown:SetCallback("OnValueChanged", HandlePlanDropdownValueChanged)
	planContainer:AddChildren(planLabel, planDropdown)

	local reminderAndSendPlanButtonContainer = AceGUI:Create("EPContainer")
	reminderAndSendPlanButtonContainer:SetLayout("EPHorizontalLayout")
	reminderAndSendPlanButtonContainer:SetFullHeight(true)
	reminderAndSendPlanButtonContainer:SetSelfAlignment("topRight")

	local planReminderEnableCheckBox = AceGUI:Create("EPCheckBox")
	planReminderEnableCheckBox:SetText(L["Enable Reminders for Plan"])
	planReminderEnableCheckBox:SetHeight(topContainerWidgetHeight)
	planReminderEnableCheckBox:SetFrameWidthFromText()
	planReminderEnableCheckBox:SetFullHeight(true)
	planReminderEnableCheckBox:SetCallback("OnValueChanged", function(_, _, value)
		local planName = AddOn.db.profile.lastOpenPlan
		local plan = AddOn.db.profile.plans[planName]
		plan.remindersEnabled = value
		interfaceUpdater.UpdatePlanDropdownItemCustomTexture(planName, value)
	end)

	local simulateReminderButton = AceGUI:Create("EPButton")
	simulateReminderButton:SetText(L["Simulate Reminders"])
	simulateReminderButton:SetWidthFromText()
	simulateReminderButton:SetFullHeight(true)
	simulateReminderButton:SetCallback("Clicked", function()
		local wasSimulatingBoss = Private.IsSimulatingBoss()

		if wasSimulatingBoss then
			Private:StopSimulatingBoss()
			simulateReminderButton:SetText(L["Simulate Reminders"])
		else
			if Private.assignmentEditor then
				Private.assignmentEditor:Release()
			end
			if Private.rosterEditor then
				Private.rosterEditor:Release()
			end
			if Private.optionsMenu then
				Private.optionsMenu:Release()
			end
			if Private.phaseLengthEditor then
				Private.phaseLengthEditor:Release()
			end
			simulateReminderButton:SetText(L["Stop Simulating"])
			local sortedTimelineAssignments = utilities.SortAssignments(
				GetCurrentAssignments(),
				GetCurrentRoster(),
				AddOn.db.profile.preferences.assignmentSortType,
				GetCurrentBossDungeonEncounterID()
			)
			Private:SimulateBoss(GetCurrentBossDungeonEncounterID(), sortedTimelineAssignments, GetCurrentRoster())
		end
		local isSimulatingBoss = not wasSimulatingBoss
		local timeline = Private.mainFrame.timeline
		if timeline then
			timeline:SetIsSimulating(isSimulatingBoss)
			local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
			addAssigneeDropdown:SetEnabled(not isSimulatingBoss)
		end
		Private.mainFrame.bossSelectDropdown:SetEnabled(not isSimulatingBoss)
		Private.mainFrame.planDropdown:SetEnabled(not isSimulatingBoss)
	end)

	local function HandleSimulationCompleted()
		simulateReminderButton:SetText(L["Simulate Reminders"])
		local timeline = Private.mainFrame.timeline
		if timeline then
			timeline:SetIsSimulating(false)
			local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
			addAssigneeDropdown:SetEnabled(true)
		end
		Private.mainFrame.bossSelectDropdown:SetEnabled(true)
		Private.mainFrame.planDropdown:SetEnabled(true)
	end
	Private.callbackTarget.RegisterCallback(self, "SimulationCompleted", HandleSimulationCompleted)

	local sendPlanButton = AceGUI:Create("EPButton")
	sendPlanButton:SetText(L["Send Plan to Group"])
	sendPlanButton:SetWidthFromText()
	sendPlanButton:SetFullHeight(true)
	sendPlanButton:SetCallback("Clicked", function()
		Private:SendPlanToGroup(AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan])
	end)
	sendPlanButton:SetEnabled(
		(IsInGroup() or IsInRaid()) and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player"))
	)

	reminderAndSendPlanButtonContainer:AddChildren(planReminderEnableCheckBox, simulateReminderButton, sendPlanButton)

	local topContainer = AceGUI:Create("EPContainer")
	topContainer:SetLayout("EPHorizontalLayout")
	topContainer:SetFullWidth(true)
	topContainer:AddChildren(bossDropdown, planContainer, reminderAndSendPlanButtonContainer)

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetPreferences(AddOn.db.profile.preferences)
	timeline.CalculateAssignmentTimeFromStart = function(timelineAssignment)
		local assignment = timelineAssignment.assignment
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			return utilities.ConvertAbsoluteTimeToCombatLogEventTime(
				timelineAssignment.startTime,
				GetCurrentBossDungeonEncounterID(),
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
				assignment--[[@as CombatLogEventAssignment]].spellCount,
				assignment--[[@as CombatLogEventAssignment]].combatLogEventType
			)
		else
			return nil
		end
	end
	timeline.GetMinimumCombatLogEventTime = function(timelineAssignment)
		local assignment = timelineAssignment.assignment
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			return utilities.GetMinimumCombatLogEventTime(
				GetCurrentBossDungeonEncounterID(),
				assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID,
				assignment--[[@as CombatLogEventAssignment]].spellCount,
				assignment--[[@as CombatLogEventAssignment]].combatLogEventType
			)
		else
			return nil
		end
	end

	timeline:SetFullWidth(true)
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)
	timeline:SetCallback("CreateNewTimedAssignment", HandleCreateNewTimedAssignment)
	timeline:SetCallback("DuplicateAssignment", function(_, _, timelineAssignment)
		local newAssignment = Private.DuplicateAssignment(timelineAssignment.assignment)
		tinsert(GetCurrentAssignments(), newAssignment)
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		local sortedTimelineAssignments = utilities.SortAssignments(
			GetCurrentAssignments(),
			GetCurrentRoster(),
			AddOn.db.profile.preferences.assignmentSortType,
			GetCurrentBossDungeonEncounterID()
		)
		local sortedWithSpellID = utilities.SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
		timeline:SetAssignments(sortedTimelineAssignments, sortedWithSpellID, collapsed)
		return newAssignment.uniqueID
	end)
	timeline:SetCallback("ResizeBoundsCalculated", function(_, _, minHeight, maxHeight)
		local topContainerSpacing = topContainer.content.spacing
		local heightDiff = Private.mainFrame.frame:GetHeight() - timeline.frame:GetHeight()
		local minWidth, maxWidth = 0.0, nil
		for _, child in ipairs(topContainer.children) do
			if child.type ~= "EPSpacer" then
				minWidth = minWidth + child.frame:GetWidth() + topContainerSpacing.x
			end
		end
		local padding = Private.mainFrame:GetPadding()
		minWidth = minWidth + padding.left + padding.right - topContainerSpacing.x
		minHeight = minHeight + heightDiff
		maxHeight = maxHeight + heightDiff
		Private.mainFrame.frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
	end)
	local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
	addAssigneeDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeDropdown:SetText(L["Add Assignee"])
	addAssigneeDropdown:AddItems(
		utilities.CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster()),
		"EPDropdownItemToggle",
		true
	)

	Private.mainFrame.bossSelectDropdown = bossDropdown
	Private.mainFrame.bossMenuButton = bossMenuButton
	Private.mainFrame.planDropdown = planDropdown
	Private.mainFrame.planReminderEnableCheckBox = planReminderEnableCheckBox
	Private.mainFrame.timeline = timeline
	Private.mainFrame.sendPlanButton = sendPlanButton

	Private.mainFrame:AddChildren(topContainer, timeline)

	interfaceUpdater.UpdatePlanDropdown()
	interfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
	utilities.UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(GetCurrentRoster())
	utilities.UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
	interfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID, true)
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

function Private:InitializeInterface()
	spellDropdownItems = utilities.CreateSpellAssignmentDropdownItems()
	assignmentTypeDropdownItems = utilities.CreateAssignmentTypeDropdownItems()
	classDropdownItems = utilities.CreateClassDropdownItemData()
end
