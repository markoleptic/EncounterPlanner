---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn
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

---@param assignment Assignment|CombatLogEventAssignment|TimedAssignment
---@return table
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
	end
	return required
end

---@param data table
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
	if data[8] then
		assignment.combatLogEventType = data[6]
		assignment.combatLogEventSpellID = data[7]
		assignment.spellCount = data[8]
		return Private.classes.CombatLogEventAssignment:New(assignment)
	else
		return Private.classes.TimedAssignment:New(assignment)
	end
end

---@param plan Plan
---@return table<integer|string|table>
local function SerializePlan(plan)
	local required = {
		plan.name,
		plan.bossName,
		plan.dungeonEncounterID,
		plan.instanceID,
		{},
		{},
	}
	local assignments = required[5]
	for _, assignment in ipairs(plan.assignments) do
		assignments[#assignments + 1] = SerializeAssignment(assignment)
	end
	local roster = required[6]
	for name, rosterInfo in pairs(plan.roster) do
		roster[#roster + 1] = { name, rosterInfo.class or "", rosterInfo.role or "", rosterInfo.classColoredName or "" }
	end
	return required
end

---@param data table
---@return Plan
local function DeserializePlan(data)
	local plan = {
		name = data[1],
		bossName = data[2],
		dungeonEncounterID = data[3],
		instanceID = data[4],
	}
	plan.assignments = {}
	for _, assignment in ipairs(data[5]) do
		plan.assignments[#plan.assignments + 1] = DeserializeAssignment(assignment)
	end
	plan.roster = {}
	for _, entry in ipairs(data[6]) do
		plan.roster[entry[1]] = { class = entry[2], role = entry[3], classColoredName = entry[4] }
	end
	plan.content = {}
	plan.collapsed = {}
	plan.remindersEnabled = true
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
		return "Error decoding."
	end

	local decompressed = LibDeflate:DecompressZlib(decoded)
	if not decompressed then
		return "Error decompressing."
	end

	---@diagnostic disable-next-line: undefined-field
	local deserialized = Private.Decode(decompressed)
	return deserialized
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
			local plans = AddOn.db.profile.plans
			plans[package.name] = plan -- TODO: Consider asking about overriding
			interfaceUpdater.UpdateFromNote(package.name)
			local noteDropdown = Private.mainFrame.noteDropdown
			if noteDropdown then
				noteDropdown:AddItem(package.name, package.name, "EPDropdownItemToggle")
				noteDropdown:SetValue(package.name)
			end
			local renameNoteLineEdit = Private.mainFrame.noteLineEdit
			if renameNoteLineEdit then
				renameNoteLineEdit:SetText(package.name)
			end
			Private.mainFrame.planReminderEnableCheckBox:SetChecked(plans[package.name].remindersEnabled)
		elseif type(package) == "string" then
			print(format("%s: ", AddOnName, package))
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
		print(sent, total)
	end
	AddOn:SendCommMessage("EPDistributePlan", export, inGroup, nil, "BULK", callback)
end
