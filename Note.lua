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
local UnitClass = UnitClass
local UnitName = UnitName
local wipe = wipe

local postOptionsPreDashRegex = "}{spell:(%d+)}?(.-) %-"
local postDashRegex = "([^ \n-][^\n-]-)  +"
local nonSymbolRegex = "[^ \n,%(%)%[%]_%$#@!&]+"
local doublePipeRegex = "||"

local healerRegex = "{[Hh]}.-{/[Hh]}"
local tankRegex = "{[Tt]}.-{/[Tt]}"
local dpsRegex = "{[Dd]}.-{/[Dd]}"
local groupRegex = "{(!?)[Gg](%d+)}(.-){/[Gg]}"
local playerRegex = "{(!?)[Pp]:([^}]+)}(.-){/[Pp]}"
local classRegex = "{(!?)[Cc]:([^}]+)}(.-){/[Cc]}"
local raceRegex = "{(!?)[Rr][Aa][Cc][Ee]:([^}]+)}(.-){/[Rr][Aa][Cc][Ee]}"
local encounterRegex = "{[Ee]:([^}]+)}(.-){/[Ee]}"
local textRegex = "{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}"

local colorStartRegex = "|c........"
local colorEndRegex = "|r"

local timeOptionsSplitRegex = "{time:(%d+)[:%.]?(%d*),?([^{}]*)}"
local nameRegex = "^(%S+)"
local targetNameRegex = "@(%S+)"
local spellIconRegex = "{spell:(%d+):?%d*}"
local namePlaceholderRegex = "^({.-})"
local spellIDPlaceholderRegex = "(.*){spell:(%d+):?%d*}"
local raidIconRegex = "{icon:([^}]+)}"
local ertIconRegex = "{.-}"
local dashRegex = "{.-}"
local phaseNumberRegex = "^p(g?):?(.-)$"

local classList = {
	[GetClassInfo(1):lower()] = 1,
	[GetClassInfo(2):lower()] = 2,
	[GetClassInfo(3):lower()] = 3,
	[GetClassInfo(4):lower()] = 4,
	[GetClassInfo(5):lower()] = 5,
	[(GetClassInfo(6) or "unk"):lower()] = 6,
	[GetClassInfo(7):lower()] = 7,
	[GetClassInfo(8):lower()] = 8,
	[GetClassInfo(9):lower()] = 9,
	[(GetClassInfo(10) or "unk"):lower()] = 10,
	[GetClassInfo(11):lower()] = 11,
	[(GetClassInfo(12) or "unk"):lower()] = 12,
	[(GetClassInfo(13) or "unk"):lower()] = 13,
	["warrior"] = 1,
	["paladin"] = 2,
	["hunter"] = 3,
	["rogue"] = 4,
	["priest"] = 5,
	["deathknight"] = 6,
	["shaman"] = 7,
	["mage"] = 8,
	["warlock"] = 9,
	["monk"] = 10,
	["druid"] = 11,
	["demonhunter"] = 12,
	["evoker"] = 13,
	["war"] = 1,
	["pal"] = 2,
	["hun"] = 3,
	["rog"] = 4,
	["pri"] = 5,
	["dk"] = 6,
	["sham"] = 7,
	["lock"] = 9,
	["dru"] = 11,
	["dh"] = 12,
	["dragon"] = 13,
	["1"] = 1,
	["2"] = 2,
	["3"] = 3,
	["4"] = 4,
	["5"] = 5,
	["6"] = 6,
	["7"] = 7,
	["8"] = 7,
	["9"] = 9,
	["10"] = 10,
	["11"] = 11,
	["12"] = 12,
	["13"] = 13,
}

local localERTIcons = {
	--- Raid Target Icon [ID]
	["{rt1}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{rt2}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{rt3}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{rt4}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{rt5}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{rt6}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{rt7}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{rt8}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [ENG]
	["{star}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{circle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{diamond}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{triangle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{moon}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{square}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{cross}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{skull}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [DE]
	["{stern}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{kreis}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{diamant}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{dreieck}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{mond}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{quadrat}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{kreuz}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{totenschädel}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [FR]
	["{étoile}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{cercle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{losange}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	-- ["{triangle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{lune}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{carré}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{croix}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{crâne}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [IT]
	["{stella}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{cerchio}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{rombo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{triangolo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{luna}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{quadrato}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{croce}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{teschio}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [RU]
	["{звезда}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{круг}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{ромб}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{треугольник}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{полумесяц}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{квадрат}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{крест}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{череп}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [ES]
	["{dorado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{naranja}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{morado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{verde}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{plateado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{azul}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{rojo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{blanco}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [PT]
	["{dourado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{laranja}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{roxo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	-- ["{verde}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{prateado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	-- ["{azul}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{vermelho}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{branco}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Raid Target Icon [KR]
	["{별}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	["{동그라미}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	["{다이아몬드}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	["{세모}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	["{달}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	["{네모}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	["{가위표}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	["{해골}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
	--- Other Icons
	["{wow}"] = "|TInterface\\FriendsFrame\\Battlenet-WoWicon:16|t",
	["{d3}"] = "|TInterface\\FriendsFrame\\Battlenet-D3icon:16|t",
	["{sc2}"] = "|TInterface\\FriendsFrame\\Battlenet-Sc2icon:16|t",
	["{bnet}"] = "|TInterface\\FriendsFrame\\Battlenet-Portrait:16|t",
	["{bnet1}"] = "|TInterface\\FriendsFrame\\Battlenet-Battleneticon:16|t",
	["{alliance}"] = "|TInterface\\FriendsFrame\\PlusManz-Alliance:16|t",
	["{horde}"] = "|TInterface\\FriendsFrame\\PlusManz-Horde:16|t",
	["{hots}"] = "|TInterface\\FriendsFrame\\Battlenet-HotSicon:16|t",
	["{ow}"] = "|TInterface\\FriendsFrame\\Battlenet-Overwatchicon:16|t",
	["{sc1}"] = "|TInterface\\FriendsFrame\\Battlenet-SCicon:16|t",
	["{barcade}"] = "|TInterface\\FriendsFrame\\Battlenet-BlizzardArcadeCollectionicon:16|t",
	["{crashb}"] = "|TInterface\\FriendsFrame\\Battlenet-CrashBandicoot4icon:16|t",
	--- Role Icons
	["{tank}"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
	["{healer}"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
	["{dps}"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t",
	--- Class Icons
	["{" .. GetClassInfo(1) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t",
	["{Warrior}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t",
	["{" .. GetClassInfo(2) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:128:192|t",
	["{Paladin}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:128:192|t",
	["{" .. GetClassInfo(3) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:64:128|t",
	["{Hunter}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:64:128|t",
	["{" .. GetClassInfo(4) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:0:64|t",
	["{Rogue}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:0:64|t",
	["{" .. GetClassInfo(5) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:64:128|t",
	["{Priest}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:64:128|t",
	["{" .. (GetClassInfo(6) or "unk") .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:128:128:192|t",
	["{Death Knight}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:128:128:192|t",
	["{" .. GetClassInfo(7) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:64:128|t",
	["{Shaman}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:64:128|t",
	["{" .. GetClassInfo(8) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:0:64|t",
	["{Mage}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:0:64|t",
	["{" .. GetClassInfo(9) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:64:128|t",
	["{Warlock}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:64:128|t",
	["{" .. (GetClassInfo(10) or "unk") .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:128:189:128:192|t",
	["{Monk}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:128:189:128:192|t",
	["{" .. GetClassInfo(11) .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:0:64|t",
	["{Druid}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:0:64|t",
	["{" .. (GetClassInfo(12) or "unk") .. "}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:128:192|t",
	["{Demon Hunter}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:128:192|t",
	["{" .. (GetClassInfo(13) or "unk") .. "}"] = "interface/icons/classicon_evoker",
	["{Evoker}"] = "|Tinterface/icons/classicon_evoker:16|t",
}
localERTIcons["{unk}"] = nil

local noteEncounters = {}
local encounterIds = {}

-- Create autocolor table like most "stolen" from ERT/KAZE
local combatLogEventFromAbbreviation = {
	SCC = "SPELL_CAST_SUCCESS",
	SCS = "SPELL_CAST_START",
	SAA = "SPELL_AURA_APPLIED",
	SAR = "SPELL_AURA_REMOVED",
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

---@param list string
---@param msg string
---@return string
local function GSubEncounter(list, msg)
	local tableList = splitTable(",", list)
	local found = false
	for i = 1, #tableList do
		tableList[i] = tableList[i]:gsub("|?|c........", ""):gsub("|?|r", ""):lower()
		noteEncounters[tableList[i]] = true
		if encounterIds[tableList[i]] then
			found = true
			break
		end
	end
	return found and msg or ""
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

-- Replaces regular name text with class-colored name text.
---@param lines string
---@param classColoredNameTable table
---@return string
local function ReplaceNamesWithColoredNamesIfFound(lines, classColoredNameTable)
	local result, _ = lines:gsub(nonSymbolRegex, function(word)
		if classColoredNameTable[word] and classColoredNameTable[word].classColoredName then
			return classColoredNameTable[word].classColoredName
		end
		return word
	end)
	return result
end

-- Filters lines by the player's current role.
---@param lines string
---@return string
local function FilterByCurrentRole(lines)
	-- filters stolen grazefully from MRT
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
	-- filters stolen grazefully from MRT
	line = line:gsub(groupRegex, GsubGroup)
		:gsub(playerRegex, GSubPlayer)
		:gsub(classRegex, GSubClass)
		:gsub(raceRegex, GSubRace)
		:gsub(encounterRegex, GSubEncounter)
	return line
end

---@param spellID string
---@return string
local function GSubIcon(spellID)
	local spellTexture = GetSpellTexture(spellID)
	return "|T" .. (spellTexture or "Interface\\Icons\\INV_MISC_QUESTIONMARK") .. ":16|t"
end

-- Parses a line of text in the note and creates assignment(s).
---@param line string
---@param generalText string|nil
---@param generalTextSpellID number|nil
---@param classColoredNameTable table
---@return table<integer, Assignment>
local function CreateAssignmentsFromLine(line, generalText, generalTextSpellID, classColoredNameTable)
	local assignments = {}
	for str in (line .. "  "):gmatch(postDashRegex) do
		local targetName = str:match(targetNameRegex) or ""
		targetName = targetName:gsub(doublePipeRegex, "|"):gsub(colorStartRegex, ""):gsub(colorEndRegex, "")

		local spellinfo = { spellID = 0, name = "", iconID = 0 }
		local strWithoutSpell = str:gsub(spellIDPlaceholderRegex, function(rest, id)
			spellinfo = GetSpellInfo(id)
			return rest
		end)

		local nameOrGroup = strWithoutSpell:match(namePlaceholderRegex) or strWithoutSpell:match(nameRegex) or ""
		nameOrGroup = nameOrGroup:gsub(doublePipeRegex, "|"):gsub(colorStartRegex, ""):gsub(colorEndRegex, "")

		local textWithIconReplacements = nil
		local text = str:match(textRegex)
		if text then
			textWithIconReplacements = text:gsub(spellIconRegex, GSubIcon)
				:gsub(raidIconRegex, "|T%1:16|t")
				:gsub(ertIconRegex, localERTIcons)
				:gsub(doublePipeRegex, "|")
				:gsub(dashRegex, "")
				:gsub(nonSymbolRegex, function(s)
					ReplaceNamesWithColoredNamesIfFound(s, classColoredNameTable)
				end)
		end
		local strWithIconReplacements = str:gsub(spellIconRegex, GSubIcon)
			:gsub(raidIconRegex, "|T%1:16|t")
			:gsub(ertIconRegex, localERTIcons)
			:gsub(doublePipeRegex, "|")
			:gsub(dashRegex, "")
			:gsub(nonSymbolRegex, function(s)
				ReplaceNamesWithColoredNamesIfFound(s, classColoredNameTable)
			end)

		local assignment = Private.classes.Assignment:New({
			assigneeNameOrRole = nameOrGroup or "",
			line = str,
			text = text,
			textWithIconReplacements = textWithIconReplacements,
			strWithIconReplacements = strWithIconReplacements,
			spellInfo = spellinfo,
			targetName = targetName,
			generalText = generalText,
			generalTextSpellID = generalTextSpellID,
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
---@param note EncounterPlannerDbNote Note to repopulate
---@return string|nil
function Private:ParseNote(note)
	wipe(note.assignments) -- temporary until assignments are more stable
	local bossName = nil
	local classColoredNameTable = utilities.GetDataFromGroup()

	for _, line in pairs(note.content) do
		local time, options = ParseTime(line)
		if time and options then
			local spellID, generalText = line:match(postOptionsPreDashRegex)
			local spellIDNumber = nil
			if spellID then
				spellIDNumber = tonumber(spellID)
				if not bossName and spellIDNumber then
					bossName = bossUtilities.GetBossNameFromSpellID(spellIDNumber)
				end
			end
			local inputs = CreateAssignmentsFromLine(line, generalText, spellIDNumber, classColoredNameTable)
			self:ProcessOptions(inputs, note.assignments, time, options)
		end
	end

	return bossName
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
	else
		timeAndOptionsString = string.format("{time:%d:%02d}", minutes, seconds)
	end
	if assignment.generalTextSpellID and assignment.generalTextSpellID >= 0 then
		local optionsString = format("{spell:%d}%s", assignment.generalTextSpellID, assignment.generalText)
		timeAndOptionsString = timeAndOptionsString .. optionsString
	else
		timeAndOptionsString = timeAndOptionsString .. assignment.generalText
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

---@param note EncounterPlannerDbNote
---@return string|nil
function Private:ExportNote(note)
	local bossName =
		bossUtilities.GetBossNameFromBossDefinitionIndex(Private.mainFrame:GetBossSelectDropdown():GetValue())
	if bossName then
		local timelineAssignments = utilities.CreateTimelineAssignments(note.assignments, bossName)
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
---@param parseMRTNote boolean? If true, the MRT shared note will be parsed, otherwise the existing note in the database
-- will be parsed.
---@return string|nil
function Private:Note(epNoteName, parseMRTNote)
	local notes = AddOn.db.profile.notes --[[@as table<string, EncounterPlannerDbNote>]]

	if parseMRTNote then
		local loadingOrLoaded, loaded = IsAddOnLoaded("MRT")
		if not loadingOrLoaded and not loaded then
			print(format("%s: No note was loaded due to MRT not being installed.", AddOnName))
			return nil
		end
	end

	if not notes[epNoteName] then
		notes[epNoteName] = Private.classes.EncounterPlannerDbNote:New()
	end
	local note = notes[epNoteName]

	if parseMRTNote then
		if VMRT and VMRT.Note then
			local sharedMRTNote = VMRT.Note.Text1 or ""
			note.content = utilities.SplitStringIntoTable(sharedMRTNote)
		end
	end

	local bossName = self:ParseNote(note)
	if bossName then
		note.bossName = bossName
	end

	utilities.UpdateRosterFromAssignments(note.assignments, note.roster)
	utilities.UpdateRosterDataFromGroup(note.roster)
	return bossName
end
