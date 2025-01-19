local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

local constants = Private.constants

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local pairs = pairs
local UnitIsGroupAssistant, UnitIsGroupLeader = UnitIsGroupAssistant, UnitIsGroupLeader

local function HandleGroupRosterUpdate()
	local enableButton = false
	if IsInGroup() or IsInRaid() then
		utilities.UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
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
			utilities.SetAssignmentMetaTables(plan.assignments) -- Convert tables from DB into classes

			plan = Private.classes.Plan:New(plan, plan.name, plan.ID)
			local absoluteSpellCastTimeTable = bossUtilities.GetAbsoluteSpellCastTimeTable(plan.dungeonEncounterID)
			local orderedBossPhaseTable = bossUtilities.GetOrderedBossPhases(plan.dungeonEncounterID)

			for _, assignment in ipairs(plan.assignments) do
				if assignment.spellInfo.spellID == constants.kInvalidAssignmentSpellID then
					if assignment.text:len() > 0 then
						assignment.spellInfo.spellID = constants.kTextAssignmentSpellID
					end
				end
				if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
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

function AddOn:OnInitialize()
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
	Private:InitializeInterface()
	Private:RegisterCommunications()
	Private:RegisterReminderEvents()
	self:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupRosterUpdate)
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
		local timeline = Private.mainFrame.timeline
		if timeline then
			timeline:SetPreferences(db.profile.preferences)
		end
		interfaceUpdater.UpdatePlanDropdown()
		interfaceUpdater.UpdateFromPlan(db.profile.lastOpenPlan)
	end
end

-- Closes any editors and dialogs that may incorrectly represent the current profile.
function AddOn:OnProfileShutdown()
	if Private.IsSimulatingBoss() then
		Private:StopSimulatingBoss()
	end
	if Private.messageAnchor then
		Private.messageAnchor:Release()
	end
	if Private.progressBarAnchor then
		Private.progressBarAnchor:Release()
	end
	if Private.assignmentEditor then
		Private.assignmentEditor:Release()
	end
	if Private.rosterEditor then
		Private.rosterEditor:Release()
	end
	if Private.importEditBox then
		Private.importEditBox:Release()
	end
	if Private.exportEditBox then
		Private.exportEditBox:Release()
	end
	if Private.phaseLengthEditor then
		Private.phaseLengthEditor:Release()
	end
	if Private.exportEditBox then
		Private.exportEditBox:Release()
	end
	if Private.messageBox then
		Private.messageBox:Release()
	end
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
		end
	end
end
