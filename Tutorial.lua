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
local min, max = math.min, math.max
local pairs = pairs
local tinsert = tinsert

local tutorialPlanID = nil

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

local function CreateTutorialPlan()
	local plan = AddOn.db.profile.plans["Tutorial"]
	if not plan then
		plan = utilities.CreatePlan(AddOn.db.profile.plans, "Tutorial", 2900)
	end
	tutorialPlanID = plan.ID
	return plan
end

---@param self Private
---@param steps table
---@param name string
---@return boolean
local function ShouldIncrementCurrentStep(self, steps, name)
	if self.quickStart then
		local step = steps[self.quickStart.currentStep]
		if step and step.callbackName == name then
			return true
		end
	end
	return false
end

---@param self Private
local function HandleCreateAssignmentEditor(self)
	self.CreateAssignmentEditor()

	local timelineRows = AddOn.db.profile.preferences.timelineRows
	timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)

	local name, entry = utilities.CreateRosterEntryForSelf()

	local assignments = GetCurrentAssignments()
	local needToCreateNewAssignment = false
	for _, assignment in ipairs(assignments) do
		if assignment.assignee == name then
			needToCreateNewAssignment = false
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

local kAssignmentTextureSize = 30
local kAssignmentSpacing = 2
local kQuickStartOffset = 10
local kQuickStartFrameLevel = 250

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
		x = kHighlightPadding - rightOffset
		y = kHighlightPadding - assignmentHeight
		highlightBorderFrame:SetPoint("TOPRIGHT", assignmentTimelineFrame, x, y)
		highlightBorderFrame:SetHeight(kAssignmentTextureSize)
		highlightBorderFrame:Show()
		self.quickStart.frame:ClearAllPoints()
		self.quickStart.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kQuickStartOffset)
	end
end

function Private:OpenQuickStart()
	-- TODO: Save last step
	if not self.quickStart then
		if not self.mainFrame then
			self:CreateInterface()
		end

		local addBack = {
			{
				text = "Clicking the Boss button lets change the current plan boss, adjust phase timings, and show/hide boss abilities.",
				frame = self.mainFrame.menuButtonContainer.children[2].frame,
			},
			{
				text = "The Shared Roster tab opens the Shared Roster, which is plan-independent and persists across all plans.",
				CreateRequiredWidget = function(localSelf)
					if not self.rosterEditor then
						self.CreateRosterEditor("Shared Roster")
					end
					self.rosterEditor:SetCurrentTab("Shared Roster")
					localSelf.frame = self.rosterEditor.tabContainer.children[2].frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.rosterEditor then
						self.rosterEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = true,
			},
		}

		local steps = {
			{
				text = "The Menu Bar contains high level categories for managing plans, modifying bosses, editing rosters, and settings.",
				showNextButton = true,
				frame = self.mainFrame.menuButtonContainer.frame,
			},
			{
				text = "Click the Plan button, and then click New Plan.",
				showNextButton = false,
				frame = self.mainFrame.menuButtonContainer.children[1].frame,
				callbackName = "TutNewPlanDialogOpened",
			},
			{
				text = "This plan will be used throughout this tutorial. Select Brew Master Aldryr (Cinderbrew Meadery) as the boss and name the plan Tutorial.",
				showNextButton = false,
				CreateRequiredWidget = function(localSelf)
					if not self.newPlanDialog then
						self.CreateNewPlanDialog()
					end
					localSelf.frame = self.newPlanDialog.frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.newPlanDialog then
						self.newPlanDialog:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = true,
				closeRequiredWidgetOnIncrement = true,
				callbackName = "TutNewPlanDialogValidatePlan",
			},
			{
				text = "Click the Roster button to open the Roster Editor for the plan.",
				showNextButton = false,
				frame = self.mainFrame.menuButtonContainer.children[3].frame,
				callbackName = "TutRosterEditorOpened",
			},
			{
				text = "The Current Plan Roster is unique to the current plan. Roster members must be added here before assigning assignments to individuals. The creator of the plan is automatically added.",
				showNextButton = true,
				CreateRequiredWidget = function(localSelf)
					if not self.rosterEditor then
						self.CreateRosterEditor("Current Plan Roster")
					end
					self.rosterEditor:SetCurrentTab("Current Plan Roster")
					localSelf.frame = self.rosterEditor.tabContainer.children[1].frame
				end,
				CloseRequiredWidget = function()
					if self.rosterEditor then
						self.rosterEditor:Release()
					end
				end,
				closeRequiredWidgetOnDecrement = true,
				closeRequiredWidgetOnIncrement = true,
			},
			{
				text = "The Current Plan Bar shows information and settings for the current plan.",
				showNextButton = true,
				frame = self.mainFrame.children[1].frame,
			},
			{
				text = "The current plan is selected using this dropdown. You can rename the current plan by double clicking the dropdown.",
				showNextButton = true,
				frame = self.mainFrame.planDropdown.frame,
			},
			{
				text = "Reminders for plans can be individually toggled on and off. The yellow bell icon in the Current Plan Dropdown also indicates whether reminders are enabled for a plan.",
				showNextButton = true,
				frame = self.mainFrame.planReminderEnableCheckBox.frame,
			},
			{
				text = "Add yourself to the Assignment Timeline by selecting your character name from the Individual menu in the Add Assignee dropdown.",
				showNextButton = false,
				frame = self.mainFrame.timeline.addAssigneeDropdown.frame,
				callbackName = "TutSelfAssigneeAdded",
			},
			{
				text = "The Assignment Editor is opened after adding an assignee. It can also by opened by left-clicking an assignment spell icon in the Assignment Timeline.",
				showNextButton = true,
				CreateRequiredWidget = function(localSelf)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
					localSelf.frame = self.assignmentEditor.frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = true,
				closeRequiredWidgetOnIncrement = false,
			},
			{
				text = "The Trigger determines what activates an assignment. It can either be relative to the start of an encounter (Fixed Time) or relative to a combat log event. Not all combat log event types may be available for a given boss. Leave it as Fixed Time for now.",
				showNextButton = true,
				CreateRequiredWidget = function(localSelf)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
					localSelf.frame = self.assignmentEditor.children[1].frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = false,
			},
			{
				text = "Check the Spell checkbox and use the dropdown to select a spell for the assignment.", -- TODO: Add dps/healer/tank cooldown spell
				showNextButton = false,
				CreateRequiredWidget = function(localSelf)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
					localSelf.frame = self.assignmentEditor.spellAssignmentContainer
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = false,
				callbackName = "TutAssignmentSpellChanged",
			},
			{

				text = "The Assignment Timeline is updated to reflect the spell. The cooldown duration of the spell is shown as the alternating grey texture.",
				showNextButton = true,
				HighlightFrame = function()
					HighlightTimelineSection(self, 0, -30, 1)
				end,
			},
			{
				text = "Spell cooldown durations can be overridden in the Cooldown Overrides section of the Preferences Menu.",
				showNextButton = true,
				frame = self.mainFrame.menuButtonContainer.children[4].frame,
			},
			{
				text = "If the Assignment Text is blank, the spell icon and name are automatically used to create assignment text.",
				showNextButton = true,
				CreateRequiredWidget = function(_)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				HighlightFrame = function()
					local textFrame = self.assignmentEditor.optionalTextContainer.frame
					local previewFrame = self.assignmentEditor.previewContainer.frame
					highlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
					highlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
					highlightBorderFrame:ClearAllPoints()
					highlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
					highlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, 2)
					highlightBorderFrame:Show()
					self.quickStart.frame:ClearAllPoints()
					self.quickStart.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kQuickStartOffset)
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = false,
			},
			{
				text = "You can display icons in the text by surrounding a spell ID, raid marker name, etc. in curly braces. Set the Assignment Text to the following:\nUse Healthstone {6262} at {circle}",
				showNextButton = false,
				CreateRequiredWidget = function(localSelf)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
					localSelf.frame = self.assignmentEditor.optionalTextContainer.frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				HighlightFrame = function()
					local textFrame = self.assignmentEditor.optionalTextContainer.frame
					local previewFrame = self.assignmentEditor.previewContainer.frame
					highlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
					highlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
					highlightBorderFrame:ClearAllPoints()
					highlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
					highlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, 2)
					highlightBorderFrame:Show()
					self.quickStart.frame:ClearAllPoints()
					self.quickStart.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kQuickStartOffset)
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = false,
				callbackName = "TutAssignmentTextChanged",
			},
			{
				-- TODO: Limit highlight frame to phase 1
				text = "Create a blank assignment by left-clicking the timeline beside an Assignee. The assignment will be created relative to the start of the encounter unless clicked within a boss phase triggered by a combat log event.",
				showNextButton = false,
				HighlightFrame = function()
					EnsureAssigneeIsExpanded(self)
					HighlightTimelineSection(self, 200 + 10, -30, 0)
				end,
				callbackName = "TutAssignmentAdded",
			},
			{
				-- TODO: Limit highlight frame after intermission
				-- TODO: Ensure the assignment was created in intermission before increment
				text = "Create another blank assignment but this time during the first intermission.",
				showNextButton = false,
				HighlightFrame = function()
					EnsureAssigneeIsExpanded(self)
					HighlightTimelineSection(self, 200 + 10, -30, 0)
				end,
				callbackName = "TutAssignmentAddedTwo",
			},
			{
				text = "Since the intermission is triggered by boss health, using timed assignments would be unreliable. Instead, the spell the boss casts before transitioning into intermission is used.\nSpell Cast Success is used but Spell Aura Applied would have the same effect.",
				showNextButton = true,
				CreateRequiredWidget = function(localSelf)
					if not self.assignmentEditor then
						HandleCreateAssignmentEditor(self)
					end
					localSelf.frame = self.assignmentEditor.children[1].frame
				end,
				CloseRequiredWidget = function(localSelf)
					if self.assignmentEditor then
						self.assignmentEditor:Release()
					end
					localSelf.frame = nil
				end,
				closeRequiredWidgetOnDecrement = false,
				closeRequiredWidgetOnIncrement = false,
			},
			{
				text = "Instead of clicking beside an Assignee, left-click beside an assignment.",
				showNextButton = false,
				HighlightFrame = function()
					EnsureAssigneeIsExpanded(self)
					HighlightTimelineSection(self, 200 + 10, -30, 1)
				end,
				callbackName = "TutAssignmentAddedThree",
			},
			{
				text = "You can change the time of an assignment by holding left-click and dragging.",
				HighlightFrame = function()
					EnsureAssigneeIsExpanded(self)
					HighlightTimelineSection(self, 200 + 10, -30, 1)
				end,
			},
			{
				text = "Assignments can be duplicated by control-clicking an icon and dragging.",
				HighlightFrame = function()
					EnsureAssigneeIsExpanded(self)
					HighlightTimelineSection(self, 200 + 10, -30, 1)
				end,
			},
		}

		local totalStepCount = #steps

		---@param previousStepIndex integer
		---@param currentStepIndex integer
		local function SetCurrentStep(previousStepIndex, currentStepIndex)
			Private.activeTutorialCallbackName = nil
			local previousStep = steps[previousStepIndex]
			if previousStep then
				if currentStepIndex > previousStepIndex and previousStep.closeRequiredWidgetOnIncrement then
					if previousStep.CloseRequiredWidget then
						previousStep:CloseRequiredWidget()
					end
				elseif currentStepIndex < previousStepIndex and previousStep.closeRequiredWidgetOnDecrement then
					if previousStep.CloseRequiredWidget then
						previousStep:CloseRequiredWidget()
					end
				end
			end

			currentStepIndex = max(1, currentStepIndex)
			if currentStepIndex > totalStepCount then
				self.quickStart:Release()
			else
				local currentStep = steps[currentStepIndex]
				self.quickStart:SetCurrentStep(currentStepIndex, currentStep.text)
				if currentStep.CreateRequiredWidget then
					currentStep:CreateRequiredWidget()
				end
				if currentStep.frame then
					HighlightFrame(currentStep.frame)
					self.quickStart.frame:ClearAllPoints()
					self.quickStart.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kQuickStartOffset)
				elseif currentStep.HighlightFrame then
					currentStep:HighlightFrame()
				end
				if currentStep.callbackName then
					Private.activeTutorialCallbackName = currentStep.callbackName
				end
			end
		end

		local function IncrementCurrentStep()
			SetCurrentStep(self.quickStart.currentStep, self.quickStart.currentStep + 1)
		end

		self.tutorialCallbackObject = {}
		self.RegisterCallback(Private.tutorialCallbackObject, "TutNewPlanDialogOpened", function()
			if ShouldIncrementCurrentStep(self, steps, "TutNewPlanDialogOpened") then
				IncrementCurrentStep()
			end
		end)
		self.RegisterCallback(
			Private.tutorialCallbackObject,
			"TutNewPlanDialogValidatePlan",
			function(_, planName, encounterID)
				return planName:lower():find("tutorial") and encounterID == 2900
			end
		)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutRosterEditorOpened", function()
			if ShouldIncrementCurrentStep(self, steps, "TutRosterEditorOpened") then
				IncrementCurrentStep()
			end
		end)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutSelfAssigneeAdded", function()
			if ShouldIncrementCurrentStep(self, steps, "TutSelfAssigneeAdded") then
				local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan] --[[@as Plan]]
				local shouldActuallyIncrement = false
				if plan then
					local playerName, _ = UnitFullName("player")
					for _, assignment in ipairs(plan.assignments) do
						if assignment.assignee == playerName then
							shouldActuallyIncrement = true
							break
						end
					end
				end
				if shouldActuallyIncrement then
					IncrementCurrentStep()
				end
			end
		end)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutAssignmentSpellChanged", function()
			if ShouldIncrementCurrentStep(self, steps, "TutAssignmentSpellChanged") then
				local shouldActuallyIncrement = false
				local assignmentID = self.assignmentEditor:GetAssignmentID()
				if assignmentID then
					local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
					if assignment then
						local name = C_Spell.GetSpellName(assignment.spellID)
						if name then
							shouldActuallyIncrement = true
						end
					end
				end
				if shouldActuallyIncrement then
					IncrementCurrentStep()
				end
			end
		end)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutAssignmentTextChanged", function()
			if ShouldIncrementCurrentStep(self, steps, "TutAssignmentTextChanged") then
				local shouldActuallyIncrement = false
				local assignmentID = self.assignmentEditor:GetAssignmentID()
				if assignmentID then
					local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
					if assignment then
						if assignment.text:lower() == "use healthstone {6262} at {circle}" then
							shouldActuallyIncrement = true
						end
					end
				end
				if shouldActuallyIncrement then
					IncrementCurrentStep()
				end
			end
		end)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutAssignmentAdded", function()
			if ShouldIncrementCurrentStep(self, steps, "TutAssignmentAdded") then
				IncrementCurrentStep()
			end
		end)
		self.RegisterCallback(Private.tutorialCallbackObject, "TutAssignmentAddedTwo", function()
			if ShouldIncrementCurrentStep(self, steps, "TutAssignmentAddedTwo") then
				IncrementCurrentStep()
			end
		end)

		local quickStart = AceGUI:Create("EPQuickStartDialog")
		quickStart:InitProgressBar(totalStepCount, AddOn.db.profile.preferences.reminder.progressBars.texture)
		quickStart.frame:SetFrameLevel(kQuickStartFrameLevel)
		quickStart:SetCallback("OnRelease", function()
			Private.UnregisterAllCallbacks(Private.tutorialCallbackObject)
			Private.tutorialCallbackObject = nil
			self.quickStart = nil
			highlightBorderFrame:ClearAllPoints()
			highlightBorderFrame:Hide()
			for _, quickStartStep in pairs(steps) do
				if quickStartStep.CloseRequiredWidget then
					quickStartStep:CloseRequiredWidget()
				end
			end
		end)
		quickStart:SetCallback("PreviousButtonClicked", function()
			SetCurrentStep(self.quickStart.currentStep, self.quickStart.currentStep - 1)
		end)
		quickStart:SetCallback("NextButtonClicked", function()
			SetCurrentStep(self.quickStart.currentStep, self.quickStart.currentStep + 1)
		end)
		quickStart:SetCallback("SkipButtonClicked", function()
			self.quickStart:Release()
		end)

		self.quickStart = quickStart
		SetCurrentStep(1, 1)
	end
end
