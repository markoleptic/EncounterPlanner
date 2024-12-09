---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

local LibStub = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local pairs = pairs
local setmetatable = setmetatable
local type = type

---@alias CombatLogEventType
---| "SCC" SPELL_CAST_SUCCESS
---| "SCS" SPELL_CAST_START
---| "SAA" SPELL_AURA_APPLIED
---| "SAR" SPELL_AURA_REMOVED

---@alias AssignmentType
---| "CombatLogEventAssignment"
---| "TimedAssignment"
---| "PhasedAssignment"

---@alias AssigneeType
---| "Everyone"
---| "Role"
---| "GroupNumber"
---| "Tanks"
---| "Class"
---| "Individual"

---@alias AssignmentSortType
---| "Alphabetical"
---| "First Appearance"
---| "Role > Alphabetical"
---| "Role > First Appearance"

---@alias GameTooltipTemplate GameTooltip

local assignmentIDCounter = 0

Private.classes = {}

---@class Assignment
---@field assigneeNameOrRole string Who to assign the assignment to
---@field line string Originally parsed line in the form: {assigneeNameOrRole} {options}
---@field text string The originally parsed portion of the assignment containing a {text}{/text} block
---@field textWithIconReplacements string Text with icons formatted back in
---@field strWithIconReplacements string Line with icons formatted back in, similar to how it appears in the note
---@field spellInfo { spellID: integer, name: string, iconID: integer } The spell info for the assignment
---@field targetName string|nil The target's name if the assignment has a '@'
Private.classes.Assignment = {
	assigneeNameOrRole = "",
	line = "",
	text = "",
	textWithIconReplacements = "",
	strWithIconReplacements = "",
	spellInfo = { spellID = 0, name = "", iconID = 0 },
	targetName = "",
	uniqueID = 0,
	generalText = "",
	generalTextSpellID = -1,
}

-- An assignment based on a combat log event.
---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType|nil The type of combat log even the assignment is triggered by
---@field combatLogEventSpellID integer|nil The spell for the event
---@field phase number|nil The phase the combat log event must occur in (Currently not used)
---@field spellCount integer|nil The number of times the combat log event must have occurred
---@field time number|nil The time from the combat log event to trigger the assignment
Private.classes.CombatLogEventAssignment = setmetatable({
	combatLogEventType = "SCS",
	combatLogEventSpellID = 0,
	phase = 1,
	spellCount = 1,
	time = 0,
}, { __index = Private.classes.Assignment })
Private.classes.CombatLogEventAssignment.__index = Private.classes.CombatLogEventAssignment

-- An assignment based on time from the boss being pulled.
---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered
Private.classes.TimedAssignment = setmetatable({
	time = 0,
}, { __index = Private.classes.Assignment })
Private.classes.TimedAssignment.__index = Private.classes.TimedAssignment

-- An assignment dependent only upon a boss phase. Currently half-implemented.
---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by
---@field time number The time from the start of the phase to trigger the assignment
Private.classes.PhasedAssignment = setmetatable({
	phase = 1,
	time = 0,
}, { __index = Private.classes.Assignment })
Private.classes.PhasedAssignment.__index = Private.classes.PhasedAssignment

-- Wrapper around an assignment with additional info about where to draw the assignment on the timeline.
---@class TimelineAssignment
---@field assignment Assignment The assignment
---@field startTime number Time used to place the assignment on the timeline
---@field order number The row of the assignment in the timeline.

Private.classes.TimelineAssignment = {}
Private.classes.TimelineAssignment.__index = Private.classes.TimelineAssignment

---@class RaidInstance
---@field name string The name of the raid
---@field journalInstanceID number The journal instance ID of the raid. All bosses share the same JournalInstanceID
---@field instanceId number The instance ID for the zone the boss is located in (?)
---@field bosses table<integer, BossDefinition>
Private.classes.RaidInstance = {
	name = "",
	journalInstanceID = 0,
	instanceId = 0,
	bosses = {},
}

---@class BossDefinition
---@field name string Name of the boss
---@field bossID table<integer,integer> ID of the boss or bosses
---@field journalEncounterID integer Journal encounter ID of the boss encounter
---@field dungeonEncounterID integer Dungeon encounter ID of the boss encounter
Private.classes.BossDefinition = {
	name = "",
	bossID = {},
	journalEncounterID = 0,
	dungeonEncounterID = 0,
}

---@class Boss
---@field abilities table<integer, BossAbility> A list of abilities
---@field phases table<integer, BossPhase> A list of phases
---@field sortedAbilityIDs table<integer, integer> An ordered list of abilities sorted by first appearance
Private.classes.Boss = {
	abilities = {},
	phases = {},
	sortedAbilityIDs = {},
}

---@class BossAbility
---@field phases table<number, BossAbilityPhase> Describes at which times in which phases the ability occurs in
---@field eventTriggers table<integer, EventTrigger>|nil Events the ability triggers in response to
---@field duration number Usually how long the ability effect lasts
---@field castTime number The actual cast time of the ability
Private.classes.BossAbility = {
	phases = {},
	eventTriggers = nil,
	duration = 0,
	castTime = 0,
}

---@class BossPhase
---@field duration number The duration of the boss phase
---@field defaultDuration number The default duration of the boss phase
---@field count number The number of times the boss phase occurs
---@field defaultCount number The default number of times the boss phase occurs
---@field repeatAfter number|nil Which phase this phase repeats after
Private.classes.BossPhase = {
	duration = 0,
	defaultDuration = 0,
	count = 0,
	defaultCount = 0,
	repeatAfter = nil,
}

---@class BossAbilityPhase
---@field castTimes table<number> An ordered list of cast times, where the actual cast time is the running sum
---@field repeatInterval number|nil If defined, the ability will repeat at this interval starting from the last cast time
Private.classes.BossAbilityPhase = {
	castTimes = {},
	repeatInterval = nil,
}

---@class EventTrigger
---@field combatLogEventType CombatLogEventType The combat log event type that acts as a trigger
---@field castTimes table<number> An ordered list of cast times, where the actual cast time is the running sum
---@field repeatInterval {triggerCastIndex: number, castTimes: table<number>}|nil Describes criteria for repeating casts
Private.classes.EventTrigger = {
	combatLogEventType = "SCS",
	castTimes = {},
	repeatInterval = nil,
}

---@class BossAbilityInstance
---@field spellID number
---@field spellOccurrence integer The number of times the spell has already been cast prior to this instance (+1).
---@field phase number
---@field castTime number|nil The cast time from the start of the encounter
---@field relativeCastTime number|nil The cast time from the trigger cast time, if applicable
---@field combatLogEventType CombatLogEventType|nil
---@field triggerSpellID number|nil
---@field triggerCastIndex number|nil
---@field repeatInstance number|nil
---@field repeatCastIndex number|nil
Private.classes.BossAbilityInstance = {
	spellID = 0,
	spellOccurrence = 1,
	phase = 1,
	castTime = nil,
	relativeCastTime = nil,
	combatLogEventType = nil,
	triggerSpellID = nil,
	triggerCastIndex = nil,
	repeatInstance = nil,
	repeatCastIndex = nil,
}

---@class EncounterPlannerDbRosterEntry
---@field class string|nil
---@field classColoredName string|nil
---@field role RaidGroupRole|nil
Private.classes.EncounterPlannerDbRosterEntry = {}

---@class EncounterPlannerDbNote
---@field bossName string|nil
---@field content table<integer, string>
---@field assignments table<integer, Assignment>
---@field roster table<string, EncounterPlannerDbRosterEntry>
---@field collapsed table<string, boolean>
Private.classes.EncounterPlannerDbNote = {
	bossName = nil,
	content = {},
	assignments = {},
	roster = {},
	collapsed = {},
}

--- Copies a table
---@generic T
---@param inTable T A table with any keys and values of type T
---@return T
function Private.DeepCopy(inTable)
	local copy = {}
	if type(inTable) == "table" then
		for k, v in pairs(inTable) do
			if k ~= "__index" then
				copy[k] = Private.DeepCopy(v)
			end
		end
	else
		copy = inTable
	end
	return copy
end

--- Collects all valid fields recursively from the inheritance chain.
---@param classTable table The class table to collect fields from
---@param validFields table The table to populate with valid fields
local function CollectValidFields(classTable, validFields, visited)
	if visited[classTable] then
		return
	end
	visited[classTable] = true
	for key, _ in pairs(classTable) do
		validFields[key] = true
	end
	if classTable.__index and type(classTable.__index) == "table" then
		CollectValidFields(classTable.__index, validFields, visited)
	end
end

--- Removes invalid fields not present in the inheritance chain of the class.
---@param classTable table The target class table
---@param o table The object to clean up
local function RemoveInvalidFields(classTable, o)
	local validFields = {}
	local visited = {}
	CollectValidFields(classTable, validFields, visited)
	for key, _ in pairs(o) do
		if not validFields[key] then
			o[key] = nil
		end
	end
end

---@generic T : table
---@param classTable T
---@param o table|nil
---@return T
local function CreateNewInstance(classTable, o)
	o = o or {}
	for key, value in pairs(Private.DeepCopy(classTable)) do
		if o[key] == nil then
			o[key] = value
		end
	end
	setmetatable(o, classTable)
	return o
end

---@return Assignment
function Private.classes.Assignment:New(o)
	local instance = CreateNewInstance(self, o)
	assignmentIDCounter = assignmentIDCounter + 1
	instance.uniqueID = assignmentIDCounter
	return instance
end

---@return CombatLogEventAssignment
function Private.classes.CombatLogEventAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	return CreateNewInstance(self, o)
end

---@return TimedAssignment
function Private.classes.TimedAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	return CreateNewInstance(self, o)
end

---@return PhasedAssignment
function Private.classes.PhasedAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	return CreateNewInstance(self, o)
end

-- Creates a timeline assignment from an assignment.
---@param assignment Assignment
---@return TimelineAssignment
function Private.classes.TimelineAssignment:New(assignment)
	assignment = assignment or Private.classes.Assignment:New(assignment)
	local timelineAssignment = {
		assignment = assignment,
		startTime = 0,
		order = 0,
	}
	setmetatable(timelineAssignment, self)
	return timelineAssignment
end

---@return RaidInstance
function Private.classes.RaidInstance:New(o)
	return CreateNewInstance(self, o)
end

---@return BossDefinition
function Private.classes.BossDefinition:New(o)
	return CreateNewInstance(self, o)
end

---@return Boss
function Private.classes.Boss:New(o)
	return CreateNewInstance(self, o)
end

---@return BossAbility
function Private.classes.BossAbility:New(o)
	return CreateNewInstance(self, o)
end

---@return BossAbilityPhase
function Private.classes.BossAbilityPhase:New(o)
	return CreateNewInstance(self, o)
end

---@return EventTrigger
function Private.classes.EventTrigger:New(o)
	return CreateNewInstance(self, o)
end

---@return BossPhase
function Private.classes.BossPhase:New(o)
	return CreateNewInstance(self, o)
end

---@return EncounterPlannerDbNote
function Private.classes.EncounterPlannerDbNote:New(o)
	return CreateNewInstance(self, o)
end

---@alias RaidGroupRole
---| "role:damager"
---| "role:healer"
---| "role:tank"
---| ""

local defaults = {
	--[[@class EncounterPlannerOptions]]
	---@field activeBossAbilities table<string, table<integer, boolean>>
	---@field assignmentSortType AssignmentSortType
	---@field notes table<string, EncounterPlannerDbNote>
	---@field sharedRoster table<string, EncounterPlannerDbRosterEntry>
	---@field lastOpenNote string
	profile = {
		activeBossAbilities = {},
		assignmentSortType = "First Appearance",
		notes = {},
		sharedRoster = {},
		lastOpenNote = "",
	},
}

Private.addOn = AceAddon:NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0")
Private.addOn.defaults = defaults
Private.addOn.optionsModule = Private.addOn:NewModule("Options", "AceConsole-3.0") --[[@as OptionsModule]]
Private.interfaceUpdater = {}
Private.bosses = {} --[[@as table<string, Boss>]]
Private.bossUtilities = {}
Private.utilities = {}
Private.mainFrame = nil --[[@as EPMainFrame]]
-- A map of class names to class pascal case colored class names with spaces if needed
Private.prettyClassNames = {} --[[@as table<string, string>]]
Private.assignmentEditor = nil --[[@as EPAssignmentEditor]]
Private.rosterEditor = nil --[[@as EPRosterEditor]]
Private.importEditBox = nil --[[@as EPEditBox]]
Private.exportEditBox = nil --[[@as EPEditBox]]

LSM:Register(
	"font",
	"PT Sans Narrow",
	"Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
	bit.bor(LSM.LOCALE_BIT_western, LSM.LOCALE_BIT_ruRU)
)

---@class EncounterPlanner
EncounterPlanner = {}

EncounterPlanner.tooltip = CreateFrame("GameTooltip", "EncounterPlannerTooltip", UIParent, "GameTooltipTemplate")
EncounterPlanner.tooltipUpdateTime = 0.2
EncounterPlanner.tooltip.updateTooltipTimer = EncounterPlanner.tooltipUpdateTime
