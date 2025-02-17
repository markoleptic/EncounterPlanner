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
			bossID = {
				164451, -- Dessia the Decapitator
				164463, -- Paceran the Virulent
				164461, -- Sathel the Accursed
			},
			journalEncounterID = 2397,
			dungeonEncounterID = 2391,
			instanceID = 2293,
			abilities = {
				[1215741] = BossAbility:New({ -- Mighty Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.5 },
							repeatInterval = 42.5, -- 29.2 stage 2, 14.5 stage 3
						}),
					},
					duration = 10.0,
					castTime = 4.0,
				}),
				[320069] = BossAbility:New({ -- Mortal Strike (Dessia)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.5 },
							repeatInterval = 21.9,
						}),
					},
					duration = 5.0,
					castTime = 1.0,
				}),
				[320182] = BossAbility:New({ -- Noxious Spores (Paceran)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 20.3 },
							repeatInterval = 42.5, -- 29.2 stage 2, 14.5 stage 3
						}),
					},
					duration = 6.0,
					castTime = 0.0,
				}),
				[1215738] = BossAbility:New({ -- Decaying Breath (Paceran)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.9 },
							repeatInterval = { 29.1, 14.6 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
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
				}),
				[1215600] = BossAbility:New({ -- Withering Touch (Sathel)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = 17.0,
						}),
					},
					duration = 12.0,
					castTime = 2.0,
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
			bossID = { 162317 },
			journalEncounterID = 2401,
			dungeonEncounterID = 2365,
			instanceID = 2293,
			abilities = {
				[322795] = BossAbility:New({ -- Meat Hooks
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.2, 10.2 },
							repeatInterval = 20.6,
						}),
					},
					duration = 5.0,
					castTime = 0.0,
				}),
				[323515] = BossAbility:New({ -- Hateful Strike
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.6 },
							repeatInterval = 14.6,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
				[318406] = BossAbility:New({ -- Tenderizing Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.1 },
							repeatInterval = 19.4,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
			bossID = { 162329 },
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
					castTime = 0.0,
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
				}),
				[320644] = BossAbility:New({ -- Brutal Combo
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = 30.3,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
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
			bossID = { 162309 },
			journalEncounterID = 2389,
			dungeonEncounterID = 2364,
			instanceID = 2293,
			abilities = {
				[1223803] = BossAbility:New({ -- Well of Darkness
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.9 },
							repeatInterval = 23.0,
						}),
					},
					duration = 6.0,
					castTime = 3.0,
				}),
				[474298] = BossAbility:New({ -- Draw Soul
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 48.6 },
							repeatInterval = 50.6,
						}),
					},
					duration = 8.0,
					castTime = 4.0,
				}),
				[1215787] = BossAbility:New({ -- Death Spiral
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.1 },
							repeatInterval = 48.5,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
				}),
				[474087] = BossAbility:New({ -- Necrotic Eruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.0 },
							repeatInterval = { 34.0, 23.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
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
			bossID = { 165946 },
			journalEncounterID = 2417,
			dungeonEncounterID = 2404,
			instanceID = 2293,
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
