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
			journalEncounterCreatureIDsToBossIDs = {
				[5022] = 144244, -- The Platinum Pummeler
				[5023] = 145185, -- Gnomercy 4.U.
			},
			journalEncounterID = 2336,
			dungeonEncounterID = 2257,
			instanceID = 2097,
			hasBossDeath = true,
			abilities = {
				[1216443] = BossAbility:New({ -- Electrical Storm
					eventTriggers = {
						[144244] = EventTrigger:New({ -- Platinum Pummeler ded
							combatLogEventType = "UD",
							castTimes = { 0.0 },
						}),
						[145185] = EventTrigger:New({ -- Gnomercy 4.U. ded
							combatLogEventType = "UD",
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[282801] = BossAbility:New({ -- Platinum Plating
					phases = {
						[1] = BossAbilityPhase:New({ -- Mildly inconsistent
							castTimes = { 39.6, 43.7, 41.3 },
							repeatInterval = 42.5,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 144244,
							combatLogEventType = "UD",
						},
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[1215065] = BossAbility:New({ -- Platinum Pummel
					phases = {
						[1] = BossAbilityPhase:New({ -- Super inconsistent
							castTimes = { 6.8, 15.8, 18.2, 21.9, 17.0, 18.2, 19.4, 23.1, 17.0, 18.2 },
							repeatInterval = 18.8,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 144244,
							combatLogEventType = "UD",
						},
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[1215102] = BossAbility:New({ -- Ground Pound
					phases = {
						[1] = BossAbilityPhase:New({ -- Mildly inconsistent
							castTimes = { 13.4, 18.2, 20.7, 19.0, 23.1, 18.2, 21.8, 18.2, 18.3 },
							repeatInterval = 18.2,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 144244,
							combatLogEventType = "UD",
						},
					},
					duration = 4.0,
					castTime = 3.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[285152] = BossAbility:New({ -- Foe Flipper
					phases = {
						[1] = BossAbilityPhase:New({ -- Super inconsistent
							castTimes = { 6.1, 15.4, 31.6, 15.8, 20.0, 15.4, 19.4, 15.8, 19.5, 16.2 },
							repeatInterval = { 18.8 },
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 145185,
							combatLogEventType = "UD",
						},
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[1216431] = BossAbility:New({ -- B.4.T.T.L.3. Mine
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.4, 18.2, 29.2, 34.9, 35.2, 35.3 },
							repeatInterval = { 35.2 },
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 145185,
							combatLogEventType = "UD",
						},
					},
					duration = 4.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[283422] = BossAbility:New({ -- Maximum Thrust
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.4, 35.6, 35.2, 34.9 },
							repeatInterval = 35.2,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 145185,
							combatLogEventType = "UD",
						},
					},
					duration = 5.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS" },
				}),
				[144244] = BossAbility:New({ -- The Platinum Pummeler died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 144244,
					allowedCombatLogEventTypes = { "UD" },
				}),
				[145185] = BossAbility:New({ -- Gnomercy 4.U. died
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
							castTimes = { 5.9, 26.8 },
							repeatInterval = { 34.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
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
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[294929] = BossAbility:New({ -- Blazing Chomp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.8, 15.8, 20.7 },
							repeatInterval = { 15.8, 18.2 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[291946] = BossAbility:New({ -- Venting Flames
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.7 },
							repeatInterval = 34.0,
						}),
					},
					duration = 3.0,
					castTime = 6.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
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
							castTimes = { 5.3 },
							repeatInterval = 46.2,
						}),
					},
					duration = 5.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[292332] = BossAbility:New({ -- Self-trimming Hedge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.8, 28.0, 25.4, 25.5, 26.8, 25.5 },
							repeatInterval = { 26.8, 25.5 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[285440] = BossAbility:New({ -- "Hidden" Flame Cannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.4 },
							repeatInterval = 47.3,
						}),
					},
					duration = 10.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[285454] = BossAbility:New({ -- Discom-BOMB-ulator
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 7.7 },
							repeatInterval = 20.6,
						}),
					},
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					duration = 9.0,
					castTime = 2.0,
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
			preferredCombatLogEventAbilities = {
				[1] = nil,
				[2] = { combatLogEventSpellID = 291974, combatLogEventType = "SCC" },
			},
			abilities = {
				[291928] = BossAbility:New({ -- Mega-Zap (P1)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0, 16.6 },
							repeatInterval = { 20.6, 15.8 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[292264] = BossAbility:New({ -- Mega-Zap (P2)
					eventTriggers = {
						[291974] = EventTrigger:New({ -- Obnoxious monologue
							combatLogEventType = "SAR",
							castTimes = { 21.3 },
							repeatInterval = { 3.5, 3.5, 23 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[291613] = BossAbility:New({ -- Take Off!
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 35.1 },
							repeatInterval = 36.4,
						}),
					},
					duration = 9.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[291626] = BossAbility:New({ -- Cutting Beam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 39.8 },
							repeatInterval = 36.5,
						}),
					},
					duration = 6.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
					allowedCombatLogEventTypes = { "SCS", "SCC" },
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
					allowedCombatLogEventTypes = {},
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
