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

Private.dungeonInstances[2913] = DungeonInstance:New({
	journalInstanceID = 1308,
	instanceID = 2913,
	customGroups = { "MidnightSeasonOne" },
	isRaid = true,
	hasHeroic = true,
	bosses = {
		Boss:New({ -- Belo'ren, Child of Al'ar
			bossIDs = {
				249637, -- Belo'ren
				246728, -- Void Ember
				246729, -- Light Ember
			},
			journalEncounterCreatureIDsToBossIDs = {
				-- [5904] = 249637, -- Belo'ren
				-- [5973] = 246728, -- Void Ember
				-- [5974] = 246729, -- Light Ember
			},
			journalEncounterID = 2739,
			dungeonEncounterID = 3182,
			instanceID = 2913,
			abilities = {},
			-- phases = {},
			abilitiesHeroic = {},
			-- phasesHeroic = {},
		}),
		Boss:New({ -- Midnight Falls
			bossIDs = {
				214650, -- L'ura
				250615, -- Midnight Crystal
				250616, -- Dusk Crystal
				251180, -- Dawn Crystal
			},
			journalEncounterCreatureIDsToBossIDs = {
				-- [5905] = 214650, -- L'ura
				-- [6111] = 250615, -- Midnight Crystal
				-- [6112] = 250616, -- Dusk Crystal
				-- [6114] = 251180, -- Dawn Crystal
			},
			journalEncounterID = 2740,
			dungeonEncounterID = 3183,
			instanceID = 2913,
			abilities = {},
			-- phases = {},
			abilitiesHeroic = {},
			-- phasesHeroic = {},
		}),
	},
})
