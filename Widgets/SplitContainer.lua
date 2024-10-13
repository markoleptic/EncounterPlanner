local Type    = "EPSplitContainer"
local Version = 1
local AceGUI  = LibStub("AceGUI-3.0")


local methods = {

	["OnAcquire"] = function(self)
		self.frame:SetParent(UIParent)
		self:Show()
	end,
	["OnWidthSet"] = function(self, width)
		local content = self.content
		content:SetWidth(width)
		content.width = width
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		content:SetHeight(height)
		content.height = height
	end,

	["AddChild"] = function(self, child)
		child:SetParent(self)
		if self.children[1] then
			tinsert(self.children, child)
			child:SetPoint("TOPLEFT", self.children[1].frame, "TOPRIGHT")
			child:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
		else
			tinsert(self.children, child)
			child:SetPoint("TOPLEFT")
			child:SetPoint("BOTTOMLEFT")
		end
		child.frame:Show()
		self:DoLayout()
	end
}

-- Custom container widget creation
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetPoint("TOPLEFT")
	frame:SetPoint("BOTTOMRIGHT")

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

	local widget = {
		type = Type,
		frame = frame,
		version = Version,
		content = frame
	}

	for method, func in pairs(methods) do
		---@diagnostic disable-next-line: assign-type-mismatch
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

-- Register and use the custom container
AceGUI:RegisterWidgetType("SplitContainer", Constructor, Version)
