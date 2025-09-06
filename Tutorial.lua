---@diagnostic disable: invisible
local _, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
---@class Constants
local constants = Private.constants

---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local GetBoss = bossUtilities.GetBoss
local GetBossPhases = bossUtilities.GetBossPhases

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

---@class Utilities
local utilities = Private.utilities
local GetCurrentAssignments = utilities.GetCurrentAssignments
local GetCurrentBossDungeonEncounterID = utilities.GetCurrentBossDungeonEncounterID
local GetCurrentDifficulty = utilities.GetCurrentDifficulty
local GetCurrentRoster = utilities.GetCurrentRoster

local UIParent = UIParent
local abs = math.abs
local AceGUI = LibStub("AceGUI-3.0")
local concat = table.concat
local format = string.format
local getmetatable = getmetatable
local ipairs = ipairs
local max = math.max
local pairs = pairs
local tinsert = table.insert
local type = type

local k = {
	AbilityEntryWidth = 200,
	AssignmentSpacing = 2,
	BrewmasterAldryrEncounterID = 2900,
	HappyHourSpellID = 442525,
	HighlightPadding = 2,
	TutorialFrameLevel = 250,
	TutorialOffset = 10,
	PlayerName = UnitFullName("player"),
	TimeValues = { [1] = 15.0, [2] = 20.0, [3] = 120.0 },
}

local s = {
	HighlightBorderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"),
}
s.HighlightBorderFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
s.HighlightBorderFrame:SetBackdropBorderColor(1, 0.82, 0, 1)
s.HighlightBorderFrame:EnableMouse(false)
s.HighlightBorderFrame:Hide()

---@param frame Frame
local function HighlightFrame(frame)
	if not frame then
		return
	end

	s.HighlightBorderFrame:SetParent(UIParent)
	s.HighlightBorderFrame:SetFrameStrata(frame:GetFrameStrata())
	s.HighlightBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
	s.HighlightBorderFrame:ClearAllPoints()
	s.HighlightBorderFrame:SetPoint("TOPLEFT", frame, -k.HighlightPadding, k.HighlightPadding)
	s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", frame, k.HighlightPadding, -k.HighlightPadding)
	s.HighlightBorderFrame:Show()
end

-- Highlights the assignment timeline and places the tutorial frame above it.
---@param self Private
local function HighlightAssignmentTimelineAndPositionTutorialFrame(self)
	local timeline = self.mainFrame.timeline
	if timeline then
		local timelineFrame = timeline.assignmentTimeline.scrollFrame
		s.HighlightBorderFrame:SetParent(timelineFrame)
		s.HighlightBorderFrame:SetFrameStrata(timelineFrame:GetFrameStrata())
		s.HighlightBorderFrame:SetFrameLevel(timelineFrame:GetFrameLevel() + 50)
		s.HighlightBorderFrame:ClearAllPoints()
		s.HighlightBorderFrame:SetPoint("TOPLEFT", timelineFrame)
		s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", timelineFrame)
		s.HighlightBorderFrame:Show()
		self.tutorial.frame:ClearAllPoints()
		self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset + 32)
	end
end

-- Highlights a specific row of the assignment timeline and places the tutorial frame above it.
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
		s.HighlightBorderFrame:SetParent(timelineFrame)
		s.HighlightBorderFrame:SetFrameStrata(timelineFrame:GetFrameStrata())
		s.HighlightBorderFrame:SetFrameLevel(timelineFrame:GetFrameLevel() + 50)
		s.HighlightBorderFrame:ClearAllPoints()
		local x = leftOffset
		local assignmentHeightSetting = AddOn.db.profile.preferences.timelineRows.assignmentHeight
		local assignmentHeight = (assignmentHeightSetting + k.AssignmentSpacing) * rowNumber
		local y = -assignmentHeight
		s.HighlightBorderFrame:SetPoint("TOPLEFT", timelineFrame, x, y)
		x = rightOffset
		y = -assignmentHeight
		s.HighlightBorderFrame:SetPoint("TOPRIGHT", timelineFrame, x, y)
		s.HighlightBorderFrame:SetHeight(assignmentHeightSetting)
		s.HighlightBorderFrame:Show()
		self.tutorial.frame:ClearAllPoints()
		if additionalVerticalOffset then
			self.tutorial.frame:SetPoint(
				"BOTTOM",
				s.HighlightBorderFrame,
				"TOP",
				0,
				k.TutorialOffset + additionalVerticalOffset
			)
		else
			self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset)
		end
	end
end

---@param encounterID integer
---@return Plan|nil
local function FindTutorialPlan(encounterID)
	local plans = AddOn.db.profile.plans
	for _, plan in pairs(plans) do
		if plan.name:lower():find(L["Tutorial"]:lower()) and plan.dungeonEncounterID == encounterID then
			return plan
		end
	end
	return nil
end

-- Creates a generic assignment if none are found and updates the interface from the assignment found or created.
local function CreateGenericAssignmentIfNoAssignmentsAndUpdateInterfaceFromAssignment()
	local assignments = GetCurrentAssignments()
	local needToCreateNewAssignment = true

	for _, assignment in ipairs(assignments) do
		if assignment.assignee == k.PlayerName then
			needToCreateNewAssignment = false
			interfaceUpdater.UpdateFromAssignment(
				GetCurrentBossDungeonEncounterID(),
				GetCurrentDifficulty(),
				assignment,
				true,
				true,
				true,
				true
			)
			break
		end
	end
	if needToCreateNewAssignment then
		local name, entry = utilities.CreateRosterEntryForSelf()
		local roster = GetCurrentRoster()
		if not roster[name] then
			roster[name] = entry
		end
		local plan = FindTutorialPlan(k.BrewmasterAldryrEncounterID)
		if plan then
			local assignment = TimedAssignment:New(nil, plan.ID)
			assignment.assignee = name
			utilities.AddAssignmentToPlan(plan, assignment)
			interfaceUpdater.UpdateFromAssignment(
				GetCurrentBossDungeonEncounterID(),
				GetCurrentDifficulty(),
				assignment,
				true,
				true,
				true,
				true
			)
		else
			error("Couldn't find a tutorial plan.")
		end
	end
end

---@param self Private
---@return integer|nil
local function FindCurrentAssignmentOrder(self)
	if self.mainFrame and self.mainFrame.timeline then
		if self.assignmentEditor then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				return self.mainFrame.timeline.ComputeAssignmentRowIndexFromAssignmentID(assignmentID)
			end
		end
	end
	return nil
end

-- Expands the abilities for the current player name if not already expanded and optionally scrolls the assignment editor
-- assignment into view if open.
---@param self Private
---@param scrollIntoView boolean
local function EnsureAssigneeIsExpanded(self, scrollIntoView)
	local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
	if collapsed[k.PlayerName] ~= nil then
		if collapsed[k.PlayerName] == true then
			collapsed[k.PlayerName] = false
			interfaceUpdater.UpdateAllAssignments(false, GetCurrentBossDungeonEncounterID())
		end
	end
	local timeline = self.mainFrame.timeline
	if timeline then
		if self.assignmentEditor and scrollIntoView then
			local assignmentID = self.assignmentEditor:GetAssignmentID()
			if assignmentID then
				timeline:ScrollAssignmentIntoView(assignmentID)
			end
		end
	end
end

---@return boolean
local function IsSelfPresentInPlan()
	local plan = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
	if plan then
		for _, assignment in ipairs(plan.assignments) do
			if assignment.assignee == k.PlayerName then
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
					---@cast assignment CombatLogEventAssignment
					if
						assignment.combatLogEventType == combatLogEventType
						and assignment.combatLogEventSpellID == spellID
					then
						return true
					end
				end
			end
		end
	end
	return false
end

---@param requiredCount integer The required count of spells that have spell ID > 1.
---@param unique boolean|nil Whether to add a unique spell count requirement.
---@param requiredUniqueCount integer|nil Required amount of unique spells that have spell ID > 1.
---@param exactUnique boolean|nil Whether to require the exact number of requiredUniqueCount.
local function CountSpells(requiredCount, unique, requiredUniqueCount, exactUnique)
	local count = 0
	local uniqueCount = 0
	local uniqueSet = {}
	for _, assignment in ipairs(GetCurrentAssignments()) do
		if assignment.spellID > constants.kTextAssignmentSpellID then
			if unique and not uniqueSet[assignment.spellID] then
				uniqueCount = uniqueCount + 1
				uniqueSet[assignment.spellID] = true
			end
			count = count + 1
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
				if assignment.text:lower() == L["Use {6262} at {circle}"]:lower() then
					return true
				end
			end
		end
	end
	return false
end

---@param assignmentNumber integer
---@param setTime boolean
---@param allowUnknown boolean|nil
---@return Assignment|CombatLogEventAssignment|TimedAssignment|nil
local function FindPhaseOneAssignment(assignmentNumber, setTime, allowUnknown)
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	local assignments = GetCurrentAssignments()
	if boss then
		local phases = GetBossPhases(boss, GetCurrentDifficulty())
		local phaseOneDuration = phases[1].duration
		local firstSpell = AddOn.db.global.tutorial.firstSpell
		local secondSpell = AddOn.db.global.tutorial.secondSpell
		local encounteredSecondSpell = false
		for _, assignment in ipairs(assignments) do
			if assignment.assignee == k.PlayerName then
				---@cast assignment TimedAssignment
				if getmetatable(assignment) == Private.classes.TimedAssignment then
					local valid = false
					if assignmentNumber == 1 then
						if assignment.time < phaseOneDuration then
							if firstSpell > 0 then
								if firstSpell == assignment.spellID then
									valid = true
								end
							elseif secondSpell ~= assignment.spellID then
								valid = true
							end
						end
					elseif assignmentNumber == 2 then
						if assignment.time < phaseOneDuration then
							if secondSpell > 0 then
								if secondSpell == assignment.spellID then
									valid = true
								elseif allowUnknown and firstSpell ~= assignment.spellID then
									valid = true
								end
							elseif firstSpell ~= assignment.spellID then
								valid = true
							end
						end
					elseif assignmentNumber == 3 then
						if secondSpell > 0 and secondSpell == assignment.spellID then
							if encounteredSecondSpell then
								return assignment
							end
							encounteredSecondSpell = true
						end
					end
					if valid then
						if setTime and assignmentNumber ~= 3 then
							assignment.time = k.TimeValues[assignmentNumber]
						end
						return assignment
					end
				elseif
					assignmentNumber == 3 and getmetatable(assignment) == Private.classes.CombatLogEventAssignment
				then
					if encounteredSecondSpell and secondSpell > 0 and secondSpell == assignment.spellID then
						return assignment
					end
				end
			end
		end
	end
end

---@param assignmentNumber integer
---@param setSpellID boolean
---@param setTime boolean
---@param allowUnknown boolean|nil
---@return Assignment|CombatLogEventAssignment|TimedAssignment
local function FindOrCreatePhaseOneAssignment(assignmentNumber, setSpellID, setTime, allowUnknown)
	local assignment = FindPhaseOneAssignment(assignmentNumber, setTime, allowUnknown)
	if assignment then
		return assignment
	else
		local plan = FindTutorialPlan(k.BrewmasterAldryrEncounterID)
		if plan then
			assignment = TimedAssignment:New(nil, plan.ID)
		else
			error("Couldn't find a tutorial plan.")
		end
		assignment.assignee = k.PlayerName
		if assignmentNumber == 1 then
			if AddOn.db.global.tutorial.firstSpell > 0 then
				assignment.spellID = AddOn.db.global.tutorial.firstSpell
			end
			if setTime then
				assignment.time = 15.0
			end
		elseif assignmentNumber == 2 then
			if setSpellID and AddOn.db.global.tutorial.secondSpell > 0 then
				assignment.spellID = AddOn.db.global.tutorial.secondSpell
			end
			if setTime then
				assignment.time = 20.0
			end
		elseif assignmentNumber == 3 then
			if setSpellID and AddOn.db.global.tutorial.secondSpell > 0 then
				assignment.spellID = AddOn.db.global.tutorial.secondSpell
			end
			if setTime then
				assignment.time = 120.0
			end
		end
		utilities.AddAssignmentToPlan(plan, assignment)
		return assignment
	end
end

---@return boolean
local function TwoPhaseOneAssignmentsExist()
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phases = GetBossPhases(boss, GetCurrentDifficulty())
		local phaseOneDuration = phases[1].duration
		local count = 0
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.TimedAssignment then
				---@cast assignment TimedAssignment
				if assignment.time < phaseOneDuration then
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
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phases = GetBossPhases(boss, GetCurrentDifficulty())
		local phaseTwoDuration = phases[2].duration
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local timeOkay = not limitToInIntermission or assignment.time < phaseTwoDuration
				if
					timeOkay
					and assignment.combatLogEventType == combatLogEventType
					and assignment.combatLogEventSpellID == k.HappyHourSpellID
				then
					return true
				end
			end
		end
	end
	return false
end

---@return boolean
local function TwoIntermissionAssignmentsExist()
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local count = 0
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				if
					assignment.combatLogEventType == "SAR"
					and assignment.combatLogEventSpellID == k.HappyHourSpellID
				then
					if assignment.spellID == constants.kTextAssignmentSpellID then
						count = count + 1
						if count >= 2 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

---@param assignmentNumber integer
---@param setSpellID boolean
---@param setTime boolean
---@param combatLogEventTypes table<integer, CombatLogEventType>
---@param spellID integer
---@param spellCount integer
---@param limitToInIntermission boolean
---@param time number
---@return Assignment|CombatLogEventAssignment
local function FindOrCreateIntermissionAssignment(
	assignmentNumber,
	setSpellID,
	setTime,
	combatLogEventTypes,
	spellID,
	spellCount,
	limitToInIntermission,
	time
)
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	if boss then
		local phases = GetBossPhases(boss, GetCurrentDifficulty())
		local phaseTwoDuration = phases[2].duration
		local encounteredFirstAssignment = false
		for _, assignment in ipairs(GetCurrentAssignments()) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local timeOkay = not limitToInIntermission or assignment.time < phaseTwoDuration
				if timeOkay and assignment.combatLogEventSpellID == spellID and assignment.spellCount == spellCount then
					local validEventType = false
					for _, eventType in ipairs(combatLogEventTypes) do
						if eventType == assignment.combatLogEventType then
							validEventType = true
							break
						end
					end
					if validEventType then
						if assignmentNumber == 1 then
							if setSpellID then
								assignment.spellID = constants.kTextAssignmentSpellID
								assignment.text = L["Use {6262} at {circle}"]
							end
							return assignment
						elseif assignmentNumber == 2 then
							if encounteredFirstAssignment then
								if setSpellID then
									assignment.spellID = constants.kTextAssignmentSpellID
									assignment.text = L["Use {6262} at {circle}"]
								end
								return assignment
							end
							encounteredFirstAssignment = true
						end
					end
				end
			end
		end
	end

	local assignment
	local plan = FindTutorialPlan(k.BrewmasterAldryrEncounterID)
	if plan then
		assignment = CombatLogEventAssignment:New(nil, plan.ID)
	else
		error("Couldn't find a tutorial plan.")
	end

	assignment.assignee = k.PlayerName
	assignment.combatLogEventType = combatLogEventTypes[1]
	assignment.combatLogEventSpellID = spellID
	assignment.spellCount = spellCount
	if assignmentNumber == 1 then
		if setSpellID then
			assignment.spellID = constants.kTextAssignmentSpellID
			assignment.text = L["Use {6262} at {circle}"]
		end
		if setTime then
			assignment.time = 10.0
		end
	elseif assignmentNumber == 2 then
		if setSpellID then
			assignment.spellID = constants.kTextAssignmentSpellID
			assignment.text = L["Use {6262} at {circle}"]
		end
		if setTime then
			assignment.time = time
		end
	end
	utilities.AddAssignmentToPlan(plan, assignment)
	return assignment
end

---@param self Private
---@return number
---@return number
local function GetPhaseOffsets(self, startPhaseIndex, endPhaseIndex)
	local leftOffset, rightOffset = 0.0, 0.0
	local boss = GetBoss(GetCurrentBossDungeonEncounterID())
	if boss and self.mainFrame and self.mainFrame.timeline then
		local startTime = 0.0
		local endTime = 0.0
		local phases = GetBossPhases(boss, GetCurrentDifficulty())
		if phases[startPhaseIndex] then
			for index, phase in ipairs(phases) do
				if index == startPhaseIndex then
					break
				end
				startTime = startTime + phase.duration
			end
		end
		if endPhaseIndex > startPhaseIndex then
			for index, phase in ipairs(phases) do
				endTime = endTime + phase.duration
				if index == endPhaseIndex then
					break
				end
			end
		elseif phases[endPhaseIndex] then
			endTime = startTime + phases[endPhaseIndex].duration
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
---@param assignmentNumber integer
---@param setSpellID boolean
---@param setTime boolean
---@param openAssignmentEditor boolean
---@param allowUnknown boolean|nil
---@return integer|nil
local function PhaseOneOkay(self, assignmentNumber, setSpellID, setTime, openAssignmentEditor, allowUnknown)
	if self.tutorial then
		local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
		if collapsed[k.PlayerName] ~= nil then
			if collapsed[k.PlayerName] == true then
				collapsed[k.PlayerName] = false
			end
		end

		if not self.assignmentEditor and openAssignmentEditor then
			self.CreateAssignmentEditor()
		end
		if assignmentNumber > 1 then
			FindOrCreatePhaseOneAssignment(1, true, true)
		end
		if assignmentNumber > 2 then
			FindOrCreatePhaseOneAssignment(2, true, true)
		end
		local assignment = FindOrCreatePhaseOneAssignment(assignmentNumber, setSpellID, setTime, allowUnknown)
		interfaceUpdater.UpdateFromAssignment(
			GetCurrentBossDungeonEncounterID(),
			GetCurrentDifficulty(),
			assignment,
			true,
			true,
			true,
			true
		)
		if not openAssignmentEditor then
			self.mainFrame.timeline.ClearSelectedBossAbilities()
			self.mainFrame.timeline.ClearSelectedAssignments()
		end
		local assignmentRowIndex =
			self.mainFrame.timeline.ComputeAssignmentRowIndexFromAssignmentID(assignment.uniqueID)
		if assignmentRowIndex then
			return assignmentRowIndex - 1
		end
		return 1
	end
end

---@param self Private
---@param assignmentNumber integer
---@param setSpellID boolean
---@param setTime boolean
---@param combatLogEventTypes table<integer, CombatLogEventType>
---@param spellID integer
---@param limitToInIntermission boolean
---@param openAssignmentEditor boolean
---@param skipExpand boolean|nil
---@return integer|nil
local function IntermissionOkay(
	self,
	assignmentNumber,
	setSpellID,
	setTime,
	combatLogEventTypes,
	spellID,
	limitToInIntermission,
	openAssignmentEditor,
	skipExpand
)
	if self.tutorial then
		if not skipExpand then
			local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
			if collapsed[k.PlayerName] ~= nil then
				if collapsed[k.PlayerName] == true then
					collapsed[k.PlayerName] = false
				end
			end
		end

		if not self.assignmentEditor and openAssignmentEditor then
			self.CreateAssignmentEditor()
		end

		FindOrCreatePhaseOneAssignment(1, true, true)
		FindOrCreatePhaseOneAssignment(2, true, true)
		local time = 0.0
		if assignmentNumber > 1 then
			FindOrCreatePhaseOneAssignment(3, true, true)
			local a = FindOrCreateIntermissionAssignment(1, true, true, { "SAR" }, k.HappyHourSpellID, 1, false, 0.0)
			time = a.time + 15.0
		end
		local assignment = FindOrCreateIntermissionAssignment(
			assignmentNumber,
			setSpellID,
			setTime,
			combatLogEventTypes,
			spellID,
			1,
			limitToInIntermission,
			time
		)
		interfaceUpdater.UpdateFromAssignment(
			GetCurrentBossDungeonEncounterID(),
			GetCurrentDifficulty(),
			assignment,
			true,
			true,
			true,
			true
		)
		if not openAssignmentEditor then
			self.mainFrame.timeline:ClearSelectedBossAbilities()
			self.mainFrame.timeline:ClearSelectedAssignments()
		end
		local assignmentRowIndex =
			self.mainFrame.timeline.ComputeAssignmentRowIndexFromAssignmentID(assignment.uniqueID)
		if assignmentRowIndex then
			return assignmentRowIndex - 1
		end
		return 1
	end
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

---@param self Private
---@param setCurrentStep fun(previousStepIndex: integer, currentStepIndex: integer)
---@return table<integer, TutorialStep>
local function CreateTutorialSteps(self, setCurrentStep)
	local createdTutorialPlan = false
	local cinderBrewMeaderyName = self.dungeonInstances[2661].name
	local brewmasterAldryrName = GetBoss(k.BrewmasterAldryrEncounterID).name

	---@type table<integer, TutorialStep>
	return {
		{
			name = "start",
			text = FormatText(
				L["This optional interactive tutorial walks you through the key features of Encounter Planner. You can close this window at any time and resume where you left off by clicking the"],
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
				return true
			end,
		},
		{
			name = "planMenuBar",
			text = FormatText(
				L["The"],
				{ L["Menu Bar"] },
				L["contains high level categories for managing plans, modifying bosses, editing rosters, and settings"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.menuButtonContainer.frame
				return true
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
				return IsCurrentPlanValidTutorial(k.BrewmasterAldryrEncounterID)
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
				localSelf.frame = self.mainFrame.planMenuButton.frame
				return true
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
				return IsCurrentPlanValidTutorial(k.BrewmasterAldryrEncounterID)
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
								ValidateNewTutorialPlan(planName, encounterID, k.BrewmasterAldryrEncounterID)
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
						ValidateNewTutorialPlan(planName, encounterID, k.BrewmasterAldryrEncounterID)
					)
				end
				localSelf.frame = self.newPlanDialog.frame
				return true
			end,
			PreStepDeactivated = function()
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
				localSelf.frame = self.mainFrame.rosterMenuButton.frame
				return true
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
				localSelf.frame = self.rosterEditor.currentRosterTab.frame
				return true
			end,
			PreStepDeactivated = function(_, incrementing)
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
				L["is independent of plans and can be used to quickly populate the"],
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
				localSelf.frame = self.rosterEditor.sharedRosterTab.frame
				return true
			end,
			PreStepDeactivated = function(_, incrementing)
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
				localSelf.frame = self.mainFrame.currentPlanWidget.frame
				return true
			end,
		},
		{
			name = "currentPlanDropdown",
			text = L["The current plan is selected using this dropdown. You can rename the current plan by double clicking the dropdown (You cannot rename the tutorial plan)."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.planDropdown.frame
				return true
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
				return true
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
				return true
			end,
		},
		{
			name = "assignmentEditorOpened",
			text = FormatText(
				L["The"],
				{ L["Assignment Editor"] },
				L["is opened after adding an assignee. It can also by opened by left-clicking an icon in the Assignment Timeline"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, false, false, true) then
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
					return true
				else
					return false
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
				L["determines what activates an assignment. It can either be relative to the start of an encounter or relative to a combat log event. Leave it as Fixed Time"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, false, false, true) then
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
					localSelf.frame = self.assignmentEditor.triggerContainer.frame
					return true
				else
					return false
				end
			end,
		},
		{
			name = "assignmentTime",
			text = FormatText(
				L["The"],
				{ L["Time"] },
				L["coincides with the end of reminder countdowns"] .. ".",
				L["Set the"],
				{ L["Time"] },
				L["to 15 seconds and press enter"]
			),
			enableNextButton = function()
				return IsTimeCorrect(self, 15.0)
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, false, false, true) then
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
					return true
				else
					return false
				end
			end,
		},
		{
			name = "assignmentSpell",
			text = FormatText(L["Check the"], { L["Spell"] }, L["checkbox"], L["and select a spell from the dropdown"]),
			enableNextButton = function()
				return CountSpells(1)
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, false, true, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if CountSpells(1) then
								for _, assignment in ipairs(GetCurrentAssignments()) do
									if assignment.spellID > constants.kTextAssignmentSpellID then
										AddOn.db.global.tutorial.firstSpell = assignment.spellID
										break
									end
								end
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
					return true
				else
					return false
				end
			end,
		},
		{
			name = "assignmentTarget",
			text = FormatText(
				L["Choosing a"],
				{ L["Target"] },
				L["adds their name to the assignment"],
				{ L["Text"] },
				L["and highlights their raid frame at the end of reminder countdown"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, true, true, true) then
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
					localSelf.frame = self.assignmentEditor.targetContainer.frame
					return true
				else
					return false
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
				if PhaseOneOkay(self, 1, true, true, true) then
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
					return true
				else
					return false
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local textFrame = self.assignmentEditor.optionalTextContainer.frame
				local previewFrame = self.assignmentEditor.previewContainer.frame
				s.HighlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
				s.HighlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
				s.HighlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
				s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, -2)
				s.HighlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset)
			end,
			PreStepDeactivated = function(_, incrementing)
				if incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "assignmentTimelineUpdated",
			text = L["The Assignment Timeline updates to reflect the spell. Its cooldown duration is represented by an alternating grey texture. If multiple instances of the same spell overlap, the rightmost spell icon will be tinted red."],
			enableNextButton = true,
			OnStepActivated = function(_)
				return PhaseOneOkay(self, 1, true, true, false) ~= nil
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, true)
				HighlightAssignmentTimelineAndPositionTutorialFrame(self)
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
				localSelf.frame = self.mainFrame.preferencesMenuButton.frame
				return true
			end,
		},
		{
			name = "createAssignmentBesideAssignee",
			text = L["Create a blank assignment in Phase 1 by left-clicking the timeline beside an assignee."],
			enableNextButton = function()
				return TwoPhaseOneAssignmentsExist()
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 1, true, true, false) then
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
					self.mainFrame.timeline:SetHorizontalScroll(0)
					self.mainFrame.timeline:SetAssignmentTimelineVerticalScroll(0)
					return true
				else
					return false
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, true)
				local leftOffset, rightOffset = GetPhaseOffsets(self, 1, 1)
				HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
			end,
		},
		{
			name = "createAssignmentBesideAssigneeExplain",
			text = L["The assignment is created relative to the start of the encounter since it was clicked within Phase 1."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 2, false, false, true, true) then
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
					return true
				else
					return false
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local triggerContainerFrame = self.assignmentEditor.triggerContainer.frame
				s.HighlightBorderFrame:SetFrameStrata(triggerContainerFrame:GetFrameStrata())
				s.HighlightBorderFrame:SetFrameLevel(triggerContainerFrame:GetFrameLevel() + 10)
				s.HighlightBorderFrame:SetPoint(
					"TOPLEFT",
					triggerContainerFrame,
					-k.HighlightPadding,
					k.HighlightPadding
				)
				local lowerFrame = self.assignmentEditor.timeContainer.frame
				s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", lowerFrame, k.HighlightPadding, -k.HighlightPadding)
				s.HighlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset)
			end,
			PreStepDeactivated = function(_, incrementing)
				if not incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "assignmentTimeTwo",
			text = FormatText(L["Set the"], { L["Time"] }, L["to 20 seconds and press enter"]),
			enableNextButton = function()
				return IsTimeCorrect(self, 20.0)
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 2, false, false, true, true) then
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
					return true
				else
					return false
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
				return CountSpells(2, true, 2)
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 2, false, true, true, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if CountSpells(2, true, 2) then
								for _, assignment in ipairs(GetCurrentAssignments()) do
									if assignment.spellID > constants.kTextAssignmentSpellID then
										if assignment.spellID ~= AddOn.db.global.tutorial.firstSpell then
											AddOn.db.global.tutorial.secondSpell = assignment.spellID
											break
										end
									end
								end
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function(_, incrementing)
				if incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "createAssignmentDuringIntermission",
			text = L["Create another blank assignment, this time during the first intermission."],
			enableNextButton = function()
				return IntermissionAssignmentExists("SCS", true) or IntermissionAssignmentExists("SAR", true)
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, false)
				local leftOffset, rightOffset = GetPhaseOffsets(self, 2, 2)
				HighlightTimelineSectionAndPositionTutorialFrame(self, leftOffset, rightOffset, 0, 32)
				self.mainFrame.timeline:SetAssignmentTimelineVerticalScroll(0)
			end,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 2, true, true, false) then
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
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function(_, incrementing)
				if incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "createAssignmentDuringIntermissionExplain",
			text = L["Since the intermission is triggered by boss health, using timed assignments would be unreliable. Instead, the spell the boss casts before transitioning into intermission is used."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 1, false, false, { "SCS", "SAR" }, k.HappyHourSpellID, true, true) then
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
					localSelf.frame = self.assignmentEditor.triggerContainer.frame
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function(_, incrementing)
				if not incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "changeIntermissionAssignmentCombatLogEventType",
			text = FormatText(L["Change the"], { L["Trigger"] }, L["to"], { L["Spell Aura Removed"] }),
			enableNextButton = function()
				return IsCombatLogEventCorrect(self, "SAR", k.HappyHourSpellID)
			end,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 1, false, false, { "SCS", "SAR" }, k.HappyHourSpellID, false, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsCombatLogEventCorrect(self, "SAR", k.HappyHourSpellID) then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						elseif category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.triggerContainer.frame
					return true
				else
					return false
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
				if IntermissionOkay(self, 1, false, false, { "SAR" }, k.HappyHourSpellID, false, true) then
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
					localSelf.frame = self.assignmentEditor.triggerContainer.frame
					return true
				else
					return false
				end
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
				if IntermissionOkay(self, 1, false, false, { "SAR" }, k.HappyHourSpellID, false, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "assignmentEditorDataChanged" then
							if IsTextChanged(self) then
								self.tutorial.nextButton:SetEnabled(true)
							end
						elseif category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					return true
				else
					return false
				end
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local textFrame = self.assignmentEditor.optionalTextContainer.frame
				local previewFrame = self.assignmentEditor.previewContainer.frame
				s.HighlightBorderFrame:SetFrameStrata(previewFrame:GetFrameStrata())
				s.HighlightBorderFrame:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
				s.HighlightBorderFrame:SetPoint("TOPLEFT", textFrame, -2, 2)
				s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", previewFrame, 2, -2)
				s.HighlightBorderFrame:Show()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset)
			end,
			PreStepDeactivated = function(_, incrementing)
				if incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "createAssignmentBesideSpell",
			text = L["Instead of left-clicking beside an assignee, create an assignment by left-clicking the timeline beside a spell."],
			enableNextButton = function()
				local count = 0
				for _, assignment in ipairs(GetCurrentAssignments()) do
					if assignment.spellID == AddOn.db.global.tutorial.secondSpell then
						count = count + 1
						if count >= 2 then
							return true
						end
					end
				end
				return false
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, true)
			end,
			OnStepActivated = function(localSelf)
				local order = PhaseOneOkay(self, 2, true, true, false)
				if order then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "added" and FindPhaseOneAssignment(3, false) then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						elseif category == "timelineFrameMouseWheel" then
							HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, order)
						end
					end)
					HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, order)
					return true
				else
					return false
				end
			end,
		},
		{
			name = "createAssignmentBesideSpellExplain",
			text = L["The new assignment is created using the matching spell."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if PhaseOneOkay(self, 3, true, true, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						elseif category == "assignmentEditorReleased" then
							if self.tutorial then
								self.tutorial:Release()
							end
						end
					end)
					localSelf.frame = self.assignmentEditor.spellAssignmentContainer.frame
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function()
				if self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "changeIntermissionAssignmentTimeByDragging",
			text = L["Change the time of the assignment by left-clicking the icon and dragging it.\nWhen dragging a combat log event assignment, it can only be placed after the boss ability, as the assignment must occur afterward."],
			enableNextButton = false,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, true)
			end,
			OnStepActivated = function(localSelf)
				local order = IntermissionOkay(self, 1, true, false, { "SAR" }, k.HappyHourSpellID, false, false)
				if order then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, timeDifference)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if type(timeDifference) == "number" and timeDifference > 0.0 then
							self.tutorial.nextButton:SetEnabled(true)
						elseif type(timeDifference) == "string" then
							if timeDifference == "timelineFrameMouseWheel" then
								local o = FindCurrentAssignmentOrder(self) or order
								HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, o)
							end
						end
					end)
					HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, order or 1)
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function(_, incrementing)
				if incrementing and self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "duplicateAssignment",
			text = L["Duplicate an assignment by control-clicking an icon and dragging."],
			enableNextButton = function()
				return TwoIntermissionAssignmentsExist()
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				EnsureAssigneeIsExpanded(self, true)
			end,
			OnStepActivated = function(localSelf)
				local order = IntermissionOkay(self, 1, true, false, { "SAR" }, k.HappyHourSpellID, false, false)
				if order then
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
								FindCurrentAssignmentOrder(self) or order
							)
						end
					end)
					HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, order)
					return true
				else
					return false
				end
			end,
		},
		{
			name = "duplicateAssignmentExplain",
			text = L["The duplicated assignment inherits all properties, besides time, from the original and is independent of it."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, true) then
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
					return true
				else
					return false
				end
			end,
			PreStepDeactivated = function()
				if self.assignmentEditor then
					self.assignmentEditor:Release()
				end
			end,
		},
		{
			name = "zoomAndPan",
			text = L["Zoom in and out horizontally on either timeline by pressing Ctrl + Mouse Scroll. Pan the view to the left and right by holding right-click."],
			enableNextButton = true,
			OnStepActivated = function()
				return IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false) ~= nil
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local timeline = self.mainFrame.timeline
				if timeline then
					local bossAbilityTimelineFrame = timeline.bossAbilityTimeline.frame
					local assignmentTimelineFrame = timeline.assignmentTimeline.frame
					s.HighlightBorderFrame:SetFrameStrata(bossAbilityTimelineFrame:GetFrameStrata())
					s.HighlightBorderFrame:SetFrameLevel(bossAbilityTimelineFrame:GetFrameLevel() + 50)
					s.HighlightBorderFrame:ClearAllPoints()
					local x = -k.HighlightPadding + k.AbilityEntryWidth + 10
					local y = k.HighlightPadding
					s.HighlightBorderFrame:SetPoint("TOPLEFT", bossAbilityTimelineFrame, x, y)
					x = -30
					y = -k.HighlightPadding
					s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", assignmentTimelineFrame, x, y)
					s.HighlightBorderFrame:Show()
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset)
				end
			end,
		},
		{
			name = "resizeMainWindow",
			text = format(
				"%s %s %s.",
				L["Drag the"],
				"|T" .. constants.resizer.kIcon .. ":0:0:0:-4|t",
				L["button to resize the main window"]
			),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "mainWindowResized" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					localSelf.frame = self.mainFrame.resizer
					return true
				else
					return false
				end
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
			enableNextButton = function()
				local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
				if collapsed[k.PlayerName] ~= nil then
					if collapsed[k.PlayerName] == true then
						return true
					end
				end
				return false
			end,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false, true) then
					self.RegisterCallback(
						Private.tutorialCallbackObject,
						localSelf.name,
						function(_, category, assignee, collapsed)
							if self.activeTutorialCallbackName ~= localSelf.name then
								return
							end
							if category == "assigneeCollapsed" and assignee == k.PlayerName and collapsed == true then
								setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
							end
						end
					)
					local timeline = self.mainFrame.timeline
					if timeline then
						local assignmentContainer = timeline:GetAssignmentContainer()
						for _, child in ipairs(assignmentContainer.children) do
							if child.type == "EPAbilityEntry" then
								---@cast child EPAbilityEntry
								local key = child:GetKey()
								if type(key) == "string" then
									if key == k.PlayerName then
										localSelf.frame = child.collapseButton
										break
									end
								end
							end
						end
						timeline:SetAssignmentTimelineVerticalScroll(0)
					end
					return true
				else
					return false
				end
			end,
		},
		{
			name = "collapseSpellsForAssigneeExplain",
			text = L["All spells for that assignee are condensed into a single row and cooldown durations are hidden. The same button can be clicked to expand spells."],
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "timelineFrameMouseWheel" then
							HighlightTimelineSectionAndPositionTutorialFrame(self, 0, 0, 0)
						end
					end)
					return true
				else
					return false
				end
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
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false, true) then
					localSelf.frame = self.mainFrame.collapseAllButton.frame
					return true
				else
					return false
				end
			end,
		},
		{
			name = "expandAllAssigneeSpells",
			text = FormatText(
				L["Click the"],
				"|T" .. [[Interface\AddOns\EncounterPlanner\Media\icons8-expand-64]] .. ":0:0:0:-6|t",
				L["button to expand all spells for all assignees"]
			),
			enableNextButton = function()
				local collapsed = AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan].collapsed
				if collapsed[k.PlayerName] ~= nil then
					if collapsed[k.PlayerName] == false then
						return true
					end
				end
				return false
			end,
			OnStepActivated = function(localSelf)
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "expandAllButtonClicked" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					localSelf.frame = self.mainFrame.expandAllButton.frame
					return true
				else
					return false
				end
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
				return true
			end,
		},
		{
			name = "filterBossSpellsExplain",
			text = L["Hiding a boss ability does not affect combat log event assignments using it."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.bossMenuButton.frame
				return true
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
				return true
			end,
		},
		{
			name = "phaseTimingEditorDescription",
			text = L["Boss phase durations and counts can be customized here. These settings are unique to each plan. If a boss phase has a fixed timer, it will not be editable. Similarly, if a boss phase does not repeat, its count will not be editable."],
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
					if self.activeTutorialCallbackName ~= localSelf.name then
						return
					end
					if category == "phaseLengthEditorReleased" then
						if self.tutorial then
							self.tutorial:Release()
						end
					end
				end)
				if not self.phaseLengthEditor then
					Private.CreatePhaseLengthEditor()
				end
				localSelf.frame = self.phaseLengthEditor.frame
				return true
			end,
			PreStepDeactivated = function(_, incrementing)
				if not incrementing and self.phaseLengthEditor then
					self.phaseLengthEditor:Release()
				end
			end,
		},
		{
			name = "editPhaseOneBossPhaseDuration",
			text = L["Change the duration of Phase 1 to 1:30."],
			enableNextButton = function()
				local boss = GetBoss(GetCurrentBossDungeonEncounterID())
				if boss then
					local phases = GetBossPhases(boss, GetCurrentDifficulty())
					if abs(phases[1].duration - 90.0) < 0.01 then
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
				return true
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
					if category == "timelineFrameMouseWheel" or category == "mainWindowResized" then
						localSelf.HighlightFrameAndPositionTutorialFrame()
					end
				end)
				return true
			end,
			HighlightFrameAndPositionTutorialFrame = function()
				local timeline = self.mainFrame.timeline
				if timeline then
					local bossAbilityTimelineFrame = timeline.bossAbilityTimeline.timelineFrame
					s.HighlightBorderFrame:SetParent(bossAbilityTimelineFrame)
					s.HighlightBorderFrame:SetFrameStrata(bossAbilityTimelineFrame:GetFrameStrata())
					s.HighlightBorderFrame:SetFrameLevel(bossAbilityTimelineFrame:GetFrameLevel() + 50)
					s.HighlightBorderFrame:ClearAllPoints()
					local leftOffset, rightOffset = GetPhaseOffsets(self, 1, 1)
					s.HighlightBorderFrame:SetPoint("TOPLEFT", bossAbilityTimelineFrame, leftOffset, 0)
					s.HighlightBorderFrame:SetPoint("BOTTOMRIGHT", bossAbilityTimelineFrame, rightOffset, 0)
					s.HighlightBorderFrame:Show()
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, k.TutorialOffset + 10)
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
				if IntermissionOkay(self, 2, true, true, { "SAR" }, k.HappyHourSpellID, false, false, true) then
					self.RegisterCallback(Private.tutorialCallbackObject, localSelf.name, function(_, category)
						if self.activeTutorialCallbackName ~= localSelf.name then
							return
						end
						if category == "simulationStarted" then
							setCurrentStep(self.tutorial.currentStep, self.tutorial.currentStep + 1)
						end
					end)
					localSelf.frame = self.mainFrame.simulateRemindersButton.frame
					return true
				else
					return false
				end
			end,
		},
		{
			name = "minimizeMainWindow",
			text = L["Minimize the main window to get a better view."],
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					return false
				else
					if self.mainFrame.minimizedWindowBar and self.mainFrame.minimizedWindowBar.frame:IsShown() then
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
					localSelf.frame = self.mainFrame.windowBar.buttons[1].frame
					return true
				end
			end,
		},
		{
			name = "maximizeMainWindow",
			text = L["Click the maximize button to continue the tutorial."],
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					return false
				else
					if
						not self.mainFrame.minimizedWindowBar or not self.mainFrame.minimizedWindowBar.frame:IsShown()
					then
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
					HighlightFrame(self.mainFrame.minimizedWindowBar.buttons[1].frame)
					self.tutorial.frame:ClearAllPoints()
					self.tutorial.frame:SetPoint("TOP", s.HighlightBorderFrame, "BOTTOM", 0, -k.TutorialOffset)
					self.tutorial.frame:Show()
					return true
				end
			end,
		},
		{
			name = "simulateRemindersEnd",
			text = FormatText(L["Click the"], { L["Stop Simulating"] }, L["button"], L["to stop previewing"]),
			enableNextButton = false,
			OnStepActivated = function(localSelf)
				if not self:IsSimulatingBoss() then
					return false
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
					return true
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
				self.optionsMenu:SetCurrentTab(L["Reminder"], L["Reminder"])
				for _, widget in ipairs(self.optionsMenu.tabTitleContainer.children) do
					if widget.type == "EPButton" and widget.button then
						---@cast widget EPButton
						if widget.button:GetText() == L["Reminder"] then
							localSelf.frame = widget.frame
							break
						end
					end
				end
				return true
			end,
			PreStepDeactivated = function()
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
					self.CreateAssignmentEditor()
					local timelineRows = AddOn.db.profile.preferences.timelineRows
					timelineRows.numberOfAssignmentsToShow = max(timelineRows.numberOfAssignmentsToShow, 2)
					CreateGenericAssignmentIfNoAssignmentsAndUpdateInterfaceFromAssignment()
				end
				localSelf.frame = self.assignmentEditor.deleteButton.frame
				return true
			end,
			PreStepDeactivated = function(localSelf)
				localSelf.ignoreNextAssignmentEditorReleased = nil
				if self.assignmentEditor then
					self.assignmentEditor:Release()
				end
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
					CreateGenericAssignmentIfNoAssignmentsAndUpdateInterfaceFromAssignment()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						if child.type == "EPAbilityEntry" then
							---@cast child EPAbilityEntry
							local key = child:GetKey()
							if type(key) == "table" then
								if key.assignee and key.assignee == k.PlayerName then
									localSelf.frame = child.check.frame
									break
								end
							end
						end
					end
				end
				return true
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
					CreateGenericAssignmentIfNoAssignmentsAndUpdateInterfaceFromAssignment()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						if child.type == "EPAbilityEntry" then
							---@cast child EPAbilityEntry
							local key = child:GetKey()
							if type(key) == "string" and key == k.PlayerName then
								localSelf.frame = child.check.frame
								break
							end
						end
					end
				end
				return true
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
					CreateGenericAssignmentIfNoAssignmentsAndUpdateInterfaceFromAssignment()
					local assignmentContainer = timeline:GetAssignmentContainer()
					for _, child in ipairs(assignmentContainer.children) do
						if child.type == "EPAbilityEntry" then
							---@cast child EPAbilityEntry
							local key = child:GetKey()
							if type(key) == "string" and key == k.PlayerName then
								if child.swap then
									localSelf.frame = child.swap.frame
								end
								break
							end
						end
					end
				end
				return true
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
				return true
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
				return true
			end,
		},
		{
			name = "sendPlan",
			text = format(
				"%s. %s.",
				L["Group leaders and assistants can send the current plan"],
				L["Receivers can approve, reject, or auto-accept plans from trusted characters"]
			),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.sendPlanButton.frame
				return true
			end,
		},
		{
			name = "proposeChanges",
			text = format("%s.", L["Others can propose changes, which the leader reviews"]),
			enableNextButton = true,
			OnStepActivated = function(localSelf)
				localSelf.frame = self.mainFrame.proposeChangesButton.frame
				return true
			end,
		},
		{
			name = "tutorialCompleted",
			text = L["Tutorial Complete! You can delete the tutorial plan or keep it for future reference."],
			enableNextButton = true,
			OnStepActivated = function(_)
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("CENTER", UIParent)
				local x, y = self.tutorial.frame:GetLeft(), self.tutorial.frame:GetTop()
				self.tutorial.frame:ClearAllPoints()
				self.tutorial.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
				return true
			end,
		},
	}
end

local creatingTutorial = false

function Private:OpenTutorial()
	if not self.tutorial and not creatingTutorial then
		creatingTutorial = true
		if not self.mainFrame then
			self:CreateInterface()
		end

		self:CloseDialogs()
		if self.IsSimulatingBoss() then
			self:StopSimulatingBoss()
		end

		local highlightBorderFrameWasVisible = false
		self.mainFrame:SetCallback("MinimizeButtonClicked", function()
			if self.tutorial then
				highlightBorderFrameWasVisible = s.HighlightBorderFrame:IsShown()
				self.tutorial.frame:Hide()
				s.HighlightBorderFrame:Hide()
				if self.activeTutorialCallbackName then
					self.callbacks:Fire(self.activeTutorialCallbackName, "minimizeButtonClicked")
				end
			end
		end)
		self.mainFrame:SetCallback("MaximizeButtonClicked", function()
			if self.tutorial then
				self.tutorial.frame:Show()
				if highlightBorderFrameWasVisible then
					s.HighlightBorderFrame:Show()
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
				AddOn.db.global.tutorial.completed = true
				AddOn.db.global.tutorial.skipped = false
				AddOn.db.global.tutorial.lastStepName = ""
				self.tutorial:Release()
			else
				local currentStep = steps[currentStepIndex]

				s.HighlightBorderFrame:SetParent(UIParent)
				s.HighlightBorderFrame:ClearAllPoints()
				s.HighlightBorderFrame:Hide()

				local continue = true
				if currentStep.OnStepActivated then
					continue = currentStep:OnStepActivated()
				end

				if continue then
					AddOn.db.global.tutorial.lastStepName = currentStep.name
					self.activeTutorialCallbackName = currentStep.name
					self.tutorial.currentStep = currentStepIndex

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
						local offset = k.TutorialOffset
						if currentStep.additionalVerticalOffset then
							offset = offset + currentStep.additionalVerticalOffset
						end
						self.tutorial.frame:SetPoint("BOTTOM", s.HighlightBorderFrame, "TOP", 0, offset)
					end
				else
					if currentStep.PreStepDeactivated then
						currentStep:PreStepDeactivated(false)
					end
					SetCurrentStep(previousStepIndex - 1, currentStepIndex - 1)
				end
			end
		end

		steps = CreateTutorialSteps(self, SetCurrentStep)
		totalStepCount = #steps

		--@debug@
		do
			local map = {}
			for _, step in ipairs(steps) do
				if map[step.name] then
					print("Duplicate entry:", step.name)
				else
					map[step.name] = true
				end
			end
		end
		--@end-debug@

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
		tutorial.frame:SetFrameLevel(k.TutorialFrameLevel)
		tutorial:SetCallback("OnRelease", function()
			self.tutorial = nil
			self.UnregisterAllCallbacks(self.tutorialCallbackObject)
			if not AddOn.db.global.tutorial.completed then
				AddOn.db.global.tutorial.skipped = true
			end
			s.HighlightBorderFrame:ClearAllPoints()
			s.HighlightBorderFrame:Hide()
			for _, step in pairs(steps) do
				if step.PreStepDeactivated then
					step:PreStepDeactivated(true, true)
				end
			end
			if not self.assignmentEditor and self.mainFrame and self.mainFrame.timeline then
				self.mainFrame.timeline.ClearSelectedBossAbilities()
				self.mainFrame.timeline.ClearSelectedAssignments()
			end
			self.tutorialCallbackObject = nil
			self.activeTutorialCallbackName = nil
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

		local lastTutorialStepName = AddOn.db.global.tutorial.lastStepName
		local plan = FindTutorialPlan(k.BrewmasterAldryrEncounterID)
		if plan then
			AddOn.db.profile.lastOpenPlan = plan.name
			interfaceUpdater.UpdateFromPlan(plan)
		else
			if
				lastTutorialStepName:len() > 0
				and lastTutorialStepName ~= "start"
				and lastTutorialStepName ~= "planMenuBar"
				and lastTutorialStepName ~= "createNewPlan"
				and lastTutorialStepName ~= "newPlanDialog"
			then -- Only allow these steps to not have a tutorial plan associated with them
				lastTutorialStepName = "createNewPlan"
				AddOn.db.global.tutorial.lastStepName = "createNewPlan"
			end
		end

		SetCurrentStep(0, FindStepIndex(lastTutorialStepName))
		creatingTutorial = false
	end
end
