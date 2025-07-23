local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
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

if not Private.dungeonInstances[2441] then
	Private.dungeonInstances[2441] = DungeonInstance:New({
		journalInstanceID = 1194,
		instanceID = 2441,
		isSplit = true,
		splitDungeonInstances = {},
	})
end

Private.dungeonInstances[2441].splitDungeonInstances[391] = DungeonInstance:New({
	journalInstanceID = 1194,
	instanceID = 2441,
	mapChallengeModeID = 391,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Zo'phex the Sentinel
			bossIDs = {
				175616, -- Zo'phex
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5236] = 175616, -- Zo'phex
			},
			journalEncounterID = 2437,
			dungeonEncounterID = 2425,
			instanceID = 2441,
			mapChallengeModeID = 391,
			abilities = {
				[346006] = BossAbility:New({ -- Impound Contraband
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[346204] = BossAbility:New({ -- Armed Security
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 1.5,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[348350] = BossAbility:New({ -- Interrogation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {},
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[348128] = BossAbility:New({ -- Fully Armed
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1236348] = BossAbility:New({ -- Charged Slash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
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
		Boss:New({ -- The Grand Menagerie
			bossIDs = {
				176556, -- Alcruux
				176555, -- Achillite
				176705, -- Venza Goldfuse
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6009] = 176556, -- Alcruux
				[5249] = 176555, -- Achillite
				[5251] = 176705, -- Venza Goldfuse
			},
			journalEncounterID = 2454,
			dungeonEncounterID = 2441,
			instanceID = 2441,
			mapChallengeModeID = 391,
			preferredCombatLogEventAbilities = {
				[2] = { combatLogEventSpellID = 181089, combatLogEventType = "SCC" },
				[3] = { combatLogEventSpellID = 181089, combatLogEventType = "SCC" },
			},
			abilities = {
				[181089] = BossAbility:New({ -- Encounter Event
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[349663] = BossAbility:New({ -- Grip of Hunger
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.87 },
							repeatInterval = { 23.04, 29.36 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[349797] = BossAbility:New({ -- Grand Consumption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.60 },
							repeatInterval = { 30.32 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[349954] = BossAbility:New({ -- Purification Protocol
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 4.64 },
							repeatInterval = { 24.46, 26.61 },
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[349934] = BossAbility:New({ -- Flagellation Protocol
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 14.56 },
							repeatInterval = { 22.99, 23.02, 25.31 },
						}),
					},
					duration = 5.0,
					castTime = 1.0,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[349987] = BossAbility:New({ -- Venting Protocol
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 21.70 },
							repeatInterval = { 26.72, 26.63, 28.43 },
						}),
					},
					duration = 4.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[350101] = BossAbility:New({ -- Chains of Damnation
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 5.02, 21.97, 29.78 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[350086] = BossAbility:New({ -- Whirling Annihilation
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 16.59, 30.42, 30.35 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 40.0,
					defaultDuration = 40.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 70.0,
					defaultDuration = 70.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P2",
				}),
				[3] = BossPhase:New({
					duration = 70.0,
					defaultDuration = 70.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P3",
				}),
			},
			customSpells = { [181089] = {
				iconID = 136051,
				text = L["Boss Spawn"],
			} },
		}),
		Boss:New({ -- Mailroom Mayhem
			bossIDs = {
				175646, -- P.O.S.T. Master
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5276] = 175646, -- P.O.S.T. Master
			},
			journalEncounterID = 2436,
			dungeonEncounterID = 2424,
			instanceID = 2441,
			mapChallengeModeID = 391,
			preferredCombatLogEventAbilities = {},
			abilities = {
				[346286] = BossAbility:New({ -- Hazardous Liquids
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.98, 43.25, 43.72, 43.64, 43.40 },
							repeatInterval = { 43.40 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[346742] = BossAbility:New({ -- Fan Mail
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.88, 43.04, 43.74, 43.56, 43.72 },
							repeatInterval = { 43.40 },
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[346947] = BossAbility:New({ -- Unstable Goods
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.88, 43.04, 43.74, 43.56, 43.72 },
							repeatInterval = { 43.40 },
						}),
					},
					duration = 30.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[346962] = BossAbility:New({ -- Money Order
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.27, 42.97, 43.78, 43.61, 43.58 },
							repeatInterval = { 43.40 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC" },
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
		Boss:New({ -- Myza's Oasis
			bossIDs = {
				176564, -- Zo'gron
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5277] = 176564, -- Zo'gron
				[5290] = 176564, -- Brawling Patron
				[5291] = 176564, -- Disruptive Patron
				[5289] = 176564, -- Oasis Security
			},
			journalEncounterID = 2452,
			dungeonEncounterID = 2440,
			instanceID = 2441,
			mapChallengeModeID = 391,
			preferredCombatLogEventAbilities = {
				[2] = { combatLogEventSpellID = 181089, combatLogEventType = "SCC" },
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
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[359028] = BossAbility:New({ -- Security Slam
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 8.51, 47.09, 43.48 },
							repeatInterval = { 43.48 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[350919] = BossAbility:New({ -- Crowd Control
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 38.38, 37.77, 24.70 },
							repeatInterval = { 30.07 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[1241023] = BossAbility:New({ -- Final Warning (66%, 33%)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 24.79, 40.10 },
						}),
					},
					duration = 20.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SAA", "SAR" },
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
					name = "P2",
				}),
			},
			customSpells = { [181089] = {
				iconID = 136051,
				text = L["Boss Spawn"],
			} },
		}),
		Boss:New({ -- So'azmi
			bossIDs = {
				175806, -- So'azmi
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5278] = 175806, -- So'azmi
			},
			journalEncounterID = 2451,
			dungeonEncounterID = 2437,
			instanceID = 2441,
			mapChallengeModeID = 391,
			abilities = {
				[1248209] = BossAbility:New({ -- Phase Slash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.41, 17.91, 18.22, 24.55 },
							repeatInterval = { 18.84, 17.44, 23.05 },
						}),
					},
					duration = 8.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1245579] = BossAbility:New({ -- Shuri
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.59, 22.32, 37.50, 22.77, 37.02, 21.09 },
							repeatInterval = { 37.50, 22.77 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCS" },
				}),
				[1245634] = BossAbility:New({ -- Divide (70%, 40%)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 29.69, 52.17 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCS" },
				}),
				[1245669] = BossAbility:New({ -- Double Technique
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 50.46, 5.49, 52.47, 6.99, 54.52, 6.22, 51.98, 8.96 },
							repeatInterval = { 52.0, 6.5 },
						}),
					},
					halfHeight = true,
					duration = 0.0,
					castTime = 15.0,
					allowedCombatLogEventTypes = { "SCS" },
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
	executeAndNil = function()
		local instance = Private.dungeonInstances[2441].splitDungeonInstances[391]
		EJ_SelectInstance(instance.journalInstanceID)
		local grandMenagerie = instance.bosses[2]
		local journalEncounterID = grandMenagerie.journalEncounterID
		EJ_SelectEncounter(journalEncounterID)
		local phases = grandMenagerie.phases
		for i = 1, 3 do
			local _, bossName, _, _, _, _ = EJ_GetCreatureInfo(i, journalEncounterID)
			phases[i].name = string.format("P%d (%s)", i, bossName)
		end

		local oasis = instance.bosses[4]
		journalEncounterID = oasis.journalEncounterID
		EJ_SelectEncounter(journalEncounterID)
		local _, bossName, _, _, _, _ = EJ_GetCreatureInfo(1, journalEncounterID)
		oasis.phases[2].name = string.format("P%d (%s)", 2, bossName)
	end,
})
