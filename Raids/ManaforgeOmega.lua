local _, Namespace = ...

local isElevenDotTwo = select(4, GetBuildInfo()) >= 110200 -- Remove when 11.2 is live
if true then
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
				[2] = { combatLogEventSpellID = 1220618, combatLogEventType = "SAA" },
				[3] = { combatLogEventSpellID = 1220618, combatLogEventType = "SAR" },
				[4] = { combatLogEventSpellID = 1220981, combatLogEventType = "SAA" },
				[5] = { combatLogEventSpellID = 1220981, combatLogEventType = "SAR" },
				[6] = { combatLogEventSpellID = 1220982, combatLogEventType = "SAA" },
				[7] = { combatLogEventSpellID = 1220982, combatLogEventType = "SAR" },
			},
			abilities = {
				[1234733] = BossAbility:New({ -- Cleanse the Chamber
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.02 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 29.76 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 29.89 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 63.39 },
							repeatInterval = { 7.03, 10.37 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1232543] = BossAbility:New({ -- Energy Overload
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 61.00 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 95.84 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 96.47 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1219531] = BossAbility:New({ -- Eradicating Salvo
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.08 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 20.81, 32.73, 32.59 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 20.89, 32.61, 32.88 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 20.96 },
							repeatInterval = { 33.0 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1219450] = BossAbility:New({ -- Manifest Matrices
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.03, 29.09 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 5.23, 25.86, 25.94, 25.03 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 5.28, 25.52, 26.25, 25.23 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 5.30, 23.50, 26.33, 33.28 },
							repeatInterval = { 30.87 },
						}),
					},
					duration = 6.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1219263] = BossAbility:New({ -- Obliteration Arcanocannon
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 21.84, 30.57 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 13.49, 28.63, 28.60 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 13.60, 28.77, 28.71 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 13.71, 28.81, 30.21 },
							repeatInterval = { 30.21 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1223364] = BossAbility:New({ -- Powered Automaton
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.02 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 1.57 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 1.66 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 1.65 },
						}),
					},
					durationLastsUntilEndOfPhase = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1227639] = BossAbility:New({ -- Static Lightning
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 62.46 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 95.67 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 96.17 },
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1220618] = BossAbility:New({ -- Protocol: Purge (Buff 1)
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220981] = BossAbility:New({ -- Protocol: Purge (Buff 2)
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220982] = BossAbility:New({ -- Protocol: Purge (Buff 3)
					phases = {
						[6] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220489] = BossAbility:New({ -- Protocol: Purge (Cast 1)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.84 },
						}),
					},
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220553] = BossAbility:New({ -- Protocol: Purge (Cast 2)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 93.98 },
						}),
					},
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220555] = BossAbility:New({ -- Protocol: Purge (Cast 3)
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 94.53 },
						}),
					},
					signifiesPhaseEnd = true,
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 65.8,
					defaultDuration = 65.8,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 50.0,
					defaultDuration = 50.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
				}),
				[3] = BossPhase:New({
					duration = 100.5,
					defaultDuration = 100.5,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[4] = BossPhase:New({
					duration = 50.0,
					defaultDuration = 50.0,
					count = 1,
					defaultCount = 1,
					name = "Int2",
				}),
				[5] = BossPhase:New({
					duration = 100.5,
					defaultDuration = 100.5,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[6] = BossPhase:New({
					duration = 50.0,
					defaultDuration = 50.0,
					count = 1,
					defaultCount = 1,
					name = "Int3",
				}),
				[7] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
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
			abilities = {
				[1227782] = BossAbility:New({ -- Arcane Outrage
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 17.26 },
							repeatInterval = { 20.00 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1227784] = BossAbility:New({ -- Arcane Outrage
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 19.27 },
							repeatInterval = { 20.00 },
						}),
					},
					duration = 4.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1237272] = BossAbility:New({ -- Lair Weaving
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 0.52 },
							repeatInterval = { 7.02, 36.46, 7.00, 34.51 },
						}),
					},
					duration = 5.0, -- Channel
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1226395] = BossAbility:New({ -- Overinfusion Burst
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 75.94 },
							repeatInterval = { 85.0 },
						}),
					},
					duration = 8.0, -- Channel
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1227263] = BossAbility:New({ -- Piercing Strand
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 12.58 },
							repeatInterval = { 3.96, 39.52, 4.95, 36.55 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1227261] = BossAbility:New({ -- Piercing Strand
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.58 },
							repeatInterval = { 3.96, 39.52, 4.95, 36.55 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					defaultHidden = true,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1227227] = BossAbility:New({ -- Writhing Wave
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 14.27 },
							repeatInterval = { 20.0 },
						}),
					},
					duration = 25.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1227226] = BossAbility:New({ -- Writhing Wave
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 10.27 },
							repeatInterval = { 20.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					name = "P2 (50%)",
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
