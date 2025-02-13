local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
---@class EventTrigger
local EventTrigger = Private.classes.EventTrigger
---@class Boss
local Boss = Private.classes.Boss
---@class BossAbility
local BossAbility = Private.classes.BossAbility
---@class BossAbilityPhase
local BossAbilityPhase = Private.classes.BossAbilityPhase
---@class BossPhase
local BossPhase = Private.classes.BossPhase
---@class RaidInstance
local RaidInstance = Private.classes.RaidInstance

Private.raidInstances[2649] = RaidInstance:New({
	journalInstanceID = 1267,
	instanceID = 2649,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Captain Dailcry
			bossID = { 207946 },
			journalEncounterID = 2571,
			dungeonEncounterID = 2847,
			instanceID = 2649,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Baron Braunpyke
			bossID = { 207939 },
			journalEncounterID = 2570,
			dungeonEncounterID = 2835,
			instanceID = 2649,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Prioress Murrpray
			bossID = { 207940 },
			journalEncounterID = 2573,
			dungeonEncounterID = 2848,
			instanceID = 2649,
			abilities = {},
			phases = {},
		}),
	},
})
