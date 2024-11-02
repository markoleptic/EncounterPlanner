local Type = "EPContentFrameLayout"

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
	local height = 0
	local width = content.width or content:GetWidth() or 0
	for i = 1, #children do
		local child = children[i]

		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if i == 1 then
			frame:SetPoint("TOPLEFT", content)
		elseif i == 2 then
			frame:SetPoint("TOPLEFT", children[1].frame, "TOPRIGHT", 0, 0)
			frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
		elseif i == 3 then
			frame:SetPoint("TOPLEFT", children[2].frame, "BOTTOMLEFT", 6, 0)
		end

		if child.width == "fill" then
			child:SetWidth(width)
			frame:SetPoint("RIGHT", content)

			if child.DoLayout then
				child:DoLayout()
			end
		elseif child.width == "relative" then
			child:SetWidth(width * child.relWidth)

			if child.DoLayout then
				child:DoLayout()
			end
		end
	end

	if #children >= 1 then
		height = math.max(height, children[1].frame.height or children[1].frame:GetHeight() or 0)
	end
	if #children >= 2 then
		height = math.max(height, children[2].frame.height or children[2].frame:GetHeight() or 0)
	end
	if #children >= 3 then
		height = math.max(
			height,
			(children[2].frame.height or children[2].frame:GetHeight() or 0)
				+ (children[3].frame.height or children[3].frame:GetHeight())
		)
	end
	safecall(content.obj.LayoutFinished, content.obj, nil, height)
end)
