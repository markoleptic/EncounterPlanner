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

Private.raidInstances[2097] = RaidInstance:New({
	journalInstanceID = 1178,
	instanceID = 2097,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Tussle Tonks
			bossID = {
				144244, -- The Platinum Pummeler
				145185, -- Gnomercy 4.U.
				151657, -- Bomb Tonk
				151658, -- Strider Tonk
				151659, -- Rocket Tonk
			},
			journalEncounterID = 2336,
			dungeonEncounterID = 2257,
			instanceID = 2097,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- K.U.-J.0.
			bossID = { 144246 },
			journalEncounterID = 2339,
			dungeonEncounterID = 2258,
			instanceID = 2097,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Machinist's Garden
			bossID = { 144248 },
			journalEncounterID = 2348,
			dungeonEncounterID = 2259,
			instanceID = 2097,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- King Mechagon
			bossID = { 150396, 150397, 144249 },
			journalEncounterID = 2331,
			dungeonEncounterID = 2260,
			instanceID = 2097,
			abilities = {},
			phases = {},
		}),
	},
})
