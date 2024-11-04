---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class OptionsModule : AceModule
local OptionsModule = Private.addOn.optionsModule

local LibStub = LibStub
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

function OptionsModule:OnInitialize()
	self:CreateOptions()
end

function OptionsModule:CreateOptions()
	ACR:RegisterOptionsTable(AddOnName, self:GetOptions(), true)
	ACD:SetDefaultSize(AddOnName, 700, 500)
	ACD:AddToBlizOptions(AddOnName)
end

function OptionsModule:GetOptions()
	local options = {
		name = AddOnName,
		type = "group",
		childGroups = "tab",
		args = {},
	}
	return options
end

function OptionsModule:OpenOptions()
	ACD:Open(AddOnName)
end
