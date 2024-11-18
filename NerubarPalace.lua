---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class TimelineAssignment
local TimelineAssignment = Private.classes.TimelineAssignment

local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

Private.raidInstances = {
	["Nerub'ar Palace"] = Private.classes.RaidInstance:New({
		name = "Nerub'ar Palace",
		journalInstanceId = 1273,
		instanceId = 2657,
		bosses = {
			Private.classes.BossDefinition:New({
				name = "Ulgrax the Devourer",
				bossID = 215657,
				journalEncounterID = 2607,
				dungeonEncounterID = 2902,
			}),
			Private.classes.BossDefinition:New({
				name = "The Bloodbound Horror",
				bossID = 214502,
				journalEncounterID = 2611,
				dungeonEncounterID = 2917,
			}),
			Private.classes.BossDefinition:New({
				name = "Sikran, Captain of the Sureki",
				bossID = 214503,
				journalEncounterID = 2599,
				dungeonEncounterID = 2898,
			}),
			Private.classes.BossDefinition:New({
				name = "Rasha'nan",
				bossID = 214504,
				journalEncounterID = 2609,
				dungeonEncounterID = 2918,
			}),
			Private.classes.BossDefinition:New({
				name = "Broodtwister Ovi'nax",
				bossID = 214506,
				journalEncounterID = 2612,
				dungeonEncounterID = 2919,
			}),
			Private.classes.BossDefinition:New({
				name = "Nexus-Princess Ky'veza",
				bossID = 217748,
				journalEncounterID = 2601,
				dungeonEncounterID = 2920,
			}),
			Private.classes.BossDefinition:New({
				name = "The Silken Court",
				bossID = { 217489, 217491 },
				journalEncounterID = 2608,
				dungeonEncounterID = 2921,
			}),
			Private.classes.BossDefinition:New({
				name = "Queen Ansurek",
				bossID = 218370,
				journalEncounterID = 2602,
				dungeonEncounterID = 2922,
			}),
		},
	}),
}

local bosses = {
	["Ulgrax the Devourer"] = Private.classes.Boss:New({
		abilities = {
			[435136] = Private.classes.BossAbility:New({ -- Venomous Lash
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 5.0, 25.0, 28.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[435138] = Private.classes.BossAbility:New({ -- Digestive Acid
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 20.0, 47.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[434803] = Private.classes.BossAbility:New({ -- Carnivorous Contest
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 38.0, 36.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 4.0,
			}),
			[445123] = Private.classes.BossAbility:New({ -- Hulking Crash
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 90.0 },
						repeatInterval = nil,
					}),
				},
				duration = 0.0,
				castTime = 5.0,
			}),
			[436200] = Private.classes.BossAbility:New({ -- Juggernaut Charge
				phases = {
					[2] = Private.classes.BossAbilityPhase:New({
						castTimes = { 16.7, 7.1, 7.1, 7.1 },
						repeatInterval = nil,
					}),
				},
				duration = 8.0,
				castTime = 4.0,
			}),
			[438012] = Private.classes.BossAbility:New({ -- Hungering Bellows
				phases = {
					[2] = Private.classes.BossAbilityPhase:New({
						castTimes = { 60.8 },
						repeatInterval = 7,
					}),
				},
				duration = 3.0,
				castTime = 3.0,
			}),
			[445052] = Private.classes.BossAbility:New({ -- Chittering Swarm
				phases = {
					[2] = Private.classes.BossAbilityPhase:New({
						castTimes = { 6 },
						repeatInterval = nil,
					}),
				},
				duration = 0.0,
				castTime = 3.0,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:New({
				duration = 90,
				defaultDuration = 90,
				count = 3,
				defaultCount = 3,
				repeatAfter = 2,
			}),
			[2] = Private.classes.BossPhase:New({
				duration = 80,
				defaultDuration = 80,
				count = 3,
				defaultCount = 3,
				repeatAfter = 1,
			}),
		},
	}),
	-- ["The Bloodbound Horror"] = Private.classes.Boss:New({}),
	-- ["Sikran, Captain of the Sureki"] = Private.classes.Boss:New({}),
	-- ["Rasha'nan"] = Private.classes.Boss:New({}),
	["Broodtwister Ovi'nax"] = Private.classes.Boss:New({
		abilities = {
			[441362] = Private.classes.BossAbility:New({ -- Volatile Concoction
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 2.0 },
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:New({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						repeatInterval = {
							triggerCastIndex = 3,
							castTimes = { 20.0 },
						},
					}),
				},
				duration = 0.0,
				castTime = 1.5,
			}),
			[446349] = Private.classes.BossAbility:New({ -- Sticky Web
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 15.0 },
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:New({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 30.0, 30.0, 30.0, 30.0 },
						repeatInterval = {
							triggerCastIndex = 3,
							castTimes = { 30.0 },
						},
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[442432] = Private.classes.BossAbility:New({ -- Ingest Black Blood
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 19.0, 171.0, 172.0 },
						repeatInterval = nil,
					}),
				},
				duration = 15.0,
				castTime = 1.0,
			}),
			[442526] = Private.classes.BossAbility:New({ -- Experimental Dosage
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = nil,
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:New({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 16.0, 50.0, 50.0 },
						repeatInterval = {
							triggerCastIndex = 3,
							castTimes = { 50.0 },
						},
					}),
				},
				duration = 8.0,
				castTime = 1.5,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:New({
				duration = 600,
				defaultDuration = 600,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
		},
	}),
	["Nexus-Princess Ky'veza"] = Private.classes.Boss:New({
		abilities = {
			[436867] = Private.classes.BossAbility:New({ -- Assassination
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 15.0, 130.0, 130.0, 130.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 0.0,
				duration = 8.0,
			}),
			[440377] = Private.classes.BossAbility:New({ -- Void Shredders
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 10.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 0.0,
				duration = 5.0,
			}),
			[437620] = Private.classes.BossAbility:New({ -- Nether Rift
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 22.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 4.0,
				duration = 6.0,
			}),
			[438245] = Private.classes.BossAbility:New({ -- Twilight Massacre
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 34.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 0.0,
			}),
			[439576] = Private.classes.BossAbility:New({ -- Nexus Daggers
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 45.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.5,
				duration = 5.0,
			}),
			[435405] = Private.classes.BossAbility:New({ -- Starless Night
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 96.1, 130.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 24.0,
			}),
			[442277] = Private.classes.BossAbility:New({ -- Eternal Night
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 356.1 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 24.0,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:New({
				duration = 385,
				defaultDuration = 385,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
		},
	}),
	["The Silken Court"] = Private.classes.Boss:New({
		abilities = {
			[440504] = Private.classes.BossAbility:New({ -- Impaling Eruption
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 8.0, 20.0, 34.0, 20.0 },
						repeatInterval = nil,
					}),
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 11.0, 30.0, 30.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 4.5,
				duration = 0.0,
			}),
			[438218] = Private.classes.BossAbility:New({ -- Piercing Strike
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 13.0, 20.0, 27.0, 20.0 },
						repeatInterval = nil,
					}),
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 16.0, 20.0, 25.0, 15.0, 20.0, 25.0 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 20.0, 17.0, 32.0, 20.0, 21.0, 20.0, 36.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.5,
				duration = 0.0,
			}),
			[438801] = Private.classes.BossAbility:New({ -- Call of the Swarm
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 25.0, 53.0 },
						repeatInterval = nil,
					}),
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 31.0, 61.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 3,
				duration = 0.0,
			}),
			[441791] = Private.classes.BossAbility:New({ -- Burrowed Eruption
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 35.0, 60.0 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 43.0, 98.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.8,
				duration = 0.0,
			}),
			[440246] = Private.classes.BossAbility:New({ -- Reckless Charge
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 38.5, 60.0 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 46.1, 98.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.8,
				duration = 0.0,
			}),
			[450045] = Private.classes.BossAbility:New({ -- Skittering Leap
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 42.1, 60.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.0,
				duration = 0.0,
			}),
			[439838] = Private.classes.BossAbility:New({ -- Web Bomb
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 16.7, 70.2 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.5,
				duration = 0.0,
			}),
			[438656] = Private.classes.BossAbility:New({ -- Venomous Rain
				phases = {
					[1] = Private.classes.BossAbilityPhase:New({
						castTimes = { 19.8, 33.3, 26.8 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.5,
				duration = 10.0,
			}),
			[438677] = Private.classes.BossAbility:New({ -- Stinging Swarm
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 25.0, 58.0 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 81.1, 57.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 2.0,
				duration = 0.0,
			}),
			[441782] = Private.classes.BossAbility:New({ -- Strands of Reality
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 32.0, 36.0, 24.0 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 22.2, 33.7, 24.9, 43.0, 33.8, 24.9, 43.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 4.5,
				duration = 0.0,
			}),
			[450483] = Private.classes.BossAbility:New({ -- Void Step
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 38.7, 34.2, 23.6, 29.2 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 49.3, 40.5, 29.1, 30.1, 2.6, 38.4, 29.2, 30.1, 2.7 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.0,
				duration = 0.0,
			}),
			[441626] = Private.classes.BossAbility:New({ -- Web Vortex
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 20.2, 55.8 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 33.4, 33.7, 63.8, 33.7, 64.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 2.0,
				duration = 16.0,
			}),
			[450129] = Private.classes.BossAbility:New({ -- Entropic Desolation
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 25.4, 55.8 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 38.7, 33.7, 63.8, 33.7, 64.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 4.5,
				duration = 8.0,
			}),
			[438355] = Private.classes.BossAbility:New({ -- Cataclysmic Entropy
				phases = {
					[3] = Private.classes.BossAbilityPhase:New({
						castTimes = { 41.7, 57.9 },
						repeatInterval = nil,
					}),
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 92.7, 61.8 },
						repeatInterval = nil,
					}),
				},
				castTime = 10.0,
				duration = 0.0,
			}),
			[463459] = Private.classes.BossAbility:New({ -- Apex of Entropy
				phases = {
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 170.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 3.0,
				duration = 8.0,
			}),
			[443598] = Private.classes.BossAbility:New({ -- Uncontrollable Rage
				phases = {
					[5] = Private.classes.BossAbilityPhase:New({
						castTimes = { 170.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 3.0,
				duration = 8.0,
			}),
			[450980] = Private.classes.BossAbility:New({ -- Shatter Existence
				phases = {
					[2] = Private.classes.BossAbilityPhase:New({
						castTimes = { 0.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 45.0,
				duration = 0.0,
			}),
			[451277] = Private.classes.BossAbility:New({ -- Spike Storm
				phases = {
					[4] = Private.classes.BossAbilityPhase:New({
						castTimes = { 0.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 45.0,
				duration = 0.0,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:New({ -- Stage 1: Clash of Rivals
				duration = 127,
				defaultDuration = 127,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
			[2] = Private.classes.BossPhase:New({ -- Intermission: Void Ascension
				duration = 45,
				defaultDuration = 45,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
			[3] = Private.classes.BossPhase:New({ -- Stage 2: Grasp of the Void
				duration = 131,
				defaultDuration = 131,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
			[4] = Private.classes.BossPhase:New({ -- Intermission: Raging Fury
				duration = 45,
				defaultDuration = 45,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
			[5] = Private.classes.BossPhase:New({ -- Stage 3: Unleashed Rage
				duration = 252,
				defaultDuration = 252,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
		},
	}),
	-- ["Queen Ansurek"] = Private.classes.Boss:New({}),
}

-- Generate a list of abilities for each boss sorted by their first cast time
for _, boss in pairs(bosses) do
	local firstAppearances = {}
	local firstAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		for phaseNumber, phase in pairs(data.phases) do
			if phase.castTimes then
				for _, castTime in ipairs(phase.castTimes) do
					if phaseNumber > 1 then
						local phaseTimeOffset = boss.phases[phaseNumber].duration
						earliestCastTime = min(earliestCastTime, phaseTimeOffset + castTime)
					else
						earliestCastTime = min(earliestCastTime, castTime)
					end
				end
			end
		end
		firstAppearancesMap[spellID] = earliestCastTime
		tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
	end
	local firstEventTriggerAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		if data.eventTriggers then
			for triggerSpellID, eventTrigger in pairs(data.eventTriggers) do
				local earliestTriggerCastTime = firstAppearancesMap[triggerSpellID]
				local castTime = earliestTriggerCastTime
					+ boss.abilities[triggerSpellID].castTime
					+ eventTrigger.castTimes[1]
				earliestCastTime = min(earliestCastTime, castTime)
			end
			firstEventTriggerAppearancesMap[spellID] = earliestCastTime
		end
	end

	for _, data in pairs(firstAppearances) do
		if firstEventTriggerAppearancesMap[data.spellID] then
			data.earliestCastTime = min(data.earliestCastTime, firstEventTriggerAppearancesMap[data.spellID])
		end
	end

	for spellID, earliestCastTime in pairs(firstEventTriggerAppearancesMap) do
		local found = false
		for _, data in pairs(firstAppearances) do
			if data.spellID == spellID then
				found = true
				break
			end
		end
		if not found then
			tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
		end
	end

	sort(firstAppearances, function(a, b)
		return a.earliestCastTime < b.earliestCastTime
	end)
	boss.sortedAbilityIDs = {}
	for _, entry in ipairs(firstAppearances) do
		tinsert(boss.sortedAbilityIDs, entry.spellID)
	end
end

Private.bosses["Nerub'ar Palace"] = bosses
