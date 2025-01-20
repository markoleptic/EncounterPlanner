local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants

---@class InterfaceUpdater
local InterfaceUpdater = Private.interfaceUpdater

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local L = Private.L
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local format = format
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellName = C_Spell.GetSpellName
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
	local lastBossDungeonEncounterID = 0

	---@param abilityEntry EPAbilityEntry
	local function HandleBossAbilityAbilityEntryValueChanged(abilityEntry, _)
		local key = tonumber(abilityEntry:GetKey())
		local boss = bossUtilities.GetBoss(Private.mainFrame.bossSelectDropdown:GetValue())
		if key and boss then
			local bossDungeonEncounterID = boss.dungeonEncounterID
			local atLeastOneSelected = false
			for currentAbilityID, currentSelected in pairs(AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID]) do
				if currentAbilityID ~= key and currentSelected then
					atLeastOneSelected = true
					break
				end
			end
			if atLeastOneSelected then
				AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID][key] = false
				InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			end
		end
	end

	-- Clears and repopulates the boss ability container based on the boss name.
	---@param boss Boss
	---@param timeline EPTimeline
	---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
	local function UpdateBossAbilityList(boss, timeline, updateBossAbilitySelectDropdown)
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossDropdown = Private.mainFrame.bossSelectDropdown
		if bossAbilityContainer and bossDropdown then
			if AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID] = {}
			end
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]
			bossDropdown:SetValue(boss.dungeonEncounterID)
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
					abilityEntry:SetCallback("OnValueChanged", HandleBossAbilityAbilityEntryValueChanged)
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
		local bossPhaseTable = bossUtilities.GetOrderedBossPhases(boss.dungeonEncounterID)
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
			bossUtilities.ResetBossPhaseTimings(lastBossDungeonEncounterID)
		end
		lastBossDungeonEncounterID = bossDungeonEncounterID
		local boss = bossUtilities.GetBoss(bossDungeonEncounterID)
		if boss then
			local customPhaseDurations = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseDurations
			for phaseIndex, phaseDuration in pairs(customPhaseDurations) do
				if boss.phases[phaseIndex] then
					boss.phases[phaseIndex].duration = phaseDuration
				end
			end
			bossUtilities.GenerateBossTables(boss)
			local timeline = Private.mainFrame.timeline
			if timeline then
				UpdateBossAbilityList(boss, timeline, updateBossAbilitySelectDropdown)
				UpdateTimelineBossAbilities(boss, timeline)
			end
		end
	end
end

do
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
		if key then
			local assignments = GetCurrentAssignments()
			if type(key) == "string" then
				for i = #assignments, 1, -1 do
					if assignments[i].assigneeNameOrRole == key then
						tremove(assignments, i)
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
					end
				end
			end
			local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
			if bossDungeonEncounterID then
				InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
		end
	end

	---@param abilityEntry EPAbilityEntry
	---@param collapsed boolean
	local function HandleCollapseButtonClicked(abilityEntry, _, collapsed)
		AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed[abilityEntry:GetKey()] = collapsed
		local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
		if bossDungeonEncounterID then
			InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
		end
	end

	---@param abilityEntry EPAbilityEntry
	local function HandleSwapButtonClicked(abilityEntry)
		local assigneeDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster())
		abilityEntry:SetAssigneeDropdownItems(assigneeDropdownItems)
	end

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
			local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
			if bossDungeonEncounterID then
				InterfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
			if Private.assignmentEditor then
				local assignmentEditor = Private.assignmentEditor
				local assignmentID = assignmentEditor:GetAssignmentID()
				if assignmentID then
					local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
					if assignment then
						local previewText = utilities.CreateReminderProgressBarText(assignment, GetCurrentRoster())
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
				local map = utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
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
							if spellID == constants.kInvalidAssignmentSpellID then
								spellEntry:SetNullAbility(key)
							elseif spellID == constants.kTextAssignmentSpellID then
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
			sortedWithSpellID = utilities.SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
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
			utilities.CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster()),
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
	local sortedTimelineAssignments = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.preferences.assignmentSortType,
		bossDungeonEncounterID
	)
	local sortedWithSpellID = utilities.SortAssigneesWithSpellID(
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

-- Clears and repopulates the plan dropdown, selecting the last open plan and setting reminder enabled check box value.
function InterfaceUpdater.UpdatePlanDropdown()
	if Private.mainFrame then
		local lastOpenPlan = AddOn.db.profile.lastOpenPlan
		local planDropdown = Private.mainFrame.planDropdown
		if planDropdown then
			planDropdown:Clear()
			local planDropdownData = {}
			for planName, _ in pairs(AddOn.db.profile.plans) do
				tinsert(planDropdownData, { itemValue = planName, text = planName })
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
			if not item then
				planDropdown:AddItem(planName, planName, "EPDropdownItemToggle")
				planDropdown:Sort()
			end
			if select then
				planDropdown:SetValue(planName)
				local planReminderEnableCheckBox = Private.mainFrame.planReminderEnableCheckBox
				if planReminderEnableCheckBox then
					local enabled = AddOn.db.profile.plans[planName].remindersEnabled
					planReminderEnableCheckBox:SetChecked(enabled)
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
		messageBox.frame:SetFrameLevel(110)
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
