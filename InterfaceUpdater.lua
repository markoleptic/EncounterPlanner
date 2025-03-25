local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class Constants
local constants = Private.constants
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
local SortAssigneesWithSpellID = utilities.SortAssigneesWithSpellID
local SortAssignments = utilities.SortAssignments

local AceGUI = LibStub("AceGUI-3.0")
local format = format
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local tremove = tremove
local type = type
local wipe = wipe

---@return table<string, RosterEntry>
local function GetCurrentRoster()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].assignments
end

---@return Plan
local function GetCurrentPlan()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
end

do
	local CreateAbilityDropdownItemData = utilities.CreateAbilityDropdownItemData
	local GenerateBossTables = bossUtilities.GenerateBossTables
	local GetBoss = bossUtilities.GetBoss
	local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases
	local ResetBossPhaseCounts = bossUtilities.ResetBossPhaseCounts
	local ResetBossPhaseTimings = bossUtilities.ResetBossPhaseTimings
	local SetPhaseCounts = bossUtilities.SetPhaseCounts
	local SetPhaseDurations = bossUtilities.SetPhaseDurations

	local instanceAndBossPadding = 4
	local kMaxBossDuration = constants.kMaxBossDuration
	local lastBossDungeonEncounterID = 0
	local deathIcon = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]]
	local tankIcon = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":14:14:0:0:64:64:0:19:22:41|t"

	-- Clears and repopulates the boss ability container based on the boss name.
	---@param boss Boss
	---@param timeline EPTimeline
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	local function UpdateBossAbilityList(boss, timeline, updateBossAbilitySelectDropdown)
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossLabel = Private.mainFrame.bossLabel
		local instanceLabel = Private.mainFrame.instanceLabel
		if bossAbilityContainer and bossLabel and instanceLabel then
			if AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] = {}
			end
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]
			local dungeonInstance = Private.dungeonInstances[boss.instanceID]

			instanceLabel:SetText(dungeonInstance.name, instanceAndBossPadding, dungeonInstance.instanceID)
			instanceLabel:SetIcon(dungeonInstance.icon, 0, 2, 0, 0, 2)
			instanceLabel:SetFrameWidthFromText()

			bossLabel:SetText(boss.name, instanceAndBossPadding, boss.dungeonEncounterID)
			bossLabel:SetIcon(boss.icon, 0, 2, 0, 0, 2)
			bossLabel:SetFrameWidthFromText()

			Private.mainFrame:UpdateHorizontalResizeBounds()

			bossAbilityContainer:ReleaseChildren()
			local children = {}
			local bossAbilitySelectItems = {}
			for _, abilityID in ipairs(boss.sortedAbilityIDs) do
				if activeBossAbilities[abilityID] == nil then
					activeBossAbilities[abilityID] = not boss.abilities[abilityID].defaultHidden
				end
				local placeholderName, bossDeathName, context = nil, nil, nil
				if Private:HasPlaceholderBossSpellID(abilityID) then
					placeholderName = Private:GetPlaceholderBossName(abilityID)
					if boss.abilities[abilityID].onlyRelevantForTanks then
						placeholderName = placeholderName .. " " .. tankIcon
					end
				end
				if boss.hasBossDeath and boss.abilities[abilityID].bossNpcID then
					local bossNpcID = boss.abilities[abilityID].bossNpcID
					bossDeathName = boss.bossNames[bossNpcID] .. " " .. L["Death"]
				end

				if boss.abilities[abilityID].additionalContext then
					context = format("(%s)", boss.abilities[abilityID].additionalContext)
				end

				if activeBossAbilities[abilityID] == true then
					local abilityEntry = AceGUI:Create("EPAbilityEntry")
					abilityEntry:SetFullWidth(true)
					if placeholderName then
						if context then
							placeholderName = format("%s (%s)", placeholderName, context)
						end
						abilityEntry:SetNullAbility(tostring(abilityID), placeholderName)
					elseif bossDeathName then
						if context then
							bossDeathName = format("%s (%s)", bossDeathName, context)
						end
						abilityEntry:SetText(bossDeathName, tostring(abilityID))
						abilityEntry.label:SetText(bossDeathName, 4)
						abilityEntry.label:SetIcon(deathIcon, 2, 2, 0)
					else
						if boss.abilities[abilityID].onlyRelevantForTanks then
							if context then
								tankIcon = tankIcon .. " " .. context
							end
							abilityEntry:SetAbility(abilityID, tostring(abilityID), tankIcon)
						else
							abilityEntry:SetAbility(abilityID, tostring(abilityID), context)
						end
					end
					abilityEntry:HideCheckBox()
					tinsert(children, abilityEntry)
				end
				if updateBossAbilitySelectDropdown then
					tinsert(bossAbilitySelectItems, CreateAbilityDropdownItemData(boss, abilityID))
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

	-- Sets the boss abilities for the timeline and rerenders it.
	---@param boss Boss
	---@param timeline EPTimeline
	local function UpdateTimelineBossAbilities(boss, timeline)
		local bossPhaseTable = GetOrderedBossPhases(boss.dungeonEncounterID)
		if bossPhaseTable then
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]
			timeline:SetBossAbilities(
				boss.abilityInstances,
				boss.sortedAbilityIDs,
				boss.phases,
				bossPhaseTable,
				activeBossAbilities
			)
			timeline:UpdateTimeline()
			Private.mainFrame:DoLayout()
		end
	end

	-- Updates the list of boss abilities and the boss ability timeline.
	---@param bossDungeonEncounterID integer
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	function InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, updateBossAbilitySelectDropdown)
		if lastBossDungeonEncounterID ~= 0 then
			ResetBossPhaseTimings(lastBossDungeonEncounterID)
			ResetBossPhaseCounts(lastBossDungeonEncounterID)
		end
		lastBossDungeonEncounterID = bossDungeonEncounterID
		local boss = GetBoss(bossDungeonEncounterID)
		if boss then
			local customPhaseDurations = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseDurations
			SetPhaseDurations(bossDungeonEncounterID, customPhaseDurations)
			local customPhaseCounts = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseCounts
			customPhaseCounts = SetPhaseCounts(bossDungeonEncounterID, customPhaseCounts, kMaxBossDuration)
			GenerateBossTables(boss)
			local timeline = Private.mainFrame.timeline
			if timeline then
				UpdateBossAbilityList(boss, timeline, updateBossAbilitySelectDropdown)
				UpdateTimelineBossAbilities(boss, timeline)
			end
		end
	end
end

do
	local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID

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
			local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
			if bossDungeonEncounterID then
				InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
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

	local CreateReminderText = utilities.CreateReminderText
	local FindBossAbility = bossUtilities.FindBossAbility
	local GetAvailableCombatLogEventTypes = bossUtilities.GetAvailableCombatLogEventTypes

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapAssignee(abilityEntry, _, newAssignee)
		local key = abilityEntry:GetKey()
		if key then
			local plan = GetCurrentPlan()
			local assignments = GetCurrentAssignments()
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
			local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
			if bossDungeonEncounterID then
				InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
			if Private.assignmentEditor then
				local assignmentEditor = Private.assignmentEditor
				local assignmentID = assignmentEditor:GetAssignmentID()
				if assignmentID then
					local assignment = FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
					if assignment then
						local previewText = CreateReminderText(assignment, GetCurrentRoster(), true)
						local availableCombatLogEventTypes = GetAvailableCombatLogEventTypes(bossDungeonEncounterID)
						local spellSpecificCombatLogEventTypes = nil
						local combatLogEventSpellID = assignment.combatLogEventSpellID
						if combatLogEventSpellID then
							local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
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

	local GetSpellName = C_Spell.GetSpellName

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

	local CreateAssignmentListTable = utilities.CreateAssignmentListTable
	local GetSpecializationInfoByID = GetSpecializationInfoByID

	-- Clears and repopulates the list of assignments and spells.
	---@param sortedAssigneesAndSpells table<integer, {assignee:string, spellID:number|nil}>
	---@param firstUpdate boolean|nil
	function InterfaceUpdater.UpdateAssignmentList(sortedAssigneesAndSpells, firstUpdate)
		local timeline = Private.mainFrame.timeline
		if timeline then
			local assignmentContainer = timeline:GetAssignmentContainer()
			if assignmentContainer then
				assignmentContainer:ReleaseChildren()
				local children = {}
				local roster = GetCurrentRoster()
				local map = CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
				local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
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
					assigneeEntry:SetText(coloredAssignee, assignee)
					assigneeEntry:SetFullWidth(true)
					assigneeEntry:SetHeight(30)
					assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
					assigneeEntry:SetRoleOrSpec(roster[assignee] and roster[assignee].role or specIconID or nil)
					assigneeEntry:SetCollapsible(true)
					assigneeEntry:ShowSwapIcon(true)
					assigneeEntry:SetCollapsed(assigneeCollapsed)
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
							spellEntry:SetLeftIndent(15 - 2)
							spellEntry:SetHeight(30)
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
end

-- Sets the assignments and assignees for the timeline and rerenders it.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> A sorted list of timeline assignments
---@param sortedWithSpellID table<integer, { assignee: string, spellID: number|nil }>|nil
---@param firstUpdate boolean|nil
function InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedWithSpellID, firstUpdate)
	local timeline = Private.mainFrame.timeline
	if timeline then
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		if not sortedWithSpellID then
			sortedWithSpellID = SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
		end
		timeline:SetAssignments(sortedTimelineAssignments, sortedWithSpellID, collapsed)
		if not firstUpdate then
			timeline:UpdateTimeline()
			Private.mainFrame:DoLayout()
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

-- Sorts assignments & assignees, updates the assignment list, timeline assignments, and optionally the add assignee
-- dropdown.
---@param updateAddAssigneeDropdown boolean Whether or not to update the add assignee dropdown
---@param bossDungeonEncounterID integer
---@param firstUpdate boolean|nil
---@param preserve boolean|nil Whether or not to preserve the current message log.
function InterfaceUpdater.UpdateAllAssignments(updateAddAssigneeDropdown, bossDungeonEncounterID, firstUpdate, preserve)
	local sortedTimelineAssignments = SortAssignments(
		GetCurrentPlan(),
		AddOn.db.profile.preferences.assignmentSortType,
		bossDungeonEncounterID,
		preserve
	)
	local sortedWithSpellID = SortAssigneesWithSpellID(
		sortedTimelineAssignments,
		AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
	)
	InterfaceUpdater.UpdateAssignmentList(sortedWithSpellID, firstUpdate)
	InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedWithSpellID, firstUpdate)
	if updateAddAssigneeDropdown then
		InterfaceUpdater.UpdateAddAssigneeDropdown()
	end
	local timeline = Private.mainFrame.timeline
	if timeline then -- Sometimes items in this container are invisible for unknown reasons..
		timeline.assignmentTimeline.listContainer:DoLayout()
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
			local preferences = AddOn.db.profile.preferences --[[@as Preferences]]
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

	local sort = table.sort

	-- Clears and repopulates the plan dropdown, selecting the last open plan and setting reminder enabled check box value.
	function InterfaceUpdater.RepopulatePlanWidgets()
		if Private.mainFrame then
			local lastOpenPlan = AddOn.db.profile.lastOpenPlan
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				planDropdown:Clear()
				local instanceDropdownData = utilities.GetOrCreateInstanceDropdownItems()
				local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
				for _, dropdownData in pairs(instanceDropdownData) do
					dropdownData.dropdownItemMenuData = {}
				end
				for planName, plan in pairs(plans) do
					local instanceID = plan.instanceID
					local customTexture = plan.remindersEnabled and reminderEnabledTexture or reminderDisabledTexture
					local color = plan.remindersEnabled and reminderEnabledIconColor or reminderDisabledIconColor
					for _, dropdownData in pairs(instanceDropdownData) do
						if dropdownData.itemValue == instanceID then
							local text
							local boss = bossUtilities.GetBoss(plan.dungeonEncounterID)
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
							})
							break
						end
					end
				end
				for _, dropdownData in pairs(instanceDropdownData) do
					sort(dropdownData.dropdownItemMenuData, function(a, b)
						return a.text < b.text
					end)
				end
				planDropdown:AddItems(instanceDropdownData, "EPDropdownItemToggle")
				planDropdown:SetValue(lastOpenPlan)
			end
			InterfaceUpdater.UpdatePlanCheckBoxes(AddOn.db.profile.plans[lastOpenPlan])
		end
	end

	-- Adds a new plan name to the plan dropdown and optionally selects it and updates the reminder enabled check box.
	---@param plan Plan
	---@param select boolean
	function InterfaceUpdater.AddPlanToDropdown(plan, select)
		if Private.mainFrame then
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				local item, _ = planDropdown:FindItemAndText(plan.name)
				local enabled = plan.remindersEnabled
				if not item then
					local customTexture = enabled and reminderEnabledTexture or reminderDisabledTexture
					local color = enabled and reminderEnabledIconColor or reminderDisabledIconColor
					local text
					local boss = bossUtilities.GetBoss(plan.dungeonEncounterID)
					if boss then
						text = format("|T%s:16|t %s", boss.icon, plan.name)
					else
						text = plan.name
					end
					planDropdown:AddItemsToExistingDropdownItemMenu(plan.instanceID, {
						{
							itemValue = plan.name,
							text = text,
							customTexture = customTexture,
							customTextureVertexColor = color,
						},
					})
					planDropdown:Sort(plan.instanceID)
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
				local item, _ = planDropdown:FindItemAndText(planName)
				if item then
					local customTexture = enabled and reminderEnabledTexture or reminderDisabledTexture
					local color = enabled and reminderEnabledIconColor or reminderDisabledIconColor
					item:SetCustomTexture(customTexture, color)
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
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
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
	function InterfaceUpdater.UpdateFromAssignment(
		dungeonEncounterID,
		assignment,
		updateFields,
		updateTimeline,
		updateAssignments
	)
		if updateFields and Private.assignmentEditor then
			local previewText = utilities.CreateReminderText(assignment, GetCurrentRoster(), true)
			local availableCombatLogEventTypes = bossUtilities.GetAvailableCombatLogEventTypes(dungeonEncounterID)
			local spellSpecificCombatLogEventTypes = nil
			local combatLogEventSpellID = assignment.combatLogEventSpellID
			if combatLogEventSpellID then
				local ability = bossUtilities.FindBossAbility(dungeonEncounterID, combatLogEventSpellID)
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
			if updateTimeline then
				for _, timelineAssignment in pairs(timeline:GetAssignments()) do
					if timelineAssignment.assignment.uniqueID == assignment.uniqueID then
						utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, dungeonEncounterID)
						break
					end
				end
				timeline:UpdateTimeline()
				timeline:ClearSelectedAssignments()
				timeline:ClearSelectedBossAbilities()
				timeline:SelectAssignment(assignment.uniqueID, true)
				if assignment.combatLogEventSpellID and assignment.spellCount then
					timeline:SelectBossAbility(assignment.combatLogEventSpellID, assignment.spellCount, true)
				end
			end
			if updateAssignments then
				InterfaceUpdater.UpdateAllAssignments(false, dungeonEncounterID)
				timeline:ScrollAssignmentIntoView(assignment.uniqueID)
			end
		end
	end
end
