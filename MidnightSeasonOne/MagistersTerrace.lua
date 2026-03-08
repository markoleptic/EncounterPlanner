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
			abilities = {
				[1214081] = BossAbility:New({ -- Arcane Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.9 },
							repeatInterval = { 23.1, 45.6 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[474345] = BossAbility:New({ -- Refueling Protocol
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 45.8 },
							repeatInterval = { 68.5 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1214038] = BossAbility:New({ -- Ethereal Shackles
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.9 },
							repeatInterval = { 23.1, 62.8 },
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
		Boss:New({ -- Seranel Sunlash
			bossIDs = { 231863 },
			journalEncounterCreatureIDsToBossIDs = {
				[5914] = 231863, -- Seranel Sunlash
			},
			journalEncounterID = 2661,
			dungeonEncounterID = 3072,
			instanceID = 2811,
			abilities = {
				[1224903] = BossAbility:New({ -- Suppression Zone
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.8 },
							repeatInterval = { 57.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1225792] = BossAbility:New({ -- Runic Mark
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.3 },
							repeatInterval = { 29.2, 27.3, 29.1, 27.9 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248689] = BossAbility:New({ -- Hastening Ward
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.7 },
							repeatInterval = { 56.6, 57.0, 57.1 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1225193] = BossAbility:New({ -- Wave of Silence
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 51.7 },
							repeatInterval = { 57.0 },
						}),
					},
					duration = 8.0,
					castTime = 5.0,
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
		Boss:New({ -- Gemellus
			bossIDs = { 231864 },
			journalEncounterCreatureIDsToBossIDs = {
				[5982] = 231864, -- Gemellus
			},
			journalEncounterID = 2660,
			dungeonEncounterID = 3073,
			instanceID = 2811,
			abilities = {
				[1224299] = BossAbility:New({ -- Astral Grasp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 37.5 },
							repeatInterval = { 43.0 },
						}),
					},
					duration = 9.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1223847] = BossAbility:New({ -- Triplicate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.0, 82.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1284954] = BossAbility:New({ -- Cosmic Sting
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.2 },
							repeatInterval = { 43.0 },
						}),
					},
					duration = 6.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253709] = BossAbility:New({ -- Neural Link
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.1 },
							repeatInterval = { 43.0 },
						}),
					},
					duration = 12.0,
					castTime = 2.0,
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
		Boss:New({ -- Degentrius
			bossIDs = { 231865 },
			journalEncounterCreatureIDsToBossIDs = {
				[6087] = 231865, -- Degentrius
			},
			journalEncounterID = 2662,
			dungeonEncounterID = 3074,
			instanceID = 2811,
			abilities = {
				[1215087] = BossAbility:New({ -- Unstable Void Essence
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.8 },
							repeatInterval = { 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1280113] = BossAbility:New({ -- Hulking Fragment
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.6 },
							repeatInterval = { 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1284627] = BossAbility:New({ -- Umbral Splinters
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.6 },
							repeatInterval = { 23.0 },
						}),
					},
					duration = 30.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1215897] = BossAbility:New({ -- Devouring Entropy
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0, 0.1, 0.1 },
							repeatInterval = { 22.7, 0.1, 0.1 },
						}),
					},
					duration = 16.0,
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
	},
})
