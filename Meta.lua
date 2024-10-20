---@meta

---@alias SpellID number
---@alias CombatLogEventType string

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
---@field eventTriggers table<SpellID, EventTrigger>|nil
---@field duration number
---@field castTime number

---@class BossPhase
---@field duration number
---@field defaultDuration number
---@field count number
---@field defaultCount number
---@field repeatAfter number|nil

---@class Boss
---@field abilities table<SpellID, BossAbility>
---@field phases table<integer, BossPhase>
---@field sortedAbilityIDs? table<SpellID>

---@class CombatLogEventBasedTimer
---@field assignedUnit number
---@field assigneeNameOrRole string
---@field line string
---@field spellInfo table
---@field strWithIconReplacements string

---@alias SpellOccurance table<number, table<time_t, table<number, CombatLogEventBasedTimer>>>
---@alias CombatLogEvent table<SpellID, SpellOccurance>
---@alias CombatLogEventBasedTimers table<CombatLogEventType, CombatLogEvent>

---@class AbsoluteTimeBasedTimer
---@field assignedUnit number
---@field assigneeNameOrRole string
---@field line string
---@field spellInfo table
---@field strWithIconReplacements string
---@field time number

---@class TimelineAssignment
---@field assignedUnit number
---@field assigneeNameOrRole string
---@field spellInfo table
---@field strWithIconReplacements string
---@field startTime number
---@field offset number
