local _, Namespace = ...

---@class Private
local Private = Namespace
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

Private.dungeonInstances[2805] = DungeonInstance:New({
	journalInstanceID = 1299,
	instanceID = 2805,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Emberdawn
			bossIDs = { 231606 },
			journalEncounterCreatureIDsToBossIDs = {
				[5764] = 231606, -- Emberdawn
			},
			journalEncounterID = 2655,
			dungeonEncounterID = 3056,
			instanceID = 2805,
			abilities = {
				[465904] = BossAbility:New({ -- Burning Gale
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.2 },
							repeatInterval = { 55.0 },
						}),
					},
					duration = 16.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[466064] = BossAbility:New({ -- Searing Beak
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.8, 40.3, 12.2 },
							repeatInterval = { 42.9, 12.4 },
						}),
					},
					duration = 8.0,
					castTime = 3.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[466556] = BossAbility:New({ -- Flaming Updraft
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.6, 40.1, 17.0 },
							repeatInterval = { 38.1, 17.0 },
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		Boss:New({ -- Derelict Duo
			bossIDs = {
				231626, -- Kalis
				231629, -- Latch
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5839] = 231626, -- Kalis
				[5840] = 231629, -- Latch
			},
			journalEncounterID = 2656,
			dungeonEncounterID = 3057,
			instanceID = 2805,
			abilities = {
				[474105] = BossAbility:New({ -- Curse of Darkness (Kalis)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.7 },
							repeatInterval = { 58.1 },
						}),
					},
					duration = 12.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[472888] = BossAbility:New({ -- Bone Hack (Latch)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.4 },
							repeatInterval = { 58.1 },
						}),
					},
					duration = 3.0,
					castTime = 2.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[472795] = BossAbility:New({ -- Heaving Yank (Latch)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 48.1 },
							repeatInterval = { 58.1 },
						}),
					},
					duration = 0.0,
					castTime = 7.0,
					allowedCombatLogEventTypes = {},
				}),
				[472745] = BossAbility:New({ -- Splattering Spew (Latch)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.0, 27.3, 30.8 },
							repeatInterval = { 27.3, 31.5 },
						}),
					},
					duration = 10.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		-- Boss:New({ -- Commander Kroluk
		-- 	bossIDs = { 231631 },
		-- 	journalEncounterCreatureIDsToBossIDs = {
		-- 		[5845] = 231631, -- Commander Kroluk
		-- 		[6035] = 234061, -- Phantasmal Mystic
		-- 		[6036] = 232447, -- Spectral Axethrower
		-- 		[6034] = 258868, -- Haunting Grunt
		-- 	},
		-- 	journalEncounterID = 2657,
		-- 	dungeonEncounterID = 3058,
		-- 	instanceID = 2805,
		-- 	abilities = {},
		-- 	phases = {
		-- 		[1] = BossPhase:New({
		-- 			duration = 180.0,
		-- 			defaultDuration = 180.0,
		-- 		}),
		-- 	},
		-- }),
		Boss:New({ -- The Restless Heart
			bossIDs = { 231636 },
			journalEncounterCreatureIDsToBossIDs = {
				[5844] = 231636, -- The Restless Heart
			},
			journalEncounterID = 2658,
			dungeonEncounterID = 3059,
			instanceID = 2805,
			abilities = {
				[468429] = BossAbility:New({ -- Bullseye Windblast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.4 },
							repeatInterval = 65.0,
						}),
					},
					duration = 0.0,
					castTime = 7.0,
					allowedCombatLogEventTypes = {},
				}),
				[472556] = BossAbility:New({ -- Arrow Rain
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.5, 38.0 },
							repeatInterval = 65.0,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[472662] = BossAbility:New({ -- Tempest Slash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 57.0 },
							repeatInterval = 65.0,
						}),
					},
					duration = 10.0,
					castTime = 2.5,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[474528] = BossAbility:New({ -- Bolt Gale
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 75.0 },
							repeatInterval = 65.0,
						}),
					},
					duration = 5.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253986] = BossAbility:New({ -- Gust Shot
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 59.9 },
							repeatInterval = 65.0,
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
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
