local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class Constants
local constants = Private.constants

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

---@class AssignmentUtilities
local assignmentUtilities = Private.assignmentUtilities

---@class Utilities
local utilities = Private.utilities
local CreatePlan = utilities.CreatePlan

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local DifficultyType = Private.classes.DifficultyType

local AceDB = LibStub("AceDB-3.0")
local AddOnProfilerMetricEnum = Enum.AddOnProfilerMetric
local format = string.format
local GetConfigInfo = C_Traits.GetConfigInfo
local TraitConfigType = Enum.TraitConfigType
local GameTooltip = GameTooltip
local ipairs = ipairs
local NewTimer = C_Timer.NewTimer
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local pairs = pairs
local print = print
local tonumber = tonumber
local type = type
local UIParent = UIParent

---@param version string
---@return number?
---@return number?
---@return number?
local function ParseVersion(version)
	local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
	if major and minor and patch then
		return tonumber(major), tonumber(minor), tonumber(patch)
	end
	return nil, nil, nil
end

---@param major number|nil
---@param minor number|nil
---@param patch number|nil
---@param targetMajor number
---@param targetMinor number
---@param targetPatch number
---@return boolean
local function IsVersionLessThan(major, minor, patch, targetMajor, targetMinor, targetPatch)
	if not major or not minor or not patch then
		return true
	end
	return (major < targetMajor)
		or (major == targetMajor and minor < targetMinor)
		or (major == targetMajor and minor == targetMinor and patch < targetPatch)
end

---@class MinimapIconObject
local MinimapIconObject = {}
do -- Minimap icon initialization and handling
	local GetAddOnMetric = C_AddOnProfiler.GetAddOnMetric

	-- Function copied from LibDBIcon-1.0.lua
	---@param frame Frame
	local function GetAnchors(frame)
		local x, y = frame:GetCenter()
		if not x or not y then
			return "CENTER"
		end
		local hHalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
		local vHalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
		return vHalf .. hHalf, frame, (vHalf == "TOP" and "BOTTOM" or "TOP") .. hHalf
	end

	local function ToggleMinimap()
		AddOn.db.profile.preferences.minimap.show = not AddOn.db.profile.preferences.minimap.show
		if not AddOn.db.profile.preferences.minimap.show then
			LDBIcon:Hide(AddOnName)
			print(L["Use /ep minimap to show the minimap icon again."])
		else
			LDBIcon:Show(AddOnName)
		end
	end

	---@param isAddonCompartment boolean
	---@param blizzardTooltip GameTooltip|nil
	local function DrawTooltip(isAddonCompartment, blizzardTooltip)
		local tooltip
		if isAddonCompartment then
			tooltip = blizzardTooltip
		else
			tooltip = GameTooltip
		end
		if tooltip then
			tooltip:ClearLines()
			tooltip:AddDoubleLine(AddOnName, Private.version)
			tooltip:AddLine(" ")
			tooltip:AddLine("|cffeda55f" .. L["Left-Click|r to toggle showing the main window."], 0.2, 1, 0.2)
			tooltip:AddLine("|cffeda55f" .. L["Right-Click|r to open the options menu."], 0.2, 1, 0.2)
			tooltip:AddLine(" ")

			local sessionAverageTime = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.SessionAverageTime)
			local encounterAverageTime = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.EncounterAverageTime)

			local r, g, b = 237.0 / 255.0, 165.0 / 255.0, 95.0 / 255.0
			local str = format("%s:", L["Average Time Since Login/Reload"])
			tooltip:AddDoubleLine(str, format("%.4f %s", sessionAverageTime, L["ms"]), r, g, b)
			str = format("%s:", L["Average Time Over Boss Encounter"])
			tooltip:AddDoubleLine(str, format("%.4f %s", encounterAverageTime, L["ms"]), r, g, b)

			--@debug@
			local recentAverageTime = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.RecentAverageTime)
			local lastTime = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.LastTime)
			local peakTime = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.PeakTime)
			local countTimeOver1Ms = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.CountTimeOver1Ms)
			local countTimeOver5Ms = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.CountTimeOver5Ms)
			local countTimeOver10Ms = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.CountTimeOver10Ms)
			local countTimeOver50Ms = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.CountTimeOver50Ms)
			local countTimeOver100Ms = GetAddOnMetric(AddOnName, AddOnProfilerMetricEnum.CountTimeOver100Ms)
			str = format("%s:", L["Highest Time Since Login/Reload"])
			tooltip:AddDoubleLine(str, format("%.4f %s", peakTime, L["ms"]), r, g, b)
			str = format("%s:", L["Total Time In Most Recent Tick"])
			tooltip:AddDoubleLine(str, format("%.4f %s", lastTime, L["ms"]), r, g, b)
			str = format("%s:", L["Average Time Over Last 60 Ticks"])
			tooltip:AddDoubleLine(str, format("%.4f %s", recentAverageTime, L["ms"]), r, g, b)
			str = format("%s %d %s:", L["Count Time Over"], 1, L["ms"])
			tooltip:AddDoubleLine(str, format("%d", countTimeOver1Ms), r, g, b)
			str = format("%s %d %s:", L["Count Time Over"], 5, L["ms"])
			tooltip:AddDoubleLine(str, format("%d", countTimeOver5Ms), r, g, b)
			str = format("%s %d %s:", L["Count Time Over"], 10, L["ms"])
			tooltip:AddDoubleLine(str, format("%d", countTimeOver10Ms), r, g, b)
			str = format("%s %d %s:", L["Count Time Over"], 50, L["ms"])
			tooltip:AddDoubleLine(str, format("%d", countTimeOver50Ms), r, g, b)
			str = format("%s %d %s:", L["Count Time Over"], 100, L["ms"])
			tooltip:AddDoubleLine(str, format("%d", countTimeOver100Ms), r, g, b)
			--@end-debug@

			if not isAddonCompartment then
				tooltip:AddLine(" ")
				tooltip:AddLine("|cffeda55f" .. L["Middle-Click|r to hide this icon."], r, g, b)
			end

			tooltip:Show()
		end
	end

	local MenuUtil = MenuUtil

	---@param buttonNameOrMenuInputData string|table
	local function HandleMinimapButtonClicked(_, buttonNameOrMenuInputData, _)
		local mouseButton = buttonNameOrMenuInputData
		if type(buttonNameOrMenuInputData) == "table" then
			mouseButton = buttonNameOrMenuInputData.buttonName
		end
		if mouseButton == "LeftButton" then
			if not Private.mainFrame then
				Private:CreateInterface()
			elseif not Private.mainFrame.frame:IsVisible() then
				Private.mainFrame:Maximize()
			end
		elseif mouseButton == "MiddleButton" then
			ToggleMinimap()
		elseif mouseButton == "RightButton" then
			if not Private.optionsMenu then
				Private:CreateOptionsMenu()
			end
		end
	end

	local AddonCompartmentFrameObject = {
		text = AddOnName,
		icon = constants.textures.kLogo,
		registerForAnyClick = true,
		notCheckable = true,
		func = HandleMinimapButtonClicked,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip)
				DrawTooltip(true, tooltip)
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	}

	---@type LibDataBroker.QuickLauncher
	local dataBrokerObject = {
		type = "launcher",
		text = AddOnName,
		icon = constants.textures.kLogo,
		OnClick = HandleMinimapButtonClicked,
		OnEnter = function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_NONE")
			GameTooltip:SetPoint(GetAnchors(frame))
			DrawTooltip(false)
		end,
		OnLeave = function(_)
			GameTooltip:Hide()
		end,
		iconR = 74 / 255.0,
		iconG = 174 / 255.0,
		iconB = 242 / 255.0,
	}

	---@param addOn AceAddon|table
	function MinimapIconObject.RegisterMinimapIcons(addOn)
		AddonCompartmentFrame:RegisterAddon(AddonCompartmentFrameObject)
		dataBrokerObject = LDB:NewDataObject(AddOnName, dataBrokerObject)
		LDBIcon:Register(AddOnName, dataBrokerObject, addOn.db.profile.preferences.minimap)
	end
end

---@class DungeonInstanceInitializer
local DungeonInstanceInitializer = {}
do -- Raid instance initialization
	local EJ_GetCreatureInfo = EJ_GetCreatureInfo
	local EJ_GetEncounterInfo, EJ_SelectEncounter = EJ_GetEncounterInfo, EJ_SelectEncounter
	local EJ_GetInstanceInfo, EJ_SelectInstance = EJ_GetInstanceInfo, EJ_SelectInstance

	---@param nameOrNumber string|integer
	---@return string longName
	---@return string shortName
	local function CreatePhaseName(nameOrNumber)
		if type(nameOrNumber) == "string" then
			-- Match "Int" or "P" followed by a number, optional content in parenthesis
			local phaseType, number, extra = nameOrNumber:match("^(%a+)(%d+)%s*%(([^)]+)%)$")
			if not phaseType then
				phaseType, number = nameOrNumber:match("^(%a+)(%d+)$")
			end

			local phaseName, shortName
			if phaseType == "Int" then
				phaseName = format("%s %d", L["Intermission"], number)
				shortName = format("%s%d", L["I"], number)
			else
				phaseName = format("%s %d", L["Phase"], number)
				shortName = format("%s%d", L["P"], number)
			end

			if extra then
				local energy = extra:match("^(%d+) Energy$")
				local health = extra:match("^(%d+) Health$")
				if energy then
					phaseName = format("%s (%d%% %s)", phaseName, energy, L["Energy"])
				elseif health then
					phaseName = format("%s (%d%% %s)", phaseName, health, L["Health"])
				else
					phaseName = format("%s (%s)", phaseName, extra)
				end
			end

			return phaseName, shortName
		else
			return format("%s %d", L["Phase"], nameOrNumber), format("%s%d", L["P"], nameOrNumber)
		end
	end

	local GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
	local GetBossPhases = bossUtilities.GetBossPhases

	-- Initializes names and icons for raid instances.
	function DungeonInstanceInitializer.InitializeDungeonInstances()
		for dungeonInstance in bossUtilities.IterateDungeonInstances() do
			if dungeonInstance.executeAndNil then
				dungeonInstance.executeAndNil()
				dungeonInstance.executeAndNil = nil
			end

			EJ_SelectInstance(dungeonInstance.journalInstanceID)
			if dungeonInstance.mapChallengeModeID then
				local name, _, _, texture, _ = GetMapUIInfo(dungeonInstance.mapChallengeModeID)
				dungeonInstance.name, dungeonInstance.icon = name, texture
			else
				local instanceName, _, _, _, _, buttonImage2, _, _, _, _ =
					EJ_GetInstanceInfo(dungeonInstance.journalInstanceID)
				dungeonInstance.name, dungeonInstance.icon = instanceName, buttonImage2
			end

			for _, boss in ipairs(dungeonInstance.bosses) do
				EJ_SelectEncounter(boss.journalEncounterID)
				local encounterName = EJ_GetEncounterInfo(boss.journalEncounterID)
				local creatureID, bossName, _, _, iconImage, _ = EJ_GetCreatureInfo(1, boss.journalEncounterID)
				boss.name, boss.icon = encounterName, iconImage
				local index = 2
				if boss.journalEncounterCreatureIDsToBossIDs[creatureID] then
					while creatureID and bossName do
						local npcID = boss.journalEncounterCreatureIDsToBossIDs[creatureID]
						if npcID then
							boss.bossNames[npcID] = bossName
						end
						creatureID, bossName, _, _, _, _ = EJ_GetCreatureInfo(index, boss.journalEncounterID)
						index = index + 1
					end
				end
				if boss.phases then
					for phaseIndex, phase in ipairs(GetBossPhases(boss, DifficultyType.Mythic)) do
						local long, short = CreatePhaseName(phase.name or phaseIndex)
						phase.name = long
						phase.shortName = short
					end
				end
				if boss.phasesHeroic then
					for phaseIndex, phase in ipairs(GetBossPhases(boss, DifficultyType.Heroic)) do
						local long, short = CreatePhaseName(phase.name or phaseIndex)
						phase.name = long
						phase.shortName = short
					end
				end
			end
		end
	end
end

do -- Profile updating and refreshing
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class Plan
	local Plan = Private.classes.Plan

	---@param assignment CombatLogEventAssignment
	---@param absoluteSpellCastTimeTable table<integer, table<integer, SpellCastStartTableEntry>>
	---@param orderedBossPhaseTable table<integer, integer>
	local function UpdateCombatLogEventAssignment(assignment, absoluteSpellCastTimeTable, orderedBossPhaseTable)
		local spellIDSpellCastStartTable = absoluteSpellCastTimeTable[assignment.combatLogEventSpellID]
		if spellIDSpellCastStartTable then
			if not spellIDSpellCastStartTable[assignment.spellCount] then
				assignment.spellCount = 1
			end
			if not assignment.phase or assignment.phase == 0 or assignment.bossPhaseOrderIndex == 0 then
				local spellInfo = spellIDSpellCastStartTable[assignment.spellCount]
				if spellInfo and spellInfo.bossPhaseOrderIndex then
					assignment.bossPhaseOrderIndex = spellInfo.bossPhaseOrderIndex
					assignment.phase = orderedBossPhaseTable[spellInfo.bossPhaseOrderIndex]
				end
			end
		end
	end

	local getmetatable = getmetatable
	local next = next

	local GenerateBossTables = bossUtilities.GenerateBossTables
	local GetAbsoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable
	local GetBoss = bossUtilities.GetBoss
	local GetBossAbilities = bossUtilities.GetBossAbilities
	local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases
	local SetPhaseCounts = bossUtilities.SetPhaseCounts
	local SetPhaseDurations = bossUtilities.SetPhaseDurations

	local ChangePlanBoss = utilities.ChangePlanBoss
	local SetAssignmentMetaTables = assignmentUtilities.SetAssignmentMetaTables

	local function RemoveInvalidActiveBossAbilities(activeBossAbilities, difficulty)
		for dungeonEncounterID, activeBossAbilitiesForEncounterID in pairs(activeBossAbilities) do
			local boss = GetBoss(dungeonEncounterID)
			if boss then
				local bossAbilities = GetBossAbilities(boss, difficulty)
				for bossAbilityID, _ in pairs(activeBossAbilitiesForEncounterID) do
					if not bossAbilities[bossAbilityID] then
						activeBossAbilitiesForEncounterID[bossAbilityID] = nil
					end
				end
			end
		end
	end

	-- Sets the metatables for assignments and performs a small amount of assignment validation.
	---@param profile DefaultProfile
	function AddOn.UpdateProfile(profile)
		if profile then
			Private.ResetPlanAssignmentCounter()
			local remappings = Private.spellDB.GetSpellRemappings()

			---@type table<integer, table<DifficultyType, boolean>>
			local encounterIDsAndDifficultiesWithPlans = {}

			local plans = profile.plans
			for planName, plan in pairs(plans) do
				plan = Plan:New(plan, planName, plan.ID)
				SetAssignmentMetaTables(plan.assignments, plan.ID) -- Convert tables from DB into classes

				local boss = GetBoss(plan.dungeonEncounterID)
				if not boss then
					ChangePlanBoss(
						profile.plans,
						plan.name,
						constants.kDefaultBossDungeonEncounterID,
						DifficultyType.Mythic
					)
				end
				boss = GetBoss(plan.dungeonEncounterID)--[[@as Boss]]

				local dungeonEncounterID = boss.dungeonEncounterID

				if not boss.phasesHeroic and plan.difficulty == DifficultyType.Heroic then
					ChangePlanBoss(profile.plans, plan.name, dungeonEncounterID, DifficultyType.Mythic)
				elseif not boss.phases and plan.difficulty == DifficultyType.Mythic then
					ChangePlanBoss(profile.plans, plan.name, dungeonEncounterID, DifficultyType.Heroic)
				end

				if not encounterIDsAndDifficultiesWithPlans[dungeonEncounterID] then
					encounterIDsAndDifficultiesWithPlans[dungeonEncounterID] = {}
				end
				if not encounterIDsAndDifficultiesWithPlans[dungeonEncounterID][plan.difficulty] then
					encounterIDsAndDifficultiesWithPlans[dungeonEncounterID][plan.difficulty] = true
				end

				SetPhaseDurations(dungeonEncounterID, plan.customPhaseDurations, plan.difficulty)
				plan.customPhaseCounts = SetPhaseCounts(
					dungeonEncounterID,
					plan.customPhaseCounts,
					constants.kMaxBossDuration,
					plan.difficulty
				)

				GenerateBossTables(boss, plan.difficulty)
				local absoluteSpellCastTimeTable = GetAbsoluteSpellCastTimeTable(dungeonEncounterID, plan.difficulty)
				local orderedBossPhaseTable = GetOrderedBossPhases(dungeonEncounterID, plan.difficulty)

				if absoluteSpellCastTimeTable and orderedBossPhaseTable then
					for _, assignment in ipairs(plan.assignments) do
						if remappings[assignment.spellID] then
							assignment.spellID = remappings[assignment.spellID]
						end
						if getmetatable(assignment) == CombatLogEventAssignment then
							---@cast assignment CombatLogEventAssignment
							UpdateCombatLogEventAssignment(
								assignment,
								absoluteSpellCastTimeTable,
								orderedBossPhaseTable
							)
						end
					end
				else
					for _, assignment in ipairs(plan.assignments) do
						if remappings[assignment.spellID] then
							assignment.spellID = remappings[assignment.spellID]
						end
					end
				end
			end

			local missing = bossUtilities.DetermineMissingEncounterIDsAcrossAllDifficulties(
				encounterIDsAndDifficultiesWithPlans,
				profile.createdDefaults
			)
			for encounterID, difficulties in pairs(missing) do
				profile.createdDefaults[encounterID] = true
				local boss = GetBoss(encounterID)
				for difficulty, _ in pairs(difficulties) do
					local planName = boss.name
					if boss.phasesHeroic then
						if difficulty == DifficultyType.Heroic then
							planName = format("%s (%s)", planName, L["H"])
						else
							planName = format("%s (%s)", planName, L["M"])
						end
					end
					utilities.CreatePlan(plans, planName, encounterID, difficulty)
				end
			end

			local lastOpenPlan = profile.lastOpenPlan
			if lastOpenPlan == "" or not plans[lastOpenPlan] or plans[lastOpenPlan].dungeonEncounterID == 0 then
				local nextPlanName = next(plans)
				if nextPlanName then
					profile.lastOpenPlan = nextPlanName
				else
					local newPlan =
						CreatePlan(plans, nil, constants.kDefaultBossDungeonEncounterID, DifficultyType.Mythic)
					profile.lastOpenPlan = newPlan.name
				end
			end

			if not next(profile.sharedRoster) then
				local name, entry = utilities.CreateRosterEntryForSelf()
				profile.sharedRoster[name] = entry
			end

			RemoveInvalidActiveBossAbilities(profile.activeBossAbilities, DifficultyType.Mythic)
			RemoveInvalidActiveBossAbilities(profile.activeBossAbilitiesHeroic, DifficultyType.Heroic)

			local currentMajor, currentMinor, currentPatch = ParseVersion(Private.version)
			local major, minor, patch = ParseVersion(profile.version)
			local noVersion = not major or not minor or not patch

			if noVersion or major ~= currentMajor or minor ~= currentMinor or patch ~= currentPatch then
				if noVersion or IsVersionLessThan(major, minor, patch, 0, 9, 9) then -- v0.9.8 or less
					local gallywixActiveBossAbilities = profile.activeBossAbilities[3016]
					if gallywixActiveBossAbilities then
						if gallywixActiveBossAbilities[466341] == true then -- Fused Canisters
							gallywixActiveBossAbilities[466341] = false
						end
						if gallywixActiveBossAbilities[466342] == true then -- Tick-Tock Canisters
							gallywixActiveBossAbilities[466342] = false
						end
						if gallywixActiveBossAbilities[1224378] == true then -- Giga Coils
							gallywixActiveBossAbilities[1224378] = false
						end
						if gallywixActiveBossAbilities[466958] == true then -- Ego Check
							gallywixActiveBossAbilities[466958] = false
						end
					end
				end

				if noVersion or IsVersionLessThan(major, minor, patch, 1, 2, 0) then -- v1.1.1 or less
					local cooldownOverrides = profile.cooldownOverrides --[[@as table<integer, number>]]
					if cooldownOverrides then
						for spellID, cooldownDuration in pairs(cooldownOverrides) do
							profile.cooldownAndChargeOverrides[spellID] = { duration = cooldownDuration }
						end
						---@diagnostic disable-next-line: inject-field
						profile.cooldownOverrides = nil
					end
				end
			end

			profile.version = Private.version
		end
	end

	---@param db AceDBObject-3.0
	---@param _ string|nil New profile
	function AddOn:Refresh(_, db, _)
		local profile = db.profile --[[@as DefaultProfile]]
		self.UpdateProfile(profile)
		LDBIcon:Refresh(AddOnName, profile.preferences.minimap)
		Private.callbacks:Fire("ProfileRefreshed")
		interfaceUpdater.RemoveMessageBoxes(false)
		if Private.mainFrame then
			local plans = profile.plans
			local timeline = Private.mainFrame.timeline
			if timeline then
				timeline.SetPreferences(profile.preferences)
			end
			interfaceUpdater.RepopulatePlanWidgets()
			Private.RepopulateTemplates(profile.templates)
			interfaceUpdater.UpdateFromPlan(plans[profile.lastOpenPlan])
		end
		if Private.optionsMenu then
			Private:RecreateAnchors()
		end
	end
end

function AddOn:OnInitialize()
	local loadedOrLoading, loaded = IsAddOnLoaded("WeakAuras")
	if not loadedOrLoading and not loaded then
		self.defaults.profile.preferences.reminder.progressBars.texture = constants.textures.kGenericWhite
	end
	self.db = AceDB:New(AddOnName .. "DB", self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self:RegisterChatCommand("ep", "SlashCommand")
	MinimapIconObject.RegisterMinimapIcons(self)

	self.OnInitialize = nil
end

---@param _ string
---@param configID integer|nil
local function HandlePlayerTalentUpdate(_, configID)
	local configInfo = GetConfigInfo(configID)
	if configInfo.type == TraitConfigType.Combat then
		NewTimer(0, function()
			utilities.RefreshCachedCooldowns()
			if Private.mainFrame then
				interfaceUpdater.UpdateAllAssignments(false)
			end
		end)
	end
end

function AddOn:OnEnable()
	DungeonInstanceInitializer.InitializeDungeonInstances()
	bossUtilities.Initialize()

	--@debug@
	Private.testRunner.RunTests()
	--@end-debug@

	self.UpdateProfile(self.db.profile)

	--@debug@
	Private.testUtilities.CreateTestPlans(self.db.profile)
	--@end-debug@

	Private:RegisterCommunications()
	local preferences = self.db.profile.preferences
	if preferences.reminder.enabled then
		Private:RegisterReminderEvents()
	end
	Private:RegisterEvent("TRAIT_CONFIG_UPDATED", HandlePlayerTalentUpdate)
end

function AddOn:OnDisable()
	self:OnProfileShutdown()
	Private:UnregisterCommunications()
	Private:UnregisterAllEvents()
	if Private.mainFrame then
		Private.mainFrame:Release()
	end
	Private:ReleaseOptionsMenu()
	if Private.optionsMenu then
		Private.optionsMenu:Release()
	end
end

-- Executed before a profile is changed. Closes any editors and dialogs that may incorrectly represent the current
-- profile. Refresh will be called afterwards.
function AddOn:OnProfileShutdown()
	if Private.IsSimulatingBoss() then
		Private:StopSimulatingBoss()
	end
	Private:CloseDialogs()
	Private:CloseAnchors()
	interfaceUpdater.ClearMessageLog()
	interfaceUpdater.RemoveMessageBoxes(false)
end

---@param input string|nil
function AddOn:SlashCommand(input)
	if not input or input:trim() == "" then
		--@debug@
		if DevTool then
			DevTool:AddData(Private)
		end
		--@end-debug@
		if not Private.mainFrame then
			Private:CreateInterface()
		end
	elseif input then
		local trimmed = input:trim():lower()
		if trimmed == "options" then
			if not Private.optionsMenu then
				Private:CreateOptionsMenu()
			end
		elseif trimmed == "close" then
			if Private.mainFrame then
				Private.mainFrame:Release()
			end
		elseif trimmed == "reset" then
			if Private.mainFrame then
				Private.mainFrame.frame:ClearAllPoints()
				Private.mainFrame.frame:SetPoint("CENTER")
				local x, y = Private.mainFrame.frame:GetLeft(), Private.mainFrame.frame:GetTop()
				Private.mainFrame.frame:ClearAllPoints()
				Private.mainFrame.frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
				Private.mainFrame:DoLayout()
			end
		elseif trimmed == "minimap" then
			self.db.profile.preferences.minimap.show = not self.db.profile.preferences.minimap.show
			if not self.db.profile.preferences.minimap.show then
				LDBIcon:Hide(AddOnName)
				print(AddOnName .. ": " .. L["Use /ep minimap to show the minimap icon again."])
			else
				LDBIcon:Show(AddOnName)
			end
		elseif trimmed == "tut" or trimmed == "tutorial" then
			if not Private.tutorial then
				Private:OpenTutorial()
			end
		--@debug@
		elseif trimmed == "dolayout" then
			if Private.mainFrame then
				Private.mainFrame:DoLayout()
			end
		elseif trimmed == "updatetimeline" then
			if Private.mainFrame then
				local timeline = Private.mainFrame.timeline
				if timeline then
					timeline:UpdateTimeline()
				end
			end
		elseif trimmed == "runtests" then
			Private.testRunner.RunTests()
			--@end-debug@
		end
	end
end

--@debug@
Private.ParseVersion = ParseVersion
Private.IsVersionLessThan = IsVersionLessThan
--@end-debug@
