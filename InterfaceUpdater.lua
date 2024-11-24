---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class InterfaceUpdater
local InterfaceUpdater = Private.interfaceUpdater

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local format = format
local ipairs = ipairs
local GetSpellInfo = C_Spell.GetSpellInfo
local tinsert = tinsert
local tremove = tremove

---@return table<string, EncounterPlannerDbRosterEntry>
local function GetCurrentRoster()
	return AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	return AddOn.db.profile.notes[AddOn.db.profile.lastOpenNote].assignments
end

---@param abilityEntry EPAbilityEntry
local function HandleDeleteAssigneeRowClicked(abilityEntry, _, _)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end

	local assigneeNameOrRole = abilityEntry:GetKey()
	if assigneeNameOrRole then
		local assignments = GetCurrentAssignments()
		for i = #assignments, 1, -1 do
			if assignments[i].assigneeNameOrRole == assigneeNameOrRole then
				tremove(assignments, i)
			end
		end
		local boss = bossUtilities.GetBossFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
		InterfaceUpdater.UpdateAllAssignments(true, boss)
	end
end

-- Clears and repopulates the boss ability container based on the boss name.
---@param bossName string The name of the boss
---@param updateBossAbilitySelectDropdown boolean? Whether to update the boss ability select dropdown
function InterfaceUpdater.UpdateBossAbilityList(bossName, updateBossAbilitySelectDropdown)
	if updateBossAbilitySelectDropdown == nil then
		updateBossAbilitySelectDropdown = true
	end
	local boss = bossUtilities.GetBoss(bossName)
	local timeline = Private.mainFrame:GetTimeline()
	if boss and timeline then
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossDropdown = Private.mainFrame:GetBossSelectDropdown()
		local bossAbilitySelectDropdown = Private.mainFrame:GetBossAbilitySelectDropdown()
		if bossAbilityContainer and bossDropdown and bossAbilitySelectDropdown then
			if AddOn.db.profile.activeBossAbilities[bossName] == nil then
				AddOn.db.profile.activeBossAbilities[bossName] = {}
			end
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[bossName]
			local bossIndex = bossUtilities.GetBossDefinitionIndex(bossName)
			if bossIndex and bossDropdown:GetValue() ~= bossIndex then
				bossDropdown:SetValue(bossIndex)
			end
			bossAbilityContainer:ReleaseChildren()
			if updateBossAbilitySelectDropdown then
				bossAbilitySelectDropdown:Clear()
			end
			local bossAbilitySelectItems = {}
			for _, abilityID in ipairs(boss.sortedAbilityIDs) do
				if activeBossAbilities[abilityID] == nil then
					activeBossAbilities[abilityID] = true
				end
				if activeBossAbilities[abilityID] == true then
					local abilityEntry = AceGUI:Create("EPAbilityEntry")
					abilityEntry:SetFullWidth(true)
					abilityEntry:SetAbility(abilityID)
					abilityEntry:SetCallback("OnValueChanged", function(_, _, checked)
						AddOn.db.profile.activeBossAbilities[bossName][abilityID] = checked
						InterfaceUpdater.UpdateBossAbilityList(bossName, true)
						InterfaceUpdater.UpdateTimelineBossAbilities(bossName)
					end)
					bossAbilityContainer:AddChild(abilityEntry)
				end
				if updateBossAbilitySelectDropdown then
					local spellInfo = GetSpellInfo(abilityID)
					if spellInfo then
						local iconText = format("|T%s:16|t %s", spellInfo.iconID, spellInfo.name)
						tinsert(
							bossAbilitySelectItems,
							{ itemValue = abilityID, text = iconText, dropdownItemMenuData = {} }
						)
					end
				end
			end
			if updateBossAbilitySelectDropdown then
				bossAbilitySelectDropdown:AddItems(bossAbilitySelectItems, "EPDropdownItemToggle")
				bossAbilitySelectDropdown:SetText("Active Boss Abilities")
				bossAbilitySelectDropdown:SetSelectedItems(activeBossAbilities)
			end
		end
		Private.mainFrame:DoLayout()
	end
end

-- Sets the boss abilities for the timeline and rerenders it.
---@param bossName string The name of the boss
function InterfaceUpdater.UpdateTimelineBossAbilities(bossName)
	local boss = bossUtilities.GetBoss(bossName)
	local timeline = Private.mainFrame:GetTimeline()
	if boss and timeline then
		local bossPhaseTable = bossUtilities.CreateBossPhaseTable(boss)
		local activeBossAbilities = AddOn.db.profile.activeBossAbilities[bossName]
		timeline:SetBossAbilities(
			boss.abilities,
			boss.sortedAbilityIDs,
			boss.phases,
			bossPhaseTable,
			activeBossAbilities
		)
		timeline:UpdateTimeline()
		Private.mainFrame:DoLayout()
	end
end

-- Clears and repopulates the list of assignments based on sortedAssignees
---@param sortedAssignees table<integer, string> A sorted list of assignees
function InterfaceUpdater.UpdateAssignmentList(sortedAssignees)
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		local assignmentContainer = timeline:GetAssignmentContainer()
		if assignmentContainer then
			assignmentContainer:ReleaseChildren()
			local assignmentTable, map =
				utilities.GetAssignmentListTextFromAssignees(sortedAssignees, GetCurrentRoster())
			for _, text in ipairs(assignmentTable) do
				local assigneeEntry = AceGUI:Create("EPAbilityEntry")
				assigneeEntry:SetText(text, map[text])
				assigneeEntry:SetFullWidth(true)
				assigneeEntry:SetHeight(30)
				assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-x-64]])
				assigneeEntry:SetCallback("OnValueChanged", HandleDeleteAssigneeRowClicked)
				assignmentContainer:AddChild(assigneeEntry)
			end
		end
		Private.mainFrame:DoLayout()
	end
end

-- Sets the assignments and assignees for the timeline and rerenders it.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> A sorted list of timeline assignments
---@param sortedAssignees table<integer, string> A sorted list of assignees
function InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedAssignees)
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
		Private.mainFrame:DoLayout()
	end
end

-- Clears and repopulates the add assignee dropdown from the current roster.
function InterfaceUpdater.UpdateAddAssigneeDropdown()
	local addAssigneeDropdown = Private.mainFrame:GetTimeline():GetAddAssigneeDropdown()
	if addAssigneeDropdown then
		addAssigneeDropdown:Clear()
		addAssigneeDropdown:SetText("Add Assignee")
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
---@param boss Boss? The boss to pass to the assignment sort function
function InterfaceUpdater.UpdateAllAssignments(updateAddAssigneeDropdown, boss)
	local sorted = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.assignmentSortType,
		boss
	)
	local sortedAssignees = utilities.SortAssignees(sorted)
	InterfaceUpdater.UpdateAssignmentList(sortedAssignees)
	InterfaceUpdater.UpdateTimelineAssignments(sorted, sortedAssignees)
	if updateAddAssigneeDropdown then
		InterfaceUpdater.UpdateAddAssigneeDropdown()
	end
end
