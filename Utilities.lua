local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
---@class Assignment
local Assignment = Private.classes.Assignment
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment
---@class Plan
local Plan = Private.classes.Plan
---@class PhasedAssignment
local PhasedAssignment = Private.classes.PhasedAssignment
---@class RosterEntry
local RosterEntry = Private.classes.RosterEntry
---@class TimelineAssignment
local TimelineAssignment = Private.classes.TimelineAssignment

---@class Constants
local constants = Private.constants
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local FindBossAbility = bossUtilities.FindBossAbility
local GetAbsoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable
local GetBoss = bossUtilities.GetBoss
local GetBossName = bossUtilities.GetBossName
local GetCumulativePhaseStartTime = bossUtilities.GetCumulativePhaseStartTime
local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases

local Ambiguate = Ambiguate
local ceil = math.ceil
local EJ_GetCreatureInfo = EJ_GetCreatureInfo
local EJ_SelectEncounter, EJ_GetEncounterInfo = EJ_SelectEncounter, EJ_GetEncounterInfo
local EJ_SelectInstance, EJ_GetInstanceInfo = EJ_SelectInstance, EJ_GetInstanceInfo
local floor = math.floor
local format = string.format
local GetClassColor = C_ClassColor.GetClassColor
local GetClassInfo = GetClassInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local hugeNumber = math.huge
local ipairs = ipairs
local IsInRaid = IsInRaid
local pairs = pairs
local print = print
local rawget = rawget
local rawset = rawset
local select = select
local setmetatable = setmetatable
local sort = table.sort
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitClass = UnitClass
local UnitFullName = UnitFullName
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitName = UnitName

local lineMatchRegex = "([^\r\n]+)"

do
	local kNumberOfClasses = 13

	local caseAndWhiteSpaceInsensitiveMetaTable = {
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
	}

	local prettyClassNames = setmetatable({}, caseAndWhiteSpaceInsensitiveMetaTable)
	local englishClassNamesWithoutSpaces = setmetatable({}, caseAndWhiteSpaceInsensitiveMetaTable)
	local localizedClassNames = setmetatable({}, caseAndWhiteSpaceInsensitiveMetaTable)
	local localizedTypes = setmetatable({
		["ranged"] = L["Ranged"],
		["melee"] = L["Melee"],
	}, caseAndWhiteSpaceInsensitiveMetaTable)
	local localizedRoles = setmetatable({
		["damager"] = L["Damager"],
		["healer"] = L["Healer"],
		["tank"] = L["Tank"],
	}, caseAndWhiteSpaceInsensitiveMetaTable)
	local specIDToName = {}
	local specIDToIconAndName = {}
	local specIDToType = {
		-- Mage
		[62] = "ranged", -- Arcane
		[63] = "ranged", -- Fire
		[64] = "ranged", -- Frost
		-- Paladin
		[65] = "melee", -- Holy
		[66] = "melee", -- Protection
		[70] = "melee", -- Retribution
		-- Warrior
		[71] = "melee", -- Arms
		[72] = "melee", -- Fury
		[73] = "melee", -- Protection
		-- Druid
		[102] = "ranged", -- Balance
		[103] = "melee", -- Feral
		[104] = "melee", -- Guardian
		[105] = "ranged", -- Restoration
		-- Death Knight
		[250] = "melee", -- Blood
		[251] = "melee", -- Frost
		[252] = "melee", -- Unholy
		-- Hunter
		[253] = "ranged", -- Beast Mastery
		[254] = "ranged", -- Marksmanship
		[255] = "melee", -- Survival
		-- Priest
		[256] = "ranged", -- Discipline
		[257] = "ranged", -- Holy
		[258] = "ranged", -- Shadow
		-- Rogue
		[259] = "melee", -- Assassination
		[260] = "melee", -- Outlaw
		[261] = "melee", -- Subtlety
		-- Shaman
		[262] = "ranged", -- Elemental
		[263] = "melee", -- Enhancement
		[264] = "ranged", -- Restoration
		-- Warlock
		[265] = "ranged", -- Affliction
		[266] = "ranged", -- Demonology
		[267] = "ranged", -- Destruction
		-- Monk
		[268] = "melee", -- Brewmaster
		[270] = "melee", -- Mistweaver
		[269] = "melee", -- Windwalker
		-- Demon Hunter
		[577] = "melee", -- Havoc
		[581] = "melee", -- Vengeance
		-- Evoker
		[1467] = "ranged", -- Devastation
		[1468] = "ranged", -- Preservation
		[1473] = "ranged", -- Augmentation
	}

	for specID, _ in pairs(specIDToType) do
		local _, name, _, icon, _ = GetSpecializationInfoByID(specID)
		specIDToIconAndName[specID] = format("|T%s:16|t %s", icon, name)
		specIDToName[specID] = name
	end

	local genericIcons = setmetatable({
		["star"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" .. ":0|t",
		["circle"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" .. ":0|t",
		["diamond"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" .. ":0|t",
		["triangle"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" .. ":0|t",
		["moon"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" .. ":0|t",
		["square"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" .. ":0|t",
		["cross"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" .. ":0|t",
		["skull"] = "|T" .. "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" .. ":0|t",
		["wow"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-WoWicon" .. ":16|t",
		["d3"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-D3icon" .. ":16|t",
		["sc2"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Sc2icon" .. ":16|t",
		["bnet"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Portrait" .. ":16|t",
		["bnet1"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Battleneticon" .. ":16|t",
		["alliance"] = "|T" .. "Interface\\FriendsFrame\\PlusManz-Alliance" .. ":16|t",
		["horde"] = "|T" .. "Interface\\FriendsFrame\\PlusManz-Horde" .. ":16|t",
		["hots"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-HotSicon" .. ":16|t",
		["ow"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-Overwatchicon" .. ":16|t",
		["sc1"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-SCicon" .. ":16|t",
		["barcade"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-BlizzardArcadeCollectionicon" .. ":16|t",
		["crashb"] = "|T" .. "Interface\\FriendsFrame\\Battlenet-CrashBandicoot4icon" .. ":16|t",
		["tank"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:0:19:22:41|t",
		["healer"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:1:20|t",
		["dps"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:22:41|t",
	}, caseAndWhiteSpaceInsensitiveMetaTable)

	for i = 1, 8 do
		local icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ":0|t"
		genericIcons[format("rt%d", i)] = icon
	end

	for i = 1, kNumberOfClasses do
		local className, classFile, classID = GetClassInfo(i)
		local enClassName
		if classFile == "DEATHKNIGHT" then
			enClassName = "DeathKnight"
		elseif classFile == "DEMONHUNTER" then
			enClassName = "DemonHunter"
		else
			enClassName = classFile:sub(1, 1):upper() .. classFile:sub(2):lower()
		end
		englishClassNamesWithoutSpaces[classFile] = enClassName

		localizedClassNames[classFile] = className

		local colorMixin = GetClassColor(classFile)
		local prettyClassName = colorMixin:WrapTextInColorCode(className)
		prettyClassNames[classFile] = prettyClassName
		prettyClassNames[className] = prettyClassName

		local classNameWithoutSpaces = className:gsub(" ", "")
		local classIcon = "|T" .. "Interface\\Icons\\ClassIcon_" .. classNameWithoutSpaces .. ":0|t"
		genericIcons[format("%s", classFile)] = classIcon
		genericIcons[format("%s", className)] = classIcon
		genericIcons[format("%d", classID)] = classIcon
	end

	---@param text string
	---@return string
	function Utilities.ReplaceGenericIcons(text)
		local result, _ = text:gsub("{(.-)}", function(match)
			return genericIcons[match] or ("{" .. match .. "}")
		end)
		return result
	end

	---@param className string
	---@return string|nil
	function Utilities.GetLocalizedPrettyClassName(className)
		return prettyClassNames[className]
	end

	---@param specID integer
	---@return string|nil
	function Utilities.GetSpecIconAndLocalizedSpecName(specID)
		return specIDToIconAndName[specID]
	end

	---@return table<integer, integer>
	function Utilities.GetSpecIDs()
		local IDs = {}
		for specID, _ in pairs(specIDToType) do
			tinsert(IDs, specID)
		end
		return IDs
	end

	---@param specID integer
	---@return string|nil
	function Utilities.GetTypeFromSpecID(specID)
		return specIDToType[specID]
	end

	---@param name string
	---@return integer|nil
	function Utilities.GetSpecIDFromSpecName(name)
		local normalizedSpecName = name:gsub("%s", ""):lower()
		for specID, specName in pairs(specIDToName) do
			if name == specName then
				return specID
			elseif normalizedSpecName == specName:gsub("%s", ""):lower() then
				return specID
			end
		end
		return nil
	end

	---@param specID integer
	---@return string|nil
	function Utilities.GetLocalizedSpecNameFromSpecID(specID)
		return specIDToName[specID]
	end

	---@param stringType string
	---@return string|nil
	function Utilities.GetLocalizedType(stringType)
		return localizedTypes[stringType]
	end

	---@param role string
	---@return string|nil
	function Utilities.GetLocalizedRole(role)
		return localizedRoles[role]
	end

	---@param name string
	---@return string|nil
	function Utilities.GetEnglishClassNameWithoutSpaces(name)
		return englishClassNamesWithoutSpaces[name]
	end

	---@param specID integer
	---@return boolean
	function Utilities.IsValidSpecID(specID)
		return specIDToType[specID] ~= nil
	end

	---@param stringType string
	---@return boolean
	function Utilities.IsValidType(stringType)
		return localizedTypes[stringType] ~= nil
	end

	---@param role string
	---@return boolean
	function Utilities.IsValidRole(role)
		return localizedRoles[role] ~= nil
	end
end

---@param value number
---@param precision integer
---@return number
function Utilities.Round(value, precision)
	local factor = 10 ^ precision
	if value > 0 then
		return floor(value * factor + 0.5) / factor
	else
		return ceil(value * factor - 0.5) / factor
	end
end

---@param value number
---@param minValue number
---@param maxValue number
---@return number
function Utilities.Clamp(value, minValue, maxValue)
	return min(maxValue, max(minValue, value))
end

---@param plans table<string, Plan>
---@param bossName string
---@param existingName string|nil
---@return string
function Utilities.CreateUniquePlanName(plans, bossName, existingName)
	local newPlanName = existingName or bossName
	if plans then
		local baseName, suffix = newPlanName:match("^(.-)%s*(%d*)$")
		baseName = baseName or ""
		local num = tonumber(suffix) or 1

		if plans[newPlanName] then
			num = suffix ~= "" and (num + 1) or 2
			newPlanName = baseName .. " " .. num
		end

		while plans[newPlanName] do
			if #baseName > 0 then
				newPlanName = baseName .. " " .. num
			else
				newPlanName = tostring(num)
			end
			num = num + 1
		end
	end
	return newPlanName
end

---@param assignments table<integer, Assignment>
---@param ID integer
---@return Assignment|nil
function Utilities.FindAssignmentByUniqueID(assignments, ID)
	for _, assignment in pairs(assignments) do
		if assignment.uniqueID == ID then
			return assignment
		end
	end
end

---@param time number
---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.ConvertCombatLogEventTimeToAbsoluteTime(
	time,
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	if absoluteSpellCastStartTable then
		if
			absoluteSpellCastStartTable[combatLogEventSpellID]
			and absoluteSpellCastStartTable[combatLogEventSpellID][spellCount]
		then
			local adjustedTime = absoluteSpellCastStartTable[combatLogEventSpellID][spellCount].castStart + time
			local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
			if ability then
				if combatLogEventType == "SAR" then
					adjustedTime = adjustedTime + ability.duration + ability.castTime
				elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
					adjustedTime = adjustedTime + ability.castTime
				end
			end
			return adjustedTime
		end
	end
	return nil
end

---@param absoluteTime number
---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.ConvertAbsoluteTimeToCombatLogEventTime(
	absoluteTime,
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	if absoluteSpellCastStartTable then
		if
			absoluteSpellCastStartTable[combatLogEventSpellID]
			and absoluteSpellCastStartTable[combatLogEventSpellID][spellCount]
		then
			local adjustedTime = absoluteTime - absoluteSpellCastStartTable[combatLogEventSpellID][spellCount].castStart
			local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
			if ability then
				if combatLogEventType == "SAR" then
					adjustedTime = adjustedTime - ability.duration - ability.castTime
				elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
					adjustedTime = adjustedTime - ability.castTime
				end
			end
			return adjustedTime
		end
	end
	return nil
end

---@param bossDungeonEncounterID integer
---@param combatLogEventSpellID integer
---@param spellCount integer
---@param combatLogEventType CombatLogEventType
---@return number|nil
function Utilities.GetMinimumCombatLogEventTime(
	bossDungeonEncounterID,
	combatLogEventSpellID,
	spellCount,
	combatLogEventType
)
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	if absoluteSpellCastStartTable then
		if
			absoluteSpellCastStartTable[combatLogEventSpellID]
			and absoluteSpellCastStartTable[combatLogEventSpellID][spellCount]
		then
			local time = absoluteSpellCastStartTable[combatLogEventSpellID][spellCount].castStart
			local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
			if ability then
				if combatLogEventType == "SAR" then
					time = time + ability.duration + ability.castTime
				elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
					time = time + ability.castTime
				end
			end
			return time
		end
	end
	return nil
end

---@param absoluteTime number The time from the beginning of the boss encounter
---@param bossDungeonEncounterID integer
---@param combatLogEventType CombatLogEventType Type of combat log event for more accurate findings
---@param allowBefore boolean? If specified, combat log events will be chosen before the time if none can be found without doing so.
---@return integer|nil -- combat log event Spell ID
---@return integer|nil -- spell count
---@return number|nil -- leftover time offset
function Utilities.FindNearestCombatLogEvent(absoluteTime, bossDungeonEncounterID, combatLogEventType, allowBefore)
	local minTime = hugeNumber
	local combatLogEventSpellIDForMinTime = nil
	local spellCountForMinTime = nil
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	if absoluteSpellCastStartTable then
		if allowBefore then
			local minTimeBefore = hugeNumber
			local combatLogEventSpellIDForMinTimeBefore = nil
			local spellCountForMinTimeBefore = nil
			for combatLogEventSpellID, spellCountAndTime in pairs(absoluteSpellCastStartTable) do
				local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
				for spellCount, time in pairs(spellCountAndTime) do
					local adjustedTime = time.castStart
					if ability then
						if combatLogEventType == "SAR" then
							adjustedTime = adjustedTime + ability.duration + ability.castTime
						elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
							adjustedTime = adjustedTime + ability.castTime
						end
					end
					if adjustedTime <= absoluteTime then
						local difference = absoluteTime - adjustedTime
						if difference < minTime then
							minTime = difference
							combatLogEventSpellIDForMinTime = combatLogEventSpellID
							spellCountForMinTime = spellCount
						end
					else
						local difference = adjustedTime - absoluteTime
						if difference < minTimeBefore then
							minTimeBefore = difference
							combatLogEventSpellIDForMinTimeBefore = combatLogEventSpellID
							spellCountForMinTimeBefore = spellCount
						end
					end
				end
			end
			if not combatLogEventSpellIDForMinTime and not spellCountForMinTime then
				minTime = minTimeBefore
				combatLogEventSpellIDForMinTime = combatLogEventSpellIDForMinTimeBefore
				spellCountForMinTime = spellCountForMinTimeBefore
			end
		else
			for combatLogEventSpellID, spellCountAndTime in pairs(absoluteSpellCastStartTable) do
				local ability = FindBossAbility(bossDungeonEncounterID, combatLogEventSpellID)
				for spellCount, time in pairs(spellCountAndTime) do
					local adjustedTime = time.castStart
					if ability then
						if combatLogEventType == "SAR" then
							adjustedTime = adjustedTime + ability.duration + ability.castTime
						elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
							adjustedTime = adjustedTime + ability.castTime
						end
					end
					if adjustedTime <= absoluteTime then
						local difference = absoluteTime - adjustedTime
						if difference < minTime then
							minTime = difference
							combatLogEventSpellIDForMinTime = combatLogEventSpellID
							spellCountForMinTime = spellCount
						end
					end
				end
			end
		end
	end
	if combatLogEventSpellIDForMinTime and spellCountForMinTime then
		return combatLogEventSpellIDForMinTime, spellCountForMinTime, minTime
	end
	return nil
end

---@param relativeTime number Time relative to the combat log event.
---@param bossDungeonEncounterID integer
---@param currentCombatLogEventType CombatLogEventType Type of combat log event.
---@param currentCombatLogEventSpellID integer
---@param currentSpellCount integer
---@param newCombatLogEventSpellID integer
---@param allowBefore boolean? If specified, spell will be chosen before the time if none can be found without doing so.
---@return integer|nil -- spell count
---@return number|nil -- leftover time offset
function Utilities.FindNearestSpellCount(
	relativeTime,
	bossDungeonEncounterID,
	currentCombatLogEventType,
	currentCombatLogEventSpellID,
	currentSpellCount,
	newCombatLogEventSpellID,
	allowBefore
)
	local absoluteTime = Utilities.ConvertCombatLogEventTimeToAbsoluteTime(
		relativeTime,
		bossDungeonEncounterID,
		currentCombatLogEventSpellID,
		currentSpellCount,
		currentCombatLogEventType
	)
	local minTime = hugeNumber
	local spellCountForMinTime = nil
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	if absoluteSpellCastStartTable and absoluteSpellCastStartTable[newCombatLogEventSpellID] then
		local spellCountAndTime = absoluteSpellCastStartTable[newCombatLogEventSpellID]
		local ability = FindBossAbility(bossDungeonEncounterID, newCombatLogEventSpellID)
		if allowBefore then
			local minTimeBefore = hugeNumber
			local spellCountForMinTimeBefore = nil
			for spellCount, time in pairs(spellCountAndTime) do
				local adjustedTime = time.castStart
				if ability then
					if currentCombatLogEventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif currentCombatLogEventType == "SCC" or currentCombatLogEventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime <= absoluteTime then
					local difference = absoluteTime - adjustedTime
					if difference < minTime then
						minTime = difference
						spellCountForMinTime = spellCount
					end
				else
					local difference = adjustedTime - absoluteTime
					if difference < minTimeBefore then
						minTimeBefore = difference
						spellCountForMinTimeBefore = spellCount
					end
				end
			end
			if not spellCountForMinTime then
				minTime = minTimeBefore
				spellCountForMinTime = spellCountForMinTimeBefore
			end
		else
			for spellCount, time in pairs(spellCountAndTime) do
				local adjustedTime = time.castStart
				if ability then
					if currentCombatLogEventType == "SAR" then
						adjustedTime = adjustedTime + ability.duration + ability.castTime
					elseif currentCombatLogEventType == "SCC" or currentCombatLogEventType == "SAA" then
						adjustedTime = adjustedTime + ability.castTime
					end
				end
				if adjustedTime <= absoluteTime then
					local difference = absoluteTime - adjustedTime
					if difference < minTime then
						minTime = difference
						spellCountForMinTime = spellCount
					end
				end
			end
		end
	end
	if spellCountForMinTime then
		return spellCountForMinTime, minTime
	end
	return nil
end

---@alias AssignmentConversionMethod
---| 1 # Convert combat log event assignments to timed assignments
---| 2 # Replace combat log event spells with those of the new boss, matching the closest timing

---@param assignments table<integer, Assignment|CombatLogEventAssignment>
---@param oldBoss Boss
---@param newBoss Boss
---@param conversionMethod AssignmentConversionMethod
function Utilities.ConvertAssignmentsToNewBoss(assignments, oldBoss, newBoss, conversionMethod)
	if conversionMethod == 1 then
		for _, assignment in ipairs(assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				local convertedTime = Utilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldBoss.dungeonEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType
				)
				if convertedTime then
					assignment = TimedAssignment:New(assignment, true)
					assignment.time = Utilities.Round(convertedTime, 1)
				end
			end
		end
	elseif conversionMethod == 2 then
		for _, assignment in ipairs(assignments) do
			if
				getmetatable(assignment --[[@as CombatLogEventAssignment]]) == CombatLogEventAssignment
			then
				local absoluteTime = Utilities.ConvertCombatLogEventTimeToAbsoluteTime(
					assignment.time,
					oldBoss.dungeonEncounterID,
					assignment.combatLogEventSpellID,
					assignment.spellCount,
					assignment.combatLogEventType
				)
				if absoluteTime then
					local newCombatLogEventSpellID, newSpellCount, newTime = Utilities.FindNearestCombatLogEvent(
						absoluteTime,
						newBoss.dungeonEncounterID,
						assignment.combatLogEventType,
						true
					)
					if newCombatLogEventSpellID and newSpellCount and newTime then
						local castTimeTable = GetAbsoluteSpellCastTimeTable(newBoss.dungeonEncounterID)
						local bossPhaseTable = GetOrderedBossPhases(newBoss.dungeonEncounterID)
						if castTimeTable and bossPhaseTable then
							if
								castTimeTable[newCombatLogEventSpellID]
								and castTimeTable[newCombatLogEventSpellID][newSpellCount]
							then
								local orderedBossPhaseIndex =
									castTimeTable[newCombatLogEventSpellID][newSpellCount].bossPhaseOrderIndex
								assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
								assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
							end
						end
						assignment.time = Utilities.Round(newTime, 1)
						assignment.combatLogEventSpellID = newCombatLogEventSpellID
						assignment.spellCount = newSpellCount
					end
				end
			end
		end
	end
end

---@return DropdownItemData
local function CreateSpellDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for className, classSpells in pairs(Private.spellDB.classes) do
		local classDropdownData = {
			itemValue = className,
			text = Utilities.GetLocalizedPrettyClassName(className),
			dropdownItemMenuData = {},
		}
		local spellTypeIndex = 1
		local spellTypeIndexMap = {}
		for _, spell in pairs(classSpells) do
			if not spellTypeIndexMap[spell["type"]] then
				classDropdownData.dropdownItemMenuData[spellTypeIndex] = {
					itemValue = spell["type"],
					text = spell["type"],
					dropdownItemMenuData = {},
				}
				spellTypeIndexMap[spell["type"]] = spellTypeIndex
				spellTypeIndex = spellTypeIndex + 1
			end
			local name = GetSpellName(spell["spellID"])
			local iconText = format("|T%s:16|t %s", spell["icon"], name)
			local spellID = spell["commonSpellID"] or spell["spellID"]
			tinsert(classDropdownData.dropdownItemMenuData[spellTypeIndexMap[spell["type"]]].dropdownItemMenuData, {
				itemValue = spellID,
				text = iconText,
			})
		end
		tinsert(dropdownItems, classDropdownData)
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Class", text = L["Class"], dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
local function CreateRacialDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for _, racialInfo in pairs(Private.spellDB.other["RACIAL"]) do
		local name = GetSpellName(racialInfo["spellID"])
		local iconText = format("|T%s:16|t %s", racialInfo["icon"], name)
		tinsert(dropdownItems, {
			itemValue = racialInfo["spellID"],
			text = iconText,
		})
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Racial", text = L["Racial"], dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
local function CreateTrinketDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for _, trinketInfo in pairs(Private.spellDB.other["TRINKET"]) do
		local name = GetSpellName(trinketInfo["spellID"])
		local iconText = format("|T%s:16|t %s", trinketInfo["icon"], name)
		tinsert(dropdownItems, {
			itemValue = trinketInfo["spellID"],
			text = iconText,
		})
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Trinket", text = L["Trinket"], dropdownItemMenuData = dropdownItems }
end

---@return DropdownItemData
function Utilities.CreateSpellAssignmentDropdownItems()
	return { CreateSpellDropdownItems(), CreateRacialDropdownItems(), CreateTrinketDropdownItems() }
end

---@return DropdownItemData
local function CreateSpecDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	for _, specID in ipairs(Utilities.GetSpecIDs()) do
		tinsert(dropdownItems, {
			itemValue = "spec:" .. tostring(specID),
			text = Utilities.GetSpecIconAndLocalizedSpecName(specID),
		})
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return { itemValue = "Spec", text = L["Spec"], dropdownItemMenuData = dropdownItems }
end

---@return table<integer, DropdownItemData>
function Utilities.CreateClassDropdownItemData()
	local dropdownData = {}

	for className, _ in pairs(Private.spellDB.classes) do
		local actualClassName
		if className == "DEATHKNIGHT" then
			actualClassName = "DeathKnight"
		elseif className == "DEMONHUNTER" then
			actualClassName = "DemonHunter"
		else
			actualClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		local classDropdownData = {
			itemValue = "class:" .. actualClassName:gsub("%s", ""),
			text = Utilities.GetLocalizedPrettyClassName(className),
		}
		tinsert(dropdownData, classDropdownData)
	end

	Utilities.SortDropdownDataByItemValue(dropdownData)
	return dropdownData
end

---@return table<integer, DropdownItemData>
function Utilities.CreateAssignmentTypeDropdownItems()
	local assignmentTypes = {
		{
			text = L["Group Number"],
			itemValue = "Group Number",
			dropdownItemMenuData = {
				{ text = L["1"], itemValue = "group:1" },
				{ text = L["2"], itemValue = "group:2" },
				{ text = L["3"], itemValue = "group:3" },
				{ text = L["4"], itemValue = "group:4" },
			},
		},
		{
			text = L["Role"],
			itemValue = "Role",
			dropdownItemMenuData = {
				{ text = L["Damager"], itemValue = "role:damager" },
				{ text = L["Healer"], itemValue = "role:healer" },
				{ text = L["Tank"], itemValue = "role:tank" },
			},
		},
		{
			text = "Type",
			itemValue = "Type",
			dropdownItemMenuData = {
				{ text = "Melee", itemValue = "type:melee" },
				{ text = "Ranged", itemValue = "type:ranged" },
			},
		},
		{ text = L["Everyone"], itemValue = "{everyone}" },
		{
			text = L["Individual"],
			itemValue = "Individual",
			dropdownItemMenuData = {},
		},
	} --[[@as table<integer, DropdownItemData>]]

	local classAssignmentTypes = {
		text = L["Class"],
		itemValue = "Class",
		dropdownItemMenuData = Utilities.CreateClassDropdownItemData(),
	}

	tinsert(assignmentTypes, classAssignmentTypes)
	tinsert(assignmentTypes, CreateSpecDropdownItems())

	Utilities.SortDropdownDataByItemValue(assignmentTypes)

	return assignmentTypes
end

---@param roster table<string, RosterEntry>
---@return table<integer, DropdownItemData>
function Utilities.CreateAssigneeDropdownItems(roster)
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	if roster then
		for normalName, rosterTable in pairs(roster) do
			tinsert(dropdownItems, {
				itemValue = normalName,
				text = rosterTable.classColoredName ~= "" and rosterTable.classColoredName or normalName,
			})
		end
	end
	Utilities.SortDropdownDataByItemValue(dropdownItems)
	return dropdownItems
end

-- Creates dropdown data with all assignments types including individual roster members.
---@param roster table<string, RosterEntry> Roster to character names from
---@param assignmentTypeDropdownItems? table<integer, DropdownItemData>
---@param assigneeDropdownItems? table<integer, DropdownItemData>
---@return table<integer, DropdownItemData>
function Utilities.CreateAssignmentTypeWithRosterDropdownItems(
	roster,
	assignmentTypeDropdownItems,
	assigneeDropdownItems
)
	local assignmentTypes = assignmentTypeDropdownItems or Utilities.CreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	if individualIndex and roster then
		assignmentTypes[individualIndex].dropdownItemMenuData = assigneeDropdownItems
			or Utilities.CreateAssigneeDropdownItems(roster)
		Utilities.SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	end
	return assignmentTypes
end

-- Initializes names and icons for raid instances and bosses and creates dropdown item data.
---@return table<integer, DropdownItemData>
function Utilities.InitializeRaidInstances()
	local bossDropdownData = {}
	for _, raidInstance in pairs(Private.raidInstances) do
		EJ_SelectInstance(raidInstance.journalInstanceID)
		local instanceName, _, _, _, _, buttonImage2, _, _, _, _ = EJ_GetInstanceInfo(raidInstance.journalInstanceID)
		raidInstance.name, raidInstance.icon = instanceName, buttonImage2
		local instanceIconText = format("|T%s:16|t %s", buttonImage2, instanceName)
		local instanceDropdownData =
			{ itemValue = raidInstance.instanceID, text = instanceIconText, dropdownItemMenuData = {} }
		for _, boss in ipairs(raidInstance.bosses) do
			EJ_SelectEncounter(boss.journalEncounterID)
			local encounterName = EJ_GetEncounterInfo(boss.journalEncounterID)
			local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, boss.journalEncounterID)
			boss.name, boss.icon = encounterName, iconImage
			local iconText = format("|T%s:16|t %s", iconImage, encounterName)
			tinsert(instanceDropdownData.dropdownItemMenuData, { itemValue = boss.dungeonEncounterID, text = iconText })
		end
		tinsert(bossDropdownData, instanceDropdownData)
	end
	return bossDropdownData
end

-- Creates unsorted timeline assignments from assignments and sets the timeline assignments' start times.
---@param assignments table<integer, Assignment> Assignments to create timeline assignments from
---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it
---@return table<integer, TimelineAssignment> -- Unsorted timeline assignments
function Utilities.CreateTimelineAssignments(assignments, bossDungeonEncounterID)
	local timelineAssignments = {}
	for _, assignment in pairs(assignments) do
		tinsert(timelineAssignments, TimelineAssignment:New(assignment))
	end
	local success, failTable = Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID)

	local invalidSpellIDOnlyCount = 0
	local spellCounts = {}
	if not success and failTable then
		local startCount = #timelineAssignments
		local failedSpellIDs = failTable.combatLogEventSpellIDs
		local onlyFailedSpellIDsString = ""

		for i = #timelineAssignments, 1, -1 do
			local assignment = timelineAssignments[i].assignment --[[@as CombatLogEventAssignment]]
			local spellID = assignment.combatLogEventSpellID
			if spellID and failedSpellIDs[spellID] then
				local spellCount = assignment.spellCount
				if failedSpellIDs[spellID][spellCount] then
					spellCounts[spellID] = spellCounts[spellID] or {}
					tinsert(spellCounts[spellID], spellCount)
				else
					onlyFailedSpellIDsString = onlyFailedSpellIDsString .. spellID .. ", "
					invalidSpellIDOnlyCount = invalidSpellIDOnlyCount + 1
				end
				tremove(timelineAssignments, i)
			end
		end

		print(format("%s: %d %s.", AddOnName, startCount - #timelineAssignments, L["assignment(s) failed to update"]))

		if onlyFailedSpellIDsString:len() > 1 then
			onlyFailedSpellIDsString = onlyFailedSpellIDsString:sub(1, onlyFailedSpellIDsString:len() - 2)
			print(format("%d %s: %s", invalidSpellIDOnlyCount, L["Invalid Boss Spell ID(s)"], onlyFailedSpellIDsString))
		end

		if #spellCounts > 0 then
			local total = 0
			local spellCountsString = ""
			sort(spellCounts)
			for spellID, counts in pairs(spellCounts) do
				local spellIDAndSpellCountString = tostring(spellID) .. ":"
				for _, spellCount in pairs(counts) do
					spellIDAndSpellCountString = spellIDAndSpellCountString .. " " .. spellCount .. ", "
					total = total + 1
				end
				if spellIDAndSpellCountString:len() > 1 then
					spellIDAndSpellCountString = spellIDAndSpellCountString:sub(1, spellIDAndSpellCountString:len() - 2)
					spellCountsString = spellCountsString .. spellIDAndSpellCountString .. "\n"
				end
			end
			if spellCountsString:len() > 0 then
				spellCountsString = spellCountsString:sub(1, spellCountsString:len() - 2)
				print(format("%d %s:\n %s", total, L["Invalid Boss Spell Count(s)"], spellCountsString))
			end
		end
	end
	return timelineAssignments
end

-- Sorts the assignees based on the order of the timeline assignments, taking spellID into account.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@param collapsed table<string, boolean>
---@return table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
function Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
	local assigneeIndices = {}
	local groupedByAssignee = {}
	for _, entry in ipairs(sortedTimelineAssignments) do
		local assignee = entry.assignment.assigneeNameOrRole
		if not groupedByAssignee[assignee] then
			groupedByAssignee[assignee] = {}
			tinsert(assigneeIndices, assignee)
		end
		tinsert(groupedByAssignee[assignee], entry)
	end

	local order = 0
	local assigneeMap = {}
	local assigneeOrder = {}

	for _, assignee in ipairs(assigneeIndices) do
		for _, entry in ipairs(groupedByAssignee[assignee]) do
			local spellID = entry.assignment.spellInfo.spellID
			if not assigneeMap[assignee] then
				assigneeMap[assignee] = {
					order = order,
					spellIDs = {},
				}
				tinsert(assigneeOrder, { assigneeNameOrRole = assignee, spellID = nil })
				order = order + 1
			end
			if not assigneeMap[assignee].spellIDs[spellID] then
				if not collapsed[assignee] then
					order = order + 1
				end
				assigneeMap[assignee].spellIDs[spellID] = order
				tinsert(assigneeOrder, { assigneeNameOrRole = assignee, spellID = spellID })
			end
			entry.order = assigneeMap[assignee].spellIDs[spellID]
		end
	end

	return assigneeOrder
end

-- Creates a Timeline Assignment comparator function.
---@param roster table<string, RosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@return fun(a:TimelineAssignment, b:TimelineAssignment):boolean
local function CompareAssignments(roster, assignmentSortType)
	local function RolePriority(role)
		if role == "role:healer" then
			return 1
		elseif role == "role:tank" then
			return 2
		elseif role == "role:damager" then
			return 3
		elseif role == nil or role == "" then
			return 4
		end
	end

	---@param a TimelineAssignment
	---@param b TimelineAssignment
	return function(a, b)
		local nameOrRoleA, nameOrRoleB = a.assignment.assigneeNameOrRole, b.assignment.assigneeNameOrRole
		local spellIDA, spellIDB = a.assignment.spellInfo.spellID, b.assignment.spellInfo.spellID
		if assignmentSortType == "Alphabetical" then
			if nameOrRoleA == nameOrRoleB then
				return spellIDA < spellIDB
			end
			return nameOrRoleA < nameOrRoleB
		elseif assignmentSortType == "First Appearance" then
			if a.startTime == b.startTime then
				if nameOrRoleA == nameOrRoleB then
					return spellIDA < spellIDB
				end
				return nameOrRoleA < nameOrRoleB
			end
			return a.startTime < b.startTime
		elseif assignmentSortType:match("^Role") then
			local roleA, roleB = roster[nameOrRoleA], roster[nameOrRoleB]
			local rolePriorityA, rolePriorityB = RolePriority(roleA and roleA.role), RolePriority(roleB and roleB.role)
			if rolePriorityA == rolePriorityB then
				if assignmentSortType == "Role > Alphabetical" then
					if nameOrRoleA == nameOrRoleB then
						if spellIDA == spellIDB then
							return a.startTime < b.startTime
						end
						return spellIDA < spellIDB
					end
					return nameOrRoleA < nameOrRoleB
				elseif assignmentSortType == "Role > First Appearance" then
					if a.startTime == b.startTime then
						if nameOrRoleA == nameOrRoleB then
							return spellIDA < spellIDB
						end
						return nameOrRoleA < nameOrRoleB
					end
					return a.startTime < b.startTime
				end
			end
			return rolePriorityA < rolePriorityB
		else
			return false
		end
	end
end

-- Creates and sorts a table of TimelineAssignments and sets the start time used for each assignment on the timeline.
-- Sorts assignments based on the assignmentSortType.
---@param assignments table<integer, Assignment> Assignments to sort
---@param roster table<string, RosterEntry> Roster associated with the assignments
---@param assignmentSortType AssignmentSortType Sort method
---@param bossDungeonEncounterID integer Used to get boss timers to set the proper timeline assignment start time for combat log assignments
---@return table<integer, TimelineAssignment>
function Utilities.SortAssignments(assignments, roster, assignmentSortType, bossDungeonEncounterID)
	local timelineAssignments = Utilities.CreateTimelineAssignments(assignments, bossDungeonEncounterID)
	sort(timelineAssignments, CompareAssignments(roster, assignmentSortType))
	return timelineAssignments
end

-- Attempts to assign roles based on assignment spells. Currently only tries to assign healer roles.
---@param assignments table<integer, Assignment> Assignments to assign roles for
function Utilities.DetermineRolesFromAssignments(assignments)
	local assigneeAssignments = {}
	local healerClasses = {
		["DRUID"] = "role:healer",
		["EVOKER"] = "role:healer",
		["MONK"] = "role:healer",
		["PALADIN"] = "role:healer",
		["PRIEST"] = "role:healer",
		["SHAMAN"] = "role:healer",
	}
	for _, assignment in pairs(assignments) do
		local assignee = assignment.assigneeNameOrRole
		if not assigneeAssignments[assignee] then
			assigneeAssignments[assignee] = {}
		end
		tinsert(assigneeAssignments[assignee], assignment)
	end
	local determinedRoles = {}
	for assignee, currentAssigneeAssignments in pairs(assigneeAssignments) do
		for _, currentAssigneeAssignment in pairs(currentAssigneeAssignments) do
			if determinedRoles[assignee] then
				break
			end
			local spellID = currentAssigneeAssignment.spellInfo.spellID
			if spellID == 98008 or spellID == 108280 then -- Shaman healing bc classified as raid defensive
				determinedRoles[assignee] = "role:healer"
				break
			end
			for className, classData in pairs(Private.spellDB.classes) do
				if determinedRoles[assignee] then
					break
				end
				for _, spellInfo in pairs(classData) do
					if spellInfo["spellID"] == spellID then
						if spellInfo["type"] == "heal" and healerClasses[className] then
							determinedRoles[assignee] = "role:healer"
							break
						end
					end
				end
			end
		end
		if not determinedRoles[assignee] then
			determinedRoles[assignee] = ""
		end
	end
	return determinedRoles
end

---@param assigneeNameOrRole string
---@return string|nil
function Utilities.IsValidAssigneeNameOrRole(assigneeNameOrRole)
	if assigneeNameOrRole == "{everyone}" then
		return assigneeNameOrRole
	else
		local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
		local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
		local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
		local specMatch = assigneeNameOrRole:match("spec:%s*([%a%d]+)")
		local typeMatch = assigneeNameOrRole:match("type:%s*(%a+)")
		if classMatch then
			local englishClassName = Utilities.GetEnglishClassNameWithoutSpaces(classMatch)
			if englishClassName then
				return "class:" .. englishClassName
			end
		elseif roleMatch then
			if Utilities.IsValidRole(roleMatch) then
				return "role:" .. roleMatch:lower()
			end
		elseif groupMatch then
			return "group:" .. groupMatch
		elseif specMatch then
			local specIDMatch = tonumber(specMatch)
			if specIDMatch then
				if Utilities.IsValidSpecID(specIDMatch) then
					return "spec:" .. specIDMatch
				end
			else
				local specID = Utilities.GetSpecIDFromSpecName(specMatch)
				if specID then
					return "spec:" .. tostring(specID)
				end
			end
		elseif typeMatch then
			if Utilities.IsValidType(typeMatch) then
				return "type:" .. typeMatch
			end
		else
			assigneeNameOrRole = assigneeNameOrRole:gsub("%s", "")
			local characterMatch, realmMatch = assigneeNameOrRole:match("^(%a+)(%-(%a[%a%s%d']+))$")
			if characterMatch and realmMatch then
				characterMatch = characterMatch:sub(1, 1):upper() .. characterMatch:sub(2):lower()
				return characterMatch .. "-" .. realmMatch:gsub("%s", "")
			else
				characterMatch = assigneeNameOrRole:match("^(%a+)$")
				if characterMatch then
					return characterMatch:sub(1, 1):upper() .. characterMatch:sub(2):lower()
				end
			end
		end
	end
	return nil
end

---@param assigneeNameOrRole string
---@param roster table<string, RosterEntry> Roster for the assignments
---@return string
function Utilities.ConvertAssigneeNameOrRoleToLegibleString(assigneeNameOrRole, roster)
	local legibleString = assigneeNameOrRole
	if assigneeNameOrRole == "{everyone}" then
		return L["Everyone"]
	else
		local classMatch = assigneeNameOrRole:match("class:%s*(%a+)")
		local roleMatch = assigneeNameOrRole:match("role:%s*(%a+)")
		local groupMatch = assigneeNameOrRole:match("group:%s*(%d)")
		local specMatch = assigneeNameOrRole:match("spec:%s*(%d+)")
		local typeMatch = assigneeNameOrRole:match("type:%s*(%a+)")
		if classMatch then
			local prettyClassName = Utilities.GetLocalizedPrettyClassName(classMatch)
			if prettyClassName then
				legibleString = prettyClassName
			else
				legibleString = classMatch:sub(1, 1):upper() .. classMatch:sub(2):lower()
			end
		elseif roleMatch then
			local localizedRole = Utilities.GetLocalizedRole(roleMatch:lower())
			if localizedRole then
				legibleString = localizedRole
			end
		elseif groupMatch then
			legibleString = L["Group"] .. " " .. groupMatch
		elseif specMatch then
			local specIDMatch = tonumber(specMatch)
			if specIDMatch then
				local specIconAndLocalizedSpecName = Utilities.GetSpecIconAndLocalizedSpecName(specIDMatch)
				if specIconAndLocalizedSpecName then
					legibleString = specIconAndLocalizedSpecName
				end
			end
		elseif typeMatch then
			local localizedType = Utilities.GetLocalizedType(typeMatch)
			if localizedType then
				legibleString = localizedType
			end
		elseif roster and roster[assigneeNameOrRole] then
			if roster[assigneeNameOrRole].classColoredName ~= "" then
				legibleString = roster[assigneeNameOrRole].classColoredName
			end
		end
	end
	return legibleString
end

-- Sorts a table of possibly nested dropdown item data, removing any inline icons if present before sorting.
---@param data table<integer, DropdownItemData> Dropdown data to sort
function Utilities.SortDropdownDataByItemValue(data)
	-- Sort the top-level table
	sort(data, function(a, b)
		local itemValueA = a.itemValue
		local itemValueB = b.itemValue
		if type(itemValueA) == "number" or itemValueA:find("spec:") then
			local spellName = a.text:match("|T.-|t%s(.+)")
			if spellName then
				itemValueA = spellName
			end
		end
		if type(itemValueB) == "number" or itemValueB:find("spec:") then
			local spellName = b.text:match("|T.-|t%s(.+)")
			if spellName then
				itemValueB = spellName
			end
		end
		return itemValueA < itemValueB
	end)

	-- Recursively sort any nested dropdownItemMenuData tables
	for _, item in pairs(data) do
		if item.dropdownItemMenuData and #item.dropdownItemMenuData > 0 then
			Utilities.SortDropdownDataByItemValue(item.dropdownItemMenuData)
		end
	end
end

-- Updates a timeline assignment's start time.
---@param timelineAssignment TimelineAssignment
---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it.
---@return boolean -- Whether or not the update succeeded
function Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, bossDungeonEncounterID)
	if getmetatable(timelineAssignment.assignment) == CombatLogEventAssignment then
		local assignment = timelineAssignment.assignment --[[@as CombatLogEventAssignment]]
		local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
		if absoluteSpellCastStartTable then
			local spellIDSpellCastStartTable = absoluteSpellCastStartTable[assignment.combatLogEventSpellID]
			if spellIDSpellCastStartTable then
				local spellCastStartTable = spellIDSpellCastStartTable[assignment.spellCount]
				if spellCastStartTable then
					local startTime = spellCastStartTable.castStart + assignment.time
					local ability = FindBossAbility(bossDungeonEncounterID, assignment.combatLogEventSpellID)
					if ability then
						if assignment.combatLogEventType == "SAR" then
							startTime = startTime + ability.duration + ability.castTime
						elseif assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SAA" then
							startTime = startTime + ability.castTime
						end
					end
					timelineAssignment.startTime = startTime
					return true
				end
			end
		end
		return false
	elseif getmetatable(timelineAssignment.assignment) == TimedAssignment then
		local assignment = timelineAssignment.assignment --[[@as TimedAssignment]]
		timelineAssignment.startTime = assignment.time
	elseif getmetatable(timelineAssignment.assignment) == PhasedAssignment then
		local assignment = timelineAssignment.assignment --[[@as PhasedAssignment]]
		local boss = GetBoss(bossDungeonEncounterID)
		if boss then
			local bossPhaseTable = GetOrderedBossPhases(bossDungeonEncounterID)
			local phase = boss.phases[assignment.phase]
			if bossPhaseTable and phase then
				for phaseCount = 1, #phase.count do
					local phaseStartTime =
						GetCumulativePhaseStartTime(bossDungeonEncounterID, bossPhaseTable, phaseCount)
					timelineAssignment.startTime = phaseStartTime
					break -- TODO: Only first phase appearance implemented
				end
			else
				return false
			end
		else
			return false
		end
	end
	return true
end

---@class FailedInfo
---@field bossName string|nil
---@field combatLogEventSpellIDs table<integer, table<integer, integer>>

-- Updates multiple timeline assignments' start times.
---@param timelineAssignments table<integer, TimelineAssignment>
---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it.
---@return boolean
---@return {bossName: string|nil, combatLogEventSpellIDs: table<integer, table<integer, integer>>}?
function Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID)
	local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
	local bossName = GetBossName(bossDungeonEncounterID)
	local failedTable = {
		bossName = bossName,
		combatLogEventSpellIDs = {},
	}

	if not absoluteSpellCastStartTable or not bossName then
		return false, failedTable
	end

	local failedSpellIDs = failedTable.combatLogEventSpellIDs
	for _, timelineAssignment in ipairs(timelineAssignments) do
		if getmetatable(timelineAssignment.assignment) == CombatLogEventAssignment then
			local assignment = timelineAssignment.assignment --[[@as CombatLogEventAssignment]]
			local spellID = assignment.combatLogEventSpellID
			local spellIDSpellCastStartTable = absoluteSpellCastStartTable[spellID]
			if spellIDSpellCastStartTable then
				local spellCount = assignment.spellCount
				local spellCastStartTable = spellIDSpellCastStartTable[spellCount]
				if spellCastStartTable then
					local startTime = spellCastStartTable.castStart + assignment.time
					local ability = FindBossAbility(bossDungeonEncounterID, spellID) --[[@as BossAbility]]
					local combatLogEventType = assignment.combatLogEventType
					if combatLogEventType == "SAR" then
						startTime = startTime + ability.duration + ability.castTime
					elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
						startTime = startTime + ability.castTime
					end
					timelineAssignment.startTime = startTime
				else
					failedSpellIDs[spellID] = failedSpellIDs or {}
					failedSpellIDs[spellID][spellCount] = true
				end
			else
				failedSpellIDs[spellID] = failedSpellIDs or {}
			end
		elseif getmetatable(timelineAssignment.assignment) == TimedAssignment then
			timelineAssignment.startTime = timelineAssignment
				.assignment--[[@as TimedAssignment]]
				.time
		elseif getmetatable(timelineAssignment.assignment) == PhasedAssignment then
			local assignment = timelineAssignment.assignment --[[@as PhasedAssignment]]
			local boss = GetBoss(bossDungeonEncounterID)
			if boss then
				local bossPhaseTable = GetOrderedBossPhases(bossDungeonEncounterID)
				local phase = boss.phases[assignment.phase]
				if bossPhaseTable and phase then
					for phaseCount = 1, #phase.count do
						local phaseStartTime =
							GetCumulativePhaseStartTime(bossDungeonEncounterID, bossPhaseTable, phaseCount)
						timelineAssignment.startTime = phaseStartTime
						break -- TODO: Only first phase appearance implemented
					end
				end
			end
		end
	end
	if #failedTable.combatLogEventSpellIDs == 0 then
		return true
	else
		return false, failedTable
	end
end

-- Creates a sorted table used to populate the assignment list.
---@param sortedAssigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}> Sorted assignment list
---@param roster table<string, RosterEntry> Roster for the assignments
---@return table<integer, {assigneeNameOrRole:string, text:string, spells:table<integer, integer>}>
function Utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
	local visited = {}
	local map = {}
	for _, nameAndSpell in ipairs(sortedAssigneesAndSpells) do
		local assigneeNameOrRole = nameAndSpell.assigneeNameOrRole
		local abilityEntryText = Utilities.ConvertAssigneeNameOrRoleToLegibleString(assigneeNameOrRole, roster)
		if not visited[abilityEntryText] then
			tinsert(map, {
				assigneeNameOrRole = assigneeNameOrRole,
				text = abilityEntryText,
				spells = {},
			})
			visited[abilityEntryText] = map[#map]
		end
		if nameAndSpell.spellID then
			tinsert(visited[abilityEntryText].spells, nameAndSpell.spellID)
		end
	end
	return map
end

-- Creates a table of unit types for the current raid or party group.
---@param maxGroup? integer Maximum group number
---@return table<integer, string>
function Utilities.IterateRosterUnits(maxGroup)
	local units = {}
	maxGroup = maxGroup or 8
	local numMembers = GetNumGroupMembers()
	local inRaid = IsInRaid()
	for i = 1, numMembers do
		if i == 1 and numMembers <= 4 then
			units[i] = "player"
		elseif inRaid then
			local _, _, subgroup = GetRaidRosterInfo(i)
			if subgroup and subgroup <= maxGroup then
				units[i] = "raid" .. i
			end
		else
			units[i] = "party" .. (i - 1)
		end
	end
	return units
end

-- Attempts to find the unit GUID of a player in the group.
---@param name string
---@return string?
function Utilities.FindGroupMemberUnit(name)
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if name == UnitName(unit) then
			return unit
		else
			local unitName, unitRealm = UnitFullName(unit)
			if unitName and unitRealm then
				local unitFullName = unitName .. "-" .. unitRealm
				if name == unitFullName then
					return unitFullName
				end
			end
		end
	end
	return nil
end

-- Creates a table where keys are character names and the values are tables with class and role fields. Dependent on the
-- group the player is in.
---@return RosterEntry
function Utilities.GetDataFromGroup()
	local groupData = {}
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if unit then
			local role = UnitGroupRolesAssigned(unit)
			local _, classFileName, _ = UnitClass(unit)
			local unitName, unitServer = UnitFullName(unit)
			unitName = Ambiguate(unitName .. "-" .. unitServer, "all")
			if classFileName then
				groupData[unitName] = {}
				groupData[unitName].class = classFileName
				groupData[unitName].role = role
				local colorMixin = GetClassColor(classFileName)
				local classColoredName = colorMixin:WrapTextInColorCode(unitName:gsub("%-.*", ""))
				groupData[unitName].classColoredName = classColoredName
			end
		end
	end
	return groupData
end

---@param unitName string Character name for the roster entry
---@param rosterEntry RosterEntry Roster entry to update
local function UpdateRosterEntryClassColoredName(unitName, rosterEntry)
	if rosterEntry.class ~= "" then
		local className = rosterEntry.class:match("class:%s*(%a+)")
		if className then
			className = className:upper()
			if Private.spellDB.classes[className] then
				local colorMixin = GetClassColor(className)
				rosterEntry.classColoredName = colorMixin:WrapTextInColorCode(unitName)
			end
		end
	end
end

-- Updates class, class colored name, and role from the group if they do not exist.
---@param rosterEntry RosterEntry Roster entry to update
---@param unitData RosterEntry
local function UpdateRosterEntryFromUnitData(rosterEntry, unitData)
	if rosterEntry.class == "" then
		local className = unitData.class
		local actualClassName
		if className == "DEATHKNIGHT" then
			actualClassName = "DeathKnight"
		elseif className == "DEMONHUNTER" then
			actualClassName = "DemonHunter"
		else
			actualClassName = className:sub(1, 1):upper() .. className:sub(2):lower()
		end
		rosterEntry.class = "class:" .. actualClassName:gsub("%s", "")
	end

	if rosterEntry.classColoredName == "" then
		rosterEntry.classColoredName = unitData.classColoredName
	end

	if rosterEntry.role == "" then
		if unitData.role == "DAMAGER" then
			rosterEntry.role = "role:damager"
		elseif unitData.role == "HEALER" then
			rosterEntry.role = "role:healer"
		elseif unitData.role == "TANK" then
			rosterEntry.role = "role:tank"
		end
	end
end

-- Imports all characters in the group if they do not already exist.
---@param roster table<string, RosterEntry> Roster to update
function Utilities.ImportGroupIntoRoster(roster)
	for _, unit in pairs(Utilities.IterateRosterUnits()) do
		if unit then
			local unitName, _ = UnitName(unit)
			if unitName then
				roster[unitName] = RosterEntry:New({})
			end
		end
	end
end

-- Updates class, class colored name, and role from the current raid or party group.
---@param roster table<string, RosterEntry> Roster to update
function Utilities.UpdateRosterDataFromGroup(roster)
	local groupData = Utilities.GetDataFromGroup()
	for unitName, data in pairs(groupData) do
		if roster[unitName] then
			UpdateRosterEntryFromUnitData(roster[unitName], data)
		end
	end
end

-- Adds assignees from assignments not already present in roster, updates estimated roles if one was found and the entry
-- does not already have one.
---@param assignments table<integer, Assignment> Assignments to add assignees from
---@param roster table<string, RosterEntry> Roster to update
function Utilities.UpdateRosterFromAssignments(assignments, roster)
	local determinedRoles = Utilities.DetermineRolesFromAssignments(assignments)
	local visited = {}
	for _, assignment in ipairs(assignments) do
		if assignment.assigneeNameOrRole and not visited[assignment.assigneeNameOrRole] then
			local nameOrRole = assignment.assigneeNameOrRole
			if
				not nameOrRole:find("class:")
				and not nameOrRole:find("group:")
				and not nameOrRole:find("role:")
				and not nameOrRole:find("spec:")
				and not nameOrRole:find("type:")
				and not nameOrRole:find("{everyone}")
			then
				if not roster[nameOrRole] then
					roster[nameOrRole] = RosterEntry:New({})
				end
				if roster[nameOrRole].role == "" then
					if determinedRoles[nameOrRole] then
						roster[nameOrRole].role = determinedRoles[nameOrRole]
					end
				end
				UpdateRosterEntryClassColoredName(nameOrRole, roster[nameOrRole])
			end
			visited[nameOrRole] = true
		end
	end
	for nameOrRole, _ in pairs(roster) do
		if not visited[nameOrRole] then
			UpdateRosterEntryClassColoredName(nameOrRole, roster[nameOrRole])
		end
	end
end

-- Splits a string into table using new lines as separators.
---@param text string The text to use to create the table
---@return table<integer, string>
function Utilities.SplitStringIntoTable(text)
	local stringTable = {}
	for line in text:gmatch(lineMatchRegex) do
		tinsert(stringTable, line)
	end
	return stringTable
end

---@param iconID integer|string
---@param text string
---@param size? integer
---@return string
function Utilities.AddIconBeforeText(iconID, text, size)
	return format("|T%s:%d|t %s", iconID, size or 0, text)
end

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

---@param timelineAssignments table<integer, TimelineAssignment>|table<integer, Assignment>
---@return table<integer, TimelineAssignment|Assignment>
function Utilities.FilterSelf(timelineAssignments)
	local filtered = {}
	local unitName, unitRealm = UnitFullName("player")
	local unitClass = select(2, UnitClass("player"))
	local specID, _, _, _, role = GetSpecializationInfo(GetSpecialization())
	local classType = Utilities.GetTypeFromSpecID(specID)
	for _, timelineAssignment in ipairs(timelineAssignments) do
		local nameOrRole = timelineAssignment.assigneeNameOrRole or timelineAssignment.assignment.assigneeNameOrRole
		if nameOrRole:find("class:") then
			local classMatch = nameOrRole:match("class:%s*(%a+)")
			if classMatch then
				if classMatch:upper() == unitClass then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("group:") then
			if nameOrRole:find(tostring(GetGroupNumber())) then
				tinsert(filtered, timelineAssignment)
			end
		elseif nameOrRole:find("role:") then
			local roleMatch = nameOrRole:match("role:%s*(%a+)")
			if roleMatch then
				if roleMatch:upper() == role then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("type:") then
			local typeMatch = nameOrRole:match("type:%s*(%a+)")
			if typeMatch then
				if typeMatch:lower() == classType then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("spec:") then
			local specMatch = nameOrRole:match("spec:%s*(%d+)")
			if specMatch then
				local foundSpecID = tonumber(specMatch)
				if foundSpecID and foundSpecID == specID then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif nameOrRole:find("{everyone}") then
			tinsert(filtered, timelineAssignment)
		elseif unitName == nameOrRole or unitName .. "-" .. unitRealm == nameOrRole then
			tinsert(filtered, timelineAssignment)
		end
	end
	return filtered
end

---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param addIcon boolean
---@return string
function Utilities.CreateReminderText(assignment, roster, addIcon)
	local reminderText = ""
	local spellID = assignment.spellInfo.spellID
	if assignment.text ~= nil and assignment.text ~= "" then
		reminderText = Utilities.ReplaceGenericIcons(assignment.text)
	elseif assignment.targetName ~= nil and assignment.targetName ~= "" then
		if spellID ~= nil and spellID > kTextAssignmentSpellID then
			if assignment.spellInfo.name then
				reminderText = assignment.spellInfo.name
			else
				local spellName = GetSpellName(spellID)
				if spellName then
					reminderText = spellName
				end
			end
		end
		local targetRosterEntry = roster[assignment.targetName] --[[@as RosterEntry]]
		if targetRosterEntry and targetRosterEntry.classColoredName ~= "" then
			if reminderText:len() > 0 then
				reminderText = reminderText .. " " .. targetRosterEntry.classColoredName
			else
				reminderText = targetRosterEntry.classColoredName
			end
		else
			if reminderText:len() > 0 then
				reminderText = reminderText .. " " .. assignment.targetName
			else
				reminderText = assignment.targetName
			end
		end
	elseif spellID ~= nil and spellID > kTextAssignmentSpellID then
		local spellName = assignment.spellInfo.name:len() > 0 and assignment.spellInfo.name or GetSpellName(spellID)
		if spellName then
			if addIcon then
				local spellTexture = GetSpellTexture(spellID)
				if spellTexture then
					reminderText = Utilities.AddIconBeforeText(spellTexture, spellName, 16)
				else
					reminderText = spellName
				end
			else
				reminderText = spellName
			end
		end
	end
	return reminderText
end

---@param assignments table<integer, Assignment>
function Utilities.SetAssignmentMetaTables(assignments)
	for _, assignment in pairs(assignments) do
		assignment = Assignment:New(assignment)
		if
			---@diagnostic disable-next-line: undefined-field
			assignment.combatLogEventType
			---@diagnostic disable-next-line: undefined-field
			and assignment.combatLogEventSpellID
			---@diagnostic disable-next-line: undefined-field
			and assignment.combatLogEventSpellID > 0
		then
			assignment = CombatLogEventAssignment:New(assignment)
			---@diagnostic disable-next-line: undefined-field
		elseif assignment.phase then
			assignment = PhasedAssignment:New(assignment)
			---@diagnostic disable-next-line: undefined-field
		elseif assignment.time then
			assignment = TimedAssignment:New(assignment)
		end
	end
end

---@param regionName string|nil
---@return boolean
function Utilities.IsValidRegionName(regionName)
	if regionName then
		local region = _G[regionName]
		return region ~= nil and region.SetPoint ~= nil
	end
	return false
end

-- Formats the minutes to an integer, and formats the seconds to be 2 digits left padded with 0s, including a decimal
-- only if necessary.
---@param time number
---@return string minutes formatted minutes string
---@return string seconds formatted seconds string
function Utilities.FormatTime(time)
	local minutes = floor(time / 60)
	local seconds = Utilities.Round(time % 60, 1)

	local formattedMinutes = format("%d", minutes)
	local formattedSeconds = format("%02d", seconds)
	local secondsDecimalMatch = tostring(seconds):match("^%d+%.(%d+)")
	if secondsDecimalMatch and secondsDecimalMatch ~= "0" and secondsDecimalMatch ~= "" then
		formattedSeconds = formattedSeconds .. "." .. secondsDecimalMatch
	end

	return formattedMinutes, formattedSeconds
end
