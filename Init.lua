---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...)

do
	Private.AddOn = LibStub("AceAddon-3.0"):NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0")
	Private.AddOn.OptionsModule = Private.AddOn:NewModule("Options", "AceConsole-3.0")
	Private.Libs = {}
	Private.Libs.ACD = LibStub("AceConfigDialog-3.0")
	Private.Libs.AC = LibStub("AceConfig-3.0");
	Private.Libs.ACR = LibStub("AceConfigRegistry-3.0")
	Private.Libs.ADBO = LibStub("AceDBOptions-3.0")
	Private.Libs.LSM = LibStub("LibSharedMedia-3.0")
	Private.Libs.AGUI = LibStub("AceGUI-3.0")
	Private.phaseBasedTimers = {}
	Private.absoluteTimeBasedTimers = {}
	Private.customTimers = {}
	Private.lastEncounterId = nil
	Private.selectedBoss = nil
end

---@class EncounterPlanner
EncounterPlanner = {}

---@alias GameTooltipTemplate GameTooltip
