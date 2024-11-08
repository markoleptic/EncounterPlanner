local Type = "EPVerticalLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local defaultSpacing = 10

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type, function(content, children)
	local totalHeight = 0
	local contentWidth = content.width or content:GetWidth() or 0
	local maxWidth = 0
	local alignment = "default"
	local paddingY = defaultSpacing
	if content.spacing then
		paddingY = content.spacing.y
	end
	if content.alignment then
		alignment = content.alignment
	end

	for i = 1, #children do
		local child = children[i]
		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if i > 1 then
			if alignment == "default" then
				frame:SetPoint("TOPLEFT", children[i - 1].frame, "BOTTOMLEFT", 0, -paddingY)
				frame:SetPoint("RIGHT", content)
			elseif alignment == "center" then
				frame:SetPoint("TOP", children[i - 1].frame, "BOTTOM", 0, -paddingY)
			end
		else
			if alignment == "default" then
				frame:SetPoint("TOPLEFT", content, "TOPLEFT")
				frame:SetPoint("RIGHT", content)
			elseif alignment == "center" then
				frame:SetPoint("TOP", content, "TOP")
			end
		end

		if child.width == "fill" then
			--child:SetWidth(contentWidth)
			frame:SetPoint("RIGHT", content)
			if child.DoLayout then
				child:DoLayout()
			end
		elseif child.width == "relative" then
			child:SetWidth(contentWidth * child.relWidth)
			if child.DoLayout then
				child:DoLayout()
			end
		end

		local childHeight = frame:GetHeight()
		totalHeight = totalHeight + childHeight + (i > 1 and paddingY or 0)
		maxWidth = max(maxWidth, frame:GetWidth())
	end

	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	safecall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
