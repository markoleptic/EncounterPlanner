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

Private.raidInstances[2648] = RaidInstance:New({
	journalInstanceID = 1268,
	instanceID = 2648,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Kyrioss
			bossID = { 209230 },
			journalEncounterID = 2566,
			dungeonEncounterID = 2816,
			instanceID = 2648,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Stormguard Gorren
			bossID = { 207205 },
			journalEncounterID = 2567,
			dungeonEncounterID = 2861,
			instanceID = 2648,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Voidstone Monstrosity
			bossID = { 207207 },
			journalEncounterID = 2568,
			dungeonEncounterID = 2836,
			instanceID = 2648,
			abilities = {},
			phases = {},
		}),
	},
})
