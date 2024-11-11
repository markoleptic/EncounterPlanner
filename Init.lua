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
	uniqueID = nil,
}
Private.classes.Assignment.__index = Private.classes.Assignment

---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType|nil The type of combat log even the assignment is triggered by
---@field combatLogEventSpellID integer|nil The spell for the event
---@field phase number|nil The phase the combat log event must occur in
---@field spellCount integer|nil The number of times the combat log event must have occurred
---@field time number|nil The time from the combat log event to trigger the assignment
Private.classes.CombatLogEventAssignment = setmetatable({
	combatLogEventType = nil,
	combatLogEventSpellID = nil,
	phase = nil,
	spellCount = nil,
	time = nil,
}, { __index = Private.classes.Assignment })
Private.classes.CombatLogEventAssignment.__index = Private.classes.CombatLogEventAssignment

---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered
Private.classes.TimedAssignment = setmetatable({
	time = nil,
}, { __index = Private.classes.Assignment })
Private.classes.TimedAssignment.__index = Private.classes.TimedAssignment

---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by
---@field time number The time from the start of the phase to trigger the assignment
Private.classes.PhasedAssignment = setmetatable({
	phase = nil,
	time = nil,
}, { __index = Private.classes.Assignment })
Private.classes.PhasedAssignment.__index = Private.classes.PhasedAssignment

---@class TimelineAssignment
---@field assignment Assignment The assignment
---@field startTime number Time used to place the assignment on the timeline
---@field order number When sorted by first appearance, this number signifies the order relative to other assignments. This number is the same across assignments with the same assignee.
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
Private.classes.RaidInstance.__index = Private.classes.RaidInstance

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
Private.classes.BossDefinition.__index = Private.classes.BossDefinition

---@class Boss
---@field abilities table<integer, BossAbility> A list of abilities
---@field phases table<integer, BossPhase> A list of phases
---@field sortedAbilityIDs? table<integer, integer> An ordered list of abilities sorted by first appearance
Private.classes.Boss = {
	abilities = {},
	phases = {},
	sortedAbilityIDs = nil,
}
Private.classes.Boss.__index = Private.classes.Boss

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
Private.classes.BossAbility.__index = Private.classes.BossAbility

---@class BossAbilityPhase
---@field castTimes table<number> An ordered list of cast times, where the actual cast time is the running sum
---@field repeatInterval number|nil If defined, the ability will repeat at this interval starting from the last cast time
Private.classes.BossAbilityPhase = {
	castTimes = {},
	repeatInterval = nil,
}
Private.classes.BossAbilityPhase.__index = Private.classes.BossAbilityPhase

---@class EventTrigger
---@field combatLogEventType CombatLogEventType The combat log event type that acts as a trigger
---@field castTimes table<number> An ordered list of cast times, where the actual cast time is the running sum
---@field repeatInterval {triggerCastIndex: number, castTimes: table<number>}|nil Describes criteria for repeating casts
Private.classes.EventTrigger = {
	combatLogEventType = "SCS",
	castTimes = {},
	repeatInterval = nil,
}
Private.classes.EventTrigger.__index = Private.classes.EventTrigger

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
Private.classes.BossPhase.__index = Private.classes.BossPhase

---@class BossAbilityInstance
---@field spellID number
---@field phase number
---@field castTime number|nil
---@field combatLogEventType CombatLogEventType|nil
---@field triggerSpellID number|nil
---@field triggerCastIndex number|nil
---@field repeatInstance number|nil
---@field repeatCastIndex number|nil
Private.classes.BossAbilityInstance = {
	spellID = 0,
	phase = 1,
	castTime = nil,
	combatLogEventType = nil,
	triggerSpellID = nil,
	triggerCastIndex = nil,
	repeatInstance = nil,
	repeatCastIndex = nil,
}
Private.classes.BossAbilityInstance.__index = Private.classes.BossAbilityInstance

--- Copies a table
---@generic T
---@param inTable table<any, T> A table with any keys and values of type T
---@return table<any, T>
function Private:DeepCopy(inTable)
	local copy = {}
	if type(inTable) == "table" then
		for k, v in pairs(inTable) do
			if k ~= "__index" then
				copy[k] = self:DeepCopy(v)
			end
		end
	else
		copy = inTable
	end
	return copy
end

---@return Assignment
function Private.classes.Assignment:New(o)
	o = o or {}
	assignmentIDCounter = assignmentIDCounter + 1
	o.uniqueID = assignmentIDCounter
	for key, value in pairs(Private:DeepCopy(self)) do
		if o[key] == nil then
			o[key] = value
		end
	end
	setmetatable(o, self)
	return o
end

---@return CombatLogEventAssignment
function Private.classes.CombatLogEventAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	setmetatable(o, self)
	return o
end

---@return TimedAssignment
function Private.classes.TimedAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	setmetatable(o, self)
	return o
end

---@return PhasedAssignment
function Private.classes.PhasedAssignment:New(o)
	o = o or Private.classes.Assignment:New(o)
	setmetatable(o, self)
	return o
end

---@return RaidInstance
function Private.classes.RaidInstance:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossDefinition
function Private.classes.BossDefinition:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return Boss
function Private.classes.Boss:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossAbility
function Private.classes.BossAbility:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossAbilityPhase
function Private.classes.BossAbilityPhase:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return EventTrigger
function Private.classes.EventTrigger:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossPhase
function Private.classes.BossPhase:New(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

local defaults = {
	--[[@class EncounterPlannerOptions]]
	---@field assignmentSortType AssignmentSortType
	---@field notes table
	---@field roster table
	---@field lastOpenNote string
	profile = {
		assignmentSortType = "First Appearance",
		notes = {},
		roster = {},
		lastOpenNote = "",
	},
}

Private.addOn = AceAddon:NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0")
Private.addOn.defaults = defaults
Private.addOn.optionsModule = Private.addOn:NewModule("Options", "AceConsole-3.0") --[[@as OptionsModule]]
Private.utilities = {}
-- The assignments for the currently selected note
Private.assignments = {} --[[@as table<integer, Assignment>]]
-- A map of plain text names (or group type) mapped to class colored names
Private.roster = {} --[[@as table<string, string>]]
Private.mainFrame = nil --[[@as EPMainFrame]]
-- A map of class names to class pascal case colored class names with spaces if needed
Private.prettyClassNames = {} --[[@as table<string, string>]]
Private.assignmentEditor = nil --[[@as EPAssignmentEditor]]
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
