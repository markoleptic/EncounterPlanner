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

local defaultFrameWidth = 400
local defaultFrameHeight = 400
local defaultScrollBarScrollFramePadding = 10
local defaultScrollBarWidth = 16
local thumbPadding = { x = 2, y = 2 }
local totalVerticalThumbPadding = 2 * thumbPadding.y
local verticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local verticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 }
local minThumbSize = 20
local scrollMultiplier = 25
local scrollFrameBackdropBorderColor = { 0.25, 0.25, 0.25, 1.0 }
local maxEdgeCursorScrollDistance = 300.0
local minEdgeMultiplier = 0.05
local maxEdgeMultiplier = 1.5
local edgeMultiplierRange = maxEdgeMultiplier - minEdgeMultiplier
local scrollFrameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	edgeSize = 2,
}

---@param self EPScrollFrame
local function HandleEdgeScrolling(self)
	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local scrollChild = scrollFrame:GetScrollChild()
	if not scrollChild then
		return
	end

	local scrollChildHeight = scrollChild:GetHeight()
	local maxScroll = scrollChildHeight - scrollFrameHeight
	if maxScroll <= 0 then
		return
	end

	local yPosition = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
	local frameTop = scrollFrame:GetTop()
	local frameBottom = scrollFrame:GetBottom()
	local currentScroll = scrollFrame:GetVerticalScroll()

	if yPosition > frameTop - 5 then -- Cursor near the top
		local t = min(maxEdgeCursorScrollDistance, yPosition - (frameTop - 5)) / maxEdgeCursorScrollDistance
		local result = edgeMultiplierRange * t + minEdgeMultiplier
		scrollFrame:SetVerticalScroll(max(0, currentScroll - scrollMultiplier * result))
	elseif yPosition < frameBottom + 5 then -- Cursor near the bottom edge
		local t = min(maxEdgeCursorScrollDistance, (frameBottom + 5) - yPosition) / maxEdgeCursorScrollDistance
		local result = edgeMultiplierRange * t + minEdgeMultiplier
		scrollFrame:SetVerticalScroll(min(maxScroll, currentScroll + scrollMultiplier * result))
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

	local minAllowedOffset = thumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - thumbPadding.y
	local newOffset = Clamp(self.scrollBar:GetTop() - yPosition - currentOffset, minAllowedOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local scrollChildHeight = scrollFrame:GetScrollChild():GetHeight()
	local maxScroll = scrollChildHeight - scrollFrameHeight

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * thumbPadding.y)
	local scrollOffset = ((newOffset - thumbPadding.y) / maxThumbPosition) * maxScroll
	scrollFrame:SetVerticalScroll(max(0, scrollOffset))
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
	self.verticalThumbOffsetWhenThumbClicked = 0
	self.verticalScrollBarHeightWhenThumbClicked = 0
	self.verticalThumbHeightWhenThumbClicked = 0
	self.verticalThumbIsDragging = false
	self.edgeScrollingEnabled = false
	self.setScrollChildWidth = false
	self.enableEdgeScrolling = false
	self.scrollBarScrollFramePadding = defaultScrollBarScrollFramePadding

	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self.frame:Show()

	self.scrollFrameWrapper:SetParent(self.frame --[[@as Frame]])
	self.scrollFrame:SetSize(
		defaultFrameWidth - defaultScrollBarScrollFramePadding - defaultScrollBarWidth,
		defaultFrameHeight
	)
	self.scrollFrameWrapper:SetPoint("TOPLEFT")
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -defaultScrollBarScrollFramePadding - defaultScrollBarWidth, 0)
	self.scrollFrameWrapper:SetBackdrop(scrollFrameBackdrop)
	self.scrollFrameWrapper:SetBackdropColor(0, 0, 0, 1.0)
	self.scrollFrameWrapper:SetBackdropBorderColor(unpack(scrollFrameBackdropBorderColor))
	self.scrollFrameWrapper:Show()

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(self.scrollFrameWrapper --[[@as Frame]])
	self.scrollFrame:SetSize(
		defaultFrameWidth - defaultScrollBarScrollFramePadding - defaultScrollBarWidth - 4,
		defaultFrameHeight - 4
	)
	self.scrollFrame:SetPoint("TOPLEFT", 2, -2)
	self.scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
	self.scrollFrame:Show()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(self.frame --[[@as Frame]])
	self.scrollBar:SetSize(defaultScrollBarWidth, defaultFrameHeight)
	self.scrollBar:SetPoint("TOPRIGHT")
	self.scrollBar:SetPoint("BOTTOMRIGHT")
	self.scrollBar:Show()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(self.scrollBar)
	self.thumb:SetPoint("TOP", 0, -thumbPadding.y)
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
	self.frame:ClearBackdrop()
	self.scrollFrameWrapper:ClearBackdrop()

	self.scrollFrameWrapper:ClearAllPoints()
	self.scrollFrameWrapper:SetParent(UIParent)
	self.scrollFrameWrapper:Hide()

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
end

---@param self EPScrollFrame
---@param child Frame
---@param needsWidthSetting boolean
---@param enableEdgeScrolling boolean
local function SetScrollChild(self, child, needsWidthSetting, enableEdgeScrolling)
	self.setScrollChildWidth = needsWidthSetting
	self.enableEdgeScrolling = enableEdgeScrolling

	child:ClearAllPoints()
	child:EnableMouse(true)
	child:SetParent(self.scrollFrame --[[@as Frame]])
	child:Show()
	self.scrollFrame:SetScrollChild(child)

	child:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT")
	child:SetPoint("RIGHT", self.scrollFrame, "RIGHT")

	if needsWidthSetting then
		child:SetWidth(self.scrollFrame:GetWidth())
	end

	if enableEdgeScrolling then
		child:SetScript("OnMouseDown", function(frame, button)
			if button == "LeftButton" then
				EnableEdgeScrolling(self)
			end
		end)
		child:SetScript("OnMouseUp", function(frame, button)
			if button == "LeftButton" then
				DisableEdgeScrolling(self)
			end
		end)
	end

	child:SetScript("OnMouseWheel", function(frame, delta)
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
	local scrollChild = self.scrollFrame:GetScrollChild()
	if scrollChild then
		if self.setScrollChildWidth then
			scrollChild:SetWidth(self.scrollFrame:GetWidth())
		end
		if not delta then
			delta = 0
		end
		local scrollChildHeight = scrollChild:GetHeight()
		local maxScroll = scrollChildHeight - scrollFrameHeight
		if maxScroll <= 0.0 then
			self.scrollFrame:SetVerticalScroll(0)
			self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", 0, 0)
			self.scrollBar:Hide()
		else
			self.scrollBar:Show()
			self.scrollFrameWrapper:SetPoint(
				"BOTTOMRIGHT",
				-self.scrollBarScrollFramePadding - self.scrollBar:GetWidth(),
				0
			)
			local currentScroll = self.scrollFrame:GetVerticalScroll()
			local newVerticalScroll = Clamp(currentScroll - (delta * scrollMultiplier), 0, maxScroll)
			self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		end
	end
end

---@param self EPScrollFrame
local function UpdateThumbPositionAndSize(self)
	if self.scrollBar:IsShown() then
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local scrollChild = self.scrollFrame:GetScrollChild()
		if scrollChild then
			local scrollChildHeight = scrollChild:GetHeight()
			local scrollPercentage = self.scrollFrame:GetVerticalScroll() / (scrollChildHeight - scrollFrameHeight)
			local availableThumbHeight = self.scrollBar:GetHeight() - totalVerticalThumbPadding

			local thumbHeight = (scrollFrameHeight / scrollChildHeight) * availableThumbHeight
			thumbHeight = Clamp(thumbHeight, minThumbSize, availableThumbHeight)
			self.thumb:SetHeight(thumbHeight)

			local maxThumbPosition = availableThumbHeight - thumbHeight
			local verticalThumbPosition = Clamp(scrollPercentage * maxThumbPosition, 0, maxThumbPosition)
				+ thumbPadding.y
			self.thumb:SetPoint("TOP", 0, -verticalThumbPosition)
		end
	end
end

---@param self EPScrollFrame
---@param height number
local function OnHeightSet(self, height)
	self:UpdateVerticalScroll()
	self:UpdateThumbPositionAndSize()
end

---@param self EPScrollFrame
---@param width number
local function SetScrollBarWidth(self, width)
	self.scrollBar:SetWidth(width)
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -self.scrollBarScrollFramePadding - width, 0)
	self.thumb:SetSize(width - (2 * thumbPadding.x), self.scrollBar:GetHeight() - 2 * thumbPadding.y)
end

---@param self EPScrollFrame
---@param padding number
local function SetScrollBarScrollFramePadding(self, padding)
	self.scrollBarScrollFramePadding = padding
	local scrollBarWidth = self.scrollBar:GetWidth()
	self.scrollFrameWrapper:SetPoint("BOTTOMRIGHT", -padding - scrollBarWidth, 0)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local scrollFrameWrapper = CreateFrame("Frame", Type .. "scrollFrameWrapper" .. count, frame, "BackdropTemplate")
	scrollFrameWrapper:SetClipsChildren(true)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
	scrollFrame:SetClipsChildren(true)

	local scrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	scrollBar:SetWidth(defaultScrollBarWidth)
	scrollBar:SetPoint("TOPRIGHT")
	scrollBar:SetPoint("BOTTOMRIGHT")

	local verticalScrollBarBackground =
		scrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(unpack(verticalScrollBackgroundColor))

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, scrollBar)
	verticalThumb:SetPoint("TOP", 0, thumbPadding.y)
	verticalThumb:SetSize(defaultScrollBarWidth - (2 * thumbPadding.x), scrollBar:GetHeight() - 2 * thumbPadding.y)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(unpack(verticalThumbBackgroundColor))

	---@class EPScrollFrame : AceGUIWidget
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetScrollChild = SetScrollChild,
		UpdateThumbPositionAndSize = UpdateThumbPositionAndSize,
		OnHeightSet = OnHeightSet,
		UpdateVerticalScroll = UpdateVerticalScroll,
		SetScrollBarWidth = SetScrollBarWidth,
		SetScrollBarScrollFramePadding = SetScrollBarScrollFramePadding,
		frame = frame,
		scrollFrame = scrollFrame,
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
		scrollBarScrollFramePadding = defaultScrollBarScrollFramePadding,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
