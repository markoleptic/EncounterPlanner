---@module "NerubarPalace"
---@module "Options"
---@module "Interface"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local bossUtilities = Private.bossUtilities

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

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults --[[,true]])
	self.db.RegisterCallback(self, "OnProfileChanged", AddOn.Refresh)
	self.db.RegisterCallback(self, "OnProfileCopied", AddOn.Refresh)
	self.db.RegisterCallback(self, "OnProfileReset", AddOn.Refresh)

	local profile = self.db.profile --[[@as DefaultProfile]]
	if profile then
		for _, note in pairs(profile.plans) do
			-- Convert tables from DB into classes
			utilities.SetAssignmentMetaTables(note.assignments)
		end
	end

	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self:RegisterChatCommand("ep", "SlashCommand")

	self.OnInitialize = nil
end

function AddOn:OnEnable()
	Private:InitializeInterface()
	Private:RegisterCommunications()
	Private:RegisterReminderEvents()
	self:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupRosterUpdate)
end

function AddOn:OnDisable()
	Private:UnregisterAllEvents()
end

function AddOn:Refresh(db, newProfile)
	-- TODO: Refresh gui with new profile data
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
		if trimmed == "close" then
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
