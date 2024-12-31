---@module "NerubarPalace"
---@module "Options"
---@module "Interface"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")

local pairs = pairs

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults --[[,true]])
	self.db.RegisterCallback(self, "OnProfileChanged", AddOn.Refresh)
	self.db.RegisterCallback(self, "OnProfileCopied", AddOn.Refresh)
	self.db.RegisterCallback(self, "OnProfileReset", AddOn.Refresh)

	local profile = self.db.profile --[[@as DefaultProfile]]
	if profile then
		for _, note in pairs(profile.notes) do
			if not note.dungeonEncounterID or note.dungeonEncounterID == 0 then -- TODO: Temp remove
				if note.bossName then
					local bossDungeonEncounterID = bossUtilities.GetBossDungeonEncounterID(note.bossName)
					if bossDungeonEncounterID then
						note.dungeonEncounterID = bossDungeonEncounterID
					end
				end
			end
			if not note.instanceID or note.instanceID == 0 then -- TODO: Temp remove
				if note.bossName then
					local bossInstanceID = bossUtilities.GetBossInstanceID(note.bossName)
					if bossInstanceID then
						note.instanceID = bossInstanceID
					end
				end
			end
			-- Convert tables from DB into classes
			for _, assignment in pairs(note.assignments) do
				assignment = Private.classes.Assignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				if assignment.combatLogEventType then
					assignment = Private.classes.CombatLogEventAssignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				elseif assignment.phase then
					assignment = Private.classes.PhasedAssignment:New(assignment)
				---@diagnostic disable-next-line: undefined-field
				elseif assignment.time then
					assignment = Private.classes.TimedAssignment:New(assignment)
				end
			end
		end
	end

	Private:InitializeInterface()

	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self:RegisterChatCommand("ep", "SlashCommand")

	self.OnInitialize = nil
end

function AddOn:OnEnable()
	Private:RegisterReminderEvents()
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
