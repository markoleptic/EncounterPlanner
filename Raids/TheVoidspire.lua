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

Private.dungeonInstances[2912] = DungeonInstance:New({
	journalInstanceID = 1307,
	instanceID = 2912,
	customGroups = { "MidnightSeasonOne" },
	isRaid = true,
	hasHeroic = true,
	bosses = {
		Boss:New({ -- Averzian
			bossIDs = {
				240435, -- Averzian
				252918, -- Abyssal Voidshaper
				251176, -- Voidmaw
				255304, -- Shadowguard Stalwart
				251267, -- Obscurion Endwalker
				257950, -- Abyssal Malus
				256757, -- Voidbound Annihilator
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5911] = 240435, -- Averzian
				[6065] = 252918, -- Abyssal Voidshaper
				[6073] = 251176, -- Voidmaw
				[6064] = 255304, -- Shadowguard Stalwart
				[6063] = 251267, -- Obscurion Endwalker
				[6143] = 257950, -- Abyssal Malus
				[6152] = 256757, -- Voidbound Annihilator
			},
			journalEncounterID = 2733,
			dungeonEncounterID = 3176,
			instanceID = 2912,
			abilities = {
				[1249251] = BossAbility:New({ -- Dark Upheaval
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.0 },
							repeatInterval = { 48.0, 36.0, 102.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1249266] = BossAbility:New({ -- Umbral Collapse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.0 },
							repeatInterval = { 80.2, 105.8, 80.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.5,
					allowedCombatLogEventTypes = {},
				}),
				[1260206] = BossAbility:New({ -- Umbral Collapse 2 ??
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 39.5 },
							repeatInterval = { 80.2, 105.8, 80.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.5,
					allowedCombatLogEventTypes = {},
				}),
				[1249714] = BossAbility:New({ -- Umbral Barrier
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.1 },
							repeatInterval = { 80.0, 106.0, 80.0, 104.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251361] = BossAbility:New({ -- Shadow's Advance
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 94.0 },
							repeatInterval = { 106.0, 80.0, 104.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1255702] = BossAbility:New({ -- Void Fall
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[1260712] = BossAbility:New({ -- Oblivion's Wrath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.0 },
							repeatInterval = { 18.0, 168.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262036] = BossAbility:New({ -- Void Rupture
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.6 },
							repeatInterval = { 80.0, 106.0, 80.0, 104.0 },
						}),
					},
					duration = 0.0,
					castTime = 35.0,
					allowedCombatLogEventTypes = {},
				}),
				[1261249] = BossAbility:New({ -- Void Rupture 2
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 52.6 },
							repeatInterval = { 80.0, 106.0, 80.0, 104.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262776] = BossAbility:New({ -- Shadow's Advance
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1280015] = BossAbility:New({ -- Void Marked
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = { 80.0, 106.0, 80.0, 104.0 },
						}),
					},
					duration = 25.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
			abilitiesHeroic = {
				[1249251] = BossAbility:New({ -- Dark Upheaval
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.2 },
							repeatInterval = { 36.0, 36.0, 79.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1249266] = BossAbility:New({ -- Umbral Collapse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.3 },
							repeatInterval = { 72.0, 79.0, 72.0, 77.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.5,
					allowedCombatLogEventTypes = {},
				}),
				[1260206] = BossAbility:New({ -- Umbral Collapse 2??
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.6 },
							repeatInterval = { 72.0, 79.0, 72.0, 77.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.5,
					allowedCombatLogEventTypes = {},
				}),
				[1249714] = BossAbility:New({ -- Umbral Barrier
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.5 },
							repeatInterval = { 71.5, 79.0, 72.0, 77.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251361] = BossAbility:New({ -- Shadow's Advance
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 84.0 },
							repeatInterval = { 79.0, 72.0, 77.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1255702] = BossAbility:New({ -- Void Fall
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 125.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = {},
				}),
				[1260712] = BossAbility:New({ -- Oblivion's Wrath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 48.0 },
							repeatInterval = { 18.1, 132.9 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262036] = BossAbility:New({ -- Void Rupture
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.0 },
							repeatInterval = { 71.6, 79.0, 72.0, 77.0 },
						}),
					},
					duration = 0.0,
					castTime = 35.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262776] = BossAbility:New({ -- Shadow's Advance
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1270946] = BossAbility:New({ -- Desolation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 58.1, 150.9 },
						}),
					},
					duration = 0.0,
					castTime = 7.0,
					allowedCombatLogEventTypes = {},
				}),
				-- [1251583] = BossAbility:New({ -- March of the Endless
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = { 336.6 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 3.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 339.6,
					defaultDuration = 339.6,
				}),
			},
		}),
		Boss:New({ -- Vorasius
			bossIDs = {
				240434, -- Vorasius
				250564, -- Blistercreep
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5913] = 240434, -- Vorasius
				[5981] = 250564, -- Blistercreep
			},
			journalEncounterID = 2734,
			dungeonEncounterID = 3177,
			instanceID = 2912,
			abilities = {
				-- [1258967] = BossAbility:New({ -- Focused Aggression UNCONFIRMED
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = { 361.0 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 10.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
			abilitiesHeroic = {
				[1265018] = BossAbility:New({ -- Fixate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 71.0 },
							repeatInterval = { 123.1 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1258967] = BossAbility:New({ -- Focused Aggression
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 361.0 },
						}),
					},
					duration = 0.0,
					castTime = 10.0,
					allowedCombatLogEventTypes = {},
				}),
				[1257629] = BossAbility:New({ -- Void Breath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 96.3 },
							repeatInterval = 121.0,
						}),
					},
					duration = 15.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1254199] = BossAbility:New({ -- Parasite Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 57.3 },
							repeatInterval = 123.1,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1244097] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.8 },
							repeatInterval = { 109.7, 131.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241686] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.0 },
							repeatInterval = { 129.2, 111.5 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241692] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.0 },
							repeatInterval = { 9.7, 110.5 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241768] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 36.5, 41.5 },
							repeatInterval = { 87.7, 25.6, 85.9, 47.1 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241769] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.2, 22.0 },
							repeatInterval = { 87.7, 44.9, 86.1, 27.6 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241770] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.8 },
							repeatInterval = { 109.7, 131.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241836] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.0 },
							repeatInterval = { 240.7 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1244012] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.0 },
							repeatInterval = { 129.2, 111.5 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1244100] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 36.5, 41.5 },
							repeatInterval = { 87.7, 25.6, 85.9, 47.1 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1244101] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.2, 22.0 },
							repeatInterval = { 87.7, 44.9, 86.1, 27.6 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272329] = BossAbility:New({ -- Shadowclaw Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.5, 9.7 },
							repeatInterval = { 22.0, 9.7, 78.0, 9.7, 25.6, 9.5, 76.4, 9.7, 27.6, 9.7 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1241844] = BossAbility:New({ -- Smashed
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.1 },
							repeatInterval = { 9.7, 110.0 },
						}),
					},
					halfHeight = true,
					duration = 60.0,
					castTime = 0.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1260052] = BossAbility:New({ -- Primordial Roar
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.2 },
							repeatInterval = { 120.5 },
						}),
					},
					duration = 60.0,
					castTime = 0.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
		}),
		Boss:New({ -- Vaelgor & Ezzorak
			bossIDs = {
				242056, -- Vaelgor
				254109, -- Ezzorak
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5949] = 242056, -- Vaelgor
				[6006] = 254109, -- Ezzorak
			},
			journalEncounterID = 2735,
			dungeonEncounterID = 3178,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {
				[1244221] = BossAbility:New({ -- Dread Breath (Vaelgor)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.3, 34.0, 35.0, 85.7, 45.0, 67.2, 57.6 },
						}),
					},
					duration = 21.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1245391] = BossAbility:New({ -- Gloom (Ezzorak)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 50.5, 98.6, 45.2, 44.8, 78.7 },
						}),
					},
					duration = 21.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = {},
				}),
				[1265152] = BossAbility:New({ -- Impale (Ezzorak)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 142.2, 25.0, 25.2, 27.4, 62.2, 32.6, 33.9 },
						}),
					},
					duration = 3.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1249748] = BossAbility:New({ -- Midnight Flames (Both)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 115.4, 0.0, 132.3, 0.0 },
						}),
					},
					duration = 25.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1258744] = BossAbility:New({ -- Midnight Manifestation (Xal'atath)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.3, 20.0, 20.0, 93.8, 20.0, 20.0, 92.2, 26.4, 25.9, 27.1 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1245645] = BossAbility:New({ -- Rakfang (Ezzorak)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.5, 25.1, 25.0, 25.0, 52.5, 25.0, 25.2, 27.4, 62.2, 33.0, 33.5 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1264467] = BossAbility:New({ -- Tail Lash (Vaelgor)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.8, 25.1, 24.9, 31.5, 184.4, 32.7, 42.0, 27.1 },
						}),
					},
					duration = 4.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1265131] = BossAbility:New({ -- Vaelwing (Vaelgor)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.3, 25.0, 25.0, 31.5, 58.6, 27.1, 23.4, 24.7, 50.7, 32.7, 42.1, 27.1 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[1244917] = BossAbility:New({ -- Void Howl (Ezzorak)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.5, 45.0, 73.6, 34.0, 35.0, 84.2, 59.7 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				-- [1262623] = BossAbility:New({ -- Nullbeam (Vaelgor) (TOO MUCH VARIANCE)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = { 18.8 , 41.5 , 91.5 , 90.1 , 70.7 , 55.5 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
		}),
		Boss:New({ -- Fallen-King Salhadaar
			bossIDs = {
				240432, -- Fallen-King Salhadaar
				246665, -- Concentrated Void
				251791, -- Fractured Image
				255280, -- Enduring Void
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5908] = 240432, -- Fallen-King Salhadaar
				[6090] = 246665, -- Concentrated Void
				[6067] = 251791, -- Fractured Image
				[6154] = 255280, -- Enduring Void
			},
			journalEncounterID = 2736,
			dungeonEncounterID = 3179,
			instanceID = 2912,
			abilities = {
				[1260823] = BossAbility:New({ -- Despotic Command
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.9, 46.5 },
						}),
					},
					duration = 12.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = {},
				}),
				[1254081] = BossAbility:New({ -- Fractured Projection
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.7, 46.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253032] = BossAbility:New({ -- Shattering Twilight
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 45.0, 46.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 45.0, 46.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {},
			abilitiesHeroic = {
				[1254092] = BossAbility:New({ -- Attuned to the Nether (Fractured Image)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.3, 45.7 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246175] = BossAbility:New({ -- Cosmic Unraveling
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 100.8 },
							castSignifiesPhaseEnd = true,
							durationExtendsIntoNextPhase = true,
						}),
					},
					duration = 20.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[1243453] = BossAbility:New({ -- Desperate Measures
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.9, 45.4 },
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = {},
				}),
				[1260823] = BossAbility:New({ -- Despotic Command
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 27.8, 46.5 },
						}),
					},
					duration = 12.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = {},
				}),
				[1254081] = BossAbility:New({ -- Fractured Projection
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.4, 45.4 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1271577] = BossAbility:New({ -- Instability
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							castSignifiesPhaseEnd = true,
							durationExtendsIntoNextPhase = true,
						}),
					},
					duration = 15.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1253032] = BossAbility:New({ -- Shattering Twilight
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 42.6, 45.5 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 42.6, 45.5 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1250686] = BossAbility:New({ -- Twisting Obscurity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.7, 45.4 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 15.7, 45.4 },
						}),
					},
					duration = 23.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1260030] = BossAbility:New({ -- Uncontainable Cosmos
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 20.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 100.8 + 1.5,
					defaultDuration = 100.8 + 1.5,
					count = 4,
					defaultCount = 4,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 20.0,
					defaultDuration = 20.0,
					count = 3,
					defaultCount = 3,
					name = "P2",
					repeatAfter = 1,
					fixedDuration = true,
				}),
			},
		}),
		Boss:New({ -- Lightblinded Vanguard
			bossIDs = {
				250589, -- War Chaplain Senn
				250587, -- General Amias Bellamy
				250588, -- Commander Venel Lightblood
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5972] = 250589, -- War Chaplain Senn
				[5971] = 250587, -- General Amias Bellamy
				[5970] = 250588, -- Commander Venel Lightblood
			},
			journalEncounterID = 2737,
			dungeonEncounterID = 3180,
			instanceID = 2912,
			abilities = {
				[1246162] = BossAbility:New({ -- Aura of Devotion (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.4 },
							repeatInterval = 159.0,
						}),
					},
					duration = 25.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248451] = BossAbility:New({ -- Aura of Peace (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 134.2 },
							repeatInterval = 159.0,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248449] = BossAbility:New({ -- Aura of Wrath (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 79.0 },
							repeatInterval = 159.0,
						}),
					},
					duration = 15.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246497] = BossAbility:New({ -- Avenger's Shield (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 14.9, 54.0, 36.0, 18.0, 36.0, 18.0, 54.0, 36.0, 18.0, 20.0, 16.0, 18.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1258514] = BossAbility:New({ -- Blinding Light (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 40.2, 130.1, 43.9, 50.9, 60.8 },
						}),
					},
					duration = 10.0,
					castTime = 10.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246765] = BossAbility:New({ -- Divine Storm (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								15.0,
								18.0,
								18.0,
								18.0,
								72.0,
								18.0,
								18.0,
								18.0,
								18.0,
								18.0,
								36.0,
								36.0,
								18.0,
								18.0,
								18.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272310] = BossAbility:New({ -- Divine Storm (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 123.0, 162.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248644] = BossAbility:New({ -- Divine Toll (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 29.4, 52.7, 106.0, 53.0, 106.1 },
						}),
					},
					duration = 18.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251812] = BossAbility:New({ -- Final Verdict (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 29.3, 36.0, 54.0, 18.0, 18.0, 18.0, 53.9, 72.0, 18.0, 18.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1251857] = BossAbility:New({ -- Judgment (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 22.1, 36.0, 54.0, 18.0, 18.0, 18.0, 54.0, 54.0, 18.0, 18.0, 18.0 },
						}),
					},
					duration = 5.0,
					castTime = 3.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1246736] = BossAbility:New({ -- Judgment (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 26.0, 36.0, 54.0, 18.0, 18.0, 18.0, 54.0, 72.0, 18.0, 18.0 },
						}),
					},
					duration = 5.0,
					castTime = 3.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1258662] = BossAbility:New({ -- Light Infused (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 26.4, 52.7, 55.0, 50.9, 53.0, 106.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
					defaultHidden = true,
				}),
				[1248674] = BossAbility:New({ -- Sacred Shield (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 34.7, 129.5, 44.5, 52.2, 60.2 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246749] = BossAbility:New({ -- Sacred Toll (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								20.0,
								18.0,
								18.0,
								18.0,
								36.0,
								18.0,
								36.0,
								18.0,
								18.0,
								18.0,
								54.0,
								18.0,
								18.0,
								18.0,
								18.0,
								18.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1255738] = BossAbility:New({ -- Searing Radiance (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 59.9, 52.3, 121.8 },
						}),
					},
					duration = 15.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1276639] = BossAbility:New({ -- Searing Radiance (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 10.1, 171.5, 159.5 },
						}),
					},
					duration = 15.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251859] = BossAbility:New({ -- Shield of the Righteous (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 25.3, 36.0, 54.0, 18.0, 18.0, 18.0, 54.0, 54.0, 18.0, 18.0, 18.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1249130] = BossAbility:New({ -- Trampling Charge (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 37.7, 129.5, 44.5, 52.2, 60.2 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272484] = BossAbility:New({ -- Tyr's Wrath (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 29.4, 158.7, 159.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248710] = BossAbility:New({ -- Tyr's Wrath (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 139.3 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272425] = BossAbility:New({ -- Zealous Spirit (Divine Storm) (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 112.6, 156.4 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272380] = BossAbility:New({ -- Zealous Spirit (Searing Radiance) (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 4.1, 160.2, 159.8 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1272423] = BossAbility:New({ -- Zealous Spirit (Avenger's Shield) (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 57.0, 159.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
			abilitiesHeroic = {
				[1246162] = BossAbility:New({ -- Aura of Devotion (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 235.0, 174.0, 172.0 },
						}),
					},
					duration = 25.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248451] = BossAbility:New({ -- Aura of Peace (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 133.2, 175.7, 264.3 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248449] = BossAbility:New({ -- Aura of Wrath (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 83.0, 175.0, 169.0 },
						}),
					},
					duration = 15.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246497] = BossAbility:New({ -- Avenger's Shield (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								12.8,
								67.0,
								43.0,
								17.0,
								20.0,
								20.0,
								23.0,
								48.0,
								41.0,
								40.0,
								20.0,
								20.0,
								41.0,
								40.0,
								67.0,
								43.0,
								17.0,
								20.0,
								20.0,
								23.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1258514] = BossAbility:New({ -- Blinding Light (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								22.7,
								32.4,
								67.6,
								48.5,
								29.2,
								23.2,
								52.5,
								70.7,
								31.8,
								32.7,
								51.1,
								32.7,
								67.8,
								48.1,
							},
						}),
					},
					duration = 10.0,
					castTime = 10.0,
					allowedCombatLogEventTypes = {},
				}),
				[1248644] = BossAbility:New({ -- Divine Toll (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 38.1, 174.0, 172.0, 94.0 },
						}),
					},
					duration = 18.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251812] = BossAbility:New({ -- Final Verdict (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								33.3,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
								92.0,
								20.0,
								20.0,
								20.0,
								20.0,
								106.0,
								42.0,
								40.0,
								20.1,
								20.0,
								20.0,
								20.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1251857] = BossAbility:New({ -- Judgment (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								29.2,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
								52.1,
								39.9,
								20.0,
								20.0,
								40.0,
								106.0,
								42.0,
								40.0,
								19.9,
								20.0,
								20.1,
								20.0,
							},
						}),
					},
					duration = 5.0,
					castTime = 3.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1246736] = BossAbility:New({ -- Judgment (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								30.0,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
								92.0,
								20.0,
								20.0,
								20.0,
								20.0,
								106.0,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
							},
						}),
					},
					duration = 5.0,
					castTime = 3.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1258662] = BossAbility:New({ -- Light Infused (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = { 35.0, 48.0, 50.2, 75.8, 49.0, 50.9, 72.1, 46.0, 146.2 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
					defaultHidden = true,
				}),
				[1248674] = BossAbility:New({ -- Sacred Shield (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								17.7,
								32.6,
								67.9,
								47.5,
								30.1,
								22.6,
								52.8,
								70.2,
								32.6,
								32.6,
								32.7,
								18.3,
								32.6,
								67.9,
								47.6,
								30.2,
							},
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246749] = BossAbility:New({ -- Sacred Toll (Lightblood)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								23.0,
								20.0,
								20.0,
								62.0,
								20.0,
								40.0,
								20.0,
								20.0,
								28.0,
								44.0,
								20.0,
								20.0,
								20.0,
								20.0,
								20.0,
								20.0,
								46.0,
								20.0,
								20.0,
								62.0,
								20.0,
								40.0,
								20.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1251859] = BossAbility:New({ -- Shield of the Righteous (Bellamy)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								29.3,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
								52.0,
								40.0,
								20.0,
								20.0,
								40.0,
								106.0,
								42.0,
								40.0,
								20.0,
								20.0,
								20.0,
								20.0,
							},
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					tankAbility = true,
					allowedCombatLogEventTypes = {},
				}),
				[1249130] = BossAbility:New({ -- Trampling Charge (Senn)
					phases = {
						[1] = BossAbilityPhase:New({
							-- Not all casts confirmed
							castTimes = {
								20.7,
								32.6,
								67.9,
								47.5,
								30.1,
								22.6,
								52.8,
								70.2,
								32.6,
								32.6,
								32.7,
								18.3,
								32.6,
								67.9,
								47.6,
								30.2,
							},
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				-- [1255738] = BossAbility:New({ -- Searing Radiance (Senn)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = { 59.9, 52.3, 121.8 },
				-- 		}),
				-- 	},
				-- 	duration = 15.0,
				-- 	castTime = 2.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
				-- [1276639] = BossAbility:New({ -- Searing Radiance (Senn)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = { 10.1, 171.5, 159.5 },
				-- 		}),
				-- 	},
				-- 	duration = 15.0,
				-- 	castTime = 2.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
				-- [1272484] = BossAbility:New({ -- Tyr's Wrath (Senn)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = { 29.4, 158.7, 159.0 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 5.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
				-- [1248710] = BossAbility:New({ -- Tyr's Wrath (Senn)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = { 139.3 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 5.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
				-- [1246765] = BossAbility:New({ -- Divine Storm (Lightblood)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = {
				-- 				15.0,
				-- 				18.0,
				-- 				18.0,
				-- 				18.0,
				-- 				72.0,
				-- 				18.0,
				-- 				18.0,
				-- 				18.0,
				-- 				18.0,
				-- 				18.0,
				-- 				36.0,
				-- 				36.0,
				-- 				18.0,
				-- 				18.0,
				-- 				18.0,
				-- 			},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
				-- [1272310] = BossAbility:New({ -- Divine Storm (Lightblood)
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			-- Not all casts confirmed
				-- 			castTimes = { 123.0, 162.0 },
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- 	allowedCombatLogEventTypes = {},
				-- }),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 360.0,
					defaultDuration = 360.0,
				}),
			},
		}),
		Boss:New({ -- Crown of the Cosmos
			bossIDs = {
				244761, -- Alleria Windrunner
				254172, -- Vorelus
				254173, -- Demiar
				254174, -- Morium
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5906] = 244761, -- Alleria Windrunner
				[5975] = 254172, -- Vorelus
				[5976] = 254173, -- Demiar
				[5977] = 254174, -- Morium
			},
			journalEncounterID = 2738,
			dungeonEncounterID = 3181,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
	},
})

local dungeonInstance = Private.dungeonInstances[2912]
local bosses = dungeonInstance.bosses ---@cast bosses table<integer, Boss>

---@param bossIndex integer
---@param abilityID integer
local function copyHeroicAbilityToMythic(bossIndex, abilityID)
	bosses[bossIndex].abilities[abilityID] = bosses[bossIndex].abilitiesHeroic[abilityID]
end

---@param bossIndex integer
local function copyHeroicPhasesToMythic(bossIndex)
	bosses[bossIndex].phases = Private.DeepCopy(bosses[bossIndex].phasesHeroic)
end

assert(bosses[2].dungeonEncounterID == 3177)
copyHeroicAbilityToMythic(2, 1257629)
copyHeroicAbilityToMythic(2, 1244097)
copyHeroicAbilityToMythic(2, 1241686)
copyHeroicAbilityToMythic(2, 1241692)
copyHeroicAbilityToMythic(2, 1254199)
copyHeroicAbilityToMythic(2, 1241768)
copyHeroicAbilityToMythic(2, 1241769)
copyHeroicAbilityToMythic(2, 1241770)
copyHeroicAbilityToMythic(2, 1241836)
copyHeroicAbilityToMythic(2, 1244012)
copyHeroicAbilityToMythic(2, 1244100)
copyHeroicAbilityToMythic(2, 1244101)
copyHeroicAbilityToMythic(2, 1241844)
copyHeroicAbilityToMythic(2, 1260052)
copyHeroicAbilityToMythic(2, 1265018)

assert(bosses[4].dungeonEncounterID == 3179)
copyHeroicPhasesToMythic(4)
copyHeroicAbilityToMythic(4, 1254092)
copyHeroicAbilityToMythic(4, 1246175)
copyHeroicAbilityToMythic(4, 1243453)
copyHeroicAbilityToMythic(4, 1260823)
copyHeroicAbilityToMythic(4, 1254081)
copyHeroicAbilityToMythic(4, 1271577)
copyHeroicAbilityToMythic(4, 1253032)
copyHeroicAbilityToMythic(4, 1250686)
copyHeroicAbilityToMythic(4, 1260030)
