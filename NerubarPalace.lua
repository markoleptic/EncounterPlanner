--@type string
local AddOnName = ...

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

---@param bossNameOrIndex string|integer
---@return BossDefinition|nil
function Private:GetBossDefinition(bossNameOrIndex)
	if type(bossNameOrIndex) == "number" then
		return Private.raidInstances["Nerub'ar Palace"].bosses[bossNameOrIndex]
	elseif type(bossNameOrIndex) == "string" then
		for _, bossDefinition in ipairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
			if bossDefinition.name == bossNameOrIndex then
				return bossDefinition
			end
		end
	end
	return nil
end

---@param bossName string
---@return integer|nil
function Private:GetBossDefinitionIndex(bossName)
	for index, bossDefinition in ipairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
		if bossDefinition.name == bossName then
			return index
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

---@param spellID integer
---@return string|nil
function Private:GetBossFromSpellID(spellID)
	for bossName, boss in pairs(bosses) do
		if boss.abilities[spellID] then
			return bossName
		end
	end
	return nil
end

---@param bossDefinitionIndex integer
---@return Boss|nil
function Private:GetBossFromBossDefinitionIndex(bossDefinitionIndex)
	local bossDef = self:GetBossDefinition(bossDefinitionIndex)
	if bossDef then
		return bosses[bossDef.name]
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

-- Creates a timeline assignment from an assignment and calculates the start time of the timeline assignment.
---@param assignment Assignment
---@return TimelineAssignment
function TimelineAssignment:New(assignment)
	assignment = assignment or Private.classes.Assignment:New(assignment)
	local timelineAssignment = {
		assignment = assignment,
		startTime = 0,
		order = 0,
	}
	setmetatable(timelineAssignment, self)
	self:Update()
	return timelineAssignment
end

-- Updates a timeline assignment's start time
function TimelineAssignment:Update()
	local assignment = self.assignment
	if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
		assignment = assignment --[[@as CombatLogEventAssignment]]
		local ability = Private:FindBossAbility(assignment.combatLogEventSpellID)
		local startTime = assignment.time
		if ability and startTime then
			if assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SCS" then
				for i = 1, min(assignment.spellCount, #ability.phases[1].castTimes) do
					startTime = startTime + ability.phases[1].castTimes[i]
				end
			end
			if assignment.combatLogEventType == "SCC" then
				startTime = startTime + ability.castTime
			end
			self.startTime = startTime
		end
	elseif getmetatable(assignment) == Private.classes.TimedAssignment then
		self.startTime = assignment--[[@as TimedAssignment]].time
	elseif getmetatable(assignment) == Private.classes.PhasedAssignment then
		assignment = assignment --[[@as PhasedAssignment]]
		local boss = Private:GetBoss("Broodtwister Ovi'nax")
		if boss then
			local totalOccurances = 0
			for _, phaseData in pairs(boss.phases) do
				totalOccurances = totalOccurances + phaseData.count
			end
			local currentPhase = 1
			local bossPhaseOrder = {}
			local runningStartTime = 0
			while #bossPhaseOrder < totalOccurances and currentPhase ~= nil do
				tinsert(bossPhaseOrder, currentPhase)
				if currentPhase == assignment.phase then
					self.startTime = runningStartTime
					return
				end
				runningStartTime = runningStartTime + boss.phases[currentPhase].duration
				currentPhase = boss.phases[currentPhase].repeatAfter
			end
		end
	end
end
