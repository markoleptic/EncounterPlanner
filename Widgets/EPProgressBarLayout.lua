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
	local totalHeight = 0
	local contentWidth = content.width or content:GetWidth() or 0
	local maxWidth = 0
	local paddingY = defaultSpacing
	if content.spacing then
		paddingY = content.spacing.y
	end

	for i = 1, #children do
		local child = children[i]
		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if i > 1 then
			frame:SetPoint("TOP", children[i - 1].frame, "BOTTOM", 0, -paddingY)
		else
			frame:SetPoint("TOP", content, "TOP")
		end

		if child.width == "fill" then
			frame:SetPoint("RIGHT", content)
		elseif child.width == "relative" then
			child:SetWidth(contentWidth * child.relWidth)
		end

		if totalHeight > 0 then
			totalHeight = totalHeight + paddingY
		end
		totalHeight = totalHeight + frame:GetHeight()
		maxWidth = max(maxWidth, frame:GetWidth())
	end

	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	SafeCall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
