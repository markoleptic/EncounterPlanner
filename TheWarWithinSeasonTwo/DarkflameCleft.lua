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

Private.raidInstances[2651] = RaidInstance:New({
	journalInstanceID = 1210,
	instanceID = 2651,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Ol' Waxbeard
			bossID = {
				210149, -- Ol' Waxbeard (boss)
				210153, -- Ol' Waxbeard (mount)
			},
			journalEncounterID = 2569,
			dungeonEncounterID = 2829,
			instanceID = 2651,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Blazikon
			bossID = { 208743 },
			journalEncounterID = 2559,
			dungeonEncounterID = 2826,
			instanceID = 2651,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- The Candle King
			bossID = { 208745 },
			journalEncounterID = 2560,
			dungeonEncounterID = 2787,
			instanceID = 2651,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- The Darkness
			bossID = {
				212777, -- Massive Candle
				208747, -- The Darkness
			},
			journalEncounterID = 2561,
			dungeonEncounterID = 2788,
			instanceID = 2651,
			abilities = {},
			phases = {},
		}),
	},
})
