local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Utilities
local utilities = Private.utilities
local SplitStringIntoTable = utilities.SplitStringIntoTable

local ipairs = ipairs
local tinsert = tinsert

-- Public facing API.
---@class EncounterPlannerAPI
local EncounterPlannerAPI = {}

---@return string
function EncounterPlannerAPI.GetExternalTextAsString()
	local externalText = Private.addOn.db.profile.activeText
	return externalText
end

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

---@return table<integer, table<integer, string>>
function EncounterPlannerAPI.GetExternalTextAsTable()
	local profile = Private.addOn.db.profile ---@type DefaultProfile
	return SplitStringTableByWhiteSpace(SplitStringIntoTable(profile.activeText))
end

_G["EncounterPlannerAPI"] = EncounterPlannerAPI

do
	---@class Tests
	local tests = Private.tests
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	local TestEqual = testUtilities.TestEqual
	local RemoveTabs = testUtilities.RemoveTabs

	do
		local text = [[
            nsdispelstart
            |cff006fdcMajablast|r  |cfffe7b09Skorke|r  |cfff38bb9Berlinnetti|r  |cff00fe97Dogpog|r  
            nsdispelend
        ]]

		function tests.TestExternalTextDispel()
			local textTable = RemoveTabs(SplitStringIntoTable(text, true))
			TestEqual(#textTable, 3, "Expected number of lines")
			local splitByWhiteSpaceTable = SplitStringTableByWhiteSpace(textTable)

			TestEqual(splitByWhiteSpaceTable[1][1], "nsdispelstart", "First line")
			TestEqual(splitByWhiteSpaceTable[2][1], "|cff006fdcMajablast|r", "Second line first word")
			TestEqual(splitByWhiteSpaceTable[2][2], "|cfffe7b09Skorke|r", "Second line second word")
			TestEqual(splitByWhiteSpaceTable[2][3], "|cfff38bb9Berlinnetti|r", "Second line third word")
			TestEqual(splitByWhiteSpaceTable[2][4], "|cff00fe97Dogpog|r", "Second line fourth word")
			TestEqual(splitByWhiteSpaceTable[3][1], "nsdispelend", "Third line")

			return "TestExternalTextDispel"
		end
	end

	do
		local text = [[
            {star} npc:226200    |cfffe7b09Person1|r  Person2 Person3 Person4    
            {circle}  npc:226200 |cff006fdcPerson5|r  Person6 Person7 |cff00fe97Person8|r Person9
        ]]

		function tests.TestExternalText()
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

			return "TestExternalText"
		end
	end
end
