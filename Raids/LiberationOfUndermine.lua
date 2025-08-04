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

Private.dungeonInstances[2769] = DungeonInstance:New({
	journalInstanceID = 1296,
	instanceID = 2769,
	customGroups = { "TheWarWithinSeasonTwo" },
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
				[2] = { combatLogEventSpellID = 460603, combatLogEventType = "SCS" },
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
					tankAbility = true,
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
							castTimes = { 4.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 45.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[460603] = BossAbility:New({ -- Mechanical Breakdown
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" }, -- Inconsistent/spam SAA/SAR
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
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
					duration = 120.0,
					defaultDuration = 120.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
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
				[2] = { combatLogEventSpellID = 465872, combatLogEventType = "SAA" },
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
					duration = 20.0, -- Channeled, SCC is start of cast
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[465863] = BossAbility:New({ -- Colossal Clash (Flarendo)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 20.0, -- Channeled, SCC is start of cast
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
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
					allowedCombatLogEventTypes = {}, -- Spell Aura Refresh not implemented
					defaultHidden = true,
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
					allowedCombatLogEventTypes = {}, -- Spell Aura Refresh not implemented
					defaultHidden = true,
				}),
				[473650] = BossAbility:New({ -- Scrapbomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 23.0, 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 9.0, 23.0, 24.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[472233] = BossAbility:New({ -- Blastburn Roarcannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0, 24.0, 21.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.0, 24.0, 21.0 },
						}),
					},
					duration = 3.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1213690] = BossAbility:New({ -- Molten Phlegm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.6, 24.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 24.6, 24.4 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- No cast, only applies debuffs
				}),
				[1214190] = BossAbility:New({ -- Eruption Stomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.0, 25.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 26.0, 25.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					tankAbility = true, -- Also affects players
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
					duration = 8.0, -- Channeled, SCC is start of cast
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
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
					tankAbility = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 74.0,
					defaultDuration = 74.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 21.0,
					defaultDuration = 21.0,
					count = 5,
					defaultCount = 5,
					name = "P2",
					repeatAfter = 3,
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 74.0,
					defaultDuration = 74.0,
					count = 5,
					defaultCount = 5,
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
							castTimes = { 21.0, 39.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 21.0, 39.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[467606] = BossAbility:New({ -- Sound Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.0, 35.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 32.0, 35.0 },
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
							castTimes = { 43.5, 31.5, 26.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 43.5, 31.5, 26.0 },
						}),
					},
					duration = 12.0,
					castTime = 2.125,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[472293] = BossAbility:New({ -- Grand Finale (death of Pyrotechnics)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.1, 59.7, 22.3 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 26.1, 59.7, 22.3 },
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
					tankAbility = true,
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
					tankAbility = true,
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
					tankAbility = true, -- Also relevant for everyone else
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
						[1] = BossAbilityPhase:New({
							castTimes = { 3.3, 26.7, 40.1, 34.0, 25.9, 24.3, 26.7 },
							repeatInterval = 26.7,
						}),
						[2] = BossAbilityPhase:New({
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
						[1] = BossAbilityPhase:New({
							castTimes = { 8.2, 34.0, 15.8, 31.6, 19.4, 32.8, 18.2, 32.8 },
							repeatInterval = { 18.2, 32.8 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 1.1, 25.7, 25.7, 25.7 }, -- Heroic timers
						}),
					},
					duration = 1.5,
					castTime = 0.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[460472] = BossAbility:New({ -- The Big Hit
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.9, 18.2, 39.0, 20.6, 19.4, 20.6 },
							repeatInterval = { 39.0, 20.6, 19.4, 20.6 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 11.0, 19.4, 19.4, 19.4 },
						}),
					},
					duration = 30.0,
					castTime = 2.5,
					halfHeight = true,
					tankAbility = true,
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
				[2] = BossPhase:New({
					duration = 93.0,
					defaultDuration = 93.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					fixedDuration = true,
					name = "P2 (30% Health)",
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
					defaultHidden = true,
				}),
				[468728] = BossAbility:New({ -- Mug taking charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 120.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
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
					tankAbility = true,
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
					defaultHidden = true,
				}),
				[468794] = BossAbility:New({ -- Zee Taking Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.0 },
							repeatInterval = 120.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
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
					duration = 360.0,
					defaultDuration = 360.0,
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
					name = "Int1 (40% Health)",
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
		Boss:New({ -- Chrome King Gallywix
			bossIDs = {
				237194, -- Gallywix
			},
			journalEncounterID = 2646,
			dungeonEncounterID = 3016,
			instanceID = 2769,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 1214590, combatLogEventType = "SAR" },
				[3] = { combatLogEventSpellID = 1226891, combatLogEventType = "SAA" },
				[4] = { combatLogEventSpellID = 1226891, combatLogEventType = "SAR" },
				[5] = { combatLogEventSpellID = 1226891, combatLogEventType = "SAA" },
				[6] = { combatLogEventSpellID = 1226891, combatLogEventType = "SAR" },
			},
			abilities = {
				[1214590] = BossAbility:New({ -- TOTAL DESTRUCTION!!!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.8 },
							signifiesPhaseEnd = true,
						}),
					},
					durationLastsUntilEndOfPhase = true,
					duration = 30.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[466958] = BossAbility:New({ -- Ego Check
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 15.4, 21.5, 14.5, 19.9, 17.1, 12.4, 16.5, 23.6, 11.5, 23.8, 23.5 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 21.1, 26.5, 28.6, 27.9, 29.0, 22.1 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 23.0, 39.0, 26.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
					defaultHidden = true,
				}),
				[1217987] = BossAbility:New({ -- Combination Canisters
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 30.4, 28.5, 31.6, 38.4, 25.6, 38.9 },
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
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
					defaultHidden = true,
				}),
				[466341] = BossAbility:New({ -- Fused Canisters
					eventTriggers = {
						[1217987] = EventTrigger:New({ -- Combination Canisters
							combatLogEventType = "SCC",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
					defaultHidden = true,
				}),
				[1218488] = BossAbility:New({ -- Scatterbomb Canisters
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 12.55, 42.56, 36.92, 32.52 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 7.48, 37.01, 45.6 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = {},
				}),
				[1214607] = BossAbility:New({ -- Bigger Badder Bomb Blast
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 7.4 },
							repeatInterval = 57.0,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466165] = BossAbility:New({ -- 1500-Pound "Dud"
					eventTriggers = {
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCS",
							castTimes = { 6.0 },
						}),
					},
					duration = 0.0,
					castTime = 15.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1218546] = BossAbility:New({ -- Biggest Baddest Bomb Barrage
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 37.55, 47.99, 54.1 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 30.0, 48.03 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466338] = BossAbility:New({ -- Zagging Zizzler
					eventTriggers = {
						[1214607] = EventTrigger:New({ -- Bigger Badder Bomb Blast
							combatLogEventType = "SCS",
							castTimes = { 6.0 },
							phaseOccurrences = { [2] = { [1] = true } },
						}),
					},
					phases = {
						-- [2] = BossAbilityPhase:New({
						-- 	castTimes = { 13.5 },
						-- 	repeatInterval = 58.0,
						-- }),
						[4] = BossAbilityPhase:New({
							castTimes = { 42.4, 47.9, 54.2 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 34.8, 48.0 },
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1214749] = BossAbility:New({ -- Overloaded Rockets
					eventTriggers = {
						[466338] = EventTrigger:New({ -- Zagging Zizzler
							combatLogEventType = "SCS",
							castTimes = { 0.5 },
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[467182] = BossAbility:New({ -- Suppression
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 42.5, 60.5, 64.5 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 23.1, 44.1, 44.9 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 64.1, 34.6 },
						}),
					},
					duration = 3.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[466751] = BossAbility:New({ -- Venting Heat
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 38.9, 16.5, 23.6, 18.4, 22.0, 29.6, 12.1, 23.4 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 9.0, 35.0, 19.6, 36.9, 20.5, 25.1 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 19.5, 33.5, 31.5 },
						}),
					},
					duration = 4.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1224378] = BossAbility:New({ -- Giga Coils
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 26.4, 58.2, 60.5, 59.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 159.2 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
					defaultHidden = true,
				}),
				[469327] = BossAbility:New({ -- Giga Blast
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 17.4 },
							repeatInterval = 57.0,
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 37.55 + 12.0, 47.99 + 12.0, 42.0 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 54.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					defaultHidden = false,
				}),
				[1222831] = BossAbility:New({ -- Overloaded Coils
					phases = {
						[6] = BossAbilityPhase:New({
							castTimes = { 110.2 },
						}),
					},
					duration = 0.0,
					castTime = 10.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = {},
				}),
				[1226891] = BossAbility:New({ -- Circuit Reboot
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
						[5] = BossAbilityPhase:New({
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
				[1219333] = BossAbility:New({ -- Gallybux Finale Blast
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 46.9, 60.5, 64.5 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 27.6, 44.1, 44.9 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 68.6, 34.6 },
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 28.0,
					defaultDuration = 28.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 208.0,
					defaultDuration = 208.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedCount = true,
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 33.5,
					defaultDuration = 33.5,
					count = 1,
					defaultCount = 1,
					name = "Int2",
					fixedCount = true,
					fixedDuration = true,
				}),
				[4] = BossPhase:New({
					duration = 167.2,
					defaultDuration = 167.2,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedCount = true,
					fixedDuration = true,
				}),
				[5] = BossPhase:New({
					duration = 31.0,
					defaultDuration = 31.0,
					count = 1,
					defaultCount = 1,
					name = "Int3",
					fixedCount = true,
					fixedDuration = true,
				}),
				[6] = BossPhase:New({
					duration = 132.6,
					defaultDuration = 132.6,
					count = 1,
					defaultCount = 1,
					name = "P2",
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
	isRaid = true,
})
