---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class InterfaceUpdater
local InterfaceUpdater = Private.interfaceUpdater

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")

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
function InterfaceUpdater.UpdateBossAbilityList(bossName)
	local boss = Private:GetBoss(bossName)
	local bossAbilityContainer = Private.mainFrame:GetBossAbilityContainer()
	local bossDropdown = Private.mainFrame:GetBossDropdown()
	if boss and bossAbilityContainer and bossDropdown then
		local bossIndex = Private:GetBossDefinitionIndex(bossName)
		if bossIndex and bossDropdown:GetValue() ~= bossIndex then
			bossDropdown:SetValue(bossIndex)
		end
		bossAbilityContainer:ReleaseChildren()
		for _, ID in pairs(boss.sortedAbilityIDs) do
			local abilityEntry = AceGUI:Create("EPAbilityEntry")
			abilityEntry:SetFullWidth(true)
			abilityEntry:SetAbility(ID)
			bossAbilityContainer:AddChild(abilityEntry)
		end
		bossAbilityContainer:DoLayout()
	end
end

-- Sets the boss abilities for the timeline and rerenders it.
---@param bossName string The name of the boss
function InterfaceUpdater.UpdateTimelineBossAbilities(bossName)
	local boss = Private:GetBoss(bossName)
	local timeline = Private.mainFrame:GetTimeline()
	if boss and timeline then
		timeline:SetBossAbilities(boss.abilities, boss.sortedAbilityIDs, boss.phases)
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
function InterfaceUpdater.UpdateAllAssignments(updateAddAssigneeDropdown)
	local sorted =
		utilities.SortAssignments(GetCurrentAssignments(), GetCurrentRoster(), AddOn.db.profile.assignmentSortType)
	local sortedAssignees = utilities.SortAssignees(sorted)
	InterfaceUpdater.UpdateAssignmentList(sortedAssignees)
	InterfaceUpdater.UpdateTimelineAssignments(sorted, sortedAssignees)
	if updateAddAssigneeDropdown then
		InterfaceUpdater.UpdateAddAssigneeDropdown()
	end
end
