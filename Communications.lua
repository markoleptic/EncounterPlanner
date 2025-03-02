local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
local Encode, Decode = Private.Encode, Private.Decode

---@class Constants
local constants = Private.constants
local kDistributePlan = constants.communications.kDistributePlan
local kPlanReceived = constants.communications.kPlanReceived
local kDistributeText = constants.communications.kDistributeText

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

local format = format

local LibDeflate = LibStub("LibDeflate")
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

local planSerializer = {}
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
	function planSerializer.SerializePlan(plan)
		local serializedPlan = {}
		serializedPlan[1] = plan.ID
		serializedPlan[2] = plan.name
		serializedPlan[3] = plan.dungeonEncounterID
		serializedPlan[4] = plan.instanceID
		serializedPlan[5] = {}
		local assignments = serializedPlan[5]
		for _, assignment in ipairs(plan.assignments) do
			assignments[#assignments + 1] = SerializeAssignment(assignment)
		end
		serializedPlan[6] = {}
		local roster = serializedPlan[6]
		for name, rosterInfo in pairs(plan.roster) do
			roster[#roster + 1] = SerializeRosterEntry(name, rosterInfo)
		end
		serializedPlan[7] = plan.content
		return serializedPlan
	end

	---@param serializedPlan SerializedPlan
	---@return Plan
	function planSerializer.DeserializePlan(serializedPlan)
		local ID = serializedPlan[1]
		local name = serializedPlan[2]
		local plan = Plan:New({}, name, ID)
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
end

---@param inString string
---@param forChat boolean
---@param level integer|nil
---@return string
local function CompressString(inString, forChat, level)
	local compressed = LibDeflate:CompressZlib(inString, configForDeflate[level] or nil)
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

	local deserialized = Decode(decompressed)
	return deserialized
end

---@param plan Plan
---@param fullName string
local function ImportPlan(plan, fullName)
	local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
	local existingPlanName, existingPlan = FindMatchingPlan(plan.ID)

	local importInfo = ""
	if existingPlanName and existingPlan then -- Replace matching plan with imported plan
		plans[plan.name] = plan
		if existingPlanName ~= plan.name then
			plans[existingPlanName] = nil
		end
		if AddOn.db.profile.lastOpenPlan == existingPlanName then -- Replace last open if it was removed
			AddOn.db.profile.lastOpenPlan = plan.name
		end
		existingPlan = nil
		importInfo = format("%s '%s'", L["Updated matching plan"], existingPlanName)
	else -- Create a unique plan name if necessary
		if plans[plan.name] then
			plan.name = CreateUniquePlanName(plans, plan.name)
		end
		plans[plan.name] = plan
		importInfo = format("%s '%s'", L["Imported plan as"], plan.name)
	end

	LogMessage(format("%s '%s' %s %s", L["Received plan"], plan.name, L["from"], fullName))
	LogMessage(importInfo)

	if IsInRaid() then
		local changedPrimaryPlan = SetDesignatedExternalPlan(plans, plan)
		if changedPrimaryPlan then
			LogMessage(format("%s '%s'", L["Changed the Designated External Plan to"], plan.name))
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
			UpdateFromPlan(plan) -- Only update if current plan is the imported plan
		else
			AddPlanToDropdown(plan, false)
		end
	end
end

local commObject = {}
do
	local CreateMessageBox = interfaceUpdater.CreateMessageBox
	local IsInGroup, IsInRaid = IsInGroup, IsInRaid
	local next = next
	local RemoveFromMessageQueue = interfaceUpdater.RemoveFromMessageQueue
	local strsplittable = strsplittable
	local UnitIsGroupAssistant, UnitIsGroupLeader = UnitIsGroupAssistant, UnitIsGroupLeader
	local UpdateRosterDataFromGroup = utilities.UpdateRosterDataFromGroup
	local wipe = wipe

	local activePlanIDsBeingSent = {} ---@type table<string, {timer:FunctionContainer|nil, totalReceivedConfirmations: integer}>
	local activePlanReceiveMessageBoxDataIDs = {} ---@type table<integer, string>

	function commObject.Reset()
		for _, ID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			RemoveFromMessageQueue(ID)
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
		for index, ID in ipairs(activePlanReceiveMessageBoxDataIDs) do
			if ID == IDToRemove then
				tremove(activePlanReceiveMessageBoxDataIDs, index)
				break
			end
		end
	end

	---@param plan Plan
	---@param sender string
	local function CreateImportMessageBox(plan, sender)
		local ID = Private.GenerateUniqueID()
		local messageBoxData = {
			ID = ID,
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
				RemoveFromActiveMessageBoxDataIDs(ID)
			end,
			rejectButtonText = L["Reject"],
			rejectButtonCallback = function()
				RemoveFromActiveMessageBoxDataIDs(ID)
			end,
			buttonsToAdd = {
				{
					beforeButtonIndex = 2,
					buttonText = L["Accept without Trusting"],
					callback = function()
						if plan then
							ImportPlan(plan, sender)
						end
						RemoveFromActiveMessageBoxDataIDs(ID)
					end,
				},
			},
		} --[[@as MessageBoxData]]
		tinsert(activePlanReceiveMessageBoxDataIDs, messageBoxData.ID)
		CreateMessageBox(messageBoxData, true)
	end

	---@param package table
	---@param sender string
	local function HandleDistributePlanCommReceived(package, sender)
		local plan = planSerializer.DeserializePlan(package --[[@as table]])
		local groupType = GetGroupType()
		if groupType then
			local returnMessage = CompressString(format("%s,%s", plan.ID, sender), false)
			AddOn:SendCommMessage(kPlanReceived, returnMessage, groupType, nil, "NORMAL")
		end
		local foundTrustedCharacter = false
		for _, trustedCharacter in ipairs(AddOn.db.profile.trustedCharacters) do
			if sender == trustedCharacter then
				foundTrustedCharacter = true
				break
			end
		end
		if foundTrustedCharacter then
			ImportPlan(plan, sender)
		else
			CreateImportMessageBox(plan, sender)
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
		local playerName, playerRealm = UnitFullName("player")
		local playerFullName = format("%s-%s", playerName, playerRealm)
		if not realm or realm:len() < 3 then
			realm = playerRealm
		end
		local fullName = format("%s-%s", name, realm)

		--[===[@non-debug@
		if fullName == playerName .. "-" .. playerRealm then
			return
		end
        --@end-non-debug@]===]

		if prefix == kDistributePlan then
			local package = StringToTable(message, false)
			if type(package == "table") then
				HandleDistributePlanCommReceived(package --[[@as table]], fullName)
			end
		elseif prefix == kPlanReceived and next(activePlanIDsBeingSent) then
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
		elseif prefix == kDistributeText then
			local package = StringToTable(message, false)
			self.db.profile.activeText = package
		end
	end

	---@param planID string
	---@param sent integer
	---@param total integer
	local function CallbackProgress(planID, sent, total)
		local progress = sent / total
		if progress >= 1.0 then
			LogMessage(L["Plan sent"] .. ".")
			if activePlanIDsBeingSent[planID] then
				activePlanIDsBeingSent[planID].timer = C_Timer.NewTimer(10, function()
					local count = activePlanIDsBeingSent[planID].totalReceivedConfirmations
					local playerString = count == 1 and L["player"] or L["players"]
					LogMessage(format("%s %d %s.", L["Plan received by"], count, playerString))
					activePlanIDsBeingSent[planID] = nil
				end)
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
					LogMessage(format("%s '%s'", L["Changed the Designated External Plan to"], plan.name))
				end
			end
			if activePlanIDsBeingSent[plan.ID] then
				activePlanIDsBeingSent[plan.ID].timer:Cancel()
				activePlanIDsBeingSent[plan.ID].timer = nil
			end
			activePlanIDsBeingSent[plan.ID] = { timer = nil, totalReceivedConfirmations = 0 }
			local exportString = TableToString(planSerializer.SerializePlan(plan), false)
			LogMessage(format("%s '%s'...", L["Sending plan"], plan.name))
			AddOn:SendCommMessage(kDistributePlan, exportString, groupType, nil, "BULK", CallbackProgress, plan.ID)
		end
	end

	---@param bossDungeonEncounterID integer
	function Private.SendTextToGroup(bossDungeonEncounterID)
		local plans = AddOn.db.profile.plans --[[@as table<integer, Plan>]]
		local primaryPlan --[[@as Plan]]
		for _, plan in pairs(plans) do
			if plan.dungeonEncounterID == bossDungeonEncounterID and plan.isPrimaryPlan then
				primaryPlan = plan
				break
			end
		end
		local groupType = GetGroupType()
		if groupType then
			local exportString = TableToString(primaryPlan.content, false)
			AddOn:SendCommMessage(kDistributeText, exportString, groupType, nil, "NORMAL")
		end
	end
end

function Private:RegisterCommunications()
	AddOn:RegisterComm(AddOnName)
	AddOn:RegisterComm(kDistributePlan)
	AddOn:RegisterComm(kPlanReceived)
	AddOn:RegisterComm(kDistributeText)
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
do
	---@class BossUtilities
	local bossUtilities = Private.bossUtilities
	---@class Plan
	local Plan = Private.classes.Plan
	---@class Test
	local test = Private.test
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	local ChangePlanBoss = utilities.ChangePlanBoss
	local RemoveTabs = testUtilities.RemoveTabs
	local SplitStringIntoTable = utilities.SplitStringIntoTable
	local TestEqual = testUtilities.TestEqual
	local UpdateRosterFromAssignments = utilities.UpdateRosterFromAssignments

	do
		-- cSpell:disable
		local text = [[
            {time:0:16,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:1}{spell:442432}|cffAB0E0EDosage Hit|r - Duck {spell:421453}  Brockx {spell:97462}  Majablast {spell:108281}
            {time:0:29,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Sephx {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:46,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Poglizard {spell:359816}
            {time:0:59,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:06,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374968}  Draugmentor {spell:374227}  Gun {spell:77764}  Vodkabro {spell:192077}
            {time:1:13,SCS:442432:1}{spell:442432}|cffAB0E0EDosage Hit|r - Duck {spell:451234}  Stranko {spell:97462}
            {time:1:26,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}
            {time:1:29,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:1}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:374968}  Skorke {spell:77764}
            {time:1:59,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:06,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Poglizard {spell:363534}
            {time:2:30,SCS:442432:1}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:30,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - class:Mage {spell:414660}
            {time:2:46,SCS:442432:1}{spell:442432}|cffFF6666Volatile Concoction|r - Poglizard {spell:359816}
            {time:2:52,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Duck {spell:246287}
            {time:2:57,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Vodkabro {spell:114049}
            {time:3:02,SCS:442432:1}{spell:442432}|cff8B4513Ingest Black Blood|r - Vodkabro {spell:108280}
            {time:0:16,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Majablast {spell:108281}
            {time:0:26,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:421453}
            {time:0:29,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:59,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:06,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}
            {time:1:06,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374227}  Draugmentor {spell:374968}  Gun {spell:77764}  Vodkabro {spell:192077}
            {time:1:13,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Brockx {spell:97462}  Vodkabro {spell:98008}
            {time:1:29,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:2}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:374968}  Skorke {spell:77764}
            {time:2:00,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:03,SCS:442432:2}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:451234}  Stranko {spell:97462}
            {time:2:30,SCS:442432:2}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:46,SCS:442432:2}{spell:442432}|cffFF6666Volatile Concoction|r - Poglizard {spell:359816}
            {time:2:52,SCS:442432:2}{spell:442432}|cff8B4513Ingest Black Blood|r - Duck {spell:246287}  Vodkabro {spell:108280}  class:Mage {spell:414660}
            {time:3:02,SCS:442432:2}{spell:442432}|cff8B4513Ingest Black Blood|r - Poglizard {spell:363534}  Vodkabro {spell:114049}
            {time:0:16,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Majablast {spell:192077}  Skorke {spell:77764}
            {time:0:23,SCS:442432:3}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:421453}  {everyone} {text}{Personals{/text}
            {time:0:29,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:0:59,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}
            {time:1:06,SCS:442432:3}{spell:442432}|cffFF6666Volatile Concoction|r - Duck {spell:451234}  Draugmentor {spell:374227}
            {time:1:06,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Draugmentor {spell:374968}  Gun {spell:77764}  Vodkabro {spell:192077}  {everyone} {text}Spread for Webs{/text}
            {time:1:09,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:1:56,SCS:442432:3}{spell:442432}|cffFFFF00Experimental Dosage|r - Poglizard {spell:359816}  Poglizard {spell:374968}  Skorke {spell:77764}
            {time:1:57,SCS:442432:3}{spell:442432}|cffCC0000Dosage Hit|r - Duck {spell:451234}  Brockx {spell:97462}
            {time:2:26,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
            {time:2:27,SCS:442432:3}{spell:442432}|cffFF6666Volatile Concoction|r - Stranko {spell:97462}
            {time:2:56,SCS:442432:3}{spell:442432}|cff0000FFSticky Web|r - Pogdog @Lbkt {spell:1044}  Sarys @Poglizard {spell:1044}  {everyone} {text}Spread for Webs{/text}
        ]]
		-- cSpell:enable

		function test.EncodeDecodePlan()
			local plan = Plan:New({}, "Test")
			local textTable = RemoveTabs(SplitStringIntoTable(text))
			local bossDungeonEncounterID = Private.ParseNote(plan, textTable, true) --[[@as integer]]
			plan.dungeonEncounterID = bossDungeonEncounterID
			ChangePlanBoss({ [plan.name] = plan }, plan.name, plan.dungeonEncounterID)
			UpdateRosterFromAssignments(plan.assignments, plan.roster)

			local export = TableToString(planSerializer.SerializePlan(plan), false)
			local package = StringToTable(export, false)
			local deserializedPlan = planSerializer.DeserializePlan(package --[[@as table]])
			deserializedPlan.isPrimaryPlan = true
			TestEqual(plan, deserializedPlan, "Plan equals serialized plan")

			return "EncodeDecodePlan"
		end
	end
end
--@end-debug@
