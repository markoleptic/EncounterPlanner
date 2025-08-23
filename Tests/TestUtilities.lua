local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class TestUtilities
Private.testUtilities = {}

---@class TestUtilities
local TestUtilities = Private.testUtilities

do
	local ipairs = ipairs
	local pairs = pairs
	local print = print
	local tinsert = table.insert
	local tostring = tostring
	local type = type

	local currentTestName = ""
	local currentTotalComparisons = 0
	local currentPassedComparisons = 0
	local currentFailedComparisons = 0
	local currentFailedComparisonsContexts = {}

	local totalTests = 0
	local totalPassed = 0
	local totalFailed = 0
	local totalComparisons = 0
	local testFailures = {} ---@type table<string, table<integer, string>>

	function TestUtilities.Reset()
		currentTestName = ""
		currentTotalComparisons = 0
		currentPassedComparisons = 0
		currentFailedComparisons = 0
		currentFailedComparisonsContexts = {}

		totalTests = 0
		totalPassed = 0
		totalFailed = 0
		totalComparisons = 0
		testFailures = {}
	end

	function TestUtilities.ResetCurrent()
		totalTests = totalTests + 1
		if currentPassedComparisons == currentTotalComparisons then
			totalPassed = totalPassed + 1
		else
			totalFailed = totalFailed + 1
			testFailures[currentTestName] = {}
			for _, failed in ipairs(currentFailedComparisonsContexts) do
				tinsert(testFailures[currentTestName], failed)
			end
		end
		totalComparisons = totalComparisons + currentTotalComparisons
		currentTestName = ""
		currentTotalComparisons = 0
		currentPassedComparisons = 0
		currentFailedComparisons = 0
		currentFailedComparisonsContexts = {}
	end

	---@param name string
	function TestUtilities.SetCurrentTest(name)
		currentTestName = name
	end

	function TestUtilities.PrintResults()
		print(
			format(
				"%s: Tests Passed: %d/%d - Comparisons Made: %d",
				AddOnName,
				totalPassed,
				totalTests,
				totalComparisons
			)
		)
		for testName, contexts in pairs(testFailures) do
			print(testName .. ": " .. #contexts .. " failures")
			for _, context in pairs(contexts) do
				print("    " .. context)
			end
		end
	end

	---@param inTable any
	---@return table<any, boolean>
	function TestUtilities.CreateValuesTable(inTable)
		local returnTable = {}
		for _, v in pairs(inTable) do
			returnTable[v] = true
		end
		return returnTable
	end

	---@param t1 any
	---@param t2 any
	---@return boolean, string?
	local function TestEqualTable(t1, t2)
		if type(t1) == "table" and type(t2) == "table" then
			for k, v in pairs(t1) do
				if k ~= "__index" and k ~= "uniqueID" then -- Ignore metatables
					local equal, err = TestEqualTable(v, t2[k])
					if not equal then
						return false, "Mismatch at key '" .. tostring(k) .. "': " .. err
					end
				end
			end
			for k, _ in pairs(t2) do
				if k ~= "__index" then -- Ignore metatables
					if t1[k] == nil then
						return false, tostring(t1[k]) .. " has no matching value"
					end
				end
			end
		else
			if t1 == t2 then
				return true
			else
				return false, tostring(t1) .. " ~= " .. tostring(t2)
			end
		end
		return true
	end

	---@param first any
	---@param second any
	---@param context string|number
	function TestUtilities.TestEqual(first, second, context)
		currentTotalComparisons = currentTotalComparisons + 1
		if type(first) == "table" and type(second) == "table" then
			local result, contextString = TestEqualTable(first, second)
			local result2, contextString2 = TestEqualTable(second, first)
			if result == true and result2 == true then
				currentPassedComparisons = currentPassedComparisons + 1
			else
				if not result then
					tinsert(currentFailedComparisonsContexts, tostring(context) .. ": " .. contextString)
					currentFailedComparisons = currentFailedComparisons + 1
				else
					tinsert(currentFailedComparisonsContexts, tostring(context) .. ": " .. contextString2)
					currentFailedComparisons = currentFailedComparisons + 1
				end
			end
		else
			if first == second then
				currentPassedComparisons = currentPassedComparisons + 1
			else
				tinsert(
					currentFailedComparisonsContexts,
					tostring(context) .. ": " .. tostring(first) .. " != " .. tostring(second)
				)
				currentFailedComparisons = currentFailedComparisons + 1
			end
		end
	end

	---@param first any
	---@param second any
	---@param context string|number
	function TestUtilities.TestNotEqual(first, second, context)
		currentTotalComparisons = currentTotalComparisons + 1
		if first ~= second then
			currentPassedComparisons = currentPassedComparisons + 1
		else
			tinsert(
				currentFailedComparisonsContexts,
				tostring(context) .. ": " .. tostring(first) .. " == " .. tostring(second)
			)
			currentFailedComparisons = currentFailedComparisons + 1
		end
	end

	---@param lookupTable table
	---@param key string
	---@param values table<any, boolean>
	function TestUtilities.TestContains(lookupTable, key, values)
		for _, entry in pairs(lookupTable) do
			if entry[key] then
				if values[entry[key]] then
					currentTotalComparisons = currentTotalComparisons + 1
					currentPassedComparisons = currentPassedComparisons + 1
					values[entry[key]] = nil
				end
			end
		end
		for value, _ in pairs(values) do
			currentTotalComparisons = currentTotalComparisons + 1
			currentFailedComparisons = currentFailedComparisons + 1
			tinsert(currentFailedComparisonsContexts, tostring(value) .. " not found in lookupTable.")
		end
	end

	---@param textTable table<integer, string>
	---@return table<integer, string>
	function TestUtilities.RemoveTabs(textTable)
		for i, str in ipairs(textTable) do
			textTable[i] = str:trim()
		end
		return textTable
	end

	---@class Utilities
	local utilities = Private.utilities
	local CreatePlan = utilities.CreatePlan

	---@class BossUtilities
	local bossUtilities = Private.bossUtilities

	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class TimedAssignment
	local TimedAssignment = Private.classes.TimedAssignment

	local DifficultyType = Private.classes.DifficultyType

	local floor = math.floor
	local GetSpellName = C_Spell.GetSpellName
	local random = math.random
	local EJ_GetEncounterInfo, EJ_SelectEncounter = EJ_GetEncounterInfo, EJ_SelectEncounter
	local EJ_SelectInstance = EJ_SelectInstance

	---@param profile DefaultProfile
	function TestUtilities.CreateTestPlans(profile)
		for k, _ in pairs(profile.plans) do
			if k:find("-Test") then
				profile.plans[k] = nil
			end
		end
		local testPlans = {}
		local name, entry = utilities.CreateRosterEntryForSelf()
		-- cSpell:disable
		local textTable = {
			"Test Start",
			"|cff006fdcMajablast|r  |cfffe7b09Skorke|r  |cfff38bb9Berlinnetti|r  |cff00fe97Dogpog|r",
			"Test End",
		}
		-- cSpell:enable

		for dungeonInstance in bossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				EJ_SelectInstance(dungeonInstance.journalInstanceID)
				EJ_SelectEncounter(boss.journalEncounterID)
				local encounterName = EJ_GetEncounterInfo(boss.journalEncounterID)
				for difficultyName, difficulty in pairs(Private.classes.DifficultyType) do
					if
						(boss.phases and difficulty == DifficultyType.Mythic)
						or (boss.phasesHeroic and difficulty == DifficultyType.Heroic)
					then
						local planName = encounterName .. "-" .. difficultyName .. "-Test"
						local plan = CreatePlan(testPlans, planName, boss.dungeonEncounterID, difficulty)
						plan.roster[name] = entry
						plan.content = textTable
						local instances =
							bossUtilities.GetBossAbilityInstances(boss.dungeonEncounterID, plan.difficulty)
						local bossAbilities = bossUtilities.GetBossAbilities(boss, plan.difficulty)
						---@cast instances table<integer, BossAbilityInstance>
						for _, abilityInstance in ipairs(instances) do
							local types = bossAbilities[abilityInstance.bossAbilitySpellID].allowedCombatLogEventTypes
							if #types > 0 then
								local allowedType = types[random(1, #types)]
								local assignment = CombatLogEventAssignment:New()
								assignment.assignee = name
								assignment.combatLogEventSpellID = abilityInstance.bossAbilitySpellID
								assignment.phase = abilityInstance.bossPhaseIndex
								assignment.bossPhaseOrderIndex = abilityInstance.bossAbilityOrderIndex
								assignment.combatLogEventType = allowedType
								assignment.spellCount = abilityInstance.spellCount
								assignment.time = 8.00
								assignment.spellID = 1
								assignment.text = GetSpellName(abilityInstance.bossAbilitySpellID)
								tinsert(plan.assignments, assignment)
							end
						end
						local _, d = bossUtilities.GetTotalDurations(boss.dungeonEncounterID, plan.difficulty)
						do
							local assignment = Private.classes.TimedAssignment:New()
							assignment.assignee = name
							assignment.time = 0
							assignment.spellID = 1
							assignment.text = "Timed " .. 0
							tinsert(plan.assignments, assignment)
						end
						for i = 5, floor(d * 0.6), 30 do
							local assignment = Private.classes.TimedAssignment:New()
							assignment.assignee = name
							assignment.time = i
							assignment.spellID = 1
							assignment.text = "Timed " .. i
							tinsert(plan.assignments, assignment)
						end
						testPlans[plan.name] = plan
					end
				end
			end
		end
		for _, testPlan in pairs(testPlans) do
			if not profile.plans[testPlan.name] then
				profile.plans[testPlan.name] = testPlan
			end
		end
	end
end
