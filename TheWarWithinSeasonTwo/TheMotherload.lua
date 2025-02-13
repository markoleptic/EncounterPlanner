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

Private.raidInstances[1594] = RaidInstance:New({
	journalInstanceID = 1012,
	instanceID = 1594,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Crowd Pummeler
			bossID = { 129214 },
			journalEncounterID = 2109,
			dungeonEncounterID = 2105,
			instanceID = 1594,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Azerokk
			bossID = {
				129227, -- Azerokk
				129802, -- Earthrager
			},
			journalEncounterID = 2114,
			dungeonEncounterID = 2106,
			instanceID = 1594,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Rixxa Fluxflame
			bossID = { 129231 },
			journalEncounterID = 2115,
			dungeonEncounterID = 2107,
			instanceID = 1594,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Mogul Razdunk
			bossID = { 129232 },
			journalEncounterID = 2116,
			dungeonEncounterID = 2108,
			instanceID = 1594,
			abilities = {},
			phases = {},
		}),
	},
})
