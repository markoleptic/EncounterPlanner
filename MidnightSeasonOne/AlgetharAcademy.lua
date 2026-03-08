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

Private.dungeonInstances[2526] = DungeonInstance:New({
	journalInstanceID = 1201,
	instanceID = 2526,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Vexamus
			bossIDs = {
				194181, -- Vexamus
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5411] = 194181, -- Vexamus
			},
			journalEncounterID = 2509,
			dungeonEncounterID = 2562,
			instanceID = 2526,
			abilities = {
				[385958] = BossAbility:New({ -- Arcane Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 18.0, 26.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[386173] = BossAbility:New({ -- Mana Bombs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0 },
							repeatInterval = { 18.0, 26.0 },
						}),
					},
					duration = 4.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[387691] = BossAbility:New({ -- Arcane Orbs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.0 },
							repeatInterval = { 18.0, 26.0 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[388537] = BossAbility:New({ -- Arcane Fissure
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.0 },
							repeatInterval = { 44.0 },
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
		Boss:New({ -- Overgrown Ancient
			bossIDs = {
				196482, -- Overgrown Ancient
				196548, -- Ancient Branch
				197398, -- Hungry Lasher
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5420] = 196482, -- Overgrown Ancient
				[5422] = 196548, -- Ancient Branch
				[5425] = 197398, -- Hungry Lasher
			},
			journalEncounterID = 2512,
			dungeonEncounterID = 2563,
			instanceID = 2526,
			abilities = {
				[388544] = BossAbility:New({ -- Barkbreaker
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0 },
							repeatInterval = { 28.0 },
						}),
					},
					duration = 9.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = {},
				}),
				[388623] = BossAbility:New({ -- Branch Out
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = { 56.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[388796] = BossAbility:New({ -- Germinate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.0 },
							repeatInterval = { 33.0, 23.0 },
						}),
					},
					duration = 4.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[388923] = BossAbility:New({ -- Burst Forth
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 55.1 },
							repeatInterval = { 56.0 },
						}),
					},
					duration = 0.0,
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
		Boss:New({ -- Crawth
			bossIDs = { 191736 },
			journalEncounterCreatureIDsToBossIDs = {
				[5370] = 191736, -- Crawth
			},
			journalEncounterID = 2495,
			dungeonEncounterID = 2564,
			instanceID = 2526,
			abilities = {
				[376997] = BossAbility:New({ -- Savage Peck
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 24.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 22.9 },
							repeatInterval = { 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 32.8 },
							repeatInterval = { 24.0 },
						}),
					},
					duration = 10.0,
					castTime = 4.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[377004] = BossAbility:New({ -- Deafening Screech
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.0 },
							repeatInterval = { 24.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 31.8 },
							repeatInterval = { 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 41.8 },
							repeatInterval = { 24.0 },
						}),
					},
					duration = 8.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[377034] = BossAbility:New({ -- Overpowering Gust
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = { 24.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 37.8 },
							repeatInterval = { 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 47.8 },
							repeatInterval = { 24.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1276752] = BossAbility:New({ -- Ruinous Winds
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 20.0,
					allowedCombatLogEventTypes = {},
				}),
				[1285508] = BossAbility:New({ -- Blistering Fire
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 15.9 },
						}),
					},
					duration = 0.0,
					durationLastsUntilEndOfPhase = true,
					castTime = 00.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 48.0,
					defaultDuration = 48.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P2 (75% Health)",
				}),
				[3] = BossPhase:New({
					duration = 72.0,
					defaultDuration = 72.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P3 (45% Health)",
				}),
			},
		}),
		Boss:New({ -- Echo of Doragosa
			bossIDs = { 190609 },
			journalEncounterCreatureIDsToBossIDs = {
				[5423] = 190609, -- Echo of Doragosa
			},
			journalEncounterID = 2514,
			dungeonEncounterID = 2565,
			instanceID = 2526,
			abilities = {
				[374343] = BossAbility:New({ -- Energy Bomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.0 },
							repeatInterval = { 33.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[388822] = BossAbility:New({ -- Power Vacuum
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = { 33.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[439488] = BossAbility:New({ -- Unleash Energy
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
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
	},
})
