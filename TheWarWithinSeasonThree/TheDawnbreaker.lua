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

Private.dungeonInstances[2662] = DungeonInstance:New({
	journalInstanceID = 1270,
	instanceID = 2662,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Speaker Shadowcrown
			bossIDs = {
				211087, -- Speaker Shadowcrown
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5696] = 211087, -- Speaker Shadowcrown
			},
			journalEncounterID = 2580,
			dungeonEncounterID = 2837,
			instanceID = 2662,
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
		Boss:New({ -- Anub'ikkaj
			bossIDs = {
				211089, -- Anub'ikkaj
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5733] = 211089, -- Anub'ikkaj
			},
			journalEncounterID = 2581,
			dungeonEncounterID = 2838,
			instanceID = 2662,
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
		Boss:New({ -- Rasha'nan
			bossIDs = {
				224552, -- Rasha'nan
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5658] = 224552, -- Rasha'nan
			},
			journalEncounterID = 2593,
			dungeonEncounterID = 2839,
			instanceID = 2662,
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
