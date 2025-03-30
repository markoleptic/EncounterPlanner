local _, Namespace = ...

---@class Private
local Private = Namespace

---@class TestUtilities
local testUtilities = Private.testUtilities

---@class Test
local test = Private.test

---@class TestRunner
Private.testRunner = {}

---@class TestRunner
local TestRunner = Private.testRunner

local pairs = pairs
local type = type

function TestRunner.RunTests()
	for _, testFunction in pairs(test) do
		if type(testFunction) == "function" then
			testUtilities.SetCurrentTest(testFunction())
			testUtilities.ResetCurrent()
		end
	end
	testUtilities.PrintResults()
	testUtilities.Reset()
end
