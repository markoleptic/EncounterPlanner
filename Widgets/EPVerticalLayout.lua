local Type = "EPVerticalLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local tinsert = table.insert
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
	local contentWidth = content:GetWidth() or 0
	local maxWidth = 0
	local paddingY = defaultSpacing
	if content.spacing and content.spacing.y then
		paddingY = content.spacing.y
	end

	local spacers = {}
	local childCount = #children

	if content.alignment == "center" then
		for i = 1, childCount do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if child.type == "EPSpacer" and child.fillSpace then
				tinsert(spacers, i)
			else
				if i > 1 then
					frame:SetPoint("TOP", children[i - 1].frame, "BOTTOM", 0, -paddingY)
				else
					frame:SetPoint("TOP", content, "TOP")
				end

				if child.width == "fill" then
					frame:SetPoint("LEFT", content)
					frame:SetPoint("RIGHT", content)
				elseif child.width == "relative" then
					child:SetWidth(contentWidth * child.relWidth)
				end
				if child.height == "fill" and i == childCount then
					frame:SetPoint("BOTTOM", content)
				end

				if child.DoLayout then
					child:DoLayout()
				end

				if totalHeight > 0 then
					totalHeight = totalHeight + paddingY
				end
				totalHeight = totalHeight + frame:GetHeight()
				maxWidth = max(maxWidth, frame:GetWidth())
			end
		end
	else
		for i = 1, childCount do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if child.type == "EPSpacer" and child.fillSpace then
				tinsert(spacers, i)
			else
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
				if child.height == "fill" and i == childCount then
					frame:SetPoint("BOTTOM", content)
				end

				if child.DoLayout then
					child:DoLayout()
				end

				if totalHeight > 0 then
					totalHeight = totalHeight + paddingY
				end

				totalHeight = totalHeight + frame:GetHeight()
				maxWidth = max(maxWidth, frame:GetWidth())
			end
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
			if i ~= childCount then
				children[i + 1].frame:SetPoint("TOPLEFT", spacer.frame, "BOTTOMLEFT")
			end
		end
	end

	content:SetHeight(totalHeight)
	content:SetWidth(maxWidth)

	SafeCall(content.obj.LayoutFinished, content.obj, maxWidth, totalHeight)
end)
