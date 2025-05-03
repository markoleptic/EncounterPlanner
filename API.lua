local _, Namespace = ...

---@class Private
local Private = Namespace

---@class Utilities
local utilities = Private.utilities
local SplitStringIntoTable = utilities.SplitStringIntoTable

local ipairs = ipairs
local join = string.join
local tinsert = table.insert
local unpack = unpack

---@param strTable table<integer, string>
---@return table<integer, table<integer, string>>
local function SplitStringTableByWhiteSpace(strTable)
	local returnTable = {}
	for index, line in ipairs(strTable) do
		returnTable[index] = {}
		for word in line:gmatch("%S+") do
			tinsert(returnTable[index], word)
		end
	end
	return returnTable
end

-- Public facing API.
---@class EncounterPlannerAPI
local API = {}

-- Retrieve the synced external text as a string. The text is set on encounter start by sending an addon message to all
-- raid members with the leader's external text from their "Designated External Plan" for the current boss. The text
-- will be the same for all raid members with Encounter Planner installed.
---@return string -- The current external text as a string, including newlines and spaces.
---[Documentation](https://github.com/markoleptic/EncounterPlanner/wiki/API#getexternaltextasstring)
function API.GetExternalTextAsString()
	local profile = Private.addOn.db.profile ---@type DefaultProfile
	return join("\n", unpack(profile.activeText))
end

-- Retrieve the synced external text as a table. The text is set on encounter start by sending an addon message to all
-- raid members with the leader's external text from their "Designated External Plan" for the current boss. The text
-- will be the same for all raid members with Encounter Planner installed.
---@return table<integer, table<integer, string>> -- The current external text in a table format, where each word from each line is an entry in the table (table[RowNumber][WordNumber]).
---[Documentation](https://github.com/markoleptic/EncounterPlanner/wiki/API#getexternaltextastable)
function API.GetExternalTextAsTable()
	local profile = Private.addOn.db.profile ---@type DefaultProfile
	return SplitStringTableByWhiteSpace(profile.activeText)
end

do
	local error = error
	local format = string.format
	local geterrorhandler = geterrorhandler
	local pairs = pairs
	local type = type
	local xpcall = xpcall
	local concat = table.concat
	local callbacks = {} ---@type table<CallbackName, table<table, string|fun(callbackName: CallbackName, ...: any)>>
	local validCallbackNames = { ["ExternalTextSynced"] = true } ---@type table<CallbackName, boolean>
	local errorLevel = 2
	local validCallbackNamesString = ""

	do
		local names = {}
		for callbackName, _ in pairs(validCallbackNames) do
			callbacks[callbackName] = {}
			tinsert(names, callbackName)
		end
		validCallbackNamesString = concat(names, "|")
	end

	---@param func fun(callbackName: CallbackName, ...: any)
	---@param ... any
	---@return boolean success
	---@return any result
	local function SafeCall(func, ...)
		if func then
			return xpcall(func, geterrorhandler(), ...)
		end
		return true
	end

	---@param functionName string
	---@param parameterName string
	---@param actualType string
	---@param expectedType string
	---@return string
	local function FormatError(functionName, parameterName, actualType, expectedType)
		return format("%s Usage: '%s' was '%s', expected '%s'.", functionName, parameterName, actualType, expectedType)
	end

	---@alias CallbackName
	---| "ExternalTextSynced"

	-- Registers a callback function for the given callback name. Throws an error if parameters are invalid.
	---@param callbackName CallbackName The name of the callback to register. Must be a valid callback name.
	---@param target table The object to associate the callback with.
	---@param callbackFunction string|fun(callbackName: CallbackName, ...: any) Either a method name on `target` or a direct function to be called.
	---[Documentation](https://github.com/markoleptic/EncounterPlanner/wiki/API#registercallback)
	function API.RegisterCallback(callbackName, target, callbackFunction)
		local callbackNameType = type(callbackName)
		local targetType = type(target)
		local callbackFunctionType = type(callbackFunction)
		if callbackNameType ~= "string" then
			error(FormatError("RegisterCallback", "callbackName", callbackNameType, "string"), errorLevel)
			return
		end
		if not validCallbackNames[callbackName] then
			error(FormatError("RegisterCallback", "callbackName", callbackName, validCallbackNamesString), errorLevel)
			return
		end
		if targetType ~= "table" then
			error(FormatError("RegisterCallback", "target", targetType, "table"), errorLevel)
			return
		end
		if callbackFunctionType ~= "string" and callbackFunctionType ~= "function" then
			error(
				FormatError("RegisterCallback", "callbackFunction", callbackFunctionType, "string|function"),
				errorLevel
			)
			return
		end
		if callbackFunctionType == "string" then
			if not target[callbackFunction] then
				error("RegisterCallback Usage: Function must be a member on target when using a string argument.")
				return
			end
		end

		callbacks[callbackName][target] = callbackFunction
	end

	-- Unregisters a previously registered callback.
	---@param callbackName CallbackName The name of the callback to unregister.
	---@param target table The object the callback was registered with.
	---[Documentation](https://github.com/markoleptic/EncounterPlanner/wiki/API#unregistercallback)
	function API.UnregisterCallback(callbackName, target)
		if callbacks[callbackName] and callbacks[callbackName][target] then
			callbacks[callbackName][target] = nil
		end
	end

	---@param callbackName CallbackName
	---@param ... any
	function Private.ExecuteAPICallback(callbackName, ...)
		if callbacks[callbackName] then
			for obj, fun in pairs(callbacks[callbackName]) do
				if type(fun) == "function" then
					SafeCall(fun, callbackName, ...)
				elseif obj and type(fun) == "string" then
					local method = obj[fun]
					if type(method) == "function" then
						SafeCall(method, obj, callbackName, ...)
					end
				end
			end
		end
	end
end

EncounterPlannerAPI = setmetatable({}, { __index = API, __newindex = function() end, __metatable = false })

--@debug@
do
	---@class Test
	local test = Private.test
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	local pcall = pcall
	local RemoveTabs = testUtilities.RemoveTabs
	local seterrorhandler = seterrorhandler
	local TestEqual = testUtilities.TestEqual

	-- cSpell:disable
	do
		local text = [[
            nsdispelstart
            |cff006fdcMajablast|r  |cfffe7b09Skorke|r  |cfff38bb9Berlinnetti|r  |cff00fe97Dogpog|r  
            nsdispelend]]

		function test.ExternalTextDispel()
			local textTable = RemoveTabs(SplitStringIntoTable(text, true))
			TestEqual(#textTable, 3, "Expected number of lines")
			local splitByWhiteSpaceTable = SplitStringTableByWhiteSpace(textTable)

			TestEqual(splitByWhiteSpaceTable[1][1], "nsdispelstart", "First line")
			TestEqual(splitByWhiteSpaceTable[2][1], "|cff006fdcMajablast|r", "Second line first word")
			TestEqual(splitByWhiteSpaceTable[2][2], "|cfffe7b09Skorke|r", "Second line second word")
			TestEqual(splitByWhiteSpaceTable[2][3], "|cfff38bb9Berlinnetti|r", "Second line third word")
			TestEqual(splitByWhiteSpaceTable[2][4], "|cff00fe97Dogpog|r", "Second line fourth word")
			TestEqual(splitByWhiteSpaceTable[3][1], "nsdispelend", "Third line")

			return "ExternalTextDispel"
		end
	end

	do
		local text = [[
            {star} npc:226200    |cfffe7b09Person1|r  Person2 Person3 Person4    
            {circle}  npc:226200 |cff006fdcPerson5|r  Person6 Person7 |cff00fe97Person8|r Person9
        ]]

		function test.ExternalText()
			local textTable = RemoveTabs(SplitStringIntoTable(text, true))
			TestEqual(#textTable, 2, "Expected number of lines")
			local splitByWhiteSpaceTable = SplitStringTableByWhiteSpace(textTable)

			TestEqual(splitByWhiteSpaceTable[1][1], "{star}", "First line, first word")
			TestEqual(splitByWhiteSpaceTable[1][2], "npc:226200", "First line second word")
			TestEqual(splitByWhiteSpaceTable[1][3], "|cfffe7b09Person1|r", "First line third word")
			TestEqual(splitByWhiteSpaceTable[1][4], "Person2", "First line fourth word")
			TestEqual(splitByWhiteSpaceTable[1][5], "Person3", "First line fifth word")
			TestEqual(splitByWhiteSpaceTable[1][6], "Person4", "First line sixth word")

			TestEqual(splitByWhiteSpaceTable[2][1], "{circle}", "Second line, first word")
			TestEqual(splitByWhiteSpaceTable[2][2], "npc:226200", "Second line second word")
			TestEqual(splitByWhiteSpaceTable[2][3], "|cff006fdcPerson5|r", "Second line third word")
			TestEqual(splitByWhiteSpaceTable[2][4], "Person6", "Second line fourth word")
			TestEqual(splitByWhiteSpaceTable[2][5], "Person7", "Second line fifth word")
			TestEqual(splitByWhiteSpaceTable[2][6], "|cff00fe97Person8|r", "Second line sixth word")
			TestEqual(splitByWhiteSpaceTable[2][7], "Person9", "Second line seventh word")

			return "ExternalText"
		end
	end
	-- cSpell:enable

	function test.CallbackFunctions()
		local originalErrorHandler = geterrorhandler()
		seterrorhandler(function() end)

		local called = {}
		local object = {}

		function object:OnExternalTextSyncedWithImplicitSelf(callbackName, ...)
			called = { callbackName, ... }
		end

		do
			EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, "OnExternalTextSyncedWithImplicitSelf")
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)

			TestEqual(type(called), "table", "")
			TestEqual(called[1], "ExternalTextSynced", "First argument correct")
			TestEqual(called[2], "testArg", "Second argument correct")
			TestEqual(called[3], 42, "Third argument correct")

			wipe(called)

			EncounterPlannerAPI.UnregisterCallback("ExternalTextSynced", object)
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)
			TestEqual(called[1], nil, "Callback not executed after unregister")
		end

		function object.OnExternalTextSyncedWithExplicitSelf(self, callbackName, ...)
			called = { callbackName, ... }
		end

		do
			EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, "OnExternalTextSyncedWithExplicitSelf")
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)

			TestEqual(type(called), "table", "")
			TestEqual(called[1], "ExternalTextSynced", "First argument correct")
			TestEqual(called[2], "testArg", "Second argument correct")
			TestEqual(called[3], 42, "Third argument correct")

			wipe(called)

			EncounterPlannerAPI.UnregisterCallback("ExternalTextSynced", object)
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)
			TestEqual(called[1], nil, "Callback not executed after unregister")
		end

		local function OnExternalTextSyncedLocalFunc(callbackName, ...)
			called = { callbackName, ... }
		end

		do
			EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, OnExternalTextSyncedLocalFunc)
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)

			TestEqual(type(called), "table", "")
			TestEqual(called[1], "ExternalTextSynced", "First argument correct")
			TestEqual(called[2], "testArg", "Second argument correct")
			TestEqual(called[3], 42, "Third argument correct")

			wipe(called)

			EncounterPlannerAPI.UnregisterCallback("ExternalTextSynced", object)
			Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)
			TestEqual(called[1], nil, "Callback not executed after unregister")
		end

		seterrorhandler(originalErrorHandler)

		return "CallbackFunctions"
	end

	function test.InvalidRegisterCallbackArguments()
		local originalErrorHandler = geterrorhandler()
		seterrorhandler(function() end)

		local object = {}
		local function CallbackFunction() end

		do
			local _, err = pcall(function()
				---@diagnostic disable-next-line: param-type-mismatch
				EncounterPlannerAPI.RegisterCallback("Invalid", object, CallbackFunction)
			end)
			TestEqual(type(err), "string", "")
			if err then
				local foundInErrMessage = err:find(
					"RegisterCallback Usage: 'callbackName' was 'Invalid', expected 'ExternalTextSynced'."
				) ~= nil
				TestEqual(foundInErrMessage, true, "Invalid callbackName")
			end
		end

		do
			local _, err = pcall(function()
				---@diagnostic disable-next-line: param-type-mismatch
				EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", nil, CallbackFunction)
			end)
			TestEqual(type(err), "string", "")
			if err then
				local foundInErrMessage = err:find("RegisterCallback Usage: 'target' was 'nil', expected 'table'.")
					~= nil
				TestEqual(foundInErrMessage, true, "Invalid target")
			end
		end

		do
			local _, err = pcall(function()
				---@diagnostic disable-next-line: param-type-mismatch
				EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, nil)
			end)
			TestEqual(type(err), "string", "")
			if err then
				local foundInErrMessage = err:find(
					"RegisterCallback Usage: 'callbackFunction' was 'nil', expected 'string|function'."
				) ~= nil
				TestEqual(foundInErrMessage, true, "Invalid callbackFunction")
			end
		end

		do
			local _, err = pcall(function()
				EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, "NonexistentFunction")
			end)
			TestEqual(type(err), "string", "")
			if err then
				local foundInErrMessage = err:find(
					"RegisterCallback Usage: Function must be a member on target when using a string argument."
				) ~= nil
				TestEqual(foundInErrMessage, true, "Missing callbackFunction on target")
			end
		end

		do
			object.CallbackFunction = function() end
			EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, "CallbackFunction")
			object.CallbackFunction = nil
			local _, err = pcall(function()
				Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)
			end)
			TestEqual(err, nil, "No error after setting callback function to nil")
		end

		do
			EncounterPlannerAPI.RegisterCallback("ExternalTextSynced", object, CallbackFunction)
			---@diagnostic disable-next-line: cast-local-type
			CallbackFunction = nil
			local _, err = pcall(function()
				Private.ExecuteAPICallback("ExternalTextSynced", "testArg", 42)
			end)
			TestEqual(err, nil, "No error after setting callback function to nil")
		end

		seterrorhandler(originalErrorHandler)

		return "InvalidRegisterCallbackArguments"
	end
end
--@end-debug@
