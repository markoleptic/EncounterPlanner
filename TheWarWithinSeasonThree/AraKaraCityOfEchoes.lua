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

Private.dungeonInstances[2660] = DungeonInstance:New({
	journalInstanceID = 1271,
	instanceID = 2660,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Avanoxx
			bossIDs = {
				213179, -- Avanoxx
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5700] = 213179, -- Avanoxx
				-- [5745] = , -- Starved Crawler
			},
			journalEncounterID = 2583,
			dungeonEncounterID = 2926,
			instanceID = 2660,
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
		Boss:New({ -- Anub'zekt
			bossIDs = {
				215405, -- Anub'zekt
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5726] = 215405, -- Anub'zekt
				-- [5744] = , -- Bloodstained Webmage
			},
			journalEncounterID = 2584,
			dungeonEncounterID = 2906,
			instanceID = 2660,
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
		Boss:New({ -- Ki'katal the Harvester
			bossIDs = {
				215407, -- Ki'katal the Harvester
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5632] = 215407, -- Ki'katal the Harvester
			},
			journalEncounterID = 2585,
			dungeonEncounterID = 2901,
			instanceID = 2660,
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
