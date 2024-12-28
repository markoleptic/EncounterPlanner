local Type = "EPHorizontalLayout"

local AceGUI = LibStub("AceGUI-3.0")
local geterrorhandler = geterrorhandler
local xpcall = xpcall
local max = math.max
local pairs = pairs
local tinsert = tinsert
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
	local contentWidth = content:GetWidth()
	local totalWidth = 0
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
	local childCount = #children

	if alignment == "center" then
		for i = 1, childCount do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if child.type == "EPSpacer" and child.fillSpace then
				tinsert(spacers, i)
			else
				if i > 1 then
					if i == childCount then
						if child.selfAlignment == "right" then
							frame:SetPoint("RIGHT", content, "RIGHT")
						else
							frame:SetPoint("RIGHT", content, "RIGHT")
						end
					else
						frame:SetPoint("LEFT", children[i - 1].frame, "RIGHT", paddingX, 0)
					end
				else
					frame:SetPoint("LEFT", content, "LEFT")
				end

				if child.width == "fill" and i == childCount then
					frame:SetPoint("RIGHT", content)
				end
				if child.height == "fill" then
					frame:SetPoint("BOTTOM", content)
				end

				if child.DoLayout then
					child:DoLayout()
				end

				if totalWidth > 0 then
					totalWidth = totalWidth + paddingX
				end
				totalWidth = totalWidth + frame:GetWidth()
				maxHeight = max(maxHeight, frame:GetHeight())
			end
		end
	else
		contentWidth = contentWidth - (childCount - 1) * paddingX
		for i = 1, childCount do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()

			if child.type == "EPSpacer" and child.fillSpace then
				tinsert(spacers, i)
			else
				if i > 1 then
					if i == childCount then
						if child.selfAlignment == "right" then
							frame:SetPoint("RIGHT", content, "RIGHT")
						else
							frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", paddingX, 0)
						end
					else
						frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", paddingX, 0)
					end
				else
					frame:SetPoint("TOPLEFT", content, "TOPLEFT")
				end

				if child.width == "fill" and i == childCount then
					frame:SetPoint("RIGHT", content)
				elseif child.width == "relative" then
					child:SetWidth(contentWidth * child.relWidth)
				end
				if child.height == "fill" then
					frame:SetPoint("BOTTOM", content)
				end

				if child.DoLayout then
					child:DoLayout()
				end

				if totalWidth > 0 then
					totalWidth = totalWidth + paddingX
				end
				totalWidth = totalWidth + frame:GetWidth()
				maxHeight = max(maxHeight, frame:GetHeight())
			end
		end
	end

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
			if i ~= childCount then
				children[i + 1].frame:SetPoint("TOPLEFT", spacer.frame, "TOPRIGHT")
			end
		end
	end

	content:SetHeight(maxHeight)
	content:SetWidth(totalWidth)

	SafeCall(content.obj.LayoutFinished, content.obj, totalWidth, maxHeight)
end)
