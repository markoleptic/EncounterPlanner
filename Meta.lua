---@meta

---@class Private

---@class PhaseData
---@field castTimes table<number>|nil
---@field repeatInterval number|nil

---@class EventTrigger
---@field cleuEventType string
---@field castTimes table<number>
---@field repeatCriteria {castOccurance: number, castTimes: table<number>}|nil

---@class BossAbility
---@field phases table<number, PhaseData>
---@field eventTriggers table<integer, EventTrigger>|nil
---@field duration number
---@field castTime number

---@class BossPhase
---@field duration number
---@field defaultDuration number
---@field count number
---@field defaultCount number
---@field repeatAfter number|nil

---@class Boss
---@field abilities table<integer, BossAbility>
---@field phases table<integer, BossPhase>
---@field sortedAbilityIDs? table<integer>


---@alias CombatLogEventType = {
---| "SCC" SPELL_CAST_SUCCESS
---| "SCS" SPELL_CAST_START
---| "SAA" SPELL_AURA_APPLIED
---| "SAR" SPELL_AURA_REMOVED

---@alias AssignmentType
---| "CombatLogEvent"
---| "Time"
---| "Phase"
---| "CustomEvent"

---@class Assignment
---@field assigneeNameOrRole string Who to assign the assignment to
---@field line string Originally parsed line in the form: {assigneeNameOrRole} {options}
---@field text string The originally parsed portion of the assignment containing a {text}{/text} block
---@field textWithIconReplacements string Text with icons formatted back in
---@field strWithIconReplacements string Line with icons formatted back in, similar to how it appears in the note
---@field spellInfo { spellID: integer, name: string, iconID: integer } The spell info for the assignment
---@field targetName string|nil The target's name if the assignment has a '@'

---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType The type of combat log even the assignment is triggered by
---@field combatLogEventSpellID integer The spell for the event
---@field phase number|nil The phase the combat log event must occur in
---@field spellCount integer|nil The number of times the combat log event must have occurred
---@field time number The time from the combat log event to trigger the assignment

---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered

---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by
---@field time number The time from the start of the phase to trigger the assignment

---@class TimelineAssignment
---@field assignment Assignment The assignment
---@field startTime number Time used to place the assignment on the timeline
---@field offset number TODO Get rid of
---@field order number When sorted by first appearance, this number signifies the order relative to other assignments. This number is the same across assignments with the same assignee.
