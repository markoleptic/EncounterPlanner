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

Private.raidInstances[2293] = RaidInstance:New({
	journalInstanceID = 1187,
	instanceID = 2293,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- An Affront of Challengers
			bossID = {
				164451, -- Dessia the Decapitator
				164463, -- Paceran the Virulent
				164461, -- Sathel the Accursed
			},
			journalEncounterID = 2397,
			dungeonEncounterID = 2391,
			instanceID = 2293,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Gorechop
			bossID = { 162317 },
			journalEncounterID = 2401,
			dungeonEncounterID = 2365,
			instanceID = 2293,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Xav the Unfallen
			bossID = { 162329 },
			journalEncounterID = 2390,
			dungeonEncounterID = 2366,
			instanceID = 2293,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Kul'tharok
			bossID = { 162309 },
			journalEncounterID = 2389,
			dungeonEncounterID = 2364,
			instanceID = 2293,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Mordretha
			bossID = { 165946 },
			journalEncounterID = 2417,
			dungeonEncounterID = 2404,
			instanceID = 2293,
			abilities = {},
			phases = {},
		}),
	},
})
