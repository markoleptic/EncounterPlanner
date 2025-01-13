local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class BossUtilities
local BossUtilities = Private.bossUtilities

local hugeNumber = math.huge
local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

---@type table<integer, table<integer, table<integer, number>>>
local absoluteSpellCastStartTables = {}
---@type table<integer, table<integer, integer>>
local bossPhaseTables = {}

---@param dungeonEncounterID integer
---@return string|nil
function BossUtilities.GetBossName(dungeonEncounterID)
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
---@return table<integer, integer>|nil -- Ordered boss phase table
function BossUtilities.GetBossPhaseTable(bossDungeonEncounterID)
	return bossPhaseTables[bossDungeonEncounterID]
end

-- Returns a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param bossDungeonEncounterID integer
---@return table<integer, table<integer, number>>|nil
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
---@param spellID integer
---@param count integer
---@return boolean
function BossUtilities.IsValidSpellCount(bossDungeonEncounterID, spellID, count)
	local spellCount = absoluteSpellCastStartTables[bossDungeonEncounterID]
	if spellCount then
		if spellCount[spellID] then
			return count >= 1 and count <= #spellCount[spellID]
		end
	end
	return false
end

do
	-- Creates a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
	---@param bossDungeonEncounterID integer
	---@return table<integer, integer> -- Ordered boss phase table
	local function CreateBossPhaseTable(bossDungeonEncounterID)
		local boss = BossUtilities.GetBoss(bossDungeonEncounterID)
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
	---@param boss Boss
	local function GenerateAbsoluteSpellCastTimeTable(boss)
		local spellCount = {}

		local bossPhaseTable = CreateBossPhaseTable(boss.dungeonEncounterID)
		bossPhaseTables[boss.dungeonEncounterID] = bossPhaseTable

		local cumulativePhaseStartTime = 0
		for _, bossPhaseIndex in ipairs(bossPhaseTable) do
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
										tinsert(spellCount[bossAbilitySpellID], castStart)
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
													tinsert(spellCount[bossAbilitySpellID], castStart)
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
		local bossPhaseOrder = BossUtilities.GetBossPhaseTable(boss.dungeonEncounterID)
		if not bossPhaseOrder then
			return
		end
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(bossPhaseOrder) do
			local bossPhase = boss.phases[bossPhaseIndex]
			if bossPhase then
				local bossPhaseName = bossPhase.name
				local nextBossPhaseName
				local nextBossPhaseIndex = bossPhaseOrder[bossPhaseOrderIndex + 1]
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

							if castStart <= phaseEndTime then
								if bossAbilityPhase.signifiesPhaseStart and castIndex == 1 then
									castEnd = min(castEnd, phaseEndTime)
									if castEnd + bossAbility.duration >= phaseEndTime then
										local newDuration = phaseEndTime - castEnd
										effectEnd = castEnd + newDuration
									end
								end
								if bossAbilityPhase.signifiesPhaseEnd and castIndex == #bossAbilityPhase.castTimes then
									if castEnd < phaseEndTime and bossAbility.duration > 0.0 then
										effectEnd = phaseEndTime
									else
										if castTime == bossPhase.defaultDuration then
											castStart = phaseEndTime
										end
										castEnd = phaseEndTime
										effectEnd = castEnd
									end
								end

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
