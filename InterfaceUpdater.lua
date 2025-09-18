local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class Constants
local constants = Private.constants
local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType
local kInvalidAssignmentSpellID = constants.kInvalidAssignmentSpellID
local kMessageBoxFrameLevel = constants.frameLevels.kMessageBoxFrameLevel
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class InterfaceUpdater
local InterfaceUpdater = Private.interfaceUpdater

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities
local AddIconBeforeText = utilities.AddIconBeforeText
local CreateAssignmentTypeWithRosterDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems
local GetBoss = bossUtilities.GetBoss
local GetCurrentPlan = utilities.GetCurrentPlan
local GetCurrentRoster = utilities.GetCurrentRoster
local SortAssignments = utilities.SortAssignments

local DifficultyType = Private.classes.DifficultyType

local AceGUI = LibStub("AceGUI-3.0")

local format = string.format
local ipairs = ipairs
local max = math.max

local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local tonumber = tonumber
local tremove = table.remove
local type = type
local unpack = unpack
local wipe = table.wipe

do
	local CreateAbilityDropdownItemData = utilities.CreateAbilityDropdownItemData
	local GenerateBossTables = bossUtilities.GenerateBossTables
	local GetBossAbilities = bossUtilities.GetBossAbilities
	local GetBossAbilityIconAndLabel = bossUtilities.GetBossAbilityIconAndLabel
	local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases
	local GetTextCoordsFromDifficulty = utilities.GetTextCoordsFromDifficulty
	local ResetBossPhaseCounts = bossUtilities.ResetBossPhaseCounts
	local ResetBossPhaseTimings = bossUtilities.ResetBossPhaseTimings
	local SetPhaseCounts = bossUtilities.SetPhaseCounts
	local SetPhaseDurations = bossUtilities.SetPhaseDurations

	local kInstanceAndBossPadding = 4
	local kMaxBossDuration = constants.kMaxBossDuration
	local sLastBossDungeonEncounterID = 0
	local sLastDifficulty = DifficultyType.Mythic

	-- Clears and repopulates the boss ability container based on the boss name.
	---@param boss Boss
	---@param timeline EPTimeline
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	---@param activeBossAbilities table<integer, boolean>
	---@param sortedAbilityIDs table<integer, integer>
	---@param difficulty DifficultyType
	local function UpdateBossAbilityList(
		boss,
		timeline,
		updateBossAbilitySelectDropdown,
		activeBossAbilities,
		sortedAbilityIDs,
		difficulty
	)
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossLabel = Private.mainFrame.bossLabel
		local instanceLabel = Private.mainFrame.instanceLabel
		local difficultyLabel = Private.mainFrame.difficultyLabel
		if bossAbilityContainer and bossLabel and instanceLabel then
			local dungeonEncounterID = boss.dungeonEncounterID
			local profile = AddOn.db.profile

			local dungeonInstance = Private.dungeonInstances[boss.instanceID]
			if dungeonInstance.isSplit and boss.mapChallengeModeID then
				dungeonInstance = dungeonInstance.splitDungeonInstances[boss.mapChallengeModeID]
				instanceLabel:SetText(
					dungeonInstance.name,
					kInstanceAndBossPadding,
					{ dungeonInstanceID = dungeonInstance.instanceID, mapChallengeModeID = boss.mapChallengeModeID }
				)
			else
				instanceLabel:SetText(dungeonInstance.name, kInstanceAndBossPadding, dungeonInstance.instanceID)
			end
			instanceLabel:SetIcon(dungeonInstance.icon, 0, 2, 0, 0, 2)
			instanceLabel:SetFrameWidthFromText()

			bossLabel:SetText(boss.name, kInstanceAndBossPadding, dungeonEncounterID)
			bossLabel:SetIcon(boss.icon, 0, 2, 0, 0, 2)
			bossLabel.icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)
			bossLabel:SetFrameWidthFromText()

			if difficulty == DifficultyType.Heroic then
				difficultyLabel:SetText(L["Heroic"], kInstanceAndBossPadding, difficulty)
			else
				difficultyLabel:SetText(L["Mythic"], kInstanceAndBossPadding, difficulty)
			end
			difficultyLabel.icon:SetTexCoord(GetTextCoordsFromDifficulty(difficulty, true))
			difficultyLabel:SetFrameWidthFromText()

			Private.mainFrame:UpdateHorizontalResizeBounds()
			bossAbilityContainer:ReleaseChildren()

			local bossAbilityHeight = profile.preferences.timelineRows.bossAbilityHeight

			local children = {}
			local bossAbilitySelectItems = {}
			local bossAbilities = GetBossAbilities(boss, difficulty)
			for _, abilityID in ipairs(sortedAbilityIDs) do
				if activeBossAbilities[abilityID] == nil then
					activeBossAbilities[abilityID] = not bossAbilities[abilityID].defaultHidden
				end

				local icon, text
				if activeBossAbilities[abilityID] == true or updateBossAbilitySelectDropdown then
					icon, text = GetBossAbilityIconAndLabel(boss, abilityID, difficulty)
				end

				if activeBossAbilities[abilityID] == true then
					local abilityEntry = AceGUI:Create("EPAbilityEntry")
					abilityEntry:SetFullWidth(true)
					abilityEntry:SetBossAbility(abilityID, text, icon)
					abilityEntry:HideCheckBox()
					abilityEntry:SetHeight(bossAbilityHeight)
					tinsert(children, abilityEntry)
				end
				if updateBossAbilitySelectDropdown then
					tinsert(bossAbilitySelectItems, CreateAbilityDropdownItemData(abilityID, icon, text))
				end
			end

			if #children > 0 then
				bossAbilityContainer:AddChildren(unpack(children))
			end

			if updateBossAbilitySelectDropdown then
				local bossAbilitySelectDropdown = Private.mainFrame.bossMenuButton
				if bossAbilitySelectDropdown then
					bossAbilitySelectDropdown:ClearExistingDropdownItemMenu("Filter Spells")
					bossAbilitySelectDropdown:AddItemsToExistingDropdownItemMenu(
						"Filter Spells",
						bossAbilitySelectItems
					)
					bossAbilitySelectDropdown:SetSelectedItems(activeBossAbilities, "Filter Spells")
				end
			end
		end
	end

	local GetBossAbilityInstances = bossUtilities.GetBossAbilityInstances
	local GetBossPhases = bossUtilities.GetBossPhases

	-- Sets the boss abilities for the timeline and rerenders it.
	---@param boss Boss
	---@param timeline EPTimeline
	---@param activeBossAbilities table<integer, boolean>
	---@param sortedAbilityIDs table<integer, integer>
	---@param difficulty DifficultyType
	local function UpdateTimelineBossAbilities(boss, timeline, activeBossAbilities, sortedAbilityIDs, difficulty)
		local bossDungeonEncounterID = boss.dungeonEncounterID
		local bossPhaseTable = GetOrderedBossPhases(bossDungeonEncounterID, difficulty)
		if bossPhaseTable then
			local abilityInstances = GetBossAbilityInstances(bossDungeonEncounterID, difficulty)
			local phases = GetBossPhases(boss, difficulty)
			timeline:SetBossAbilities(abilityInstances, sortedAbilityIDs, phases, bossPhaseTable, activeBossAbilities)
			timeline:UpdateTimeline()
			Private.mainFrame:DoLayout()
		end
	end

	local GetActiveBossAbilities = utilities.GetActiveBossAbilities
	local GetSortedBossAbilityIDs = bossUtilities.GetSortedBossAbilityIDs

	-- Updates the list of boss abilities and the boss ability timeline.
	---@param bossDungeonEncounterID integer
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	function InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, updateBossAbilitySelectDropdown)
		local plan = GetCurrentPlan()
		local difficulty = plan.difficulty
		if sLastBossDungeonEncounterID ~= 0 then
			ResetBossPhaseTimings(sLastBossDungeonEncounterID, sLastDifficulty)
			ResetBossPhaseCounts(sLastBossDungeonEncounterID, sLastDifficulty)
		end
		sLastBossDungeonEncounterID = bossDungeonEncounterID
		sLastDifficulty = difficulty
		local boss = GetBoss(bossDungeonEncounterID)
		if boss then
			SetPhaseDurations(bossDungeonEncounterID, plan.customPhaseDurations, difficulty)
			plan.customPhaseCounts =
				SetPhaseCounts(bossDungeonEncounterID, plan.customPhaseCounts, kMaxBossDuration, difficulty)
			GenerateBossTables(boss, difficulty)
			local timeline = Private.mainFrame.timeline
			if timeline then
				local sortedAbilityIDs = GetSortedBossAbilityIDs(boss, difficulty)
				local activeBossAbilities = GetActiveBossAbilities(bossDungeonEncounterID, difficulty)
				UpdateBossAbilityList(
					boss,
					timeline,
					updateBossAbilitySelectDropdown,
					activeBossAbilities,
					sortedAbilityIDs,
					difficulty
				)
				UpdateTimelineBossAbilities(boss, timeline, activeBossAbilities, sortedAbilityIDs, difficulty)
			end
		end
	end
end

do
	local CreateReminderText = utilities.CreateReminderText
	local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID
	local FindBossAbility = bossUtilities.FindBossAbility
	local GetAvailableCombatLogEventTypes = bossUtilities.GetAvailableCombatLogEventTypes
	local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
	local GetSpellName = C_Spell.GetSpellName

	local kAssignmentMetaTables = {
		CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
		TimedAssignment = Private.classes.TimedAssignment,
	}
	local kCloseTexture = constants.textures.kClose

	---@param abilityEntry EPAbilityEntry
	local function HandleDeleteAssigneeRowClicked(abilityEntry)
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end
		local key = abilityEntry:GetKey()
		if key then
			local plan = GetCurrentPlan()

			local removedAssignmentCount, removedTemplateCount = 0, 0
			if type(key) == "string" then
				removedAssignmentCount, removedTemplateCount = utilities.RemoveAssignmentFromPlan(plan, key)
			elseif type(key) == "table" then
				local assignee = key.assignee
				local spellID = key.spellID
				removedAssignmentCount, removedTemplateCount =
					utilities.RemoveAssignmentFromPlan(plan, assignee, spellID)
			end
			local lowerAssignment, lowerTemplate
			if removedAssignmentCount == 1 then
				lowerAssignment = L["Assignment"]:lower()
			else
				lowerAssignment = L["assignments"]
			end
			if removedTemplateCount == 1 then
				lowerTemplate = L["Template"]:lower()
			else
				lowerTemplate = L["Templates"]:lower()
			end
			InterfaceUpdater.LogMessage(
				format(
					"%s %d %s, %d %s.",
					L["Removed"],
					removedAssignmentCount,
					lowerAssignment,
					removedTemplateCount,
					lowerTemplate
				)
			)
			InterfaceUpdater.UpdateAllAssignments(false)
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "deleteAssigneeRowClicked")
			end
		end
	end

	---@param abilityEntry EPAbilityEntry
	---@param shouldCollapse boolean
	local function HandleCollapseButtonClicked(abilityEntry, _, shouldCollapse)
		local collapsed = GetCurrentPlan().collapsed
		collapsed[abilityEntry:GetKey()] = shouldCollapse
		InterfaceUpdater.UpdateAllAssignments(false)
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(
				Private.activeTutorialCallbackName,
				"assigneeCollapsed",
				abilityEntry:GetKey(),
				shouldCollapse
			)
		end
	end

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapButtonClicked(abilityEntry)
		local roster = GetCurrentRoster()
		local items, enableIndividualItem = CreateAssignmentTypeWithRosterDropdownItems(roster)
		abilityEntry:SetAssigneeDropdownItems(items)
		abilityEntry.dropdown:SetItemEnabled("Individual", enableIndividualItem)
	end

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapAssignee(abilityEntry, _, newAssignee)
		local key = abilityEntry:GetKey()
		if key then
			local plan = GetCurrentPlan()
			local assignments = plan.assignments
			if type(key) == "string" then
				for _, assignment in ipairs(assignments) do
					if assignment.assignee == key then
						assignment.assignee = newAssignee
					end
				end
				plan.collapsed[key] = nil
			elseif type(key) == "table" then
				local assignee = key.assignee
				local spellID = key.spellID
				for _, assignment in ipairs(assignments) do
					if assignment.assignee == assignee and assignment.spellID == spellID then
						assignment.assignee = newAssignee
					end
				end
				plan.collapsed[assignee] = nil
			end
			local bossDungeonEncounterID = plan.dungeonEncounterID
			local difficulty = plan.difficulty
			InterfaceUpdater.UpdateAllAssignments(false)
			if Private.assignmentEditor then
				local assignmentEditor = Private.assignmentEditor
				local assignmentID = assignmentEditor:GetAssignmentID()
				if assignmentID then
					local assignment = FindAssignmentByUniqueID(assignments, assignmentID)
					if assignment then
						local previewText = CreateReminderText(assignment, plan.roster, true)
						local availableCombatLogEventTypes =
							GetAvailableCombatLogEventTypes(bossDungeonEncounterID, difficulty)
						local spellSpecificCombatLogEventTypes = nil
						local combatLogEventSpellID = assignment.combatLogEventSpellID
						if combatLogEventSpellID then
							local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID, difficulty)
							if ability then
								spellSpecificCombatLogEventTypes = ability.allowedCombatLogEventTypes
							end
						end
						assignmentEditor:PopulateFields(
							assignment,
							GetCurrentRoster(),
							previewText,
							kAssignmentMetaTables,
							availableCombatLogEventTypes,
							spellSpecificCombatLogEventTypes,
							AddOn.db.profile.favoritedSpellAssignments
						)
					else
						assignmentEditor:Release()
					end
				else
					assignmentEditor:Release()
				end
			end
		end
	end

	---@param widget EPAbilityEntry
	local function HandleAssigneeRowDeleteButtonClicked(widget)
		local messageBoxData = {
			ID = Private.GenerateUniqueID(),
			widgetType = "EPMessageBox",
			isCommunication = false,
			title = L["Delete Assignments Confirmation"],
			message = format(
				"%s %s?",
				format(L["Are you sure you want to delete all %s assignments and templates for"], ""):gsub("  ", " "),
				widget:GetText()
			),
			acceptButtonText = L["Okay"],
			acceptButtonCallback = function()
				if Private.mainFrame then
					HandleDeleteAssigneeRowClicked(widget)
				end
			end,
			rejectButtonText = L["Cancel"],
			rejectButtonCallback = nil,
			buttonsToAdd = {},
		} --[[@as MessageBoxData]]
		InterfaceUpdater.CreateMessageBox(messageBoxData, false)
	end

	---@param widget EPAbilityEntry
	local function HandleAssigneeSpellRowDeleteButtonClicked(widget)
		local spellEntryKey = widget:GetKey()
		if not spellEntryKey then
			return
		end
		local spellName
		if spellEntryKey.spellID == constants.kInvalidAssignmentSpellID then
			spellName = L["Unknown"]
		elseif spellEntryKey.spellID == constants.kTextAssignmentSpellID then
			spellName = L["Text"]
		else
			spellName = GetSpellName(spellEntryKey.spellID)
		end
		local messageBoxData = {
			ID = Private.GenerateUniqueID(),
			widgetType = "EPMessageBox",
			isCommunication = false,
			title = L["Delete Assignments Confirmation"],
			message = format(
				"%s %s?",
				format(L["Are you sure you want to delete all %s assignments and templates for"], spellName),
				spellEntryKey.coloredAssignee or spellEntryKey.assignee
			),
			acceptButtonText = L["Okay"],
			acceptButtonCallback = function()
				if Private.mainFrame then
					HandleDeleteAssigneeRowClicked(widget)
				end
			end,
			rejectButtonText = L["Cancel"],
			rejectButtonCallback = nil,
			buttonsToAdd = {},
		} --[[@as MessageBoxData]]
		InterfaceUpdater.CreateMessageBox(messageBoxData, false)
	end

	-- Clears and repopulates the list of assignments and spells.
	---@param assigneeSpellSets table<integer, AssigneeSpellSet>
	---@param firstUpdate boolean|nil
	local function UpdateAssignmentList(assigneeSpellSets, firstUpdate)
		local timeline = Private.mainFrame.timeline
		if timeline then
			local assignmentContainer = timeline:GetAssignmentContainer()
			if assignmentContainer then
				assignmentContainer:ReleaseChildren()
				local children = {}
				local plan = GetCurrentPlan()
				local roster = plan.roster
				local collapsed = plan.collapsed
				local assignmentHeight = AddOn.db.profile.preferences.timelineRows.assignmentHeight
				for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
					local assignee = assigneeSpellSet.assignee
					local entryText = utilities.ConvertAssigneeToLegibleString(assignee, roster)
					local assigneeCollapsed = collapsed[assignee]

					local specIconID = nil
					local specMatch = assignee:match("spec:%s*(%d+)")
					if specMatch then
						local specIDMatch = tonumber(specMatch)
						if specIDMatch then
							local _, _, _, icon, _ = GetSpecializationInfo(specIDMatch)
							specIconID = icon
							entryText = entryText:gsub("|T[^|]+|t%s*", "")
						end
					end

					local assigneeEntry = AceGUI:Create("EPAbilityEntry")
					assigneeEntry:SetText(entryText, assignee, 2)
					assigneeEntry:SetFullWidth(true)
					assigneeEntry:SetCheckedTexture(kCloseTexture)
					assigneeEntry:SetRoleOrSpec(roster[assignee] and roster[assignee].role or specIconID or nil)
					assigneeEntry:SetCollapsible(true)
					assigneeEntry:ShowSwapIcon(true)
					assigneeEntry:SetCollapsed(assigneeCollapsed)
					assigneeEntry:SetHeight(assignmentHeight)
					assigneeEntry:SetCallback("SwapButtonClicked", HandleSwapButtonClicked)
					assigneeEntry:SetCallback("CollapseButtonToggled", HandleCollapseButtonClicked)
					assigneeEntry:SetCallback("AssigneeSwapped", HandleSwapAssignee)
					assigneeEntry:SetCallback("OnValueChanged", HandleAssigneeRowDeleteButtonClicked)
					tinsert(children, assigneeEntry)

					if not assigneeCollapsed then
						for _, spellID in ipairs(assigneeSpellSet.spells) do
							local spellEntry = AceGUI:Create("EPAbilityEntry")
							local key = { assignee = assignee, spellID = spellID, coloredAssignee = entryText }
							if spellID == kInvalidAssignmentSpellID then
								spellEntry:SetNullAbility(key)
							elseif spellID == kTextAssignmentSpellID then
								spellEntry:SetGeneralAbility(key)
							else
								spellEntry:SetAbility(spellID, key)
							end
							spellEntry:SetFullWidth(true)
							spellEntry:SetLeftIndent(assignmentHeight / 2.0 - 2)
							spellEntry:SetHeight(assignmentHeight)
							spellEntry:SetCheckedTexture(kCloseTexture)
							spellEntry:SetCallback("OnValueChanged", HandleAssigneeSpellRowDeleteButtonClicked)
							tinsert(children, spellEntry)
						end
					end
				end
				if #children > 0 then
					assignmentContainer:AddChildren(unpack(children))
				end
			end
			if not firstUpdate then
				Private.mainFrame:DoLayout()
			end
		end
	end

	-- Sets the effectiveCooldownDuration, relativeChargeRestoreTime, and invalidChargeCast fields on timeline
	-- assignments.
	---@param timelineAssignments table<integer, TimelineAssignment> Timeline assignments grouped by spellID.
	function InterfaceUpdater.ComputeChargeStates(timelineAssignments)
		local chargeQueueBySpellID = {} -- Holds the future times when a charge comes up, relative to encounter start

		for _, timelineAssignment in ipairs(timelineAssignments) do
			local spellID = timelineAssignment.assignment.spellID
			if spellID > constants.kTextAssignmentSpellID then
				local maxCharges = timelineAssignment.maxCharges
				local startTime = timelineAssignment.startTime
				local cooldownDuration = timelineAssignment.cooldownDuration

				timelineAssignment.effectiveCooldownDuration = cooldownDuration
				timelineAssignment.relativeChargeRestoreTime = nil

				chargeQueueBySpellID[spellID] = chargeQueueBySpellID[spellID] or {}
				local chargeQueue = chargeQueueBySpellID[spellID]

				-- Restore charges that would have come up by the time this cast occurs
				while chargeQueue[1] and chargeQueue[1].restorationTime <= startTime do
					tremove(chargeQueue, 1)
				end

				local currentCharges = maxCharges - #chargeQueue
				if currentCharges > 0 then -- Consume a charge by inserting into queue
					local regentStartTime = startTime
					local lastRegenQueueEntry = chargeQueue[#chargeQueue]
					if lastRegenQueueEntry then
						regentStartTime = max(regentStartTime, lastRegenQueueEntry.restorationTime)
					end
					local regenEndTime = regentStartTime + cooldownDuration
					tinsert(chargeQueue, { restorationTime = regenEndTime, covered = false })
					timelineAssignment.effectiveCooldownDuration = regenEndTime - startTime
					timelineAssignment.invalidChargeCast = false
				else
					timelineAssignment.invalidChargeCast = true
				end

				for _, regen in ipairs(chargeQueue) do
					local restorationTime = regen.restorationTime
					if restorationTime > startTime then
						local relativeTime = restorationTime - startTime
						if relativeTime > 0 and relativeTime < timelineAssignment.effectiveCooldownDuration then
							-- Charge will be restored during the duration of this cooldown
							if maxCharges > 1 and not regen.covered then
								timelineAssignment.relativeChargeRestoreTime = relativeTime
								regen.covered = true -- Prevent repeat charge drawing
							end
							-- Don't extend cooldown duration past last valid duration
							if timelineAssignment.invalidChargeCast then
								timelineAssignment.effectiveCooldownDuration = 0
							end
							break -- There can only ever be one
						end
					end
				end
			end
		end
	end

	local SortAssigneesWithSpellID = utilities.SortAssigneesWithSpellID
	local ComputeChargeStates = InterfaceUpdater.ComputeChargeStates
	local MergeTemplatesSorted = utilities.MergeTemplatesSorted

	-- Sorts assignments & assignees, updates the assignment list, timeline assignments, and optionally the add assignee
	-- dropdown.
	---@param updateAddAssigneeDropdown boolean Whether or not to update the add assignee dropdown
	---@param firstUpdate boolean|nil Whether or not this is the first update.
	---@param preserve boolean|nil Whether or not to preserve the current message log.
	function InterfaceUpdater.UpdateAllAssignments(updateAddAssigneeDropdown, firstUpdate, preserve)
		local currentPlan = GetCurrentPlan()
		local profile = AddOn.db.profile
		local sortType = profile.preferences.assignmentSortType
		local cooldownAndChargeOverrides = profile.cooldownAndChargeOverrides
		local onlyShowMe = profile.preferences.timelineRows.onlyShowMe
		local sortedTimelineAssignments =
			SortAssignments(currentPlan, sortType, cooldownAndChargeOverrides, onlyShowMe, preserve)
		local orderedAssigneeSpellSets, groupedByAssignee = SortAssigneesWithSpellID(sortedTimelineAssignments)
		for _, timelineAssignments in pairs(groupedByAssignee) do
			ComputeChargeStates(timelineAssignments)
		end
		orderedAssigneeSpellSets = MergeTemplatesSorted(
			orderedAssigneeSpellSets,
			currentPlan.assigneeSpellSets,
			currentPlan.roster,
			sortType,
			onlyShowMe
		)

		UpdateAssignmentList(orderedAssigneeSpellSets, firstUpdate)

		local timeline = Private.mainFrame.timeline
		if timeline then
			timeline:SetAssignments(sortedTimelineAssignments, orderedAssigneeSpellSets, currentPlan.collapsed)
			if not firstUpdate then
				timeline:UpdateTimeline()
				Private.mainFrame:DoLayout()
			end
			-- Sometimes items in this container are invisible for unknown reasons..
			timeline.assignmentTimeline.listContainer:DoLayout()
		end

		if updateAddAssigneeDropdown then
			InterfaceUpdater.UpdateAddAssigneeDropdown()
		end
	end
end

-- Clears and repopulates the add assignee dropdown from the current roster.
function InterfaceUpdater.UpdateAddAssigneeDropdown()
	local addAssigneeDropdown = Private.mainFrame.timeline:GetAddAssigneeDropdown()
	if addAssigneeDropdown then
		addAssigneeDropdown:Clear()
		local text = AddIconBeforeText(constants.textures.kAdd, L["Add Assignee"])
		addAssigneeDropdown:SetText(text)
		local roster = GetCurrentRoster()
		local items, enableIndividualItem = CreateAssignmentTypeWithRosterDropdownItems(roster)
		addAssigneeDropdown:AddItems(items, "EPDropdownItemToggle", true)
		addAssigneeDropdown:SetItemEnabled("Individual", enableIndividualItem)
	end
end

-- Releases the assignment editor, updates boss and assignments, and updates plan checkboxes.
---@param plan Plan
---@param preserve boolean|nil Whether or not to preserve the current message log.
function InterfaceUpdater.UpdateFromPlan(plan, preserve)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.mainFrame then
		AddOn.db.profile.lastOpenPlan = plan.name
		InterfaceUpdater.RepopulatePlanWidgets()
		local bossDungeonEncounterID = plan.dungeonEncounterID
		if bossDungeonEncounterID then
			InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			InterfaceUpdater.UpdateAllAssignments(true, nil, preserve)
		end
		Private.mainFrame:DoLayout()
	end
end

do
	local kReminderDisabledIconColor = { 0.35, 0.35, 0.35, 1 }
	local kReminderDisabledTexture = constants.textures.kNoReminder
	local kReminderEnabledIconColor = { 1, 0.82, 0, 1 }
	local kReminderEnabledTexture = constants.textures.kReminder

	---@param plan Plan
	function InterfaceUpdater.UpdatePlanCheckBoxes(plan)
		if Private.mainFrame then
			local primaryPlanCheckBox = Private.mainFrame.primaryPlanCheckBox
			if primaryPlanCheckBox then
				local isPrimary = plan.isPrimaryPlan
				primaryPlanCheckBox:SetChecked(isPrimary)
				primaryPlanCheckBox:SetEnabled(not isPrimary)
			end
			local preferences = AddOn.db.profile.preferences
			local planReminderEnableCheckBox = Private.mainFrame.planReminderEnableCheckBox
			if planReminderEnableCheckBox then
				planReminderEnableCheckBox:SetChecked(plan.remindersEnabled)
				planReminderEnableCheckBox:SetEnabled(preferences.reminder.enabled)
			end
			local simulateReminderButton = Private.mainFrame.simulateRemindersButton
			if simulateReminderButton then
				simulateReminderButton:SetEnabled(preferences.reminder.enabled)
			end
		end
	end

	local CreateDropdownItemDataPlanSorter = utilities.CreateDropdownItemDataPlanSorter
	local FormatPlanText = utilities.FormatPlanText

	-- Clears and repopulates the plan dropdown, selecting the last open plan and setting reminder enabled check box value.
	function InterfaceUpdater.RepopulatePlanWidgets()
		if Private.mainFrame then
			local lastOpenPlan = AddOn.db.profile.lastOpenPlan
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				planDropdown:Clear()
				local instanceDropdownData = utilities.GetOrCreateInstanceDropdownItems()
				local plans = AddOn.db.profile.plans
				for planName, plan in pairs(plans) do
					local instanceID = plan.instanceID
					local customTexture = plan.remindersEnabled and kReminderEnabledTexture or kReminderDisabledTexture
					local color = plan.remindersEnabled and kReminderEnabledIconColor or kReminderDisabledIconColor
					for _, dropdownData in pairs(instanceDropdownData) do
						local boss = GetBoss(plan.dungeonEncounterID)
						local dungeonInstanceID, mapChallengeModeID
						if boss then
							dungeonInstanceID, mapChallengeModeID = boss.instanceID, boss.mapChallengeModeID
						end

						local same = false
						if type(dropdownData.itemValue) == "table" then
							same = dropdownData.itemValue.dungeonInstanceID == dungeonInstanceID
								and dropdownData.itemValue.mapChallengeModeID == mapChallengeModeID
						else
							same = dropdownData.itemValue == instanceID
						end
						if same then
							local text = FormatPlanText(planName, boss.icon, plan.difficulty)
							tinsert(dropdownData.dropdownItemMenuData, {
								itemValue = planName,
								text = text,
								customTexture = customTexture,
								customTextureVertexColor = color,
								mapChallengeModeID = mapChallengeModeID,
								dungeonEncounterID = plan.dungeonEncounterID,
							})
							break
						end
					end
				end
				for _, dropdownData in pairs(instanceDropdownData) do
					if dropdownData.dropdownItemMenuData then
						sort(dropdownData.dropdownItemMenuData, CreateDropdownItemDataPlanSorter(dropdownData))
					end
				end
				planDropdown:AddItems(instanceDropdownData, "EPDropdownItemToggle")
				planDropdown:SetValue(lastOpenPlan)
				planDropdown:SetText(lastOpenPlan)
			end
			InterfaceUpdater.UpdatePlanCheckBoxes(AddOn.db.profile.plans[lastOpenPlan])
		end
	end

	local CreatePlanSorter = utilities.CreateDropdownItemPlanSorter

	-- Adds a new plan name to the plan dropdown and optionally selects it and updates the reminder enabled check box.
	---@param plan Plan
	---@param select boolean
	function InterfaceUpdater.AddPlanToDropdown(plan, select)
		if Private.mainFrame then
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				local items = planDropdown:FindItems(plan.name)
				local enabled = plan.remindersEnabled
				if #items == 0 then
					local customTexture = enabled and kReminderEnabledTexture or kReminderDisabledTexture
					local color = enabled and kReminderEnabledIconColor or kReminderDisabledIconColor
					local boss = GetBoss(plan.dungeonEncounterID)
					local text = FormatPlanText(plan.name, boss.icon, plan.difficulty)
					local dropdownItemData = {
						itemValue = plan.name,
						text = text,
						customTexture = customTexture,
						customTextureVertexColor = color,
					}

					if boss and boss.mapChallengeModeID then
						planDropdown:AddItemsToExistingDropdownItemMenu({
							dungeonInstanceID = plan.instanceID,
							mapChallengeModeID = boss.mapChallengeModeID,
						}, { dropdownItemData })
						planDropdown:Sort({
							dungeonInstanceID = plan.instanceID,
							mapChallengeModeID = boss.mapChallengeModeID,
						}, nil, CreatePlanSorter(boss))
					elseif boss then
						planDropdown:AddItemsToExistingDropdownItemMenu(plan.instanceID, { dropdownItemData })
						planDropdown:Sort(plan.instanceID, nil, CreatePlanSorter(boss))
					end
				end
				if select then
					planDropdown:SetValue(plan.name)
					planDropdown:SetText(plan.name)
				end
			end
			InterfaceUpdater.UpdatePlanCheckBoxes(plan)
		end
	end

	-- Removes a plan name from the plan dropdown.
	---@param planName string
	function InterfaceUpdater.RemovePlanFromDropdown(planName)
		if Private.mainFrame then
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				planDropdown:RemoveItem(planName)
			end
		end
	end

	---@param planName string
	---@param enabled boolean
	function InterfaceUpdater.UpdatePlanDropdownItemCustomTexture(planName, enabled)
		if Private.mainFrame then
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				local items = planDropdown:FindItems(planName)
				local customTexture = enabled and kReminderEnabledTexture or kReminderDisabledTexture
				local color = enabled and kReminderEnabledIconColor or kReminderDisabledIconColor
				for _, itemData in pairs(items) do
					itemData.item:SetCustomTexture(customTexture, color, false)
				end
			end
		end
	end
end

do
	local InCombatLockdown = InCombatLockdown
	local sMessageBox = nil ---@type EPMessageBox|EPDiffViewer|nil
	local sMessageQueue = {} ---@type table<integer, MessageBoxData>
	local sIsExecutingCallbacks = false

	local function Enqueue(messageBoxData)
		tinsert(sMessageQueue, messageBoxData)
	end

	---@return MessageBoxData|nil
	local function Dequeue()
		if #sMessageQueue > 0 then
			return tremove(sMessageQueue, 1)
		end
	end

	---@param onlyNonCommunication boolean
	local function ClearQueue(onlyNonCommunication)
		local newQueue = {}
		for _, messageBoxData in ipairs(sMessageQueue) do
			if onlyNonCommunication and messageBoxData.isCommunication then
				tinsert(newQueue, messageBoxData)
			end
		end
		sMessageQueue = newQueue
	end

	local function ProcessMessageQueue()
		Private:UnregisterEvent("PLAYER_REGEN_ENABLED")
		if not sMessageBox and #sMessageQueue > 0 then
			local messageBoxData = Dequeue()
			if messageBoxData then
				InterfaceUpdater.CreateMessageBox(messageBoxData, false)
			end
		end
	end

	---@param callback fun()
	local function ExecuteCallback(callback)
		if callback then
			sIsExecutingCallbacks = true
			callback()
			sIsExecutingCallbacks = false
		end
	end

	local function HandleMessageBoxReleased()
		sMessageBox = nil
		ProcessMessageQueue()
	end

	---@param messageBoxData MessageBoxData
	---@param queueIfNotCreated boolean
	---@return boolean
	function InterfaceUpdater.CreateMessageBox(messageBoxData, queueIfNotCreated)
		if InCombatLockdown() then
			if queueIfNotCreated then
				Enqueue(messageBoxData)
				Private:RegisterEvent("PLAYER_REGEN_ENABLED", ProcessMessageQueue)
			end
			return false
		else
			if not sMessageBox then
				if messageBoxData.widgetType == "EPMessageBox" then
					sMessageBox = AceGUI:Create("EPMessageBox")
					sMessageBox.frame:SetParent(UIParent)
					sMessageBox.frame:SetFrameLevel(kMessageBoxFrameLevel)
					sMessageBox:SetTitle(messageBoxData.title)
					sMessageBox:SetText(messageBoxData.message)
					sMessageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					sMessageBox:SetPoint("TOP", UIParent, "TOP", 0, -sMessageBox.frame:GetBottom())
					sMessageBox:SetAcceptButtonText(messageBoxData.acceptButtonText)
					sMessageBox:SetRejectButtonText(messageBoxData.rejectButtonText)
					sMessageBox.isCommunicationsMessage = messageBoxData.isCommunication
				elseif messageBoxData.widgetType == "EPDiffViewer" then
					sMessageBox = AceGUI:Create("EPDiffViewer")
					sMessageBox.frame:SetParent(UIParent)
					sMessageBox.frame:SetFrameLevel(kMessageBoxFrameLevel)
					sMessageBox:SetText(messageBoxData.message)
					sMessageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					sMessageBox:SetPoint("TOP", UIParent, "TOP", 0, -sMessageBox.frame:GetBottom())
					sMessageBox:AddDiffs(messageBoxData.planDiff, messageBoxData.oldPlan, messageBoxData.newPlan)
				end
				if sMessageBox then
					sMessageBox:SetCallback("OnRelease", HandleMessageBoxReleased)
					sMessageBox:SetCallback("Accepted", function()
						AceGUI:Release(sMessageBox)
						ExecuteCallback(messageBoxData.acceptButtonCallback)
					end)
					sMessageBox:SetCallback("Rejected", function()
						AceGUI:Release(sMessageBox)
						if type(messageBoxData.rejectButtonCallback) == "function" then
							ExecuteCallback(messageBoxData.rejectButtonCallback)
						end
					end)
					for _, buttonToAdd in ipairs(messageBoxData.buttonsToAdd) do
						local button = sMessageBox.buttonContainer.children[buttonToAdd.beforeButtonIndex]
						if button then
							sMessageBox:AddButton(buttonToAdd.buttonText, button)
							sMessageBox:SetCallback(buttonToAdd.buttonText .. "Clicked", function()
								AceGUI:Release(sMessageBox)
								if type(buttonToAdd.callback) == "function" then
									ExecuteCallback(buttonToAdd.callback)
								end
							end)
						else
							error(AddOnName .. ": Invalid button index.")
						end
					end
				end
				return true
			elseif queueIfNotCreated then
				Enqueue(messageBoxData)
			end
			return false
		end
	end

	---@param onlyNonCommunication boolean
	function InterfaceUpdater.RemoveMessageBoxes(onlyNonCommunication)
		ClearQueue(onlyNonCommunication)

		if not sIsExecutingCallbacks and sMessageBox then
			local isCurrentCommunication = sMessageBox.isCommunicationsMessage
			if not onlyNonCommunication or isCurrentCommunication then
				sMessageBox:Release()
			end
		end

		if not onlyNonCommunication then
			Private:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end

	---@param messageBoxDataID string
	function InterfaceUpdater.RemoveFromMessageQueue(messageBoxDataID)
		for index, messageBoxData in ipairs(sMessageQueue) do
			if messageBoxData.ID == messageBoxDataID then
				tremove(sMessageQueue, index)
				break
			end
		end
	end
end

do
	local sMessageLog = {} ---@type table<integer, {message: string, severityLevel: integer, indentLevel: integer}>

	---@param message string
	---@param severityLevel SeverityLevel?
	---@param indentLevel IndentLevel?
	function InterfaceUpdater.LogMessage(message, severityLevel, indentLevel)
		tinsert(sMessageLog, { message = message, severityLevel = severityLevel, indentLevel = indentLevel })
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:AddMessage(message, severityLevel, indentLevel)
		end
	end

	function InterfaceUpdater.ClearMessageLog()
		wipe(sMessageLog)
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:ClearMessages()
		end
	end

	function InterfaceUpdater.RestoreMessageLog()
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:ClearMessages()
			Private.mainFrame.statusBar:AddMessages(sMessageLog)
		end
	end
end

---@param planID string
---@return string|nil
---@return Plan|nil
function InterfaceUpdater.FindMatchingPlan(planID)
	local plans = AddOn.db.profile.plans
	for planName, plan in pairs(plans) do
		if plan.ID == planID then
			return planName, plan
		end
	end
end

do
	local kAssignmentMetaTables = {
		CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
		TimedAssignment = Private.classes.TimedAssignment,
	}

	-- Syncs the Assignment Editor and optionally the timeline with data from the assignment.
	---@param dungeonEncounterID integer Boss dungeon encounter ID.
	---@param difficulty DifficultyType
	---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment Assignment to update from.
	---@param updateFields boolean If true, updates all fields in the Assignment Editor from the assignment.
	---@param updateTimeline boolean If true, the timeline assignment start time is updated, UpdateTimeline is called, and selected boss abilities are updated.
	---@param updateAssignments boolean If true, UpdateAllAssignments is called
	---@param scrollAssignmentIntoView boolean If true, assignment is scrolled into view.
	function InterfaceUpdater.UpdateFromAssignment(
		dungeonEncounterID,
		difficulty,
		assignment,
		updateFields,
		updateTimeline,
		updateAssignments,
		scrollAssignmentIntoView
	)
		if updateFields and Private.assignmentEditor then
			local roster = GetCurrentRoster()
			local previewText = utilities.CreateReminderText(assignment, roster, true)
			local availableCombatLogEventTypes =
				bossUtilities.GetAvailableCombatLogEventTypes(dungeonEncounterID, difficulty)
			local spellSpecificCombatLogEventTypes = nil
			local combatLogEventSpellID = assignment.combatLogEventSpellID
			if combatLogEventSpellID then
				local ability = bossUtilities.FindBossAbility(dungeonEncounterID, combatLogEventSpellID, difficulty)
				if ability then
					spellSpecificCombatLogEventTypes = ability.allowedCombatLogEventTypes
				end
			end
			Private.assignmentEditor:PopulateFields(
				assignment,
				roster,
				previewText,
				kAssignmentMetaTables,
				availableCombatLogEventTypes,
				spellSpecificCombatLogEventTypes,
				AddOn.db.profile.favoritedSpellAssignments
			)
		end

		local timeline = Private.mainFrame.timeline
		if timeline then
			if updateAssignments then
				InterfaceUpdater.UpdateAllAssignments(false)
			end
			if updateTimeline then
				if not updateAssignments then
					local timelineAssignment = timeline.FindTimelineAssignment(assignment.uniqueID)
					if timelineAssignment then
						utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, dungeonEncounterID, difficulty)
					end
					timeline:UpdateTimeline()
				end
				timeline.ClearSelectedAssignments()
				timeline.ClearSelectedBossAbilities()
				timeline.SelectAssignment(assignment.uniqueID, AssignmentSelectionType.kSelection)
				if assignment.combatLogEventSpellID and assignment.spellCount then
					timeline.SelectBossAbility(
						assignment.combatLogEventSpellID,
						assignment.spellCount,
						BossAbilitySelectionType.kSelection
					)
				end
			end
			if scrollAssignmentIntoView then
				timeline:ScrollAssignmentIntoView(assignment.uniqueID)
			end
		end
	end
end
