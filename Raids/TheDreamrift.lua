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

Private.dungeonInstances[2939] = DungeonInstance:New({
	journalInstanceID = 1314,
	instanceID = 2939,
	customGroups = { "MidnightSeasonOne" },
	isRaid = true,
	hasHeroic = true,
	bosses = {
		Boss:New({ -- Chimaerus the Undreamt God
			bossIDs = {
				256116, -- Chimaerus
				257691, -- Colossal Horror
				256803, -- Haunting Essence
				256804, -- Swarming Shade
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5963] = 256116, -- Chimaerus
				[6014] = 257691, -- Colossal Horror
				[5994] = 256803, -- Haunting Essence
				[5993] = 256804, -- Swarming Shade
			},
			journalEncounterID = 2795,
			dungeonEncounterID = 3306,
			instanceID = 2939,
			abilities = {
				[1245396] = BossAbility:New({ -- Consume
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 65.5, 71.8 },
						}),
					},
					duration = 10.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1245452] = BossAbility:New({ -- Corrupted Devastation
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 10.4, 23.1, 24.3 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1245406] = BossAbility:New({ -- Ravenous Dive
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 92.4 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = {},
				}),
				[1257087] = BossAbility:New({ -- Consuming Miasma
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.3, 0.2, 50.8, 0.2, 37.0, 0.2 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = {
								24.3,
								0.1,
								0.9,
								0.1,
								26.8,
								0.2,
								0.3,
								0.2,
								27.3,
								0.1,
								0.6,
								0.2,
							},
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					halfHeight = true,
					allowedCombatLogEventTypes = {},
				}),
				[1264756] = BossAbility:New({ -- Rift Madness
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 39.1, 0.0, 72.7, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 157.1,
					defaultDuration = 157.1,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 96.9,
					defaultDuration = 96.9,
					count = 2,
					defaultCount = 2,
					name = "P2",
					repeatAfter = 1,
					fixedDuration = true,
				}),
			},
			abilitiesHeroic = {
				[1252863] = BossAbility:New({ -- Insatiable
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
							signifiesPhaseEnd = true,
						}),
					},
					duration = 153.1,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1262289] = BossAbility:New({ -- Alndust Upheaval
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.7, 72.7 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1245727] = BossAbility:New({ -- Alnshroud
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.4, 74.5 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = {},
				}),
				[1246621] = BossAbility:New({ -- Caustic Phlegm
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 23.7, 26.4, 48.2, 21.8 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 3.6 },
						}),
					},
					duration = 12.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1245396] = BossAbility:New({ -- Consume
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 65.5, 74.5 },
						}),
					},
					duration = 10.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1245452] = BossAbility:New({ -- Corrupted Devastation
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 9.5, 24.7, 23.8 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = {},
				}),
				[1245406] = BossAbility:New({ -- Ravenous Dive
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 81.2 },
						}),
					},
					duration = 0.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = {},
				}),
				[1272726] = BossAbility:New({ -- Rending Tear
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 36.4, 72.7 },
						}),
					},
					duration = 6.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = {},
				}),
				[1258610] = BossAbility:New({ -- Rift Emergence
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.4, 74.5 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = {},
				}),
				[1257087] = BossAbility:New({ -- Consuming Miasma
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.4, 0.3, 49.7, 0.3, 35.4, 0.3 },
						}),
						[2] = BossAbilityPhase:New({
							castTimes = { 31.7, 0.2, 26.9, 0.2, 27.9, 0.2 },
						}),
					},
					duration = 10.0,
					castTime = 0.0,
					halfHeight = true,
					allowedCombatLogEventTypes = {},
				}),
			},
			phasesHeroic = {
				[1] = BossPhase:New({
					duration = 153.1,
					defaultDuration = 153.1,
					count = 2,
					defaultCount = 2,
					name = "P1",
					repeatAfter = 2,
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 90.0,
					defaultDuration = 90.0,
					count = 2,
					defaultCount = 2,
					name = "P2",
					repeatAfter = 1,
					fixedDuration = true,
				}),
			},
		}),
	},
})

local dungeonInstance = Private.dungeonInstances[2939]
local bosses = dungeonInstance.bosses ---@cast bosses table<integer, Boss>

---@param bossIndex integer
---@param abilityID integer
local function copyHeroicAbilityToMythic(bossIndex, abilityID)
	bosses[bossIndex].abilities[abilityID] = bosses[bossIndex].abilitiesHeroic[abilityID]
end

copyHeroicAbilityToMythic(1, 1252863)
copyHeroicAbilityToMythic(1, 1262289)
copyHeroicAbilityToMythic(1, 1245727)
copyHeroicAbilityToMythic(1, 1246621)
copyHeroicAbilityToMythic(1, 1272726)
copyHeroicAbilityToMythic(1, 1258610)
