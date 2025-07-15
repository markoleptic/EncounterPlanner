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

Private.dungeonInstances[2649] = DungeonInstance:New({
	journalInstanceID = 1267,
	instanceID = 2649,
	customGroups = { "TheWarWithinSeasonTwo", "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Captain Dailcry
			bossIDs = { 207946 },
			journalEncounterID = 2571,
			dungeonEncounterID = 2847,
			instanceID = 2649,
			abilities = {
				[424419] = BossAbility:New({ -- Battle Cry
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.9, 30.9, 30.4, 31.1 },
							repeatInterval = 30.1,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[447270] = BossAbility:New({ -- Hurl Spear
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.4 },
							repeatInterval = 30.3,
						}),
					},
					duration = 8.0,
					castTime = 2.5,
				}),
				[424414] = BossAbility:New({ -- Pierce Armor
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8, 14.6, 13.4, 19.4, 13.4, 14.6, 13.3 },
							repeatInterval = { 17.0, 13.4 },
						}),
					},
					duration = 10.0,
					castTime = 2.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[447439] = BossAbility:New({ -- Savage Mauling
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.0 },
							repeatInterval = 30.4,
						}),
					},
					duration = 0.0,
					castTime = 30.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[464240] = BossAbility:New({ -- Reflective Shield
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.3, 31.6, 27.9, 32.8, 21.8, 21.8 },
							repeatInterval = 21.8,
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[424420] = BossAbility:New({ -- Cinderblast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.4, 25.5, 19.4 },
							repeatInterval = { 24.3, 30.4, 21.8, 19.4 },
						}),
					},
					duration = 5.0,
					castTime = 4.5,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[424462] = BossAbility:New({ -- Ember Storm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.16 },
							repeatInterval = { 37.61, 36.46, 37.64 },
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[429091] = BossAbility:New({ -- Inner Fire
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 31.5, 27.9, 32.8, 21.8, 21.9, 23.1 },
							repeatInterval = { 32.8, 21.8, 21.9, 23.1 },
						}),
					},
					duration = 10.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
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
		Boss:New({ -- Baron Braunpyke
			bossIDs = { 207939 },
			journalEncounterID = 2570,
			dungeonEncounterID = 2835,
			instanceID = 2649,
			abilities = {
				[422969] = BossAbility:New({ -- Vindictive Wrath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.2 },
							repeatInterval = 48.1,
						}),
					},
					duration = 20.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[423015] = BossAbility:New({ -- Castigator's Shield
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.7, 60.7 }, -- Not sure on repeat of this
							repeatInterval = 30.4,
						}),
					},
					duration = 5.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[423051] = BossAbility:New({ -- Burning Light
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.5 },
							repeatInterval = 40.1,
						}),
					},
					duration = 12.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[423062] = BossAbility:New({ -- Hammer of Purity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.6 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[446368] = BossAbility:New({ -- Sacrificial Pyre
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.4 },
							repeatInterval = 38.8,
						}),
					},
					duration = 12.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
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
		Boss:New({ -- Prioress Murrpray
			bossIDs = { 207940 },
			journalEncounterID = 2573,
			dungeonEncounterID = 2848,
			instanceID = 2649,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 423588, combatLogEventType = "SAA" },
				[3] = { combatLogEventSpellID = 423588, combatLogEventType = "SAR" },
			},
			abilities = {
				[423588] = BossAbility:New({ -- Barrier of Light
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[423664] = BossAbility:New({ -- Embrace the Light
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[444546] = BossAbility:New({ -- Purify
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.1 },
							repeatInterval = 28.8,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 6.3 },
							repeatInterval = 28.8,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[444608] = BossAbility:New({ -- Inner Fire
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.8 },
							repeatInterval = 24.3,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 6.4 },
							repeatInterval = 24.3,
						}),
					},
					duration = 5.2,
					castTime = 2.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[451605] = BossAbility:New({ -- Holy Flame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.3 },
							repeatInterval = 12.1,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 12.3 },
							repeatInterval = 12.1,
						}),
					},
					duration = 1.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[428169] = BossAbility:New({ -- Blinding Light
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.5 },
							repeatInterval = 24.2,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = 24.2,
						}),
					},
					duration = 4.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 70.0,
					defaultDuration = 70.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 40.0,
					defaultDuration = 40.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 70.0,
					defaultDuration = 70.0,
					count = 1,
					defaultCount = 1,
					name = "P3",
					fixedCount = true,
				}),
			},
		}),
	},
})
