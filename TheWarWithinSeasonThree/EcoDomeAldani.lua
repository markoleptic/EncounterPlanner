local _, Namespace = ...

local isElevenDotTwo = select(4, GetBuildInfo()) >= 110200 -- Remove when 11.2 is live
if not isElevenDotTwo then
	return
end

---@class Private
local Private = Namespace
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

Private.dungeonInstances[2830] = DungeonInstance:New({
	journalInstanceID = 1303,
	instanceID = 2830,
	customGroups = { "TheWarWithinSeasonThree" },
	bosses = {
		Boss:New({ -- Azhiccar
			bossIDs = {
				234893, -- Azhiccar
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5841] = 234893, -- Azhiccar
				-- [5866] = , --Frenzied Mite
			},
			journalEncounterID = 2675,
			dungeonEncounterID = 3107,
			instanceID = 2830,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Taah'bat and A'wazj
			bossIDs = {
				234933, -- Taah'bat
				241375, -- A'wazj
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5894] = 234933, -- Taah'bat
				[5895] = 241375, -- A'wazj
			},
			journalEncounterID = 2676,
			dungeonEncounterID = 3108,
			instanceID = 2830,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Soul-Scribe
			bossIDs = {
				247283, -- Soul-Scribe
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5893] = 247283, -- Soul-Scribe
			},
			journalEncounterID = 2677,
			dungeonEncounterID = 3109,
			instanceID = 2830,
			preferredCombatLogEventAbilities = {},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
	},
})
