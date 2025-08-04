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

Private:RegisterPlaceholderBossSpellID(1236973, L["Erupting Torment"])
Private:RegisterPlaceholderBossSpellID(1236512, L["Unstable Anima"])

Private.dungeonInstances[2287] = DungeonInstance:New({
	journalInstanceID = 1185,
	instanceID = 2287,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Halkias, the Sin-Stained Goliath
			bossIDs = {
				165408, -- Halkias
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5159] = 165408, -- Halkias
			},
			journalEncounterID = 2406,
			dungeonEncounterID = 2401,
			instanceID = 2287,
			abilities = {
				[322711] = BossAbility:New({ -- Refracted Sinlight
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 33.25 },
							repeatInterval = { 49.75 },
						}),
					},
					duration = 13.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[322936] = BossAbility:New({ -- Crumbling Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.73 },
							repeatInterval = { 13.90, 36.38 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					tankAbility = true,
				}),
				[322943] = BossAbility:New({ -- Heave Debris
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.53 },
							repeatInterval = { 13.62, 22.32 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
		Boss:New({ -- Echelon
			bossIDs = {
				164185, -- Echelon
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5172] = 164185, -- Echelon
			},
			journalEncounterID = 2387,
			dungeonEncounterID = 2380,
			instanceID = 2287,
			abilities = {
				[319733] = BossAbility:New({ -- Stone Call
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.17 },
							repeatInterval = { 52.0, 42.99 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[319941] = BossAbility:New({ -- Stone Shattering Leap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.12 },
							repeatInterval = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[326389] = BossAbility:New({ -- Blood Torrent
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.14 },
							repeatInterval = { 25.49, 17.05, 20.09, 23.65, 19.81, 18.44 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[328206] = BossAbility:New({ -- Flesh to Stone
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.95 },
							repeatInterval = { 31.45, 28.49, 31.72, 30.68 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
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
		Boss:New({ -- High Adjudicator Aleez
			bossIDs = {
				165410, -- High Adjudicator Aleez
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5166] = 165410, -- High Adjudicator Aleez
				-- [5168] = 165410, -- Ghastly Parishioner
				-- [5188] = 165410, -- Vessel of Atonement
			},
			journalEncounterID = 2411,
			dungeonEncounterID = 2403,
			instanceID = 2287,
			abilities = {
				[323852] = BossAbility:New({ -- Pulse from Beyond
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.76 },
							repeatInterval = { 21.0 },
						}),
					},
					duration = 8.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[329340] = BossAbility:New({ -- Anima Fountain
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.54, 23.85 },
							repeatInterval = { 24.0 },
						}),
					},
					duration = 6.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SAA", "SAR" },
				}),
				[1236512] = BossAbility:New({ -- Unstable Anima
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.04 },
							repeatInterval = { 17.0 },
						}),
					},
					duration = 14.0,
					castTime = 0.0,
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
		Boss:New({ -- Lord Chamberlain
			bossIDs = {
				164218, -- Lord Chamberlain
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5213] = 164218, -- Lord Chamberlain
			},
			journalEncounterID = 2413,
			dungeonEncounterID = 2381,
			instanceID = 2287,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 329104, combatLogEventType = "SCS" },
				[3] = { combatLogEventSpellID = 329104, combatLogEventType = "SCS" },
			},
			abilities = {
				[329104] = BossAbility:New({ -- Door of shadows (70% and 40%)
					phases = {
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
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[329113] = BossAbility:New({ -- Telekinetic Onslaught
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.4 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 2.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 2.4 },
						}),
					},
					duration = 6.0, -- channel
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" }, -- SAR/SAA spam
				}),
				[323143] = BossAbility:New({ -- Telekinetic Toss
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.50 },
							repeatInterval = { 12.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 9.50 },
							repeatInterval = { 12.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 9.50 },
							repeatInterval = { 12.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5, -- channel
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[323236] = BossAbility:New({ -- Unleashed Suffering
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.0 },
							repeatInterval = { 24.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 19.0 },
							repeatInterval = { 24.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 19.0 },
							repeatInterval = { 24.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[328791] = BossAbility:New({ -- Ritual of Woe
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 10.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 10.0 },
						}),
					},
					duration = 10.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1236973] = BossAbility:New({ -- Erupting Torment
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.67 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 25.67 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 25.67 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 45.0,
					defaultDuration = 45.0,
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
					name = "P2 (70% Health)",
				}),
				[3] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P3 (40% Health)",
				}),
			},
		}),
	},
})
