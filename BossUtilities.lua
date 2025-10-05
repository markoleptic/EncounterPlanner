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

local s = {
	-- Boss dungeon encounter ID -> boss ability spell ID -> [SpellCastStartTableEntry]
	---@type table<integer, table<integer, table<integer, SpellCastStartTableEntry>>>
	AbsoluteSpellCastStartTables = {},

	-- Boss dungeon encounter ID -> boss ability spell ID -> [SpellCastStartTableEntry]
	---@type table<integer, table<integer, table<integer, SpellCastStartTableEntry>>>
	AbsoluteSpellCastStartTablesHeroic = {},

	---@type table<integer, SortedDungeonInstanceEntry>
	InstanceBossOrder = {},

	---@type table<integer, table<integer, table<integer, SpellCastStartTableEntry>>>
	MaxAbsoluteSpellCastStartTables = {},

	---@type table<integer, table<integer, table<integer, SpellCastStartTableEntry>>>
	MaxAbsoluteSpellCastStartTablesHeroic = {},

	---@type table<integer, table<integer, integer>>
	MaxOrderedBossPhases = {},

	---@type table<integer, table<integer, integer>>
	MaxOrderedBossPhasesHeroic = {},

	-- Boss dungeon encounter ID -> [boss phase order index, boss phase index]
	---@type table<integer, table<integer, integer>>
	OrderedBossPhases = {},

	-- Boss dungeon encounter ID -> [boss phase order index, boss phase index]
	---@type table<integer, table<integer, integer>>
	OrderedBossPhasesHeroic = {},
}

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

do
	---@type table<integer, Boss>
	local dungeonEncounterIDToBossCache = nil

	local function PopulateDungeonEncounterIDToBossMap()
		dungeonEncounterIDToBossCache = {}
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				dungeonEncounterIDToBossCache[boss.dungeonEncounterID] = boss
			end
		end
	end

	---@param encounterID integer Boss dungeon encounter ID
	---@return string|nil
	function BossUtilities.GetBossName(encounterID)
		if not dungeonEncounterIDToBossCache then
			PopulateDungeonEncounterIDToBossMap()
		end
		---@cast dungeonEncounterIDToBossCache table<integer, Boss>
		if dungeonEncounterIDToBossCache[encounterID] then
			return dungeonEncounterIDToBossCache[encounterID].name
		end
	end

	---@param encounterID integer Boss dungeon encounter ID
	---@return Boss
	function BossUtilities.GetBoss(encounterID)
		if not dungeonEncounterIDToBossCache then
			PopulateDungeonEncounterIDToBossMap()
		end
		---@cast dungeonEncounterIDToBossCache table<integer, Boss>
		return dungeonEncounterIDToBossCache[encounterID]
	end

	---@param encounterIDsAndDifficultiesWithPlans table<integer, table<DifficultyType, boolean>>
	---@param ignoreEncounterIDs table<integer, boolean>
	---@return table<integer, table<DifficultyType, boolean>> missing
	function BossUtilities.DetermineMissingEncounterIDsAcrossAllDifficulties(
		encounterIDsAndDifficultiesWithPlans,
		ignoreEncounterIDs
	)
		local missing = {}
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				local encounterID = boss.dungeonEncounterID
				if not ignoreEncounterIDs[encounterID] then
					missing[encounterID] = missing[encounterID] or {}
					if not encounterIDsAndDifficultiesWithPlans[encounterID] then
						encounterIDsAndDifficultiesWithPlans[encounterID] = {}
					end
					if
						boss.phasesHeroic
						and not encounterIDsAndDifficultiesWithPlans[encounterID][DifficultyType.Heroic]
					then
						missing[encounterID][DifficultyType.Heroic] = true
					end
					if boss.phases and not encounterIDsAndDifficultiesWithPlans[encounterID][DifficultyType.Mythic] then
						missing[encounterID][DifficultyType.Mythic] = true
					end
				end
			end
		end
		return missing
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
---@return table<integer, PreferredCombatLogEventAbility|nil>|nil
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

do
	---@type table<integer, table<integer, table<integer, BossAbility>>>|nil
	local bossAbilityCache = nil

	---@param encounterID integer Boss dungeon encounter ID
	---@param spellID number
	---@param difficulty DifficultyType
	---@return BossAbility|nil
	function BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
		if not bossAbilityCache then
			bossAbilityCache = {}
			for dungeonInstance in BossUtilities.IterateDungeonInstances() do
				for _, boss in ipairs(dungeonInstance.bosses) do
					bossAbilityCache[boss.dungeonEncounterID] = bossAbilityCache[boss.dungeonEncounterID] or {}
					local encounterSpecificCache = bossAbilityCache[boss.dungeonEncounterID]
					if boss.phases then
						encounterSpecificCache[DifficultyType.Mythic] = {}
						for bossAbilitySpellID, bossAbility in
							pairs(BossUtilities.GetBossAbilities(boss, DifficultyType.Mythic))
						do
							encounterSpecificCache[DifficultyType.Mythic][bossAbilitySpellID] = bossAbility
						end
					end

					if boss.phasesHeroic then
						encounterSpecificCache[DifficultyType.Heroic] = {}
						for bossAbilitySpellID, bossAbility in
							pairs(BossUtilities.GetBossAbilities(boss, DifficultyType.Heroic))
						do
							encounterSpecificCache[DifficultyType.Heroic][bossAbilitySpellID] = bossAbility
						end
					end
				end
			end
		end
		if bossAbilityCache[encounterID][difficulty] then
			return bossAbilityCache[encounterID][difficulty][spellID]
		end
	end
end

do
	local kUnknownTexture = Private.constants.textures.kUnknown
	local kDeathTexture = Private.constants.textures.kSkull
	local kTankTexture = "|T" .. Private.constants.textures.kLfgPortraitRoles .. ":14:14:0:0:64:64:0:19:22:41|t"
	local GetSpellName = C_Spell.GetSpellName
	local GetSpellTexture = C_Spell.GetSpellTexture

	---@param boss Boss
	---@param abilityID integer
	---@param difficulty DifficultyType
	---@return string|integer, string
	function BossUtilities.GetBossAbilityIconAndLabel(boss, abilityID, difficulty)
		local icon, label = kUnknownTexture, ""

		local bossAbilities = BossUtilities.GetBossAbilities(boss, difficulty)

		if boss.hasBossDeath and bossAbilities[abilityID].bossNpcID then
			icon = kDeathTexture
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

		if bossAbilities[abilityID].tankAbility then
			label = label .. " " .. kTankTexture
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
---@return table<integer, integer> -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetOrderedBossPhases(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return s.OrderedBossPhasesHeroic[encounterID]
	else
		return s.OrderedBossPhases[encounterID]
	end
end

-- Returns a table of boss phases in the order in which they occur, for the maximum allowed duration of a fight.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, integer> -- [bossPhaseOrderIndex, bossPhaseIndex]
function BossUtilities.GetMaxOrderedBossPhases(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return s.MaxOrderedBossPhasesHeroic[encounterID]
	else
		return s.MaxOrderedBossPhases[encounterID]
	end
end

-- Returns a table that can be used to find the absolute cast time of given the spellID and spell occurrence number.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, table<integer, SpellCastStartTableEntry>>
function BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return s.AbsoluteSpellCastStartTablesHeroic[encounterID]
	else
		return s.AbsoluteSpellCastStartTables[encounterID]
	end
end

-- Returns a table that can be used to find the cast time of given the spellID and spell occurrence number. The table
-- is created using the maximum allowed phase counts rather than the current phase counts.
---@param encounterID integer Boss dungeon encounter ID
---@param difficulty DifficultyType
---@return table<integer, table<integer, SpellCastStartTableEntry>>
function BossUtilities.GetMaxAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if difficulty == DifficultyType.Heroic then
		return s.MaxAbsoluteSpellCastStartTablesHeroic[encounterID]
	else
		return s.MaxAbsoluteSpellCastStartTables[encounterID]
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
			return false
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
		spellCount = s.AbsoluteSpellCastStartTablesHeroic[encounterID]
	else
		spellCount = s.AbsoluteSpellCastStartTables[encounterID]
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
function BossUtilities.CalculateMaxPhaseCounts(encounterID, maxTotalDuration, difficulty)
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
		local maxCounts = BossUtilities.CalculateMaxPhaseCounts(encounterID, maxTotalDuration, difficulty)
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
		if phases[phaseIndex].maxDuration then
			return phases[phaseIndex].maxDuration
		end
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

---@param encounterID integer Boss dungeon encounter ID
---@param spellCastStartTableEntry SpellCastStartTableEntry
---@param difficulty DifficultyType
---@param combatLogEventType CombatLogEventType
---@param ability BossAbility
---@return number -- Offset
function BossUtilities.GetAdjustedStartTime(
	encounterID,
	spellCastStartTableEntry,
	difficulty,
	combatLogEventType,
	ability
)
	local adjustedStartTime = spellCastStartTableEntry.castStart
	local boss = BossUtilities.GetBoss(encounterID)
	if boss then
		if combatLogEventType == "SAR" then
			local bossPhaseOrderIndex = spellCastStartTableEntry.bossPhaseOrderIndex
			---@type table<integer, integer>
			local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(encounterID, difficulty)
			local phases = BossUtilities.GetBossPhases(boss, difficulty)
			local duration = ability.duration

			local bossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex]
			local bossAbilityPhase = ability.phases[bossPhaseIndex]

			if bossAbilityPhase and bossAbilityPhase.duration then
				duration = bossAbilityPhase.duration
			elseif ability.durationLastsUntilEndOfPhase then
				duration = phases[bossPhaseIndex].duration
			elseif ability.durationLastsUntilEndOfNextPhase then
				local cumPhaseTime = 0.0
				for currentOrderIndex = 1, bossPhaseOrderIndex do
					local phaseIndex = orderedBossPhaseTable[currentOrderIndex]
					cumPhaseTime = cumPhaseTime + phases[phaseIndex].duration
				end
				local nextBossPhaseOrderIndex = bossPhaseOrderIndex + 1
				local nextPhaseIndex = orderedBossPhaseTable[nextBossPhaseOrderIndex]
				if nextPhaseIndex then
					local nextPhaseDuration = phases[nextPhaseIndex].duration
					cumPhaseTime = cumPhaseTime + nextPhaseDuration
				end
				duration = cumPhaseTime - spellCastStartTableEntry.castStart
			end
			if bossAbilityPhase and bossAbilityPhase.castTime then
				adjustedStartTime = adjustedStartTime + duration + bossAbilityPhase.castTime
			else
				adjustedStartTime = adjustedStartTime + duration + ability.castTime
			end
		elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
			local bossPhaseOrderIndex = spellCastStartTableEntry.bossPhaseOrderIndex
			---@type table<integer, integer>
			local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(encounterID, difficulty)
			local bossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex]
			local bossAbilityPhase = ability.phases[bossPhaseIndex]
			if bossAbilityPhase and bossAbilityPhase.castTime then
				adjustedStartTime = adjustedStartTime + bossAbilityPhase.castTime
			else
				adjustedStartTime = adjustedStartTime + ability.castTime
			end
		end
	end
	return adjustedStartTime
end

---@param relativeTime number Time relative to the combat log event
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
	relativeTime,
	encounterID,
	spellID,
	spellCount,
	combatLogEventType,
	difficulty
)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			return relativeTime
				+ BossUtilities.GetAdjustedStartTime(
					encounterID,
					absoluteSpellCastStartTable[spellID][spellCount],
					difficulty,
					combatLogEventType,
					ability
				)
		end
	end
	return nil
end

---@param time number The time from the beginning of the boss encounter
---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer Combat log event spell count
---@param combatLogEventType CombatLogEventType
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.ConvertAbsoluteTimeToCombatLogEventTime(
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
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			return time
				- BossUtilities.GetAdjustedStartTime(
					encounterID,
					absoluteSpellCastStartTable[spellID][spellCount],
					difficulty,
					combatLogEventType,
					ability
				)
		end
	end
	return nil
end

---@param encounterID integer Boss dungeon encounter ID
---@param spellID integer Combat log event spell ID
---@param spellCount integer Combat log event spell count
---@param combatLogEventType CombatLogEventType
---@param difficulty DifficultyType
---@return number|nil
function BossUtilities.GetMinimumCombatLogEventTime(encounterID, spellID, spellCount, combatLogEventType, difficulty)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable then
		if absoluteSpellCastStartTable[spellID] and absoluteSpellCastStartTable[spellID][spellCount] then
			local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
			return BossUtilities.GetAdjustedStartTime(
				encounterID,
				absoluteSpellCastStartTable[spellID][spellCount],
				difficulty,
				combatLogEventType,
				ability
			)
		end
	end
	return nil
end

-- Finds the nearest combat log event corresponding to the absolute time in the encounter. If no matching combat log
-- events occur before absoluteTime, it will fall back to choosing the closest one after.
---@param absoluteTime number The time from the beginning of the boss encounter.
---@param encounterID integer Boss dungeon encounter ID.
---@param eventType CombatLogEventType Type of combat log event to limit the search to.
---@param difficulty DifficultyType Encounter difficulty.
---@return integer|nil spellID
---@return integer|nil spellCount
---@return number|nil leftoverTime
function BossUtilities.FindNearestCombatLogEvent(absoluteTime, encounterID, eventType, difficulty)
	local castTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if castTimeTable then
		local minTime, minTimeAfter = hugeNumber, hugeNumber
		local spellIDForMinTime, spellCountForMinTime = nil, nil
		local spellIDForMinTimeAfter, spellCountForMinTimeAfter = nil, nil

		for spellID, spellCountAndTime in pairs(castTimeTable) do
			if BossUtilities.IsValidCombatLogEventType(encounterID, spellID, eventType, difficulty) then
				local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
				for spellCount, spellCastStartTableEntry in pairs(spellCountAndTime) do
					local currentTime = spellCastStartTableEntry.castStart
					if ability then
						currentTime = BossUtilities.GetAdjustedStartTime(
							encounterID,
							spellCastStartTableEntry,
							difficulty,
							eventType,
							ability
						)
					end
					if currentTime <= absoluteTime then
						local difference = absoluteTime - currentTime
						if difference < minTime then
							minTime = difference
							spellIDForMinTime = spellID
							spellCountForMinTime = spellCount
						end
					else
						local difference = currentTime - absoluteTime
						if difference < minTimeAfter then
							minTimeAfter = difference
							spellIDForMinTimeAfter = spellID
							spellCountForMinTimeAfter = spellCount
						end
					end
				end
			end
		end
		if not spellIDForMinTime and not spellCountForMinTime then
			minTime = 0.0
			spellIDForMinTime = spellIDForMinTimeAfter
			spellCountForMinTime = spellCountForMinTimeAfter
		end
		return spellIDForMinTime, spellCountForMinTime, minTime
	end
	return nil
end

-- Finds the nearest combat log event corresponding to the absolute time in the encounter and the spellID. If no
-- matching combat log events occur before absoluteTime, it will fall back to choosing the closest one after.
---@param absoluteTime number Time relative to the combat log event.
---@param encounterID integer Boss dungeon encounter ID.
---@param spellID integer Combat log event spell ID.
---@param eventType CombatLogEventType Combat log event type.
---@param difficulty DifficultyType Encounter difficulty.
---@return integer|nil spellCount
---@return number|nil leftoverTime
function BossUtilities.FindNearestSpellCount(absoluteTime, encounterID, spellID, eventType, difficulty)
	local absoluteSpellCastStartTable = BossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)
	if absoluteSpellCastStartTable and absoluteSpellCastStartTable[spellID] then
		local castTimeTable = absoluteSpellCastStartTable[spellID]
		local ability = BossUtilities.FindBossAbility(encounterID, spellID, difficulty)
		if not ability then
			return nil
		end
		local minTime, minTimeBefore = hugeNumber, hugeNumber
		local spellCountForMinTime, spellCountForMinTimeBefore = nil, nil

		for spellCount, spellCastStartTableEntry in pairs(castTimeTable) do
			local currentTime = spellCastStartTableEntry.castStart
			if ability then
				currentTime = BossUtilities.GetAdjustedStartTime(
					encounterID,
					spellCastStartTableEntry,
					difficulty,
					eventType,
					ability
				)
			end
			if currentTime <= absoluteTime then
				local difference = absoluteTime - currentTime
				if difference < minTime then
					minTime = difference
					spellCountForMinTime = spellCount
				end
			else
				local difference = currentTime - absoluteTime
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
	return nil
end

do
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class TimedAssignment
	local TimedAssignment = Private.classes.TimedAssignment

	---@param absoluteTime number The time from the beginning of the boss encounter.
	---@param encounterID integer Boss dungeon encounter ID.
	---@param preferredAbilities table<integer, PreferredCombatLogEventAbility|nil> Preferred abilities for boss.
	---@param phases table<integer, BossPhase> Boss phases.
	---@param orderedBossPhaseTable table<integer, integer> Ordered boss abilities.
	---@param difficulty DifficultyType Encounter difficulty.
	---@return integer|nil spellID
	---@return integer|nil spellCount
	---@return CombatLogEventType|nil eventType
	---@return number|nil leftoverTime
	function BossUtilities.FindNearestPreferredCombatLogEvent(
		absoluteTime,
		encounterID,
		preferredAbilities,
		phases,
		orderedBossPhaseTable,
		difficulty
	)
		local cumulativeTime = 0.0
		local newSpellID, newSpellCount, newEventType, newTime

		local lastPhaseIndex = 1
		for _, phaseIndex in ipairs(orderedBossPhaseTable) do
			local phase = phases[phaseIndex]
			if cumulativeTime + phase.duration > absoluteTime then
				if preferredAbilities[phaseIndex] then
					newSpellID = preferredAbilities[phaseIndex].combatLogEventSpellID
					newEventType = preferredAbilities[phaseIndex].combatLogEventType
					newSpellCount, newTime = BossUtilities.FindNearestSpellCount(
						absoluteTime,
						encounterID,
						newSpellID,
						newEventType,
						difficulty
					)
				end
				break
			end
			cumulativeTime = cumulativeTime + phase.duration
			lastPhaseIndex = phaseIndex
		end
		if not newSpellID and absoluteTime >= cumulativeTime then
			-- Use the last phase index if time is greater than total fight length
			if preferredAbilities[lastPhaseIndex] then
				newSpellID = preferredAbilities[lastPhaseIndex].combatLogEventSpellID
				newEventType = preferredAbilities[lastPhaseIndex].combatLogEventType
				newSpellCount, newTime =
					BossUtilities.FindNearestSpellCount(absoluteTime, encounterID, newSpellID, newEventType, difficulty)
			end
		end
		return newSpellID, newSpellCount, newEventType, newTime
	end

	-- Converts all assignments based on their appearance in the new boss phases.
	---@param plan Plan Plan with assignments to convert.
	---@param oldBoss Boss Old boss.
	---@param newBoss Boss New boss.
	---@param oldDifficulty DifficultyType Old encounter difficulty.
	---@param newDifficulty DifficultyType New encounter difficulty.
	function BossUtilities.ConvertAssignmentsToNewBoss(plan, oldBoss, newBoss, oldDifficulty, newDifficulty)
		local oldEncounterID, newEncounterID = oldBoss.dungeonEncounterID, newBoss.dungeonEncounterID
		local preferredAbilities = BossUtilities.GetBossPreferredCombatLogEventAbilities(newBoss, newDifficulty)
		local phases = BossUtilities.GetBossPhases(newBoss, newDifficulty)
		local orderedBossPhaseTable = BossUtilities.GetOrderedBossPhases(newEncounterID, newDifficulty)
		local absoluteSpellCastTimeTable = BossUtilities.GetAbsoluteSpellCastTimeTable(newEncounterID, newDifficulty)

		for _, assignment in ipairs(plan.assignments) do
			local createTimed = true
			local absoluteTime = assignment.time

			-- Always convert relative time to absolute time for combat log event assignments
			if getmetatable(assignment) == CombatLogEventAssignment then
				absoluteTime = BossUtilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType,
					oldDifficulty
				)
			end
			if preferredAbilities then
				local newSpellID, newSpellCount, newEventType, newTime =
					BossUtilities.FindNearestPreferredCombatLogEvent(
						absoluteTime,
						newEncounterID,
						preferredAbilities,
						phases,
						orderedBossPhaseTable,
						newDifficulty
					)
				if newSpellID and newSpellCount and newEventType and newTime then
					local orderedBossPhaseIndex =
						absoluteSpellCastTimeTable[newSpellID][newSpellCount].bossPhaseOrderIndex
					assignment = CombatLogEventAssignment:New(assignment, true)
					assignment.combatLogEventType = newEventType
					assignment.combatLogEventSpellID = newSpellID
					assignment.spellCount = newSpellCount
					assignment.time = Utilities.Round(newTime, 1)
					assignment.phase = absoluteSpellCastTimeTable[orderedBossPhaseIndex]
					assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
					createTimed = false
				end
			end
			if createTimed then
				assignment = TimedAssignment:New(assignment, true)
				assignment.time = absoluteTime
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

	-- Special case where the ability duration will be up to date, due to being called in
	-- GenerateAbsoluteSpellCastTimeTable.
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
	---@return table<integer, {startTime: number, endTime: number, count: integer, index: integer}>
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
				tbl = s.OrderedBossPhasesHeroic[boss.dungeonEncounterID]
			else
				tbl = s.OrderedBossPhases[boss.dungeonEncounterID]
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
	---@return integer count
	---@return integer index
	---@return number endTime
	local function GetCurrentPhaseCountAndIndex(time)
		for _, tbl in ipairs(phaseCountDurationMap) do
			if tbl.endTime > time and tbl.startTime <= time then
				return tbl.count, tbl.index, tbl.endTime
			end
		end
		return 0, 0, 0.0
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

	local select = select

	---@param spellID integer
	---@param ability BossAbility
	---@param abilityPhase BossAbilityPhase|EventTrigger
	---@param startTime number Cumulative phase start time.
	---@param endTime number Phase end time.
	---@param castCallback fun(spellID: integer, castStart: number, castEnd: number, effectEnd: number)
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
				local castEnd = castStart + (abilityPhase.castTime or ability.castTime)
				local effectEnd = castEnd + (abilityPhase.duration or ability.duration)
				if abilityPhase.signifiesPhaseStart and castIndex == 1 then
					castEnd = min(castEnd, endTime)
					if effectEnd >= endTime then
						local newDuration = endTime - castEnd
						effectEnd = castEnd + newDuration
					end
				end

				local lastUntilEnd = abilityPhase.signifiesPhaseEnd
					or ability.durationLastsUntilEndOfPhase
					or ability.castTimeLastsUntilEndOfPhase
				if lastUntilEnd and castIndex == #abilityPhase.castTimes then
					if castEnd < endTime then
						effectEnd = endTime -- Extend duration until end of phase
					else
						castEnd = endTime -- Clamp cast time to end of phase
					end
				end

				if not abilityPhase.durationExtendsIntoNextPhase then
					castEnd = min(castEnd, endTime)
				end
				if ability.durationLastsUntilEndOfNextPhase then
					local nextPhaseEndTime = select(3, GetCurrentPhaseCountAndIndex(endTime + 1))
					if nextPhaseEndTime > 0.0 then
						effectEnd = nextPhaseEndTime
					else
						effectEnd = endTime
					end
				else
					if not abilityPhase.durationExtendsIntoNextPhase then
						effectEnd = min(effectEnd, endTime)
					end
				end

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
	---@return table<integer, table<integer, SpellCastStartTableEntry>>
	local function GenerateAbsoluteSpellCastTimeTable(boss, orderedBossPhaseTable, difficulty)
		---@type table<integer, table<integer, SpellCastStartTableEntry>>
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
							local lastCastIndex = #bossAbilityPhase.castTimes
							local lastBossAbilityPhaseCastTime = bossAbilityPhase.castTimes[lastCastIndex]
							local timeAfterLastCast = bossPhase.duration - lastBossAbilityPhaseCastTime
							if bossAbilityPhase.duration and bossAbilityPhase.castTime then
								bossAbilityPhase.castTime = min(bossAbility.castTime, max(0, timeAfterLastCast))
								bossAbilityPhase.duration = max(0, timeAfterLastCast - bossAbilityPhase.castTime)
							end

							if bossAbility.durationLastsUntilEndOfPhase then
								bossAbility.duration = max(0, timeAfterLastCast)
							elseif bossAbility.castTimeLastsUntilEndOfPhase then
								bossAbility.castTime = max(0, timeAfterLastCast)
							elseif bossAbility.durationLastsUntilEndOfNextPhase then
								local nextBossPhaseIndex = orderedBossPhaseTable[bossPhaseOrderIndex + 1]
								if nextBossPhaseIndex then
									local nextPhaseDuration = phases[nextBossPhaseIndex].duration
									bossAbility.duration = max(0, timeAfterLastCast + nextPhaseDuration)
								end
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
	---@return table<integer, table<integer, SpellCastStartTableEntry>>
	local function GenerateMaxAbsoluteSpellCastTimeTable(encounterID, difficulty)
		---@type table<integer, table<integer, SpellCastStartTableEntry>>
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
							if phase.minDuration then
								phase.duration = phase.minDuration
							else
								phase.duration = kMinBossPhaseDuration
							end
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
	---@param absoluteSpellCastStartTable table<integer, table<integer, SpellCastStartTableEntry>>
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
			s.OrderedBossPhasesHeroic[encounterID] = GenerateOrderedBossPhaseTable(encounterID, difficulty)
		else
			s.OrderedBossPhases[encounterID] = GenerateOrderedBossPhaseTable(encounterID, difficulty)
		end
		phaseCountDurationMap = GeneratePhaseCountDurationMap(boss, nil, difficulty)
		if difficulty == DifficultyType.Heroic then
			s.AbsoluteSpellCastStartTablesHeroic[encounterID] =
				GenerateAbsoluteSpellCastTimeTable(boss, s.OrderedBossPhasesHeroic[encounterID], difficulty)
			boss.sortedAbilityIDsHeroic = GenerateSortedBossAbilities(s.AbsoluteSpellCastStartTablesHeroic[encounterID])
			boss.abilityInstancesHeroic =
				GenerateBossAbilityInstances(boss, s.OrderedBossPhasesHeroic[encounterID], nil, difficulty)
		else
			s.AbsoluteSpellCastStartTables[encounterID] =
				GenerateAbsoluteSpellCastTimeTable(boss, s.OrderedBossPhases[encounterID], difficulty)
			boss.sortedAbilityIDs = GenerateSortedBossAbilities(s.AbsoluteSpellCastStartTables[encounterID])
			boss.abilityInstances =
				GenerateBossAbilityInstances(boss, s.OrderedBossPhases[encounterID], nil, difficulty)
		end

		wipe(phaseCountDurationMap)
	end

	local sInstanceIDToInstanceBossOrderIndices = {}

	local function GenerateInstanceBossOrder()
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			local dungeonInstanceID = dungeonInstance.instanceID
			if not sInstanceIDToInstanceBossOrderIndices[dungeonInstanceID] then
				sInstanceIDToInstanceBossOrderIndices[dungeonInstanceID] = {}
			end

			---@type SortedDungeonInstanceEntry
			local entry = {
				dungeonInstanceID = dungeonInstance.instanceID,
				name = dungeonInstance.name,
				bosses = {},
				sortedBosses = {},
				isRaid = dungeonInstance.isRaid,
				mapChallengeModeID = dungeonInstance.mapChallengeModeID,
			}

			for index, boss in ipairs(dungeonInstance.bosses) do
				entry.bosses[boss.dungeonEncounterID] = {
					dungeonEncounterID = boss.dungeonEncounterID,
					index = index,
				}
				tinsert(entry.sortedBosses, {
					dungeonEncounterID = boss.dungeonEncounterID,
					index = index,
				})
			end
			tinsert(s.InstanceBossOrder, entry)
		end

		sort(s.InstanceBossOrder, function(a, b)
			if a.isRaid then
				if not b.isRaid then
					return true
				end
			elseif b.isRaid then
				return false
			end

			return a.name < b.name
		end)

		for index, sortedDungeonInstanceEntry in ipairs(s.InstanceBossOrder) do
			local dungeonInstanceID = sortedDungeonInstanceEntry.dungeonInstanceID
			tinsert(sInstanceIDToInstanceBossOrderIndices[dungeonInstanceID], index)
		end
	end

	---@param dungeonInstanceID? integer Dungeon instance ID
	---@return table<integer, SortedDungeonInstanceEntry>
	function BossUtilities.GetInstanceBossOrder(dungeonInstanceID)
		if not dungeonInstanceID then
			return s.InstanceBossOrder
		else
			---@type table<integer, SortedDungeonInstanceEntry>
			local instanceEntries = {}
			for _, index in ipairs(sInstanceIDToInstanceBossOrderIndices[dungeonInstanceID]) do
				tinsert(instanceEntries, s.InstanceBossOrder[index])
			end
			return instanceEntries
		end
	end

	local kMaxBossDuration = Private.constants.kMaxBossDuration

	-- Creates the following tables for all dungeon instance bosses: boss ordering, max, max absolute, and ordered boss
	-- phases, spell cast times, sorted abilities, and ability instances for a boss.
	function BossUtilities.Initialize()
		GenerateInstanceBossOrder()
		for dungeonInstance in BossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				local encounterID = boss.dungeonEncounterID
				if boss.phases then
					BossUtilities.GenerateBossTables(boss, DifficultyType.Mythic)
					s.MaxOrderedBossPhases[encounterID] =
						GenerateMaxOrderedBossPhaseTable(encounterID, kMaxBossDuration, DifficultyType.Mythic)
					s.MaxAbsoluteSpellCastStartTables[encounterID] =
						GenerateMaxAbsoluteSpellCastTimeTable(encounterID, DifficultyType.Mythic)
				end
				if boss.phasesHeroic then
					BossUtilities.GenerateBossTables(boss, DifficultyType.Heroic)
					s.MaxOrderedBossPhasesHeroic[encounterID] =
						GenerateMaxOrderedBossPhaseTable(encounterID, kMaxBossDuration, DifficultyType.Heroic)
					s.MaxAbsoluteSpellCastStartTablesHeroic[encounterID] =
						GenerateMaxAbsoluteSpellCastTimeTable(encounterID, DifficultyType.Heroic)
				end
			end
		end
	end

	--@debug@
	---@param map table<integer, {startTime: number, endTime: number, count: integer, index: integer}>
	Private.testReferences.SetPhaseCountDurationMap = function(map)
		phaseCountDurationMap = map
	end
	Private.testReferences.GeneratePhaseCountDurationMap = GeneratePhaseCountDurationMap
	Private.testReferences.GenerateBossAbilityInstances = GenerateBossAbilityInstances
	--@end-debug@
end
