local _, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment
---@class PhasedAssignment
local PhasedAssignment = Private.classes.PhasedAssignment

---@class Constants
local constants = Private.constants

---@class Utilities
local utilities = Private.utilities
local ChangePlanBoss = utilities.ChangePlanBoss
local CreateAssigneeDropdownItems = utilities.CreateAssigneeDropdownItems
local CreateAssignmentTypeWithRosterDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems
local CreateUniquePlanName = utilities.CreateUniquePlanName
local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID
local FormatTime = utilities.FormatTime
local ImportGroupIntoRoster = utilities.ImportGroupIntoRoster
local Round = utilities.Round
local SortAssignments = utilities.SortAssignments
local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup
local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local ConvertAbsoluteTimeToCombatLogEventTime = bossUtilities.ConvertAbsoluteTimeToCombatLogEventTime
local ConvertAssignmentsToNewBoss = bossUtilities.ConvertAssignmentsToNewBoss
local GetBoss = bossUtilities.GetBoss
local GetMinimumCombatLogEventTime = bossUtilities.GetMinimumCombatLogEventTime

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater
local AddPlanToDropdown = interfaceUpdater.AddPlanToDropdown
local CreateMessageBox = interfaceUpdater.CreateMessageBox
local UpdateAllAssignments = interfaceUpdater.UpdateAllAssignments
local UpdateBoss = interfaceUpdater.UpdateBoss

local abs = math.abs
local AceGUI = LibStub("AceGUI-3.0")
local Clamp = Clamp
local format = string.format
local getmetatable = getmetatable
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local min, max = math.min, math.max
local pairs = pairs
local sub = string.sub
local tinsert = table.insert
local tonumber = tonumber
local tremove = table.remove
local unpack = unpack
local wipe = table.wipe

local Create = {}
local Handle = {}

local addAssigneeText =
	utilities.AddIconBeforeText([[Interface\AddOns\EncounterPlanner\Media\icons8-add-32]], L["Add Assignee"])
local maxNumberOfRecentItems = 10
local menuButtonHorizontalPadding = 8

do -- Plan Menu Items
	local AddIconBeforeText = utilities.AddIconBeforeText

	local planMenuItems = nil

	---@return table<integer, DropdownItemData>
	function Create.PlanMenuItems()
		if not planMenuItems then
			planMenuItems = {
				{
					itemValue = "New Plan",
					text = AddIconBeforeText([[Interface\AddOns\EncounterPlanner\Media\icons8-add-32]], L["New Plan"]),
				},
				{
					itemValue = "Duplicate Plan",
					text = AddIconBeforeText(
						[[Interface\AddOns\EncounterPlanner\Media\icons8-duplicate-32]],
						L["Duplicate Plan"]
					),
				},
				{
					itemValue = "Import",
					text = AddIconBeforeText([[Interface\AddOns\EncounterPlanner\Media\icons8-import-32]], "Import"),
					dropdownItemMenuData = {
						{
							itemValue = "FromMRT",
							text = L["From"] .. " " .. "MRT",
							dropdownItemMenuData = {
								{
									itemValue = "FromMRTCreateNew",
									text = L["Import As New Plan"],
								},
								{
									itemValue = "FromMRTOverwriteCurrent",
									text = L["Overwrite Current Plan"],
								},
							},
						},
						{
							itemValue = "FromString",
							text = L["From Text"],
						},
					},
				},
				{
					itemValue = "Export Current Plan",
					text = AddIconBeforeText(
						[[Interface\AddOns\EncounterPlanner\Media\icons8-export-32]],
						L["Export Current Plan"]
					),
				},
				{
					itemValue = "Delete Current Plan",
					text = AddIconBeforeText(
						[[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]],
						L["Delete Current Plan"]
					),
				},
			}
		end
		return planMenuItems
	end
end

do -- Boss Menu Items
	local bossMenuItems = nil

	---@return table<integer, DropdownItemData>
	function Create.BossMenuItems()
		if not bossMenuItems then
			bossMenuItems = {
				{
					itemValue = "Change Boss",
					text = L["Change Boss"],
					dropdownItemMenuData = utilities.GetOrCreateBossDropdownItems(),
				},
				{
					itemValue = "Edit Phase Timings",
					text = L["Edit Phase Timings"],
					selectable = false,
				},
				{
					itemValue = "Filter Spells",
					text = L["Filter Spells"],
					dropdownItemMenuData = {
						{
							itemValue = "",
							text = "",
						},
					},
				},
			}
		end
		return bossMenuItems
	end
end

---@return table<string, RosterEntry>
local function GetCurrentRoster()
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	local plan = AddOn.db.profile.plans[lastOpenPlan]
	return plan.roster
end

---@return table<integer, Assignment>
local function GetCurrentAssignments()
	local lastOpenPlan = AddOn.db.profile.lastOpenPlan
	local plan = AddOn.db.profile.plans[lastOpenPlan]
	return plan.assignments
end

---@return Plan
local function GetCurrentPlan()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
end

---@return Boss|nil
local function GetCurrentBoss()
	return GetBoss(Private.mainFrame.bossLabel:GetValue())
end

---@return integer
local function GetCurrentBossDungeonEncounterID()
	return Private.mainFrame.bossLabel:GetValue()
end

local function ClosePlanDependentWidgets()
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.rosterEditor then
		Private.rosterEditor:Release()
	end
	if Private.phaseLengthEditor then
		Private.phaseLengthEditor:Release()
	end
	if Private.externalTextEditor then
		Private.externalTextEditor:Release()
	end
	interfaceUpdater.RemoveMessageBoxes(true)
end

do -- Menu Button
	local autoOpenNextMenuButtonEntered = nil
	local menuButtonToClose = nil
	local menuButtonFontSize = 16

	---@param menuButton EPDropdown
	local function HandleMenuButtonEntered(menuButton)
		if menuButton.open then
			return
		end
		if autoOpenNextMenuButtonEntered and menuButtonToClose then
			menuButtonToClose:Close()
			menuButton:Open()
			menuButtonToClose = menuButton
		end
	end

	---@param menuButton EPDropdown
	local function HandleMenuButtonOpened(menuButton)
		autoOpenNextMenuButtonEntered = true
		menuButtonToClose = menuButton
	end

	local function HandleMenuButtonClosed()
		autoOpenNextMenuButtonEntered = false
		menuButtonToClose = nil
	end

	---@param text string
	---@param height number
	---@return EPDropdown
	function Create.DropdownMenuButton(text, height)
		local menuButton = AceGUI:Create("EPDropdown")
		menuButton:SetTextCentered(true)
		menuButton:SetAutoItemWidth(true)
		menuButton:SetText(text)
		menuButton:SetTextFontSize(menuButtonFontSize)
		menuButton:SetItemTextFontSize(menuButtonFontSize)
		menuButton:SetItemHorizontalPadding(menuButtonHorizontalPadding)
		menuButton:SetWidth(menuButton.text:GetStringWidth() + 2 * menuButtonHorizontalPadding)
		menuButton:SetDropdownItemHeight(height)
		menuButton:SetButtonVisibility(false)
		menuButton:SetShowHighlight(true)
		menuButton:SetCallback("OnEnter", HandleMenuButtonEntered)
		menuButton:SetCallback("OnOpened", HandleMenuButtonOpened)
		menuButton:SetCallback("OnClosed", HandleMenuButtonClosed)
		return menuButton
	end

	local menuButtonBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	}
	local menuButtonBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
	local menuButtonBackdropColor = { 0.1, 0.1, 0.1, 1 }

	---@param text string
	---@param height number
	---@param clickedCallback fun()
	---@return EPButton
	function Create.MenuButton(text, height, clickedCallback)
		local menuButton = AceGUI:Create("EPButton")
		menuButton:SetText(text)
		menuButton:SetFontSize(menuButtonFontSize)
		local width = menuButton.button:GetFontString():GetStringWidth() + 2 * menuButtonHorizontalPadding
		menuButton:SetWidth(width)
		menuButton:SetHeight(height)
		menuButton:SetBackdrop(menuButtonBackdrop, menuButtonBackdropColor, menuButtonBackdropBorderColor)
		menuButton.background:SetPoint("TOPLEFT", 1, -1)
		menuButton.background:SetPoint("BOTTOMRIGHT", -1, 1)
		menuButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
		menuButton:SetCallback("Clicked", clickedCallback)
		return menuButton
	end
end

do -- Roster Editor
	local GetOrCreateClassDropdownItemData = utilities.GetOrCreateClassDropdownItemData
	local kRosterEditorFrameLevel = constants.frameLevels.kRosterEditorFrameLevel

	---@param currentRosterMap table<integer, RosterWidgetMapping>
	---@param sharedRosterMap table<integer, RosterWidgetMapping>
	local function HandleRosterEditingFinished(_, _, currentRosterMap, sharedRosterMap)
		local lastOpenPlan = AddOn.db.profile.lastOpenPlan
		if lastOpenPlan then
			local tempRoster = {}
			for _, rosterWidgetMapping in ipairs(currentRosterMap) do
				if rosterWidgetMapping.name:gsub("%s", ""):len() ~= 0 then
					tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
				end
			end
			AddOn.db.profile.plans[lastOpenPlan].roster = tempRoster
		end

		local tempRoster = {}
		for _, rosterWidgetMapping in ipairs(sharedRosterMap) do
			if rosterWidgetMapping.name:gsub("%s", ""):len() ~= 0 then
				tempRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
			end
		end
		AddOn.db.profile.sharedRoster = tempRoster

		Private.rosterEditor:Release()
		UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
		UpdateRosterDataFromGroup(GetCurrentRoster())
		UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())

		if Private.assignmentEditor then
			local assigneeTypeDropdown = Private.assignmentEditor.assigneeTypeDropdown
			local targetDropdown = Private.assignmentEditor.targetDropdown
			local roster = GetCurrentRoster()

			local assigneeDropdownItems = CreateAssigneeDropdownItems(roster)
			local updatedDropdownItems, enableIndividualItem =
				CreateAssignmentTypeWithRosterDropdownItems(roster, assigneeDropdownItems)

			local previousValue = assigneeTypeDropdown:GetValue()
			assigneeTypeDropdown:Clear()
			assigneeTypeDropdown:AddItems(updatedDropdownItems, "EPDropdownItemToggle", false)
			assigneeTypeDropdown:SetValue(previousValue)
			assigneeTypeDropdown:SetItemEnabled("Individual", enableIndividualItem)

			local previousTargetValue = targetDropdown:GetValue()
			targetDropdown:Clear()
			targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
			targetDropdown:SetValue(previousTargetValue)
			targetDropdown:SetItemEnabled("Individual", enableIndividualItem)
			Private.assignmentEditor:HandleRosterChanged()
		end

		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "rosterEditorClosed")
		end
	end

	---@param rosterTab EPRosterEditorTab
	local function HandleImportCurrentGroupButtonClicked(_, _, rosterTab)
		local importRosterWidgetMapping = nil
		local noChangeRosterWidgetMapping = nil
		if rosterTab == "Shared Roster" then
			noChangeRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
			importRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
		elseif rosterTab == "Current Plan Roster" then
			noChangeRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
			importRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		end
		if importRosterWidgetMapping and noChangeRosterWidgetMapping then
			local importRoster = {}
			local noChangeRoster = {}
			for _, rosterWidgetMapping in ipairs(importRosterWidgetMapping) do
				importRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
			end
			for _, rosterWidgetMapping in ipairs(noChangeRosterWidgetMapping) do
				noChangeRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
			end
			ImportGroupIntoRoster(importRoster)
			UpdateRosterDataFromGroup(importRoster)
			if rosterTab == "Shared Roster" then
				Private.rosterEditor:SetRosters(noChangeRoster, importRoster)
			elseif rosterTab == "Current Plan Roster" then
				Private.rosterEditor:SetRosters(importRoster, noChangeRoster)
			end
			Private.rosterEditor:SetCurrentTab(rosterTab)
		end
	end

	---@param rosterTab EPRosterEditorTab
	---@param fill boolean
	local function HandleFillOrUpdateRosterButtonClicked(_, _, rosterTab, fill)
		local fromRosterWidgetMapping = nil
		local toRosterWidgetMapping = nil
		if rosterTab == "Shared Roster" then
			fromRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
			toRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
		elseif rosterTab == "Current Plan Roster" then
			fromRosterWidgetMapping = Private.rosterEditor.sharedRosterWidgetMap
			toRosterWidgetMapping = Private.rosterEditor.currentRosterWidgetMap
		end
		if fromRosterWidgetMapping and toRosterWidgetMapping then
			local fromRoster = {}
			local toRoster = {}
			for _, rosterWidgetMapping in ipairs(fromRosterWidgetMapping) do
				fromRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
			end
			for _, rosterWidgetMapping in ipairs(toRosterWidgetMapping) do
				toRoster[rosterWidgetMapping.name] = rosterWidgetMapping.dbEntry
			end
			for name, dbEntry in pairs(fromRoster) do
				if fill and not toRoster[name] then
					toRoster[name] = Private.DeepCopy(dbEntry)
				elseif toRoster[name] then
					if dbEntry.class then
						if toRoster[name].class == "" then
							toRoster[name].class = dbEntry.class
							toRoster[name].classColoredName = ""
						end
					end
					if dbEntry.role then
						if toRoster[name].role == "" then
							toRoster[name].role = dbEntry.role
						end
					end
				end
			end
			if rosterTab == "Shared Roster" then
				Private.rosterEditor:SetRosters(fromRoster, toRoster)
			elseif rosterTab == "Current Plan Roster" then
				Private.rosterEditor:SetRosters(toRoster, fromRoster)
			end
			Private.rosterEditor:SetCurrentTab(rosterTab)
		end
	end

	---@param openToTab string
	function Private.CreateRosterEditor(openToTab)
		if Private.IsSimulatingBoss() then
			return
		end
		if not Private.rosterEditor then
			Private.rosterEditor = AceGUI:Create("EPRosterEditor")
			Private.rosterEditor:SetCallback("OnRelease", function()
				Private.rosterEditor = nil
			end)
			Private.rosterEditor:SetCallback("EditingFinished", HandleRosterEditingFinished)
			Private.rosterEditor:SetCallback("ImportCurrentGroupButtonClicked", HandleImportCurrentGroupButtonClicked)
			Private.rosterEditor:SetCallback("FillRosterButtonClicked", function(_, _, tabName)
				HandleFillOrUpdateRosterButtonClicked(_, _, tabName, true)
			end)
			Private.rosterEditor:SetCallback("UpdateRosterButtonClicked", function(_, _, tabName)
				HandleFillOrUpdateRosterButtonClicked(_, _, tabName, false)
			end)
			Private.rosterEditor.frame:SetParent(UIParent)
			Private.rosterEditor.frame:SetFrameLevel(kRosterEditorFrameLevel)
			Private.rosterEditor:SetClassDropdownData(GetOrCreateClassDropdownItemData())
			Private.rosterEditor:SetRosters(GetCurrentRoster(), AddOn.db.profile.sharedRoster)
			Private.rosterEditor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			Private.rosterEditor:SetCurrentTab(openToTab)
			Private.rosterEditor:SetPoint("TOP", UIParent, "TOP", 0, -Private.rosterEditor.frame:GetBottom())
		end
	end
end

do -- Assignment Editor
	local GetOrCreateSpellAssignmentDropdownItems = utilities.GetOrCreateSpellAssignmentDropdownItems

	local kAssignmentEditorFrameLevel = constants.frameLevels.kAssignmentEditorFrameLevel
	local assignmentEditorWidth = 240

	local function HandleAssignmentEditorDeleteButtonClicked()
		local assignmentID = Private.assignmentEditor:GetAssignmentID()
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "preAssignmentEditorDeleteButtonClicked")
		end
		Private.assignmentEditor:Release()
		local assignments = GetCurrentAssignments()
		for i, v in ipairs(assignments) do
			if v.uniqueID == assignmentID then
				tremove(assignments, i)
				interfaceUpdater.LogMessage(format("%s 1 %s.", L["Removed"], L["Assignment"]:lower()))
				break
			end
		end
		UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "assignmentEditorDeleteButtonClicked")
		end
	end

	local ChangeAssignmentType = utilities.ChangeAssignmentType
	local ClampSpellCount = bossUtilities.ClampSpellCount
	local IsValidSpellCount = bossUtilities.IsValidSpellCount
	local UpdateAssignmentBossPhase = utilities.UpdateAssignmentBossPhase

	---@param assignmentEditor EPAssignmentEditor
	---@param dataType string
	---@param value string
	local function HandleAssignmentEditorDataChanged(assignmentEditor, _, dataType, value)
		local assignmentID = assignmentEditor:GetAssignmentID()
		if not assignmentID then
			return
		end

		local assignment = FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
		if not assignment then
			return
		end

		local dungeonEncounterID = GetCurrentBossDungeonEncounterID()
		local updateFields = false
		local updateAssignments = false

		if dataType == "AssignmentType" then
			---@cast assignment CombatLogEventAssignment|TimedAssignment
			ChangeAssignmentType(assignment, dungeonEncounterID, value)
			updateFields = true
			updateAssignments = true
		elseif dataType == "CombatLogEventSpellID" then
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local spellID = tonumber(value)
				if spellID then
					utilities.ChangeAssignmentCombatLogEventSpellID(assignment, dungeonEncounterID, spellID)
				end
				updateFields = true
			end
		elseif dataType == "CombatLogEventSpellCount" then
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local spellCount = tonumber(value)
				if spellCount then
					local spellID = assignment.combatLogEventSpellID
					if IsValidSpellCount(dungeonEncounterID, spellID, spellCount) then
						assignment.spellCount = spellCount
						UpdateAssignmentBossPhase(assignment, dungeonEncounterID)
					else
						local clamped = ClampSpellCount(dungeonEncounterID, spellID, spellCount)
						if clamped then
							assignment.spellCount = clamped
						end
					end
				end
				updateFields = true
			end
		elseif dataType == "PhaseNumber" then
			if getmetatable(assignment) == PhasedAssignment then
				---@cast assignment PhasedAssignment
				local phase = tonumber(value, 10)
				if phase then
					assignment.phase = phase
				end
			end
		elseif dataType == "SpellAssignment" then
			if value == constants.kInvalidAssignmentSpellID then
				if assignment.text:len() > 0 then
					assignment.spellID = constants.kTextAssignmentSpellID
				else
					assignment.spellID = constants.kInvalidAssignmentSpellID
				end
			else
				local numericValue = tonumber(value)
				if numericValue then
					assignment.spellID = numericValue
				end
			end
			updateAssignments = true
			updateFields = true
		elseif dataType == "AssigneeType" then
			assignment.assignee = value
			updateFields = true
			updateAssignments = true
		elseif dataType == "Time" then
			local timeMinutes = tonumber(assignmentEditor.timeMinuteLineEdit:GetText())
			local timeSeconds = tonumber(assignmentEditor.timeSecondLineEdit:GetText())
			---@cast assignment CombatLogEventAssignment|TimedAssignment
			local newTime = assignment.time
			if timeMinutes and timeSeconds then
				local roundedMinutes = Round(timeMinutes, 0)
				local roundedSeconds = Round(timeSeconds, 1)
				local timeValue = roundedMinutes * 60 + roundedSeconds
				local maxTime = Private.mainFrame.timeline.GetTotalTimelineDuration()
				if timeValue < 0 or timeValue > maxTime then
					newTime = max(min(timeValue, maxTime), 0)
				else
					newTime = timeValue
				end
			end
			if getmetatable(assignment) == CombatLogEventAssignment or getmetatable(assignment) == TimedAssignment then
				---@cast assignment CombatLogEventAssignment|TimedAssignment
				newTime = Round(newTime, 1)
				assignment.time = newTime
			end
			local minutes, seconds = FormatTime(newTime)
			assignmentEditor.timeMinuteLineEdit:SetText(minutes)
			assignmentEditor.timeSecondLineEdit:SetText(seconds)
			updateAssignments = true
		elseif dataType == "OptionalText" then
			assignment.text = value
			if assignment.text:len() > 0 and assignment.spellID == constants.kInvalidAssignmentSpellID then
				assignment.spellID = constants.kTextAssignmentSpellID
				updateAssignments = true
			elseif assignment.text:len() == 0 and assignment.spellID == constants.kTextAssignmentSpellID then
				assignment.spellID = constants.kInvalidAssignmentSpellID
				updateAssignments = true
			end
			updateFields = true
		elseif dataType == "Target" then
			assignment.targetName = value
			updateFields = true
		end

		interfaceUpdater.UpdateFromAssignment(dungeonEncounterID, assignment, updateFields, true, updateAssignments)
		if
			dataType == "SpellAssignment"
			or dataType == "OptionalText"
			or dataType == "Time"
			or dataType == "AssignmentType"
		then
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "assignmentEditorDataChanged")
			end
		end
	end

	local CreateAbilityDropdownItemData = utilities.CreateAbilityDropdownItemData
	local GetBossAbilityIconAndLabel = bossUtilities.GetBossAbilityIconAndLabel

	function Private.CreateAssignmentEditor()
		local assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		assignmentEditor.FormatTime = FormatTime
		assignmentEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		assignmentEditor.frame:SetFrameLevel(kAssignmentEditorFrameLevel)
		assignmentEditor.frame:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
		assignmentEditor:SetLayout("EPVerticalLayout")
		assignmentEditor:SetCallback("OnRelease", function()
			if Private.mainFrame then
				local timeline = Private.mainFrame.timeline
				if timeline then
					timeline:ClearSelectedAssignments()
					timeline:ClearSelectedBossAbilities()
				end
			end
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "assignmentEditorReleased")
			end
			Private.assignmentEditor = nil
		end)
		assignmentEditor:SetCallback("DataChanged", HandleAssignmentEditorDataChanged)
		assignmentEditor:SetCallback("DeleteButtonClicked", HandleAssignmentEditorDeleteButtonClicked)
		assignmentEditor:SetCallback("CloseButtonClicked", function()
			Private.assignmentEditor:Release()
			UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		end)
		assignmentEditor:SetCallback("RecentItemsChanged", function(_, _, recentItems)
			AddOn.db.profile.recentSpellAssignments = recentItems
		end)
		assignmentEditor:SetCallback("FavoriteItemsChanged", function(_, _, favoriteItems)
			AddOn.db.profile.favoritedSpellAssignments = favoriteItems
		end)

		local roster = GetCurrentRoster()
		local assigneeDropdownItems = CreateAssigneeDropdownItems(roster)

		local updatedDropdownItems, enableIndividualItem =
			CreateAssignmentTypeWithRosterDropdownItems(roster, assigneeDropdownItems)
		assignmentEditor.assigneeTypeDropdown:AddItems(updatedDropdownItems, "EPDropdownItemToggle", false)
		assignmentEditor.assigneeTypeDropdown:SetItemEnabled("Individual", enableIndividualItem)

		assignmentEditor.targetDropdown:AddItems(assigneeDropdownItems, "EPDropdownItemToggle")
		assignmentEditor.targetDropdown:SetItemEnabled("Individual", enableIndividualItem)

		local favoritedSpellAssignments = AddOn.db.profile.favoritedSpellAssignments
		assignmentEditor.spellAssignmentDropdown:AddItems(
			GetOrCreateSpellAssignmentDropdownItems(true, favoritedSpellAssignments),
			"EPDropdownItemToggle"
		)
		assignmentEditor.spellAssignmentDropdown:SetItemEnabled("Recent", #AddOn.db.profile.recentSpellAssignments > 0)
		assignmentEditor.spellAssignmentDropdown:SetItemEnabled("Favorite", #favoritedSpellAssignments > 0)
		assignmentEditor.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu(
			"Recent",
			AddOn.db.profile.recentSpellAssignments
		)
		local favoritedItems = Private.DeepCopy(favoritedSpellAssignments)
		for _, data in ipairs(favoritedItems) do
			data.customTextureSelectable = true
			data.customTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]]
			data.customTextureVertexColor = { 1, 1, 1, 1 }
		end
		assignmentEditor.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu("Favorite", favoritedItems)

		local dropdownItems = {}
		local itemsToDisable = {}
		local boss = GetCurrentBoss()
		if boss then
			for _, abilityID in ipairs(boss.sortedAbilityIDs) do
				local icon, text = GetBossAbilityIconAndLabel(boss, abilityID)
				tinsert(dropdownItems, CreateAbilityDropdownItemData(abilityID, icon, text))
				if #boss.abilities[abilityID].allowedCombatLogEventTypes == 0 then
					tinsert(itemsToDisable, abilityID)
				end
			end
		end
		assignmentEditor.combatLogEventSpellIDDropdown:AddItems(dropdownItems, "EPDropdownItemToggle")
		for _, abilityID in ipairs(itemsToDisable) do
			assignmentEditor.combatLogEventSpellIDDropdown:SetItemEnabled(abilityID, false)
		end
		assignmentEditor:SetWidth(assignmentEditorWidth)
		assignmentEditor:DoLayout()
		Private.assignmentEditor = assignmentEditor
	end
end

do -- Phase Length Editor
	local CalculateMaxPhaseDuration = bossUtilities.CalculateMaxPhaseDuration
	local GetTotalDurations = bossUtilities.GetTotalDurations
	local SetPhaseDuration = bossUtilities.SetPhaseDuration
	local SetPhaseDurations = bossUtilities.SetPhaseDurations
	local SetPhaseCount = bossUtilities.SetPhaseCount

	local kPhaseEditorFrameLevel = constants.frameLevels.kPhaseEditorFrameLevel
	local kMaxBossDuration = constants.kMaxBossDuration
	local kMinBossPhaseDuration = constants.kMinBossPhaseDuration

	local function UpdateTotalTime()
		if Private.phaseLengthEditor then
			local totalCustomTime, totalDefaultTime = GetTotalDurations(GetCurrentBossDungeonEncounterID())
			local totalCustomMinutes, totalCustomSeconds = FormatTime(totalCustomTime)
			local totalCustomTimeString = totalCustomMinutes .. ":" .. totalCustomSeconds
			local totalDefaultMinutes, totalDefaultSeconds = FormatTime(totalDefaultTime)
			local totalDefaultTimeString = totalDefaultMinutes .. ":" .. totalDefaultSeconds
			Private.phaseLengthEditor:SetTotalDurations(totalDefaultTimeString, totalCustomTimeString)
		end
	end

	---@param phaseIndex integer
	---@param minLineEdit EPLineEdit
	---@param secLineEdit EPLineEdit
	local function HandlePhaseLengthEditorDataChanged(_, _, phaseIndex, minLineEdit, secLineEdit)
		local boss = GetCurrentBoss()
		if boss then
			local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()

			local previousDuration = boss.phases[phaseIndex].duration
			if boss.treatAsSinglePhase then
				local totalCustomTime, _ = GetTotalDurations(bossDungeonEncounterID)
				previousDuration = totalCustomTime
			end

			local formatAndReturn = false
			local newDuration = previousDuration
			local timeMinutes = tonumber(minLineEdit:GetText())
			local timeSeconds = tonumber(secLineEdit:GetText())
			if timeMinutes and timeSeconds then
				local roundedMinutes = Round(timeMinutes, 0)
				local roundedSeconds = Round(timeSeconds, 1)
				newDuration = roundedMinutes * 60 + roundedSeconds
				local maxPhaseDuration = CalculateMaxPhaseDuration(bossDungeonEncounterID, phaseIndex, kMaxBossDuration)
				if maxPhaseDuration then
					if boss.treatAsSinglePhase then
						maxPhaseDuration = kMaxBossDuration
					end
					newDuration = Clamp(newDuration, kMinBossPhaseDuration, maxPhaseDuration)
				end
				if abs(newDuration - previousDuration) < 0.01 then
					formatAndReturn = true
				end
			else
				formatAndReturn = true
			end

			local minutes, seconds = FormatTime(newDuration)
			minLineEdit:SetText(minutes)
			secLineEdit:SetText(seconds)

			if not formatAndReturn then
				local customPhaseDurations = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseDurations
				if boss.treatAsSinglePhase then
					local cumulativePhaseTime = 0.0
					for index, phase in ipairs(boss.phases) do
						if cumulativePhaseTime + phase.defaultDuration <= newDuration then
							cumulativePhaseTime = cumulativePhaseTime + phase.defaultDuration
							customPhaseDurations[index] = phase.defaultDuration
						elseif cumulativePhaseTime < newDuration then
							customPhaseDurations[index] = newDuration - cumulativePhaseTime
							cumulativePhaseTime = cumulativePhaseTime + phase.duration
						else
							customPhaseDurations[index] = 0.0
						end
					end
					if cumulativePhaseTime < newDuration then
						customPhaseDurations[#boss.phases] = (customPhaseDurations[#boss.phases] or 0)
							+ newDuration
							- cumulativePhaseTime
					end
					SetPhaseDurations(bossDungeonEncounterID, customPhaseDurations)
				else
					SetPhaseDuration(bossDungeonEncounterID, phaseIndex, newDuration)
					customPhaseDurations[phaseIndex] = newDuration
				end

				UpdateBoss(bossDungeonEncounterID, true)
				UpdateAllAssignments(false, bossDungeonEncounterID)
				UpdateTotalTime()

				if Private.activeTutorialCallbackName then
					if phaseIndex == 1 then
						Private.callbacks:Fire(
							Private.activeTutorialCallbackName,
							"phaseOneDurationChanged",
							newDuration
						)
					end
				end
			end
		end
	end

	local floor = math.floor

	---@param phaseIndex integer
	---@param text string
	---@param widget EPLineEdit
	local function HandlePhaseCountChanged(_, _, phaseIndex, text, widget)
		local boss = GetCurrentBoss()
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		if boss then
			local previousCount = boss.phases[phaseIndex].count
			local newCount = tonumber(text)
			if newCount then
				newCount = floor(newCount)
			else
				widget:SetText(tostring(previousCount))
				return
			end
			local validatedPhaseCounts = SetPhaseCount(bossDungeonEncounterID, phaseIndex, newCount, kMaxBossDuration)
			local customPhaseCounts = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].customPhaseCounts
			for index, count in ipairs(validatedPhaseCounts) do
				customPhaseCounts[index] = count
			end
			Private.phaseLengthEditor:SetPhaseCounts(validatedPhaseCounts)
			UpdateBoss(bossDungeonEncounterID, true)
			UpdateAllAssignments(false, bossDungeonEncounterID)
			UpdateTotalTime()
		end
	end

	function Private.CreatePhaseLengthEditor()
		if not Private.phaseLengthEditor then
			local phaseLengthEditor = AceGUI:Create("EPPhaseLengthEditor")
			phaseLengthEditor.FormatTime = FormatTime
			phaseLengthEditor:SetCallback("OnRelease", function()
				Private.phaseLengthEditor = nil
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "phaseLengthEditorReleased")
				end
			end)
			phaseLengthEditor:SetCallback("CloseButtonClicked", function()
				Private.phaseLengthEditor:Release()
			end)
			phaseLengthEditor:SetCallback("ResetAllButtonClicked", function()
				local lastOpenPlan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
				wipe(lastOpenPlan.customPhaseDurations)
				wipe(lastOpenPlan.customPhaseCounts)
				local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
				UpdateBoss(bossDungeonEncounterID, true)
				UpdateAllAssignments(false, bossDungeonEncounterID)
				UpdateTotalTime()
			end)
			phaseLengthEditor:SetCallback("DataChanged", HandlePhaseLengthEditorDataChanged)
			phaseLengthEditor:SetCallback("CountChanged", HandlePhaseCountChanged)

			local boss = GetCurrentBoss()
			if boss then
				local totalCustomTime, totalDefaultTime = GetTotalDurations(GetCurrentBossDungeonEncounterID())
				if boss.treatAsSinglePhase then
					local phaseData = {}
					tinsert(phaseData, {
						name = L["Phase"] .. " 1",
						defaultDuration = totalDefaultTime,
						fixedDuration = boss.phases[1].fixedDuration,
						duration = totalCustomTime,
						count = 1,
						defaultCount = 1,
						repeatAfter = nil,
					})
					phaseLengthEditor:AddEntries(phaseData)
				else
					phaseLengthEditor:AddEntries(boss.phases)
				end

				local totalCustomMinutes, totalCustomSeconds = FormatTime(totalCustomTime)
				local totalCustomTimeString = totalCustomMinutes .. ":" .. totalCustomSeconds
				local totalDefaultMinutes, totalDefaultSeconds = FormatTime(totalDefaultTime)
				local totalDefaultTimeString = totalDefaultMinutes .. ":" .. totalDefaultSeconds
				phaseLengthEditor:SetTotalDurations(totalDefaultTimeString, totalCustomTimeString)
			end

			phaseLengthEditor.frame:SetParent(UIParent)
			phaseLengthEditor.frame:SetFrameLevel(kPhaseEditorFrameLevel)
			phaseLengthEditor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			phaseLengthEditor:Resize()
			phaseLengthEditor:SetPoint("TOP", UIParent, "TOP", 0, -phaseLengthEditor.frame:GetBottom())

			Private.phaseLengthEditor = phaseLengthEditor
		end
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "phaseLengthEditorOpened")
		end
	end
end

---@param plan Plan
---@param newBossDungeonEncounterID integer
---@param conversionMethod integer|nil
local function HandleConvertAssignments(plan, newBossDungeonEncounterID, conversionMethod)
	local currentBossDungeonEncounterID = plan.dungeonEncounterID
	local currentBoss = GetBoss(currentBossDungeonEncounterID)
	local newBoss = GetBoss(newBossDungeonEncounterID)
	local currentAssignments = plan.assignments
	if currentBoss and newBoss then
		ClosePlanDependentWidgets()
		if conversionMethod then
			ConvertAssignmentsToNewBoss(currentAssignments, currentBoss, newBoss, conversionMethod)
		end
		ChangePlanBoss(AddOn.db.profile.plans, plan.name, newBossDungeonEncounterID)
		interfaceUpdater.RepopulatePlanWidgets()
		UpdateBoss(newBossDungeonEncounterID, true)
		UpdateAllAssignments(false, newBossDungeonEncounterID)
	end
end

---@param value number|string
local function HandleChangeBossDropdownValueChanged(value)
	local bossDungeonEncounterID = tonumber(value)
	if bossDungeonEncounterID then
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local containsCombatLogEventAssignment = false
		for _, assignment in ipairs(plan.assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				containsCombatLogEventAssignment = true
				break
			end
		end
		if containsCombatLogEventAssignment then
			local messageBoxData = {
				ID = Private.GenerateUniqueID(),
				isCommunication = true,
				title = L["Changing Boss with Combat Log Event Assignments"],
				message = format(
					"%s\n\n%s.\n%s.\n%s.\n\n%s",
					L["The current plan includes combat log event assignments tied to this boss's spells. Choose an option:"],
					L["1. Convert all assignments to timed assignments for the new boss"],
					L["2. Replace spells with those of the new boss, matching the closest timing"],
					L["3. Cancel"],
					L["Note: Replacing spells may not be reversible and could result in changes if you revert to the original boss."]
				),
				acceptButtonText = L["Convert to Timed Assignments"],
				acceptButtonCallback = function()
					HandleConvertAssignments(plan, bossDungeonEncounterID, 1)
				end,
				rejectButtonText = L["Cancel"],
				rejectButtonCallback = nil,
				buttonsToAdd = {
					{
						beforeButtonIndex = 2,
						buttonText = L["Replace Spells"],
						callback = function()
							HandleConvertAssignments(plan, bossDungeonEncounterID, 2)
						end,
					},
				},
			} --[[@as MessageBoxData]]
			CreateMessageBox(messageBoxData, false)
		else
			HandleConvertAssignments(plan, bossDungeonEncounterID, nil)
		end
	end
end

---@param dropdown EPDropdown
---@param value number|string
---@param selected boolean
local function HandleActiveBossAbilitiesChanged(dropdown, value, selected)
	if type(value) == "number" then
		local boss = GetBoss(Private.mainFrame.bossLabel:GetValue())
		if boss then
			local activeBossAbilities = AddOn.db.profile.activeBossAbilities[boss.dungeonEncounterID]
			local atLeastOneSelected = false
			for currentAbilityID, currentSelected in pairs(activeBossAbilities) do
				if currentAbilityID ~= value and currentSelected then
					atLeastOneSelected = true
					break
				end
			end

			local enabledCount = 0
			if Private.activeTutorialCallbackName then
				for _, currentSelected in pairs(activeBossAbilities) do
					if currentSelected == true then
						enabledCount = enabledCount + 1
					end
				end
			end

			if atLeastOneSelected then
				activeBossAbilities[value] = selected
				UpdateBoss(boss.dungeonEncounterID, false)
			else
				dropdown:SetItemIsSelected(value, true, true)
				activeBossAbilities[value] = true
			end

			if Private.activeTutorialCallbackName then
				local newEnabledCount = 0
				for _, currentSelected in pairs(activeBossAbilities) do
					if currentSelected == true then
						newEnabledCount = newEnabledCount + 1
					end
				end
				if newEnabledCount < enabledCount then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "bossAbilityHidden")
				end
			end
		end
	end
end

---@param dropdown EPDropdown
---@param value any
local function HandlePlanDropdownValueChanged(dropdown, _, value)
	if AddOn.db.profile.plans[value] then
		ClosePlanDependentWidgets()
		AddOn.db.profile.lastOpenPlan = value
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local bossDungeonEncounterID = plan.dungeonEncounterID

		UpdateBoss(bossDungeonEncounterID, true)
		UpdateAllAssignments(true, bossDungeonEncounterID)
		interfaceUpdater.UpdatePlanCheckBoxes(plan)
		Private.mainFrame:DoLayout()
		Private.callbacks:Fire("PlanChanged")
	else
		local dungeonInstanceID, mapChallengeModeID = nil, nil
		if type(value) == "number" then
			dungeonInstanceID = value
		elseif type(value) == "table" then
			dungeonInstanceID, mapChallengeModeID = value.dungeonInstanceID, value.mapChallengeModeID
		end

		if dungeonInstanceID then
			local dungeonInstance = bossUtilities.FindDungeonInstance(dungeonInstanceID, mapChallengeModeID)
			if dungeonInstance then
				local _, boss = next(dungeonInstance.bosses)
				---@cast boss Boss
				Private.CreateNewPlanDialog(boss.dungeonEncounterID)
				dropdown:SetValue(AddOn.db.profile.lastOpenPlan)
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanButtonClicked")
				end
			end
		else
			value = value or "nil"
			error(format("The plan '%s' does not exist.", value))
		end
	end
end

---@param lineEdit EPLineEdit
---@param text string
local function HandlePlanNameChanged(lineEdit, _, text)
	if Private.activeTutorialCallbackName then
		return
	end
	local newPlanName = text:match("|T.-|t%s(.+)") or text
	local currentPlanName = AddOn.db.profile.lastOpenPlan
	local revert = false

	if newPlanName:gsub("%s", "") == "" then
		revert = true
	elseif newPlanName == currentPlanName then
		return
	elseif AddOn.db.profile.plans[newPlanName] then
		revert = true
	end

	local currentPlan = AddOn.db.profile.plans[currentPlanName]
	if revert then
		local previousText
		local boss = GetBoss(currentPlan.dungeonEncounterID)
		if boss then
			previousText = format("|T%s:16|t %s", boss.icon, currentPlanName)
		else
			previousText = currentPlanName
		end
		lineEdit:SetText(previousText)
	else
		AddOn.db.profile.plans[newPlanName] = currentPlan
		AddOn.db.profile.plans[currentPlanName] = nil
		AddOn.db.profile.plans[newPlanName].name = newPlanName
		AddOn.db.profile.lastOpenPlan = newPlanName
		local planDropdown = Private.mainFrame.planDropdown
		if planDropdown then
			local newText
			local boss = GetBoss(currentPlan.dungeonEncounterID)
			if boss then
				newText = format("|T%s:16|t %s", boss.icon, newPlanName)
			else
				newText = newPlanName
			end
			planDropdown:EditItemValueAndText(currentPlanName, newPlanName, newText)
			planDropdown:Sort(AddOn.db.profile.plans[newPlanName].instanceID, nil, utilities.CreatePlanSorter(boss))
		end
	end
end

---@param widget EPTimeline|nil
---@param uniqueID integer
---@param timeDifference number|nil
local function HandleTimelineAssignmentClicked(widget, _, uniqueID, timeDifference)
	if Private.IsSimulatingBoss() then
		return
	end
	local assignment = FindAssignmentByUniqueID(GetCurrentAssignments(), uniqueID)
	if assignment then
		if not Private.assignmentEditor then
			Private.CreateAssignmentEditor()
		end
		interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
		if Private.activeTutorialCallbackName and widget then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, timeDifference)
		end
	end
end

local function HandleAddAssigneeRowDropdownValueChanged(dropdown, _, value)
	if value == addAssigneeText then
		return
	end

	local assignments = GetCurrentAssignments()
	for _, assignment in pairs(GetCurrentAssignments()) do
		if assignment.assignee == value then
			dropdown:SetText(addAssigneeText)
			return
		end
	end

	local assignment = TimedAssignment:New()
	assignment.assignee = value
	if #assignments == 0 then
		local timelineRows = AddOn.db.profile.preferences.timelineRows
		timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)
	end

	tinsert(assignments, assignment)
	UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	dropdown:SetText(addAssigneeText)
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, "assigneeAdded")
	end
end

---@param assignee string
---@param spellID integer|nil
---@param time number
local function HandleCreateNewAssignment(_, _, assignee, spellID, time)
	local encounterID = GetCurrentBossDungeonEncounterID()
	local assignment = utilities.CreateNewAssignment(encounterID, time, assignee, spellID)
	if assignment then
		tinsert(GetCurrentAssignments(), assignment)
		UpdateAllAssignments(false, encounterID)
		HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "added")
		end
	end
end

do -- Plan Menu Button Handlers
	local GetBossName = bossUtilities.GetBossName

	local kExportEditBoxFrameLevel = constants.frameLevels.kExportEditBoxFrameLevel
	local kImportEditBoxFrameLevel = constants.frameLevels.kImportEditBoxFrameLevel
	local kNewPlanDialogFrameLevel = constants.frameLevels.kNewPlanDialogFrameLevel

	---@param newPlanName string
	local function HandleImportPlanFromString(newPlanName)
		ClosePlanDependentWidgets()
		local text = Private.importEditBox:GetText()
		Private.importEditBox:Release()
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		bossDungeonEncounterID = Private:ImportPlanFromNote(newPlanName, bossDungeonEncounterID, text)
			or bossDungeonEncounterID

		AddOn.db.profile.lastOpenPlan = newPlanName
		local newPlan = AddOn.db.profile.plans[newPlanName]
		AddPlanToDropdown(newPlan, true)
		interfaceUpdater.RepopulatePlanWidgets()
		UpdateBoss(bossDungeonEncounterID, true)
		UpdateAllAssignments(true, bossDungeonEncounterID)
		Private.callbacks:Fire("PlanChanged")
	end

	local function CreateImportEditBox()
		if not Private.importEditBox then
			local importEditBox = AceGUI:Create("EPEditBox")
			importEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
			importEditBox.frame:SetFrameLevel(kImportEditBoxFrameLevel)
			importEditBox.frame:SetPoint("CENTER")
			importEditBox:SetTitle(L["Import From Text"])
			importEditBox:ShowOkayButton(true, L["Import As New Plan"])
			importEditBox.okayButton:SetEnabled(true)
			importEditBox:SetCallback("OnRelease", function()
				Private.importEditBox = nil
			end)
			importEditBox:SetCallback("CloseButtonClicked", function()
				AceGUI:Release(Private.importEditBox)
			end)
			importEditBox:SetCallback("OverwriteCheckBoxValueChanged", function(widget, _, checked)
				if checked then
					widget.lineEdit:SetText(AddOn.db.profile.lastOpenPlan)
					widget.okayButton:SetText(L["Overwrite"] .. " " .. AddOn.db.profile.lastOpenPlan)
					widget.okayButton:SetWidthFromText()
					widget.okayButton:SetEnabled(true)
				else
					widget.lineEdit:SetText("")
					widget.okayButton:SetEnabled(false)
					widget.okayButton:SetText(L["Import As New Plan"])
					widget.okayButton:SetWidthFromText()
				end
			end)
			importEditBox:SetCallback("ValidatePlanName", function(widget, _, planName)
				planName = planName:trim()
				if planName == "" or AddOn.db.profile.plans[planName] then
					widget.okayButton:SetEnabled(false)
				else
					widget.okayButton:SetEnabled(true)
				end
				widget.okayButton:SetText(L["Import As"] .. " " .. planName)
				widget.okayButton:SetWidthFromText()
			end)
			importEditBox:ShowCheckBoxAndLineEdit(
				true,
				L["Overwrite Current Plan"],
				L["New Plan Name:"],
				CreateUniquePlanName(AddOn.db.profile.plans, GetCurrentBoss().name)
			)
			importEditBox:SetCallback("OkayButtonClicked", function(widget)
				local checked = Private.importEditBox.checkBox:IsChecked()
				local planName = Private.importEditBox.lineEdit:GetText()
				planName = planName:trim()
				if planName == "" then
					widget.okayButton:SetEnabled(false)
				else
					if not AddOn.db.profile.plans[planName] or checked then
						HandleImportPlanFromString(planName)
					end
				end
			end)
			Private.importEditBox = importEditBox
		end
	end

	local function HandleDuplicatePlanButtonClicked()
		ClosePlanDependentWidgets()
		local plans = AddOn.db.profile.plans
		local planToDuplicateName = AddOn.db.profile.lastOpenPlan

		local newPlan = utilities.DuplicatePlan(plans, planToDuplicateName, planToDuplicateName)
		AddOn.db.profile.lastOpenPlan = newPlan.name

		UpdateAllAssignments(true, GetCurrentBossDungeonEncounterID())
		AddPlanToDropdown(newPlan, true)
	end

	local RemovePlanFromDropdown = interfaceUpdater.RemovePlanFromDropdown

	local function HandleDeleteCurrentPlanButtonClicked()
		ClosePlanDependentWidgets()
		local lastOpenPlanName = AddOn.db.profile.lastOpenPlan
		utilities.DeletePlan(AddOn.db.profile, lastOpenPlanName)
		RemovePlanFromDropdown(lastOpenPlanName)

		local newLastOpenPlanName = AddOn.db.profile.lastOpenPlan
		local newLastOpenPlan = AddOn.db.profile.plans[newLastOpenPlanName]
		AddPlanToDropdown(newLastOpenPlan, true) -- Won't add duplicate, updates plan checkboxes

		local newEncounterID = newLastOpenPlan.dungeonEncounterID
		UpdateBoss(newEncounterID, true)
		UpdateAllAssignments(true, newEncounterID)
		Private.callbacks:Fire("PlanChanged")
	end

	---@param importType string
	local function ImportPlan(importType)
		if not Private.importEditBox then
			if importType:find("FromMRT") then
				if VMRT and VMRT.Note and VMRT.Note.Text1 then
					local createNew = importType:find("CreateNew")
					ClosePlanDependentWidgets()
					local text = VMRT.Note.Text1
					local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
					local bossName = GetBossName(bossDungeonEncounterID)
					local plans = AddOn.db.profile.plans
					local planName
					if createNew then
						planName = CreateUniquePlanName(plans, bossName --[[@as string]])
					else
						planName = AddOn.db.profile.lastOpenPlan
					end
					bossDungeonEncounterID = Private:ImportPlanFromNote(planName, bossDungeonEncounterID, text)
						or bossDungeonEncounterID
					AddOn.db.profile.lastOpenPlan = planName
					AddPlanToDropdown(plans[planName], true)
					UpdateBoss(bossDungeonEncounterID, true)
					UpdateAllAssignments(true, bossDungeonEncounterID)
					Private.callbacks:Fire("PlanChanged")
				end
			elseif importType:find("FromString") then
				CreateImportEditBox()
			end
		end
	end

	local function HandleExportPlanButtonClicked()
		if not Private.exportEditBox then
			local exportEditBox = AceGUI:Create("EPEditBox")
			exportEditBox.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
			exportEditBox.frame:SetFrameLevel(kExportEditBoxFrameLevel)
			exportEditBox.frame:SetPoint("CENTER")
			exportEditBox:SetTitle(L["Export"])
			exportEditBox:SetCallback("OnRelease", function()
				Private.exportEditBox = nil
			end)
			exportEditBox:SetCallback("CloseButtonClicked", function()
				AceGUI:Release(Private.exportEditBox)
			end)
			Private.exportEditBox = exportEditBox
		end
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local text = Private:ExportPlanToNote(plan, GetCurrentBossDungeonEncounterID())
		if text then
			Private.exportEditBox:SetText(text)
			Private.exportEditBox:HighlightTextAndFocus()
		end
	end

	---@param bossDungeonEncounterID integer|nil
	function Private.CreateNewPlanDialog(bossDungeonEncounterID)
		if not Private.newPlanDialog then
			local newPlanDialog = AceGUI:Create("EPNewPlanDialog")
			newPlanDialog:SetCallback("OnRelease", function()
				Private.newPlanDialog = nil
			end)
			newPlanDialog:SetCallback("CloseButtonClicked", function()
				Private.newPlanDialog:Release()
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogClosed")
				end
			end)
			newPlanDialog:SetCallback("CancelButtonClicked", function()
				Private.newPlanDialog:Release()
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogClosed")
				end
			end)
			newPlanDialog:SetCallback("CreateNewPlanName", function(widget, _, currentBossDungeonEncounterID)
				local newBossName = GetBossName(currentBossDungeonEncounterID) --[[@as string]]
				widget:SetPlanNameLineEditText(CreateUniquePlanName(AddOn.db.profile.plans, newBossName))
				widget:SetCreateButtonEnabled(true)
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogValidate")
				end
			end)
			newPlanDialog:SetCallback(
				"CreateButtonClicked",
				function(widget, _, currentBossDungeonEncounterID, planName)
					planName = planName:trim()
					if planName == "" or AddOn.db.profile.plans[planName] then
						widget:SetCreateButtonEnabled(false)
					else
						ClosePlanDependentWidgets()
						widget:Release()
						local newPlan =
							utilities.CreatePlan(AddOn.db.profile.plans, planName, currentBossDungeonEncounterID)
						AddOn.db.profile.lastOpenPlan = newPlan.name
						AddPlanToDropdown(newPlan, true)
						UpdateBoss(currentBossDungeonEncounterID, true)
						UpdateAllAssignments(true, currentBossDungeonEncounterID)
						Private.callbacks:Fire("PlanChanged")
						if Private.activeTutorialCallbackName then
							Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogPlanCreated")
						end
					end
				end
			)
			newPlanDialog:SetCallback("ValidatePlanName", function(widget, _, planName)
				planName = planName:trim()
				if planName == "" or AddOn.db.profile.plans[planName] then
					widget:SetCreateButtonEnabled(false)
				else
					widget:SetCreateButtonEnabled(true)
				end
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogValidate")
				end
			end)
			if not bossDungeonEncounterID then
				bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
			end
			newPlanDialog.frame:SetParent(UIParent)
			newPlanDialog.frame:SetFrameLevel(kNewPlanDialogFrameLevel)
			newPlanDialog:SetBossDropdownItems(utilities.GetOrCreateBossDropdownItems(), bossDungeonEncounterID)
			newPlanDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			newPlanDialog:Resize()
			newPlanDialog:SetPoint("TOP", UIParent, "TOP", 0, -newPlanDialog.frame:GetBottom())
			local bossName = GetBossName(bossDungeonEncounterID) --[[@as string]]
			newPlanDialog:SetPlanNameLineEditText(CreateUniquePlanName(AddOn.db.profile.plans, bossName))
			Private.newPlanDialog = newPlanDialog
		end
	end

	---@param planMenuButton EPDropdown
	---@param value any
	function Handle.PlanMenuButtonClicked(planMenuButton, _, value)
		if value == "Plan" then
			return
		end
		if value == "New Plan" then
			Private.CreateNewPlanDialog()
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanButtonClicked")
			end
		elseif value == "Duplicate Plan" then
			HandleDuplicatePlanButtonClicked()
		elseif value == "Export Current Plan" then
			HandleExportPlanButtonClicked()
		elseif value == "Delete Current Plan" then
			local messageBoxData = {
				ID = Private.GenerateUniqueID(),
				isCommunication = false,
				title = L["Delete Plan Confirmation"],
				message = format(
					"%s '%s'?",
					L["Are you sure you want to delete the plan"],
					AddOn.db.profile.lastOpenPlan
				),
				acceptButtonText = L["Okay"],
				acceptButtonCallback = function()
					if Private.mainFrame then
						HandleDeleteCurrentPlanButtonClicked()
					end
				end,
				rejectButtonText = L["Cancel"],
				rejectButtonCallback = nil,
				buttonsToAdd = {},
			} --[[@as MessageBoxData]]
			CreateMessageBox(messageBoxData, false)
		elseif sub(value, 1, 4) == "From" then
			ImportPlan(value)
		end
		planMenuButton:SetValue("Plan")
		planMenuButton:SetText(L["Plan"])
	end
end

---@param bossMenuButton EPDropdown
---@param value any
local function HandleBossMenuButtonClicked(bossMenuButton, _, value, selected, topLevelItemValue)
	if value == "Boss" then
		return
	elseif value == "Edit Phase Timings" then
		Private.CreatePhaseLengthEditor()
		bossMenuButton:SetValue("Boss")
		bossMenuButton:SetText("Boss")
	elseif topLevelItemValue == "Change Boss" then
		bossMenuButton:Close()
		HandleChangeBossDropdownValueChanged(value)
		bossMenuButton:SetValue("Boss")
		bossMenuButton:SetText("Boss")
	elseif topLevelItemValue == "Filter Spells" then
		HandleActiveBossAbilitiesChanged(bossMenuButton, value, selected)
	end
end

local function HandleRosterMenuButtonClicked()
	Private.CreateRosterEditor("Current Plan Roster")
	if Private.mainFrame then
		local menuButtonContainer = Private.mainFrame.menuButtonContainer
		if menuButtonContainer then
			for _, widget in ipairs(menuButtonContainer.children) do
				if widget.type == "EPDropdown" then
					widget:Close()
				end
			end
		end
	end
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, "rosterEditorOpened")
	end
end

local function HandlePreferencesMenuButtonClicked()
	if not Private.optionsMenu then
		Private:CreateOptionsMenu()
	end
	if Private.mainFrame then
		local menuButtonContainer = Private.mainFrame.menuButtonContainer
		if menuButtonContainer then
			for _, widget in ipairs(menuButtonContainer.children) do
				if widget.type == "EPDropdown" then
					widget:Close()
				end
			end
		end
	end
end

local function HandleExternalTextButtonClicked()
	if not Private.externalTextEditor then
		local currentPlan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local currentPlanID = currentPlan.ID
		local externalTextEditor = AceGUI:Create("EPEditBox")
		externalTextEditor.frame:SetParent(Private.mainFrame.frame --[[@as Frame]])
		externalTextEditor.frame:SetFrameLevel(constants.frameLevels.kExternalTextEditorFrameLevel)
		externalTextEditor.frame:SetPoint("CENTER")
		externalTextEditor:SetTitle(L["External Text Editor"])
		externalTextEditor:SetCallback("OnRelease", function()
			Private.externalTextEditor = nil
		end)
		externalTextEditor:SetCallback("CloseButtonClicked", function()
			local text = Private.externalTextEditor:GetText()
			AceGUI:Release(Private.externalTextEditor)

			if AddOn.db and AddOn.db.profile then
				local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
				if plan.ID == currentPlanID then
					plan.content = utilities.SplitStringIntoTable(text)
				end
			end
		end)
		externalTextEditor:SetText(("\n"):join(unpack(currentPlan.content)))
		externalTextEditor:SetFocusAndCursorPosition(0)
		Private.externalTextEditor = externalTextEditor
	end
end

---@param simulateReminderButton EPButton
local function HandleSimulateRemindersButtonClicked(simulateReminderButton)
	local wasSimulatingBoss = Private.IsSimulatingBoss()

	if wasSimulatingBoss then
		Private:StopSimulatingBoss()
		simulateReminderButton:SetText(L["Simulate Reminders"])
	else
		ClosePlanDependentWidgets()
		simulateReminderButton:SetText(L["Stop Simulating"])
		local sortedTimelineAssignments = SortAssignments(
			GetCurrentPlan(),
			AddOn.db.profile.preferences.assignmentSortType,
			GetCurrentBossDungeonEncounterID()
		)
		Private:SimulateBoss(GetCurrentBossDungeonEncounterID(), sortedTimelineAssignments, GetCurrentRoster())
	end
	local isSimulatingBoss = not wasSimulatingBoss
	local timeline = Private.mainFrame.timeline
	if timeline then
		timeline:SetIsSimulating(isSimulatingBoss)
		local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
		addAssigneeDropdown:SetEnabled(not isSimulatingBoss)
	end
	Private.mainFrame.planDropdown:SetEnabled(not isSimulatingBoss)
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(
			Private.activeTutorialCallbackName,
			wasSimulatingBoss and "simulationStopped" or "simulationStarted"
		)
	end
end

local simulationCompletedObject = {}
function simulationCompletedObject.HandleSimulationCompleted()
	if Private.mainFrame then
		local simulateRemindersButton = Private.mainFrame.simulateRemindersButton
		if simulateRemindersButton then
			simulateRemindersButton:SetText(L["Simulate Reminders"])
			local timeline = Private.mainFrame.timeline
			if timeline then
				timeline:SetIsSimulating(false)
				local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
				addAssigneeDropdown:SetEnabled(true)
			end
			Private.mainFrame.planDropdown:SetEnabled(true)
		end
	end
end

---@param value boolean
local function HandlePlanReminderEnableCheckBoxValueChanged(_, _, value)
	local planName = AddOn.db.profile.lastOpenPlan
	local plan = AddOn.db.profile.plans[planName]
	plan.remindersEnabled = value
	interfaceUpdater.UpdatePlanDropdownItemCustomTexture(planName, value)
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, value)
	end
end

---@param checkBoxOrButton EPCheckBox|EPButton
local function HandlePlanReminderCheckBoxOrButtonEnter(checkBoxOrButton)
	local preferences = AddOn.db.profile.preferences
	if preferences.reminder.enabled == false then
		local tooltip = Private.tooltip
		tooltip:SetOwner(checkBoxOrButton.frame, "ANCHOR_TOP")
		local isCheckBox = checkBoxOrButton.type == "EPCheckBox"
		local title, text

		if isCheckBox then
			title = L["Plan Reminders"]
			text =
				L["Reminders are currently disabled globally. Enable them in Preferences to modify this plan's reminder setting."]
		else
			title = L["Simulate Reminders"]
			text = L["Reminders are currently disabled globally. Enable them in Preferences to simulate them."]
		end
		tooltip:SetText(title, 1, 0.82, 0, true)
		tooltip:AddLine(text, 1, 1, 1, true)
		tooltip:Show()
	end
end

local function HandlePlanReminderEnableCheckBoxOrButtonLeave()
	Private.tooltip:ClearLines()
	Private.tooltip:Hide()
end

local function HandlePrimaryPlanCheckBoxValueChanged()
	local planName = AddOn.db.profile.lastOpenPlan
	local plans = AddOn.db.profile.plans
	local plan = plans[planName]
	utilities.SetDesignatedExternalPlan(plans, plan)
	interfaceUpdater.UpdatePlanCheckBoxes(plan)
end

---@param checkBox EPCheckBox
local function HandlePrimaryPlanCheckBoxEnter(checkBox)
	local tooltip = Private.tooltip
	tooltip:SetOwner(checkBox.frame, "ANCHOR_TOP")
	local title = L["Designated External Plan"]
	local text =
		L["Whether External Text of this plan should be made available to other addons or WeakAuras. Only one plan per boss may have this designation."]
	tooltip:SetText(title, 1, 0.82, 0, true)
	tooltip:AddLine(text, 1, 1, 1, true)
	tooltip:Show()
end

local function HandlePrimaryPlanCheckBoxLeave()
	Private.tooltip:ClearLines()
	Private.tooltip:Hide()
end

---@param timelineAssignment TimelineAssignment
---@return number|nil
local function HandleCalculateAssignmentTimeFromStart(timelineAssignment)
	local assignment = timelineAssignment.assignment
	if getmetatable(assignment) == CombatLogEventAssignment then
		---@cast assignment CombatLogEventAssignment
		return ConvertAbsoluteTimeToCombatLogEventTime(
			timelineAssignment.startTime,
			GetCurrentBossDungeonEncounterID(),
			assignment.combatLogEventSpellID,
			assignment.spellCount,
			assignment.combatLogEventType
		)
	else
		return nil
	end
end

---@param timelineAssignment TimelineAssignment
---@return number|nil
local function HandleGetMinimumCombatLogEventTime(timelineAssignment)
	local assignment = timelineAssignment.assignment
	if getmetatable(assignment) == CombatLogEventAssignment then
		---@cast assignment CombatLogEventAssignment
		return GetMinimumCombatLogEventTime(
			GetCurrentBossDungeonEncounterID(),
			assignment.combatLogEventSpellID,
			assignment.spellCount,
			assignment.combatLogEventType
		)
	else
		return nil
	end
end

---@param timelineAssignment TimelineAssignment
---@param newTimelineAssignment table
local function HandleDuplicateAssignmentStart(_, _, timelineAssignment, newTimelineAssignment)
	Private.DuplicateTimelineAssignment(timelineAssignment, newTimelineAssignment)
end

---@param timelineAssignment TimelineAssignment
---@param absoluteTime number
local function HandleDuplicateAssignmentEnd(_, _, timelineAssignment, absoluteTime)
	local assignment = timelineAssignment.assignment
	local newAssignment = Private.DuplicateAssignment(assignment)
	tinsert(GetCurrentAssignments(), newAssignment)

	local newAssignmentTime = utilities.Round(absoluteTime, 1)
	local relativeTime = nil
	local encounterID = GetCurrentBossDungeonEncounterID()

	if getmetatable(assignment) == CombatLogEventAssignment then
		---@cast assignment CombatLogEventAssignment
		relativeTime = ConvertAbsoluteTimeToCombatLogEventTime(
			absoluteTime,
			encounterID,
			assignment.combatLogEventSpellID,
			assignment.spellCount,
			assignment.combatLogEventType
		)
	end
	if relativeTime then
		---@cast newAssignment CombatLogEventAssignment
		newAssignment.time = utilities.Round(relativeTime, 1)
	else
		---@cast newAssignment TimedAssignment
		newAssignment.time = newAssignmentTime
	end

	UpdateAllAssignments(false, encounterID)
	HandleTimelineAssignmentClicked(nil, nil, newAssignment.uniqueID)
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, "duplicated")
	end
end

---@param timeline EPTimeline
---@param minHeight number
---@param maxHeight number
local function HandleResizeBoundsCalculated(timeline, _, minHeight, maxHeight)
	if Private.mainFrame then
		Private.mainFrame:HandleResizeBoundsCalculated(timeline.frame:GetHeight(), minHeight, maxHeight)
	end
end

local function HandleCloseButtonClicked()
	local x, y = Private.mainFrame.frame:GetSize()
	AddOn.db.profile.windowSize = { x = x, y = y }
	Private.mainFrame:Release()
end

local function HandleCollapseAllButtonClicked()
	local currentBossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
	local sortedTimelineAssignments = SortAssignments(
		GetCurrentPlan(),
		AddOn.db.profile.preferences.assignmentSortType,
		currentBossDungeonEncounterID
	)
	local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
	for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
		collapsed[timelineAssignment.assignment.assignee] = true
	end
	UpdateAllAssignments(false, currentBossDungeonEncounterID)
end

local function HandleExpandAllButtonClicked()
	local currentBossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
	local sortedTimelineAssignments = SortAssignments(
		GetCurrentPlan(),
		AddOn.db.profile.preferences.assignmentSortType,
		currentBossDungeonEncounterID
	)
	local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
	for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
		collapsed[timelineAssignment.assignment.assignee] = false
	end
	UpdateAllAssignments(false, currentBossDungeonEncounterID)
	Private.mainFrame.timeline:SetMaxAssignmentHeight()
	Private.mainFrame:DoLayout()
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, "expandAllButtonClicked")
	end
end

---@param x number
---@param y number
local function HandleMinimizeFramePointChanged(_, _, x, y)
	AddOn.db.profile.minimizeFramePosition = { x = x, y = y }
end

local function CloseDialogs()
	ClosePlanDependentWidgets()
	if Private.importEditBox then
		Private.importEditBox:Release()
	end
	if Private.exportEditBox then
		Private.exportEditBox:Release()
	end
	if Private.newPlanDialog then
		Private.newPlanDialog:Release()
	end
end

local function HandleMainFrameReleased()
	Private.mainFrame = nil
	Private.UnregisterCallback(simulationCompletedObject, "SimulationCompleted")
	if Private.IsSimulatingBoss() then
		Private:StopSimulatingBoss()
	end
	CloseDialogs()
	if Private.optionsMenu then -- Takes care of messageAnchor and progressBarAnchor
		Private.optionsMenu:Release()
	end
	if Private.tutorial then
		Private.tutorial:Release()
	end
end

function Private:CreateInterface()
	local topContainerDropdownWidth = 200
	local topContainerWidgetFontSize = 14
	local topContainerWidgetHeight = 22
	local topContainerSpacing = { 4, 4 }
	local mainFramePadding = constants.kMainFramePadding
	local mainFrameSpacing = constants.kMainFrameSpacing
	local encounterID = constants.kDefaultBossDungeonEncounterID
	local profile = self.addOn.db.profile --[[@as DefaultProfile]]
	local plans = profile.plans
	local lastOpenPlan = profile.lastOpenPlan
	local MRTLoadingOrLoaded, MRTLoaded = IsAddOnLoaded("MRT")

	if lastOpenPlan and lastOpenPlan ~= "" and plans[lastOpenPlan] then
		encounterID = plans[lastOpenPlan].dungeonEncounterID
	else
		local defaultPlanName = L["Default"]
		utilities.CreatePlan(plans, defaultPlanName, encounterID)
		profile.lastOpenPlan = defaultPlanName
		if MRTLoadingOrLoaded or MRTLoaded then
			if VMRT and VMRT.Note and VMRT.Note.Text1 then
				local maybeNew = Private:ImportPlanFromNote(defaultPlanName, encounterID, VMRT.Note.Text1)
				if maybeNew then
					encounterID = maybeNew
				end
			end
		end
	end

	local mainFrame = AceGUI:Create("EPMainFrame")
	mainFrame:SetLayout("EPVerticalLayout")
	mainFrame:SetSpacing(unpack(mainFrameSpacing))
	mainFrame:SetPadding(unpack(mainFramePadding))
	if profile.minimizeFramePosition then
		local x, y = profile.minimizeFramePosition.x, profile.minimizeFramePosition.y
		mainFrame:SetMinimizeFramePosition(x, y)
	end
	mainFrame:SetCallback("CloseButtonClicked", HandleCloseButtonClicked)
	mainFrame:SetCallback("CollapseAllButtonClicked", HandleCollapseAllButtonClicked)
	mainFrame:SetCallback("ExpandAllButtonClicked", HandleExpandAllButtonClicked)
	mainFrame:SetCallback("MinimizeFramePointChanged", HandleMinimizeFramePointChanged)
	mainFrame:SetCallback("OnRelease", HandleMainFrameReleased)
	mainFrame:SetCallback("TutorialButtonClicked", function()
		self:OpenTutorial()
	end)

	local menuButtonHeight = mainFrame.windowBar:GetHeight() - 2

	local planMenuButton = Create.DropdownMenuButton(L["Plan"], menuButtonHeight)
	planMenuButton:AddItems(Create.PlanMenuItems(), "EPDropdownItemToggle", true)
	planMenuButton:SetCallback("OnValueChanged", Handle.PlanMenuButtonClicked)
	planMenuButton:SetItemEnabled("From MRT", MRTLoadingOrLoaded or MRTLoaded)

	local bossMenuButton = Create.DropdownMenuButton(L["Boss"], menuButtonHeight)
	bossMenuButton:SetMultiselect(true)
	bossMenuButton:AddItems(Create.BossMenuItems(), "EPDropdownItemToggle")
	bossMenuButton:SetCallback("OnValueChanged", HandleBossMenuButtonClicked)

	local rosterMenuButton = Create.MenuButton(L["Roster"], menuButtonHeight, HandleRosterMenuButtonClicked)
	local preferencesMenuButton =
		Create.MenuButton(L["Preferences"], menuButtonHeight, HandlePreferencesMenuButtonClicked)

	mainFrame.menuButtonContainer:AddChildren(planMenuButton, bossMenuButton, rosterMenuButton, preferencesMenuButton)

	local instanceLabelContainer = AceGUI:Create("EPContainer")
	instanceLabelContainer:SetLayout("EPVerticalLayout")
	instanceLabelContainer:SetSpacing(0, 0)
	instanceLabelContainer:SetPadding(0, 2, 0, 2)

	local instanceLabelLabel = AceGUI:Create("EPLabel")
	instanceLabelLabel:SetFontSize(topContainerWidgetFontSize)
	instanceLabelLabel:SetHeight(topContainerWidgetHeight)
	instanceLabelLabel:SetText(L["Instance"] .. ":", 0)
	instanceLabelLabel:SetFrameWidthFromText()

	local bossLabelLabel = AceGUI:Create("EPLabel")
	bossLabelLabel:SetFontSize(topContainerWidgetFontSize)
	bossLabelLabel:SetHeight(topContainerWidgetHeight)
	bossLabelLabel:SetText(L["Boss"] .. ":", 0)
	bossLabelLabel:SetFrameWidthFromText()

	local instanceBossLabelWidth = max(instanceLabelLabel.frame:GetWidth(), bossLabelLabel.frame:GetWidth())
	instanceLabelLabel:SetWidth(instanceBossLabelWidth)
	bossLabelLabel:SetWidth(instanceBossLabelWidth)
	instanceLabelContainer:AddChildren(instanceLabelLabel, bossLabelLabel)

	local instanceBossContainer = AceGUI:Create("EPContainer")
	instanceBossContainer:SetLayout("EPVerticalLayout")
	instanceBossContainer:SetSpacing(0, 0)
	instanceBossContainer:SetPadding(0, 2, 0, 2)

	local instanceLabel = AceGUI:Create("EPLabel")
	instanceLabel:SetFontSize(topContainerWidgetFontSize)
	instanceLabel:SetWidth(topContainerDropdownWidth)
	instanceLabel:SetHeight(topContainerWidgetHeight)

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetFontSize(topContainerWidgetFontSize)
	bossLabel:SetWidth(topContainerDropdownWidth)
	bossLabel:SetHeight(topContainerWidgetHeight)
	instanceBossContainer:AddChildren(instanceLabel, bossLabel)

	local planLabel = AceGUI:Create("EPLabel")
	planLabel:SetFontSize(topContainerWidgetFontSize)
	planLabel:SetText(L["Current Plan:"], 0)
	planLabel:SetHeight(topContainerWidgetHeight)
	planLabel:SetFrameWidthFromText()

	local planDropdown = AceGUI:Create("EPDropdown")
	planDropdown:SetWidth(topContainerDropdownWidth - 10)
	planDropdown:SetAutoItemWidth(true)
	planDropdown:SetTextFontSize(topContainerWidgetFontSize)
	planDropdown:SetItemTextFontSize(topContainerWidgetFontSize)
	planDropdown:SetTextHorizontalPadding(menuButtonHorizontalPadding / 2)
	planDropdown:SetItemHorizontalPadding(menuButtonHorizontalPadding / 2)
	planDropdown:SetDropdownItemHeight(topContainerWidgetHeight)
	planDropdown:SetHeight(topContainerWidgetHeight)
	planDropdown:SetUseLineEditForDoubleClick(true)
	local maxVisiblePlanDropdownItems = 10
	planDropdown:SetMaxVisibleItems(maxVisiblePlanDropdownItems)
	planDropdown:SetCallback("OnLineEditTextSubmitted", HandlePlanNameChanged)
	planDropdown:SetCallback("OnValueChanged", HandlePlanDropdownValueChanged)

	local planContainer = AceGUI:Create("EPContainer")
	planContainer:SetLayout("EPVerticalLayout")
	planContainer:SetSpacing(0, 0)
	planContainer:SetPadding(0, 2, 0, 2)
	planContainer:AddChildren(planLabel, planDropdown)

	local reminderContainer = AceGUI:Create("EPContainer")
	reminderContainer:SetLayout("EPVerticalLayout")
	reminderContainer:SetSpacing(unpack(topContainerSpacing))

	local planReminderEnableCheckBox = AceGUI:Create("EPCheckBox")
	planReminderEnableCheckBox:SetText(L["Plan Reminders"])
	planReminderEnableCheckBox:SetHeight(topContainerWidgetHeight)
	planReminderEnableCheckBox:SetFrameWidthFromText()
	planReminderEnableCheckBox:SetCallback("OnValueChanged", HandlePlanReminderEnableCheckBoxValueChanged)
	planReminderEnableCheckBox:SetCallback("OnEnter", HandlePlanReminderCheckBoxOrButtonEnter)
	planReminderEnableCheckBox:SetCallback("OnLeave", HandlePlanReminderEnableCheckBoxOrButtonLeave)
	planReminderEnableCheckBox.fireEventsIfDisabled = true
	planReminderEnableCheckBox.button.fireEventsIfDisabled = true

	local simulateRemindersButton = AceGUI:Create("EPButton")
	simulateRemindersButton:SetText(L["Simulate Reminders"])
	simulateRemindersButton:SetWidthFromText()
	simulateRemindersButton:SetHeight(topContainerWidgetHeight)
	simulateRemindersButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	simulateRemindersButton:SetCallback("Clicked", HandleSimulateRemindersButtonClicked)
	simulateRemindersButton:SetCallback("OnEnter", HandlePlanReminderCheckBoxOrButtonEnter)
	simulateRemindersButton:SetCallback("OnLeave", HandlePlanReminderEnableCheckBoxOrButtonLeave)
	simulateRemindersButton.fireEventsIfDisabled = true

	local checkBoxWidth = max(planReminderEnableCheckBox.frame:GetWidth(), simulateRemindersButton.frame:GetWidth())
	planReminderEnableCheckBox:SetWidth(checkBoxWidth)
	simulateRemindersButton:SetWidth(checkBoxWidth)
	reminderContainer:AddChildren(planReminderEnableCheckBox, simulateRemindersButton)

	self.RegisterCallback(simulationCompletedObject, "SimulationCompleted", "HandleSimulationCompleted")

	local sendPlanAndExternalTextContainer = AceGUI:Create("EPContainer")
	sendPlanAndExternalTextContainer:SetLayout("EPVerticalLayout")
	sendPlanAndExternalTextContainer:SetSpacing(unpack(topContainerSpacing))

	local sendPlanButton = AceGUI:Create("EPButton")
	sendPlanButton:SetText(L["Send Plan to Group"])
	sendPlanButton:SetWidthFromText()
	sendPlanButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	sendPlanButton:SetHeight(topContainerWidgetHeight)
	sendPlanButton:SetCallback("Clicked", Private.SendPlanToGroup)

	local externalTextButton = AceGUI:Create("EPButton")
	externalTextButton:SetText(L["External Text"])
	externalTextButton:SetWidthFromText()
	externalTextButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	externalTextButton:SetHeight(topContainerWidgetHeight)
	externalTextButton:SetCallback("Clicked", HandleExternalTextButtonClicked)

	local buttonWidth = max(sendPlanButton.frame:GetWidth(), externalTextButton.frame:GetWidth())
	sendPlanButton:SetWidth(buttonWidth)
	externalTextButton:SetWidth(buttonWidth)
	sendPlanAndExternalTextContainer:AddChildren(sendPlanButton, externalTextButton)

	local primaryPlanCheckBox = AceGUI:Create("EPCheckBox")
	primaryPlanCheckBox:SetText(L["Designated External Plan"])
	primaryPlanCheckBox:SetHeight(topContainerWidgetHeight)
	primaryPlanCheckBox:SetFrameWidthFromText()
	primaryPlanCheckBox:SetCallback("OnValueChanged", HandlePrimaryPlanCheckBoxValueChanged)
	primaryPlanCheckBox:SetCallback("OnEnter", HandlePrimaryPlanCheckBoxEnter)
	primaryPlanCheckBox:SetCallback("OnLeave", HandlePrimaryPlanCheckBoxLeave)
	primaryPlanCheckBox.fireEventsIfDisabled = true
	primaryPlanCheckBox.button.fireEventsIfDisabled = true

	local reminderAndSendPlanButtonContainer = AceGUI:Create("EPContainer")
	reminderAndSendPlanButtonContainer:SetLayout("EPHorizontalLayout")
	reminderAndSendPlanButtonContainer:SetFullHeight(true)
	reminderAndSendPlanButtonContainer:SetSelfAlignment("topRight")
	reminderAndSendPlanButtonContainer:SetSpacing(unpack(topContainerSpacing))
	reminderAndSendPlanButtonContainer:AddChildren(
		primaryPlanCheckBox,
		reminderContainer,
		sendPlanAndExternalTextContainer
	)

	local topContainer = AceGUI:Create("EPContainer")
	topContainer:SetLayout("EPHorizontalLayout")
	topContainer:SetFullWidth(true)
	topContainer:AddChildren(
		planContainer,
		instanceLabelContainer,
		instanceBossContainer,
		reminderAndSendPlanButtonContainer
	)
	topContainer:SetPadding(10, 10, 10, 10)
	local topContainerBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	}
	topContainer:SetBackdrop(topContainerBackdrop, { 0, 0, 0, 0 }, { 0.25, 0.25, 0.25, 1 })

	local timeline = AceGUI:Create("EPTimeline")
	timeline:SetPreferences(profile.preferences)
	timeline.CalculateAssignmentTimeFromStart = HandleCalculateAssignmentTimeFromStart
	timeline.GetMinimumCombatLogEventTime = HandleGetMinimumCombatLogEventTime
	timeline.ComputeChargeStates = interfaceUpdater.ComputeChargeStates
	timeline:SetFullWidth(true)
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)
	timeline:SetCallback("DuplicateAssignmentStart", HandleDuplicateAssignmentStart)
	timeline:SetCallback("DuplicateAssignmentEnd", HandleDuplicateAssignmentEnd)
	timeline:SetCallback("ResizeBoundsCalculated", HandleResizeBoundsCalculated)
	local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
	addAssigneeDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeDropdown:SetText(addAssigneeText)
	local assigneeItems = CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster())
	addAssigneeDropdown:AddItems(assigneeItems, "EPDropdownItemToggle", true)

	mainFrame.instanceLabel = instanceLabel
	mainFrame.bossLabel = bossLabel
	mainFrame.bossMenuButton = bossMenuButton
	mainFrame.planDropdown = planDropdown
	mainFrame.planReminderEnableCheckBox = planReminderEnableCheckBox
	mainFrame.primaryPlanCheckBox = primaryPlanCheckBox
	mainFrame.timeline = timeline
	mainFrame.sendPlanButton = sendPlanButton
	mainFrame.simulateRemindersButton = simulateRemindersButton
	mainFrame.externalTextButton = externalTextButton
	self.mainFrame = mainFrame

	self.HandleSendPlanButtonConstructed()
	interfaceUpdater.RestoreMessageLog()
	mainFrame:AddChildren(topContainer, timeline)
	mainFrame.menuButtonContainer:DoLayout()

	interfaceUpdater.RepopulatePlanWidgets()
	UpdateBoss(encounterID, true)
	UpdateRosterFromAssignments(GetCurrentAssignments(), GetCurrentRoster())
	UpdateRosterDataFromGroup(GetCurrentRoster())
	UpdateRosterDataFromGroup(profile.sharedRoster)
	UpdateAllAssignments(true, encounterID, true)
	if profile.windowSize then
		local minWidth, minHeight, _, _ = mainFrame.frame:GetResizeBounds()
		profile.windowSize.x = max(profile.windowSize.x, minWidth)
		profile.windowSize.y = max(profile.windowSize.y, minHeight)
		mainFrame:SetWidth(profile.windowSize.x)
		mainFrame:SetHeight(profile.windowSize.y)
	end
	mainFrame.frame:SetPoint("CENTER")
	local x, y = mainFrame.frame:GetLeft(), mainFrame.frame:GetTop()
	mainFrame.frame:ClearAllPoints()
	mainFrame.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
	mainFrame:DoLayout()
	timeline:UpdateTimeline()

	C_Timer.After(0, function() -- Otherwise height will not be properly set and can clip messages
		self.mainFrame.statusBar:OnWidthSet()
	end)

	if not self.addOn.db.global.tutorial.skipped and not self.addOn.db.global.tutorial.completed then
		self:OpenTutorial()
	end
end

function Private:CloseDialogs()
	CloseDialogs()
end
