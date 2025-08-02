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
local getmetatable, setmetatable = getmetatable, setmetatable
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
		num = rshift(num, length)
	end
	return concat(result)
end

local version = C_AddOns.GetAddOnMetadata(AddOnName, "Version")

local function GenerateUniqueID()
	local timePart = ToBase64(GetTime() * 1000, 6)
	local randomPart1 = ToBase64(random(0, 0xFFFFFFF), 5) -- 5 chars = 30 bits
	local randomPart2 = ToBase64(random(0, 0xFFFFFFF), 5)
	return format("%s-%s-%s%s", version, timePart, randomPart1, randomPart2)
end

Private.GenerateUniqueID = GenerateUniqueID

Private.classes = {}

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

---@class PhasedAssignment
Private.classes.PhasedAssignment = setmetatable({
	phase = 1,
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.PhasedAssignment.__index = Private.classes.PhasedAssignment

---@class TimelineAssignment
Private.classes.TimelineAssignment = {
	startTime = 0.0,
	order = 0,
	cooldownDuration = 0.0,
	maxCharges = 1,
	effectiveCooldownDuration = 0.0,
}
Private.classes.TimelineAssignment.__index = Private.classes.TimelineAssignment

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
	phases = {},
	abilities = {},
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
	content = {},
	assignments = {},
	roster = {},
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

-- Creates a new instance of a table, copying fields that don't exist in the destination table.
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

local assignmentIDCounter = 0

---@param o any
---@return Assignment
function Private.classes.Assignment:New(o)
	local instance = CreateNewInstance(self, o)
	assignmentIDCounter = assignmentIDCounter + 1
	instance.uniqueID = assignmentIDCounter
	return instance
end

---@param o any
---@param removeInvalidFields boolean|nil
---@return CombatLogEventAssignment
function Private.classes.CombatLogEventAssignment:New(o, removeInvalidFields)
	o = o or Private.classes.Assignment:New(o)
	local instance = CreateNewInstance(self, o)
	if removeInvalidFields then
		RemoveInvalidFields(self, instance)
	end
	return instance
end

---@param o any
---@param removeInvalidFields boolean|nil
---@return TimedAssignment
function Private.classes.TimedAssignment:New(o, removeInvalidFields)
	o = o or Private.classes.Assignment:New(o)
	local instance = CreateNewInstance(self, o)
	if removeInvalidFields then
		RemoveInvalidFields(self, instance)
	end
	return instance
end

---@param o any
---@param removeInvalidFields boolean|nil
---@return PhasedAssignment
function Private.classes.PhasedAssignment:New(o, removeInvalidFields)
	o = o or Private.classes.Assignment:New(o)
	local instance = CreateNewInstance(self, o)
	if removeInvalidFields then
		RemoveInvalidFields(self, instance)
	end
	return instance
end

-- Copies an assignment with a new uniqueID.
---@param assignmentToCopy Assignment
---@return Assignment
function Private.DuplicateAssignment(assignmentToCopy)
	local newAssignment = Private.classes.Assignment:New()
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
---@return TimelineAssignment
function Private.classes.TimelineAssignment:New(assignment, o)
	local instance = CreateNewInstance(self, o)
	instance.assignment = assignment or Private.classes.Assignment:New(assignment)
	return instance
end

-- Creates a timeline assignment from an assignment.
---@param timelineAssignmentToCopy TimelineAssignment
---@param o any
---@return TimelineAssignment
function Private.DuplicateTimelineAssignment(timelineAssignmentToCopy, o)
	o = o or {}
	for key, value in pairs(Private.DeepCopy(timelineAssignmentToCopy)) do
		if key ~= "assignment" then
			o[key] = value
		end
	end
	o.assignment = Private.DuplicateAssignment(timelineAssignmentToCopy.assignment)
	setmetatable(o, getmetatable(timelineAssignmentToCopy))
	return o
end

---@param o any
---@return DungeonInstance
function Private.classes.DungeonInstance:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@return Boss
function Private.classes.Boss:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@return BossAbility
function Private.classes.BossAbility:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@return BossAbilityPhase
function Private.classes.BossAbilityPhase:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@return EventTrigger
function Private.classes.EventTrigger:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@return BossPhase
function Private.classes.BossPhase:New(o)
	return CreateNewInstance(self, o)
end

---@param o any
---@param name string
---@param existingID string|nil
---@return Plan
function Private.classes.Plan:New(o, name, existingID)
	local instance = CreateNewInstance(self, o)
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
	return CreateNewInstance(self, o)
end

local playerClass = select(2, UnitClass("player"))
local ccA, ccR, ccB, _ = GetClassColor(playerClass)

---@class Defaults
local defaults = {
	profile = {
		activeBossAbilities = {},
		plans = {},
		sharedRoster = {},
		lastOpenPlan = "",
		recentSpellAssignments = {},
		favoritedSpellAssignments = {},
		trustedCharacters = {},
		cooldownAndChargeOverrides = {},
		activeText = {},
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
					font = "Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
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
				},
				progressBars = {
					enabled = true,
					font = "Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
					fontSize = 16,
					fontOutline = "",
					point = "BOTTOMRIGHT",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = -200,
					y = 0,
					alpha = 0.90,
					soonestExpirationOnBottom = true,
					texture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Statusbar_Clean",
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
					font = "Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
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
} --@type table<string, CustomDungeonInstanceGroup>
Private.interfaceUpdater = {}
Private.bossUtilities = {}
Private.utilities = {}

Private.mainFrame = nil --[[@as EPMainFrame]]
Private.assignmentEditor = nil --[[@as EPAssignmentEditor]]
Private.rosterEditor = nil --[[@as EPRosterEditor]]
Private.importEditBox = nil --[[@as EPEditBox]]
Private.exportEditBox = nil --[[@as EPEditBox]]
Private.optionsMenu = nil --[[@as EPOptions]]
Private.phaseLengthEditor = nil --[[@as EPPhaseLengthEditor]]
Private.newPlanDialog = nil --[[@as EPNewPlanDialog]]
Private.externalTextEditor = nil --[[@as EPEditBox]]
Private.tutorial = nil --[[@as EPTutorial]]
Private.tutorialCallbackObject = nil ---@type table|nil
Private.activeTutorialCallbackName = nil ---@type string|nil

Private.tooltip = CreateFrame("GameTooltip", "EncounterPlannerTooltip", UIParent, "GameTooltipTemplate")

-- Use font early so that it is available when InitializeInterface is called
local fontInitializer = Private.tooltip:CreateFontString(nil, "OVERLAY")
local obj = CreateFont("EPFontInitializerObject")
local fontPath = [[Interface\Addons\EncounterPlanner\Media\Fonts\PTSansNarrow-Bold.ttf]]
obj:SetFont(fontPath, 16, "")
fontInitializer:SetFontObject(obj)
fontInitializer:Hide()
fontInitializer:SetParent(UIParent)

LSM:Register("font", "PT Sans Narrow", fontPath, bit.bor(LSM.LOCALE_BIT_western, LSM.LOCALE_BIT_ruRU))

--@debug@
Private.test = {}
--@end-debug@
