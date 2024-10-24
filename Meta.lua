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
