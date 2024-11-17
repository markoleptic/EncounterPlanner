local Type = "EPHorizontalLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local pairs = pairs
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
	local totalWidth = 0
	local contentHeight = content.height or content:GetHeight() or 0
	local maxHeight = 0
	local paddingX = defaultSpacing
	local alignment = "default"
	if content.spacing then
		paddingX = content.spacing.x
	end
	if content.alignment then
		alignment = content.alignment
	end

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
				if i == #children then
					if alignment == "default" then
						frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", paddingX, 0)
					elseif alignment == "center" then
						--frame:SetPoint("LEFT", children[i - 1].frame, "RIGHT", paddingX, 0)
						frame:SetPoint("RIGHT", content, "RIGHT")
					end
				else
					if alignment == "default" then
						frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", paddingX, 0)
					elseif alignment == "center" then
						frame:SetPoint("LEFT", children[i - 1].frame, "RIGHT", paddingX, 0)
					end
				end
			else
				if alignment == "default" then
					frame:SetPoint("TOPLEFT", content, "TOPLEFT")
				elseif alignment == "center" then
					frame:SetPoint("LEFT", content, "LEFT")
				end
				-- if i == #children then
				-- 	frame:SetPoint("RIGHT", content, "RIGHT")
				-- end
			end

			if child.height == "fill" then
				--child:SetWidth(contentWidth)
				frame:SetPoint("BOTTOM", content)
			elseif child.height == "relative" then
				child:SetHeight(contentHeight * child.relHeight)
			end

			if child.DoLayout then
				child:DoLayout()
			end

			local childWidth = frame:GetWidth()
			totalWidth = totalWidth + childWidth
			if i > 1 then
				totalWidth = totalWidth + paddingX
			end
			maxHeight = max(maxHeight, frame:GetHeight())
		end
	end
	totalWidth = totalWidth - (#spacers * paddingX)
	if #spacers > 0 then
		local remainingWidth = content:GetWidth() or 0
		remainingWidth = remainingWidth - totalWidth
		local splitWidth = remainingWidth / #spacers

		for _, i in pairs(spacers) do
			local spacer = children[i]
			spacer.frame:ClearAllPoints()
			if remainingWidth > 1 then
				spacer.frame:SetWidth(splitWidth)
			end
			if i == 1 then
				spacer.frame:SetPoint("TOPLEFT", content, "TOPLEFT")
			else
				spacer.frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT")
			end
			if i == #children then
				--spacer.frame:SetPoint("RIGHT", content, "RIGHT")
			else
				children[i + 1].frame:SetPoint("TOPLEFT", spacer.frame, "TOPRIGHT")
			end
		end
	end

	content:SetHeight(maxHeight)
	content:SetWidth(totalWidth)

	safecall(content.obj.LayoutFinished, content.obj, totalWidth, maxHeight)
end)
