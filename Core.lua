---@module "NerubarPalace"
---@module "Options"
---@module "Interface"

--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

local AddOn = Private.addOn
local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")

local pairs = pairs

-- Addon is first loaded
function AddOn:OnInitialize()
	self.db = AceDB:New(AddOnName .. "DB", self.defaults --[[,true]])
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", AddOn.Refresh)

	local profile = self.db.profile
	if profile then
		-- Convert tables from DB into classes
		for _, note in pairs(profile.notes) do
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
	-- if type(BigWigsLoader) == "table" and BigWigsLoader.RegisterMessage then
	-- 	BigWigsLoader.RegisterMessage({}, "BigWigs_SetStage", function(event, addon, stage)
	-- 		print("Stage", stage)
	-- 	end)
	-- end
	-- Private:RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
	-- 	print(encounterID, encounterName, difficultyID, groupSize)
	-- end)
	-- Private:RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
	-- 	print(encounterID, encounterName, difficultyID, groupSize, success)
	-- end)
	-- Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
	-- 	local time, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, extraSpellId, amount =
	-- 		CombatLogGetCurrentEventInfo()
	-- 	if event == "SPELL_CAST_SUCCESS" then
	-- 		print(spellId)
	-- 	end
	-- end)
end

function AddOn:OnDisable()
	-- Private:UnregisterAllEvents()
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
