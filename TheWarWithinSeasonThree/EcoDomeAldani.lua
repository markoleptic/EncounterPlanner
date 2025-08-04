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
			abilities = {
				[1217232] = BossAbility:New({ -- Devour
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.64 },
							repeatInterval = { 86.23 },
						}),
					},
					duration = 18.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1217327] = BossAbility:New({ -- Invading Shriek
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.78 },
							repeatInterval = { 37.62, 48.87 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1227745] = BossAbility:New({ -- Toxic regurgitation
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.69 },
							repeatInterval = { 18.37, 18.39, 49.47 },
						}),
					},
					duration = 6.0,
					castTime = 3.5,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
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
			abilities = {
				[1219482] = BossAbility:New({ -- Rift Claws
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.79, 24.04 },
							repeatInterval = { 51.60, 23.92, 26.73 },
						}),
					},
					duration = 8.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
					tankAbility = true,
				}),
				[1236130] = BossAbility:New({ -- Binding Javelin
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.81 },
							repeatInterval = { 75.60, 26.63 },
						}),
					},
					duration = 5.0, -- Varies
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1219700] = BossAbility:New({ -- Arcane Blitz
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 33.79 },
							repeatInterval = { 102.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220511] = BossAbility:New({ -- Arcane Overload
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.63 },
							repeatInterval = { 102.0 },
						}),
					},
					duration = 16.0, -- Approx.
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1219457] = BossAbility:New({ -- Incorporeal
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 38.63 },
							repeatInterval = { 102.0 },
						}),
					},
					duration = 16.0, -- Approx.
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
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
			abilities = {
				[1224793] = BossAbility:New({ -- Whispers of Fate
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 6.46 },
							repeatInterval = { 18.25, 18.25, 50.84 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225174] = BossAbility:New({ -- Ceremonial Dagger
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 10.02 },
							repeatInterval = { 36.5, 50.84 },
						}),
					},
					duration = 6.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225218] = BossAbility:New({ -- Dread of the Unknown
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 28.29 },
							repeatInterval = { 88.09, 87.34 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1236703] = BossAbility:New({ -- Eternal Weave
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 56.92 },
							repeatInterval = { 87.34 },
						}),
					},
					duration = 24.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					fixedCount = true,
					name = "P1",
				}),
			},
		}),
	},
})
