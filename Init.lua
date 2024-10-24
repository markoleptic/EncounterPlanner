---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

---@class Assignment
Private.Assignment = {}
Private.Assignment.__index = Private.Assignment

---@return Assignment
function Private.Assignment:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

---@class CombatLogEventAssignment
Private.CombatLogEventAssignment = setmetatable({}, { __index = Private.Assignment })
Private.CombatLogEventAssignment.__index = Private.CombatLogEventAssignment

---@return CombatLogEventAssignment
function Private.CombatLogEventAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@class TimedAssignment
Private.TimedAssignment = setmetatable({}, { __index = Private.Assignment })
Private.TimedAssignment.__index = Private.TimedAssignment

---@return TimedAssignment
function Private.TimedAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@class PhasedAssignment
Private.PhasedAssignment = setmetatable({}, { __index = Private.Assignment })
Private.PhasedAssignment.__index = Private.PhasedAssignment

---@return PhasedAssignment
function Private.PhasedAssignment:new(o)
	o = o or Private.Assignment:new(o)
	setmetatable(o, self)
	return o
end

---@class TimelineAssignment
Private.TimelineAssignment = {}
Private.TimelineAssignment = setmetatable({}, { __index = Private.TimelineAssignment })
Private.TimelineAssignment.__index = Private.TimelineAssignment

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
