local _, Namespace = ...

local isElevenDotTwo = select(4, GetBuildInfo()) >= 110200 -- Remove when 11.2 is live
if not isElevenDotTwo then
	return
end

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

Private.dungeonInstances[2810] = DungeonInstance:New({
	journalInstanceID = 1302,
	instanceID = 2810,
	bosses = {
		Boss:New({ -- Plexus Sentinel
			bossIDs = {
				233814, -- Plexus Sentinel
				243241, -- Volatile Manifestation
				-- nil, -- Arcanomatrix Warden
				-- nil, -- Overloading Attendant
			},
			journalEncounterCreatureIDsToBossIDs = {
				-- = 233814 -- Plexus Sentinel
				-- = 243241, -- Volatile Manifestation
				-- [5945] = nil, -- Arcanomatrix Warden
				-- [5946] = nil, -- Overloading Attendant
			},
			journalEncounterID = 2684,
			dungeonEncounterID = 3129,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Loom'ithar
			bossIDs = {
				233815, -- Loom'ithar
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5958] = 233815, -- Loom'ithar
			},
			journalEncounterID = 2686,
			dungeonEncounterID = 3131,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Soulbinder Naazindhri
			bossIDs = {
				233816, -- Soulbinder Naazindhri
				237981, -- Shadowguard Mage
				242730, -- Shadowguard Assassin
				244922, -- Shadowguard Phaseblade
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5959] = 233816, -- Soulbinder Naazindhri
				[6031] = 237981, -- Shadowguard Mage
				[6032] = 242730, -- Shadowguard Assassin
				[6033] = 244922, -- Shadowguard Phaseblade
			},
			journalEncounterID = 2685,
			dungeonEncounterID = 3130,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Forgeweaver Araz
			bossIDs = {
				247989, -- Forgeweaver Araz
				241923, -- Arcane Echo
				240905, -- Arcane Collector
				241832, -- Shielded Attendant
				242586, -- Arcane Manifestation
				242589, -- Void Manifestation
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5939] = 247989, -- Forgeweaver Araz
				[5932] = 241923, -- Arcane Echo
				[5938] = 240905, -- Arcane Collector
				[5937] = 241832, -- Shielded Attendant
				[5995] = 242586, -- Arcane Manifestation
				[5996] = 242589, -- Void Manifestation
			},
			journalEncounterID = 2687,
			dungeonEncounterID = 3132,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- The Soul Hunters
			bossIDs = {
				237661, -- Adarus Duskblaze
				248404, -- Velaryn Bloodwrath
				237662, -- Ilyssa Darksorrow
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5902] = 237661, -- Adarus Duskblaze
				[5901] = 248404, -- Velaryn Bloodwrath
				[5900] = 237662, -- Ilyssa Darksorrow
			},
			journalEncounterID = 2688,
			dungeonEncounterID = 3122,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Fractillus
			bossIDs = {
				237861, -- Fractillus
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5933] = 237861, -- Fractillus
			},
			journalEncounterID = 2747,
			dungeonEncounterID = 3133,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Nexus-King Salhadaar
			bossIDs = {
				237763, -- Nexus-King Salhadaar
				233823, -- The Royal Voidwing
				241800, -- Manaforged Titan
				241803, -- Nexus-Prince Ky'vor
				241798, -- Nexus-Prince Xevvos
				241801, -- Shadowguard Reaper
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5871] = 237763, -- Nexus-King Salhadaar
				[5903] = 233823, -- The Royal Voidwing
				[5923] = 241800, -- Manaforged Titan
				[6011] = 241803, -- Nexus-Prince Ky'vor
				[6010] = 241798, -- Nexus-Prince Xevvos
				[5925] = 241801, -- Shadowguard Reaper
			},
			journalEncounterID = 2690,
			dungeonEncounterID = 3134,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
		Boss:New({ -- Dimensius, the All-Devouring
			bossIDs = {
				233824, -- Dimensius
				245255, -- Artoshion
				245222, -- Pargoth
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5951] = 233824, -- Dimensius
				[5952] = 245255, -- Artoshion
				[5950] = 245222, -- Pargoth
			},
			journalEncounterID = 2691,
			dungeonEncounterID = 3135,
			instanceID = 2810,
			preferredCombatLogEventAbilities = {
				[1] = nil,
			},
			abilities = {},
			phases = {
				[1] = BossPhase:New({
					duration = 120.0,
					defaultDuration = 120.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
			},
		}),
	},
	-- executeAndNil = function()
	-- 	EJ_SelectInstance(Private.dungeonInstances[2769].journalInstanceID)
	-- 	local journalEncounterID = Private.dungeonInstances[2769].bosses[2].journalEncounterID
	-- 	EJ_SelectEncounter(journalEncounterID)
	-- 	local _, bossName, _, _, _, _ = EJ_GetCreatureInfo(1, journalEncounterID)
	-- 	Private.dungeonInstances[2769].bosses[2].abilities[465863].additionalContext = bossName:match("^(%S+)")
	-- 	_, bossName, _, _, _, _ = EJ_GetCreatureInfo(2, journalEncounterID)
	-- 	Private.dungeonInstances[2769].bosses[2].abilities[465872].additionalContext = bossName:match("^(%S+)")
	-- end,
	isRaid = true,
})
