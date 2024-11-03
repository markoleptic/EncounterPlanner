local Type = "EPContentFrameLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local listTimelinePadding = 6
local topContainerPadding = 12

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout(Type, function(content, children)
	local width = content.width or content:GetWidth() or 0

	for i = 1, #children do
		local child = children[i]

		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if i == 1 then -- top container
			frame:SetPoint("TOPLEFT", content, "TOPLEFT")
			frame:SetPoint("TOPRIGHT", content, "TOPRIGHT")
		elseif i == 2 then -- list
			frame:SetPoint("TOPLEFT", children[1].frame, "BOTTOMLEFT", 0, -topContainerPadding)
			frame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT")
		elseif i == 3 then -- timeline
			frame:SetPoint("TOPLEFT", children[2].frame, "TOPRIGHT", listTimelinePadding, 0)
		end

		if child.width == "fill" then
			child:SetWidth(width)
			frame:SetPoint("RIGHT", content)
		elseif child.width == "relative" then
			child:SetWidth(width * child.relWidth)
		end

		if child.DoLayout then
			child:DoLayout()
		end
	end

	local height = 0
	if #children >= 1 then
		local topContainerHeight = children[1].frame.height or children[1].frame:GetHeight() or 0
		height = max(height, topContainerHeight)
		if #children >= 2 then
			local listHeight = children[2].frame.height or children[2].frame:GetHeight() or 0
			height = max(height, listHeight + topContainerHeight + topContainerPadding)
			if #children >= 3 then
				local timelineHeight = children[3].frame.height or children[3].frame:GetHeight() or 0
				height = max(height, timelineHeight + topContainerHeight + topContainerPadding)
			end
		end
	end

	safecall(content.obj.LayoutFinished, content.obj, nil, height)
end)
