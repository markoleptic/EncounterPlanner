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

local floor = math.floor
local format = string.format
local GetClassColor = C_ClassColor.GetClassColor
local getmetatable, setmetatable = getmetatable, setmetatable
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpellBaseCooldown = GetSpellBaseCooldown
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local ipairs = ipairs
local IsInRaid = IsInRaid
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

do
	local GetClassInfo = GetClassInfo
	local GetSpecializationInfoByID = GetSpecializationInfoByID
	local rawget = rawget
	local rawset = rawset
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
		specIDToIconAndName[specID] = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", icon, name)
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
---@param minValue number
---@param maxValue number
---@return number
function Utilities.Clamp(value, minValue, maxValue)
	return min(maxValue, max(minValue, value))
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

---@param assignments table<integer, Assignment>
---@param ID integer
---@return Assignment|TimedAssignment|CombatLogEventAssignment|nil
function Utilities.FindAssignmentByUniqueID(assignments, ID)
	for _, assignment in pairs(assignments) do
		if assignment.uniqueID == ID then
			return assignment
		end
	end
end

do
	local spellDropdownItems = nil
	local racialDropdownItems = nil
	local trinketDropdownItems = nil

	---@return DropdownItemData
	function Utilities.GetOrCreateSpellDropdownItems()
		if not spellDropdownItems then
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
					if name then
						local iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", spell["icon"], name)
						local spellID = spell["commonSpellID"] or spell["spellID"]
						tinsert(
							classDropdownData.dropdownItemMenuData[spellTypeIndexMap[spell["type"]]].dropdownItemMenuData,
							{
								itemValue = spellID,
								text = iconText,
							}
						)
					--@debug@
					else
						print(format("%s: %s spell not found.", AddOnName, spell["name"], spell["spellID"]))
						--@end-debug@
					end
				end
				tinsert(dropdownItems, classDropdownData)
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			spellDropdownItems = { itemValue = "Class", text = L["Class"], dropdownItemMenuData = dropdownItems }
		end
		return spellDropdownItems
	end

	---@return DropdownItemData
	local function GetOrCreateRacialDropdownItems()
		if not racialDropdownItems then
			local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
			for _, racialInfo in pairs(Private.spellDB.other["RACIAL"]) do
				local name = GetSpellName(racialInfo["spellID"])
				local iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", racialInfo["icon"], name)
				tinsert(dropdownItems, {
					itemValue = racialInfo["spellID"],
					text = iconText,
				})
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			racialDropdownItems = { itemValue = "Racial", text = L["Racial"], dropdownItemMenuData = dropdownItems }
		end
		return racialDropdownItems
	end

	---@return DropdownItemData
	local function GetOrCreateTrinketDropdownItems()
		if not trinketDropdownItems then
			local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
			for _, trinketInfo in pairs(Private.spellDB.other["TRINKET"]) do
				local name = GetSpellName(trinketInfo["spellID"])
				local iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", trinketInfo["icon"], name)
				tinsert(dropdownItems, {
					itemValue = trinketInfo["spellID"],
					text = iconText,
				})
			end
			Utilities.SortDropdownDataByItemValue(dropdownItems)
			trinketDropdownItems = { itemValue = "Trinket", text = L["Trinket"], dropdownItemMenuData = dropdownItems }
		end
		return trinketDropdownItems
	end

	---@return DropdownItemData
	function Utilities.GetOrCreateSpellAssignmentDropdownItems()
		return {
			Utilities.GetOrCreateSpellDropdownItems(),
			GetOrCreateRacialDropdownItems(),
			GetOrCreateTrinketDropdownItems(),
		}
	end
end

do
	local classDropdownData = nil

	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateClassDropdownItemData()
		if not classDropdownData then
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
				local classData = {
					itemValue = "class:" .. actualClassName:gsub("%s", ""),
					text = Utilities.GetLocalizedPrettyClassName(className),
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
	local wipe = wipe

	local specDropdownItems = nil
	local addedClassAndSpecDropdownItems = false
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
	local bossDropdownItems = nil

	-- Creates dropdown item data for instances and bosses
	---@return table<integer, DropdownItemData>
	function Utilities.GetOrCreateBossDropdownItems()
		if not bossDropdownItems then
			bossDropdownItems = {}
			local customDungeonInstanceGroups = Private.customDungeonInstanceGroups
			local customInstancesDropdownData = {}
			for _, dungeonInstance in pairs(Private.dungeonInstances) do
				if dungeonInstance.customGroup and customDungeonInstanceGroups[dungeonInstance.customGroup] then
					if not customInstancesDropdownData[dungeonInstance.customGroup] then
						local instanceIDToUseForIcon =
							customDungeonInstanceGroups[dungeonInstance.customGroup].instanceIDToUseForIcon
						local instanceName = customDungeonInstanceGroups[dungeonInstance.customGroup].instanceName
						local instanceToUseForIcon = Private.dungeonInstances[instanceIDToUseForIcon]
						local instanceIconText = format("|T%s:16|t %s", instanceToUseForIcon.icon, instanceName)
						local instanceDropdownData =
							{ itemValue = instanceName, text = instanceIconText, dropdownItemMenuData = {} }
						customInstancesDropdownData[dungeonInstance.customGroup] = instanceDropdownData
					end
					local instanceIconText = format("|T%s:16|t %s", dungeonInstance.icon, dungeonInstance.name)
					local instanceDropdownData =
						{ itemValue = dungeonInstance.instanceID, text = instanceIconText, dropdownItemMenuData = {} }
					for _, boss in ipairs(dungeonInstance.bosses) do
						local iconText = format("|T%s:16|t %s", boss.icon, boss.name)
						tinsert(
							instanceDropdownData.dropdownItemMenuData,
							{ itemValue = boss.dungeonEncounterID, text = iconText }
						)
					end
					tinsert(
						customInstancesDropdownData[dungeonInstance.customGroup].dropdownItemMenuData,
						instanceDropdownData
					)
				else
					local instanceIconText = format("|T%s:16|t %s", dungeonInstance.icon, dungeonInstance.name)
					local instanceDropdownData =
						{ itemValue = dungeonInstance.instanceID, text = instanceIconText, dropdownItemMenuData = {} }
					for _, boss in ipairs(dungeonInstance.bosses) do
						local iconText = format("|T%s:16|t %s", boss.icon, boss.name)
						tinsert(
							instanceDropdownData.dropdownItemMenuData,
							{ itemValue = boss.dungeonEncounterID, text = iconText }
						)
					end
					tinsert(bossDropdownItems, instanceDropdownData)
				end
			end
			for _, customDungeonInstanceGroup in pairs(customInstancesDropdownData) do
				tinsert(bossDropdownItems, customDungeonInstanceGroup)
			end
		end
		return bossDropdownItems
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
function Utilities.CreateAssignmentTypeWithRosterDropdownItems(roster, assigneeDropdownItems)
	local assignmentTypes = Utilities.GetOrCreateAssignmentTypeDropdownItems()

	local individualIndex = nil
	for index, assignmentType in ipairs(assignmentTypes) do
		if assignmentType.itemValue == "Individual" then
			individualIndex = index
			break
		end
	end
	if individualIndex then
		if assigneeDropdownItems then
			assignmentTypes[individualIndex].dropdownItemMenuData = assigneeDropdownItems
		elseif roster then
			assignmentTypes[individualIndex].dropdownItemMenuData = Utilities.CreateAssigneeDropdownItems(roster)
		end
		Utilities.SortDropdownDataByItemValue(assignmentTypes[individualIndex].dropdownItemMenuData)
	end
	return assignmentTypes
end

do
	local unknownIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]]
	local deathIcon = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]]

	---@param boss Boss
	---@param abilityID integer
	---@return DropdownItemData
	function Utilities.CreateAbilityDropdownItemData(boss, abilityID)
		local placeholderName, bossDeathName = nil, nil
		if Private:HasPlaceholderBossSpellID(abilityID) then
			placeholderName = Private:GetPlaceholderBossName(abilityID)
		end
		if boss.hasBossDeath and boss.abilities[abilityID].bossNpcID then
			local bossNpcID = boss.abilities[abilityID].bossNpcID
			bossDeathName = boss.bossNames[bossNpcID] .. " " .. L["Death"]
		end
		local iconText
		if placeholderName then
			iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", unknownIcon, placeholderName)
		elseif bossDeathName then
			iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", deathIcon, bossDeathName)
		else
			local iconID = GetSpellTexture(abilityID)
			local spellName = GetSpellName(abilityID)
			if iconID and spellName then
				iconText = format("|T%d:16:16:0:0:64:64:5:59:5:59|t %s", iconID, spellName)
			else
				iconText = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", unknownIcon, L["Unknown"])
			end
		end
		return { itemValue = abilityID, text = iconText }
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

do
	local AddOn = Private.addOn
	local concat = table.concat
	local next = next

	local GetTotalDurations = bossUtilities.GetTotalDurations
	local GetMaxAbsoluteSpellCastTimeTable = bossUtilities.GetMaxAbsoluteSpellCastTimeTable

	local loggedOverlappingOrNotVisiblePlans = {} ---@type table <string, {overlapCount: integer, pastDurationCount: integer}>

	---@class FailedInfo
	---@field bossName string|nil
	---@field combatLogEventSpellIDs table<integer, table<integer, integer>>

	---@param spellID integer
	---@param spellCount integer
	---@param absolute table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param maxAbsolute table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@return number|nil
	local function FindCastStart(spellID, spellCount, absolute, maxAbsolute)
		local castStartTable = absolute[spellID]
		if castStartTable then
			local spellCastInfoTable = castStartTable[spellCount]
			if spellCastInfoTable then
				return spellCastInfoTable.castStart
			end
		end
		castStartTable = maxAbsolute[spellID]
		if castStartTable then
			local spellCastInfoTable = castStartTable[spellCount]
			if spellCastInfoTable then
				return spellCastInfoTable.castStart
			end
		end
	end

	-- Updates multiple timeline assignments' start times.
	---@param timelineAssignments table<integer, TimelineAssignment>
	---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it.
	---@return boolean
	---@return {bossName: string|nil, combatLogEventSpellIDs: table<integer, table<integer, integer>>}?
	function Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID)
		local absolute = GetAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
		local maxAbsolute = GetMaxAbsoluteSpellCastTimeTable(bossDungeonEncounterID)
		local bossName = GetBossName(bossDungeonEncounterID)
		local failedTable = {
			bossName = bossName,
			combatLogEventSpellIDs = {},
		}

		if not absolute or not maxAbsolute or not bossName then
			return false, failedTable
		end

		local failedSpellIDs = failedTable.combatLogEventSpellIDs
		for _, timelineAssignment in ipairs(timelineAssignments) do
			if getmetatable(timelineAssignment.assignment) == CombatLogEventAssignment then
				local assignment = timelineAssignment.assignment --[[@as CombatLogEventAssignment]]
				local spellID = assignment.combatLogEventSpellID
				if absolute[spellID] and maxAbsolute[spellID] then
					local spellCount = assignment.spellCount
					local castStart = FindCastStart(spellID, spellCount, absolute, maxAbsolute)
					if castStart then
						local startTime = castStart + assignment.time
						local ability = FindBossAbility(bossDungeonEncounterID, spellID) --[[@as BossAbility]]
						local combatLogEventType = assignment.combatLogEventType
						if combatLogEventType == "SAR" then
							startTime = startTime + ability.duration + ability.castTime
						elseif combatLogEventType == "SCC" or combatLogEventType == "SAA" then
							startTime = startTime + ability.castTime
						end
						timelineAssignment.startTime = startTime
					else
						failedSpellIDs[spellID] = failedSpellIDs[spellID] or {}
						failedSpellIDs[spellID][spellCount] = true
					end
				else
					failedSpellIDs[spellID] = failedSpellIDs[spellID] or {}
				end
			elseif getmetatable(timelineAssignment.assignment) == TimedAssignment then
				timelineAssignment.startTime = timelineAssignment
					.assignment--[[@as TimedAssignment]]
					.time
			end
		end
		if next(failedSpellIDs) then
			return false, failedTable
		else
			return true
		end
	end

	---@param timelineAssignments table<integer, TimelineAssignment>
	---@param plan Plan
	---@param bossDungeonEncounterID integer
	local function LogOverlappingOrNotVisibleAssignments(timelineAssignments, plan, bossDungeonEncounterID)
		local interfaceUpdater = Private.interfaceUpdater ---@type InterfaceUpdater
		if interfaceUpdater then
			local totalCustomDuration, _ = GetTotalDurations(bossDungeonEncounterID)

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
			local counts = loggedOverlappingOrNotVisiblePlans[plan.ID]

			local shouldLogPastDurationCount = pastDurationCount > 0
			if counts then
				if shouldLogPastDurationCount and counts.pastDurationCount ~= pastDurationCount then
					shouldLogPastDurationCount = true
				elseif counts.pastDurationCount > pastDurationCount then
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

					local assignmentsString = pastDurationCount == 1 and L["assignment"] or L["assignments"]
					local message = format(
						"%s: %d %s %s %s -> %s. %s: %s.",
						plan.name,
						pastDurationCount,
						assignmentsString,
						L["may be hidden due to starting after the encounter ends. Consider extending the duration in"],
						L["Boss"],
						L["Phase Timing Editor"],
						L["Assignment times"],
						stringTimes
					)
					interfaceUpdater.LogMessage(message, 2, 1)
				end
			end

			local shouldLogOverlapCount = overlapCount > 0
			if counts then
				if shouldLogOverlapCount and counts.overlapCount ~= overlapCount then
					shouldLogOverlapCount = true
				elseif counts.overlapCount > overlapCount then
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

			loggedOverlappingOrNotVisiblePlans[plan.ID] =
				{ overlapCount = overlapCount, pastDurationCount = pastDurationCount }
		end
	end

	local loggedPlanFailures = {} ---@type table<string, {spellIDs: string, spellCounts: string}>}>

	---@param spellIDsCount integer
	---@param spellIDs string
	---@param spellCountsCount integer
	---@param spellCounts string
	---@param plan Plan
	local function LogCombatLogEventAssignmentFailures(spellIDsCount, spellIDs, spellCountsCount, spellCounts, plan)
		local interfaceUpdater = Private.interfaceUpdater ---@type InterfaceUpdater
		if interfaceUpdater then
			local loggedPlanData = loggedPlanFailures[plan.ID]
			local shouldLogFailedSpellIDs = spellIDsCount > 0

			if loggedPlanData then
				if shouldLogFailedSpellIDs and loggedPlanData.spellIDs ~= spellIDs then
					shouldLogFailedSpellIDs = true
				else
					shouldLogFailedSpellIDs = false
				end
			end

			if shouldLogFailedSpellIDs then
				local descriptor = spellIDsCount == 1 and L["Spell ID"] or L["Spell IDs"]
				local msg =
					format("%s: %d %s %s: %s.", plan.name, spellIDsCount, L["Invalid Boss"], descriptor, spellIDs)
				interfaceUpdater.LogMessage(msg, 2, 1)
			end

			local shouldLogFailedSpellCounts = spellCountsCount > 0
			if loggedPlanData then
				if shouldLogFailedSpellCounts and loggedPlanData.spellCounts ~= spellCounts then
					shouldLogFailedSpellCounts = true
				else
					shouldLogFailedSpellCounts = false
				end
			end

			if shouldLogFailedSpellCounts then
				local descriptor = spellCountsCount == 1 and L["Spell Count"] or L["Spell Counts"]
				local msg =
					format("%s: %d %s %s: %s.", plan.name, spellCountsCount, L["Invalid Boss"], descriptor, spellCounts)
				interfaceUpdater.LogMessage(msg, 2, 1)
			end

			loggedPlanFailures[plan.ID] = { spellIDs = spellIDs, spellCounts = spellCounts }
		end
	end

	-- Creates unsorted timeline assignments from assignments and sets the timeline assignments' start times.
	---@param plan Plan Plan containing assignments to create timeline assignments from
	---@param bossDungeonEncounterID integer The boss to obtain cast times from if the assignment requires it
	---@return table<integer, TimelineAssignment> -- Unsorted timeline assignments
	function Utilities.CreateTimelineAssignments(plan, bossDungeonEncounterID)
		local timelineAssignments = {}
		if AddOn.db then
			local cooldownOverrides = AddOn.db.profile.cooldownOverrides
			for _, assignment in pairs(plan.assignments) do
				local spellID = assignment.spellID
				local overrideDuration = cooldownOverrides[spellID]
				if overrideDuration then
					assignment.cooldownDuration = overrideDuration
				else
					assignment.cooldownDuration = Utilities.GetSpellCooldown(spellID)
				end
				tinsert(timelineAssignments, TimelineAssignment:New(assignment))
			end
		else
			for _, assignment in pairs(plan.assignments) do
				local spellID = assignment.spellID
				assignment.cooldownDuration = Utilities.GetSpellCooldown(spellID)
				tinsert(timelineAssignments, TimelineAssignment:New(assignment))
			end
		end

		local success, failTable =
			Utilities.UpdateTimelineAssignmentsStartTime(timelineAssignments, bossDungeonEncounterID)

		local spellIDsString, spellCountsString = "", ""
		local invalidSpellIDsCount, invalidSpellCountsCount = 0, 0

		if not success and failTable then
			local failedSpellIDs = failTable.combatLogEventSpellIDs
			local spellIDs, spellCounts = {}, {}
			local startCount = #timelineAssignments

			for i = startCount, 1, -1 do
				local assignment = timelineAssignments[i].assignment --[[@as CombatLogEventAssignment]]
				local spellID = assignment.combatLogEventSpellID
				if spellID and failedSpellIDs[spellID] then
					local spellCount = assignment.spellCount
					if failedSpellIDs[spellID][spellCount] then
						spellCounts[spellID] = spellCounts[spellID] or {}
						tinsert(spellCounts[spellID], spellCount)
						invalidSpellCountsCount = invalidSpellCountsCount + 1
					elseif not next(failedSpellIDs[spellID]) then
						tinsert(spellIDs, spellID)
						invalidSpellIDsCount = invalidSpellIDsCount + 1
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
						tinsert(countsBySpellID, tostring(spellID) .. ": " .. concat(spellCounts[spellID], ","))
					end
				end
				if #countsBySpellID > 0 then
					spellCountsString = concat(countsBySpellID, ", ")
				end
			end
		end

		LogCombatLogEventAssignmentFailures(
			invalidSpellIDsCount,
			spellIDsString,
			invalidSpellCountsCount,
			spellCountsString,
			plan
		)
		LogOverlappingOrNotVisibleAssignments(timelineAssignments, plan, bossDungeonEncounterID)

		return timelineAssignments
	end
end

-- Sorts the assignees based on the order of the timeline assignments, taking spellID into account.
---@param sortedTimelineAssignments table<integer, TimelineAssignment> Sorted timeline assignments
---@param collapsed table<string, boolean>
---@return table<integer, {assignee:string, spellID:integer|nil}>
function Utilities.SortAssigneesWithSpellID(sortedTimelineAssignments, collapsed)
	local assigneeIndices = {}
	local groupedByAssignee = {}
	for _, timelineAssignment in ipairs(sortedTimelineAssignments) do
		local assignee = timelineAssignment.assignment.assignee
		if not groupedByAssignee[assignee] then
			groupedByAssignee[assignee] = {}
			tinsert(assigneeIndices, assignee)
		end
		tinsert(groupedByAssignee[assignee], timelineAssignment)
	end

	local order = 0
	local assigneeMap = {}
	local assigneeOrder = {}

	for _, assignee in ipairs(assigneeIndices) do
		for _, timelineAssignment in ipairs(groupedByAssignee[assignee]) do
			local spellID = timelineAssignment.assignment.spellID
			if not assigneeMap[assignee] then
				assigneeMap[assignee] = {
					order = order,
					spellIDs = {},
				}
				tinsert(assigneeOrder, { assignee = assignee, spellID = nil })
				order = order + 1
			end
			if not assigneeMap[assignee].spellIDs[spellID] then
				if not collapsed[assignee] then
					order = order + 1
				end
				assigneeMap[assignee].spellIDs[spellID] = order
				tinsert(assigneeOrder, { assignee = assignee, spellID = spellID })
			end
			timelineAssignment.order = assigneeMap[assignee].spellIDs[spellID]
		end
	end

	return assigneeOrder
end

do
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

	-- Creates a Timeline Assignment comparator function.
	---@param roster table<string, RosterEntry> Roster associated with the assignments.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@return fun(a:TimelineAssignment, b:TimelineAssignment):boolean
	local function CompareAssignments(roster, assignmentSortType)
		---@param a TimelineAssignment
		---@param b TimelineAssignment
		return function(a, b)
			local assigneeA, assigneeB = a.assignment.assignee, b.assignment.assignee
			local spellIDA, spellIDB = a.assignment.spellID, b.assignment.spellID
			if assignmentSortType == "Alphabetical" then
				if assigneeA == assigneeB then
					return spellIDA < spellIDB
				end
				return assigneeA < assigneeB
			elseif assignmentSortType == "First Appearance" then
				if a.startTime == b.startTime then
					if assigneeA == assigneeB then
						return spellIDA < spellIDB
					end
					return assigneeA < assigneeB
				end
				return a.startTime < b.startTime
			elseif assignmentSortType:match("^Role") then
				local roleA, roleB = roster[assigneeA], roster[assigneeB]
				local rolePriorityA, rolePriorityB =
					RolePriority(roleA and roleA.role), RolePriority(roleB and roleB.role)
				if rolePriorityA == rolePriorityB then
					if assignmentSortType == "Role > Alphabetical" then
						if assigneeA == assigneeB then
							if spellIDA == spellIDB then
								return a.startTime < b.startTime
							end
							return spellIDA < spellIDB
						end
						return assigneeA < assigneeB
					elseif assignmentSortType == "Role > First Appearance" then
						if a.startTime == b.startTime then
							if assigneeA == assigneeB then
								return spellIDA < spellIDB
							end
							return assigneeA < assigneeB
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
	---@param plan Plan Plan containing assignments to sort.
	---@param assignmentSortType AssignmentSortType Sort method.
	---@param bossDungeonEncounterID integer Used to get boss timers to set the proper timeline assignment start time for combat log assignments.
	---@return table<integer, TimelineAssignment>
	function Utilities.SortAssignments(plan, assignmentSortType, bossDungeonEncounterID)
		local timelineAssignments = Utilities.CreateTimelineAssignments(plan, bossDungeonEncounterID)
		sort(timelineAssignments, CompareAssignments(plan.roster, assignmentSortType))
		return timelineAssignments
	end
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
		local assignee = assignment.assignee
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
			local spellID = currentAssigneeAssignment.spellID
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
				return characterMatch:sub(1, 1):upper() .. characterMatch:sub(2):lower()
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

-- Creates a sorted table used to populate the assignment list.
---@param sortedAssigneesAndSpells table<integer, {assignee:string, spellID:number|nil}> Sorted assignment list
---@param roster table<string, RosterEntry> Roster for the assignments
---@return table<integer, {assignee:string, text:string, spells:table<integer, integer>}>
function Utilities.CreateAssignmentListTable(sortedAssigneesAndSpells, roster)
	local visited = {}
	local map = {}
	for _, nameAndSpell in ipairs(sortedAssigneesAndSpells) do
		local assignee = nameAndSpell.assignee
		local abilityEntryText = Utilities.ConvertAssigneeToLegibleString(assignee, roster)
		if not visited[abilityEntryText] then
			tinsert(map, {
				assignee = assignee,
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
			if Private.spellDB.classes[className] then
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
				if roster[assignee].role == "" then
					if determinedRoles[assignee] then
						roster[assignee].role = determinedRoles[assignee]
					end
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

---@param timelineAssignmentsOrAssignments table<integer, TimelineAssignment>|table<integer, Assignment>
---@return table<integer, TimelineAssignment|Assignment>
function Utilities.FilterSelf(timelineAssignmentsOrAssignments)
	local filtered = {}
	local unitName, unitRealm = UnitFullName("player")
	local unitClass = select(2, UnitClass("player"))
	local specID, _, _, _, role = GetSpecializationInfo(GetSpecialization())
	local classType = Utilities.GetTypeFromSpecID(specID)
	for _, timelineAssignment in ipairs(timelineAssignmentsOrAssignments) do
		local assignee = timelineAssignment.assignee or timelineAssignment.assignment.assignee
		if assignee:find("class:") then
			local classMatch = assignee:match("class:%s*(%a+)")
			if classMatch then
				if classMatch:upper() == unitClass then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif assignee:find("group:") then
			if assignee:find(tostring(GetGroupNumber())) then
				tinsert(filtered, timelineAssignment)
			end
		elseif assignee:find("role:") then
			local roleMatch = assignee:match("role:%s*(%a+)")
			if roleMatch then
				if roleMatch:upper() == role then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif assignee:find("type:") then
			local typeMatch = assignee:match("type:%s*(%a+)")
			if typeMatch then
				if typeMatch:lower() == classType then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif assignee:find("spec:") then
			local specMatch = assignee:match("spec:%s*(%d+)")
			if specMatch then
				local foundSpecID = tonumber(specMatch)
				if foundSpecID and foundSpecID == specID then
					tinsert(filtered, timelineAssignment)
				end
			end
		elseif assignee:find("{everyone}") then
			tinsert(filtered, timelineAssignment)
		elseif unitName == assignee or unitName .. "-" .. unitRealm == assignee then
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

---@param assignments table<integer, Assignment>
function Utilities.SetAssignmentMetaTables(assignments)
	for _, assignment in pairs(assignments) do
		assignment = Assignment:New(assignment)
		if
			---@diagnostic disable-next-line: undefined-field
			assignment.combatLogEventType
			---@diagnostic disable-next-line: undefined-field
			and assignment.combatLogEventSpellID
		then
			assignment = CombatLogEventAssignment:New(assignment)
			---@diagnostic disable-next-line: undefined-field
		else
			assignment = TimedAssignment:New(assignment)
		end
	end
end

---@param assignment CombatLogEventAssignment
---@param dungeonEncounterID integer
function Utilities.UpdateAssignmentBossPhase(assignment, dungeonEncounterID)
	local castTimeTable = GetAbsoluteSpellCastTimeTable(dungeonEncounterID)
	local bossPhaseTable = GetOrderedBossPhases(dungeonEncounterID)
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
	for _, plan in pairs(plans) do
		if plan.dungeonEncounterID == newDesignatedExternalPlan.dungeonEncounterID then
			if plan.isPrimaryPlan and plan ~= newDesignatedExternalPlan then
				plan.isPrimaryPlan = false
				changedPrimaryPlan = true
			end
		end
	end
	newDesignatedExternalPlan.isPrimaryPlan = true
	return changedPrimaryPlan
end

---@param plans table<string, Plan>
---@param newPlanName string|nil
---@param encounterID integer
---@return Plan
function Utilities.CreatePlan(plans, newPlanName, encounterID)
	newPlanName = Utilities.CreateUniquePlanName(plans, newPlanName or L["Default"])
	plans[newPlanName] = Plan:New({}, newPlanName)
	Utilities.ChangePlanBoss(plans, newPlanName, encounterID)
	return plans[newPlanName]
end

---@param plans table<string, Plan>
---@param planToCopyName Plan
---@param newPlanName string
---@return Plan
function Utilities.DuplicatePlan(plans, planToCopyName, newPlanName)
	newPlanName = Utilities.CreateUniquePlanName(plans, newPlanName)
	local newPlan = Private.classes.Plan:New({}, newPlanName)
	local newID = newPlan.ID

	local planToCopy = plans[planToCopyName]
	for key, value in pairs(Private.DeepCopy(planToCopy)) do
		newPlan[key] = value
	end

	newPlan.name = newPlanName
	newPlan.ID = newID
	newPlan.isPrimaryPlan = false

	setmetatable(newPlan, getmetatable(planToCopy))
	Utilities.SetAssignmentMetaTables(newPlan.assignments)
	plans[newPlanName] = newPlan
	return newPlan
end

do
	-- Reassigns a primary plan for the encounterID only if none exist.
	---@param plans table<string, Plan>
	---@param encounterID integer
	local function SwapDesignatedExternalPlanIfNeeded(plans, encounterID)
		local primaryPlanExists = false
		local candidatePlan = nil

		for _, plan in pairs(plans) do
			if plan.isPrimaryPlan and plan.dungeonEncounterID == encounterID then
				primaryPlanExists = true
				break
			end
			if plan.dungeonEncounterID == encounterID and not candidatePlan then
				candidatePlan = plan
			end
		end

		if not primaryPlanExists and candidatePlan then
			candidatePlan.isPrimaryPlan = true
		end
	end

	---@param plans table<string, Plan>
	---@param planName string
	---@param newEncounterID integer New boss dungeon encounter ID
	function Utilities.ChangePlanBoss(plans, planName, newEncounterID)
		if plans[planName] then
			local plan = plans[planName]
			local newBossHasPrimaryPlan = false

			for _, currentPlan in pairs(plans) do
				if currentPlan.dungeonEncounterID == newEncounterID then
					if currentPlan.isPrimaryPlan and currentPlan ~= plan then
						newBossHasPrimaryPlan = true
						break
					end
				end
			end

			local previousEncounterID = plan.dungeonEncounterID
			local boss = GetBoss(newEncounterID)
			if boss then
				plan.dungeonEncounterID = boss.dungeonEncounterID
				plan.instanceID = boss.instanceID
				wipe(plan.customPhaseDurations)
				wipe(plan.customPhaseCounts)
			end

			plan.isPrimaryPlan = not newBossHasPrimaryPlan

			if previousEncounterID > 0 and previousEncounterID ~= newEncounterID then
				SwapDesignatedExternalPlanIfNeeded(plans, previousEncounterID)
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
			local previousPlanName, nextPlanName

			local temp
			for currentPlanName, _ in pairs(plans) do
				if currentPlanName == planToDeleteName then
					previousPlanName = temp
				elseif temp == planToDeleteName then
					nextPlanName = currentPlanName
					break
				end
				temp = currentPlanName
			end

			local encounterID = plans[planToDeleteName].dungeonEncounterID

			plans[planToDeleteName] = nil

			if profile.lastOpenPlan == planToDeleteName then
				if previousPlanName or nextPlanName then
					profile.lastOpenPlan = previousPlanName or nextPlanName
				else
					local newPlan = Utilities.CreatePlan(profile.plans, nil, encounterID)
					profile.lastOpenPlan = newPlan.name
				end
			end

			SwapDesignatedExternalPlanIfNeeded(plans, encounterID)
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

do
	local cooldowns = {}

	---@param spellID integer
	---@return number
	function Utilities.GetSpellCooldown(spellID)
		if not cooldowns[spellID] then
			local duration = 0.0
			if spellID > kTextAssignmentSpellID then
				local chargeInfo = GetSpellCharges(spellID)
				if chargeInfo then
					duration = chargeInfo.cooldownDuration
				else
					local cooldownMS, _ = GetSpellBaseCooldown(spellID)
					if cooldownMS then
						duration = cooldownMS / 1000
					end
				end
				if duration <= 1 then
					local spellDBDuration = Private.spellDB.FindCooldownDuration(spellID)
					if spellDBDuration then
						duration = spellDBDuration
					end
				end
			end
			cooldowns[spellID] = duration
		end
		return cooldowns[spellID]
	end
end

do
	local ConvertCombatLogEventTimeToAbsoluteTime = bossUtilities.ConvertCombatLogEventTimeToAbsoluteTime
	local FindNearestCombatLogEvent = bossUtilities.FindNearestCombatLogEvent
	local FindNearestSpellCount = bossUtilities.FindNearestSpellCount
	local GetValidCombatLogEventTypes = bossUtilities.GetValidCombatLogEventTypes
	local IsValidCombatLogEventType = bossUtilities.IsValidCombatLogEventType
	local IsValidSpellCount = bossUtilities.IsValidSpellCount

	---@param assignment CombatLogEventAssignment
	---@param dungeonEncounterID integer
	---@param spellID integer
	local function ConvertToValidCombatLogEventType(assignment, dungeonEncounterID, spellID)
		local validTypes = GetValidCombatLogEventTypes(dungeonEncounterID, spellID)
		local time, eventType = assignment.time, assignment.combatLogEventType
		local previousSpellID, spellCount = assignment.combatLogEventSpellID, assignment.spellCount
		local newSpellCount, _ =
			FindNearestSpellCount(time, dungeonEncounterID, eventType, previousSpellID, spellCount, spellID, true)
		if newSpellCount then
			if #validTypes > 0 then
				assignment.combatLogEventType = validTypes[1]
			end
			assignment.combatLogEventSpellID = spellID
			assignment.spellCount = newSpellCount
		end
	end

	---@param assignment CombatLogEventAssignment
	---@param dungeonEncounterID integer
	---@param newSpellID integer
	function Utilities.ChangeAssignmentCombatLogEventSpellID(assignment, dungeonEncounterID, newSpellID)
		local eventType = assignment.combatLogEventType
		local valid, validEventType = IsValidCombatLogEventType(dungeonEncounterID, newSpellID, eventType)
		if valid or (not valid and validEventType) then
			if validEventType then
				assignment.combatLogEventType = validEventType
			end
			local currentSpellID, currentSpellCount = assignment.combatLogEventSpellID, assignment.spellCount
			if IsValidSpellCount(dungeonEncounterID, newSpellID, currentSpellCount) then
				assignment.combatLogEventSpellID = newSpellID
				assignment.spellCount = currentSpellCount
			else
				local newSpellCount = FindNearestSpellCount(
					assignment.time,
					dungeonEncounterID,
					eventType,
					currentSpellID,
					currentSpellCount,
					newSpellID,
					true
				)
				if newSpellCount then
					assignment.combatLogEventSpellID = newSpellID
					assignment.spellCount = newSpellCount
				end
			end
		else
			ConvertToValidCombatLogEventType(assignment, dungeonEncounterID, newSpellID)
		end
		Utilities.UpdateAssignmentBossPhase(assignment --[[@as CombatLogEventAssignment]], dungeonEncounterID)
	end

	local validCombatLogEventTypes = { ["SCS"] = true, ["SCC"] = true, ["SAA"] = true, ["SAR"] = true, ["UD"] = true }

	---@param assignment CombatLogEventAssignment|TimedAssignment
	---@param dungeonEncounterID integer
	---@param newType "Fixed Time"|CombatLogEventType
	function Utilities.ChangeAssignmentType(assignment, dungeonEncounterID, newType)
		if validCombatLogEventTypes[newType] then
			local newEventType = newType --[[@as CombatLogEventType]]
			if getmetatable(assignment) ~= CombatLogEventAssignment then
				local combatLogEventSpellID, spellCount, minTime =
					FindNearestCombatLogEvent(assignment.time, dungeonEncounterID, newEventType, true)
				assignment = CombatLogEventAssignment:New(assignment, true)
				assignment.combatLogEventType = newEventType
				if combatLogEventSpellID and spellCount and minTime then
					assignment.combatLogEventSpellID = combatLogEventSpellID
					assignment.spellCount = spellCount
					assignment.time = Utilities.Round(minTime, 1)
				end
			else
				local currentSpellID = assignment.combatLogEventSpellID
				if IsValidCombatLogEventType(dungeonEncounterID, currentSpellID, newEventType) then
					assignment.combatLogEventType = newEventType
				else
					local currentSpellCount, currentEventType = assignment.spellCount, assignment.combatLogEventType
					local absoluteTime = ConvertCombatLogEventTimeToAbsoluteTime(
						assignment.time,
						dungeonEncounterID,
						currentSpellID,
						currentSpellCount,
						currentEventType
					)
					if absoluteTime then
						local newCombatLogEventSpellID, newSpellCount =
							FindNearestCombatLogEvent(absoluteTime, dungeonEncounterID, newEventType, true)
						if newCombatLogEventSpellID and newSpellCount then
							assignment.combatLogEventSpellID = newCombatLogEventSpellID
							assignment.combatLogEventType = newEventType
							assignment.spellCount = newSpellCount
						end
					end
				end
			end
			Utilities.UpdateAssignmentBossPhase(assignment --[[@as CombatLogEventAssignment]], dungeonEncounterID)
		elseif newType == "Fixed Time" then
			if getmetatable(assignment) ~= TimedAssignment then
				local convertedTime = nil
				if getmetatable(assignment) == CombatLogEventAssignment then
					convertedTime = ConvertCombatLogEventTimeToAbsoluteTime(
						assignment.time,
						dungeonEncounterID,
						assignment.combatLogEventSpellID,
						assignment.spellCount,
						assignment.combatLogEventType
					)
				end
				assignment = TimedAssignment:New(assignment, true)
				if convertedTime then
					assignment.time = Utilities.Round(convertedTime, 1)
				end
			end
		end
	end
end

do
	local FindNearestPreferredCombatLogEventAbility = bossUtilities.FindNearestPreferredCombatLogEventAbility
	local FindNearestCombatLogEvent = bossUtilities.FindNearestCombatLogEvent

	---@param encounterID integer
	---@param time number Time from the start of the boss encounter
	---@param assignment CombatLogEventAssignment
	---@param phaseIndex integer
	---@param preferred table<integer, { combatLogEventSpellID: integer, combatLogEventType: CombatLogEventType }|nil>
	---@return boolean
	local function HandlePreferredCombatLogEventAbilities(encounterID, time, assignment, phaseIndex, preferred)
		if preferred[phaseIndex] then
			local eventType = preferred[phaseIndex].combatLogEventType
			local spellID = preferred[phaseIndex].combatLogEventSpellID
			local spellCount, newTime = FindNearestPreferredCombatLogEventAbility(time, encounterID, spellID, eventType)
			if spellCount and newTime then
				assignment.time = Utilities.Round(newTime, 1)
				assignment.combatLogEventSpellID = spellID
				assignment.spellCount = spellCount
				assignment.combatLogEventType = eventType
				return true
			end
		end
		return false
	end

	---@param encounterID integer
	---@param time number Time from the start of the boss encounter
	---@param assignment CombatLogEventAssignment
	local function HandleNoPreferredCombatLogEventAbilities(encounterID, time, assignment)
		local newSpellID, newSpellCount, newTime = FindNearestCombatLogEvent(time, encounterID, "SCS", true)
		if newSpellID and newSpellCount and newTime then
			if newSpellID and newSpellCount and newTime then
				assignment.time = Utilities.Round(newTime, 1)
				assignment.combatLogEventSpellID = newSpellID
				assignment.spellCount = newSpellCount
				assignment.combatLogEventType = "SCS"
			end
		end
	end

	---@param encounterID integer
	---@param time number Time from the start of the boss encounter
	---@param assignee string
	---@param spellID integer|nil Assignment spell ID
	---@return TimedAssignment|CombatLogEventAssignment|nil
	function Utilities.CreateNewAssignment(encounterID, time, assignee, spellID)
		local assignment = nil
		local boss = GetBoss(encounterID)
		if boss then
			local cumulativeTime = 0.0
			if #boss.phases == 1 then
				assignment = Private.classes.TimedAssignment:New()
			else
				local orderedBossPhaseTable = GetOrderedBossPhases(encounterID)
				if orderedBossPhaseTable then
					for orderedPhaseIndex, phaseIndex in ipairs(orderedBossPhaseTable) do
						local phase = boss.phases[phaseIndex]
						if cumulativeTime + phase.duration > time then
							if orderedPhaseIndex == 1 and phaseIndex == 1 then
								assignment = Private.classes.TimedAssignment:New()
							else
								assignment = Private.classes.CombatLogEventAssignment:New()
								if boss.preferredCombatLogEventAbilities then
									local success = HandlePreferredCombatLogEventAbilities(
										encounterID,
										time,
										assignment,
										phaseIndex,
										boss.preferredCombatLogEventAbilities
									)
									if not success then
										assignment = Private.classes.TimedAssignment:New()
									end
								else
									HandleNoPreferredCombatLogEventAbilities(encounterID, time, assignment)
								end
							end
							break
						end
						cumulativeTime = cumulativeTime + phase.duration
					end
				end
			end
		end
		if assignment then
			assignment.assignee = assignee
		end
		if getmetatable(assignment) == CombatLogEventAssignment then
			Utilities.UpdateAssignmentBossPhase(assignment --[[@as CombatLogEventAssignment]], encounterID)
		elseif getmetatable(assignment) == TimedAssignment then
			assignment.time = Utilities.Round(time, 1)
		end
		return assignment
	end
end

do
	local AceGUI = LibStub("AceGUI-3.0")
	local kReminderContainerFrameLevel = constants.frameLevels.kReminderContainerFrameLevel

	-- Creates a container for adding progress bars or messages to.
	---@param preferences GenericReminderPreferences
	---@param spacing number|nil
	---@return EPContainer
	function Utilities.CreateReminderContainer(preferences, spacing)
		local container = AceGUI:Create("EPContainer")
		container:SetLayout("EPProgressBarLayout")
		container.frame:SetParent(UIParent)
		container.frame:SetFrameStrata("MEDIUM")
		container.frame:SetFrameLevel(kReminderContainerFrameLevel)
		container:SetSpacing(0, spacing or 0)
		container.content.sortAscending = preferences.soonestExpirationOnBottom
		local regionName = Utilities.IsValidRegionName(preferences.relativeTo) and preferences.relativeTo or "UIParent"
		local point, relativePoint = preferences.point, preferences.relativePoint
		local x, y = preferences.x, preferences.y
		container.frame:SetPoint(point, regionName, relativePoint, x, y)
		return container
	end
end

--@debug@
do
	---@class Test
	local test = Private.test
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	do
		function test.CreateUniquePlanName()
			local planName, newName = "", ""
			for _ = 1, 36 do
				planName = planName .. "H"
			end
			local plans = {}
			plans[planName] = Plan:New({}, planName)
			newName = Utilities.CreateUniquePlanName(plans, planName)
			testUtilities.TestNotEqual(planName, newName, "Plan names not equal")
			testUtilities.TestEqual(newName:len(), 36, "Plan length equal to 36")

			planName = ""
			for _ = 1, 34 do
				planName = planName .. "H"
			end
			planName = planName .. "99"
			plans[planName] = Plan:New({}, planName)
			newName = Utilities.CreateUniquePlanName(plans, planName)
			testUtilities.TestNotEqual(planName, newName, "Plan names not equal")
			testUtilities.TestEqual(newName:len(), 36, "Plan length equal to 36")
			testUtilities.TestEqual(newName:sub(34, 36), "100", "Correct number appended")

			planName = "Plan Name"
			plans[planName] = Plan:New({}, planName)
			newName = Utilities.CreateUniquePlanName(plans, planName)
			testUtilities.TestEqual("Plan Name 2", newName, "Plan name appended with number")

			planName = "Plan Name 3"
			plans[planName] = Plan:New({}, planName)
			newName = Utilities.CreateUniquePlanName(plans, "Plan Name 4")
			testUtilities.TestEqual("Plan Name 4", newName, "Plan name available and used")

			return "CreateUniquePlanName"
		end
	end

	do
		local testEncounterIDOne = constants.kDefaultBossDungeonEncounterID
		local testEncounterIDTwo = 3010
		local testEncounterIDThree = 3011

		---@return table<string, Plan>, Plan, Plan, Plan, Plan
		local function CreateTestPlans()
			local planName = "Test"
			local plans = {}

			local planOne = Utilities.CreatePlan(plans, planName, testEncounterIDOne)
			local planTwo = Utilities.CreatePlan(plans, planName, testEncounterIDOne)
			local planThree = Utilities.CreatePlan(plans, planName, testEncounterIDTwo)
			local planFour = Utilities.CreatePlan(plans, planName, testEncounterIDTwo)

			return plans, planOne, planTwo, planThree, planFour
		end

		---@param planOne Plan
		---@param planTwo Plan
		---@param planThree Plan
		---@param planFour Plan
		---@param truthTable table<integer, boolean>
		---@param context string
		local function TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, context)
			testUtilities.TestEqual(planOne.isPrimaryPlan, truthTable[1], context .. " Index " .. 1)
			testUtilities.TestEqual(planTwo.isPrimaryPlan, truthTable[2], context .. " Index " .. 2)
			testUtilities.TestEqual(planThree.isPrimaryPlan, truthTable[3], context .. " Index " .. 3)
			testUtilities.TestEqual(planFour.isPrimaryPlan, truthTable[4], context .. " Index " .. 4)
		end

		function test.SetDesignatedExternalPlan()
			local plans, planOne, planTwo, planThree, planFour = CreateTestPlans()
			testUtilities.TestEqual(planOne.isPrimaryPlan, true, "Correct primary plan after creation")
			testUtilities.TestEqual(planThree.isPrimaryPlan, true, "Correct primary plan after creation")
			planOne.isPrimaryPlan = false
			planThree.isPrimaryPlan = false

			Utilities.SetDesignatedExternalPlan(plans, planOne)
			local truthTable = { true, false, false, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Set primary when none exist")

			Utilities.SetDesignatedExternalPlan(plans, planThree)
			truthTable = { true, false, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Set primary when none exist")

			Utilities.SetDesignatedExternalPlan(plans, planOne)
			Utilities.SetDesignatedExternalPlan(plans, planThree)
			truthTable = { true, false, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Do nothing when primary exists")

			Utilities.SetDesignatedExternalPlan(plans, planTwo)
			Utilities.SetDesignatedExternalPlan(plans, planFour)
			truthTable = { false, true, false, true }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Switch primary")

			return "SetDesignatedExternalPlan"
		end

		function test.ChangePlanBoss()
			local plans, planOne, planTwo, planThree, planFour = CreateTestPlans()

			Utilities.ChangePlanBoss(plans, planOne.name, constants.kDefaultBossDungeonEncounterID)
			Utilities.ChangePlanBoss(plans, planThree.name, testEncounterIDTwo)
			local truthTable = { true, false, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "No change")

			Utilities.ChangePlanBoss(plans, planTwo.name, testEncounterIDThree)
			truthTable = { true, true, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Set new primary when no primary exist")

			Utilities.ChangePlanBoss(plans, planFour.name, testEncounterIDTwo)
			truthTable = { true, true, true, false }
			local context = "Preserve primary when primary already exists"
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, context)

			Utilities.ChangePlanBoss(plans, planOne.name, testEncounterIDTwo)
			truthTable = { false, true, true, false }
			context = context .. " 2"
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, context)

			return "ChangePlanBoss"
		end

		function test.DeletePlan()
			local plans, planOne, planTwo, planThree, planFour = CreateTestPlans()
			local profile = { plans = plans, lastOpenPlan = planOne.name }

			Utilities.DeletePlan(profile, planOne.name)
			testUtilities.TestEqual(profile.plans[planOne.name], nil, "Successfully removed correct plan")
			testUtilities.TestEqual(profile.plans[planTwo.name], planTwo, "Successfully removed correct plan")
			testUtilities.TestEqual(profile.plans[planThree.name], planThree, "Successfully removed correct plan")
			testUtilities.TestEqual(profile.plans[planFour.name], planFour, "Successfully removed correct plan")

			planOne.isPrimaryPlan = false
			local truthTable = { false, true, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Primary swapped after deleting")

			Utilities.DeletePlan(profile, planFour.name)
			testUtilities.TestEqual(profile.plans[planOne.name], nil, "Successfully removed correct plan 2")
			testUtilities.TestEqual(profile.plans[planTwo.name], planTwo, "Successfully removed correct plan 2")
			testUtilities.TestEqual(profile.plans[planThree.name], planThree, "Successfully removed correct plan 2")
			testUtilities.TestEqual(profile.plans[planFour.name], nil, "Successfully removed correct plan 2")

			planFour.isPrimaryPlan = false
			truthTable = { false, true, true, false }
			TestPlansEqual(planOne, planTwo, planThree, planFour, truthTable, "Preserve primary")

			Utilities.DeletePlan(profile, planTwo.name)
			Utilities.DeletePlan(profile, planThree.name)
			testUtilities.TestEqual(profile.plans[planTwo.name], nil, "Successfully removed all plans but one")
			testUtilities.TestEqual(profile.plans[planThree.name], nil, "Successfully removed all plans but one")
			testUtilities.TestEqual(profile.plans[planFour.name], nil, "Successfully removed all plans but one")

			local _, defaultPlan = next(profile.plans) --[[@as Plan]]
			local lastExistingEncounterID = planThree.dungeonEncounterID
			local defaultPlanEncounterID = defaultPlan.dungeonEncounterID
			local context = "Created default plan after deleting all plans"
			testUtilities.TestEqual(lastExistingEncounterID, defaultPlanEncounterID, context)

			return "DeletePlan"
		end
	end
end
--@end-debug@
