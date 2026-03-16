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
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
	},
})
