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
			abilities = {
				[1257524] = BossAbility:New({ -- Corespark Detonation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.5 },
							repeatInterval = 52.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1264048] = BossAbility:New({ -- Flux Collapse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.7, 13.6, 24.0, 17.6, 15.0, 27.7 },
							repeatInterval = { 14.3, 13.4, 26.8 },
						}),
					},
					duration = 78.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251772] = BossAbility:New({ -- Reflux Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8 },
							repeatInterval = { 12.2, 12.2, 25.5 },
						}),
					},
					duration = 0.0,
					castTime = 2.1,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
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
			abilities = {
				[1247937] = BossAbility:New({ -- Umbral Lash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.6 },
							repeatInterval = { 17.1, 27.1, 23.1 },
						}),
					},
					duration = 0.0,
					castTime = 0.9,
					allowedCombatLogEventTypes = {},
				}),
				[1249014] = BossAbility:New({ -- Eclipsing Step
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.0 },
							repeatInterval = { 18.3, 41.0 },
						}),
					},
					duration = 8.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1247976] = BossAbility:New({ -- Lightscar Flare
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 39.7 },
							repeatInterval = 62.0,
						}),
					},
					duration = 18.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
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
			abilities = {
				[1253855] = BossAbility:New({ -- Brilliant Dispersion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.8 },
							repeatInterval = { 25.5, 40.9 },
						}),
					},
					duration = 6.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1257595] = BossAbility:New({ -- Divine Guile
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 52.8 },
							repeatInterval = 66.3,
						}),
					},
					duration = 6.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253950] = BossAbility:New({ -- Searing Rend
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.8 },
							repeatInterval = 41.1,
						}),
					},
					duration = 6.0,
					castTime = 4.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
	},
})
