local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local BossUtilities = Private.bossUtilities

local Clamp = Clamp
local EJ_GetCreatureInfo = EJ_GetCreatureInfo
local EJ_SelectEncounter = EJ_SelectEncounter
local EJ_SelectInstance = EJ_SelectInstance
local hugeNumber = math.huge
local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

-- Boss dungeon encounter ID -> boss ability spell ID -> {castStart, boss phase order index}
---@type table<integer, table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>>
local absoluteSpellCastStartTables = {}

---@type table<integer, table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>>
local maxAbsoluteSpellCastStartTables = {}

-- Boss dungeon encounter ID -> [boss phase order index, boss phase index]
---@type table<integer, table<integer, integer>>
local orderedBossPhases = {}

---@type table<integer, table<integer, integer>>
local maxOrderedBossPhases = {}

---@param value number
---@param precision integer
---@return number
function Utilities.Round(value, precision)
	local factor = 10 ^ precision
	if value > 0 then
		return floor(value * factor + 0.5) / factor
	else
		return ceil(value * factor - 0.5) / factor
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@return string|nil
function BossUtilities.GetBossName(encounterID)
	for _, dungeonInstance in pairs(Private.dungeonInstances) do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				if boss.name:len() == 0 then
					EJ_SelectInstance(dungeonInstance.journalInstanceID)
					EJ_SelectEncounter(boss.journalEncounterID)
					local _, bossName, _, _, _, _ = EJ_GetCreatureInfo(1, boss.journalEncounterID)
					boss.name = bossName
				end
				return boss.name
			end
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@return Boss|nil
function BossUtilities.GetBoss(encounterID)
	for _, dungeonInstance in pairs(Private.dungeonInstances) do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				return boss
			end
		end
	end
	return nil
end

---@param spellID integer
---@return integer|nil
function BossUtilities.GetBossDungeonEncounterIDFromSpellID(spellID)
	for _, dungeonInstance in pairs(Private.dungeonInstances) do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.abilities[spellID] then
				return boss.dungeonEncounterID
			end
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID number
---@return BossAbility|nil
function BossUtilities.FindBossAbility(encounterID, spellID)
	for _, dungeonInstance in pairs(Private.dungeonInstances) do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				if boss.abilities[spellID] then
					return boss.abilities[spellID]
				end
				break
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
---@param encounterID integer Boss dungeon encounter ID
---@param bossPhaseTable table<integer, integer> A table of boss phases in the order in which they occur
---@param phaseNumber integer The boss phase number
---@param phaseCount integer? The current phase repeat instance (i.e. 2nd time occurring = 2)
---@return number -- Cumulative start time for a given boss phase and count/occurrence
function BossUtilities.GetCumulativePhaseStartTime(encounterID, bossPhaseTable, phaseNumber, phaseCount)
	if not phaseCount then
		phaseCount = 1
	end
	local cumulativePhaseStartTime = 0
	local phaseNumberOccurrences = 0
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		for _, currentPhaseNumber in ipairs(bossPhaseTable) do
			if currentPhaseNumber == phaseNumber then
				phaseNumberOccurrences = phaseNumberOccurrences + 1
			end
			if phaseNumberOccurrences == phaseCount then
				break
			end
			cumulativePhaseStartTime = cumulativePhaseStartTime + boss.phases[currentPhaseNumber].duration
		end
	end
	return cumulativePhaseStartTime
end

-- Returns a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
---@param encounterID integer Boss dungeon encounter ID
---@return table<integer, integer>|nil -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetOrderedBossPhases(encounterID)
	return orderedBossPhases[encounterID]
end

-- Returns a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param encounterID integer Boss dungeon encounter ID
---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>|nil
function BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
	return absoluteSpellCastStartTables[encounterID]
end

-- Returns a table that can be used to find the cast time of given the spellID and spell occurrence number. The table
-- is created using the maximum allowed phase counts rather than the current phase counts.
---@param encounterID integer Boss dungeon encounter ID
---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>|nil
function BossUtilities.GetMaxAbsoluteSpellCastTimeTable(encounterID)
	return maxAbsoluteSpellCastStartTables[encounterID]
end

---@param encounterID integer Boss dungeon encounter ID
---@return table<integer, BossAbilityInstance>|nil
function BossUtilities.GetBossAbilityInstances(encounterID)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		return boss.abilityInstances
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
function BossUtilities.ResetBossPhaseTimings(encounterID)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		for _, phase in ipairs(boss.phases) do
			phase.duration = phase.defaultDuration
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
function BossUtilities.ResetBossPhaseCounts(encounterID)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		for _, phase in ipairs(boss.phases) do
			phase.count = phase.defaultCount
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param count integer
---@return boolean
function BossUtilities.IsValidSpellCount(encounterID, spellID, count)
	local spellCount = absoluteSpellCastStartTables[encounterID]
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			return spellCountBySpellID[count] ~= nil
		end
	end
	return false
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@return integer|nil
function BossUtilities.GetMaxSpellCount(encounterID, spellID)
	local spellCount = absoluteSpellCastStartTables[encounterID]
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			return #spellCountBySpellID
		end
	end
	return nil
end

local function CheckFixedCountsSatisfied(phases, counts)
	for phaseIndex, phase in ipairs(phases) do
		if not counts[phaseIndex] or counts[phaseIndex] < phase.defaultCount then
			return false
		end
	end
	return true
end

---@param encounterID integer Boss dungeon encounter ID
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.CalculateMaxPhaseCounts(encounterID, maxTotalDuration)
	local counts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = boss.phases
		local currentPhaseIndex, currentTotalDuration = 1, 0.0
		while phases[currentPhaseIndex] do
			local phase = phases[currentPhaseIndex]
			currentTotalDuration = currentTotalDuration + phase.duration
			if currentTotalDuration > maxTotalDuration then
				break
			end
			counts[currentPhaseIndex] = (counts[currentPhaseIndex] or 0) + 1
			if phase.repeatAfter == nil then
				currentPhaseIndex = currentPhaseIndex + 1
			else
				if phase.fixedCount and CheckFixedCountsSatisfied(phases, counts) then
					break
				else
					currentPhaseIndex = phase.repeatAfter
				end
			end
		end
	end
	return counts
end

---@param encounterID integer Boss dungeon encounter ID
---@param changedPhase integer|nil
---@param newCount integer|nil
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.ValidatePhaseCounts(encounterID, changedPhase, newCount, maxTotalDuration)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = boss.phases
		if changedPhase and newCount then
			local phaseBeforeChangedPhaseCount = newCount
			local phaseAfterChangedPhaseCount = newCount

			-- Determine count of phases before changed phase, can be one greater or equal
			if phases[changedPhase - 1] then
				local count = phases[changedPhase - 1].count
				phaseBeforeChangedPhaseCount = Clamp(count, newCount, newCount + 1)
			end
			-- Determine count of phases after changed phase, can be equal or one less
			if phases[changedPhase + 1] then
				local count = phases[changedPhase + 1].count
				phaseAfterChangedPhaseCount = Clamp(count, newCount - 1, newCount)
			end

			-- Populate validatedCounts
			for phaseIndex = changedPhase - 1, 1, -1 do
				validatedCounts[phaseIndex] = phaseBeforeChangedPhaseCount
			end
			validatedCounts[changedPhase] = newCount
			for phaseIndex = changedPhase + 1, #phases do
				validatedCounts[phaseIndex] = phaseAfterChangedPhaseCount
			end
		else
			for index, phase in ipairs(phases) do
				validatedCounts[index] = phase.count
			end
		end

		-- Clamp phases to their min/maxes
		local maxCounts = BossUtilities.CalculateMaxPhaseCounts(encounterID, maxTotalDuration)
		if validatedCounts[1] then
			validatedCounts[1] = Clamp(validatedCounts[1], 1, maxCounts[1])
			local lastPhaseIndex, lastPhaseIndexCount = 1, validatedCounts[1]
			for phaseIndex = 2, #validatedCounts do
				local phaseCount = validatedCounts[phaseIndex]
				local minCount, maxCount
				if phases[lastPhaseIndex].repeatAfter == lastPhaseIndex then
					minCount = max(0, lastPhaseIndexCount - 1)
					maxCount = min(lastPhaseIndexCount, maxCounts[phaseIndex])
				else
					minCount = 0
					maxCount = maxCounts[phaseIndex]
				end

				validatedCounts[phaseIndex] = Clamp(phaseCount, minCount, maxCount)
				lastPhaseIndexCount = validatedCounts[phaseIndex]
			end
		end
	end
	return validatedCounts
end

---@param encounterID integer Boss dungeon encounter ID
---@param changedPhase integer
---@param newCount integer
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.SetPhaseCount(encounterID, changedPhase, newCount, maxTotalDuration)
	local validatedCounts = BossUtilities.ValidatePhaseCounts(encounterID, changedPhase, newCount, maxTotalDuration)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = boss.phases
		for phaseIndex, phaseCount in ipairs(validatedCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
	end
	return validatedCounts
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseCounts  table<integer, integer>
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.SetPhaseCounts(encounterID, phaseCounts, maxTotalDuration)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = boss.phases
		for phaseIndex, phaseCount in pairs(phaseCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
		validatedCounts = BossUtilities.ValidatePhaseCounts(encounterID, nil, nil, maxTotalDuration)
		for phaseIndex, phaseCount in ipairs(validatedCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
	end
	return validatedCounts
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseIndex integer
---@param maxTotalDuration number
---@return number|nil
function BossUtilities.CalculateMaxPhaseDuration(encounterID, phaseIndex, maxTotalDuration)
	local boss = BossUtilities.GetBoss(encounterID)
	local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(encounterID)
	if boss and orderedBossPhaseTable then
		local totalDurationWithoutPhaseDuration = 0.0
		local phases = boss.phases
		for _, index in ipairs(orderedBossPhaseTable) do
			if index ~= phaseIndex then
				totalDurationWithoutPhaseDuration = totalDurationWithoutPhaseDuration + phases[index].duration
			end
		end
		local phaseCount = boss.phases[phaseIndex].count
		return (maxTotalDuration - totalDurationWithoutPhaseDuration) / phaseCount
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@return number totalCustomDuration
---@return number totalDefaultDuration
function BossUtilities.GetTotalDurations(encounterID)
	local totalCustomDuration, totalDefaultDuration = 0.0, 0.0
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		for _, phase in pairs(boss.phases) do
			totalCustomDuration = totalCustomDuration + (phase.duration * phase.count)
			totalDefaultDuration = totalDefaultDuration + (phase.defaultDuration * phase.defaultCount)
		end
	end
	return totalCustomDuration, totalDefaultDuration
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseIndex integer
---@param phaseDuration number
function BossUtilities.SetPhaseDuration(encounterID, phaseIndex, phaseDuration)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		if boss.phases[phaseIndex] then
			boss.phases[phaseIndex].duration = phaseDuration
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseDurations table<integer, number>
function BossUtilities.SetPhaseDurations(encounterID, phaseDurations)
	for phaseIndex, phaseDuration in pairs(phaseDurations) do
		BossUtilities.SetPhaseDuration(encounterID, phaseIndex, phaseDuration)
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param plan Plan
function BossUtilities.ChangePlanBoss(encounterID, plan)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		plan.dungeonEncounterID = boss.dungeonEncounterID
		plan.instanceID = boss.instanceID
		wipe(plan.customPhaseDurations)
		wipe(plan.customPhaseCounts)
	end
end

---@param time number Time relative to the combat log event
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
	time,
	encounterID,
	spellID,
	spellCount,
	combatLogEventType
)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local adjustedTime = absoluteSpellCastStartTable[spellID][spellCount].castStart + time
			local ability = BossUtilities.FindBossAbility(encounterID, spellID)
			if ability then
				if combatLogEventType == "SAR" then
					adjustedTime = adjustedTime + ability.duration + ability.castTime
				elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
					adjustedTime = adjustedTime + ability.castTime
				end
			end
			return adjustedTime
		end
	end
	return nil
end

---@param time number The time from the beginning of the boss encounter
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer Combat log event spell count
---@param eventType CombatLogEventType
---@return number|nil
function BossUtilities.ConvertAbsoluteTimeToCombatLogEventTime(time, encounterID, spellID, spellCount, eventType)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local adjustedTime = time - absoluteSpellCastStartTable[spellID][spellCount].castStart
			local ability = BossUtilities.FindBossAbility(encounterID, spellID)
			if ability then
				if eventType == "SAR" then
					adjustedTime = adjustedTime - ability.duration - ability.castTime
				elseif eventType == "SCC" or eventType == "SAA" then
					adjustedTime = adjustedTime - ability.castTime
				end
			end
			return adjustedTime
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer Combat log event spell count
---@param eventType CombatLogEventType
---@return number|nil
function BossUtilities.GetMinimumCombatLogEventTime(encounterID, spellID, spellCount, eventType)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local time = absoluteSpellCastStartTable[spellID][spellCount].castStart
			local ability = BossUtilities.FindBossAbility(encounterID, spellID)
			if ability then
				if eventType == "SAR" then
					time = time + ability.duration + ability.castTime
				elseif eventType == "SCC" or eventType == "SAA" then
					time = time + ability.castTime
				end
			end
			return time
		end
	end
	return nil
end

do
	---@param time number The time from the beginning of the boss encounter
	---@param encounterID integer Boss dungeon encounter ID
	---@param castTimeTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param eventType CombatLogEventType
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	local function FindNearestCombatLogEventAllowingBefore(time, encounterID, castTimeTable, eventType)
		local minTime, minTimeBefore = hugeNumber, hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil
		local spellIDForMinTimeBefore, spellCountForMinTimeBefore = nil, nil

		for spellID, spellCountAndTime in pairs(castTimeTable) do
			local ability = BossUtilities.FindBossAbility(encounterID, spellID)
			for spellCount, indexAndCastStart in pairs(spellCountAndTime) do
				local adjustedTime = indexAndCastStart.castStart
				if ability then
					if eventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif eventType == "SCC" or eventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime <= time then
					local difference = time - adjustedTime
					if difference < minTime then
						minTime = difference
						spellIDForMinTime = spellID
						spellCountForMinTime = spellCount
					end
				else
					local difference = adjustedTime - time
					if difference < minTimeBefore then
						minTimeBefore = difference
						spellIDForMinTimeBefore = spellID
						spellCountForMinTimeBefore = spellCount
					end
				end
			end
		end
		if not spellIDForMinTime and not spellCountForMinTime then
			minTime = minTimeBefore
			spellIDForMinTime = spellIDForMinTimeBefore
			spellCountForMinTime = spellCountForMinTimeBefore
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end

	---@param time number The time from the beginning of the boss encounter
	---@param encounterID integer Boss dungeon encounter ID
	---@param castTimeTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param eventType CombatLogEventType
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	local function FindNearestCombatLogEventNoBefore(time, encounterID, castTimeTable, eventType)
		local minTime = hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil

		for spellID, spellCountAndTime in pairs(castTimeTable) do
			local ability = BossUtilities.FindBossAbility(encounterID, spellID)
			for spellCount, indexAndCastStart in pairs(spellCountAndTime) do
				local adjustedTime = indexAndCastStart.castStart
				if ability then
					if eventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif eventType == "SCC" or eventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime <= time then
					local difference = time - adjustedTime
					if difference < minTime then
						minTime = difference
						spellIDForMinTime = spellID
						spellCountForMinTime = spellCount
					end
				end
			end
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end

	---@param time number The time from the beginning of the boss encounter
	---@param encounterID integer Boss dungeon encounter ID
	---@param eventType CombatLogEventType
	---@param allowBefore boolean? If specified, combat log events will be chosen before the time if none can be found without doing so.
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	function BossUtilities.FindNearestCombatLogEvent(time, encounterID, eventType, allowBefore)
		local castTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
		if castTimeTable then
			if allowBefore then
				return FindNearestCombatLogEventAllowingBefore(time, encounterID, castTimeTable, eventType)
			else
				return FindNearestCombatLogEventNoBefore(time, encounterID, castTimeTable, eventType)
			end
		end
		return nil
	end
end

do
	---@param time number
	---@param ability BossAbility
	---@param castTimeTable table<integer, { castStart: number, bossPhaseOrderIndex: integer }>
	---@param currentEventType CombatLogEventType
	---@return integer|nil spellCount
	---@return number leftoverTime
	local function FindNearestSpellCountAllowingBefore(time, ability, castTimeTable, currentEventType)
		local minTime, minTimeBefore = hugeNumber, hugeNumber
		local spellCountForMinTime, spellCountForMinTimeBefore = nil, nil

		for spellCount, indexAndCastStart in pairs(castTimeTable) do
			local adjustedTime = indexAndCastStart.castStart
			if ability then
				if currentEventType == "SAR" then
					adjustedTime = adjustedTime + ability.duration + ability.castTime
				elseif currentEventType == "SCC" or currentEventType == "SAA" then
					adjustedTime = adjustedTime + ability.castTime
				end
			end
			if adjustedTime <= time then
				local difference = time - adjustedTime
				if difference < minTime then
					minTime = difference
					spellCountForMinTime = spellCount
				end
			else
				local difference = adjustedTime - time
				if difference < minTimeBefore then
					minTimeBefore = difference
					spellCountForMinTimeBefore = spellCount
				end
			end
		end
		if not spellCountForMinTime then
			minTime = minTimeBefore
			spellCountForMinTime = spellCountForMinTimeBefore
		end
		return spellCountForMinTime, minTime
	end

	---@param time number
	---@param ability BossAbility
	---@param castTimeTable table<integer, { castStart: number, bossPhaseOrderIndex: integer }>
	---@param currentEventType CombatLogEventType
	---@return integer|nil spellCount
	---@return number leftoverTime
	local function FindNearestSpellCountNoBefore(time, ability, castTimeTable, currentEventType)
		local minTime = hugeNumber
		local spellCountForMinTime = nil

		for spellCount, indexAndCastStart in pairs(castTimeTable) do
			local adjustedTime = indexAndCastStart.castStart
			if ability then
				if currentEventType == "SAR" then
					adjustedTime = adjustedTime + ability.duration + ability.castTime
				elseif currentEventType == "SCC" or currentEventType == "SAA" then
					adjustedTime = adjustedTime + ability.castTime
				end
			end
			if adjustedTime <= time then
				local difference = time - adjustedTime
				if difference < minTime then
					minTime = difference
					spellCountForMinTime = spellCount
				end
			end
		end
		return spellCountForMinTime, minTime
	end

	---@param relativeTime number Time relative to the combat log event.
	---@param encounterID integer Boss dungeon encounter ID
	---@param currentEventType CombatLogEventType Current combat log event type
	---@param currentSpellID integer Current combat log event spell ID
	---@param currentSpellCount integer Current combat log event spell count
	---@param newSpellID integer New combat log event spell ID
	---@param allowBefore boolean? If specified, spell will be chosen before the time if none can be found without doing so.
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	function BossUtilities.FindNearestSpellCount(
		relativeTime,
		encounterID,
		currentEventType,
		currentSpellID,
		currentSpellCount,
		newSpellID,
		allowBefore
	)
		local absoluteTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
			relativeTime,
			encounterID,
			currentSpellID,
			currentSpellCount,
			currentEventType
		)
		if not absoluteTime then
			return nil
		end
		local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID)
		if absoluteSpellCastStartTable and absoluteSpellCastStartTable[newSpellID] then
			local spellCountAndTime = absoluteSpellCastStartTable[newSpellID]
			local ability = BossUtilities.FindBossAbility(encounterID, newSpellID)
			if not ability then
				return nil
			end
			if allowBefore then
				return FindNearestSpellCountAllowingBefore(absoluteTime, ability, spellCountAndTime, currentEventType)
			else
				return FindNearestSpellCountNoBefore(absoluteTime, ability, spellCountAndTime, currentEventType)
			end
		end
		return nil
	end
end

do
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class TimedAssignment
	local TimedAssignment = Private.classes.TimedAssignment

	---@alias AssignmentConversionMethod
	---| 1 # Convert combat log event assignments to timed assignments
	---| 2 # Replace combat log event spells with those of the new boss, matching the closest timing

	---@param assignments table<integer, Assignment|CombatLogEventAssignment>
	---@param oldEncounterID integer Old boss dungeon encounter ID
	local function ConvertCombatLogEventAssignmentsToTimedAssignments(assignments, oldEncounterID)
		for _, assignment in ipairs(assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				local convertedTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType
				)
				if convertedTime then
					assignment = TimedAssignment:New(assignment, true)
					assignment.time = Utilities.Round(convertedTime, 1)
				end
			end
		end
	end

	---@param assignments table<integer, Assignment|CombatLogEventAssignment>
	---@param oldID integer Old boss dungeon encounter ID
	---@param newID integer New boss dungeon encounter ID
	---@param castTimeTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param bossPhaseTable table<integer, integer>
	local function ReplaceCombatLogEventAssignmentSpells(assignments, oldID, newID, castTimeTable, bossPhaseTable)
		for _, assignment in ipairs(assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				local spellID, spellCount, eventType =
					assignment.combatLogEventSpellID, assignment.spellCount, assignment.combatLogEventType
				local absoluteTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldID,
					spellID,
					spellCount,
					eventType
				)
				if absoluteTime then
					local newSpellID, newSpellCount, newTime =
						BossUtilities.FindNearestCombatLogEvent(absoluteTime, newID, eventType, true)
					if newSpellID and newSpellCount and newTime then
						if castTimeTable[newSpellID] and castTimeTable[newSpellID][newSpellCount] then
							local orderedBossPhaseIndex = castTimeTable[newSpellID][newSpellCount].bossPhaseOrderIndex
							assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
							assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
						end
						assignment.time = Utilities.Round(newTime, 1)
						assignment.combatLogEventSpellID = newSpellID
						assignment.spellCount = newSpellCount
					end
				end
			end
		end
	end

	---@param assignments table<integer, Assignment|CombatLogEventAssignment>
	---@param oldBoss Boss
	---@param newBoss Boss
	---@param conversionMethod AssignmentConversionMethod
	function BossUtilities.ConvertAssignmentsToNewBoss(assignments, oldBoss, newBoss, conversionMethod)
		local oldID, newID = oldBoss.dungeonEncounterID, newBoss.dungeonEncounterID
		if conversionMethod == 1 then
			ConvertCombatLogEventAssignmentsToTimedAssignments(assignments, oldID)
		elseif conversionMethod == 2 then
			local castTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(newID)
			local bossPhaseTable = BossUtilities.GetOrderedBossPhases(newID)
			if castTimeTable and bossPhaseTable then
				ReplaceCombatLogEventAssignmentSpells(assignments, oldID, newID, castTimeTable, bossPhaseTable)
			end
		end
	end
end

---@param time number Time from the start of the boss encounter
---@return TimedAssignment|CombatLogEventAssignment|nil
function BossUtilities.DetermineAssignmentTypeToCreate(encounterID, time)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local cumulativeTime = 0.0
		if #boss.phases == 1 then
			return Private.classes.TimedAssignment:New()
		end
		local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(encounterID)
		if orderedBossPhaseTable then
			for orderedPhaseIndex, phaseIndex in ipairs(orderedBossPhaseTable) do
				local phase = boss.phases[phaseIndex]
				if cumulativeTime + phase.duration > time then
					if orderedPhaseIndex == 1 and phaseIndex == 1 then
						return Private.classes.TimedAssignment:New()
					else
						return Private.classes.CombatLogEventAssignment:New()
					end
				end
				cumulativeTime = cumulativeTime + phase.duration
			end
		end
	end
	return nil
end

--@debug@
do
	-- Creates a table of boss phases in the order in which they occur, using the maximum amount of phases until
	-- reaching maxTotalDuration.
	---@param encounterID integer Boss dungeon encounter ID
	---@param maxTotalDuration number
	---@return table<integer, integer> -- Ordered boss phase table
	local function GenerateMaxOrderedBossPhaseTable(encounterID, maxTotalDuration)
		local boss = BossUtilities.GetBoss(encounterID)
		local orderedBossPhaseTable = {}
		local counts = {}
		if boss then
			local phases = boss.phases
			local currentPhaseIndex, currentTotalDuration = 1, 0.0
			while phases[currentPhaseIndex] do
				local phase = phases[currentPhaseIndex]
				currentTotalDuration = currentTotalDuration + phase.defaultDuration
				if currentTotalDuration > maxTotalDuration then
					break
				end
				counts[currentPhaseIndex] = (counts[currentPhaseIndex] or 0) + 1
				tinsert(orderedBossPhaseTable, currentPhaseIndex)
				if phase.repeatAfter == nil then
					currentPhaseIndex = currentPhaseIndex + 1
				else
					if phase.fixedCount and CheckFixedCountsSatisfied(phases, counts) then
						break
					else
						currentPhaseIndex = phase.repeatAfter
					end
				end
			end
		end
		return orderedBossPhaseTable
	end

	-- Creates a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
	---@param encounterID integer Boss dungeon encounter ID
	---@return table<integer, integer> -- Ordered boss phase table
	local function GenerateOrderedBossPhaseTable(encounterID)
		local boss = BossUtilities.GetBoss(encounterID)
		local orderedBossPhaseTable = {}
		local counts = {}
		if boss then
			local phases = boss.phases
			local totalPhaseOccurrences = 0
			for _, phase in pairs(phases) do
				totalPhaseOccurrences = totalPhaseOccurrences + phase.count
			end
			local currentPhaseIndex = 1
			while #orderedBossPhaseTable < totalPhaseOccurrences and phases[currentPhaseIndex] do
				local phase = phases[currentPhaseIndex]
				counts[currentPhaseIndex] = (counts[currentPhaseIndex] or 0) + 1
				tinsert(orderedBossPhaseTable, currentPhaseIndex)
				if phase.repeatAfter == nil then
					currentPhaseIndex = currentPhaseIndex + 1
				else
					if phase.fixedCount and CheckFixedCountsSatisfied(phases, counts) then
						break
					else
						currentPhaseIndex = phase.repeatAfter
					end
				end
			end
		end
		return orderedBossPhaseTable
	end

	---@param ability BossAbility
	---@param abilityPhase BossAbilityPhase|EventTrigger
	---@param startTime number Cumulative phase start time.
	---@param endTime number Phase end time.
	---@param castCallback fun(castStart: number, castEnd: number, effectEnd: number)
	---@return number cumulativePhaseCastTime
	local function IterateAbilityCastTimes(ability, abilityPhase, startTime, endTime, castCallback)
		local cumulativePhaseCastTime = startTime
		for castIndex, castTime in ipairs(abilityPhase.castTimes) do
			local castStart = cumulativePhaseCastTime + castTime

			if castStart <= endTime then
				local castEnd = castStart + ability.castTime
				local effectEnd = castEnd + ability.duration

				if abilityPhase.signifiesPhaseStart and castIndex == 1 then
					castEnd = min(castEnd, endTime)
					if effectEnd >= endTime then
						local newDuration = endTime - castEnd
						effectEnd = castEnd + newDuration
					end
				end

				if abilityPhase.signifiesPhaseEnd and castIndex == #abilityPhase.castTimes then
					if castEnd < endTime then
						effectEnd = endTime -- Extend duration until end of phase
					else
						castEnd = endTime -- Clamp cast time to end of phase
					end
				end
				castEnd = min(castEnd, endTime)
				effectEnd = min(effectEnd, endTime)
				castCallback(castStart, castEnd, effectEnd)
				cumulativePhaseCastTime = cumulativePhaseCastTime + castTime
			end
		end
		return cumulativePhaseCastTime
	end

	---@param ability BossAbility
	---@param repeatInterval number|table<integer, number>|nil
	---@param startTime number Cumulative phase start time.
	---@param endTime number Phase end time.
	---@param castCallback fun(castStart: number, castEnd: number, effectEnd: number)
	---@return number cumulativePhaseCastTime
	local function IterateRepeatingAbility(ability, repeatInterval, startTime, endTime, castCallback)
		if not repeatInterval then
			return startTime
		end
		local cumulativePhaseCastTime = startTime
		local repeatIndex = 1
		local isTable = type(repeatInterval) == "table"
		local currentRepeatInterval
		if isTable then
			currentRepeatInterval = repeatInterval[repeatIndex]
		else
			currentRepeatInterval = repeatInterval
		end
		local nextRepeatStart = cumulativePhaseCastTime + currentRepeatInterval
		while nextRepeatStart < endTime do
			local castEnd = nextRepeatStart + ability.castTime
			local effectEnd = castEnd + ability.duration
			castEnd = min(castEnd, endTime)
			effectEnd = min(effectEnd, endTime)
			castCallback(nextRepeatStart, castEnd, effectEnd)
			if isTable then
				if repeatInterval[repeatIndex + 1] then
					repeatIndex = repeatIndex + 1
				else
					repeatIndex = 1
				end
				currentRepeatInterval = repeatInterval[repeatIndex]
			end
			nextRepeatStart = nextRepeatStart + currentRepeatInterval
			cumulativePhaseCastTime = cumulativePhaseCastTime + currentRepeatInterval
		end
		return cumulativePhaseCastTime
	end

	---@param bossPhaseIndex integer
	---@param abilities table<integer, BossAbility>
	---@param bossAbilitySpellID integer
	---@param startTime number
	---@param endTime number
	---@param castCallback fun(castStart: number, castEnd: number, effectEnd: number)
	local function IterateEventTriggers(bossPhaseIndex, abilities, bossAbilitySpellID, startTime, endTime, castCallback)
		local ability = abilities[bossAbilitySpellID]
		local eventTriggers = ability.eventTriggers
		if not eventTriggers then
			return
		end
		local bossAbilityCastTime = ability.castTime
		local bossAbilityDuration = ability.duration

		for triggerSpellID, eventTrigger in pairs(eventTriggers) do
			local bossAbilityTrigger = abilities[triggerSpellID]
			if bossAbilityTrigger and bossAbilityTrigger.phases[bossPhaseIndex] then
				local bossAbilityTriggerPhase = bossAbilityTrigger.phases[bossPhaseIndex]
				local cumulativeTriggerTime = startTime

				for triggerCastIndex, triggerCastTime in ipairs(bossAbilityTriggerPhase.castTimes) do
					local cumulativeCastTime = cumulativeTriggerTime + triggerCastTime
					if eventTrigger.combatLogEventType == "SCC" then
						cumulativeCastTime = cumulativeCastTime + bossAbilityTrigger.castTime
					elseif eventTrigger.combatLogEventType == "SAR" then
						cumulativeCastTime = cumulativeCastTime
							+ bossAbilityTrigger.castTime
							+ bossAbilityTrigger.duration
					end
					for _, castTime in ipairs(eventTrigger.castTimes) do
						local castStart = cumulativeCastTime + castTime
						local castEnd = castStart + bossAbilityCastTime
						local effectEnd = castEnd + bossAbilityDuration
						if castStart < endTime then
							castEnd = min(castEnd, endTime)
							effectEnd = min(effectEnd, endTime)
							castCallback(castStart, castEnd, effectEnd) -- TODO: Maybe do same thing IterateAbilityCastTimes does
						end
						cumulativeCastTime = cumulativeCastTime + castTime
					end
					if eventTrigger.repeatInterval then
						local spellCount = eventTrigger.combatLogEventSpellCount
						if not spellCount or spellCount == triggerCastIndex then
							cumulativeCastTime = IterateRepeatingAbility(
								ability,
								eventTrigger.repeatInterval,
								cumulativeCastTime,
								endTime,
								castCallback
							)
						end
					end
					cumulativeTriggerTime = cumulativeTriggerTime + triggerCastTime
					if eventTrigger.combatLogEventType == "SCC" then
						cumulativeTriggerTime = cumulativeTriggerTime + bossAbilityTrigger.castTime
					elseif eventTrigger.combatLogEventType == "SAR" then
						cumulativeTriggerTime = cumulativeTriggerTime
							+ bossAbilityTrigger.castTime
							+ bossAbilityTrigger.duration
					end
				end

				if bossAbilityTriggerPhase.repeatInterval then
					local startOffsetFromCumulativeTriggerTime = 0.0
					for _, castTime in ipairs(eventTrigger.castTimes) do
						startOffsetFromCumulativeTriggerTime = startOffsetFromCumulativeTriggerTime + castTime
						IterateRepeatingAbility(
							ability,
							bossAbilityTriggerPhase.repeatInterval,
							cumulativeTriggerTime + startOffsetFromCumulativeTriggerTime,
							endTime,
							castCallback
						)
					end
				end
			end
		end
	end

	-- Creates a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
	---@param boss Boss
	---@param orderedBossPhaseTable table<integer, integer>
	---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
	local function GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhaseTable)
		---@type table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
		local spellCount = {}
		local visitedPhaseCounts = {}

		local cumulativePhaseStartTime = 0
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
			local bossPhase = boss.phases[bossPhaseIndex]
			if bossPhase then
				visitedPhaseCounts[bossPhaseIndex] = (visitedPhaseCounts[bossPhaseIndex] or 0) + 1
				local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration
				for bossAbilitySpellID, bossAbility in pairs(boss.abilities) do
					spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] or {}
					local castCallback = function(castStart, _, _)
						tinsert(spellCount[bossAbilitySpellID], {
							castStart = castStart,
							bossPhaseOrderIndex = bossPhaseOrderIndex,
						})
					end

					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
					if bossAbilityPhase then
						local cumulativePhaseCastTime = cumulativePhaseStartTime
						if not bossAbilityPhase.skipFirst or visitedPhaseCounts[bossPhaseIndex] > 1 then
							cumulativePhaseCastTime = IterateAbilityCastTimes(
								bossAbility,
								bossAbilityPhase,
								cumulativePhaseStartTime,
								phaseEndTime,
								castCallback
							)
						end
						cumulativePhaseCastTime = IterateRepeatingAbility(
							bossAbility,
							bossAbilityPhase.repeatInterval,
							cumulativePhaseCastTime,
							phaseEndTime,
							castCallback
						)
					end

					IterateEventTriggers(
						bossPhaseIndex,
						boss.abilities,
						bossAbilitySpellID,
						cumulativePhaseStartTime,
						phaseEndTime,
						castCallback
					)
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end

		return spellCount
	end

	-- Creates BossAbilityInstances for all abilities of a boss.
	---@param boss Boss
	---@param orderedBossPhaseTable table<integer, integer>
	---@param spellCount table|nil
	---@return table<integer, BossAbilityInstance>
	local function GenerateBossAbilityInstances(boss, orderedBossPhaseTable, spellCount)
		spellCount = spellCount or {}
		local visitedPhaseCounts = {}
		local abilityInstances = {}
		local cumulativePhaseStartTime = 0.0
		local bossAbilityInstanceIndex = 1

		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
			local bossPhase = boss.phases[bossPhaseIndex]
			if bossPhase then
				visitedPhaseCounts[bossPhaseIndex] = (visitedPhaseCounts[bossPhaseIndex] or 0) + 1
				local bossPhaseName = bossPhase.name
				local nextBossPhaseName
				local nextBossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex + 1]
				if nextBossPhaseIndex then
					local nextBossPhase = boss.phases[nextBossPhaseIndex]
					if nextBossPhase then
						nextBossPhaseName = nextBossPhase.name
					end
				end
				local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration

				for bossAbilityOrderIndex, bossAbilitySpellID in ipairs(boss.sortedAbilityIDs) do
					spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] or {}
					local frameLevel = 1
					local bossAbility = boss.abilities[bossAbilitySpellID]
					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
					local overlaps = {}

					local currentCastIndex = 1
					local function castCallback(castStart, castEnd, effectEnd)
						tinsert(spellCount[bossAbilitySpellID], castStart)
						tinsert(abilityInstances, {
							bossAbilitySpellID = bossAbilitySpellID,
							bossAbilityInstanceIndex = bossAbilityInstanceIndex,
							bossAbilityOrderIndex = bossAbilityOrderIndex,
							bossPhaseIndex = bossPhaseIndex,
							bossPhaseOrderIndex = bossPhaseOrderIndex,
							bossPhaseDuration = bossPhase.duration,
							bossPhaseName = bossPhaseName,
							nextBossPhaseName = nextBossPhaseName,
							spellCount = #spellCount[bossAbilitySpellID],
							castStart = castStart,
							castEnd = castEnd,
							effectEnd = effectEnd,
							frameLevel = frameLevel,
							signifiesPhaseStart = bossAbilityPhase
								and bossAbilityPhase.signifiesPhaseStart
								and bossPhaseName
								and currentCastIndex == 1,
							signifiesPhaseEnd = bossAbilityPhase
								and bossAbilityPhase.signifiesPhaseEnd
								and nextBossPhaseName
								and currentCastIndex == #bossAbilityPhase.castTimes,
							overlaps = overlaps[currentCastIndex],
						} --[[@as BossAbilityInstance]])
						frameLevel = frameLevel + 1
						bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
						currentCastIndex = currentCastIndex + 1
					end
					if bossAbilityPhase then
						local consecutivePerfectOverlaps = 0
						for castIndex, castTime in ipairs(bossAbilityPhase.castTimes) do
							if cumulativePhaseStartTime + castTime < phaseEndTime then
								if castIndex > 1 and castTime == 0.0 then
									consecutivePerfectOverlaps = consecutivePerfectOverlaps + 1
									local currentOffset = consecutivePerfectOverlaps
									local heightMultiplier = 1.0 / (consecutivePerfectOverlaps + 1)
									for i = castIndex, castIndex - consecutivePerfectOverlaps, -1 do
										overlaps[i] = {
											heightMultiplier = heightMultiplier,
											offset = currentOffset * heightMultiplier,
										}
										currentOffset = currentOffset - 1
									end
								else
									consecutivePerfectOverlaps = 0
								end
							end
						end
						local cumulativePhaseCastTime = cumulativePhaseStartTime
						if not bossAbilityPhase.skipFirst or visitedPhaseCounts[bossPhaseIndex] > 1 then
							cumulativePhaseCastTime = IterateAbilityCastTimes(
								bossAbility,
								bossAbilityPhase,
								cumulativePhaseStartTime,
								phaseEndTime,
								castCallback
							)
						end
						cumulativePhaseCastTime = IterateRepeatingAbility(
							bossAbility,
							bossAbilityPhase.repeatInterval,
							cumulativePhaseCastTime,
							phaseEndTime,
							castCallback
						)
					end

					IterateEventTriggers(
						bossPhaseIndex,
						boss.abilities,
						bossAbilitySpellID,
						cumulativePhaseStartTime,
						phaseEndTime,
						castCallback
					)
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end
		return abilityInstances
	end

	-- Creates a sorted table of boss spell IDs based on the their earliest cast times.
	---@param absoluteSpellCastStartTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@return table<integer, integer>
	local function GenerateSortedBossAbilities(absoluteSpellCastStartTable)
		local earliestCastTimes = {}
		for spellID, spellOccurrenceNumbers in pairs(absoluteSpellCastStartTable) do
			local earliestCastTime = hugeNumber
			for _, castTimeTable in pairs(spellOccurrenceNumbers) do
				earliestCastTime = min(earliestCastTime, castTimeTable.castStart)
			end
			tinsert(earliestCastTimes, { spellID = spellID, earliestCastTime = earliestCastTime })
		end
		sort(earliestCastTimes, function(a, b)
			return a.earliestCastTime < b.earliestCastTime
		end)

		local sortedAbilityIDs = {}
		for _, entry in ipairs(earliestCastTimes) do
			tinsert(sortedAbilityIDs, entry.spellID)
		end
		return sortedAbilityIDs
	end

	-- Creates ordered boss phases, spell cast times, sorted abilities, and ability instances for a boss.
	---@param boss Boss
	function BossUtilities.GenerateBossTables(boss)
		local ID = boss.dungeonEncounterID
		orderedBossPhases[ID] = GenerateOrderedBossPhaseTable(ID)
		absoluteSpellCastStartTables[ID] = GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhases[ID])
		boss.sortedAbilityIDs = GenerateSortedBossAbilities(absoluteSpellCastStartTables[ID])
		boss.abilityInstances = GenerateBossAbilityInstances(boss, orderedBossPhases[ID])
	end

	local kMaxBossDuration = Private.constants.kMaxBossDuration

	for _, dungeonInstance in pairs(Private.dungeonInstances) do
		for _, boss in ipairs(dungeonInstance.bosses) do
			BossUtilities.GenerateBossTables(boss)
			maxOrderedBossPhases[boss.dungeonEncounterID] =
				GenerateMaxOrderedBossPhaseTable(boss.dungeonEncounterID, kMaxBossDuration)
			maxAbsoluteSpellCastStartTables[boss.dungeonEncounterID] =
				GenerateAbsoluteSpellCastTimeTable(boss, maxOrderedBossPhases[boss.dungeonEncounterID])
		end
	end

	do
		---@class Tests
		local tests = Private.tests
		---@class TestUtilities
		local testUtilities = Private.testUtilities

		local TestEqual = testUtilities.TestEqual

		do
			function tests.CompareSpellCastTimeTables()
				for _, dungeonInstance in pairs(Private.dungeonInstances) do
					for _, boss in ipairs(dungeonInstance.bosses) do
						local castTimeTable = {}
						local ID = boss.dungeonEncounterID
						GenerateBossAbilityInstances(boss, orderedBossPhases[ID], castTimeTable)
						TestEqual(#absoluteSpellCastStartTables[ID], #castTimeTable, "Cast Time Table Size Equal")
						for bossAbilitySpellID, spellCount in pairs(absoluteSpellCastStartTables[ID]) do
							for spellOccurrence, castStartAndOrder in ipairs(spellCount) do
								local castStart = castTimeTable[bossAbilitySpellID][spellOccurrence]
								TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal")
							end
						end
						for bossAbilitySpellID, spellCount in pairs(castTimeTable) do
							for spellOccurrence, castStart in ipairs(spellCount) do
								local castStartAndOrder =
									absoluteSpellCastStartTables[ID][bossAbilitySpellID][spellOccurrence]
								TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal")
							end
						end
					end
				end
				return "CompareSpellCastTimeTables"
			end
		end
	end
end
--@end-debug@
