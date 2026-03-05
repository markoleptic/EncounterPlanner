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

Private.dungeonInstances[1209] = DungeonInstance:New({
	journalInstanceID = 476,
	instanceID = 1209,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Ranjit
			bossIDs = { 75964 },
			journalEncounterCreatureIDsToBossIDs = {
				[3108] = 75964, -- Ranjit
			},
			journalEncounterID = 965,
			dungeonEncounterID = 1698,
			instanceID = 1209,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Araknath
			bossIDs = { 76141 },
			journalEncounterCreatureIDsToBossIDs = {
				[3309] = 76141, -- Araknath
			},
			journalEncounterID = 966,
			dungeonEncounterID = 1699,
			instanceID = 1209,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Rukhran
			bossIDs = { 76379 },
			journalEncounterCreatureIDsToBossIDs = {
				[3347] = 76379, -- Rukhran
				[3350] = 50357, -- Sunwings
			},
			journalEncounterID = 967,
			dungeonEncounterID = 1700,
			instanceID = 1209,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- High Sage Viryx
			bossIDs = { 76266 },
			journalEncounterCreatureIDsToBossIDs = {
				[3111] = 76266, -- High Sage Viryx
				[2936] = 76267, -- Arakkoa Solar Zealot
				[2938] = 76292, -- Arakkoa Shield Construct
			},
			journalEncounterID = 968,
			dungeonEncounterID = 1701,
			instanceID = 1209,
			abilities = {},
			phases = {},
		}),
	},
})
