local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn
local L = Private.L
local GetSpellInfo = C_Spell.GetSpellInfo
local format = format
local LibStub = LibStub
local LibDeflate = LibStub("LibDeflate")
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local print = print
local type = type
local UnitFullName = UnitFullName

local configForDeflate = {
	[1] = { level = 1 },
	[2] = { level = 2 },
	[3] = { level = 3 },
	[4] = { level = 4 },
	[5] = { level = 5 },
	[6] = { level = 6 },
	[7] = { level = 7 },
	[8] = { level = 8 },
	[9] = { level = 9 },
}

---@class SerializedPlan
---@field [1] string ID
---@field [2] string name
---@field [3] integer dungeonEncounterID
---@field [4] integer instanceID
---@field [5] table<integer, SerializedAssignment> assignments
---@field [6] table<string, SerializedRosterEntry> roster
---@field [7] table<integer, string> content

---@class SerializedAssignment
---@field [1] string assigneeNameOrRole
---@field [2] number spellInfo.spellID
---@field [3] string text
---@field [4] string targetName
---@field [5] number time
---@field [6] CombatLogEventType|nil combatLogEventType
---@field [7] integer|nil combatLogEventSpellID
---@field [8] integer|nil spellCount
---@field [9] integer|nil phase
---@field [10] integer|nil bossPhaseOrderIndex

---@class SerializedRosterEntry
---@field [1] string name
---@field [2] string class
---@field [3] RaidGroupRole role
---@field [4] string classColoredName

---@param assignment Assignment|CombatLogEventAssignment|TimedAssignment
---@return SerializedAssignment
local function SerializeAssignment(assignment)
	local required =
		{ assignment.assigneeNameOrRole, assignment.spellInfo.spellID, assignment.text, assignment.targetName }
	if assignment.time then
		required[5] = assignment.time
	end
	if assignment.combatLogEventType then
		required[6] = assignment.combatLogEventType
		required[7] = assignment.combatLogEventSpellID
		required[8] = assignment.spellCount
		required[9] = assignment.phase
		required[10] = assignment.bossPhaseOrderIndex
	end
	return required
end

---@param data SerializedAssignment
---@return CombatLogEventAssignment|TimedAssignment
local function DeserializeAssignment(data)
	local assignment = {
		assigneeNameOrRole = data[1],
		spellInfo = GetSpellInfo(data[2])
			or { name = "", iconID = 0, originalIconID = 0, castTime = 0, minRange = 0, maxRange = 0, spellID = 0 },
		text = data[3],
		targetName = data[4],
		time = data[5],
	}
	if data[10] then
		assignment.combatLogEventType = data[6]
		assignment.combatLogEventSpellID = data[7]
		assignment.spellCount = data[8]
		assignment.phase = data[9]
		assignment.bossPhaseOrderIndex = data[10]
		return Private.classes.CombatLogEventAssignment:New(assignment)
	else
		return Private.classes.TimedAssignment:New(assignment)
	end
end

---@param name string
---@param rosterEntry RosterEntry
---@return SerializedRosterEntry
local function SerializeRosterEntry(name, rosterEntry)
	local serializedRosterEntry = {
		name or "",
		rosterEntry.class or "",
		rosterEntry.role or "",
		rosterEntry.classColoredName or "",
	} --[[@as SerializedRosterEntry]]
	return serializedRosterEntry
end

---@param serializedRosterEntry SerializedRosterEntry
---@return string, RosterEntry
local function DeserializeRosterEntry(serializedRosterEntry)
	local rosterEntry = Private.classes.RosterEntry:New({})
	rosterEntry.class = serializedRosterEntry[2]
	rosterEntry.role = serializedRosterEntry[3]
	rosterEntry.classColoredName = serializedRosterEntry[4]
	return serializedRosterEntry[1], rosterEntry
end

---@param plan Plan
---@return SerializedPlan
local function SerializePlan(plan)
	local serializedPlan = {
		plan.ID,
		plan.name,
		plan.dungeonEncounterID,
		plan.instanceID,
		{},
		{},
		{},
	} --[[@as SerializedPlan]]
	local assignments = serializedPlan[5]
	for _, assignment in ipairs(plan.assignments) do
		assignments[#assignments + 1] = SerializeAssignment(assignment)
	end
	local roster = serializedPlan[6]
	for name, rosterInfo in pairs(plan.roster) do
		roster[#roster + 1] = SerializeRosterEntry(name, rosterInfo)
	end
	serializedPlan[7] = plan.content
	return serializedPlan
end

---@param serializedPlan SerializedPlan
---@return Plan
local function DeserializePlan(serializedPlan)
	local ID = serializedPlan[1]
	local name = serializedPlan[2]
	local plan = Private.classes.Plan:New({}, name, ID)
	plan.dungeonEncounterID = serializedPlan[3]
	plan.instanceID = serializedPlan[4]
	for _, serializedAssignment in ipairs(serializedPlan[5]) do
		plan.assignments[#plan.assignments + 1] = DeserializeAssignment(serializedAssignment)
	end
	for _, serializedRosterEntry in ipairs(serializedPlan[6]) do
		local rosterEntryName, rosterEntry = DeserializeRosterEntry(serializedRosterEntry)
		plan.roster[rosterEntryName] = rosterEntry
	end
	plan.content = serializedPlan[7]
	return plan
end

---@param inTable table
---@param forChat boolean
---@param level integer|nil
---@return string
local function TableToString(inTable, forChat, level)
	---@diagnostic disable-next-line: undefined-field
	local serialized = Private.Encode(inTable)
	local compressed = LibDeflate:CompressZlib(serialized, configForDeflate[level] or nil)

	if forChat then
		return LibDeflate:EncodeForPrint(compressed)
	else
		return LibDeflate:EncodeForWoWAddonChannel(compressed)
	end
end

---@param inString string
---@param fromChat boolean
---@return table|string
local function StringToTable(inString, fromChat)
	local decoded
	if fromChat then
		decoded = LibDeflate:DecodeForPrint(inString)
	else
		decoded = LibDeflate:DecodeForWoWAddonChannel(inString)
	end
	if not decoded then
		return L["Error decoding"]
	end

	local decompressed = LibDeflate:DecompressZlib(decoded)
	if not decompressed then
		return L["Error decompressing"]
	end

	---@diagnostic disable-next-line: undefined-field
	local deserialized = Private.Decode(decompressed)
	return deserialized
end

---@param plan Plan
local function ImportPlan(plan)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
	local existingPlanName, existingPlan = interfaceUpdater.FindMatchingPlan(plan.ID)

	if existingPlanName and existingPlan then -- Replace matching plan with imported plan
		plans[plan.name] = plan
		if existingPlanName ~= plan.name then
			plans[existingPlanName] = nil
		end
		existingPlan = nil
	else -- Create a unique plan name if necessary
		if plans[plan.name] then
			plan.name = utilities.CreateUniquePlanName(plans, L["Imported"], plan.name)
		end
		plans[plan.name] = plan
	end

	if Private.mainFrame then
		local planDropdown = Private.mainFrame.planDropdown
		if planDropdown then
			local item, text = planDropdown:FindItemAndText(plan.name)
			if not item then
				planDropdown:AddItem(plan.name, plan.name, "EPDropdownItemToggle") -- Only add if unique
				planDropdown:Sort()
			end
			if text and text == existingPlanName then
				planDropdown:RemoveItem(text) -- Remove existing plan name from dropdown
			end
			local currentPlanName = planDropdown:GetValue()
			if currentPlanName == existingPlanName or currentPlanName == plan.name then
				AddOn.db.profile.lastOpenPlan = plan.name
				planDropdown:SetValue(plan.name)
				interfaceUpdater.UpdateFromPlan(plan.name) -- Only update if current plan is the imported plan
			end
		end
	end
end

---@param prefix string
---@param message string
---@param distribution string
---@param sender string
function AddOn:OnCommReceived(prefix, message, distribution, sender)
	local name, realm = UnitFullName(sender)
	if not name then
		return
	end
	if not realm or string.len(realm) < 3 then
		local _, r = UnitFullName("player")
		realm = r
	end
	local fullName = name .. "-" .. realm
	if prefix == "EPDistributePlan" then
		local package = StringToTable(message, false)
		if type(package == "table") then
			local plan = DeserializePlan(package --[[@as table]])
			local foundTrustedCharacter = false
			for _, trustedCharacter in ipairs(AddOn.db.profile.trustedCharacters) do
				if fullName == trustedCharacter then
					foundTrustedCharacter = true
					break
				end
			end
			if foundTrustedCharacter then
				ImportPlan(plan)
			else
				local messageContent = format(
					'%s %s "%s". %s',
					fullName,
					L["has sent you the plan"],
					plan.name,
					L["Do you wish to accept the plan? Trusting this character will suppress this warning in the future."]
				)
				local messageBox = interfaceUpdater.CreateMessageBox(L["Plan Received"], messageContent)
				if messageBox then
					messageBox:SetAcceptButtonText(L["Accept and Trust"])
					messageBox:SetRejectButtonText(L["Reject"])
					local rejectButton = messageBox.buttonContainer.children[2]
					messageBox:AddButton(L["Accept without Trusting"], rejectButton)
					messageBox:SetCallback(L["Accept without Trusting"] .. "Clicked", function()
						ImportPlan(plan)
					end)
					messageBox:SetCallback("Accepted", function()
						local trustedCharacters = AddOn.db.profile.trustedCharacters
						trustedCharacters[#trustedCharacters + 1] = fullName
						ImportPlan(plan)
					end)
				end
			end
		end
	end
end

function Private:RegisterCommunications()
	AddOn:RegisterComm(AddOnName)
	AddOn:RegisterComm("EPDistributePlan")
end

---@param plan Plan
function Private:SendPlanToGroup(plan)
	local inGroup = (IsInRaid() and "RAID") or (IsInGroup() and "PARTY")
	if not inGroup then
		return
	end
	local export = TableToString(SerializePlan(plan), false)
	local function callback(callbackArg, sent, total)
		--print(sent, total)
	end
	AddOn:SendCommMessage("EPDistributePlan", export, inGroup, nil, "BULK", callback)
end
