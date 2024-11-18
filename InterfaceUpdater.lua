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
local GetSpellInfo = C_Spell.GetSpellInfo
local tinsert = tinsert

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

-- Clears and repopulates the boss ability container based on the boss name.
---@param bossName string The name of the boss
---@param updateBossAbilitySelectDropdown boolean? Whether to update the boss ability select dropdown
function InterfaceUpdater.UpdateBossAbilityList(bossName, updateBossAbilitySelectDropdown)
	if updateBossAbilitySelectDropdown == nil then
		updateBossAbilitySelectDropdown = true
	end
	local boss = bossUtilities.GetBoss(bossName)
	local bossAbilityContainer = Private.mainFrame:GetBossAbilityContainer()
	local bossDropdown = Private.mainFrame:GetBossSelectDropdown()
	local bossAbilitySelectDropdown = Private.mainFrame:GetBossAbilitySelectDropdown()
	if boss and bossAbilityContainer and bossDropdown and bossAbilitySelectDropdown then
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
		for _, ID in pairs(boss.sortedAbilityIDs) do
			if activeBossAbilities[ID] == nil then
				activeBossAbilities[ID] = true
			end
			if activeBossAbilities[ID] == true then
				local abilityEntry = AceGUI:Create("EPAbilityEntry")
				abilityEntry:SetFullWidth(true)
				abilityEntry:SetAbility(ID)
				abilityEntry:SetCallback("OnValueChanged", function(_, _, checked)
					AddOn.db.profile.activeBossAbilities[bossName][ID] = checked
					InterfaceUpdater.UpdateBossAbilityList(bossName, true)
					InterfaceUpdater.UpdateTimelineBossAbilities(bossName)
				end)
				bossAbilityContainer:AddChild(abilityEntry)
			end
			if updateBossAbilitySelectDropdown then
				local spellInfo = GetSpellInfo(ID)
				if spellInfo then
					local iconText = format("|T%s:16|t %s", spellInfo.iconID, spellInfo.name)
					tinsert(bossAbilitySelectItems, { itemValue = ID, text = iconText, dropdownItemMenuData = {} })
				end
			end
		end
		bossAbilityContainer:DoLayout()
		if updateBossAbilitySelectDropdown then
			bossAbilitySelectDropdown:AddItems(bossAbilitySelectItems, "EPDropdownItemToggle")
			bossAbilitySelectDropdown:SetText("Active Boss Abilities")
			bossAbilitySelectDropdown:SetSelectedItems(activeBossAbilities)
		end
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
	end
end

-- Clears and repopulates the list of assignments based on sortedAssignees
---@param sortedAssignees table<integer, string>
function InterfaceUpdater.UpdateAssignmentList(sortedAssignees)
	local assignmentContainer = Private.mainFrame:GetAssignmentContainer()
	if assignmentContainer then
		assignmentContainer:ReleaseChildren()
		local assignmentTextTable = utilities.GetAssignmentListTextFromAssignees(sortedAssignees, GetCurrentRoster())
		for _, text in ipairs(assignmentTextTable) do
			local assigneeEntry = AceGUI:Create("EPAbilityEntry")
			assigneeEntry:SetText(text)
			assigneeEntry:SetHeight(30)
			assignmentContainer:AddChild(assigneeEntry)
		end
		assignmentContainer:DoLayout()
	end
end

-- Sets the assignments and assignees for the timeline and rerenders it.
---@param sortedTimelineAssignments table<integer, TimelineAssignment>
---@param sortedAssignees table<integer, string>
function InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedAssignees)
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		timeline:SetAssignments(sortedTimelineAssignments, sortedAssignees)
		timeline:UpdateTimeline()
	end
end

-- Updates the dropdown items from the current roster
function InterfaceUpdater.UpdateAddAssigneeDropdown()
	local addAssigneeDropdown = Private.mainFrame:GetAddAssigneeDropdown()
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

---@param updateAddAssigneeDropdown boolean
---@param boss Boss?
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
