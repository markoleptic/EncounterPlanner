local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
local CreateNewInstance = Private.CreateNewInstance

local pairs = pairs
local type = type
local getmetatable, setmetatable = getmetatable, setmetatable

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

---@class TimedAssignment
Private.classes.TimedAssignment = setmetatable({
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.TimedAssignment.__index = Private.classes.TimedAssignment

---@class TimelineAssignment
Private.classes.TimelineAssignment = {
	startTime = 0.0,
	cooldownDuration = 0.0,
	maxCharges = 1,
	effectiveCooldownDuration = 0.0,
}
Private.classes.TimelineAssignment.__index = Private.classes.TimelineAssignment

---@param o any
---@param planID string
---@return Assignment
function Private.classes.Assignment:New(o, planID)
	local instance = CreateNewInstance(self, o)
	instance.uniqueID = Private.GetNewAssignmentID(planID)
	return instance
end

---@param o any
---@param planID string
---@param removeInvalidFields boolean|nil
---@return CombatLogEventAssignment
function Private.classes.CombatLogEventAssignment:New(o, planID, removeInvalidFields)
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
function Private.classes.TimedAssignment:New(o, planID, removeInvalidFields)
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
function Private.classes.TimelineAssignment:New(assignment, o, planID)
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
