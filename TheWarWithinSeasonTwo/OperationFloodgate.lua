local isElevenDotOne = select(4, GetBuildInfo()) >= 110100 -- Remove when 11.1 is live
if not isElevenDotOne then
	return
end

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

Private.dungeonInstances[2773] = DungeonInstance:New({
	journalInstanceID = 1298,
	instanceID = 2773,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Big M.O.M.M.A.
			bossIDs = { 226398 },
			journalEncounterID = 2648,
			dungeonEncounterID = 3020,
			instanceID = 2773,
			preferredCombatLogEventAbilities = {
				[1] = { combatLogEventSpellID = 460156, combatLogEventType = "SAR" },
				[2] = { combatLogEventSpellID = 460156, combatLogEventType = "SCS" },
			},
			abilities = {
				[460156] = BossAbility:New({ -- Jumpstart
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 12.0,
					castTime = 1.5,
					durationHurts = true,
					durationLastsUntilEndOfPhase = true,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[473351] = BossAbility:New({ -- Electrocrush
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = { 20.6, 21.8 },
						}),
					},
					duration = 10.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[473220] = BossAbility:New({ -- Sonic Boom
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.1 },
							repeatInterval = 21.7,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {}, -- TODO: Phase timings can cause inconsistent results
				}),
				[469981] = BossAbility:New({ -- Kill-o-Block Barrier
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 50.0 },
						}),
					},
					duration = 0.0,
					durationLastsUntilEndOfPhase = true,
					castTime = 1.5,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					name = "P1",
					count = 3,
					defaultCount = 3,
					repeatAfter = 2,
				}),
				[2] = BossPhase:New({
					duration = 13.5,
					defaultDuration = 13.5,
					fixedDuration = true,
					name = "P2",
					count = 2,
					defaultCount = 2,
					repeatAfter = 1,
				}),
			},
		}),
		Boss:New({ -- Demolition Duo
			bossIDs = {
				226402, -- Keeza Quickfuse
				226403, -- Bront
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5752] = 226402, -- Keeza Quickfuse
				[5753] = 226403, -- Bront
			},
			journalEncounterID = 2649,
			dungeonEncounterID = 3019,
			instanceID = 2773,
			hasBossDeath = true,
			abilities = {
				[459799] = BossAbility:New({ -- Wallop
					phases = {
						[1] = BossAbilityPhase:New({ -- Inconsistent
							castTimes = { 4.3, 34.0, 17.0, 19.4, 35.2, 34.7 },
							repeatInterval = 34.7,
						}),
					},
					cancelTriggers = {
						bossNpcID = 226403,
						combatLogEventType = "UD",
					},
					duration = 0.0,
					castTime = 1.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[459779] = BossAbility:New({ -- Barreling Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.3 },
							repeatInterval = { 5.3, 5.3, 24.6 },
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 226402,
							combatLogEventType = "UD",
						},
						{
							bossNpcID = 226403,
							combatLogEventType = "UD",
						},
					},
					duration = 2.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[460867] = BossAbility:New({ -- Big Bada Boom
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.3 },
							repeatInterval = 34.4,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 226402,
							combatLogEventType = "UD",
						},
						{
							bossNpcID = 226403,
							combatLogEventType = "UD",
						},
					},
					duration = 30.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[1217653] = BossAbility:New({ -- B.B.B.F.G.
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 17.7,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 226402,
							combatLogEventType = "UD",
						},
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[473690] = BossAbility:New({ -- Kinetic Explosive Gel
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.2 },
							repeatInterval = 17.7,
						}),
					},
					cancelTriggers = {
						{
							bossNpcID = 226402,
							combatLogEventType = "UD",
						},
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[226402] = BossAbility:New({ -- Keeza Quickfuse Died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 226402,
					allowedCombatLogEventTypes = { "UD" },
				}),
				[226403] = BossAbility:New({ -- Bront Died
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 160 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					bossNpcID = 226403,
					allowedCombatLogEventTypes = { "UD" },
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
		Boss:New({ -- Swampface
			bossIDs = { 226396 },
			journalEncounterID = 2650,
			dungeonEncounterID = 3053,
			instanceID = 2773,
			abilities = {
				[473070] = BossAbility:New({ -- Awaken the Swamp
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 4.0,
					castTime = 4.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[473114] = BossAbility:New({ -- Mudslide
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[469478] = BossAbility:New({ -- Sludge Claws
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 2.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[470039] = BossAbility:New({ -- Razorchoke Vines
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 1.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 24.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
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
		Boss:New({ -- Geezle Gigazap
			bossIDs = { 226404 },
			journalEncounterID = 2651,
			dungeonEncounterID = 3054,
			instanceID = 2773,
			abilities = {
				[465463] = BossAbility:New({ -- Turbo Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 1.6 },
							repeatInterval = 64.0,
						}),
					},
					duration = 10.0,
					castTime = 4.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS", "SAA", "SAR" },
				}),
				[468841] = BossAbility:New({ -- Leaping Sparks
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.0 },
							repeatInterval = 64.0,
						}),
					},
					duration = 8.0,
					castTime = 4.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[468813] = BossAbility:New({ -- Gigazap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.0 },
							repeatInterval = { 28.0, 36.0 },
						}),
					},
					duration = 8.0,
					castTime = 3.0,
					durationHurts = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
				}),
				[466190] = BossAbility:New({ -- Thunder Punch
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.0 },
							repeatInterval = { 28.0, 36.0 },
						}),
					},
					duration = 4.0,
					castTime = 2.5,
					onlyRelevantForTanks = true,
					allowedCombatLogEventTypes = { "SCC", "SCS" },
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
	},
})
