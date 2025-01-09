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
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].assignments
end

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
			InterfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
		end
	end
end

---@param abilityEntry EPAbilityEntry
---@param collapsed boolean
local function HandleCollapseButtonClicked(abilityEntry, _, collapsed)
	AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].collapsed[abilityEntry:GetKey()] = collapsed
	local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
	if bossDungeonEncounterID then
		InterfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
	end
end

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
---@param bossDungeonEncounterID integer
---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
function InterfaceUpdater.UpdateBossAbilityList(bossDungeonEncounterID, updateBossAbilitySelectDropdown)
	local boss = bossUtilities.GetBoss(bossDungeonEncounterID)
	local timeline = Private.mainFrame.timeline
	if boss and timeline then
		local bossAbilityContainer = timeline:GetBossAbilityContainer()
		local bossDropdown = Private.mainFrame.bossSelectDropdown
		if bossAbilityContainer and bossDropdown then
			if AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID] = {}
			end
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID]
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
				local bossAbilitySelectDropdown = Private.mainFrame.bossAbilitySelectDropdown
				if bossAbilitySelectDropdown then
					bossAbilitySelectDropdown:Clear()
					bossAbilitySelectDropdown:AddItems(bossAbilitySelectItems, "EPDropdownItemToggle")
					bossAbilitySelectDropdown:SetText("Active Boss Abilities")
					bossAbilitySelectDropdown:SetSelectedItems(activeBossAbilities)
				end
			end
		end
		Private.mainFrame:DoLayout()
	end
end

-- Sets the boss abilities for the timeline and rerenders it.
---@param bossDungeonEncounterID integer
function InterfaceUpdater.UpdateTimelineBossAbilities(bossDungeonEncounterID)
	local boss = bossUtilities.GetBoss(bossDungeonEncounterID)
	local timeline = Private.mainFrame.timeline
	if boss and timeline then
		local bossPhaseTable = bossUtilities.CreateBossPhaseTable(bossDungeonEncounterID)
		local activeBossAbilities = AddOn.db.profile.activeBossAbilities[bossDungeonEncounterID]
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
---@param bossDungeonEncounterID integer
---@param updateBossAbilitySelectDropdown boolean Whether to update the boss ability select dropdown
function InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, updateBossAbilitySelectDropdown)
	InterfaceUpdater.UpdateBossAbilityList(bossDungeonEncounterID, updateBossAbilitySelectDropdown)
	InterfaceUpdater.UpdateTimelineBossAbilities(bossDungeonEncounterID)
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
			local map = utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, GetCurrentRoster())
			for _, textTable in ipairs(map) do
				local assigneeNameOrRole = textTable.assigneeNameOrRole
				local coloredAssigneeNameOrRole = textTable.text
				local assigneeEntry = AceGUI:Create("EPAbilityEntry")
				assigneeEntry:SetText(coloredAssigneeNameOrRole, assigneeNameOrRole)
				assigneeEntry:SetFullWidth(true)
				assigneeEntry:SetHeight(30)
				assigneeEntry:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
				assigneeEntry:SetCallback("OnValueChanged", function(widget, _)
					local messageBox = InterfaceUpdater.CreateMessageBox(
						"Delete Assignments Confirmation",
						format("Are you sure you want to delete all assignments for %s?", coloredAssigneeNameOrRole)
					)
					if messageBox then
						messageBox:SetCallback("Accepted", function()
							if Private.mainFrame then
								HandleDeleteAssigneeRowClicked(widget)
							end
						end)
					end
				end)
				assigneeEntry.label.text:SetJustifyH("LEFT")
				assigneeEntry.label.text:SetPoint("RIGHT", assigneeEntry.label.frame, "RIGHT", -2, 0)
				assigneeEntry:SetCollapsible(true)
				assigneeEntry:SetCallback("CollapseButtonToggled", HandleCollapseButtonClicked)
				tinsert(children, assigneeEntry)
				local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].collapsed[assigneeNameOrRole]
				assigneeEntry:SetCollapsed(collapsed)
				if not collapsed then
					for _, spellID in ipairs(textTable.spells) do
						local spellEntry = AceGUI:Create("EPAbilityEntry")
						local key = { assigneeNameOrRole = assigneeNameOrRole, spellID = spellID }
						if spellID == 0 then
							spellEntry:SetNullAbility(key)
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
								"Delete Assignments Confirmation",
								format(
									"Are you sure you want to delete all %s assignments for %s?",
									spellName,
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
						spellEntry.label.text:SetJustifyH("LEFT")
						spellEntry.label.text:SetPoint("RIGHT", spellEntry.label.frame, "RIGHT", -2, 0)
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

-- Sets the assignments and assignees for the timeline and rerenders it.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> A sorted list of timeline assignments
---@param sortedWithSpellID table<integer, { assigneeNameOrRole: string, spellID: number|nil }>|nil
---@param firstUpdate boolean|nil
function InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedWithSpellID, firstUpdate)
	local timeline = Private.mainFrame.timeline
	if timeline then
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].collapsed
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
		AddOn.db.profile.plans[AddOn.db.profile.lastOpenNote].collapsed
	)
	InterfaceUpdater.UpdateAssignmentList(sortedWithSpellID, firstUpdate)
	InterfaceUpdater.UpdateTimelineAssignments(sortedTimelineAssignments, sortedWithSpellID, firstUpdate)
	if updateAddAssigneeDropdown then
		InterfaceUpdater.UpdateAddAssigneeDropdown()
	end
end

---@param noteName string
function InterfaceUpdater.UpdateFromNote(noteName)
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.mainFrame then
		local plan = AddOn.db.profile.plans[noteName] --[[@as Plan]]
		local bossDungeonEncounterID = plan.dungeonEncounterID
		if bossDungeonEncounterID then
			InterfaceUpdater.UpdateBoss(bossDungeonEncounterID, true)
			InterfaceUpdater.UpdateAllAssignments(true, bossDungeonEncounterID)
		end
		local renameNoteLineEdit = Private.mainFrame.noteLineEdit
		if renameNoteLineEdit then
			renameNoteLineEdit:SetText(noteName)
		end
		Private.mainFrame.planReminderEnableCheckBox:SetChecked(plan.remindersEnabled)
		Private.mainFrame:DoLayout()
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
