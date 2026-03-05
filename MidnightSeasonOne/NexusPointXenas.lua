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

Private.dungeonInstances[2915] = DungeonInstance:New({
	journalInstanceID = 1316,
	instanceID = 2915,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Chief Corewright Kasreth
			bossIDs = { 241539 },
			journalEncounterCreatureIDsToBossIDs = {
				[6000] = 241539, -- Chief Corewright Kasreth
			},
			journalEncounterID = 2813,
			dungeonEncounterID = 3328,
			instanceID = 2915,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Corewarden Nysarra
			bossIDs = {
				254227, -- Corewarden Nysarra
				251853, -- Grand Nullifier
				251024, -- Dreadflail
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6001] = 254227, -- Corewarden Nysarra
				[6074] = 251853, -- Grand Nullifier
				[6075] = 251024, -- Dreadflail
			},
			journalEncounterID = 2814,
			dungeonEncounterID = 3332,
			instanceID = 2915,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Lothraxion
			bossIDs = {
				241546, -- Lothraxion
				255133, -- Fractured Image
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6002] = 241546, -- Lothraxion
				[6115] = 255133, -- Fractured Image
			},
			journalEncounterID = 2815,
			dungeonEncounterID = 3333,
			instanceID = 2915,
			abilities = {},
			phases = {},
		}),
	},
})
