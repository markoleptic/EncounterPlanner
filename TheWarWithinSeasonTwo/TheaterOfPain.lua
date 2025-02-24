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

local isElevenDotOne = select(4, GetBuildInfo()) >= 110100 -- Remove when 11.1 is live
if not isElevenDotOne then
	local L = Private.L
	Private:RegisterPlaceholderBossSpellID(1215741, L["Mighty Smash"])
	Private:RegisterPlaceholderBossSpellID(320182, L["Noxious Spores"])
	Private:RegisterPlaceholderBossSpellID(1215738, L["Decaying Breath"])
	Private:RegisterPlaceholderBossSpellID(1215600, L["Withering Touch"])
	Private:RegisterPlaceholderBossSpellID(1215747, L["Final Will"])

	Private:RegisterPlaceholderBossSpellID(1223803, L["Well of Darkness"])
	Private:RegisterPlaceholderBossSpellID(474298, L["Draw Soul"])
	Private:RegisterPlaceholderBossSpellID(1215787, L["Death Spiral"])
end

Private.dungeonInstances[2293] = DungeonInstance:New({
	journalInstanceID = 1187,
	instanceID = 2293,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- An Affront of Challengers
			bossIDs = {
				164451, -- Dessia the Decapitator
				164463, -- Paceran the Virulent
				164461, -- Sathel the Accursed
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5144] = 164451, -- Dessia the Decapitator
				[5145] = 164463, -- Paceran the Virulent
				[5146] = 164461, -- Sathel the Accursed
			},
			journalEncounterID = 2397,
			dungeonEncounterID = 2391,
			instanceID = 2293,
			hasBossDeath = true,
			abilities = {
				[1215741] = BossAbility:New({ -- Mighty Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.7 },
							repeatInterval = 43.7, -- 29.2 stage 2, 14.5 stage 3
						}),
					},
					duration = 10.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[320069] = BossAbility:New({ -- Mortal Strike (Dessia)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.4 },
							repeatInterval = 17.0,
						}),
					},
					duration = 5.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					onlyRelevantForTanks = true,
				}),
				[320182] = BossAbility:New({ -- Noxious Spores (Paceran)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.4 },
							repeatInterval = 43.7, -- 29.2 stage 2, 14.5 stage 3
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1215738] = BossAbility:New({ -- Decaying Breath (Paceran)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8 },
							repeatInterval = { 29.1, 14.6 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[333231] = BossAbility:New({ -- Searing Death (Sathel)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.2 },
							repeatInterval = 42.5, -- 29.2 stage 2, 14.5 stage 3
						}),
					},
					duration = 9.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1215600] = BossAbility:New({ -- Withering Touch (Sathel)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.5 },
							repeatInterval = 18.2,
						}),
					},
					duration = 12.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[164451] = BossAbility:New({ -- Dessia died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 164451,
					allowedCombatLogEventTypes = { "UD" },
				}),
				[164463] = BossAbility:New({ -- Paceran died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 145185,
					allowedCombatLogEventTypes = { "UD" },
				}),
				[164461] = BossAbility:New({ -- Sathel died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 145185,
					allowedCombatLogEventTypes = { "UD" },
				}),
				[1215747] = BossAbility:New({ -- Final Will
					EventTriggers = {
						[164451] = EventTrigger:New({ -- Dessia ded
							combatLogEventType = "UD",
							castTimes = { 0.0 },
						}),
						[164463] = EventTrigger:New({ -- Paceran ded
							combatLogEventType = "UD",
							castTimes = { 0.0 },
						}),
						[164461] = EventTrigger:New({ -- Sathel ded
							combatLogEventType = "UD",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA" },
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
		Boss:New({ -- Gorechop
			bossIDs = { 162317 },
			journalEncounterID = 2401,
			dungeonEncounterID = 2365,
			instanceID = 2293,
			abilities = {
				[322795] = BossAbility:New({ -- Meat Hooks
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.5, 10.2 },
							repeatInterval = 20.6,
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[323515] = BossAbility:New({ -- Hateful Strike
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.7 },
							repeatInterval = 14.6,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[318406] = BossAbility:New({ -- Tenderizing Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.5 },
							repeatInterval = 19.4,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
		Boss:New({ -- Xav the Unfallen
			bossIDs = { 162329 },
			journalEncounterID = 2390,
			dungeonEncounterID = 2366,
			instanceID = 2293,
			abilities = {
				[320114] = BossAbility:New({ -- Blood and Glory
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 33.7 },
							repeatInterval = 70.0,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[331618] = BossAbility:New({ -- Oppressive Banner
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.6, 25.5 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[320644] = BossAbility:New({ -- Brutal Combo
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 0.75,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[320050] = BossAbility:New({ -- Might of Maldraxxus
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.7 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[317231] = BossAbility:New({ -- Crushing Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.5 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[320729] = BossAbility:New({ -- Massive Cleave
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.5 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[339415] = BossAbility:New({ -- Deafening Crash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.0 },
							repeatInterval = 30.3,
						}),
					},
					duration = 2.0,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
		Boss:New({ -- Kul'tharok
			bossIDs = { 162309 },
			journalEncounterID = 2389,
			dungeonEncounterID = 2364,
			instanceID = 2293,
			abilities = {
				[1223803] = BossAbility:New({ -- Well of Darkness
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.1 },
							repeatInterval = { 23.1, 32.8 },
						}),
					},
					duration = 6.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[474298] = BossAbility:New({ -- Draw Soul
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 51.4 },
							repeatInterval = 54.6,
						}),
					},
					duration = 8.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1215787] = BossAbility:New({ -- Death Spiral
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.4 },
							repeatInterval = 54.6,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[474087] = BossAbility:New({ -- Necrotic Eruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.4, 23.1, 31.6, 20.8, 36.2, 20.9, 35.0, 22.1 },
							repeatInterval = { 20.9, 35.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
		Boss:New({ -- Mordretha
			bossIDs = { 165946 },
			journalEncounterID = 2417,
			dungeonEncounterID = 2404,
			instanceID = 2293,
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 339573, combatLogEventType = "SCS" },
			},
			abilities = {
				[324079] = BossAbility:New({ -- Reaping Scythe
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.2 },
							repeatInterval = 16.9,
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 6.9 },
							repeatInterval = 16.9,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[323608] = BossAbility:New({ -- Dark Devastation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.5 },
							repeatInterval = 26.7,
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 14.6 },
							repeatInterval = 26.7,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[323825] = BossAbility:New({ -- Grasping Rift
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.2 },
							repeatInterval = 31.5,
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 22.5 },
							repeatInterval = 31.5,
						}),
					},
					duration = 6.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[324449] = BossAbility:New({ -- Manifest Death
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.4 },
							repeatInterval = 53.3,
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 21.0 },
							repeatInterval = 53.3,
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[339573] = BossAbility:New({ -- Echoes of Carnage
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA" },
				}),
				[339706] = BossAbility:New({ -- Ghostly Charge
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 13.5 },
							repeatInterval = 24.3,
						}),
					},
					duration = 5.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					buffer = 0.2,
				}),
				[339550] = BossAbility:New({ -- Echo of Battle
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 3.2 },
							repeatInterval = 24.3,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					buffer = 2.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					name = "P2",
				}),
			},
		}),
	},
})
