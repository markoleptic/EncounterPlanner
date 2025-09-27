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
	DistributePlanReceived = constants.communications.kDistributePlanReceived,
	RequestPlanUpdate = constants.communications.kRequestPlanUpdate,
	RequestPlanUpdateResponse = constants.communications.kRequestPlanUpdateResponse,
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
		required[1] = assignment.ID
		required[2] = assignment.assignee
		required[3] = assignment.spellID
		required[4] = assignment.text
		required[5] = assignment.targetName
		if assignment.time then
			required[6] = assignment.time
		end
		if assignment.combatLogEventType then
			required[7] = assignment.combatLogEventType
			required[8] = assignment.combatLogEventSpellID
			required[9] = assignment.spellCount
			required[10] = assignment.phase
			required[11] = assignment.bossPhaseOrderIndex
		end
		return required
	end

	---@param data SerializedAssignment
	---@return CombatLogEventAssignment|TimedAssignment
	local function DeserializeAssignment(data)
		local assignment = Assignment:New()
		assignment.ID = data[1]
		assignment.assignee = data[2]
		assignment.spellID = data[3]
		assignment.text = data[4]
		assignment.targetName = data[5]

		if data[11] then
			assignment = CombatLogEventAssignment:New(assignment)
			assignment.time = data[6]
			assignment.combatLogEventType = data[7]
			assignment.combatLogEventSpellID = data[8]
			assignment.spellCount = data[9]
			assignment.phase = data[10]
			assignment.bossPhaseOrderIndex = data[11]
		else
			assignment = TimedAssignment:New(assignment)
			assignment.time = data[6]
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
		serializedPlan[9] = {}
		local assigneeSpellSets = serializedPlan[9]
		for _, assigneeSpellSet in ipairs(plan.assigneeSpellSets) do
			assigneeSpellSets[#assigneeSpellSets + 1] =
				{ [1] = assigneeSpellSet.assignee, [2] = assigneeSpellSet.spells }
		end
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
		for _, assigneeSpellSet in ipairs(serializedPlan[9]) do
			tinsert(plan.assigneeSpellSets, { assignee = assigneeSpellSet[1], spells = assigneeSpellSet[2] })
		end
		return plan
	end
end
Private.PlanSerializer = PlanSerializer

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

---@param newPlan Plan
---@param fullName string
local function ImportPlan(newPlan, fullName)
	local plans = AddOn.db.profile.plans
	local existingPlanName, existingPlan = FindMatchingPlan(newPlan.ID)

	local importInfo = ""
	local newPlanName = newPlan.name
	if existingPlanName and existingPlan then
		if existingPlan.lastSyncedSnapShot then
			local planDiff = utilities.DiffPlans(existingPlan, newPlan)
			local messages = utilities.MergePlan(AddOn.db.profile.plans, existingPlan, planDiff, true)
			for _, message in ipairs(messages) do
				LogMessage(message)
			end
		else
			existingPlan.name = newPlanName
			existingPlan.dungeonEncounterID = newPlan.dungeonEncounterID
			existingPlan.instanceID = newPlan.instanceID
			existingPlan.difficulty = newPlan.difficulty
			existingPlan.content = newPlan.content
			existingPlan.assignments = newPlan.assignments
			existingPlan.roster = newPlan.roster
			existingPlan.assigneeSpellSets = newPlan.assigneeSpellSets
		end

		utilities.RemoveStaleCollapsedEntries(existingPlan)
		existingPlan.lastSyncedSnapShot = PlanSerializer.SerializePlan(existingPlan)
		plans[newPlanName] = existingPlan

		if existingPlanName ~= newPlanName then
			plans[existingPlanName] = nil
		end
		if AddOn.db.profile.lastOpenPlan == existingPlanName then -- Replace last open if it was removed
			AddOn.db.profile.lastOpenPlan = newPlanName
		end

		importInfo = format("%s '%s'.", L["Updated matching plan"], existingPlanName)
	else -- Create a unique plan name if necessary
		if plans[newPlanName] then
			newPlan.name = CreateUniquePlanName(plans, newPlanName)
		end
		plans[newPlanName] = newPlan
		existingPlan = plans[newPlanName]
		importInfo = format("%s '%s'.", L["Imported plan as"], existingPlan.name)
	end

	LogMessage(format("%s '%s' %s %s.", L["Received plan"], newPlanName, L["from"], fullName))
	LogMessage(importInfo)

	if IsInRaid() then
		local changedPrimaryPlan = SetDesignatedExternalPlan(plans, existingPlan)
		if changedPrimaryPlan then
			LogMessage(format("%s '%s'.", L["Changed the Designated External Plan to"], existingPlan.name))
		end
	end

	if Private.mainFrame then
		if existingPlanName and existingPlanName ~= newPlanName then -- Remove existing plan name from dropdown
			RemovePlanFromDropdown(existingPlanName)
		end

		local currentPlanName = Private.mainFrame.planDropdown:GetValue()
		if currentPlanName == existingPlanName or currentPlanName == newPlanName then
			AddOn.db.profile.lastOpenPlan = existingPlan.name
			AddPlanToDropdown(existingPlan, true)
			UpdateFromPlan(existingPlan, true) -- Only update if current plan is the imported plan
		else
			AddPlanToDropdown(existingPlan, false)
		end
	end
end

---@param existingPlan Plan
---@param planDiff PlanDiff
local function UpdatePlan(existingPlan, planDiff)
	local messages = utilities.MergePlan(AddOn.db.profile.plans, existingPlan, planDiff)

	for _, message in ipairs(messages) do
		LogMessage(message)
	end

	if Private.mainFrame then
		local currentPlanName = Private.mainFrame.planDropdown:GetValue()
		if currentPlanName == existingPlan.name then
			UpdateFromPlan(existingPlan, true) -- Only update if current plan is the updated plan
		end
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

function Private:UpdateSendPlanButtonState()
	if self.mainFrame then
		local sendPlanButton = self.mainFrame.sendPlanButton
		local proposeChangesButton = self.mainFrame.proposeChangesButton
		if sendPlanButton and proposeChangesButton then
			local inGroup = IsInGroup() or IsInRaid()
			local isGroupLeader = UnitIsGroupLeader("player")
			local isAssistant = UnitIsGroupAssistant("player")
			sendPlanButton:SetEnabled(inGroup and (isGroupLeader or isAssistant))
			proposeChangesButton:SetEnabled(inGroup and not isGroupLeader)
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
	local activeUpdatePlanIDsBeingSent = {} ---@type table<string, {timer:FunctionContainer|nil, totalReceivedConfirmations: integer}>
	local activePlanReceiveMessageBoxDataIDs = {} ---@type table<integer, string>
	local activePlanUpdateMessageBoxDataIDs = {} ---@type table<integer, string>

	function commObject.Reset()
		for _, uniqueID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			RemoveFromMessageQueue(uniqueID)
		end
		wipe(activePlanReceiveMessageBoxDataIDs)

		for _, uniqueID in ipairs(activePlanUpdateMessageBoxDataIDs) do
			RemoveFromMessageQueue(uniqueID)
		end
		wipe(activePlanUpdateMessageBoxDataIDs)

		for _, obj in pairs(activePlanIDsBeingSent) do
			obj.timer:Cancel()
		end
		wipe(activePlanIDsBeingSent)

		for _, obj in pairs(activeUpdatePlanIDsBeingSent) do
			obj.timer:Cancel()
		end
		wipe(activeUpdatePlanIDsBeingSent)
	end

	function commObject.HandleGroupRosterUpdate()
		if IsInGroup() or IsInRaid() then
			UpdateRosterDataFromGroup(AddOn.db.profile.sharedRoster)
		end
		Private:UpdateSendPlanButtonState()
	end

	---@param IDToRemove string
	local function RemoveFromActivePlanReceiveMessageBoxDataIDs(IDToRemove)
		for index, uniqueID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			if uniqueID == IDToRemove then
				tremove(activePlanReceiveMessageBoxDataIDs, index)
				break
			end
		end
	end

	---@param IDToRemove string
	local function RemoveFromActivePlanUpdateMessageBoxDataIDs(IDToRemove)
		for index, uniqueID in ipairs(activePlanUpdateMessageBoxDataIDs) do
			if uniqueID == IDToRemove then
				tremove(activePlanUpdateMessageBoxDataIDs, index)
				break
			end
		end
	end

	---@param planID string
	---@param senderFullName string
	---@return string
	local function CreateReceiptString(planID, senderFullName)
		return CompressString(format("%s,%s", planID, senderFullName), false)
	end

	---@param message string
	---@return string planID
	---@return string senderFullName
	local function ParseReceiptString(message)
		local package = DecompressString(message, false)
		local messageTable = strsplittable(",", package)
		return messageTable[1], messageTable[2]
	end

	---@param planID string
	---@param senderFullName string
	---@param context string
	---@return string
	local function CreateUpdateReceiptString(planID, senderFullName, context)
		return CompressString(format("%s,%s,%s", planID, senderFullName, context), false)
	end

	---@param message string
	---@return string planID
	---@return string senderFullName
	---@return string context
	local function ParseUpdateReceiptString(message)
		local package = DecompressString(message, false)
		local messageTable = strsplittable(",", package)
		return messageTable[1], messageTable[2], messageTable[3]
	end

	---@param plan Plan
	---@param senderFullName string
	local function CreateImportMessageBox(plan, senderFullName)
		local uniqueID = Private.GenerateUniqueID()
		local messageBoxData = {
			ID = uniqueID,
			widgetType = "EPMessageBox",
			isCommunication = true,
			title = L["Plan Received"],
			message = format(
				"%s %s '%s'. %s %s",
				senderFullName,
				L["has sent you the plan"],
				plan.name,
				L["Do you want to accept the plan?"],
				L["Trusting this character will allow them to send you new plans and update plans they have previously sent you without showing this message."]
			),
			acceptButtonText = L["Accept and Trust"],
			acceptButtonCallback = function()
				local trustedCharacters = AddOn.db.profile.trustedCharacters
				trustedCharacters[#trustedCharacters + 1] = senderFullName
				if plan then
					ImportPlan(plan, senderFullName)
				end
				RemoveFromActivePlanReceiveMessageBoxDataIDs(uniqueID)
			end,
			rejectButtonText = L["Reject"],
			rejectButtonCallback = function()
				RemoveFromActivePlanReceiveMessageBoxDataIDs(uniqueID)
			end,
			buttonsToAdd = {
				{
					beforeButtonIndex = 2,
					buttonText = L["Accept without Trusting"],
					callback = function()
						if plan then
							ImportPlan(plan, senderFullName)
						end
						RemoveFromActivePlanReceiveMessageBoxDataIDs(uniqueID)
					end,
				},
			},
		} --[[@as MessageBoxData]]
		tinsert(activePlanReceiveMessageBoxDataIDs, messageBoxData.ID)
		CreateMessageBox(messageBoxData, true)
	end

	---@param existingPlan Plan
	---@param newPlan Plan
	---@param planDiff PlanDiff
	---@param senderFullName string
	local function CreateUpdateMessageBox(existingPlan, newPlan, planDiff, senderFullName)
		local uniqueID = Private.GenerateUniqueID()

		local messageBoxData = {
			ID = uniqueID,
			widgetType = "EPDiffViewer",
			isCommunication = true,
			title = L["Plan Change Request"],
			message = format(
				"%s %s '%s'. %s.",
				senderFullName,
				L["wants to update"],
				existingPlan.name,
				L["Select the changes, if any, you wish to update the plan with"]
			),
			acceptButtonText = L["Accept"],
			acceptButtonCallback = function()
				UpdatePlan(existingPlan, planDiff)
				local groupType = GetGroupType()
				if groupType then
					local receiptString = CreateUpdateReceiptString(newPlan.ID, senderFullName, L["was accepted"])
					AddOn:SendCommMessage(k.RequestPlanUpdateResponse, receiptString, groupType, nil, "NORMAL")
				end
				RemoveFromActivePlanUpdateMessageBoxDataIDs(uniqueID)
			end,
			rejectButtonText = L["Reject"],
			rejectButtonCallback = function()
				local groupType = GetGroupType()
				if groupType then
					local receiptString = CreateUpdateReceiptString(newPlan.ID, senderFullName, L["was rejected"])
					AddOn:SendCommMessage(k.RequestPlanUpdateResponse, receiptString, groupType, nil, "NORMAL")
				end
				RemoveFromActivePlanUpdateMessageBoxDataIDs(uniqueID)
			end,
			buttonsToAdd = {
				{
					beforeButtonIndex = 2,
					buttonText = L["Accept and Send Plan to Group"],
					callback = function()
						UpdatePlan(existingPlan, planDiff)
						local groupType = GetGroupType()
						if groupType then
							local receiptString =
								CreateUpdateReceiptString(newPlan.ID, senderFullName, L["was accepted"])
							AddOn:SendCommMessage(k.RequestPlanUpdateResponse, receiptString, groupType, nil, "NORMAL")
						end
						RemoveFromActivePlanReceiveMessageBoxDataIDs(uniqueID)
						Private.SendPlanToGroup()
					end,
				},
			},
			planDiff = planDiff,
			oldPlan = existingPlan,
			newPlan = newPlan,
		} --[[@as MessageBoxData]]
		tinsert(activePlanUpdateMessageBoxDataIDs, messageBoxData.ID)
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
				local receiptString = CreateReceiptString(plan.ID, senderFullName)
				AddOn:SendCommMessage(k.DistributePlanReceived, receiptString, groupType, nil, "NORMAL")
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
			local planID, originalPlanSender = ParseReceiptString(message)
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

	-- Executed after receiving the RequestPlanUpdate message.
	---@param message string
	local function HandleRequestPlanUpdateCommReceived(message, senderFullName)
		if UnitIsGroupLeader("player") then
			local package = StringToTable(message, false)
			if type(package == "table") then
				local groupType = GetGroupType()
				if groupType then
					local newPlan = PlanSerializer.DeserializePlan(package --[[@as table]])
					local existingPlanName, existingPlan = FindMatchingPlan(newPlan.ID)
					if existingPlanName and existingPlan then
						local planDiff = utilities.DiffPlans(existingPlan, newPlan)
						if planDiff.empty == true then
							local receiptString = CreateUpdateReceiptString(
								newPlan.ID,
								senderFullName,
								format("%s %s", L["was cancelled because"], L["the plan is already up-to-date"])
							)
							AddOn:SendCommMessage(k.RequestPlanUpdateResponse, receiptString, groupType, nil, "NORMAL")
						else
							CreateUpdateMessageBox(existingPlan, newPlan, planDiff, senderFullName)
						end
					else
						local receiptString = CreateUpdateReceiptString(
							newPlan.ID,
							senderFullName,
							format(
								"%s %s %s",
								L["was cancelled because"],
								senderFullName,
								L["does not have a plan with a matching ID"]
							)
						)
						AddOn:SendCommMessage(k.RequestPlanUpdateResponse, receiptString, groupType, nil, "NORMAL")
					end
				end
			end
		end
	end

	-- Executed after sending a RequestPlanUpdate message and receiving a response.
	---@param message string
	---@param playerFullName string
	local function HandleRequestPlanUpdateResponseCommReceived(message, playerFullName)
		if next(activeUpdatePlanIDsBeingSent) then
			local planID, senderFullName, context = ParseUpdateReceiptString(message)
			if senderFullName == playerFullName and activeUpdatePlanIDsBeingSent[planID] then
				activeUpdatePlanIDsBeingSent[planID].timer:Cancel()
				activeUpdatePlanIDsBeingSent[planID] = nil
				local existingPlanName = FindMatchingPlan(planID)
				if existingPlanName then
					LogMessage(format("%s '%s' %s.", L["Your request to update the plan"], existingPlanName, context))
				else
					LogMessage(format("%s '%s' %s.", L["Your request to update the plan"], L["Unknown"], context))
				end
			end
		end
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
		elseif prefix == k.DistributePlanReceived then
			HandlePlanReceivedCommReceived(message, playerFullName)
		elseif prefix == k.DistributeText then
			HandleDistributeTextCommReceived(message)
		elseif prefix == k.RequestPlanUpdate then
			HandleRequestPlanUpdateCommReceived(message, senderFullName)
		elseif prefix == k.RequestPlanUpdateResponse then
			HandleRequestPlanUpdateResponseCommReceived(message, playerFullName)
		end
	end

	do
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
							local planName = interfaceUpdater.FindMatchingPlan(planID)
							if count and planName then
								local playerString
								if count == 1 then
									playerString = L["player"]
								else
									playerString = L["players"]
								end
								LogMessage(
									format(
										"%s '%s' %s %d %s.",
										L["Plan"],
										planName,
										L["received by"],
										count,
										playerString
									)
								)
							end
							activePlanIDsBeingSent[planID] = nil
						end)
					end
				end
			end
		end

		local MaybeUpgradeAssignmentIDsOnSend = Private.assignmentUtilities.MaybeUpgradeAssignmentIDsOnSend

		function Private.SendPlanToGroup()
			local plans = AddOn.db.profile.plans
			local plan = plans[AddOn.db.profile.lastOpenPlan]
			local groupType = GetGroupType()
			if groupType then
				MaybeUpgradeAssignmentIDsOnSend(plan.assignments)
				local serializedPlan = PlanSerializer.SerializePlan(plan)
				plan.lastSyncedSnapShot = serializedPlan
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
				local exportString = TableToString(serializedPlan, false)
				LogMessage(format("%s '%s'...", L["Sending plan"], plan.name))
				AddOn:SendCommMessage(k.DistributePlan, exportString, groupType, nil, "BULK", CallbackProgress, plan.ID)
			end
		end
	end

	do
		---@param planID string
		---@param sent integer
		---@param total integer
		local function CallbackProgress(planID, sent, total)
			if total > 0 then
				local progress = sent / total
				if progress >= 1.0 then
					if activeUpdatePlanIDsBeingSent[planID] then
						activeUpdatePlanIDsBeingSent[planID].timer = NewTimer(120, function()
							local planName = interfaceUpdater.FindMatchingPlan(planID)
							if planName then
								LogMessage(
									format(
										"%s '%s' %s.",
										L["Request for proposed changes for plan"],
										planName,
										L["timed out"]
									)
								)
							end
							activeUpdatePlanIDsBeingSent[planID] = nil
						end)
					end
				end
			end
		end

		function Private.SendPlanToLeader()
			local plans = AddOn.db.profile.plans
			local plan = plans[AddOn.db.profile.lastOpenPlan]
			local groupType = GetGroupType()
			if groupType then
				if activeUpdatePlanIDsBeingSent[plan.ID] then
					LogMessage(
						format("%s '%s'.", L["Still waiting for response to proposed changes for plan"], plan.name)
					)
				else
					activeUpdatePlanIDsBeingSent[plan.ID] = { timer = nil, totalReceivedConfirmations = 0 }
					local exportString = TableToString(PlanSerializer.SerializePlan(plan), false)
					LogMessage(format("%s '%s'...", L["Proposing changes to plan"], plan.name))
					AddOn:SendCommMessage(
						k.RequestPlanUpdate,
						exportString,
						groupType,
						nil,
						"BULK",
						CallbackProgress,
						plan.ID
					)
				end
			end
		end
	end

	function Private.HandleSendPlanButtonClicked()
		if IsInGroup() or IsInRaid() then
			if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") then
				Private.SendPlanToGroup()
			end
		end
	end

	function Private.HandleProposeChangesButtonClicked()
		if IsInGroup() or IsInRaid() then
			if not UnitIsGroupLeader("player") then
				Private.SendPlanToLeader()
			end
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
	AddOn:RegisterComm(k.DistributePlanReceived)
	AddOn:RegisterComm(k.DistributeText)
	AddOn:RegisterComm(k.RequestPlanUpdate)
	AddOn:RegisterComm(k.RequestPlanUpdateResponse)
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
Private.testReferences.TableToString = TableToString
Private.testReferences.StringToTable = StringToTable
Private.testReferences.PlanSerializer = PlanSerializer
--@end-debug@
