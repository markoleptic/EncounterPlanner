local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local concat = table.concat
local format = format
local floor = math.floor
local GetSpellInfo = C_Spell.GetSpellInfo
local ipairs = ipairs
local pairs = pairs
local split = string.split
local splitTable = strsplittable
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local wipe = wipe

---@class PhasedAssignment
local PhasedAssignment = Private.classes.PhasedAssignment
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment

local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"
local postOptionsPreDashNoSpellRegex = "}(.-) %-"
local postDashRegex = "([^ \n-][^\n-]-)  +"
-- postDashRegex = "([%w:,%s|%- ]+[ ]+%b{}[ ]-)"
local nonSymbolRegex = "[^ \n,%(%)%[%]_%$#@!&]+"
local textRegex = "{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}"
local removeFirstDashRegex = "%-+%s-([^\n]+)"

local colorStartRegex = "|?|c........"
local colorEndRegex = "|?|r"

local timeOptionsSplitRegex = "{time:(%d+)[:%.]?(%d*),?([^{}]*)}"
local nameRegex = "^(%S+)"
local targetNameRegex = "@(%S+)"
local spellIconRegex = "{spell:(%d+):?%d*}"
local assigneeGroupRegex = "^({.-})"
local stringWithoutSpellRegex = "(.*){spell:(%d+):?%d*}"
local phaseNumberRegex = "^p(g?):?(.-)$"

local combatLogEventFromAbbreviation = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

-- Parses a line of text in the note and creates assignment(s).
---@param line string
---@return table<integer, Assignment>
local function CreateAssignmentsFromLine(line)
	local assignments = {}
	local removedFirstDash = line:match(removeFirstDashRegex)
	for str in (removedFirstDash):gmatch(postDashRegex) do
		local targetName = str:match(targetNameRegex)
		if targetName then
			targetName = targetName:gsub(colorStartRegex, ""):gsub(colorEndRegex, "")
		end
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
		local nameOrGroup = strWithoutSpell:match(assigneeGroupRegex) or strWithoutSpell:match(nameRegex)
		if nameOrGroup then
			for _, entry in pairs(splitTable(",", nameOrGroup)) do
				entry = entry:gsub(colorStartRegex, ""):gsub(colorEndRegex, "")
				local assigneeNameOrRole = utilities.IsValidAssigneeNameOrRole(entry)
				if assigneeNameOrRole then
					local assignment = Private.classes.Assignment:New({
						assigneeNameOrRole = assigneeNameOrRole,
						text = text,
						spellInfo = spellInfo,
						targetName = targetName,
					})
					if assignment.spellInfo.spellID == constants.kInvalidAssignmentSpellID then
						if assignment.text:len() > 0 then
							assignment.spellInfo.spellID = constants.kTextAssignmentSpellID
						end
					end
					tinsert(assignments, assignment)
				end
			end
		end
	end
	return assignments
end

-- Adds an assignment using a more derived type by parsing the options (comma-separated list after time).
---@param assignments table<integer, Assignment>
---@param derivedAssignments table<integer, Assignment>
---@param time number
---@param options string
local function ProcessOptions(assignments, derivedAssignments, time, options)
	local regularTimer = true
	local option = nil
	while options do
		option, options = split(",", options, 2)
		if option == "e" then
			if options then
				option, options = split(",", options, 2)
				if option then -- custom event
					-- TODO: Handle custom event
				end
			end
		elseif option:sub(1, 1) == "p" then
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
			local combatLogEventAbbreviation, spellIDStr, spellCountStr = split(":", option, 3)
			if combatLogEventFromAbbreviation[combatLogEventAbbreviation] then
				local spellID = tonumber(spellIDStr)
				local spellCount = tonumber(spellCountStr)
				if spellID then
					local bossDungeonEncounterID = bossUtilities.GetBossDungeonEncounterIDFromSpellID(spellID)
					if bossDungeonEncounterID then
						if spellCount then
							if bossUtilities.IsValidSpellCount(bossDungeonEncounterID, spellID, spellCount) then
							else
								spellCount = bossUtilities.GetMaxSpellCount(bossDungeonEncounterID, spellID)
							end
						else
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
							end
							regularTimer = false
						end
					end
				end
			end
		end
	end
	if regularTimer then
		for _, assignment in pairs(assignments) do
			local timedAssignment = TimedAssignment:New(assignment)
			timedAssignment.time = time
			tinsert(derivedAssignments, timedAssignment)
		end
	end
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

-- Repopulates assignments for the note based on the note content. Returns a boss name if one was found using spellIDs
-- in the text.
---@param plan Plan Plan to repopulate
---@param text table<integer, string> content
---@return integer|nil
local function ParseNote(plan, text)
	wipe(plan.assignments)
	local bossDungeonEncounterID = nil
	local otherContent = {}

	for _, line in pairs(text) do
		local time, options = ParseTime(line)
		if time and options then
			local spellID, generalText = line:match(postOptionsPreDashRegex)
			local spellIDNumber = nil
			if spellID then
				spellIDNumber = tonumber(spellID)
				if not bossDungeonEncounterID and spellIDNumber then
					bossDungeonEncounterID = bossUtilities.GetBossDungeonEncounterIDFromSpellID(spellIDNumber)
				end
			else
				generalText = line:match(postOptionsPreDashNoSpellRegex)
			end
			local inputs = CreateAssignmentsFromLine(line)
			ProcessOptions(inputs, plan.assignments, time, options)
		else
			if line:gsub("%s", ""):len() ~= 0 then
				tinsert(otherContent, line)
			end
		end
	end

	plan.content = otherContent

	if not bossDungeonEncounterID then
		for _, assignment in ipairs(plan.assignments) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				local maybeID = bossUtilities.GetBossDungeonEncounterIDFromSpellID(
					assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				)
				if maybeID then
					bossDungeonEncounterID = maybeID
					break
				end
			end
		end
	end

	return bossDungeonEncounterID
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
		timeAndOptionsString = string.format("{time:%d:%02d}", minutes, seconds)
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
				local specName = utilities.GetLocalizedSpecNameFromSpecID(specIDMatch)
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
			assignmentString = assignmentString .. string.format(" @%s", classColoredName:gsub("|", "||"))
		else
			assignmentString = assignmentString .. string.format(" @%s", assignment.targetName)
		end
	end
	if assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID > constants.kTextAssignmentSpellID then
		local spellString = string.format(" {spell:%d}", assignment.spellInfo.spellID)
		assignmentString = assignmentString .. spellString
	end
	if assignment.text ~= nil and assignment.text ~= "" then
		local textString = string.format(" {text}%s{/text}", assignment.text)
		assignmentString = assignmentString .. textString
	end

	return assignmentString
end

-- Exports a plan in MRT/KAZE format.
---@param plan Plan
---@param bossDungeonEncounterID integer
---@return string|nil
function Private:ExportPlanToNote(plan, bossDungeonEncounterID)
	local timelineAssignments = utilities.CreateTimelineAssignments(plan.assignments, bossDungeonEncounterID)
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
		if getmetatable(timelineAssignment.assignment) == Private.classes.CombatLogEventAssignment then
			timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as CombatLogEventAssignment]])
			assignmentString = CreateAssignmentExportString(assignment, plan.roster)
		elseif getmetatable(timelineAssignment.assignment) == Private.classes.TimedAssignment then
			timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as TimedAssignment]])
			assignmentString = CreateAssignmentExportString(assignment, plan.roster)
		elseif getmetatable(timelineAssignment.assignment) == Private.classes.PhasedAssignment then
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
		plans[planName] = Private.classes.Plan:New({}, planName)
	end
	local plan = plans[planName]

	local bossDungeonEncounterID = ParseNote(plan, utilities.SplitStringIntoTable(content))
	plan.dungeonEncounterID = bossDungeonEncounterID or currentBossDungeonEncounterID

	if plan.dungeonEncounterID ~= currentBossDungeonEncounterID then
		wipe(plan.customPhaseDurations)
	end

	bossUtilities.ChangePlanBoss(plan.dungeonEncounterID, plan)

	utilities.UpdateRosterFromAssignments(plan.assignments, plan.roster)
	utilities.UpdateRosterDataFromGroup(plan.roster)
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
