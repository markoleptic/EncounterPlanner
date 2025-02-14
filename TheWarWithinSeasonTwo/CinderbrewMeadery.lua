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
---@class RaidInstance
local RaidInstance = Private.classes.RaidInstance

Private.raidInstances[2661] = RaidInstance:New({
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
					},
					eventTriggers = {
						[442525] = EventTrigger:New({ -- Happy Hour over
							combatLogEventType = "SAR",
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
					},
					eventTriggers = {
						[442525] = EventTrigger:New({ -- Happy Hour over
							combatLogEventType = "SAR",
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
					},
					eventTriggers = {
						[442525] = EventTrigger:New({ -- Happy Hour over
							combatLogEventType = "SAR",
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
				[3] = BossPhase:New({
					duration = 50.9,
					defaultDuration = 50.9,
					count = 2,
					defaultCount = 2,
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
					-- TODO: Signify that this might not ever happen
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
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Goldie Baronbottom
			bossID = { 214661 },
			journalEncounterID = 2589,
			dungeonEncounterID = 2930,
			instanceID = 2661,
			abilities = {},
			phases = {},
		}),
	},
})
