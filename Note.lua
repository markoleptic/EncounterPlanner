local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local AddOn = Private.addOn
local concat = table.concat
local format = format
local floor = math.floor
local GetClassInfo = GetClassInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellTexture = C_Spell.GetSpellTexture
local ipairs = ipairs
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local IsInRaid = IsInRaid
local pairs = pairs
local print = print
local select = select
local split = string.split
local splitTable = strsplittable
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitClass = UnitClass
local UnitName = UnitName
local wipe = wipe

local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"
local postOptionsPreDashNoSpellRegex = "}(.-) %-"
local postDashRegex = "([^ \n-][^\n-]-)  +"
local nonSymbolRegex = "[^ \n,%(%)%[%]_%$#@!&]+"

local healerRegex = "{[Hh]}.-{/[Hh]}"
local tankRegex = "{[Tt]}.-{/[Tt]}"
local dpsRegex = "{[Dd]}.-{/[Dd]}"
local groupRegex = "{(!?)[Gg](%d+)}(.-){/[Gg]}"
local playerRegex = "{(!?)[Pp]:([^}]+)}(.-){/[Pp]}"
local classRegex = "{(!?)[Cc]:([^}]+)}(.-){/[Cc]}"
local raceRegex = "{(!?)[Rr][Aa][Cc][Ee]:([^}]+)}(.-){/[Rr][Aa][Cc][Ee]}"
local textRegex = "{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}"

local colorStartRegex = "|?|c........"
local colorEndRegex = "|?|r"

local timeOptionsSplitRegex = "{time:(%d+)[:%.]?(%d*),?([^{}]*)}"
local nameRegex = "^(%S+)"
local targetNameRegex = "@(%S+)"
local spellIconRegex = "{spell:(%d+):?%d*}"
local assigneeGroupRegex = "^({.-})"
local stringWithoutSpellRegex = "(.*){spell:(%d+):?%d*}"
local raidIconRegex = "{icon:([^}]+)}"
local ertIconRegex = "%b{}"
local phaseNumberRegex = "^p(g?):?(.-)$"

local genericIcons = setmetatable({
	["{star}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" .. ":0|t",
	["{circle}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" .. ":0|t",
	["{diamond}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" .. ":0|t",
	["{triangle}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" .. ":0|t",
	["{moon}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" .. ":0|t",
	["{square}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" .. ":0|t",
	["{cross}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" .. ":0|t",
	["{skull}"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" .. ":0|t",
	["{wow}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-WoWicon" .. ":16|t",
	["{d3}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-D3icon" .. ":16|t",
	["{sc2}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Sc2icon" .. ":16|t",
	["{bnet}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Portrait" .. ":16|t",
	["{bnet1}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Battleneticon" .. ":16|t",
	["{alliance}"] = "|T" .. "Interface\\FriendsFrame\\PlusManz-Alliance" .. ":16|t",
	["{horde}"] = "|T" .. "Interface\\FriendsFrame\\PlusManz-Horde" .. ":16|t",
	["{hots}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-HotSicon" .. ":16|t",
	["{ow}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Overwatchicon" .. ":16|t",
	["{sc1}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-SCicon" .. ":16|t",
	["{barcade}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-BlizzardArcadeCollectionicon" .. ":16|t",
	["{crashb}"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-CrashBandicoot4icon" .. ":16|t",
	["{tank}"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:0:19:22:41|t",
	["{healer}"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:1:20|t",
	["{dps}"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:22:41|t",
}, {
	__index = function(tbl, key)
		if type(key) == "string" then
			key = key:lower()
			key = key:gsub("%s", "")
		end
		return rawget(tbl, key)
	end,
	__newindex = function(tbl, key, value)
		if type(key) == "string" then
			key = key:lower()
			key = key:gsub("%s", "")
		end
		rawset(tbl, key, value)
	end,
})

for i = 1, 8 do
	local icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ":0|t"
	genericIcons[format("{rt%d}", i)] = icon
end

local classList = {}

for i = 1, 13 do
	local className, _, classID = GetClassInfo(i)
	local classNameWithoutSpaces = className:gsub(" ", "")
	local classIcon = "|T" .. "Interface\\Icons\\ClassIcon_" .. classNameWithoutSpaces .. ":0|t"
	genericIcons[format("{%s}", className)] = classIcon
	genericIcons[format("{%d}", classID)] = classIcon
	if classNameWithoutSpaces == "DeathKnight" then
		genericIcons["{dk}"] = classIcon
	elseif classNameWithoutSpaces == "DemonHunter" then
		genericIcons["{dh}"] = classIcon
	end
	classList[classID] = i
end

local combatLogEventFromAbbreviation = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

---@return integer
local function GetGroupNumber()
	local playerName, _ = UnitName("player")
	local myGroup = 1
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if name == playerName then
				myGroup = subgroup
				break
			end
		end
	end
	return myGroup
end

---@param anti string (!)
---@param groups string (1,2)
---@param msg string (entire message for group number)
---@return string
local function GsubGroup(anti, groups, msg)
	local found = groups:find(tostring(GetGroupNumber()))
	if (found and anti:len() == 0) or (not found and anti == "!") then
		return msg
	else
		return ""
	end
end

---@param anti string (!)
---@param list string
---@param msg string
---@return string
local function GSubPlayer(anti, list, msg)
	local playerName, _ = UnitName("player")
	local tableList = splitTable(",", list)
	local found = false
	local myName = playerName:lower()
	for i = 1, #tableList do
		tableList[i] = tableList[i]:gsub(colorStartRegex, ""):gsub(colorEndRegex, ""):lower()
		if tableList[i] == myName then
			found = true
			break
		end
	end
	if (found and anti:len() == 0) or (not found and anti == "!") then
		return msg
	else
		return ""
	end
end

---@param anti string (!)
---@param list string
---@param msg string
---@return string
local function GSubClass(anti, list, msg)
	local tableList = splitTable(",", list)
	local classID = select(3, UnitClass("player"))
	local found = false
	for i = 1, #tableList do
		tableList[i] = tableList[i]:gsub(colorStartRegex, ""):gsub(colorEndRegex, ""):lower()
		if classList[tableList[i]] == classID then
			found = true
			break
		end
	end

	if (found and anti == "") or (not found and anti == "!") then
		return msg
	else
		return ""
	end
end

---@param anti string (!)
---@param list string
---@param msg string
---@return string
local function GSubRace(anti, list, msg)
	local tableList = splitTable(",", list)
	local race = select(2, UnitRace("player")):lower()
	local found = false
	for i = 1, #tableList do
		tableList[i] = tableList[i]:gsub(colorStartRegex, ""):gsub(colorEndRegex, ""):lower()
		if tableList[i] == race then
			found = true
			break
		end
	end

	if (found and anti == "") or (not found and anti == "!") then
		return msg
	else
		return ""
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

-- Filters lines by the player's current role.
---@param lines string
---@return string
local function FilterByCurrentRole(lines)
	local spec = GetSpecialization() or nil
	if spec then
		local role = select(5, GetSpecializationInfo(spec))
		if role ~= "HEALER" then
			lines = lines:gsub(healerRegex, "")
		end
		if role ~= "TANK" then
			lines = lines:gsub(tankRegex, "")
		end
		if role ~= "DAMAGER" then
			lines = lines:gsub(dpsRegex, "")
		end
	end
	return lines
end

-- Filters based on group, player, class, race, and encounter.
---@param line string
---@return string
local function Filter(line)
	line = line:gsub(groupRegex, GsubGroup)
		:gsub(playerRegex, GSubPlayer)
		:gsub(classRegex, GSubClass)
		:gsub(raceRegex, GSubRace)
	return line
end

---@param spellID string
---@return string
local function GSubIcon(spellID)
	local spellTexture = GetSpellTexture(spellID)
	return "|T" .. (spellTexture or "Interface\\Icons\\INV_MISC_QUESTIONMARK") .. ":0|t"
end

-- Parses a line of text in the note and creates assignment(s).
---@param line string
---@param generalText string|nil
---@param generalTextSpellID number|nil
---@return table<integer, Assignment>
local function CreateAssignmentsFromLine(line, generalText, generalTextSpellID)
	local assignments = {}
	for str in (line .. "  "):gmatch(postDashRegex) do
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
		local nameOrGroup = strWithoutSpell:match(assigneeGroupRegex) or strWithoutSpell:match(nameRegex)
		if nameOrGroup then
			nameOrGroup = nameOrGroup:gsub(colorStartRegex, ""):gsub(colorEndRegex, "")
		end
		local text = str:match(textRegex)
		if text then
			text = text:gsub("{everyone}", "") -- duplicate everyone
		end
		if text then
			text = text:gsub("^%s*", ""):gsub("$^%s*", "") -- remove beginning/trailing whitespace
		end
		local assignment = Private.classes.Assignment:New({
			assigneeNameOrRole = nameOrGroup or "",
			text = text,
			spellInfo = spellInfo,
			targetName = targetName,
			-- generalText = generalText,
			-- generalTextSpellID = generalTextSpellID,
		})
		tinsert(assignments, assignment)
	end
	return assignments
end

-- Adds an assignment using a more derived type by parsing the options (comma-separated list after time).
---@param assignments table<integer, Assignment>
---@param derivedAssignments table<integer, Assignment>
---@param time number
---@param options string
function Private:ProcessOptions(assignments, derivedAssignments, time, options)
	local regularTimer = true
	local option = nil
	while options do
		option, options = split(",", options, 2)
		if option == "e" then
			if options then
				option, options = split(",", options, 2)
				if option then -- custom event
					-- TODO: Handle custom event
					regularTimer = false
				end
			end
		elseif option:sub(1, 1) == "p" then
			local _, phase = option:match(phaseNumberRegex)
			if phase and phase ~= "" then
				local phaseNumber = tonumber(phase)
				if phaseNumber then
					for _, assignment in pairs(assignments) do
						local phasedAssignment = self.classes.PhasedAssignment:New(assignment)
						phasedAssignment.time = time
						phasedAssignment.phase = phaseNumber
						tinsert(derivedAssignments, phasedAssignment)
					end
				end
				regularTimer = false
			end
		else
			local combatLogEventAbbreviation, spellIDStr, spellCountStr = split(":", option, 3)
			if combatLogEventFromAbbreviation[combatLogEventAbbreviation] then
				local spellID = tonumber(spellIDStr)
				local spellCount = tonumber(spellCountStr)
				if spellID and spellCount then
					for _, assignment in pairs(assignments) do
						local combatLogEventAssignment = self.classes.CombatLogEventAssignment:New(assignment)
						combatLogEventAssignment.combatLogEventType = combatLogEventAbbreviation
						combatLogEventAssignment.time = time
						combatLogEventAssignment.phase = nil
						combatLogEventAssignment.spellCount = spellCount
						combatLogEventAssignment.combatLogEventSpellID = spellID
						tinsert(derivedAssignments, combatLogEventAssignment)
					end
				end
				regularTimer = false
			end
		end
	end
	if regularTimer then
		for _, assignment in pairs(assignments) do
			local timedAssignment = self.classes.TimedAssignment:New(assignment)
			timedAssignment.time = time
			tinsert(derivedAssignments, timedAssignment)
		end
	end
end

-- Repopulates assignments for the note based on the note content. Returns a boss name if one was found using spellIDs
-- in the text.
---@param note Plan Plan to repopulate
---@return integer|nil
function Private:ParseNote(note)
	wipe(note.assignments)
	local bossDungeonEncounterID = nil

	for _, line in pairs(note.content) do
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
			local inputs = CreateAssignmentsFromLine(line, generalText, spellIDNumber)
			self:ProcessOptions(inputs, note.assignments, time, options)
		end
	end

	return bossDungeonEncounterID
end

---@param assignment Assignment
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@return string
function Private:CreateNotePreviewText(assignment, roster)
	local previewText = ""

	local rosterEntry = roster[assignment.assigneeNameOrRole]
	if rosterEntry and rosterEntry.classColoredName and rosterEntry.classColoredName ~= "" then
		previewText = rosterEntry.classColoredName or ""
	else
		previewText = assignment.assigneeNameOrRole
	end

	if assignment.targetName ~= nil and assignment.targetName ~= "" then
		local targetRosterEntry = roster[assignment.targetName]
		if targetRosterEntry and targetRosterEntry.classColoredName and targetRosterEntry.classColoredName ~= "" then
			previewText = previewText .. string.format(" @%s", targetRosterEntry.classColoredName)
		else
			previewText = previewText .. string.format(" @%s", assignment.targetName)
		end
	end

	if assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID ~= 0 then
		previewText = previewText .. string.format(" {spell:%d}", assignment.spellInfo.spellID)
	end

	if assignment.text ~= nil and assignment.text ~= "" then
		previewText = previewText .. string.format(" %s", assignment.text)
	end

	previewText =
		previewText:gsub(spellIconRegex, GSubIcon):gsub(raidIconRegex, "|T%1:16|t"):gsub(ertIconRegex, genericIcons)

	return previewText
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
---@param roster EncounterPlannerDbRosterEntry
---@return string
local function CreateAssignmentExportString(assignment, roster)
	local assignmentString = assignment.assigneeNameOrRole

	if roster[assignment.assigneeNameOrRole] then
		local classColoredName = roster[assignment.assigneeNameOrRole].classColoredName
		if classColoredName then
			assignmentString = classColoredName:gsub("|", "||")
		end
	end
	if assignment.targetName ~= nil and assignment.targetName ~= "" then
		if roster[assignment.targetName] and roster[assignment.targetName].classColoredName then
			local classColoredName = roster[assignment.targetName].classColoredName
			assignmentString = assignmentString .. string.format(" @%s", classColoredName:gsub("|", "||"))
		else
			assignmentString = assignmentString .. string.format(" @%s", assignment.targetName)
		end
	end
	if assignment.spellInfo.spellID ~= nil and assignment.spellInfo.spellID ~= 0 then
		local spellString = string.format(" {spell:%d}", assignment.spellInfo.spellID)
		assignmentString = assignmentString .. spellString
	end
	if assignment.text ~= nil and assignment.text ~= "" then
		local textString = string.format(" {text}%s{/text}", assignment.text)
		assignmentString = assignmentString .. textString
	end

	return assignmentString
end

---@param note Plan
---@return string|nil
function Private:ExportNote(note)
	local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
	if bossDungeonEncounterID then
		local timelineAssignments = utilities.CreateTimelineAssignments(note.assignments, bossDungeonEncounterID)
		sort(timelineAssignments, function(a, b)
			if a.startTime == b.startTime then
				return a.assignment.assigneeNameOrRole < b.assignment.assigneeNameOrRole
			end
			return a.startTime < b.startTime
		end)

		local stringTable = {}

		local lastNoteContentIndex = nil
		for index, line in ipairs(note.content) do
			local time, options = ParseTime(line)
			if time and options then
				lastNoteContentIndex = index
			else
				tinsert(stringTable, line)
			end
		end

		local inStringTable = {}
		for _, timelineAssignment in ipairs(timelineAssignments) do
			local assignment = timelineAssignment.assignment
			local timeAndOptionsString, assignmentString = "", ""
			if getmetatable(timelineAssignment.assignment) == Private.classes.CombatLogEventAssignment then
				timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as CombatLogEventAssignment]])
				assignmentString = CreateAssignmentExportString(assignment, note.roster)
			elseif getmetatable(timelineAssignment.assignment) == Private.classes.TimedAssignment then
				timeAndOptionsString = CreateTimeAndOptionsExportString(assignment --[[@as TimedAssignment]])
				assignmentString = CreateAssignmentExportString(assignment, note.roster)
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

		if lastNoteContentIndex then
			for index = lastNoteContentIndex + 1, #note.content do
				tinsert(stringTable, note.content[index])
			end
		end

		if #stringTable == 0 then
			return nil
		end
		return concat(stringTable, "\n")
	end
	return nil
end

-- Clears the current assignments and repopulates it. Updates the roster.
---@param epNoteName string the name of the existing note in the database to parse/save the note. If it does not exist,
-- an empty note will be created
---@param currentBossDungeonEncounterID integer
---@param parseMRTNote boolean? If true, the MRT shared note will be parsed, otherwise the existing note in the database
-- will be parsed.
---@return integer|nil
function Private:Note(epNoteName, currentBossDungeonEncounterID, parseMRTNote)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]

	if parseMRTNote then
		local loadingOrLoaded, loaded = IsAddOnLoaded("MRT")
		if not loadingOrLoaded and not loaded then
			print(format("%s: No note was loaded due to MRT not being installed.", AddOnName))
			return nil
		end
	end

	if not plans[epNoteName] then
		plans[epNoteName] = Private.classes.Plan:New(nil, epNoteName)
	end
	local note = plans[epNoteName]

	if parseMRTNote then
		if VMRT and VMRT.Note then
			local sharedMRTNote = VMRT.Note.Text1 or ""
			note.content = utilities.SplitStringIntoTable(sharedMRTNote)
		end
	end

	local bossDungeonEncounterID = self:ParseNote(note)
	note.dungeonEncounterID = bossDungeonEncounterID or currentBossDungeonEncounterID
	local boss = bossUtilities.GetBoss(note.dungeonEncounterID)
	if boss then
		note.dungeonEncounterID = boss.dungeonEncounterID
		note.instanceID = boss.instanceID
	end

	utilities.UpdateRosterFromAssignments(note.assignments, note.roster)
	utilities.UpdateRosterDataFromGroup(note.roster)
	for name, sharedRosterEntry in pairs(AddOn.db.profile.sharedRoster) do
		local noteRosterEntry = note.roster[name]
		if noteRosterEntry then
			if not noteRosterEntry.class or noteRosterEntry.class == "" then
				if sharedRosterEntry.class and sharedRosterEntry.class ~= "" then
					noteRosterEntry.class = sharedRosterEntry.class
					if sharedRosterEntry.classColoredName then
						noteRosterEntry.classColoredName = sharedRosterEntry.classColoredName
					end
				end
			end
			if not noteRosterEntry.role or noteRosterEntry.role == "" then
				if sharedRosterEntry.role and sharedRosterEntry.role ~= "" then
					noteRosterEntry.role = sharedRosterEntry.role
				end
			end
			if not noteRosterEntry.classColoredName or noteRosterEntry.classColoredName == "" then
				if noteRosterEntry.class then
					local className = noteRosterEntry.class:match("class:%s*(%a+)")
					if className then
						className = className:upper()
						if Private.spellDB.classes[className] then
							noteRosterEntry.classColoredName = sharedRosterEntry.classColoredName
						end
					end
				end
			end
		end
	end
	return bossDungeonEncounterID
end
