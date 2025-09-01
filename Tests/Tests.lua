local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants

Private.test = {}
---@class Test
local test = Private.test

---@class TestUtilities
local testUtilities = Private.testUtilities
local CreateValuesTable = testUtilities.CreateValuesTable
local RemoveTabs = testUtilities.RemoveTabs
local TestContains = testUtilities.TestContains
local TestEqual = testUtilities.TestEqual
local TestNotEqual = testUtilities.TestNotEqual

---@class Utilities
local utilities = Private.utilities
local SplitStringIntoTable = utilities.SplitStringIntoTable

local DifficultyType = Private.classes.DifficultyType

local ipairs = ipairs
local pairs = pairs

do
	local SplitStringTableByWhiteSpace = utilities.SplitStringTableByWhiteSpace

	local pcall = pcall
	local seterrorhandler = seterrorhandler

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

do
	---@class BossUtilities
	local bossUtilities = Private.bossUtilities
	local GeneratePhaseCountDurationMap = bossUtilities.GeneratePhaseCountDurationMap

	---@param boss Boss
	---@param difficulty DifficultyType
	local function testSpellCastTimeTablesForBoss(boss, difficulty)
		local encounterID = boss.dungeonEncounterID
		bossUtilities.SetPhaseCountDurationMap(GeneratePhaseCountDurationMap(boss, nil, difficulty))
		local castTimeTable = {}
		local ordered = bossUtilities.GetOrderedBossPhases(encounterID, difficulty)

		bossUtilities.GenerateBossAbilityInstances(boss, ordered, castTimeTable, difficulty)
		for _, spellOccurrenceNumbers in pairs(castTimeTable) do
			sort(spellOccurrenceNumbers)
		end

		---@type table<integer, table<integer, SpellCastStartTableEntry>>
		local absoluteAtEncounterID = bossUtilities.GetAbsoluteSpellCastTimeTable(encounterID, difficulty)

		TestEqual(#absoluteAtEncounterID, #castTimeTable, "Cast Time Table Size Equal")
		for bossAbilitySpellID, spellCount in pairs(absoluteAtEncounterID) do
			for spellOccurrence, castStartAndOrder in ipairs(spellCount) do
				local castStart = castTimeTable[bossAbilitySpellID][spellOccurrence]
				local _, spellName = bossUtilities.GetBossAbilityIconAndLabel(boss, bossAbilitySpellID, difficulty)
				TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal " .. spellName)
			end
		end
		for bossAbilitySpellID, spellCount in pairs(castTimeTable) do
			for spellOccurrence, castStart in ipairs(spellCount) do
				local castStartAndOrder = absoluteAtEncounterID[bossAbilitySpellID][spellOccurrence]
				local _, spellName = bossUtilities.GetBossAbilityIconAndLabel(boss, bossAbilitySpellID, difficulty)
				TestEqual(castStart, castStartAndOrder.castStart, "Cast Time Equal " .. spellName)
			end
		end

		bossUtilities.SetPhaseCountDurationMap({})
	end

	function test.CompareSpellCastTimeTables()
		for dungeonInstance in bossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				if boss.phases then
					testSpellCastTimeTablesForBoss(boss, DifficultyType.Mythic)
				end
				if boss.phasesHeroic then
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
		local maxPhaseCounts =
			bossUtilities.CalculateMaxPhaseCounts(encounterID, constants.kMaxBossDuration, difficulty)
		local validatedPhaseCounts =
			bossUtilities.SetPhaseCounts(encounterID, maxPhaseCounts, constants.kMaxBossDuration, difficulty)
		TestEqual(maxPhaseCounts, validatedPhaseCounts, "Max Phase Counts Equal Validated Phase Counts")

		local maxOrderedPhasesAtEncounterID = bossUtilities.GetMaxOrderedBossPhases(encounterID, difficulty)
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
		for _, phase in ipairs(bossUtilities.GetBossPhases(boss, difficulty)) do
			phase.count = phase.defaultCount
		end
	end

	function test.ValidateMaxPhaseCounts()
		for dungeonInstance in bossUtilities.IterateDungeonInstances() do
			for _, boss in ipairs(dungeonInstance.bosses) do
				if boss.phases then
					testValidatedMaxPhaseCountsForBoss(boss, DifficultyType.Mythic)
				end
				if boss.phasesHeroic then
					testValidatedMaxPhaseCountsForBoss(boss, DifficultyType.Heroic)
				end
			end
		end
		return "ValidateMaxPhaseCounts"
	end

	bossUtilities.GeneratePhaseCountDurationMap = nil
end

do
	---@class Plan
	local Plan = Private.classes.Plan
	local PlanSerializer = Private.PlanSerializer

	local ChangePlanBoss = utilities.ChangePlanBoss
	local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments
	local TableToString = Private.TableToString
	local StringToTable = Private.StringToTable

	do
		-- cSpell:disable
		local text = [[
            {time:0:16,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:1}{spell:442432}|cffAB0E0EDosage Hit|r - Duck {spell:421453}  Brockx {spell:97462}  Majablast {spell:108281}
            {time:0:29,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Sephx {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:46,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Poglizard {spell:359816}
            {time:0:59,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:06,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374968}  Draugmentor {spell:374227}  Gun {spell:77764}  Vodkabro {spell:192077}
            {time:1:13,SCS:442432:1}{spell:442432}|cffAB0E0EDosage Hit|r - Duck {spell:451234}  Stranko {spell:97462}
            {time:1:26,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}
            {time:1:29,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:374968}  Skorke {spell:77764}
            {time:1:59,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:06,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Poglizard {spell:363534}
            {time:2:30,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:30,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - class:Mage {spell:414660}
            {time:2:46,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Poglizard {spell:359816}
            {time:2:52,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Duck {spell:246287}
            {time:2:57,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Vodkabro {spell:114049}
            {time:3:02,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Vodkabro {spell:108280}
            {time:0:16,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Majablast {spell:108281}
            {time:0:26,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:421453}
            {time:0:29,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:59,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:06,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}
            {time:1:06,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374227}  Draugmentor {spell:374968}  Gun {spell:77764}  Vodkabro {spell:192077}
            {time:1:13,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Brockx {spell:97462}  Vodkabro {spell:98008}
            {time:1:29,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:374968}  Skorke {spell:77764}
            {time:2:00,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:03,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:451234}  Stranko {spell:97462}
            {time:2:30,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:46,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Poglizard {spell:359816}
            {time:2:52,SCS:442432:2}{spell:442432}|cff8B4513Ingest Black Blood|r - Duck {spell:246287}  Vodkabro {spell:108280}  class:Mage {spell:414660}
            {time:3:02,SCS:442432:2}{spell:442432}|cff8B4513Ingest Black Blood|r - Poglizard {spell:363534}  Vodkabro {spell:114049}
            {time:0:16,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:3}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:421453}  {everyone} {text}{Personals{/text}
            {time:0:29,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:59,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}
            {time:1:06,SCS:442432:3}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Draugmentor {spell:374227}
            {time:1:06,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374968}  Gun {spell:77764}  Vodkabro {spell:192077}  {everyone} {text}Spread for Webs{/text}
            {time:1:09,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:359816}  Poglizard {spell:374968}  Skorke {spell:77764}
            {time:1:57,SCS:442432:3}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:451234}  Brockx {spell:97462}
            {time:2:26,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:27,SCS:442432:3}{spell:442432}|cffFF6666Volatile Concoction|r - Stranko {spell:97462}
            {time:2:56,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
        ]]
		-- cSpell:enable

		function test.EncodeDecodePlan()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local bossDungeonEncounterID = Private.ParseNote(plan, textTable, true) --[[@as integer]]
			plan.dungeonEncounterID = bossDungeonEncounterID
			ChangePlanBoss({ [plan.name] = plan }, plan.name, plan.dungeonEncounterID, plan.difficulty)
			UpdateRosterFromAssignments(plan.assignments, plan.roster)

			local export = TableToString(PlanSerializer.SerializePlan(plan), false)
			local package = StringToTable(export, false)
			local deserializedPlan = PlanSerializer.DeserializePlan(package --[[@as table]])
			deserializedPlan.isPrimaryPlan = true
			TestEqual(plan, deserializedPlan, "Plan equals serialized plan")

			return "EncodeDecodePlan"
		end
	end

	do
		-- cSpell:disable
		local textTable = {
			"nsdispelstart",
			"|cff006fdcMajablast|r  |cfffe7b09Skorke|r  |cfff38bb9Berlinnetti|r  |cff00fe97Dogpog|r",
			"nsdispelend",
		}
		-- cSpell:enable

		function test.TableToStringToTable()
			local export = TableToString(textTable, false)
			local package = StringToTable(export, false)

			TestEqual(type(package) == "table", true, "Correct type returned from StringToTable")
			TestEqual(package[1], textTable[1], "Conversion string table entry equal")
			TestEqual(package[2], textTable[2], "Conversion string table entry equal")
			TestEqual(package[3], textTable[3], "Conversion string table entry equal")

			return "TableToStringToTable"
		end
	end

	Private.TableToString = nil
	Private.StringToTable = nil
	Private.PlanSerializer = nil
end

do
	local IsVersionLessThan = Private.IsVersionLessThan
	local ParseVersion = Private.ParseVersion

	function test.VersionParsing()
		local major, minor, patch = ParseVersion("")
		TestEqual(major, nil, "major")
		TestEqual(minor, nil, "minor")
		TestEqual(patch, nil, "patch")

		major, minor, patch = ParseVersion("0.9.8")
		TestEqual(major, 0, "major")
		TestEqual(minor, 9, "minor")
		TestEqual(patch, 8, "patch")

		local lessThan = IsVersionLessThan(major, minor, patch, 0, 9, 9)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 0, 10, 8)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 1, 9, 8)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 0, 9, 8)
		TestEqual(lessThan, false, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 0, 8, 8)
		TestEqual(lessThan, false, "version compare")

		major, minor, patch = ParseVersion("18.19.81")
		TestEqual(major, 18, "major")
		TestEqual(minor, 19, "minor")
		TestEqual(patch, 81, "patch")

		lessThan = IsVersionLessThan(major, minor, patch, 18, 19, 82)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 18, 20, 81)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 19, 19, 81)
		TestEqual(lessThan, true, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 18, 19, 80)
		TestEqual(lessThan, false, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 18, 18, 81)
		TestEqual(lessThan, false, "version compare")
		lessThan = IsVersionLessThan(major, minor, patch, 17, 19, 81)
		TestEqual(lessThan, false, "version compare")

		major, minor, patch = ParseVersion("18.1.81")
		TestEqual(major, 18, "major")
		TestEqual(minor, 1, "minor")
		TestEqual(patch, 81, "patch")

		major, minor, patch = ParseVersion("18.19.8")
		TestEqual(major, 18, "major")
		TestEqual(minor, 19, "minor")
		TestEqual(patch, 8, "patch")

		return "VersionParsing"
	end

	Private.IsVersionLessThan = nil
	Private.ParseVersion = nil
end

do
	---@class Plan
	local Plan = Private.classes.Plan

	local ParseNote = Private.ParseNote

	do
		local text = [[
            {time:75}Markoleptic {spell:235450}
            {time:85}-Markoleptic {spell:235450}
            {time:95} -Markoleptic {spell:235450}
            {time:105}- Markoleptic {spell:235450}
            {time:115} - Markoleptic {spell:235450}
            {time:125}Random Text-Markoleptic {spell:235450}
            {time:135}Random Text -Markoleptic {spell:235450}
            {time:145}Random Text- Markoleptic {spell:235450}
            {time:145}Random Text - Markoleptic {spell:235450}
            {time:155}-Markoleptic-Bleeding Hollow {spell:235450}
            {time:165} -Markoleptic-Bleeding Hollow {spell:235450}
            {time:175}- Markoleptic-Bleeding Hollow {spell:235450}
            {time:185} - Markoleptic-Bleeding Hollow {spell:235450}
            {time:195}Random Text-Markoleptic-Bleeding Hollow {spell:235450}
            {time:205}Random Text -Markoleptic-Bleeding Hollow {spell:235450}
            {time:215}Random Text- Markoleptic-Bleeding Hollow {spell:235450}
            {time:225}Random Text - Markoleptic-Bleeding Hollow {spell:235450}
        ]]

		function test.DashParsing()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local actualAssignmentCount, expectedAssignmentCount = 0, 17

			for _, entry in ipairs(textTable) do
				ParseNote(plan, { entry }, true)
				for _, assignment in ipairs(plan.assignments) do
					TestEqual(assignment.assignee, "Markoleptic", entry)
					actualAssignmentCount = actualAssignmentCount + 1
				end
			end
			TestEqual(actualAssignmentCount, expectedAssignmentCount, "Expected Assignment Count")

			return "DashParsing"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic {spell:235450}
            {time:10} Markoleptic {spell:}
            {time:15} Markoleptic {spell:a}
        ]]

		function test.SpellParsing()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			ParseNote(plan, textTable, true)

			TestEqual(plan.assignments[1].spellID, 235450, textTable[1])
			TestEqual(plan.assignments[2].spellID, 0, textTable[2])
			TestEqual(plan.assignments[3].spellID, 0, textTable[3])

			return "SpellParsing"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic {text}Yo{/text}
            {time:10} Markoleptic {text} Y o {/text}
            {time:15} Markoleptic {text}|cff3ec6ea Yo |r{/text}
            {time:20} Markoleptic {text}Use Healthstone {6262}{/text}
            {time:25} Markoleptic {spell:235450}{text}Use Healthstone {6262}{/text}
            {time:30} Markoleptic {text}Use Healthstone {6262}{/text}{spell:235450}
        ]]

		function test.TextParsing()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			ParseNote(plan, textTable, true)

			TestEqual(plan.assignments[1].text, "Yo", textTable[1])
			TestEqual(plan.assignments[2].text, "Y o", textTable[2])
			TestEqual(plan.assignments[3].text, "|cff3ec6ea Yo |r", textTable[3])
			TestEqual(plan.assignments[4].text, "Use Healthstone {6262}", textTable[4])

			TestEqual(plan.assignments[5].text, "Use Healthstone {6262}", textTable[5])
			TestEqual(plan.assignments[5].spellID, 235450, textTable[5])

			TestEqual(plan.assignments[6].text, "Use Healthstone {6262}", textTable[6])
			TestEqual(plan.assignments[6].spellID, 235450, textTable[6])

			return "TextParsing"
		end
	end

	do
		-- cSpell:disable
		local textOne = [[
            {time:0:27} - Ãsunä {spell:51052}
        ]]
		local textTwo = [[
            {time:0:23,SAA:1223364:3}{spell:1223364}Powered Automaton - |cffc41e3aÃsunä|r {spell:51052}
        ]]
		-- cSpell:enable

		function test.SpecialCharacterParsing()
			local plan = Plan:New({}, "Test")
			ParseNote(plan, RemoveTabs(SplitStringIntoTable(textOne)), true)
			-- cSpell:disable-next-line
			TestContains(plan.assignments, "assignee", { ["Ãsunä"] = true })

			plan = Plan:New({}, "Test")
			ParseNote(plan, RemoveTabs(SplitStringIntoTable(textTwo)), true)
			-- cSpell:disable-next-line
			TestContains(plan.assignments, "assignee", { ["Ãsunä"] = true })

			return "SpecialCharacterParsing"
		end
	end

	do
		local text = [[
            {time:1} Markoleptic {spell:235450}
            {time:0:05} Markoleptic {spell:235450}
            {time:01:10} Markoleptic {spell:235450}
            {time:15,SCS:450483:1} Markoleptic {spell:235450}
            {time:0:25,SCC:450483:2} Markoleptic {spell:235450}
            {time:0:35,SAA:450483:2} Markoleptic {spell:235450}
            {time:45,SAR:450483:2} Markoleptic {spell:235450}
        ]]

		function test.TimeParsing()
			local plan = Plan:New({}, "Test")
			ParseNote(plan, RemoveTabs(SplitStringIntoTable(text)), true)

			local valuesTable = CreateValuesTable({ 1, 5, 70, 15, 25, 35, 45 })
			TestContains(plan.assignments, "time", valuesTable)

			return "TimeParsing"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic @Markoleptic {spell:235450}
            {time:10} Markoleptic@Markoleptic {spell:235450}
            {time:15} Markoleptic@ Markoleptic {spell:235450}
        ]]

		function test.TargetParsing()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local actualAssignmentCount, expectedAssignmentCount = 0, 3

			for _, entry in ipairs(textTable) do
				ParseNote(plan, { entry }, true)
				for _, assignment in ipairs(plan.assignments) do
					TestEqual(assignment.assignee, "Markoleptic", entry)
					TestEqual(assignment.targetName, "Markoleptic", entry)
					actualAssignmentCount = actualAssignmentCount + 1
				end
			end
			TestEqual(actualAssignmentCount, expectedAssignmentCount, "Expected Assignment Count")

			return "TargetParsing"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic {spell:235450}
            {time:10} class:Mage {spell:235450}
            {time:15} role:damager {spell:235450}
            {time:20} role:healer {spell:235450}
            {time:25} role:tank {spell:235450}
            {time:30} group:1 {spell:235450}
            {time:35} group:2 {spell:235450}
            {time:40} group:3 {spell:235450}
            {time:45} group:4 {spell:235450}
            {time:55} spec:62 {spell:235450}
            {time:50} spec:fire {spell:235450}
            {time:60} type:ranged {spell:235450}
            {time:65} type:melee {spell:235450}]]

		function test.AssignmentUnits()
			local plan = Plan:New({}, "Test")
			ParseNote(plan, RemoveTabs(SplitStringIntoTable(text)), true)
			local valuesTable = CreateValuesTable({
				"Markoleptic",
				"class:Mage",
				"role:damager",
				"role:damager",
				"role:healer",
				"role:tank",
				"group:1",
				"group:2",
				"group:3",
				"group:4",
				"spec:62",
				"spec:63",
				"type:ranged",
				"type:melee",
			})
			TestContains(plan.assignments, "assignee", valuesTable)

			return "AssignmentUnits"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic, Idk, Dk {spell:235450}
            {time:10} Markoleptic, class:Mage,role:damager {spell:235450}
            {time:15} Markoleptic, group:1,spec:62, type:ranged {spell:235450}
            {time:20} Markoleptic@Idk, Idk@Markoleptic {spell:235450}
            {time:25} Markoleptic @Idk, Idk@ Markoleptic {spell:235450}
        ]]

		function test.MultiValuedAssignmentUnits()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			ParseNote(plan, textTable, true)

			TestEqual(plan.assignments[1].assignee, "Markoleptic", textTable[1])
			TestEqual(plan.assignments[2].assignee, "Idk", textTable[1])
			TestEqual(plan.assignments[3].assignee, "Dk", textTable[1])

			TestEqual(plan.assignments[4].assignee, "Markoleptic", textTable[3])
			TestEqual(plan.assignments[5].assignee, "class:Mage", textTable[3])
			TestEqual(plan.assignments[6].assignee, "role:damager", textTable[3])

			TestEqual(plan.assignments[7].assignee, "Markoleptic", textTable[3])
			TestEqual(plan.assignments[8].assignee, "group:1", textTable[3])
			TestEqual(plan.assignments[9].assignee, "spec:62", textTable[3])
			TestEqual(plan.assignments[10].assignee, "type:ranged", textTable[3])

			TestEqual(plan.assignments[11].assignee, "Markoleptic", textTable[4])
			TestEqual(plan.assignments[11].targetName, "Idk", textTable[4])
			TestEqual(plan.assignments[12].assignee, "Idk", textTable[4])
			TestEqual(plan.assignments[12].targetName, "Markoleptic", textTable[4])

			TestEqual(plan.assignments[13].assignee, "Markoleptic", textTable[5])
			TestEqual(plan.assignments[13].targetName, "Idk", textTable[5])
			TestEqual(plan.assignments[14].assignee, "Idk", textTable[5])
			TestEqual(plan.assignments[14].targetName, "Markoleptic", textTable[5])

			return "MultiValuedAssignmentUnits"
		end
	end

	do
		local text = [[
            {time:5} Markoleptic {spell:235450}  Idk {spell:196718}  Dk,Mans {spell:51052}
            {time:10} Markoleptic@Idk {spell:235450}  Idk@ Markoleptic {spell:196718}
            {time:15} group:1 {text}Yo{/text}  type:ranged {text}Yo 2{/text}
        ]]

		function test.MultipleAssignmentsPerRow()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			ParseNote(plan, textTable, true)

			local valuesTable = CreateValuesTable({
				"Markoleptic",
				"Idk",
				"Dk",
				"Mans",
				"group:1",
				"type:ranged",
			})
			TestContains(plan.assignments, "assignee", valuesTable)
			valuesTable = CreateValuesTable({
				"Markoleptic",
				"Idk",
			})
			TestContains(plan.assignments, "targetName", valuesTable)
			TestEqual(#plan.assignments, 8, "Expected number of assignments")

			return "MultipleAssignmentsPerRow"
		end
	end
	do
		-- cSpell:disable
		local text = [[
            nsnovastart
            ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r
            ||cff33937fDraugmentor||r  ||cfffefefeReduckted||r  ||cff3ec6eaMarkoleptic||r  ||cffa9d271Orcodontist||r 
            ||cffc31d39Hobyrim||r  ||cffc31d39Xonj||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r  
            ||cffa9d271Orcodontist||r  ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r  ||cfffe7b09Skorke||r   
            ||cfffe7b09Gun||r  ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r   
            ||cff00fe97Dogpog||r  ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff3ec6eaSeansmage||r
            ||cfffe7b09Skorke||r  ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r  ||cff3ec6eaMarkoleptic||r
            ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Gun||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r
            nsnovaend
            {time:5} Markoleptic {spell:235450}
            stuff
            {time:10,SCC:435136:1} Markoleptic {spell:235450}
            stuff 2
            {time:15,SCC:435136:1} Markoleptic {spell:235450}
            {time:20,SCC:444497:1} Markoleptic,group:1,spec:62,type:ranged {spell:235450}
            BLUE LEFT:|cfffff468Gørø|r |cffc41e3aHobyrim|r |cfffff468Shiryon|r |cfff48cbaSarys|r |cffc69b6dStranko|r 
            BLUE RIGHT:|cffff7c0aGun|r |cff0070ddVodkabro|r |cff3fc7ebReduts|r |cff3fc7ebMarkoleptic|r  
            RED LEFT: |cffaad372Orcodontist|r  |cfff48cbaPogdog|r |cffc69b6dBrockx|r |cff00ff98Dogpog|r
            REDRIGHT: |cffff7c0aSkorke|r |cff33937fDraugmentor|r |cff0070ddMajablas|r|cff0070ddt|r |cff8788eeArchidell
        ]]
		-- cSpell:enable

		function test.ImportNonAssignmentText()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			ParseNote(plan, textTable, true)

			TestEqual(#plan.assignments, 7, "Correct number of assignments")
			for i = 1, 10 do
				TestEqual(textTable[i], plan.content[i], format("Matching content row %d %d", i, i))
			end
			TestEqual(textTable[12], plan.content[11], format("Matching content row %d %d", 12, 11))
			TestEqual(textTable[14], plan.content[12], format("Matching content row %d %d", 14, 12))
			for i = 17, 20 do
				TestEqual(textTable[i], plan.content[i - 4], format("Matching content row %d %d", i, i - 4))
			end

			return "ImportNonAssignmentText"
		end
	end

	do
		---@class TimedAssignment
		local TimedAssignment = Private.classes.TimedAssignment

		local text = [[
            {time:5,SCC:435136:1} Markoleptic {spell:235450}
            {time:10,SCC:435136:1} Markoleptic {spell:235450}
            {time:15,SCC:435136:1} Markoleptic {spell:235450}
            {time:20,SCC:444497:1} Markoleptic,group:1,spec:62,type:ranged {spell:235450}
        ]]

		function test.BossParsing()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local bossDungeonEncounterID = ParseNote(plan, textTable, true)

			TestEqual(bossDungeonEncounterID, 2917, "Correct boss dungeon encounter ID")
			for i = 1, 3 do
				---@diagnostic disable-next-line: undefined-field
				TestEqual(plan.assignments[i].combatLogEventType, nil, "Combat log event type removed")
				---@diagnostic disable-next-line: undefined-field
				TestEqual(plan.assignments[i].combatLogEventSpellID, nil, "Combat log event spell ID removed")
				---@diagnostic disable-next-line: undefined-field
				TestEqual(plan.assignments[i].spellCount, nil, "Spell count removed")
				---@diagnostic disable-next-line: undefined-field
				TestEqual(plan.assignments[i].phase, nil, "Phase removed")
				---@diagnostic disable-next-line: undefined-field
				TestEqual(plan.assignments[i].bossPhaseOrderIndex, nil, "Boss phase order index removed")
				TestEqual(getmetatable(plan.assignments[i]), TimedAssignment, "Correct meta table")
			end

			return "BossParsing"
		end
	end

	do
		local ChangePlanBoss = utilities.ChangePlanBoss
		local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments

		local text = [[
            {time:0:00} - Idk,Markoleptic @Markoleptic {spell:235450}
            {time:0:05,SCS:435136:1}{spell:435136}Venomous Lash - Dk,Markoleptic {spell:235450}
            {time:0:10,SCC:435136:2}{spell:435136}Venomous Lash - Markoleptic,type:Ranged {spell:235450} {text}Use Healthstone {6262}{/text}  spec:Fire {spell:235450}
            {time:0:15,SAA:435136:2}{spell:435136}Venomous Lash - Markoleptic,class:Mage,role:damager {text}Use Healthstone {6262}{/text}
            {time:0:20,SAR:445123:2}{spell:445123}Hulking Crash - Markoleptic,group:1,spec:Arcane {spell:235450} {text}Use Healthstone {6262}{/text}
            BLUE LEFT:Person Person2
            BLUE RIGHT:Person3 Person4
            RED LEFT:Person5 Person6
            RED RIGHT:Person7 Person8
        ]]

		function test.Export()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local bossDungeonEncounterID = ParseNote(plan, textTable, true) --[[@as integer]]
			plan.dungeonEncounterID = bossDungeonEncounterID or bossDungeonEncounterID
			ChangePlanBoss({ plan }, plan.name, plan.dungeonEncounterID, plan.difficulty)
			UpdateRosterFromAssignments(plan.assignments, plan.roster)

			local exportString = Private:ExportPlanToNote(plan, bossDungeonEncounterID) --[[@as string]]
			local exportStringTable = SplitStringIntoTable(exportString)
			for index, line in ipairs(exportStringTable) do
				TestEqual(line, textTable[index], "")
			end

			return "Export"
		end
	end
end

do
	local CombatLogEventMap = Private.CombatLogEventMap
	local CombatLogEventReminders = Private.CombatLogEventReminders
	local CombatLogGetCurrentEventInfo = Private.CombatLogGetCurrentEventInfo
	local CreateSpellCountEntry = Private.CreateSpellCountEntry
	local CreateTimer = Private.CreateTimer
	local HandleCombatLogEventUnfiltered = Private.HandleCombatLogEventUnfiltered
	local ResetLocalVariables = Private.ResetLocalVariables
	local SetCombatLogGetCurrentEventInfo = Private.SetCombatLogGetCurrentEventInfo
	local SetCreateTimer = Private.SetCreateTimer
	local SpellCounts = Private.SpellCounts

	---@param testSpellCounts table<FullCombatLogEventType, table<integer, integer>>
	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param spellID integer
	---@param count integer
	local function CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, spellID, count)
		for _, eventType in pairs(CombatLogEventMap) do
			CreateSpellCountEntry(eventType, spellID, 1)
			testSpellCounts[eventType] = testSpellCounts[eventType] or {}
			testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] or 0
			testCombatLogEventReminders[eventType] = testCombatLogEventReminders[eventType] or {}
			testCombatLogEventReminders[eventType][spellID] = testCombatLogEventReminders[eventType][spellID] or {}
			for i = 1, count do
				if not testCombatLogEventReminders[eventType][spellID][i] then
					testCombatLogEventReminders[eventType][spellID][i] = {}
				end
			end
		end
	end

	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param eventType FullCombatLogEventType
	---@param spellID integer
	---@param count integer
	local function AddTestSpellCount(testCombatLogEventReminders, eventType, spellID, count)
		CreateSpellCountEntry(eventType, spellID, count)
		testCombatLogEventReminders[eventType][spellID][count] = {}
	end

	---@param testSpellCounts table<FullCombatLogEventType, table<integer, integer>>
	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param eventType FullCombatLogEventType
	---@param spellID integer|nil
	---@param count integer|nil
	local function RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, spellID, count)
		if spellID then
			if count then
				testCombatLogEventReminders[eventType][spellID][count] = nil
				testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] + 1
			else
				testSpellCounts[eventType][spellID] = nil
				testCombatLogEventReminders[eventType][spellID] = nil
			end
		else
			testSpellCounts[eventType] = nil
			testCombatLogEventReminders[eventType] = nil
		end
	end

	function test.CombatLogEvents()
		local oldCreateTimer = CreateTimer
		local oldCombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

		SetCreateTimer(function() end)
		local currentEventType = "SPELL_CAST_SUCCESS"
		local currentSpellID = 123
		SetCombatLogGetCurrentEventInfo(function()
			return nil, currentEventType, nil, nil, nil, nil, nil, nil, nil, nil, nil, currentSpellID
		end)

		local testSpellCounts, testCombatLogEventReminders = {}, {}
		CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, 123, 1)
		CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, 321, 1)
		AddTestSpellCount(testCombatLogEventReminders, "SPELL_CAST_SUCCESS", 123, 2)
		AddTestSpellCount(testCombatLogEventReminders, "SPELL_CAST_SUCCESS", 321, 2)

		local context = "Initialized Test Tables Equal"
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentEventType = "SPELL_CAST_SUCCESS"
		currentSpellID = 123
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, 1)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentSpellID = 321
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, 1)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentSpellID = 123
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 2
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentSpellID = 321
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 2
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)
		HandleCombatLogEventUnfiltered()

		currentEventType = "SPELL_CAST_START"
		currentSpellID = 123
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentSpellID = 321
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)
		HandleCombatLogEventUnfiltered()

		currentEventType = "SPELL_AURA_APPLIED"
		currentSpellID = 123
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentSpellID = 321
		context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)
		HandleCombatLogEventUnfiltered()

		SetCreateTimer(oldCreateTimer)
		SetCombatLogGetCurrentEventInfo(oldCombatLogGetCurrentEventInfo)
		ResetLocalVariables()
		return "CombatLogEvents"
	end

	function test.UnitDied()
		local oldCreateTimer = CreateTimer
		local oldCombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

		SetCreateTimer(function() end)
		local eventType = "UNIT_DIED"
		local currentSpellID = 123
		local currentDestGUID = "a-b-c-d-e-111"
		SetCombatLogGetCurrentEventInfo(function()
			return nil, eventType, nil, nil, nil, nil, nil, currentDestGUID, nil, nil, nil, currentSpellID
		end)

		local testSpellCounts, testCombatLogEventReminders = {}, {}
		CreateSpellCountEntry(eventType, 111, 1)
		CreateSpellCountEntry(eventType, 112, 1)
		for spellID = 111, 112 do
			testSpellCounts[eventType] = testSpellCounts[eventType] or {}
			testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] or 0
			testCombatLogEventReminders[eventType] = testCombatLogEventReminders[eventType] or {}
			testCombatLogEventReminders[eventType][spellID] = testCombatLogEventReminders[eventType][spellID] or {}
			if not testCombatLogEventReminders[eventType][spellID][1] then
				testCombatLogEventReminders[eventType][spellID][1] = {}
			end
		end

		local context = "Initialized Test Tables Equal"
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)

		currentDestGUID = "a-b-c-d-e-111"
		currentSpellID = 111
		context = "Event: " .. eventType .. " Dest GUID: " .. currentDestGUID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, currentSpellID, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)
		HandleCombatLogEventUnfiltered()

		currentDestGUID = "a-b-c-d-e-112"
		currentSpellID = 112
		context = "Event: " .. eventType .. " Dest GUID: " .. currentDestGUID .. " Count: " .. 1
		HandleCombatLogEventUnfiltered()
		RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, nil, nil)
		TestEqual(SpellCounts, testSpellCounts, context)
		TestEqual(CombatLogEventReminders, testCombatLogEventReminders, context)
		HandleCombatLogEventUnfiltered()

		SetCreateTimer(oldCreateTimer)
		SetCombatLogGetCurrentEventInfo(oldCombatLogGetCurrentEventInfo)
		ResetLocalVariables()
		return "UnitDied"
	end

	Private.CombatLogEventMap = nil
	Private.CombatLogEventReminders = nil
	Private.CombatLogGetCurrentEventInfo = nil
	Private.CreateSpellCountEntry = nil
	Private.CreateTimer = nil
	Private.HandleCombatLogEventUnfiltered = nil
	Private.ResetLocalVariables = nil
	Private.SetCombatLogGetCurrentEventInfo = nil
	Private.SetCreateTimer = nil
	Private.SpellCounts = nil
end

do
	---@class Plan
	local Plan = Private.classes.Plan
	local CreateUniquePlanName = utilities.CreateUniquePlanName
	local CreatePlan = utilities.CreatePlan

	function test.CreateUniquePlanName()
		local planName = ""
		local newName
		for _ = 1, 36 do
			planName = planName .. "H"
		end
		local plans = {}
		plans[planName] = Plan:New({}, planName)
		newName = CreateUniquePlanName(plans, planName)
		TestNotEqual(planName, newName, "Plan names not equal")
		TestEqual(newName:len(), 36, "Plan length equal to 36")

		planName = ""
		for _ = 1, 34 do
			planName = planName .. "H"
		end
		planName = planName .. "99"
		plans[planName] = Plan:New({}, planName)
		newName = CreateUniquePlanName(plans, planName)
		TestNotEqual(planName, newName, "Plan names not equal")
		TestEqual(newName:len(), 36, "Plan length equal to 36")
		TestEqual(newName:sub(34, 36), "100", "Correct number appended")

		planName = "Plan Name"
		plans[planName] = Plan:New({}, planName)
		newName = CreateUniquePlanName(plans, planName)
		TestEqual("Plan Name 2", newName, "Plan name appended with number")

		planName = "Plan Name 3"
		plans[planName] = Plan:New({}, planName)
		newName = CreateUniquePlanName(plans, "Plan Name 4")
		TestEqual("Plan Name 4", newName, "Plan name available and used")

		return "CreateUniquePlanName"
	end

	do
		local SetDesignatedExternalPlan = utilities.SetDesignatedExternalPlan
		local testEncounterIDOne = constants.kDefaultBossDungeonEncounterID
		local testEncounterIDTwo = 3010
		local testEncounterIDThree = 3011
		local kTestPlanName = "Test"
		local plans = {}

		---@param index integer
		---@return Plan
		local function GetPlan(index)
			if index == 1 then
				return plans[kTestPlanName]
			else
				return plans[kTestPlanName .. " " .. tostring(index)]
			end
		end

		---@return table<integer, Plan>
		local function CreateTestPlans()
			wipe(plans)
			CreatePlan(plans, kTestPlanName, testEncounterIDOne, DifficultyType.Mythic)
			CreatePlan(plans, kTestPlanName, testEncounterIDOne, DifficultyType.Mythic)
			CreatePlan(plans, kTestPlanName, testEncounterIDTwo, DifficultyType.Mythic)
			CreatePlan(plans, kTestPlanName, testEncounterIDTwo, DifficultyType.Mythic)

			CreatePlan(plans, kTestPlanName, testEncounterIDOne, DifficultyType.Heroic)
			CreatePlan(plans, kTestPlanName, testEncounterIDTwo, DifficultyType.Heroic)

			return { GetPlan(1), GetPlan(2), GetPlan(3), GetPlan(4), GetPlan(5), GetPlan(6) }
		end

		---@param truthTable table<integer, boolean>
		---@param context string
		---@param numericIndexedPlans table<integer, Plan>
		local function TestPlansEqual(truthTable, context, numericIndexedPlans)
			for index, plan in ipairs(numericIndexedPlans) do
				TestEqual(plan.isPrimaryPlan, truthTable[index], context .. " Index " .. 1)
			end
		end

		function test.SetDesignatedExternalPlan()
			local numericIndexedPlans = CreateTestPlans()

			TestEqual(GetPlan(1).isPrimaryPlan, true, "Correct primary plan after creation")
			TestEqual(GetPlan(3).isPrimaryPlan, true, "Correct primary plan after creation")
			TestEqual(GetPlan(5).isPrimaryPlan, true, "Correct primary plan after creation")
			TestEqual(GetPlan(6).isPrimaryPlan, true, "Correct primary plan after creation")

			GetPlan(1).isPrimaryPlan = false
			GetPlan(3).isPrimaryPlan = false

			SetDesignatedExternalPlan(plans, GetPlan(1))
			local truthTable = { true, false, false, false, true, true }
			TestPlansEqual(truthTable, "Set primary when none exist", numericIndexedPlans)

			SetDesignatedExternalPlan(plans, GetPlan(3))
			truthTable = { true, false, true, false, true, true }
			TestPlansEqual(truthTable, "Set primary when none exist", numericIndexedPlans)

			SetDesignatedExternalPlan(plans, GetPlan(1))
			SetDesignatedExternalPlan(plans, GetPlan(3))
			truthTable = { true, false, true, false, true, true }
			TestPlansEqual(truthTable, "Do nothing when primary exists", numericIndexedPlans)

			SetDesignatedExternalPlan(plans, GetPlan(2))
			SetDesignatedExternalPlan(plans, GetPlan(4))
			truthTable = { false, true, false, true, true, true }
			TestPlansEqual(truthTable, "Switch primary", numericIndexedPlans)

			GetPlan(5).isPrimaryPlan = false
			GetPlan(6).isPrimaryPlan = false

			SetDesignatedExternalPlan(plans, GetPlan(5))
			truthTable = { false, true, false, true, true, false }
			TestPlansEqual(truthTable, "Set primary when none exist", numericIndexedPlans)

			SetDesignatedExternalPlan(plans, GetPlan(6))
			truthTable = { false, true, false, true, true, true }
			TestPlansEqual(truthTable, "Set primary when none exist", numericIndexedPlans)

			return "SetDesignatedExternalPlan"
		end

		local ChangeBossPlan = utilities.ChangePlanBoss

		function test.ChangePlanBoss()
			local numericIndexedPlans = CreateTestPlans()

			ChangeBossPlan(plans, GetPlan(1).name, constants.kDefaultBossDungeonEncounterID, GetPlan(1).difficulty)

			ChangeBossPlan(plans, GetPlan(3).name, testEncounterIDTwo, GetPlan(3).difficulty)
			local truthTable = { true, false, true, false, true, true }
			TestPlansEqual(truthTable, "No change", numericIndexedPlans)

			ChangeBossPlan(plans, GetPlan(2).name, testEncounterIDThree, GetPlan(2).difficulty)
			truthTable = { true, true, true, false, true, true }
			local context = "Set new primary when no primary exist"
			TestPlansEqual(truthTable, context, numericIndexedPlans)

			ChangeBossPlan(plans, GetPlan(4).name, testEncounterIDTwo, GetPlan(4).difficulty)
			truthTable = { true, true, true, false, true, true }
			context = "Preserve primary when primary already exists"
			TestPlansEqual(truthTable, context, numericIndexedPlans)

			ChangeBossPlan(plans, GetPlan(1).name, testEncounterIDTwo, GetPlan(1).difficulty)
			truthTable = { false, true, true, false, true, true }
			context = context .. " 2"
			TestPlansEqual(truthTable, context, numericIndexedPlans)

			GetPlan(2).isPrimaryPlan = false
			GetPlan(5).isPrimaryPlan = false
			ChangeBossPlan(plans, GetPlan(5).name, GetPlan(5).dungeonEncounterID, DifficultyType.Mythic)
			truthTable = { false, false, true, false, true, true }
			context = "Set new primary when no primary exist after changing difficulty"
			TestPlansEqual(truthTable, context, numericIndexedPlans)

			return "ChangePlanBoss"
		end

		local DeletePlan = utilities.DeletePlan

		function test.DeletePlan()
			local numericIndexedPlans = CreateTestPlans()
			local profile = { plans = plans, lastOpenPlan = GetPlan(1).name }

			local planOne = GetPlan(1)
			DeletePlan(profile, planOne.name)
			local context = "Successfully removed correct plan"
			TestEqual(profile.plans[planOne.name], nil, context)
			TestEqual(profile.plans[GetPlan(2).name], GetPlan(2), context)
			TestEqual(profile.plans[GetPlan(3).name], GetPlan(3), context)
			TestEqual(profile.plans[GetPlan(4).name], GetPlan(4), context)
			TestEqual(profile.plans[GetPlan(5).name], GetPlan(5), context)
			TestEqual(profile.plans[GetPlan(6).name], GetPlan(6), context)

			planOne.isPrimaryPlan = false
			local truthTable = { false, true, true, false, true, true }
			TestPlansEqual(truthTable, "Primary swapped after deleting", numericIndexedPlans)

			local planFour = GetPlan(4)
			DeletePlan(profile, planFour.name)
			context = "Successfully removed correct plan 2"
			TestEqual(profile.plans[planOne.name], nil, context)
			TestEqual(profile.plans[GetPlan(2).name], GetPlan(2), context)
			TestEqual(profile.plans[GetPlan(3).name], GetPlan(3), context)
			TestEqual(profile.plans[planFour.name], nil, context)
			TestEqual(profile.plans[GetPlan(5).name], GetPlan(5), context)
			TestEqual(profile.plans[GetPlan(6).name], GetPlan(6), context)

			planFour.isPrimaryPlan = false
			truthTable = { false, true, true, false, true, true }
			TestPlansEqual(truthTable, "Preserve primary", numericIndexedPlans)

			local planTwo = GetPlan(2)
			local planThree = GetPlan(3)
			local planFive = GetPlan(5)
			local planSix = GetPlan(6)
			DeletePlan(profile, planTwo.name)
			DeletePlan(profile, planThree.name)
			DeletePlan(profile, planFive.name)
			DeletePlan(profile, planSix.name)
			context = "Successfully removed all plans except default"
			TestEqual(profile.plans[planTwo.name], nil, context)
			TestEqual(profile.plans[planThree.name], nil, context)
			TestEqual(profile.plans[planFour.name], nil, context)
			TestEqual(profile.plans[planFive.name], nil, context)
			TestEqual(profile.plans[planSix.name], nil, context)

			local _, defaultPlan = next(profile.plans) --[[@as Plan]]
			local lastExistingEncounterID = planThree.dungeonEncounterID
			local defaultPlanEncounterID = defaultPlan.dungeonEncounterID
			context = "Created default plan after deleting all plans"
			TestEqual(lastExistingEncounterID, defaultPlanEncounterID, context)
			TestEqual(defaultPlan.name, L["Default"], context)
			return "DeletePlan"
		end

		local GetCooldownDurationFromTooltip = utilities.GetCooldownDurationFromTooltip

		function test.CooldownDurationTooltip()
			local duration = GetCooldownDurationFromTooltip(342245)
			TestEqual(duration, 50.0, "Shortened duration from talent")
			return "CooldownDurationTooltip"
		end
	end

	---@class TimedAssignment
	local TimedAssignment = Private.classes.TimedAssignment
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class RosterEntry
	local RosterEntry = Private.classes.RosterEntry
	---@class BossUtilities
	local bossUtilities = Private.bossUtilities

	local DuplicatePlan = utilities.DuplicatePlan
	local CreateTestPlan = testUtilities.CreateTestPlan

	---@return table<string, RosterEntry>
	local function CreateTestRoster()
		local roster = {}
		for index, classFileName in ipairs(utilities.GetClassFileNames()) do
			local rosterEntry = RosterEntry:New()
			rosterEntry.class = utilities.GetFormattedDataClassName(classFileName)
			rosterEntry.classColoredName = utilities.GetLocalizedPrettyClassName(classFileName)
			rosterEntry.role = "role:damager"
			roster["Player" .. index] = rosterEntry
		end
		return roster
	end

	function test.DuplicatePlan()
		local plans = {}

		local plan = CreateTestPlan(
			plans,
			"Test",
			bossUtilities.GetBoss(Private.constants.kDefaultBossDungeonEncounterID),
			DifficultyType.Mythic,
			CreateTestRoster()
		)

		local duplicatedPlan = DuplicatePlan(plans, "Test", "Test")
		duplicatedPlan.isPrimaryPlan = plan.isPrimaryPlan
		duplicatedPlan.name = plan.name
		duplicatedPlan.ID = plan.ID
		TestEqual(plan, duplicatedPlan, "Duplicated plan equals original plan")

		return "DuplicatePlan"
	end

	do
		local ApplyDiff = utilities.ApplyDiff
		local DiffPlans = utilities.DiffPlans
		local DuplicateAssignment = Private.DuplicateAssignment
		local GetClassColor = C_ClassColor.GetClassColor
		local PlanDiffType = Private.classes.PlanDiffType

		-- cSpell:disable
		local textOne = [[
            nsnovastart
            ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r
            ||cff33937fDraugmentor||r  ||cfffefefeReduckted||r  ||cff3ec6eaMarkoleptic||r  ||cffa9d271Orcodontist||r 
            ||cffc31d39Hobyrim||r  ||cffc31d39Xonj||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r  
            ||cffa9d271Orcodontist||r  ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r  ||cfffe7b09Skorke||r   
            ||cfffe7b09Gun||r  ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r   
            ||cff00fe97Dogpog||r  ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff3ec6eaSeansmage||r
            ||cfffe7b09Skorke||r  ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r  ||cff3ec6eaMarkoleptic||r
            ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Gun||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r
            nsnovaend
        ]]
		local textTwo = [[
            nsnovastart
            ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r
            ||cff33937fDraugmentor||r  ||cfffefefeReduckted||r  ||cff3ec6eaMarkoleptic||r  ||cffa9d271Orcodontist||r 
            ||cffc31d39Hobyrim||r  ||cffc31d39Xonj||r  ||cff00fe97Dogpog||r  ||cff3ec6eaSeansmage||r  
            ||cffa9d271Orcodontist||r  ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r 
            ||cfffe7b09Gun||r  ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r   
            ||cff00fe97Dogpog||r  ||cffc31d39Xonj||r  ||cffc31d39Hobyrim||r  ||cff3ec6eaSeansmage||r
            ||cfffefefeReduckted||r  ||cff33937fDraugmentor||r  ||cff3ec6eaMarkoleptic||r
            ||cff3ec6eaMarkoleptic||r  ||cfffe7b09Gun||r  ||cfffe7b09Wiiki||r  ||cfffefefeLbkt||r
            Yo
            nsnovaend
        ]]
		-- cSpell:enable

		function test.PlanDiff()
			local plans = {}
			local oldPlan =
				CreatePlan(plans, "Test", Private.constants.kDefaultBossDungeonEncounterID, DifficultyType.Mythic)
			oldPlan.content = RemoveTabs(SplitStringIntoTable(textOne))

			for i = 1, 10 do
				local assignment = TimedAssignment:New(nil, oldPlan.ID)
				assignment.assignee = "Player" .. i
				assignment.time = 60.0
				assignment.text = "Buh"
				assignment.spellID = 344343
				tinsert(oldPlan.assignments, assignment)
			end

			oldPlan.roster = CreateTestRoster()

			local newPlan = DuplicatePlan(plans, "Test", "DuplicatedTest")

			local diff = DiffPlans(oldPlan, newPlan)
			TestEqual(diff.empty, true, "Diff Empty with exact duplicate")

			newPlan.content = RemoveTabs(SplitStringIntoTable(textTwo))

			newPlan.difficulty = DifficultyType.Heroic

			newPlan.roster["Player13"] = nil
			newPlan.roster["Player8"].role = "role:healer"
			newPlan.roster["Player22"] = {
				class = "class:DemonHunter",
				classColoredName = GetClassColor("DEMONHUNTER"):WrapTextInColorCode("Player22"),
				role = "role:tank",
			}

			tremove(newPlan.assignments, 1)
			tremove(newPlan.assignments, 2)
			tremove(newPlan.assignments, 5)
			newPlan.assignments[6].assignee = "{everyone}"

			diff = DiffPlans(oldPlan, newPlan)

			TestEqual(diff.metaData.difficulty.oldValue, DifficultyType.Mythic, "Changed difficulty")
			TestEqual(diff.metaData.difficulty.newValue, DifficultyType.Heroic, "Changed difficulty")

			TestEqual(diff.roster[1].type, PlanDiffType.Delete, "Deleted roster member")
			TestEqual(diff.roster[2].type, PlanDiffType.Change, "Changed roster member")
			TestEqual(diff.roster[2].oldValue.role, "role:damager", "Changed roster member")
			TestEqual(diff.roster[2].newValue.role, "role:healer", "Changed roster member")
			TestEqual(diff.roster[3].type, PlanDiffType.Insert, "Inserted roster member")

			TestEqual(diff.assignments[1].type, PlanDiffType.Delete, "Deleted assignment")
			TestEqual(diff.assignments[2].type, PlanDiffType.Equal, "Equal assignment")
			TestEqual(diff.assignments[3].type, PlanDiffType.Delete, "Deleted assignment")
			TestEqual(diff.assignments[4].type, PlanDiffType.Equal, "Equal assignment")
			TestEqual(diff.assignments[5].type, PlanDiffType.Equal, "Equal assignment")
			TestEqual(diff.assignments[6].type, PlanDiffType.Equal, "Equal assignment")
			TestEqual(diff.assignments[7].type, PlanDiffType.Delete, "Deleted assignment")
			TestEqual(diff.assignments[8].type, PlanDiffType.Equal, "Equal assignment")
			-- TestEqual(diff.assignments[9].type, PlanDiffType.Change, "Changed assignment")
			-- TestEqual(diff.assignments[9].newValue.assignee, "{everyone}", "Changed assignment")
			-- TestEqual(diff.assignments[10].type, PlanDiffType.Equal, "Equal assignment")

			ApplyDiff(oldPlan.assignments, diff.assignments, DuplicateAssignment, oldPlan.ID)
			TestEqual(oldPlan.assignments, newPlan.assignments, "New plan assignments applied correctly")

			return "PlanDiff"
		end

		local MergePlan = utilities.MergePlan

		function test.MergePlan()
			local plans = {}
			local boss = bossUtilities.GetBoss(Private.constants.kDefaultBossDungeonEncounterID)
			local oldPlan = CreateTestPlan(plans, "Test", boss, DifficultyType.Mythic, CreateTestRoster())
			oldPlan.content = RemoveTabs(SplitStringIntoTable(textOne))

			local newPlan = DuplicatePlan(plans, "Test", "DuplicatedTest")
			do
				local diff = DiffPlans(oldPlan, newPlan)
				TestEqual(diff.empty, true, "Diff Empty with exact duplicate")
			end

			newPlan.content = RemoveTabs(SplitStringIntoTable(textTwo))

			local rosterCount = 0
			for _ in pairs(newPlan.roster) do
				rosterCount = rosterCount + 1
			end

			local assignees = {}
			for _, assignment in ipairs(newPlan.assignments) do
				tinsert(assignees, assignment.assignee)
			end

			for _ = 1, math.random(20, 60) do
				local choice = math.random() -- [0,1)
				local len = #newPlan.assignments
				if choice < 0.3 and len > 0 then -- delete
					local idx = math.random(1, len)
					tremove(newPlan.assignments, idx)
				elseif choice < 0.6 then -- insert
					local idx = math.random(1, len + 1)
					tinsert(newPlan.assignments, idx, testUtilities.CreateRandomAssignment(newPlan, boss, assignees))
				elseif len > 0 then -- change
					local idx = math.random(1, len)
					newPlan.assignments[idx].assignee = testUtilities.GetRandomAssignee(newPlan.roster, rosterCount)
				end
			end

			local diff = DiffPlans(oldPlan, newPlan)
			MergePlan(plans, oldPlan, diff)
			TestEqual(
				oldPlan.dungeonEncounterID,
				newPlan.dungeonEncounterID,
				"New plan dungeonEncounterID applied correctly"
			)
			TestEqual(oldPlan.instanceID, newPlan.instanceID, "New plan instanceID applied correctly")
			TestEqual(oldPlan.difficulty, newPlan.difficulty, "New plan difficulty applied correctly")
			TestEqual(oldPlan.roster, newPlan.roster, "New plan roster applied correctly")
			TestEqual(oldPlan.assignments, newPlan.assignments, "New plan assignments applied correctly")
			TestEqual(oldPlan.content, newPlan.content, "New plan content applied correctly")

			return "MergePlan"
		end
	end
end

do
	local CoalesceChanges = utilities.CoalesceChanges
	local MyersDiff = utilities.MyersDiff
	local PlanDiffType = Private.classes.PlanDiffType

	function test.MyersDiff()
		local comparator = function(a, b)
			return a == b
		end

		for i = 1, 2 do
			local func
			if i == 1 then
				func = function(...)
					return MyersDiff(...)
				end
			else
				func = function(...)
					return CoalesceChanges(MyersDiff(...))
				end
			end

			local aStringTable, bStringTable = {}, {}
			local diff = func(aStringTable, bStringTable, comparator)
			TestEqual(#diff, 0, "Empty")

			aStringTable = { "a", "b", "c" }
			bStringTable = { "a", "b", "c" }
			diff = func(aStringTable, bStringTable, comparator)
			for _, diffEntry in ipairs(diff) do
				TestEqual(diffEntry.type, PlanDiffType.Equal, "Equal for all elements")
			end

			aStringTable = { "a", "b" }
			bStringTable = { "a", "b", "c", "d" }
			diff = func(aStringTable, bStringTable, comparator)

			local context = "Insert Only"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Insert, context)
			TestEqual(diff[4].type, PlanDiffType.Insert, context)
			TestEqual(diff[3].value, "c", context)
			TestEqual(diff[4].value, "d", context)

			aStringTable = { "a", "b", "c", "d" }
			bStringTable = { "a", "b" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Delete Only"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Delete, context)
			TestEqual(diff[4].type, PlanDiffType.Delete, context)
			TestEqual(diff[3].value, "c", context)
			TestEqual(diff[4].value, "d", context)

			aStringTable = { "a", "b", "x", "d" }
			bStringTable = { "a", "b", "y", "d" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Coalesced insert and delete"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			if i == 1 then
				TestEqual(diff[3].type, PlanDiffType.Delete, context)
				TestEqual(diff[4].type, PlanDiffType.Insert, context)
				TestEqual(diff[5].type, PlanDiffType.Equal, context)
				TestEqual(diff[3].value, "x", context)
				TestEqual(diff[4].value, "y", context)
			else
				TestEqual(diff[3].type, PlanDiffType.Change, context)
				TestEqual(diff[4].type, PlanDiffType.Equal, context)
				TestEqual(diff[3].oldValue, "x", context)
				TestEqual(diff[3].newValue, "y", context)
			end

			aStringTable = { "b", "c" }
			bStringTable = { "a", "b", "c" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Leading insertion"
			TestEqual(diff[1].type, PlanDiffType.Insert, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Equal, context)
			TestEqual(diff[1].value, "a", context)

			aStringTable = { "a", "b", "c" }
			bStringTable = { "b", "c" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Leading deletion"
			TestEqual(diff[1].type, PlanDiffType.Delete, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Equal, context)
			TestEqual(diff[1].value, "a", context)

			aStringTable = { "a", "b" }
			bStringTable = { "a", "b", "c" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Trailing insertion"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Insert, context)
			TestEqual(diff[3].value, "c", context)

			aStringTable = { "a", "b", "c" }
			bStringTable = { "a", "b" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Trailing deletion"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Delete, context)
			TestEqual(diff[3].value, "c", context)

			aStringTable = { "a", "b", "c", "d", "e" }
			bStringTable = { "a", "x", "c", "y", "e" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Multiple inserts and deletes"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			if i == 1 then
				TestEqual(diff[2].type, PlanDiffType.Delete, context)
				TestEqual(diff[3].type, PlanDiffType.Insert, context)
				TestEqual(diff[4].type, PlanDiffType.Equal, context)
				TestEqual(diff[5].type, PlanDiffType.Delete, context)
				TestEqual(diff[6].type, PlanDiffType.Insert, context)
				TestEqual(diff[7].type, PlanDiffType.Equal, context)
				TestEqual(diff[2].value, "b", context)
				TestEqual(diff[3].value, "x", context)
				TestEqual(diff[5].value, "d", context)
				TestEqual(diff[6].value, "y", context)
			else
				TestEqual(diff[2].type, PlanDiffType.Change, context)
				TestEqual(diff[3].type, PlanDiffType.Equal, context)
				TestEqual(diff[4].type, PlanDiffType.Change, context)
				TestEqual(diff[5].type, PlanDiffType.Equal, context)
				TestEqual(diff[2].oldValue, "b", context)
				TestEqual(diff[2].newValue, "x", context)
				TestEqual(diff[4].oldValue, "d", context)
				TestEqual(diff[4].newValue, "y", context)
			end

			if i == 1 then
				aStringTable = { "a", "b", "c" }
				bStringTable = { "x", "y", "z" }
				diff = func(aStringTable, bStringTable, comparator)

				context = "Completely different sequences"
				TestEqual(diff[1].type, PlanDiffType.Delete, context)
				TestEqual(diff[2].type, PlanDiffType.Delete, context)
				TestEqual(diff[3].type, PlanDiffType.Delete, context)
				TestEqual(diff[4].type, PlanDiffType.Insert, context)
				TestEqual(diff[5].type, PlanDiffType.Insert, context)
				TestEqual(diff[6].type, PlanDiffType.Insert, context)
				TestEqual(diff[1].value, "a", context)
				TestEqual(diff[2].value, "b", context)
				TestEqual(diff[3].value, "c", context)
				TestEqual(diff[4].value, "x", context)
				TestEqual(diff[5].value, "y", context)
				TestEqual(diff[6].value, "z", context)
			end

			aStringTable = { "a", "b", "c", "d", "e" }
			bStringTable = { "b", "c", "d" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Subsequence match"
			TestEqual(diff[1].type, PlanDiffType.Delete, context)
			TestEqual(diff[2].type, PlanDiffType.Equal, context)
			TestEqual(diff[3].type, PlanDiffType.Equal, context)
			TestEqual(diff[4].type, PlanDiffType.Equal, context)
			TestEqual(diff[5].type, PlanDiffType.Delete, context)
			TestEqual(diff[1].value, "a", context)
			TestEqual(diff[5].value, "e", context)

			aStringTable = { "a", "d" }
			bStringTable = { "a", "b", "c", "d" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Large insertion in middle"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Insert, context)
			TestEqual(diff[3].type, PlanDiffType.Insert, context)
			TestEqual(diff[4].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].value, "b", context)
			TestEqual(diff[3].value, "c", context)

			aStringTable = { "a", "b", "c", "d" }
			bStringTable = { "a", "d" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Large deletion in middle"
			TestEqual(diff[1].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].type, PlanDiffType.Delete, context)
			TestEqual(diff[3].type, PlanDiffType.Delete, context)
			TestEqual(diff[4].type, PlanDiffType.Equal, context)
			TestEqual(diff[2].value, "b", context)
			TestEqual(diff[3].value, "c", context)

			aStringTable = {}
			bStringTable = { "a", "b", "c" }
			diff = func(aStringTable, bStringTable, comparator)

			context = "Existing empty, new non-empty"
			TestEqual(diff[1].type, PlanDiffType.Insert, context)
			TestEqual(diff[2].type, PlanDiffType.Insert, context)
			TestEqual(diff[3].type, PlanDiffType.Insert, context)
			TestEqual(diff[1].value, "a", context)
			TestEqual(diff[2].value, "b", context)
			TestEqual(diff[3].value, "c", context)

			aStringTable = { "a", "b", "c" }
			bStringTable = {}
			diff = func(aStringTable, bStringTable, comparator)

			context = "Existing non-empty, new empty"
			TestEqual(diff[1].type, PlanDiffType.Delete, context)
			TestEqual(diff[2].type, PlanDiffType.Delete, context)
			TestEqual(diff[3].type, PlanDiffType.Delete, context)
			TestEqual(diff[1].value, "a", context)
			TestEqual(diff[2].value, "b", context)
			TestEqual(diff[3].value, "c", context)
		end

		return "MyersDiff"
	end

	do
		local ApplyDiff = utilities.ApplyDiff

		function test.ApplyMyersDiff()
			local changeFunc = function(newValue)
				return newValue
			end
			local aStringTable = { "A", "B", "C", "D", "E" }
			local bStringTable = { "A", "B", "C", "D" }
			local planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "2")
			end

			aStringTable = { "A", "B", "C", "D", "E" }
			bStringTable = { "A", "B", "C", "D", "E", "F" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "1")
			end

			aStringTable = { "A", "B", "C", "D", "E" }
			bStringTable = { "A", "F", "C", "X", "E" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "1")
			end

			aStringTable = { "A", "B", "C", "D", "E" }
			bStringTable = { "F", "C", "X", "E" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "2")
			end

			aStringTable = { "A", "B", "C", "D", "E" }
			bStringTable = { "A", "F", "C", "X" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "3")
			end

			aStringTable = { "A", "B", "C", "D" }
			bStringTable = { "X", "A", "B", "C", "Y", "D", "Z" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "3")
			end

			aStringTable = { "A", "B", "C", "D" }
			bStringTable = { "X", "Y", "Z" }
			planDiff = MyersDiff(aStringTable, bStringTable, function(a, b)
				return a == b
			end)
			ApplyDiff(aStringTable, planDiff, changeFunc)
			for i, v in ipairs(bStringTable) do
				TestEqual(aStringTable[i], v, "3")
			end

			return "ApplyMyersDiff"
		end
	end
end
