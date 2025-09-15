local AddOnName, Namespace = ...

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
local AddAssignmentToPlan = utilities.AddAssignmentToPlan
local ChangePlanBoss = utilities.ChangePlanBoss
local CreateAssigneeDropdownItems = utilities.CreateAssigneeDropdownItems
local CreateAssignmentTypeWithRosterDropdownItems = utilities.CreateAssignmentTypeWithRosterDropdownItems
local CreateUniquePlanName = utilities.CreateUniquePlanName
local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID
local FormatTime = utilities.FormatTime
local GetCurrentAssignments = utilities.GetCurrentAssignments
local GetCurrentBoss = utilities.GetCurrentBoss
local GetCurrentBossDungeonEncounterID = utilities.GetCurrentBossDungeonEncounterID
local GetCurrentDifficulty = utilities.GetCurrentDifficulty
local GetCurrentPlan = utilities.GetCurrentPlan
local GetCurrentRoster = utilities.GetCurrentRoster
local ImportGroupIntoRoster = utilities.ImportGroupIntoRoster
local ParseTime = Private.utilities.ParseTime
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

local DifficultyType = Private.classes.DifficultyType

local abs = math.abs
local assert = assert
local AceGUI = LibStub("AceGUI-3.0")
local Clamp = Clamp
local format = string.format
local getmetatable = getmetatable
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local min, max = math.min, math.max
local pairs = pairs
local tinsert = table.insert
local tonumber = tonumber
local tremove = table.remove
local unpack = unpack
local wipe = table.wipe

local s = {
	Creator = {},
	Handler = {},
	SimulationCompletedObject = {
		HandleSimulationCompleted = function()
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
		end,
	},
}

local k = {
	AddAssigneeText = utilities.AddIconBeforeText(constants.textures.kAdd, L["Add Assignee"]),
	GenericWhite = constants.textures.kGenericWhite,
	MaxVisibleDropdownItems = 10,
	TopContainerDropdownWidth = 200,
	TopContainerWidgetFontSize = 14,
	PlanMenuItemValues = {
		NewPlan = {},
		Templates = {
			Apply = {},
			Create = {},
			Delete = {},
		},
		DuplicatePlan = {},
		Import = {
			FromMRT = {
				Create = {},
				Overwrite = {},
			},
			FromString = {},
		},
		ExportPlan = {},
		DeletePlan = {},
	},
}

do -- Plan Menu Items
	local AddIconBeforeText = utilities.AddIconBeforeText

	local planMenuItems = nil

	---@return table<integer, DropdownItemData>
	function s.Creator.PlanMenuItems()
		if not planMenuItems then
			planMenuItems = {
				{
					itemValue = k.PlanMenuItemValues.NewPlan,
					text = AddIconBeforeText(constants.textures.kAdd, L["New Plan"]),
				},
				{
					itemValue = k.PlanMenuItemValues.Templates,
					text = AddIconBeforeText(constants.textures.kTemplate, L["Templates"]),
					dropdownItemMenuData = {
						{
							itemValue = k.PlanMenuItemValues.Templates.Create,
							text = L["Create Template"],
						},
						{
							itemValue = k.PlanMenuItemValues.Templates.Apply,
							text = L["Apply Template"],
							dropdownItemMenuData = {},
						},
						{
							itemValue = k.PlanMenuItemValues.Templates.Delete,
							text = L["Delete Template"],
							dropdownItemMenuData = {},
						},
					},
				},
				{
					itemValue = k.PlanMenuItemValues.DuplicatePlan,
					text = AddIconBeforeText(constants.textures.kDuplicate, L["Duplicate Plan"]),
				},
				{
					itemValue = k.PlanMenuItemValues.Import,
					text = AddIconBeforeText(constants.textures.kImport, L["Import"]),
					dropdownItemMenuData = {
						{
							itemValue = k.PlanMenuItemValues.Import.FromMRT,
							text = L["From"] .. " " .. "MRT",
							dropdownItemMenuData = {
								{
									itemValue = k.PlanMenuItemValues.Import.FromMRT.Create,
									text = L["Import As New Plan"],
								},
								{
									itemValue = k.PlanMenuItemValues.Import.FromMRT.Overwrite,
									text = L["Overwrite Current Plan"],
								},
							},
						},
						{
							itemValue = k.PlanMenuItemValues.Import.FromString,
							text = L["From Text"],
						},
					},
				},
				{
					itemValue = k.PlanMenuItemValues.ExportPlan,
					text = AddIconBeforeText(constants.textures.kExport, L["Export Current Plan"]),
				},
				{
					itemValue = k.PlanMenuItemValues.DeletePlan,
					text = AddIconBeforeText(constants.textures.kClose, L["Delete Current Plan"]),
				},
			}
		end
		return planMenuItems
	end
end

do -- Boss Menu Items
	local bossMenuItems = nil

	---@return table<integer, DropdownItemData>
	function s.Creator.BossMenuItems()
		if not bossMenuItems then
			bossMenuItems = {
				{
					itemValue = "Change Boss",
					text = L["Change Boss"],
					dropdownItemMenuData = utilities.GetOrCreateBossDropdownItemsWithDifficulty(),
				},
				{
					itemValue = "Edit Phase Timings",
					text = L["Edit Phase Timings"],
					notSelectable = true,
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
	if Private.newTemplateDialog then
		Private.newTemplateDialog:Release()
	end
	interfaceUpdater.RemoveMessageBoxes(true)
end

do -- Menu Button
	local autoOpenNextMenuButtonEntered = nil
	local menuButtonToClose = nil
	local kMenuButtonFontSize = 16
	local kMenuButtonHorizontalPadding = 8

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
	function s.Creator.DropdownMenuButton(text, height)
		local menuButton = AceGUI:Create("EPDropdown")
		menuButton:SetTextCentered(true)
		menuButton:SetAutoItemWidth(true)
		menuButton:SetText(text)
		menuButton:SetTextFontSize(kMenuButtonFontSize)
		menuButton:SetWidth(menuButton.text:GetStringWidth() + 2 * kMenuButtonHorizontalPadding)
		menuButton:SetHeight(height)
		menuButton:SetButtonVisibility(false)
		menuButton:SetShowHighlight(true)
		menuButton:SetMaxVisibleItems(k.MaxVisibleDropdownItems)
		menuButton:SetCallback("OnEnter", HandleMenuButtonEntered)
		menuButton:SetCallback("OnOpened", HandleMenuButtonOpened)
		menuButton:SetCallback("OnClosed", HandleMenuButtonClosed)
		return menuButton
	end

	local menuButtonBackdrop = {
		bgFile = k.GenericWhite,
		edgeFile = k.GenericWhite,
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
	function s.Creator.MenuButton(text, height, clickedCallback)
		local menuButton = AceGUI:Create("EPButton")
		menuButton:SetText(text)
		menuButton:SetFontSize(kMenuButtonFontSize)
		local width = menuButton.button:GetFontString():GetStringWidth() + 2 * kMenuButtonHorizontalPadding
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
		UpdateAllAssignments(true)

		local assignmentEditor = Private.assignmentEditor
		if assignmentEditor then
			local assigneeTypeDropdown = assignmentEditor.assigneeTypeDropdown
			local targetDropdown = assignmentEditor.targetDropdown
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

			local assignmentID = assignmentEditor:GetAssignmentID()
			if assignmentID then
				local assignment = FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
				if assignment then
					assignmentEditor:RepopulateSpellDropdown(
						assignment.assignee,
						roster,
						assignment.spellID,
						AddOn.db.profile.favoritedSpellAssignments
					)
					assignmentEditor:HandleRosterChanged()
				end
			end
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
		local plan = GetCurrentPlan()
		local removedAssignmentCount, removedTemplateCount = utilities.RemoveAssignmentFromPlan(plan, assignmentID)

		local lowerAssignment, lowerTemplate
		if removedAssignmentCount == 1 then
			lowerAssignment = L["Assignment"]:lower()
		else
			lowerAssignment = L["assignments"]
		end
		if removedTemplateCount == 1 then
			lowerTemplate = L["Template"]:lower()
		else
			lowerTemplate = L["Templates"]:lower()
		end
		interfaceUpdater.LogMessage(
			format(
				"%s %d %s, %d %s.",
				L["Removed"],
				removedAssignmentCount,
				lowerAssignment,
				removedTemplateCount,
				lowerTemplate
			)
		)
		UpdateAllAssignments(false)
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "assignmentEditorDeleteButtonClicked")
		end
	end

	local ChangeAssignmentType = utilities.ChangeAssignmentType
	local ClampSpellCount = bossUtilities.ClampSpellCount
	local IsValidSpellCount = bossUtilities.IsValidSpellCount
	local UpdateAssignmentBossPhase = utilities.UpdateAssignmentBossPhase

	local AssignmentEditorDataType = Private.classes.AssignmentEditorDataType

	---@param assignmentEditor EPAssignmentEditor
	---@param dataType AssignmentEditorDataType
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
		local difficulty = GetCurrentDifficulty()
		local updateFields = false
		local updateAssignments = false

		if dataType == AssignmentEditorDataType.AssignmentType then
			---@cast assignment CombatLogEventAssignment|TimedAssignment
			ChangeAssignmentType(assignment, dungeonEncounterID, value, difficulty, GetCurrentPlan().ID)
			updateFields = true
			updateAssignments = true
		elseif dataType == AssignmentEditorDataType.CombatLogEventSpellID then
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local spellID = tonumber(value)
				if spellID then
					utilities.ChangeAssignmentCombatLogEventSpellID(assignment, dungeonEncounterID, spellID, difficulty)
				end
				updateFields = true
			end
		elseif dataType == AssignmentEditorDataType.CombatLogEventSpellCount then
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local spellCount = tonumber(value)
				if spellCount then
					local spellID = assignment.combatLogEventSpellID
					if IsValidSpellCount(dungeonEncounterID, spellID, spellCount, nil, difficulty) then
						assignment.spellCount = spellCount
						UpdateAssignmentBossPhase(assignment, dungeonEncounterID, difficulty)
					else
						local clamped = ClampSpellCount(dungeonEncounterID, spellID, spellCount, difficulty)
						if clamped then
							assignment.spellCount = clamped
						end
					end
				end
				updateFields = true
			end
		elseif dataType == AssignmentEditorDataType.SpellAssignment then
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
		elseif dataType == AssignmentEditorDataType.AssigneeType then
			assignment.assignee = value
			updateFields = true
			updateAssignments = true
		elseif dataType == AssignmentEditorDataType.Time then
			local timeMinutes = assignmentEditor.timeMinuteLineEdit:GetText()
			local timeSeconds = assignmentEditor.timeSecondLineEdit:GetText()
			local maxTime = Private.mainFrame.timeline.GetTotalTimelineDuration()
			local newTime = ParseTime(timeMinutes, timeSeconds, 0.0, maxTime)
			if not newTime then
				newTime = assignment.time
			end
			if getmetatable(assignment) == CombatLogEventAssignment or getmetatable(assignment) == TimedAssignment then
				---@cast assignment CombatLogEventAssignment|TimedAssignment
				assignment.time = newTime
			end
			local minutes, seconds = FormatTime(newTime)
			assignmentEditor.timeMinuteLineEdit:SetText(minutes)
			assignmentEditor.timeSecondLineEdit:SetText(seconds)
			updateAssignments = true
		elseif dataType == AssignmentEditorDataType.OptionalText then
			assignment.text = value
			if assignment.text:len() > 0 and assignment.spellID == constants.kInvalidAssignmentSpellID then
				assignment.spellID = constants.kTextAssignmentSpellID
				updateAssignments = true
			elseif assignment.text:len() == 0 and assignment.spellID == constants.kTextAssignmentSpellID then
				assignment.spellID = constants.kInvalidAssignmentSpellID
				updateAssignments = true
			end
			updateFields = true
		elseif dataType == AssignmentEditorDataType.Target then
			assignment.targetName = value
			updateFields = true
		end

		interfaceUpdater.UpdateFromAssignment(
			dungeonEncounterID,
			difficulty,
			assignment,
			updateFields,
			true,
			updateAssignments,
			true
		)
		if
			dataType == AssignmentEditorDataType.SpellAssignment
			or dataType == AssignmentEditorDataType.OptionalText
			or dataType == AssignmentEditorDataType.Time
			or dataType == AssignmentEditorDataType.AssignmentType
		then
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "assignmentEditorDataChanged")
			end
		end
	end

	local CreateAbilityDropdownItemData = utilities.CreateAbilityDropdownItemData
	local GetBossAbilityIconAndLabel = bossUtilities.GetBossAbilityIconAndLabel
	local GetBossAbilities = bossUtilities.GetBossAbilities
	local GetSortedBossAbilityIDs = bossUtilities.GetSortedBossAbilityIDs

	function Private.CreateAssignmentEditor()
		local assignmentEditor = AceGUI:Create("EPAssignmentEditor")
		assignmentEditor.FormatTime = FormatTime
		assignmentEditor.frame:SetParent(Private.mainFrame.frame)
		assignmentEditor.frame:SetFrameLevel(kAssignmentEditorFrameLevel)
		assignmentEditor.frame:SetPoint("TOPRIGHT", Private.mainFrame.frame, "TOPLEFT", -2, 0)
		assignmentEditor:SetLayout("EPVerticalLayout")
		assignmentEditor:SetCallback("OnRelease", function()
			if Private.mainFrame then
				local timeline = Private.mainFrame.timeline
				if timeline then
					timeline.ClearSelectedAssignments()
					timeline.ClearSelectedBossAbilities()
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
			UpdateAllAssignments(false)
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
			data.customTexture = constants.textures.kClose
			data.customTextureVertexColor = { 1, 1, 1, 1 }
		end
		assignmentEditor.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu("Favorite", favoritedItems)

		local dropdownItems = {}
		local itemsToDisable = {}
		local boss = GetCurrentBoss()

		if boss then
			local difficulty = GetCurrentDifficulty()
			local bossAbilities = GetBossAbilities(boss, difficulty)
			for _, abilityID in ipairs(GetSortedBossAbilityIDs(boss, difficulty)) do
				local icon, text = GetBossAbilityIconAndLabel(boss, abilityID, difficulty)
				tinsert(dropdownItems, CreateAbilityDropdownItemData(abilityID, icon, text))
				if #bossAbilities[abilityID].allowedCombatLogEventTypes == 0 then
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
	local GetBossPhases = bossUtilities.GetBossPhases
	local GetTotalDurations = bossUtilities.GetTotalDurations
	local SetPhaseDuration = bossUtilities.SetPhaseDuration
	local SetPhaseDurations = bossUtilities.SetPhaseDurations
	local SetPhaseCount = bossUtilities.SetPhaseCount

	local kPhaseEditorFrameLevel = constants.frameLevels.kPhaseEditorFrameLevel
	local kMaxBossDuration = constants.kMaxBossDuration
	local kMinBossPhaseDuration = constants.kMinBossPhaseDuration

	local function UpdateTotalTime()
		if Private.phaseLengthEditor then
			local totalCustomTime, totalDefaultTime =
				GetTotalDurations(GetCurrentBossDungeonEncounterID(), GetCurrentDifficulty())
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
			local difficulty = GetCurrentDifficulty()
			local phases = GetBossPhases(boss, difficulty)

			local previousDuration = phases[phaseIndex].duration
			if boss.treatAsSinglePhase then
				local totalCustomTime, _ = GetTotalDurations(bossDungeonEncounterID, difficulty)
				previousDuration = totalCustomTime
			end

			local formatAndReturn = false
			local minPhaseDuration = kMinBossPhaseDuration
			if phases[phaseIndex] and phases[phaseIndex].minDuration then
				minPhaseDuration = phases[phaseIndex].minDuration
			end
			local maxPhaseDuration =
				CalculateMaxPhaseDuration(bossDungeonEncounterID, phaseIndex, kMaxBossDuration, difficulty)
			if maxPhaseDuration and boss.treatAsSinglePhase then
				maxPhaseDuration = kMaxBossDuration
			end
			local newDuration =
				ParseTime(minLineEdit:GetText(), secLineEdit:GetText(), minPhaseDuration, maxPhaseDuration)
			if not newDuration then
				newDuration = previousDuration
			end
			if abs(newDuration - previousDuration) < 0.01 then
				formatAndReturn = true
			end

			local minutes, seconds = FormatTime(newDuration)
			minLineEdit:SetText(minutes)
			secLineEdit:SetText(seconds)

			if not formatAndReturn then
				local customPhaseDurations = GetCurrentPlan().customPhaseDurations
				if boss.treatAsSinglePhase then
					local cumulativePhaseTime = 0.0
					for index, phase in ipairs(phases) do
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
						customPhaseDurations[#phases] = (customPhaseDurations[#phases] or 0)
							+ newDuration
							- cumulativePhaseTime
					end
					SetPhaseDurations(bossDungeonEncounterID, customPhaseDurations, difficulty)
				else
					SetPhaseDuration(bossDungeonEncounterID, phaseIndex, newDuration, difficulty)
					customPhaseDurations[phaseIndex] = newDuration
				end

				UpdateBoss(bossDungeonEncounterID, true)
				UpdateAllAssignments(false)
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
			local difficulty = GetCurrentDifficulty()
			local phases = GetBossPhases(boss, difficulty)
			local previousCount = phases[phaseIndex].count
			local newCount = tonumber(text)
			if newCount then
				newCount = floor(newCount)
			else
				widget:SetText(tostring(previousCount))
				return
			end
			local validatedPhaseCounts =
				SetPhaseCount(bossDungeonEncounterID, phaseIndex, newCount, kMaxBossDuration, difficulty)
			local customPhaseCounts = GetCurrentPlan().customPhaseCounts
			for index, count in ipairs(validatedPhaseCounts) do
				customPhaseCounts[index] = count
			end
			Private.phaseLengthEditor:SetPhaseCounts(validatedPhaseCounts)
			UpdateBoss(bossDungeonEncounterID, true)
			UpdateAllAssignments(false)
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
				local currentPlan = GetCurrentPlan()
				wipe(currentPlan.customPhaseDurations)
				wipe(currentPlan.customPhaseCounts)
				local bossDungeonEncounterID = currentPlan.dungeonEncounterID
				UpdateBoss(bossDungeonEncounterID, true)
				UpdateAllAssignments(false)
				UpdateTotalTime()
			end)
			phaseLengthEditor:SetCallback("DataChanged", HandlePhaseLengthEditorDataChanged)
			phaseLengthEditor:SetCallback("CountChanged", HandlePhaseCountChanged)

			local boss = GetCurrentBoss()
			if boss then
				local difficulty = GetCurrentDifficulty()
				local totalCustomTime, totalDefaultTime =
					GetTotalDurations(GetCurrentBossDungeonEncounterID(), difficulty)
				local phases = GetBossPhases(boss, difficulty)
				if boss.treatAsSinglePhase then
					local phaseData = {}
					tinsert(phaseData, {
						name = L["Phase"] .. " 1",
						defaultDuration = totalDefaultTime,
						fixedDuration = phases[1].fixedDuration,
						duration = totalCustomTime,
						count = 1,
						defaultCount = 1,
						repeatAfter = nil,
					})
					phaseLengthEditor:AddEntries(phaseData)
				else
					phaseLengthEditor:AddEntries(phases)
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
---@param newDifficulty DifficultyType
local function HandleConvertAssignments(plan, newBossDungeonEncounterID, newDifficulty)
	local previousBossDungeonEncounterID = plan.dungeonEncounterID
	local previousBoss = GetBoss(previousBossDungeonEncounterID)
	local newBoss = GetBoss(newBossDungeonEncounterID)
	local previousDifficulty = plan.difficulty

	if previousBoss and newBoss then
		ClosePlanDependentWidgets()
		local plans = AddOn.db.profile.plans
		local newPlan = utilities.DuplicatePlan(plans, plan.name, plan.name)
		AddOn.db.profile.lastOpenPlan = newPlan.name

		ConvertAssignmentsToNewBoss(newPlan, previousBoss, newBoss, previousDifficulty, newDifficulty)
		ChangePlanBoss(AddOn.db.profile.plans, newPlan.name, newBossDungeonEncounterID, newDifficulty)

		AddPlanToDropdown(newPlan, true)
		UpdateBoss(newBossDungeonEncounterID, true)
		UpdateAllAssignments(false)
	end
end

---@param value number|string
---@param newDifficulty DifficultyType
local function HandleChangeBossDropdownValueChanged(value, newDifficulty)
	local newBossDungeonEncounterID = tonumber(value)
	if newBossDungeonEncounterID then
		local plan = GetCurrentPlan()
		local messageBoxData = {
			ID = Private.GenerateUniqueID(),
			widgetType = "EPMessageBox",
			isCommunication = true,
			title = L["Change Boss"],
			message = format(
				"%s %s",
				L["The current plan will be duplicated, and assignments will be converted based on the phase in which they occur for the new boss."],
				L["The conversion uses the same rules as when adding a new assignment by clicking the timeline."]
			),
			acceptButtonText = L["Okay"],
			acceptButtonCallback = function()
				HandleConvertAssignments(plan, newBossDungeonEncounterID, newDifficulty)
			end,
			rejectButtonText = L["Cancel"],
			rejectButtonCallback = nil,
			buttonsToAdd = {},
		} --[[@as MessageBoxData]]
		CreateMessageBox(messageBoxData, false)
	end
end

---@param dropdown EPDropdown
---@param value number|string
---@param selected boolean
local function HandleActiveBossAbilitiesChanged(dropdown, value, selected)
	if type(value) == "number" then
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		local activeBossAbilities = utilities.GetActiveBossAbilities(bossDungeonEncounterID, GetCurrentDifficulty())
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
			UpdateBoss(bossDungeonEncounterID, false)
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

---@param dropdown EPDropdown
---@param value any
local function HandlePlanDropdownValueChanged(dropdown, _, value)
	if AddOn.db.profile.plans[value] then
		dropdown:SetText(value)
		ClosePlanDependentWidgets()
		AddOn.db.profile.lastOpenPlan = value
		local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
		local bossDungeonEncounterID = plan.dungeonEncounterID

		UpdateBoss(bossDungeonEncounterID, true)
		UpdateAllAssignments(true)
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
				dropdown:SetText(AddOn.db.profile.lastOpenPlan)
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
	local newPlanName = text
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
	local boss = GetBoss(currentPlan.dungeonEncounterID)
	if revert then
		lineEdit:SetText(currentPlanName)
	else
		AddOn.db.profile.plans[newPlanName] = currentPlan
		AddOn.db.profile.plans[currentPlanName] = nil
		AddOn.db.profile.plans[newPlanName].name = newPlanName
		AddOn.db.profile.lastOpenPlan = newPlanName
		local planDropdown = Private.mainFrame.planDropdown
		if planDropdown then
			local newDropdownItemText = utilities.FormatPlanText(newPlanName, boss.icon, currentPlan.difficulty)
			planDropdown:EditItemValueAndText(currentPlanName, newPlanName, newDropdownItemText)
			planDropdown:Sort(
				AddOn.db.profile.plans[newPlanName].instanceID,
				nil,
				utilities.CreateDropdownItemPlanSorter(boss)
			)
			planDropdown:SetText(newPlanName)
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
		interfaceUpdater.UpdateFromAssignment(
			GetCurrentBossDungeonEncounterID(),
			GetCurrentDifficulty(),
			assignment,
			true,
			true,
			false,
			true
		)
		if Private.activeTutorialCallbackName and widget then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, timeDifference)
		end
	end
end

local function HandleAddAssigneeRowDropdownValueChanged(dropdown, _, value)
	if value == k.AddAssigneeText then
		return
	end

	local plan = GetCurrentPlan()
	local assignments = plan.assignments
	for _, assignment in ipairs(assignments) do
		if assignment.assignee == value then
			dropdown:SetText(k.AddAssigneeText)
			return
		end
	end

	local assignment = TimedAssignment:New(nil, GetCurrentPlan().ID)
	assignment.assignee = value
	if #assignments == 0 then
		local timelineRows = AddOn.db.profile.preferences.timelineRows
		timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)
	end

	AddAssignmentToPlan(plan, assignment)
	UpdateAllAssignments(false)
	HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
	dropdown:SetText(k.AddAssigneeText)
	if Private.activeTutorialCallbackName then
		Private.callbacks:Fire(Private.activeTutorialCallbackName, "assigneeAdded")
	end
end

---@param assignee string
---@param spellID integer|nil
---@param time number
local function HandleCreateNewAssignment(_, _, assignee, spellID, time)
	local plan = GetCurrentPlan()
	local encounterID = plan.dungeonEncounterID
	local assignment = utilities.CreateNewAssignment(encounterID, time, assignee, spellID, plan.difficulty, plan.ID)
	if assignment then
		AddAssignmentToPlan(plan, assignment)
		UpdateAllAssignments(false)
		HandleTimelineAssignmentClicked(nil, nil, assignment.uniqueID)
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "added")
		end
	end
end

---@param templates table<integer, PlanTemplate>
function Private.RepopulateTemplates(templates)
	if Private.mainFrame then
		local planMenuButton = Private.mainFrame.planMenuButton
		if planMenuButton then
			local templateDropdownMenuItems = {}
			for _, template in ipairs(templates) do
				tinsert(templateDropdownMenuItems, { itemValue = template.name, text = template.name })
			end
			sort(templateDropdownMenuItems, function(a, b)
				return a.text < b.text
			end)
			planMenuButton:ClearExistingDropdownItemMenu(k.PlanMenuItemValues.Templates.Apply)
			planMenuButton:ClearExistingDropdownItemMenu(k.PlanMenuItemValues.Templates.Delete)
			planMenuButton:AddItemsToExistingDropdownItemMenu(
				k.PlanMenuItemValues.Templates.Apply,
				templateDropdownMenuItems
			)
			planMenuButton:AddItemsToExistingDropdownItemMenu(
				k.PlanMenuItemValues.Templates.Delete,
				templateDropdownMenuItems
			)
		end
	end
end

do -- Plan Menu Button s.Handlers
	local GetBossName = bossUtilities.GetBossName

	local kExportEditBoxFrameLevel = constants.frameLevels.kExportEditBoxFrameLevel
	local kImportEditBoxFrameLevel = constants.frameLevels.kImportEditBoxFrameLevel
	local kNewPlanDialogFrameLevel = constants.frameLevels.kNewPlanDialogFrameLevel
	local kNewTemplateDialogFrameLevel = constants.frameLevels.kNewTemplateDialogFrameLevel

	local TextImportType = Private.classes.TextImportType

	---@param importType TextImportType
	---@param newOrExistingPlanName string
	local function HandleImportPlanFromString(importType, newOrExistingPlanName)
		ClosePlanDependentWidgets()
		local text = Private.importEditBox:GetText()
		Private.importEditBox:Release()
		local bossDungeonEncounterID = GetCurrentBossDungeonEncounterID()
		if importType == TextImportType.IntoCurrent then
			Private:ImportTextIntoPlan(newOrExistingPlanName, text)
		elseif importType == TextImportType.OverwriteCurrent or importType == TextImportType.CreateNew then
			bossDungeonEncounterID = Private:ImportPlanFromNote(newOrExistingPlanName, bossDungeonEncounterID, text)
				or bossDungeonEncounterID
		end
		AddOn.db.profile.lastOpenPlan = newOrExistingPlanName
		local newPlan = AddOn.db.profile.plans[newOrExistingPlanName]
		AddPlanToDropdown(newPlan, true)
		interfaceUpdater.RepopulatePlanWidgets()
		UpdateBoss(bossDungeonEncounterID, true)
		UpdateAllAssignments(true)
		Private.callbacks:Fire("PlanChanged")
	end

	local function CreateImportEditBox()
		if not Private.importEditBox then
			local importEditBox = AceGUI:Create("EPEditBox")
			importEditBox.frame:SetParent(Private.mainFrame.frame)
			importEditBox.frame:SetFrameLevel(kImportEditBoxFrameLevel)
			importEditBox.frame:SetPoint("CENTER")
			importEditBox:SetTitle(L["Import From Text"])
			importEditBox:ShowOkayButton(true, L["Import"])
			importEditBox.okayButton:SetEnabled(true)
			importEditBox:SetCallback("OnRelease", function()
				Private.importEditBox = nil
			end)
			importEditBox:SetCallback("CloseButtonClicked", function()
				AceGUI:Release(Private.importEditBox)
			end)
			importEditBox:SetCallback("ValidatePlanName", function(widget, _, planName)
				planName = planName:trim()
				if planName == "" or AddOn.db.profile.plans[planName] then
					widget.okayButton:SetEnabled(false)
				else
					widget.okayButton:SetEnabled(true)
				end
			end)
			importEditBox:ShowRadioButtonGroup(
				true,
				{ L["Import Into Current Plan"], L["Overwrite Current Plan"], L["Create New Plan"] },
				L["New Plan Name:"],
				CreateUniquePlanName(AddOn.db.profile.plans, GetCurrentBoss().name)
			)
			importEditBox:SetCallback("OkayButtonClicked", function(widget)
				local container = Private.importEditBox.radioButtonGroup
				if container then
					for index, child in ipairs(container.children) do
						if child:IsToggled() then
							if index == TextImportType.CreateNew then
								local planName = Private.importEditBox.lineEdit:GetText()
								planName = planName:trim()
								if planName == "" or AddOn.db.profile.plans[planName] ~= nil then
									widget.okayButton:SetEnabled(false)
								else
									HandleImportPlanFromString(TextImportType.CreateNew, planName)
								end
							else
								HandleImportPlanFromString(index, AddOn.db.profile.lastOpenPlan)
							end
							break
						end
					end
				end
			end)
			importEditBox:SetFocusAndCursorPosition(0)
			Private.importEditBox = importEditBox
		end
	end

	local function HandleDuplicatePlanButtonClicked()
		ClosePlanDependentWidgets()
		local plans = AddOn.db.profile.plans
		local planToDuplicateName = AddOn.db.profile.lastOpenPlan

		local newPlan = utilities.DuplicatePlan(plans, planToDuplicateName, planToDuplicateName)
		AddOn.db.profile.lastOpenPlan = newPlan.name

		UpdateAllAssignments(true)
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
		UpdateAllAssignments(true)
		Private.callbacks:Fire("PlanChanged")
	end

	---@param importType table
	local function ImportPlan(importType)
		if not Private.importEditBox then
			if
				importType == k.PlanMenuItemValues.Import.FromMRT.Create
				or importType == k.PlanMenuItemValues.Import.FromMRT.Overwrite
			then
				if VMRT and VMRT.Note and VMRT.Note.Text1 then
					local createNew = importType == k.PlanMenuItemValues.Import.FromMRT.Create
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
					UpdateAllAssignments(true)
					Private.callbacks:Fire("PlanChanged")
				end
			elseif importType == k.PlanMenuItemValues.Import.FromString then
				CreateImportEditBox()
			end
		end
	end

	local function HandleExportPlanButtonClicked()
		if not Private.exportEditBox then
			local exportEditBox = AceGUI:Create("EPEditBox")
			exportEditBox.frame:SetParent(Private.mainFrame.frame)
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
		local profile = AddOn.db.profile
		local cooldownAndChargeOverrides = profile.cooldownAndChargeOverrides
		local onlyShowMe = profile.preferences.timelineRows.onlyShowMe
		local text = Private:ExportPlanToNote(GetCurrentPlan(), cooldownAndChargeOverrides, onlyShowMe)
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
			newPlanDialog:SetCallback("BossChanged", function(widget, _, currentBossDungeonEncounterID)
				---@cast widget EPNewPlanDialog
				local boss = GetBoss(currentBossDungeonEncounterID)
				if boss then
					local hasMythic = boss.phases ~= nil
					local hasHeroic = boss.phasesHeroic ~= nil
					widget.difficultyDropdown:SetEnabled(hasMythic and hasHeroic)
					if not hasMythic then
						if widget.difficultyDropdown:GetValue() ~= DifficultyType.Heroic then
							widget.difficultyDropdown:SetValue(DifficultyType.Heroic)
						end
					end
					if not hasHeroic then
						if widget.difficultyDropdown:GetValue() ~= DifficultyType.Mythic then
							widget.difficultyDropdown:SetValue(DifficultyType.Mythic)
						end
					end
					if not widget.planNameManuallyChanged then
						local newBossName = boss.name
						widget:SetPlanNameLineEditText(CreateUniquePlanName(AddOn.db.profile.plans, newBossName))
						widget:SetCreateButtonEnabled(true)
						if Private.activeTutorialCallbackName then
							Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogValidate")
						end
					end
				end
			end)
			newPlanDialog:SetCallback(
				"CreateButtonClicked",
				function(widget, _, currentBossDungeonEncounterID, planName, difficulty)
					---@cast widget EPNewPlanDialog
					planName = planName:trim()
					if planName == "" or AddOn.db.profile.plans[planName] then
						widget:SetCreateButtonEnabled(false)
					else
						ClosePlanDependentWidgets()
						widget:Release()

						local newPlan = utilities.CreatePlan(
							AddOn.db.profile.plans,
							planName,
							currentBossDungeonEncounterID,
							difficulty
						)
						AddOn.db.profile.lastOpenPlan = newPlan.name
						AddPlanToDropdown(newPlan, true)
						UpdateBoss(currentBossDungeonEncounterID, true)
						UpdateAllAssignments(true)
						Private.callbacks:Fire("PlanChanged")
						if Private.activeTutorialCallbackName then
							Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanDialogPlanCreated")
						end
					end
				end
			)
			newPlanDialog:SetCallback("ValidatePlanName", function(widget, _, planName)
				---@cast widget EPNewPlanDialog
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

			local boss = GetBoss(bossDungeonEncounterID)
			if boss then
				local hasMythic = boss.phases ~= nil
				local hasHeroic = boss.abilitiesHeroic ~= nil
				if hasMythic then
					newPlanDialog.difficultyDropdown:SetValue(DifficultyType.Mythic)
				elseif hasHeroic then
					newPlanDialog.difficultyDropdown:SetValue(DifficultyType.Heroic)
				end
				newPlanDialog.difficultyDropdown:SetEnabled(hasMythic and hasHeroic)
				newPlanDialog:SetPlanNameLineEditText(CreateUniquePlanName(AddOn.db.profile.plans, boss.name))
			end

			Private.newPlanDialog = newPlanDialog
		end
	end

	---@param templateName string
	local function HandleApplyTemplateButtonClicked(templateName)
		local templates = AddOn.db.profile.templates
		local _, index = utilities.ContainsValue(templates, "name", templateName)
		assert(index, "Profile contains template")
		local template = templates[index]
		utilities.ApplyPlanTemplate(template, GetCurrentPlan())
		UpdateAllAssignments(true)
	end

	---@param templateName string
	local function HandleDeleteTemplateButtonClicked(templateName)
		local templates = AddOn.db.profile.templates
		local _, index = utilities.ContainsValue(templates, "name", templateName)
		assert(index, "Profile contains template")
		tremove(templates, index)
		interfaceUpdater.LogMessage(format("%s 1 %s.", L["Removed"], L["Template"]:lower()))
		Private.RepopulateTemplates(templates)
	end

	local CreateUniqueTemplateName = utilities.CreateUniqueTemplateName
	local SortAssigneesWithSpellID = utilities.SortAssigneesWithSpellID

	local function HandleCreateTemplateButtonClicked()
		if not Private.newTemplateDialog then
			local newTemplateDialog = AceGUI:Create("EPNewTemplateDialog")
			newTemplateDialog:SetCallback("OnRelease", function()
				Private.newTemplateDialog = nil
			end)
			newTemplateDialog:SetCallback("CloseButtonClicked", function()
				Private.newTemplateDialog:Release()
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newTemplateDialogClosed")
				end
			end)
			newTemplateDialog:SetCallback("CancelButtonClicked", function()
				Private.newTemplateDialog:Release()
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newTemplateDialogClosed")
				end
			end)

			local currentPlan = GetCurrentPlan()
			local profile = AddOn.db.profile
			local sortType = profile.preferences.assignmentSortType
			local cooldownAndChargeOverrides = profile.cooldownAndChargeOverrides
			local onlyShowMe = profile.preferences.timelineRows.onlyShowMe
			local sortedTimelineAssignments =
				SortAssignments(currentPlan, sortType, cooldownAndChargeOverrides, onlyShowMe, true)
			local orderedAssigneeSpellSets = SortAssigneesWithSpellID(sortedTimelineAssignments)
			local filteredAssignees = {}
			for _, assigneeSpellSet in ipairs(orderedAssigneeSpellSets) do
				filteredAssignees[assigneeSpellSet.assignee] = false
			end

			---@param widget EPNewTemplateDialog
			---@return integer selectedCount
			local function UpdateSelectedCount(widget)
				local count, total = 0, 0
				for _, isFiltered in pairs(filteredAssignees) do
					if not isFiltered then
						count = count + 1
					end
					total = total + 1
				end
				widget.assigneeDropdown:SetText(format("%d / %d %s", count, total, L["Selected"]))
				return count
			end

			---@param widget EPNewTemplateDialog
			---@param selectedCount integer
			---@return boolean
			local function UpdateCreateButtonEnabledState(widget, selectedCount)
				local validName = false
				local templateName = widget.templateNameLineEdit:GetText():trim()
				if templateName ~= "" then
					local templates = AddOn.db.profile.templates
					validName = not utilities.ContainsValue(templates, "name", templateName)
				end
				local enabled = validName and selectedCount > 0
				widget:SetCreateButtonEnabled(enabled)
				return enabled
			end

			newTemplateDialog:SetCallback("ValidateTemplateName", function(widget)
				---@cast widget EPNewTemplateDialog
				UpdateCreateButtonEnabledState(widget, UpdateSelectedCount(widget))
				if Private.activeTutorialCallbackName then
					Private.callbacks:Fire(Private.activeTutorialCallbackName, "newTemplateDialogValidate")
				end
			end)
			newTemplateDialog:SetCallback("AssigneeChanged", function(widget, _, value, selected)
				---@cast widget EPNewTemplateDialog
				filteredAssignees[value] = not selected
				UpdateCreateButtonEnabledState(widget, UpdateSelectedCount(widget))
			end)
			newTemplateDialog:SetCallback("CreateButtonClicked", function(widget, _, templateName)
				---@cast widget EPNewTemplateDialog
				if UpdateCreateButtonEnabledState(widget, UpdateSelectedCount(widget)) then
					templateName = templateName:trim()
					widget:Release()
					local templates = AddOn.db.profile.templates
					utilities.CreatePlanTemplate(
						templates,
						GetCurrentPlan(),
						templateName,
						orderedAssigneeSpellSets,
						filteredAssignees
					)
					Private.RepopulateTemplates(templates)
					if Private.activeTutorialCallbackName then
						Private.callbacks:Fire(Private.activeTutorialCallbackName, "newTemplateDialogTemplateCreated")
					end
				end
			end)

			newTemplateDialog.frame:SetParent(UIParent)
			newTemplateDialog.frame:SetFrameLevel(kNewTemplateDialogFrameLevel)
			local assigneeDropdownItemData = {}
			local roster = GetCurrentRoster()
			for _, assigneeSpellSet in ipairs(orderedAssigneeSpellSets) do
				local assignee = assigneeSpellSet.assignee
				local entryText = utilities.ConvertAssigneeToLegibleString(assignee, roster)
				tinsert(assigneeDropdownItemData, {
					itemValue = assignee,
					text = entryText,
				})
			end
			newTemplateDialog:SetAssigneeDropdownItems(assigneeDropdownItemData)
			local templateName = CreateUniqueTemplateName(AddOn.db.profile.templates, L["New"] .. L["Template"])
			newTemplateDialog:SetTemplateNameLineEditText(templateName)
			UpdateCreateButtonEnabledState(newTemplateDialog, UpdateSelectedCount(newTemplateDialog))
			UpdateSelectedCount(newTemplateDialog)
			newTemplateDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			newTemplateDialog:Resize()
			newTemplateDialog:SetPoint("TOP", UIParent, "TOP", 0, -newTemplateDialog.frame:GetBottom())

			Private.newTemplateDialog = newTemplateDialog
		end
	end

	---@param planMenuButton EPDropdown
	---@param value any
	---@param parentValue any
	---@param valueOwningDropdownItemMenu EPDropdownItemMenu?
	function s.Handler.PlanMenuButtonClicked(planMenuButton, _, value, _, parentValue, valueOwningDropdownItemMenu)
		if value == "Plan" then
			return
		end

		if value == k.PlanMenuItemValues.NewPlan then
			Private.CreateNewPlanDialog()
			if Private.activeTutorialCallbackName then
				Private.callbacks:Fire(Private.activeTutorialCallbackName, "newPlanButtonClicked")
			end
		elseif value == k.PlanMenuItemValues.Templates.Create then
			HandleCreateTemplateButtonClicked()
		elseif value == k.PlanMenuItemValues.DuplicatePlan then
			HandleDuplicatePlanButtonClicked()
		elseif value == k.PlanMenuItemValues.ExportPlan then
			HandleExportPlanButtonClicked()
		elseif value == k.PlanMenuItemValues.DeletePlan then
			local messageBoxData = {
				ID = Private.GenerateUniqueID(),
				widgetType = "EPMessageBox",
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
		elseif parentValue == k.PlanMenuItemValues.Import.FromMRT or parentValue == k.PlanMenuItemValues.Import then
			ImportPlan(value)
		else
			if valueOwningDropdownItemMenu then
				local valueOwningDropdownValue = valueOwningDropdownItemMenu:GetValue()
				if valueOwningDropdownValue == k.PlanMenuItemValues.Templates.Apply then
					HandleApplyTemplateButtonClicked(value)
				elseif valueOwningDropdownValue == k.PlanMenuItemValues.Templates.Delete then
					HandleDeleteTemplateButtonClicked(value)
				end
			end
		end
		planMenuButton:SetValue("Plan")
		planMenuButton:SetText(L["Plan"])
	end
end

---@param bossMenuButton EPDropdown
---@param value any
---@param selected boolean
---@param topLevelItemValue any Value of the top level dropdown item menu
---@param valueOwningDropdownItemMenu? EPDropdownItemMenu The parent dropdown item menu owning the item with value
local function HandleBossMenuButtonClicked(
	bossMenuButton,
	_,
	value,
	selected,
	topLevelItemValue,
	valueOwningDropdownItemMenu
)
	if value == "Boss" then
		return
	elseif value == "Edit Phase Timings" then
		Private.CreatePhaseLengthEditor()
		bossMenuButton:SetValue("Boss")
		bossMenuButton:SetText("Boss")
	elseif topLevelItemValue == "Change Boss" then
		bossMenuButton:Close()
		local newDifficulty = GetCurrentDifficulty()
		if valueOwningDropdownItemMenu then
			local initialValue = valueOwningDropdownItemMenu:GetUserDataTable().initialValue
			if initialValue == DifficultyType.Heroic or initialValue == DifficultyType.Mythic then
				newDifficulty = initialValue
			end
		end
		HandleChangeBossDropdownValueChanged(value, newDifficulty)
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
		local currentPlan = GetCurrentPlan()
		local currentPlanID = currentPlan.ID
		local externalTextEditor = AceGUI:Create("EPEditBox")
		externalTextEditor.frame:SetParent(Private.mainFrame.frame)
		externalTextEditor.frame:SetFrameLevel(constants.frameLevels.kExternalTextEditorFrameLevel)
		externalTextEditor.frame:SetPoint("CENTER")
		externalTextEditor:SetTitle(L["External Text Editor"])
		externalTextEditor:SetCallback("OnRelease", function()
			Private.externalTextEditor = nil
		end)
		externalTextEditor:SetCallback("CloseButtonClicked", function()
			local text = Private.externalTextEditor:GetText()
			AceGUI:Release(Private.externalTextEditor)
			local plan = GetCurrentPlan()
			if plan.ID == currentPlanID then
				plan.content = utilities.SplitStringIntoTable(text)
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
		local currentPlan = GetCurrentPlan()
		local profile = AddOn.db.profile
		local sortType = profile.preferences.assignmentSortType
		local cooldownAndChargeOverrides = profile.cooldownAndChargeOverrides
		-- Use reminder.onlyShowMe since timelineRows.onlyShowMe only applies to timeline assignments
		local onlyShowMe = profile.preferences.reminder.onlyShowMe
		local sortedTimelineAssignments = SortAssignments(currentPlan, sortType, cooldownAndChargeOverrides, onlyShowMe)
		Private:SimulateBoss(
			currentPlan.dungeonEncounterID,
			sortedTimelineAssignments,
			currentPlan.roster,
			currentPlan.difficulty
		)
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
			assignment.combatLogEventType,
			GetCurrentDifficulty()
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
			assignment.combatLogEventType,
			GetCurrentDifficulty()
		)
	else
		return nil
	end
end

---@param timelineAssignment TimelineAssignment
---@param newTimelineAssignment table
local function HandleDuplicateAssignmentStart(_, _, timelineAssignment, newTimelineAssignment)
	Private.DuplicateTimelineAssignment(timelineAssignment, newTimelineAssignment, GetCurrentPlan().ID)
end

---@param timelineAssignment TimelineAssignment
---@param absoluteTime number
local function HandleDuplicateAssignmentEnd(_, _, timelineAssignment, absoluteTime)
	local plan = GetCurrentPlan()
	local assignment = timelineAssignment.assignment
	local newAssignment = Private.DuplicateAssignment(assignment, plan.ID)
	AddAssignmentToPlan(plan, newAssignment)

	local newAssignmentTime = utilities.Round(absoluteTime, 1)
	local relativeTime = nil
	if getmetatable(assignment) == CombatLogEventAssignment then
		---@cast assignment CombatLogEventAssignment
		relativeTime = ConvertAbsoluteTimeToCombatLogEventTime(
			absoluteTime,
			plan.dungeonEncounterID,
			assignment.combatLogEventSpellID,
			assignment.spellCount,
			assignment.combatLogEventType,
			plan.difficulty
		)
	end
	if relativeTime then
		---@cast newAssignment CombatLogEventAssignment
		newAssignment.time = utilities.Round(relativeTime, 1)
	else
		---@cast newAssignment TimedAssignment
		newAssignment.time = newAssignmentTime
	end

	UpdateAllAssignments(false)
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

local function HandleVersionButtonClicked()
	if not Private.patchNotesDialog then
		local patchNotesDialog = AceGUI:Create("EPEditBox")
		patchNotesDialog:SetCallback("OnRelease", function()
			Private.patchNotesDialog.editBox:EnableMouse(true)
			Private.patchNotesDialog.editBox:SetSpacing(0)
			Private.patchNotesDialog = nil
		end)
		patchNotesDialog:SetCallback("CloseButtonClicked", function()
			Private.patchNotesDialog:Release()
		end)
		patchNotesDialog.editBox:EnableMouse(false)
		patchNotesDialog.editBox:SetSpacing(2)
		patchNotesDialog:SetText(constants.kPatchNotesText)
		patchNotesDialog:SetTitle(
			format(
				"%s %s (%s)",
				L["Encounter Planner"],
				Private.version,
				C_AddOns.GetAddOnMetadata(AddOnName, "X-Date")
			)
		)
		patchNotesDialog.frame:SetParent(UIParent)
		patchNotesDialog.frame:SetFrameStrata("DIALOG")
		patchNotesDialog.frame:SetFrameLevel(constants.frameLevels.kPatchNotesDialogFrameLevel)
		patchNotesDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		patchNotesDialog:SetPoint("TOP", UIParent, "TOP", 0, -patchNotesDialog.frame:GetBottom())
		Private.patchNotesDialog = patchNotesDialog
	end
end

local function HandleCollapseAllButtonClicked()
	local currentPlan = GetCurrentPlan()

	local collapsed = currentPlan.collapsed

	local assignments = currentPlan.assignments
	for _, assignment in ipairs(assignments) do
		collapsed[assignment.assignee] = true
	end

	local assigneeSpellSets = currentPlan.assigneeSpellSets
	for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
		collapsed[assigneeSpellSet.assignee] = true
	end
	UpdateAllAssignments(false)
end

local function HandleExpandAllButtonClicked()
	local currentPlan = GetCurrentPlan()
	local collapsed = currentPlan.collapsed

	local assignments = currentPlan.assignments
	for _, assignment in ipairs(assignments) do
		collapsed[assignment.assignee] = false
	end

	local assigneeSpellSets = currentPlan.assigneeSpellSets
	for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
		collapsed[assigneeSpellSet.assignee] = false
	end

	UpdateAllAssignments(false)
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
	if Private.newTemplateDialog then
		Private.newTemplateDialog:Release()
	end
	if Private.patchNotesDialog then
		Private.patchNotesDialog:Release()
	end
end

local function HandleMainFrameReleased()
	Private.mainFrame = nil
	Private.UnregisterCallback(s.SimulationCompletedObject, "SimulationCompleted")
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
	local topContainerWidgetHeight = 22
	local topContainerSpacing = { 4, 4 }
	local mainFramePadding = constants.kMainFramePadding
	local mainFrameSpacing = constants.kMainFrameSpacing
	local encounterID = constants.kDefaultBossDungeonEncounterID
	local profile = self.addOn.db.profile --[[@as DefaultProfile]]
	local plans = profile.plans
	local lastOpenPlan = profile.lastOpenPlan
	encounterID = plans[lastOpenPlan].dungeonEncounterID

	local mainFrame = AceGUI:Create("EPMainFrame")
	mainFrame:SetLayout("EPVerticalLayout")
	mainFrame:SetSpacing(unpack(mainFrameSpacing))
	mainFrame:SetPadding(unpack(mainFramePadding))
	if profile.minimizeFramePosition then
		local x, y = profile.minimizeFramePosition.x, profile.minimizeFramePosition.y
		mainFrame:SetMinimizeFramePosition(x, y)
	end
	mainFrame:SetCallback("VersionButtonClicked", HandleVersionButtonClicked)
	mainFrame:SetCallback("CloseButtonClicked", HandleCloseButtonClicked)
	mainFrame:SetCallback("CollapseAllButtonClicked", HandleCollapseAllButtonClicked)
	mainFrame:SetCallback("ExpandAllButtonClicked", HandleExpandAllButtonClicked)
	mainFrame:SetCallback("MinimizeFramePointChanged", HandleMinimizeFramePointChanged)
	mainFrame:SetCallback("OnRelease", HandleMainFrameReleased)
	mainFrame:SetCallback("TutorialButtonClicked", function()
		self:OpenTutorial()
	end)

	local menuButtonHeight = mainFrame.windowBar.frame:GetHeight() - 2

	local planMenuButton = s.Creator.DropdownMenuButton(L["Plan"], menuButtonHeight)
	planMenuButton:AddItems(s.Creator.PlanMenuItems(), "EPDropdownItemToggle", true)
	planMenuButton:SetCallback("OnValueChanged", s.Handler.PlanMenuButtonClicked)
	local MRTLoadingOrLoaded, MRTLoaded = IsAddOnLoaded("MRT")
	planMenuButton:SetItemEnabled(k.PlanMenuItemValues.Import.FromMRT, MRTLoadingOrLoaded or MRTLoaded)

	local bossMenuButton = s.Creator.DropdownMenuButton(L["Boss"], menuButtonHeight)
	bossMenuButton:SetMultiselect(true)
	bossMenuButton:AddItems(s.Creator.BossMenuItems(), "EPDropdownItemToggle")
	bossMenuButton:SetCallback("OnValueChanged", HandleBossMenuButtonClicked)

	local rosterMenuButton = s.Creator.MenuButton(L["Roster"], menuButtonHeight, HandleRosterMenuButtonClicked)
	local preferencesMenuButton =
		s.Creator.MenuButton(L["Preferences"], menuButtonHeight, HandlePreferencesMenuButtonClicked)

	mainFrame.menuButtonContainer:AddChildren(planMenuButton, bossMenuButton, rosterMenuButton, preferencesMenuButton)

	local instanceLabelLabel = AceGUI:Create("EPLabel")
	instanceLabelLabel:SetFontSize(k.TopContainerWidgetFontSize)
	instanceLabelLabel:SetHeight(16)
	instanceLabelLabel:SetText(L["Instance"] .. ":", 0)
	instanceLabelLabel:SetFrameWidthFromText()

	local bossLabelLabel = AceGUI:Create("EPLabel")
	bossLabelLabel:SetFontSize(k.TopContainerWidgetFontSize)
	bossLabelLabel:SetHeight(16)
	bossLabelLabel:SetText(L["Boss"] .. ":", 0)
	bossLabelLabel:SetFrameWidthFromText()

	local difficultyLabelLabel = AceGUI:Create("EPLabel")
	difficultyLabelLabel:SetFontSize(k.TopContainerWidgetFontSize)
	difficultyLabelLabel:SetHeight(16)
	difficultyLabelLabel:SetText(L["Difficulty"] .. ":", 0)
	difficultyLabelLabel:SetFrameWidthFromText()

	local instanceBossLabelWidth =
		max(instanceLabelLabel.frame:GetWidth(), bossLabelLabel.frame:GetWidth(), difficultyLabelLabel.frame:GetWidth())
	instanceLabelLabel:SetWidth(instanceBossLabelWidth)
	bossLabelLabel:SetWidth(instanceBossLabelWidth)
	difficultyLabelLabel:SetWidth(instanceBossLabelWidth)

	local instanceLabelContainer = AceGUI:Create("EPContainer")
	instanceLabelContainer:SetLayout("EPVerticalLayout")
	instanceLabelContainer:SetSpacing(0, 0)
	instanceLabelContainer:SetPadding(0, 0, 0, 0)
	instanceLabelContainer:AddChildren(instanceLabelLabel, bossLabelLabel, difficultyLabelLabel)

	local instanceLabel = AceGUI:Create("EPLabel")
	instanceLabel:SetFontSize(k.TopContainerWidgetFontSize)
	instanceLabel:SetWidth(k.TopContainerDropdownWidth)
	instanceLabel:SetHeight(16)

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetFontSize(k.TopContainerWidgetFontSize)
	bossLabel:SetWidth(k.TopContainerDropdownWidth)
	bossLabel:SetHeight(16)

	local difficultyLabel = AceGUI:Create("EPLabel")
	difficultyLabel:SetFontSize(k.TopContainerWidgetFontSize)
	difficultyLabel:SetHeight(16)
	difficultyLabel:SetWidth(k.TopContainerDropdownWidth)
	difficultyLabel:SetIcon(constants.textures.kEncounterJournalIcons, 0, 2, 0, 0, 2)

	local instanceBossContainer = AceGUI:Create("EPContainer")
	instanceBossContainer:SetLayout("EPVerticalLayout")
	instanceBossContainer:SetSpacing(0, 0)
	instanceBossContainer:SetPadding(0, 0, 0, 0)
	instanceBossContainer:AddChildren(instanceLabel, bossLabel, difficultyLabel)

	local planLabel = AceGUI:Create("EPLabel")
	planLabel:SetFontSize(k.TopContainerWidgetFontSize)
	planLabel:SetText(L["Current Plan:"], 0)
	planLabel:SetHeight(topContainerWidgetHeight)
	planLabel:SetFrameWidthFromText()

	local planDropdown = AceGUI:Create("EPDropdown")
	planDropdown:SetWidth(k.TopContainerDropdownWidth - 10)
	planDropdown:SetAutoItemWidth(true)
	planDropdown:SetHeight(topContainerWidgetHeight)
	planDropdown:SetUseLineEditForDoubleClick(true)
	planDropdown:SetMaxVisibleItems(k.MaxVisibleDropdownItems)
	planDropdown:SetCallback("OnLineEditTextSubmitted", HandlePlanNameChanged)
	planDropdown:SetCallback("OnValueChanged", HandlePlanDropdownValueChanged)

	local planContainer = AceGUI:Create("EPContainer")
	planContainer:SetLayout("EPVerticalLayout")
	planContainer:SetSpacing(0, 0)
	planContainer:SetPadding(0, 2, 0, 2)
	planContainer:AddChildren(planLabel, planDropdown)

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

	self.RegisterCallback(s.SimulationCompletedObject, "SimulationCompleted", "HandleSimulationCompleted")

	local enableRemindersAndSimulateRemindersButtonWidth =
		max(planReminderEnableCheckBox.frame:GetWidth(), simulateRemindersButton.frame:GetWidth())
	planReminderEnableCheckBox:SetWidth(enableRemindersAndSimulateRemindersButtonWidth)
	simulateRemindersButton:SetWidth(enableRemindersAndSimulateRemindersButtonWidth)

	local reminderContainer = AceGUI:Create("EPContainer")
	reminderContainer:SetLayout("EPVerticalLayout")
	reminderContainer:SetSpacing(unpack(topContainerSpacing))
	reminderContainer:AddChildren(planReminderEnableCheckBox, simulateRemindersButton)

	local primaryPlanCheckBox = AceGUI:Create("EPCheckBox")
	primaryPlanCheckBox:SetText(L["Designated External Plan"])
	primaryPlanCheckBox:SetHeight(topContainerWidgetHeight)
	primaryPlanCheckBox:SetFrameWidthFromText()
	primaryPlanCheckBox:SetCallback("OnValueChanged", HandlePrimaryPlanCheckBoxValueChanged)
	primaryPlanCheckBox:SetCallback("OnEnter", HandlePrimaryPlanCheckBoxEnter)
	primaryPlanCheckBox:SetCallback("OnLeave", HandlePrimaryPlanCheckBoxLeave)
	primaryPlanCheckBox.fireEventsIfDisabled = true
	primaryPlanCheckBox.button.fireEventsIfDisabled = true

	local externalTextButton = AceGUI:Create("EPButton")
	externalTextButton:SetText(L["External Text"])
	externalTextButton:SetFullWidth(true)
	externalTextButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	externalTextButton:SetHeight(topContainerWidgetHeight)
	externalTextButton:SetCallback("Clicked", HandleExternalTextButtonClicked)

	local primaryPlanAndExternalTextContainer = AceGUI:Create("EPContainer")
	primaryPlanAndExternalTextContainer:SetLayout("EPVerticalLayout")
	primaryPlanAndExternalTextContainer:SetSpacing(unpack(topContainerSpacing))
	primaryPlanAndExternalTextContainer:AddChildren(primaryPlanCheckBox, externalTextButton)

	local sendPlanButton = AceGUI:Create("EPButton")
	sendPlanButton:SetText(L["Send to Group"])
	sendPlanButton:SetWidthFromText()
	sendPlanButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	sendPlanButton:SetHeight(topContainerWidgetHeight)
	sendPlanButton:SetCallback("Clicked", Private.HandleSendPlanButtonClicked)

	local proposeChangesButton = AceGUI:Create("EPButton")
	proposeChangesButton:SetText(L["Propose Changes"])
	proposeChangesButton:SetWidthFromText()
	proposeChangesButton:SetColor(unpack(constants.colors.kNeutralButtonActionColor))
	proposeChangesButton:SetHeight(topContainerWidgetHeight)
	proposeChangesButton:SetCallback("Clicked", Private.HandleProposeChangesButtonClicked)

	local sendPlanAndProposeChangesButtonWidth =
		max(sendPlanButton.frame:GetWidth(), proposeChangesButton.frame:GetWidth())
	sendPlanButton:SetWidth(sendPlanAndProposeChangesButtonWidth)
	proposeChangesButton:SetWidth(sendPlanAndProposeChangesButtonWidth)

	local sendAndProposeChangesContainer = AceGUI:Create("EPContainer")
	sendAndProposeChangesContainer:SetLayout("EPVerticalLayout")
	sendAndProposeChangesContainer:SetSpacing(unpack(topContainerSpacing))
	sendAndProposeChangesContainer:AddChildren(sendPlanButton, proposeChangesButton)

	local reminderAndSendPlanButtonContainer = AceGUI:Create("EPContainer")
	reminderAndSendPlanButtonContainer:SetLayout("EPHorizontalLayout")
	reminderAndSendPlanButtonContainer:SetFullHeight(true)
	reminderAndSendPlanButtonContainer:SetSelfAlignment("topRight")
	reminderAndSendPlanButtonContainer:SetSpacing(8, 4)
	reminderAndSendPlanButtonContainer:AddChildren(
		reminderContainer,
		primaryPlanAndExternalTextContainer,
		sendAndProposeChangesContainer
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
		bgFile = k.GenericWhite,
		edgeFile = k.GenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	}
	topContainer:SetBackdrop(topContainerBackdrop, { 0, 0, 0, 0 }, { 0.25, 0.25, 0.25, 1 })

	local timeline = AceGUI:Create("EPTimeline")
	timeline.SetPreferences(profile.preferences)
	timeline:SetFunctionReferences(
		HandleCalculateAssignmentTimeFromStart,
		HandleGetMinimumCombatLogEventTime,
		interfaceUpdater.ComputeChargeStates
	)
	timeline:SetFullWidth(true)
	timeline:SetCallback("AssignmentClicked", HandleTimelineAssignmentClicked)
	timeline:SetCallback("CreateNewAssignment", HandleCreateNewAssignment)
	timeline:SetCallback("DuplicateAssignmentStart", HandleDuplicateAssignmentStart)
	timeline:SetCallback("DuplicateAssignmentEnd", HandleDuplicateAssignmentEnd)
	timeline:SetCallback("ResizeBoundsCalculated", HandleResizeBoundsCalculated)
	local addAssigneeDropdown = timeline:GetAddAssigneeDropdown()
	addAssigneeDropdown:SetCallback("OnValueChanged", HandleAddAssigneeRowDropdownValueChanged)
	addAssigneeDropdown:SetText(k.AddAssigneeText)
	local assigneeItems = CreateAssignmentTypeWithRosterDropdownItems(GetCurrentRoster())
	addAssigneeDropdown:AddItems(assigneeItems, "EPDropdownItemToggle", true)

	mainFrame.bossLabel = bossLabel
	mainFrame.bossMenuButton = bossMenuButton
	mainFrame.difficultyLabel = difficultyLabel
	mainFrame.externalTextButton = externalTextButton
	mainFrame.instanceLabel = instanceLabel
	mainFrame.planDropdown = planDropdown
	mainFrame.planMenuButton = planMenuButton
	mainFrame.planReminderEnableCheckBox = planReminderEnableCheckBox
	mainFrame.preferencesMenuButton = preferencesMenuButton
	mainFrame.primaryPlanCheckBox = primaryPlanCheckBox
	mainFrame.proposeChangesButton = proposeChangesButton
	mainFrame.rosterMenuButton = rosterMenuButton
	mainFrame.sendPlanButton = sendPlanButton
	mainFrame.simulateRemindersButton = simulateRemindersButton
	mainFrame.timeline = timeline
	self.mainFrame = mainFrame

	self:UpdateSendPlanButtonState()
	interfaceUpdater.RestoreMessageLog()
	mainFrame:AddChildren(topContainer, timeline)
	mainFrame.currentPlanWidget = topContainer
	mainFrame.menuButtonContainer:DoLayout()

	interfaceUpdater.RepopulatePlanWidgets()
	Private.RepopulateTemplates(AddOn.db.profile.templates)
	UpdateBoss(encounterID, true)
	local roster = GetCurrentRoster()
	UpdateRosterFromAssignments(GetCurrentAssignments(), roster)
	UpdateRosterDataFromGroup(roster)
	UpdateRosterDataFromGroup(profile.sharedRoster)
	UpdateAllAssignments(true, true)
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
