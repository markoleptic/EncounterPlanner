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

	local instanceAndBossPadding = 4
	local kMaxBossDuration = constants.kMaxBossDuration
	local lastBossDungeonEncounterID = 0
	local lastDifficulty = DifficultyType.Mythic

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
					instanceAndBossPadding,
					{ dungeonInstanceID = dungeonInstance.instanceID, mapChallengeModeID = boss.mapChallengeModeID }
				)
			else
				instanceLabel:SetText(dungeonInstance.name, instanceAndBossPadding, dungeonInstance.instanceID)
			end
			instanceLabel:SetIcon(dungeonInstance.icon, 0, 2, 0, 0, 2)
			instanceLabel:SetFrameWidthFromText()

			bossLabel:SetText(boss.name, instanceAndBossPadding, dungeonEncounterID)
			bossLabel:SetIcon(boss.icon, 0, 2, 0, 0, 2)
			bossLabel:SetFrameWidthFromText()

			if difficulty == DifficultyType.Heroic then
				difficultyLabel:SetText(L["Heroic"], instanceAndBossPadding, difficulty)
			else
				difficultyLabel:SetText(L["Mythic"], instanceAndBossPadding, difficulty)
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
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local difficulty = plan.difficulty
		if lastBossDungeonEncounterID ~= 0 then
			ResetBossPhaseTimings(lastBossDungeonEncounterID, lastDifficulty)
			ResetBossPhaseCounts(lastBossDungeonEncounterID, lastDifficulty)
		end
		lastBossDungeonEncounterID = bossDungeonEncounterID
		lastDifficulty = difficulty
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
	local CreateAssignmentListTable = utilities.CreateAssignmentListTable
	local CreateReminderText = utilities.CreateReminderText
	local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID
	local FindBossAbility = bossUtilities.FindBossAbility
	local GetAvailableCombatLogEventTypes = bossUtilities.GetAvailableCombatLogEventTypes
	local GetSpecializationInfoByID = GetSpecializationInfoByID
	local GetSpellName = C_Spell.GetSpellName
	local SortAssigneesWithSpellID = utilities.SortAssigneesWithSpellID

	local assignmentMetaTables = {
		CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
		TimedAssignment = Private.classes.TimedAssignment,
		PhasedAssignment = Private.classes.PhasedAssignment,
	}

	---@param abilityEntry EPAbilityEntry
	local function HandleDeleteAssigneeRowClicked(abilityEntry)
		if Private.assignmentEditor then
			Private.assignmentEditor:Release()
		end

		local key = abilityEntry:GetKey()
		local removed = 0
		if key then
			local plan = GetCurrentPlan()
			local assignments = plan.assignments
			if type(key) == "string" then
				for i = #assignments, 1, -1 do
					if assignments[i].assignee == key then
						tremove(assignments, i)
						removed = removed + 1
					end
				end
				plan.collapsed[key] = nil
			elseif type(key) == "table" then
				local assignee = key.assignee
				local spellID = key.spellID
				for i = #assignments, 1, -1 do
					if assignments[i].assignee == assignee and assignments[i].spellID == spellID then
						tremove(assignments, i)
						removed = removed + 1
					end
				end
				plan.collapsed[assignee] = nil
			end
			InterfaceUpdater.UpdateAllAssignments(false, plan.dungeonEncounterID)
			local assignmentString = removed == 1 and L["Assignment"]:lower() or L["assignments"]
			InterfaceUpdater.LogMessage(format("%s %d %s.", L["Removed"], removed, assignmentString))
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "deleteAssigneeRowClicked")
			end
		end
	end

	---@param abilityEntry EPAbilityEntry
	---@param collapsed boolean
	local function HandleCollapseButtonClicked(abilityEntry, _, collapsed)
		AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed[abilityEntry:GetKey()] = collapsed
		local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
		if bossDungeonEncounterID then
			InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
		end
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(
				Private.activeTutorialCallbackName,
				"assigneeCollapsed",
				abilityEntry:GetKey(),
				collapsed
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
			InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
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
							previewText,
							assignmentMetaTables,
							availableCombatLogEventTypes,
							spellSpecificCombatLogEventTypes
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
			isCommunication = false,
			title = L["Delete Assignments Confirmation"],
			message = format(
				"%s %s %s?",
				L["Are you sure you want to delete all"],
				L["assignments for"],
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
			isCommunication = false,
			title = L["Delete Assignments Confirmation"],
			message = format(
				"%s %s %s %s?",
				L["Are you sure you want to delete all"],
				spellName,
				L["assignments for"],
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
	---@param sortedAssigneesAndSpells table<integer, {assignee:string, spellID:number|nil}>
	---@param firstUpdate boolean|nil
	local function UpdateAssignmentList(sortedAssigneesAndSpells, firstUpdate)
		local timeline = Private.mainFrame.timeline
		if timeline then
			local assignmentContainer = timeline:GetAssignmentContainer()
			if assignmentContainer then
				assignmentContainer:ReleaseChildren()
				local children = {}
				local roster = GetCurrentRoster()
				local map = CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
				local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
				local assignmentHeight = AddOn.db.profile.preferences.timelineRows.assignmentHeight
				for _, textTable in ipairs(map) do
					local assignee = textTable.assignee
					local coloredAssignee = textTable.text
					local assigneeCollapsed = collapsed[assignee]

					local specIconID = nil
					local specMatch = assignee:match("spec:%s*(%d+)")
					if specMatch then
						local specIDMatch = tonumber(specMatch)
						if specIDMatch then
							local _, _, _, icon, _ = GetSpecializationInfoByID(specIDMatch)
							specIconID = icon
							coloredAssignee = coloredAssignee:gsub("|T[^|]+|t%s*", "")
						end
					end

					local assigneeEntry = AceGUI:Create("EPAbilityEntry")
					assigneeEntry:SetText(coloredAssignee, assignee, 2)
					assigneeEntry:SetFullWidth(true)
					assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
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
						for _, spellID in ipairs(textTable.spells) do
							local spellEntry = AceGUI:Create("EPAbilityEntry")
							local key = { assignee = assignee, spellID = spellID, coloredAssignee = coloredAssignee }
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
							spellEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
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
	---@param timelineAssignments table<integer, TimelineAssignment>
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

	-- Sorts assignments & assignees, updates the assignment list, timeline assignments, and optionally the add assignee
	-- dropdown.
	---@param updateAddAssigneeDropdown boolean Whether or not to update the add assignee dropdown
	---@param bossDungeonEncounterID integer
	---@param firstUpdate boolean|nil
	---@param preserve boolean|nil Whether or not to preserve the current message log.
	function InterfaceUpdater.UpdateAllAssignments(
		updateAddAssigneeDropdown,
		bossDungeonEncounterID,
		firstUpdate,
		preserve
	)
		local currentPlan = GetCurrentPlan()
		local sortType = AddOn.db.profile.preferences.assignmentSortType
		local sortedTimelineAssignments =
			SortAssignments(currentPlan, sortType, bossDungeonEncounterID, preserve, currentPlan.difficulty)
		local sortedWithSpellID, groupedByAssignee =
			SortAssigneesWithSpellID(sortedTimelineAssignments, currentPlan.collapsed)
		for _, timelineAssignments in pairs(groupedByAssignee) do
			InterfaceUpdater.ComputeChargeStates(timelineAssignments)
		end
		UpdateAssignmentList(sortedWithSpellID, firstUpdate)

		local timeline = Private.mainFrame.timeline
		if timeline then
			local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
			timeline:SetAssignments(sortedTimelineAssignments, sortedWithSpellID, collapsed)
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
		local text = AddIconBeforeText([[Interface\AddOns\EncounterPlanner\Media\icons8-add-32]], L["Add Assignee"])
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
			InterfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID, nil, preserve)
		end
		Private.mainFrame:DoLayout()
	end
end

do
	local reminderDisabledIconColor = { 0.35, 0.35, 0.35, 1 }
	local reminderDisabledTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-no-reminder-24]]
	local reminderEnabledIconColor = { 1, 0.82, 0, 1 }
	local reminderEnabledTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-reminder-24]]

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

	local GetInstanceBossOrder = bossUtilities.GetInstanceBossOrder

	-- Clears and repopulates the plan dropdown, selecting the last open plan and setting reminder enabled check box value.
	function InterfaceUpdater.RepopulatePlanWidgets()
		if Private.mainFrame then
			local lastOpenPlan = AddOn.db.profile.lastOpenPlan
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				planDropdown:Clear()
				local instanceDropdownData = utilities.GetOrCreateInstanceDropdownItems()
				local plans = AddOn.db.profile.plans
				for _, dropdownData in pairs(instanceDropdownData) do
					if not dropdownData.neverHasChildren then
						dropdownData.dropdownItemMenuData = {}
						dropdownData.itemMenuClickable = true
					end
				end
				for planName, plan in pairs(plans) do
					local instanceID = plan.instanceID
					local customTexture = plan.remindersEnabled and reminderEnabledTexture or reminderDisabledTexture
					local color = plan.remindersEnabled and reminderEnabledIconColor or reminderDisabledIconColor
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
							local text
							if boss then
								text = format("|T%s:16|t %s", boss.icon, planName)
							else
								text = planName
							end
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
					local dungeonInstanceID
					if type(dropdownData.itemValue) == "table" then
						dungeonInstanceID = dropdownData.itemValue.dungeonInstanceID
					else
						dungeonInstanceID = dropdownData.itemValue
					end
					local instanceBossOrder = GetInstanceBossOrder(dungeonInstanceID)
					if instanceBossOrder then
						---@param a DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}
						---@param b DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}
						---@return boolean
						local function sortPlans(a, b)
							local aOrder, bOrder = nil, nil
							if a.mapChallengeModeID then
								aOrder = instanceBossOrder[a.mapChallengeModeID][a.dungeonEncounterID]
							else
								aOrder = instanceBossOrder[a.dungeonEncounterID]
							end
							if b.mapChallengeModeID then
								bOrder = instanceBossOrder[b.mapChallengeModeID][b.dungeonEncounterID]
							else
								bOrder = instanceBossOrder[b.dungeonEncounterID]
							end
							if aOrder and bOrder then
								if aOrder ~= bOrder then
									return aOrder < bOrder
								end
							end
							return a.text < b.text
						end
						sort(dropdownData.dropdownItemMenuData, sortPlans)
					end
				end
				planDropdown:AddItems(instanceDropdownData, "EPDropdownItemToggle")
				planDropdown:SetValue(lastOpenPlan)
			end
			InterfaceUpdater.UpdatePlanCheckBoxes(AddOn.db.profile.plans[lastOpenPlan])
		end
	end

	local CreatePlanSorter = utilities.CreatePlanSorter

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
					local customTexture = enabled and reminderEnabledTexture or reminderDisabledTexture
					local color = enabled and reminderEnabledIconColor or reminderDisabledIconColor
					local text
					local boss = GetBoss(plan.dungeonEncounterID)
					if boss then
						text = format("|T%s:16|t %s", boss.icon, plan.name)
					else
						text = plan.name
					end
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
				local customTexture = enabled and reminderEnabledTexture or reminderDisabledTexture
				local color = enabled and reminderEnabledIconColor or reminderDisabledIconColor
				for _, itemData in pairs(items) do
					itemData.item:SetCustomTexture(customTexture, color, false)
				end
			end
		end
	end
end

do
	local InCombatLockdown = InCombatLockdown
	local messageBox = nil ---@type  EPMessageBox|nil
	local messageQueue = {} ---@type table<integer, MessageBoxData>
	local isExecutingCallbacks = false

	local function Enqueue(messageBoxData)
		tinsert(messageQueue, messageBoxData)
	end

	---@return MessageBoxData|nil
	local function Dequeue()
		if #messageQueue > 0 then
			return tremove(messageQueue, 1)
		end
	end

	---@param onlyNonCommunication boolean
	local function ClearQueue(onlyNonCommunication)
		local newQueue = {}
		for _, messageBoxData in ipairs(messageQueue) do
			if onlyNonCommunication and messageBoxData.isCommunication then
				tinsert(newQueue, messageBoxData)
			end
		end
		messageQueue = newQueue
	end

	local function ProcessMessageQueue()
		Private:UnregisterEvent("PLAYER_REGEN_ENABLED")
		if not messageBox and #messageQueue > 0 then
			local messageBoxData = Dequeue()
			if messageBoxData then
				InterfaceUpdater.CreateMessageBox(messageBoxData, false)
			end
		end
	end

	---@param callback fun()
	local function ExecuteCallback(callback)
		if callback then
			isExecutingCallbacks = true
			callback()
			isExecutingCallbacks = false
		end
	end

	local function HandleMessageBoxReleased()
		messageBox = nil
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
			if not messageBox then
				messageBox = AceGUI:Create("EPMessageBox")
				messageBox.frame:SetParent(UIParent)
				messageBox.frame:SetFrameLevel(kMessageBoxFrameLevel)
				messageBox:SetTitle(messageBoxData.title)
				messageBox:SetText(messageBoxData.message)
				messageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				messageBox:SetPoint("TOP", UIParent, "TOP", 0, -messageBox.frame:GetBottom())
				messageBox:SetAcceptButtonText(messageBoxData.acceptButtonText)
				messageBox:SetRejectButtonText(messageBoxData.rejectButtonText)
				messageBox:SetCallback("OnRelease", HandleMessageBoxReleased)
				messageBox:SetCallback("Accepted", function()
					AceGUI:Release(messageBox)
					ExecuteCallback(messageBoxData.acceptButtonCallback)
				end)
				messageBox:SetCallback("Rejected", function()
					AceGUI:Release(messageBox)
					if type(messageBoxData.rejectButtonCallback) == "function" then
						ExecuteCallback(messageBoxData.rejectButtonCallback)
					end
				end)
				for _, buttonToAdd in ipairs(messageBoxData.buttonsToAdd) do
					local button = messageBox.buttonContainer.children[buttonToAdd.beforeButtonIndex]
					if button then
						messageBox:AddButton(buttonToAdd.buttonText, button)
						messageBox:SetCallback(buttonToAdd.buttonText .. "Clicked", function()
							AceGUI:Release(messageBox)
							if type(buttonToAdd.callback) == "function" then
								ExecuteCallback(buttonToAdd.callback)
							end
						end)
					else
						error(AddOnName .. ": Invalid button index.")
					end
				end
				messageBox.isCommunicationsMessage = messageBoxData.isCommunication
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

		if not isExecutingCallbacks and messageBox then
			local isCurrentCommunication = messageBox.isCommunicationsMessage
			if not onlyNonCommunication or isCurrentCommunication then
				messageBox:Release()
			end
		end

		if not onlyNonCommunication then
			Private:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end

	---@param messageBoxDataID string
	function InterfaceUpdater.RemoveFromMessageQueue(messageBoxDataID)
		for index, messageBoxData in ipairs(messageQueue) do
			if messageBoxData.ID == messageBoxDataID then
				tremove(messageQueue, index)
				break
			end
		end
	end
end

do
	local messageLog = {} ---@type table<integer, {message: string, severityLevel: integer, indentLevel: integer}>

	---@param message string
	---@param severityLevel SeverityLevel?
	---@param indentLevel IndentLevel?
	function InterfaceUpdater.LogMessage(message, severityLevel, indentLevel)
		tinsert(messageLog, { message = message, severityLevel = severityLevel, indentLevel = indentLevel })
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:AddMessage(message, severityLevel, indentLevel)
		end
	end

	function InterfaceUpdater.ClearMessageLog()
		wipe(messageLog)
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:ClearMessages()
		end
	end

	function InterfaceUpdater.RestoreMessageLog()
		if Private.mainFrame and Private.mainFrame.statusBar then
			Private.mainFrame.statusBar:ClearMessages()
			Private.mainFrame.statusBar:AddMessages(messageLog)
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
	local assignmentMetaTables = {
		CombatLogEventAssignment = Private.classes.CombatLogEventAssignment,
		TimedAssignment = Private.classes.TimedAssignment,
	}
	-- Syncs the Assignment Editor and optionally the timeline with data from the assignment.
	---@param dungeonEncounterID any
	---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
	---@param updateFields boolean If true, updates all fields in the Assignment Editor from the assignment.
	---@param updateTimeline boolean If true, the timeline assignment start time is updated, UpdateTimeline is called, and selected boss abilities are updated.
	---@param updateAssignments boolean If true, UpdateAllAssignments is called, and assignment is scrolled into view.
	---@param difficulty DifficultyType
	function InterfaceUpdater.UpdateFromAssignment(
		dungeonEncounterID,
		assignment,
		updateFields,
		updateTimeline,
		updateAssignments,
		difficulty
	)
		if updateFields and Private.assignmentEditor then
			local previewText = utilities.CreateReminderText(assignment, GetCurrentRoster(), true)
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
				previewText,
				assignmentMetaTables,
				availableCombatLogEventTypes,
				spellSpecificCombatLogEventTypes
			)
		end

		local timeline = Private.mainFrame.timeline
		if timeline then
			if updateAssignments then
				InterfaceUpdater.UpdateAllAssignments(false, dungeonEncounterID)
			end
			if updateTimeline then
				if not updateAssignments then
					for _, timelineAssignment in pairs(timeline:GetAssignments()) do
						if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
							utilities.UpdateTimelineAssignmentStartTime(
								timelineAssignment,
								dungeonEncounterID,
								difficulty
							)
							break
						end
					end
					timeline:UpdateTimeline()
				end
				timeline:ClearSelectedAssignments()
				timeline:ClearSelectedBossAbilities()
				timeline:SelectAssignment(assignment.uniqueID, AssignmentSelectionType.kSelection)
				if assignment.combatLogEventSpellID and assignment.spellCount then
					timeline:SelectBossAbility(
						assignment.combatLogEventSpellID,
						assignment.spellCount,
						BossAbilitySelectionType.kSelection
					)
				end
			end
			if updateAssignments then
				timeline:ScrollAssignmentIntoView(assignment.uniqueID)
			end
		end
	end
end
