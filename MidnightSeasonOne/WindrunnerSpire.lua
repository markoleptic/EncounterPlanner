local _, Namespace = ...

---@class Private
local Private = Namespace
---@class Boss
local Boss = Private.classes.Boss
---@class BossAbility
local BossAbility = Private.classes.BossAbility
---@class BossAbilityPhase
local BossAbilityPhase = Private.classes.BossAbilityPhase
---@class BossPhase
local BossPhase = Private.classes.BossPhase
---@class DungeonInstance
local DungeonInstance = Private.classes.DungeonInstance

Private.dungeonInstances[2805] = DungeonInstance:New({
	journalInstanceID = 1299,
	instanceID = 2805,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Emberdawn
			bossIDs = { 231606 },
			journalEncounterCreatureIDsToBossIDs = {
				[5764] = 231606, -- Emberdawn
			},
			journalEncounterID = 2655,
			dungeonEncounterID = 3056,
			instanceID = 2805,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Derelict Duo
			bossIDs = {
				231626, -- Kalis
				231629, -- Latch
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5839] = 231626, -- Kalis
				[5840] = 231629, -- Latch
			},
			journalEncounterID = 2656,
			dungeonEncounterID = 3057,
			instanceID = 2805,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Commander Kroluk
			bossIDs = { 231631 },
			journalEncounterCreatureIDsToBossIDs = {
				[5845] = 231631, -- Commander Kroluk
				[6035] = 234061, -- Phantasmal Mystic
				[6036] = 232447, -- Spectral Axethrower
				[6034] = 258868, -- Haunting Grunt
			},
			journalEncounterID = 2657,
			dungeonEncounterID = 3058,
			instanceID = 2805,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- The Restless Heart
			bossIDs = { 231636 },
			journalEncounterCreatureIDsToBossIDs = {
				[5844] = 231636, -- The Restless Heart
			},
			journalEncounterID = 2658,
			dungeonEncounterID = 3059,
			instanceID = 2805,
			abilities = {},
			phases = {},
		}),
	},
})
