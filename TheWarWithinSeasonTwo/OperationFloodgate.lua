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
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Demolition Duo
			bossID = {
				226403, -- Keeza Quickfuse
				226402, -- Bront
			},
			journalEncounterID = 2649,
			dungeonEncounterID = 3019,
			instanceID = 2773,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Swampface
			bossID = { 226396 },
			journalEncounterID = 2650,
			dungeonEncounterID = 3053,
			instanceID = 2773,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Geezle Gigazap
			bossID = { 226404 },
			journalEncounterID = 2651,
			dungeonEncounterID = 3054,
			instanceID = 2773,
			abilities = {},
			phases = {},
		}),
	},
})
