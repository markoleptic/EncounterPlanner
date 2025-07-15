local _, Namespace = ...

---@class Private
local Private = Namespace
---@class EventTrigger
local EventTrigger = Private.classes.EventTrigger
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

Private.dungeonInstances[1594] = DungeonInstance:New({
	journalInstanceID = 1012,
	instanceID = 1594,
	customGroups = { "TheWarWithinSeasonTwo" },
	bosses = {
		Boss:New({ -- Crowd Pummeler
			bossIDs = { 129214 },
			journalEncounterID = 2109,
			dungeonEncounterID = 2105,
			instanceID = 1594,
			abilities = {
				[269493] = BossAbility:New({ -- Footbomb Launcher
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.1, 48.1 },
							repeatInterval = 43.7,
						}),
					},
					duration = 15.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[271903] = BossAbility:New({ -- Coin Magnet
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.0 },
							repeatInterval = 43.7,
						}),
					},
					duration = 4.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[262347] = BossAbility:New({ -- Static Pulse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.4, 48.1 },
							repeatInterval = 43.7,
						}),
					},
					duration = 2.5,
					castTime = 8.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1217294] = BossAbility:New({ -- Shocking Claw
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0, 48.6 },
							repeatInterval = 43.7,
						}),
					},
					duration = 3.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[271784] = BossAbility:New({ -- Throw Coins
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.5, 2.0, 2.0, 2.0, 2.0 },
							repeatInterval = { 41.3, 2.0, 2.0, 2.0, 2.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- Unreliable cast amounts
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
		Boss:New({ -- Azerokk
			bossIDs = {
				129227, -- Azerokk
				129802, -- Earthrager
			},
			journalEncounterID = 2114,
			dungeonEncounterID = 2106,
			instanceID = 1594,
			abilities = {
				[271698] = BossAbility:New({ -- Azerite Infusion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1 },
							repeatInterval = 42.5,
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[258622] = BossAbility:New({ -- Resonant Quake
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.3 },
							repeatInterval = 42.5,
						}),
					},
					duration = 6.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[257593] = BossAbility:New({ -- Call Earthrager
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.4 },
							repeatInterval = 42.1,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[275907] = BossAbility:New({ -- Tectonic Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.7 },
							repeatInterval = { 15.8, 26.7 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
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
		Boss:New({ -- Rixxa Fluxflame
			bossIDs = { 129231 },
			journalEncounterID = 2115,
			dungeonEncounterID = 2107,
			instanceID = 1594,
			abilities = {
				[275992] = BossAbility:New({ -- Gushing Catalyst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0 },
							repeatInterval = { 53.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[270042] = BossAbility:New({ -- Azerite Catalyst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.5 },
							repeatInterval = { 53.0 },
						}),
					},
					duration = 3.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[259940] = BossAbility:New({ -- Propellant Blast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.4, 11.0, 11.0 },
							repeatInterval = { 31.0, 11.0, 11.0 },
						}),
					},
					duration = 4.0,
					castTime = 3.5,
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
		Boss:New({ -- Mogul Razdunk
			bossIDs = { 129232 },
			journalEncounterID = 2116,
			dungeonEncounterID = 2108,
			instanceID = 1594,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 260189, combatLogEventType = "SCC" },
				[3] = { combatLogEventSpellID = 260190, combatLogEventType = "SCC" },
			},
			abilities = {
				[260280] = BossAbility:New({ -- Gatling Gun
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = 30.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 17.1 },
							repeatInterval = { 20.0, 25.0 },
						}),
					},
					duration = 8.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[260829] = BossAbility:New({ -- Homing Missile
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 30.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 7.1 },
							repeatInterval = { 21.0, 24.0 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[276229] = BossAbility:New({ -- Micro Missiles
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = 30.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 11.8 },
							repeatInterval = 19.4, -- Inconsistent
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
					buffer = 1.0,
				}),
				[271456] = BossAbility:New({ -- Drill Smash
					eventTriggers = {
						[260189] = EventTrigger:New({ -- Configuration: Drill
							combatLogEventType = "SCC",
							castTimes = { 17.5, 11.0, 11.0, 11.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[260189] = BossAbility:New({ -- Configuration: Drill
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[260190] = BossAbility:New({ -- Configuration: Combat
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					name = "P1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					name = "P2",
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					name = "P1",
					fixedCount = true,
				}),
			},
		}),
	},
})
