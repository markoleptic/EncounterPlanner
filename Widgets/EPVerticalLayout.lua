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

	local hitFirstNonSpacer = false
	local spacers = {}
	for i = 1, #children do
		local child = children[i]
		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()

		if child.type == "EPSpacer" and child.fillSpace then
			tinsert(spacers, i)
		else
			if i > 1 then
				if alignment == "default" then
					frame:SetPoint("TOPLEFT", children[i - 1].frame, "BOTTOMLEFT", 0, -paddingY)
				elseif alignment == "center" then
					frame:SetPoint("TOP", children[i - 1].frame, "BOTTOM", 0, -paddingY)
				end
			else
				if alignment == "default" then
					frame:SetPoint("TOPLEFT", content, "TOPLEFT")
				elseif alignment == "center" then
					frame:SetPoint("TOP", content, "TOP")
				end
			end

			if child.width == "fill" then
				frame:SetPoint("RIGHT", content)
			elseif child.width == "relative" then
				child:SetWidth(contentWidth * child.relWidth)
			end

			if child.height == "fill" and i == #children then
				frame:SetPoint("BOTTOM", content)
			end

			if child.DoLayout then
				child:DoLayout()
			end

			local childHeight = frame:GetHeight()
			totalHeight = totalHeight + childHeight
			if hitFirstNonSpacer == true then
				totalHeight = totalHeight + paddingY
			end
			maxWidth = max(maxWidth, frame:GetWidth())
			hitFirstNonSpacer = true
		end
	end

	if #spacers > 0 then
		local remainingHeight = content:GetHeight() or 0
		remainingHeight = remainingHeight - totalHeight
		local splitHeight = remainingHeight / #spacers

		for _, i in pairs(spacers) do
			local spacer = children[i]
			spacer.frame:ClearAllPoints()
			if remainingHeight > 1 then
				spacer.frame:SetHeight(splitHeight)
			end
			if i == 1 then
				spacer.frame:SetPoint("TOPLEFT", content, "TOPLEFT")
			else
				spacer.frame:SetPoint("TOPLEFT", children[i - 1].frame, "BOTTOMLEFT")
			end
			if i ~= #children then
				children[i + 1].frame:SetPoint("TOPLEFT", spacer.frame, "BOTTOMLEFT")
			end
		end
	end

	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	safecall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
