local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
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

local gallywixEnergyChargeTime = 90.0

Private.dungeonInstances[2769] = DungeonInstance:New({
	journalInstanceID = 1296,
	instanceID = 2769,
	bosses = {
		Boss:New({ -- Vexie and the Geargrinders
			bossIDs = {
				225821, -- The Geargrinder
			},
			journalEncounterID = 2639,
			dungeonEncounterID = 3009,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 460603, combatLogEventType = "SCC" },
				[3] = { combatLogEventSpellID = 460116, combatLogEventType = "SAR" },
			},
			abilities = {
				[466615] = BossAbility:New({ -- Protective Plating
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 3.5 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" }, -- Stacking buff, instant cast on first application
				}),
				[471403] = BossAbility:New({ -- Unrelenting CAR-nage
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 121.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 121.0 },
						}),
					},
					duration = 30.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {}, -- May or may not happen
				}),
				[459943] = BossAbility:New({ -- Call Bikers
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.4, 28.2, 28.2, 28.2 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 24.2, 28.2, 28.2, 28.2 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[459671] = BossAbility:New({ -- Spew Oil
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.5, 41.3, 41.3 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 12.2, 20.7, 20.7, 20.7, 20.7, 20.7 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[468487] = BossAbility:New({ -- Incendiary Fire
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.7, 25.6, 25.6, 25.6 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 25.7, 35.0, 35.0 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[459627] = BossAbility:New({ -- Tank Buster
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.05, 23.3, 27.2, 21.9, 21.9 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 10.3, 17.4, 16.6, 19.9, 21.8, 21.9 },
						}),
					},
					duration = 25.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					halfHeight = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[468149] = BossAbility:New({ -- Exhaust Fumes (DPS / Healers)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.0, 23.3, 23.3, 23.3, 23.3 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 12.0, 19.5, 19.5, 19.5, 19.5, 19.5 },
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Stacking buff, no cast
				}),
				[460116] = BossAbility:New({ -- Tune-Up
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 45.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[460603] = BossAbility:New({ -- Mechanical Breakdown
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 125.0 },
							signifiesPhaseEnd = true,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 125.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" }, -- Inconsistent/spam SAA/SAR
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 129.0,
					defaultDuration = 129.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 45.0,
					defaultDuration = 45.0,
					count = 2,
					defaultCount = 2,
					name = "P2",
					repeatAfter = 3,
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 129.0,
					defaultDuration = 129.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
				}),
			},
		}),
		Boss:New({ -- Cauldron of Carnage
			bossIDs = {
				229181, -- Flarendo
				229177, -- Torq
			},
			journalEncounterID = 2640,
			dungeonEncounterID = 3010,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 465872, combatLogEventType = "SCS" },
				[3] = { combatLogEventSpellID = 465872, combatLogEventType = "SAR" },
			},
			abilities = {
				[465872] = BossAbility:New({ -- Colossal Clash (Torq)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 20.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[465863] = BossAbility:New({ -- Colossal Clash (Flarendo)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 20.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[472222] = BossAbility:New({ -- Blistering Spite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Spell Aura Refresh not implemented
					defaultHidden = true,
				}),
				[472225] = BossAbility:New({ -- Galvanized Spite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Spell Aura Refresh not implemented
					defaultHidden = true,
				}),
				[473650] = BossAbility:New({ -- Scrapbomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 24.0, 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 9.0, 24.0, 23.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[472233] = BossAbility:New({ -- Blastburn Roarcannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0, 24.0, 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.0, 24.0, 23.0 },
						}),
					},
					duration = 3.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1213690] = BossAbility:New({ -- Molten Phlegm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.6, 27.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 24.6, 27.4 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- No cast, only applies debuffs
				}),
				[1214190] = BossAbility:New({ -- Eruption Stomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 27.0, 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 27.0, 24.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					onlyRelevantForTanks = true, -- Also affects players
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[474159] = BossAbility:New({ -- Static Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 6.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[463900] = BossAbility:New({ -- Thunderdrum Salvo
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 10.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 8.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1213994] = BossAbility:New({ -- Voltaic Image
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0 },
						}),
					},
					duration = 12.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[466178] = BossAbility:New({ -- Lightning Bash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 21.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 95.0,
					defaultDuration = 95.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 20.0,
					defaultDuration = 20.0,
					count = 3,
					defaultCount = 3,
					name = "P2",
					repeatAfter = 3,
					fixedDuration = true,
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 95.0,
					defaultDuration = 95.0,
					count = 3,
					defaultCount = 3,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
					fixedCount = true,
				}),
			},
		}),
		Boss:New({ -- Rik Reverb
			bossIDss = {
				228648, -- Rik
			},
			journalEncounterID = 2641,
			dungeonEncounterID = 3011,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 464584, combatLogEventType = "SAA" },
				[3] = { combatLogEventSpellID = 464584, combatLogEventType = "SAR" },
			},
			abilities = {
				[473748] = BossAbility:New({ -- Amplification!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.8, 39.0, 39.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 10.8, 39.0, 39.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.3,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466866] = BossAbility:New({ -- Echoing Chant
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0, 29.0, 57.5 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 22.0, 29.0, 57.5 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[467606] = BossAbility:New({ -- Sound Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0, 37.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0, 37.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464584] = BossAbility:New({ -- Sound Cloud
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
							phaseOccurrences = { [1] = true, [2] = true },
						}),
					},
					duration = 28.0,
					castTime = 0.0, -- 5.0 sec but is casted in previous phase
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[466979] = BossAbility:New({ -- Faulty Zap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.5, 34.5, 26.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 40.5, 34.5, 26.0 },
						}),
					},
					duration = 12.0,
					castTime = 2.125,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[472306] = BossAbility:New({ -- Sparkblast Ignition (Pyrotechnics)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.8, 82.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 20.8, 82.4 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Don't see in PTR logs
				}),
				[472293] = BossAbility:New({ -- Grand Finale (death of Pyrotechnics)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.8, 82.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 20.8, 82.4 },
						}),
					},
					duration = 14.5,
					castTime = 0.5,
					allowedCombatLogEventTypes = {}, -- 5 simultaneous casts
				}),
				[473260] = BossAbility:New({ -- Blaring Drop
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.2, 7.0, 7.0, 7.0 },
						}),
					},
					duration = 3.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[473655] = BossAbility:New({ -- Hype Fever!
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							phaseOccurrences = { [3] = true },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 121.0,
					defaultDuration = 121.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 28.0,
					defaultDuration = 28.0,
					count = 3,
					defaultCount = 3,
					name = "P2",
					repeatAfter = 3,
					fixedDuration = true,
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 121.0,
					defaultDuration = 121.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
					fixedCount = true,
				}),
			},
		}),
		Boss:New({ -- Stix Bunkjunker
			bossIDss = {
				230322, -- Stix
			},
			journalEncounterID = 2642,
			dungeonEncounterID = 3012,
			instanceID = 2769,
			abilities = {
				[464399] = BossAbility:New({ -- Electromagnetic Sorting
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.3, 80.2 },
							repeatInterval = 51.1,
						}),
					},
					duration = 5.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[464149] = BossAbility:New({ -- Incinerator
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.1, 25.0, 25.0, 29.1 },
							repeatInterval = 25.55,
						}),
					},
					duration = 4.5,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[464112] = BossAbility:New({ -- Demolish
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.8, 80.2, 51.1 },
							repeatInterval = 51.1,
						}),
					},
					duration = 50.0,
					castTime = 0.0,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1217954] = BossAbility:New({ -- Meltdown
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 44.5, 80.2, 51.1 },
							repeatInterval = 51.1,
						}),
					},
					duration = 3.0,
					castTime = 1.0,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[467117] = BossAbility:New({ -- Overdrive
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 66.7 },
						}),
					},
					duration = 9.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 480.0,
					defaultDuration = 480.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Sprocketmonger Lockenstock
			bossIDs = {
				230583, -- Sprocketmonger
			},
			journalEncounterID = 2653,
			dungeonEncounterID = 3013,
			instanceID = 2769,
			-- No preferred combat log events bc everything is time-based
			abilities = {
				[473276] = BossAbility:New({ -- Activate Inventions!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0, 30.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0, 30.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1216414] = BossAbility:New({ -- Blazing Beam
					eventTriggers = {
						[473276] = EventTrigger:New({ -- Activate Inventions!
							combatLogEventType = "SCS",
							castTimes = { 2.0 },
							phaseOccurrences = {
								[1] = { [1] = true },
							},
						}),
					},
					duration = 5.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- Spam
				}),
				[1216674] = BossAbility:New({ -- Jumbo Void Beam
					eventTriggers = {
						[473276] = EventTrigger:New({ -- Activate Inventions!
							combatLogEventType = "SCS",
							castTimes = { 2.0 },
							phaseOccurrences = {
								[3] = {
									[1] = true,
									[2] = true,
									[3] = true,
									[4] = true,
									[5] = true,
									[6] = true,
									[7] = true,
									[8] = true,
								},
							},
						}),
					},
					duration = 6.5,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- Spam
				}),
				[1216525] = BossAbility:New({ -- Rocket Barrage
					eventTriggers = {
						[473276] = EventTrigger:New({ -- Activate Inventions!
							combatLogEventType = "SCS",
							castTimes = { 2.0 },
							phaseOccurrences = { [1] = { [1] = true }, [3] = { [1] = true } },
							cast = function(spellCount)
								return (spellCount - 1) % 3 ~= 0
							end,
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- Spam
				}),
				[1216699] = BossAbility:New({ -- Void Barrage
					eventTriggers = {
						[473276] = EventTrigger:New({ -- Activate Inventions!
							combatLogEventType = "SCS",
							castTimes = { 2.0 },
							phaseOccurrences = {
								[3] = {
									[2] = true,
									[3] = true,
									[4] = true,
									[5] = true,
									[6] = true,
									[7] = true,
									[8] = true,
								},
							},
							cast = function(spellCount)
								return (spellCount - 1) % 3 ~= 0
							end,
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- Spam
				}),
				[466765] = BossAbility:New({ -- Beta Launch
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 121.8 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 121.8 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466860] = BossAbility:New({ -- Bleeding Edge
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 20.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1218319] = BossAbility:New({ -- Voidsplosion
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 1.0, 5.0, 5.0, 5.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- No logged casts
				}),
				[1214872] = BossAbility:New({ -- Pyro Party Pack
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.0, 33.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 23.0, 33.0, 30.0 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					onlyRelevantForTanks = true, -- Also relevant for everyone else
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465232] = BossAbility:New({ -- Sonic Ba-Boom
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 25.0, 27.0, 32.0, 18.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 9.0, 25.0, 27.0, 32.0, 18.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1217231] = BossAbility:New({ -- Foot-Blasters
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0, 33.0, 30.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 12.0, 33.0, 30.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1218418] = BossAbility:New({ -- Wire Transfer
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0, 41.0, 60.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0, 41.0, 60.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1217355] = BossAbility:New({ -- Polarization Generator
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.0, 67.0, 43.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 4.0, 67.0, 43.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1216509] = BossAbility:New({ -- Screw Up
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.0, 30.0, 32.0, 27.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 18.0, 30.0, 32.0, 27.0 },
						}),
					},
					duration = 4.5,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1218344] = BossAbility:New({ -- Upgraded Bloodtech
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Stacking buff, no casts
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 126.6,
					defaultDuration = 126.6,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 20.0,
					defaultDuration = 20.0,
					count = 3,
					defaultCount = 3,
					fixedDuration = true,
					name = "P2",
					repeatAfter = 3,
				}),
				[3] = BossPhase:New({
					duration = 126.6,
					defaultDuration = 126.6,
					count = 3,
					defaultCount = 3,
					name = "P1",
					fixedDuration = true,
					repeatAfter = 2,
				}),
			},
		}),
		Boss:New({ -- The One-Armed Bandit
			bossIDs = {
				228458, -- Bandit
			},
			journalEncounterID = 2644,
			dungeonEncounterID = 3014,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 465761, combatLogEventType = "SCS" },
			},
			abilities = {
				[460181] = BossAbility:New({ -- Pay-Line
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 3.3, 26.7, 40.1, 34.0, 25.9, 24.3, 26.7 },
							repeatInterval = 26.7,
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 7.0, 31.7, 29.2 }, -- Heroic timers
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[460444] = BossAbility:New({ -- High Roller!
					eventTriggers = {
						[460181] = EventTrigger:New({ -- Pay-Line
							combatLogEventType = "SCS",
							castTimes = { 2.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- Buff that players can get
					defaultHidden = true,
				}),
				[469993] = BossAbility:New({ -- Foul Exhaust
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Mildly inconsistent
							castTimes = { 8.2, 34.0, 15.8, 31.6, 19.4, 32.8, 18.2, 32.8 },
							repeatInterval = { 18.2, 32.8 },
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 1.1, 25.7, 25.7, 25.7 }, -- Heroic timers
						}),
					},
					duration = 1.5,
					castTime = 0.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[460472] = BossAbility:New({ -- The Big Hit
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 17.9, 18.2, 39.0, 20.6, 19.4, 20.6 },
							repeatInterval = { 39.0, 20.6, 19.4, 20.6 },
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 11.0, 19.4, 19.4, 19.4 },
						}),
					},
					duration = 30.0,
					castTime = 2.5,
					halfHeight = true,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[461060] = BossAbility:New({ -- Spin To Win!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.2, 53.0, 53.0, 53.0, 53.0, 53.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465761] = BossAbility:New({ -- Rig the Game!
					phases = {
						[2] = BossAbilityPhase:New({ -- Cast completion triggers phase change
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0, -- Actually 4s cast
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465309] = BossAbility:New({ -- Cheat to Win!
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 1.3, 25.7, 24.4, 27.8 }, -- Heroic timers
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[465432] = BossAbility:New({ -- Linked Machines
					eventTriggers = {
						[465309] = EventTrigger:New({ -- Cheat to Win!
							combatLogEventType = "SCC",
							combatLogEventSpellCount = 1,
							castTimes = { 0.3 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465322] = BossAbility:New({ -- Hot Hot Heat
					eventTriggers = {
						[465309] = EventTrigger:New({ -- Cheat to Win!
							combatLogEventType = "SCC",
							combatLogEventSpellCount = 2,
							castTimes = { 0.3 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465580] = BossAbility:New({ -- Scattered Payout
					eventTriggers = {
						[465309] = EventTrigger:New({ -- Cheat to Win!
							combatLogEventType = "SCC",
							combatLogEventSpellCount = 3,
							castTimes = { 0.3 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[465587] = BossAbility:New({ -- Explosive Jackpot
					eventTriggers = {
						[465309] = EventTrigger:New({ -- Cheat to Win!
							combatLogEventType = "SCC",
							combatLogEventSpellCount = 4,
							castTimes = { 0.3 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 10.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[464772] = BossAbility:New({ -- Reward: Shock and Flame
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 1,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464801] = BossAbility:New({ -- Reward: Shock and Bomb
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 2,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464804] = BossAbility:New({ -- Reward: Flame and Bomb
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 3,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464806] = BossAbility:New({ -- Reward: Flame and Coin
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 4,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464809] = BossAbility:New({ -- Reward: Coin and Shock
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 5,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[464810] = BossAbility:New({ -- Reward: Coin and Bomb
					eventTriggers = {
						[461060] = EventTrigger:New({ -- Spin to Win!
							combatLogEventType = "SCS",
							combatLogEventSpellCount = 6,
							castTimes = { 30.0 }, -- Estimate, could vary depending on depositing
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({ -- TODO: Not sure what actual mythic duration is
					duration = 93.0,
					defaultDuration = 93.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					fixedDuration = true,
					name = "P2 (30%)",
				}),
			},
		}),
		Boss:New({ -- Mug'Zee, Heads of Security
			bossIDs = {
				229953, -- Mug'Zee
			},
			journalEncounterID = 2645,
			dungeonEncounterID = 3015,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 1222408, combatLogEventType = "SAA" },
			},
			abilities = {
				[466459] = BossAbility:New({ -- Head Honcho: Mug
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 120.0,
						}),
					},
					duration = 60.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[468658] = BossAbility:New({ -- Elemental Carnage (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 0.1 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 0.1 },
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[472631] = BossAbility:New({ -- Earthshaker Gaol (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 17.4 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 17.4 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 4.5, -- Targeting duration
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCC" }, -- This is the spell that targets, 474461 casts it
				}),
				[466470] = BossAbility:New({ -- Frostshatter Boots (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 34.8 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 34.8 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466509] = BossAbility:New({ -- Stormfury Finger Gun (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 50.0 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 34.8 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 4.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466518] = BossAbility:New({ -- Molten Gold Knuckles (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 30.3 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 30.3 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466460] = BossAbility:New({ -- Head Honcho: Zee
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.0 },
							repeatInterval = 120.0,
						}),
					},
					duration = 60.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[468694] = BossAbility:New({ -- Uncontrolled Destruction (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 0.1 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 0.1 },
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" }, -- Instant cast
				}),
				[472458] = BossAbility:New({ -- Unstable Crawler Mines (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 14.0 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 14.0 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[467380] = BossAbility:New({ -- Goblin-guided Rocket (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 29.9 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 27.9 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 9.0, -- Unconfirmed
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" }, -- This is the spell that the goblin instant casts
				}),
				[466545] = BossAbility:New({ -- Spray and Pray (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 50.1 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 50.1 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 3.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[469491] = BossAbility:New({ -- Double Whammy Shot (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 45.0 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 45.0 },
							repeatInterval = 73.2, -- Unconfirmed (PTR Normal log)
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[471419] = BossAbility:New({ -- Bulletstorm (Intermission)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0, 15.8, 15.8 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 8.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1215953] = BossAbility:New({ -- Static Charge (Intermission)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { -5.7, 10.3, 16.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[463967] = BossAbility:New({ -- Bloodlust (Intermission)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 15.8 + 15.8 + 10.3 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1222408] = BossAbility:New({ -- Head Honcho: Mug'Zee (Phase 2)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SAA" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 300.0,
					defaultDuration = 300.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 47.2,
					defaultDuration = 47.2,
					count = 1,
					defaultCount = 1,
					name = "Int1 (40%)",
					fixedCount = true,
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedCount = true,
					fixedDuration = true,
				}),
			},
		}),
		Boss:New({ -- Chrome King Gallywix -- TODO: Completely made up timings
			bossIDs = {
				237194, -- Gallywix
			},
			journalEncounterID = 2646,
			dungeonEncounterID = 3016,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = nil,
				[3] = { combatLogEventSpellID = 1214226, combatLogEventType = "SCC" },
				[4] = { combatLogEventSpellID = 1214369, combatLogEventType = "SCS" },
			},
			abilities = {
				[466340] = BossAbility:New({ -- Scatterblast Canisters
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = { 45.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = { 45.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[465952] = BossAbility:New({ -- Big Bad Buncha Bombs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = { 60.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = { 60.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[466158] = BossAbility:New({ -- Sapper's Satchel
					eventTriggers = {
						[465952] = EventTrigger:New({ -- Big Bad Buncha Bombs
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[466165] = BossAbility:New({ -- 1500-Pound "Dud"
					eventTriggers = {
						[465952] = EventTrigger:New({ -- Big Bad Buncha Bombs
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
					},
					duration = 0.0,
					castTime = 15.0,
					allowedCombatLogEventTypes = {},
				}),
				[466338] = BossAbility:New({ -- Zagging Zizzler
					eventTriggers = {
						[465952] = EventTrigger:New({ -- Big Bad Buncha Bombs
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
					},
					duration = 0.0,
					castTime = 15.0,
					allowedCombatLogEventTypes = {},
				}),
				[467182] = BossAbility:New({ -- Suppression
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0 },
							repeatInterval = { 30.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 15.0 },
							repeatInterval = { 30.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 15.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 3.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[466751] = BossAbility:New({ -- Venting Heat
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 45.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 45.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 4.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = {},
				}),
				[466341] = BossAbility:New({ -- Fused Canisters
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 40 },
							repeatInterval = { 60.0 },
						}),
					},
					eventTriggers = {
						[1217987] = EventTrigger:New({ -- Combination Canisters
							combatLogEventType = "SCC",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[1220761] = BossAbility:New({ -- Mechengineer's Canisters
					eventTriggers = {
						[466341] = EventTrigger:New({ -- Fused Canisters
							combatLogEventType = "SCC",
							castTimes = { 2.0 },
						}),
					},
					duration = 30.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[469286] = BossAbility:New({ -- Giga Coils
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { gallywixEnergyChargeTime },
							repeatInterval = { gallywixEnergyChargeTime },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { gallywixEnergyChargeTime },
							repeatInterval = { gallywixEnergyChargeTime },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[469327] = BossAbility:New({ -- Giga Blast
					eventTriggers = {
						[469286] = EventTrigger:New({ -- Giga Coils
							combatLogEventType = "SCC",
							castTimes = { 0.0, 3.5, 3.5, 3.5, 3.5 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[469362] = BossAbility:New({ -- Charged Giga Bomb
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { gallywixEnergyChargeTime - 20.0 },
							repeatInterval = { gallywixEnergyChargeTime },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { gallywixEnergyChargeTime - 20.0 },
							repeatInterval = { gallywixEnergyChargeTime },
						}),
					},
					duration = 40.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1214226] = BossAbility:New({ -- Cratering
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[466958] = BossAbility:New({ -- Ego Check
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = {},
				}),
				[1219278] = BossAbility:New({ -- Gallybux Pest Eliminator
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 5.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1214369] = BossAbility:New({ -- TOTAL DESTRUCTION!!!
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 30.0,
					castTime = 4.6,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[1214607] = BossAbility:New({ -- Bigger Badder Bomb Blast
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = 60.0,
						}),
					},
					duration = 25.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1217987] = BossAbility:New({ -- Combination Canisters
					eventTriggers = {
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCC",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[466342] = BossAbility:New({ -- Tick-Tock Canisters
					eventTriggers = {
						[1217987] = EventTrigger:New({ -- Combination Canisters
							combatLogEventType = "SCC",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = gallywixEnergyChargeTime,
					defaultDuration = gallywixEnergyChargeTime,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = gallywixEnergyChargeTime * 1.5,
					defaultDuration = gallywixEnergyChargeTime * 1.5,
					count = 1,
					defaultCount = 1,
					name = "P2 (100 Energy)",
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 44.6,
					defaultDuration = 44.6,
					count = 1,
					defaultCount = 1,
					name = "Int1 (50%)",
					fixedCount = true,
					fixedDuration = true,
				}),
				[4] = BossPhase:New({
					duration = 240.0,
					defaultDuration = 240.0,
					count = 1,
					defaultCount = 1,
					name = "P3",
					fixedCount = true,
				}),
			},
		}),
	},
	executeAndNil = function()
		EJ_SelectInstance(Private.dungeonInstances[2769].journalInstanceID)
		local journalEncounterID = Private.dungeonInstances[2769].bosses[2].journalEncounterID
		EJ_SelectEncounter(journalEncounterID)
		local _, bossName, _, _, _, _ = EJ_GetCreatureInfo(1, journalEncounterID)
		Private.dungeonInstances[2769].bosses[2].abilities[465863].additionalContext = bossName:match("^(%S+)")
		_, bossName, _, _, _, _ = EJ_GetCreatureInfo(2, journalEncounterID)
		Private.dungeonInstances[2769].bosses[2].abilities[465872].additionalContext = bossName:match("^(%S+)")
	end,
})
