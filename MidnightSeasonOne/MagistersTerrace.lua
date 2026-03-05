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

Private.dungeonInstances[2811] = DungeonInstance:New({
	journalInstanceID = 1300,
	instanceID = 2811,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Arcanotron Custos
			bossIDs = { 231861 },
			journalEncounterCreatureIDsToBossIDs = {
				[6086] = 231861, -- Arcanotron Custos
			},
			journalEncounterID = 2659,
			dungeonEncounterID = 3071,
			instanceID = 2811,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Seranel Sunlash
			bossIDs = { 231863 },
			journalEncounterCreatureIDsToBossIDs = {
				[5914] = 231863, -- Seranel Sunlash
			},
			journalEncounterID = 2661,
			dungeonEncounterID = 3072,
			instanceID = 2811,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Gemellus
			bossIDs = { 231864 },
			journalEncounterCreatureIDsToBossIDs = {
				[5982] = 231864, -- Gemellus
			},
			journalEncounterID = 2660,
			dungeonEncounterID = 3073,
			instanceID = 2811,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Degentrius
			bossIDs = { 231865 },
			journalEncounterCreatureIDsToBossIDs = {
				[6087] = 231865, -- Degentrius
			},
			journalEncounterID = 2662,
			dungeonEncounterID = 3074,
			instanceID = 2811,
			abilities = {},
			phases = {},
		}),
	},
})
