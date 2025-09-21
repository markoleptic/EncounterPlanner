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
---@class RosterEntry
local RosterEntry = Private.classes.RosterEntry
---@class TimelineAssignment
local TimelineAssignment = Private.classes.TimelineAssignment
local DeepCopy = Private.DeepCopy

---@class Constants
local constants = Private.constants
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class AssignmentUtilities
local assignmentUtilities = Private.assignmentUtilities

---@class Utilities
local Utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local FindBossAbility = bossUtilities.FindBossAbility
local GetAbsoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable
local GetBoss = bossUtilities.GetBoss
local GetBossName = bossUtilities.GetBossName
local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases

local DifficultyType = Private.classes.DifficultyType

local assert = assert
local floor = math.floor
local format = string.format
local GetClassColor = C_ClassColor.GetClassColor
local getmetatable, setmetatable = getmetatable, setmetatable
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetSpellBaseCooldown = GetSpellBaseCooldown
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local ipairs = ipairs
local IsInRaid = IsInRaid
local max, min = math.max, math.min
local next = next
local pairs = pairs
local select = select
local sort = table.sort
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitClass = UnitClass
local UnitFullName = UnitFullName
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local wipe = table.wipe

do
	local GetClassInfo = GetClassInfo
	local GetClassIDFromSpecID = C_SpecializationInfo.GetClassIDFromSpecID
	local GetSpecializationInfoForSpecID = GetSpecializationInfoForSpecID
	local rawget = rawget
	local rawset = rawset
	local kNumberOfClasses = GetNumClasses()

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

	-- class as class file name, role as RaidGroupRole
	---@type table<integer, {class: string, role: RaidGroupRole}>
	local sSpecIDToClassAndRole = {}

	for specID, _ in pairs(specIDToType) do
		local _, name, _, icon, role = GetSpecializationInfoForSpecID(specID)
		local classID = GetClassIDFromSpecID(specID)
		local classFile = select(2, GetClassInfo(classID))
		local inlineIcon = format(constants.kFormatStringGenericInlineIconWithZoom, icon)
		specIDToIconAndName[specID] = format("%s %s", inlineIcon, name)
		specIDToName[specID] = name
		sSpecIDToClassAndRole[specID] = {
			class = classFile,
			role = "role:" .. role:lower(),
		}
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

	---@type table<integer, string>
	local sClassFileNames = {}

	---@type table<integer, string>
	local sUnformattedClassIcons = setmetatable({}, caseAndWhiteSpaceInsensitiveMetaTable)

	for i = 1, kNumberOfClasses do
		local className, classFile, classID = GetClassInfo(i)
		tinsert(sClassFileNames, classFile)
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

		local unformattedClassIcon = "Interface\\Icons\\ClassIcon_" .. classNameWithoutSpaces
		sUnformattedClassIcons[classFile] = unformattedClassIcon

		local classIcon = "|T" .. unformattedClassIcon .. ":0|t"
		genericIcons[format("%s", classFile)] = classIcon
		genericIcons[format("%s", className)] = classIcon
		genericIcons[format("%d", classID)] = classIcon
	end

	---@return table<integer, string>
	function Utilities.GetClassFileNames()
		return sClassFileNames
	end

	---@param specIDOrFormattedSpecDataType integer|string
	---@return string classFileName
	---@return RaidGroupRole raidGroupRole
	function Utilities.GetClassAndRoleFromSpecID(specIDOrFormattedSpecDataType)
		local specID = specIDOrFormattedSpecDataType
		if type(specIDOrFormattedSpecDataType) == "string" then
			local match = specIDOrFormattedSpecDataType:match("spec:%s*(%d+)")
			if match then
				specID = tonumber(match)
			end
		end
		return sSpecIDToClassAndRole[specID].class, sSpecIDToClassAndRole[specID].role
	end

	---@param className string
	---@return string
	function Utilities.GetFormattedDataClassName(className)
		return "class:" .. englishClassNamesWithoutSpaces[className]
	end

	---@param classFileName string
	---@return boolean
	function Utilities.IsValidClassFileName(classFileName)
		return englishClassNamesWithoutSpaces[classFileName] ~= nil
	end

	---@param text string Class file name, localized class name, or class ID.
	---@return string
	function Utilities.GetUnformattedClassIcon(text)
		return sUnformattedClassIcons[text]
	end

	---@param text string
	---@return string
	function Utilities.ReplaceGenericIconsOrSpells(text)
		local result, _ = text:gsub("{(.-)}", function(match)
			local genericIcon = genericIcons[match]
			if genericIcon then
				return genericIcon:gsub(":16|t", ":0|t")
			else
				local texture = GetSpellTexture(match)
				if texture then
					return format("|T%s:0|t", texture)
				end
			end
			return "{" .. match .. "}"
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
		local specIDs = {}
		for specID, _ in pairs(specIDToType) do
			tinsert(specIDs, specID)
		end
		return specIDs
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

do
	local AddOn = Private.addOn

	---@return table<string, RosterEntry>
	function Utilities.GetCurrentRoster()
		local lastOpenPlan = AddOn.db.profile.lastOpenPlan
		local plan = AddOn.db.profile.plans[lastOpenPlan]
		return plan.roster
	end

	---@return table<integer, Assignment>
	function Utilities.GetCurrentAssignments()
		local lastOpenPlan = AddOn.db.profile.lastOpenPlan
		local plan = AddOn.db.profile.plans[lastOpenPlan]
		return plan.assignments
	end

	---@return Plan
	function Utilities.GetCurrentPlan()
		return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
	end

	---@return Boss|nil
	function Utilities.GetCurrentBoss()
		return GetBoss(Private.mainFrame.bossLabel:GetValue())
	end

	---@return integer
	function Utilities.GetCurrentBossDungeonEncounterID()
		return Private.mainFrame.bossLabel:GetValue()
	end

	---@return DifficultyType
	function Utilities.GetCurrentDifficulty()
		return Private.mainFrame.difficultyLabel:GetValue()
	end

	---@param dungeonEncounterID integer
	---@param difficultyType DifficultyType
	---@return table<integer, boolean>
	function Utilities.GetActiveBossAbilities(dungeonEncounterID, difficultyType)
		if difficultyType == DifficultyType.Heroic then
			if AddOn.db.profile.activeBossAbilitiesHeroic[dungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilitiesHeroic[dungeonEncounterID] = {}
			end
			return AddOn.db.profile.activeBossAbilitiesHeroic[dungeonEncounterID]
		else
			if AddOn.db.profile.activeBossAbilities[dungeonEncounterID] == nil then
				AddOn.db.profile.activeBossAbilities[dungeonEncounterID] = {}
			end
			return AddOn.db.profile.activeBossAbilities[dungeonEncounterID]
		end
	end
end

---@param value number
---@param minValue number
---@param maxValue number
---@return number
function Utilities.Clamp(value, minValue, maxValue)
	return min(maxValue, max(minValue, value))
end

---@param templates table<integer, PlanTemplate>
---@param newTemplateName string
---@return string
function Utilities.CreateUniqueTemplateName(templates, newTemplateName)
	local templateName = newTemplateName

	local function ContainsTemplateName(name)
		for _, template in ipairs(templates) do
			if template.name == name then
				return true
			end
		end
		return false
	end

	if templates then
		local baseName, suffix = templateName:match("^(.-)%s*(%d*)$")
		baseName = baseName or ""
		local num = tonumber(suffix) or 1

		if ContainsTemplateName(templateName) then
			num = suffix ~= "" and (num + 1) or 2
		end

		while ContainsTemplateName(templateName) do
			local suffixStr = " " .. num
			local maxBaseLength = 36 - #suffixStr
			local truncatedBase = #baseName > 0 and baseName:sub(1, maxBaseLength) or tostring(num)
			templateName = truncatedBase .. suffixStr
			num = num + 1
		end
	end
	return templateName
end

---@param plans table<string, Plan>
---@param newPlanName string
---@return string
function Utilities.CreateUniquePlanName(plans, newPlanName)
	local planName = newPlanName
	if plans then
		local baseName, suffix = planName:match("^(.-)%s*(%d*)$")
		baseName = baseName or ""
		local num = tonumber(suffix) or 1

		if plans[planName] then
			num = suffix ~= "" and (num + 1) or 2
		end

		while plans[planName] do
			local suffixStr = " " .. num
			local maxBaseLength = 36 - #suffixStr
			local truncatedBase = #baseName > 0 and baseName:sub(1, maxBaseLength) or tostring(num)
			planName = truncatedBase .. suffixStr
			num = num + 1
		end
	end
	return planName
end

do
	---@param str string
	---@return string|nil
	---@return integer
	local function Utf8firstChar(str)
		local b = str:byte(1)
		if not b then
			return nil, 0
		end
		if b < 0x80 then
			return str:sub(1, 1), 1 -- ASCII (1 byte)
		elseif b < 0xE0 then
			return str:sub(1, 2), 2 -- 2 byte sequence
		elseif b < 0xF0 then
			return str:sub(1, 3), 3 -- 3 byte sequence
		else
			return str:sub(1, 4), 4 -- 4 byte sequence
		end
	end

	---@param str string
	---@return string
	function Utilities.UpperCaseFirst(str)
		local first, size = Utf8firstChar(str)
		if not first then
			return str
		end
		local rest = str:sub(size + 1)
		return first:upper() .. rest:lower()
	end
end

---@param assignments table<integer, Assignment>
---@param assignmentID integer
---@return Assignment|TimedAssignment|CombatLogEventAssignment|nil
function Utilities.FindAssignmentByUniqueID(assignments, assignmentID)
	for _, assignment in pairs(assignments) do
		if assignment.uniqueID == assignmentID then
			return assignment
		end
	end
end

do
	local mod = math.fmod
	local kIconSize = 32

	---@param difficulty DifficultyType
	---@param fraction boolean
	---@param padding? integer
	---@return number, number, number, number
	function Utilities.GetTextCoordsFromDifficulty(difficulty, fraction, padding)
		local iconIndex
		if difficulty == DifficultyType.Heroic then
			iconIndex = 3
		else
			iconIndex = 12
		end
		local columns = 256 / kIconSize
		padding = padding or 8

		local l = (mod(iconIndex, columns) * kIconSize + padding) / 4
		local r = ((mod(iconIndex, columns) + 1) * kIconSize - padding) / 4
		local t = (floor(iconIndex / columns) * kIconSize + padding)
		local b = ((floor(iconIndex / columns) + 1) * kIconSize - padding)

		if fraction then
			l = l / 64
			r = r / 64
			t = t / 64
			b = b / 64
		end

		return l, r, t, b
	end
end

do
	local cache = setmetatable({}, { __mode = "kv" })
	local kFavoriteFilledTexture = constants.textures.kFavoriteFilled
	local kFavoriteOutlineTexture = constants.textures.kFavoriteOutlined

	---@param dropdownItemMenuData table<integer, DropdownItemData>
	---@param visible boolean
	---@param favoritedItemsMap? table<integer, boolean>
	local function SetFavoriteTextureVisibility(dropdownItemMenuData, visible, favoritedItemsMap)
		for _, data in ipairs(dropdownItemMenuData) do
			if not data.dropdownItemMenuData then
				if visible then
					if favoritedItemsMap and favoritedItemsMap[data.itemValue] then
						data.customTexture = kFavoriteFilledTexture
					else
						data.customTexture = kFavoriteOutlineTexture
					end
					data.customTextureVertexColor = { 1, 1, 1, 1 }
					data.customTextureSelectable = true
				else
					data.customTexture = nil
					data.customTextureVertexColor = nil
					data.customTextureSelectable = nil
				end
			else
				SetFavoriteTextureVisibility(data.dropdownItemMenuData, visible, favoritedItemsMap)
			end
		end
	end

	local kFormatStringGenericInlineIconWithZoom = constants.kFormatStringGenericInlineIconWithZoom
	local GetFormattedDataClassName = Utilities.GetFormattedDataClassName

	---@param classFileName string
	---@param role? RaidGroupRole
	---@param showFavoriteTexture? boolean
	---@param favoritedItemsMap? table<integer, boolean>
	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateSingleClassSpellDropdownItems(
		classFileName,
		role,
		showFavoriteTexture,
		favoritedItemsMap
	)
		local formattedDataClassName = classFileName
		local classMatch = formattedDataClassName:match("class:%s*(%a+)")
		if classMatch then
			classFileName = classMatch
		else
			formattedDataClassName = GetFormattedDataClassName(classFileName)
		end

		local dropdownItemData = {}

		if cache["class"] ~= nil and role == nil then -- Return unfiltered items for class
			for _, classDropdownData in ipairs(cache["class"].dropdownItemMenuData) do
				if classDropdownData.itemValue == formattedDataClassName then
					dropdownItemData = classDropdownData.dropdownItemMenuData
					break
				end
			end
		end

		if dropdownItemData and #dropdownItemData == 0 then
			local classSpells = Private.spellDB.classes[classFileName:upper()]
			local spellTypeIndex = 1
			local spellTypeIndexMap = {}
			for _, spell in pairs(classSpells) do
				if not role or not spell["role"] or spell["role"][role] == true then
					local spellType = spell["type"]
					if not spellTypeIndexMap[spellType] then
						dropdownItemData[spellTypeIndex] = {
							itemValue = spellType,
							text = spellType,
							dropdownItemMenuData = {},
						}
						spellTypeIndexMap[spellType] = spellTypeIndex
						spellTypeIndex = spellTypeIndex + 1
					end
					local currentSpellTypeIndex = spellTypeIndexMap[spellType]
					local spellID = spell["spellID"]
					local name = GetSpellName(spellID)
					local icon = GetSpellTexture(spellID)
					if name and icon then
						local inlineIcon = format(kFormatStringGenericInlineIconWithZoom, icon)
						local iconAndText = format("%s %s", inlineIcon, name)
						tinsert(dropdownItemData[currentSpellTypeIndex].dropdownItemMenuData, {
							itemValue = spellID,
							text = iconAndText,
						})
					--@debug@
					else
						print(format("%s: %s spell not found.", AddOnName, spellID))
						--@end-debug@
					end
				end
			end
		end

		if favoritedItemsMap then
			SetFavoriteTextureVisibility(dropdownItemData, showFavoriteTexture, favoritedItemsMap)
		end

		Utilities.SortClassCategoryDropdownItemData(dropdownItemData)
		return dropdownItemData
	end

	---@param showFavoriteTexture boolean
	---@param favoritedItemsMap? table<integer, boolean>
	---@return DropdownItemData
	function Utilities.GetOrCreateClassSpellDropdownItems(showFavoriteTexture, favoritedItemsMap)
		if not cache["class"] then
			local dropdownItems = {} ---@type table<integer, DropdownItemData>

			for _, classFileName in ipairs(Utilities.GetClassFileNames()) do
				tinsert(dropdownItems, {
					itemValue = GetFormattedDataClassName(classFileName),
					text = Utilities.GetLocalizedPrettyClassName(classFileName),
					dropdownItemMenuData = Utilities.GetOrCreateSingleClassSpellDropdownItems(classFileName),
				})
			end
			Utilities.SortClassCategoryDropdownItemData(dropdownItems)
			cache["class"] = { itemValue = "Class", text = L["Class"], dropdownItemMenuData = dropdownItems }
		end

		-- Remove class icons from text
		for _, classDropdownData in ipairs(cache["class"].dropdownItemMenuData) do
			for _, entry in ipairs(classDropdownData.dropdownItemMenuData) do
				entry.text = entry.itemValue
			end
		end

		SetFavoriteTextureVisibility(cache["class"].dropdownItemMenuData, showFavoriteTexture, favoritedItemsMap)
		return cache["class"]
	end

	---@param showFavoriteTexture boolean
	---@param favoritedItemsMap table<integer, boolean>
	---@return DropdownItemData
	local function GetOrCreateRacialSpellDropdownItems(showFavoriteTexture, favoritedItemsMap)
		if not cache["racial"] then
			cache["racial"] = {} --[[@as table<string, DropdownItemData>]]
			local dropdownItems = cache["racial"]
			for _, racialInfo in pairs(Private.spellDB.other["RACIAL"]) do
				local name = GetSpellName(racialInfo["spellID"])
				local icon = GetSpellTexture(racialInfo["spellID"])
				local inlineIcon = format(kFormatStringGenericInlineIconWithZoom, icon)
				local iconText = format("%s %s", inlineIcon, name)
				tinsert(dropdownItems, {
					itemValue = racialInfo["spellID"],
					text = iconText,
				})
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			cache["racial"] = { itemValue = "Racial", text = L["Racial"], dropdownItemMenuData = dropdownItems }
		end
		SetFavoriteTextureVisibility(cache["racial"].dropdownItemMenuData, showFavoriteTexture, favoritedItemsMap)
		return cache["racial"]
	end

	---@param showFavoriteTexture boolean
	---@param favoritedItemsMap table<integer, boolean>
	---@return DropdownItemData
	local function GetOrCreateConsumableSpellDropdownItems(showFavoriteTexture, favoritedItemsMap)
		if not cache["consumable"] then
			cache["consumable"] = {} --[[@as table<string, DropdownItemData>]]
			local dropdownItems = cache["consumable"]
			for _, consumableInfo in pairs(Private.spellDB.other["CONSUMABLE"]) do
				local name = GetSpellName(consumableInfo["spellID"])
				local icon = GetSpellTexture(consumableInfo["spellID"])
				local inlineIcon = format(kFormatStringGenericInlineIconWithZoom, icon)
				local iconText = format("%s %s", inlineIcon, name)
				tinsert(dropdownItems, {
					itemValue = consumableInfo["spellID"],
					text = iconText,
				})
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			cache["consumable"] =
				{ itemValue = "Consumable", text = L["Consumable"], dropdownItemMenuData = dropdownItems }
		end
		SetFavoriteTextureVisibility(cache["consumable"].dropdownItemMenuData, showFavoriteTexture, favoritedItemsMap)
		return cache["consumable"]
	end

	---@param showFavoriteTexture boolean
	---@param favoritedItems? table<integer, DropdownItemData>
	---@return DropdownItemData
	function Utilities.GetOrCreateSpellAssignmentDropdownItems(showFavoriteTexture, favoritedItems)
		local favoritedItemsMap = {}
		if favoritedItems then
			for _, v in ipairs(favoritedItems) do
				favoritedItemsMap[v.itemValue] = true
			end
		end
		return {
			Utilities.GetOrCreateClassSpellDropdownItems(showFavoriteTexture, favoritedItemsMap),
			GetOrCreateRacialSpellDropdownItems(showFavoriteTexture, favoritedItemsMap),
			GetOrCreateConsumableSpellDropdownItems(showFavoriteTexture, favoritedItemsMap),
		}
	end
end

do
	local classDropdownData = nil

	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateClassDropdownItemData()
		if not classDropdownData then
			local dropdownData = {}
			for _, classFileName in ipairs(Utilities.GetClassFileNames()) do
				local classData = {
					itemValue = Utilities.GetFormattedDataClassName(classFileName),
					text = Utilities.GetLocalizedPrettyClassName(classFileName),
				}
				tinsert(dropdownData, classData)
			end
			Utilities.SortDropdownDataByItemValue(dropdownData)
			classDropdownData = dropdownData
		end

		return classDropdownData
	end
end

do
	local specDropdownItems = nil
	local addedClassAndSpecDropdownItems = false
	local assignmentTypes = {
		{
			text = L["Group Number"],
			itemValue = "Group Number",
			dropdownItemMenuData = {
				{ text = "1", itemValue = "group:1" },
				{ text = "2", itemValue = "group:2" },
				{ text = "3", itemValue = "group:3" },
				{ text = "4", itemValue = "group:4" },
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

	---@return DropdownItemData
	local function GetOrCreateSpecDropdownItems()
		if not specDropdownItems then
			local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
			for _, specID in ipairs(Utilities.GetSpecIDs()) do
				tinsert(dropdownItems, {
					itemValue = "spec:" .. tostring(specID),
					text = Utilities.GetSpecIconAndLocalizedSpecName(specID),
				})
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			specDropdownItems = { itemValue = "Spec", text = L["Spec"], dropdownItemMenuData = dropdownItems }
		end
		return specDropdownItems
	end

	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateAssignmentTypeDropdownItems()
		if not addedClassAndSpecDropdownItems then
			local classAssignmentTypes = {
				text = L["Class"],
				itemValue = "Class",
				dropdownItemMenuData = Utilities.GetOrCreateClassDropdownItemData(),
			}
			tinsert(assignmentTypes, classAssignmentTypes)
			tinsert(assignmentTypes, GetOrCreateSpecDropdownItems())
			Utilities.SortDropdownDataByItemValue(assignmentTypes)
			addedClassAndSpecDropdownItems = true
		end
		for _, assignmentType in ipairs(assignmentTypes) do
			if assignmentType.itemValue == "Individual" then
				wipe(assignmentType.dropdownItemMenuData)
				break
			end
		end
		return assignmentTypes
	end
end

do
	local kRegexIconText = constants.kRegexIconText

	---@param a DropdownItemData|{order:integer}
	---@param b DropdownItemData|{order:integer}
	local function SortInstances(a, b)
		local aInstance, bInstance

		if a.order and b.order then
			return a.order < b.order
		end

		if type(a.itemValue) == "table" then
			aInstance = bossUtilities.FindDungeonInstance(a.itemValue.dungeonInstanceID, a.itemValue.mapChallengeModeID)
		else
			aInstance = bossUtilities.FindDungeonInstance(a.itemValue)
		end
		if type(b.itemValue) == "table" then
			bInstance = bossUtilities.FindDungeonInstance(b.itemValue.dungeonInstanceID, b.itemValue.mapChallengeModeID)
		else
			bInstance = bossUtilities.FindDungeonInstance(b.itemValue)
		end

		if aInstance and bInstance then
			if aInstance.isRaid then
				if not bInstance.isRaid then
					return true
				end
			elseif bInstance.isRaid then
				return false
			end
		end

		return a.text:match(kRegexIconText) < b.text:match(kRegexIconText)
	end

	local kFormatStringGenericInlineIconWithText = constants.kFormatStringGenericInlineIconWithText

	do
		local instanceAndBossDropdownItems = nil

		-- Creates dropdown item data for instances and bosses
		---@return table<integer, DropdownItemData>
		function Utilities.GetOrCreateBossDropdownItems()
			if not instanceAndBossDropdownItems then
				instanceAndBossDropdownItems = {}
				for dungeonInstance in bossUtilities.IterateDungeonInstances() do
					local instanceIconText =
						format(kFormatStringGenericInlineIconWithText, dungeonInstance.icon, dungeonInstance.name)
					local instanceDropdownData
					if dungeonInstance.mapChallengeModeID then
						instanceDropdownData = {
							itemValue = {
								dungeonInstanceID = dungeonInstance.instanceID,
								mapChallengeModeID = dungeonInstance.mapChallengeModeID,
							},
							text = instanceIconText,
							dropdownItemMenuData = {},
						}
					else
						instanceDropdownData = {
							itemValue = dungeonInstance.instanceID,
							text = instanceIconText,
							dropdownItemMenuData = {},
						}
					end
					for _, boss in ipairs(dungeonInstance.bosses) do
						local iconText = format(kFormatStringGenericInlineIconWithText, boss.icon, boss.name)
						tinsert(
							instanceDropdownData.dropdownItemMenuData,
							{ itemValue = boss.dungeonEncounterID, text = iconText }
						)
					end
					tinsert(instanceAndBossDropdownItems, instanceDropdownData)
				end
				sort(instanceAndBossDropdownItems, SortInstances)
			end
			return instanceAndBossDropdownItems
		end
	end

	local kFormatStringDifficultyIcon = constants.kFormatStringDifficultyIcon
	local kEncounterJournalIcons = constants.textures.kEncounterJournalIcons
	local kUnknownTexture = constants.textures.kUnknown

	do
		local kOffsetX = -6
		local difficultyTextCoordPadding = 6
		local l, r, t, b =
			Utilities.GetTextCoordsFromDifficulty(DifficultyType.Heroic, false, difficultyTextCoordPadding)
		local kHeroicIcon = format(kFormatStringDifficultyIcon, kEncounterJournalIcons, kOffsetX, l, r, t, b)
		l, r, t, b = Utilities.GetTextCoordsFromDifficulty(DifficultyType.Mythic, false, difficultyTextCoordPadding)
		local kMythicIcon = format(kFormatStringDifficultyIcon, kEncounterJournalIcons, kOffsetX, l, r, t, b)
		local kFormatStringPlanName = constants.kFormatStringGenericInlineIconWithZoom .. "%s%s"

		---@param planName string
		---@param bossIcon string|integer
		---@param difficulty DifficultyType
		---@return string
		function Utilities.FormatPlanText(planName, bossIcon, difficulty)
			local difficultyIcon
			if difficulty == DifficultyType.Heroic then
				difficultyIcon = kHeroicIcon
			else
				difficultyIcon = kMythicIcon
			end
			return format(kFormatStringPlanName, bossIcon, difficultyIcon, planName)
		end
	end

	do
		local kOffsetX = 0
		local l, r, t, b = Utilities.GetTextCoordsFromDifficulty(DifficultyType.Heroic, false, 6)
		local kHeroicIcon = format(kFormatStringDifficultyIcon, kEncounterJournalIcons, kOffsetX, l, r, t, b)
		l, r, t, b = Utilities.GetTextCoordsFromDifficulty(DifficultyType.Mythic, false, 6)
		local kMythicIcon = format(kFormatStringDifficultyIcon, kEncounterJournalIcons, kOffsetX, l, r, t, b)
		local kHeroicIconText = format("%s %s", kHeroicIcon, L["Heroic"])
		local kMythicIconText = format("%s %s", kMythicIcon, L["Mythic"])

		local instanceAndBossDropdownItemsWithDifficulty
		-- Creates dropdown item data for instances and bosses
		---@return table<integer, DropdownItemData>
		function Utilities.GetOrCreateBossDropdownItemsWithDifficulty()
			if not instanceAndBossDropdownItemsWithDifficulty then
				instanceAndBossDropdownItemsWithDifficulty = {}
				for dungeonInstance in bossUtilities.IterateDungeonInstances() do
					local instanceIconText =
						format(kFormatStringGenericInlineIconWithText, dungeonInstance.icon, dungeonInstance.name)
					local instanceDropdownData
					if dungeonInstance.mapChallengeModeID then
						instanceDropdownData = {
							itemValue = {
								dungeonInstanceID = dungeonInstance.instanceID,
								mapChallengeModeID = dungeonInstance.mapChallengeModeID,
							},
							text = instanceIconText,
							dropdownItemMenuData = {},
						}
					else
						instanceDropdownData = {
							itemValue = dungeonInstance.instanceID,
							text = instanceIconText,
							dropdownItemMenuData = {},
						}
					end

					if dungeonInstance.hasHeroic then
						instanceDropdownData.dropdownItemMenuData = {
							{
								itemValue = DifficultyType.Heroic,
								text = kHeroicIconText,
								dropdownItemMenuData = {},
							},
							{
								itemValue = DifficultyType.Mythic,
								text = kMythicIconText,
								dropdownItemMenuData = {},
							},
						}
						for _, boss in ipairs(dungeonInstance.bosses) do
							local iconText = format(kFormatStringGenericInlineIconWithText, boss.icon, boss.name)
							local data = { itemValue = boss.dungeonEncounterID, text = iconText }
							if boss.phasesHeroic then
								tinsert(instanceDropdownData.dropdownItemMenuData[1].dropdownItemMenuData, data)
							end
							if boss.phases then
								tinsert(instanceDropdownData.dropdownItemMenuData[2].dropdownItemMenuData, data)
							end
						end
					else
						for _, boss in ipairs(dungeonInstance.bosses) do
							local iconText = format(kFormatStringGenericInlineIconWithText, boss.icon, boss.name)
							tinsert(
								instanceDropdownData.dropdownItemMenuData,
								{ itemValue = boss.dungeonEncounterID, text = iconText }
							)
						end
					end
					tinsert(instanceAndBossDropdownItemsWithDifficulty, instanceDropdownData)
				end
				sort(instanceAndBossDropdownItemsWithDifficulty, SortInstances)
			end
			return instanceAndBossDropdownItemsWithDifficulty
		end
	end

	---@return table<integer, DropdownItemData>
	local function CreateInstanceDropdownData()
		local customInstanceDropdownItems = {} ---@type table<integer, DropdownItemData>
		local customInstanceDropdownItemChildren = {} ---@type table<string, table<integer, DropdownItemData>>

		for _, customDungeonInstanceGroup in pairs(Private.customDungeonInstanceGroups) do
			local instanceName = customDungeonInstanceGroup.instanceName
			local instanceToUseForIcon = Private.dungeonInstances[customDungeonInstanceGroup.instanceIDToUseForIcon]
			local instanceIconText
			if instanceToUseForIcon then
				instanceIconText =
					format(kFormatStringGenericInlineIconWithText, instanceToUseForIcon.icon, instanceName)
			else
				instanceIconText = format(kFormatStringGenericInlineIconWithText, kUnknownTexture, instanceName)
			end

			---@type DropdownItemData|{order:integer}
			local customInstanceDropdownData = {
				itemValue = customDungeonInstanceGroup.instanceName,
				text = instanceIconText,
				notSelectable = true,
				notClickable = true,
				order = customDungeonInstanceGroup.order,
			}
			tinsert(customInstanceDropdownItems, customInstanceDropdownData)
			customInstanceDropdownItemChildren[instanceName] = {}
		end

		local kCustomGroupIndent = 10
		local instanceDropdownItems = {} ---@type table<integer, DropdownItemData>
		for dungeonInstance in bossUtilities.IterateDungeonInstances() do
			local instanceIconText =
				format(kFormatStringGenericInlineIconWithText, dungeonInstance.icon, dungeonInstance.name)
			---@type DropdownItemData
			local instanceDropdownData = {
				text = instanceIconText,
				dropdownItemMenuData = {},
				itemMenuClickable = true,
				itemValue = nil,
			}
			if dungeonInstance.mapChallengeModeID then
				instanceDropdownData.itemValue = {
					dungeonInstanceID = dungeonInstance.instanceID,
					mapChallengeModeID = dungeonInstance.mapChallengeModeID,
				}
			else
				instanceDropdownData.itemValue = dungeonInstance.instanceID
			end
			if dungeonInstance.customGroups then
				instanceDropdownData.indent = kCustomGroupIndent
				for _, customGroup in pairs(dungeonInstance.customGroups) do
					local name = Private.customDungeonInstanceGroups[customGroup].instanceName
					tinsert(customInstanceDropdownItemChildren[name], instanceDropdownData)
				end
			else
				tinsert(instanceDropdownItems, instanceDropdownData)
			end
		end

		for _, children in pairs(customInstanceDropdownItemChildren) do
			sort(children, SortInstances)
		end
		sort(instanceDropdownItems, SortInstances)
		sort(customInstanceDropdownItems, SortInstances)
		for _, dropdownItemData in ipairs(customInstanceDropdownItems) do
			tinsert(instanceDropdownItems, dropdownItemData)
			for _, children in pairs(customInstanceDropdownItemChildren[dropdownItemData.itemValue]) do
				tinsert(instanceDropdownItems, children)
			end
		end

		return instanceDropdownItems
	end

	local instanceDropdownItems = nil

	-- Creates dropdown item data for instances
	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateInstanceDropdownItems()
		if not instanceDropdownItems then
			instanceDropdownItems = CreateInstanceDropdownData()
		end
		return instanceDropdownItems
	end
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
---@param assigneeDropdownItems? table<integer, DropdownItemData>
---@return table<integer, DropdownItemData>
---@return boolean individualEmpty
function Utilities.CreateAssignmentTypeWithRosterDropdownItems(roster, assigneeDropdownItems)
	local assignmentTypes = Utilities.GetOrCreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	local individualEmpty = true
	if individualIndex then
		if assigneeDropdownItems then
			assignmentTypes[individualIndex].dropdownItemMenuData = assigneeDropdownItems
		elseif roster then
			assignmentTypes[individualIndex].dropdownItemMenuData = Utilities.CreateAssigneeDropdownItems(roster)
		end
		Utilities.SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
		individualEmpty = #assignmentTypes[individualIndex].dropdownItemMenuData > 0
	end
	return assignmentTypes, individualEmpty
end

---@param icon string|integer
---@param text string
---@return DropdownItemData
function Utilities.CreateAbilityDropdownItemData(abilityID, icon, text)
	local inlineIcon = format(constants.kFormatStringGenericInlineIconWithZoom, icon)
	local iconText = format("%s %s", inlineIcon, text)
	return { itemValue = abilityID, text = iconText }
end

do
	local GetAdjustedStartTime = bossUtilities.GetAdjustedStartTime

	-- Updates a timeline assignment's start time.
	---@param timelineAssignment TimelineAssignment
	---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it.
	---@param difficulty DifficultyType
	---@return boolean -- Whether or not the update succeeded
	function Utilities.UpdateTimelineAssignmentStartTime(timelineAssignment, bossDungeonEncounterID, difficulty)
		local assignment = timelineAssignment.assignment
		if getmetatable(assignment) == CombatLogEventAssignment then
			---@cast assignment CombatLogEventAssignment
			local absoluteSpellCastStartTable = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID, difficulty)
			if absoluteSpellCastStartTable then
				local spellIDSpellCastStartTable = absoluteSpellCastStartTable[assignment.combatLogEventSpellID]
				if spellIDSpellCastStartTable then
					local spellCastStartTableEntry = spellIDSpellCastStartTable[assignment.spellCount]
					if spellCastStartTableEntry then
						local ability =
							FindBossAbility(bossDungeonEncounterID, assignment.combatLogEventSpellID, difficulty)
						local abilityStartTime = GetAdjustedStartTime(
							bossDungeonEncounterID,
							spellCastStartTableEntry,
							difficulty,
							assignment.combatLogEventType,
							ability
						)
						timelineAssignment.startTime = abilityStartTime + assignment.time
						return true
					end
				end
			end
			return false
		elseif getmetatable(assignment) == TimedAssignment then
			---@cast assignment TimedAssignment
			timelineAssignment.startTime = assignment.time
			return true
		else
			return false
		end
	end

	local AddOn = Private.addOn
	local concat = table.concat

	local GetTotalDurations = bossUtilities.GetTotalDurations
	local GetMaxAbsoluteSpellCastTimeTable = bossUtilities.GetMaxAbsoluteSpellCastTimeTable

	local loggedPlanInfo = {} ---@type table<string, LoggedPlanInfo>

	---@param spellID integer
	---@param spellCount integer
	---@param absolute table<integer, table<integer, SpellCastStartTableEntry>>
	---@param maxAbsolute table<integer, table<integer, SpellCastStartTableEntry>>
	---@return SpellCastStartTableEntry|nil spellCastStartTableEntry
	---@return boolean wasMax
	local function FindBossPhaseOrderIndexAndCastStart(spellID, spellCount, absolute, maxAbsolute)
		local castStartTable = absolute[spellID]
		if castStartTable then
			local spellCastStartTableEntry = castStartTable[spellCount]
			if spellCastStartTableEntry then
				return spellCastStartTableEntry, false
			end
		end
		castStartTable = maxAbsolute[spellID]
		if castStartTable then
			local spellCastStartTableEntry = castStartTable[spellCount]
			if spellCastStartTableEntry then
				return spellCastStartTableEntry, true
			end
		end
		return nil, false
	end

	-- Updates multiple timeline assignments' start times.
	---@param timelineAssignments table<integer, TimelineAssignment>
	---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it.
	---@param difficulty DifficultyType
	---@return boolean
	---@return FailTable?
	function Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID, difficulty)
		local absolute = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID, difficulty)
		local maxAbsolute = GetMaxAbsoluteSpellCastTimeTable(bossDungeonEncounterID, difficulty)
		local bossName = GetBossName(bossDungeonEncounterID)
		local failTable = {
			bossName = bossName,
			combatLogEventSpellIDs = {},
			onlyInMaxCastTimeTable = {},
		}

		if not absolute or not maxAbsolute or not bossName then
			return false, failTable
		end

		local failedSpellIDs = failTable.combatLogEventSpellIDs
		local onlyInMax = failTable.onlyInMaxCastTimeTable
		for _, timelineAssignment in ipairs(timelineAssignments) do
			local assignment = timelineAssignment.assignment
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local spellID = assignment.combatLogEventSpellID
				if absolute[spellID] and maxAbsolute[spellID] then
					local spellCount = assignment.spellCount
					local spellCastStartTableEntry, wasMax =
						FindBossPhaseOrderIndexAndCastStart(spellID, spellCount, absolute, maxAbsolute)
					if spellCastStartTableEntry then
						local ability = FindBossAbility(bossDungeonEncounterID, spellID, difficulty) --[[@as BossAbility]]
						local abilityStartTime = GetAdjustedStartTime(
							bossDungeonEncounterID,
							spellCastStartTableEntry,
							difficulty,
							assignment.combatLogEventType,
							ability
						)
						timelineAssignment.startTime = abilityStartTime + assignment.time
						if wasMax then
							onlyInMax[spellID] = onlyInMax[spellID] or {}
							onlyInMax[spellID][spellCount] = true
						end
					else
						failedSpellIDs[spellID] = failedSpellIDs[spellID] or {}
						failedSpellIDs[spellID][spellCount] = true
					end
				else
					failedSpellIDs[spellID] = failedSpellIDs[spellID] or {}
				end
			elseif getmetatable(assignment) == TimedAssignment then
				---@cast assignment TimedAssignment
				timelineAssignment.startTime = assignment.time
			end
		end
		if next(failedSpellIDs) or next(onlyInMax) then
			return false, failTable
		else
			return true
		end
	end

	---@param timelineAssignments table<integer, TimelineAssignment>
	---@param plan Plan
	---@param bossDungeonEncounterID integer
	---@param difficulty DifficultyType
	local function LogOverlappingOrNotVisibleAssignments(timelineAssignments, plan, bossDungeonEncounterID, difficulty)
		local interfaceUpdater = Private.interfaceUpdater ---@type InterfaceUpdater
		if interfaceUpdater then
			local totalCustomDuration, _ = GetTotalDurations(bossDungeonEncounterID, difficulty)

			local startTimesPastTotalDuration = {} ---@type table<integer, number>
			local inStartTimesPastTotalDuration = {} ---@type table<number, boolean>
			local pastDurationCount = 0

			local overlappingAssignments = {} ---@type table<integer, table<integer, TimelineAssignment>>
			local groupedAssignments = {} ---@type table<string, table<integer, TimelineAssignment>>

			for _, timelineAssignment in ipairs(timelineAssignments) do
				local assignee = timelineAssignment.assignment.assignee
				local spellID = timelineAssignment.assignment.spellID
				local key = assignee .. tostring(spellID)
				groupedAssignments[key] = groupedAssignments[key] or {}
				tinsert(groupedAssignments[key], timelineAssignment)
				if timelineAssignment.startTime > totalCustomDuration then
					if not inStartTimesPastTotalDuration[timelineAssignment.startTime] then
						tinsert(startTimesPastTotalDuration, timelineAssignment.startTime)
						inStartTimesPastTotalDuration[timelineAssignment.startTime] = true
					end
					pastDurationCount = pastDurationCount + 1
				end
			end

			for _, timelineAssignmentTable in pairs(groupedAssignments) do
				sort(timelineAssignmentTable, function(a, b)
					return a.startTime < b.startTime
				end)
				for i = 2, #timelineAssignmentTable do
					local previous = timelineAssignmentTable[i - 1]
					local current = timelineAssignmentTable[i]
					local timeDiff = current.startTime - previous.startTime
					if timeDiff < constants.kMinimumTimeBetweenAssignmentsBeforeWarning then
						tinsert(overlappingAssignments, { previous, current })
					end
				end
			end

			local overlapCount = #overlappingAssignments
			local planInfo = loggedPlanInfo[plan.ID]

			local shouldLogPastDurationCount = pastDurationCount > 0
			if planInfo and planInfo.pastDurationCount then
				if shouldLogPastDurationCount and planInfo.pastDurationCount ~= pastDurationCount then
					shouldLogPastDurationCount = true
				elseif planInfo.pastDurationCount > pastDurationCount then
					shouldLogPastDurationCount = true
				else
					shouldLogPastDurationCount = false
				end
			end

			if shouldLogPastDurationCount then
				if pastDurationCount == 0 then
					interfaceUpdater.LogMessage(format("%s: %s.", plan.name, L["All assignments visible"]), 1, 1)
				else
					sort(startTimesPastTotalDuration)
					local stringTimes = ""
					for _, duration in ipairs(startTimesPastTotalDuration) do
						stringTimes = stringTimes .. format("%s:%s", Utilities.FormatTime(duration)) .. ", "
					end
					if stringTimes:len() > 1 then
						stringTimes = stringTimes:sub(1, stringTimes:len() - 2)
					end

					local assignmentsString = pastDurationCount == 1 and L["Assignment"]:lower() or L["assignments"]
					local message = format(
						"%s: %d %s %s %s -> %s. %s: %s.",
						plan.name,
						pastDurationCount,
						assignmentsString,
						L["may be hidden due to starting after the encounter ends. Consider extending the duration in"],
						L["Boss"],
						L["Edit Phase Timings"],
						L["Assignment times"],
						stringTimes
					)
					interfaceUpdater.LogMessage(message, 2, 1)
				end
			end

			local shouldLogOverlapCount = overlapCount > 0
			if planInfo and planInfo.overlapCount then
				if shouldLogOverlapCount and planInfo.overlapCount ~= overlapCount then
					shouldLogOverlapCount = true
				elseif planInfo.overlapCount > overlapCount then
					shouldLogOverlapCount = true
				else
					shouldLogOverlapCount = false
				end
			end

			if shouldLogOverlapCount then
				if overlapCount == 0 then
					interfaceUpdater.LogMessage(format("%s: %s.", plan.name, L["No overlapping assignments"]), 1, 1)
				else
					interfaceUpdater.LogMessage(
						format("%s: %s:", plan.name, L["Assignments might be overlapping"]),
						2,
						1
					)
					for _, timelineAssignmentPair in ipairs(overlappingAssignments) do
						local previous = timelineAssignmentPair[1]
						local current = timelineAssignmentPair[2]
						local assignee =
							Utilities.ConvertAssigneeToLegibleString(previous.assignment.assignee, plan.roster)
						local spell = L["Unknown"]
						if previous.assignment.spellID == constants.kTextAssignmentSpellID then
							spell = L["Text"]
						elseif previous.assignment.spellID > constants.kTextAssignmentSpellID then
							spell = GetSpellName(previous.assignment.spellID)
						end
						local previousStartTime = format("%s:%s", Utilities.FormatTime(previous.startTime))
						local currentStartTime = format("%s:%s", Utilities.FormatTime(current.startTime))
						local message = format(
							"%s: %s, %s: %s, %s: %s, %s.",
							L["Assignee"],
							assignee,
							L["Spell"],
							spell,
							L["Start times"],
							previousStartTime,
							currentStartTime
						)
						interfaceUpdater.LogMessage(message, 2, 2)
					end
				end
			end

			loggedPlanInfo[plan.ID] = loggedPlanInfo[plan.ID] or {}
			loggedPlanInfo[plan.ID].overlapCount = overlapCount
			loggedPlanInfo[plan.ID].pastDurationCount = pastDurationCount
		end
	end

	---@param interfaceUpdater InterfaceUpdater
	---@param count integer
	---@param spellIDs string
	---@param planID string
	---@param planName string
	local function LogFailedSpellIDs(interfaceUpdater, count, spellIDs, planID, planName)
		local shouldLogFailedSpellIDs = count > 0

		local loggedInfo = loggedPlanInfo[planID]
		if loggedInfo and loggedInfo.spellIDsCount then
			if shouldLogFailedSpellIDs and loggedInfo.spellIDsCount ~= count then
				shouldLogFailedSpellIDs = true
			elseif loggedInfo.spellIDsCount > count then
				shouldLogFailedSpellIDs = true
			else
				shouldLogFailedSpellIDs = false
			end
		end

		if shouldLogFailedSpellIDs then
			if count == 0 then
				interfaceUpdater.LogMessage(format("%s: %s.", planName, L["All Boss Spell IDs valid"]), 1, 1)
			else
				local descriptor = count == 1 and L["Spell ID"] or L["Spell IDs"]
				local msg = format("%s: %d %s %s: %s.", planName, count, L["Invalid Boss"], descriptor, spellIDs)
				interfaceUpdater.LogMessage(msg, 2, 1)
			end
			loggedPlanInfo[planID] = loggedPlanInfo[planID] or {}
			loggedPlanInfo[planID].spellIDsCount = count
		end
	end

	---@param interfaceUpdater InterfaceUpdater
	---@param count integer
	---@param spellCounts string
	---@param planID string
	---@param planName string
	local function LogFailedSpellCounts(interfaceUpdater, count, spellCounts, planID, planName)
		local shouldLogFailedSpellCounts = count > 0

		local loggedInfo = loggedPlanInfo[planID]
		if loggedInfo and loggedInfo.spellCountsCount then
			if shouldLogFailedSpellCounts and loggedInfo.spellCountsCount ~= count then
				shouldLogFailedSpellCounts = true
			elseif loggedInfo.spellCountsCount > count then
				shouldLogFailedSpellCounts = true
			else
				shouldLogFailedSpellCounts = false
			end
		end

		if shouldLogFailedSpellCounts then
			if count == 0 then
				interfaceUpdater.LogMessage(format("%s: %s.", planName, L["All Boss Spell Counts valid"]), 1, 1)
			else
				local descriptor = count == 1 and L["Spell Count"] or L["Spell Counts"]
				local msg = format("%s: %d %s %s: %s.", planName, count, L["Invalid Boss"], descriptor, spellCounts)
				interfaceUpdater.LogMessage(msg, 2, 1)
			end
			loggedPlanInfo[planID] = loggedPlanInfo[planID] or {}
			loggedPlanInfo[planID].spellCountsCount = count
		end
	end

	---@param interfaceUpdater InterfaceUpdater
	---@param count integer
	---@param maxSpellCounts string
	---@param planID string
	---@param planName string
	local function LogFailedMaxSpellCounts(interfaceUpdater, count, maxSpellCounts, planID, planName)
		local shouldLogFailedMaxSpellCounts = count > 0

		local loggedInfo = loggedPlanInfo[planID]
		if loggedInfo and loggedInfo.maxSpellCountsCount then
			if shouldLogFailedMaxSpellCounts and loggedInfo.maxSpellCountsCount ~= count then
				shouldLogFailedMaxSpellCounts = true
			elseif loggedInfo.maxSpellCountsCount > count then
				shouldLogFailedMaxSpellCounts = true
			else
				shouldLogFailedMaxSpellCounts = false
			end
		end

		if shouldLogFailedMaxSpellCounts then
			if count == 0 then
				local msg =
					format("%s: %s.", planName, L["All Boss Spell Counts active and assignments drawn correctly"])
				interfaceUpdater.LogMessage(msg, 1, 1)
			else
				local descriptor = count == 1 and L["Spell Count"] or L["Spell Counts"]
				local location = format("%s -> %s", L["Boss"], L["Edit Phase Timings"])
				local consider = format("%s %s", L["Consider extending boss phase durations/counts in"], location)
				consider = consider .. " " .. L["so assignments are drawn correctly"] .. "."
				local msg = format(
					"%s: %d %s %s: %s. %s",
					planName,
					count,
					L["Inactive Boss"],
					descriptor,
					maxSpellCounts,
					consider
				)
				interfaceUpdater.LogMessage(msg, 2, 1)
			end
			loggedPlanInfo[planID] = loggedPlanInfo[planID] or {}
			loggedPlanInfo[planID].maxSpellCountsCount = count
		end
	end

	---@param spellIDsCount integer
	---@param spellIDs string
	---@param spellCountsCount integer
	---@param spellCounts string
	---@param maxSpellCountsCount integer
	---@param maxSpellCounts string
	---@param plan Plan
	local function LogCombatLogEventAssignmentFailures(
		spellIDsCount,
		spellIDs,
		spellCountsCount,
		spellCounts,
		maxSpellCountsCount,
		maxSpellCounts,
		plan
	)
		local interfaceUpdater = Private.interfaceUpdater ---@type InterfaceUpdater
		if interfaceUpdater then
			LogFailedSpellIDs(interfaceUpdater, spellIDsCount, spellIDs, plan.ID, plan.name)
			LogFailedSpellCounts(interfaceUpdater, spellCountsCount, spellCounts, plan.ID, plan.name)
			LogFailedMaxSpellCounts(interfaceUpdater, maxSpellCountsCount, maxSpellCounts, plan.ID, plan.name)
		end
	end

	-- Creates unsorted timeline assignments from assignments and sets the timeline assignments' start times.
	-- The message log is cleared when the plan is changed and preserveMessageLog is nil/false.
	---@param plan Plan Plan containing assignments to create timeline assignments from
	---@param cooldownAndChargeOverrides table<integer, CooldownAndChargeOverride> Cooldown duration and charge overrides for spells.
	---@param onlyShowMe boolean Whether to only show assignments on timeline that are relevant to the player.
	---@param preserveMessageLog boolean|nil Whether or not to preserve the current message log.
	---@return table<integer, TimelineAssignment> -- Unsorted timeline assignments
	function Utilities.CreateTimelineAssignments(plan, cooldownAndChargeOverrides, onlyShowMe, preserveMessageLog)
		---@type table<integer, TimelineAssignment>
		local timelineAssignments = {}

		for _, assignment in pairs(plan.assignments) do
			local timelineAssignment = TimelineAssignment:New(assignment, nil, plan.ID)
			local spellID = assignment.spellID
			local cooldownAndChargeOverride = cooldownAndChargeOverrides[spellID]

			if cooldownAndChargeOverride then
				timelineAssignment.cooldownDuration = cooldownAndChargeOverride.duration
				if cooldownAndChargeOverride.maxCharges then
					timelineAssignment.maxCharges = cooldownAndChargeOverride.maxCharges
				else
					local _, charges = Utilities.GetSpellCooldownAndCharges(spellID)
					timelineAssignment.maxCharges = charges
				end
			else
				timelineAssignment.cooldownDuration, timelineAssignment.maxCharges =
					Utilities.GetSpellCooldownAndCharges(spellID)
			end
			tinsert(timelineAssignments, timelineAssignment)
		end

		if onlyShowMe == true then
			timelineAssignments = Utilities.FilterSelf(timelineAssignments)
		end

		local bossDungeonEncounterID = plan.dungeonEncounterID
		local difficulty = plan.difficulty
		local success, failTable =
			Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID, difficulty)

		local spellIDsString, spellCountsString, maxSpellCountsString = "", "", ""
		local invalidSpellIDsCount, invalidSpellCountsCount, maxSpellCountsCount = 0, 0, 0

		if not success and failTable then
			local failedSpellIDs = failTable.combatLogEventSpellIDs
			local onlyInMaxSpellIDs = failTable.onlyInMaxCastTimeTable
			local spellIDs, spellCounts, maxSpellCounts = {}, {}, {}
			local startCount = #timelineAssignments

			for i = startCount, 1, -1 do
				local assignment = timelineAssignments[i].assignment --[[@as CombatLogEventAssignment]]
				local spellID = assignment.combatLogEventSpellID
				if spellID then
					if failedSpellIDs[spellID] then
						local spellCount = assignment.spellCount
						if failedSpellIDs[spellID][spellCount] then
							spellCounts[spellID] = spellCounts[spellID] or {}
							tinsert(spellCounts[spellID], spellCount)
							invalidSpellCountsCount = invalidSpellCountsCount + 1
						elseif not next(failedSpellIDs[spellID]) then
							tinsert(spellIDs, spellID)
							invalidSpellIDsCount = invalidSpellIDsCount + 1
						end
					elseif onlyInMaxSpellIDs[spellID] then
						local spellCount = assignment.spellCount
						if onlyInMaxSpellIDs[spellID][spellCount] then
							maxSpellCounts[spellID] = maxSpellCounts[spellID] or {}
							tinsert(maxSpellCounts[spellID], spellCount)
							maxSpellCountsCount = maxSpellCountsCount + 1
						end
					end
				end
			end

			if #spellIDs > 0 then
				sort(spellIDs)
				spellIDsString = concat(spellIDs, ", ")
			end

			if next(spellCounts) then
				local spellIDKeys = {}
				for spellID, _ in pairs(spellCounts) do
					tinsert(spellIDKeys, spellID)
				end
				sort(spellIDKeys)
				local countsBySpellID = {}
				for _, spellID in ipairs(spellIDKeys) do
					sort(spellCounts[spellID])
					if #spellCounts[spellID] > 0 then
						tinsert(countsBySpellID, tostring(spellID) .. ": " .. concat(spellCounts[spellID], ", "))
					end
				end
				if #countsBySpellID > 0 then
					spellCountsString = concat(countsBySpellID, ", ")
				end
			end

			if next(maxSpellCounts) then
				local spellIDKeys = {}
				for spellID, _ in pairs(maxSpellCounts) do
					tinsert(spellIDKeys, spellID)
				end
				sort(spellIDKeys)
				local countsBySpellID = {}
				for _, spellID in ipairs(spellIDKeys) do
					sort(maxSpellCounts[spellID])
					if #maxSpellCounts[spellID] > 0 then
						tinsert(countsBySpellID, tostring(spellID) .. ": " .. concat(maxSpellCounts[spellID], ", "))
					end
				end
				if #countsBySpellID > 0 then
					maxSpellCountsString = concat(countsBySpellID, ", ")
				end
			end
		end

		-- Clear log when changing plans
		if not preserveMessageLog and next(loggedPlanInfo) and not loggedPlanInfo[plan.ID] then
			local interfaceUpdater = Private.interfaceUpdater ---@type InterfaceUpdater
			if interfaceUpdater then
				interfaceUpdater.ClearMessageLog()
			end
			loggedPlanInfo = {}
		end

		LogCombatLogEventAssignmentFailures(
			invalidSpellIDsCount,
			spellIDsString,
			invalidSpellCountsCount,
			spellCountsString,
			maxSpellCountsCount,
			maxSpellCountsString,
			plan
		)
		LogOverlappingOrNotVisibleAssignments(timelineAssignments, plan, bossDungeonEncounterID, difficulty)

		return timelineAssignments
	end
end

do
	local kRolePriority = constants.kRolePriority

	-- Creates and sorts a table of TimelineAssignments and sets the start time used for each assignment on the
	-- timeline. Sorts assignments based on the assignmentSortType.
	---@param plan Plan Plan containing assignments to sort.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@param cooldownAndChargeOverrides table<integer, CooldownAndChargeOverride> Cooldown duration and charge overrides for spells.
	---@param onlyShowMe boolean Whether to only show assignments on timeline that are relevant to the player.
	---@param preserveMessageLog boolean|nil Whether or not to preserve the current message log.
	---@return table<integer, TimelineAssignment>
	function Utilities.SortAssignments(
		plan,
		assignmentSortType,
		cooldownAndChargeOverrides,
		onlyShowMe,
		preserveMessageLog
	)
		local timelineAssignments =
			Utilities.CreateTimelineAssignments(plan, cooldownAndChargeOverrides, onlyShowMe, preserveMessageLog)
		sort(timelineAssignments, assignmentUtilities.CompareAssignments(plan.roster, assignmentSortType))
		return timelineAssignments
	end

	-- Creates a AssigneeSpellSet comparator function.
	---@param roster table<string, RosterEntry> Roster associated with the current plan.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@return fun(a:AssigneeSpellSet, b:AssigneeSpellSet):boolean
	local function ComparePlanTemplateEntries(roster, assignmentSortType)
		---@param a AssigneeSpellSet
		---@param b AssigneeSpellSet
		return function(a, b)
			local assigneeA, assigneeB = a.assignee, b.assignee
			if assignmentSortType:match("^Role") then -- Role > Assignee > Spell Name
				local rolePriorityA, rolePriorityB = kRolePriority[""], kRolePriority[""]
				if roster[assigneeA] and roster[assigneeB] then
					rolePriorityA, rolePriorityB =
						kRolePriority[roster[assigneeA].role], kRolePriority[roster[assigneeB].role]
				end
				if rolePriorityA == rolePriorityB then
					if assignmentSortType == "Role > Alphabetical" then
						return assigneeA < assigneeB
					end
				end
				return rolePriorityA < rolePriorityB
			else -- Assignee > Spell Name
				return assigneeA < assigneeB
			end
		end
	end

	---@param assigneeSpellSetsFromAssignments table<integer, AssigneeSpellSet> Spells sets from assignments.
	---@param assigneeSpellSetsFromTemplate table<integer, AssigneeSpellSet> Spells sets from a template.
	---@param roster table<string, RosterEntry> Roster associated with the current plan.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@param onlyShowMe boolean If true, only add templates relevant to self.
	---@return table<integer, AssigneeSpellSet>
	function Utilities.MergeTemplatesSorted(
		assigneeSpellSetsFromAssignments,
		assigneeSpellSetsFromTemplate,
		roster,
		assignmentSortType,
		onlyShowMe
	)
		---@type table<integer, AssigneeSpellSet>
		local combined = {}

		local unitName, unitRealm = UnitFullName("player")
		local unitClass = select(2, UnitClass("player"))
		local specID, _, _, _, role = GetSpecializationInfo(GetSpecialization())
		local classType = Utilities.GetTypeFromSpecID(specID)

		---@type table<string, integer>
		local combinedAssigneeIndices = {}
		for _, assigneeSpellSet in ipairs(assigneeSpellSetsFromAssignments) do
			local assignee = assigneeSpellSet.assignee
			if
				onlyShowMe == false
				or Utilities.IsRelevantToSelf(assignee, unitName, unitRealm, unitClass, specID, role, classType)
			then
				tinsert(combined, DeepCopy(assigneeSpellSet))
				combinedAssigneeIndices[assignee] = #combined
			end
		end

		local newEntries = {}

		for _, templateSpellSets in ipairs(assigneeSpellSetsFromTemplate) do
			local assignee = templateSpellSets.assignee
			local combinedAssigneeIndex = combinedAssigneeIndices[assignee]
			if combinedAssigneeIndex then
				local combinedSpellSetsForAssignee = combined[combinedAssigneeIndex]

				local existing = {}
				for _, spellID in ipairs(combinedSpellSetsForAssignee.spells) do
					existing[spellID] = true
				end

				local missingSpellIDs = {}
				for _, spellID in ipairs(templateSpellSets.spells) do
					if not existing[spellID] then
						tinsert(missingSpellIDs, spellID)
						existing[spellID] = true
					end
				end

				sort(missingSpellIDs, function(a, b)
					if a <= constants.kTextAssignmentSpellID or b <= constants.kTextAssignmentSpellID then
						return a < b
					else
						local nameA, nameB = GetSpellName(a), GetSpellName(b)
						if nameA and nameB then
							return nameA < nameB
						else
							return a < b
						end
					end
				end)

				for i = #missingSpellIDs, 1, -1 do
					tinsert(combinedSpellSetsForAssignee.spells, 1, missingSpellIDs[i])
				end
			else
				if
					onlyShowMe == false
					or Utilities.IsRelevantToSelf(assignee, unitName, unitRealm, unitClass, specID, role, classType)
				then
					tinsert(newEntries, DeepCopy(templateSpellSets))
				end
			end
		end

		if assignmentSortType == "Alphabetical" then -- Assignee > Spell Name > Start Time
			for _, newEntry in pairs(newEntries) do
				tinsert(combined, newEntry)
			end
			sort(combined, ComparePlanTemplateEntries(roster, assignmentSortType))
		elseif assignmentSortType == "First Appearance" then -- Start Time > Assignee > Spell Name
			sort(newEntries, ComparePlanTemplateEntries(roster, assignmentSortType))
			for i = #newEntries, 1, -1 do
				tinsert(combined, 1, newEntries[i])
			end
		elseif assignmentSortType == "Role > Alphabetical" then -- Role > Assignee > Spell Name > Start Time
			for _, newEntry in pairs(newEntries) do
				tinsert(combined, newEntry)
			end
			sort(combined, ComparePlanTemplateEntries(roster, assignmentSortType))
		elseif assignmentSortType == "Role > First Appearance" then -- Role > Start Time > Assignee > Spell Name
			sort(newEntries, ComparePlanTemplateEntries(roster, assignmentSortType))
			for i = #newEntries, 1, -1 do
				tinsert(combined, 1, newEntries[i])
			end
		end

		return combined
	end
end

-- Sets the order field for timeline assignments and creates a sorted table for rows in the assignment timeline.
-- Also returns a table where timeline assignments are grouped by assignee.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@return table<integer, AssigneeSpellSet> orderedAssigneeSpellSets
---@return table<string, table<integer, TimelineAssignment>> groupedByAssignee
function Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments)
	local assigneeIndices = {} ---@type table<integer, string>
	local groupedByAssignee = {} ---@type table<string, table<integer, TimelineAssignment>>

	for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
		local assignee = timelineAssignment.assignment.assignee
		if not groupedByAssignee[assignee] then
			groupedByAssignee[assignee] = {}
			tinsert(assigneeIndices, assignee)
		end
		tinsert(groupedByAssignee[assignee], timelineAssignment)
	end

	local assigneeOrder = {} ---@type table<integer, AssigneeSpellSet>
	for _, assignee in ipairs(assigneeIndices) do
		tinsert(assigneeOrder, { assignee = assignee, spells = {} })
		local visited = {} ---@type table<integer, boolean>
		for _, timelineAssignment in ipairs(groupedByAssignee[assignee]) do
			local spellID = timelineAssignment.assignment.spellID
			if not visited[spellID] then
				visited[spellID] = true
				tinsert(assigneeOrder[#assigneeOrder].spells, spellID)
			end
		end
	end

	return assigneeOrder, groupedByAssignee
end

---@param assignee string
---@return string|nil
function Utilities.IsValidAssignee(assignee)
	if assignee == "{everyone}" then
		return assignee
	else
		local classMatch = assignee:match("class:%s*(%a+)")
		local roleMatch = assignee:match("role:%s*(%a+)")
		local groupMatch = assignee:match("group:%s*(%d)")
		local specMatch = assignee:match("spec:%s*([%a%d]+)")
		local typeMatch = assignee:match("type:%s*(%a+)")
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
			local characterMatch, _ = assignee:gsub("%s*%-.*", ""):match("^(%S+)$")
			if characterMatch then
				return Utilities.UpperCaseFirst(characterMatch)
			end
		end
	end
	return nil
end

---@param assignee string
---@param roster table<string, RosterEntry> Roster for the assignments
---@return string
function Utilities.ConvertAssigneeToLegibleString(assignee, roster)
	local legibleString = assignee
	if assignee == "{everyone}" then
		return L["Everyone"]
	else
		local classMatch = assignee:match("class:%s*(%a+)")
		local roleMatch = assignee:match("role:%s*(%a+)")
		local groupMatch = assignee:match("group:%s*(%d)")
		local specMatch = assignee:match("spec:%s*(%d+)")
		local typeMatch = assignee:match("type:%s*(%a+)")
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
		elseif roster and roster[assignee] then
			if roster[assignee].classColoredName ~= "" then
				legibleString = roster[assignee].classColoredName
			end
		end
	end
	return legibleString
end

do
	local kRegexIconText = constants.kRegexIconText

	do
		---@param a DropdownItemData
		---@param b DropdownItemData
		---@return boolean
		local function SortFunction(a, b)
			local itemValueA = a.itemValue
			local itemValueB = b.itemValue
			if type(itemValueA) == "number" or itemValueA:find("spec:") then
				local spellName = a.text:match(kRegexIconText)
				if spellName then
					itemValueA = spellName
				end
			end
			if type(itemValueB) == "number" or itemValueB:find("spec:") then
				local spellName = b.text:match(kRegexIconText)
				if spellName then
					itemValueB = spellName
				end
			end
			return itemValueA < itemValueB
		end

		-- Sorts a table of possibly nested dropdown item data, removing any inline icons if present before sorting.
		---@param data table<integer, DropdownItemData> Dropdown data to sort
		function Utilities.SortDropdownDataByItemValue(data)
			-- Sort the top-level table
			sort(data, SortFunction)

			-- Recursively sort any nested dropdownItemMenuData tables
			for _, item in pairs(data) do
				if item.dropdownItemMenuData and #item.dropdownItemMenuData > 0 then
					Utilities.SortDropdownDataByItemValue(item.dropdownItemMenuData)
				end
			end
		end
	end

	do
		local kSortOrder = {
			[L["Core"]] = 1,
			[L["Group Utility"]] = 2,
			[L["Personal Defensive"]] = 3,
			[L["External Defensive"]] = 4,
			[L["Other"]] = 5,
		}

		---@param a DropdownItemData
		---@param b DropdownItemData
		---@return boolean
		local function SortFunction(a, b)
			local itemValueA = a.itemValue
			local itemValueB = b.itemValue

			if kSortOrder[itemValueA] then
				itemValueA = kSortOrder[itemValueA]
			elseif type(itemValueA) == "number" or itemValueA:find("spec:") then
				local spellName = a.text:match(kRegexIconText)
				if spellName then
					itemValueA = spellName
				end
			end

			if kSortOrder[itemValueB] then
				itemValueB = kSortOrder[itemValueB]
			elseif type(itemValueB) == "number" or itemValueB:find("spec:") then
				local spellName = b.text:match(kRegexIconText)
				if spellName then
					itemValueB = spellName
				end
			end
			return itemValueA < itemValueB
		end

		-- Sorts a table of possibly nested dropdown item data, removing any inline icons if present before sorting.
		---@param data table<integer, DropdownItemData> Dropdown data to sort
		function Utilities.SortClassCategoryDropdownItemData(data)
			-- Sort the top-level table
			sort(data, SortFunction)

			-- Recursively sort any nested dropdownItemMenuData tables
			for _, item in pairs(data) do
				if item.dropdownItemMenuData and #item.dropdownItemMenuData > 0 then
					Utilities.SortClassCategoryDropdownItemData(item.dropdownItemMenuData)
				end
			end
		end
	end
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
		local unitName, unitRealm = UnitFullName(unit)
		if unitName then
			if unitName == name then
				return unit
			elseif unitRealm then
				local unitFullName = unitName .. "-" .. unitRealm
				if unitFullName == name then
					return unit
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
			local unitName, _ = UnitFullName(unit)
			if classFileName then
				groupData[unitName] = {}
				groupData[unitName].class = classFileName
				groupData[unitName].role = role
				local colorMixin = GetClassColor(classFileName)
				groupData[unitName].classColoredName = colorMixin:WrapTextInColorCode(unitName)
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
			if Utilities.IsValidClassFileName(className) then
				local colorMixin = GetClassColor(className)
				rosterEntry.classColoredName = colorMixin:WrapTextInColorCode(unitName:gsub("%s*%-.*", ""))
			end
		end
	end
end

-- Updates class, class colored name, and role from the group if they do not exist.
---@param rosterEntry RosterEntry Roster entry to update
---@param unitData RosterEntry
local function UpdateRosterEntryFromUnitData(rosterEntry, unitData)
	if rosterEntry.class == "" then
		if Utilities.IsValidClassFileName(unitData.class) then
			rosterEntry.class = Utilities.GetFormattedDataClassName(unitData.class)
		end
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
			local unitName, _ = UnitFullName(unit)
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
	local visited = {}
	for _, assignment in ipairs(assignments) do
		if assignment.assignee and not visited[assignment.assignee] then
			local assignee = assignment.assignee
			if
				not assignee:find("class:")
				and not assignee:find("group:")
				and not assignee:find("role:")
				and not assignee:find("spec:")
				and not assignee:find("type:")
				and not assignee:find("{everyone}")
			then
				if not roster[assignee] then
					roster[assignee] = RosterEntry:New({})
				end
				UpdateRosterEntryClassColoredName(assignee, roster[assignee])
			end
			visited[assignee] = true
		end
	end
	for assigneeName, _ in pairs(roster) do
		if not visited[assigneeName] then
			UpdateRosterEntryClassColoredName(assigneeName, roster[assigneeName])
		end
	end
end

do
	local lineMatchRegex = "([^\r\n]+)"

	-- Splits a string into table using new lines as separators.
	---@param text string The text to use to create the table.
	---@param removeEmptyLines boolean? If true, don't add empty lines.
	---@return table<integer, string>
	function Utilities.SplitStringIntoTable(text, removeEmptyLines)
		local stringTable = {}
		if removeEmptyLines then
			for line in text:gmatch(lineMatchRegex) do
				if line:trim():len() > 0 then
					tinsert(stringTable, line)
				end
			end
		else
			for line in text:gmatch(lineMatchRegex) do
				tinsert(stringTable, line)
			end
		end

		return stringTable
	end
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
	local playerName, _ = UnitFullName("player")
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

---@param assignee string Assignee string as found in an assignment or template.
---@param unitName string Player name.
---@param unitRealm string Player realm.
---@param unitClass string Player class file name.
---@param specID integer Player specialization ID.
---@param role string Player role.
---@param classType "melee"|"ranged" Player class type.
---@return boolean
function Utilities.IsRelevantToSelf(assignee, unitName, unitRealm, unitClass, specID, role, classType)
	if assignee:find("class:") then
		local classMatch = assignee:match("class:%s*(%a+)")
		if classMatch then
			if classMatch:upper() == unitClass then
				return true
			end
		end
	elseif assignee:find("group:") then
		if assignee:find(tostring(GetGroupNumber())) then
			return true
		end
	elseif assignee:find("role:") then
		local roleMatch = assignee:match("role:%s*(%a+)")
		if roleMatch then
			if roleMatch:upper() == role then
				return true
			end
		end
	elseif assignee:find("type:") then
		local typeMatch = assignee:match("type:%s*(%a+)")
		if typeMatch then
			if typeMatch:lower() == classType then
				return true
			end
		end
	elseif assignee:find("spec:") then
		local specMatch = assignee:match("spec:%s*(%d+)")
		if specMatch then
			local foundSpecID = tonumber(specMatch)
			if foundSpecID and foundSpecID == specID then
				return true
			end
		end
	elseif assignee:find("{everyone}") then
		return true
	elseif unitName == assignee or unitName .. "-" .. unitRealm == assignee then
		return true
	end
	return false
end

do
	local IsRelevantToSelf = Utilities.IsRelevantToSelf

	---@param timelineAssignmentsOrAssignments table<integer, TimelineAssignment|Assignment>
	---@return table<integer, TimelineAssignment|Assignment>
	function Utilities.FilterSelf(timelineAssignmentsOrAssignments)
		local filtered = {}
		local unitName, unitRealm = UnitFullName("player")
		local unitClass = select(2, UnitClass("player"))
		local specID, _, _, _, role = GetSpecializationInfo(GetSpecialization())
		local classType = Utilities.GetTypeFromSpecID(specID)
		for _, timelineAssignment in ipairs(timelineAssignmentsOrAssignments) do
			local assignee = timelineAssignment.assignee or timelineAssignment.assignment.assignee
			if IsRelevantToSelf(assignee, unitName, unitRealm, unitClass, specID, role, classType) then
				tinsert(filtered, timelineAssignment)
			end
		end
		return filtered
	end
end

---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param addIcon boolean
---@return string
function Utilities.CreateReminderText(assignment, roster, addIcon)
	local reminderText = ""
	if assignment.text ~= nil and assignment.text ~= "" then
		reminderText = Utilities.ReplaceGenericIconsOrSpells(assignment.text)
		reminderText = reminderText:gsub("||", "|")
		return reminderText
	end

	local spellID = assignment.spellID
	if spellID ~= nil and spellID > kTextAssignmentSpellID then
		local spellName = GetSpellName(spellID)
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

	if assignment.targetName ~= nil and assignment.targetName ~= "" then
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
	end
	return reminderText
end

---@param assignment CombatLogEventAssignment
---@param dungeonEncounterID integer
---@param difficulty DifficultyType
function Utilities.UpdateAssignmentBossPhase(assignment, dungeonEncounterID, difficulty)
	local castTimeTable = GetAbsoluteSpellCastTimeTable(dungeonEncounterID, difficulty)
	local bossPhaseTable = GetOrderedBossPhases(dungeonEncounterID, difficulty)
	if castTimeTable and bossPhaseTable then
		local combatLogEventSpellID = assignment.combatLogEventSpellID
		local spellCount = assignment.spellCount
		if castTimeTable[combatLogEventSpellID] and castTimeTable[combatLogEventSpellID][spellCount] then
			local orderedBossPhaseIndex = castTimeTable[combatLogEventSpellID][spellCount].bossPhaseOrderIndex
			assignment.bossPhaseOrderIndex = orderedBossPhaseIndex
			assignment.phase = bossPhaseTable[orderedBossPhaseIndex]
		end
	end
end

---@param plans table<string, Plan>
---@param newDesignatedExternalPlan Plan
---@return boolean -- True if another plan with the same dungeonEncounterID was the Designated External Plan.
function Utilities.SetDesignatedExternalPlan(plans, newDesignatedExternalPlan)
	local changedPrimaryPlan = false
	for _, currentPlan in pairs(plans) do
		local matching = currentPlan.dungeonEncounterID == newDesignatedExternalPlan.dungeonEncounterID
			and currentPlan.difficulty == newDesignatedExternalPlan.difficulty
		if matching then
			if currentPlan.isPrimaryPlan == true and currentPlan ~= newDesignatedExternalPlan then
				currentPlan.isPrimaryPlan = false
				changedPrimaryPlan = true
			end
		end
	end
	newDesignatedExternalPlan.isPrimaryPlan = true
	return changedPrimaryPlan
end

---@return string
---@return RosterEntry
function Utilities.CreateRosterEntryForSelf()
	local role = select(5, GetSpecializationInfo(GetSpecialization()))
	if role then
		role = "role:" .. role:lower()
	else
		role = ""
	end
	local _, classFileName, _ = UnitClass("player")
	local unitName, _ = UnitFullName("player")
	local colorMixin = GetClassColor(classFileName)
	local classColoredName = colorMixin:WrapTextInColorCode(unitName)
	if classFileName == "DEATHKNIGHT" then
		classFileName = "DeathKnight"
	elseif classFileName == "DEMONHUNTER" then
		classFileName = "DemonHunter"
	else
		classFileName = classFileName:sub(1, 1):upper() .. classFileName:sub(2):lower()
	end
	return unitName,
		RosterEntry:New({
			class = "class:" .. classFileName,
			role = role,
			classColoredName = classColoredName,
		})
end

---@generic T
---@param tbl table<integer, T>
---@param tblValue string
---@param value any
---@return boolean contains
---@return integer? index
function Utilities.ContainsValue(tbl, tblValue, value)
	for k, v in ipairs(tbl) do
		if v[tblValue] == value then
			return true, k
		end
	end
	return false
end

---@param assigneeSpellSets table<integer, AssigneeSpellSet>
function Utilities.SortAssigneeSpellSets(assigneeSpellSets)
	for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
		sort(assigneeSpellSet.spells)
	end
	sort(assigneeSpellSets, function(a, b)
		return a.assignee < b.assignee
	end)
end

---@param plan Plan Plan.
---@param assignmentSortType AssignmentSortType Sort method.
---@param cooldownAndChargeOverrides table<integer, CooldownAndChargeOverride> Cooldown duration and charge overrides for spells.
---@param onlyShowMe boolean Whether to only show assignments on timeline that are relevant to the player.
---@return table<integer, AssigneeSpellSet>
function Utilities.CreateAssigneeSpellSetsFromPlan(plan, assignmentSortType, cooldownAndChargeOverrides, onlyShowMe)
	local sortedTimelineAssignments =
		Utilities.SortAssignments(plan, assignmentSortType, cooldownAndChargeOverrides, onlyShowMe, true)
	local assigneeSpellSets, _ = Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments)
	return assigneeSpellSets
end

---@param templates table<integer, PlanTemplate>
---@param plan Plan
---@param newTemplateName string
---@param assigneeSpellSets table<integer, AssigneeSpellSet>
---@param filteredAssignees table<string, boolean>?
---@return PlanTemplate
function Utilities.CreatePlanTemplate(templates, plan, newTemplateName, assigneeSpellSets, filteredAssignees)
	newTemplateName = Utilities.CreateUniqueTemplateName(templates, newTemplateName)
	if filteredAssignees then
		for assignee, filtered in pairs(filteredAssignees) do
			if filtered then
				for index, assigneeSpellSet in ipairs(assigneeSpellSets) do
					if assigneeSpellSet.assignee == assignee then
						tremove(assigneeSpellSets, index)
						break
					end
				end
			end
		end
	end
	Utilities.SortAssigneeSpellSets(assigneeSpellSets)

	-- Import roster entries
	local roster = plan.roster
	for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
		if roster[assigneeSpellSet.assignee] then
			assigneeSpellSet.assigneeRosterEntry = DeepCopy(roster[assigneeSpellSet.assignee])
		end
	end

	local template = {
		name = newTemplateName,
		assigneeSpellSets = assigneeSpellSets,
	} ---@type PlanTemplate
	tinsert(templates, template)
	return template
end

---@param template PlanTemplate
---@param plan Plan
function Utilities.ApplyPlanTemplate(template, plan)
	local assigneeOrderIndex = {} ---@type table<string, integer>

	for index, assigneeSpellSet in ipairs(plan.assigneeSpellSets) do
		assigneeOrderIndex[assigneeSpellSet.assignee] = index
	end

	local roster = plan.roster
	for _, assigneeSpellSet in ipairs(template.assigneeSpellSets) do
		local assignee = assigneeSpellSet.assignee
		if not roster[assignee] then
			if assignee ~= "{everyone}" and not assignee:find(":") then
				roster[assignee] = RosterEntry:New()
				if assigneeSpellSet.assigneeRosterEntry then
					roster[assignee].class = assigneeSpellSet.assigneeRosterEntry.class
					roster[assignee].role = assigneeSpellSet.assigneeRosterEntry.role
					roster[assignee].classColoredName = assigneeSpellSet.assigneeRosterEntry.classColoredName
				end
			end
		end
		local index = assigneeOrderIndex[assigneeSpellSet.assignee]
		if index then -- Add missing spells for assignee
			local existingAssigneeSpellSet = plan.assigneeSpellSets[index]
			local existing = {}
			for _, spellID in ipairs(existingAssigneeSpellSet.spells) do
				existing[spellID] = true
			end
			for _, spellID in ipairs(assigneeSpellSet.spells) do
				if not existing[spellID] then
					tinsert(existingAssigneeSpellSet.spells, spellID)
					existing[spellID] = true
				end
			end
		else -- Add assignee and spells
			tinsert(plan.assigneeSpellSets, DeepCopy(assigneeSpellSet))
		end
	end
end

---@param plans table<string, Plan>
---@param newPlanName string|nil
---@param encounterID integer
---@param difficulty DifficultyType
---@return Plan
function Utilities.CreatePlan(plans, newPlanName, encounterID, difficulty)
	newPlanName = Utilities.CreateUniquePlanName(plans, newPlanName or L["Default"])
	local plan = Plan:New({}, newPlanName)
	plan.difficulty = difficulty
	plans[newPlanName] = plan
	Utilities.ChangePlanBoss(plans, newPlanName, encounterID, difficulty)
	local unitName, entry = Utilities.CreateRosterEntryForSelf()
	plan.roster[unitName] = entry
	return plan
end

---@param plans table<string, Plan>
---@param planToCopyName string
---@param newPlanName string
---@return Plan
function Utilities.DuplicatePlan(plans, planToCopyName, newPlanName)
	newPlanName = Utilities.CreateUniquePlanName(plans, newPlanName)
	local newPlan = Plan:New({}, newPlanName)
	local newID = newPlan.ID

	local planToCopy = plans[planToCopyName]
	for key, value in pairs(DeepCopy(planToCopy)) do
		newPlan[key] = value
	end

	newPlan.name = newPlanName
	newPlan.ID = newID
	newPlan.isPrimaryPlan = false

	setmetatable(newPlan, getmetatable(planToCopy))
	assignmentUtilities.SetAssignmentMetaTables(newPlan.assignments, newPlan.ID)
	plans[newPlanName] = newPlan
	return newPlan
end

---@param plan Plan
---@param assignment Assignment|CombatLogEventAssignment|TimedAssignment
function Utilities.AddAssignmentToPlan(plan, assignment)
	tinsert(plan.assignments, assignment)
	local assignee, spellID = assignment.assignee, assignment.spellID
	for _, assigneeSpellSet in ipairs(plan.assigneeSpellSets) do
		if assigneeSpellSet.assignee == assignee then
			for index, currentSpellID in ipairs(assigneeSpellSet.spells) do
				if spellID == currentSpellID then
					tremove(assigneeSpellSet.spells, index)
					break
				end
			end
			break
		end
	end
end

---@param plan Plan Plan to remove assignments and template entries from.
---@param assigneeOrUniqueID string|integer Either the assignee or the assignment's uniqueID.
---@param spellID integer? If using an assignee, the spellID to further filter assignments to remove.
---@return integer removedAssignmentCount
---@return integer removedTemplateCount
function Utilities.RemoveAssignmentFromPlan(plan, assigneeOrUniqueID, spellID)
	local removedAssignmentCount, removedTemplateCount = 0, 0
	local assignments = plan.assignments
	local assigneeSpellSets = plan.assigneeSpellSets

	if type(assigneeOrUniqueID) == "string" then
		-- Remove assignments
		local assigneeHasOtherSpellIDs = false
		if spellID then
			for i = #assignments, 1, -1 do
				local currentAssignee, currentSpellID = assignments[i].assignee, assignments[i].spellID
				if currentAssignee == assigneeOrUniqueID then
					if currentSpellID == spellID then
						tremove(assignments, i)
						removedAssignmentCount = removedAssignmentCount + 1
					else
						assigneeHasOtherSpellIDs = true
					end
				end
			end
		else
			for i = #assignments, 1, -1 do
				if assignments[i].assignee == assigneeOrUniqueID then
					tremove(assignments, i)
					removedAssignmentCount = removedAssignmentCount + 1
				end
			end
		end

		-- Remove templates
		for index, assigneeSpellSet in ipairs(assigneeSpellSets) do
			if assigneeSpellSet.assignee == assigneeOrUniqueID then
				local spells = assigneeSpellSet.spells
				if spellID then
					for spellIDIndex, currentSpellID in ipairs(spells) do
						if currentSpellID == spellID then
							tremove(spells, spellIDIndex)
							removedTemplateCount = removedTemplateCount + 1
							break
						end
					end
				else
					removedTemplateCount = removedTemplateCount + #spells
					wipe(spells)
				end

				if not next(spells) then
					tremove(assigneeSpellSets, index)
				end
				break
			end
		end

		-- Remove from collapsed
		if not assigneeHasOtherSpellIDs then
			plan.collapsed[assigneeOrUniqueID] = nil
		end
	elseif type(assigneeOrUniqueID) == "number" then
		local assignmentToRemove = Utilities.FindAssignmentByUniqueID(assignments, assigneeOrUniqueID)
		if assignmentToRemove then -- Remove assignments
			local matchingAssignee, matchingSpellID = assignmentToRemove.assignee, assignmentToRemove.spellID
			local foundMatchingAssigneeAndSpellID = false
			local assigneeHasOtherAssignments = false
			for i = #assignments, 1, -1 do
				local currentAssignment = assignments[i]
				if currentAssignment.uniqueID == assigneeOrUniqueID then
					tremove(assignments, i)
					removedAssignmentCount = removedAssignmentCount + 1
				else
					local currentAssignee, currentSpellID = currentAssignment.assignee, currentAssignment.spellID
					if currentAssignee == matchingAssignee then
						if currentSpellID == matchingSpellID then
							foundMatchingAssigneeAndSpellID = true
						end
						assigneeHasOtherAssignments = true
					end
				end
			end
			if foundMatchingAssigneeAndSpellID == false then -- Remove templates
				for index, assigneeSpellSet in ipairs(assigneeSpellSets) do
					if assigneeSpellSet.assignee == matchingAssignee then
						local spells = assigneeSpellSet.spells

						for spellIDIndex, currentSpellID in ipairs(spells) do
							if currentSpellID == matchingSpellID then
								tremove(spells, spellIDIndex)
								removedTemplateCount = removedTemplateCount + 1
								break
							end
						end

						if not next(spells) then
							tremove(assigneeSpellSets, index)
						end
						break
					end
				end
			end

			if not assigneeHasOtherAssignments then -- Remove from collapsed
				plan.collapsed[matchingAssignee] = nil
			end
		end
	end

	return removedAssignmentCount, removedTemplateCount
end

do
	---@param plans table<string, Plan>
	---@param instanceID integer
	---@param encounterID integer
	---@param planToDeleteName string
	---@return string|nil
	local function SelectNewLastOpenPlan(plans, instanceID, encounterID, planToDeleteName)
		local instanceBossOrder = bossUtilities.GetInstanceBossOrder()
		---@type table<integer, table<integer, table<integer, string>>>
		local planNamesByInstanceAndEncounterID = {}
		planNamesByInstanceAndEncounterID[instanceID] = {}
		planNamesByInstanceAndEncounterID[instanceID][encounterID] = { planToDeleteName }

		for currentPlanName, currentPlan in pairs(plans) do
			if not planNamesByInstanceAndEncounterID[currentPlan.instanceID] then
				planNamesByInstanceAndEncounterID[currentPlan.instanceID] = {}
			end
			local instanceTable = planNamesByInstanceAndEncounterID[currentPlan.instanceID]

			if not instanceTable[currentPlan.dungeonEncounterID] then
				instanceTable[currentPlan.dungeonEncounterID] = {}
			end
			local bossTable = instanceTable[currentPlan.dungeonEncounterID]

			tinsert(bossTable, currentPlanName)
		end

		for _, planNamesByInstanceID in pairs(planNamesByInstanceAndEncounterID) do
			for _, planNamesByEncounterID in pairs(planNamesByInstanceID) do
				sort(planNamesByEncounterID)
			end
		end

		local mapChallengeModeID = bossUtilities.GetBoss(encounterID).mapChallengeModeID

		local deletedEncounterReached = false
		local previousCandidate = nil
		local firstForwardCandidate = nil
		local candidateWithSameInstanceIDBefore = nil
		local candidateWithSameInstanceIDAfter = nil

		for _, sortedDungeonInstanceEntry in ipairs(instanceBossOrder) do
			local currentInstanceID = sortedDungeonInstanceEntry.dungeonInstanceID
			local currentMapChallengeModeID = sortedDungeonInstanceEntry.mapChallengeModeID
			local planNamesByEncounterID = planNamesByInstanceAndEncounterID[currentInstanceID]
			if planNamesByEncounterID then
				for _, sortedDungeonInstanceEntryBossEntry in ipairs(sortedDungeonInstanceEntry.sortedBosses) do
					local currentEncounterID = sortedDungeonInstanceEntryBossEntry.dungeonEncounterID
					local planNames = planNamesByEncounterID[currentEncounterID]
					if planNames then
						if
							currentInstanceID == instanceID
							and currentMapChallengeModeID == mapChallengeModeID
							and currentEncounterID == encounterID
						then
							local deletedIndex = nil
							for i, name in ipairs(planNames) do
								if name == planToDeleteName then
									deletedIndex = i
									break
								end
							end
							if deletedIndex then
								tremove(planNames, deletedIndex)
							end

							-- Neighbor selection
							if #planNames > 0 then
								if deletedIndex and deletedIndex <= #planNames then
									return planNames[deletedIndex] or planNames[#planNames]
								else
									return planNames[1]
								end
							end

							deletedEncounterReached = true
						else
							if currentInstanceID == instanceID and currentMapChallengeModeID == mapChallengeModeID then
								if deletedEncounterReached then
									if not candidateWithSameInstanceIDAfter then
										candidateWithSameInstanceIDAfter = planNames[1]
									end
								else
									candidateWithSameInstanceIDBefore = planNames[#planNames]
								end
							end

							if deletedEncounterReached then
								if not firstForwardCandidate then
									firstForwardCandidate = planNames[1]
								end
							else
								-- Otherwise keep this as last known previous candidate
								previousCandidate = planNames[#planNames]
							end
						end
					end
				end
				if deletedEncounterReached then
					if candidateWithSameInstanceIDAfter then
						return candidateWithSameInstanceIDAfter
					elseif candidateWithSameInstanceIDBefore then
						return candidateWithSameInstanceIDBefore
					elseif firstForwardCandidate then
						return firstForwardCandidate
					elseif previousCandidate then
						return previousCandidate
					end
				end
			end
		end

		-- If no forward candidates found, fallback to the last valid previous
		return previousCandidate
	end

	-- Reassigns a primary plan for the encounterID and difficulty only if none exist.
	---@param plans table<string, Plan>
	---@param encounterID integer
	---@param difficulty DifficultyType
	local function SwapDesignatedExternalPlanIfNeeded(plans, encounterID, difficulty)
		local primaryPlanExists = false
		local candidatePlan = nil

		for _, currentPlan in pairs(plans) do
			local matching = currentPlan.dungeonEncounterID == encounterID and currentPlan.difficulty == difficulty
			if matching then
				if currentPlan.isPrimaryPlan == true then
					primaryPlanExists = true
					break
				end
				if not candidatePlan then
					candidatePlan = currentPlan
				end
			end
		end

		if not primaryPlanExists and candidatePlan then
			candidatePlan.isPrimaryPlan = true
		end
	end

	---@param plans table<string, Plan>
	---@param planName string
	---@param newEncounterID integer New boss dungeon encounter ID
	---@param newDifficulty DifficultyType
	function Utilities.ChangePlanBoss(plans, planName, newEncounterID, newDifficulty)
		if plans[planName] then
			local plan = plans[planName]
			local newBossHasPrimaryPlan = false

			for _, currentPlan in pairs(plans) do
				local matching = currentPlan.dungeonEncounterID == newEncounterID
					and currentPlan.difficulty == newDifficulty
				if matching then
					if currentPlan.isPrimaryPlan == true and currentPlan ~= plan then
						newBossHasPrimaryPlan = true
						break
					end
				end
			end

			local previousEncounterID = plan.dungeonEncounterID
			local previousDifficulty = plan.difficulty

			plan.difficulty = newDifficulty
			plan.dungeonEncounterID = newEncounterID
			plan.instanceID = GetBoss(newEncounterID).instanceID
			plan.isPrimaryPlan = not newBossHasPrimaryPlan
			wipe(plan.customPhaseDurations)
			wipe(plan.customPhaseCounts)

			if
				previousEncounterID > 0
				and previousEncounterID ~= newEncounterID
				and previousDifficulty == newDifficulty
			then
				SwapDesignatedExternalPlanIfNeeded(plans, previousEncounterID, previousDifficulty)
			end
		end
	end

	-- Deletes the plan from the profile. If it was the last open plan, the last open plan will be changed to either
	-- the plan before/after the plan to delete, or a new plan will be created. Handles swapping Designated External
	-- Plans.
	---@param profile DefaultProfile
	---@param planToDeleteName string
	function Utilities.DeletePlan(profile, planToDeleteName)
		if profile.plans[planToDeleteName] then
			local plans = profile.plans

			local instanceID = plans[planToDeleteName].instanceID
			local encounterID = plans[planToDeleteName].dungeonEncounterID
			local difficulty = plans[planToDeleteName].difficulty

			plans[planToDeleteName] = nil

			if profile.lastOpenPlan == planToDeleteName then
				local newPlanName = SelectNewLastOpenPlan(plans, instanceID, encounterID, planToDeleteName)
				if newPlanName then
					profile.lastOpenPlan = newPlanName
				else
					local newPlan = Utilities.CreatePlan(plans, nil, encounterID, difficulty)
					profile.lastOpenPlan = newPlan.name
				end
			end

			SwapDesignatedExternalPlanIfNeeded(plans, encounterID, difficulty)
		end
	end
end

do
	local ShallowCopy = function(tbl)
		local copy = {}
		for k, v in pairs(tbl) do
			copy[k] = v
		end
		return copy
	end

	local PlanDiffType = Private.classes.PlanDiffType

	---@generic T
	---@param a table<integer, T>
	---@param b table<integer, T>
	---@param comparator fun(a: T, b: T): boolean
	---@return table<integer, PlanDiffEntry<T>>
	function Utilities.MyersDiff(a, b, comparator)
		local front = { [1] = { 0, {} } } -- k = 1 represents diagonal 0

		local aCount, bCount = #a, #b
		for d = 0, aCount + bCount do
			for k = -d, d, 2 do
				local goDown
				if k == -d or k ~= d and front[k - 1][1] < front[k + 1][1] then
					goDown = true
				elseif k == d then
					goDown = false
				else
					local left = front[k - 1] and front[k - 1][1] or -math.huge
					local right = front[k + 1] and front[k + 1][1] or -math.huge
					goDown = right > left
				end

				local previousX, x, history
				if goDown then
					previousX = front[k + 1][1]
					history = front[k + 1][2]
					x = previousX
				else
					previousX = front[k - 1][1]
					history = front[k - 1][2]
					x = previousX + 1
				end
				local y = x - k

				history = ShallowCopy(history)

				if 1 <= y and y <= bCount and goDown then
					tinsert(history, { type = PlanDiffType.Insert, index = y, value = b[y], result = true })
				elseif 1 <= x and x <= aCount and not goDown then
					tinsert(history, { type = PlanDiffType.Delete, index = x, value = a[x], result = true })
				end

				while x < aCount and y < bCount and comparator(a[x + 1], b[y + 1]) == true do
					tinsert(history, { type = PlanDiffType.Equal, aIndex = x + 1, bIndex = y + 1, result = false })
					x = x + 1
					y = y + 1
				end

				if x >= aCount and y >= bCount then
					return history
				end

				front[k] = { x, history }
			end
		end

		return {}
	end

	-- Merges delete and inserts entries into change entries of a diff if they their index is equal, accounting for
	-- shifts due to deletes, inserts, and changes.
	---@generic T
	---@param diff table<integer, PlanDiffEntry<T>> Original diff with no Change entries.
	---@return table<integer, PlanDiffEntry<T>> modifiedDiff
	function Utilities.CoalesceChanges(diff)
		local result = {}
		local i = 1
		local shift = 0
		while i <= #diff do
			local entry = diff[i]
			local nextEntry = diff[i + 1]
			local coalesced = false
			if entry.type == PlanDiffType.Delete then
				if nextEntry and nextEntry.type == PlanDiffType.Insert then
					if nextEntry.index == entry.index then
						tinsert(result, {
							type = PlanDiffType.Change,
							index = entry.index,
							oldValue = entry.value,
							newValue = nextEntry.value,
							result = true,
						})
						coalesced = true
					elseif nextEntry.index == entry.index + shift then
						tinsert(result, {
							type = PlanDiffType.Change,
							index = entry.index + shift,
							oldValue = entry.value,
							newValue = nextEntry.value,
							result = true,
						})
						coalesced = true
					end
				end
				shift = shift - 1
			elseif entry.type == PlanDiffType.Insert then
				shift = shift + 1
			end

			if coalesced then -- Cancel out shift and skip next
				shift = shift + 1
				i = i + 2
			else
				tinsert(result, entry)
				i = i + 1
			end
		end
		return result
	end

	---@param a FlatAssigneeSpellSet
	---@param b FlatAssigneeSpellSet
	---@return boolean
	local function SortFlattenedAssigneeSpellSets(a, b)
		if a.assignee == b.assignee then
			if a.spellID <= constants.kTextAssignmentSpellID or b.spellID <= constants.kTextAssignmentSpellID then
				return a.spellID < b.spellID
			else
				local nameA, nameB = GetSpellName(a.spellID), GetSpellName(b.spellID)
				if nameA and nameB then
					return nameA < nameB
				else
					return a.spellID < b.spellID
				end
			end
		end
		return a.assignee < b.assignee
	end

	---@param assigneeSpellSets table<integer, AssigneeSpellSet>
	---@return table<integer, FlatAssigneeSpellSet>
	local function FlattenAssigneeSpellSets(assigneeSpellSets)
		local flattened = {}
		for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
			for _, spellID in ipairs(assigneeSpellSet.spells) do
				tinsert(flattened, { assignee = assigneeSpellSet.assignee, spellID = spellID })
			end
		end
		sort(flattened, SortFlattenedAssigneeSpellSets)
		return flattened
	end

	-- Creates a diff between two plans.
	---@param oldPlan Plan Existing plan.
	---@param newPlan Plan New plan.
	---@return PlanDiff
	function Utilities.DiffPlans(oldPlan, newPlan)
		---@type PlanDiff
		local diff = {
			assignments = Utilities.CoalesceChanges(
				Utilities.MyersDiff(oldPlan.assignments, newPlan.assignments, assignmentUtilities.AssignmentsEqual)
			),
			roster = {},
			content = Utilities.CoalesceChanges(Utilities.MyersDiff(oldPlan.content, newPlan.content, function(a, b)
				return a == b
			end)),
			metaData = {},
			assigneeSpellSets = {},
			empty = true,
		}

		-- Metadata
		if oldPlan.difficulty ~= newPlan.difficulty then
			diff.metaData.difficulty = {}
			diff.metaData.difficulty.oldValue = oldPlan.difficulty
			diff.metaData.difficulty.newValue = newPlan.difficulty
			diff.metaData.difficulty.result = true
			diff.empty = false
		end
		if oldPlan.dungeonEncounterID ~= newPlan.dungeonEncounterID then
			diff.metaData.dungeonEncounterID = {}
			diff.metaData.dungeonEncounterID.oldValue = oldPlan.dungeonEncounterID
			diff.metaData.dungeonEncounterID.newValue = newPlan.dungeonEncounterID
			diff.metaData.dungeonEncounterID.result = true
			diff.empty = false
		end
		if oldPlan.instanceID ~= newPlan.instanceID then
			diff.metaData.instanceID = {}
			diff.metaData.instanceID.oldValue = oldPlan.instanceID
			diff.metaData.instanceID.newValue = newPlan.instanceID
			diff.metaData.instanceID.result = true
			diff.empty = false
		end

		-- Roster
		local oldRoster = oldPlan.roster
		local newRoster = newPlan.roster
		local seen = {}
		for newRosterName, newRosterEntry in pairs(newRoster) do
			local oldRosterEntry = oldRoster[newRosterName]
			if not oldRosterEntry then
				local planRosterDiff = {
					assignee = newRosterName,
					type = PlanDiffType.Insert,
					newValue = DeepCopy(newRosterEntry),
					result = true,
				} ---@type PlanRosterDiff
				tinsert(diff.roster, planRosterDiff)
			else
				if oldRosterEntry.class ~= newRosterEntry.class or oldRosterEntry.role ~= newRosterEntry.role then
					local planRosterDiff = {
						assignee = newRosterName,
						type = PlanDiffType.Change,
						oldValue = DeepCopy(oldRosterEntry),
						newValue = DeepCopy(newRosterEntry),
						result = true,
					} ---@type PlanRosterDiff
					tinsert(diff.roster, planRosterDiff)
				end
				seen[newRosterName] = true
			end
		end
		for oldRosterName, oldRosterEntry in pairs(oldRoster) do
			if not seen[oldRosterName] then
				local planRosterDiff = {
					assignee = oldRosterName,
					type = PlanDiffType.Delete,
					oldValue = DeepCopy(oldRosterEntry),
					result = true,
				} ---@type PlanRosterDiff
				tinsert(diff.roster, planRosterDiff)
			end
		end

		-- Assignee spell sets
		Utilities.SortAssigneeSpellSets(oldPlan.assigneeSpellSets)
		Utilities.SortAssigneeSpellSets(newPlan.assigneeSpellSets)
		local oldAssigneeSpellSets = FlattenAssigneeSpellSets(oldPlan.assigneeSpellSets)
		local newAssigneeSpellSets = FlattenAssigneeSpellSets(newPlan.assigneeSpellSets)
		diff.assigneeSpellSets =
			Utilities.CoalesceChanges(Utilities.MyersDiff(oldAssigneeSpellSets, newAssigneeSpellSets, function(a, b)
				return a.assignee == b.assignee and a.spellID == b.spellID
			end))

		---@generic T
		---@param tbl table<integer, PlanDiffEntry<T>>
		local function CheckIfNotEmpty(tbl)
			if diff.empty == true then
				for _, entry in ipairs(tbl) do
					if entry.result == true then
						diff.empty = false
						return
					end
				end
			end
		end

		CheckIfNotEmpty(diff.assignments)
		CheckIfNotEmpty(diff.assigneeSpellSets)
		CheckIfNotEmpty(diff.roster)
		CheckIfNotEmpty(diff.content)

		if diff.empty == true then
			if diff.metaData.difficulty then
				diff.empty = false
			elseif diff.metaData.dungeonEncounterID then
				diff.empty = false
			elseif diff.metaData.instanceID then
				diff.empty = false
			end
		end

		return diff
	end

	-- Applies the diff with proper index handling.
	---@generic T
	---@param existingTable table<integer, T> Existing table to apply the diff to.
	---@param tableDiff table<integer, PlanDiffEntry<T>> Diff between existing and new table.
	---@param changeFunc fun(newValue:T, ...:any):T Function to set new values from the new table.
	---@param ... any Args for changeFunc
	---@return integer addedCount
	---@return integer removedCount
	---@return integer changedCount
	function Utilities.ApplyDiff(existingTable, tableDiff, changeFunc, ...)
		local addedCount, removedCount, changedCount = 0, 0, 0

		-- Apply deletes first (reverse order)
		for i = #tableDiff, 1, -1 do
			local diff = tableDiff[i]
			if diff.result and diff.type == PlanDiffType.Delete then
				tremove(existingTable, diff.index)
				removedCount = removedCount + 1
			end
		end

		-- Apply inserts and changes in forward order
		for i = 1, #tableDiff do
			local diff = tableDiff[i]
			if diff.result then
				if diff.type == PlanDiffType.Insert then
					tinsert(existingTable, diff.index, diff.value)
					addedCount = addedCount + 1
				elseif diff.type == PlanDiffType.Change then
					existingTable[diff.index] = changeFunc(diff.newValue, ...)
					changedCount = changedCount + 1
				end
			end
		end

		return addedCount, removedCount, changedCount
	end

	---@param existingPlan Plan Existing plan to apply the diff to.
	---@param tableDiff table<integer, PlanDiffEntry<FlatAssigneeSpellSet>> Diff between existing and new table.
	---@return integer addedCount
	---@return integer removedCount
	---@return integer changedCount
	function Utilities.ApplyDiffToAssigneeSpellSets(existingPlan, tableDiff)
		local addedCount, removedCount, changedCount = 0, 0, 0

		local existingAssigneeSpellSets = existingPlan.assigneeSpellSets
		local flattenedAssigneeSpellSets = FlattenAssigneeSpellSets(existingAssigneeSpellSets)

		-- Apply deletes first (reverse order)
		for i = #tableDiff, 1, -1 do
			local diff = tableDiff[i]
			if diff.result and diff.type == PlanDiffType.Delete then
				tremove(flattenedAssigneeSpellSets, diff.index)
				removedCount = removedCount + 1
			end
		end

		-- Apply inserts and changes in forward order
		for i = 1, #tableDiff do
			local diff = tableDiff[i]
			if diff.result then
				if diff.type == PlanDiffType.Insert then
					tinsert(flattenedAssigneeSpellSets, diff.index, diff.value)
					addedCount = addedCount + 1
				elseif diff.type == PlanDiffType.Change then
					flattenedAssigneeSpellSets[diff.index].assignee = diff.newValue.assignee
					flattenedAssigneeSpellSets[diff.index].spellID = diff.newValue.spellID
					changedCount = changedCount + 1
				end
			end
		end

		local newAssigneeSpellSets = {} ---@type table<integer, AssigneeSpellSet>
		local indexMap = {}
		for _, flatAssigneeSpellSet in ipairs(flattenedAssigneeSpellSets) do
			local assignee = flatAssigneeSpellSet.assignee
			if not indexMap[assignee] then
				tinsert(newAssigneeSpellSets, { assignee = assignee, spells = {} })
				indexMap[assignee] = #newAssigneeSpellSets
			end
			local index = indexMap[assignee]
			tinsert(newAssigneeSpellSets[index].spells, flatAssigneeSpellSet.spellID)
		end
		Utilities.SortAssigneeSpellSets(newAssigneeSpellSets)
		existingPlan.assigneeSpellSets = newAssigneeSpellSets

		return addedCount, removedCount, changedCount
	end

	local DuplicateAssignment = Private.DuplicateAssignment

	-- Merges an existing plan using a plan diff.
	---@param plans table<string, Plan> All plans.
	---@param existingPlan Plan Existing plan to apply diff to.
	---@param planDiff PlanDiff Diff between existing and new plan.
	---@return table<integer, string> messages
	function Utilities.MergePlan(plans, existingPlan, planDiff)
		local messages = {}
		local existingAssignments = existingPlan.assignments
		local existingPlanID = existingPlan.ID
		local added, removed, changed =
			Utilities.ApplyDiff(existingAssignments, planDiff.assignments, DuplicateAssignment, existingPlanID)

		if added > 0 or removed > 0 or changed > 0 then
			tinsert(
				messages,
				format(
					"%s %d, %s %d, %s %s %d %s.",
					L["Added"],
					added,
					L["Removed"]:lower(),
					removed,
					L["and"],
					L["Changed"]:lower(),
					changed,
					L["assignments"]
				)
			)
			added, removed, changed = 0, 0, 0
		end

		local existingRoster = existingPlan.roster
		for i = #planDiff.roster, 1, -1 do
			local diff = planDiff.roster[i]
			if diff.result == true then
				if diff.type == PlanDiffType.Delete then
					existingRoster[diff.assignee] = nil
					removed = removed + 1
				elseif diff.type == PlanDiffType.Insert then
					local rosterEntry = RosterEntry:New()
					rosterEntry.class = diff.newValue.class
					rosterEntry.classColoredName = diff.newValue.classColoredName
					rosterEntry.role = diff.newValue.role
					existingRoster[diff.assignee] = rosterEntry
					added = added + 1
				elseif diff.type == PlanDiffType.Change then
					existingRoster[diff.assignee].class = diff.newValue.class
					existingRoster[diff.assignee].classColoredName = diff.newValue.classColoredName
					existingRoster[diff.assignee].role = diff.newValue.role
					changed = changed + 1
				end
			end
		end

		if added > 0 or removed > 0 or changed > 0 then
			tinsert(
				messages,
				format(
					"%s %d, %s %d, %s %s %d %s.",
					L["Added"],
					added,
					L["Removed"]:lower(),
					removed,
					L["and"],
					L["Changed"]:lower(),
					changed,
					L["roster members"]
				)
			)
			added, removed, changed = 0, 0, 0
		end

		added, removed, changed = Utilities.ApplyDiffToAssigneeSpellSets(existingPlan, planDiff.assigneeSpellSets)
		if added > 0 or removed > 0 or changed > 0 then
			tinsert(
				messages,
				format(
					"%s %d, %s %d, %s %s %d %s.",
					L["Added"],
					added,
					L["Removed"]:lower(),
					removed,
					L["and"],
					L["Changed"]:lower(),
					changed,
					L["Templates"]:lower()
				)
			)
			added, removed, changed = 0, 0, 0
		end

		local existingContent = existingPlan.content
		added, removed, changed = Utilities.ApplyDiff(existingContent, planDiff.content, function(v)
			return v
		end)

		if added > 0 or removed > 0 or changed > 0 then
			tinsert(
				messages,
				format(
					"%s %d, %s %d, %s %s %d %s.",
					L["Added"],
					added,
					L["Removed"]:lower(),
					removed,
					L["and"],
					L["Changed"]:lower(),
					changed,
					L["lines of External Text"]
				)
			)
			added, removed, changed = 0, 0, 0
		end

		local changedMetaData = false
		local metaDataMessages = {}
		if planDiff.metaData.instanceID and planDiff.metaData.instanceID.result == true then
			existingPlan.instanceID = planDiff.metaData.instanceID.newValue
			tinsert(metaDataMessages, L["Instance"]:lower())
			changedMetaData = true
		end
		if planDiff.metaData.dungeonEncounterID and planDiff.metaData.dungeonEncounterID.result == true then
			existingPlan.dungeonEncounterID = planDiff.metaData.dungeonEncounterID.newValue
			tinsert(metaDataMessages, L["Boss"]:lower())
			changedMetaData = true
		end
		if planDiff.metaData.difficulty and planDiff.metaData.difficulty.result == true then
			existingPlan.difficulty = planDiff.metaData.difficulty.newValue
			tinsert(metaDataMessages, L["Difficulty"]:lower())
			changedMetaData = true
		end

		if changedMetaData then
			Utilities.ChangePlanBoss(plans, existingPlan.name, existingPlan.dungeonEncounterID, existingPlan.difficulty)
			if #metaDataMessages == 1 then
				tinsert(messages, format("%s %s %s.", L["Changed"]:lower(), L["The"]:lower(), metaDataMessages[1]))
			elseif #metaDataMessages == 2 then
				tinsert(
					messages,
					format(
						"%s %s %s %s %s.",
						L["Changed"]:lower(),
						L["The"]:lower(),
						metaDataMessages[1],
						L["and"],
						metaDataMessages[2]
					)
				)
			elseif #metaDataMessages == 3 then
				tinsert(
					messages,
					format(
						"%s %s %s, %s, %s %s.",
						L["Changed"]:lower(),
						L["The"]:lower(),
						metaDataMessages[1],
						metaDataMessages[2],
						L["and"],
						metaDataMessages[3]
					)
				)
			end
		end

		return messages
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

	local formattedMinutes = format("%02d", minutes)
	local formattedSeconds = format("%02d", seconds)
	local secondsDecimalMatch = tostring(seconds):match("^%d+%.(%d+)")
	if secondsDecimalMatch then
		formattedSeconds = formattedSeconds .. "." .. secondsDecimalMatch
	else
		formattedSeconds = formattedSeconds .. ".0"
	end

	return formattedMinutes, formattedSeconds
end

---@param minutes string|number Minutes string or number
---@param seconds string|number Seconds string or number
---@param minTime? number Optional minimum bound
---@param maxTime? number Optional maximum bound
---@return number? time
function Utilities.ParseTime(minutes, seconds, minTime, maxTime)
	local timeMinutes, timeSeconds = tonumber(minutes), tonumber(seconds)
	if timeMinutes and timeSeconds then
		local wholeMinutes = floor(timeMinutes)
		local timeValue = 0.0
		if timeMinutes % 1 ~= 0 then
			local secondsFromFractionalMinutes = (timeMinutes - wholeMinutes) * 60.0
			timeValue = Utilities.Round(wholeMinutes * 60.0 + secondsFromFractionalMinutes, 1)
		else
			if timeSeconds >= 60.0 then
				timeValue = Utilities.Round(timeSeconds, 1)
			else
				timeValue = Utilities.Round(wholeMinutes * 60.0 + timeSeconds, 1)
			end
		end
		if minTime and maxTime then
			timeValue = Clamp(timeValue, minTime, maxTime)
		elseif minTime then
			timeValue = Clamp(timeValue, minTime, timeValue)
		elseif maxTime then
			timeValue = Clamp(timeValue, timeValue, maxTime)
		end
		return timeValue
	else
		return nil
	end
end

---@param strTable table<integer, string>
---@return table<integer, table<integer, string>>
function Utilities.SplitStringTableByWhiteSpace(strTable)
	local returnTable = {}
	for index, line in ipairs(strTable) do
		returnTable[index] = {}
		for word in line:gmatch("%S+") do
			tinsert(returnTable[index], word)
		end
	end
	return returnTable
end

do
	local tooltipOwner = CreateFrame("Frame", "EPCooldownScannerTooltipOwnerFrame")
	tooltipOwner:Hide()

	local tooltip = CreateFrame("GameTooltip", "EPCooldownScannerTooltip", nil, "GameTooltipTemplate")
	tooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
	tooltip:Hide()

	---@param spellID integer
	---@return number?
	function Utilities.GetCooldownDurationFromTooltip(spellID)
		tooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
		tooltip:SetSpellByID(spellID)
		tooltip:RefreshData()

		for i = 2, tooltip:NumLines() do
			local text = _G["EPCooldownScannerTooltipTextRight" .. i]:GetText()
			if text then
				local secondMatch = text:match("(%d+%.?%d*)%s+sec")
				if secondMatch then
					return tonumber(secondMatch)
				end
				local minuteMatch = text:match("(%d+%.?%d*)%s+min")
				if minuteMatch then
					return tonumber(minuteMatch) * 60.0
				end
			end
		end

		return nil
	end
end

do
	local GetCooldownDurationFromTooltip = Utilities.GetCooldownDurationFromTooltip
	---@type table<integer, {duration: number, maxCharges: integer}>
	local cooldowns = {
		[113942] = {
			duration = 120.0,
			maxCharges = 1,
		},
	}

	---@param spellID integer
	---@return number
	---@return integer
	local function GetSpellCooldownAndCharges(spellID)
		local duration, maxCharges = 0.0, 1
		if spellID > kTextAssignmentSpellID then
			local chargeInfo = GetSpellCharges(spellID)
			if chargeInfo then
				duration = chargeInfo.cooldownDuration
				maxCharges = chargeInfo.maxCharges
			else
				local durationFromTooltip = GetCooldownDurationFromTooltip(spellID)
				if durationFromTooltip then
					duration = durationFromTooltip
				else
					local cooldownMS, _ = GetSpellBaseCooldown(spellID)
					if cooldownMS then
						duration = cooldownMS / 1000
					end
				end
			end
		end
		return duration, maxCharges
	end

	---@param spellID integer
	---@return number
	---@return integer
	function Utilities.GetSpellCooldownAndCharges(spellID)
		if not cooldowns[spellID] then
			local duration, maxCharges = GetSpellCooldownAndCharges(spellID)
			cooldowns[spellID] = {
				duration = duration,
				maxCharges = maxCharges,
			}
		end
		return cooldowns[spellID].duration, cooldowns[spellID].maxCharges
	end

	function Utilities.RefreshCachedCooldowns()
		for spellID, cooldownInfo in pairs(cooldowns) do
			local duration, maxCharges = GetSpellCooldownAndCharges(spellID)
			cooldownInfo.duration = duration
			cooldownInfo.maxCharges = maxCharges
		end
	end
end

do
	local AceGUI = LibStub("AceGUI-3.0")
	local kReminderContainerFrameLevel = constants.frameLevels.kReminderContainerFrameLevel
	local UIParent = UIParent

	---@generic T
	---@param containerType `T` | "EPContainer"|"EPAnchorContainer"
	---@param preferences GenericReminderPreferences|IconPreferences
	---@param spacing number|nil
	---@return T
	local function Create(containerType, preferences, spacing)
		local container = AceGUI:Create(containerType) --[[@as EPContainer|EPAnchorContainer]]
		container:SetLayout("EPReminderLayout")
		container.frame:SetParent(UIParent)
		container.frame:SetFrameStrata("MEDIUM")
		container.frame:SetFrameLevel(kReminderContainerFrameLevel)
		container:SetSpacing(spacing or 0, spacing or 0)
		if preferences.orientation then
			container:SetOrientation(preferences.orientation)
		else
			container:SetOrientation("vertical")
		end
		container:SetSortAscending(preferences.soonestExpirationOnBottom)
		local regionName = Utilities.IsValidRegionName(preferences.relativeTo) and preferences.relativeTo or "UIParent"
		local region = _G[regionName] or UIParent
		local point, relativePoint = preferences.point, preferences.relativePoint
		local x, y = preferences.x, preferences.y
		container.frame:SetPoint(point, region, relativePoint, x, y)
		return container
	end

	-- Creates a container for adding progress bars or messages to.
	---@param preferences GenericReminderPreferences|IconPreferences
	---@param spacing number|nil
	---@return EPContainer
	function Utilities.CreateReminderContainer(preferences, spacing)
		return Create("EPContainer", preferences, spacing)
	end

	-- Creates a container for adding progress bars or messages to.
	---@param preferences GenericReminderPreferences|IconPreferences
	---@param spacing number|nil
	---@return EPAnchorContainer
	function Utilities.CreateReminderAnchorContainer(preferences, spacing)
		return Create("EPAnchorContainer", preferences, spacing)
	end
end

do
	local kRegexIconText = constants.kRegexIconText
	local GetInstanceBossOrder = bossUtilities.GetInstanceBossOrder

	-- Creates a function that can sort dropdown item data for plans.
	---@param dropdownItemData DropdownItemData
	---@return fun(a: DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}, b: DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}):boolean
	function Utilities.CreateDropdownItemDataPlanSorter(dropdownItemData)
		local dungeonInstanceID
		if type(dropdownItemData.itemValue) == "table" then
			dungeonInstanceID = dropdownItemData.itemValue.dungeonInstanceID
		else
			dungeonInstanceID = dropdownItemData.itemValue
		end

		local instanceBossOrder = GetInstanceBossOrder(dungeonInstanceID)

		---@param a DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}
		---@param b DropdownItemData|{dungeonEncounterID:integer, mapChallengeModeID?:integer}
		---@return boolean
		return function(a, b)
			local aOrder, bOrder = nil, nil
			local firstEntry, secondEntry = instanceBossOrder[1], instanceBossOrder[2]

			if a.mapChallengeModeID then
				if firstEntry.mapChallengeModeID == a.mapChallengeModeID then
					aOrder = firstEntry.bosses[a.dungeonEncounterID].index
				elseif secondEntry and secondEntry.mapChallengeModeID == a.mapChallengeModeID then
					aOrder = secondEntry.bosses[a.dungeonEncounterID].index
				end
			else
				aOrder = firstEntry.bosses[a.dungeonEncounterID].index
			end
			if b.mapChallengeModeID then
				if firstEntry.mapChallengeModeID == b.mapChallengeModeID then
					aOrder = firstEntry.bosses[b.dungeonEncounterID].index
				elseif secondEntry and secondEntry.mapChallengeModeID == b.mapChallengeModeID then
					aOrder = secondEntry.bosses[b.dungeonEncounterID].index
				end
			else
				bOrder = firstEntry.bosses[b.dungeonEncounterID].index
			end
			if aOrder and bOrder then
				if aOrder ~= bOrder then
					return aOrder < bOrder
				end
			end

			return a.text < b.text
		end
	end

	-- Creates a function that can sort dropdown items for plans.
	---@param boss Boss
	---@return fun(a: EPItemBase, b: EPItemBase):boolean
	function Utilities.CreateDropdownItemPlanSorter(boss)
		local instanceBossOrder = GetInstanceBossOrder(boss.instanceID)
		local firstEntry = instanceBossOrder[1]
		local plans = Private.addOn.db.profile.plans

		return function(a, b)
			---@cast a EPItemBase
			---@cast b EPItemBase
			local aOrder, bOrder
			if instanceBossOrder then
				local aPlan, bPlan = plans[a:GetUserDataTable().value], plans[b:GetUserDataTable().value]
				if aPlan and bPlan then
					aOrder = firstEntry.bosses[aPlan.dungeonEncounterID].index
					bOrder = firstEntry.bosses[bPlan.dungeonEncounterID].index
				end
			end
			if aOrder ~= bOrder then
				return aOrder < bOrder
			end
			return a:GetText():match(kRegexIconText) < b:GetText():match(kRegexIconText)
		end
	end
end
