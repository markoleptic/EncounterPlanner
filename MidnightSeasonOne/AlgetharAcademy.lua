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

Private.dungeonInstances[2526] = DungeonInstance:New({
	journalInstanceID = 1201,
	instanceID = 2526,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Vexamus
			bossIDs = {
				194181, -- Vexamus
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5411] = 194181, -- Vexamus
			},
			journalEncounterID = 2509,
			dungeonEncounterID = 2562,
			instanceID = 2526,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Overgrown Ancient
			bossIDs = {
				196482, -- Overgrown Ancient
				196548, -- Ancient Branch
				197398, -- Hungry Lasher
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5420] = 196482, -- Overgrown Ancient
				[5422] = 196548, -- Ancient Branch
				[5425] = 197398, -- Hungry Lasher
			},
			journalEncounterID = 2512,
			dungeonEncounterID = 2563,
			instanceID = 2526,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Crawth
			bossIDs = { 191736 },
			journalEncounterCreatureIDsToBossIDs = {
				[5370] = 191736, -- Crawth
			},
			journalEncounterID = 2495,
			dungeonEncounterID = 2564,
			instanceID = 2526,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Echo of Doragosa
			bossIDs = { 190609 },
			journalEncounterCreatureIDsToBossIDs = {
				[5423] = 190609, -- Echo of Doragosa
			},
			journalEncounterID = 2514,
			dungeonEncounterID = 2565,
			instanceID = 2526,
			abilities = {},
			phases = {},
		}),
	},
})
