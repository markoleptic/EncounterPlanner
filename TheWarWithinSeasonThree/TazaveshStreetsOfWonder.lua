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

Private.dungeonInstances[2441] = DungeonInstance:New({
	journalInstanceID = 1194,
	instanceID = 2441,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Zo'phex the Sentinel
			bossIDs = {
				175616, -- Zo'phex
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5236] = 175616, -- Zo'phex
			},
			journalEncounterID = 2437,
			dungeonEncounterID = 2425,
			instanceID = 2441,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- The Grand Menagerie
			bossIDs = {
				176556, -- Alcruux
				176555, -- Achillite
				176705, -- Venza Goldfuse
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6009] = 176556, -- Alcruux
				[5249] = 176555, -- Achillite
				[5251] = 176705, -- Venza Goldfuse
			},
			journalEncounterID = 2454,
			dungeonEncounterID = 2441,
			instanceID = 2441,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Mailroom Mayhem
			bossIDs = {
				175646, -- P.O.S.T. Master
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5276] = 175646, -- P.O.S.T. Master
			},
			journalEncounterID = 2436,
			dungeonEncounterID = 2424,
			instanceID = 2441,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Myza's Oasis
			bossIDs = {
				176564, -- Zo'gron
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5277] = 176564, -- Zo'gron
				[5290] = 176564, -- Brawling Patron
				[5291] = 176564, -- Disruptive Patron
				[5289] = 176564, -- Oasis Security
			},
			journalEncounterID = 2452,
			dungeonEncounterID = 2440,
			instanceID = 2441,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- So'azmi
			bossIDs = {
				175806, -- So'azmi
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5278] = 175806, -- So'azmi
			},
			journalEncounterID = 2451,
			dungeonEncounterID = 2437,
			instanceID = 2441,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
	},
})
