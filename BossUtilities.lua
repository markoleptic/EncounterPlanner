local _, Namespace = ...

---@class Private
local Private = Namespace

local L = Private.L

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local BossUtilities = Private.bossUtilities

local DifficultyType = Private.classes.DifficultyType

local Clamp = Clamp
local floor = math.floor
local hugeNumber = math.huge
local ipairs = ipairs
local max, min = math.max, math.min
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local wipe = table.wipe

--- Dungeon Instance ID -> [dungeonInstance.mapChallengeModeID, [Boss dungeon encounter ID, order]] | [Boss dungeon encounter ID, order]
---@type table<integer, table<integer, table<integer, integer>>|table<integer, integer>>
local instanceBossOrder = {}

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

-- Boss dungeon encounter ID -> boss ability spell ID -> {castStart, boss phase order index}
---@type table<integer, table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>>
local absoluteSpellCastStartTablesHeroic = {}

---@type table<integer, table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>>
local maxAbsoluteSpellCastStartTablesHeroic = {}

-- Boss dungeon encounter ID -> [boss phase order index, boss phase index]
---@type table<integer, table<integer, integer>>
local orderedBossPhasesHeroic = {}

---@type table<integer, table<integer, integer>>
local maxOrderedBossPhasesHeroic = {}

do
	local ceil = math.ceil

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
end

---@return fun(): DungeonInstance?
function BossUtilities.IterateDungeonInstances()
	local mainIndex, mainInstance = next(Private.dungeonInstances)
	local splitIndex, splitInstance = nil, nil
	return function()
		while mainIndex do
			if mainInstance and mainInstance.splitDungeonInstances then
				splitIndex, splitInstance = next(mainInstance.splitDungeonInstances, splitIndex)
				if splitIndex then
					return splitInstance
				end
			else
				if mainInstance then
					local result = mainInstance
					mainIndex, mainInstance = next(Private.dungeonInstances, mainIndex)
					return result
				end
			end

			-- Finished splits or current item — advance to next main
			mainIndex, mainInstance = next(Private.dungeonInstances, mainIndex)
			splitIndex, splitInstance = nil, nil
		end

		return nil
	end
end

---@param dungeonInstanceID integer Instance ID of the dungeon.
---@param mapChallengeModeID integer? Map challenge mode ID of the dungeon if split.
---@return DungeonInstance?
function BossUtilities.FindDungeonInstance(dungeonInstanceID, mapChallengeModeID)
	if Private.dungeonInstances[dungeonInstanceID] then
		if not Private.dungeonInstances[dungeonInstanceID].isSplit then
			return Private.dungeonInstances[dungeonInstanceID]
		else
			for _, dungeonInstance in pairs(Private.dungeonInstances[dungeonInstanceID].splitDungeonInstances) do
				if dungeonInstance.mapChallengeModeID == mapChallengeModeID then
					return dungeonInstance
				end
			end
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@return string|nil
function BossUtilities.GetBossName(encounterID)
	for dungeonInstance in BossUtilities.IterateDungeonInstances() do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				return boss.name
			end
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@return Boss|nil
function BossUtilities.GetBoss(encounterID)
	for dungeonInstance in BossUtilities.IterateDungeonInstances() do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				return boss
			end
		end
	end
end

---@param boss Boss
---@param difficulty DifficultyType
---@return table<integer, BossAbility>
function BossUtilities.GetBossAbilities(boss, difficulty)
	if difficulty == DifficultyType.Heroic then
		return boss.abilitiesHeroic
	else
		return boss.abilities
	end
end

---@param boss Boss
---@param difficulty DifficultyType
---@return table<integer, integer>
function BossUtilities.GetSortedBossAbilityIDs(boss, difficulty)
	if difficulty == DifficultyType.Heroic then
		return boss.sortedAbilityIDsHeroic
	else
		return boss.sortedAbilityIDs
	end
end

---@param boss Boss
---@param difficulty DifficultyType
---@return table<integer, BossPhase>
function BossUtilities.GetBossPhases(boss, difficulty)
	if difficulty == DifficultyType.Heroic then
		return boss.phasesHeroic
	else
		return boss.phases
	end
end

---@param boss Boss
---@param difficulty DifficultyType
---@return { [integer]: PreferredCombatLogEventAbility|nil }|nil
function BossUtilities.GetBossPreferredCombatLogEventAbilities(boss, difficulty)
	if difficulty == DifficultyType.Heroic then
		return boss.preferredCombatLogEventAbilitiesHeroic
	else
		return boss.preferredCombatLogEventAbilities
	end
end

---@param spellID integer
---@param difficulty DifficultyType
---@return integer|nil
function BossUtilities.GetBossDungeonEncounterIDFromSpellID(spellID, difficulty)
	if spellID > 0 then
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)
				if bossAbilities[spellID] then
					return boss.dungeonEncounterID
				end
			end
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID number
---@param difficulty DifficultyType
---@return BossAbility|nil
function BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
	for dungeonInstance in BossUtilities.IterateDungeonInstances() do
		for _, boss in ipairs(dungeonInstance.bosses) do
			if boss.dungeonEncounterID == encounterID then
				local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)
				if bossAbilities[spellID] then
					return bossAbilities[spellID]
				end
			end
		end
	end
end

---@param dungeonInstanceID integer Dungeon instance ID
---@return table<integer, integer>|table<integer, table<integer, integer>>|nil
function BossUtilities.GetInstanceBossOrder(dungeonInstanceID)
	return instanceBossOrder[dungeonInstanceID]
end

do
	local unknownIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]]
	local deathIcon = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]]
	local tankIcon = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":14:14:0:0:64:64:0:19:22:41|t"
	local GetSpellName = C_Spell.GetSpellName
	local GetSpellTexture = C_Spell.GetSpellTexture

	---@param boss Boss
	---@param abilityID integer
	---@param difficulty DifficultyType
	---@return string|integer, string
	function BossUtilities.GetBossAbilityIconAndLabel(boss, abilityID, difficulty)
		local icon, label = unknownIcon, ""

		local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)

		if boss.hasBossDeath and bossAbilities[abilityID].bossNpcID then
			icon = deathIcon
			local bossNpcID = bossAbilities[abilityID].bossNpcID
			label = boss.bossNames[bossNpcID] .. " " .. L["Death"]
		else
			if boss.customSpells and boss.customSpells[abilityID] then
				label = boss.customSpells[abilityID].text
				icon = boss.customSpells[abilityID].iconID
			else
				local spellTexture = GetSpellTexture(abilityID)
				local spellName = GetSpellName(abilityID)
				if spellTexture and spellName then
					icon = tostring(spellTexture)
					label = spellName
				elseif Private:HasPlaceholderBossSpellID(abilityID) then
					label = Private:GetPlaceholderBossName(abilityID)
				end
			end
		end

		if label == "" then
			label = L["Unknown"]
		end

		if bossAbilities[abilityID].onlyRelevantForTanks then
			label = label .. " " .. tankIcon
		end

		if bossAbilities[abilityID].additionalContext then
			label = label .. " " .. format("(%s)", bossAbilities[abilityID].additionalContext)
		end

		return icon, label
	end
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
---@param difficulty DifficultyType
---@return number -- Cumulative start time for a given boss phase and count/occurrence
function BossUtilities.GetCumulativePhaseStartTime(encounterID, bossPhaseTable, phaseNumber, phaseCount, difficulty)
	if not phaseCount then
		phaseCount = 1
	end
	local cumulativePhaseStartTime = 0
	local phaseNumberOccurrences = 0
	local boss = BossUtilities.GetBoss(encounterID)

	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for _, currentPhaseNumber in ipairs(bossPhaseTable) do
			if currentPhaseNumber == phaseNumber then
				phaseNumberOccurrences = phaseNumberOccurrences + 1
			end
			if phaseNumberOccurrences == phaseCount then
				break
			end
			cumulativePhaseStartTime = cumulativePhaseStartTime + phases[currentPhaseNumber].duration
		end
	end
	return cumulativePhaseStartTime
end

-- Returns a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, integer>|nil -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetOrderedBossPhases(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return orderedBossPhasesHeroic[encounterID]
	else
		return orderedBossPhases[encounterID]
	end
end

-- Returns a table of boss phases in the order in which they occur, for the maximum allowed duration of a fight.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, integer>|nil -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetMaxOrderedBossPhases(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return maxOrderedBossPhasesHeroic[encounterID]
	else
		return maxOrderedBossPhases[encounterID]
	end
end

-- Returns a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>|nil
function BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return absoluteSpellCastStartTablesHeroic[encounterID]
	else
		return absoluteSpellCastStartTables[encounterID]
	end
end

-- Returns a table that can be used to find the cast time of given the spellID and spell occurrence number. The table
-- is created using the maximum allowed phase counts rather than the current phase counts.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>|nil
function BossUtilities.GetMaxAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return maxAbsoluteSpellCastStartTablesHeroic[encounterID]
	else
		return maxAbsoluteSpellCastStartTables[encounterID]
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, BossAbilityInstance>|nil
function BossUtilities.GetBossAbilityInstances(encounterID, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		if difficulty == DifficultyType.Heroic then
			return boss.abilityInstancesHeroic
		else
			return boss.abilityInstances
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
function BossUtilities.ResetBossPhaseTimings(encounterID, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for _, phase in ipairs(phases) do
			phase.duration = phase.defaultDuration
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
function BossUtilities.ResetBossPhaseCounts(encounterID, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for _, phase in ipairs(phases) do
			phase.count = phase.defaultCount
		end
	end
end

-- Returns true if the spell count exists in the current boss phase timing configuration.
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param count integer
---@param useMaxSpellCount boolean|nil If specified, the maxAbsoluteSpellCastStartTable will also be searched.
---@param difficulty DifficultyType
---@return boolean
function BossUtilities.IsValidSpellCount(encounterID, spellID, count, useMaxSpellCount, difficulty)
	local spellCount = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID and spellCountBySpellID[count] then
			return true
		elseif useMaxSpellCount then
			spellCount = BossUtilities.GetMaxAbsoluteSpellCastTimeTable(encounterID, difficulty)
			if spellCount then
				spellCountBySpellID = spellCount[spellID]
				if spellCountBySpellID and spellCountBySpellID[count] then
					return true
				end
			end
		end
	end
	return false
end

-- Clamps the spell count based on the current boss phase timing configuration.
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param count integer
---@param difficulty DifficultyType
---@return integer|nil
function BossUtilities.ClampSpellCount(encounterID, spellID, count, difficulty)
	local spellCount = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			local length = #spellCountBySpellID
			if length > 0 then
				return Clamp(count, 1, #spellCountBySpellID)
			end
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param difficulty DifficultyType
---@return table <integer, CombatLogEventType>
function BossUtilities.GetValidCombatLogEventTypes(encounterID, spellID, difficulty)
	local bossAbility = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
	if bossAbility then
		return bossAbility.allowedCombatLogEventTypes
	end
	return {}
end

---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table <integer, CombatLogEventType>
function BossUtilities.GetAvailableCombatLogEventTypes(encounterID, difficulty)
	local available = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)
		for _, ability in pairs(bossAbilities) do
			for _, allowed in ipairs(ability.allowedCombatLogEventTypes) do
				available[allowed] = true
			end
		end
	end
	local returnTable = {}
	for eventType, _ in pairs(available) do
		tinsert(returnTable, eventType)
	end
	return returnTable
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param combatLogEventType CombatLogEventType
---@param difficulty DifficultyType
---@return boolean valid
---@return CombatLogEventType|nil suggestedCombatLogEventType
function BossUtilities.IsValidCombatLogEventType(encounterID, spellID, combatLogEventType, difficulty)
	local bossAbility = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
	if bossAbility then
		if bossAbility.allowedCombatLogEventTypes then
			if #bossAbility.allowedCombatLogEventTypes == 0 then
				return false
			else
				local allowed = {}
				for _, eventType in ipairs(bossAbility.allowedCombatLogEventTypes) do
					if eventType == combatLogEventType then
						return true
					end
					allowed[eventType] = true
				end
				local suggested = {
					["SCS"] = { "SAA", "SCC", "SAR" },
					["SCC"] = { "SAR", "SCS", "SAA" },
					["SAA"] = { "SCS", "SAR", "SCC" },
					["SAR"] = { "SCC", "SAA", "SCS" },
					["UD"] = {},
				}
				for _, eventType in ipairs(suggested[combatLogEventType]) do
					if allowed[eventType] then
						return false, eventType
					end
				end
				return false
			end
		else
			return true
		end
	end
	return false
end

-- Returns the max spell count according to the current boss phase timing configuration.
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer
---@param difficulty DifficultyType
---@return integer|nil
function BossUtilities.GetMaxSpellCount(encounterID, spellID, difficulty)
	local spellCount
	if difficulty == DifficultyType.Heroic then
		spellCount = absoluteSpellCastStartTablesHeroic[encounterID]
	else
		spellCount = absoluteSpellCastStartTables[encounterID]
	end
	if spellCount then
		local spellCountBySpellID = spellCount[spellID]
		if spellCountBySpellID then
			return #spellCountBySpellID
		end
	end
	return nil
end

---@param phases table<integer, BossPhase>
---@param counts table<integer, integer>
---@return boolean
local function FixedCountsSatisfied(phases, counts)
	for phaseIndex, phase in ipairs(phases) do
		if phase.fixedCount then
			if not counts[phaseIndex] or counts[phaseIndex] < phase.defaultCount then
				return false
			end
		end
	end
	return true
end

-- Calculates the maximum amount number of each boss phase based on their durations compared to the max total duration.
---@param encounterID integer Boss dungeon encounter ID
---@param maxTotalDuration number
---@param difficulty DifficultyType
---@return table<integer, integer>
local function CalculateMaxPhaseCounts(encounterID, maxTotalDuration, difficulty)
	local counts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
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
				if phase.fixedCount and FixedCountsSatisfied(phases, counts) then
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
---@param difficulty DifficultyType
---@return table<integer, integer>
function BossUtilities.ValidatePhaseCounts(encounterID, changedPhase, newCount, maxTotalDuration, difficulty)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
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
		local maxCounts = CalculateMaxPhaseCounts(encounterID, maxTotalDuration, difficulty)
		if validatedCounts[1] then
			validatedCounts[1] = Clamp(validatedCounts[1], 1, maxCounts[1])
			local lastPhaseIndex, lastPhaseIndexCount = 1, validatedCounts[1]
			for phaseIndex = 2, #validatedCounts do
				local phaseCount = validatedCounts[phaseIndex]
				local minCount, maxCount
				if phases[lastPhaseIndex].repeatAfter == lastPhaseIndex then
					minCount = max(1, lastPhaseIndexCount - 1)
					maxCount = min(lastPhaseIndexCount, maxCounts[phaseIndex])
				else
					minCount = 1
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
---@param difficulty DifficultyType
---@return table<integer, integer>
function BossUtilities.SetPhaseCount(encounterID, changedPhase, newCount, maxTotalDuration, difficulty)
	local validatedCounts =
		BossUtilities.ValidatePhaseCounts(encounterID, changedPhase, newCount, maxTotalDuration, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
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
---@param difficulty DifficultyType
---@return table<integer, integer>
function BossUtilities.SetPhaseCounts(encounterID, phaseCounts, maxTotalDuration, difficulty)
	local validatedCounts = {}
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for phaseIndex, phaseCount in pairs(phaseCounts) do
			if phases[phaseIndex] then
				phases[phaseIndex].count = phaseCount
			end
		end
		validatedCounts = BossUtilities.ValidatePhaseCounts(encounterID, nil, nil, maxTotalDuration, difficulty)
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
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.CalculateMaxPhaseDuration(encounterID, phaseIndex, maxTotalDuration, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(encounterID, difficulty)
	if boss and orderedBossPhaseTable then
		local totalDurationWithoutPhaseDuration = 0.0
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for _, index in ipairs(orderedBossPhaseTable) do
			if index ~= phaseIndex then
				totalDurationWithoutPhaseDuration = totalDurationWithoutPhaseDuration + phases[index].duration
			end
		end
		local phaseCount = phases[phaseIndex].count
		if phaseCount > 0 then
			return (maxTotalDuration - totalDurationWithoutPhaseDuration) / phaseCount
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return number totalCustomDuration
---@return number totalDefaultDuration
function BossUtilities.GetTotalDurations(encounterID, difficulty)
	local totalCustomDuration, totalDefaultDuration = 0.0, 0.0
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		for _, phase in pairs(phases) do
			totalCustomDuration = totalCustomDuration + (phase.duration * phase.count)
			totalDefaultDuration = totalDefaultDuration + (phase.defaultDuration * phase.defaultCount)
		end
	end
	return totalCustomDuration, totalDefaultDuration
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseIndex integer
---@param phaseDuration number
---@param difficulty DifficultyType
function BossUtilities.SetPhaseDuration(encounterID, phaseIndex, phaseDuration, difficulty)
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		if phases[phaseIndex] then
			phases[phaseIndex].duration = phaseDuration
		end
	end
end

---@param encounterID integer Boss dungeon encounter ID
---@param phaseDurations table<integer, number>
---@param difficulty DifficultyType
function BossUtilities.SetPhaseDurations(encounterID, phaseDurations, difficulty)
	for phaseIndex, phaseDuration in pairs(phaseDurations) do
		BossUtilities.SetPhaseDuration(encounterID, phaseIndex, phaseDuration, difficulty)
	end
end

---@param time number Time relative to the combat log event
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
	time,
	encounterID,
	spellID,
	spellCount,
	combatLogEventType,
	difficulty
)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local adjustedTime = absoluteSpellCastStartTable[spellID][spellCount].castStart + time
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
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
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.ConvertAbsoluteTimeToCombatLogEventTime(
	time,
	encounterID,
	spellID,
	spellCount,
	eventType,
	difficulty
)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local adjustedTime = time - absoluteSpellCastStartTable[spellID][spellCount].castStart
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
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
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.GetMinimumCombatLogEventTime(encounterID, spellID, spellCount, eventType, difficulty)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local time = absoluteSpellCastStartTable[spellID][spellCount].castStart
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
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
	---@param eventType CombatLogEventType|nil
	---@param difficulty DifficultyType
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	local function FindNearestCombatLogEventAllowingBefore(time, encounterID, castTimeTable, eventType, difficulty)
		local minTime, minTimeBefore = hugeNumber, hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil
		local spellIDForMinTimeBefore, spellCountForMinTimeBefore = nil, nil

		for spellID, spellCountAndTime in pairs(castTimeTable) do
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			if
				not eventType or BossUtilities.IsValidCombatLogEventType(encounterID, spellID, eventType, difficulty)
			then
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
		end
		if not spellIDForMinTime and not spellCountForMinTime then
			minTime = 0.0
			spellIDForMinTime = spellIDForMinTimeBefore
			spellCountForMinTime = spellCountForMinTimeBefore
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end

	---@param time number The time from the beginning of the boss encounter
	---@param encounterID integer Boss dungeon encounter ID
	---@param castTimeTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param eventType CombatLogEventType|nil
	---@param difficulty DifficultyType
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	local function FindNearestCombatLogEventNoBefore(time, encounterID, castTimeTable, eventType, difficulty)
		local minTime = hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil

		for spellID, spellCountAndTime in pairs(castTimeTable) do
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			if
				not eventType or BossUtilities.IsValidCombatLogEventType(encounterID, spellID, eventType, difficulty)
			then
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
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end

	---@param time number The time from the beginning of the boss encounter
	---@param encounterID integer Boss dungeon encounter ID
	---@param eventType CombatLogEventType
	---@param allowBefore boolean? If specified, combat log events will be chosen before the time if none can be found without doing so.
	---@param difficulty DifficultyType
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	function BossUtilities.FindNearestCombatLogEvent(time, encounterID, eventType, allowBefore, difficulty)
		local castTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
		if castTimeTable then
			if allowBefore then
				return FindNearestCombatLogEventAllowingBefore(time, encounterID, castTimeTable, eventType, difficulty)
			else
				return FindNearestCombatLogEventNoBefore(time, encounterID, castTimeTable, eventType, difficulty)
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
	---@param difficulty DifficultyType
	---@return integer|nil spellCount
	---@return number|nil leftoverTime
	function BossUtilities.FindNearestSpellCount(
		relativeTime,
		encounterID,
		currentEventType,
		currentSpellID,
		currentSpellCount,
		newSpellID,
		allowBefore,
		difficulty
	)
		local absoluteTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
			relativeTime,
			encounterID,
			currentSpellID,
			currentSpellCount,
			currentEventType,
			difficulty
		)
		if not absoluteTime then
			return nil
		end
		local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
		if absoluteSpellCastStartTable and absoluteSpellCastStartTable[newSpellID] then
			local spellCountAndTime = absoluteSpellCastStartTable[newSpellID]
			local ability = BossUtilities.FindBossAbility(encounterID, newSpellID, difficulty)
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

---@param absoluteTime number
---@param encounterID integer
---@param spellID integer|nil
---@param eventType CombatLogEventType
---@param difficulty DifficultyType
---@return integer|nil spellID
---@return integer|nil spellCount
---@return number|nil leftoverTime
function BossUtilities.FindNearestPreferredCombatLogEventAbility(
	absoluteTime,
	encounterID,
	spellID,
	eventType,
	difficulty
)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if not absoluteSpellCastStartTable then
		return nil
	end
	if spellID then
		if absoluteSpellCastStartTable[spellID] then
			local spellCountAndTime = absoluteSpellCastStartTable[spellID]
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			if not ability then
				return nil
			end
			local minTime = hugeNumber
			local spellCountForMinTime = nil

			for spellCount, indexAndCastStart in pairs(spellCountAndTime) do
				local adjustedTime = indexAndCastStart.castStart
				if ability then
					if eventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif eventType == "SCC" or eventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime <= absoluteTime then
					local difference = absoluteTime - adjustedTime
					if difference < minTime then
						minTime = difference
						spellCountForMinTime = spellCount
					end
				end
			end
			return nil, spellCountForMinTime, minTime
		end
	else
		local minTime = hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil

		for currentSpellID, spellCountAndTime in pairs(absoluteSpellCastStartTable) do
			local ability = BossUtilities.FindBossAbility(encounterID, currentSpellID, difficulty)
			if
				not eventType
				or BossUtilities.IsValidCombatLogEventType(encounterID, currentSpellID, eventType, difficulty)
			then
				for spellCount, indexAndCastStart in pairs(spellCountAndTime) do
					local adjustedTime = indexAndCastStart.castStart
					if ability then
						if eventType == "SAR" then
							adjustedTime = adjustedTime + ability.duration + ability.castTime
						elseif eventType == "SCC" or eventType == "SAA" then
							adjustedTime = adjustedTime + ability.castTime
						end
					end
					if adjustedTime <= absoluteTime then
						local difference = absoluteTime - adjustedTime
						if difference < minTime then
							minTime = difference
							spellIDForMinTime = spellID
							spellCountForMinTime = spellCount
						end
					end
				end
			end
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end

	return nil
end

do
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class TimedAssignment
	local TimedAssignment = Private.classes.TimedAssignment

	---@param assignments table<integer, Assignment|CombatLogEventAssignment>
	---@param oldEncounterID integer Old boss dungeon encounter ID
	---@param difficulty DifficultyType
	local function ConvertCombatLogEventAssignmentsToTimedAssignments(assignments, oldEncounterID, difficulty)
		for _, assignment in ipairs(assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				local convertedTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType,
					difficulty
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
	---@param difficulty DifficultyType
	local function ReplaceCombatLogEventAssignmentSpells(
		assignments,
		oldID,
		newID,
		castTimeTable,
		bossPhaseTable,
		difficulty
	)
		for _, assignment in ipairs(assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				local spellID, spellCount, eventType =
					assignment.combatLogEventSpellID, assignment.spellCount, assignment.combatLogEventType
				local absoluteTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldID,
					spellID,
					spellCount,
					eventType,
					difficulty
				)
				if absoluteTime then
					local newSpellID, newSpellCount, newTime = BossUtilities.FindNearestPreferredCombatLogEventAbility(
						absoluteTime,
						newID,
						nil,
						eventType,
						difficulty
					)
					if not newSpellID then
						newSpellID, newSpellCount, newTime =
							BossUtilities.FindNearestCombatLogEvent(absoluteTime, newID, eventType, true, difficulty)
					end
					if newSpellID and newSpellCount and newTime then
						if castTimeTable[newSpellID] and castTimeTable[newSpellID][newSpellCount] then
							local orderedBossPhaseIndex = castTimeTable[newSpellID][newSpellCount].bossPhaseOrderIndex
							assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
							assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
						end
						assignment.time = Utilities.Round(newTime, 1)
						assignment.combatLogEventSpellID = newSpellID
						assignment.spellCount = newSpellCount
					else
						assignment = TimedAssignment:New(assignment, true)
						assignment.time = Utilities.Round(absoluteTime, 1)
					end
				end
			end
		end
	end

	---@param assignments table<integer, Assignment|CombatLogEventAssignment>
	---@param oldBoss Boss
	---@param newBoss Boss
	---@param conversionMethod AssignmentConversionMethod
	---@param difficulty DifficultyType
	function BossUtilities.ConvertAssignmentsToNewBoss(assignments, oldBoss, newBoss, conversionMethod, difficulty)
		local oldID, newID = oldBoss.dungeonEncounterID, newBoss.dungeonEncounterID
		if conversionMethod == 1 then
			ConvertCombatLogEventAssignmentsToTimedAssignments(assignments, oldID, difficulty)
		elseif conversionMethod == 2 then
			local castTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(newID, difficulty)
			local bossPhaseTable = BossUtilities.GetOrderedBossPhases(newID, difficulty)
			if castTimeTable and bossPhaseTable then
				ReplaceCombatLogEventAssignmentSpells(
					assignments,
					oldID,
					newID,
					castTimeTable,
					bossPhaseTable,
					difficulty
				)
			end
		end
	end
end

do
	-- Creates a table of boss phases in the order in which they occur, using the maximum amount of phases until
	-- reaching maxTotalDuration.
	---@param encounterID integer Boss dungeon encounter ID
	---@param maxTotalDuration number
	---@param difficulty DifficultyType
	---@return table<integer, integer> -- Ordered boss phase table
	local function GenerateMaxOrderedBossPhaseTable(encounterID, maxTotalDuration, difficulty)
		local boss = BossUtilities.GetBoss(encounterID)
		local orderedBossPhaseTable = {}
		local counts = {}
		if boss then
			local phases = BossUtilities.GetBossPhases(boss, difficulty)
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
					if phase.fixedCount and FixedCountsSatisfied(phases, counts) then
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
	---@param difficulty DifficultyType
	---@return table<integer, integer> -- Ordered boss phase table
	local function GenerateOrderedBossPhaseTable(encounterID, difficulty)
		local boss = BossUtilities.GetBoss(encounterID)
		local orderedBossPhaseTable = {}
		local counts = {}
		if boss then
			local phases = BossUtilities.GetBossPhases(boss, difficulty)
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
					if phase.fixedCount and FixedCountsSatisfied(phases, counts) then
						break
					else
						currentPhaseIndex = phase.repeatAfter
					end
				end
			end
		end
		return orderedBossPhaseTable
	end

	---@param eventType CombatLogEventType
	---@param ability BossAbility
	---@return number
	local function GetCombatLogEventTimeOffset(eventType, ability)
		if eventType == "SAR" then
			return ability.castTime + ability.duration
		elseif eventType == "SCC" or eventType == "SAA" then
			return ability.castTime
		end
		return 0.0
	end

	---@param boss Boss
	---@param customOrderedBossPhases table<integer, integer>|nil
	---@param difficulty DifficultyType
	---@return table<integer, {startTime: number, endTime: number, count: integer}>
	local function GeneratePhaseCountDurationMap(boss, customOrderedBossPhases, difficulty)
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		local counts = {}
		local map = {}
		local currentTotalDuration = 0.0
		local tbl
		if customOrderedBossPhases ~= nil then
			tbl = customOrderedBossPhases
		else
			if difficulty == DifficultyType.Heroic then
				tbl = orderedBossPhasesHeroic[boss.dungeonEncounterID]
			else
				tbl = orderedBossPhases[boss.dungeonEncounterID]
			end
		end
		for _, bossPhaseIndex in ipairs(tbl) do
			local phase = phases[bossPhaseIndex]
			counts[bossPhaseIndex] = (counts[bossPhaseIndex] or 0) + 1
			tinsert(map, {
				startTime = currentTotalDuration,
				endTime = currentTotalDuration + phase.duration,
				count = counts[bossPhaseIndex],
				index = bossPhaseIndex,
			})
			currentTotalDuration = currentTotalDuration + phase.duration
		end
		return map
	end

	local phaseCountDurationMap = {} ---@type table<integer, {startTime: number, endTime: number, count: integer, index: integer}>

	---@param time number
	---@return integer,integer count
	local function GetCurrentPhaseCountAndIndex(time)
		for _, tbl in ipairs(phaseCountDurationMap) do
			if tbl.endTime > time and tbl.startTime <= time then
				return tbl.count, tbl.index
			end
		end
		return 0, 0
	end

	local abilityIterator = {}

	---@param spellID integer
	---@param ability BossAbility
	---@param castIndex integer
	---@param startTime number
	---@param endTime number Phase end time.
	---@param castCallback fun(spellID: integer, castStart: number, castEnd: number, effectEnd: number)
	---@param dependencies table<integer,table<integer,integer>>|nil
	---@param abilities table<integer, BossAbility>
	function abilityIterator:HandleDependencies(
		spellID,
		ability,
		castIndex,
		startTime,
		endTime,
		castCallback,
		dependencies,
		abilities
	)
		if not dependencies or not dependencies[spellID] then
			return
		end

		for _, dependencyID in ipairs(dependencies[spellID]) do
			local dependencyAbility = abilities[dependencyID]
			if dependencyAbility and dependencyAbility.eventTriggers[spellID] then
				local dependencyTrigger = dependencyAbility.eventTriggers[spellID]
				local timeOffset = GetCombatLogEventTimeOffset(dependencyTrigger.combatLogEventType, ability)
				local triggerTime = startTime + timeOffset
				local spellCount = dependencyTrigger.combatLogEventSpellCount
				local spellCountIrrelevant = not castIndex or not spellCount
				local validSpellCount = spellCountIrrelevant or spellCount == castIndex

				local validPhase = not dependencyTrigger.phaseOccurrences
				if not validPhase then
					local phaseCount, index = GetCurrentPhaseCountAndIndex(startTime)
					validPhase = dependencyTrigger.phaseOccurrences[index]
						and dependencyTrigger.phaseOccurrences[index][phaseCount]
					if castIndex and validPhase and dependencyTrigger.cast then
						validPhase = validPhase and dependencyTrigger.cast(castIndex)
					end
				end

				if validSpellCount and validPhase then
					triggerTime = self:IterateAbilityCastTimes(
						dependencyID,
						dependencyAbility,
						dependencyTrigger,
						triggerTime,
						endTime,
						castCallback,
						dependencies,
						abilities
					)
					local shouldRepeat = dependencyTrigger.repeatInterval
						and (not dependencyTrigger.onlyRepeatOn or dependencyTrigger.onlyRepeatOn == castIndex)
					if shouldRepeat then
						self:IterateRepeatingAbility(
							dependencyID,
							dependencyAbility,
							castIndex,
							dependencyTrigger.repeatInterval,
							triggerTime,
							endTime,
							castCallback,
							dependencies,
							abilities
						)
					end
				end
			end
		end
	end

	---@param spellID integer
	---@param ability BossAbility
	---@param castIndex integer
	---@param repeatInterval number|table<integer, number>|nil
	---@param startTime number Cumulative phase start time.
	---@param endTime number Phase end time.
	---@param castCallback fun(spellID: integer, castStart: number, castEnd: number, effectEnd: number)
	---@param dependencies table<integer,table<integer,integer>>|nil
	---@param abilities table<integer, BossAbility>
	function abilityIterator:IterateRepeatingAbility(
		spellID,
		ability,
		castIndex,
		repeatInterval,
		startTime,
		endTime,
		castCallback,
		dependencies,
		abilities
	)
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
			castIndex = castIndex + 1 -- Will be the value of the last cast

			local castEnd = nextRepeatStart + ability.castTime
			local effectEnd = castEnd + ability.duration
			castEnd = min(castEnd, endTime)
			effectEnd = min(effectEnd, endTime)
			castCallback(spellID, nextRepeatStart, castEnd, effectEnd)

			self:HandleDependencies(
				spellID,
				ability,
				castIndex,
				nextRepeatStart,
				endTime,
				castCallback,
				dependencies,
				abilities
			)

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
	end

	---@param spellID integer
	---@param ability BossAbility
	---@param abilityPhase BossAbilityPhase|EventTrigger
	---@param startTime number Cumulative phase start time.
	---@param endTime number Phase end time.
	---@param castCallback fun(spellID:integer, castStart: number, castEnd: number, effectEnd: number)
	---@param dependencies table<integer,table<integer,integer>>|nil
	---@param abilities table<integer, BossAbility>
	---@return number cumulativePhaseCastTime
	function abilityIterator:IterateAbilityCastTimes(
		spellID,
		ability,
		abilityPhase,
		startTime,
		endTime,
		castCallback,
		dependencies,
		abilities
	)
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
				-- if not abilityPhase.durationLastsUntilEndOfNextPhase then end
				effectEnd = min(effectEnd, endTime)
				castCallback(spellID, castStart, castEnd, effectEnd)

				self:HandleDependencies(
					spellID,
					ability,
					castIndex,
					castStart,
					endTime,
					castCallback,
					dependencies,
					abilities
				)

				cumulativePhaseCastTime = cumulativePhaseCastTime + castTime
			end
		end
		return cumulativePhaseCastTime
	end

	---@param bossAbilities table<integer, BossAbility>
	---@param map table<integer, table<integer,integer>>|nil
	---@param visited table<integer, boolean>|nil
	---@return table<integer, table<integer,integer>>
	local function BuildEventTriggerDependencies(bossAbilities, map, visited)
		map = map or {}
		visited = visited or {}
		for spellID, bossAbility in pairs(bossAbilities) do
			if not visited[spellID] then
				visited[spellID] = true

				if bossAbility.eventTriggers then
					for triggerSpellID, _ in pairs(bossAbility.eventTriggers) do
						map[triggerSpellID] = map[triggerSpellID] or {}
						tinsert(map[triggerSpellID], spellID)

						if not visited[triggerSpellID] then
							BuildEventTriggerDependencies(bossAbilities, map, visited)
						end
					end
				end
			end
		end
		return map
	end

	-- Creates a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
	---@param boss Boss
	---@param orderedBossPhaseTable table<integer, integer>
	---@param difficulty DifficultyType
	---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
	local function GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhaseTable, difficulty)
		---@type table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
		local spellCount = {}
		local visitedPhaseCounts = {}

		local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		local eventTriggerDependencies = BuildEventTriggerDependencies(bossAbilities)
		local cumulativePhaseStartTime = 0
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
			local bossPhase = phases[bossPhaseIndex]
			if bossPhase then
				visitedPhaseCounts[bossPhaseIndex] = (visitedPhaseCounts[bossPhaseIndex] or 0) + 1
				local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration
				for bossAbilitySpellID, bossAbility in pairs(bossAbilities) do
					local castCallback = function(spellID, castStart, _, _)
						spellCount[spellID] = spellCount[spellID] or {}
						tinsert(spellCount[spellID], {
							castStart = castStart,
							bossPhaseOrderIndex = bossPhaseOrderIndex,
						})
					end

					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
					if bossAbilityPhase then
						local cumulativePhaseCastTime = cumulativePhaseStartTime
						local phaseOccurrence = not bossAbilityPhase.phaseOccurrences
							or bossAbilityPhase.phaseOccurrences[visitedPhaseCounts[bossPhaseIndex]]
						if
							phaseOccurrence
							and (not bossAbilityPhase.skipFirst or visitedPhaseCounts[bossPhaseIndex] > 1)
						then
							if bossAbility.durationLastsUntilEndOfPhase then
								bossAbility.duration = bossPhase.duration - bossAbilityPhase.castTimes[1]
							elseif bossAbility.castTimeLastsUntilEndOfPhase then
								bossAbility.castTime = bossPhase.duration - bossAbilityPhase.castTimes[1]
								-- elseif bossAbilityPhase.durationLastsUntilEndOfNextPhase then
								-- 	local nextBossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex + 1]
								-- 	if nextBossPhaseIndex then
								-- 		local nextPhaseDuration = phases[nextBossPhaseIndex].duration
								-- 		bossAbility.duration = bossPhase.duration
								-- 			+ nextPhaseDuration
								-- 			- bossAbilityPhase.castTimes[1]
								-- 	end
							end

							cumulativePhaseCastTime = abilityIterator:IterateAbilityCastTimes(
								bossAbilitySpellID,
								bossAbility,
								bossAbilityPhase,
								cumulativePhaseStartTime,
								phaseEndTime,
								castCallback,
								eventTriggerDependencies,
								bossAbilities
							)
						end
						abilityIterator:IterateRepeatingAbility(
							bossAbilitySpellID,
							bossAbility,
							#bossAbilityPhase.castTimes,
							bossAbilityPhase.repeatInterval,
							cumulativePhaseCastTime,
							phaseEndTime,
							castCallback,
							eventTriggerDependencies,
							bossAbilities
						)
					end
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end
		for _, spellOccurrenceNumbers in pairs(spellCount) do
			sort(spellOccurrenceNumbers, function(a, b)
				return a.castStart < b.castStart
			end)
		end
		return spellCount
	end

	-- Creates a table that can be used to find the absolute cast time of given the spellID and spell occurrence number
	-- for the longest possible phase durations and counts.
	---@param encounterID integer
	---@param difficulty DifficultyType
	---@return table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
	local function GenerateMaxAbsoluteSpellCastTimeTable(encounterID, difficulty)
		---@type table<integer, table<integer, {castStart: number, bossPhaseOrderIndex: integer}>>
		local spellCount = {}
		local boss = BossUtilities.GetBoss(encounterID)
		local kMinBossPhaseDuration = Private.constants.kMinBossPhaseDuration
		local kMaxBossDuration = Private.constants.kMaxBossDuration
		if boss then
			local phases = BossUtilities.GetBossPhases(boss, difficulty)
			for phaseIndex, currentPhase in ipairs(phases) do
				for _, phase in ipairs(phases) do
					if currentPhase ~= phase then
						if not phase.fixedDuration then
							phase.duration = kMinBossPhaseDuration
						end
					end
				end
				local duration =
					BossUtilities.CalculateMaxPhaseDuration(encounterID, phaseIndex, kMaxBossDuration, difficulty)
				if duration then
					currentPhase.duration = duration
				end

				local orderedBossPhaseTable =
					GenerateMaxOrderedBossPhaseTable(encounterID, kMaxBossDuration, difficulty)
				phaseCountDurationMap = GeneratePhaseCountDurationMap(boss, orderedBossPhaseTable, difficulty)
				local currentSpellCastTimeTable =
					GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhaseTable, difficulty)

				for spellID, spellCountBySpellID in pairs(currentSpellCastTimeTable) do
					spellCount[spellID] = spellCount[spellID] or {}
					for count, castStartAndIndex in pairs(spellCountBySpellID) do
						if not spellCount[spellID][count] then
							spellCount[spellID][count] = castStartAndIndex
						end
					end
				end
			end
			for _, phase in ipairs(phases) do
				phase.duration = phase.defaultDuration
			end
		end
		wipe(phaseCountDurationMap)
		return spellCount
	end

	-- Creates BossAbilityInstances for all abilities of a boss.
	---@param boss Boss
	---@param orderedBossPhaseTable table<integer, integer>
	---@param spellCount table|nil
	---@param difficulty DifficultyType
	---@return table<integer, BossAbilityInstance>
	local function GenerateBossAbilityInstances(boss, orderedBossPhaseTable, spellCount, difficulty)
		spellCount = spellCount or {}
		local visitedPhaseCounts = {}
		local abilityInstances = {} --[[@type table<integer, BossAbilityInstance>]]
		local cumulativePhaseStartTime = 0.0
		local bossAbilityInstanceIndex = 1
		local abilityOrderMap = {}

		local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)
		local phases = BossUtilities.GetBossPhases(boss, difficulty)
		local sortedAbilityIDs = BossUtilities.GetSortedBossAbilityIDs(boss, difficulty)
		local eventTriggerDependencies = BuildEventTriggerDependencies(bossAbilities)

		for orderIndex, spellID in ipairs(sortedAbilityIDs) do
			abilityOrderMap[spellID] = orderIndex
		end
		for bossPhaseOrderIndex, bossPhaseIndex in ipairs(orderedBossPhaseTable) do
			local bossPhase = phases[bossPhaseIndex]
			if bossPhase then
				visitedPhaseCounts[bossPhaseIndex] = (visitedPhaseCounts[bossPhaseIndex] or 0) + 1
				local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration

				local nextBossPhaseName, nextBossPhaseShortName
				local nextBossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex + 1]
				if nextBossPhaseIndex then
					local nextBossPhase = phases[nextBossPhaseIndex]
					if nextBossPhase then
						nextBossPhaseName = nextBossPhase.name
						nextBossPhaseShortName = nextBossPhase.shortName
					end
				end

				for _, bossAbilitySpellID in ipairs(sortedAbilityIDs) do
					local bossAbility = bossAbilities[bossAbilitySpellID]
					local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]

					local currentPhaseCastIndex = 1
					local function castCallback(spellID, castStart, castEnd, effectEnd)
						local overlaps = nil
						spellCount[spellID] = spellCount[spellID] or {}
						tinsert(spellCount[spellID], castStart)
						if bossAbilities[spellID].halfHeight then
							overlaps = {
								heightMultiplier = 0.5,
								offset = ((currentPhaseCastIndex + 1) % 2) * 0.5, -- Alternates 0 and 0.5
							}
						end
						tinsert(abilityInstances, {
							bossAbilitySpellID = spellID,
							bossAbilityInstanceIndex = bossAbilityInstanceIndex,
							bossAbilityOrderIndex = abilityOrderMap[spellID],
							bossPhaseIndex = bossPhaseIndex,
							bossPhaseOrderIndex = bossPhaseOrderIndex,
							bossPhaseDuration = bossPhase.duration,
							bossPhaseName = bossPhase.name,
							bossPhaseShortName = bossPhase.shortName,
							nextBossPhaseName = nextBossPhaseName,
							nextBossPhaseShortName = nextBossPhaseShortName,
							spellCount = #spellCount[spellID],
							castStart = castStart,
							castEnd = castEnd,
							effectEnd = effectEnd,
							frameLevel = 1,
							signifiesPhaseStart = bossAbilityPhase
								and bossAbilityPhase.signifiesPhaseStart
								and currentPhaseCastIndex == 1,
							signifiesPhaseEnd = bossAbilityPhase
								and bossAbilityPhase.signifiesPhaseEnd
								and nextBossPhaseName
								and currentPhaseCastIndex == #bossAbilityPhase.castTimes,
							overlaps = overlaps,
							-- alpha = bossAbilityPhase.durationLastsUntilEndOfNextPhase and 0.5 or 1.0,
						} --[[@as BossAbilityInstance]])
						bossAbilityInstanceIndex = 0 -- Updated later in function
						currentPhaseCastIndex = currentPhaseCastIndex + 1
					end
					if bossAbilityPhase then
						local cumulativePhaseCastTime = cumulativePhaseStartTime
						local phaseOccurrence = not bossAbilityPhase.phaseOccurrences
							or bossAbilityPhase.phaseOccurrences[visitedPhaseCounts[bossPhaseIndex]]
						if
							phaseOccurrence
							and (not bossAbilityPhase.skipFirst or visitedPhaseCounts[bossPhaseIndex] > 1)
						then
							cumulativePhaseCastTime = abilityIterator:IterateAbilityCastTimes(
								bossAbilitySpellID,
								bossAbility,
								bossAbilityPhase,
								cumulativePhaseStartTime,
								phaseEndTime,
								castCallback,
								eventTriggerDependencies,
								bossAbilities
							)
						end
						abilityIterator:IterateRepeatingAbility(
							bossAbilitySpellID,
							bossAbility,
							#bossAbilityPhase.castTimes,
							bossAbilityPhase.repeatInterval,
							cumulativePhaseCastTime,
							phaseEndTime,
							castCallback,
							eventTriggerDependencies,
							bossAbilities
						)
					end
				end
				cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
			end
		end

		sort(abilityInstances, function(a, b)
			local aOrder = abilityOrderMap[a.bossAbilitySpellID]
			local bOrder = abilityOrderMap[b.bossAbilitySpellID]
			if aOrder == bOrder then
				if a.castStart == b.castStart then
					return a.bossAbilityInstanceIndex < b.bossAbilityInstanceIndex
				end
				return a.castStart < b.castStart
			end
			return aOrder < bOrder
		end)

		bossAbilityInstanceIndex = 1
		local currentSpellID = -hugeNumber
		local frameLevel = 1
		---@type table<integer, number> [bossAbilitySpellID, castStart]
		local lastCastStartTimes = {}
		---@type table<integer, table<integer, integer>> [bossAbilitySpellID, [abilityInstanceIndex]]
		local consecutiveOverlapIndices = {}
		---@type table<integer, number> [bossAbilitySpellID, overlap count]
		local consecutiveOverlaps = {}

		for index, abilityInstance in ipairs(abilityInstances) do
			-- Update frame levels and bossAbilityInstanceIndex
			if abilityInstance.bossAbilitySpellID ~= currentSpellID then
				currentSpellID = abilityInstance.bossAbilitySpellID
				frameLevel = 1
			end
			abilityInstance.bossAbilityInstanceIndex = bossAbilityInstanceIndex
			abilityInstance.frameLevel = frameLevel

			bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
			frameLevel = frameLevel + 1

			-- Update overlaps so that abilities get split vertically if cast at the same time
			local castStart = abilityInstance.castStart
			if not consecutiveOverlaps[currentSpellID] then
				consecutiveOverlaps[currentSpellID] = 0
				consecutiveOverlapIndices[currentSpellID] = { index }
			else
				if lastCastStartTimes[currentSpellID] == castStart then
					consecutiveOverlaps[currentSpellID] = consecutiveOverlaps[currentSpellID] + 1
					tinsert(consecutiveOverlapIndices[currentSpellID], index)
					local currentOffset = consecutiveOverlaps[currentSpellID]
					local heightMultiplier = 1.0 / (currentOffset + 1)
					for _, overlappingAbilityIndex in ipairs(consecutiveOverlapIndices[currentSpellID]) do
						abilityInstances[overlappingAbilityIndex].overlaps = {
							heightMultiplier = heightMultiplier,
							offset = currentOffset * heightMultiplier,
						}
						currentOffset = currentOffset - 1
					end
				else
					consecutiveOverlaps[currentSpellID] = 0
					consecutiveOverlapIndices[currentSpellID] = { index }
				end
			end
			lastCastStartTimes[currentSpellID] = abilityInstance.castStart
		end

		return abilityInstances
	end

	-- Creates a sorted table of boss spell IDs based on their earliest cast times.
	---@param absoluteSpellCastStartTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@return table<integer, integer>
	local function GenerateSortedBossAbilities(absoluteSpellCastStartTable)
		local earliestCastTimes = {}
		for spellID, spellOccurrenceNumbers in pairs(absoluteSpellCastStartTable) do
			if #spellOccurrenceNumbers > 0 then -- Relies on absoluteSpellCastStartTable to be sorted
				tinsert(
					earliestCastTimes,
					{ spellID = spellID, earliestCastTime = spellOccurrenceNumbers[1].castStart }
				)
			end
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
	---@param difficulty DifficultyType
	function BossUtilities.GenerateBossTables(boss, difficulty)
		local encounterID = boss.dungeonEncounterID
		if difficulty == DifficultyType.Heroic then
			orderedBossPhasesHeroic[encounterID] = GenerateOrderedBossPhaseTable(encounterID, difficulty)
		else
			orderedBossPhases[encounterID] = GenerateOrderedBossPhaseTable(encounterID, difficulty)
		end
		phaseCountDurationMap = GeneratePhaseCountDurationMap(boss, nil, difficulty)
		if difficulty == DifficultyType.Heroic then
			absoluteSpellCastStartTablesHeroic[encounterID] =
				GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhasesHeroic[encounterID], difficulty)
			boss.sortedAbilityIDsHeroic = GenerateSortedBossAbilities(absoluteSpellCastStartTablesHeroic[encounterID])
			boss.abilityInstancesHeroic =
				GenerateBossAbilityInstances(boss, orderedBossPhasesHeroic[encounterID], nil, difficulty)
		else
			absoluteSpellCastStartTables[encounterID] =
				GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhases[encounterID], difficulty)
			boss.sortedAbilityIDs = GenerateSortedBossAbilities(absoluteSpellCastStartTables[encounterID])
			boss.abilityInstances = GenerateBossAbilityInstances(boss, orderedBossPhases[encounterID], nil, difficulty)
		end

		wipe(phaseCountDurationMap)
	end

	---@param dungeonInstance DungeonInstance
	---@param order table
	local function GenerateInstanceBossOrder(dungeonInstance, order)
		local dungeonInstanceID = dungeonInstance.instanceID
		order[dungeonInstanceID] = order[dungeonInstanceID] or {}
		if dungeonInstance.mapChallengeModeID then
			order[dungeonInstanceID][dungeonInstance.mapChallengeModeID] = {}
			for index, boss in ipairs(dungeonInstance.bosses) do
				order[dungeonInstanceID][dungeonInstance.mapChallengeModeID][boss.dungeonEncounterID] = index
			end
		else
			for index, boss in ipairs(dungeonInstance.bosses) do
				order[dungeonInstanceID][boss.dungeonEncounterID] = index
			end
		end
	end

	local kMaxBossDuration = Private.constants.kMaxBossDuration

	-- Creates the following tables for all dungeon instance bosses: boss ordering, max, max absolute, and ordered boss
	-- phases, spell cast times, sorted abilities, and ability instances for a boss.
	function BossUtilities.Initialize()
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			GenerateInstanceBossOrder(dungeonInstance, instanceBossOrder)
			for _, boss in ipairs(dungeonInstance.bosses) do
				local encounterID = boss.dungeonEncounterID
				BossUtilities.GenerateBossTables(boss, DifficultyType.Mythic)
				maxOrderedBossPhases[encounterID] =
					GenerateMaxOrderedBossPhaseTable(encounterID, kMaxBossDuration, DifficultyType.Mythic)
				maxAbsoluteSpellCastStartTables[encounterID] =
					GenerateMaxAbsoluteSpellCastTimeTable(encounterID, DifficultyType.Mythic)
				if boss.abilitiesHeroic then
					BossUtilities.GenerateBossTables(boss, DifficultyType.Heroic)
					maxOrderedBossPhasesHeroic[encounterID] =
						GenerateMaxOrderedBossPhaseTable(encounterID, kMaxBossDuration, DifficultyType.Heroic)
					maxAbsoluteSpellCastStartTablesHeroic[encounterID] =
						GenerateMaxAbsoluteSpellCastTimeTable(encounterID, DifficultyType.Heroic)
				end
			end
		end
	end

	--@debug@
	do
		---@class Test
		local test = Private.test
		---@class TestUtilities
		local testUtilities = Private.testUtilities

		local TestEqual = testUtilities.TestEqual
		local TestNotEqual = testUtilities.TestNotEqual

		---@param boss Boss
		---@param difficulty DifficultyType
		local function testSpellCastTimeTablesForBoss(boss, difficulty)
			local encounterID = boss.dungeonEncounterID
			phaseCountDurationMap = GeneratePhaseCountDurationMap(boss, nil, difficulty)
			local castTimeTable = {}
			local ordered = BossUtilities.GetOrderedBossPhases(encounterID, difficulty)

			GenerateBossAbilityInstances(boss, ordered, castTimeTable, difficulty)
			for _, spellOccurrenceNumbers in pairs(castTimeTable) do
				sort(spellOccurrenceNumbers)
			end

			---@type table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
			local absoluteAtEncounterID = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)

			TestEqual(#absoluteAtEncounterID, #castTimeTable, "Cast Time Table Size Equal")
			for bossAbilitySpellID, spellCount in pairs(absoluteAtEncounterID) do
				for spellOccurrence, castStartAndOrder in ipairs(spellCount) do
					local castStart = castTimeTable[bossAbilitySpellID][spellOccurrence]
					local _, spellName = BossUtilities.GetBossAbilityIconAndLabel(boss, bossAbilitySpellID, difficulty)
					TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal " .. spellName)
				end
			end
			for bossAbilitySpellID, spellCount in pairs(castTimeTable) do
				for spellOccurrence, castStart in ipairs(spellCount) do
					local castStartAndOrder = absoluteAtEncounterID[bossAbilitySpellID][spellOccurrence]
					local _, spellName = BossUtilities.GetBossAbilityIconAndLabel(boss, bossAbilitySpellID, difficulty)
					TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal " .. spellName)
				end
			end

			wipe(phaseCountDurationMap)
		end

		function test.CompareSpellCastTimeTables()
			for dungeonInstance in BossUtilities.IterateDungeonInstances() do
				for _, boss in ipairs(dungeonInstance.bosses) do
					testSpellCastTimeTablesForBoss(boss, DifficultyType.Mythic)
					if boss.abilitiesHeroic then
						testSpellCastTimeTablesForBoss(boss, DifficultyType.Heroic)
					end
				end
			end
			return "CompareSpellCastTimeTables"
		end

		---@param boss Boss
		---@param difficulty DifficultyType
		local function testValidatedMaxPhaseCountsForBoss(boss, difficulty)
			local encounterID = boss.dungeonEncounterID
			local maxPhaseCounts = CalculateMaxPhaseCounts(encounterID, kMaxBossDuration, difficulty)
			local validatedPhaseCounts =
				BossUtilities.SetPhaseCounts(encounterID, maxPhaseCounts, kMaxBossDuration, difficulty)
			TestEqual(maxPhaseCounts, validatedPhaseCounts, "Max Phase Counts Equal Validated Phase Counts")

			local maxOrderedPhasesAtEncounterID = BossUtilities.GetMaxOrderedBossPhases(encounterID, difficulty)
			local maxPhaseCountsFromOrderedPhases = {}
			TestNotEqual(maxOrderedPhasesAtEncounterID, nil, "maxOrderedPhasesAtEncounterID not nil")
			for _, phaseIndex in ipairs(maxOrderedPhasesAtEncounterID) do
				maxPhaseCountsFromOrderedPhases[phaseIndex] = (maxPhaseCountsFromOrderedPhases[phaseIndex] or 0) + 1
			end

			TestEqual(
				maxPhaseCounts,
				maxPhaseCountsFromOrderedPhases,
				"Max Phase Counts Equal Max Phase Counts From Ordered Phases"
			)
			for _, phase in ipairs(BossUtilities.GetBossPhases(boss, difficulty)) do
				phase.count = phase.defaultCount
			end
		end

		function test.ValidateMaxPhaseCounts()
			for dungeonInstance in BossUtilities.IterateDungeonInstances() do
				for _, boss in ipairs(dungeonInstance.bosses) do
					testValidatedMaxPhaseCountsForBoss(boss, DifficultyType.Mythic)

					if boss.abilitiesHeroic then
						testValidatedMaxPhaseCountsForBoss(boss, DifficultyType.Heroic)
					end
				end
			end
			return "ValidateMaxPhaseCounts"
		end
	end
	--@end-debug@
end
