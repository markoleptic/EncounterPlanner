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

local isElevenDotOne = select(4, GetBuildInfo()) >= 110100 -- Remove when 11.1 is live
if not isElevenDotOne then
	local L = Private.L
	Private:RegisterPlaceholderBossSpellID(1217294, L["Shocking Claw"])
end

Private.raidInstances[1594] = RaidInstance:New({
	journalInstanceID = 1012,
	instanceID = 1594,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Crowd Pummeler
			bossID = { 129214 },
			journalEncounterID = 2109,
			dungeonEncounterID = 2105,
			instanceID = 1594,
			abilities = {
				[269493] = BossAbility:New({ -- Footbomb Launcher
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.1 },
							repeatInterval = 47.4,
						}),
					},
					duration = 15.0,
					castTime = 2.0,
				}),
				[256493] = BossAbility:New({ -- Blazing Azerite
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[271903] = BossAbility:New({ -- Coin Magnet
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.0 },
							repeatInterval = 43.8,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[262347] = BossAbility:New({ -- Static Pulse
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.1 },
							repeatInterval = 43.8,
						}),
					},
					duration = 2.5,
					castTime = 8.0,
				}),
				[1217294] = BossAbility:New({ -- Shocking Claw
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = 48.6,
						}),
					},
					duration = 3.0,
					castTime = 4.0,
				}),
				[271784] = BossAbility:New({ -- Throw Coins
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.0, 2.0, 2.0, 2.0, 2.0 },
							repeatInterval = { 43.8, 2.0, 2.0, 2.0, 2.0 },
						}),
					},
					duration = 0.0,
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
		Boss:New({ -- Azerokk
			bossID = {
				129227, -- Azerokk
				129802, -- Earthrager
			},
			journalEncounterID = 2114,
			dungeonEncounterID = 2106,
			instanceID = 1594,
			abilities = {
				[271698] = BossAbility:New({ -- Azerite Infusion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.6 },
							repeatInterval = 44.0,
						}),
					},
					duration = 0.0,
					castTime = 1.0,
				}),
				[258622] = BossAbility:New({ -- Resonant Quake
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 29.0 },
							repeatInterval = 41.3,
						}),
					},
					duration = 6.0,
					castTime = 5.0,
				}),
				[257593] = BossAbility:New({ -- Call Earthrager
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.4 },
							repeatInterval = 42.1,
						}),
					},
					duration = 0.0,
					castTime = 2.5,
				}),
				[275907] = BossAbility:New({ -- Tectonic Smash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1, 19.4, 21.5 },
							repeatInterval = { 19.4, 23.1 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
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
		Boss:New({ -- Rixxa Fluxflame
			bossID = { 129231 },
			journalEncounterID = 2115,
			dungeonEncounterID = 2107,
			instanceID = 1594,
			abilities = {
				[259856] = BossAbility:New({ -- Chemical Burn
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.5 },
							repeatInterval = { 15.0, 27.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[275992] = BossAbility:New({ -- Gushing Catalyst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 3.0 },
							repeatInterval = { 53.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[270042] = BossAbility:New({ -- Azerite Catalyst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = { 53.0 },
						}),
					},
					duration = 3.0,
					castTime = 2.5,
				}),
				[259940] = BossAbility:New({ -- Propellant Blast
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 22.4, 11.0, 11.0 },
							repeatInterval = { 31.0, 11.0, 11.0 },
						}),
					},
					duration = 4.0,
					castTime = 3.5,
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
		Boss:New({ -- Mogul Razdunk
			bossID = { 129232 },
			journalEncounterID = 2116,
			dungeonEncounterID = 2108,
			instanceID = 1594,
			abilities = {
				[260280] = BossAbility:New({ -- Gatling Gun
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 8.0,
					castTime = 3.0,
				}),
				[260829] = BossAbility:New({ -- Homing Missile
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 6.0,
					castTime = 3.0,
				}),
				[276229] = BossAbility:New({ -- Micro Missiles
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.0 },
							repeatInterval = 30.0,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[271456] = BossAbility:New({ -- Drill Smash
					eventTriggers = {
						[260189] = EventTrigger:New({ -- Configuration: Drill
							combatLogEventType = "SCC",
							castTimes = { 17.5, 11.0, 11.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
				}),
				[260189] = BossAbility:New({ -- Configuration: Drill
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[260190] = BossAbility:New({ -- Configuration: Combat
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 43.5 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedCount = true,
				}),
				[2] = BossPhase:New({
					duration = 43.5,
					defaultDuration = 43.5,
					name = "P2",
					count = 1,
					defaultCount = 1,
					repeatAfter = 1,
					fixedCount = true,
				}),
			},
		}),
	},
})
