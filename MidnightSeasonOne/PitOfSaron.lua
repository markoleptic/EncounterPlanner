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

Private.dungeonInstances[658] = DungeonInstance:New({
	journalInstanceID = 278,
	instanceID = 658,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Forgemaster Garfrost
			bossIDs = { 36494 },
			journalEncounterCreatureIDsToBossIDs = {
				[1182] = 36494, -- Forgemaster Garfrost
			},
			journalEncounterID = 608,
			dungeonEncounterID = 1999,
			instanceID = 658,
			abilities = {
				[1261847] = BossAbility:New({ -- Cryostomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.5 },
							repeatInterval = 41.5,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1262029] = BossAbility:New({ -- Glacial Overload
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 33.0 },
							repeatInterval = 41.5,
						}),
					},
					duration = 3.5,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1261546] = BossAbility:New({ -- Orebreaker
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = 41.5,
						}),
					},
					duration = 8.0,
					castTime = 4.5,
					allowedCombatLogEventTypes = {},
				}),
				[1261299] = BossAbility:New({ -- Throw Saronite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.0 },
							repeatInterval = 41.5,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1261806] = BossAbility:New({ -- Radiating Chill
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					durationLastsUntilEndOfPhase = true,
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
		Boss:New({ -- Ick and Krick
			bossIDs = {
				36477, -- Krick
				36476, -- Ick
				255037, -- Shade of Krick
			},
			journalEncounterCreatureIDsToBossIDs = {
				[1184] = 36477, -- Krick
				[1183] = 36476, -- Ick
				[6108] = 255037, -- Shade of Krick
			},
			journalEncounterID = 609,
			dungeonEncounterID = 2001,
			instanceID = 658,
			abilities = {
				[1264363] = BossAbility:New({ -- Get 'Em, Ick! (Krick)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 50.1 },
							repeatInterval = 82.8,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1264027] = BossAbility:New({ -- Shade Shift (Krick)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 82.8,
						}),
					},
					duration = 12.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1264336] = BossAbility:New({ -- Plague Expulsion (Ick)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.1 },
							repeatInterval = { 19.0, 63.8 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1264287] = BossAbility:New({ -- Blight Smash (Ick)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.1 },
							repeatInterval = { 19.0, 63.8 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1264453] = BossAbility:New({ -- Lumbering Fixation (Ick)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 54.8, 7.0, 7.0, 7.0 },
							repeatInterval = { 62.0, 7.0, 7.0, 7.0 },
						}),
					},
					duration = 5.0,
					castTime = 2.0,
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
		Boss:New({ -- Scourgelord Tyrannus
			bossIDs = {
				36658, -- Scourgelord Tyrannus
				252653, -- Rimefang
				254691, -- Scourge Plaguespreader
				254684, -- Rotling
			},
			journalEncounterCreatureIDsToBossIDs = {
				[1185] = 36658, -- Scourgelord Tyrannus
				[6091] = 252653, -- Rimefang
				[6146] = 254691, -- Scourge Plaguespreader
				[6147] = 254684, -- Rotling
			},
			journalEncounterID = 610,
			dungeonEncounterID = 2000,
			instanceID = 658,
			abilities = {
				[1263406] = BossAbility:New({ -- Army of the Dead
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 52.0 },
							repeatInterval = 85.0,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1276648] = BossAbility:New({ -- Bone Infusion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 85.0,
						}),
					},
					duration = 8.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1263756] = BossAbility:New({ -- Death's Grasp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.0 },
							repeatInterval = 85.0,
						}),
					},
					duration = 3.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262582] = BossAbility:New({ -- Scourgelord's Brand
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.0 },
							repeatInterval = { 28.0, 57.0 },
						}),
					},
					duration = 5.0,
					castTime = 2.5,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1263671] = BossAbility:New({ -- Scourgelord's Reckoning
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.4 },
							repeatInterval = { 28.0, 57.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1262745] = BossAbility:New({ -- Rime Blast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.0 },
							repeatInterval = { 28.0, 57.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[1276948] = BossAbility:New({ -- Ice Barrage
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 69.0 },
							repeatInterval = { 85.0 },
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
