local Type = "EPReminderLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local max = math.max
local xpcall = xpcall
local kDefaultSpacing = 10

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function SafeCall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type, function(content, children)
	---@cast content EPContainerContentFrame
	---@cast children table<integer, EPWidgetType>
	local paddingX, paddingY = kDefaultSpacing, kDefaultSpacing
	if content.spacing then
		paddingX = content.spacing.x
		paddingY = content.spacing.y
	end

	local sortAscending = content.sortAscending
	local orientation = content.orientation
	local width, height = 0.0, 0.0

	if orientation == "vertical" then
		local cumulativeHeight = 0.0
		if sortAscending then
			for i = 1, #children do
				local child = children[i]
				local frame = child.frame
				frame:ClearAllPoints()

				frame:SetPoint("BOTTOM", content, "BOTTOM", 0, cumulativeHeight)

				cumulativeHeight = cumulativeHeight + frame:GetHeight() + paddingY
				width = max(width, frame:GetWidth())
			end
		else
			for i = 1, #children do
				local child = children[i]
				local frame = child.frame
				frame:ClearAllPoints()

				frame:SetPoint("TOP", content, "TOP", 0, -cumulativeHeight)

				cumulativeHeight = cumulativeHeight + frame:GetHeight() + paddingY
				width = max(width, frame:GetWidth())
			end
		end
		height = cumulativeHeight - paddingY
		content:SetHeight(height)
		content:SetWidth(width)
	else
		local cumulativeWidth = 0.0
		if sortAscending then
			for i = 1, #children do
				local child = children[i]
				local frame = child.frame
				frame:ClearAllPoints()

				frame:SetPoint("LEFT", content, "LEFT", cumulativeWidth, 0)

				cumulativeWidth = cumulativeWidth + frame:GetWidth() + paddingX
				height = max(height, frame:GetHeight())
			end
		else
			for i = 1, #children do
				local child = children[i]
				local frame = child.frame
				frame:ClearAllPoints()

				frame:SetPoint("RIGHT", content, "RIGHT", -cumulativeWidth, 0)

				cumulativeWidth = cumulativeWidth + frame:GetWidth() + paddingX
				height = max(height, frame:GetHeight())
			end
		end
		width = cumulativeWidth - paddingX
	end

	content:SetHeight(height)
	content:SetWidth(width)

	SafeCall(content.obj.LayoutFinished, content.obj, width, height)
end)
