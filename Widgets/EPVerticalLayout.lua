local Type   = "EPVerticalLayout"
local AceGUI = LibStub("AceGUI-3.0")

local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type,
	function(content, children)
		local totalHeight = 0
		local maxWidth = 0
		local paddingY = 10

		for i = 1, #children do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if i > 1 then
				frame:SetPoint("TOPLEFT", children[i - 1].frame, "BOTTOMLEFT", 0, -paddingY)
			else
				frame:SetPoint("TOPLEFT", content, "TOPLEFT")
			end

			local childHeight
			if child.height == "relative" then
				childHeight = (content:GetHeight() * child.relHeight)
				child:SetHeight(childHeight)
			else
				childHeight = frame:GetHeight()
			end

			totalHeight = totalHeight + childHeight + (i > 1 and paddingY or 0)
			maxWidth = math.max(maxWidth, frame:GetWidth())

			if child.DoLayout then
				child:DoLayout()
			end
		end

		content:SetHeight(totalHeight)
		content:SetWidth(maxWidth)

		safecall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
	end)
