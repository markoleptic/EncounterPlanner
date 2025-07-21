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
							signifiesPhaseEnd = true,
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220981] = BossAbility:New({ -- Protocol: Purge (Buff 2)
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220982] = BossAbility:New({ -- Protocol: Purge (Buff 3)
					phases = {
						[6] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					durationLastsUntilEndOfNextPhase = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA", "SAR" },
				}),
				[1220489] = BossAbility:New({ -- Protocol: Purge (Cast 1)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 60.84 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220553] = BossAbility:New({ -- Protocol: Purge (Cast 2)
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 93.98 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220555] = BossAbility:New({ -- Protocol: Purge (Cast 3)
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 94.53 },
							signifiesPhaseEnd = true,
						}),
					},
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
					halfHeight = true,
					duration = 45.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1227227] = BossAbility:New({ -- Writhing Wave
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 14.27 },
							repeatInterval = { 20.0 },
						}),
					},
					halfHeight = true,
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
			abilities = {
				[1242088] = BossAbility:New({ -- Arcane Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 41.0 },
							repeatInterval = { 38.0, 67.0, 45.0 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1224025] = BossAbility:New({ -- Mythic Lash (Targeting)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.0 },
							repeatInterval = { 41.0, 38.0, 40.0, 31.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1241100] = BossAbility:New({ -- Mythic Lash (Cast)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 5.0 },
							repeatInterval = { 41.0, 38.0, 40.0, 31.0 },
						}),
					},
					duration = 5.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1225582] = BossAbility:New({ -- Soul Calling
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 13.0 },
							repeatInterval = { 150.0 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225616] = BossAbility:New({ -- Soulfire Convergence
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 16.0 },
							repeatInterval = { 37.0, 38.0, 75.0 },
						}),
					},
					duration = 3.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1227276] = BossAbility:New({ -- Soulfray Annihilation (Targeting)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 26.0 },
							repeatInterval = { 37.0, 37.0, 76.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1227279] = BossAbility:New({ -- Soulfray Annihilation (Cast)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 30.0 },
							repeatInterval = { 37.0, 37.0, 76.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1245422] = BossAbility:New({ -- Tsunami of Arcane
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.0 },
							repeatInterval = { 38.0, 67.0, 45.0 },
						}),
					},
					duration = 5.2,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 300.0,
					defaultDuration = 300.0,
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
			preferredCombatLogEventAbilities = {},
			abilities = {
				[1227631] = BossAbility:New({ -- Arcane Expulsion
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 155.00 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 141.73 },
						}),
					},
					duration = 0.0,
					castTime = 5.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1230231] = BossAbility:New({ -- Phase Transition P1 -> P2
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1235338] = BossAbility:New({ -- Phase Transition
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 0.00 },
							signifiesPhaseStart = true,
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1228216] = BossAbility:New({ -- Arcane Obliteration
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.08, 44.92 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 70.84 },
						}),
					},
					duration = 0.0,
					castTime = 5.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1231720] = BossAbility:New({ -- Invoke Collector
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.0, 44.0, 44.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 25.78, 22.0, 44.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1231719] = BossAbility:New({ -- Invoke Collector
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 11.0, 44.0, 44.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 27.82, 22.0, 44.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					defaultHidden = true,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1230529] = BossAbility:New({ -- Mana Sacrifice
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 2.05 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 1.97 },
						}),
					},
					duration = 5.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1228502] = BossAbility:New({ -- Overwhelming Power
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 4.0 },
							repeatInterval = { 22.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 22.0 },
							repeatInterval = { 22.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 28.55 },
							repeatInterval = { 22.0 },
						}),
					},
					duration = 0.0,
					castTime = 1.2,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1228161] = BossAbility:New({ -- Silencing Tempest
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 63.0, 44.0, 23.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 59.82, 43.89, 21.02 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 36.55, 43.24, 21.02 },
						}),
					},
					duration = 3.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 160.0,
					defaultDuration = 160.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 40.0,
					defaultDuration = 40.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
				}),
				[3] = BossPhase:New({
					duration = 146.7,
					defaultDuration = 146.7,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[4] = BossPhase:New({
					duration = 54.0,
					defaultDuration = 54.0,
					count = 1,
					defaultCount = 1,
					name = "Int2",
				}),
				[5] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					name = "P2",
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
				[2] = { combatLogEventSpellID = 1233093, combatLogEventType = "SAA" },
				[3] = { combatLogEventSpellID = 1245978, combatLogEventType = "SAR" },
				[4] = { combatLogEventSpellID = 1233863, combatLogEventType = "SAA" },
				[5] = { combatLogEventSpellID = 1245978, combatLogEventType = "SAR" },
				[6] = { combatLogEventSpellID = 1233672, combatLogEventType = "SCC" },
				[7] = { combatLogEventSpellID = 1245978, combatLogEventType = "SAR" },
			},
			abilities = {
				[1233093] = BossAbility:New({ -- Collapsing Star
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 26.1 },
						}),
					},
					duration = 25.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA" },
				}),
				[1233863] = BossAbility:New({ -- Fel Rush
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true,
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 28.6 },
						}),
					},
					duration = 24.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SAA" },
				}),
				[1227117] = BossAbility:New({ -- Fel Devastation
					phases = {
						[6] = BossAbilityPhase:New({
							castTimes = { 2.31, 9.0, 9.0 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 30.71 },
							repeatInterval = { 9.0 },
						}),
					},
					duration = 4.5,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1233672] = BossAbility:New({ -- Infernal Strike
					phases = {
						[6] = BossAbilityPhase:New({
							castTimes = { 0.0, 9.0, 9.0 },
							signifiesPhaseStart = true,
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 28.4 },
							repeatInterval = { 9.0 },
						}),
					},
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1245978] = BossAbility:New({ -- Soul Tether
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 1.19, 0.0 },
						}),
						[4] = BossAbilityPhase:New({
							castTimes = { 0.73, 0.0 },
						}),
						[6] = BossAbilityPhase:New({
							castTimes = { 0.73, 0.0 },
							signifiesPhaseEnd = true,
						}),
					},
					duration = 24.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC", "SAA", "SAR" },
				}),
				[1245743] = BossAbility:New({ -- Eradicate (Targeting)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.13, 34.33 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 34.58, 34.27 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 34.58, 34.25 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1245726] = BossAbility:New({ -- Eradicate (Casts)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 51.26, 5.2, 5.2, 5.2, 18.67, 5.2, 5.2, 5.2 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 39.61, 5.2, 5.2, 5.2, 18.78, 5.2, 5.2, 5.2 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 39.72, 5.2, 5.2, 5.2, 18.80, 5.2, 5.2, 5.2 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1218103] = BossAbility:New({ -- Eye Beam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 19.36, 31.91, 31.94 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 7.76, 31.91, 31.92 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 7.76, 31.91, 31.92 },
						}),
					},
					duration = 4.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225130] = BossAbility:New({ -- Felblade
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.80, 32.27, 31.72 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 14.48, 32.04, 31.53 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 14.16, 31.89, 31.96 },
						}),
					},
					duration = 25.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1241833] = BossAbility:New({ -- Fracture
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 15.16, 32.04, 31.73 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 3.53, 31.89, 31.92 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 3.52, 31.90, 31.91 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1232569] = BossAbility:New({ -- Meta (Adarus)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 102.16 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 91.78 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 91.45 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 20.40 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1231501] = BossAbility:New({ -- Meta (Velaryn)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 102.80 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 90.84 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 91.75 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 21.04 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1232568] = BossAbility:New({ -- Meta (Ilyssa)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 103.10 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 91.48 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 90.81 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 21.34 },
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1240891] = BossAbility:New({ -- Sigil of Chains
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 37.94, 31.94 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 26.38, 31.92 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 26.37, 31.92 },
						}),
					},
					duration = 6.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1242259] = BossAbility:New({ -- Spirit Bomb
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 31.01, 31.91, 31.95 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 19.46, 31.91, 31.91 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 19.46, 31.91, 31.91 },
						}),
					},
					duration = 0.0,
					castTime = 3.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1227809] = BossAbility:New({ -- The Hunt (Targeting)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 40.27, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 28.74, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 28.75, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
					},
					halfHeight = true,
					duration = 0.0,
					castTime = 6.0,
					defaultHidden = true,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1227823] = BossAbility:New({ -- The Hunt (Casts)
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 46.27, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
						[3] = BossAbilityPhase:New({
							castTimes = { 34.74, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 34.75, 3.0, 3.0, 26.0, 3.0, 3.0 },
						}),
					},
					halfHeight = true,
					duration = 0.0,
					castTime = 0.0,
					allowedCombatLogEventTypes = { "SCC" },
				}),
				[1227355] = BossAbility:New({ -- Voidstep
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 25.84, 31.56 },
						}),
						[5] = BossAbilityPhase:New({
							castTimes = { 14.24, 31.58 },
						}),
						[7] = BossAbilityPhase:New({
							castTimes = { 10.58 },
						}),
					},
					duration = 0.0,
					castTime = 2.5,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 109.1,
					defaultDuration = 109.1,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[2] = BossPhase:New({
					duration = 25.2,
					defaultDuration = 25.2,
					count = 1,
					defaultCount = 1,
					name = "Int1",
				}),
				[3] = BossPhase:New({ -- 134.3
					duration = 98.0,
					defaultDuration = 98.0,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[4] = BossPhase:New({
					duration = 24.8,
					defaultDuration = 24.8,
					count = 1,
					defaultCount = 1,
					name = "Int2",
				}),
				[5] = BossPhase:New({ -- 257.1
					duration = 97.8,
					defaultDuration = 97.8,
					count = 1,
					defaultCount = 1,
					name = "P1",
				}),
				[6] = BossPhase:New({ --  354.9
					duration = 25.8,
					defaultDuration = 25.8,
					count = 1,
					defaultCount = 1,
					name = "Int3",
				}),
				[7] = BossPhase:New({ -- 380.70
					duration = 60.0,
					defaultDuration = 60.0,
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
			abilities = {
				[1233416] = BossAbility:New({ -- Crystalline Eruption
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 14.74, 20.48, 29.92, 20.69, 30.25, 20.61 },
							repeatInterval = { 20.6, 30.2 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1231871] = BossAbility:New({ -- Shockwave Slam
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.43 },
							repeatInterval = { 50.9 },
						}),
					},
					halfHeight = true,
					duration = 55.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1220394] = BossAbility:New({ -- Shattering Backhand
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 48.6 },
							repeatInterval = { 50.9 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 300.0,
					defaultDuration = 300.0,
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
				[2] = { combatLogEventSpellID = 1227734, combatLogEventType = "SCC" },
				[3] = { combatLogEventSpellID = 1228065, combatLogEventType = "SCC" },
				[4] = { combatLogEventSpellID = 1228265, combatLogEventType = "SAA" },
				[5] = { combatLogEventSpellID = 1228265, combatLogEventType = "SAR" },
			},
			abilities = {
				[1227734] = BossAbility:New({ -- Coalesce Voidwing
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 119.5 },
							signifiesPhaseEnd = true, -- End of P1
						}),
					},
					duration = 0.0,
					castTime = 6.2,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1227529] = BossAbility:New({ -- Banishment
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 32.94, 15.71, 23.17, 14.68 },
						}),
					},
					duration = 8.0,
					castTime = 1.35,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225010] = BossAbility:New({ -- Command: Behead
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 34.52, 37.97 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1225016] = BossAbility:New({ -- Command: Besiege
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 9.17, 39.9 },
							repeatInterval = { 39.9 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1224787] = BossAbility:New({ -- Conquer
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 17.23, 8.04, 31.83, 7.13, 33.36, 5.79 },
						}),
					},
					halfHeight = true,
					duration = 20.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1224906] = BossAbility:New({ -- Invoke the Oath
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 115.0 },
						}),
					},
					duration = 0.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1224812] = BossAbility:New({ -- Vanquish
					phases = {
						[1] = BossAbilityPhase:New({
							castTimes = { 18.26, 7.55, 33.14, 5.60, 33.59, 4.90 },
						}),
					},
					halfHeight = true,
					duration = 20.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1228065] = BossAbility:New({ -- Rally the Shadowguard
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 32.25 },
							signifiesPhaseEnd = true, -- End of P2
						}),
					},
					duration = 0.0,
					castTime = 4.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1234529] = BossAbility:New({ -- Cosmic Maw
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 9.28 },
						}),
					},
					duration = 10.0,
					castTime = 1.25,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1237068] = BossAbility:New({ -- Dimensional Breath
					phases = {
						[2] = BossAbilityPhase:New({
							castTimes = { 14.61, 5.69, 5.46 },
						}),
					},
					duration = 4.0,
					castTime = 2.0,
					allowedCombatLogEventTypes = {},
				}),
				[1232327] = BossAbility:New({ -- Seal the Forge
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 1.00 },
						}),
					},
					duration = 0.0, -- Maybe inf
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1230302] = BossAbility:New({ -- Self-Destruct
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 50.0, 0.0 },
						}),
					},
					duration = 0.0,
					castTime = 10.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1237105] = BossAbility:New({ -- Twilight Barrier
					phases = {
						[3] = BossAbilityPhase:New({
							castTimes = { 13.96 },
						}),
					},
					duration = 0.0,
					castTime = 1.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				-- [1230263] = BossAbility:New({ -- Netherblast
				-- 	phases = {
				-- 		[3] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 2.0,
				-- 	allowedCombatLogEventTypes = { "SCS", "SCC" },
				-- }),
				-- [1228113] = BossAbility:New({ -- Netherbreaker
				-- 	phases = {
				-- 		[3] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 0.0,
				-- 	defaultHidden = true,
				-- 	allowedCombatLogEventTypes = { "SCC" },
				-- }),
				-- [1228115] = BossAbility:New({ -- Netherbreaker
				-- 	phases = {
				-- 		[3] = BossAbilityPhase:New({
				-- 			castTimes = {},
				-- 		}),
				-- 	},
				-- 	duration = 0.0,
				-- 	castTime = 2.0,
				-- 	allowedCombatLogEventTypes = { "SCS", "SCC" },
				-- }),
				[1228265] = BossAbility:New({ -- King's Hunger
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
							signifiesPhaseStart = true, -- End of Int1
							signifiesPhaseEnd = true, -- End of Int2
						}),
					},
					duration = 30.0,
					castTime = 6.2,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1228317] = BossAbility:New({ -- King's Hunger
					phases = {
						[4] = BossAbilityPhase:New({
							castTimes = { 0.0 },
						}),
					},
					defaultHidden = true,
					duration = 30.0,
					castTime = 6.2,
					allowedCombatLogEventTypes = { "SCS", "SCC", "SAA", "SAR" },
				}),
				[1225319] = BossAbility:New({ -- Galactic Smash
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 7.3 },
							repeatInterval = { 55.0 },
						}),
					},
					duration = 0.0,
					castTime = 8.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
				[1226024] = BossAbility:New({ -- Starkiller Swing
					phases = {
						[5] = BossAbilityPhase:New({
							castTimes = { 40.5 },
							repeatInterval = { 55.0 },
						}),
					},
					duration = 0.0,
					castTime = 6.0,
					allowedCombatLogEventTypes = { "SCS", "SCC" },
				}),
			},
			phases = {
				[1] = BossPhase:New({
					duration = 125.2,
					defaultDuration = 125.2,
					count = 1,
					defaultCount = 1,
					name = "P1",
					fixedDuration = true,
				}),
				[2] = BossPhase:New({
					duration = 36.25,
					defaultDuration = 36.25,
					count = 1,
					defaultCount = 1,
					name = "P2",
					fixedDuration = true,
				}),
				[3] = BossPhase:New({
					duration = 60.0,
					defaultDuration = 60.0,
					count = 1,
					defaultCount = 1,
					name = "Int1",
					fixedDuration = true,
				}),
				[4] = BossPhase:New({
					duration = 30.0,
					defaultDuration = 30.0,
					count = 1,
					defaultCount = 1,
					name = "Int2",
					fixedDuration = true,
				}),
				[5] = BossPhase:New({
					duration = 180.0,
					defaultDuration = 180.0,
					count = 1,
					defaultCount = 1,
					name = "P3",
				}),
			},
		}),
		-- Boss:New({ -- Dimensius, the All-Devouring
		-- 	bossIDs = {
		-- 		233824, -- Dimensius
		-- 		245255, -- Artoshion
		-- 		245222, -- Pargoth
		-- 	},
		-- 	journalEncounterCreatureIDsToBossIDs = {
		-- 		[5951] = 233824, -- Dimensius
		-- 		[5952] = 245255, -- Artoshion
		-- 		[5950] = 245222, -- Pargoth
		-- 	},
		-- 	journalEncounterID = 2691,
		-- 	dungeonEncounterID = 3135,
		-- 	instanceID = 2810,
		-- 	preferredCombatLogEventAbilities = {
		-- 		[1] = nil,
		-- 	},
		-- 	abilities = {},
		-- 	phases = {
		-- 		[1] = BossPhase:New({
		-- 			duration = 120.0,
		-- 			defaultDuration = 120.0,
		-- 			count = 1,
		-- 			defaultCount = 1,
		-- 			name = "P1",
		-- 		}),
		-- 	},
		-- }),
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
