local _, Namespace = ...

---@class Private
local Private = Namespace

---@diagnostic disable: invisible

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local ipairs = ipairs
local select = select
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack

local k = {
	AnchorTexture = Private.constants.textures.kAnchor,
	DefaultSpacing = { x = 10, y = 10 },
	DefaultHeight = 100,
	DefaultWidth = 100,
	GenericWhite = Private.constants.textures.kGenericWhite,
}

---@param self EPAnchorContainer|EPContainer
local function OnAcquire(self)
	self.frame:ClearBackdrop()
	self.frame:Show()
	self.content.spacing = { x = k.DefaultSpacing.x, y = k.DefaultSpacing.y }
	self.content.alignment = nil
	self.content.orientation = nil
	self.content.sortAscending = nil
	self:SetPadding(0, 0, 0, 0)
	self:SetHeight(k.DefaultHeight)
	self:SetWidth(k.DefaultWidth)
	self.content:SetScript("OnSizeChanged", nil)
	self.frame:SetScript("OnSizeChanged", nil)
end

---@param self EPAnchorContainer|EPContainer
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

---@param self EPAnchorContainer|EPContainer
---@param horizontal number
---@param vertical number
local function SetSpacing(self, horizontal, vertical)
	self.content.spacing = { x = horizontal, y = vertical }
end

---@param self EPAnchorContainer|EPContainer
---@param left number
---@param top number
---@param right number
---@param bottom number
local function SetPadding(self, left, top, right, bottom)
	self.padding = { left = left, top = top, right = right, bottom = bottom }
	self.content:SetPoint("TOPLEFT", left, -top)
	self.content:SetPoint("BOTTOMRIGHT", -right, bottom)
end

---@param self EPAnchorContainer|EPContainer
---@param alignment string
local function SetAlignment(self, alignment)
	self.content.alignment = alignment
end

---@param self EPAnchorContainer|EPContainer
---@param alignment string
local function SetSelfAlignment(self, alignment)
	self.selfAlignment = alignment
end

---@param self EPAnchorContainer|EPContainer
---@param orientation "vertical"|"horizontal"
local function SetOrientation(self, orientation)
	self.content.orientation = orientation
end

---@param self EPAnchorContainer|EPContainer
---@param ascending boolean
local function SetSortAscending(self, ascending)
	self.content.sortAscending = ascending
end

---@param self EPAnchorContainer|EPContainer
---@param ignore boolean
local function SetIgnoreFromLayout(self, ignore)
	self.content.ignoreFromLayout = ignore
end

---@param self EPAnchorContainer|EPContainer
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
---@param self EPAnchorContainer|EPContainer
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

---@param self EPAnchorContainer|EPContainer
---@param child AceGUIWidget
local function AddChildNoDoLayout(self, child)
	if child then
		tinsert(self.children, child)
		child:SetParent(self)
		child.frame:Show()
	end
end

---@param self EPAnchorContainer|EPContainer
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

---@param self EPAnchorContainer|EPContainer
---@param child AceGUIWidget
local function RemoveChild(self, child)
	for i = #self.children, 1, -1 do
		if self.children[i] == child then
			self.children[i]:Release()
			tremove(self.children, i)
			break
		end
	end
	self:DoLayout()
end

---@param self EPAnchorContainer|EPContainer
---@param ... AceGUIWidget
local function RemoveChildren(self, ...)
	local map = {}
	for i = 1, select("#", ...) do
		map[select(i, ...)] = true
	end
	for i = #self.children, 1, -1 do
		if map[self.children[i]] then
			self.children[i]:Release()
			tremove(self.children, i)
		end
	end
	self:DoLayout()
end

do
	local Type = "EPContainer"
	local Version = 1

	---@param self EPContainer
	local function OnRelease(self)
		self.content.alignment = nil
		self.content.sortAscending = nil
		self.content.spacing = nil
		self.content.orientation = nil
		self.content.ignoreFromLayout = nil
		self.selfAlignment = nil
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetFrameStrata("DIALOG")
		frame:SetHeight(k.DefaultHeight)
		frame:SetWidth(k.DefaultWidth)

		local content = CreateFrame("Frame", Type .. "Content" .. count, frame)
		content:SetPoint("TOPLEFT")
		content:SetPoint("BOTTOMRIGHT")

		---@class EPContainer : AceGUIContainer
		---@field content EPContainerContentFrame
		---@field children table<AceGUIWidget>
		---@field selfAlignment string|nil
		---@field padding {left: number, top: number, right: number, bottom: number}
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			LayoutFinished = LayoutFinished,
			SetSpacing = SetSpacing,
			SetAlignment = SetAlignment,
			SetSelfAlignment = SetSelfAlignment,
			SetOrientation = SetOrientation,
			SetSortAscending = SetSortAscending,
			SetIgnoreFromLayout = SetIgnoreFromLayout,
			InsertChildren = InsertChildren,
			AddChildNoDoLayout = AddChildNoDoLayout,
			RemoveChild = RemoveChild,
			RemoveChildren = RemoveChildren,
			RemoveChildNoDoLayout = RemoveChildNoDoLayout,
			SetBackdrop = SetBackdrop,
			SetPadding = SetPadding,
			frame = frame,
			type = Type,
			count = count,
			content = content,
		}

		return AceGUI:RegisterAsContainer(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
	local Type = "EPAnchorContainer"
	local Version = 1

	local previousPointDetails = {}

	---@param self EPAnchorContainer
	local function HandleFrameMouseDown(self, button)
		if button == "LeftButton" then
			local point, relativeTo, relativePoint, _, _ = self.frame:GetPoint()
			previousPointDetails = {
				point = point,
				relativeTo = relativeTo:GetName(),
				relativePoint = relativePoint,
			}
			self.frame:StartMoving()
			self:Fire("MouseDown")
		end
	end

	---@param self EPAnchorContainer
	local function HandleFrameMouseUp(self, button)
		if button == "LeftButton" then
			self.frame:StopMovingOrSizing()
			local point = previousPointDetails.point
			local relativeFrame = previousPointDetails.relativeTo
			local relativePoint = previousPointDetails.relativePoint
			self:Fire("NewPoint", point, relativeFrame, relativePoint)
		end
	end

	---@param self EPAnchorContainer
	local function OnRelease(self)
		self.frame:Hide()
		self.frame:SetParent(UIParent)
		if self.anchorMode then
			self.anchorMode = nil
			self.frame:SetMovable(false)
			self.frame:SetScript("OnMouseDown", nil)
			self.frame:SetScript("OnMouseUp", nil)
			self.anchorFrame:SetScript("OnMouseDown", nil)
			self.anchorFrame:SetScript("OnMouseUp", nil)
			self.anchorFrame:ClearAllPoints()
			self.anchorFrame:Hide()
		end
		self.content.alignment = nil
		self.content.sortAscending = nil
		self.content.spacing = nil
		self.content.orientation = nil
		self.content.ignoreFromLayout = nil
		self.selfAlignment = nil
	end

	---@param self EPAnchorContainer
	---@param point AnchorPoint
	local function SetAnchorPoint(self, point)
		local x, y = 0, 0
		if point == "TOP" then
			y = 16
		elseif point == "TOPLEFT" then
			x, y = -16, 16
		elseif point == "TOPRIGHT" then
			x, y = 16, 16
		elseif point == "RIGHT" then
			x = 16
		elseif point == "BOTTOMRIGHT" then
			x, y = 16, -16
		elseif point == "BOTTOM" then
			y = -16
		elseif point == "LEFT" then
			x = -16
		elseif point == "BOTTOMLEFT" then
			x, y = -16, -16
		end
		self.anchorFrame:ClearAllPoints()
		self.anchorFrame:SetPoint(point, self.frame, point, x, y)
	end

	---@param self EPAnchorContainer
	---@param anchorMode boolean
	---@param point AnchorPoint|nil
	local function SetAnchorMode(self, anchorMode, point)
		if anchorMode then
			self.anchorMode = true
			self.frame:SetMovable(true)
			self.frame:SetScript("OnMouseDown", function(_, button)
				HandleFrameMouseDown(self, button)
			end)
			self.frame:SetScript("OnMouseUp", function(_, button)
				HandleFrameMouseUp(self, button)
			end)
			self.anchorFrame:SetScript("OnMouseDown", function(_, button)
				HandleFrameMouseDown(self, button)
			end)
			self.anchorFrame:SetScript("OnMouseUp", function(_, button)
				HandleFrameMouseUp(self, button)
			end)
			if point then
				SetAnchorPoint(self, point)
				self.anchorFrame:Show()
			end
		else
			self.anchorMode = nil
			self.frame:SetMovable(false)
			self.frame:SetScript("OnMouseDown", nil)
			self.frame:SetScript("OnMouseUp", nil)
			self.anchorFrame:SetScript("OnMouseDown", nil)
			self.anchorFrame:SetScript("OnMouseUp", nil)
			self.anchorFrame:ClearAllPoints()
			self.anchorFrame:Hide()
		end
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetFrameStrata("DIALOG")
		frame:SetHeight(k.DefaultHeight)
		frame:SetWidth(k.DefaultWidth)

		local content = CreateFrame("Frame", Type .. "Content" .. count, frame)
		content:SetPoint("TOPLEFT")
		content:SetPoint("BOTTOMRIGHT")

		local anchorFrame = CreateFrame("Frame", Type .. "Anchor" .. count, frame, "BackdropTemplate")
		anchorFrame:SetBackdrop({
			bgFile = k.GenericWhite,
			edgeFile = nil,
			tile = false,
		})
		anchorFrame:SetBackdropColor(20.0 / 255.0, 20.0 / 255.0, 20.0 / 255.0, 0.25)
		anchorFrame:SetSize(16, 16)
		local resizer = anchorFrame:CreateTexture(nil, "OVERLAY")
		resizer:SetAllPoints()
		resizer:SetTexture(k.AnchorTexture)
		resizer:SetVertexColor(1, 0.82, 0, 1)
		anchorFrame:Hide()

		---@class EPAnchorContainer : AceGUIContainer
		---@field content EPContainerContentFrame
		---@field children table<AceGUIWidget>
		---@field selfAlignment "topRight"|"center"|nil
		---@field padding {left: number, top: number, right: number, bottom: number}
		---@field anchorMode boolean|nil
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			LayoutFinished = LayoutFinished,
			SetSpacing = SetSpacing,
			SetAlignment = SetAlignment,
			SetSelfAlignment = SetSelfAlignment,
			SetOrientation = SetOrientation,
			SetSortAscending = SetSortAscending,
			SetIgnoreFromLayout = SetIgnoreFromLayout,
			InsertChildren = InsertChildren,
			AddChildNoDoLayout = AddChildNoDoLayout,
			RemoveChild = RemoveChild,
			RemoveChildren = RemoveChildren,
			RemoveChildNoDoLayout = RemoveChildNoDoLayout,
			SetBackdrop = SetBackdrop,
			SetPadding = SetPadding,
			SetAnchorPoint = SetAnchorPoint,
			SetAnchorMode = SetAnchorMode,
			frame = frame,
			type = Type,
			count = count,
			content = content,
			anchorFrame = anchorFrame,
		}

		return AceGUI:RegisterAsContainer(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
