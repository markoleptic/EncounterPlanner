local AddOnName, Namespace = ...

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

local isElevenDotOne = select(4, GetBuildInfo()) >= 110100 -- Remove when 11.1 is live
if not isElevenDotOne then
	Private:RegisterPlaceholderBossSpellID(1215065, L["Platinum Pummel"])
	Private:RegisterPlaceholderBossSpellID(1215102, L["Ground Pound"])
	Private:RegisterPlaceholderBossSpellID(1216431, L["B.4.T.T.L.3. Mine"])
end

Private.dungeonInstances[2097] = DungeonInstance:New({
	journalInstanceID = 1178,
	instanceID = 2097,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Tussle Tonks
			bossIDs = {
				144244, -- The Platinum Pummeler
				145185, -- Gnomercy 4.U.
			},
			journalEncounterID = 2336,
			dungeonEncounterID = 2257,
			instanceID = 2097,
			abilities = {
				-- [1216443] = BossAbility:New({ -- Electrical Storm
				-- 	phases = {
				-- 		[1] = BossAbilityPhase:New({
				-- 			castTimes = { 31.7 },
				-- 			repeatInterval = 63.2,
				-- 		}),
				-- 	},
				-- 	duration = 4.0,
				-- 	castTime = 3.0,
				-- }),
				[282801] = BossAbility:New({ -- Platinum Plating
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.5 },
							repeatInterval = 40.5,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1215065] = BossAbility:New({ -- Platinum Pummel
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.2 },
							repeatInterval = 15.1,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[1215102] = BossAbility:New({ -- Ground Pound
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.1 },
							repeatInterval = 18.2,
						}),
					},
					duration = 4.0,
					castTime = 0.0,
				}),
				[285152] = BossAbility:New({ -- Foe Flipper
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8, 15.8, 28.0 },
							repeatInterval = { 19.4, 15.8 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[1216431] = BossAbility:New({ -- B.4.T.T.L.3. Mine
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.0, 17.0, 27.9 },
							repeatInterval = { 34.8 },
						}),
					},
					duration = 4.0,
					castTime = 2.0,
				}),
				[283422] = BossAbility:New({ -- Maximum Thrust
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.1 },
							repeatInterval = 63.2,
						}),
					},
					duration = 5.0,
					castTime = 6.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		Boss:New({ -- K.U.-J.0.
			bossIDs = { 144246 },
			journalEncounterID = 2339,
			dungeonEncounterID = 2258,
			instanceID = 2097,
			abilities = {
				[291918] = BossAbility:New({ -- Air Drop
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1 },
							repeatInterval = { 26.7, 34.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[291973] = BossAbility:New({ -- Explosive Leap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.8 },
							repeatInterval = 34.0,
						}),
					},
					duration = 1.0,
					castTime = 3.0,
				}),
				[294929] = BossAbility:New({ -- Blazing Chomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.8, 17.0 },
							repeatInterval = { 17.0, 15.8 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[291946] = BossAbility:New({ -- Venting Flames
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.7 },
							repeatInterval = 34.0,
						}),
					},
					duration = 5.0,
					castTime = 6.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
				}),
			},
		}),
		Boss:New({ -- Machinist's Garden
			bossIDs = { 144248 },
			journalEncounterID = 2348,
			dungeonEncounterID = 2259,
			instanceID = 2097,
			abilities = {
				[294853] = BossAbility:New({ -- Activate Plant
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.1 },
							repeatInterval = 46.1,
						}),
					},
					duration = 5.0,
					castTime = 0.0,
				}),
				[285440] = BossAbility:New({ -- "Hidden" Flame Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.1 },
							repeatInterval = 47.3,
						}),
					},
					duration = 10.0,
					castTime = 0.0,
				}),
				[285454] = BossAbility:New({ -- Discom-BOMB-ulator
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.5 },
							repeatInterval = 20.6,
						}),
					},
					duration = 9.0,
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
		Boss:New({ -- King Mechagon
			bossIDs = { 150396, 150397, 144249 },
			journalEncounterID = 2331,
			dungeonEncounterID = 2260,
			instanceID = 2097,
			abilities = {
				[291928] = BossAbility:New({ -- Mega-Zap (P1)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 8.4 },
							repeatInterval = { 20.8, 16.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[291974] = BossAbility:New({ -- Obnoxious monologue
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 8.0,
					castTime = 0.0,
				}),
				[292264] = BossAbility:New({ -- Mega-Zap (P2)
					eventTriggers = {
						[291974] = EventTrigger:New({ -- Obnoxious monologue
							combatLogEventType = "SAR",
							castTimes = { 14.8 },
							repeatInterval = { 3.5, 3.5, 23 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[291613] = BossAbility:New({ -- Take Off!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30 },
							repeatInterval = 34,
						}),
					},
					duration = 9.0,
					castTime = 2.5,
				}),
				[291626] = BossAbility:New({ -- Cutting Beam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.0 },
							repeatInterval = 36.5,
						}),
					},
					duration = 6.0,
					castTime = 0.0,
				}),
				[283551] = BossAbility:New({ -- Magneto-Arm (Omega buster activating the device)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 35.6 },
							repeatInterval = 62,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
				[283143] = BossAbility:New({ -- Magneto-Arm (Cast by Magneto-Arm, pull in start)
					eventTriggers = {
						[283551] = EventTrigger:New({ -- Magneto-Arm (Omega buster activating the device)
							combatLogEventType = "SCC",
							castTimes = { 3.5 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					name = "P2",
				}),
			},
		}),
	},
})
