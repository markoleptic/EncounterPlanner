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
					duration = 6.0,
					castTime = 1.5,
				}),
				[423693] = BossAbility:New({ -- Luring Candleflame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.0 },
							repeatInterval = 38.5,
						}),
					},
					duration = 10.0,
					castTime = 0.0,
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
				}),
				[429093] = BossAbility:New({ -- Underhanded Track-tics
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.4 },
							repeatInterval = 50.2,
						}),
					},
					duration = 20.0,
					secondaryDuration = 20.0,
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
		Boss:New({ -- Blazikon
			bossIDs = { 208743 },
			journalEncounterID = 2559,
			dungeonEncounterID = 2826,
			instanceID = 2651,
			abilities = {
				[421817] = BossAbility:New({ -- Wicklighter Barrage
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.9 },
							repeatInterval = 60.0,
						}),
					},
					-- TODO: Consider distinguishing targeting duration
					duration = 6.0,
					castTime = 3.0,
				}),
				[424212] = BossAbility:New({ -- Incite Flames
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 37.7 },
							repeatInterval = 60.7,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[423109] = BossAbility:New({ -- Enkindling Inferno
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.7 },
							repeatInterval = 29.1,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[425394] = BossAbility:New({ -- Dousing Breath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.4 },
							repeatInterval = 55.8,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[421910] = BossAbility:New({ -- Extinguishing Gust
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 59.5 },
							repeatInterval = 13.3,
						}),
					},
					duration = 30.0,
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
		Boss:New({ -- The Candle King
			bossIDs = { 208745 },
			journalEncounterID = 2560,
			dungeonEncounterID = 2787,
			instanceID = 2651,
			abilities = {
				[420659] = BossAbility:New({ -- Eerie Molds
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.0 },
							repeatInterval = 31.6,
						}),
					},
					duration = 6.0,
					castTime = 1.5,
				}),
				[426145] = BossAbility:New({ -- Paranoid Mind
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.5 },
							repeatInterval = 20.7,
						}),
					},
					duration = 4.0,
					castTime = 2.5,
				}),
				[422648] = BossAbility:New({ -- Darkflame Pickaxe
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.4 },
							repeatInterval = 17.0, -- TODO often delayed
						}),
					},
					duration = 0.0,
					castTime = 6.0,
				}),
				[420696] = BossAbility:New({ -- Throw Darkflame
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.6 },
							repeatInterval = 17.0, -- TODO often delayed
						}),
					},
					-- TODO: Consider distinguishing targeting duration
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
					-- TODO: Consider distinguishing channelling
					castTime = 6.0,
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
				}),
				[427011] = BossAbility:New({ -- Shadowblast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.9 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					-- TODO: Consider distinguishing channelling
					castTime = 6.0,
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
