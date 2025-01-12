---@diagnostic disable: invisible
local Type = "EPContainer"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local ipairs = ipairs
local select = select
local tinsert = tinsert
local unpack = unpack

local defaultSpacing = { x = 10, y = 10 }
local defaultHeight = 100
local defaultWidth = 100

---@class EPContainer : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame
---@field children table<AceGUIWidget>
---@field selfAlignment string|nil
---@field padding {left: number, top: number, right: number, bottom: number}

---@param self EPContainer
local function OnAcquire(self)
	self.frame:Show()
	self:SetPadding(0, 0, 0, 0)
	self:SetHeight(defaultHeight)
	self:SetWidth(defaultWidth)
	self.content.spacing = defaultSpacing
	self.content:SetScript("OnSizeChanged", nil)
	self.frame:SetScript("OnSizeChanged", nil)
end

local function OnRelease(self)
	self.frame:ClearBackdrop()
	self.content.alignment = nil
	self.selfAlignment = nil
end

---@param self EPContainer
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		if width > 0 then
			self:SetWidth(width + self.padding.left + self.padding.right)
		end
		self:SetHeight(height + self.padding.top + self.padding.bottom)
	end
end

---@param self EPContainer
---@param horizontal number
---@param vertical number
local function SetSpacing(self, horizontal, vertical)
	self.content.spacing = { x = horizontal, y = vertical }
end

---@param self EPContainer
---@param left number
---@param top number
---@param right number
---@param bottom number
local function SetPadding(self, left, top, right, bottom)
	self.padding = { left = left, top = top, right = right, bottom = bottom }
	self.content:SetPoint("TOPLEFT", left, -top)
	self.content:SetPoint("BOTTOMRIGHT", -right, bottom)
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

---@param self EPContainer
---@param backdropInfo backdropInfo
---@param backdropColor table<number>?
---@param backdropBorderColor table<number>?
local function SetBackdrop(self, backdropInfo, backdropColor, backdropBorderColor)
	self.frame:SetBackdrop(backdropInfo)
	if backdropColor then
		self.frame:SetBackdropColor(unpack(backdropColor))
	end
	if backdropBorderColor then
		self.frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	end
end

-- Inserts a variable number of widgets before beforeWidget.
---@param self EPContainer
---@param beforeWidget AceGUIWidget
---@param ... AceGUIWidget
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
---@param child AceGUIWidget
local function AddChildNoDoLayout(self, child)
	if child then
		tinsert(self.children, child)
		child:SetParent(self)
		child.frame:Show()
	end
end

---@param self EPContainer
---@param child AceGUIWidget
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
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetHeight(defaultHeight)
	frame:SetWidth(defaultWidth)

	local content = CreateFrame("Frame", Type .. "Content" .. count, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

	---@class EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetSpacing = SetSpacing,
		SetAlignment = SetAlignment,
		SetSelfAlignment = SetSelfAlignment,
		InsertChildren = InsertChildren,
		AddChildNoDoLayout = AddChildNoDoLayout,
		RemoveChildNoDoLayout = RemoveChildNoDoLayout,
		SetBackdrop = SetBackdrop,
		SetPadding = SetPadding,
		frame = frame,
		type = Type,
		content = content,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
