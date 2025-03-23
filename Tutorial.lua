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
---@return integer|nil
local function FindCurrentAssignmentOrder(self)
	if self.mainFrame and self.mainFrame.timeline then
		if self.assignmentEditor then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				local timelineAssignment, _ = self.mainFrame.timeline.FindTimelineAssignment(
					self.mainFrame.timeline.timelineAssignments,
					assignmentID
				)
				if timelineAssignment then
					return timelineAssignment.order - 1
				end
			end
		end
	end
	return nil
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
local function IsTimeCorrect(self, time)
	if self.assignmentEditor then
		local assignmentID = self.assignmentEditor:GetAssignmentID()
		if assignmentID then
			local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
			if assignment then
				return abs(assignment.time - time) < 0.01
			end
		end
	end
	return false
end

---@param self Private
---@param combatLogEventType CombatLogEventType
local function IsCombatLogEventTypeCorrect(self, combatLogEventType)
	if self.assignmentEditor then
		local assignmentID = self.assignmentEditor:GetAssignmentID()
		if assignmentID then
			local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
			if assignment then
				if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
					if
						assignment--[[@as CombatLogEventAssignment]].combatLogEventType == combatLogEventType
						and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == 442525
					then
						return true
					end
				end
			end
		end
	end
	return false
end

---@param self Private
---@param requiredCount integer
---@param unique boolean|nil
---@param requiredUniqueCount integer|nil
---@param exactUnique boolean|nil
local function IsSpellChanged(self, requiredCount, unique, requiredUniqueCount, exactUnique)
	local count = 0
	local uniqueCount = 0
	local uniqueSet = {}
	if self.assignmentEditor then
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if assignment.spellID > Private.constants.kTextAssignmentSpellID then
				if unique and not uniqueSet[assignment.spellID] then
					uniqueCount = uniqueCount + 1
					uniqueSet[assignment.spellID] = true
				end
				count = count + 1
			end
		end
	end
	if unique and requiredUniqueCount then
		if exactUnique then
			return count >= requiredCount and uniqueCount == requiredUniqueCount
		else
			return count >= requiredCount and uniqueCount >= requiredUniqueCount
		end
	end
	return count >= requiredCount
end

---@param self Private
---@return boolean
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

---@return Assignment|CombatLogEventAssignment|TimedAssignment|nil
local function FindPhaseOneAssignment()
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseOneDuration = boss.phases[1].duration
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.TimedAssignment then
				if
					assignment--[[@as TimedAssignment]].time < phaseOneDuration
				then
					return assignment
				end
			end
		end
	end
	return nil
end

---@param self Private
---@return boolean
local function IsCurrentAssignmentInPhaseOne(self)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseOneDuration = boss.phases[1].duration
		if self.assignmentEditor then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
				if assignment then
					if getmetatable(assignment) == Private.classes.TimedAssignment then
						if
							assignment--[[@as TimedAssignment]].time < phaseOneDuration
						then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

---@return boolean
local function TwoPhaseOneAssignmentsExist()
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

---@param combatLogEventType CombatLogEventType
---@param limitToInIntermission boolean
---@return boolean
local function IntermissionAssignmentExists(combatLogEventType, limitToInIntermission)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseTwoDuration = boss.phases[2].duration
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				local timeOkay = not limitToInIntermission
					or assignment--[[@as CombatLogEventAssignment]].time < phaseTwoDuration
				if
					timeOkay
					and assignment--[[@as CombatLogEventAssignment]].combatLogEventType == combatLogEventType
					and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == 442525
				then
					return true
				end
			end
		end
	end
	return false
end

---@param combatLogEventType CombatLogEventType
---@param limitToInIntermission boolean
---@return Assignment|CombatLogEventAssignment|TimedAssignment|nil
local function FindIntermissionAssignment(combatLogEventType, limitToInIntermission)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseTwoDuration = boss.phases[2].duration
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				local timeOkay = not limitToInIntermission
					or assignment--[[@as CombatLogEventAssignment]].time < phaseTwoDuration
				if
					timeOkay
					and assignment--[[@as CombatLogEventAssignment]].combatLogEventType == combatLogEventType
					and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == 442525
				then
					return assignment
				end
			end
		end
	end
	return nil
end

---@param self Private
---@param combatLogEventType CombatLogEventType
---@param limitToInIntermission boolean
---@return boolean
local function IsCurrentAssignmentInIntermission(self, combatLogEventType, limitToInIntermission)
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phaseTwoDuration = boss.phases[2].duration
		if self.assignmentEditor then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
				if assignment then
					if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
						local timeOkay = not limitToInIntermission
							or assignment--[[@as CombatLogEventAssignment]].time < phaseTwoDuration
						if
							timeOkay
							and assignment--[[@as CombatLogEventAssignment]].combatLogEventType == combatLogEventType
							and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == 442525
						then
							return true
						end
					end
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
local function GetIntermissionOffsets(self)
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

---@param dungeonEncounterID integer
---@return Plan|nil
local function FindTutorialPlan(dungeonEncounterID)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
	for _, plan in pairs(plans) do
		if plan.name:lower():find(L["Tutorial"]:lower()) and plan.dungeonEncounterID == dungeonEncounterID then
			return plan
		end
	end
	return nil
end

---@param dungeonEncounterID integer
---@return boolean
local function CurrentPlanValidates(dungeonEncounterID)
	return AddOn.db.profile.lastOpenPlan:lower():find(L["Tutorial"]:lower()) ~= nil
		and AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].dungeonEncounterID == dungeonEncounterID
end

---@param self Private
---@return boolean
local function ShouldProceedPhaseOne(self)
	local proceed = false
	if self.tutorial then
		if not self.assignmentEditor then
			HandleCreateAssignmentEditor(self)
		end
		proceed = IsCurrentAssignmentInPhaseOne(self)
		if not proceed then
			local assignment = FindPhaseOneAssignment()
			if assignment then
				interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
				return true
			end
		end
	end
	return proceed
end

---@param self Private
---@param combatLogEventType CombatLogEventType
---@param limitToInIntermission boolean
---@return boolean
local function ShouldProceedIntermission(self, combatLogEventType, limitToInIntermission)
	local proceed = false
	if self.tutorial then
		if not self.assignmentEditor then
			HandleCreateAssignmentEditor(self)
		end
		proceed = IsCurrentAssignmentInIntermission(self, combatLogEventType, limitToInIntermission)
		if not proceed then
			local assignment = FindIntermissionAssignment(combatLogEventType, limitToInIntermission)
			if assignment then
				interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
				return true
			end
		end
	end
	return proceed
end

local kAssignmentTextureSize = 30
local kAssignmentSpacing = 2
local kTutorialOffset = 10
local kTutorialFrameLevel = 250

---@param self Private
---@param leftOffset number
---@param rightOffset number
---@param rowNumber integer
---@param additionalVerticalOffset number|nil
local function HighlightTimelineSection(self, leftOffset, rightOffset, rowNumber, additionalVerticalOffset)
	local timeline = self.mainFrame.timeline
	if timeline then
		local assignmentTimelineFrame = timeline.assignmentTimeline.frame
		highlightBorderFrame:SetFrameStrata(assignmentTimelineFrame:GetFrameStrata())
		highlightBorderFrame:SetFrameLevel(assignmentTimelineFrame:GetFrameLevel() + 50)
		highlightBorderFrame:ClearAllPoints()
		local x = -kHighlightPadding + leftOffset
		local assignmentHeight = (kAssignmentTextureSize + kAssignmentSpacing) * rowNumber
		local y = kHighlightPadding - assignmentHeight
		highlightBorderFrame:SetPoint("TOPLEFT", assignmentTimelineFrame, x, y)
		x = kHighlightPadding + rightOffset
		y = kHighlightPadding - assignmentHeight
		highlightBorderFrame:SetPoint("TOPRIGHT", assignmentTimelineFrame, x, y)
		highlightBorderFrame:SetHeight(kAssignmentTextureSize + 2 * kHighlightPadding)
		highlightBorderFrame:Show()
		self.tutorial.frame:ClearAllPoints()
		if additionalVerticalOffset then
			self.tutorial.frame:SetPoint(
				"BOTTOM",
				highlightBorderFrame,
				"TOP",
				0,
				kTutorialOffset + additionalVerticalOffset
			)
		else
			self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
		end
	end
end

---@class TutorialStep
---@field text string
---@field enableNextButton boolean|fun():boolean
---@field frame Frame|table|nil
---@field callbackName string|nil
---@field OnStepActivated fun(self: TutorialStep)|nil
---@field PreStepDeactivated fun(self: TutorialStep, incrementing: boolean, cleanUp: boolean|nil)|nil
---@field HighlightFrame fun()|nil
---@field additionalVerticalOffset number|nil

---@param self Private
---@param setCurrentStep fun(previousStepIndex: integer, currentStepIndex: integer)
---@return table<integer, TutorialStep>
local function CreateTutorialSteps(self, setCurrentStep)
	local steps = {}
	local createdTutorialPlan = false
	---@type table<integer, TutorialStep>
	steps = {
		{
			text = format(
				"%s |c%s%s|r %s.",
				"This interactive tutorial walks you the key features of Encounter Planner. You can close this window at any time and pick up where you left by clicking the",
				"cffffd10",
				"Tutorial button",
				"located in the lower left of the main window"
			),
			enableNextButton = true,
			OnStepActivated = function(_)
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("CENTER", UIParent)
				local x, y = self.tutorial.frame:GetLeft(), self.tutorial.frame:GetTop()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
			end,
		},
		{
			text = "The Menu Bar contains high level categories for managing plans, modifying bosses, editing rosters, and settings.",
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.menuButtonContainer.frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				if not incrementing then
					highlightBorderFrame:ClearAllPoints()
					highlightBorderFrame:Hide()
				end
				localSelf.frame = nil
			end,
		},
		{
			text = "Click the Plan button, and then click New Plan.",
			enableNextButton = function()
				return CurrentPlanValidates(2900)
			end,
			callbackName = "TutNewPlanDialogOpened",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "planCreated" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.menuButtonContainer.children[1].frame
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r (|c%s%s|r) %s |c%s%s|r.",
				"This plan will be used throughout this tutorial. Select",
				"cffffd10",
				"Brew Master Aldryr",
				"cffffd10",
				"Cinderbrew Meadery",
				"as the boss, and name the plan",
				"cffffd10",
				L["Tutorial"]
			),
			enableNextButton = function()
				return CurrentPlanValidates(2900)
			end,
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
									and planName:lower():find(L["Tutorial"]:lower()) ~= nil
									and encounterID == 2900
							)
						end
					elseif category == "created" then
						createdTutorialPlan = true
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "closed" then
						if self.tutorial then
							self.tutorial:Release()
						end
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
							and planName:lower():find(L["Tutorial"]:lower()) ~= nil
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
			text = format(
				"%s |c%s%s|r %s.",
				"Click the",
				"cffffd10",
				"Roster button",
				"to open the Roster Editor for the plan"
			),
			enableNextButton = false,
			frame = self.mainFrame.menuButtonContainer.children[3].frame,
			callbackName = "TutRosterEditorOpened",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "rosterEditorOpened" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
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
				"is unique to the current plan. Roster members must be added here before assignments can be assigned to them. The creator of the plan is automatically added"
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
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				localSelf.frame = self.rosterEditor.tabContainer.children[1].frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				if not incrementing and self.rosterEditor then
					self.rosterEditor:Release()
				end
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s |c%s%s|r.",
				"The",
				"cffffd10",
				"Shared Roster",
				"is independent of plans and can and be used quickly populate the",
				"cffffd10",
				"Current Plan Roster"
			),
			enableNextButton = true,
			callbackName = "TutRosterEditorTwo",
			OnStepActivated = function(localSelf)
				if not self.rosterEditor then
					self.CreateRosterEditor("Shared Roster")
				end
				self.rosterEditor:SetCurrentTab("Shared Roster")
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "closed" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				localSelf.frame = self.rosterEditor.tabContainer.children[2].frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				if incrementing and self.rosterEditor then
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
			additionalVerticalOffset = 10,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Reminders can be toggled on and off on a per-plan basis. The yellow bell icon in the",
				"cffffd10",
				"Current Plan Dropdown",
				"also indicates whether reminders are enabled for a plan.\n\nUncheck the check box to disable reminders for this plan"
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
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "assigneeAdded" and IsSelfPresentInPlan() then
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
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
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
				"determines what activates an assignment. It can either be relative to the start of an encounter (Fixed Time) or relative to a combat log event. Leave it as Fixed Time"
			),
			enableNextButton = true,
			callbackName = "TutAssignmentTrigger",
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.children[1].frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = format("%s |c%s%s|r %s.", "Set the", "cffffd10", "Time", "to 30 seconds"),
			enableNextButton = function()
				return IsTimeCorrect(self, 30.0)
			end,
			callbackName = "TutAssignmentTime",
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsTimeCorrect(self, 30.0) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.timeContainer.frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
				localSelf.frame = nil
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s |c%s%s|r.",
				"Check the",
				"cffffd10",
				"Spell checkbox",
				"and select a spell from the",
				"cffffd10",
				"Spell dropdown"
			),
			enableNextButton = function()
				return IsSpellChanged(self, 1)
			end,
			callbackName = "TutAssignmentSpellChanged",
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsSpellChanged(self, 1) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
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
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 0, -30, 1)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s. %s |c%s%s|r %s",
				"Spell cooldown durations can be overridden in the",
				"cffffd10",
				"Cooldown Overrides",
				"section of the Preferences Menu",
				"The alternating grey cooldown textures can be disabled in the",
				"cffffd10",
				"View",
				"section"
			),
			enableNextButton = true,
			frame = self.mainFrame.menuButtonContainer.children[4].frame,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Assignment",
				"cffffd10",
				"Text",
				"is displayed on reminder messages and progress bars. If blank, the spell icon and name are automatically used"
			),
			enableNextButton = true,
			callbackName = "TutAssignmentAutoText",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "released" then
						if self.tutorial then
							self.tutorial:Release()
						end
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
				"Icons can be inserted into text by enclosing a spell ID, raid marker name, or similar in curly braces. Set the",
				"cffffd10",
				"Text",
				"to the following:\nUse Healthstone {6262} at {circle}\nand press enter."
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
					if category == "assignmentEditorDataChanged" then
						if IsTextChanged(self) then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					elseif category == "released" then
						if self.tutorial then
							self.tutorial:Release()
						end
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
			text = "Create a blank assignment in Phase 1 by left-clicking the timeline beside an assignee.",
			enableNextButton = function()
				return TwoPhaseOneAssignmentsExist()
			end,
			callbackName = "TutAssignmentAddedOne",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "added" and TwoPhaseOneAssignmentsExist() then
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
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, GetPhaseOneRightOffset(self), 0, 32)
			end,
		},
		{
			text = "The assignment is created relative to the start of the encounter since it was clicked within Phase 1.",
			enableNextButton = true,
			callbackName = "TutAssignmentAddedOneTime",
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
			HighlightFrame = function()
				local frame = self.assignmentEditor.children[1].frame
				highlightBorderFrame:SetFrameStrata(frame:GetFrameStrata())
				highlightBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
				highlightBorderFrame:ClearAllPoints()
				highlightBorderFrame:SetPoint("TOPLEFT", frame, -kHighlightPadding, kHighlightPadding)
				local lowerFrame = self.assignmentEditor.timeContainer.frame
				highlightBorderFrame:SetPoint("BOTTOMRIGHT", lowerFrame, kHighlightPadding, -kHighlightPadding)
				highlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Change the",
				"cffffd10",
				"Spell",
				"to something different from first assignment you created"
			),
			enableNextButton = function()
				return IsSpellChanged(self, 2, true, 2)
			end,
			callbackName = "TutAssignmentSpellChangedTwo",
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsSpellChanged(self, 2, true, 2) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
				localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Create another blank assignment, this time during the first intermission.",
			enableNextButton = function()
				return IntermissionAssignmentExists("SCS", true)
			end,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				local left, right = GetIntermissionOffsets(self)
				HighlightTimelineSection(self, left, right, 0, 32)
			end,
			callbackName = "TutAssignmentAddedTwo",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "added" and IntermissionAssignmentExists("SCS", true) then
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
				if ShouldProceedIntermission(self, "SCS", true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.children[1].frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Change the time of an assignment by left-clicking an icon and dragging it.\nWhen dragging a combat log event assignment, it can only be placed after the boss ability, as the assignment must occur afterward.",
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, FindCurrentAssignmentOrder(self) or 1)
			end,
			callbackName = "TutAssignmentMovedByDragging",
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SCS", false) then
					self.RegisterCallback(
						Private.tutorialCallbackObject,
						localSelf.callbackName,
						function(_, timeDifference)
							if self.activeTutorialCallbackName ~= localSelf.callbackName then
								return
							end
							if type(timeDifference) == "number" and timeDifference > 0.0 then
								self.tutorial.nextButton:SetEnabled(true)
							end
						end
					)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s.",
				"Change the",
				"cffffd10",
				"Spell",
				"to one of the spells you used in another assignment"
			),
			enableNextButton = function()
				return IsSpellChanged(self, 3, true, 2, true)
			end,
			callbackName = "TutAssignmentSpellChangedThree",
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SCS", false) or ShouldProceedIntermission(self, "SAR", false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsSpellChanged(self, 3, true, 2, true) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
				localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s |c%s%s|r.",
				"Change the",
				"cffffd10",
				"Trigger",
				"to",
				"cffffd10",
				"Spell Aura Removed"
			),
			callbackName = "TutAssignmentChangeCombatLogEventType",
			enableNextButton = function()
				return IsCombatLogEventTypeCorrect(self, "SAR")
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SCS", false) or ShouldProceedIntermission(self, "SAR", false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "assignmentEditorDataChanged" then
							print(IsCombatLogEventTypeCorrect(self, "SAR"))
							if IsCombatLogEventTypeCorrect(self, "SAR") then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.children[1].frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = format(
				"%s |c%s%s|r %s |c%s%s|r %s.",
				"The time relative to the event stayed the same, but the icon moved forward since the",
				"cffffd10",
				"Spell Aura Removed",
				"event occurs after the",
				"cffffd10",
				"Spell Cast Start",
				"event"
			),
			callbackName = "TutAssignmentChangeCombatLogEventTypeExplain",
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SAR", false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.callbackName then
							return
						end
						if category == "released" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.children[1].frame
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
				self.UnregisterCallback(self.tutorialCallbackObject, localSelf.callbackName)
			end,
		},
		{
			text = "Instead of left-clicking beside an assignee, create an assignment by left-clicking the timeline beside a spell.",
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, FindCurrentAssignmentOrder(self) or 1)
			end,
			callbackName = "TutAssignmentAddedThree",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "added" then
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
			text = "The new assignment is created using the matching spell.",
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
			end,
		},
		{
			text = "Duplicate an assignment by control-clicking an icon and dragging.",
			enableNextButton = false,
			HighlightFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSection(self, 200 + 10, -30, FindCurrentAssignmentOrder(self) or 1)
			end,
			callbackName = "TutAssignmentDuplicated",
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.callbackName, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.callbackName then
						return
					end
					if category == "duplicated" then
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
			text = "The duplicated assignment inherits all properties, besides time, from the original and is independent of it.",
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.frame = nil
			end,
		},
		{
			text = "Tutorial Complete!",
			enableNextButton = true,
			OnStepActivated = function(_)
				highlightBorderFrame:ClearAllPoints()
				highlightBorderFrame:Hide()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("CENTER", UIParent)
				local x, y = self.tutorial.frame:GetLeft(), self.tutorial.frame:GetTop()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
			end,
		},
	}
	return steps
end

function Private:OpenTutorial()
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
			AddOn.db.global.lastTutorialStep = min(currentStepIndex, totalStepCount)
			if currentStepIndex > totalStepCount then
				AddOn.db.global.tutorialCompleted = true
				AddOn.db.global.lastTutorialStep = 1
				self.tutorial:Release()
			else
				local currentStep = steps[currentStepIndex]
				if currentStep.callbackName then
					Private.activeTutorialCallbackName = currentStep.callbackName
				end
				self.tutorial.currentStep = currentStepIndex
				if currentStep.OnStepActivated then
					currentStep:OnStepActivated()
				end
				local enable = false
				if type(currentStep.enableNextButton) == "function" then
					enable = currentStep.enableNextButton()
				elseif type(currentStep.enableNextButton) == "boolean" then
					enable = currentStep.enableNextButton --[[@as boolean]]
				end
				self.tutorial:SetCurrentStep(currentStepIndex, currentStep.text, enable)
				if currentStep.frame then
					HighlightFrame(currentStep.frame)
					self.tutorial.frame:ClearAllPoints()
					local offset = kTutorialOffset
					if currentStep.additionalVerticalOffset then
						offset = offset + currentStep.additionalVerticalOffset
					end
					self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, offset)
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
			},
		}

		local tutorial = AceGUI:Create("EPTutorial")
		tutorial:InitProgressBar(totalStepCount, AddOn.db.profile.preferences.reminder.progressBars.texture)
		tutorial.frame:SetFrameLevel(kTutorialFrameLevel)
		tutorial:SetCallback("OnRelease", function()
			self.tutorial = nil
			Private.UnregisterAllCallbacks(Private.tutorialCallbackObject)
			highlightBorderFrame:ClearAllPoints()
			highlightBorderFrame:Hide()
			for _, step in pairs(steps) do
				if step.PreStepDeactivated then
					step:PreStepDeactivated(true, true)
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
		tutorial:SetCallback("CloseButtonClicked", function()
			self.tutorial:Release()
		end)

		self.tutorial = tutorial
		if AddOn.db.global.lastTutorialStep > 3 then
			local plan = FindTutorialPlan(2900)
			if plan then
				AddOn.db.profile.lastOpenPlan = plan.name
				interfaceUpdater.UpdateFromPlan(plan)
			else
				AddOn.db.global.lastTutorialStep = 2
			end
		end

		SetCurrentStep(1, AddOn.db.global.lastTutorialStep)
	end
end
