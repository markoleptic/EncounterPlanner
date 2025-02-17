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
			bossID = { 210271 },
			journalEncounterID = 2586,
			dungeonEncounterID = 2900,
			instanceID = 2661,
			abilities = {
				[442525] = BossAbility:New({ -- Happy Hour
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 20.0,
					castTime = 2.0,
				}),
				[432198] = BossAbility:New({ -- Blazing Belch
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 17.6, 23.1 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[432179] = BossAbility:New({ -- Throw Cinderbrew
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 14.0, 18.2 },
						}),
					},
					duration = 9.0,
					castTime = 1.5,
				}),
				[432229] = BossAbility:New({ -- Keg Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 9.1, 14.5, 14.5 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 27.8,
					defaultDuration = 27.8,
					count = 1,
					defaultCount = 1,
					fixedDuration = true,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 20.0,
					defaultDuration = 20.0,
					count = 3,
					defaultCount = 3,
					repeatAfter = 3,
					name = "P2",
				}),
				[3] = BossPhase:New({ -- TODO: Scuffed
					duration = 50.9,
					defaultDuration = 50.9,
					count = 3,
					defaultCount = 3,
					repeatAfter = 2,
					fixedDuration = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- I'pa
			bossID = { 210267 },
			journalEncounterID = 2587,
			dungeonEncounterID = 2929,
			instanceID = 2661,
			abilities = {
				[439365] = BossAbility:New({ -- Spouting Stout
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.6 },
							repeatInterval = 47.3,
						}),
					},
					duration = 8.0,
					castTime = 2.0,
				}),
				[439202] = BossAbility:New({ -- Burning Fermentation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.0 },
							repeatInterval = 47.3,
						}),
					},
					duration = 16.0,
					castTime = 2.0,
				}),
				[439031] = BossAbility:New({ -- Bottoms Uppercut
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.3 },
							repeatInterval = 47.3,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[440147] = BossAbility:New({ -- Fill 'Er Up
					phases = {},
					duration = 0.0,
					castTime = 0.0,
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
			bossID = { 218002 },
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
				}),
				[440134] = BossAbility:New({ -- Honey Marinade
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = 14.0,
						}),
					},
					duration = 5.0,
					castTime = 2.0,
				}),
				[439524] = BossAbility:New({ -- Fluttering Wing
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0 },
							repeatInterval = 23.0,
						}),
					},
					duration = 2.0,
					castTime = 1.5,
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
			bossID = { 214661 },
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
				}),
				[435622] = BossAbility:New({ -- Let It Hail!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.9 },
							repeatInterval = 55.8,
						}),
					},
					duration = 5.0,
					castTime = 4.5,
				}),
				[436644] = BossAbility:New({ -- Burning Ricochet
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.6 },
							repeatInterval = { 14.6, 41.3 },
						}),
					},
					duration = 4.0,
					castTime = 6.0,
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
