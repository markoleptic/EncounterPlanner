local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
local Encode, Decode = Private.Encode, Private.Decode

---@class Constants
local constants = Private.constants

local k = {
	ConfigForDeflate = {
		[1] = { level = 1 },
		[2] = { level = 2 },
		[3] = { level = 3 },
		[4] = { level = 4 },
		[5] = { level = 5 },
		[6] = { level = 6 },
		[7] = { level = 7 },
		[8] = { level = 8 },
		[9] = { level = 9 },
	},
	DistributePlan = constants.communications.kDistributePlan,
	DistributeText = constants.communications.kDistributeText,
	PlanReceived = constants.communications.kPlanReceived,
	RequestPlanUpdate = constants.communications.kRequestPlanUpdate,
}

---@class Utilities
local utilities = Private.utilities
local CreateUniquePlanName = utilities.CreateUniquePlanName
local SetDesignatedExternalPlan = utilities.SetDesignatedExternalPlan

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater
local AddPlanToDropdown = interfaceUpdater.AddPlanToDropdown

local FindMatchingPlan = interfaceUpdater.FindMatchingPlan
local LogMessage = interfaceUpdater.LogMessage
local RemovePlanFromDropdown = interfaceUpdater.RemovePlanFromDropdown
local UpdateFromPlan = interfaceUpdater.UpdateFromPlan

local LibDeflate = LibStub("LibDeflate")
local format = string.format
local ipairs = ipairs
local IsInRaid = IsInRaid
local pairs = pairs
local type = type
local UnitFullName = UnitFullName

---@class PlanSerializer
local PlanSerializer = {}
do
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

	---@param assignment Assignment|CombatLogEventAssignment|TimedAssignment
	---@return SerializedAssignment
	local function SerializeAssignment(assignment)
		local required = {}
		required[1] = assignment.assignee
		required[2] = assignment.spellID
		required[3] = assignment.text
		required[4] = assignment.targetName
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
		local assignment = Assignment:New({})
		assignment.assignee = data[1]
		assignment.spellID = data[2]
		assignment.text = data[3]
		assignment.targetName = data[4]

		if data[10] then
			assignment = CombatLogEventAssignment:New(assignment)
			assignment.time = data[5]
			assignment.combatLogEventType = data[6]
			assignment.combatLogEventSpellID = data[7]
			assignment.spellCount = data[8]
			assignment.phase = data[9]
			assignment.bossPhaseOrderIndex = data[10]
		else
			assignment = TimedAssignment:New(assignment)
			assignment.time = data[5]
		end

		return assignment
	end

	---@param name string
	---@param rosterEntry RosterEntry
	---@return SerializedRosterEntry
	local function SerializeRosterEntry(name, rosterEntry)
		local serializedRosterEntry = {}
		serializedRosterEntry[1] = name or ""
		serializedRosterEntry[2] = rosterEntry.class or ""
		serializedRosterEntry[3] = rosterEntry.role or ""
		serializedRosterEntry[4] = rosterEntry.classColoredName or ""
		return serializedRosterEntry
	end

	---@param serializedRosterEntry SerializedRosterEntry
	---@return string, RosterEntry
	local function DeserializeRosterEntry(serializedRosterEntry)
		local rosterEntry = RosterEntry:New({})
		local name = serializedRosterEntry[1]
		rosterEntry.class = serializedRosterEntry[2]
		rosterEntry.role = serializedRosterEntry[3]
		rosterEntry.classColoredName = serializedRosterEntry[4]
		return name, rosterEntry
	end

	---@param plan Plan
	---@return SerializedPlan
	function PlanSerializer.SerializePlan(plan)
		local serializedPlan = {}
		serializedPlan[1] = plan.ID
		serializedPlan[2] = plan.name
		serializedPlan[3] = plan.dungeonEncounterID
		serializedPlan[4] = plan.instanceID
		serializedPlan[5] = plan.difficulty
		serializedPlan[6] = {}
		local assignments = serializedPlan[6]
		for _, assignment in ipairs(plan.assignments) do
			assignments[#assignments + 1] = SerializeAssignment(assignment)
		end
		serializedPlan[7] = {}
		local roster = serializedPlan[7]
		for name, rosterInfo in pairs(plan.roster) do
			roster[#roster + 1] = SerializeRosterEntry(name, rosterInfo)
		end
		serializedPlan[8] = plan.content
		return serializedPlan
	end

	---@param serializedPlan SerializedPlan
	---@return Plan
	function PlanSerializer.DeserializePlan(serializedPlan)
		local planID = serializedPlan[1]
		local name = serializedPlan[2]
		local plan = Plan:New({}, name, planID)
		plan.dungeonEncounterID = serializedPlan[3]
		plan.instanceID = serializedPlan[4]
		plan.difficulty = serializedPlan[5]
		for _, serializedAssignment in ipairs(serializedPlan[6]) do
			plan.assignments[#plan.assignments + 1] = DeserializeAssignment(serializedAssignment)
		end
		for _, serializedRosterEntry in ipairs(serializedPlan[7]) do
			---@cast serializedRosterEntry SerializedRosterEntry
			local rosterEntryName, rosterEntry = DeserializeRosterEntry(serializedRosterEntry)
			plan.roster[rosterEntryName] = rosterEntry
		end
		plan.content = serializedPlan[8]
		return plan
	end
end

---@param inString string
---@param forChat boolean
---@param level integer|nil
---@return string
local function CompressString(inString, forChat, level)
	local compressed = LibDeflate:CompressZlib(inString, k.ConfigForDeflate[level] or nil)
	if forChat then
		return LibDeflate:EncodeForPrint(compressed)
	else
		return LibDeflate:EncodeForWoWAddonChannel(compressed)
	end
end

---@param inString string
---@return string
local function DecompressString(inString, fromChat)
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
	return decompressed
end

---@param inTable table
---@param forChat boolean
---@param level integer|nil
---@return string
local function TableToString(inTable, forChat, level)
	local serialized = Encode(inTable)
	local compressed = LibDeflate:CompressZlib(serialized, k.ConfigForDeflate[level] or nil)

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

	local deserialized = Decode(decompressed)
	return deserialized
end

---@param plan Plan
---@param fullName string
local function ImportPlan(plan, fullName)
	local plans = AddOn.db.profile.plans
	local existingPlanName, existingPlan = FindMatchingPlan(plan.ID)

	local importInfo
	if existingPlanName and existingPlan then -- Replace matching plan with imported plan
		plans[plan.name] = plan
		if existingPlanName ~= plan.name then
			plans[existingPlanName] = nil
		end
		if AddOn.db.profile.lastOpenPlan == existingPlanName then -- Replace last open if it was removed
			AddOn.db.profile.lastOpenPlan = plan.name
		end
		importInfo = format("%s '%s'.", L["Updated matching plan"], existingPlanName)
	else -- Create a unique plan name if necessary
		if plans[plan.name] then
			plan.name = CreateUniquePlanName(plans, plan.name)
		end
		plans[plan.name] = plan
		importInfo = format("%s '%s'.", L["Imported plan as"], plan.name)
	end

	LogMessage(format("%s '%s' %s %s.", L["Received plan"], plan.name, L["from"], fullName))
	LogMessage(importInfo)

	if IsInRaid() then
		local changedPrimaryPlan = SetDesignatedExternalPlan(plans, plan)
		if changedPrimaryPlan then
			LogMessage(format("%s '%s'.", L["Changed the Designated External Plan to"], plan.name))
		end
	end

	if Private.mainFrame then
		if existingPlanName and existingPlanName ~= plan.name then -- Remove existing plan name from dropdown
			RemovePlanFromDropdown(existingPlanName)
		end

		local currentPlanName = Private.mainFrame.planDropdown:GetValue()
		if currentPlanName == existingPlanName or currentPlanName == plan.name then
			AddOn.db.profile.lastOpenPlan = plan.name
			AddPlanToDropdown(plan, true)
			UpdateFromPlan(plan, true) -- Only update if current plan is the imported plan
		else
			AddPlanToDropdown(plan, false)
		end
	end
end

local commObject = {}
do
	local CreateMessageBox = interfaceUpdater.CreateMessageBox
	local IsInGroup = IsInGroup
	local NewTimer = C_Timer.NewTimer
	local next = next
	local RemoveFromMessageQueue = interfaceUpdater.RemoveFromMessageQueue
	local strsplittable = strsplittable
	local tinsert = table.insert
	local tremove = table.remove
	local UnitIsGroupAssistant, UnitIsGroupLeader = UnitIsGroupAssistant, UnitIsGroupLeader
	local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup
	local wipe = table.wipe

	local activePlanIDsBeingSent = {} ---@type table<string, {timer:FunctionContainer|nil, totalReceivedConfirmations: integer}>
	local activePlanReceiveMessageBoxDataIDs = {} ---@type table<integer, string>

	function commObject.Reset()
		for _, uniqueID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			RemoveFromMessageQueue(uniqueID)
		end
		wipe(activePlanReceiveMessageBoxDataIDs)
		for _, obj in pairs(activePlanIDsBeingSent) do
			obj.timer:Cancel()
		end
		wipe(activePlanIDsBeingSent)
	end

	local function UpdateSendPlanButtonEnabledState()
		if Private.mainFrame and Private.mainFrame.sendPlanButton then
			local inGroup = IsInGroup() or IsInRaid()
			local isLeader = UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")
			Private.mainFrame.sendPlanButton:SetEnabled(inGroup and isLeader)
		end
	end

	---@return string|nil
	local function GetGroupType()
		local groupType = nil
		if IsInRaid() then
			groupType = "RAID"
		elseif IsInGroup() then
			groupType = "PARTY"
		end
		return groupType
	end

	function commObject.HandleGroupRosterUpdate()
		if IsInGroup() or IsInRaid() then
			UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
		end
		UpdateSendPlanButtonEnabledState()
	end

	---@param IDToRemove string
	local function RemoveFromActiveMessageBoxDataIDs(IDToRemove)
		for index, uniqueID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			if uniqueID == IDToRemove then
				tremove(activePlanReceiveMessageBoxDataIDs, index)
				break
			end
		end
	end

	---@param plan Plan
	---@param sender string
	local function CreateImportMessageBox(plan, sender)
		local uniqueID = Private.GenerateUniqueID()
		local messageBoxData = {
			ID = uniqueID,
			isCommunication = true,
			title = L["Plan Received"],
			message = format(
				"%s %s '%s'. %s %s",
				sender,
				L["has sent you the plan"],
				plan.name,
				L["Do you want to accept the plan?"],
				L["Trusting this character will allow them to send you new plans and update plans they have previously sent you without showing this message."]
			),
			acceptButtonText = L["Accept and Trust"],
			acceptButtonCallback = function()
				local trustedCharacters = AddOn.db.profile.trustedCharacters
				trustedCharacters[#trustedCharacters + 1] = sender
				if plan then
					ImportPlan(plan, sender)
				end
				RemoveFromActiveMessageBoxDataIDs(uniqueID)
			end,
			rejectButtonText = L["Reject"],
			rejectButtonCallback = function()
				RemoveFromActiveMessageBoxDataIDs(uniqueID)
			end,
			buttonsToAdd = {
				{
					beforeButtonIndex = 2,
					buttonText = L["Accept without Trusting"],
					callback = function()
						if plan then
							ImportPlan(plan, sender)
						end
						RemoveFromActiveMessageBoxDataIDs(uniqueID)
					end,
				},
			},
		} --[[@as MessageBoxData]]
		tinsert(activePlanReceiveMessageBoxDataIDs, messageBoxData.ID)
		CreateMessageBox(messageBoxData, true)
	end

	-- Executed after receiving the DistributePlan message.
	---@param message string
	---@param senderFullName string
	local function HandleDistributePlanCommReceived(message, senderFullName)
		local package = StringToTable(message, false)
		if type(package == "table") then
			local plan = PlanSerializer.DeserializePlan(package --[[@as table]])
			local groupType = GetGroupType()
			if groupType then
				local returnMessage = CompressString(format("%s,%s", plan.ID, senderFullName), false)
				AddOn:SendCommMessage(k.PlanReceived, returnMessage, groupType, nil, "NORMAL")
			end
			local foundTrustedCharacter = false
			for _, trustedCharacter in ipairs(AddOn.db.profile.trustedCharacters) do
				if senderFullName == trustedCharacter then
					foundTrustedCharacter = true
					break
				end
			end
			if foundTrustedCharacter then
				ImportPlan(plan, senderFullName)
			else
				CreateImportMessageBox(plan, senderFullName)
			end
		end
	end

	-- Executed after sending a plan and receiving the PlanReceived response.
	---@param message string
	---@param playerFullName string
	local function HandlePlanReceivedCommReceived(message, playerFullName)
		if next(activePlanIDsBeingSent) then
			local package = DecompressString(message, false)
			local messageTable = strsplittable(",", package)
			local planID, originalPlanSender = messageTable[1], messageTable[2]
			if planID and originalPlanSender then
				if activePlanIDsBeingSent[planID] then
					if originalPlanSender == playerFullName then
						local count = activePlanIDsBeingSent[planID].totalReceivedConfirmations
						activePlanIDsBeingSent[planID].totalReceivedConfirmations = count + 1
					end
				end
			end
		end
	end

	-- Executed after receiving the DistributeText message.
	---@param message string
	local function HandleDistributeTextCommReceived(message)
		local package = StringToTable(message, false)
		AddOn.db.profile.activeText = package --[[@as table]]
		Private.ExecuteAPICallback("ExternalTextSynced")
	end

	---@param prefix string
	---@param message string
	---@param _ string Distribution
	---@param sender string
	function AddOn:OnCommReceived(prefix, message, _, sender)
		local senderName, senderRealm = UnitFullName(sender)
		if not senderName then
			return
		end
		local playerName, playerRealm = UnitFullName("player")
		local playerFullName = format("%s-%s", playerName, playerRealm)
		if not senderRealm or senderRealm:len() < 3 then
			senderRealm = playerRealm
		end
		local senderFullName = format("%s-%s", senderName, senderRealm)

		--[===[@non-debug@
		if senderFullName == playerFullName then
			return
		end
        --@end-non-debug@]===]

		if prefix == k.DistributePlan then
			HandleDistributePlanCommReceived(message, senderFullName)
		elseif prefix == k.PlanReceived then
			HandlePlanReceivedCommReceived(message, playerFullName)
		elseif prefix == k.DistributeText then
			HandleDistributeTextCommReceived(message)
		end
	end

	---@param planID string
	---@param sent integer
	---@param total integer
	local function CallbackProgress(planID, sent, total)
		if total > 0 then
			local progress = sent / total
			if progress >= 1.0 then
				LogMessage(L["Plan sent"] .. ".")
				if activePlanIDsBeingSent[planID] then
					activePlanIDsBeingSent[planID].timer = NewTimer(10, function()
						local count = activePlanIDsBeingSent[planID].totalReceivedConfirmations
						local playerString = count == 1 and L["player"] or L["players"]
						LogMessage(format("%s %d %s.", L["Plan received by"], count, playerString))
						activePlanIDsBeingSent[planID] = nil
					end)
				end
			end
		end
	end

	function Private.HandleSendPlanButtonConstructed()
		UpdateSendPlanButtonEnabledState()
	end

	function Private.SendPlanToGroup()
		local plans = AddOn.db.profile.plans
		local plan = plans[AddOn.db.profile.lastOpenPlan]
		local groupType = GetGroupType()
		if groupType then
			if groupType == "RAID" then
				local changedPrimaryPlan = SetDesignatedExternalPlan(plans, plan)
				interfaceUpdater.UpdatePlanCheckBoxes(plan)
				if changedPrimaryPlan then
					LogMessage(format("%s '%s'.", L["Changed the Designated External Plan to"], plan.name))
				end
			end
			if activePlanIDsBeingSent[plan.ID] then
				activePlanIDsBeingSent[plan.ID].timer:Cancel()
				activePlanIDsBeingSent[plan.ID].timer = nil
			end
			activePlanIDsBeingSent[plan.ID] = { timer = nil, totalReceivedConfirmations = 0 }
			local exportString = TableToString(PlanSerializer.SerializePlan(plan), false)
			LogMessage(format("%s '%s'...", L["Sending plan"], plan.name))
			AddOn:SendCommMessage(k.DistributePlan, exportString, groupType, nil, "BULK", CallbackProgress, plan.ID)
		end
	end

	---@param bossDungeonEncounterID integer
	---@param difficultyType DifficultyType
	function Private.SendTextToGroup(bossDungeonEncounterID, difficultyType)
		if UnitIsGroupLeader("player") then
			local plans = AddOn.db.profile.plans
			local primaryPlan ---@type Plan|nil
			for _, plan in pairs(plans) do
				if plan.dungeonEncounterID == bossDungeonEncounterID and plan.difficulty == difficultyType then
					if plan.isPrimaryPlan == true then
						primaryPlan = plan
						break
					end
				end
			end
			if primaryPlan then
				local groupType = GetGroupType()
				if groupType then
					local exportString = TableToString(primaryPlan.content, false)
					AddOn:SendCommMessage(k.DistributeText, exportString, groupType, nil, "NORMAL")
					Private.ExecuteAPICallback("ExternalTextSynced")
				end
			end
		end
	end
end

function Private:RegisterCommunications()
	AddOn:RegisterComm(AddOnName)
	AddOn:RegisterComm(k.DistributePlan)
	AddOn:RegisterComm(k.PlanReceived)
	AddOn:RegisterComm(k.DistributeText)
	self.RegisterCallback(commObject, "ProfileRefreshed", "Reset")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", commObject.HandleGroupRosterUpdate)
end

function Private:UnregisterCommunications()
	commObject.Reset()
	AddOn:UnregisterAllComm()
	self.UnregisterCallback(commObject, "ProfileRefreshed")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

--@debug@
Private.TableToString = TableToString
Private.StringToTable = StringToTable
Private.PlanSerializer = PlanSerializer
--@end-debug@
