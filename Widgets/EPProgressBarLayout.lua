local Type = "EPProgressBarLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local defaultSpacing = 10

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function SafeCall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type, function(content, children)
	local maxWidth = 0.0
	local paddingY = defaultSpacing
	if content.spacing then
		paddingY = content.spacing.y
	end
	local cumulativeHeight = 0.0
	local sortAscending = content.sortAscending

	if sortAscending then
		for i = 1, #children do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			frame:SetPoint("BOTTOM", content, "BOTTOM", 0, cumulativeHeight)

			cumulativeHeight = cumulativeHeight + frame:GetHeight() + paddingY
			maxWidth = max(maxWidth, frame:GetWidth())
		end
	else
		for i = 1, #children do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			frame:SetPoint("TOP", content, "TOP", 0, -cumulativeHeight)

			cumulativeHeight = cumulativeHeight + frame:GetHeight() + paddingY
			maxWidth = max(maxWidth, frame:GetWidth())
		end
	end

	local totalHeight = cumulativeHeight - paddingY
	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	SafeCall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
