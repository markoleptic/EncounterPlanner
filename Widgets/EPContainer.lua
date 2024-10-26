local Type           = "EPContainer"
local Version        = 1
local AceGUI         = LibStub("AceGUI-3.0")
local defaultSpacing = { x = 10, y = 10 }
local defaultHeight  = 100
local defaultWidth   = 100

---@class EPContainer : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame

---@param self EPContainer
local function OnAcquire(self)
	self:SetHeight(defaultHeight)
	self:SetWidth(defaultWidth)
	self.content.spacing = defaultSpacing
end

---@param self EPContainer
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		self:SetHeight(height)
		self:SetWidth(width)
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
	frame:SetHeight(defaultHeight)
	frame:SetWidth(defaultWidth)

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

	---@class EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		LayoutFinished = LayoutFinished,
		SetSpacing = SetSpacing,
		frame = frame,
		type = Type,
		content = content,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
