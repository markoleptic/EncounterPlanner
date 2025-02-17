local isElevenDotOne = select(4, GetBuildInfo()) >= 110100 -- Remove when 11.1 is live
if not isElevenDotOne then
	return
end

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
			bossID = {
				225821, -- The Geargrinder
			},
			journalEncounterID = 2639,
			dungeonEncounterID = 3009,
			instanceID = 2769,
			abilities = {
				[466615] = BossAbility:New({ -- Protective Plating
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							allowedCombatLogEventType = { "SAA", "SAR" }, -- TODO: Enforce allowed types
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							allowedCombatLogEventType = { "SAA", "SAR" }, -- TODO: Enforce allowed types
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
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
				}),
				[459943] = BossAbility:New({ -- Call Bikers
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.4 },
							repeatInterval = 28.2,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 20.4 },
							repeatInterval = 28.2,
						}),
					},
					duration = 0.0,
					castTime = 1.0,
				}),
				[459678] = BossAbility:New({ -- Spew Oil
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.5 },
							repeatInterval = 41.3,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 12.2 },
							repeatInterval = 20.7,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[468216] = BossAbility:New({ -- Incendiary Fire
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.7 },
							repeatInterval = 25.7,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 25.7 },
							repeatInterval = 35.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[465865] = BossAbility:New({ -- Tank Buster
					-- TODO: Alternate half height boss ability bars
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.2 },
							repeatInterval = 17.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 6.2 },
							repeatInterval = 17.0,
						}),
					},
					duration = 25.0,
					castTime = 0.0,
				}),
				[468147] = BossAbility:New({ -- Exhaust Fumes (DPS / Healers)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.2 + 1.5 },
							repeatInterval = 17.0,
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 6.2 + 1.5 },
							repeatInterval = 17.0,
						}),
					},
					duration = 6.0,
					castTime = 0.0,
				}),
				[460116] = BossAbility:New({ -- Tune-Up
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 45.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 125.0,
					defaultDuration = 125.0,
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
					duration = 125.0,
					defaultDuration = 125.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
				}),
			},
		}),
		Boss:New({ -- Cauldron of Carnage
			bossID = {
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
			bossID = {
				228648, -- Rik
			},
			journalEncounterID = 2641,
			dungeonEncounterID = 3011,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Stix Bunkjunker
			bossID = {
				230322, -- Stix
			},
			journalEncounterID = 2642,
			dungeonEncounterID = 3012,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Sprocketmonger Lockenstock
			bossID = {
				230583, -- Sprocketmonger
			},
			journalEncounterID = 2653,
			dungeonEncounterID = 3013,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- The One-Armed Bandit
			bossID = {
				228458, -- Bandit
			},
			journalEncounterID = 2644,
			dungeonEncounterID = 3014,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Mug'Zee, Heads of Security
			bossID = {
				229953, -- Mug'Zee
			},
			journalEncounterID = 2645,
			dungeonEncounterID = 3015,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Chrome King Gallywix
			bossID = {
				237194, -- Gallywix
			},
			journalEncounterID = 2646,
			dungeonEncounterID = 3016,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
	},
})
