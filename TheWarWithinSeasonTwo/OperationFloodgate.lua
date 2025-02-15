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
---@class RaidInstance
local RaidInstance = Private.classes.RaidInstance

Private.raidInstances[2773] = RaidInstance:New({
	journalInstanceID = 1298,
	instanceID = 2773,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Big M.O.M.M.A.
			bossID = { 226398 },
			journalEncounterID = 2648,
			dungeonEncounterID = 3020,
			instanceID = 2773,
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
				}),
				[473351] = BossAbility:New({ -- Electrocrush
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.7 },
							repeatInterval = 20.6,
						}),
					},
					duration = 10.0,
					castTime = 1.5,
				}),
				[473220] = BossAbility:New({ -- Sonic Boom
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.9 },
							repeatInterval = 21.7,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[469981] = BossAbility:New({ -- Kill-o-Block Barrier
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 51.0 },
						}),
					},
					-- TODO: Implement support for lasting until end of phase
					duration = 60,
					castTime = 1.5,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 13.5,
					defaultDuration = 13.5,
					fixedDuration = true,
					name = "P2",
				}),
			},
		}),
		Boss:New({ -- Demolition Duo
			bossID = {
				226403, -- Keeza Quickfuse
				226402, -- Bront
			},
			journalEncounterID = 2649,
			dungeonEncounterID = 3019,
			instanceID = 2773,
			abilities = {
				[459799] = BossAbility:New({ -- Wallop
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.1 },
							repeatInterval = 17.0,
						}),
					},
					duration = 0.0,
					castTime = 1.5,
				}),
				[459779] = BossAbility:New({ -- Barreling Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.8 },
							repeatInterval = 17.0,
						}),
					},
					duration = 2.0,
					castTime = 3.5,
				}),
				[460867] = BossAbility:New({ -- Big Bada Boom
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.9 },
							repeatInterval = 34.2,
						}),
					},
					duration = 2.0,
					castTime = 3.5,
				}),
				[1217653] = BossAbility:New({ -- B.B.B.F.G.
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.5 },
							repeatInterval = 17.7,
						}),
					},
					duration = 0.0,
					castTime = 3.5,
				}),
				[473690] = BossAbility:New({ -- Kinetic Explosive Gel
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.7 },
							repeatInterval = 17.7,
						}),
					},
					duration = 0.0,
					castTime = 2.0,
				}),
			},
			-- TODO: Add option for phase 2 when one of the bosses dies
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Swampface
			bossID = { 226396 },
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
				}),
				[473114] = BossAbility:New({ -- Mudslide
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[469478] = BossAbility:New({ -- Sludge Claws
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
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
			bossID = { 226404 },
			journalEncounterID = 2651,
			dungeonEncounterID = 3054,
			instanceID = 2773,
			abilities = {
				[465463] = BossAbility:New({ -- Turbo Charge
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 1.6 },
							repeatInterval = 60.0,
						}),
					},
					duration = 10.0,
					castTime = 0.0,
				}),
				[468841] = BossAbility:New({ -- Leaping Sparks
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.0 },
							repeatInterval = 60.0,
						}),
					},
					duration = 8.0,
					castTime = 0.0,
				}),
				[468813] = BossAbility:New({ -- Gigazap
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.0 },
							repeatInterval = { 26.0, 34.0 },
						}),
					},
					duration = 8.0,
					castTime = 0.0,
				}),
				[466190] = BossAbility:New({ -- Thunder Punch
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 24.0 },
							repeatInterval = { 26.0, 34.0 },
						}),
					},
					duration = 4.0,
					castTime = 0.0,
				}),
				[468723] = BossAbility:New({ -- Shock Water
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							repeatInterval = 0.0,
						}),
					},
					duration = 4.0,
					castTime = 0.0,
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
