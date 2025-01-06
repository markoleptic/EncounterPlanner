---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local BossUtilities = Private.bossUtilities

local hugeNumber = math.huge
local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

---@param bossName string
---@return Boss|nil
function BossUtilities.GetBoss(bossName)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.name == bossName then
				return boss
			end
		end
	end
	return nil
end

---@param dungeonEncounterID integer
---@return string|nil
function BossUtilities.GetBossNameFromDungeonEncounterID(dungeonEncounterID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.dungeonEncounterID == dungeonEncounterID then
				return boss.name
			end
		end
	end
	return nil
end

---@param dungeonEncounterID integer
---@return Boss|nil
function BossUtilities.GetBossFromDungeonEncounterID(dungeonEncounterID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.dungeonEncounterID == dungeonEncounterID then
				return boss
			end
		end
	end
	return nil
end

---@param bossName string
---@return integer|nil
function BossUtilities.GetBossDungeonEncounterID(bossName)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.name == bossName then
				return boss.dungeonEncounterID
			end
		end
	end
	return nil
end

---@param bossName string
---@return integer|nil
function BossUtilities.GetBossInstanceID(bossName)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.name == bossName then
				return boss.instanceID
			end
		end
	end
	return nil
end

---@param spellID integer
---@return string|nil
function BossUtilities.GetBossNameFromSpellID(spellID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.abilities[spellID] then
				return boss.name
			end
		end
	end
	return nil
end

---@param spellID integer
---@return Boss|nil
function BossUtilities.GetBossFromSpellID(spellID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.abilities[spellID] then
				return boss
			end
		end
	end
	return nil
end

---@param spellID number
---@return BossAbility|nil
function BossUtilities.FindBossAbility(spellID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.abilities[spellID] then
				return boss.abilities[spellID]
			end
		end
	end
	return nil
end

-- Accumulates cast times for a boss ability until it reaches spellCount occurrences.
---@param ability BossAbility The boss ability to get cast times for
---@param spellCount integer The spell count/occurrence
---@return number, number -- Time from the start of the phase, the phase in which the occurrence is located in
function BossUtilities.GetRelativeBossAbilityStartTime(ability, spellCount)
	local startTime = 0
	local phaseNumberOffset = 1
	if ability then
		local currentSpellCount = 1
		for phaseNumber, phase in pairs(ability.phases) do
			startTime = 0
			for _, castTime in ipairs(phase.castTimes) do
				startTime = startTime + castTime
				if currentSpellCount == spellCount then
					phaseNumberOffset = phaseNumber
					break
				end
				currentSpellCount = currentSpellCount + 1
			end
			if currentSpellCount == spellCount then
				phaseNumberOffset = phaseNumber
				break
			end
		end
	end
	return startTime, phaseNumberOffset
end

-- Returns the phase start time from boss pull to the specified phase number and occurrence.
---@param bossName string The boss
---@param bossPhaseTable table<integer, integer> A table of boss phases in the order in which they occur
---@param phaseNumber integer The boss phase number
---@param phaseCount integer? The current phase repeat instance (i.e. 2nd time occurring = 2)
---@return number -- Cumulative start time for a given boss phase and count/occurrence
function BossUtilities.GetCumulativePhaseStartTime(bossName, bossPhaseTable, phaseNumber, phaseCount)
	if not phaseCount then
		phaseCount = 1
	end
	local cumulativePhaseStartTime = 0
	local phaseNumberOccurrences = 0
	for _, currentPhaseNumber in ipairs(bossPhaseTable) do
		if currentPhaseNumber == phaseNumber then
			phaseNumberOccurrences = phaseNumberOccurrences + 1
		end
		if phaseNumberOccurrences == phaseCount then
			break
		end
		cumulativePhaseStartTime = cumulativePhaseStartTime
			+ BossUtilities.GetBoss(bossName).phases[currentPhaseNumber].duration
	end
	return cumulativePhaseStartTime
end

-- Creates a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
---@param bossName string The boss
---@return table<integer, integer> -- Ordered boss phase table
function BossUtilities.CreateBossPhaseTable(bossName)
	local boss = BossUtilities.GetBoss(bossName)
	local bossPhaseOrder = {}
	if boss then
		local totalPhaseOccurrences = 0
		local totalTimelineDuration = 0
		for _, phase in pairs(boss.phases) do
			totalTimelineDuration = totalTimelineDuration + (phase.duration * phase.count)
			totalPhaseOccurrences = totalPhaseOccurrences + phase.count
		end
		local currentPhase = 1
		while #bossPhaseOrder < totalPhaseOccurrences and currentPhase ~= nil do
			tinsert(bossPhaseOrder, currentPhase)
			if boss.phases[currentPhase].repeatAfter == nil and boss.phases[currentPhase + 1] then
				currentPhase = currentPhase + 1
			else
				currentPhase = boss.phases[currentPhase].repeatAfter
			end
		end
	end
	return bossPhaseOrder
end

-- Creates a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param bossName string The boss
---@return table<integer, table<integer, number>> -- spellID, spell occurrence, time
function BossUtilities.CreateAbsoluteSpellCastTimeTable(bossName)
	local boss = BossUtilities.GetBoss(bossName)
	local spellCount = {}
	if boss then
		local cumulativePhaseStartTime = 0
		for _, bossPhaseIndex in ipairs(BossUtilities.CreateBossPhaseTable(bossName)) do
			local bossPhase = boss.phases[bossPhaseIndex]
			if bossPhase then
				local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration
				for bossAbilitySpellID, _ in pairs(boss.abilities) do
					if not spellCount[bossAbilitySpellID] then
						spellCount[bossAbilitySpellID] = {}
					end
					local bossAbility = boss.abilities[bossAbilitySpellID]
					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
					if bossAbilityPhase then
						local cumulativePhaseCastTime = cumulativePhaseStartTime
						for _, castTime in ipairs(bossAbilityPhase.castTimes) do
							local castStart = cumulativePhaseCastTime + castTime
							tinsert(spellCount[bossAbilitySpellID], castStart)
							if bossAbilityPhase.repeatInterval then
								local repeatInterval = bossAbilityPhase.repeatInterval
								local nextRepeatStart = castStart + repeatInterval
								while nextRepeatStart < phaseEndTime do
									tinsert(spellCount[bossAbilitySpellID], nextRepeatStart)
									nextRepeatStart = nextRepeatStart + repeatInterval
								end
							end
							cumulativePhaseCastTime = cumulativePhaseCastTime + castTime
						end
					end

					if bossAbility.eventTriggers then
						for triggerSpellID, eventTrigger in pairs(bossAbility.eventTriggers) do
							local bossAbilityTrigger = boss.abilities[triggerSpellID]
							if bossAbilityTrigger and bossAbilityTrigger.phases[bossPhaseIndex] then
								local cumulativeTriggerTime = cumulativePhaseStartTime
								for triggerCastIndex, triggerCastTime in
									ipairs(bossAbilityTrigger.phases[bossPhaseIndex].castTimes)
								do
									local cumulativeCastTime = cumulativeTriggerTime
										+ triggerCastTime
										+ bossAbilityTrigger.castTime
									for _, castTime in ipairs(eventTrigger.castTimes) do
										local castStart = cumulativeCastTime + castTime
										tinsert(spellCount[bossAbilitySpellID], castStart)
										cumulativeCastTime = cumulativeCastTime + castTime
									end
									if
										eventTrigger.repeatInterval
										and eventTrigger.repeatInterval.triggerCastIndex == triggerCastIndex
									then
										while cumulativeCastTime < phaseEndTime do
											for _, castTime in ipairs(eventTrigger.repeatInterval.castTimes) do
												local castStart = cumulativeCastTime + castTime
												local castEnd = castStart + bossAbility.castTime
												local effectEnd = castEnd + bossAbility.duration
												if effectEnd < phaseEndTime then
													tinsert(spellCount[bossAbilitySpellID], castStart)
												end
												cumulativeCastTime = cumulativeCastTime + castTime
											end
										end
									end
									cumulativeTriggerTime = cumulativeTriggerTime
										+ triggerCastTime
										+ bossAbilityTrigger.castTime
								end
							end
						end
					end
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end
	end
	return spellCount
end

do -- Generate a list of abilities for each boss sorted by their first cast time
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			local earliestCastTimes = {}
			local spellCount = BossUtilities.CreateAbsoluteSpellCastTimeTable(boss.name)
			for spellID, spellOccurrenceNumbers in pairs(spellCount) do
				local earliestCastTime = hugeNumber
				for _, castTime in pairs(spellOccurrenceNumbers) do
					earliestCastTime = min(earliestCastTime, castTime)
				end
				tinsert(earliestCastTimes, { spellID = spellID, earliestCastTime = earliestCastTime })
			end
			sort(earliestCastTimes, function(a, b)
				return a.earliestCastTime < b.earliestCastTime
			end)
			boss.sortedAbilityIDs = {}
			for _, entry in ipairs(earliestCastTimes) do
				tinsert(boss.sortedAbilityIDs, entry.spellID)
			end
		end
	end
end
