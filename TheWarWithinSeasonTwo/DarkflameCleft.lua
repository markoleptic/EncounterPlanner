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

Private.dungeonInstances[2651] = DungeonInstance:New({
	journalInstanceID = 1210,
	instanceID = 2651,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Ol' Waxbeard
			bossIDs = {
				210149, -- Ol' Waxbeard (boss)
				210153, -- Ol' Waxbeard (mount)
			},
			journalEncounterID = 2569,
			dungeonEncounterID = 2829,
			instanceID = 2651,
			abilities = {
				[422245] = BossAbility:New({ -- Rock Buster
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 1.3 },
							repeatInterval = 13.3,
						}),
					},
					durationIsPlayerDebuff = true,
					duration = 6.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[423693] = BossAbility:New({ -- Luring Candleflame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.0 },
							repeatInterval = 40.0,
						}),
					},
					durationIsPlayerDebuff = true,
					duration = 10.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[422116] = BossAbility:New({ -- Reckless Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.8 },
							repeatInterval = 35.2,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[429093] = BossAbility:New({ -- Underhanded Track-tics
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 55.0 },
							repeatInterval = 80.0,
						}),
					},
					duration = 0.0,
					castTime = 20.0,
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
		Boss:New({ -- Blazikon
			bossIDs = { 208743 },
			journalEncounterID = 2559,
			dungeonEncounterID = 2826,
			instanceID = 2651,
			abilities = {
				[421817] = BossAbility:New({ -- Wicklighter Barrage
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.7 },
							repeatInterval = 60.7,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[424212] = BossAbility:New({ -- Incite Flames
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.1 },
							repeatInterval = 60.7,
						}),
					},
					duration = 0.0,
					castTime = 2.1,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[423109] = BossAbility:New({ -- Enkindling Inferno
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.7 },
							repeatInterval = 30.35,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[425394] = BossAbility:New({ -- Dousing Breath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.1, 55.8 },
							repeatInterval = 60.7,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[421910] = BossAbility:New({ -- Extinguishing Gust
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.0 },
							repeatInterval = 60.7,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
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
		Boss:New({ -- The Candle King
			bossIDs = { 208745 },
			journalEncounterID = 2560,
			dungeonEncounterID = 2787,
			instanceID = 2651,
			abilities = {
				[420659] = BossAbility:New({ -- Eerie Molds
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.2 },
							repeatInterval = 27.0,
						}),
					},
					duration = 6.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[426145] = BossAbility:New({ -- Paranoid Mind
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.9, 10.9 },
							repeatInterval = 12.1,
						}),
					},
					duration = 4.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[421277] = BossAbility:New({ -- Darkflame Pickaxe
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.6 },
							repeatInterval = 26.7,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[420696] = BossAbility:New({ -- Throw Darkflame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.6 },
							repeatInterval = 26.7,
						}),
					},
					allowedCombatLogEventTypes = {}, -- Never cast, 3 debuffs just go out
					duration = 6.0,
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
		Boss:New({ -- The Darkness
			bossIDs = {
				212777, -- Massive Candle
				208747, -- The Darkness
			},
			journalEncounterID = 2561,
			dungeonEncounterID = 2788,
			instanceID = 2651,
			abilities = {
				[427157] = BossAbility:New({ -- Call Darkspawn
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.9 },
							repeatInterval = 46.1,
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					castIsChannel = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[427025] = BossAbility:New({ -- Umbral Slash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.4 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[427011] = BossAbility:New({ -- Shadowblast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.9 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[428266] = BossAbility:New({ -- Eternal Darkness
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.7 },
							repeatInterval = 63.2,
						}),
					},
					duration = 4.0,
					castTime = 3.0,
					durationHurts = true,
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
