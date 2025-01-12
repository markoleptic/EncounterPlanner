local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

local LibStub = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local concat = table.concat
local CreateFrame = CreateFrame
local getmetatable, setmetatable = getmetatable, setmetatable
local pairs = pairs
local random = math.random
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
---| "Spec"
---| "Type"

---@alias AssignmentSortType
---| "Alphabetical"
---| "First Appearance"
---| "Role > Alphabetical"
---| "Role > First Appearance"

---@alias SpellIDIndex
---| integer

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

local function GenerateUniqueID()
	local s = {}
	for i = 1, 16 do
		s[i] = byteToBase64[random(0, 63)]
	end
	return concat(s)
end

local assignmentIDCounter = 0

Private.classes = {}

-- Abstract base class for assignments.
---@class Assignment
---@field uniqueID integer Incremented each time a new assignment is created used to distinguish in-memory assignments.
---@field assigneeNameOrRole string Who to assign the assignment to, AssigneeType.
---@field text string Text to display for the assignment. If empty, the spell name is used.
---@field spellInfo SpellInfo The spell info for the assignment.
---@field targetName string|nil The target's name if the assignment has a '@'.
Private.classes.Assignment = {
	uniqueID = 0,
	assigneeNameOrRole = "",
	text = "",
	spellInfo = { name = "", iconID = 0, originalIconID = 0, castTime = 0, minRange = 0, maxRange = 0, spellID = 0 },
	targetName = "",
}

-- An assignment based on a combat log event.
---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType The type of combat log even the assignment is triggered by.
---@field combatLogEventSpellID integer The spell for the event.
---@field spellCount integer The number of times the combat log event must occur before the assignment is triggered.
---@field time number The time from the combat log event to trigger the assignment.
Private.classes.CombatLogEventAssignment = setmetatable({
	combatLogEventType = "SCS",
	combatLogEventSpellID = 0,
	spellCount = 1,
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.CombatLogEventAssignment.__index = Private.classes.CombatLogEventAssignment

-- An assignment based on time from the boss being pulled.
---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered.
Private.classes.TimedAssignment = setmetatable({
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.TimedAssignment.__index = Private.classes.TimedAssignment

-- An assignment dependent only upon a boss phase. Currently half-implemented.
---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by.
---@field time number The time from the start of the phase to trigger the assignment.
Private.classes.PhasedAssignment = setmetatable({
	phase = 1,
	time = 0.0,
}, { __index = Private.classes.Assignment })
Private.classes.PhasedAssignment.__index = Private.classes.PhasedAssignment

-- Wrapper around an assignment with additional info about where to draw the assignment on the timeline.
---@class TimelineAssignment
---@field assignment Assignment The assignment.
---@field startTime number Time used to place the assignment on the timeline.
---@field order number The row of the assignment in the timeline.
---@field spellCooldownDuration number Cached cooldown duration of the spell associated with the assignment.
Private.classes.TimelineAssignment = {}
Private.classes.TimelineAssignment.__index = Private.classes.TimelineAssignment

-- A raid or dungeon with a specific instanceID.
---@class RaidInstance
---@field name string The name of the raid or dungeon.
---@field journalInstanceID number The journal instance ID of the raid or dungeon. All bosses share the same JournalInstanceID.
---@field instanceID number The instance ID for the zone. All bosses share the same instanceID.
---@field bosses table<integer, Boss> List of bosses for the instance.
Private.classes.RaidInstance = {
	name = "",
	journalInstanceID = 0,
	instanceID = 0,
	bosses = {},
}

-- A raid or dungeon boss containing abilities, phases, etc.
---@class Boss
---@field name string Name of the boss.
---@field bossID table<integer,integer> ID of the boss or bosses.
---@field journalEncounterID integer Journal encounter ID of the boss encounter.
---@field dungeonEncounterID integer Dungeon encounter ID of the boss encounter.
---@field instanceID number The instance ID for the zone the boss is located in.
---@field phases table<integer, BossPhase> A list of phases and their durations.
---@field abilities table<SpellIDIndex, BossAbility> A list of abilities.
---@field sortedAbilityIDs table<integer, integer> An ordered list of abilities sorted by first appearance.
---@field abilityInstances table<integer, BossAbilityInstance> Data about a single instance of a boss ability stored in a boss ability frame in the timeline.
---@field treatAsSinglePhase boolean|nil If specified, the boss phases will be merged into one phase.
Private.classes.Boss = {
	name = "",
	bossID = {},
	journalEncounterID = 0,
	dungeonEncounterID = 0,
	instanceID = 0,
	phases = {},
	abilities = {},
	sortedAbilityIDs = {},
	abilityInstances = {},
	treatAsSinglePhase = nil,
}

-- A stage/phase in a boss encounter.
---@class BossPhase
---@field duration number The duration of the boss phase.
---@field defaultDuration number The default duration of the boss phase.
---@field count number The number of times the boss phase occurs.
---@field defaultCount number The default number of times the boss phase occurs.
---@field repeatAfter number|nil Which phase this phase repeats after.
---@field name string|nil If specified, the phase will be displayed on the timeline under this name. Otherwise hidden.
---@field fixedDuration boolean|nil If specified, the duration is not editable.
Private.classes.BossPhase = {
	duration = 0.0,
	defaultDuration = 0.0,
	count = 1,
	defaultCount = 1,
	repeatAfter = nil,
	name = nil,
	fixedDuration = nil,
}

-- A spell that a boss casts including when the spell is cast.
---@class BossAbility
---@field phases table<number, BossAbilityPhase> Describes at which times in which phases the ability occurs in.
---@field eventTriggers table<SpellIDIndex, EventTrigger>|nil Other boss abilities that trigger the ability.
---@field duration number Usually how long the ability effect lasts.
---@field castTime number The actual cast time of the ability.
Private.classes.BossAbility = {
	phases = {},
	eventTriggers = nil,
	duration = 0.0,
	castTime = 0.0,
}

-- A phase in which a boss ability is triggered/cast at least once. May also repeat.
---@class BossAbilityPhase
---@field castTimes table<integer, number> An ordered list of cast times, where the actual cast time is the running sum.
---@field repeatInterval number|nil If defined, the ability will repeat at this interval starting from the last cast time.
---@field signifiesPhaseStart boolean|nil If defined, first cast denotes the start of the phase it occurs in.
---@field signifiesPhaseEnd boolean|nil If defined, last cast completion denotes the end of the phase it occurs in.
Private.classes.BossAbilityPhase = {
	castTimes = {},
	repeatInterval = nil,
	signifiesPhaseStart = nil,
	signifiesPhaseEnd = nil,
}

-- Defines a boss ability that triggers another boss ability. May also repeat.
---@class EventTrigger
---@field combatLogEventType CombatLogEventType The combat log event type that acts as a trigger.
---@field castTimes table<integer, number> An ordered list of cast times, where the actual cast time is the running sum.
---@field repeatCriteria EventTriggerRepeatCriteria|nil Describes criteria for the ability to repeat.
Private.classes.EventTrigger = {
	combatLogEventType = "SCS",
	castTimes = {},
	repeatCriteria = nil,
}

-- A set of cast times to repeat until the phase ends. The triggering boss ability must be defined in the phase to trigger the repeat.
---@class EventTriggerRepeatCriteria
---@field spellCount integer The number of times the other ability must have been cast before the ability begins repeating.
---@field castTimes table<integer, number> An ordered list of cast times, where the actual cast time is the running sum.
Private.classes.EventTriggerRepeatCriteria = {
	spellCount = 0,
	castTimes = {},
}

-- Data about a single instance of a boss ability stored in a boss ability frame in the timeline.
---@class BossAbilityInstance
---@field bossAbilitySpellID integer The SpellID of the boss ability.
---@field bossAbilityInstanceIndex integer The occurrence number of this instance out of all boss ability instances.
---@field bossAbilityOrderIndex integer The index of the ability in the boss's sortedAbilityIDs.
---@field bossPhaseOrderIndex integer The index of boss phase in the boss phase order (not the boss phase).
---@field bossPhaseDuration number The duration of the boss phase.
---@field bossPhaseName string|nil If defined, the name of the start of the phase.
---@field nextBossPhaseName string|nil If defined, the name of the start of the next phase.
---@field spellOccurrence integer The number of times the spell has already been cast prior to this instance (+1).
---@field bossPhaseIndex integer The phase the ability instance is cast in.
---@field castStart number The cast time from the start of the encounter.
---@field castEnd number The cast start plus the cast time.
---@field effectEnd number The cast end plus the ability duration.
---@field frameLevel integer Frame level to use for the ability instance on the timeline.
---@field relativeCastTime number|nil If defined, the cast time from the trigger cast time.
---@field combatLogEventType CombatLogEventType|nil If defined, the combat log event type that acts as a trigger.
---@field triggerSpellID number|nil If defined, the spellID of the boss ability that triggers the event trigger.
---@field spellCount number|nil If defined, the spell count of the boss ability that triggers the event trigger.
---@field repeatInstance number|nil If defined, the number of times the set of repeat criteria cast times has been completed.
---@field repeatCastIndex number|nil If defined, the index of the cast time in the repeat criteria.
---@field signifiesPhaseStart boolean|nil If defined, first cast denotes start of the phase it occurs in.
---@field signifiesPhaseEnd boolean|nil If defined, last cast completion denotes end of the phase it occurs in.
---@field overlaps {heightMultiplier:number, offset:number}|nil A height and offset multiplier to use if perfectly overlapping with another cast of the same ability.
Private.classes.BossAbilityInstance = {
	bossAbilitySpellID = 0,
	bossAbilityInstanceIndex = 0,
	bossAbilityOrderIndex = 0,
	bossPhaseIndex = 0,
	bossPhaseOrderIndex = 0,
	bossPhaseDuration = 0.0,
	bossPhaseName = nil,
	nextBossPhaseName = nil,
	spellOccurrence = 0,
	castStart = 0.0,
	castEnd = 0.0,
	effectEnd = 0.0,
	frameLevel = 0,
	relativeCastTime = nil,
	combatLogEventType = nil,
	triggerSpellID = nil,
	spellCount = nil,
	repeatInstance = nil,
	repeatCastIndex = nil,
	signifiesPhaseStart = nil,
	signifiesPhaseEnd = nil,
	overlaps = nil,
}

-- An entry in a roster, only used in gui.
---@class RosterEntry
---@field class string
---@field classColoredName string
---@field role RaidGroupRole
Private.classes.RosterEntry = {
	class = "",
	role = "",
	classColoredName = "",
}

-- A plan for a boss encounter.
---@class Plan
---@field ID string Uniquely generated ID used when updating assignments received from other characters.
---@field name string Name of the plan.
---@field bossName string The name of the boss the plan is associated with.
---@field dungeonEncounterID integer Dungeon encounter ID for the boss the plan is associated with.
---@field instanceID integer Instance ID for the boss the plan is associated with.
---@field content table<integer, string> Miscellaneous text that other addons or WeakAuras can use for the encounter.
---@field assignments table<integer, Assignment> Assignments for the plan.
---@field roster table<string, RosterEntry> Roster for the plan.
---@field collapsed table<string, boolean> Which assignees are collapsed in the assignment timeline.
---@field customPhaseDurations table<integer, number> Overridden boss phase durations.
---@field remindersEnabled boolean Whether reminders are enabled for the plan.
Private.classes.Plan = {
	ID = "",
	name = "",
	bossName = "",
	dungeonEncounterID = 0,
	instanceID = 0,
	content = {},
	assignments = {},
	roster = {},
	collapsed = {},
	customPhaseDurations = {},
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

---@param o any
---@return RaidInstance
function Private.classes.RaidInstance:New(o)
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
	if not existingID then
		instance.ID = GenerateUniqueID()
	end
	return instance
end

---@param o any
---@return RosterEntry
function Private.classes.RosterEntry:New(o)
	return CreateNewInstance(self, o)
end

---@alias RaidGroupRole
---| "role:damager"
---| "role:healer"
---| "role:tank"
---| ""

---@alias ScrollKeyBinding
---| "MouseScroll"
---| "Alt-MouseScroll"
---| "Ctrl-MouseScroll"
---| "Shift-MouseScroll"

---@alias MouseButtonKeyBinding
---| "LeftButton"
---| "Alt-LeftButton"
---| "Ctrl-LeftButton"
---| "Shift-LeftButton"
---| "MiddleButton"
---| "Alt-MiddleButton"
---| "Ctrl-MiddleButton"
---| "Shift-MiddleButton"
---| "RightButton"
---| "Alt-RightButton"
---| "Ctrl-RightButton"
---| "Shift-RightButton"

---@alias AnchorPoint
---| "TOPLEFT"
---| "TOP"
---| "TOPRIGHT"
---| "RIGHT"
---| "BOTTOMRIGHT"
---| "BOTTOM"
---| "LEFT"
---| "BOTTOMLEFT"
---| "CENTER"

---@class KeyBindings
---@field pan MouseButtonKeyBinding
---@field zoom ScrollKeyBinding
---@field scroll ScrollKeyBinding
---@field editAssignment MouseButtonKeyBinding
---@field newAssignment MouseButtonKeyBinding
---@field duplicateAssignment MouseButtonKeyBinding

---@class Preferences
---@field keyBindings KeyBindings
---@field assignmentSortType AssignmentSortType
---@field timelineRows {numberOfAssignmentsToShow: integer, numberOfBossAbilitiesToShow: integer}
---@field zoomCenteredOnCursor boolean
---@field reminder ReminderPreferences
---@field showSpellCooldownDuration boolean

---@class ReminderTextToSpeechPreferences
---@field enableAtAdvanceNotice boolean
---@field enableAtTime boolean
---@field voiceID integer
---@field volume number

---@class ReminderSoundPreferences
---@field enableAtAdvanceNotice boolean
---@field enableAtTime boolean
---@field advanceNoticeSound string
---@field atSound string

---@class GenericReminderPreferences
---@field enabled boolean
---@field font string,
---@field fontSize integer
---@field fontOutline ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@field point AnchorPoint
---@field relativeTo string
---@field relativePoint AnchorPoint
---@field x number
---@field y number
---@field alpha number

---@class ProgressBarPreferences : GenericReminderPreferences
---@field textAlignment "LEFT"|"CENTER"|"RIGHT"
---@field texture string
---@field iconPosition "LEFT"|"RIGHT"
---@field width number
---@field durationAlignment "LEFT"|"CENTER"|"RIGHT"
---@field fill boolean
---@field showBorder boolean
---@field showIconBorder boolean
---@field color {r:number, g:number, b:number, a:number}
---@field backgroundColor {r:number, g:number, b:number, a:number}
---@field spacing integer

---@class MessagePreferences : GenericReminderPreferences
---@field showOnlyAtExpiration boolean
---@field textColor {r:number, g:number, b:number, a:number}

---@class ReminderPreferences
---@field enabled boolean
---@field onlyShowMe boolean
---@field cancelIfAlreadyCasted boolean
---@field advanceNotice number
---@field progressBars ProgressBarPreferences
---@field messages MessagePreferences
---@field textToSpeech ReminderTextToSpeechPreferences
---@field sound ReminderSoundPreferences

local defaults = {
	---@class DefaultProfile
	---@field activeBossAbilities table<integer, table<integer, boolean>> Boss abilities to show on the timeline.
	---@field plans table<string, Plan> All plans.
	---@field sharedRoster table<string, RosterEntry> A roster that is persistent across plans.
	---@field lastOpenNote string The last open plan.
	---@field recentSpellAssignments table<string, DropdownItemData> Recently assigned spells (up to 10).
	---@field trustedCharacters table<integer, string> Characters that may bypass the import warning.
	---@field windowSize {x: number, y: number}|nil Size of main frame when the addon was closed last.
	---@field minimizeFramePosition {x: number, y: number}|nil Position of the minimize frame.
	---@field preferences Preferences Settings.
	profile = {
		activeBossAbilities = {},
		plans = {},
		sharedRoster = {},
		lastOpenNote = "",
		recentSpellAssignments = {},
		trustedCharacters = {},
		preferences = {
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
				numberOfBossAbilitiesToShow = 6,
			},
			zoomCenteredOnCursor = true,
			showSpellCooldownDuration = true,
			reminder = {
				enabled = true,
				onlyShowMe = true,
				cancelIfAlreadyCasted = true,
				advanceNotice = 10.0,
				messages = {
					enabled = true,
					font = "PT Sans Narrow",
					fontSize = 24,
					fontOutline = "",
					point = "CENTER",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = 0,
					y = 300,
					alpha = 0.95,
					showOnlyAtExpiration = true,
					textColor = { 1, 0.82, 0, 0.95 },
				},
				progressBars = {
					enabled = true,
					textAlignment = "LEFT",
					font = "PT Sans Narrow",
					fontSize = 14,
					fontOutline = "",
					point = "RIGHT",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = -100,
					y = 0,
					alpha = 0.95,
					texture = "Clean",
					iconPosition = "LEFT",
					width = 100,
					durationAlignment = "RIGHT",
					fill = false,
					showBorder = true,
					showIconBorder = false,
					color = { 0.05, 0.05, 0.05, 0.25 },
					backgroundColor = { 0.5, 0.5, 0.5, 0.75 },
					spacing = -1,
				},
				textToSpeech = {
					enableAtAdvanceNotice = false,
					enableAtTime = false,
					voiceID = 0,
					volume = 100,
				},
				sound = {
					advanceNoticeSound = "",
					atSound = "",
					enableAtAdvanceNotice = false,
					enableAtTime = false,
				},
			},
		},
	},
}

Private.addOn = AceAddon:NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
Private.addOn.defaults = defaults
Private.addOn.optionsModule = Private.addOn:NewModule("Options") --[[@as OptionsModule]]

Private.raidInstances = {} --[[@as table<string, RaidInstance>]]
Private.interfaceUpdater = {}
Private.bossUtilities = {}
Private.utilities = {}
Private.prettyClassNames = {} --[[@as table<string, string>]] -- A map of class names to class pascal case colored class names

Private.mainFrame = nil --[[@as EPMainFrame]]
Private.assignmentEditor = nil --[[@as EPAssignmentEditor]]
Private.rosterEditor = nil --[[@as EPRosterEditor]]
Private.importEditBox = nil --[[@as EPEditBox]]
Private.exportEditBox = nil --[[@as EPEditBox]]
Private.optionsMenu = nil --[[@as EPOptions]]
Private.messageAnchor = nil --[[@as EPReminderMessage]]
Private.progressBarAnchor = nil --[[@as EPProgressBar]]
Private.menuButtonContainer = nil --[[@as EPContainer]]
Private.messageContainer = nil --[[@as EPContainer]]
Private.progressBarContainer = nil --[[@as EPContainer]]
Private.messageBox = nil --[[@as EPMessageBox]]
Private.phaseLengthEditor = nil --[[@as EPPhaseLengthEditor]]
Private.tooltip = CreateFrame("GameTooltip", "EncounterPlannerTooltip", UIParent, "GameTooltipTemplate")

LSM:Register(
	"font",
	"PT Sans Narrow",
	"Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
	bit.bor(LSM.LOCALE_BIT_western, LSM.LOCALE_BIT_ruRU)
)

-- Public facing API.
---@class EncounterPlanner
EncounterPlanner = {}
