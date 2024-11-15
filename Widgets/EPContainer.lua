local Type = "EPContainer"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultSpacing = { x = 10, y = 10 }
local defaultHeight = 100
local defaultWidth = 100

---@class EPContainer : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame
---@field children table<AceGUIWidget>

---@param self EPContainer
local function OnAcquire(self)
	self:SetHeight(defaultHeight)
	self:SetWidth(defaultWidth)
	self.content.spacing = defaultSpacing
	self.content.alignment = nil
end

---@param self EPContainer
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		if width > 0 then
			self:SetWidth(width)
		end
		self:SetHeight(height)
	end
end

local function OnHeightSet(self, width)
	self.content:SetHeight(width)
	self.content.height = width
end

local function OnWidthSet(self, width)
	self.content:SetWidth(width)
	self.content.width = width
end

---@param self EPContainer
---@param horizontal number
---@param vertical number
local function SetSpacing(self, horizontal, vertical)
	self.content.spacing = { x = horizontal, y = vertical }
end

---@param self EPContainer
---@param alignment string
local function SetAlignment(self, alignment)
	self.content.alignment = alignment
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetHeight(defaultHeight)
	frame:SetWidth(defaultWidth)

	local content = CreateFrame("Frame", Type .. "Content" .. count, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

	---@class EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		LayoutFinished = LayoutFinished,
		SetSpacing = SetSpacing,
		OnWidthSet = OnWidthSet,
		OnHeightSet = OnHeightSet,
		SetAlignment = SetAlignment,
		frame = frame,
		type = Type,
		content = content,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
