--@type string
local AddOnName = ...
--@class Private
local Private = select(2, ...)
local AddOn = Private.AddOn

local lineRegex = "[^\r\n]+"
local wordSegmentationRegex = "([^ \n-][^\n-]-)  +"
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
local targetNameRegex = "@(%S+)"
local spellIconRegex = "{spell:(%d+):?%d*}"
local displayStringRegex = "(.*){spell:(%d+):?%d*}"
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
	["13"] = 13
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
	["{" .. GetClassInfo(1) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t",
	["{Warrior}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t",
	["{" .. GetClassInfo(2) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:128:192|t",
	["{Paladin}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:128:192|t",
	["{" .. GetClassInfo(3) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:64:128|t",
	["{Hunter}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:64:128|t",
	["{" .. GetClassInfo(4) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:0:64|t",
	["{Rogue}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:0:64|t",
	["{" .. GetClassInfo(5) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:64:128|t",
	["{Priest}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:64:128|t",
	["{" .. (GetClassInfo(6) or "unk") .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:128:128:192|t",
	["{Death Knight}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:128:128:192|t",
	["{" .. GetClassInfo(7) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:64:128|t",
	["{Shaman}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:64:128|t",
	["{" .. GetClassInfo(8) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:0:64|t",
	["{Mage}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:0:64|t",
	["{" .. GetClassInfo(9) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:64:128|t",
	["{Warlock}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:64:128|t",
	["{" .. (GetClassInfo(10) or "unk") .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:128:189:128:192|t",
	["{Monk}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:128:189:128:192|t",
	["{" .. GetClassInfo(11) .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:0:64|t",
	["{Druid}"] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:0:64|t",
	["{" .. (GetClassInfo(12) or "unk") .. "}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:128:192|t",
	["{Demon Hunter}"] =
	"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:128:192|t",
	["{" .. (GetClassInfo(13) or "unk") .. "}"] = "interface/icons/classicon_evoker",
	["{Evoker}"] = "|Tinterface/icons/classicon_evoker:16|t"
}
localERTIcons["{unk}"] = nil

local noteEncounters = {}
local encounterIds = {}

-- Create autocolor table like most "stolen" from ERT/KAZE
Private.GSubAutoColorData = {}
local combatLogEventFromAbbreviation = {
	SCC = "SPELL_CAST_SUCCESS",
	SCS = "SPELL_CAST_START",
	SAA = "SPELL_AURA_APPLIED",
	SAR = "SPELL_AURA_REMOVED"
}

---@param maxGroup? integer
---@return function
local function IterateRosterUnits(maxGroup)
	maxGroup = maxGroup or 8
	local index = 0
	local numMembers = GetNumGroupMembers()
	return function()
		index = index + 1

		if index == 1 and numMembers <= 4 then
			return "player"
		end

		if index > numMembers then
			return nil
		end

		if IsInRaid() then
			local _, _, subgroup = GetRaidRosterInfo(index)
			if subgroup and subgroup <= maxGroup then
				return "raid" .. index
			else
				return nil
			end
		else
			return "party" .. (index - 1)
		end
	end
end

-- Creates a table where keys are player names and values are colored names.
local function GSubAutoColorCreate()
	wipe(Private.GSubAutoColorData)
	for unit in IterateRosterUnits() do
		if unit then
			local _, classFileName, _ = UnitClass(unit)
			local unitName, unitServer = UnitName(unit)
			local classData = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classFileName]
			local coloredName = ("|c%s%s|r"):format(classData.colorStr, unitName)
			if unitServer then -- nil if on same server
				Private.GSubAutoColorData[unitName.join("-", unitServer)] = coloredName
			end
			Private.GSubAutoColorData[unitName] = coloredName
		end
	end
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
	local tableList = strsplittable(",", list)
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
	local tableList = strsplittable(",", list)
	local found = false
	for i = 1, #tableList do
		tableList[i] = tableList[i]
			:gsub("|?|c........", "")
			:gsub("|?|r", ""):lower()
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
	local tableList = strsplittable(",", list)
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
	local tableList = strsplittable(",", list)
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

local function ParseTime(preText, t, msg, newlinesym)
	local timeText, opts = strsplit(",", t, 2)

	local time = tonumber(timeText)
	if not time then
		local min, sec = strsplit(":", timeText)
		if min and sec then
			time = (tonumber(min) or 0) * 60 + (tonumber(sec) or 0)
		else
			time = -1
		end
	end
end

-- Replaces regular name text with class-colored name text.
---@param lines string
---@return string
local function ReplaceNamesWithColoredNamesIfFound(lines)
	local result, _ = lines:gsub(nonSymbolRegex, function(word)
		return Private.GSubAutoColorData[word] or word
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
	local spellTexture = C_Spell.GetSpellTexture(spellID)
	return "|T" .. (spellTexture or "Interface\\Icons\\INV_MISC_QUESTIONMARK") .. ":16|t"
end

-- Extracts inputs from a line of text.
---@param line string
---@param time number
---@return table
local function ExtractInputs(line, time)
	local inputs = {}
	for str in (line .. "  "):gmatch(wordSegmentationRegex) do
		local targetName               = (str:match(targetNameRegex) or "")
			:gsub(doublePipeRegex, "|")
			:gsub(colorStartRegex, "")
			:gsub(colorEndRegex, "")
		local text                     = str:match(textRegex)
		local spellinfo                = { spellID = 0, name = "", iconID = 0 }
		local strWithoutSpell          = str:gsub(displayStringRegex, function(rest, id)
			spellinfo = C_Spell.GetSpellInfo(id)
			return rest
		end)
		local textWithIconReplacements = nil
		if text then
			textWithIconReplacements = text
				:gsub(spellIconRegex, GSubIcon)
				:gsub(raidIconRegex, "|T%1:16|t")
				:gsub(ertIconRegex, localERTIcons)
				:gsub(doublePipeRegex, "|")
				:gsub(dashRegex, "")
		end
		local strWithIconReplacements = str
			:gsub(spellIconRegex, GSubIcon)
			:gsub(raidIconRegex, "|T%1:16|t")
			:gsub(ertIconRegex, localERTIcons)
			:gsub(doublePipeRegex, "|")
			:gsub(dashRegex, "")
		inputs[#inputs + 1]           = {
			time = time,
			line = str,
			text = text,
			textWithIconReplacements = textWithIconReplacements,
			strWithIconReplacements = strWithIconReplacements, -- Similar to how appear in Note
			assigneeNameOrRole = strWithoutSpell,
			spellinfo = spellinfo,
			assignedUnit = targetName,
		}
	end
	return inputs
end

-- Inserts the timer into the correct table based on options.
---@param timer table
---@param options string
---@param noteType string
function Private:ProcessOptions(timer, options, noteType)
	local regularTimer = true
	local option = nil
	while options do
		option, options = strsplit(",", options, 2)
		if option == "e" then
			if options then
				option, options = strsplit(",", options, 2)
			else
				option = nil
			end
			if option then -- custom event
				if not self.customTimers[option] then
					self.customTimers[option] = {}
				end
				tinsert(self.phaseBasedTimers[option], timer)
				regularTimer = false
			end
		elseif option:sub(1, 1) == "p" then
			local _, phase = option:match(phaseNumberRegex)
			if phase and phase ~= "" then
				phase = tonumber(phase)
				for _, input in pairs(timer.inputs) do
					input.phase = phase
				end
				local phaseText = "p" .. phase
				if not self.phaseBasedTimers[phaseText] then
					self.phaseBasedTimers[phaseText] = {}
				end
				tinsert(self.phaseBasedTimers[phaseText], timer)
				regularTimer = false
			end
		else
			local combatLogEventAbbreviation, spellID, phase = strsplit(":", option, 3)
			if combatLogEventFromAbbreviation[combatLogEventAbbreviation] then
				if not self.phaseBasedTimers[combatLogEventAbbreviation] then
					self.phaseBasedTimers[combatLogEventAbbreviation] = {}
				end
				if not self.phaseBasedTimers[combatLogEventAbbreviation][spellID] then
					self.phaseBasedTimers[combatLogEventAbbreviation][spellID] = {}
				end
				if not self.phaseBasedTimers[combatLogEventAbbreviation][spellID][phase] then
					self.phaseBasedTimers[combatLogEventAbbreviation][spellID][phase] = {}
				end
				tinsert(self.phaseBasedTimers[combatLogEventAbbreviation][spellID][phase], timer)
				regularTimer = false
			end
		end
	end
	if regularTimer then
		self.absoluteTimeBasedTimers[#self.absoluteTimeBasedTimers + 1] = timer
	end
end

---@param text string
---@param noteType string
function Private:ParseNote(text, noteType)
	--self.filteredText = Filter(text)
	--self.filteredText = FilterByCurrentRole(self.filteredText)
	--self.filteredText = ReplaceNamesWithColoredNamesIfFound(self.filteredText)

	for line in text:gmatch(lineRegex) do
		local minute, sec, options = line:match(timeOptionsSplitRegex)
		local time = nil
		if minute and sec then
			time = tonumber(sec) + (tonumber(minute) * 60)
		elseif minute and (sec == nil or sec == "") then
			time = tonumber(minute)
		end
		if time then
			local inputs = ExtractInputs(line, time)
			self:ProcessOptions(inputs, options, noteType)
		end
	end
end

function Private:Note()
	if not C_AddOns.IsAddOnLoaded("MRT") then return end
	GSubAutoColorCreate()
	if GMRT and GMRT.F then
		self:ParseNote(VMRT.Note.Text1 or "", "shared")
		self:ParseNote(VMRT.Note.SelfText or "", "personal")
		DevTool:AddData(self)
	end
end
