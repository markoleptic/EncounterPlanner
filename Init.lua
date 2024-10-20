---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

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
	Private.combatLogEventBasedTimers = {} --[[@as CombatLogEventBasedTimers]]
	Private.absoluteTimeBasedTimers = {} --[[@as table<integer, table<number, table<integer, AbsoluteTimeBasedTimer>>>]]
	Private.phaseBasedTimers = {}
	Private.customTimers = {}
	Private.lastEncounterId = nil
	Private.selectedBoss = nil
end

---@class EncounterPlanner
EncounterPlanner = {}

---@alias GameTooltipTemplate GameTooltip
