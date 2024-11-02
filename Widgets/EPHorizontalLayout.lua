local Type = "EPHorizontalLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type, function(content, children)
	local totalWidth = 0
	local contentHeight = content.height or content:GetHeight() or 0
	local maxHeight = 0
	local paddingX = (content.spacing and content.spacing.x) or 10

	for i = 1, #children do
		local child = children[i]
		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if i > 1 then
			frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", paddingX, 0)
		else
			frame:SetPoint("TOPLEFT", content, "TOPLEFT")
		end

		if child.height == "fill" then
			child:SetHeight(contentHeight)
			frame:SetPoint("BOTTOM", content)
		elseif child.width == "relative" then
			child:SetHeight(contentHeight * child.relWidth)
		end

		local childWidth = frame:GetWidth()
		totalWidth = totalWidth + childWidth + (i > 1 and paddingX or 0)
		maxHeight = math.max(maxHeight, frame:GetHeight())

		if child.DoLayout then
			child:DoLayout()
		end
	end

	content:SetHeight(maxHeight)
	content:SetWidth(totalWidth)

	safecall(content.obj.LayoutFinished, content.obj, totalWidth, maxHeight)
end)
