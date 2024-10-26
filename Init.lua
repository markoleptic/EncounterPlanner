---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

---@alias CombatLogEventType = {
---| "SCC" SPELL_CAST_SUCCESS
---| "SCS" SPELL_CAST_START
---| "SAA" SPELL_AURA_APPLIED
---| "SAR" SPELL_AURA_REMOVED

---@class Assignment
---@field assigneeNameOrRole string Who to assign the assignment to
---@field line string Originally parsed line in the form: {assigneeNameOrRole} {options}
---@field text string The originally parsed portion of the assignment containing a {text}{/text} block
---@field textWithIconReplacements string Text with icons formatted back in
---@field strWithIconReplacements string Line with icons formatted back in, similar to how it appears in the note
---@field spellInfo { spellID: integer, name: string, iconID: integer } The spell info for the assignment
---@field targetName string|nil The target's name if the assignment has a '@'
Private.Assignment = {
	assigneeNameOrRole = "",
	line = "",
	text = "",
	textWithIconReplacements = "",
	strWithIconReplacements = "",
	spellInfo = { spellID = 0, name = "", iconID = 0 },
	targetName = "",
}
Private.Assignment.__index = Private.Assignment

---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType|nil The type of combat log even the assignment is triggered by
---@field combatLogEventSpellID integer|nil The spell for the event
---@field phase number|nil The phase the combat log event must occur in
---@field spellCount integer|nil The number of times the combat log event must have occurred
---@field time number|nil The time from the combat log event to trigger the assignment
Private.CombatLogEventAssignment = setmetatable({
	combatLogEventType    = nil,
	combatLogEventSpellID = nil,
	phase                 = nil,
	spellCount            = nil,
	time                  = nil,
}, { __index = Private.Assignment })
Private.CombatLogEventAssignment.__index = Private.CombatLogEventAssignment

---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered
Private.TimedAssignment = setmetatable({
	time = nil,
}, { __index = Private.Assignment })
Private.TimedAssignment.__index = Private.TimedAssignment

---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by
---@field time number The time from the start of the phase to trigger the assignment
Private.PhasedAssignment = setmetatable({
	phase = nil,
	time = nil,
}, { __index = Private.Assignment })
Private.PhasedAssignment.__index = Private.PhasedAssignment

---@class TimelineAssignment
---@field assignment Assignment The assignment
---@field startTime number Time used to place the assignment on the timeline
---@field offset number TODO Get rid of
---@field order number When sorted by first appearance, this number signifies the order relative to other assignments. This number is the same across assignments with the same assignee.
Private.TimelineAssignment = setmetatable({
	assignment = nil,
	startTime = nil,
	offset = nil,
	order = nil,
}, { __index = Private.TimelineAssignment })
Private.TimelineAssignment.__index = Private.TimelineAssignment

---@return Assignment
function Private.Assignment:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@return CombatLogEventAssignment
function Private.CombatLogEventAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return TimedAssignment
function Private.TimedAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return PhasedAssignment
function Private.PhasedAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@return TimelineAssignment
function Private.TimelineAssignment:new(o)
	o = o or Private.TimelineAssignment:new(o)
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
	Private.AddOn.OptionsModule = Private.AddOn:NewModule("Options", "AceConsole-3.0") --[[@as OptionsModule]]
	Private.Libs = {}
	Private.Libs.ACD = LibStub("AceConfigDialog-3.0")
	Private.Libs.AC = LibStub("AceConfig-3.0");
	Private.Libs.ACR = LibStub("AceConfigRegistry-3.0")
	Private.Libs.ADBO = LibStub("AceDBOptions-3.0")
	Private.Libs.LSM = LibStub("LibSharedMedia-3.0")
	Private.Libs.LSM:Register("font", "PT Sans Narrow",
		"Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
		bit.bor(Private.Libs.LSM.LOCALE_BIT_western, Private.Libs.LSM.LOCALE_BIT_ruRU))
	Private.Libs.AGUI = LibStub("AceGUI-3.0")
	Private.assignments = {} --[[@as table<integer, Assignment>]]
	Private.lastEncounterId = nil
	Private.selectedBoss = nil
end

---@class EncounterPlanner
EncounterPlanner = {}

---@alias GameTooltipTemplate GameTooltip
