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
	Private:RegisterPlaceholderBossSpellID(1214325, L["Crashing Thunder"])
	Private:RegisterPlaceholderBossSpellID(474018, L["Wild Lightning"])
end

Private.dungeonInstances[2648] = DungeonInstance:New({
	journalInstanceID = 1268,
	instanceID = 2648,
	customGroup = "TheWarWithinSeasonTwo",
	bosses = {
		Boss:New({ -- Kyrioss
			bossID = { 209230 },
			journalEncounterID = 2566,
			dungeonEncounterID = 2816,
			instanceID = 2648,
			abilities = {
				[444123] = BossAbility:New({ -- Lightning Torrent
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.0 },
							repeatInterval = 55.9,
						}),
					},
					duration = 15.0,
					castTime = 0.0,
				}),
				[1214325] = BossAbility:New({ -- Crashing Thunder
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.1, 42.5 },
							repeatInterval = { 15.8, 40.1 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[474018] = BossAbility:New({ -- Wild Lightning
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.5, 41.3 },
							repeatInterval = { 15.8, 40.1 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[419870] = BossAbility:New({ -- Lightning Dash
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.5 },
							repeatInterval = 55.9,
						}),
					},
					duration = 0.0,
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
		Boss:New({ -- Stormguard Gorren
			bossID = { 207205 },
			journalEncounterID = 2567,
			dungeonEncounterID = 2861,
			instanceID = 2648,
			abilities = {
				[424737] = BossAbility:New({ -- Chaotic Corruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8 },
							repeatInterval = 32.7,
						}),
					},
					duration = 5.0,
					castTime = 2.0,
				}),
				[425048] = BossAbility:New({ -- Dark Gravity
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.1 },
							repeatInterval = 32.7,
						}),
					},
					duration = 6.0,
					castTime = 2.0,
				}),
				[424958] = BossAbility:New({ -- Crush Reality
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.5 },
							repeatInterval = 15.7,
						}),
					},
					duration = 0.0,
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
		Boss:New({ -- Voidstone Monstrosity
			bossID = { 207207 },
			journalEncounterID = 2568,
			dungeonEncounterID = 2836,
			instanceID = 2648,
			abilities = {
				[423305] = BossAbility:New({ -- Null Upheaval
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.7 },
							repeatInterval = 32.8,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[445262] = BossAbility:New({ -- Void Shell
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 60.0,
					castTime = 0.0,
				}),
				[429487] = BossAbility:New({ -- Unleash Corruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.7 },
							repeatInterval = 17.0,
						}),
					},
					duration = 15.0,
					castTime = 2.0,
				}),
				[445457] = BossAbility:New({ -- Oblivion Wave
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.8 },
							repeatInterval = 13.3,
						}),
					},
					duration = 0.0,
					castTime = 3.0,
				}),
				[458082] = BossAbility:New({ -- Stormrider's Charge (Stormrider Vokmar)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.8 },
							repeatInterval = 32.8,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
				}),
				[424371] = BossAbility:New({ -- Storm's Vengeance
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 4.5 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 20.0,
					castTime = 0.0,
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
					duration = 24.5,
					defaultDuration = 24.5,
					name = "P2",
					count = 3,
					defaultCount = 3,
					fixedDuration = true,
					repeatAfter = 1,
				}),
			},
		}),
	},
})
