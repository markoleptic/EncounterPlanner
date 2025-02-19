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

Private.dungeonInstances[2657] = DungeonInstance:New({
	journalInstanceID = 1273,
	instanceID = 2657,
	bosses = {
		Boss:New({ -- Ulgrax the Devourer
			bossID = 215657,
			journalEncounterID = 2607,
			dungeonEncounterID = 2902,
			instanceID = 2657,
			abilities = {
				[435136] = BossAbility:New({ -- Venomous Lash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0, 25.0, 28.0 },
						}),
					},
					duration = 6.0,
					castTime = 2.0,
				}),
				[435138] = BossAbility:New({ -- Digestive Acid
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0, 47.0 },
						}),
					},
					duration = 6.0,
					castTime = 2.0,
				}),
				[434803] = BossAbility:New({ -- Carnivorous Contest
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.0, 36.0 },
						}),
					},
					duration = 6.0,
					castTime = 4.0,
				}),
				[445123] = BossAbility:New({ -- Hulking Crash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 85.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[436200] = BossAbility:New({ -- Juggernaut Charge
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 16.7, 7.1, 7.1, 7.1 },
						}),
					},
					duration = 8.0,
					castTime = 4.0,
				}),
				[438012] = BossAbility:New({ -- Hungering Bellows
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 60.8 },
							repeatInterval = 7.0,
						}),
					},
					duration = 3.0,
					castTime = 3.0,
				}),
				[445052] = BossAbility:New({ -- Chittering Swarm
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 6.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[441425] = BossAbility:New({ -- Phase Transition
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							skipFirst = true,
						}),
						[2] = BossAbilityPhase:New({
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
					duration = 90.0,
					defaultDuration = 90.0,
					count = 3,
					defaultCount = 3,
					repeatAfter = 2,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 80.0,
					defaultDuration = 80.0,
					count = 3,
					defaultCount = 3,
					repeatAfter = 1,
					name = "P2",
				}),
			},
		}),
		Boss:New({ -- The Bloodbound Horror
			bossID = 214502,
			journalEncounterID = 2611,
			dungeonEncounterID = 2917,
			instanceID = 2657,
			abilities = {
				[444497] = BossAbility:New({ -- Invoke Terrors
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0, 59.0, 69.0, 59.0, 69.0, 59.0, 69.0 },
						}),
					},
					duration = 1.0,
					castTime = 0.0,
				}),
				[444363] = BossAbility:New({ -- Gruesome Disgorge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.0, 59.0, 69.0, 59.0, 69.0, 59.0, 69.0 },
						}),
					},
					duration = 40.0,
					castTime = 5.0,
				}),
				[445936] = BossAbility:New({ -- Spewing Hemorrhage
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.0, 59.0, 69.0, 59.0, 69.0, 59.0, 69.0 },
						}),
					},
					duration = 20.0,
					castTime = 5.0,
				}),
				[442530] = BossAbility:New({ -- Goresplatter
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 120.0, 128.0, 128.0 },
						}),
					},
					duration = 10.0,
					castTime = 8.0,
				}),
				[443203] = BossAbility:New({ -- Crimson Rain
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.0, 128.0, 128.0, 128.0 },
						}),
					},
					duration = 5.0,
					castTime = 0.0,
				}),
				[443042] = BossAbility:New({ -- Grasp From Beyond
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {
								19.0,
								28.0,
								31.0,
								28.0,
								41.0,
								28.0,
								31.0,
								28.0,
								41.0,
								28.0,
								31.0,
								28.0,
								41.0,
							},
						}),
					},
					duration = 12.0,
					castTime = 0.0,
				}),
				[452237] = BossAbility:New({ -- Bloodcurdle
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 32.0, 27.0, 32.0, 37.0, 32.0, 27.0, 32.0, 37.0 },
						}),
					},
					duration = 5.0,
					castTime = 2.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 300.0,
					defaultDuration = 300.0,
				}),
			},
		}),
		Boss:New({ -- Sikran, Captain of the Sureki
			bossID = 214503,
			journalEncounterID = 2599,
			dungeonEncounterID = 2898,
			instanceID = 2657,
			abilities = {
				[439511] = BossAbility:New({ -- Captain's Flourish
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {
								6.9,
								25.8,
								25.1,
								25.7,
								18.7,
								28.1,
								28.0,
								27.1,
								15.8,
								28.1,
								28.1,
								27.3,
								15.3,
								28.2,
								27.1,
								28.0,
								15.4,
								28.1,
								27.2,
								28.0,
							},
						}),
					},
					duration = 6.0,
					castTime = 0.0,
				}),
				[433517] = BossAbility:New({ -- Phase Blades
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {
								13.0,
								27.3,
								27.2,
								42.1,
								28.1,
								28.2,
								43.9,
								28.2,
								28.1,
								41.6,
								27.9,
								28.0,
								43.8,
								28.0,
								28.1,
							},
						}),
					},
					duration = 20.0,
					castTime = 1.5,
				}),
				[442428] = BossAbility:New({ -- Decimate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 51.2, 26.6, 75.6, 27.1, 72.0, 28.1, 70.8, 27.9, 70.7, 28.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
				}),
				[439559] = BossAbility:New({ -- Rain of Arrows
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = {
								22.8,
								42.3,
								55.5,
								26.8,
								27.1,
								45.1,
								27.0,
								26.6,
								45.5,
								26.7,
								26.7,
								45.0,
								26.9,
								26.8,
							},
						}),
					},
					duration = 8.0,
					castTime = 2.0,
				}),
				[456420] = BossAbility:New({ -- Shattering Sweep
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 90.0, 98.0, 98.0, 98.0, 98.0, 98.0, 98.0 },
						}),
					},
					duration = 10.0,
					castTime = 5.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 481.0,
					defaultDuration = 481.0,
				}),
			},
		}),
		Boss:New({ -- Rasha'nan
			bossID = 214504,
			journalEncounterID = 2609,
			dungeonEncounterID = 2918,
			instanceID = 2657,
			abilities = {
				[439789] = BossAbility:New({ -- Rolling Acid
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.1 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 40.7 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.9 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 20.7 },
						}),
					},
					duration = 3.0,
					castTime = 2.0,
				}),
				[455373] = BossAbility:New({ -- Infested Spawn
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.7 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 14.4 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 14.3, 20.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 14.3, 24.8 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 19.1 },
						}),
					},
					duration = 2.5,
					castTime = 2.5,
				}),
				[439784] = BossAbility:New({ -- Spinneret's Strands
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.2 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 33.8 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 18.7, 15.2 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 18.7 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 13.9, 20.0 },
						}),
					},
					duration = 3.0,
					castTime = 2.0,
				}),
				[454989] = BossAbility:New({ -- Enveloping Webs
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.1 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 18.6 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 38.6 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 38.6 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 33.9 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 38.6 },
						}),
					},
					duration = 2.5,
					castTime = 2.5,
				}),
				[439795] = BossAbility:New({ -- Web Reave
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 0.3 },
						}),
					},
					duration = 1.0,
					castTime = 4.0,
				}),
				[439811] = BossAbility:New({ -- Erosive Spray
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.1, 40.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 23.7 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 23.7 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 23.7 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 23.7 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 23.7 },
						}),
					},
					duration = 4.0,
					castTime = 1.5,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 64.5,
					defaultDuration = 64.5,
				}),
				[2] = BossPhase:New({
					duration = 64.5,
					defaultDuration = 64.5,
				}),
				[3] = BossPhase:New({
					duration = 64.5,
					defaultDuration = 64.5,
				}),
				[4] = BossPhase:New({
					duration = 64.5,
					defaultDuration = 64.5,
				}),
				[5] = BossPhase:New({
					duration = 64.5,
					defaultDuration = 64.5,
				}),
				[6] = BossPhase:New({
					duration = 44.5,
					defaultDuration = 44.5,
				}),
			},
			treatAsSinglePhase = true,
		}),
		Boss:New({ -- Broodtwister Ovi'nax
			bossID = 214506,
			journalEncounterID = 2612,
			dungeonEncounterID = 2919,
			instanceID = 2657,
			abilities = {
				[441362] = BossAbility:New({ -- Volatile Concoction
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.0 },
						}),
					},
					eventTriggers = {
						[442432] = EventTrigger:New({ -- Ingest Black Blood
							combatLogEventType = "SCS",
							castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
							combatLogEventSpellCount = 3,
							repeatInterval = 20.0,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
				[446349] = BossAbility:New({ -- Sticky Web
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0 },
						}),
					},
					eventTriggers = {
						[442432] = EventTrigger:New({ -- Ingest Black Blood
							combatLogEventType = "SCS",
							castTimes = { 30.0, 30.0, 30.0, 30.0 },
							combatLogEventSpellCount = 3,
							repeatInterval = 30.0,
						}),
					},
					duration = 6.0,
					castTime = 2.0,
				}),
				[442432] = BossAbility:New({ -- Ingest Black Blood
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.0, 171.0, 172.0 },
						}),
					},
					duration = 15.0,
					castTime = 1.0,
				}),
				[442526] = BossAbility:New({ -- Experimental Dosage
					eventTriggers = {
						[442432] = EventTrigger:New({ -- Ingest Black Blood
							combatLogEventType = "SCS",
							castTimes = { 16.0, 50.0, 50.0 },
							combatLogEventSpellCount = 3,
							repeatInterval = 50.0,
						}),
					},
					duration = 8.0,
					castTime = 1.5,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 600.0,
					defaultDuration = 600.0,
				}),
			},
		}),
		Boss:New({ -- Nexus-Princess Ky'veza
			bossID = 217748,
			journalEncounterID = 2601,
			dungeonEncounterID = 2920,
			instanceID = 2657,
			abilities = {
				[436867] = BossAbility:New({ -- Assassination
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0, 130.0, 130.0, 130.0 },
						}),
					},
					castTime = 0.0,
					duration = 8.0,
				}),
				[440377] = BossAbility:New({ -- Void Shredders
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						}),
					},
					castTime = 0.0,
					duration = 5.0,
				}),
				[437620] = BossAbility:New({ -- Nether Rift
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						}),
					},
					castTime = 4.0,
					duration = 6.0,
				}),
				[438245] = BossAbility:New({ -- Twilight Massacre
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 34.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						}),
					},
					castTime = 5.0,
					duration = 0.0,
				}),
				[439576] = BossAbility:New({ -- Nexus Daggers
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 45.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						}),
					},
					castTime = 1.5,
					duration = 5.0,
				}),
				[435405] = BossAbility:New({ -- Starless Night
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 96.1, 130.0 },
						}),
					},
					castTime = 5.0,
					duration = 24.0,
				}),
				[442277] = BossAbility:New({ -- Eternal Night
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 356.1 },
						}),
					},
					castTime = 5.0,
					duration = 24.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 385.0,
					defaultDuration = 385.0,
				}),
			},
		}),
		Boss:New({ -- The Silken Court
			bossID = { 217489, 217491 },
			journalEncounterID = 2608,
			dungeonEncounterID = 2921,
			instanceID = 2657,
			abilities = {
				[440504] = BossAbility:New({ -- Impaling Eruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.0, 20.0, 34.0, 20.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 11.0, 30.0, 30.0, 30.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[438218] = BossAbility:New({ -- Piercing Strike
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.0, 20.0, 27.0, 20.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 16.0, 20.0, 25.0, 15.0, 20.0, 25.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 20.0, 17.0, 32.0, 20.0, 21.0, 20.0, 36.0 },
						}),
					},
					castTime = 1.5,
					duration = 0.0,
				}),
				[438801] = BossAbility:New({ -- Call of the Swarm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.0, 53.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 31.0, 61.0 },
						}),
					},
					castTime = 3,
					duration = 0.0,
				}),
				[441791] = BossAbility:New({ -- Burrowed Eruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.0, 60.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 43.0, 98.0 },
						}),
					},
					castTime = 1.8,
					duration = 0.0,
				}),
				[440246] = BossAbility:New({ -- Reckless Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.5, 60.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 46.1, 98.0 },
						}),
					},
					castTime = 1.8,
					duration = 0.0,
				}),
				[450045] = BossAbility:New({ -- Skittering Leap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 42.1, 60.0 },
						}),
					},
					castTime = 1.0,
					duration = 0.0,
				}),
				[439838] = BossAbility:New({ -- Web Bomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.7, 70.2 },
						}),
					},
					castTime = 1.5,
					duration = 0.0,
				}),
				[438656] = BossAbility:New({ -- Venomous Rain
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.8, 33.3, 26.8 },
						}),
					},
					castTime = 1.5,
					duration = 10.0,
				}),
				[438677] = BossAbility:New({ -- Stinging Swarm
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 25.0, 58.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 81.1, 57.0 },
						}),
					},
					castTime = 2.0,
					duration = 0.0,
				}),
				[441782] = BossAbility:New({ -- Strands of Reality
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 32.0, 36.0, 24.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 22.2, 33.7, 24.9, 43.0, 33.8, 24.9, 43.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[450483] = BossAbility:New({ -- Void Step
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 38.7, 34.2, 23.6, 29.2 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 49.3, 40.5, 29.1, 30.1, 2.6, 38.4, 29.2, 30.1, 2.7 },
						}),
					},
					castTime = 1.0,
					duration = 0.0,
				}),
				[441626] = BossAbility:New({ -- Web Vortex
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 20.2, 55.8 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 33.4, 33.7, 63.8, 33.7, 64.0 },
						}),
					},
					castTime = 2.0,
					duration = 16.0,
				}),
				[450129] = BossAbility:New({ -- Entropic Desolation
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 25.4, 55.8 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 38.7, 33.7, 63.8, 33.7, 64.0 },
						}),
					},
					castTime = 4.5,
					duration = 8.0,
				}),
				[438355] = BossAbility:New({ -- Cataclysmic Entropy
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 41.7, 57.9 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 92.7, 61.8 },
						}),
					},
					castTime = 10.0,
					duration = 0.0,
				}),
				[463459] = BossAbility:New({ -- Apex of Entropy
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 170.0 },
						}),
					},
					castTime = 3.0,
					duration = 8.0,
				}),
				[443598] = BossAbility:New({ -- Uncontrollable Rage
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 170.0 },
						}),
					},
					castTime = 3.0,
					duration = 8.0,
				}),
				[450980] = BossAbility:New({ -- Shatter Existence
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					castTime = 45.0,
					duration = 0.0,
				}),
				[451277] = BossAbility:New({ -- Spike Storm
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					castTime = 45.0,
					duration = 0.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({ -- Stage 1: Clash of Rivals
					duration = 127.0,
					defaultDuration = 127.0,
					name = "P1",
				}),
				[2] = BossPhase:New({ -- Intermission: Void Ascension
					duration = 45.0,
					defaultDuration = 45.0,
					name = "Int1",
				}),
				[3] = BossPhase:New({ -- Stage 2: Grasp of the Void
					duration = 131.0,
					defaultDuration = 131.0,
					name = "P2",
				}),
				[4] = BossPhase:New({ -- Intermission: Raging Fury
					duration = 45.0,
					defaultDuration = 45.0,
					name = "Int2",
				}),
				[5] = BossPhase:New({ -- Stage 3: Unleashed Rage
					duration = 252.0,
					defaultDuration = 252.0,
					name = "P3",
				}),
			},
		}),
		Boss:New({ -- Queen Ansurek
			bossID = 218370,
			journalEncounterID = 2602,
			dungeonEncounterID = 2922,
			instanceID = 2657,
			abilities = {
				[437592] = BossAbility:New({ -- Reactive Toxin
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.1, 56.0, 56.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[439814] = BossAbility:New({ -- Silken Tomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.3, 40.0, 57.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[440899] = BossAbility:New({ -- Liquefy
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.4, 40.0, 54.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[437093] = BossAbility:New({ -- Feast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.4, 40.0, 54.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[439299] = BossAbility:New({ -- Web Blades
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.3, 40.0, 13.0, 25.0, 19.0, 23.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 48.3, 37.0, 21.0, 17.0, 42.0, 21.0, 19.0, 36.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[444829] = BossAbility:New({ -- Queen's Summons
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 43.3, 64.0, 83.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[438976] = BossAbility:New({ -- Royal Condemnation
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 111.4, 86.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[443325] = BossAbility:New({ -- Infest
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 30.0, 66.0, 80.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[443336] = BossAbility:New({ -- Gorge
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 32.0, 66.0, 80.0 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[445422] = BossAbility:New({ -- Frothing Gluttony
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 45.0, 80.0, 88.0, 35.5 },
						}),
					},
					castTime = 4.5,
					duration = 0.0,
				}),
				[449986] = BossAbility:New({ -- Aphotic Communion
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					castTime = 20.0,
					duration = 0.0,
				}),
				[462692] = BossAbility:New({ -- Echoing Connection (Chamber Guardian)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0, 0.0 },
						}),
					},
					castTime = 0.0,
					duration = 20.0,
				}),
				[462693] = BossAbility:New({ -- Echoing Connection (Chamber Expeller)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 30.0, 0.0, 30.0, 0.0 },
						}),
					},
					castTime = 0.0,
					duration = 20.0,
				}),
				[448300] = BossAbility:New({ -- Echoing Connection (Ascended Voidspeaker)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 5.0, 0.0, 90.0, 0.0 },
						}),
					},
					castTime = 0.0,
					duration = 20.0,
				}),
				[447207] = BossAbility:New({ -- Predation
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					castTime = 40.0,
					duration = 0.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 150.0,
					defaultDuration = 150.0,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 40.0,
					defaultDuration = 40.0,
					name = "Int1",
				}),
				[3] = BossPhase:New({
					duration = 126.0,
					defaultDuration = 126.0,
					name = "P2",
				}),
				[4] = BossPhase:New({
					duration = 240.0,
					defaultDuration = 240.0,
					name = "P3",
				}),
			},
		}),
	},
})
