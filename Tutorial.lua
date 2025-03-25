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

local abs = math.abs
local AceGUI = LibStub("AceGUI-3.0")
local Clamp = Clamp
local concat = table.concat
local format = string.format
local getmetatable = getmetatable
local ipairs = ipairs
local max = math.max
local pairs = pairs
local tinsert = tinsert
local type = type

local kAbilityEntryWidth = 200
local kAssignmentSpacing = 2
local kAssignmentTextureSize = 30
local kBrewmasterAldryrEncounterID = 2900
local kHappyHourSpellID = 442525
local kHighlightPadding = 2
local kTutorialFrameLevel = 250
local kTutorialOffset = 10

local playerName, _ = UnitFullName("player")

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

---@param frame Frame
local function HighlightFrame(frame)
	if not frame then
		return
	end

	highlightBorderFrame:SetParent(UIParent)
	highlightBorderFrame:SetFrameStrata(frame:GetFrameStrata())
	highlightBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
	highlightBorderFrame:ClearAllPoints()
	highlightBorderFrame:SetPoint("TOPLEFT", frame, -kHighlightPadding, kHighlightPadding)
	highlightBorderFrame:SetPoint("BOTTOMRIGHT", frame, kHighlightPadding, -kHighlightPadding)
	highlightBorderFrame:Show()
end

---@param self Private
---@param leftOffset number
---@param rightOffset number
---@param rowNumber integer
---@param additionalVerticalOffset number|nil
local function HighlightTimelineSectionAndPositionTutorialFrame(
	self,
	leftOffset,
	rightOffset,
	rowNumber,
	additionalVerticalOffset
)
	local timeline = self.mainFrame.timeline
	if timeline then
		local timelineFrame = timeline.assignmentTimeline.timelineFrame
		highlightBorderFrame:SetParent(timelineFrame)
		highlightBorderFrame:SetFrameStrata(timelineFrame:GetFrameStrata())
		highlightBorderFrame:SetFrameLevel(timelineFrame:GetFrameLevel() + 50)
		highlightBorderFrame:ClearAllPoints()
		local x = leftOffset
		local assignmentHeight = (kAssignmentTextureSize + kAssignmentSpacing) * rowNumber
		local y = -assignmentHeight
		highlightBorderFrame:SetPoint("TOPLEFT", timelineFrame, x, y)
		x = rightOffset
		y = -assignmentHeight
		highlightBorderFrame:SetPoint("TOPRIGHT", timelineFrame, x, y)
		highlightBorderFrame:SetHeight(kAssignmentTextureSize)
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

local function CreateAssignmentIfNecessary()
	local assignments = GetCurrentAssignments()
	local needToCreateNewAssignment = true
	for _, assignment in ipairs(assignments) do
		if assignment.assignee == playerName then
			needToCreateNewAssignment = false
			interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
			break
		end
	end
	if needToCreateNewAssignment then
		local name, entry = utilities.CreateRosterEntryForSelf()
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
local function HandleCreateAssignmentEditor(self)
	self.CreateAssignmentEditor()

	local timelineRows = AddOn.db.profile.preferences.timelineRows
	timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)

	CreateAssignmentIfNecessary()
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
local function ScrollCurrentAssignmentIntoView(self)
	local timeline = self.mainFrame.timeline
	if timeline then
		if self.assignmentEditor then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				local timelineAssignment, _ = self.mainFrame.timeline.FindTimelineAssignment(
					self.mainFrame.timeline.timelineAssignments,
					assignmentID
				)
				if timelineAssignment then
					timeline:ScrollAssignmentIntoView(timelineAssignment.assignment.uniqueID)
				end
			end
		end
	end
end

---@param self Private
local function EnsureAssigneeIsExpanded(self)
	local timeline = self.mainFrame.timeline
	if timeline then
		local assignmentContainer = timeline:GetAssignmentContainer()
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		for _, child in ipairs(assignmentContainer.children) do
			local key = child--[[@as EPAbilityEntry]]:GetKey()
			if type(key) == "string" then
				if key == playerName then
					if collapsed[key] == true then
						collapsed[key] = false
						interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
					end
				end
			end
		end
		ScrollCurrentAssignmentIntoView(self)
	end
end

---@return boolean
local function IsSelfPresentInPlan()
	local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan] --[[@as Plan]]
	if plan then
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
---@param spellID integer
local function IsCombatLogEventCorrect(self, combatLogEventType, spellID)
	if self.assignmentEditor then
		local assignmentID = self.assignmentEditor:GetAssignmentID()
		if assignmentID then
			local assignment = utilities.FindAssignmentByUniqueID(GetCurrentAssignments(), assignmentID)
			if assignment then
				if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
					if
						assignment--[[@as CombatLogEventAssignment]].combatLogEventType == combatLogEventType
						and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == spellID
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
---@param requiredCount integer The required count of spells that have spell ID > 1.
---@param unique boolean|nil Whether to add a unique spell count requirement.
---@param requiredUniqueCount integer|nil Required amount of unique spells that have spell ID > 1.
---@param exactUnique boolean|nil Whether to require the exact number of requiredUniqueCount.
local function CountSpells(self, requiredCount, unique, requiredUniqueCount, exactUnique)
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
				if assignment.text:lower() == L["use {6262} at {circle}"] then
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
---@param limitToInIntermission boolean Whether to only count as valid if the time is less than intermission duration.
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
---@param spellID integer
---@param limitToInIntermission boolean Whether to only count as valid if the time is less than intermission duration.
---@return Assignment|CombatLogEventAssignment|TimedAssignment|nil
local function FindIntermissionAssignment(combatLogEventType, spellID, limitToInIntermission)
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
					and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == spellID
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
---@param spellID integer
---@param limitToInIntermission boolean Whether to only count as valid if the time is less than intermission duration.
---@return boolean
local function IsCurrentAssignmentInIntermission(self, combatLogEventType, spellID, limitToInIntermission)
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
							and assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID == spellID
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
---@return number
local function GetPhaseOffsets(self, startPhaseIndex, endPhaseIndex)
	local leftOffset, rightOffset = 0.0, 0.0
	local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
	if boss and self.mainFrame and self.mainFrame.timeline then
		local startTime = 0.0
		local endTime = 0.0

		if boss.phases[startPhaseIndex] then
			for index, phase in ipairs(boss.phases) do
				if index == startPhaseIndex then
					break
				end
				startTime = startTime + phase.duration
			end
		end
		if endPhaseIndex > startPhaseIndex then
			for index, phase in ipairs(boss.phases) do
				endTime = endTime + phase.duration
				if index == endPhaseIndex then
					break
				end
			end
		elseif boss.phases[endPhaseIndex] then
			endTime = startTime + boss.phases[endPhaseIndex].duration
		end
		local startOffsetFromLeft = self.mainFrame.timeline:GetOffsetFromTime(startTime)
		local endOffsetFromLeft = self.mainFrame.timeline:GetOffsetFromTime(endTime)
		local scrollFrameWidth = self.mainFrame.timeline.assignmentTimeline.timelineFrame:GetWidth()
		leftOffset = startOffsetFromLeft
		rightOffset = endOffsetFromLeft - scrollFrameWidth
	end
	return leftOffset, rightOffset
end

---@param encounterID integer
---@return Plan|nil
local function FindTutorialPlan(encounterID)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
	for _, plan in pairs(plans) do
		if plan.name:lower():find(L["Tutorial"]:lower()) and plan.dungeonEncounterID == encounterID then
			return plan
		end
	end
	return nil
end

---@param encounterID integer
---@return boolean
local function IsCurrentPlanValidTutorial(encounterID)
	return AddOn.db.profile.lastOpenPlan:lower():find(L["Tutorial"]:lower()) ~= nil
		and AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].dungeonEncounterID == encounterID
end

---@param planName string
---@param currentEncounterID integer
---@param encounterID integer
---@return boolean
local function ValidateNewTutorialPlan(planName, currentEncounterID, encounterID)
	return planName ~= ""
		and not AddOn.db.profile.plans[planName]
		and planName:lower():find(L["Tutorial"]:lower()) ~= nil
		and currentEncounterID == encounterID
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
		local assignment = FindPhaseOneAssignment()
		if not proceed then
			if assignment then
				interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
				self.mainFrame.timeline:ScrollAssignmentIntoView(assignment.uniqueID)
				return true
			end
		elseif assignment then
			self.mainFrame.timeline:ScrollAssignmentIntoView(assignment.uniqueID)
		end
	end
	return proceed
end

---@param self Private
---@param combatLogEventType CombatLogEventType
---@param spellID integer
---@param limitToInIntermission boolean
---@return boolean
local function ShouldProceedIntermission(self, combatLogEventType, spellID, limitToInIntermission)
	local proceed = false
	if self.tutorial then
		if not self.assignmentEditor then
			HandleCreateAssignmentEditor(self)
		end
		proceed = IsCurrentAssignmentInIntermission(self, combatLogEventType, spellID, limitToInIntermission)
		local assignment = FindIntermissionAssignment(combatLogEventType, spellID, limitToInIntermission)
		if not proceed then
			if assignment then
				interfaceUpdater.UpdateFromAssignment(GetCurrentBossDungeonEncounterID(), assignment, true, true, false)
				self.mainFrame.timeline:ScrollAssignmentIntoView(assignment.uniqueID)
				return true
			end
		elseif assignment then
			self.mainFrame.timeline:ScrollAssignmentIntoView(assignment.uniqueID)
		end
	end
	return proceed
end

---@param ... string|table<integer, string>
---@return string
local function FormatText(...)
	local args = { ... }
	local formatted = {}

	for i = 1, #args do
		if type(args[i]) == "table" then
			-- Wrap text in color if it's marked for highlighting
			tinsert(formatted, format("|c%s%s|r", "cffffd10", args[i][1]))
		else
			tinsert(formatted, args[i])
		end
	end

	return concat(formatted, " ") .. "."
end

---@class TutorialStep
---@field name string
---@field text string
---@field enableNextButton boolean|fun():boolean
---@field frame Frame|table|nil
---@field OnStepActivated fun(self: TutorialStep)|nil
---@field PreStepDeactivated fun(self: TutorialStep, incrementing: boolean, cleanUp: boolean|nil)|nil
---@field HighlightFrameAndPositionTutorialFrame fun()|nil
---@field additionalVerticalOffset number|nil
---@field ignoreNextAssignmentEditorReleased boolean|nil

---@param self Private
---@param setCurrentStep fun(previousStepIndex: integer, currentStepIndex: integer)
---@return table<integer, TutorialStep>
local function CreateTutorialSteps(self, setCurrentStep)
	local steps = {}
	local createdTutorialPlan = false
	local cinderBrewMeaderyName = self.dungeonInstances[2661].name
	local brewmasterAldryrName = bossUtilities.GetBoss(kBrewmasterAldryrEncounterID).name

	---@type table<integer, TutorialStep>
	steps = {
		{
			name = "start",
			text = FormatText(
				L["This interactive tutorial walks you the key features of Encounter Planner. You can close this window at any time and resume where you left off by clicking the"],
				{ L["Tutorial"] },
				L["button"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("CENTER", UIParent)
				local x, y = self.tutorial.frame:GetLeft(), self.tutorial.frame:GetTop()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
				localSelf.frame = self.mainFrame.tutorialButton.frame
			end,
		},
		{
			name = "menuBar",
			text = FormatText(
				L["The"],
				{ L["Menu Bar"] },
				L["contains high level categories for managing plans, modifying bosses, editing rosters, and settings"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.menuButtonContainer.frame
			end,
		},
		{
			name = "createNewPlan",
			text = FormatText(
				L["Click the"],
				{ L["Plan"] },
				L["menu button"] .. ",",
				L["and then click"],
				{ L["New Plan"] }
			),
			enableNextButton = function()
				return IsCurrentPlanValidTutorial(kBrewmasterAldryrEncounterID)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "newPlanButtonClicked" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.menuButtonContainer.children[1].frame
			end,
		},
		{
			name = "newPlanDialog",
			text = FormatText(
				L["This plan will be used throughout the tutorial. Select"],
				{ brewmasterAldryrName },
				{ "(" .. cinderBrewMeaderyName .. ")" },
				L["as the boss, and name the plan"],
				{ L["Tutorial"] }
			),
			enableNextButton = function()
				return IsCurrentPlanValidTutorial(kBrewmasterAldryrEncounterID)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "newPlanDialogValidate" then
						if self.newPlanDialog then
							local planName = self.newPlanDialog.planNameLineEdit:GetText():trim()
							local encounterID = self.newPlanDialog.bossDropdown:GetValue()
							self.newPlanDialog.createButton:SetEnabled(
								ValidateNewTutorialPlan(planName, encounterID, kBrewmasterAldryrEncounterID)
							)
						end
					elseif category == "newPlanDialogPlanCreated" then
						createdTutorialPlan = true
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "newPlanDialogClosed" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				if not self.newPlanDialog then
					self.CreateNewPlanDialog()
				end

				if createdTutorialPlan then
					if self.tutorial then
						self.tutorial.nextButton:SetEnabled(true)
					end
				elseif self.newPlanDialog then
					local planName = self.newPlanDialog.planNameLineEdit:GetText():trim()
					local encounterID = self.newPlanDialog.bossDropdown:GetValue()
					self.newPlanDialog.createButton:SetEnabled(
						ValidateNewTutorialPlan(planName, encounterID, kBrewmasterAldryrEncounterID)
					)
				end
				localSelf.frame = self.newPlanDialog.frame
			end,
			PreStepDeactivated = function(_)
				if self.newPlanDialog then
					self.newPlanDialog:Release()
				end
			end,
		},
		{
			name = "openRosterEditor",
			text = FormatText(
				L["Click the"],
				{ L["Roster"] },
				L["menu button"],
				L["to open the Roster Editor for the plan"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "rosterEditorOpened" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.menuButtonContainer.children[3].frame
			end,
		},
		{
			name = "currentPlanRoster",
			text = FormatText(
				L["The"],
				{ L["Current Plan Roster"] },
				L["is unique to the current plan. Roster members must be added here before assignments can be assigned to them. The creator of the plan is automatically added"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.rosterEditor then
					self.CreateRosterEditor("Current Plan Roster")
				end
				self.rosterEditor:SetCurrentTab("Current Plan Roster")
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "rosterEditorClosed" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				localSelf.frame = self.rosterEditor.tabContainer.children[1].frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				if not incrementing and self.rosterEditor then
					self.rosterEditor:Release()
				end
			end,
		},
		{
			name = "sharedRoster",
			text = FormatText(
				L["The"],
				{ L["Shared Roster"] },
				L["is independent of plans and can and be used quickly populate the"],
				{ L["Current Plan Roster"] }
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.rosterEditor then
					self.CreateRosterEditor("Shared Roster")
				end
				self.rosterEditor:SetCurrentTab("Shared Roster")
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "rosterEditorClosed" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				localSelf.frame = self.rosterEditor.tabContainer.children[2].frame
			end,
			PreStepDeactivated = function(localSelf, incrementing)
				if incrementing and self.rosterEditor then
					self.rosterEditor:Release()
				end
			end,
		},
		{
			name = "currentPlanBar",
			text = FormatText(
				L["The"],
				{ L["Current Plan Bar"] },
				L["shows information and settings for the current plan"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.children[1].frame
			end,
		},
		{
			name = "currentPlanDropdown",
			text = L["The current plan is selected using this dropdown. You can rename the current plan by double clicking the dropdown."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.planDropdown.frame
			end,
			additionalVerticalOffset = 10,
		},
		{
			name = "toggleReminders",
			text = FormatText(
				L["Reminders can be toggled on and off for each plan using this checkbox or globally in the"],
				{ L["Reminder"] },
				L["section of the"],
				{ L["Preferences"] },
				L["menu"] .. ".",
				L["The yellow bell icon in the"],
				{ L["Current Plan"] },
				L["dropdown"],
				L["also indicates whether reminders are enabled for a plan.\n\nUncheck the checkbox to disable reminders for this plan"]
			),
			enableNextButton = function()
				if Private.mainFrame and not Private.mainFrame.planReminderEnableCheckBox:IsChecked() then
					return true
				end
				return false
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(self.tutorialCallbackObject, localSelf.name, function(_, checked)
					if self.activeTutorialCallbackName ~= localSelf.name then
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
		},
		{
			name = "addAssignee",
			text = FormatText(
				L["Add yourself to the Assignment Timeline by selecting your character name from the Individual menu in the"],
				{ L["Add Assignee"] },
				L["dropdown"]
			),
			enableNextButton = function()
				return IsSelfPresentInPlan()
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "assigneeAdded" and IsSelfPresentInPlan() then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.timeline.addAssigneeDropdown.frame
			end,
		},
		{
			name = "assignmentEditorOpened",
			text = FormatText(
				L["The"],
				{ L["Assignment Editor"] },
				L["is opened after adding an assignee. It can also by opened by left-clicking an assignment spell icon in the Assignment Timeline"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorReleased" then
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
			PreStepDeactivated = function(_, incrementing)
				if not incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "assignmentTrigger",
			text = FormatText(
				L["The"],
				{ L["Trigger"] },
				L["determines what activates an assignment. It can either be relative to the start of an encounter (Fixed Time) or relative to a combat log event. Leave it as Fixed Time"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorReleased" then
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
		},
		{
			name = "assignmentTime",
			text = FormatText(L["Set the"], { L["Time"] }, L["to 15 seconds and press enter"]),
			enableNextButton = function()
				return IsTimeCorrect(self, 15.0)
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsTimeCorrect(self, 15.0) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "assignmentSpell",
			text = FormatText(L["Check the"], { L["Spell"] }, L["checkbox"], L["and select a spell from the dropdown"]),
			enableNextButton = function()
				return CountSpells(self, 1)
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if CountSpells(self, 1) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "assignmentTimelineUpdated",
			text = L["The Assignment Timeline updates to reflect the spell. Its cooldown duration is represented by an alternating grey texture. If multiple instances of the same spell overlap, the rightmost spell icon will be tinted red."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "timelineFrameMouseWheel" then
						HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, 1)
					end
				end)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, 1)
			end,
		},
		{
			name = "spellCooldownDurations",
			text = FormatText(
				L["Spell cooldown durations can be overridden in the"],
				{ L["Cooldown Overrides"] },
				L["section of the"],
				{ L["Preferences"] },
				L["menu"] .. ".",
				L["The alternating grey cooldown textures can be disabled in the"],
				{ L["View"] },
				L["section"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.menuButtonContainer.children[4].frame
			end,
		},
		{
			name = "zoomAndPan",
			text = L["Zoom in and out horizontally on either timeline by pressing Ctrl + Mouse Scroll. Pan the view to the left and right by holding right-click."],
			enableNextButton = true,
			HighlightFrameAndPositionTutorialFrame = function()
				local timeline = self.mainFrame.timeline
				if timeline then
					local bossAbilityTimelineFrame = timeline.bossAbilityTimeline.frame
					local assignmentTimelineFrame = timeline.assignmentTimeline.frame
					highlightBorderFrame:SetFrameStrata(bossAbilityTimelineFrame:GetFrameStrata())
					highlightBorderFrame:SetFrameLevel(bossAbilityTimelineFrame:GetFrameLevel() + 50)
					highlightBorderFrame:ClearAllPoints()
					local x = -kHighlightPadding + kAbilityEntryWidth + 10
					local y = kHighlightPadding
					highlightBorderFrame:SetPoint("TOPLEFT", bossAbilityTimelineFrame, x, y)
					x = -30
					y = -kHighlightPadding
					highlightBorderFrame:SetPoint("BOTTOMRIGHT", assignmentTimelineFrame, x, y)
					highlightBorderFrame:Show()
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
				end
			end,
		},
		{
			name = "assignmentText",
			text = FormatText(
				L["Assignment"],
				{ L["Text"] },
				L["is displayed on reminder messages and progress bars. If blank, the spell icon and name are automatically used"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "assignmentEditorReleased" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local textFrame = self.assignmentEditor.optionalTextContainer.frame
				local previewFrame = self.assignmentEditor.previewContainer.frame
				highlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
				highlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
				highlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
				highlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, -2)
				highlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
			end,
		},
		{
			name = "assignmentTextIconInsert",
			text = FormatText(
				L["Icons can be inserted into text by enclosing a spell ID, raid marker name, or similar in curly braces. Set the"],
				{ L["Text"] },
				L["to the following:\nUse {6262} at {circle}\nand press enter"]
			),
			enableNextButton = function()
				return IsTextChanged(self)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "assignmentEditorDataChanged" then
						if IsTextChanged(self) then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "createAssignmentBesideAssignee",
			text = L["Create a blank assignment in Phase 1 by left-clicking the timeline beside an assignee."],
			enableNextButton = function()
				return TwoPhaseOneAssignmentsExist()
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "added" and TwoPhaseOneAssignmentsExist() then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "timelineFrameMouseWheel" then
						local leftOffset, rightOffset = GetPhaseOffsets(self, 1, 1)
						HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				self.mainFrame.timeline:SetHorizontalScroll(0)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				local leftOffset, rightOffset = GetPhaseOffsets(self, 1, 1)
				HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
			end,
		},
		{
			name = "createAssignmentBesideAssigneeExplain",
			text = L["The assignment is created relative to the start of the encounter since it was clicked within Phase 1."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local frame = self.assignmentEditor.children[1].frame
				highlightBorderFrame:SetFrameStrata(frame:GetFrameStrata())
				highlightBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
				highlightBorderFrame:SetPoint("TOPLEFT", frame, -kHighlightPadding, kHighlightPadding)
				local lowerFrame = self.assignmentEditor.timeContainer.frame
				highlightBorderFrame:SetPoint("BOTTOMRIGHT", lowerFrame, kHighlightPadding, -kHighlightPadding)
				highlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset)
			end,
		},
		{
			name = "assignmentTimeTwo",
			text = FormatText(L["Set the"], { L["Time"] }, L["to 20 seconds and press enter"]),
			enableNextButton = function()
				return IsTimeCorrect(self, 20.0)
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsTimeCorrect(self, 20.0) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "createAssignmentBesideAssigneeChangeSpell",
			text = FormatText(
				L["Change the"],
				{ L["Spell"] },
				L["to something different from first assignment you created"]
			),
			enableNextButton = function()
				return CountSpells(self, 2, true, 2)
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedPhaseOne(self) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if CountSpells(self, 2, true, 2) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "createAssignmentDuringIntermission",
			text = L["Create another blank assignment, this time during the first intermission."],
			enableNextButton = function()
				return IntermissionAssignmentExists("SCS", true)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				local leftOffset, rightOffset = GetPhaseOffsets(self, 2, 2)
				HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "added" and IntermissionAssignmentExists("SCS", true) then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "timelineFrameMouseWheel" then
						local leftOffset, rightOffset = GetPhaseOffsets(self, 2, 2)
						HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
		},
		{
			name = "createAssignmentDuringIntermissionExplain",
			text = L["Since the intermission is triggered by boss health, using timed assignments would be unreliable. Instead, the spell the boss casts before transitioning into intermission is used."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SCS", kHappyHourSpellID, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorReleased" then
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
		},
		{
			name = "changeIntermissionAssignmentTimeByDragging",
			text = L["Change the time of the assignment by left-clicking the icon and dragging it.\nWhen dragging a combat log event assignment, it can only be placed after the boss ability, as the assignment must occur afterward."],
			enableNextButton = false,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, FindCurrentAssignmentOrder(self) or 1)
			end,
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SCS", kHappyHourSpellID, false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, timeDifference)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if type(timeDifference) == "number" and timeDifference > 0.0 then
							self.tutorial.nextButton:SetEnabled(true)
						elseif type(timeDifference) == "string" and timeDifference == "timelineFrameMouseWheel" then
							HighlightTimelineSectionAndPositionTutorialFrame(
								self,
								0,
								0,
								FindCurrentAssignmentOrder(self) or 1
							)
						end
					end)
				else
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				end
			end,
		},
		{
			name = "changeIntermissionAssignmentSpell",
			text = FormatText(
				L["Change the"],
				{ L["Spell"] },
				L["to one of the spells you used for first two assignments"]
			),
			enableNextButton = function()
				return CountSpells(self, 3, true, 2, true)
			end,
			OnStepActivated = function(localSelf)
				if
					ShouldProceedIntermission(self, "SCS", kHappyHourSpellID, false)
					or ShouldProceedIntermission(self, "SAR", kHappyHourSpellID, false)
				then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if CountSpells(self, 3, true, 2, true) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "changeIntermissionAssignmentCombatLogEventType",
			text = FormatText(L["Change the"], { L["Trigger"] }, L["to"], { L["Spell Aura Removed"] }),
			enableNextButton = function()
				return IsCombatLogEventCorrect(self, "SAR", kHappyHourSpellID)
			end,
			OnStepActivated = function(localSelf)
				if
					ShouldProceedIntermission(self, "SCS", kHappyHourSpellID, false)
					or ShouldProceedIntermission(self, "SAR", kHappyHourSpellID, false)
				then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsCombatLogEventCorrect(self, "SAR", kHappyHourSpellID) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
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
		},
		{
			name = "changeIntermissionAssignmentCombatLogEventTypeExplain",
			text = FormatText(
				L["The time relative to the event stayed the same, but the icon moved forward since the"],
				{ L["Spell Aura Removed"] },
				L["event occurs after the"],
				{ L["Spell Cast Start"] },
				L["event"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if ShouldProceedIntermission(self, "SAR", kHappyHourSpellID, false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorReleased" then
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
		},
		{
			name = "createAssignmentBesideSpell",
			text = L["Instead of left-clicking beside an assignee, create an assignment by left-clicking the timeline beside a spell."],
			enableNextButton = false,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, FindCurrentAssignmentOrder(self) or 1)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "added" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "timelineFrameMouseWheel" then
						HighlightTimelineSectionAndPositionTutorialFrame(
							self,
							0,
							0,
							FindCurrentAssignmentOrder(self) or 1
						)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
		},
		{
			name = "createAssignmentBesideSpellExplain",
			text = L["The new assignment is created using the matching spell."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
			end,
		},
		{
			name = "duplicateAssignment",
			text = L["Duplicate an assignment by control-clicking an icon and dragging."],
			enableNextButton = false,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self)
				HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, FindCurrentAssignmentOrder(self) or 1)
			end,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "duplicated" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					elseif category == "timelineFrameMouseWheel" then
						HighlightTimelineSectionAndPositionTutorialFrame(
							self,
							0,
							0,
							FindCurrentAssignmentOrder(self) or 1
						)
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
			end,
		},
		{
			name = "duplicateAssignmentExplain",
			text = L["The duplicated assignment inherits all properties, besides time, from the original and is independent of it."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.frame
			end,
		},
		{
			name = "collapseSpellsForAssignee",
			text = format(
				"%s %s %s.",
				L["Click the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]] .. ":16:16:0:-4|t",
				L["button to collapse spells for an assignee"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(
					Private.tutorialCallbackObject,
					localSelf.name,
					function(_, category, assignee, collapsed)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assigneeCollapsed" and assignee == playerName and collapsed == true then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				)
				local timeline = self.mainFrame.timeline
				if timeline then
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						local key = child--[[@as EPAbilityEntry]]:GetKey()
						if type(key) == "string" then
							if key == playerName then
								localSelf.frame = child--[[@as EPAbilityEntry]].collapseButton
								break
							end
						end
					end
				end
			end,
		},
		{
			name = "collapseSpellsForAssigneeExplain",
			text = L["All spells for that assignee are condensed into a single row and cooldown durations are hidden. The same button can be clicked to expand spells."],
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "timelineFrameMouseWheel" then
						HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, 0)
					end
				end)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, 0)
			end,
			enableNextButton = true,
		},
		{
			name = "collapseAllAssigneeSpells",
			text = FormatText(
				L["The"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-collapse-64]] .. ":0:0:0:-6|t",
				L["button"],
				L["collapses all spells for all assignees"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.collapseAllButton.frame
			end,
		},
		{
			name = "expandAllAssigneeSpells",
			text = FormatText(
				L["Click the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-expand-64]] .. ":0:0:0:-6|t",
				L["button to expand all spells for all assignees"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "expandAllButtonClicked" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.expandAllButton.frame
			end,
		},
		{
			name = "resizeMainWindow",
			text = format(
				"%s %s %s.",
				L["Drag the"],
				"|T" .. [[Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up]] .. ":0:0:0:-4|t",
				L["button to resize the main window"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "mainWindowResized" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.resizer
			end,
		},
		{
			name = "filterBossSpells",
			text = FormatText(
				L["Click the"],
				{ L["Boss"] },
				L["menu button"] .. ",",
				L["navigate to"],
				format("|c%s%s|r", "cffffd10", L["Filter Spells"]) .. ",",
				L["and click an ability to hide it from the timeline"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "bossAbilityHidden" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.bossMenuButton.frame
			end,
		},
		{
			name = "filterBossSpellsExplain",
			text = L["Hiding a boss ability does not affect combat log event assignments using it."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.bossMenuButton.frame
			end,
		},
		{
			name = "openPhaseTimingEditor",
			text = FormatText(
				L["Click the"],
				{ L["Boss"] },
				L["menu button"] .. ",",
				L["and click the"],
				{ L["Edit Phase Timings"] },
				L["button"],
				L["to open the"],
				L["Phase Timing Editor"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "phaseLengthEditorReleased" then
						if self.tutorial then
							self.tutorial:Release()
						end
					elseif category == "phaseLengthEditorOpened" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.bossMenuButton.frame
			end,
		},
		{
			name = "phaseTimingEditorDescription",
			text = L["Boss phase durations and counts can be customized here. These settings are unique to each plan. If a boss phase has a fixed timer, it will not be editable. Similarly, if a boss phase does not repeat, its count will not be editable."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if not self.phaseLengthEditor then
					Private.CreatePhaseLengthEditor()
				end
				localSelf.frame = self.phaseLengthEditor.frame
			end,
		},
		{
			name = "editPhaseOneBossPhaseDuration",
			text = L["Change the duration of Phase 1 to 1:30."],
			enableNextButton = function()
				local boss = bossUtilities.GetBoss(GetCurrentBossDungeonEncounterID())
				if boss then
					if abs(boss.phases[1].duration - 90.0) < 0.01 then
						return true
					end
				end
				return false
			end,
			OnStepActivated = function(localSelf)
				if not self.phaseLengthEditor then
					Private.CreatePhaseLengthEditor()
				end
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category, duration)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "phaseLengthEditorReleased" then
						if self.tutorial then
							self.tutorial:Release()
						end
					elseif category == "phaseOneDurationChanged" and type(duration) == "number" then
						if abs(duration - 90.0) < 0.01 then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				end)
				localSelf.frame = self.phaseLengthEditor.frame
			end,
			PreStepDeactivated = function(_, increasing)
				if increasing and self.phaseLengthEditor then
					self.phaseLengthEditor:Release()
				end
			end,
		},
		{
			name = "bossAbilitySpellCastsAdded",
			text = L["Boss ability spell casts are added when the duration is increased and removed when the duration is decreased."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "timelineFrameMouseWheel" then
						localSelf.HighlightFrameAndPositionTutorialFrame()
					end
				end)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local timeline = self.mainFrame.timeline
				if timeline then
					local bossAbilityTimelineFrame = timeline.bossAbilityTimeline.timelineFrame
					highlightBorderFrame:SetParent(bossAbilityTimelineFrame)
					highlightBorderFrame:SetFrameStrata(bossAbilityTimelineFrame:GetFrameStrata())
					highlightBorderFrame:SetFrameLevel(bossAbilityTimelineFrame:GetFrameLevel() + 50)
					highlightBorderFrame:ClearAllPoints()
					local leftOffset, rightOffset = GetPhaseOffsets(self, 1, 1)
					highlightBorderFrame:SetPoint("TOPLEFT", bossAbilityTimelineFrame, leftOffset, 0)
					highlightBorderFrame:SetPoint("BOTTOMRIGHT", bossAbilityTimelineFrame, rightOffset, 0)
					highlightBorderFrame:Show()
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, kTutorialOffset + 10)
				end
			end,
		},
		{
			name = "simulateRemindersStart",
			text = FormatText(
				L["Click the"],
				{ L["Simulate Reminders"] },
				L["button"],
				L["to preview reminders for the current plan"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if self:IsSimulatingBoss() then
					self:StopSimulatingBoss()
				end
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "simulationStarted" then
						setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
					end
				end)
				localSelf.frame = self.mainFrame.simulateRemindersButton.frame
			end,
		},
		{
			name = "minimizeMainWindow",
			text = L["Minimize the main window to get a better view."],
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				else
					if self.mainFrame.minimizeFrame:IsShown() then
						self.mainFrame:Maximize()
					end
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "minimizeButtonClicked" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					localSelf.frame = self.mainFrame.minimizeButton.frame
				end
			end,
		},
		{
			name = "maximizeMainWindow",
			text = L["Click the maximize button to continue the tutorial."],
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				else
					if not self.mainFrame.minimizeFrame:IsShown() then
						self.mainFrame:Minimize()
					end
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "maximizeButtonClicked" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					HighlightFrame(self.mainFrame.maximizeButton.frame)
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("TOP", highlightBorderFrame, "BOTTOM", 0, -kTutorialOffset)
					self.tutorial.frame:Show()
				end
			end,
		},
		{
			name = "simulateRemindersEnd",
			text = FormatText(L["Click the"], { L["Stop Simulating"] }, L["button"], L["to stop previewing"]),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep - 1)
				else
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "simulationStopped" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					localSelf.frame = self.mainFrame.simulateRemindersButton.frame
				end
			end,
		},
		{
			name = "customizeReminders",
			text = FormatText(
				L["Reminders can be customized in the"],
				{ L["Reminder"] },
				L["section of the"],
				{ L["Preferences"] },
				L["menu"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "optionsMenuClosed" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				if not self.optionsMenu then
					self:CreateOptionsMenu()
				end
				self.optionsMenu:SetCurrentTab(L["Reminder"])
				for _, widget in ipairs(self.optionsMenu.tabTitleContainer.children) do
					if widget.type == "EPButton" and widget.button then
						if
							widget--[[@as EPButton]].button:GetText() == L["Reminder"]
						then
							localSelf.frame = widget--[[@as EPButton]].frame
							break
						end
					end
				end
			end,
			PreStepDeactivated = function(_)
				if self.optionsMenu then
					self:ReleaseOptionsMenu()
				end
			end,
		},
		{
			name = "deleteSingleAssignment",
			text = L["Individual assignments can be deleted by clicking this button."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "assignmentEditorReleased" then
						if not localSelf.ignoreNextAssignmentEditorReleased and self.tutorial then
							self.tutorial:Release()
						end
					elseif category == "assignmentEditorDeleteButtonClicked" then
						if self.tutorial then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
						localSelf.ignoreNextAssignmentEditorReleased = nil
					elseif category == "preAssignmentEditorDeleteButtonClicked" then
						localSelf.ignoreNextAssignmentEditorReleased = true
					end
				end)
				if not self.assignmentEditor then
					HandleCreateAssignmentEditor(self)
				end
				localSelf.frame = self.assignmentEditor.deleteButton.frame
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.ignoreNextAssignmentEditorReleased = nil
			end,
		},
		{
			name = "deleteAllAssigneeSpellAssignments",
			text = format(
				"%s %s %s.",
				L["All assignments for a specific spell of an assignee can be deleted by clicking the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]] .. ":0:0:0:-6|t",
				L["button beside the spell"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "deleteAssigneeRowClicked" then
						if self.tutorial then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				end)
				local timeline = self.mainFrame.timeline
				if timeline then
					CreateAssignmentIfNecessary()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						local key = child--[[@as EPAbilityEntry]]:GetKey()
						if type(key) == "table" then
							if key.assignee and key.assignee == playerName then
								localSelf.frame = child--[[@as EPAbilityEntry]].check.frame
								break
							end
						end
					end
				end
			end,
		},
		{
			name = "deleteAllAssigneeAssignments",
			text = format(
				"%s %s %s.",
				L["All assignments for an assignee can be deleted by clicking the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]] .. ":0:0:0:-6|t",
				L["button beside the assignee"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "deleteAssigneeRowClicked" then
						if self.tutorial then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				end)
				local timeline = self.mainFrame.timeline
				if timeline then
					CreateAssignmentIfNecessary()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						local key = child--[[@as EPAbilityEntry]]:GetKey()
						if type(key) == "string" and key == playerName then
							localSelf.frame = child--[[@as EPAbilityEntry]].check.frame
							break
						end
					end
				end
			end,
		},
		{
			name = "swapAssignee",
			text = format(
				"%s %s %s.",
				L["Assignments can be swapped between assignees by clicking the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-swap-32]] .. ":0:0:0:-6|t",
				L["button beside the assignee"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "deleteAssigneeRowClicked" then
						if self.tutorial then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end
				end)
				local timeline = self.mainFrame.timeline
				if timeline then
					CreateAssignmentIfNecessary()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						local key = child--[[@as EPAbilityEntry]]:GetKey()
						if type(key) == "string" and key == playerName then
							if child.swap then
								localSelf.frame = child--[[@as EPAbilityEntry]].swap.frame
							end
							break
						end
					end
				end
			end,
		},
		{
			name = "externalText",
			text = FormatText(
				{ L["External Text"] },
				L["is miscellaneous text that can be accessed by other addons and WeakAuras. Clicking this button opens the External Text Editor"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.externalTextButton.frame
			end,
		},
		{
			name = "designatedExternalPlan",
			text = FormatText(
				L["If a plan is the"],
				{ L["Designated External Plan"] },
				L["and you are the group leader"] .. ",",
				L["its"],
				{ L["External Text"] },
				L["is sent to all members of the group"] .. ".",
				L["Each boss must have a unique"],
				{ L["Designated External Plan"] }
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.primaryPlanCheckBox.frame
			end,
		},
		{
			name = "sendPlan",
			text = format(
				"%s. %s.",
				L["Sending the current plan requires group leader or group assistant"],
				L["Receivers can approve or reject incoming plans, and can automatically receive future plans by saving the sender as a trusted character"]
			),
			enableNextButton = true,
			frame = self.mainFrame.sendPlanButton.frame,
		},
		{
			name = "tutorialCompleted",
			text = L["Tutorial Complete!"],
			enableNextButton = true,
			OnStepActivated = function(_)
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
				if self.activeTutorialCallbackName then
					self.callbacks:Fire(self.activeTutorialCallbackName, "minimizeButtonClicked")
				end
			end
		end)
		self.mainFrame:SetCallback("MaximizeButtonClicked", function()
			if self.tutorial then
				self.tutorial.frame:Show()
				if highlightBorderFrameWasVisible then
					highlightBorderFrame:Show()
				end
				if self.activeTutorialCallbackName then
					self.callbacks:Fire(self.activeTutorialCallbackName, "maximizeButtonClicked")
				end
			end
		end)
		self.mainFrame:SetCallback("Resized", function()
			if self.tutorial then
				if self.activeTutorialCallbackName then
					self.callbacks:Fire(self.activeTutorialCallbackName, "mainWindowResized")
				end
			end
		end)

		self.tutorialCallbackObject = {}
		local steps = {} ---@type table<integer, TutorialStep>
		local totalStepCount = 0

		---@param previousStepIndex integer
		---@param currentStepIndex integer
		local function SetCurrentStep(previousStepIndex, currentStepIndex)
			self.activeTutorialCallbackName = nil
			local previousStep = steps[previousStepIndex]
			if previousStep then
				local incrementing = currentStepIndex > previousStepIndex
				if incrementing or currentStepIndex < previousStepIndex then
					self.UnregisterCallback(self.tutorialCallbackObject, previousStep.name)
					if previousStep.PreStepDeactivated then
						previousStep:PreStepDeactivated(incrementing)
					end
					previousStep.frame = nil
				end
			end

			currentStepIndex = max(1, currentStepIndex)

			if currentStepIndex > totalStepCount then
				AddOn.db.global.tutorialCompleted = true
				AddOn.db.global.lastTutorialStepName = ""
				self.tutorial:Release()
			else
				local currentStep = steps[currentStepIndex]
				AddOn.db.global.lastTutorialStepName = currentStep.name
				self.activeTutorialCallbackName = currentStep.name
				self.tutorial.currentStep = currentStepIndex
				highlightBorderFrame:SetParent(UIParent)
				highlightBorderFrame:ClearAllPoints()
				highlightBorderFrame:Hide()
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

				if currentStep.HighlightFrameAndPositionTutorialFrame then
					currentStep:HighlightFrameAndPositionTutorialFrame()
				elseif currentStep.frame then
					HighlightFrame(currentStep.frame)
					self.tutorial.frame:ClearAllPoints()
					local offset = kTutorialOffset
					if currentStep.additionalVerticalOffset then
						offset = offset + currentStep.additionalVerticalOffset
					end
					self.tutorial.frame:SetPoint("BOTTOM", highlightBorderFrame, "TOP", 0, offset)
				end
			end
		end

		---@param stepName string
		---@return integer
		local function FindStepIndex(stepName)
			local index = 1
			if stepName:len() == 0 then
				return index
			end
			for currentIndex, step in ipairs(steps) do
				if step.name == stepName then
					index = currentIndex
					break
				end
			end
			return index
		end

		steps = CreateTutorialSteps(self, SetCurrentStep)
		totalStepCount = #steps

		--@debug@
		local map = {}
		for _, step in ipairs(steps) do
			if map[step.name] then
				print("Duplicate entry:", step.name)
			else
				map[step.name] = true
			end
		end
		--@end-debug@

		self:CloseDialogs()
		if self.IsSimulatingBoss() then
			self:StopSimulatingBoss()
		end

		self.RegisterCallback(self.tutorialCallbackObject, "PlanChanged", function()
			if
				self.tutorial
				and self.activeTutorialCallbackName ~= "start"
				and self.activeTutorialCallbackName ~= "planMenuBar"
				and self.activeTutorialCallbackName ~= "createNewPlan"
				and self.activeTutorialCallbackName ~= "newPlanDialog"
			then
				self.tutorial:Release()
			end
		end)

		local tutorial = AceGUI:Create("EPTutorial")
		tutorial:InitProgressBar(totalStepCount, AddOn.db.profile.preferences.reminder.progressBars.texture)
		tutorial.frame:SetFrameLevel(kTutorialFrameLevel)
		tutorial:SetCallback("OnRelease", function()
			self.tutorial = nil
			self.UnregisterAllCallbacks(self.tutorialCallbackObject)
			highlightBorderFrame:ClearAllPoints()
			highlightBorderFrame:Hide()
			for _, step in pairs(steps) do
				if step.PreStepDeactivated then
					step:PreStepDeactivated(true, true)
				end
			end
			self.tutorialCallbackObject = nil
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

		local lastTutorialStepName = AddOn.db.global.lastTutorialStepName
		local plan = FindTutorialPlan(kBrewmasterAldryrEncounterID)
		if plan then
			AddOn.db.profile.lastOpenPlan = plan.name
			interfaceUpdater.UpdateFromPlan(plan)
		else
			if
				lastTutorialStepName ~= "planMenuBar"
				and lastTutorialStepName ~= "createNewPlan"
				and lastTutorialStepName ~= "newPlanDialog"
			then -- Only allow these steps to not have a tutorial plan associated with them
				lastTutorialStepName = "createNewPlan"
				AddOn.db.global.lastTutorialStepName = "createNewPlan"
			end
		end

		SetCurrentStep(0, FindStepIndex(lastTutorialStepName))
	end
end
