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

Private.raidInstances[2649] = RaidInstance:New({
	journalInstanceID = 1267,
	instanceID = 2649,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Captain Dailcry
			bossID = { 207946 },
			journalEncounterID = 2571,
			dungeonEncounterID = 2847,
			instanceID = 2649,
			abilities = {
				[424419] = BossAbility:New({ -- Battle Cry
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = 26.7,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
				}),
				[447270] = BossAbility:New({ -- Hurl Spear
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.1 },
							repeatInterval = 30.3,
						}),
					},
					duration = 8.0,
					castTime = 0.0,
				}),
				[424414] = BossAbility:New({ -- Pierce Armor
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.2 },
							repeatInterval = 12.1,
						}),
					},
					duration = 10.0,
					castTime = 2.5,
				}),
				[447439] = BossAbility:New({ -- Savage Mauling
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.0 },
						}),
					},
					duration = 0.0,
					castTime = 30.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Baron Braunpyke
			bossID = { 207939 },
			journalEncounterID = 2570,
			dungeonEncounterID = 2835,
			instanceID = 2649,
			abilities = {
				[422969] = BossAbility:New({ -- Vindictive Wrath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.2 },
							repeatInterval = 48.1,
						}),
					},
					duration = 20.0,
					castTime = 2.5,
				}),
				[423015] = BossAbility:New({ -- Castigator's Shield
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.0 },
							repeatInterval = 30.3,
						}),
					},
					duration = 5.0,
					castTime = 1.0,
				}),
				[423051] = BossAbility:New({ -- Burning Light
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.0 },
							repeatInterval = 40.1,
						}),
					},
					duration = 12.0,
					castTime = 3.0,
				}),
				[423062] = BossAbility:New({ -- Hammer of Purity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.2 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
				}),
				[446368] = BossAbility:New({ -- Sacrificial Pyre
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.4 },
							repeatInterval = 38.8,
						}),
					},
					duration = 12.0,
					castTime = 0.0,
				}),
				[446525] = BossAbility:New({ -- Unleashed Pyre
					eventTriggers = {
						[446368] = EventTrigger:New({ -- Sacrificial Pyre
							combatLogEventType = "SCC",
							castTimes = { 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				-- TODO: Only allow SAA or SAR, take into account if Castigator's Shield is active, might only be needed during reminders
				-- [446403] = BossAbility:New({ -- Sacrificial Flame
				-- 	eventTriggers = {
				-- 		[446368] = EventTrigger:New({ -- Sacrificial Pyre
				-- 			combatLogEventType = "SCC",
				-- 			castTimes = { 10.0, 10.0, 10.0 },
				-- 		}),
				-- 	},
				-- 	duration = 12.0,
				-- 	castTime = 0.0,
				-- }),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Prioress Murrpray
			bossID = { 207940 },
			journalEncounterID = 2573,
			dungeonEncounterID = 2848,
			instanceID = 2649,
			abilities = {
				[423588] = BossAbility:New({ -- Barrier of Light
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 50.0,
					castTime = 0.0,
				}),
				[423664] = BossAbility:New({ -- Embrace the Light
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 50.0,
					castTime = 0.0,
					-- TODO: Enforce allowed types
					allowedCombatLogEventType = { "SCC", "SCS" },
				}),
				[444546] = BossAbility:New({ -- Purify
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.1 },
							repeatInterval = 28.8,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[444608] = BossAbility:New({ -- Inner Fire
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.6 },
							repeatInterval = 22.6,
						}),
					},
					-- TODO: Create way to override phase 1 cast times or ignore phase 1 cast times and use event trigger repeatInterval instead
					-- eventTriggers = {
					-- 	[423588] = EventTrigger:New({ -- Barrier of Light
					-- 		combatLogEventType = "SAR",
					-- 		castTimes = { 6.4 },
					-- 		repeatCriteria = {
					-- 			spellCount = 1,
					-- 			castTimes = { 22.6 },
					-- 		},
					-- 	}),
					-- },
					duration = 5.2,
					castTime = 2.0,
				}),
				[451605] = BossAbility:New({ -- Holy Flame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.3 },
							repeatInterval = 12.1,
						}),
					},
					-- TODO: Create way to override phase 1 cast times or ignore phase 1 cast times and use event trigger repeatInterval instead
					-- eventTriggers = {
					-- 	[423588] = EventTrigger:New({ -- Barrier of Light
					-- 		combatLogEventType = "SAR",
					-- 		castTimes = { 12.3 },
					-- 		repeatCriteria = {
					-- 			spellCount = 1,
					-- 			castTimes = { 12.1 },
					-- 		},
					-- 	}),
					-- },
					duration = 1.0,
					castTime = 3.0,
				}),
				[428169] = BossAbility:New({ -- Blinding Light
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.5 },
							repeatInterval = 24.2,
						}),
					},
					-- TODO: Create way to override phase 1 cast times or ignore phase 1 cast times and use event trigger repeatInterval instead
					-- eventTriggers = {
					-- 	[423588] = EventTrigger:New({ -- Barrier of Light
					-- 		combatLogEventType = "SAR",
					-- 		castTimes = { 5.7 },
					-- 		repeatCriteria = {
					-- 			spellCount = 1,
					-- 			castTimes = { 24.2 },
					-- 		},
					-- 	}),
					-- },
					duration = 4.0,
					castTime = 4.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 50.0,
					defaultDuration = 50.0,
					name = "P2",
					count = 1,
					defaultCount = 1,
					repeatAfter = 1,
					fixedCount = true,
				}),
			},
		}),
	},
})
