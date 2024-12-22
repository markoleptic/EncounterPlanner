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
	local growUp = content.growUp or false
	local maxWidth = 0
	local paddingY = defaultSpacing
	if content.spacing then
		paddingY = content.spacing.y
	end

	local childCount = #children
	if growUp then
		for i = #children, 1, -1 do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if i < childCount then
				frame:SetPoint("TOPLEFT", children[i + 1].frame, "BOTTOMLEFT", 0, -paddingY)
			else
				frame:SetPoint("TOPLEFT", content, "TOPLEFT")
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
	else
		for i = 1, childCount do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if i > 1 then
				frame:SetPoint("TOPLEFT", children[i - 1].frame, "BOTTOMLEFT", 0, -paddingY)
			else
				frame:SetPoint("TOPLEFT", content, "TOPLEFT")
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
	end
	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	SafeCall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
