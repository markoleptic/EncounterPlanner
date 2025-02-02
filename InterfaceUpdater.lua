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

---@class Utilities
local utilities = Private.utilities
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

---@return table<string, RosterEntry>
local function GetCurrentRoster()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].assignments
end

do
	---@class BossUtilities
	local bossUtilities = Private.bossUtilities
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

	local GetSpellInfo = C_Spell.GetSpellInfo

	-- Clears and repopulates the boss ability container based on the boss name.
	---@param boss Boss
	---@param timeline EPTimeline
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	local function UpdateBossAbilityList(boss, timeline, updateBossAbilitySelectDropdown)
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossLabel = Private.mainFrame.bossLabel
		if bossAbilityContainer and bossLabel then
			if AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] = {}
			end
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]
			local raidInstance = Private.raidInstances[boss.instanceID]

			Private.mainFrame.instanceLabel:SetText(raidInstance.name, instanceAndBossPadding, raidInstance.instanceID)
			Private.mainFrame.instanceLabel:SetIcon(raidInstance.icon, 0, 0, 0, 0, 0)

			bossLabel:SetText(boss.name, instanceAndBossPadding, boss.dungeonEncounterID)
			bossLabel:SetIcon(boss.icon, 0, 0, 0, 0, 0)

			bossAbilityContainer:ReleaseChildren()
			local children = {}
			local bossAbilitySelectItems = {}
			for _, abilityID in ipairs(boss.sortedAbilityIDs) do
				if activeBossAbilities[abilityID] == nil then
					activeBossAbilities[abilityID] = true
				end
				if activeBossAbilities[abilityID] == true then
					local abilityEntry = AceGUI:Create("EPAbilityEntry")
					abilityEntry:SetFullWidth(true)
					abilityEntry:SetAbility(abilityID, tostring(abilityID))
					abilityEntry:HideCheckBox()
					tinsert(children, abilityEntry)
				end
				if updateBossAbilitySelectDropdown then
					local spellInfo = GetSpellInfo(abilityID)
					if spellInfo then
						local iconText = format("|T%s:16|t %s", spellInfo.iconID, spellInfo.name)
						tinsert(bossAbilitySelectItems, { itemValue = abilityID, text = iconText })
					end
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
			SetPhaseDurations(bossDungeonEncounterID, customPhaseDurations, kMaxBossDuration)
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
			local assignments = GetCurrentAssignments()
			if type(key) == "string" then
				for i = #assignments, 1, -1 do
					if assignments[i].assigneeNameOrRole == key then
						tremove(assignments, i)
						removed = removed + 1
					end
				end
			elseif type(key) == "table" then
				local assigneeNameOrRole = key.assigneeNameOrRole
				local spellID = key.spellID
				for i = #assignments, 1, -1 do
					if
						assignments[i].assigneeNameOrRole == assigneeNameOrRole
						and assignments[i].spellInfo.spellID == spellID
					then
						tremove(assignments, i)
						removed = removed + 1
					end
				end
			end
			local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
			if bossDungeonEncounterID then
				InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
			InterfaceUpdater.LogMessage("Removed " .. removed .. " assignments.")
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
	end

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapButtonClicked(abilityEntry)
		local assigneeDropdownItems = CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster())
		abilityEntry:SetAssigneeDropdownItems(assigneeDropdownItems)
	end

	local CreateReminderText = utilities.CreateReminderText

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapAssignee(abilityEntry, _, newAssigneeNameOrRole)
		local key = abilityEntry:GetKey()
		if key then
			local assignments = GetCurrentAssignments()
			if type(key) == "string" then
				for _, assignment in ipairs(assignments) do
					if assignment.assigneeNameOrRole == key then
						assignment.assigneeNameOrRole = newAssigneeNameOrRole
					end
				end
			elseif type(key) == "table" then
				local assigneeNameOrRole = key.assigneeNameOrRole
				local spellID = key.spellID
				for _, assignment in ipairs(assignments) do
					if
						assignment.assigneeNameOrRole == assigneeNameOrRole
						and assignment.spellInfo.spellID == spellID
					then
						assignment.assigneeNameOrRole = newAssigneeNameOrRole
					end
				end
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
						assignmentEditor:PopulateFields(assignment, previewText, assignmentMetaTables)
					else
						assignmentEditor:Release()
					end
				else
					assignmentEditor:Release()
				end
			end
		end
	end

	local CreateAssignmentListTable = utilities.CreateAssignmentListTable
	local GetSpecializationInfoByID = GetSpecializationInfoByID
	local GetSpellName = C_Spell.GetSpellName

	-- Clears and repopulates the list of assignments and spells.
	---@param sortedAssigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
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
					local assigneeNameOrRole = textTable.assigneeNameOrRole
					local coloredAssigneeNameOrRole = textTable.text
					local assigneeCollapsed = collapsed[assigneeNameOrRole]

					local specIconID = nil
					local specMatch = assigneeNameOrRole:match("spec:%s*(%d+)")
					if specMatch then
						local specIDMatch = tonumber(specMatch)
						if specIDMatch then
							local _, _, _, icon, _ = GetSpecializationInfoByID(specIDMatch)
							specIconID = icon
							coloredAssigneeNameOrRole = coloredAssigneeNameOrRole:gsub("|T[^:]+:16|t ", "")
						end
					end

					local assigneeEntry = AceGUI:Create("EPAbilityEntry")
					assigneeEntry:SetText(coloredAssigneeNameOrRole, assigneeNameOrRole)
					assigneeEntry:SetFullWidth(true)
					assigneeEntry:SetHeight(30)
					assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
					assigneeEntry:SetRoleOrSpec(
						roster[assigneeNameOrRole] and roster[assigneeNameOrRole].role or specIconID or nil
					)
					assigneeEntry:SetCollapsible(true)
					assigneeEntry:ShowSwapIcon(true)
					assigneeEntry:SetCollapsed(assigneeCollapsed)
					assigneeEntry:SetCallback("SwapButtonClicked", HandleSwapButtonClicked)
					assigneeEntry:SetCallback("CollapseButtonToggled", HandleCollapseButtonClicked)
					assigneeEntry:SetCallback("AssigneeSwapped", HandleSwapAssignee)
					assigneeEntry:SetCallback("OnValueChanged", function(widget, _)
						local messageBox = InterfaceUpdater.CreateMessageBox(
							L["Delete Assignments Confirmation"],
							format(
								"%s %s %s?",
								L["Are you sure you want to delete all"],
								L["assignments for"],
								coloredAssigneeNameOrRole
							)
						)
						if messageBox then
							messageBox:SetCallback("Accepted", function()
								if Private.mainFrame then
									HandleDeleteAssigneeRowClicked(widget)
								end
							end)
						end
					end)
					tinsert(children, assigneeEntry)

					if not assigneeCollapsed then
						for _, spellID in ipairs(textTable.spells) do
							local spellEntry = AceGUI:Create("EPAbilityEntry")
							local key = { assigneeNameOrRole = assigneeNameOrRole, spellID = spellID }
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
							spellEntry:SetCallback("OnValueChanged", function(widget, _)
								local spellEntryKey = widget:GetKey()
								local spellName = GetSpellName(spellEntryKey.spellID) or "Unknown Spell"
								local messageBox = InterfaceUpdater.CreateMessageBox(
									L["Delete Assignments Confirmation"],
									format(
										"%s %s %s %s?",
										L["Are you sure you want to delete all"],
										spellName,
										L["assignments for"],
										coloredAssigneeNameOrRole
									)
								)
								if messageBox then
									messageBox:SetCallback("Accepted", function()
										if Private.mainFrame then
											HandleDeleteAssigneeRowClicked(widget)
										end
									end)
								end
							end)
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
---@param sortedWithSpellID table<integer, { assigneeNameOrRole: string, spellID: number|nil }>|nil
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
		addAssigneeDropdown:SetText(L["Add Assignee"])
		addAssigneeDropdown:AddItems(
			CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster()),
			"EPDropdownItemToggle",
			true
		)
	end
end

-- Sorts assignments & assignees, updates the assignment list, timeline assignments, and optionally the add assignee
-- dropdown.
---@param updateAddAssigneeDropdown boolean Whether or not to update the add assignee dropdown
---@param bossDungeonEncounterID integer
---@param firstUpdate boolean|nil
function InterfaceUpdater.UpdateAllAssignments(updateAddAssigneeDropdown, bossDungeonEncounterID, firstUpdate)
	local sortedTimelineAssignments = SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.preferences.assignmentSortType,
		bossDungeonEncounterID
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

---@param planName string
function InterfaceUpdater.UpdateFromPlan(planName)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.mainFrame then
		local plan = AddOn.db.profile.plans[planName] --[[@as Plan]]
		local bossDungeonEncounterID = plan.dungeonEncounterID
		if bossDungeonEncounterID then
			InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			InterfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
		end
		Private.mainFrame.planReminderEnableCheckBox:SetChecked(plan.remindersEnabled)
		Private.mainFrame:DoLayout()
	end
end

do
	local reminderDisabledIconColor = { 0.35, 0.35, 0.35, 1 }
	local reminderDisabledTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-no-reminder-24]]
	local reminderEnabledIconColor = { 1, 0.82, 0, 1 }
	local reminderEnabledTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-reminder-24]]

	-- Clears and repopulates the plan dropdown, selecting the last open plan and setting reminder enabled check box value.
	function InterfaceUpdater.UpdatePlanDropdown()
		if Private.mainFrame then
			local lastOpenPlan = AddOn.db.profile.lastOpenPlan
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				planDropdown:Clear()
				local planDropdownData = {}
				for planName, plan in pairs(AddOn.db.profile.plans) do
					tinsert(planDropdownData, {
						itemValue = planName,
						text = planName,
						customTexture = plan.remindersEnabled and reminderEnabledTexture or reminderDisabledTexture,
						customTextureVertexColor = plan.remindersEnabled and reminderEnabledIconColor
							or reminderDisabledIconColor,
					})
				end
				planDropdown:AddItems(planDropdownData, "EPDropdownItemToggle")
				planDropdown:Sort()
				planDropdown:SetValue(lastOpenPlan)
			end
			local planReminderEnableCheckBox = Private.mainFrame.planReminderEnableCheckBox
			if planReminderEnableCheckBox then
				local enabled = AddOn.db.profile.plans[lastOpenPlan].remindersEnabled
				planReminderEnableCheckBox:SetChecked(enabled)
			end
		end
	end

	-- Adds a new plan name to the plan dropdown and optionally selects it and updates the reminder enabled check box.
	---@param planName string
	---@param select boolean
	function InterfaceUpdater.AddPlanToDropdown(planName, select)
		if Private.mainFrame then
			local planDropdown = Private.mainFrame.planDropdown
			if planDropdown then
				local item, _ = planDropdown:FindItemAndText(planName)
				local enabled = AddOn.db.profile.plans[planName].remindersEnabled
				if not item then
					local customTexture = enabled and reminderEnabledTexture or reminderDisabledTexture
					local color = enabled and reminderEnabledIconColor or reminderDisabledIconColor
					planDropdown:AddItem(planName, planName, "EPDropdownItemToggle", nil, false, customTexture, color)
					planDropdown:Sort()
				end
				if select then
					planDropdown:SetValue(planName)
					local planReminderEnableCheckBox = Private.mainFrame.planReminderEnableCheckBox
					if planReminderEnableCheckBox then
						planReminderEnableCheckBox:SetChecked(enabled)
					end
				end
			end
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

	-- Removes a plan name from the plan dropdown.
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

---@param title string
---@param text string
---@return EPMessageBox|nil
function InterfaceUpdater.CreateMessageBox(title, text)
	if not Private.messageBox then
		local messageBox = AceGUI:Create("EPMessageBox")
		messageBox.frame:SetParent(UIParent)
		messageBox.frame:SetFrameLevel(kMessageBoxFrameLevel)
		messageBox:SetTitle(title)
		messageBox:SetText(text)
		messageBox:SetCallback("OnRelease", function()
			Private.messageBox = nil
		end)
		messageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		messageBox:SetPoint("TOP", UIParent, "TOP", 0, -messageBox.frame:GetBottom())
		Private.messageBox = messageBox
		return messageBox
	end
	return nil
end

---@param message string
---@param severityLevel SeverityLevel?
---@param indentLevel IndentLevel?
function InterfaceUpdater.LogMessage(message, severityLevel, indentLevel)
	if Private.mainFrame and Private.mainFrame.statusBar then
		Private.mainFrame.statusBar:AddMessage(message, severityLevel, indentLevel)
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
