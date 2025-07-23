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

if not Private.dungeonInstances[2441] then
	Private.dungeonInstances[2441] = DungeonInstance:New({
		journalInstanceID = 1194,
		instanceID = 2441,
		isSplit = true,
		splitDungeonInstances = {},
	})
end

Private.dungeonInstances[2441].splitDungeonInstances[392] = DungeonInstance:New({
	journalInstanceID = 1194,
	instanceID = 2441,
	mapChallengeModeID = 392,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Hylbrande
			bossIDs = {
				175663, -- Hylbrande
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5240] = 175663, -- Hylbrande
				-- [5274] = , -- Vault Purifier
			},
			journalEncounterID = 2448,
			dungeonEncounterID = 2426,
			instanceID = 2441,
			mapChallengeModeID = 392,
			preferredCombatLogEventAbilities = {
				[2] = { combatLogEventSpellID = 346766, combatLogEventType = "SCS" },
				[3] = { combatLogEventSpellID = 346766, combatLogEventType = "SAR" },
				[4] = { combatLogEventSpellID = 346766, combatLogEventType = "SCS" },
				[5] = { combatLogEventSpellID = 346766, combatLogEventType = "SAR" },
			},
			abilities = {
				[346116] = BossAbility:New({ -- Shearing Swings
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.49 },
							repeatInterval = { 10.85, 11.93 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 16.14 },
							repeatInterval = { 11.07, 12.03, 10.94, 12.00 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 16.14 },
							repeatInterval = { 11.07, 12.03, 10.94, 12.00 },
						}),
					},
					duration = 2.6, -- Channeled
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[353312] = BossAbility:New({ -- Purifying Burst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.68 },
							repeatInterval = { 23.60 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 13.68 },
							repeatInterval = { 23.50 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 13.58 },
							repeatInterval = { 23.65 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[347094] = BossAbility:New({ -- Titanic Crash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.67 },
							repeatInterval = { 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 23.41 },
							repeatInterval = { 23.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 23.28 },
							repeatInterval = { 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[346766] = BossAbility:New({ -- Sanitizing Cycle
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					durationLastsUntilEndOfPhase = true,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[181113] = BossAbility:New({ -- Encounter Spawn (Vault Purifier)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.62, 0.00 },
							repeatInterval = { 30.00, 0.00 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 23.37, 0.00 },
							repeatInterval = { 30.00, 0.00 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 23.05, 0.00 },
							repeatInterval = { 30.00, 0.00 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 38.0,
					defaultDuration = 38.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 30.0,
					defaultDuration = 30.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "Int1",
				}),
				[3] = BossPhase:New({
					duration = 68.95,
					defaultDuration = 68.95,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[4] = BossPhase:New({
					duration = 30.0,
					defaultDuration = 30.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "Int2",
				}),
				[5] = BossPhase:New({
					duration = 68.95,
					defaultDuration = 68.95,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Timecap'n Hooktail
			bossIDs = {
				175546, -- Timecap'n Hooktail
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5241] = 175546, -- Timecap'n Hooktail
				-- [5271] = , -- Corsair Brute
			},
			journalEncounterID = 2449,
			dungeonEncounterID = 2419,
			instanceID = 2441,
			mapChallengeModeID = 392,
			preferredCombatLogEventAbilities = {},
			abilities = {
				[347149] = BossAbility:New({ -- Infinite Breath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.04 },
							repeatInterval = { 15.0 },
						}),
					},
					duration = 3.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[1240102] = BossAbility:New({ -- Time Bombs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.4, 28.0, 22.0, 25.0, 15.0 },
							repeatInterval = { 20.0, 25.0, 15.0 },
						}),
					},
					duration = 30.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCS" },
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
		Boss:New({ -- So'leah
			bossIDs = {
				177269, -- So'leah
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5275] = 177269, -- So'leah
			},
			journalEncounterID = 2455,
			dungeonEncounterID = 2442,
			instanceID = 2441,
			mapChallengeModeID = 392,
			preferredCombatLogEventAbilities = {
				[2] = { combatLogEventSpellID = 351086, combatLogEventType = "SAR" },
			},
			abilities = {
				[181089] = BossAbility:New({ -- Encounter Event
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[353635] = BossAbility:New({ -- Collapsing Star
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.49 },
							repeatInterval = { 60.73 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 38.08 },
							repeatInterval = { 75.43 },
						}),
					},
					duration = 30.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[351096] = BossAbility:New({ -- Energy Fragmentation
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 21.03 },
							repeatInterval = { 38.84, 57.27 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[350875] = BossAbility:New({ -- Hyperlight Jolt
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 5.0, 70.0 },
							repeatInterval = { 70.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[351646] = BossAbility:New({ -- Hyperlight Nova
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 41.63 },
							repeatInterval = { 55.38, 38.34 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = {},
				}),
				[350796] = BossAbility:New({ -- Hyperlight Spark
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.74 },
							repeatInterval = { 15.90 },
						}),
					},
					duration = 0.0,
					castTime = 0.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[351086] = BossAbility:New({ -- Power Overwhelming
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = { 75.0 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[351057] = BossAbility:New({ -- Relocation
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Power Overwhelming
							combatLogEventType = "SAR",
							castTimes = { 1.0 },
							repeatInterval = { 21.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[351124] = BossAbility:New({ -- Summon Assassins
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.78, 42.64, 42.33 },
							repeatInterval = { 42.5 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P2",
				}),
			},
		}),
	},
})
