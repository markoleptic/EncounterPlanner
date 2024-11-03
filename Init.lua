---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

local CreateFrame = CreateFrame
local LibStub = LibStub
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
---| "Role"

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
---@field offset number TODO Get rid of
---@field order number When sorted by first appearance, this number signifies the order relative to other assignments. This number is the same across assignments with the same assignee.
Private.classes.TimelineAssignment = setmetatable({
	assignment = nil,
	startTime = nil,
	offset = nil,
	order = nil,
}, { __index = Private.classes.TimelineAssignment })
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
---@field repeatCriteria {castOccurance: number, castTimes: table<number>}|nil Describes criteria for repeating casts
Private.classes.EventTrigger = {
	combatLogEventType = "SCS",
	castTimes = {},
	repeatCriteria = nil,
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

---@return Assignment
function Private.classes.Assignment:new(o)
	o = o or {}
	setmetatable(o, self)
	if not o.uniqueID then
		assignmentIDCounter = assignmentIDCounter + 1
		o.uniqueID = assignmentIDCounter
	end
	return o
end

---@return CombatLogEventAssignment
function Private.classes.CombatLogEventAssignment:new(o)
	o = o or Private.classes.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return TimedAssignment
function Private.classes.TimedAssignment:new(o)
	o = o or Private.classes.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return PhasedAssignment
function Private.classes.PhasedAssignment:new(o)
	o = o or Private.classes.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return TimelineAssignment
function Private.classes.TimelineAssignment:new(o)
	o = o or Private.classes.TimelineAssignment:new(o)
	setmetatable(o, self)
	return o
end

---@return RaidInstance
function Private.classes.RaidInstance:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossDefinition
function Private.classes.BossDefinition:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return Boss
function Private.classes.Boss:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossAbility
function Private.classes.BossAbility:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossAbilityPhase
function Private.classes.BossAbilityPhase:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return EventTrigger
function Private.classes.EventTrigger:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return BossPhase
function Private.classes.BossPhase:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

--- Copies a table
---@generic T
---@param inTable table<any, T> A table with any keys and values of type T
---@return table<any, T>
function Private:DeepCopy(inTable)
	local copy = {}
	if type(inTable) == "table" then
		for k, v in pairs(inTable) do
			copy[k] = self:DeepCopy(v)
		end
	else
		copy = inTable
	end
	return copy
end

do
	Private.AddOn = LibStub("AceAddon-3.0"):NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0")
	Private.AddOn.Defaults = { profile = {} }
	Private.AddOn.OptionsModule = Private.AddOn:NewModule("Options", "AceConsole-3.0") --[[@as OptionsModule]]
	Private.Libs = {}
	Private.Libs.ACD = LibStub("AceConfigDialog-3.0")
	Private.Libs.AC = LibStub("AceConfig-3.0")
	Private.Libs.ACR = LibStub("AceConfigRegistry-3.0")
	Private.Libs.ADBO = LibStub("AceDBOptions-3.0")
	Private.Libs.LSM = LibStub("LibSharedMedia-3.0")
	Private.Libs.LSM:Register(
		"font",
		"PT Sans Narrow",
		"Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
		bit.bor(Private.Libs.LSM.LOCALE_BIT_western, Private.Libs.LSM.LOCALE_BIT_ruRU)
	)
	Private.Libs.AGUI = LibStub("AceGUI-3.0")
	Private.assignments = {} --[[@as table<integer, Assignment>]]
	Private.roster = {} --[[@as table<string, string>]]
	Private.lastEncounterId = nil
	Private.selectedBoss = nil
	Private.mainFrame = nil --[[@as EPMainFrame]]
	Private.prettyClassNames = {} --[[@as table<string, string>]]
	Private.assignmentEditor = nil --[[@as EPAssignmentEditor]]
end

---@class EncounterPlanner
EncounterPlanner = {}

---@alias GameTooltipTemplate GameTooltip

EncounterPlanner.tooltip = CreateFrame("GameTooltip", "EncounterPlannerTooltip", UIParent, "GameTooltipTemplate")
EncounterPlanner.tooltipUpdateTime = 0.2
EncounterPlanner.tooltip.updateTooltipTimer = EncounterPlanner.tooltipUpdateTime

-- local function HandleTooltipOnUpdate(frame, elapsed)
-- 	frame.updateTooltipTimer = frame.updateTooltipTimer - elapsed
-- 	if frame.updateTooltipTimer > 0 then
-- 		return
-- 	end
-- 	frame.updateTooltipTimer = EncounterPlanner.tooltipUpdateTime
-- 	local owner = frame:GetOwner()
-- 	if owner and frame.spellID then
-- 		frame:SetSpellByID(frame.spellID)
-- 	end
-- end

-- local function HandleIconEnter(frame, motion, anchorFrame, anchor, xOffset, yOffset)
-- 	if frame.spellID and frame.spellID ~= 0 then
-- 		EncounterPlanner.tooltip:ClearLines()
-- 		EncounterPlanner.tooltip:SetOwner(anchorFrame, anchor, xOffset or xOffset() or 0, yOffset or yOffset() or 0)
-- 		EncounterPlanner.tooltip:SetSpellByID(frame.spellID)
-- 		EncounterPlanner.tooltip:SetScript("OnUpdate", HandleTooltipOnUpdate)
-- 	end
-- end

-- local function HandleIconLeave(frame, motion)
-- 	EncounterPlanner.tooltip:SetScript("OnUpdate", nil)
-- 	EncounterPlanner.tooltip:Hide()
-- end

-- function EncounterPlanner:BindFrameEnterAndLeaveToTooltip(frame, anchorFrame, anchor, xOffset, yOffset)
-- 	frame:SetScript("OnEnter", function(f, motion) HandleIconEnter(f, motion, anchorFrame, anchor, xOffset, yOffset) end)
-- 	frame:SetScript("OnLeave", function(f, motion) HandleIconLeave(f, motion) end)
-- end
