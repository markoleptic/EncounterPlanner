local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class TestUtilities
local testUtilities = Private.testUtilities

---@class Tests
local tests = Private.tests

---@class TestRunner
Private.testRunner = {}

---@class TestRunner
local TestRunner = Private.testRunner

local pairs = pairs
local type = type

function TestRunner.RunTests()
	for _, test in pairs(tests) do
		if type(test) == "function" then
			testUtilities.SetCurrentTest(test())
			testUtilities.ResetCurrent()
		end
	end
	testUtilities.PrintResults()
	testUtilities.Reset()
end
