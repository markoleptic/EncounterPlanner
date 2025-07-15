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

Private.dungeonInstances[2287] = DungeonInstance:New({
	journalInstanceID = 1185,
	instanceID = 2287,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Halkias, the Sin-Stained Goliath
			bossIDs = {
				165408, -- Halkias
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5159] = 165408, -- Halkias
			},
			journalEncounterID = 2406,
			dungeonEncounterID = 2401,
			instanceID = 2287,
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
		Boss:New({ -- Echelon
			bossIDs = {
				164185, -- Echelon
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5172] = 164185, -- Echelon
			},
			journalEncounterID = 2387,
			dungeonEncounterID = 2380,
			instanceID = 2287,
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
		Boss:New({ -- High Adjudicator Aleez
			bossIDs = {
				165410, -- High Adjudicator Aleez
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5166] = 165410, -- High Adjudicator Aleez
				-- [5168] = 165410, -- Ghastly Parishioner
				-- [5188] = 165410, -- Vessel of Atonement
			},
			journalEncounterID = 2411,
			dungeonEncounterID = 2403,
			instanceID = 2287,
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
		Boss:New({ -- Lord Chamberlain
			bossIDs = {
				164218, -- Lord Chamberlain
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5213] = 164218, -- Lord Chamberlain
			},
			journalEncounterID = 2413,
			dungeonEncounterID = 2381,
			instanceID = 2287,
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
