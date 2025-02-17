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

Private.dungeonInstances[2769] = DungeonInstance:New({
	journalInstanceID = 1296,
	instanceID = 2769,
	bosses = {
		Boss:New({ -- Vexie and the Geargrinders
			bossID = {
				225821, -- The Geargrinder
			},
			journalEncounterID = 2639,
			dungeonEncounterID = 3009,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Cauldron of Carnage
			bossID = {
				229181, -- Flarendo
				229177, -- Torque
			},
			journalEncounterID = 2640,
			dungeonEncounterID = 3010,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Rik Reverb
			bossID = {
				228648, -- Rik
			},
			journalEncounterID = 2641,
			dungeonEncounterID = 3011,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Stix Bunkjunker
			bossID = {
				230322, -- Stix
			},
			journalEncounterID = 2642,
			dungeonEncounterID = 3012,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Sprocketmonger Lockenstock
			bossID = {
				230583, -- Sprocketmonger
			},
			journalEncounterID = 2653,
			dungeonEncounterID = 3013,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- The One-Armed Bandit
			bossID = {
				228458, -- Bandit
			},
			journalEncounterID = 2644,
			dungeonEncounterID = 3014,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Mug'Zee, Heads of Security
			bossID = {
				229953, -- Mug'Zee
			},
			journalEncounterID = 2645,
			dungeonEncounterID = 3015,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
		Boss:New({ -- Chrome King Gallywix
			bossID = {
				237194, -- Gallywix
			},
			journalEncounterID = 2646,
			dungeonEncounterID = 3016,
			instanceID = 2769,
			abilities = {},
			phases = {},
		}),
	},
})
