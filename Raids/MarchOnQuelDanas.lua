local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
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

Private.dungeonInstances[2913] = DungeonInstance:New({
	journalInstanceID = 1308,
	instanceID = 2913,
	customGroups = { "MidnightSeasonOne" },
	isRaid = true,
	hasHeroic = true,
	bosses = {
		Boss:New({ -- Belo'ren, Child of Al'ar
			bossIDs = {
				249637, -- Belo'ren
				246728, -- Void Ember
				246729, -- Light Ember
			},
			journalEncounterCreatureIDsToBossIDs = {
				-- [5904] = 249637, -- Belo'ren
				-- [5973] = 246728, -- Void Ember
				-- [5974] = 246729, -- Light Ember
			},
			journalEncounterID = 2739,
			dungeonEncounterID = 3182,
			instanceID = 2913,
			abilities = {},
			-- phases = {},
			abilitiesHeroic = {},
			-- phasesHeroic = {},
		}),
		Boss:New({ -- Midnight Falls
			bossIDs = {
				214650, -- L'ura
				250615, -- Midnight Crystal
				250616, -- Dusk Crystal
				251180, -- Dawn Crystal
			},
			journalEncounterCreatureIDsToBossIDs = {
				-- [5905] = 214650, -- L'ura
				-- [6111] = 250615, -- Midnight Crystal
				-- [6112] = 250616, -- Dusk Crystal
				-- [6114] = 251180, -- Dawn Crystal
			},
			journalEncounterID = 2740,
			dungeonEncounterID = 3183,
			instanceID = 2913,
			abilities = {
				[1255743] = BossAbility:New({ -- Total Eclipse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 184.0 },
							castSignifiesPhaseEnd = true,
							durationExtendsIntoNextPhase = true,
						}),
					},
					duration = 30.0,
					castTime = 6.5,
				}),
				[1282043] = BossAbility:New({ -- Into the Darkwell
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 35.1 },
							castSignifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 6.0,
				}),
				[1281123] = BossAbility:New({ -- Dark Meltdown
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 90.5 },
							castSignifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 8.0,
				}),
				[1276278] = BossAbility:New({ -- Reintegration
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 160.5, 0.0 },
							castSignifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[1282006] = BossAbility:New({ -- Abyssal Pool
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					defaultHidden = true,
				}),
				[1282412] = BossAbility:New({ -- Core Harvest
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 26.5, 30.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
				}),
				[1266587] = BossAbility:New({ -- Dark Constellation
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 22.9, 117.6, 12.8 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1284528] = BossAbility:New({ -- Galvanize
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 6.5, 30.0, 30.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
				}),
				[1249609] = BossAbility:New({ -- Dark Rune
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.3, 62.0, 62.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 23.1, 20.0, 34.9, 20.1, 36.3, 20.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1285708] = BossAbility:New({ -- Grim Symphony
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 47.1, 62.0, 62.0 },
						}),
					},
					duration = 2.5,
					castTime = 3.0,
				}),
				[1276525] = BossAbility:New({ -- Heaven & Hell
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 20.0, 20.0, 20.0, 20.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
				}),
				[1253915] = BossAbility:New({ -- Heaven's Glaives
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.1, 62.0, 62.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[1267049] = BossAbility:New({ -- Heaven's Lance
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.1, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 13.5, 20.0, 20.0, 20.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 40.0, 0.0, 30.0, 0.0, 30.0, 0.0, 30.1, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					tankAbility = true,
				}),
				[1287447] = BossAbility:New({ -- Midnight Perpetual
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 75.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
				}),
				[1275539] = BossAbility:New({ -- Severance
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 2.1, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 10.0,
				}),
				[1284931] = BossAbility:New({ -- Termination Prism
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0, 62.0, 62.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[1284934] = BossAbility:New({ -- Terminate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.1, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0 },
							repeatInterval = { 59.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1251331] = BossAbility:New({ -- The Dark Archangel
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 59.0, 0.0, 55.0, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
				}),
				[1281184] = BossAbility:New({ -- Criticality
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 17.2, 29.5, 29.5, 17.9 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 184.0 + 6.5,
					defaultDuration = 184.0 + 6.5,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 35.1 + 6.0,
					defaultDuration = 35.1 + 6.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 90.5 + 8.0,
					defaultDuration = 90.5 + 8.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedDuration = true,
				}),
				[4] = BossPhase:New({
					duration = 160.5 + 5.0,
					defaultDuration = 160.5 + 5.0,
					count = 1,
					defaultCount = 1,
					name = "P3",
					fixedDuration = true,
				}),
				[5] = BossPhase:New({
					duration = 78.0,
					defaultDuration = 78.0,
					count = 1,
					defaultCount = 1,
					name = "P4",
					maxDuration = 84.0,
				}),
			},
			abilitiesHeroic = {},
			-- phasesHeroic = {},
		}),
	},
})
