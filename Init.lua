local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

local LibStub = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local concat = table.concat
local CreateFrame = CreateFrame
local GetTime = GetTime
local band = bit.band
local setmetatable = setmetatable
local pairs = pairs
local random = math.random
local type = type
local format = string.format
local rshift = bit.rshift

Private.L = LibStub("AceLocale-3.0"):GetLocale(AddOnName)

local byteToBase64 = {
	[0] = "a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"(",
	")",
}

---@param num number
---@param length integer
---@return string
local function ToBase64(num, length)
	local result = {}
	for i = 1, length do
		result[i] = byteToBase64[band(num, 63)] -- Last 6 bits
		num = rshift(num, 6)
	end
	return concat(result)
end

Private.version = C_AddOns.GetAddOnMetadata(AddOnName, "Version")

local function GenerateUniqueID()
	local timePart = ToBase64(GetTime() * 1000, 6)
	local randomPart1 = ToBase64(random(0, 0x7FFFFFFF), 6) -- 6 chars (from 32 bits)
	local randomPart2 = ToBase64(random(0, 0x7FFFFFFF), 6)
	return format("%s-%s-%s%s", Private.version, timePart, randomPart1, randomPart2)
end
Private.GenerateUniqueID = GenerateUniqueID

---@param str string
---@return number
local function Hash32(str)
	local hash = 5381
	for i = 1, #str do
		hash = (hash * 33 + str:byte(i)) % 4294967296
	end
	return hash
end

---@param assignmentKey string
---@return string
local function GenerateTransitionalID(assignmentKey)
	local hash1 = Hash32(assignmentKey)
	local hash2 = Hash32("salt2-" .. assignmentKey)

	local s1 = ToBase64(hash1, 6) -- 6 chars (from 32 bits)
	local s2 = ToBase64(hash2, 6)
	return "T-" .. s1 .. s2 -- ~64 bits effective
end
Private.GenerateTransitionalID = GenerateTransitionalID

Private.classes = {}

---@enum DifficultyType
Private.classes.DifficultyType = {
	Heroic = 15,
	Mythic = 16,
}

---@enum PlanDiffType
Private.classes.PlanDiffType = {
	Equal = 1,
	Insert = 2,
	Delete = 3,
	Change = 4,
}

---@enum TextImportType
Private.classes.TextImportType = {
	IntoCurrent = 1,
	OverwriteCurrent = 2,
	CreateNew = 3,
}

---@enum AssignmentEditorDataType
Private.classes.AssignmentEditorDataType = {
	AssignmentType = 1,
	CombatLogEventSpellID = 2,
	CombatLogEventSpellCount = 3,
	SpellAssignment = 4,
	AssigneeType = 5,
	Time = 6,
	OptionalText = 7,
	Target = 8,
	CountdownLength = 9,
	CancelIfAlreadyCasted = 10,
	HoldDuration = 11,
}

---@class DungeonInstance
Private.classes.DungeonInstance = {
	name = "",
	journalInstanceID = 0,
	instanceID = 0,
	bosses = {},
	icon = 0,
}

---@class Boss
Private.classes.Boss = {
	name = "",
	bossIDs = {},
	journalEncounterCreatureIDsToBossIDs = {},
	bossNames = {},
	journalEncounterID = 0,
	dungeonEncounterID = 0,
	instanceID = 0,
	sortedAbilityIDs = {},
	abilityInstances = {},
	icon = 0,
}

---@class BossPhase
Private.classes.BossPhase = {
	duration = 0.0,
	defaultDuration = 0.0,
	count = 1,
	defaultCount = 1,
}

---@class BossAbility
Private.classes.BossAbility = {
	phases = {},
	duration = 0.0,
	castTime = 0.0,
	allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
}

---@class BossAbilityPhase
Private.classes.BossAbilityPhase = {
	castTimes = {},
}

---@class EventTrigger
Private.classes.EventTrigger = {
	castTimes = {},
	combatLogEventType = "SCS",
}

---@class BossAbilityInstance
Private.classes.BossAbilityInstance = {
	bossAbilitySpellID = 0,
	bossAbilityInstanceIndex = 0,
	bossAbilityOrderIndex = 0,
	bossPhaseIndex = 0,
	bossPhaseOrderIndex = 0,
	bossPhaseDuration = 0.0,
	spellCount = 0,
	castStart = 0.0,
	castEnd = 0.0,
	effectEnd = 0.0,
	frameLevel = 0,
}

---@class RosterEntry
Private.classes.RosterEntry = {
	class = "",
	role = "",
	classColoredName = "",
}

---@class Plan
Private.classes.Plan = {
	ID = "",
	isPrimaryPlan = false,
	name = "",
	dungeonEncounterID = 0,
	instanceID = 0,
	difficulty = Private.classes.DifficultyType.Mythic,
	content = {},
	assignments = {},
	roster = {},
	assigneeSpellSets = {},
	collapsed = {},
	customPhaseDurations = {},
	customPhaseCounts = {},
	remindersEnabled = true,
}

--- Copies a table
---@generic T
---@param inTable T A table with any keys and values of type T
---@return T
function Private.DeepCopy(inTable)
	local copy = {}
	if type(inTable) == "table" then
		for k, v in pairs(inTable) do
			if k ~= "__index" and k ~= "New" then
				copy[k] = Private.DeepCopy(v)
			end
		end
	else
		copy = inTable
	end
	return copy
end

-- Creates a new instance of a table, copying fields that don't exist in the destination table.
---@generic T : table
---@param classTable T
---@param o table|nil
---@return T
function Private.CreateNewInstance(classTable, o)
	o = o or {}
	for key, value in pairs(Private.DeepCopy(classTable)) do
		if o[key] == nil then
			o[key] = value
		end
	end
	setmetatable(o, classTable)
	return o
end

---@param o any
---@return DungeonInstance
function Private.classes.DungeonInstance:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@return Boss
function Private.classes.Boss:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@return BossAbility
function Private.classes.BossAbility:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@return BossAbilityPhase
function Private.classes.BossAbilityPhase:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@return EventTrigger
function Private.classes.EventTrigger:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@return BossPhase
function Private.classes.BossPhase:New(o)
	return Private.CreateNewInstance(self, o)
end

---@param o any
---@param name string
---@param existingID string|nil
---@return Plan
function Private.classes.Plan:New(o, name, existingID)
	local instance = Private.CreateNewInstance(self, o)
	instance.name = name
	if existingID then
		instance.ID = existingID
	else
		instance.ID = GenerateUniqueID()
	end
	return instance
end

---@param o any
---@return RosterEntry
function Private.classes.RosterEntry:New(o)
	return Private.CreateNewInstance(self, o)
end

local playerClass = select(2, UnitClass("player"))
local ccA, ccR, ccB, _ = GetClassColor(playerClass)

---@class Defaults
local defaults = {
	profile = {
		activeBossAbilities = {},
		activeBossAbilitiesHeroic = {},
		plans = {},
		templates = {},
		sharedRoster = {},
		lastOpenPlan = "",
		recentSpellAssignments = {},
		favoritedSpellAssignments = {},
		trustedCharacters = {},
		cooldownAndChargeOverrides = {},
		activeText = {},
		createdDefaults = {},
		preferences = {
			lastOpenTab = Private.L["Cooldown Overrides"],
			keyBindings = {
				pan = "RightButton",
				zoom = "Ctrl-MouseScroll",
				scroll = "MouseScroll",
				editAssignment = "LeftButton",
				newAssignment = "LeftButton",
				duplicateAssignment = "Ctrl-LeftButton",
			},
			assignmentSortType = "First Appearance",
			timelineRows = {
				numberOfAssignmentsToShow = 8,
				numberOfBossAbilitiesToShow = 8,
				assignmentHeight = 30.0,
				bossAbilityHeight = 30.0,
				onlyShowMe = false,
			},
			zoomCenteredOnCursor = true,
			showSpellCooldownDuration = true,
			minimap = {
				show = true,
			},
			reminder = {
				enabled = true,
				onlyShowMe = true,
				cancelIfAlreadyCasted = true,
				removeDueToPhaseChange = false,
				countdownLength = 10.0,
				glowTargetFrame = true,
				messages = {
					enabled = true,
					font = Private.constants.kDefaultFont,
					fontSize = 24,
					fontOutline = "",
					point = "BOTTOM",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = 0,
					y = 385,
					alpha = 1.0,
					soonestExpirationOnBottom = true,
					showOnlyAtExpiration = true,
					textColor = { 1, 0.82, 0, 0.95 },
					showIcon = true,
					holdDuration = 2.0,
				},
				progressBars = {
					enabled = true,
					font = Private.constants.kDefaultFont,
					fontSize = 16,
					fontOutline = "",
					point = "BOTTOMRIGHT",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = -200,
					y = 0,
					alpha = 0.90,
					soonestExpirationOnBottom = true,
					texture = Private.constants.textures.kStatusBarClean,
					iconPosition = "LEFT",
					height = 24,
					width = 200,
					durationAlignment = "RIGHT",
					fill = false,
					showBorder = false,
					showIconBorder = false,
					color = { ccA, ccR, ccB, 0.90 },
					backgroundColor = { 10.0 / 255.0, 10.0 / 255.0, 10.0 / 255.0, 0.25 },
					spacing = 0,
					shrinkTextToFit = true,
				},
				icons = {
					enabled = true,
					font = Private.constants.kDefaultFont,
					fontSize = 12,
					fontOutline = "",
					point = "TOPLEFT",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = -400,
					y = -10,
					alpha = 0.90,
					soonestExpirationOnBottom = true,
					height = 50,
					width = 50,
					drawSwipe = true,
					drawEdge = false,
					showText = false,
					shrinkTextToFit = true,
					textColor = { 1, 0.82, 0, 0.95 },
					borderSize = 2,
					spacing = 2,
					orientation = "horizontal",
				},
				textToSpeech = {
					enableAtCountdownStart = false,
					enableAtCountdownEnd = false,
					voiceID = 0,
					volume = 100,
				},
				sound = {
					countdownStartSound = "",
					countdownEndSound = "",
					enableAtCountdownStart = false,
					enableAtCountdownEnd = false,
				},
			},
		},
		version = "",
	},
	global = {
		tutorial = {
			completed = false,
			lastStepName = "",
			skipped = false,
			revision = 1,
			firstSpell = -1,
			secondSpell = -1,
		},
	},
}

do
	local currentPlaceholderBossSpellIDIndex = -1
	local placeholderBossSpellIDs = {} ---@type table<integer, {placeholderID: integer, placeholderName: string}>

	---@param actualSpellID integer
	---@param placeholderName string
	---@return integer placeholderBossSpellID
	function Private:RegisterPlaceholderBossSpellID(actualSpellID, placeholderName)
		if not placeholderBossSpellIDs[actualSpellID] then
			placeholderBossSpellIDs[actualSpellID] = {
				placeholderID = currentPlaceholderBossSpellIDIndex,
				placeholderName = placeholderName,
			}
			currentPlaceholderBossSpellIDIndex = currentPlaceholderBossSpellIDIndex - 1
		end
		return placeholderBossSpellIDs[actualSpellID].placeholderID
	end

	---@param actualSpellID integer
	---@return boolean
	function Private:HasPlaceholderBossSpellID(actualSpellID)
		return placeholderBossSpellIDs[actualSpellID] ~= nil
	end

	---@param actualSpellID integer
	---@return string|nil placeholderName
	function Private:GetPlaceholderBossName(actualSpellID)
		if placeholderBossSpellIDs[actualSpellID] then
			return placeholderBossSpellIDs[actualSpellID].placeholderName
		end
	end
end

Private.addOn = AceAddon:NewAddon(AddOnName, "AceConsole-3.0", "AceComm-3.0")
Private.addOn.defaults = defaults
Private.addOn.db = nil ---@type Defaults
Private.addOn.optionsModule = Private.addOn:NewModule("Options") --[[@as OptionsModule]]
Private.callbacks = LibStub("CallbackHandler-1.0"):New(Private)

do
	local eventMap = {}
	local eventFrame = CreateFrame("Frame")

	eventFrame:SetScript("OnEvent", function(_, event, ...)
		for k, v in pairs(eventMap[event]) do
			if type(v) == "function" then
				v(event, ...)
			else
				k[v](k, event, ...)
			end
		end
	end)

	---@param event string
	---@param func fun()|string
	function Private:RegisterEvent(event, func)
		if type(event) == "string" then
			eventMap[event] = eventMap[event] or {}
			eventMap[event][self] = func or event
			eventFrame:RegisterEvent(event)
		end
	end

	---@param event string
	function Private:UnregisterEvent(event)
		if type(event) == "string" then
			if eventMap[event] then
				eventMap[event][self] = nil
				if not next(eventMap[event]) then
					eventFrame:UnregisterEvent(event)
					eventMap[event] = nil
				end
			end
		end
	end

	function Private:UnregisterAllEvents()
		for k, v in pairs(eventMap) do
			for _, j in pairs(v) do
				j:UnregisterEvent(k)
			end
		end
	end
end

Private.dungeonInstances = {} ---@type table<integer, DungeonInstance>
---@type table<string, CustomDungeonInstanceGroup>
Private.customDungeonInstanceGroups = {
	["TheWarWithinSeasonThree"] = {
		instanceIDToUseForIcon = 2810,
		instanceName = Private.L["TWW Season 3"],
		order = 0,
	},
	["TheWarWithinSeasonTwo"] = {
		instanceIDToUseForIcon = 2769,
		instanceName = Private.L["TWW Season 2"],
		order = 1,
	},
}

Private.interfaceUpdater = {} ---@type InterfaceUpdater
Private.bossUtilities = {} ---@type BossUtilities
Private.utilities = {} ---@type Utilities
Private.assignmentUtilities = {} ---@type AssignmentUtilities
Private.timeline = {
	constants = nil, ---@type EPTimelineConstants
	state = nil, ---@type EPTimelineState
	utilities = {}, ---@type EPTimelineUtilities
	bossAbility = {}, ---@type EPTimelineBossAbility
	assignment = {}, ---@type EPTimelineAssignment
}
Private.mainFrame = nil ---@type EPMainFrame
Private.assignmentEditor = nil ---@type EPAssignmentEditor
Private.rosterEditor = nil ---@type EPRosterEditor
Private.importEditBox = nil ---@type EPEditBox
Private.exportEditBox = nil ---@type EPEditBox
Private.optionsMenu = nil ---@type EPOptions
Private.phaseLengthEditor = nil ---@type EPPhaseLengthEditor
Private.newPlanDialog = nil ---@type EPNewPlanDialog
Private.newTemplateDialog = nil ---@type EPNewTemplateDialog
Private.patchNotesDialog = nil ---@type EPEditBox
Private.externalTextEditor = nil ---@type EPEditBox
Private.tutorial = nil ---@type EPTutorial
Private.tutorialCallbackObject = nil ---@type table|nil
Private.activeTutorialCallbackName = nil ---@type string|nil

Private.tooltip = CreateFrame("GameTooltip", "EncounterPlannerTooltip", UIParent, "GameTooltipTemplate")

-- Use font early so that it is available when InitializeInterface is called
local fontInitializer = Private.tooltip:CreateFontString(nil, "OVERLAY")
local obj = CreateFont("EPFontInitializerObject")
local fontPath = Private.constants.kDefaultFont
obj:SetFont(fontPath, 16, "")
fontInitializer:SetFontObject(obj)
fontInitializer:Hide()
fontInitializer:SetParent(UIParent)
LSM:Register("font", "PT Sans Narrow", fontPath, bit.bor(LSM.LOCALE_BIT_western, LSM.LOCALE_BIT_ruRU))

--@debug@
Private.testReferences = {}
--@end-debug@
