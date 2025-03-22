---@diagnostic disable: invisible
local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class Plan
local Plan = Private.classes.Plan
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater
local UpdateAllAssignments = interfaceUpdater.UpdateAllAssignments

---@class Utilities
local utilities = Private.utilities

local AceGUI = LibStub("AceGUI-3.0")
local format = string.format
local getmetatable = getmetatable
local ipairs = ipairs
local max = math.max
local pairs = pairs
local tinsert = tinsert

local highlightBorderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
highlightBorderFrame:SetBackdrop({
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 2,
})
highlightBorderFrame:SetBackdropBorderColor(1, 0.82, 0, 1)
highlightBorderFrame:EnableMouse(false)
highlightBorderFrame:Hide()

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

---@return integer
local function GetCurrentBossDungeonEncounterID()
	return Private.mainFrame.bossLabel:GetValue()
end

local kHighlightPadding = 2

---@param frame Frame
local function HighlightFrame(frame)
	if not frame then
		return
	end

	highlightBorderFrame:SetFrameStrata(frame:GetFrameStrata())
	highlightBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
	highlightBorderFrame:ClearAllPoints()
	highlightBorderFrame:SetPoint("TOPLEFT", frame, -kHighlightPadding, kHighlightPadding)
	highlightBorderFrame:SetPoint("BOTTOMRIGHT", frame, kHighlightPadding, -kHighlightPadding)
	highlightBorderFrame:Show()
end

---@param self Private
local function HandleCreateAssignmentEditor(self)
	self.CreateAssignmentEditor()

	local timelineRows = AddOn.db.profile.preferences.timelineRows
	timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)

	local name, entry = utilities.CreateRosterEntryForSelf()

	local assignments = GetCurrentAssignments()
	local needToCreateNewAssignment = true
	for _, assignment in ipairs(assignments) do
		if assignment.assignee == name then
			needToCreateNewAssignment = false
			interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
			break
		end
	end
	if needToCreateNewAssignment then
		local roster = GetCurrentRoster()
		if not roster[name] then
			roster[name] = entry
		end
		local assignment = TimedAssignment:New()
		assignment.assignee = name
		tinsert(GetCurrentAssignments(), assignment)
		UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
	end
end

---@param self Private
local function EnsureAssigneeIsExpanded(self)
	local timeline = self.mainFrame.timeline
	if timeline then
		local assignmentContainer = timeline:GetAssignmentContainer()
		if assignmentContainer.children[1] then
			local abilityEntry = assignmentContainer.children[1]
			AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed[abilityEntry:GetKey()] = false
			local bossDungeonEncounterID = self.mainFrame.bossLabel:GetValue()
			if bossDungeonEncounterID then
				interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
			end
		end
	end
end

---@return boolean
local function IsSelfPresentInPlan()
	local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan] --[[@as Plan]]
	if plan then
		local playerName, _ = UnitFullName("player")
		for _, assignment in ipairs(plan.assignments) do
			if assignment.assignee == playerName then
				return true
			end
		end
	end
	return false
end

---@param self Private
local function IsSpellChanged(self)
	if self.assignmentEditor then
		local assignmentID = self.assignmentEditor:GetAssignmentID()
		if assignmentID then
			local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
			if assignment then
				local name = C_Spell.GetSpellName(assignment.spellID)
				if name then
					return true
				end
			end
		end
	end
	return false
end

---@param self Private
local function IsTextChanged(self)
	if self.assignmentEditor then
		local assignmentID = self.assignmentEditor:GetAssignmentID()
		if assignmentID then
			local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
			if assignment then
				if assignment.text:lower() == "use healthstone {6262} at {circle}" then
					return true
				end
			end
		end
	end
	return false
end

---@param self Private
local function TwoPhaseOneSpellsExists(self)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseOneDuration = boss.phases[1].duration
		local count = 0
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.TimedAssignment then
				if
					assignment--[[@as TimedAssignment]].time < phaseOneDuration
				then
					count = count + 1
					if count >= 2 then
						return true
					end
				end
			end
		end
	end
	return false
end

---@param self Private
local function IntermissionSpellExists(self)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseTwoDuration = boss.phases[1].duration
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				if
					assignment--[[@as TimedAssignment]].time < phaseTwoDuration
				then
					return true
				end
			end
		end
	end
	return false
end

---@param self Private
---@return number
local function GetPhaseOneRightOffset(self)
	local offset = -30
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseOneDuration = boss.phases[1].duration
		if self.mainFrame and self.mainFrame.timeline then
			local timelineFrameWidth = self.mainFrame.timeline.bossAbilityTimeline.timelineFrame:GetWidth()
			local tOffset = self.mainFrame.timeline.ConvertTimeToTimelineOffset(phaseOneDuration, timelineFrameWidth)
			offset = offset - (timelineFrameWidth - tOffset)
		end
	end
	return offset
end

---@param self Private
---@return number
---@return number
local function GetPhaseTwoOffsets(self)
	local left, right = 200 + 10, -30
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseOneDuration = boss.phases[1].duration
		local phaseTwoEnd = phaseOneDuration + boss.phases[2].duration
		if self.mainFrame and self.mainFrame.timeline then
			local timelineFrameWidth = self.mainFrame.timeline.bossAbilityTimeline.timelineFrame:GetWidth()
			local tOffset = self.mainFrame.timeline.ConvertTimeToTimelineOffset(phaseOneDuration, timelineFrameWidth)
			left = left + tOffset
			tOffset = self.mainFrame.timeline.ConvertTimeToTimelineOffset(phaseTwoEnd, timelineFrameWidth)
			right = right - (timelineFrameWidth - tOffset)
		end
	end
	return left, right
end

local kAssignmentTextureSize = 30
local kAssignmentSpacing = 2
local kTutorialOffset = 10
local kTutorialFrameLevel = 250

---@param self Private
---@param leftOffset number
---@param rightOffset number
---@param rowNumber integer
local function HighlightTimelineSection(self, leftOffset, rightOffset, rowNumber)
	local timeline = self.mainFrame.timeline
	if timeline then
		local assignmentTimelineFrame = timeline.assignmentTimeline.frame
		highlightBorderFrame:SetFrameStrata(assignmentTimelineFrame:GetFrameStrata())
		highlightBorderFrame:SetFrameLevel(assignmentTimelineFrame:GetFrameLevel() + 50)
		highlightBorderFrame:ClearAllPoints()
		local x = -kHighlightPadding + leftOffset
		local assignmentHeight = (kAssignmentTextureSize + kAssignmentSpacing) * rowNumber
		if assignmentHeight > (kAssignmentTextureSize + kAssignmentSpacing) then
			assignmentHeight = assignmentHeight - kAssignmentSpacing
		end
		local y = kHighlightPadding - assignmentHeight
		highlightBorderFrame:SetPoint("TOPLEFT", assignmentTimelineFrame, x, y)
		x = kHighlightPadding + rightOffset
		y = kHighlightPadding - assignmentHeight
		highlightBorderFrame:SetPoint("TOPRIGHT", assignmentTimelineFrame, x, y)
		highlightBorderFrame:SetHeight(kAssignmentTextureSize + 2 * kHighlightPadding)
		highlightBorderFrame:Show()
		self.tutorial.frame:ClearAllPoints()
		self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
	end
end

---@class TutorialStep
---@field text string
---@field enableNextButton boolean|fun():boolean
---@field frame Frame|table|nil
---@field callbackName string|nil
---@field OnStepActivated fun(self: TutorialStep)|nil
---@field PreStepDeactivated fun(self: TutorialStep, incrementing: boolean)|nil
---@field HighlightFrame fun()|nil

---@param self Private
---@param setCurrentStep fun(previousStepIndex: integer, currentStepIndex: integer)
---@return table<integer, TutorialStep>
local function CreateTutorialSteps(self, setCurrentStep)
	local steps = {}
	local createdTutorialPlan = false
	---@type table<integer, TutorialStep>
	steps = {
		{
			text = "The Menu Bar contains high level categories for managing plans, modifying bosses, editing rosters, and settings.",
			enableNextButton = true,
			frame = self.mainFrame.menuButtonContainer.frame,
		},
		{
			text = "Click the Plan button, and then click New Plan.",
			enableNextButton = false,
			frame = self.mainFrame.menuButtonContainer.children[1].frame,
			callbackName = "TutNewPlanDialogOpened",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function()
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
				end)
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "This plan will be used throughout this tutorial. Select Brew Master Aldryr (Cinderbrew Meadery) as the boss and name the plan Tutorial.",
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "validate" then
						if self.newPlanDialog then
							local planName = self.newPlanDialog.planNameLineEdit:GetText():trim()
							local encounterID = self.newPlanDialog.bossDropdown:GetValue()
							self.newPlanDialog.createButton:SetEnabled(
								planName ~= ""
									and not AddOn.db.profile.plans[planName]
									and planName:lower():find("tutorial") ~= nil
									and encounterID == 2900
							)
						end
					elseif category == "created" then
						createdTutorialPlan = true
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "closed" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
					end
				end)
				if not self.newPlanDialog then
					self.CreateNewPlanDialog()
				end
				if self.newPlanDialog then
					local planName = self.newPlanDialog.planNameLineEdit:GetText():trim()
					local encounterID = self.newPlanDialog.bossDropdown:GetValue()
					self.newPlanDialog.createButton:SetEnabled(
						planName ~= ""
							and not AddOn.db.profile.plans[planName]
							and planName:lower():find("tutorial") ~= nil
							and encounterID == 2900
					)
				end
				if createdTutorialPlan then
					if self.tutorial then
						self.tutorial.nextButton:SetEnabled(true)
					end
				end
				localSelf.frame = self.newPlanDialog.frame
			end,
			PreStepDeactivated = function(localSelf)
				if self.newPlanDialog then
					self.newPlanDialog:Release()
				end
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
			callbackName = "TutNewPlanDialog",
		},
		{
			text = "Click the Roster button to open the Roster Editor for the plan.",
			enableNextButton = false,
			frame = self.mainFrame.menuButtonContainer.children[3].frame,
			callbackName = "TutRosterEditorOpened",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function()
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
				end)
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"The",
				"cffffd10",
				"Current Plan Roster",
				"is unique to the current plan. Roster members must be added here before assigning assignments to individuals. The creator of the plan is automatically added"
			),
			enableNextButton = true,
			callbackName = "TutRosterEditor",
			OnStepActivated = function(localSelf)
				if not self.rosterEditor then
					self.CreateRosterEditor("Current Plan Roster")
				end
				self.rosterEditor:SetCurrentTab("Current Plan Roster")
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "closed" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
					end
				end)
				localSelf.frame = self.rosterEditor.tabContainer.children[1].frame
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				if self.rosterEditor then
					self.rosterEditor:Release()
				end
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"The",
				"cffffd10",
				"Current Plan Bar",
				"shows information and settings for the current plan"
			),
			enableNextButton = true,
			frame = self.mainFrame.children[1].frame,
		},
		{
			text = "The current plan is selected using this dropdown. You can rename the current plan by double clicking the dropdown.",
			enableNextButton = true,
			frame = self.mainFrame.planDropdown.frame,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Reminders can be toggled on and off on a per-plan basis. The yellow bell icon in the",
				"cffffd10",
				"Current Plan Dropdown",
				"also indicates whether reminders are enabled for a plan.\n\nDisable reminders for this plan since it is a tutorial"
			),
			enableNextButton = function()
				if Private.mainFrame and not Private.mainFrame.planReminderEnableCheckBox:IsChecked() then
					return true
				end
				return false
			end,
			callbackName = "TutPlanReminders",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, checked)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if checked == false then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					else
						if self.tutorial then
							self.tutorial.nextButton:SetEnabled(false)
						end
					end
				end)
				localSelf.frame = self.mainFrame.planReminderEnableCheckBox.frame
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r.",
				"Add yourself to the Assignment Timeline by selecting your character name from the Individual menu in the",
				"cffffd10",
				"Add Assignee dropdown"
			),
			enableNextButton = function()
				return IsSelfPresentInPlan()
			end,
			callbackName = "TutSelfAssigneeAdded",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function()
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if IsSelfPresentInPlan() then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.timeline.addAssigneeDropdown.frame
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"The",
				"cffffd10",
				"Assignment Editor",
				"is opened after adding an assignee. It can also by opened by left-clicking an assignment spell icon in the Assignment Timeline"
			),
			enableNextButton = true,
			callbackName = "TutAssignmentEditorOpened",
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
					end
				end)
				localSelf.frame = self.assignmentEditor.frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				if not incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"The",
				"cffffd10",
				"Trigger",
				"determines what activates an assignment. It can either be relative to the start of an encounter (Fixed Time) or relative to a combat log event. Not all combat log event types may be available for a given boss. Leave it as Fixed Time for now"
			),
			enableNextButton = true,
			callbackName = "TutAssignmentTrigger",
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 2)
					end
				end)
				localSelf.frame = self.assignmentEditor.children[1].frame
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = "Check the Spell checkbox and use the dropdown to select a spell for the assignment.", -- TODO: Add dps/healer/tank cooldown spell
			enableNextButton = function()
				return IsSpellChanged(self)
			end,
			callbackName = "TutAssignmentSpellChanged",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == nil then
						if IsSpellChanged(self) then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					elseif category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 3)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "The Assignment Timeline is updated to reflect the spell. The cooldown duration of the spell is shown as the alternating grey texture.",
			enableNextButton = true,
			HighlightFrame = function()
				HighlightTimelineSection(self, 0, -30, 1)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Spell cooldown durations can be overridden in the",
				"cffffd10",
				"Cooldown Overrides",
				"section of the Preferences Menu"
			),
			enableNextButton = true,
			frame = self.mainFrame.menuButtonContainer.children[4].frame,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"If the",
				"cffffd10",
				"Text",
				"is blank, the spell icon and name are automatically used"
			),
			enableNextButton = true,
			callbackName = "TutAssignmentAutoText",
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
			HighlightFrame = function()
				local textFrame = self.assignmentEditor.optionalTextContainer.frame
				local previewFrame = self.assignmentEditor.previewContainer.frame
				highlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
				highlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
				highlightBorderFrame:ClearAllPoints()
				highlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
				highlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, -2)
				highlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s",
				"You can display icons in the text by surrounding a spell ID, raid marker name, etc. in curly braces. Set the",
				"cffffd10",
				"Text",
				"to the following:\nUse Healthstone {6262} at {circle}"
			),
			enableNextButton = function()
				return IsTextChanged(self)
			end,
			callbackName = "TutAssignmentTextChanged",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == nil then
						if IsTextChanged(self) then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					elseif category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 2)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.optionalTextContainer.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Create a blank assignment by left-clicking the timeline beside an Assignee. The assignment will be created relative to the start of the encounter unless clicked within a boss phase triggered by a combat log event.",
			enableNextButton = function()
				return TwoPhaseOneSpellsExists(self)
			end,
			callbackName = "TutAssignmentAddedOne",
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, GetPhaseOneRightOffset(self), 0)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == nil and TwoPhaseOneSpellsExists(self) then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Create another blank assignment but this time during the first intermission.",
			enableNextButton = function()
				return IntermissionSpellExists(self)
			end,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				local left, right = GetPhaseTwoOffsets(self)
				HighlightTimelineSection(self, left, right, 0)
			end,
			callbackName = "TutAssignmentAddedTwo",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == nil and IntermissionSpellExists(self) then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Since the intermission is triggered by boss health, using timed assignments would be unreliable. Instead, the spell the boss casts before transitioning into intermission is used.",
			enableNextButton = true,
			callbackName = "TutIntermissionSpell",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.children[1].frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Instead of clicking beside an Assignee, left-click beside the spell of an assignee.", -- TODO Show arrow
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, 1)
			end,
			callbackName = "TutAssignmentAddedThree",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == nil then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "released" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 2)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Change the time of an assignment by left-clicking an icon and dragging it.", -- TODO Show longer arrow
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, 1)
			end,
			callbackName = "TutAssignmentMovedByDragging",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(
					Private.tutorialCallbackObject,
					localSelf.callbackName,
					function(_, timeDifference)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if type(timeDifference) == "number" and timeDifference > 0.0 then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Duplicate an assignment by control-clicking an icon and dragging.", -- TODO Show longer arrow
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, 1)
			end,
			callbackName = "TutAssignmentDuplicated",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function()
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Tutorial Complete!",
			enableNextButton = true,
		},
	}
	return steps
end

function Private:OpenTutorial()
	-- TODO: Save last step
	if not self.tutorial then
		if not self.mainFrame then
			self:CreateInterface()
		end

		local highlightBorderFrameWasVisible = false
		self.mainFrame:SetCallback("MinimizeButtonClicked", function()
			if self.tutorial then
				highlightBorderFrameWasVisible = highlightBorderFrame:IsShown()
				self.tutorial.frame:Hide()
				highlightBorderFrame:Hide()
			end
		end)
		self.mainFrame:SetCallback("MaximizeButtonClicked", function()
			if self.tutorial then
				self.tutorial.frame:Show()
				if highlightBorderFrameWasVisible then
					highlightBorderFrame:Show()
				end
			end
		end)

		self.tutorialCallbackObject = {}
		local steps = {} ---@type table<integer, TutorialStep>
		local totalStepCount = 0

		---@param previousStepIndex integer
		---@param currentStepIndex integer
		local function SetCurrentStep(previousStepIndex, currentStepIndex)
			Private.activeTutorialCallbackName = nil
			local previousStep = steps[previousStepIndex]
			if previousStep then
				if currentStepIndex > previousStepIndex then
					if previousStep.PreStepDeactivated then
						previousStep:PreStepDeactivated(true)
					end
				elseif currentStepIndex < previousStepIndex then
					if previousStep.PreStepDeactivated then
						previousStep:PreStepDeactivated(false)
					end
				end
			end

			currentStepIndex = max(1, currentStepIndex)
			if currentStepIndex > totalStepCount then
				self.tutorial:Release()
			else
				local currentStep = steps[currentStepIndex]
				if currentStep.callbackName then
					Private.activeTutorialCallbackName = currentStep.callbackName
				end
				local enable = false
				if type(currentStep.enableNextButton) == "function" then
					enable = currentStep.enableNextButton()
				elseif type(currentStep.enableNextButton) == "boolean" then
					enable = currentStep.enableNextButton --[[@as boolean]]
				end
				self.tutorial:SetCurrentStep(currentStepIndex, currentStep.text, enable)
				if currentStep.OnStepActivated then
					currentStep:OnStepActivated()
				end
				if currentStep.frame then
					HighlightFrame(currentStep.frame)
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
				elseif currentStep.HighlightFrame then
					currentStep:HighlightFrame()
				end
			end
		end

		steps = CreateTutorialSteps(self, SetCurrentStep)
		totalStepCount = #steps

		local addBack = {
			{
				text = "Clicking the Boss button lets change the current plan boss, adjust phase timings, and show/hide boss abilities.",
				frame = self.mainFrame.menuButtonContainer.children[2].frame,
			},
			{
				text = "The Shared Roster tab opens the Shared Roster, which is plan-independent and persists across all plans.",
				OnStepActivated = function(localSelf)
					if not self.rosterEditor then
						self.CreateRosterEditor("Shared Roster")
					end
					self.rosterEditor:SetCurrentTab("Shared Roster")
					localSelf.frame = self.rosterEditor.tabContainer.children[2].frame
				end,
				PreStepDeactivated = function(localSelf)
					if self.rosterEditor then
						self.rosterEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = true,
			},
		}

		local tutorial = AceGUI:Create("EPTutorial")
		tutorial:InitProgressBar(totalStepCount, AddOn.db.profile.preferences.reminder.progressBars.texture)
		tutorial.frame:SetFrameLevel(kTutorialFrameLevel)
		tutorial:SetCallback("OnRelease", function()
			Private.UnregisterAllCallbacks(Private.tutorialCallbackObject)
			self.tutorial = nil
			highlightBorderFrame:ClearAllPoints()
			highlightBorderFrame:Hide()
			for _, step in pairs(steps) do
				if step.PreStepDeactivated then
					step:PreStepDeactivated(true)
				end
			end
			Private.tutorialCallbackObject = nil
		end)
		tutorial:SetCallback("PreviousButtonClicked", function()
			SetCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
		end)
		tutorial:SetCallback("NextButtonClicked", function()
			SetCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
		end)
		tutorial:SetCallback("SkipButtonClicked", function()
			self.tutorial:Release()
		end)

		self.tutorial = tutorial
		SetCurrentStep(1, 14)
	end
end
