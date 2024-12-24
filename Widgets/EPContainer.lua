local Type = "EPContainer"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local ipairs = ipairs
local select = select
local tinsert = tinsert

local defaultSpacing = { x = 10, y = 10 }
local defaultHeight = 100
local defaultWidth = 100

---@class EPContainer : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame
---@field children table<AceGUIWidget>
---@field selfAlignment string|nil

---@param self EPContainer
local function OnAcquire(self)
	self.frame:Show()
	self:SetHeight(defaultHeight)
	self:SetWidth(defaultWidth)
	self.content.spacing = defaultSpacing
	self.content:SetScript("OnSizeChanged", nil)
	self.frame:SetScript("OnSizeChanged", nil)
	self.content.alignment = nil
	self.selfAlignment = nil
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

---@param self EPContainer
---@param alignment string
local function SetSelfAlignment(self, alignment)
	self.selfAlignment = alignment
end

-- Inserts a variable number of widgets before beforeWidget.
---@param self EPContainer
---@param beforeWidget AceGUIWidget|EPWidgetType
---@param ... AceGUIWidget|EPWidgetType
local function InsertChildren(self, beforeWidget, ...)
	if not beforeWidget then
		return
	end

	local childIndex = nil
	for index, widget in ipairs(self.children) do
		if widget == beforeWidget then
			childIndex = index
			break
		end
	end
	if childIndex then
		for i = 1, select("#", ...) do
			local child = select(i, ...)
			tinsert(self.children, childIndex, child)
			childIndex = childIndex + 1
			child:SetParent(self)
			child.frame:Show()
		end
		self:DoLayout()
	end
end

---@param self EPContainer
---@param child AceGUIWidgetType|EPWidgetType|table
local function AddChildNoDoLayout(self, child)
	tinsert(self.children, child)
	child:SetParent(self)
	child.frame:Show()
end

---@param self EPContainer
---@param child AceGUIWidgetType|EPWidgetType|table
local function RemoveChildNoDoLayout(self, child)
	for i = #self.children, 1, -1 do
		if self.children[i] == child then
			self.children[i]:Release()
			tremove(self.children, i)
			break
		end
	end
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
		SetAlignment = SetAlignment,
		SetSelfAlignment = SetSelfAlignment,
		InsertChildren = InsertChildren,
		AddChildNoDoLayout = AddChildNoDoLayout,
		RemoveChildNoDoLayout = RemoveChildNoDoLayout,
		frame = frame,
		type = Type,
		content = content,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
