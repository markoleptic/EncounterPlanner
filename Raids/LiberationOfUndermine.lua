local AddOnName, Namespace = ...

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
							halfHeight = true,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 10.3, 17.4, 16.6, 19.9, 21.8, 21.9 },
							halfHeight = true,
						}),
					},
					duration = 25.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
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
				229177, -- Torque
			},
			journalEncounterID = 2640,
			dungeonEncounterID = 3010,
			instanceID = 2769,
			abilities = {
				[465863 --[[465833]]] = BossAbility:New({ -- Colossal Clash
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0, 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 20.0,
					castTime = 0.0,
				}),
				[472222] = BossAbility:New({ -- Blistering Spite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
				}),
				[472225] = BossAbility:New({ -- Galvanized Spite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
				}),
				[473650] = BossAbility:New({ -- Scrapbomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.9, 24.0, 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 8.9, 24.0, 23.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
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
				}),
				[1214190] = BossAbility:New({ -- Eruption Stomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 27.0, 24.0, 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 27.0, 24.0, 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
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
				}),
				[3] = BossPhase:New({
					duration = 95.0,
					defaultDuration = 95.0,
					count = 3,
					defaultCount = 3,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
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
				}),
				[466866] = BossAbility:New({ -- Echoing Chant
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0, 57.5, 29.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 22.0, 57.5, 29.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
				}),
				[467606] = BossAbility:New({ -- Sound Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0, 30.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[464584] = BossAbility:New({ -- Sound Cloud
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
						-- [1] = BossAbilityPhase:New({
						-- 	castTimes = { 116.0 },
						-- 	doNotClipDuration = true, -- TODO
						-- 	castCompletionSignifiesPhaseStart = true, -- TODO
						-- 	auraRemovedSignifiesNextPhaseEnd = true, -- TODO
						-- }),
					},
					duration = 28.0,
					castTime = 0.0, -- 5.0 sec but is casted in previous phase
				}),
				[466979] = BossAbility:New({ -- Faulty Zap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38, 37, 24 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 38, 37, 24 },
						}),
					},
					duration = 12.0,
					castTime = 2.125,
				}),
				[472306] = BossAbility:New({ -- Sparkblast Ignition
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0, 82.5, 65.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.0, 82.5, 65.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[472293] = BossAbility:New({ -- Grand Finale
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0 + 15.0, 82.5 + 15.0, 65.0 + 15.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.0 + 15.0, 82.5 + 15.0, 65.0 + 15.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
				}),
				[473260] = BossAbility:New({ -- Blaring Drop
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.2, 7.0, 7.0, 7.0 },
						}),
					},
					duration = 3.0,
					castTime = 5.0,
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
				}),
				[3] = BossPhase:New({
					duration = 121.0,
					defaultDuration = 121.0,
					count = 3,
					defaultCount = 3,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
				}),
			},
		}),
		Boss:New({ -- Stix Bunkjunker  -- TODO: Nothing confirmed
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
							castTimes = { 22.2 },
							repeatInterval = { 80.5, 51.1 },
						}),
					},
					duration = 5.0,
					castTime = 1.0,
				}),
				[464149] = BossAbility:New({ -- Incinerator
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.1, 25.0, 25.0, 29.4 },
							repeatInterval = 25.0,
						}),
					},
					duration = 4.5,
					castTime = 3.0,
				}),
				[464112] = BossAbility:New({ -- Demolish
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.8, 80.5, 51.1 },
						}),
					},
					duration = 50.0,
					castTime = 0.0,
				}),
				[1217954] = BossAbility:New({ -- Meltdown
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 44.5, 80.5, 51.1 },
						}),
					},
					duration = 3.0,
					castTime = 1.0,
				}),
				[467117] = BossAbility:New({ -- Overdrive
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 76.7 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
				}),
				[467109] = BossAbility:New({ -- Trash Compactor
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 76.7 + 9.7 },
						}),
					},
					duration = 0.0,
					castTime = 3.75,
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
			abilities = {
				[473276] = BossAbility:New({ -- Activate Inventions!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = 30.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 1.0,
				}),
				[466765] = BossAbility:New({ -- Beta Launch
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 127.4 },
						}),
						[3] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 127.4 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
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
				}),
				[1218319] = BossAbility:New({ -- Voidsplosion
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 1.0, 5.0, 5.0, 5.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1214872] = BossAbility:New({ -- Pyro Party Pack
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 23.0, 32.9, 30.0 },
						}),
						[3] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 23.0, 32.9, 30.0 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
				}),
				[465232] = BossAbility:New({ -- Sonic Ba-Boom
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 9.0, 25.0, 27.0, 32.0, 18 },
						}),
						[3] = BossAbilityPhase:New({ -- TODO: Not confirmed
							castTimes = { 9.0, 25.0, 27.0, 32.0, 18 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
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
					castTime = 0.0,
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
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 129.4,
					defaultDuration = 129.4,
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
					duration = 129.4,
					defaultDuration = 129.4,
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
			abilities = {
				[460181] = BossAbility:New({ -- Pay-Line
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 3.3, 26.7, 40.1, 34.0, 25.9, 24.3, 26.7 },
							repeatInterval = 26.7,
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 7.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 1.0,
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
				}),
				[469993] = BossAbility:New({ -- Foul Exhaust
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 8.2 },
							repeatInterval = { 34, 15.8 },
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 1.0 },
							repeatInterval = { 31.6, 25.5 },
						}),
					},
					duration = 1.5,
					castTime = 0.5,
				}),
				[460472] = BossAbility:New({ -- The Big Hit
					phases = {
						[1] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 17.9, 18.2, 39.0, 20.6, 19.4, 20.6 },
						}),
						[2] = BossAbilityPhase:New({ -- TODO: Inconsistent, prob wrong
							castTimes = { 11.0 },
							repeatInterval = 19.4,
						}),
					},
					duration = 30.0,
					castTime = 2.5,
				}),
				[461060] = BossAbility:New({ -- Spin To Win!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.2 },
							repeatInterval = 53.0,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
				}),
				[465761] = BossAbility:New({ -- Rig the Game!
					phases = {
						[2] = BossAbilityPhase:New({ -- TODO: Actually cast in P1
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[465432] = BossAbility:New({ -- Linked Machines
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 2.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[465322] = BossAbility:New({ -- Hot Hot Heat
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 2.0 + 31.5 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[465580] = BossAbility:New({ -- Scattered Payout
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 2.0 + 31.5 + 31.5 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[465587] = BossAbility:New({ -- Explosive Jackpot
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 2.0 + 31.5 + 31.5 + 31.5 },
						}),
					},
					duration = 0.0,
					castTime = 10.0,
				}),
				-- [461083] = BossAbility:New({ -- Reward: Shock and Flame
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
				-- [461091] = BossAbility:New({ -- Reward: Shock and Bomb
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
				-- [461176] = BossAbility:New({ -- Reward: Flame and Bomb
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
				-- [461389] = BossAbility:New({ -- Reward: Flame and Coin
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
				-- [461101] = BossAbility:New({ -- Reward: Coin and Shock
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
				-- [461395] = BossAbility:New({ -- Reward: Coin and Bomb
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- }),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 285.2,
					defaultDuration = 285.2,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 106.5,
					defaultDuration = 106.5,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					fixedDuration = true,
					name = "P2",
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
			abilities = {
				[466385] = BossAbility:New({ -- Moxie (Both)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 5.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 5.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[466459] = BossAbility:New({ -- Head Honcho: Mug
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0, 120.0, 240.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
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
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 0.0,
					castTime = 2.5,
				}),
				[466476] = BossAbility:New({ -- Frostshatter Boots (Mug)
					eventTriggers = {
						[466459] = EventTrigger:New({ -- Head Honcho: Mug
							combatLogEventType = "SAA",
							castTimes = { 34.8 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 34.8 },
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 0.0,
					castTime = 2.0,
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
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 4.0,
					castTime = 3.0,
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
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 0.0,
					castTime = 2.5,
				}),
				[466460] = BossAbility:New({ -- Head Honcho: Zee
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.0, 180.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
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
				}),
				[466539] = BossAbility:New({ -- Unstable Crawler Mines (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 14.0 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 14.0 },
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
				[467380] = BossAbility:New({ -- Goblin-guided Rocket (Zee)
					eventTriggers = {
						[466460] = EventTrigger:New({ -- Head Honcho: Zee
							combatLogEventType = "SAA",
							castTimes = { 27.9 },
						}),
						[1222408] = EventTrigger:New({ -- Head Honcho: Mug'Zee
							combatLogEventType = "SAA",
							castTimes = { 27.9 },
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 9.0, -- Unconfirmed
					castTime = 2.0,
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
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 3.0,
					castTime = 3.5,
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
							repeatInterval = 60.0, -- Unconfirmed
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[471574] = BossAbility:New({ -- Bulletstorm (Intermission)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0, 15.8, 15.8 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 8.0,
					castTime = 0.0,
				}),
				[1215898] = BossAbility:New({ -- Static Charge (Intermission)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 300.0 - 5.7 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 10.3, 16.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[463967] = BossAbility:New({ -- Bloodlust (Intermission)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 15.8 + 15.8 + 10.3 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
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
					name = "Int1",
					fixedCount = true,
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedCount = true,
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
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[465952] = BossAbility:New({ -- Big Bad Buncha Bombs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = { 60.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = { 60.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
				}),
				[466751] = BossAbility:New({ -- Venting Heat
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 30.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 30.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 25.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 4.0,
					castTime = 1.0,
				}),
				[469327] = BossAbility:New({ -- Giga Blast
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 8.0 },
							repeatInterval = { 30.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 8.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
				}),
				[469404] = BossAbility:New({ -- Giga BOOM!
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 35 },
							repeatInterval = { 30.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 35 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[469297] = BossAbility:New({ -- Sabotaged Controls
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 30 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 15.0,
				}),
				[1220846] = BossAbility:New({ -- Control Meltdown
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 35 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 9.0,
					castTime = 0.0,
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
				}),
				[469362] = BossAbility:New({ -- Charged Giga Bomb
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 45.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1218992] = BossAbility:New({ -- Discharged Giga Bomb
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 45.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1216845] = BossAbility:New({ -- Wrench
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 1.0 },
							repeatInterval = { 5.0 },
							signifiesPhaseStart = true,
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 1.0 },
							repeatInterval = { 5.0 },
						}),
					},
					duration = 9.0,
					castTime = 1.0,
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
				}),
				[1219319] = BossAbility:New({ -- Radiant Electricity
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1219278] = BossAbility:New({ -- Gallybux Pest Eliminator
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 10.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1214369] = BossAbility:New({ -- TOTAL DESTRUCTION!!!
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 33.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 25.0,
					castTime = 2.0,
				}),
				[1214607] = BossAbility:New({ -- Bigger Badder Bomb Blast
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = { 60.0 },
						}),
					},
					duration = 25.0,
					castTime = 4.0,
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
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedCount = true,
				}),
				[3] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
					fixedCount = true,
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
})
