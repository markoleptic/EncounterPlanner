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

Private.dungeonInstances[2661] = DungeonInstance:New({
	journalInstanceID = 1272,
	instanceID = 2661,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Brew Master Aldryr
			bossIDs = { 210271 },
			journalEncounterID = 2586,
			dungeonEncounterID = 2900,
			instanceID = 2661,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 442525, combatLogEventType = "SCC" },
				[3] = { combatLogEventSpellID = 442525, combatLogEventType = "SAR" },
			},
			abilities = {
				[442525] = BossAbility:New({ -- Happy Hour (33% and 66% health)
					phases = {
						[2] = BossAbilityPhase:New({ -- Not a true phase
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					durationLastsUntilEndOfPhase = true,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[432198] = BossAbility:New({ -- Blazing Belch
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.4 },
							repeatInterval = { 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 17.4 },
							repeatInterval = { 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[432179] = BossAbility:New({ -- Throw Cinderbrew
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.8 },
							repeatInterval = { 18.2 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 13.8 },
							repeatInterval = { 18.2 },
						}),
					},
					durationHurts = true,
					durationIsPlayerDebuff = true,
					duration = 9.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[432229] = BossAbility:New({ -- Keg Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.9 },
							repeatInterval = { 14.5 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 8.9 },
							repeatInterval = { 14.5 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
					onlyRelevantForTanks = true,
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
					duration = 20.0,
					defaultDuration = 20.0,
					count = 2,
					defaultCount = 2,
					repeatAfter = 3,
					fixedCount = true,
					name = "P2",
				}),
				[3] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 2,
					defaultCount = 2,
					repeatAfter = 2,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- I'pa
			bossIDs = { 210267 },
			journalEncounterID = 2587,
			dungeonEncounterID = 2929,
			instanceID = 2661,
			abilities = {
				[439365] = BossAbility:New({ -- Spouting Stout
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.1 },
							repeatInterval = 47.3,
						}),
					},
					durationHurts = true,
					duration = 8.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[439202] = BossAbility:New({ -- Burning Fermentation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.4 },
							repeatInterval = 47.3,
						}),
					},
					durationHurts = true,
					durationIsPlayerDebuff = true,
					duration = 16.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[439031] = BossAbility:New({ -- Bottoms Uppercut
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.9 },
							repeatInterval = 47.3,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
					onlyRelevantForTanks = true,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		Boss:New({ -- Benk Buzzbee
			bossIDs = { 218002 },
			journalEncounterID = 2588,
			dungeonEncounterID = 2931,
			instanceID = 2661,
			abilities = {
				[438025] = BossAbility:New({ -- Snack Time
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0 },
							repeatInterval = 33.0,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[440134] = BossAbility:New({ -- Honey Marinade
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = 16.0,
						}),
					},
					durationHurts = true,
					durationIsPlayerDebuff = true,
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[439524] = BossAbility:New({ -- Fluttering Wing
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0 },
							repeatInterval = 25.0,
						}),
					},
					durationHurts = true,
					durationIsBossBuff = true,
					duration = 2.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		Boss:New({ -- Goldie Baronbottom
			bossIDs = { 214661 },
			journalEncounterID = 2589,
			dungeonEncounterID = 2930,
			instanceID = 2661,
			abilities = {
				[435560] = BossAbility:New({ -- Spread the Love!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 55.6,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[435622] = BossAbility:New({ -- Let It Hail!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.9 },
							repeatInterval = 55.8,
						}),
					},
					durationHurts = true,
					durationIsPlayerDebuff = true,
					duration = 5.0,
					castTime = 4.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[436637] = BossAbility:New({ -- Burning Ricochet
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.6 },
							repeatInterval = { 14.6, 41.3 },
						}),
					},
					duration = 4.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[436592] = BossAbility:New({ -- Cash Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.1 },
							repeatInterval = { 14.6, 14.6, 26.7 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
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
