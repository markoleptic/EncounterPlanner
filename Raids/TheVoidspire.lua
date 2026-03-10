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
					duration = 720.0,
					defaultDuration = 720.0,
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
					duration = 720.0,
					defaultDuration = 720.0,
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
			abilitiesHeroic = {},
			phasesHeroic = {},
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
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
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
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
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
	isRaid = true,
})

local dungeonInstance = Private.dungeonInstances[2912]
local bosses = dungeonInstance.bosses ---@cast bosses table<integer, Boss>

---@param bossIndex integer
---@param abilityID integer
local function copyHeroicAbilityToMythic(bossIndex, abilityID)
	bosses[bossIndex].abilities[abilityID] = bosses[bossIndex].abilitiesHeroic[abilityID]
end

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
