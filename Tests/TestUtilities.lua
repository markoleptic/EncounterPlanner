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
	local tinsert = tinsert
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
	---@type table<string, table<integer, string>>
	local testFailures = {}

	function TestUtilities.Reset()
		currentTestName = ""
		currentTotalComparisons = 0
		currentPassedComparisons = 0
		currentFailedComparisons = 0
		currentFailedComparisonsContexts = {}

		totalTests = 0
		totalPassed = 0
		totalFailed = 0
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
		print("Total Tests: ", totalTests)
		print("Total Passed: ", totalPassed)
		print("Total Failed: ", totalFailed)

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
				if k ~= "__index" and k ~= "uniqueID" and type(v) ~= "function" then -- Ignore metatables
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
			print("testing table")
			local result, contextString = TestEqualTable(first, second)
			if result == true then
				currentPassedComparisons = currentPassedComparisons + 1
			else
				tinsert(currentFailedComparisonsContexts, tostring(context) .. ": " .. contextString)
				currentFailedComparisons = currentFailedComparisons + 1
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
end
