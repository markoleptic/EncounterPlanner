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

Private.raidInstances[2661] = RaidInstance:New({
	journalInstanceID = 1272,
	instanceID = 2661,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Brew Master Aldryr
			bossID = { 210271 },
			journalEncounterID = 2586,
			dungeonEncounterID = 2900,
			instanceID = 2661,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- I'pa
			bossID = { 210267 },
			journalEncounterID = 2587,
			dungeonEncounterID = 2929,
			instanceID = 2661,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Benk Buzzbee
			bossID = { 218002 },
			journalEncounterID = 2588,
			dungeonEncounterID = 2931,
			instanceID = 2661,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Goldie Baronbottom
			bossID = { 214661 },
			journalEncounterID = 2589,
			dungeonEncounterID = 2930,
			instanceID = 2661,
			abilities = {},
			phases = {},
		}),
	},
})
