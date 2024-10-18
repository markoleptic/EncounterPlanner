---@type string
local AddOnName = ...
---@using Private
---@class Private
local Private = select(2, ...)
---@class OptionsModule : AceModule
local OptionsModule = Private.AddOn.OptionsModule
local ACR = Private.Libs.ACR
local ACD = Private.Libs.ACD

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
		args = {
		}
	}
	return options
end

function OptionsModule:OpenOptions()
	ACD:Open(AddOnName)
end
