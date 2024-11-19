---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local BossUtilities = Private.bossUtilities

local bosses = Private.bosses
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local type = type

---@param bossNameOrIndex string|integer
---@return BossDefinition|nil
function BossUtilities.GetBossDefinition(bossNameOrIndex)
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
function BossUtilities.GetBossDefinitionIndex(bossName)
	for index, bossDefinition in ipairs(Private.raidInstances["Nerub'ar Palace"].bosses) do
		if bossDefinition.name == bossName then
			return index
		end
	end
	return nil
end

---@param bossName string
---@return Boss|nil
function BossUtilities.GetBoss(bossName)
	local boss = bosses["Nerub'ar Palace"][bossName]
	if boss then
		return boss
	end
	return nil
end

---@param spellID integer
---@return string|nil
function BossUtilities.GetBossNameFromSpellID(spellID)
	for bossName, boss in pairs(bosses["Nerub'ar Palace"]) do
		if boss.abilities[spellID] then
			return bossName
		end
	end
	return nil
end

---@param spellID integer
---@return Boss|nil
function BossUtilities.GetBossFromSpellID(spellID)
	for _, boss in pairs(bosses["Nerub'ar Palace"]) do
		if boss.abilities[spellID] then
			return boss
		end
	end
	return nil
end

---@param bossDefinitionIndex integer
---@return Boss|nil
function BossUtilities.GetBossFromBossDefinitionIndex(bossDefinitionIndex)
	local bossDef = BossUtilities.GetBossDefinition(bossDefinitionIndex)
	if bossDef then
		return bosses["Nerub'ar Palace"][bossDef.name]
	end
	return nil
end

---@param spellID number
---@return BossAbility|nil
function BossUtilities.FindBossAbility(spellID)
	for _, boss in pairs(bosses["Nerub'ar Palace"]) do
		if boss.abilities[spellID] then
			return boss.abilities[spellID]
		end
	end
	return nil
end

-- Accumulates cast times for a boss ability until it reaches spellCount occurances.
---@param ability BossAbility The boss ability to get cast times for.
---@param spellCount integer The spell count/occurance. If the spell is cast 5 times
---@return number, number -- Time from the start of the phase, the phase in which the occurance is located in
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

-- Returns the phase start time from boss pull to the specified phase number and occurance.
---@param boss Boss The boss
---@param bossPhaseTable table<integer, integer> A table of boss phases in the order in which they occur
---@param phaseNumber integer The boss phase number
---@param phaseCount integer? The current phase repeat instance (i.e. 2nd time occuring = 2)
---@return number -- Cumulative start time for a given boss phase and count/occurance
function BossUtilities.GetCumulativePhaseStartTime(boss, bossPhaseTable, phaseNumber, phaseCount)
	if not phaseCount then
		phaseCount = 1
	end
	local cumulativePhaseStartTime = 0
	local phaseNumberOccurances = 0
	for _, currentPhaseNumber in ipairs(bossPhaseTable) do
		if currentPhaseNumber == phaseNumber then
			phaseNumberOccurances = phaseNumberOccurances + 1
		end
		if phaseNumberOccurances == phaseCount then
			break
		end
		cumulativePhaseStartTime = cumulativePhaseStartTime + boss.phases[currentPhaseNumber].duration
	end
	return cumulativePhaseStartTime
end

-- Creates a table of boss phases in the order in which they occur. This is necessary due since phases can repeat.
---@param boss Boss The boss
---@return table<integer, integer> -- Ordered boss phase table
function BossUtilities.CreateBossPhaseTable(boss)
	local totalPhaseOccurances = 0
	local totalTimelineDuration = 0
	for _, phase in pairs(boss.phases) do
		totalTimelineDuration = totalTimelineDuration + (phase.duration * phase.count)
		totalPhaseOccurances = totalPhaseOccurances + phase.count
	end
	local bossPhaseOrder = {}
	local currentPhase = 1
	while #bossPhaseOrder < totalPhaseOccurances and currentPhase ~= nil do
		tinsert(bossPhaseOrder, currentPhase)
		if boss.phases[currentPhase].repeatAfter == nil and boss.phases[currentPhase + 1] then
			currentPhase = currentPhase + 1
		else
			currentPhase = boss.phases[currentPhase].repeatAfter
		end
	end
	return bossPhaseOrder
end
