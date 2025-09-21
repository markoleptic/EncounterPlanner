local _, Namespace = ...

---@class Private
local Private = Namespace

---@class AssignmentUtilities
local AssignmentUtilities = Private.assignmentUtilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local CreateNewInstance = Private.CreateNewInstance

local assert = assert
local getmetatable, setmetatable = getmetatable, setmetatable
local pairs = pairs
local type = type

--- Collects all valid fields recursively from the inheritance chain.
---@param classTable table The class table to collect fields from
---@param validFields table The table to populate with valid fields
local function CollectValidFields(classTable, validFields, visited)
	for k, _ in pairs(classTable) do
		if k ~= "__index" then
			validFields[k] = true
		end
	end
	local mt = getmetatable(classTable)
	if mt and mt.__index and type(mt.__index) == "table" then
		if not visited[mt.__index] then
			visited[mt.__index] = true
			CollectValidFields(mt.__index, validFields, visited)
		end
	end
end

--- Removes invalid fields not present in the inheritance chain of the class.
---@param classTable table The target class table
---@param o table The object to clean up
local function RemoveInvalidFields(classTable, o)
	local validFields = {}
	local visited = {}
	CollectValidFields(classTable, validFields, visited)
	for k, _ in pairs(o) do
		if k ~= "__index" and k ~= "New" then
			if not validFields[k] then
				o[k] = nil
			end
		end
	end
end

---@class Assignment
Private.classes.Assignment = {
	uniqueID = 0,
	assignee = "",
	text = "",
	spellID = 0,
	targetName = "",
}
---@class Assignment
local Assignment = Private.classes.Assignment

---@class CombatLogEventAssignment
Private.classes.CombatLogEventAssignment = setmetatable({
	combatLogEventType = "SCS",
	combatLogEventSpellID = 0,
	spellCount = 1,
	time = 0.0,
	phase = 0,
	bossPhaseOrderIndex = 0,
}, { __index = Private.classes.Assignment })
Private.classes.CombatLogEventAssignment.__index = Private.classes.CombatLogEventAssignment
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment

---@class TimedAssignment
Private.classes.TimedAssignment = setmetatable({
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.TimedAssignment.__index = Private.classes.TimedAssignment
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment

---@class TimelineAssignment
Private.classes.TimelineAssignment = {
	startTime = 0.0,
	cooldownDuration = 0.0,
	maxCharges = 1,
	effectiveCooldownDuration = 0.0,
}
Private.classes.TimelineAssignment.__index = Private.classes.TimelineAssignment
---@class TimelineAssignment
local TimelineAssignment = Private.classes.TimelineAssignment

---@param o any
---@param planID string
---@return Assignment
function Assignment:New(o, planID)
	local instance = CreateNewInstance(self, o)
	instance.uniqueID = Private.GetNewAssignmentID(planID)
	return instance
end

---@param o any
---@param planID string
---@param removeInvalidFields boolean|nil
---@return CombatLogEventAssignment
function CombatLogEventAssignment:New(o, planID, removeInvalidFields)
	if not o or getmetatable(o) ~= Private.classes.Assignment then
		o = Private.classes.Assignment:New(o, planID)
	end

	local instance = CreateNewInstance(self, o)
	if removeInvalidFields then
		RemoveInvalidFields(self, instance)
	end
	return instance
end

---@param o any
---@param planID string
---@param removeInvalidFields boolean|nil
---@return TimedAssignment
function TimedAssignment:New(o, planID, removeInvalidFields)
	if not o or getmetatable(o) ~= Private.classes.Assignment then
		o = Private.classes.Assignment:New(o, planID)
	end
	local instance = CreateNewInstance(self, o)
	if removeInvalidFields then
		RemoveInvalidFields(self, instance)
	end
	return instance
end

-- Copies an assignment with a new uniqueID.
---@param assignmentToCopy Assignment
---@param planID string
---@return Assignment
function Private.DuplicateAssignment(assignmentToCopy, planID)
	local newAssignment = Private.classes.Assignment:New(nil, planID)
	local newId = newAssignment.uniqueID
	for key, value in pairs(Private.DeepCopy(assignmentToCopy)) do
		newAssignment[key] = value
	end
	newAssignment.uniqueID = newId
	setmetatable(newAssignment, getmetatable(assignmentToCopy))
	return newAssignment
end

-- Creates a timeline assignment from an assignment.
---@param assignment Assignment
---@param o any
---@param planID string
---@return TimelineAssignment
function TimelineAssignment:New(assignment, o, planID)
	local instance = CreateNewInstance(self, o)
	instance.assignment = assignment or Private.classes.Assignment:New(assignment, planID)
	return instance
end

-- Creates a timeline assignment from an assignment.
---@param timelineAssignmentToCopy TimelineAssignment
---@param o any
---@param planID string
---@return TimelineAssignment
function Private.DuplicateTimelineAssignment(timelineAssignmentToCopy, o, planID)
	o = o or {}
	for key, value in pairs(Private.DeepCopy(timelineAssignmentToCopy)) do
		if key ~= "assignment" then
			o[key] = value
		end
	end
	o.assignment = Private.DuplicateAssignment(timelineAssignmentToCopy.assignment, planID)
	setmetatable(o, getmetatable(timelineAssignmentToCopy))
	return o
end

do
	local GetSpellName = C_Spell.GetSpellName
	local kTextAssignmentSpellID = Private.constants.kTextAssignmentSpellID
	local kRolePriority = Private.constants.kRolePriority

	---@param a integer
	---@param b integer
	---@return boolean
	local function SpellPriority(a, b)
		if a <= kTextAssignmentSpellID or b <= kTextAssignmentSpellID then
			return a < b
		else
			return GetSpellName(a) < GetSpellName(b)
		end
	end
	-- Creates a Timeline Assignment comparator function.
	---@param roster table<string, RosterEntry> Roster associated with the assignments.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@return fun(a:TimelineAssignment, b:TimelineAssignment):boolean
	function AssignmentUtilities.CompareAssignments(roster, assignmentSortType)
		---@param a TimelineAssignment
		---@param b TimelineAssignment
		return function(a, b)
			local assigneeA, assigneeB = a.assignment.assignee, b.assignment.assignee
			local spellIDA, spellIDB = a.assignment.spellID, b.assignment.spellID
			if assignmentSortType == "Alphabetical" then -- Assignee > Spell Name > Start Time
				if assigneeA == assigneeB then
					if spellIDA == spellIDB then
						return a.startTime < b.startTime
					else
						return SpellPriority(spellIDA, spellIDB)
					end
				else
					return assigneeA < assigneeB
				end
			elseif assignmentSortType == "First Appearance" then -- Start Time > Assignee > Spell Name
				if a.startTime == b.startTime then
					if assigneeA == assigneeB then
						return SpellPriority(spellIDA, spellIDB)
					else
						return assigneeA < assigneeB
					end
				else
					return a.startTime < b.startTime
				end
			elseif assignmentSortType:match("^Role") then
				local rolePriorityA, rolePriorityB = kRolePriority[""], kRolePriority[""]
				if roster[assigneeA] and roster[assigneeB] then
					rolePriorityA, rolePriorityB =
						kRolePriority[roster[assigneeA].role], kRolePriority[roster[assigneeB].role]
				end
				if rolePriorityA == rolePriorityB then
					if assignmentSortType == "Role > Alphabetical" then -- Role > Assignee > Spell Name > Start Time
						if assigneeA == assigneeB then
							if spellIDA == spellIDB then
								return a.startTime < b.startTime
							else
								return SpellPriority(spellIDA, spellIDB)
							end
						else
							return assigneeA < assigneeB
						end
					else -- Role > Start Time > Assignee > Spell Name
						if a.startTime == b.startTime then
							if assigneeA == assigneeB then
								return SpellPriority(spellIDA, spellIDB)
							else
								return assigneeA < assigneeB
							end
						else
							return a.startTime < b.startTime
						end
					end
				else
					return rolePriorityA < rolePriorityB
				end
			else
				return false
			end
		end
	end
end

---@param a TimedAssignment|CombatLogEventAssignment
---@param b TimedAssignment|CombatLogEventAssignment
---@return boolean
function AssignmentUtilities.AssignmentsEqual(a, b)
	local metatableA, metatableB = getmetatable(a), getmetatable(b)
	if metatableA ~= metatableB then
		return false
	end
	if metatableA == TimedAssignment then
		return a.assignee == b.assignee
			and a.spellID == b.spellID
			and a.time == b.time
			and a.targetName == b.targetName
			and a.text == b.text
	elseif metatableA == CombatLogEventAssignment then
		return a.assignee == b.assignee
			and a.spellID == b.spellID
			and a.time == b.time
			and a.combatLogEventSpellID == b.combatLogEventSpellID
			and a.combatLogEventType == b.combatLogEventType
			and a.spellCount == b.spellCount
			and a.targetName == b.targetName
			and a.text == b.text
	end
	return true
end

---@param assignment CombatLogEventAssignment
---@param dungeonEncounterID integer
---@param difficulty DifficultyType
function AssignmentUtilities.UpdateAssignmentBossPhase(assignment, dungeonEncounterID, difficulty)
	local castTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable(dungeonEncounterID, difficulty)
	local bossPhaseTable = bossUtilities.GetOrderedBossPhases(dungeonEncounterID, difficulty)
	if castTimeTable and bossPhaseTable then
		local combatLogEventSpellID = assignment.combatLogEventSpellID
		local spellCount = assignment.spellCount
		if castTimeTable[combatLogEventSpellID] and castTimeTable[combatLogEventSpellID][spellCount] then
			local orderedBossPhaseIndex = castTimeTable[combatLogEventSpellID][spellCount].bossPhaseOrderIndex
			assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
			assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
		end
	end
end

do
	-- Finds the nearest combat log event corresponding to spellID to make a valid combat log event assignment.
	---@param assignment CombatLogEventAssignment Combat log event assignment.
	---@param dungeonEncounterID integer Boss dungeon encounter ID.
	---@param spellID integer Combat log event spell ID.
	---@param difficulty DifficultyType Encounter difficulty.
	local function ConvertToValidCombatLogEventType(assignment, dungeonEncounterID, spellID, difficulty)
		local validTypes = bossUtilities.GetValidCombatLogEventTypes(dungeonEncounterID, spellID, difficulty)
		assert(#validTypes > 0, "Combat log event spell ID has at least one valid combat log event type")
		if #validTypes > 0 then
			local relativeTime, currentEventType = assignment.time, assignment.combatLogEventType
			local currentSpellID, currentSpellCount = assignment.combatLogEventSpellID, assignment.spellCount
			local absoluteTime = bossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
				relativeTime,
				dungeonEncounterID,
				currentSpellID,
				currentSpellCount,
				currentEventType,
				difficulty
			)
			local newEventType = validTypes[1]
			local newSpellCount =
				bossUtilities.FindNearestSpellCount(absoluteTime, dungeonEncounterID, spellID, newEventType, difficulty)
			if newSpellCount then
				assignment.combatLogEventType = newEventType
				assignment.combatLogEventSpellID = spellID
				assignment.spellCount = newSpellCount
			end
		end
	end

	---@param assignment CombatLogEventAssignment
	---@param dungeonEncounterID integer
	---@param newSpellID integer
	---@param difficulty DifficultyType
	function AssignmentUtilities.ChangeAssignmentCombatLogEventSpellID(
		assignment,
		dungeonEncounterID,
		newSpellID,
		difficulty
	)
		local currentEventType = assignment.combatLogEventType
		local valid, newEventType =
			bossUtilities.IsValidCombatLogEventType(dungeonEncounterID, newSpellID, currentEventType, difficulty)
		if valid or (not valid and newEventType) then
			local currentSpellID, currentSpellCount = assignment.combatLogEventSpellID, assignment.spellCount

			local assignNewSpellIDAndEventType = false
			if bossUtilities.IsValidSpellCount(dungeonEncounterID, newSpellID, currentSpellCount, nil, difficulty) then
				assignNewSpellIDAndEventType = true
			else
				local relativeTime = assignment.time
				local absoluteTime = bossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					relativeTime,
					dungeonEncounterID,
					currentSpellID,
					currentSpellCount,
					currentEventType,
					difficulty
				)
				local newSpellCount = bossUtilities.FindNearestSpellCount(
					absoluteTime,
					dungeonEncounterID,
					newSpellID,
					newEventType,
					difficulty
				)
				if newSpellCount then
					assignment.spellCount = newSpellCount
					assignNewSpellIDAndEventType = true
				end
			end

			if assignNewSpellIDAndEventType then
				assignment.combatLogEventSpellID = newSpellID
				if newEventType then
					assignment.combatLogEventType = newEventType
				end
			end
		else
			ConvertToValidCombatLogEventType(assignment, dungeonEncounterID, newSpellID, difficulty)
		end

		AssignmentUtilities.UpdateAssignmentBossPhase(
			assignment --[[@as CombatLogEventAssignment]],
			dungeonEncounterID,
			difficulty
		)
	end
end

local kValidCombatLogEventTypes = { ["SCS"] = true, ["SCC"] = true, ["SAA"] = true, ["SAR"] = true, ["UD"] = true }

---@param assignment CombatLogEventAssignment|TimedAssignment
---@param dungeonEncounterID integer
---@param newType "Fixed Time"|CombatLogEventType
---@param difficulty DifficultyType
---@param planID string
function AssignmentUtilities.ChangeAssignmentType(assignment, dungeonEncounterID, newType, difficulty, planID)
	if kValidCombatLogEventTypes[newType] then
		local newEventType = newType --[[@as CombatLogEventType]]
		if getmetatable(assignment) ~= CombatLogEventAssignment then
			local combatLogEventSpellID, spellCount, minTime =
				bossUtilities.FindNearestCombatLogEvent(assignment.time, dungeonEncounterID, newEventType, difficulty)
			assignment = CombatLogEventAssignment:New(assignment, planID, true)
			assignment.combatLogEventType = newEventType
			if combatLogEventSpellID and spellCount and minTime then
				assignment.combatLogEventSpellID = combatLogEventSpellID
				assignment.spellCount = spellCount
				assignment.time = utilities.Round(minTime, 1)
			end
		else
			local currentSpellID = assignment.combatLogEventSpellID
			if
				bossUtilities.IsValidCombatLogEventType(dungeonEncounterID, currentSpellID, newEventType, difficulty)
			then
				assignment.combatLogEventType = newEventType
			else
				local currentSpellCount, currentEventType = assignment.spellCount, assignment.combatLogEventType
				local absoluteTime = bossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					dungeonEncounterID,
					currentSpellID,
					currentSpellCount,
					currentEventType,
					difficulty
				)
				if absoluteTime then
					--- Ignore new time offset to keep things similar to before
					local newCombatLogEventSpellID, newSpellCount = bossUtilities.FindNearestCombatLogEvent(
						absoluteTime,
						dungeonEncounterID,
						newEventType,
						difficulty
					)
					if newCombatLogEventSpellID and newSpellCount then
						assignment.combatLogEventSpellID = newCombatLogEventSpellID
						assignment.combatLogEventType = newEventType
						assignment.spellCount = newSpellCount
					end
				end
			end
		end
		AssignmentUtilities.UpdateAssignmentBossPhase(
			assignment --[[@as CombatLogEventAssignment]],
			dungeonEncounterID,
			difficulty
		)
	elseif newType == "Fixed Time" then
		if getmetatable(assignment) ~= TimedAssignment then
			local convertedTime = nil
			if getmetatable(assignment) == CombatLogEventAssignment then
				convertedTime = bossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					dungeonEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType,
					difficulty
				)
			end
			assignment = TimedAssignment:New(assignment, planID, true)
			if convertedTime then
				assignment.time = utilities.Round(convertedTime, 1)
			end
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID.
---@param absoluteTime number Time from the start of the boss encounter.
---@param assignee string Assignee name or assignee type.
---@param assignmentSpellID integer|nil Assignment spell ID.
---@param difficulty DifficultyType Encounter difficulty.
---@param planID string Unique plan ID.
---@return TimedAssignment|CombatLogEventAssignment|nil
function AssignmentUtilities.CreateNewAssignment(
	encounterID,
	absoluteTime,
	assignee,
	assignmentSpellID,
	difficulty,
	planID
)
	local assignment = nil
	local boss = bossUtilities.GetBoss(encounterID)
	local preferredAbilities = bossUtilities.GetBossPreferredCombatLogEventAbilities(boss, difficulty)

	if preferredAbilities then
		local phases = bossUtilities.GetBossPhases(boss, difficulty)
		local orderedBossPhaseTable = bossUtilities.GetOrderedBossPhases(encounterID, difficulty)
		local absoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
		local newSpellID, newSpellCount, newEventType, newTime = bossUtilities.FindNearestPreferredCombatLogEvent(
			absoluteTime,
			encounterID,
			preferredAbilities,
			phases,
			orderedBossPhaseTable,
			difficulty
		)
		if newSpellID and newSpellCount and newEventType and newTime then
			local orderedBossPhaseIndex = absoluteSpellCastTimeTable[newSpellID][newSpellCount].bossPhaseOrderIndex
			assignment = CombatLogEventAssignment:New(assignment, planID, true)
			assignment.combatLogEventType = newEventType
			assignment.combatLogEventSpellID = newSpellID
			assignment.spellCount = newSpellCount
			assignment.time = utilities.Round(newTime, 1)
			assignment.phase = absoluteSpellCastTimeTable[orderedBossPhaseIndex]
			assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
		end
	end

	if not assignment then
		assignment = TimedAssignment:New(assignment, planID, true)
		assignment.time = utilities.Round(absoluteTime, 1)
	end

	assignment.assignee = assignee
	if assignmentSpellID then
		assignment.spellID = assignmentSpellID
	end

	return assignment
end

---@param assignments table<integer, Assignment>
---@param planID string
function AssignmentUtilities.SetAssignmentMetaTables(assignments, planID)
	for _, assignment in pairs(assignments) do
		assignment.countdownLength = nil
		assignment.cancelIfAlreadyCasted = nil
		assignment.holdDuration = nil
		assignment = Assignment:New(assignment, planID)
		if
			---@diagnostic disable-next-line: undefined-field
			assignment.combatLogEventType
			---@diagnostic disable-next-line: undefined-field
			and assignment.combatLogEventSpellID
		then
			assignment = CombatLogEventAssignment:New(assignment, planID)
			---@diagnostic disable-next-line: undefined-field
		else
			assignment = TimedAssignment:New(assignment, planID)
		end
	end
end
