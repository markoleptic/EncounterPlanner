local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
---@class Assignment
local Assignment = Private.classes.Assignment
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class PhasedAssignment
local PhasedAssignment = Private.classes.PhasedAssignment
---@class Plan
local Plan = Private.classes.Plan
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment

---@class Constants
local constants = Private.constants
local kInvalidAssignmentSpellID = constants.kInvalidAssignmentSpellID
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local ChangePlanBoss = bossUtilities.ChangePlanBoss
local GetBossDungeonEncounterIDFromSpellID = bossUtilities.GetBossDungeonEncounterIDFromSpellID
local ClampSpellCount = bossUtilities.ClampSpellCount
local IsValidSpellCount = bossUtilities.IsValidSpellCount

---@class Utilities
local utilities = Private.utilities
local CreateTimelineAssignments = utilities.CreateTimelineAssignments
local GetLocalizedSpecNameFromSpecID = utilities.GetLocalizedSpecNameFromSpecID
local IsValidAssignee = utilities.IsValidAssignee
local SplitStringIntoTable = utilities.SplitStringIntoTable
local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup
local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments

local concat = table.concat
local format = string.format
local floor = math.floor
local GetSpellName = C_Spell.GetSpellName
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local sort = sort
local split = string.split
local splitTable = strsplittable
local tinsert = tinsert
local tonumber = tonumber
local wipe = wipe

local assigneeGroupRegex = "^({.-})"
local colorEndRegex = "|?|r"
local colorStartRegex = "|?|c........"
local nameRegex = "^(%S+)"
local nonSymbolRegex = "[^ \n,%(%)%[%]_%$#@!&]+"
local phaseNumberRegex = "^p(g?):?(.-)$"
local postDashRegex = "([^ \n][^\n]-)  +"
local postOptionsPreDashNoSpellRegex = "}(.-) %-"
local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"
local removeFirstDashRegex = "^[^%-]*%-+%s*"
local spaceSurroundedDashRegex = "^.* %- (.*)"
local stringWithoutSpellRegex = "(.*){spell:(%d+):?%d*}(.*)"
local targetNameRegex = "(@%S+)"
local textRegex = "{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}"
local timeOptionsSplitRegex = "{time:(%d+)[:%.]?(%d*),?([^{}]*)}"
local combatLogEventFromAbbreviation = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

---@class FailureTableEntry
---@field reason OptionFailureReason
---@field string string
---@field replacedSpellCount? integer

-- Parses a line of text in the note and creates assignment(s).
---@param line string
---@param failed table<integer, FailureTableEntry>
---@return table<integer, Assignment>
---@return integer
local function CreateAssignmentsFromLine(line, failed)
	local assignments = {}
	local failedCount = 0

	local rightOfDash = line:match(spaceSurroundedDashRegex)
	if rightOfDash then
		line = rightOfDash
	else
		line = line:gsub(removeFirstDashRegex, "", 1)
	end

	for str in (line .. "  "):gmatch(postDashRegex) do
		local spellID = kInvalidAssignmentSpellID
		local strWithoutSpell = str:gsub(stringWithoutSpellRegex, function(left, id, right)
			if id and id ~= "" then
				local numericValue = tonumber(id)
				if numericValue and GetSpellName(numericValue) then
					spellID = numericValue
				end
			end
			return left .. right
		end)
		local text = str:match(textRegex)
		if text then
			text = text:gsub("{everyone}", "") -- duplicate everyone
			text = text:gsub("^%s*(.-)%s*$", "%1") -- remove beginning/trailing whitespace
			strWithoutSpell = strWithoutSpell:gsub(textRegex, "")
		end
		for _, entry in pairs(splitTable(",", strWithoutSpell)) do
			local targetName = nil
			entry = entry:gsub("%s", "") -- remove all whitespace
			entry = entry:gsub(colorStartRegex, ""):gsub(colorEndRegex, "") -- Remove colors
			entry = entry:gsub(targetNameRegex, function(target)
				if target then
					targetName = target:gsub("@", "") -- Extract target name
				end
				return "" -- Remove match
			end)
			local assignee = IsValidAssignee(entry)
			if assignee then
				local assignment = Assignment:New({
					assignee = assignee,
					text = text,
					spellID = spellID,
					targetName = targetName,
				})
				if assignment.spellID == kInvalidAssignmentSpellID then
					if assignment.text:len() > 0 then
						assignment.spellID = kTextAssignmentSpellID
					end
				end
				tinsert(assignments, assignment)
			else
				tinsert(failed, { reason = 6, string = entry })
				failedCount = failedCount + 1
			end
		end
	end
	return assignments, failedCount
end

---@param option string
---@param time number
---@param assignments table<integer, Assignment>
---@param derivedAssignments table<integer, Assignment>
---@param replaced table<integer, FailureTableEntry>
---@param encounterIDs table<integer, {assignmentIDs: table<integer, integer>, string: string}> Boss encounter spell IDs
---@return boolean -- True if combat log event assignments were added
---@return boolean -- True if first first return value is true and replaced invalid spell count
---@return boolean -- True if invalid combat log event type or combat log event spell ID
local function ProcessCombatEventLogEventOption(option, time, assignments, derivedAssignments, replaced, encounterIDs)
	local combatLogEventAbbreviation, spellIDStr, spellCountStr, rest = split(":", option, 4)
	if combatLogEventFromAbbreviation[combatLogEventAbbreviation] then
		local spellID = tonumber(spellIDStr)
		local spellCount = tonumber(spellCountStr)
		if spellID then
			local bossDungeonEncounterID = GetBossDungeonEncounterIDFromSpellID(spellID)
			if bossDungeonEncounterID then
				encounterIDs[bossDungeonEncounterID] = encounterIDs[bossDungeonEncounterID]
					or { assignmentIDs = {}, string = option }
				local replacedInvalidSpellCount = false
				if spellCount then
					if not IsValidSpellCount(bossDungeonEncounterID, spellID, spellCount, true) then
						spellCount = ClampSpellCount(bossDungeonEncounterID, spellID, spellCount)
						if spellCount then
							tinsert(replaced, {
								reason = 4,
								string = option,
								replacedSpellCount = spellCount,
							})
							replacedInvalidSpellCount = true
						end
					end
				else
					tinsert(replaced, { reason = 5, string = option })
					replacedInvalidSpellCount = true
					spellCount = 1
				end
				if spellCount then
					for _, assignment in pairs(assignments) do
						local combatLogEventAssignment = CombatLogEventAssignment:New(assignment)
						combatLogEventAssignment.combatLogEventType = combatLogEventAbbreviation
						combatLogEventAssignment.time = time
						combatLogEventAssignment.spellCount = spellCount
						combatLogEventAssignment.combatLogEventSpellID = spellID
						tinsert(derivedAssignments, combatLogEventAssignment)
						tinsert(encounterIDs[bossDungeonEncounterID].assignmentIDs, combatLogEventAssignment.uniqueID)
					end
					return true, replacedInvalidSpellCount, false
				end
			else
				tinsert(replaced, { reason = 3, string = option })
				return false, false, true
			end
		else
			tinsert(replaced, { reason = 3, string = option })
			return false, false, true
		end
	elseif combatLogEventAbbreviation and combatLogEventAbbreviation:gsub("%s", ""):len() > 0 then
		tinsert(replaced, { reason = 2, string = option })
		return false, false, true
	end
	return false, false, false
end

-- Adds an assignment using a more derived type by parsing the options (comma-separated list after time).
---@param assignments table<integer, Assignment>
---@param derivedAssignments table<integer, Assignment>
---@param time number
---@param options string
---@param replaced table<integer, FailureTableEntry>
---@param encounterIDs table<integer, {assignmentIDs: table<integer, integer>, string: string}>
---@return integer -- defaultedToTimedAssignmentCount
---@return integer -- defaultedToNearestSpellCountCount
local function ProcessOptions(assignments, derivedAssignments, time, options, replaced, encounterIDs)
	local regularTimer = true
	local defaultedToTimedCount = 0

	local option, rest = split(",", options, 2)
	if option == "e" then
		if rest then
			local customEvent, _ = split(",", rest, 2)
			if customEvent then
				-- TODO: Handle custom event
				tinsert(replaced, { reason = 1, string = option })
				defaultedToTimedCount = defaultedToTimedCount + #assignments
			end
		end
	elseif option:sub(1, 1) == "p" then
		tinsert(replaced, { reason = 1, string = option })
		defaultedToTimedCount = defaultedToTimedCount + #assignments
		-- local _, phase = option:match(phaseNumberRegex)
		-- if phase and phase ~= "" then
		-- 	local phaseNumber = tonumber(phase, 10)
		-- 	if phaseNumber then
		-- 		for _, assignment in pairs(assignments) do
		-- 			local phasedAssignment = PhasedAssignment:New(assignment)
		-- 			phasedAssignment.time = time
		-- 			phasedAssignment.phase = phaseNumber
		-- 			tinsert(derivedAssignments, phasedAssignment)
		-- 		end
		-- 	end
		-- 	regularTimer = false
		-- end
	else
		local success, replacedInvalidSpellCount, invalidCombatLogEventTypeOrCombatLogEventSpellID =
			ProcessCombatEventLogEventOption(option, time, assignments, derivedAssignments, replaced, encounterIDs)
		if success then
			if replacedInvalidSpellCount then
				return 0, #assignments
			else
				return 0, 0
			end
		elseif invalidCombatLogEventTypeOrCombatLogEventSpellID then
			defaultedToTimedCount = defaultedToTimedCount + #assignments
		end
	end
	if regularTimer then
		for _, assignment in pairs(assignments) do
			local timedAssignment = TimedAssignment:New(assignment)
			timedAssignment.time = time
			tinsert(derivedAssignments, timedAssignment)
		end
	end
	return defaultedToTimedCount, 0
end

---@param line string
---@return number|nil
---@return string|nil
---@return string
local function ParseTime(line)
	local time, options = nil, nil
	local rest, _ = line:gsub(timeOptionsSplitRegex, function(minute, sec, opts)
		if minute and (sec == nil or sec == "") then
			time = tonumber(minute)
		elseif minute and sec then
			time = tonumber(sec) + (tonumber(minute) * 60)
		end
		options = opts
		return ""
	end)

	return time, options, rest
end

---@param failedOrReplaced table<integer, FailureTableEntry>
---@param failedCount integer
---@param defaultedToTimedCount integer
---@param defaultedSpellCount integer
local function LogFailures(failedOrReplaced, failedCount, defaultedToTimedCount, defaultedSpellCount)
	---@class InterfaceUpdater
	local interfaceUpdater = Private.interfaceUpdater

	if failedCount > 0 then
		local msg
		if failedCount == 1 then
			msg = format("%s %d %s:", L["Failed to import"], failedCount, L["assignment"])
		else
			msg = format("%s %d %s:", L["Failed to import"], failedCount, L["assignments"])
		end
		interfaceUpdater.LogMessage(msg, 3, 1)

		for _, value in ipairs(failedOrReplaced) do
			if value.reason == 6 then
				msg = format("%s: '%s'", L["Invalid assignee"], value.string)
				interfaceUpdater.LogMessage(msg, 3, 2)
			end
		end
	end

	if defaultedToTimedCount > 0 then
		local msg
		if defaultedToTimedCount == 1 then
			msg = format("%d %s:", defaultedToTimedCount, L["assignment was defaulted to a timed assignment"])
		else
			msg = format("%d %s:", defaultedToTimedCount, L["assignments were defaulted to timed assignments"])
		end
		interfaceUpdater.LogMessage(msg, 2, 1)

		for _, value in ipairs(failedOrReplaced) do
			if value.reason == 1 then
				msg = format("%s: '%s'.", L["Invalid assignment type"], value.string)
				interfaceUpdater.LogMessage(msg, 2, 2)
			elseif value.reason == 2 then
				msg = format("%s: '%s'.", L["Invalid combat log event type"], value.string)
				interfaceUpdater.LogMessage(msg, 2, 2)
			elseif value.reason == 3 then
				msg = format("%s: '%s'.", L["Invalid combat log event spell ID"], value.string)
				interfaceUpdater.LogMessage(msg, 2, 2)
			elseif value.reason == 7 then
				msg = format("%s (%s): '%s'.", L["Invalid combat log event spell ID"], L["Wrong boss"], value.string)
				interfaceUpdater.LogMessage(msg, 2, 2)
			end
		end
	end

	if defaultedSpellCount > 0 then
		local msg
		if defaultedSpellCount == 1 then
			msg = format("%d %s:", defaultedSpellCount, L["assignment had its spell count replaced"])
		else
			msg = format("%d %s:", defaultedSpellCount, L["assignments had their spell counts replaced"])
		end
		interfaceUpdater.LogMessage(msg, 1, 1)

		local assigned = L["Invalid spell count has been assigned the value"]
		for _, value in ipairs(failedOrReplaced) do
			if value.reason == 4 then
				msg = format("'%s': %s '%d'.", value.string, assigned, value.replacedSpellCount)
				interfaceUpdater.LogMessage(msg, 1, 2)
			elseif value.reason == 5 then
				msg = format("'%s': %s '1'.", value.string, assigned)
				interfaceUpdater.LogMessage(msg, 1, 2)
			end
		end
	end
end

-- Repopulates assignments for the note based on the note content. Returns a boss name if one was found using spellIDs
-- in the text.
---@param plan Plan Plan to repopulate
---@param text table<integer, string> content
---@param test boolean?
---@return integer|nil
function Private.ParseNote(plan, text, test)
	wipe(plan.assignments)
	local bossDungeonEncounterIDs = {} ---@type table<integer, {assignmentIDs: table<integer, integer>, string: string}>
	local lowerPriorityEncounterIDs = {} ---@type table<integer, integer>
	local otherContent = {}
	local failedOrReplaced = {} ---@type table<integer, FailureTableEntry>
	local failedCount, defaultedToTimedCount, defaultedSpellCount = 0, 0, 0

	for _, line in pairs(text) do
		local time, options, rest = ParseTime(line)
		if time and options then
			local spellID, _ = line:match(postOptionsPreDashRegex)
			local spellIDNumber = nil
			if spellID then
				spellIDNumber = tonumber(spellID)
				if spellIDNumber then
					local bossDungeonEncounterID = GetBossDungeonEncounterIDFromSpellID(spellIDNumber)
					if bossDungeonEncounterID then
						lowerPriorityEncounterIDs[bossDungeonEncounterID] = (
							lowerPriorityEncounterIDs[bossDungeonEncounterID] or 0
						) + 1
					end
				end
			end
			local inputs, count = CreateAssignmentsFromLine(rest, failedOrReplaced)
			failedCount = failedCount + count
			local defaultedToTimed, defaultedCombatLogAssignment =
				ProcessOptions(inputs, plan.assignments, time, options, failedOrReplaced, bossDungeonEncounterIDs)
			defaultedToTimedCount = defaultedToTimedCount + defaultedToTimed
			defaultedSpellCount = defaultedSpellCount + defaultedCombatLogAssignment
		else
			if line:gsub("%s", ""):len() ~= 0 then
				tinsert(otherContent, line)
			end
		end
	end

	plan.content = otherContent

	local determinedBossDungeonEncounterID, maxCount = nil, 0
	for bossDungeonEncounterID, assignmentIDsAndOptions in pairs(bossDungeonEncounterIDs) do
		local count = #assignmentIDsAndOptions.assignmentIDs
		if count > maxCount then
			maxCount = count
			determinedBossDungeonEncounterID = bossDungeonEncounterID
		end
	end
	if not determinedBossDungeonEncounterID then
		for bossDungeonEncounterID, count in pairs(lowerPriorityEncounterIDs) do
			if count > maxCount then
				maxCount = count
				determinedBossDungeonEncounterID = bossDungeonEncounterID
			end
		end
	end

	local FindAssignmentByUniqueID = utilities.FindAssignmentByUniqueID
	-- Convert assignments not matching the determined boss dungeon encounter ID to timed assignments
	for bossDungeonEncounterID, assignmentIDsAndOptions in pairs(bossDungeonEncounterIDs) do
		if bossDungeonEncounterID ~= determinedBossDungeonEncounterID then
			for _, assignmentID in pairs(assignmentIDsAndOptions.assignmentIDs) do
				local assignment = FindAssignmentByUniqueID(plan.assignments, assignmentID)
				if assignment then
					assignment = TimedAssignment:New(assignment, true)
					tinsert(failedOrReplaced, { reason = 7, string = assignmentIDsAndOptions.string })
					defaultedToTimedCount = defaultedToTimedCount + 1
				end
			end
		end
	end

	if determinedBossDungeonEncounterID then
		local castTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable(determinedBossDungeonEncounterID)
		local bossPhaseTable = bossUtilities.GetOrderedBossPhases(determinedBossDungeonEncounterID)
		if castTimeTable and bossPhaseTable then
			for _, assignment in ipairs(plan.assignments) do
				if getmetatable(assignment) == CombatLogEventAssignment then
					utilities.UpdateAssignmentBossPhase(
						assignment --[[@as CombatLogEventAssignment]],
						determinedBossDungeonEncounterID
					)
				end
			end
		end
	end

	if #failedOrReplaced > 0 and not test then
		LogFailures(failedOrReplaced, failedCount, defaultedToTimedCount, defaultedSpellCount)
	end

	return determinedBossDungeonEncounterID
end

do
	---@param assignment CombatLogEventAssignment|TimedAssignment
	---@return string
	local function CreateTimeAndOptionsExportString(assignment)
		local minutes = floor(assignment.time / 60)
		local seconds = assignment.time - (minutes * 60)
		local timeAndOptionsString = ""
		if assignment.combatLogEventType and assignment.combatLogEventSpellID and assignment.spellCount then
			timeAndOptionsString = format(
				"{time:%d:%02d,%s:%d:%d}",
				minutes,
				seconds,
				assignment.combatLogEventType,
				assignment.combatLogEventSpellID,
				assignment.spellCount
			)
			-- Add spell icon and name so note is more readable
			local spellName = GetSpellName(assignment.combatLogEventSpellID)
			if spellName then
				local spellIconAndName = format("{spell:%d}%s", assignment.combatLogEventSpellID, spellName)
				timeAndOptionsString = timeAndOptionsString .. spellIconAndName
			end
		else
			timeAndOptionsString = format("{time:%d:%02d}", minutes, seconds)
		end

		return timeAndOptionsString
	end

	---@param assignment Assignment
	---@param roster RosterEntry
	---@return string
	---@return string
	local function CreateAssignmentExportString(assignment, roster)
		local assigneeString = assignment.assignee:gsub("%s*%-.*", "")
		local assignmentString = ""

		if roster[assignment.assignee] then
			local classColoredName = roster[assignment.assignee].classColoredName
			if classColoredName ~= "" then
				assigneeString = classColoredName:gsub("|", "||")
			end
		else
			local specMatch = assigneeString:match("spec:%s*(%d+)")
			local typeMatch = assigneeString:match("type:%s*(%a+)")
			if specMatch then
				local specIDMatch = tonumber(specMatch)
				if specIDMatch then
					local specName = GetLocalizedSpecNameFromSpecID(specIDMatch)
					if specIDMatch then
						assigneeString = "spec:" .. specName
					end
				end
			elseif typeMatch then
				assigneeString = "type:" .. typeMatch:sub(1, 1):upper() .. typeMatch:sub(2):lower()
			end
		end
		if assignment.targetName ~= nil and assignment.targetName ~= "" then
			if roster[assignment.targetName] and roster[assignment.targetName].classColoredName ~= "" then
				local classColoredName = roster[assignment.targetName].classColoredName
				assigneeString = assigneeString .. format(" @%s", classColoredName:gsub("|", "||"))
			else
				assigneeString = assigneeString .. format(" @%s", assignment.targetName)
			end
		end
		if assignment.spellID ~= nil and assignment.spellID > kTextAssignmentSpellID then
			assignmentString = format("{spell:%d}", assignment.spellID)
		end
		if assignment.text ~= nil and assignment.text ~= "" then
			if assignmentString:len() > 0 then
				assignmentString = assignmentString .. format(" {text}%s{/text}", assignment.text)
			else
				assignmentString = format("{text}%s{/text}", assignment.text)
			end
		end

		return assigneeString, assignmentString
	end

	-- Exports a plan in MRT/KAZE format.
	---@param plan Plan
	---@param bossDungeonEncounterID integer
	---@return string
	function Private:ExportPlanToNote(plan, bossDungeonEncounterID)
		local timelineAssignments = CreateTimelineAssignments(plan, bossDungeonEncounterID)
		sort(timelineAssignments, function(a, b)
			if a.startTime == b.startTime then
				return a.assignment.assignee < b.assignment.assignee
			end
			return a.startTime < b.startTime
		end)

		---@type table<integer, {timeAndOptions: string, assignmentsAndAssignees: table<string, table<integer, string>>}>
		local lines = {}
		local inLines = {}

		for _, timelineAssignment in ipairs(timelineAssignments) do
			local assignment = timelineAssignment.assignment
			local timeAndOptionsString, assigneeString, assignmentString = "", "", ""
			if getmetatable(timelineAssignment.assignment) == CombatLogEventAssignment then
				timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as CombatLogEventAssignment]])
				assigneeString, assignmentString = CreateAssignmentExportString(assignment, plan.roster)
			elseif getmetatable(timelineAssignment.assignment) == TimedAssignment then
				timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as TimedAssignment]])
				assigneeString, assignmentString = CreateAssignmentExportString(assignment, plan.roster)
			elseif getmetatable(timelineAssignment.assignment) == PhasedAssignment then
				-- Not yet supported
			end
			if timeAndOptionsString:len() > 0 and assigneeString:len() > 0 and assignmentString:len() > 0 then
				local linesTableIndex = inLines[timeAndOptionsString]
				if linesTableIndex then
					local line = lines[linesTableIndex]
					line.assignmentsAndAssignees[assignmentString] = line.assignmentsAndAssignees[assignmentString]
						or {}
					tinsert(line.assignmentsAndAssignees[assignmentString], assigneeString)
				else
					tinsert(lines, {
						timeAndOptions = timeAndOptionsString,
						assignmentsAndAssignees = { [assignmentString] = { assigneeString } },
					})
					inLines[timeAndOptionsString] = #lines
				end
			end
		end

		local returnTable = {}
		for _, line in ipairs(lines) do
			local fullLine = format("%s - ", line.timeAndOptions)
			for assignment, assignees in pairs(line.assignmentsAndAssignees) do
				fullLine = format("%s%s", fullLine, assignees[1]) -- Always expects at least one space
				for i = 2, #assignees do
					fullLine = format("%s,%s", fullLine, assignees[i])
				end
				fullLine = format("%s %s  ", fullLine, assignment)
			end
			tinsert(returnTable, fullLine:trim())
		end

		for _, line in ipairs(plan.content) do
			tinsert(returnTable, line)
		end

		if #returnTable > 0 then
			return concat(returnTable, "\n")
		end

		return ""
	end
end

-- Clears the current assignments and repopulates it from a string of assignments (note). Updates the roster.
---@param planName string the name of the existing plan in the database to parse/save the plan. If it does not exist,
-- an empty plan will be created.
---@param currentBossDungeonEncounterID integer The current boss dungeon encounter ID to use as a fallback.
---@param content string A string containing assignments.
---@return integer|nil -- Boss dungeon encounter ID for the plan.
function Private:ImportPlanFromNote(planName, currentBossDungeonEncounterID, content)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]

	if not plans[planName] then
		plans[planName] = Plan:New({}, planName)
	end
	local plan = plans[planName]

	local bossDungeonEncounterID = self.ParseNote(plan, SplitStringIntoTable(content))
	plan.dungeonEncounterID = bossDungeonEncounterID or currentBossDungeonEncounterID
	ChangePlanBoss(plan.dungeonEncounterID, plan)
	if not utilities.HasPrimaryPlan(AddOn.db.profile.plans, plan.dungeonEncounterID) then
		utilities.SwapPrimaryPlan(AddOn.db.profile.plans, plan.dungeonEncounterID)
	end

	UpdateRosterFromAssignments(plan.assignments, plan.roster)
	UpdateRosterDataFromGroup(plan.roster)
	for name, sharedRosterEntry in pairs(AddOn.db.profile.sharedRoster) do
		local planRosterEntry = plan.roster[name]
		if planRosterEntry then
			if planRosterEntry.class == "" then
				if sharedRosterEntry.class ~= "" then
					planRosterEntry.class = sharedRosterEntry.class
					if sharedRosterEntry.classColoredName ~= "" then
						planRosterEntry.classColoredName = sharedRosterEntry.classColoredName
					end
				end
			end
			if planRosterEntry.role == "" then
				if sharedRosterEntry.role and sharedRosterEntry.role ~= "" then
					planRosterEntry.role = sharedRosterEntry.role
				end
			end
			if planRosterEntry.classColoredName == "" then
				if planRosterEntry.class then
					local className = planRosterEntry.class:match("class:%s*(%a+)")
					if className then
						className = className:upper()
						if Private.spellDB.classes[className] then
							planRosterEntry.classColoredName = sharedRosterEntry.classColoredName
						end
					end
				end
			end
		end
	end
	return bossDungeonEncounterID
end

--@debug@
do
	---@class Test
	local test = Private.test
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	local CreateValuesTable = testUtilities.CreateValuesTable
	local TestContains = testUtilities.TestContains
	local TestEqual = testUtilities.TestEqual
	local RemoveTabs = testUtilities.RemoveTabs
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
            {time:65} type:melee {spell:235450}
        ]]

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
			ChangePlanBoss(plan.dungeonEncounterID, plan)
			UpdateRosterFromAssignments(plan.assignments, plan.roster)

			local exportString = Private:ExportPlanToNote(plan, bossDungeonEncounterID --[[@as integer]]) --[[@as string]]
			local exportStringTable = SplitStringIntoTable(exportString)
			for index, line in ipairs(exportStringTable) do
				TestEqual(line, textTable[index], "")
			end

			return "Export"
		end
	end
end
--@end-debug@
