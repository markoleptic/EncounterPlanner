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
---@class EventTrigger
local EventTrigger = Private.classes.EventTrigger

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
			abilities = {
				[438471] = BossAbility:New({ -- Voracious Bite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.59 },
							repeatInterval = { 14.52, 25.68 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[438473] = BossAbility:New({ -- Gossamer Onslaught
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.50 },
							repeatInterval = { 39.99 },
						}),
					},
					duration = 5.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[438476] = BossAbility:New({ -- Alerting Shrill
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.30 },
							repeatInterval = { 39.99 },
						}),
					},
					duration = 5.0,
					castTime = 4.0,
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
			abilities = {
				[433740] = BossAbility:New({ -- Infestation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.01, 10.69, 12.37, 14.96, 8.48, 8.51 },
						}),
					},
					eventTriggers = {
						[434408] = EventTrigger:New({ -- Eye of the Swarm (channeled buff)
							combatLogEventType = "SAR",
							castTimes = { 0.48, 10.88, 12.20, 10.79, 20.82, 8.53, 7.34 },
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[433766] = BossAbility:New({ -- Eye of the Swarm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.64 },
							repeatInterval = { 82.53, 82.19 },
						}),
					},
					duration = 0.0,
					castTime = 7.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[434408] = BossAbility:New({ -- Eye of the Swarm (channeled buff)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.02 },
							repeatInterval = { 82.47, 82.14 },
						}),
					},
					duration = 25.0, -- Channel
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[435012] = BossAbility:New({ -- Impale
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0, 14.53, 5.00, 17.23, 8.52, 8.40 },
						}),
					},
					eventTriggers = {
						[434408] = EventTrigger:New({ -- Eye of the Swarm (channeled buff)
							combatLogEventType = "SAR",
							castTimes = { 5.20, 14.87, 4.95, 15.55, 16.52, 10.74, 8.25 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[439506] = BossAbility:New({ -- Burrow Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.49 },
						}),
					},
					eventTriggers = {
						[434408] = EventTrigger:New({ -- Eye of the Swarm (channeled buff)
							combatLogEventType = "SAR",
							castTimes = { 15.41, 30.80 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
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
			abilities = {
				[432117] = BossAbility:New({ -- Cosmic Singularity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.67 },
							repeatInterval = { 47.47 },
						}),
					},
					duration = 0.0,
					castTime = 7.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[432130] = BossAbility:New({ -- Erupting Webs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.76 },
							repeatInterval = { 18.40, 19.49, 18.26, 20.65, 18.27 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[461487] = BossAbility:New({ -- Cultivated Poisons
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.68, 29.39 },
							repeatInterval = { 24.31, 23.14, 23.02, 24.52 },
						}),
					},
					duration = 8.0,
					castTime = 2.0,
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
	},
})
