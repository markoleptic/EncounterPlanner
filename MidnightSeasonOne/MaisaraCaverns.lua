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

Private.dungeonInstances[2874] = DungeonInstance:New({
	journalInstanceID = 1315,
	instanceID = 2874,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Muro'jin and Nekraxx
			bossIDs = {
				247570, -- Muro'jin
				247572, -- Nekraxx
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6029] = 247570, -- Muro'jin
				[6030] = 248404, -- Nekraxx
			},
			journalEncounterID = 2810,
			dungeonEncounterID = 3212,
			instanceID = 2874,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Vordaza
			bossIDs = {
				248595, -- Vordaza
				250443, -- Unstable Phantom
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6068] = 248595, -- Vordaza
				[6069] = 250443, -- Unstable Phantom
			},
			journalEncounterID = 2811,
			dungeonEncounterID = 3213,
			instanceID = 2874,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Rak'tul, Vessel of Souls
			bossIDs = { 248605 },
			journalEncounterCreatureIDsToBossIDs = {
				[6062] = 248605, -- Rak'tul
				[6071] = 251047, -- Soulbind Totem
				[6072] = 1531, -- Lost Soul
				[6070] = 251674, -- Malignant Soul
			},
			journalEncounterID = 2812,
			dungeonEncounterID = 3214,
			instanceID = 2874,
			abilities = {},
			phases = {},
		}),
	},
})
