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

Private.dungeonInstances[2648] = DungeonInstance:New({
	journalInstanceID = 1268,
	instanceID = 2648,
	customGroups = { "TheWarWithinSeasonTwo" },
	bosses = {
		Boss:New({ -- Kyrioss
			bossIDs = { 209230 },
			journalEncounterID = 2566,
			dungeonEncounterID = 2816,
			instanceID = 2648,
			abilities = {
				[1214315] = BossAbility:New({ -- Lightning Torrent
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.0 },
							repeatInterval = 55.9,
						}),
					},
					duration = 15.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1214325] = BossAbility:New({ -- Crashing Thunder
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1, 42.5 },
							repeatInterval = { 15.8, 40.1 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[474018] = BossAbility:New({ -- Wild Lightning
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.7, 41.3 },
							repeatInterval = { 15.8, 40.1 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[419870] = BossAbility:New({ -- Lightning Dash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.5 },
							repeatInterval = 55.9,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Stormguard Gorren
			bossIDs = { 207205 },
			journalEncounterID = 2567,
			dungeonEncounterID = 2861,
			instanceID = 2648,
			abilities = {
				[424737] = BossAbility:New({ -- Chaotic Corruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8, 36.4, 36.4 },
							repeatInterval = 33.2,
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[425048] = BossAbility:New({ -- Dark Gravity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.8 },
							repeatInterval = 32.8,
						}),
					},
					duration = 6.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[424958] = BossAbility:New({ -- Crush Reality
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.5 },
							repeatInterval = { 20.6, 20.6, 24.3 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Voidstone Monstrosity
			bossIDs = { 207207 },
			journalEncounterID = 2568,
			dungeonEncounterID = 2836,
			instanceID = 2648,
			preferredCombatLogEventAbilities = {
				[1] = { combatLogEventSpellID = 423839, combatLogEventType = "SAR" },
				[2] = { combatLogEventSpellID = 423839, combatLogEventType = "SAA" },
			},
			abilities = {
				[423305] = BossAbility:New({ -- Null Upheaval
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.7 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[445262] = BossAbility:New({ -- Void Shell
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
					durationLastsUntilEndOfPhase = true,
				}),
				[429487] = BossAbility:New({ -- Unleash Corruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.6 },
							repeatInterval = 17.0,
						}),
					},
					duration = 15.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {}, -- Unreliable cast counts
				}),
				[445457] = BossAbility:New({ -- Oblivion Wave
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8, 13.4, 13.4 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[458082] = BossAbility:New({ -- Stormrider's Charge (Stormrider Vokmar)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.8 },
							repeatInterval = 32.8,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
					buffer = 1.0,
				}),
				[423839] = BossAbility:New({ -- Storm's Vengeance
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 4.5 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 20.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					name = "P1",
					count = 3,
					defaultCount = 3,
					repeatAfter = 2,
				}),
				[2] = BossPhase:New({
					duration = 24.5,
					defaultDuration = 24.5,
					name = "P2",
					count = 3,
					defaultCount = 3,
					fixedDuration = true,
					repeatAfter = 1,
				}),
			},
		}),
	},
})
