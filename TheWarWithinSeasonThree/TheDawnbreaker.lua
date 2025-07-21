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
			preferredCombatLogEventAbilities = {
				[2] = { combatLogEventSpellID = 451026, combatLogEventType = "SCC" },
			},
			abilities = {
				[451026] = BossAbility:New({ -- Darkness Comes (Cast) (50%, 1%)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 90.0 },
							signifiesPhaseEnd = true,
						}),
					},
					durationLastsUntilEndOfPhase = true, -- TODO: Force offset from end of phase
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[453859] = BossAbility:New({ -- Darkness Comes (Buff) (50%, 1%)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 90.0 },
						}),
					},
					durationLastsUntilEndOfPhase = true,
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
					defaultHidden = true,
				}),
				[426734] = BossAbility:New({ -- Burning Shadows
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.56, 16.24, 22.42, 25.40, 28.26 },
							repeatInterval = { 28.26 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 14.3, 19.80, 22.67, 22.73, 25.36, 27.92, 14.56 },
							repeatInterval = { 19.80, 22.67, 22.73, 25.36, 27.92, 14.56 },
						}),
					},
					duration = 15.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[453140] = BossAbility:New({ -- Collapsing Night
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.7, 28.33, 25.41, 28.26 },
							repeatInterval = { 28.26 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 8.76, 29.05, 25.35, 25.36, 28.02, 25.29 },
							repeatInterval = { 29.05, 25.35, 25.36, 28.02, 25.29 },
						}),
					},
					duration = 00.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[453212] = BossAbility:New({ -- Obsidian Beam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.49, 32.45, 25.38, 28.29 },
							repeatInterval = { 28.29 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 18.26, 25.10, 25.35, 25.37, 27.92, 29.07 },
							repeatInterval = { 29.07 },
						}),
					},
					duration = 7.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P2 (50% Health)",
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
			abilities = {
				[426787] = BossAbility:New({ -- Shadowy Decay
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.1, 34.57, 43.59, 41.59, 34.56, 43.50 },
							repeatInterval = { 34.57, 43.59, 41.59, 34.56, 43.50 },
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[426860] = BossAbility:New({ -- Dark Orb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.06, 34.57, 27.05, 23.55, 34.57, 27.08, 34.62, 17.86 },
							repeatInterval = { 27.05, 23.55, 34.57, 27.08, 34.62, 17.86 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[427001] = BossAbility:New({ -- Terrifying Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.08, 34.57, 31.15, 30.47, 23.56, 27.03, 34.73 },
							repeatInterval = { 31.15, 30.47, 23.56, 27.03, 34.73 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[452127] = BossAbility:New({ -- Animate Shadows
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 33.11, 46.76, 38.42, 50.58, 38.25 },
							repeatInterval = { 46.76, 38.42, 50.58, 38.25 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
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
			preferredCombatLogEventAbilities = { [2] = { combatLogEventSpellID = 449734, combatLogEventType = "SCS" } },
			abilities = {
				[434407] = BossAbility:New({ -- Rolling Acid
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {
								10.69,
								20.03,
								23.98,
								20.01,
								19.97,
							},
							repeatInterval = { 20.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = {
								9.98,
								37.02,
								39.94,
								40.09,
								30.88,
								42.91,
								36.02,
								33.22,
								37.03,
								38.18,
								39.94,
								41.54,
								35.57,
								31.04,
							},
							repeatInterval = { 40.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[448213] = BossAbility:New({ -- Expel Webs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.67, 20.02, 11.98, 22.04, 9.96, 16.72 },
							repeatInterval = { 16.72 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 28.23, 27.82, 19.61, 19.94, 25.93, 18.30, 28.23 },
							repeatInterval = { 19.61, 19.94, 25.93, 18.30, 28.23 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[448888] = BossAbility:New({ -- Erosive Spray
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.01, 28.00, 32.70 },
							repeatInterval = { 28.00, 32.70 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 35.11, 31.11, 31.78, 32.56, 32.95, 26.88, 31.55, 33.30, 29.59, 31.54 },
							repeatInterval = { 31.55, 33.30, 29.59, 31.54 },
						}),
					},
					duration = 3.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[449734] = BossAbility:New({ -- Acidic Eruption
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[434089] = BossAbility:New({ -- Spinneret's Strands
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 15.86, 36.77, 31.75, 29.18, 32.41, 32.59, 32.68, 33.60, 33.38 },
							repeatInterval = { 32.59, 32.68, 33.60, 33.38 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P2",
				}),
			},
		}),
	},
})
