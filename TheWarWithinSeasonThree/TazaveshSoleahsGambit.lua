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
		Boss:New({ -- Hylbrande
			bossIDs = {
				175663, -- Hylbrande
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5240] = 175663, -- Hylbrande
				-- [5274] = , -- Vault Purifier
			},
			journalEncounterID = 2448,
			dungeonEncounterID = 2426,
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
		Boss:New({ -- Timecap'n Hooktail
			bossIDs = {
				175546, -- Timecap'n Hooktail
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5241] = 175546, -- Timecap'n Hooktail
				-- [5271] = , -- Corsair Brute
			},
			journalEncounterID = 2449,
			dungeonEncounterID = 2419,
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
		Boss:New({ -- So'leah
			bossIDs = {
				177269, -- So'leah
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5275] = 177269, -- So'leah
			},
			journalEncounterID = 2455,
			dungeonEncounterID = 2442,
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
