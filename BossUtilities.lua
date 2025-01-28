local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

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

-- Boss dungeon encounter ID -> [boss phase order index, boss phase index]
---@type table<integer, table<integer, integer>>
local orderedBossPhases = {}

---@param dungeonEncounterID integer
---@return string|nil
function BossUtilities.GetBossName(dungeonEncounterID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.dungeonEncounterID == dungeonEncounterID then
				if boss.name:len() == 0 then
					EJ_SelectInstance(raidInstance.journalInstanceID)
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

---@param dungeonEncounterID integer
---@return Boss|nil
function BossUtilities.GetBoss(dungeonEncounterID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.dungeonEncounterID == dungeonEncounterID then
				return boss
			end
		end
	end
	return nil
end

---@param spellID integer
---@return integer|nil
function BossUtilities.GetBossDungeonEncounterIDFromSpellID(spellID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.abilities[spellID] then
				return boss.dungeonEncounterID
			end
		end
	end
	return nil
end

---@param dungeonEncounterID integer
---@param spellID number
---@return BossAbility|nil
function BossUtilities.FindBossAbility(dungeonEncounterID, spellID)
	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			if boss.dungeonEncounterID == dungeonEncounterID then
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
---@param bossDungeonEncounterID integer
---@param bossPhaseTable table<integer, integer> A table of boss phases in the order in which they occur
---@param phaseNumber integer The boss phase number
---@param phaseCount integer? The current phase repeat instance (i.e. 2nd time occurring = 2)
---@return number -- Cumulative start time for a given boss phase and count/occurrence
function BossUtilities.GetCumulativePhaseStartTime(bossDungeonEncounterID, bossPhaseTable, phaseNumber, phaseCount)
	if not phaseCount then
		phaseCount = 1
	end
	local cumulativePhaseStartTime = 0
	local phaseNumberOccurrences = 0
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
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
---@param bossDungeonEncounterID integer
---@return table<integer, integer>|nil -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetOrderedBossPhases(bossDungeonEncounterID)
	return orderedBossPhases[bossDungeonEncounterID]
end

-- Returns a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param bossDungeonEncounterID integer
---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>|nil
function BossUtilities.GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	return absoluteSpellCastStartTables[bossDungeonEncounterID]
end

---@param bossDungeonEncounterID integer
---@return table<integer, BossAbilityInstance>|nil
function BossUtilities.GetBossAbilityInstances(bossDungeonEncounterID)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		return boss.abilityInstances
	end
	return nil
end

---@param bossDungeonEncounterID integer
function BossUtilities.ResetBossPhaseTimings(bossDungeonEncounterID)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		for _, phase in ipairs(boss.phases) do
			phase.duration = phase.defaultDuration
		end
	end
end

---@param bossDungeonEncounterID integer
function BossUtilities.ResetBossPhaseCounts(bossDungeonEncounterID)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		for _, phase in ipairs(boss.phases) do
			phase.count = phase.defaultCount
		end
	end
end

---@param bossDungeonEncounterID integer
---@param spellID integer
---@param count integer
---@return boolean
function BossUtilities.IsValidSpellCount(bossDungeonEncounterID, spellID, count)
	local spellCount = absoluteSpellCastStartTables[bossDungeonEncounterID]
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			return spellCountBySpellID[count] ~= nil
		end
	end
	return false
end

---@param bossDungeonEncounterID integer
---@param spellID integer
---@return integer|nil
function BossUtilities.GetMaxSpellCount(bossDungeonEncounterID, spellID)
	local spellCount = absoluteSpellCastStartTables[bossDungeonEncounterID]
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			return #spellCountBySpellID
		end
	end
	return nil
end

---@param bossDungeonEncounterID integer
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.CalculateMaxPhaseCounts(bossDungeonEncounterID, maxTotalDuration)
	local counts = {}
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		local phases = boss.phases
		local currentTotalDuration = 0.0
		local currentPhaseIndex = 1
		while currentPhaseIndex do
			local newTotalDuration = currentTotalDuration + phases[currentPhaseIndex].duration
			if newTotalDuration > maxTotalDuration then
				break
			end
			currentTotalDuration = newTotalDuration
			counts[currentPhaseIndex] = (counts[currentPhaseIndex] or 0) + 1
			currentPhaseIndex = phases[currentPhaseIndex].repeatAfter
		end
	end
	return counts
end

---@param bossDungeonEncounterID integer
---@param changedPhase integer|nil
---@param newCount integer|nil
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.ValidatePhaseCounts(bossDungeonEncounterID, changedPhase, newCount, maxTotalDuration)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
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
		local maxCounts = BossUtilities.CalculateMaxPhaseCounts(bossDungeonEncounterID, maxTotalDuration)
		validatedCounts[1] = Clamp(validatedCounts[1], 1, maxCounts[1])
		local lastPhaseIndexCount = validatedCounts[1]
		for phaseIndex = 2, #validatedCounts do
			local phaseCount = validatedCounts[phaseIndex]
			local minCount = max(0, lastPhaseIndexCount - 1)
			local maxCount = min(lastPhaseIndexCount, maxCounts[phaseIndex])
			validatedCounts[phaseIndex] = Clamp(phaseCount, minCount, maxCount)
			lastPhaseIndexCount = validatedCounts[phaseIndex]
		end
	end
	return validatedCounts
end

---@param bossDungeonEncounterID integer
---@param changedPhase integer
---@param newCount integer
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.SetPhaseCount(bossDungeonEncounterID, changedPhase, newCount, maxTotalDuration)
	local validatedCounts =
		BossUtilities.ValidatePhaseCounts(bossDungeonEncounterID, changedPhase, newCount, maxTotalDuration)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
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

---@param bossDungeonEncounterID integer
---@param phaseCounts  table<integer, integer>
---@param maxTotalDuration number
---@return table<integer, integer>
function BossUtilities.SetPhaseCounts(bossDungeonEncounterID, phaseCounts, maxTotalDuration)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		local phases = boss.phases
		for phaseIndex, phaseCount in pairs(phaseCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
		validatedCounts = BossUtilities.ValidatePhaseCounts(bossDungeonEncounterID, nil, nil, maxTotalDuration)
		for phaseIndex, phaseCount in ipairs(validatedCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
	end
	return validatedCounts
end

---@param bossDungeonEncounterID integer
---@param phaseIndex integer
---@param maxTotalDuration number
---@return number|nil
function BossUtilities.CalculateMaxPhaseDuration(bossDungeonEncounterID, phaseIndex, maxTotalDuration)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(bossDungeonEncounterID)
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

---@param bossDungeonEncounterID integer
---@return number totalCustomDuration
---@return number totalDefaultDuration
function BossUtilities.GetTotalDurations(bossDungeonEncounterID)
	local totalCustomDuration, totalDefaultDuration = 0.0, 0.0
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		for _, phase in pairs(boss.phases) do
			totalCustomDuration = totalCustomDuration + (phase.duration * phase.count)
			totalDefaultDuration = totalDefaultDuration + (phase.defaultDuration * phase.defaultCount)
		end
	end
	return totalCustomDuration, totalDefaultDuration
end

---@param bossDungeonEncounterID integer
---@param phaseIndex integer
---@param phaseDuration number
function BossUtilities.SetPhaseDuration(bossDungeonEncounterID, phaseIndex, phaseDuration)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		boss.phases[phaseIndex].duration = phaseDuration
	end
end

---@param bossDungeonEncounterID integer
---@param phaseDurations table<integer, number>
---@param maxTotalDuration number
function BossUtilities.SetPhaseDurations(bossDungeonEncounterID, phaseDurations, maxTotalDuration)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		local phases = boss.phases
		for phaseIndex, phaseDuration in pairs(phaseDurations) do
			if phases[phaseIndex] then
				phases[phaseIndex].duration = phaseDuration
			end
		end
	end
end

---@param bossDungeonEncounterID integer
---@param plan Plan
function BossUtilities.ChangePlanBoss(bossDungeonEncounterID, plan)
	local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		plan.dungeonEncounterID = boss.dungeonEncounterID
		plan.instanceID = boss.instanceID
		wipe(plan.customPhaseDurations)
		wipe(plan.customPhaseCounts)
	end
end

do
	-- Creates a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
	---@param bossDungeonEncounterID integer
	---@return table<integer, integer> -- Ordered boss phase table
	local function CreateOrderedBossPhaseTable(bossDungeonEncounterID)
		local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
		local orderedBossPhaseTable = {}
		if boss then
			local totalPhaseOccurrences = 0
			for _, phase in pairs(boss.phases) do
				totalPhaseOccurrences = totalPhaseOccurrences + phase.count
			end
			local currentPhase = 1
			while #orderedBossPhaseTable < totalPhaseOccurrences and currentPhase ~= nil do
				tinsert(orderedBossPhaseTable, currentPhase)
				if boss.phases[currentPhase].repeatAfter == nil and boss.phases[currentPhase + 1] then
					currentPhase = currentPhase + 1
				else
					currentPhase = boss.phases[currentPhase].repeatAfter
				end
			end
		end
		return orderedBossPhaseTable
	end

	-- Creates a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
	---@param boss Boss
	local function GenerateAbsoluteSpellCastTimeTable(boss)
		---@type table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
		local spellCount = {}

		local orderedBossPhaseTable = CreateOrderedBossPhaseTable(boss.dungeonEncounterID)
		orderedBossPhases[boss.dungeonEncounterID] = orderedBossPhaseTable

		local cumulativePhaseStartTime = 0
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
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
						for castIndex, castTime in ipairs(bossAbilityPhase.castTimes) do
							local castStart = cumulativePhaseCastTime + castTime

							if castStart <= phaseEndTime then
								local castEnd = castStart + bossAbility.castTime
								if bossAbilityPhase.signifiesPhaseEnd and castIndex == #bossAbilityPhase.castTimes then
									if not (castEnd < phaseEndTime and bossAbility.duration > 0.0) then
										if castTime == bossPhase.defaultDuration then
											castStart = phaseEndTime
										end
									end
								end

								tinsert(
									spellCount[bossAbilitySpellID],
									{ castStart = castStart, bossPhaseOrderIndex = bossPhaseOrderIndex }
								)

								if bossAbilityPhase.repeatInterval then
									local repeatInterval = bossAbilityPhase.repeatInterval
									local nextRepeatStart = castStart + repeatInterval
									while nextRepeatStart < phaseEndTime do
										tinsert(
											spellCount[bossAbilitySpellID],
											{ castStart = nextRepeatStart, bossPhaseOrderIndex = bossPhaseOrderIndex }
										)
										nextRepeatStart = nextRepeatStart + repeatInterval
									end
								end

								cumulativePhaseCastTime = cumulativePhaseCastTime + castTime
							end
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
									local cumulativeCastTime = cumulativeTriggerTime + triggerCastTime
									if eventTrigger.combatLogEventType == "SCC" then
										cumulativeCastTime = cumulativeCastTime + bossAbilityTrigger.castTime
									end
									for _, castTime in ipairs(eventTrigger.castTimes) do
										local castStart = cumulativeCastTime + castTime
										tinsert(
											spellCount[bossAbilitySpellID],
											{ castStart = castStart, bossPhaseOrderIndex = bossPhaseOrderIndex }
										)
										cumulativeCastTime = cumulativeCastTime + castTime
									end
									if
										eventTrigger.repeatCriteria
										and eventTrigger.repeatCriteria.spellCount == triggerCastIndex
									then
										while cumulativeCastTime < phaseEndTime do
											for _, castTime in ipairs(eventTrigger.repeatCriteria.castTimes) do
												local castStart = cumulativeCastTime + castTime
												local castEnd = castStart + bossAbility.castTime
												if castEnd + bossAbility.duration < phaseEndTime then
													tinsert(spellCount[bossAbilitySpellID], {
														castStart = castStart,
														bossPhaseOrderIndex = bossPhaseOrderIndex,
													})
												end
												cumulativeCastTime = cumulativeCastTime + castTime
											end
										end
									end
									cumulativeTriggerTime = cumulativeTriggerTime + triggerCastTime
									if eventTrigger.combatLogEventType == "SCC" then
										cumulativeTriggerTime = cumulativeTriggerTime + bossAbilityTrigger.castTime
									end
								end
							end
						end
					end
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end

		absoluteSpellCastStartTables[boss.dungeonEncounterID] = spellCount
	end

	-- Creates instances for all abilities of a boss.
	---@param boss Boss
	local function GenerateBossAbilityInstances(boss)
		local spellCount = {}
		local abilityInstances = {}

		local cumulativePhaseStartTime = 0
		local bossAbilityInstanceIndex = 1
		local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(boss.dungeonEncounterID)
		if not orderedBossPhaseTable then
			return
		end
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
			local bossPhase = boss.phases[bossPhaseIndex]
			if bossPhase then
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
					if not spellCount[bossAbilitySpellID] then
						spellCount[bossAbilitySpellID] = {}
					end
					local bossAbility = boss.abilities[bossAbilitySpellID]
					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
					if bossAbilityPhase then
						local cumulativePhaseCastTime = cumulativePhaseStartTime

						local frameLevel = 1
						local overlaps = {}

						local consecutivePerfectOverlaps = 0
						for castIndex, castTime in ipairs(bossAbilityPhase.castTimes) do
							if cumulativePhaseCastTime + castTime < phaseEndTime then
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

						for castIndex, castTime in ipairs(bossAbilityPhase.castTimes) do
							local castStart = cumulativePhaseCastTime + castTime
							local castEnd = castStart + bossAbility.castTime
							local effectEnd = castEnd + bossAbility.duration

							if bossAbilityPhase.signifiesPhaseStart and castIndex == 1 then
								castEnd = min(castEnd, phaseEndTime)
								if castEnd + bossAbility.duration >= phaseEndTime then
									local newDuration = phaseEndTime - castEnd
									effectEnd = castEnd + newDuration
								end
							end

							-- If phase duration is modified, update spells that depend on it
							if bossAbilityPhase.signifiesPhaseEnd and castIndex == #bossAbilityPhase.castTimes then
								if castEnd < phaseEndTime and bossAbility.duration > 0.0 then
									effectEnd = phaseEndTime
								else
									if castTime == bossPhase.defaultDuration then -- "Phase transition" spells
										castStart = phaseEndTime
									end
									castEnd = phaseEndTime
									effectEnd = castEnd
								end
							end

							if castStart <= phaseEndTime then
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
									spellOccurrence = #spellCount[bossAbilitySpellID],
									castStart = castStart,
									castEnd = castEnd,
									effectEnd = effectEnd,
									frameLevel = frameLevel,
									relativeCastTime = nil,
									combatLogEventType = nil,
									triggerSpellID = nil,
									spellCount = nil,
									repeatInstance = nil,
									repeatCastIndex = nil,
									signifiesPhaseStart = bossAbilityPhase.signifiesPhaseStart
										and bossPhaseName
										and castIndex == 1,
									signifiesPhaseEnd = bossAbilityPhase.signifiesPhaseEnd
										and nextBossPhaseName
										and castIndex == #bossAbilityPhase.castTimes,
									overlaps = overlaps[castIndex],
								} --[[@as BossAbilityInstance]])

								frameLevel = frameLevel + 1
								bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1

								if bossAbilityPhase.repeatInterval then
									local repeatInterval = bossAbilityPhase.repeatInterval
									local nextRepeatStart = castStart + repeatInterval
									local repeatInstance = 1
									while nextRepeatStart < phaseEndTime do
										local repeatEnd = nextRepeatStart + bossAbility.castTime
										local repeatEffectEnd = repeatEnd + bossAbility.duration

										tinsert(spellCount[bossAbilitySpellID], nextRepeatStart)
										tinsert(abilityInstances, {
											bossAbilitySpellID = bossAbilitySpellID,
											bossAbilityInstanceIndex = bossAbilityInstanceIndex,
											bossAbilityOrderIndex = bossAbilityOrderIndex,
											bossPhaseIndex = bossPhaseIndex,
											bossPhaseOrderIndex = bossPhaseOrderIndex,
											bossPhaseDuration = bossPhase.duration,
											bossPhaseName = bossPhaseName,
											nextBossPhaseName = nextBossPhaseName,
											spellOccurrence = #spellCount[bossAbilitySpellID],
											castStart = nextRepeatStart,
											castEnd = repeatEnd,
											effectEnd = repeatEffectEnd,
											frameLevel = frameLevel,
											relativeCastTime = nil,
											combatLogEventType = nil,
											triggerSpellID = nil,
											spellCount = nil,
											repeatInstance = repeatInstance,
											repeatCastIndex = nil,
											signifiesPhaseStart = nil,
											signifiesPhaseEnd = nil,
											overlaps = nil,
										} --[[@as BossAbilityInstance]])

										frameLevel = frameLevel + 1
										bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
										nextRepeatStart = nextRepeatStart + repeatInterval
										repeatInstance = repeatInstance + 1
									end
								end
								cumulativePhaseCastTime = cumulativePhaseCastTime + castTime
							end
						end
					end

					if bossAbility.eventTriggers then
						local frameLevel = 1
						for triggerSpellID, eventTrigger in pairs(bossAbility.eventTriggers) do
							local bossAbilityTrigger = boss.abilities[triggerSpellID]
							if bossAbilityTrigger and bossAbilityTrigger.phases[bossPhaseIndex] then
								local cumulativeTriggerTime = cumulativePhaseStartTime
								for triggerCastIndex, triggerCastTime in
									ipairs(bossAbilityTrigger.phases[bossPhaseIndex].castTimes)
								do
									local cumulativeCastTime = cumulativeTriggerTime + triggerCastTime
									if eventTrigger.combatLogEventType == "SCC" then
										cumulativeCastTime = cumulativeCastTime + bossAbilityTrigger.castTime
									end
									for _, castTime in ipairs(eventTrigger.castTimes) do
										local castStart = cumulativeCastTime + castTime
										local castEnd = castStart + bossAbility.castTime
										local effectEnd = castEnd + bossAbility.duration

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
											spellOccurrence = #spellCount[bossAbilitySpellID],
											castStart = castStart,
											castEnd = castEnd,
											effectEnd = effectEnd,
											frameLevel = frameLevel,
											relativeCastTime = castTime,
											combatLogEventType = eventTrigger.combatLogEventType,
											triggerSpellID = triggerSpellID,
											spellCount = triggerCastIndex,
											repeatInstance = nil,
											repeatCastIndex = nil,
											signifiesPhaseStart = nil,
											signifiesPhaseEnd = nil,
											overlaps = nil,
										} --[[@as BossAbilityInstance]])

										frameLevel = frameLevel + 1
										bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
										cumulativeCastTime = cumulativeCastTime + castTime
									end
									if
										eventTrigger.repeatCriteria
										and eventTrigger.repeatCriteria.spellCount == triggerCastIndex
									then
										local repeatInstance = 1
										while cumulativeCastTime < phaseEndTime do
											for repeatCastIndex, castTime in
												ipairs(eventTrigger.repeatCriteria.castTimes)
											do
												local castStart = cumulativeCastTime + castTime
												local castEnd = castStart + bossAbility.castTime
												local effectEnd = castEnd + bossAbility.duration
												if effectEnd < phaseEndTime then
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
														spellOccurrence = #spellCount[bossAbilitySpellID],
														castStart = castStart,
														castEnd = castEnd,
														effectEnd = effectEnd,
														frameLevel = frameLevel,
														relativeCastTime = castTime,
														combatLogEventType = eventTrigger.combatLogEventType,
														triggerSpellID = triggerSpellID,
														spellCount = triggerCastIndex,
														repeatInstance = nil,
														repeatCastIndex = repeatCastIndex,
														signifiesPhaseStart = nil,
														signifiesPhaseEnd = nil,
														overlaps = nil,
													} --[[@as BossAbilityInstance]])

													frameLevel = frameLevel + 1
													bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
													repeatInstance = repeatInstance + 1
												end
												cumulativeCastTime = cumulativeCastTime + castTime
											end
										end
									end
									cumulativeTriggerTime = cumulativeTriggerTime + triggerCastTime
									if eventTrigger.combatLogEventType == "SCC" then
										cumulativeTriggerTime = cumulativeTriggerTime + bossAbilityTrigger.castTime
									end
								end
							end
						end
					end
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end
		boss.abilityInstances = abilityInstances
	end

	---@param boss Boss
	local function GenerateSortedBossAbilities(boss)
		local earliestCastTimes = {}
		local spellCount = BossUtilities.GetAbsoluteSpellCastTimeTable(boss.dungeonEncounterID)
		if spellCount then
			for spellID, spellOccurrenceNumbers in pairs(spellCount) do
				local earliestCastTime = hugeNumber
				for _, castTimeTable in pairs(spellOccurrenceNumbers) do
					earliestCastTime = min(earliestCastTime, castTimeTable.castStart)
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

	-- Creates spell cast time, sorted abilities, and ability instances tables for a boss.
	---@param boss Boss
	function BossUtilities.GenerateBossTables(boss)
		GenerateAbsoluteSpellCastTimeTable(boss)
		GenerateSortedBossAbilities(boss)
		GenerateBossAbilityInstances(boss)
	end

	for _, raidInstance in pairs(Private.raidInstances) do
		for _, boss in ipairs(raidInstance.bosses) do
			BossUtilities.GenerateBossTables(boss)
		end
	end
end
