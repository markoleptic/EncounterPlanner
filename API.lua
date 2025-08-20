local _, Namespace = ...

---@class Private
local Private = Namespace

---@class Utilities
local utilities = Private.utilities
local SplitStringTableByWhiteSpace = utilities.SplitStringTableByWhiteSpace

local join = string.join
local tinsert = table.insert
local unpack = unpack

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
	---| "ExternalTextSynced" Executed after receiving external text from the group leader, or after sending external text if the group leader.

	---@alias ExternalTextSyncedCallback fun(callbackName: "ExternalTextSynced")

	---@alias CallbackSignature
	---| ExternalTextSyncedCallback

	-- Registers a callback function for the given callback name. Throws an error if parameters are invalid.
	---@param callbackName CallbackName The name of the callback to register. Must be a valid callback name.
	---@param target table The object to associate the callback with.
	---@param callbackFunction string | CallbackSignature Either a method name on `target` or a direct function to be called.
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
