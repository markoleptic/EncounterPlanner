local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
---@class Plan
local Plan = Private.classes.Plan

---@class Constants
local constants = Private.constants
local kInvalidAssignmentSpellID = constants.kInvalidAssignmentSpellID
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local ChangePlanBoss = bossUtilities.ChangePlanBoss
local GetAbsoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable
local GetBoss = bossUtilities.GetBoss
local GetOrderedBossPhases = bossUtilities.GetOrderedBossPhases

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater
local UpdateFromPlan = interfaceUpdater.UpdateFromPlan
local UpdatePlanDropdown = interfaceUpdater.UpdatePlanDropdown

---@class Utilities
local utilities = Private.utilities
local SetAssignmentMetaTables = utilities.SetAssignmentMetaTables
local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup

local AceDB = LibStub("AceDB-3.0")
local getmetatable = getmetatable
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local pairs = pairs
local UnitIsGroupAssistant, UnitIsGroupLeader = UnitIsGroupAssistant, UnitIsGroupLeader

local function HandleGroupRosterUpdate()
	local enableButton = false
	if IsInGroup() or IsInRaid() then
		UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
		if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") then
			enableButton = true
		end
	end
	if Private.mainFrame and Private.mainFrame.sendPlanButton then
		Private.mainFrame.sendPlanButton:SetEnabled(enableButton)
	end
end

-- Sets the metatables for assignments and performs a small amount of assignment validation.
---@param profile DefaultProfile
local function UpdateProfile(profile)
	if profile then
		for _, plan in pairs(profile.plans) do
			SetAssignmentMetaTables(plan.assignments) -- Convert tables from DB into classes

			plan = Plan:New(plan, plan.name, plan.ID)
			if not GetBoss(plan.dungeonEncounterID) then
				ChangePlanBoss(2902, plan)
			end
			local absoluteSpellCastTimeTable = GetAbsoluteSpellCastTimeTable(plan.dungeonEncounterID)
			local orderedBossPhaseTable = GetOrderedBossPhases(plan.dungeonEncounterID)

			for _, assignment in ipairs(plan.assignments) do
				if assignment.spellInfo.spellID == kInvalidAssignmentSpellID then
					if assignment.text:len() > 0 then
						assignment.spellInfo.spellID = kTextAssignmentSpellID
					end
				end
				if getmetatable(assignment) == CombatLogEventAssignment then
					assignment = assignment --[[@as CombatLogEventAssignment]]
					if absoluteSpellCastTimeTable and orderedBossPhaseTable then
						local spellIDSpellCastStartTable = absoluteSpellCastTimeTable[assignment.combatLogEventSpellID]
						if spellIDSpellCastStartTable then
							if not spellIDSpellCastStartTable[assignment.spellCount] then
								assignment.spellCount = 1
							end
							if assignment.phase == 0 or assignment.bossPhaseOrderIndex == 0 then
								local orderIndex = spellIDSpellCastStartTable[assignment.spellCount].bossPhaseOrderIndex
								assignment.bossPhaseOrderIndex = orderIndex
								assignment.phase = orderedBossPhaseTable[orderIndex]
							end
						end
					end
				end
			end
		end
	end
end

do
	local EJ_GetCreatureInfo = EJ_GetCreatureInfo
	local EJ_GetEncounterInfo, EJ_SelectEncounter = EJ_GetEncounterInfo, EJ_SelectEncounter
	local EJ_GetInstanceInfo, EJ_SelectInstance = EJ_GetInstanceInfo, EJ_SelectInstance

	local initialized = false
	-- Initializes names and icons for raid instances.
	function InitializeRaidInstances()
		if not initialized then
			for _, raidInstance in pairs(Private.raidInstances) do
				EJ_SelectInstance(raidInstance.journalInstanceID)
				local instanceName, _, _, _, _, buttonImage2, _, _, _, _ =
					EJ_GetInstanceInfo(raidInstance.journalInstanceID)
				raidInstance.name, raidInstance.icon = instanceName, buttonImage2
				for _, boss in ipairs(raidInstance.bosses) do
					EJ_SelectEncounter(boss.journalEncounterID)
					local encounterName = EJ_GetEncounterInfo(boss.journalEncounterID)
					local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, boss.journalEncounterID)
					boss.name, boss.icon = encounterName, iconImage
				end
			end
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
	self.db.RegisterCallback(self, "OnProfileDeleted", "Refresh")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")

	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self:RegisterChatCommand("ep", "SlashCommand")

	UpdateProfile(self.db.profile)

	self.OnInitialize = nil
end

function AddOn:OnEnable()
	InitializeRaidInstances()
	Private:RegisterCommunications()
	Private:RegisterReminderEvents()
	self:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupRosterUpdate)
	Private.testRunner.RunTests()
end

function AddOn:OnDisable()
	self:OnProfileShutdown()
	Private:UnregisterAllEvents()
	if Private.mainFrame then
		Private.mainFrame:Release() -- Cleans up remaining gui elements
	end
end

---@param db AceDBObject-3.0
---@param newProfile string|nil
function AddOn:Refresh(_, db, newProfile)
	UpdateProfile(db.profile)
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
		UpdatePlanDropdown()
		UpdateFromPlan(db.profile.lastOpenPlan)
	end
	if Private.optionsMenu then
		Private:RecreateAnchors()
	end
end

-- Closes any editors and dialogs that may incorrectly represent the current profile.
function AddOn:OnProfileShutdown()
	if Private.IsSimulatingBoss() then
		Private:StopSimulatingBoss()
	end
	Private:CloseAnchorsAndDialogs()
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
		end
	end
end
