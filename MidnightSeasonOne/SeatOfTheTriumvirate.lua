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

Private.dungeonInstances[1753] = DungeonInstance:New({
	journalInstanceID = 945,
	instanceID = 1753,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Zuraal the Ascended
			bossIDs = {
				122313, -- Zuraal the Ascended
				122716, -- Coalesced Void
			},
			journalEncounterCreatureIDsToBossIDs = {
				[4489] = 122313, -- Zuraal the Ascended
				[6109] = 122716, -- Coalesced Void
			},
			journalEncounterID = 1979,
			dungeonEncounterID = 2065,
			instanceID = 1753,
			abilities = {
				[1263297] = BossAbility:New({ -- Crashing Void
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 48.7 },
							repeatInterval = { 56.0 },
						}),
					},
					duration = 5.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263282] = BossAbility:New({ -- Decimate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.7 },
							repeatInterval = { 28.8, 25.2, 29.2, 25.4 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1268916] = BossAbility:New({ -- Null Palm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.9 },
							repeatInterval = 55.0,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263399] = BossAbility:New({ -- Oozing Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.8 },
							repeatInterval = 55.0,
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263440] = BossAbility:New({ -- Void Lash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.8 },
							repeatInterval = { 38.7, 16.2 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
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
		Boss:New({ -- Saprish
			bossIDs = {
				122316, -- Saprish
				122319, -- Darkfang
				125340, -- Shadewing
			},
			journalEncounterCreatureIDsToBossIDs = {
				[4492] = 122316, -- Saprish
				[4491] = 122319, -- Darkfang
				[4530] = 125340, -- Shadewing
			},
			journalEncounterID = 1980,
			dungeonEncounterID = 2066,
			instanceID = 1753,
			abilities = {
				[1263523] = BossAbility:New({ -- Overload
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.0 },
							repeatInterval = 38.0,
						}),
					},
					duration = 8.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1280065] = BossAbility:New({ -- Phase Dash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = 38.0,
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[245742] = BossAbility:New({ -- Shadow Pounce (Darkfang)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = 12.2,
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[248829] = BossAbility:New({ -- Swoop (Shadewing)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.7 },
							repeatInterval = 15.8,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[248831] = BossAbility:New({ -- Screech (Shadewing)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.6 },
							repeatInterval = 15.8,
						}),
					},
					duration = 5.0,
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
		Boss:New({ -- Viceroy Nezhar
			bossIDs = { 124309 },
			journalEncounterCreatureIDsToBossIDs = {
				[4490] = 124309, -- Viceroy Nezhar
			},
			journalEncounterID = 1981,
			dungeonEncounterID = 2067,
			instanceID = 1753,
			abilities = {
				[1263529] = BossAbility:New({ -- Collapsing Void
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 47.5 },
							repeatInterval = 65.0,
						}),
					},
					duration = 0.0,
					castTime = 9.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263542] = BossAbility:New({ -- Mass Void Infusion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = 65.0,
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263528] = BossAbility:New({ -- Repulse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 45.0 },
							repeatInterval = 65.0,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263538] = BossAbility:New({ -- Umbral Tentacles
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.0 },
							repeatInterval = 65.0,
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
		-- Boss:New({ -- L'ura
		-- 	bossIDs = {
		-- 		214650, -- L'ura
		-- 	},
		-- 	journalEncounterCreatureIDsToBossIDs = {
		-- 		[4477] = 214650, -- L'ura
		-- 	},
		-- 	journalEncounterID = 1982,
		-- 	dungeonEncounterID = 2068,
		-- 	instanceID = 1753,
		-- 	abilities = {},
		-- 	phases = {
		-- 		[1] = BossPhase:New({
		-- 			duration = 180.0,
		-- 			defaultDuration = 180.0,
		-- 		}),
		-- 	},
		-- }),
	},
})
