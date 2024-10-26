local Type           = "EPContainer"
local Version        = 1
local AceGUI         = LibStub("AceGUI-3.0")
local defaultSpacing = { x = 10, y = 10 }

---@class EPContainer : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame

---@param self EPContainer
local function OnAcquire(self)
	self:SetWidth(300)
	self:SetHeight(100)
	self.content.spacing = defaultSpacing
	self.frame:Show()
end


---@param self EPContainer
---@param width number
local function OnWidthSet(self, width)
	local content = self.content
	content:SetWidth(width)
	content.width = width
end

---@param self EPContainer
---@param height number
local function OnHeightSet(self, height)
	local content = self.content
	content:SetHeight(height)
	content.height = height
end

---@param self EPContainer
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetHeight(height)
		self.frame:SetWidth(width)
	end
end


---@param self EPContainer
---@param horizontal number
---@param vertical number
local function SetSpacing(self, horizontal, vertical)
	self.content.spacing = { x = horizontal, y = vertical }
end

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

	---@class EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		LayoutFinished = LayoutFinished,
		OnWidthSet = OnWidthSet,
		OnHeightSet = OnHeightSet,
		SetSpacing = SetSpacing,
		frame = frame,
		type = Type,
		content = content,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
