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

Private.dungeonInstances[658] = DungeonInstance:New({
	journalInstanceID = 278,
	instanceID = 658,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Forgemaster Garfrost
			bossIDs = { 36494 },
			journalEncounterCreatureIDsToBossIDs = {
				[1182] = 36494, -- Forgemaster Garfrost
			},
			journalEncounterID = 608,
			dungeonEncounterID = 1999,
			instanceID = 658,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Ick and Krick
			bossIDs = {
				36477, -- Krick
				36476, -- Ick
				255037, -- Shade of Krick
			},
			journalEncounterCreatureIDsToBossIDs = {
				[1184] = 36477, -- Krick
				[1183] = 36476, -- Ick
				[6108] = 255037, -- Shade of Krick
			},
			journalEncounterID = 609,
			dungeonEncounterID = 2001,
			instanceID = 658,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Scourgelord Tyrannus
			bossIDs = {
				36658, -- Scourgelord Tyrannus
				252653, -- Rimefang
				254691, -- Scourge Plaguespreader
				254684, -- Rotling
			},
			journalEncounterCreatureIDsToBossIDs = {
				[1185] = 36658, -- Scourgelord Tyrannus
				[6091] = 252653, -- Rimefang
				[6146] = 254691, -- Scourge Plaguespreader
				[6147] = 254684, -- Rotling
			},
			journalEncounterID = 610,
			dungeonEncounterID = 2000,
			instanceID = 658,
			abilities = {},
			phases = {},
		}),
	},
})
