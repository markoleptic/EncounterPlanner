--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

local AddOn = Private.AddOn
local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

Private.raidInstances = {
	["Nerub'ar Palace"] = Private.classes.RaidInstance:new({
		name = "Nerub'ar Palace",
		journalInstanceId = 1273,
		instanceId = 2657,
		bosses = {
			Private.classes.BossDefinition:new({
				name = "Ulgrax the Devourer",
				bossID = 215657,
				journalEncounterID = 2607,
				dungeonEncounterID = 2902,
			}),
			Private.classes.BossDefinition:new({
				name = "The Bloodbound Horror",
				bossID = 214502,
				journalEncounterID = 2611,
				dungeonEncounterID = 2917,
			}),
			Private.classes.BossDefinition:new({
				name = "Sikran, Captain of the Sureki",
				bossID = 214503,
				journalEncounterID = 2599,
				dungeonEncounterID = 2898,
			}),
			Private.classes.BossDefinition:new({
				name = "Rasha'nan",
				bossID = 214504,
				journalEncounterID = 2609,
				dungeonEncounterID = 2918,
			}),
			Private.classes.BossDefinition:new({
				name = "Broodtwister Ovi'nax",
				bossID = 214506,
				journalEncounterID = 2612,
				dungeonEncounterID = 2919,
			}),
			Private.classes.BossDefinition:new({
				name = "Nexus-Princess Ky'veza",
				bossID = 217748,
				journalEncounterID = 2601,
				dungeonEncounterID = 2920,
			}),
			Private.classes.BossDefinition:new({
				name = "The Silken Court",
				bossID = { 217489, 217491 },
				journalEncounterID = 2608,
				dungeonEncounterID = 2921,
			}),
			Private.classes.BossDefinition:new({
				name = "Queen Ansurek",
				bossID = 218370,
				journalEncounterID = 2602,
				dungeonEncounterID = 2922,
			}),
		},
	}),
}

local bosses = {
	["Ulgrax the Devourer"] = Private.classes.Boss:new({
		abilities = {
			[435136] = Private.classes.BossAbility:new({ -- Venomous Lash
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 5.0, 25.0, 28.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[435138] = Private.classes.BossAbility:new({ -- Digestive Acid
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 20.0, 47.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[434803] = Private.classes.BossAbility:new({ -- Carnivorous Contest
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 38.0, 36.0 },
						repeatInterval = nil,
					}),
				},
				duration = 6.0,
				castTime = 4.0,
			}),
			[445123] = Private.classes.BossAbility:new({ -- Hulking Crash
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 90.0 },
						repeatInterval = nil,
					}),
				},
				duration = 0.0,
				castTime = 5.0,
			}),
			[436200] = Private.classes.BossAbility:new({ -- Juggernaut Charge
				phases = {
					[2] = Private.classes.BossAbilityPhase:new({
						castTimes = { 16.7, 7.1, 7.1, 7.1 },
						repeatInterval = nil,
					}),
				},
				duration = 8.0,
				castTime = 4.0,
			}),
			[438012] = Private.classes.BossAbility:new({ -- Hungering Bellows
				phases = {
					[2] = Private.classes.BossAbilityPhase:new({
						castTimes = { 60.8 },
						repeatInterval = 7,
					}),
				},
				duration = 3.0,
				castTime = 3.0,
			}),
			[445052] = Private.classes.BossAbility:new({ -- Chittering Swarm
				phases = {
					[2] = Private.classes.BossAbilityPhase:new({
						castTimes = { 6 },
						repeatInterval = nil,
					}),
				},
				duration = 0.0,
				castTime = 3.0,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:new({
				duration = 90,
				defaultDuration = 90,
				count = 3,
				defaultCount = 3,
				repeatAfter = 2,
			}),
			[2] = Private.classes.BossPhase:new({
				duration = 80,
				defaultDuration = 80,
				count = 3,
				defaultCount = 3,
				repeatAfter = 1,
			}),
		},
	}),
	["Broodtwister Ovi'nax"] = Private.classes.Boss:new({
		abilities = {
			[441362] = Private.classes.BossAbility:new({ -- Volatile Concoction
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 2.0 },
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:new({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 20.0 },
						},
					}),
				},
				duration = 0.0,
				castTime = 1.5,
			}),
			[446349] = Private.classes.BossAbility:new({ -- Sticky Web
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 15.0 },
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:new({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 30.0, 30.0, 30.0, 30.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 30.0 },
						},
					}),
				},
				duration = 6.0,
				castTime = 2.0,
			}),
			[442432] = Private.classes.BossAbility:new({ -- Ingest Black Blood
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 19.0, 171.0, 172.0 },
						repeatInterval = nil,
					}),
				},
				duration = 15.0,
				castTime = 1.0,
			}),
			[442526] = Private.classes.BossAbility:new({ -- Experimental Dosage
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = nil,
						repeatInterval = nil,
					}),
				},
				eventTriggers = {
					[442432] = Private.classes.EventTrigger:new({ -- Ingest Black Blood
						combatLogEventType = "SCS",
						castTimes = { 16.0, 50.0, 50.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 50.0 },
						},
					}),
				},
				duration = 8.0,
				castTime = 1.5,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:new({
				duration = 600,
				defaultDuration = 600,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
		},
	}),
	["Nexus-Princess Ky'veza"] = Private.classes.Boss:new({
		abilities = {
			[436867] = Private.classes.BossAbility:new({ -- Assassination
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 15.0, 130.0, 130.0, 130.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 0.0,
				duration = 8.0,
			}),
			[440377] = Private.classes.BossAbility:new({ -- Void Shredders
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 10.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 0.0,
				duration = 5.0,
			}),
			[437620] = Private.classes.BossAbility:new({ -- Nether Rift
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 22.0, 30.0, 30.0, 70.0, 30.0, 30.0, 70.0, 30.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 4.0,
				duration = 6.0,
			}),
			[438245] = Private.classes.BossAbility:new({ -- Twilight Massacre
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 34.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 0.0,
			}),
			[439576] = Private.classes.BossAbility:new({ -- Nexus Daggers
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 45.0, 30.0, 100.0, 30.0, 100.0, 30.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 1.5,
				duration = 5.0,
			}),
			[435405] = Private.classes.BossAbility:new({ -- Starless Night
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 96.1, 130.0 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 24.0,
			}),
			[442277] = Private.classes.BossAbility:new({ -- Eternal Night
				phases = {
					[1] = Private.classes.BossAbilityPhase:new({
						castTimes = { 356.1 },
						repeatInterval = nil,
					}),
				},
				castTime = 5.0,
				duration = 24.0,
			}),
		},
		phases = {
			[1] = Private.classes.BossPhase:new({
				duration = 385,
				defaultDuration = 385,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil,
			}),
		},
	}),
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

---@param bossName string
---@return BossDefinition|nil
function Private:GetBossDefinition(bossName)
	for _, bossDefinition in pairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
		if bossDefinition.name == bossName then
			return bossDefinition
		end
	end
	return nil
end

---@param bossName string
---@return Boss|nil
function Private:GetBoss(bossName)
	local boss = bosses[bossName]
	if boss then
		return boss
	end
	return nil
end

---@param spellID number
---@return BossAbility|nil
function Private:FindBossAbility(spellID)
	for _, boss in pairs(bosses) do
		if boss.abilities[spellID] then
			return boss.abilities[spellID]
		end
	end
	return nil
end
