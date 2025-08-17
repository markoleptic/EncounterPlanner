local Type = "EPScrollFrame"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local Clamp = Clamp
local GetCursorPosition = GetCursorPosition
local max = math.max
local min = math.min
local select = select
local unpack = unpack

local k = {
	DefaultFrameHeight = 400,
	DefaultFrameWidth = 400,
	DefaultScrollBarScrollFramePadding = 10,
	DefaultScrollBarWidth = 16,
	MaxEdgeCursorScrollDistance = 300.0,
	MaxEdgeMultiplier = 1.5,
	MinEdgeMultiplier = 0.05,
	MinThumbSize = 20,
	ScrollFrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 2,
	},
	ScrollFrameBackdropBorderColor = { 0.25, 0.25, 0.25, 1.0 },
	ScrollMultiplier = 30.0,
	ThumbPadding = { x = 2, y = 2 },
	VerticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 },
	VerticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 },
}
k.EdgeMultiplierRange = k.MaxEdgeMultiplier - k.MinEdgeMultiplier
k.TotalVerticalThumbPadding = 2 * k.ThumbPadding.y
k.WrapperPadding = k.ScrollFrameBackdrop.edgeSize

---@param self EPScrollFrame
---@return number -- min
---@return number -- max
local function GetScrollRange(self)
	local minScroll, maxScroll = 0.0, 0.0
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local scrollChild = self.scrollChild
	if scrollChild then
		local scrollChildHeight = scrollChild:GetHeight()
		maxScroll = max(maxScroll, scrollChildHeight - scrollFrameHeight)
	end
	return minScroll, maxScroll
end

---@param self EPScrollFrame
---@param offset number
local function SetVerticalScroll(self, offset)
	if self.scrollChild then
		local minScroll, maxScroll = GetScrollRange(self)
		offset = max(minScroll, min(offset, maxScroll))
		self.scrollChild:SetPoint("TOPLEFT", 0, offset)
		self.currentScroll = offset
	end
end

---@param self EPScrollFrame
local function HandleEdgeScrolling(self)
	local scrollChild = self.scrollChild
	if not scrollChild then
		return
	end

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local scrollChildHeight = scrollChild:GetHeight()
	local maxScroll = scrollChildHeight - scrollFrameHeight
	if maxScroll <= 0 then
		return
	end

	local yPosition = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
	local frameTop = scrollFrame:GetTop()
	local frameBottom = scrollFrame:GetBottom()
	local currentScroll = self.currentScroll

	if yPosition > frameTop - 5 then -- Cursor near the top
		local t = min(k.MaxEdgeCursorScrollDistance, yPosition - (frameTop - 5)) / k.MaxEdgeCursorScrollDistance
		local result = k.EdgeMultiplierRange * t + k.MinEdgeMultiplier
		SetVerticalScroll(self, max(0, currentScroll - self.scrollMultiplier * result))
	elseif yPosition < frameBottom + 5 then -- Cursor near the bottom edge
		local t = min(k.MaxEdgeCursorScrollDistance, (frameBottom + 5) - yPosition) / k.MaxEdgeCursorScrollDistance
		local result = k.EdgeMultiplierRange * t + k.MinEdgeMultiplier
		SetVerticalScroll(self, min(maxScroll, currentScroll + self.scrollMultiplier * result))
	end

	self:UpdateThumbPositionAndSize()
end

---@param self EPScrollFrame
local function EnableEdgeScrolling(self)
	if not self.edgeScrollingEnabled then
		self.edgeScrollingEnabled = true
		self.scrollFrame:SetScript("OnUpdate", function()
			HandleEdgeScrolling(self)
		end)
	end
end

---@param self EPScrollFrame
local function DisableEdgeScrolling(self)
	if self.edgeScrollingEnabled then
		self.edgeScrollingEnabled = false
		self.scrollFrame:SetScript("OnUpdate", nil)
	end
end

---@param self EPScrollFrame
local function HandleVerticalThumbUpdate(self)
	if not self.verticalThumbIsDragging then
		return
	end

	local currentOffset = self.verticalThumbOffsetWhenThumbClicked
	local currentHeight = self.verticalThumbHeightWhenThumbClicked
	local currentScrollBarHeight = self.verticalScrollBarHeightWhenThumbClicked
	local yPosition = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()

	local minAllowedOffset = k.ThumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - k.ThumbPadding.y
	local newOffset = Clamp(self.scrollBar:GetTop() - yPosition - currentOffset, minAllowedOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local minScroll, maxScroll = self:GetScrollRange()

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * k.ThumbPadding.y)

	if maxScroll <= 0 or maxThumbPosition <= 0 then
		-- No scrollable content or thumb fills the scroll bar
		SetVerticalScroll(self, 0)
		return
	end

	local scrollOffset = ((newOffset - k.ThumbPadding.y) / maxThumbPosition) * maxScroll
	SetVerticalScroll(self, max(minScroll, scrollOffset))
end

---@param self EPScrollFrame
local function HandleVerticalThumbMouseDown(self)
	local yPosition = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
	self.verticalThumbOffsetWhenThumbClicked = self.thumb:GetTop() - yPosition
	self.verticalScrollBarHeightWhenThumbClicked = self.scrollBar:GetHeight()
	self.verticalThumbHeightWhenThumbClicked = self.thumb:GetHeight()
	self.verticalThumbIsDragging = true
	self.thumb:SetScript("OnUpdate", function()
		HandleVerticalThumbUpdate(self)
	end)
end

---@param self EPScrollFrame
local function HandleVerticalThumbMouseUp(self)
	self.verticalThumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

---@param self EPScrollFrame
local function OnAcquire(self)
	self.scrollMultiplier = k.ScrollMultiplier
	self.currentScroll = 0
	self.verticalThumbOffsetWhenThumbClicked = 0
	self.verticalScrollBarHeightWhenThumbClicked = 0
	self.verticalThumbHeightWhenThumbClicked = 0
	self.verticalThumbIsDragging = false
	self.edgeScrollingEnabled = false
	self.setScrollChildWidth = false
	self.enableEdgeScrolling = false
	self.scrollBarScrollFramePadding = k.DefaultScrollBarScrollFramePadding

	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self.frame:Show()

	self.scrollFrameWrapper:SetParent(self.frame --[[@as Frame]])
	self.scrollFrame:SetSize(
		k.DefaultFrameWidth - k.DefaultScrollBarScrollFramePadding - k.DefaultScrollBarWidth,
		k.DefaultFrameHeight
	)
	self.scrollFrameWrapper:SetPoint("TOPLEFT")
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -k.DefaultScrollBarScrollFramePadding - k.DefaultScrollBarWidth, 0)
	self.scrollFrameWrapper:SetBackdrop(k.ScrollFrameBackdrop)
	self.scrollFrameWrapper:SetBackdropColor(0, 0, 0, 1.0)
	self.scrollFrameWrapper:SetBackdropBorderColor(unpack(k.ScrollFrameBackdropBorderColor))
	self.scrollFrameWrapper:Show()

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(self.scrollFrameWrapper --[[@as Frame]])
	self.scrollFrame:SetSize(
		k.DefaultFrameWidth - k.DefaultScrollBarScrollFramePadding - k.DefaultScrollBarWidth - 2 * k.WrapperPadding,
		k.DefaultFrameHeight - 2 * k.WrapperPadding
	)
	self.scrollFrame:SetPoint("TOPLEFT", k.WrapperPadding, -k.WrapperPadding)
	self.scrollFrame:SetPoint("BOTTOMRIGHT", -k.WrapperPadding, k.WrapperPadding)
	self.scrollFrame:Show()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(self.frame --[[@as Frame]])
	self.scrollBar:SetSize(k.DefaultScrollBarWidth, k.DefaultFrameHeight)
	self.scrollBar:SetPoint("TOPRIGHT")
	self.scrollBar:SetPoint("BOTTOMRIGHT")
	self.scrollBar:Show()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(self.scrollBar)
	self.thumb:SetPoint("TOP", 0, -k.ThumbPadding.y)
	self.thumb:SetScript("OnMouseDown", function()
		HandleVerticalThumbMouseDown(self)
	end)
	self.thumb:SetScript("OnMouseUp", function()
		HandleVerticalThumbMouseUp(self)
	end)
	self.thumb:Show()
end

---@param self EPScrollFrame
local function OnRelease(self)
	if self.scrollChild then
		self.scrollChild:SetScript("OnMouseDown", nil)
		self.scrollChild:SetScript("OnMouseUp", nil)
		self.scrollChild:SetScript("OnMouseWheel", nil)
		self.scrollChild:SetScript("OnSizeChanged", nil)
		self.scrollChild:EnableMouse(false)
	end

	self.frame:ClearBackdrop()
	self.scrollFrameWrapper:ClearBackdrop()

	self.scrollFrameWrapper:ClearAllPoints()
	self.scrollFrameWrapper:SetParent(UIParent)
	self.scrollFrameWrapper:Hide()

	self.scrollFrame:SetScript("OnUpdate", nil)
	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(UIParent)
	self.scrollFrame:Hide()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(UIParent)
	self.scrollBar:Hide()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(UIParent)
	self.thumb:Hide()

	self.thumb:SetScript("OnMouseDown", nil)
	self.thumb:SetScript("OnMouseUp", nil)
	self.thumb:SetScript("OnUpdate", nil)

	self.currentScroll = nil
	self.verticalThumbOffsetWhenThumbClicked = nil
	self.verticalScrollBarHeightWhenThumbClicked = nil
	self.verticalThumbHeightWhenThumbClicked = nil
	self.verticalThumbIsDragging = nil
	self.edgeScrollingEnabled = nil
	self.setScrollChildWidth = nil
	self.enableEdgeScrolling = nil
	self.scrollBarScrollFramePadding = nil
end

---@param self EPScrollFrame
---@param child Frame
---@param needsWidthSetting boolean
---@param enableEdgeScrolling boolean
local function SetScrollChild(self, child, needsWidthSetting, enableEdgeScrolling)
	self.setScrollChildWidth = needsWidthSetting
	self.enableEdgeScrolling = enableEdgeScrolling
	self.scrollChild = child

	child:ClearAllPoints()
	child:EnableMouse(true)
	child:SetParent(self.scrollFrame --[[@as Frame]])
	child:Show()
	child:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT")

	if needsWidthSetting then
		child:SetWidth(self.scrollFrame:GetWidth())
	end

	if enableEdgeScrolling then
		child:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				EnableEdgeScrolling(self)
			end
		end)
		child:SetScript("OnMouseUp", function(_, button)
			if button == "LeftButton" then
				DisableEdgeScrolling(self)
			end
		end)
	end

	child:SetScript("OnMouseWheel", function(_, delta)
		self:UpdateVerticalScroll(delta)
		self:UpdateThumbPositionAndSize()
	end)
	child:SetScript("OnSizeChanged", function()
		self:UpdateVerticalScroll()
		self:UpdateThumbPositionAndSize()
	end)

	self:UpdateVerticalScroll()
	self:UpdateThumbPositionAndSize()
end

---@param self EPScrollFrame
---@param delta number|nil
local function UpdateVerticalScroll(self, delta)
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local scrollChild = self.scrollChild
	if scrollChild then
		if not delta then
			delta = 0
		end
		local scrollChildHeight = scrollChild:GetHeight()
		local maxScroll = scrollChildHeight - scrollFrameHeight
		if maxScroll <= 0.0 then
			SetVerticalScroll(self, 0)
			self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", 0, 0)
			self.scrollBar:Hide()
		else
			self.scrollBar:Show()
			self.scrollFrameWrapper:SetPoint(
				"BOTTOMRIGHT",
				-self.scrollBarScrollFramePadding - self.scrollBar:GetWidth(),
				0
			)
			local newVerticalScroll = Clamp(self.currentScroll - (delta * self.scrollMultiplier), 0, maxScroll)
			SetVerticalScroll(self, newVerticalScroll)
		end
		if self.setScrollChildWidth then
			scrollChild:SetWidth(self.scrollFrame:GetWidth())
		end
	end
end

---@param self EPScrollFrame
local function UpdateThumbPositionAndSize(self)
	if not self.scrollBar:IsShown() then
		return
	end

	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local scrollChild = self.scrollChild
	if not scrollChild then
		return
	end

	local scrollChildHeight = scrollChild:GetHeight()
	local currentScroll = self.currentScroll
	local heightDifference = scrollChildHeight - scrollFrameHeight

	if heightDifference <= 0 then
		-- No scrolling needed, reset thumb
		local fullThumbHeight = self.scrollBar:GetHeight() - k.TotalVerticalThumbPadding
		self.thumb:SetHeight(fullThumbHeight)
		self.thumb:SetPoint("TOP", 0, -k.ThumbPadding.y)
		return
	end

	local scrollPercentage = currentScroll / heightDifference
	local availableThumbHeight = self.scrollBar:GetHeight() - k.TotalVerticalThumbPadding

	local thumbHeight = (scrollFrameHeight / scrollChildHeight) * availableThumbHeight
	thumbHeight = Clamp(thumbHeight, k.MinThumbSize, availableThumbHeight)
	self.thumb:SetHeight(thumbHeight)

	local maxThumbPosition = availableThumbHeight - thumbHeight
	local verticalThumbPosition = Clamp(scrollPercentage * maxThumbPosition, 0, maxThumbPosition) + k.ThumbPadding.y
	self.thumb:SetPoint("TOP", 0, -verticalThumbPosition)
end

---@param self EPScrollFrame
local function OnHeightSet(self)
	self:UpdateVerticalScroll()
	self:UpdateThumbPositionAndSize()
end

---@return number
local function GetWrapperPadding()
	return k.WrapperPadding
end

---@param self EPScrollFrame
---@param width number
local function SetScrollBarWidth(self, width)
	self.scrollBar:SetWidth(width)
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -self.scrollBarScrollFramePadding - width, 0)
	self.thumb:SetSize(width - (2 * k.ThumbPadding.x), self.scrollBar:GetHeight() - 2 * k.ThumbPadding.y)
end

---@param self EPScrollFrame
---@param padding number
local function SetScrollBarScrollFramePadding(self, padding)
	self.scrollBarScrollFramePadding = padding
	local scrollBarWidth = self.scrollBar:GetWidth()
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -padding - scrollBarWidth, 0)
end

---@param self EPScrollFrame
---@param newVerticalScroll number
local function SetScroll(self, newVerticalScroll)
	SetVerticalScroll(self, newVerticalScroll)
	UpdateThumbPositionAndSize(self)
end

---@param self EPScrollFrame
---@param multiplier number
local function SetScrollMultiplier(self, multiplier)
	self.scrollMultiplier = multiplier
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local scrollFrameWrapper = CreateFrame("Frame", Type .. "scrollFrameWrapper" .. count, frame, "BackdropTemplate")
	scrollFrameWrapper:SetClipsChildren(true)

	local scrollFrame = CreateFrame("Frame", Type .. "ScrollFrame" .. count, frame)
	scrollFrame:SetClipsChildren(true)

	local scrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	scrollBar:SetWidth(k.DefaultScrollBarWidth)
	scrollBar:SetPoint("TOPRIGHT")
	scrollBar:SetPoint("BOTTOMRIGHT")

	local verticalScrollBarBackground =
		scrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(unpack(k.VerticalScrollBackgroundColor))

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, scrollBar)
	verticalThumb:SetPoint("TOP", 0, k.ThumbPadding.y)
	verticalThumb:SetSize(
		k.DefaultScrollBarWidth - (2 * k.ThumbPadding.x),
		scrollBar:GetHeight() - 2 * k.ThumbPadding.y
	)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(unpack(k.VerticalThumbBackgroundColor))

	---@class EPScrollFrame : AceGUIWidget
	---@field scrollChild Frame|nil
	---@field currentScroll number
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetScrollChild = SetScrollChild,
		UpdateThumbPositionAndSize = UpdateThumbPositionAndSize,
		OnHeightSet = OnHeightSet,
		UpdateVerticalScroll = UpdateVerticalScroll,
		SetScrollBarWidth = SetScrollBarWidth,
		SetScrollBarScrollFramePadding = SetScrollBarScrollFramePadding,
		GetWrapperPadding = GetWrapperPadding,
		GetScrollRange = GetScrollRange,
		SetScroll = SetScroll,
		SetScrollMultiplier = SetScrollMultiplier,
		frame = frame,
		scrollFrame = scrollFrame --[[@as Frame]],
		scrollFrameWrapper = scrollFrameWrapper,
		type = Type,
		scrollBar = scrollBar,
		thumb = verticalThumb,
		verticalThumbOffsetWhenThumbClicked = 0,
		verticalScrollBarHeightWhenThumbClicked = 0,
		verticalThumbHeightWhenThumbClicked = 0,
		verticalThumbIsDragging = false,
		edgeScrollingEnabled = false,
		setScrollChildWidth = false,
		enableEdgeScrolling = false,
		scrollBarScrollFramePadding = k.DefaultScrollBarScrollFramePadding,
		scrollMultiplier = k.ScrollMultiplier,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
