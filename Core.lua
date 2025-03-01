local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class Constants
local constants = Private.constants
local kInvalidAssignmentSpellID = constants.kInvalidAssignmentSpellID
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

---@class Utilities
local utilities = Private.utilities

local AceDB = LibStub("AceDB-3.0")
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local pairs = pairs
local print = print

local minimapIconObject = {}
do -- Minimap icon initialization and handling
	local GetAddOnMetric = C_AddOnProfiler.GetAddOnMetric
	local version = C_AddOns.GetAddOnMetadata(AddOnName, "Version")

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
			tooltip:AddDoubleLine(AddOnName, version)
			tooltip:AddLine(" ")
			tooltip:AddLine("|cffeda55f" .. L["Left-Click|r to toggle showing the main window."], 0.2, 1, 0.2)
			tooltip:AddLine("|cffeda55f" .. L["Right-Click|r to open the options menu."], 0.2, 1, 0.2)
			tooltip:AddLine(" ")

			local sessionAverageTime = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.SessionAverageTime)
			local recentAverageTime = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.RecentAverageTime)
			local encounterAverageTime = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.EncounterAverageTime)
			local lastTime = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.LastTime)
			local peakTime = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.PeakTime)
			local countTimeOver1Ms = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.CountTimeOver1Ms)
			local countTimeOver5Ms = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.CountTimeOver5Ms)
			local countTimeOver10Ms = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.CountTimeOver10Ms)
			local countTimeOver50Ms = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.CountTimeOver50Ms)
			local countTimeOver100Ms = GetAddOnMetric(AddOnName, Enum.AddOnProfilerMetric.CountTimeOver100Ms)

			local r, g, b = 237.0 / 255.0, 165.0 / 255.0, 95.0 / 255.0
			local str = format("%s:", L["Average Time Since Login/Reload"])
			tooltip:AddDoubleLine(str, format("%.4f %s", sessionAverageTime, L["ms"]), r, g, b)
			str = format("%s:", L["Highest Time Since Login/Reload"])
			tooltip:AddDoubleLine(str, format("%.4f %s", peakTime, L["ms"]), r, g, b)
			str = format("%s:", L["Total Time In Most Recent Tick"])
			tooltip:AddDoubleLine(str, format("%.4f %s", lastTime, L["ms"]), r, g, b)

			str = format("%s:", L["Average Time Over Last 60 Ticks"])
			tooltip:AddDoubleLine(str, format("%.4f %s", recentAverageTime, L["ms"]), r, g, b)
			str = format("%s:", L["Average Time Over Boss Encounter"])
			tooltip:AddDoubleLine(str, format("%.4f %s", encounterAverageTime, L["ms"]), r, g, b)

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
		icon = "Interface\\AddOns\\EncounterPlanner\\Media\\ep-logo.tga",
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

	local GameTooltip = GameTooltip

	---@type LibDataBroker.QuickLauncher
	local dataBrokerObject = {
		type = "launcher",
		text = AddOnName,
		icon = "Interface\\AddOns\\EncounterPlanner\\Media\\ep-logo.tga",
		OnClick = HandleMinimapButtonClicked,
		OnEnter = function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_NONE")
			GameTooltip:SetPoint(GetAnchors(frame))
			DrawTooltip(false)
		end,
		OnLeave = function(_)
			GameTooltip:Hide()
		end,
		iconR = 0,
		iconG = 1,
		iconB = 0,
	}

	---@param addOn AceAddon|table
	function minimapIconObject.RegisterMinimapIcons(addOn)
		AddonCompartmentFrame:RegisterAddon(AddonCompartmentFrameObject)
		dataBrokerObject = LDB:NewDataObject(AddOnName, dataBrokerObject)
		LDBIcon:Register(AddOnName, dataBrokerObject, addOn.db.profile.preferences.minimap)
	end
end

do -- Raid instance initialization
	local EJ_GetCreatureInfo = EJ_GetCreatureInfo
	local EJ_GetEncounterInfo, EJ_SelectEncounter = EJ_GetEncounterInfo, EJ_SelectEncounter
	local EJ_GetInstanceInfo, EJ_SelectInstance = EJ_GetInstanceInfo, EJ_SelectInstance

	-- Initializes names and icons for raid instances.
	function InitializeDungeonInstances()
		for _, dungeonInstance in pairs(Private.dungeonInstances) do
			if dungeonInstance.executeAndNil then
				dungeonInstance.executeAndNil()
				dungeonInstance.executeAndNil = nil
			end
			EJ_SelectInstance(dungeonInstance.journalInstanceID)
			local instanceName, _, _, _, _, buttonImage2, _, _, _, _ =
				EJ_GetInstanceInfo(dungeonInstance.journalInstanceID)
			dungeonInstance.name, dungeonInstance.icon = instanceName, buttonImage2
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
			end
		end
	end
end

do -- Profile updating and refreshing
	---@class CombatLogEventAssignment
	local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
	---@class Plan
	local Plan = Private.classes.Plan
	---@class BossUtilities
	local bossUtilities = Private.bossUtilities
	local ChangePlanBoss = bossUtilities.ChangePlanBoss
	local GetAbsoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable
	local GetBoss = bossUtilities.GetBoss
	local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases

	---@param assignment CombatLogEventAssignment
	---@param absoluteSpellCastTimeTable table<integer, table<integer, { castStart: number, bossPhaseOrderIndex: integer }>>
	---@param orderedBossPhaseTable table<integer, integer>
	local function UpdateCombatLogEventAssignment(assignment, absoluteSpellCastTimeTable, orderedBossPhaseTable)
		if absoluteSpellCastTimeTable and orderedBossPhaseTable then
			local spellIDSpellCastStartTable = absoluteSpellCastTimeTable[assignment.combatLogEventSpellID]
			if spellIDSpellCastStartTable then
				if not spellIDSpellCastStartTable[assignment.spellCount] then
					assignment.spellCount = 1
				end
				if not assignment.phase or assignment.phase == 0 or assignment.bossPhaseOrderIndex == 0 then
					local orderIndex = spellIDSpellCastStartTable[assignment.spellCount].bossPhaseOrderIndex
					assignment.bossPhaseOrderIndex = orderIndex
					assignment.phase = orderedBossPhaseTable[orderIndex]
				end
			end
		end
	end

	---@class RosterEntry
	local RosterEntry = Private.classes.RosterEntry

	local GetClassColor = C_ClassColor.GetClassColor
	local getmetatable = getmetatable
	local GetSpecialization, GetSpecializationInfo = GetSpecialization, GetSpecializationInfo
	local next = next
	local select = select
	local SetAssignmentMetaTables = utilities.SetAssignmentMetaTables
	local UnitClass = UnitClass
	local UnitFullName = UnitFullName

	-- Sets the metatables for assignments and performs a small amount of assignment validation.
	---@param profile DefaultProfile
	function AddOn.UpdateProfile(profile)
		if profile then
			local remappings = Private.spellDB.GetSpellRemappings()
			for planName, plan in pairs(profile.plans) do
				SetAssignmentMetaTables(plan.assignments) -- Convert tables from DB into classes
				plan = Plan:New(plan, planName, plan.ID)
				local boss = GetBoss(plan.dungeonEncounterID)
				if not boss then
					ChangePlanBoss(2902, plan)
				end
				local dungeonEncounterID = plan.dungeonEncounterID
				boss = GetBoss(plan.dungeonEncounterID) --[[@as Boss]]
				local customPhaseDurations = AddOn.db.profile.plans[planName].customPhaseDurations
				bossUtilities.SetPhaseDurations(dungeonEncounterID, customPhaseDurations)
				local customPhaseCounts = AddOn.db.profile.plans[planName].customPhaseCounts
				customPhaseCounts =
					bossUtilities.SetPhaseCounts(dungeonEncounterID, customPhaseCounts, constants.kMaxBossDuration)
				bossUtilities.GenerateBossTables(boss)
				local absoluteSpellCastTimeTable = GetAbsoluteSpellCastTimeTable(dungeonEncounterID)
				local orderedBossPhaseTable = GetOrderedBossPhases(dungeonEncounterID)
				if absoluteSpellCastTimeTable and orderedBossPhaseTable then
					for _, assignment in ipairs(plan.assignments) do
						if assignment.spellInfo.spellID == kInvalidAssignmentSpellID then
							if assignment.text:len() > 0 then
								assignment.spellInfo.spellID = kTextAssignmentSpellID
							end
						elseif remappings[assignment.spellInfo.spellID] then
							assignment.spellInfo.spellID = remappings[assignment.spellInfo.spellID]
						end
						if getmetatable(assignment) == CombatLogEventAssignment then
							UpdateCombatLogEventAssignment(
								assignment --[[@as CombatLogEventAssignment]],
								absoluteSpellCastTimeTable,
								orderedBossPhaseTable
							)
						end
					end
				end
			end
			if not next(profile.sharedRoster) then
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
				profile.sharedRoster[unitName] = RosterEntry:New({
					class = "class:" .. classFileName,
					role = role,
					classColoredName = classColoredName,
				})
			end
			for dungeonEncounterID, activeBossAbilities in pairs(profile.activeBossAbilities) do
				local boss = GetBoss(dungeonEncounterID)
				if boss then
					for bossAbilityID, _ in pairs(activeBossAbilities) do
						if not boss.abilities[bossAbilityID] then
							activeBossAbilities[bossAbilityID] = nil
						end
					end
				end
			end
		end
	end

	local UpdateFromPlan = interfaceUpdater.UpdateFromPlan
	local UpdatePlanWidgets = interfaceUpdater.UpdatePlanWidgets

	---@param db AceDBObject-3.0
	---@param newProfile string|nil
	function AddOn:Refresh(_, db, newProfile)
		self.UpdateProfile(db.profile)
		LDBIcon:Refresh(AddOnName, db.profile.preferences.minimap)
		Private.callbacks:Fire("ProfileRefreshed")
		interfaceUpdater.RemoveMessageBoxes(false)
		if Private.mainFrame then
			local bossDungeonEncounterID = 2902
			local plans = db.profile.plans --[[@as table<string, Plan>]]
			local lastOpenPlan = db.profile.lastOpenPlan
			if lastOpenPlan == "" or not plans[lastOpenPlan] or plans[lastOpenPlan].dungeonEncounterID == 0 then
				local defaultPlanName = L["Default"]
				plans[defaultPlanName] = Plan:New(nil, defaultPlanName)
				ChangePlanBoss(bossDungeonEncounterID, plans[defaultPlanName])
				db.profile.lastOpenPlan = defaultPlanName
			end
			local timeline = Private.mainFrame.timeline
			if timeline then
				timeline:SetPreferences(db.profile.preferences)
			end
			UpdatePlanWidgets()
			UpdateFromPlan(db.profile.lastOpenPlan)
		end
		if Private.optionsMenu then
			Private:RecreateAnchors()
		end
	end
end

function AddOn:OnInitialize()
	local loadedOrLoading, loaded = IsAddOnLoaded("WeakAuras")
	if not loadedOrLoading and not loaded then
		self.defaults.profile.preferences.reminder.progressBars.texture = [[Interface\Buttons\WHITE8X8]]
	end
	self.db = AceDB:New(AddOnName .. "DB", self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")

	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self:RegisterChatCommand("ep", "SlashCommand")

	minimapIconObject.RegisterMinimapIcons(self)

	self.OnInitialize = nil
end

function AddOn:OnEnable()
	Private.testRunner.RunTests()
	self.UpdateProfile(self.db.profile)
	InitializeDungeonInstances()
	Private:RegisterCommunications()
	Private:RegisterReminderEvents()
end

function AddOn:OnDisable()
	self:OnProfileShutdown()
	Private:UnregisterCommunications()
	Private:UnregisterAllEvents()
	if Private.mainFrame then
		Private.mainFrame:Release()
	end
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
		if DevTool then
			DevTool:AddData(Private)
		end
		if not Private.mainFrame then
			Private:CreateInterface()
		end
	elseif input then
		local trimmed = input:trim():lower()
		if trimmed == "options" then
			Private:CreateOptionsMenu()
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
