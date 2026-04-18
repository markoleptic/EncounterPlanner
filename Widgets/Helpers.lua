local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Helpers
Private.helpers = {}

---@class Helpers
local Helpers = Private.helpers

---@param container EPContainer
function Helpers.SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		if child.type == "EPButton" then
			maxWidth = max(maxWidth, child.frame:GetWidth())
		end
	end
	for _, child in ipairs(container.children) do
		if child.type == "EPButton" then
			child:SetWidth(maxWidth)
		end
	end
end
