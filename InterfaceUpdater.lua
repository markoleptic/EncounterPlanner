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

-- Updates the list of boss abilities and the boss ability timeline.
function InterfaceUpdater.UpdateBoss(bossName, updateBossAbilitySelectDropdown)
	InterfaceUpdater.UpdateBossAbilityList(bossName, updateBossAbilitySelectDropdown)
	InterfaceUpdater.UpdateTimelineBossAbilities(bossName)
end

-- Clears and repopulates the list of assignments and spells.
---@param sortedAssigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
function InterfaceUpdater.UpdateAssignmentList(sortedAssigneesAndSpells)
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		local assignmentContainer = timeline:GetAssignmentContainer()
		if assignmentContainer then
			assignmentContainer:ReleaseChildren()
			local map = utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, GetCurrentRoster())
			for _, textTable in ipairs(map) do
				local assigneeEntry = AceGUI:Create("EPAbilityEntry")
				assigneeEntry:SetText(textTable.text, textTable.assigneeNameOrRole)
				assigneeEntry:SetFullWidth(true)
				assigneeEntry:SetHeight(30)
				assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-x-64]])
				assigneeEntry:SetCallback("OnValueChanged", HandleDeleteAssigneeRowClicked)
				assigneeEntry.label.text:SetJustifyH("LEFT")
				assigneeEntry.label.text:SetPoint("RIGHT", assigneeEntry.label.frame, "RIGHT", -2, 0)
				assignmentContainer:AddChild(assigneeEntry)
				for _, spellID in ipairs(textTable.spells) do
					local spellEntry = AceGUI:Create("EPAbilityEntry")
					local key = { assigneeNameOrRole = textTable.assigneeNameOrRole, spellID = spellID }
					if spellID == 0 then
						spellEntry:SetNullAbility(key)
					else
						spellEntry:SetAbility(spellID, key)
					end
					spellEntry:SetFullWidth(true)
					spellEntry:SetLeftIndent(15)
					spellEntry:SetHeight(30)
					spellEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-x-64]])
					spellEntry:SetCallback("OnValueChanged", HandleDeleteAssigneeRowClicked)
					spellEntry.label.text:SetJustifyH("LEFT")
					spellEntry.label.text:SetPoint("RIGHT", assigneeEntry.label.frame, "RIGHT", -2, 0)
					assignmentContainer:AddChild(spellEntry)
				end
			end
		end
		Private.mainFrame:DoLayout()
	end
end

-- Sets the assignments and assignees for the timeline and rerenders it.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> A sorted list of timeline assignments
function InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments)
	local timeline = Private.mainFrame:GetTimeline()
	if timeline then
		local sortedWithSpellID = utilities.SortAssigneesWithSpellID(sortedTimelineAssignments)
		timeline:SetAssignments(sortedTimelineAssignments, sortedWithSpellID)
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
	local sortedTimelineAssignments = utilities.SortAssignments(
		GetCurrentAssignments(),
		GetCurrentRoster(),
		AddOn.db.profile.assignmentSortType,
		boss
	)
	local sortedWithSpellID = utilities.SortAssigneesWithSpellID(sortedTimelineAssignments)
	InterfaceUpdater.UpdateAssignmentList(sortedWithSpellID)
	InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments)
	if updateAddAssigneeDropdown then
		InterfaceUpdater.UpdateAddAssigneeDropdown()
	end
end
