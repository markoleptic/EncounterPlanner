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

Private.dungeonInstances[1209] = DungeonInstance:New({
	journalInstanceID = 476,
	instanceID = 1209,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Ranjit
			bossIDs = { 75964 },
			journalEncounterCreatureIDsToBossIDs = {
				[3108] = 75964, -- Ranjit
			},
			journalEncounterID = 965,
			dungeonEncounterID = 1698,
			instanceID = 1209,
			abilities = {
				[156793] = BossAbility:New({ -- Chakram Vortex
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.0 },
							repeatInterval = 40.0,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[153757] = BossAbility:New({ -- Fan of Blades
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = 20.0,
						}),
					},
					duration = 6.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1252690] = BossAbility:New({ -- Gale Surge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 40.0,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1258152] = BossAbility:New({ -- Wind Chakram
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.0 },
							repeatInterval = { 10.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
		Boss:New({ -- Araknath
			bossIDs = { 76141 },
			journalEncounterCreatureIDsToBossIDs = {
				[3309] = 76141, -- Araknath
			},
			journalEncounterID = 966,
			dungeonEncounterID = 1699,
			instanceID = 1209,
			abilities = {
				[154135] = BossAbility:New({ -- Supernova
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.0 },
							repeatInterval = 50.0,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1281874] = BossAbility:New({ -- Heat Exhaustion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.1 },
							repeatInterval = { 20.0, 0.0, 0.0, 30.0, 0.0, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
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
		Boss:New({ -- Rukhran
			bossIDs = { 76379 },
			journalEncounterCreatureIDsToBossIDs = {
				[3347] = 76379, -- Rukhran
				[3350] = 50357, -- Sunwings
			},
			journalEncounterID = 967,
			dungeonEncounterID = 1700,
			instanceID = 1209,
			abilities = {
				[1253519] = BossAbility:New({ -- Burning Claws
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 12.0, 36.0 },
						}),
					},
					duration = 8.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[159382] = BossAbility:New({ -- Searing Quills
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 39.2 },
							repeatInterval = 47.0,
						}),
					},
					duration = 3.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253510] = BossAbility:New({ -- Sunbreak
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = { 21.0, 26.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253416] = BossAbility:New({ -- Blaze of Glory (Sunwings)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 27.3 },
							repeatInterval = { 22.5, 24.7 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253511] = BossAbility:New({ -- Burning Pursuit (Sunwings)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 12.0, 34.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
		Boss:New({ -- High Sage Viryx
			bossIDs = { 76266 },
			journalEncounterCreatureIDsToBossIDs = {
				[3111] = 76266, -- High Sage Viryx
				[2936] = 76267, -- Arakkoa Solar Zealot
				[2938] = 76292, -- Arakkoa Shield Construct
			},
			journalEncounterID = 968,
			dungeonEncounterID = 1701,
			instanceID = 1209,
			abilities = {
				[153954] = BossAbility:New({ -- Cast Down
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = 39.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253840] = BossAbility:New({ -- Lens Flare
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = 39.0,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253538] = BossAbility:New({ -- Scorching Ray
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 10.0, 10.0, 19.0 },
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[154396] = BossAbility:New({ -- Solar Blast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.0 },
							repeatInterval = { 12.0, 27.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
