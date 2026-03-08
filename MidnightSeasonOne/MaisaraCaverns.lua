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

Private.dungeonInstances[2874] = DungeonInstance:New({
	journalInstanceID = 1315,
	instanceID = 2874,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Muro'jin and Nekraxx
			bossIDs = {
				247570, -- Muro'jin
				247572, -- Nekraxx
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6029] = 247570, -- Muro'jin
				[6030] = 248404, -- Nekraxx
			},
			journalEncounterID = 2810,
			dungeonEncounterID = 3212,
			instanceID = 2874,
			abilities = {
				[1243900] = BossAbility:New({ -- Fetid Quillstorm (Nekraxx)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.3 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1249479] = BossAbility:New({ -- Carrion Swoop (Nekraxx)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.0 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.5,
					allowedCombatLogEventTypes = {},
				}),
				[1246666] = BossAbility:New({ -- Infected Pinions (Nekraxx)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 30.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[1260648] = BossAbility:New({ -- Barrage (Muro'jin)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.0 },
							repeatInterval = { 40.0 },
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1266480] = BossAbility:New({ -- Flanking Spear (Muro'jin)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.5 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1260731] = BossAbility:New({ -- Freezing Trap (Muro'jin)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = { 45.0 },
						}),
					},
					duration = 40.0,
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
		Boss:New({ -- Vordaza
			bossIDs = {
				248595, -- Vordaza
				250443, -- Unstable Phantom
			},
			journalEncounterCreatureIDsToBossIDs = {
				[6068] = 248595, -- Vordaza
				[6069] = 250443, -- Unstable Phantom
			},
			journalEncounterID = 2811,
			dungeonEncounterID = 3213,
			instanceID = 2874,
			abilities = {
				[1251554] = BossAbility:New({ -- Drain Soul
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0 },
							repeatInterval = { 33.5, 56.0 },
						}),
					},
					duration = 4.0,
					castTime = 1.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1252054] = BossAbility:New({ -- Unmake
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.4 },
							repeatInterval = { 33.5, 56.0 },
						}),
					},
					duration = 4.5,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1251204] = BossAbility:New({ -- Wrest Phantoms
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.2 },
							repeatInterval = { 33.5, 56.0 },
						}),
					},
					duration = 4.5,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1264987] = BossAbility:New({ -- Withering Miasma
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
		Boss:New({ -- Rak'tul, Vessel of Souls
			bossIDs = { 248605 },
			journalEncounterCreatureIDsToBossIDs = {
				[6062] = 248605, -- Rak'tul
				[6071] = 251047, -- Soulbind Totem
				[6072] = 1531, -- Lost Soul
				[6070] = 251674, -- Malignant Soul
			},
			journalEncounterID = 2812,
			dungeonEncounterID = 3214,
			instanceID = 2874,
			abilities = {
				[1252676] = BossAbility:New({ -- Crush Souls
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.2 },
							repeatInterval = { 26.5, 93.6 },
						}),
					},
					duration = 0.0,
					castTime = 4.5,
					allowedCombatLogEventTypes = {},
				}),
				[1253909] = BossAbility:New({ -- Soul Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 74.7 },
							repeatInterval = { 120.0 },
						}),
					},
					duration = 0.0,
					castTime = 45.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253788] = BossAbility:New({ -- Soulrending Roar
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 70.1 },
							repeatInterval = { 120.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251023] = BossAbility:New({ -- Spiritbreaker
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.0 },
							repeatInterval = { 26.4, 26.4, 67.2 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
