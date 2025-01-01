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
local format = format
local LibStub = LibStub
local LibDeflate = LibStub("LibDeflate")
local getmetatable, setmetatable = getmetatable, setmetatable
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local print = print
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
			local assignments = package.assignments
			utilities.SetAssignmentMetaTables(assignments)
			local plans = AddOn.db.profile.plans
			plans[package.name] = package -- TODO: Consider asking about overriding
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
		DevTool:AddData(package)
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
	local metaTables = {}
	for index, assignment in ipairs(plan.assignments) do
		metaTables[index] = getmetatable(assignment)
		setmetatable(assignment, nil)
		assignment.New = nil
	end
	local export = TableToString(plan, false)
	for index, assignment in ipairs(plan.assignments) do
		setmetatable(assignment, metaTables[index])
	end

	local function callback(callbackArg, sent, total)
		print(sent, total)
	end
	AddOn:SendCommMessage("EPDistributePlan", export, inGroup, nil, "BULK", callback)
end
