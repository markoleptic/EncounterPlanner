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
local GetMaxSpellCount = bossUtilities.GetMaxSpellCount
local IsValidSpellCount = bossUtilities.IsValidSpellCount

---@class Utilities
local utilities = Private.utilities
local CreateTimelineAssignments = utilities.CreateTimelineAssignments
local GetLocalizedSpecNameFromSpecID = utilities.GetLocalizedSpecNameFromSpecID
local IsValidAssigneeNameOrRole = utilities.IsValidAssigneeNameOrRole
local SplitStringIntoTable = utilities.SplitStringIntoTable
local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup
local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments

local concat = table.concat
local format = string.format
local floor = math.floor
local GetSpellInfo = C_Spell.GetSpellInfo
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
-- postDashRegex = "([%w:,%s|%- ]+[ ]+%b{}[ ]-)"
local postOptionsPreDashNoSpellRegex = "}(.-) %-"
local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"
local removeFirstDashRegex = "%-+%s-([^\n]+)"
local spellIconRegex = "{spell:(%d+):?%d*}"
local stringWithoutSpellRegex = "(.*){spell:(%d+):?%d*}"
local targetNameRegex = "(@%S+)"
local textRegex = "{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}"
local timeOptionsSplitRegex = "{time:(%d+)[:%.]?(%d*),?([^{}]*)}"
local combatLogEventFromAbbreviation = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

---@alias OptionFailureReason
---|1 Invalid assignment type
---|2 Invalid combat log event type
---|3 Invalid combat log event spell ID
---|4 Invalid combat log event spell count
---|5 No spell count
---|6 Invalid assignee name or role
---|7 Invalid boss

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
	local removedFirstDash = line:match(removeFirstDashRegex)
	for str in (removedFirstDash .. "  "):gmatch(postDashRegex) do
		local spellInfo =
			{ name = "", iconID = 0, originalIconID = 0, castTime = 0, minRange = 0, maxRange = 0, spellID = 0 }
		local strWithoutSpell = str:gsub(stringWithoutSpellRegex, function(rest, id)
			spellInfo = GetSpellInfo(id)
			return rest
		end)
		local text = str:match(textRegex)
		if text then
			text = text:gsub("{everyone}", "") -- duplicate everyone
			text = text:gsub("^%s*", ""):gsub("$^%s*", "") -- remove beginning/trailing whitespace
			strWithoutSpell = strWithoutSpell:gsub(textRegex, "")
		end
		for _, entry in pairs(splitTable(",", strWithoutSpell:gsub("%s", ""))) do
			entry = entry:gsub(colorStartRegex, ""):gsub(colorEndRegex, "") -- Remove colors
			local targetName = nil
			entry = entry:gsub(targetNameRegex, function(target)
				if target then
					targetName = target:gsub("@", "") -- Extract target name
				end
				return "" -- Remove match
			end)
			local assigneeNameOrRole = IsValidAssigneeNameOrRole(entry)
			if assigneeNameOrRole then
				local assignment = Assignment:New({
					assigneeNameOrRole = assigneeNameOrRole,
					text = text,
					spellInfo = spellInfo,
					targetName = targetName,
				})
				if assignment.spellInfo.spellID == kInvalidAssignmentSpellID then
					if assignment.text:len() > 0 then
						assignment.spellInfo.spellID = kTextAssignmentSpellID
					end
				end
				tinsert(assignments, assignment)
			else
				tinsert(failed, { reason = 6, string = entry })
				failedCount = failedCount + 1
			end
		end

		-- elseif strWithoutSpell:gsub("%s", ""):len() > 0 then
		-- 	tinsert(failed, { reason = 6, string = strWithoutSpell })
		-- 	failedCount = failedCount + 1
		-- end
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
					if not IsValidSpellCount(bossDungeonEncounterID, spellID, spellCount) then
						spellCount = GetMaxSpellCount(bossDungeonEncounterID, spellID)
						tinsert(replaced, {
							reason = 4,
							string = option,
							replacedSpellCount = spellCount,
						})
						replacedInvalidSpellCount = true
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
	return true, false, false
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
---@return number|nil, string|nil
local function ParseTime(line)
	local minute, sec, options = line:match(timeOptionsSplitRegex)
	local time = nil
	if minute and sec then
		time = tonumber(sec) + (tonumber(minute) * 60)
	elseif minute and (sec == nil or sec == "") then
		time = tonumber(minute)
	end
	return time, options
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
				msg = format("%s: '%s'", L["Invalid assignee name or role"], value.string)
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
---@return integer|nil
local function ParseNote(plan, text)
	wipe(plan.assignments)
	local bossDungeonEncounterIDs = {} ---@type table<integer, {assignmentIDs: table<integer, integer>, string: string}>
	local lowerPriorityEncounterIDs = {} ---@type table<integer, integer>
	local otherContent = {}
	local failedOrReplaced = {} ---@type table<integer, FailureTableEntry>
	local failedCount, defaultedToTimedCount, defaultedSpellCount = 0, 0, 0

	for _, line in pairs(text) do
		local time, options = ParseTime(line)
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
			local inputs, count = CreateAssignmentsFromLine(line, failedOrReplaced)
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

	if #failedOrReplaced > 0 then
		LogFailures(failedOrReplaced, failedCount, defaultedToTimedCount, defaultedSpellCount)
	end

	return determinedBossDungeonEncounterID
end

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
		local spellInfo = GetSpellInfo(assignment.combatLogEventSpellID)
		if spellInfo then
			local spellIconAndName = format("{spell:%d}%s", assignment.combatLogEventSpellID, spellInfo.name)
			timeAndOptionsString = timeAndOptionsString .. spellIconAndName
		end
	else
		timeAndOptionsString = format("{time:%d:%02d}", minutes, seconds)
	end

	timeAndOptionsString = timeAndOptionsString .. " - "
	return timeAndOptionsString
end

---@param assignment Assignment
---@param roster RosterEntry
---@return string
local function CreateAssignmentExportString(assignment, roster)
	local assignmentString = assignment.assigneeNameOrRole

	if roster[assignment.assigneeNameOrRole] then
		local classColoredName = roster[assignment.assigneeNameOrRole].classColoredName
		if classColoredName ~= "" then
			assignmentString = classColoredName:gsub("|", "||")
		end
	else
		local specMatch = assignmentString:match("spec:%s*(%d+)")
		local typeMatch = assignmentString:match("type:%s*(%a+)")
		if specMatch then
			local specIDMatch = tonumber(specMatch)
			if specIDMatch then
				local specName = GetLocalizedSpecNameFromSpecID(specIDMatch)
				if specIDMatch then
					assignmentString = "spec:" .. specName
				end
			end
		elseif typeMatch then
			assignmentString = "type:" .. typeMatch:sub(1, 1):upper() .. typeMatch:sub(2):lower()
		end
	end
	if assignment.targetName ~= nil and assignment.targetName ~= "" then
		if roster[assignment.targetName] and roster[assignment.targetName].classColoredName ~= "" then
			local classColoredName = roster[assignment.targetName].classColoredName
			assignmentString = assignmentString .. format(" @%s", classColoredName:gsub("|", "||"))
		else
			assignmentString = assignmentString .. format(" @%s", assignment.targetName)
		end
	end
	if assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID > kTextAssignmentSpellID then
		local spellString = format(" {spell:%d}", assignment.spellInfo.spellID)
		assignmentString = assignmentString .. spellString
	end
	if assignment.text ~= nil and assignment.text ~= "" then
		local textString = format(" {text}%s{/text}", assignment.text)
		assignmentString = assignmentString .. textString
	end

	return assignmentString
end

-- Exports a plan in MRT/KAZE format.
---@param plan Plan
---@param bossDungeonEncounterID integer
---@return string|nil
function Private:ExportPlanToNote(plan, bossDungeonEncounterID)
	local timelineAssignments = CreateTimelineAssignments(plan.assignments, bossDungeonEncounterID)
	sort(timelineAssignments, function(a, b)
		if a.startTime == b.startTime then
			return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
		end
		return a.startTime < b.startTime
	end)

	local stringTable = {}
	local inStringTable = {}
	for _, timelineAssignment in ipairs(timelineAssignments) do
		local assignment = timelineAssignment.assignment
		local timeAndOptionsString, assignmentString = "", ""
		if getmetatable(timelineAssignment.assignment) == CombatLogEventAssignment then
			timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as CombatLogEventAssignment]])
			assignmentString = CreateAssignmentExportString(assignment, plan.roster)
		elseif getmetatable(timelineAssignment.assignment) == TimedAssignment then
			timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as TimedAssignment]])
			assignmentString = CreateAssignmentExportString(assignment, plan.roster)
		elseif getmetatable(timelineAssignment.assignment) == PhasedAssignment then
			-- Not yet supported
		end
		if timeAndOptionsString:len() > 0 and assignmentString:len() > 0 then
			local stringTableIndex = inStringTable[timeAndOptionsString]
			if stringTableIndex then
				stringTable[stringTableIndex] = stringTable[stringTableIndex] .. "  " .. assignmentString
			else
				tinsert(stringTable, timeAndOptionsString .. assignmentString)
				inStringTable[timeAndOptionsString] = #stringTable
			end
		end
	end

	for _, line in pairs(plan.content) do
		tinsert(stringTable, line)
	end

	if #stringTable == 0 then
		return nil
	end

	return concat(stringTable, "\n")
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

	local bossDungeonEncounterID = ParseNote(plan, SplitStringIntoTable(content))
	plan.dungeonEncounterID = bossDungeonEncounterID or currentBossDungeonEncounterID
	ChangePlanBoss(plan.dungeonEncounterID, plan)

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
