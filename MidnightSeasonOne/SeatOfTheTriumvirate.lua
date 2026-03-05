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

Private.dungeonInstances[1753] = DungeonInstance:New({
	journalInstanceID = 945,
	instanceID = 1753,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Zuraal the Ascended
			bossIDs = {
				122313, -- Zuraal the Ascended
				122716, -- Coalesced Void
			},
			journalEncounterCreatureIDsToBossIDs = {
				[4489] = 122313, -- Zuraal the Ascended
				[6109] = 122716, -- Coalesced Void
			},
			journalEncounterID = 1979,
			dungeonEncounterID = 2065,
			instanceID = 1753,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Saprish
			bossIDs = {
				122316, -- Saprish
				122319, -- Darkfang
				125340, -- Shadewing
			},
			journalEncounterCreatureIDsToBossIDs = {
				[4492] = 122316, -- Saprish
				[4491] = 122319, -- Darkfang
				[4530] = 125340, -- Shadewing
			},
			journalEncounterID = 1980,
			dungeonEncounterID = 2066,
			instanceID = 1753,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Viceroy Nezhar
			bossIDs = { 124309 },
			journalEncounterCreatureIDsToBossIDs = {
				[4490] = 124309, -- Viceroy Nezhar
			},
			journalEncounterID = 1981,
			dungeonEncounterID = 2067,
			instanceID = 1753,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- L'ura
			bossIDs = {
				214650, -- L'ura
			},
			journalEncounterCreatureIDsToBossIDs = {
				[4477] = 214650, -- L'ura
			},
			journalEncounterID = 1982,
			dungeonEncounterID = 2068,
			instanceID = 1753,
			abilities = {},
			phases = {},
		}),
	},
})
