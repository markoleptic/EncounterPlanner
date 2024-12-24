local Type = "EPTimelineSection"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local max = math.max
local min = math.min

local verticalPositionLineSubLevel = -8
local verticalPositionLineColor = { 1, 0.82, 0, 1 }
local scrollBarWidth = 20
local thumbPadding = { x = 2, y = 2 }
local paddingBetweenTimelineAndScrollBar = 10
local defaultListPadding = 4
local listFrameWidth = 200
local listTimelinePadding = 10

---@param self EPTimelineSection
local function HandleVerticalThumbUpdate(self)
	if not self.verticalThumbIsDragging then
		return
	end

	local currentOffset = self.verticalThumbOffsetWhenThumbClicked
	local currentHeight = self.verticalThumbHeightWhenThumbClicked
	local currentScrollBarHeight = self.verticalScrollBarHeightWhenThumbClicked
	local _, yPosition = GetCursorPosition()
	local newOffset = self.scrollBar:GetTop() - (yPosition / UIParent:GetEffectiveScale()) - currentOffset

	local minAllowedOffset = thumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - thumbPadding.y
	newOffset = max(newOffset, minAllowedOffset)
	newOffset = min(newOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local timelineHeight = self.timelineFrame:GetHeight()
	local maxScroll = timelineHeight - scrollFrameHeight

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * thumbPadding.y)
	local scrollOffset = ((newOffset - thumbPadding.y) / maxThumbPosition) * maxScroll
	scrollFrame:SetVerticalScroll(scrollOffset)
	self.listScrollFrame:SetVerticalScroll(scrollOffset)
end

---@param self EPTimelineSection
local function HandleVerticalThumbMouseDown(self)
	local _, y = GetCursorPosition()
	self.verticalThumbOffsetWhenThumbClicked = self.thumb:GetTop() - (y / UIParent:GetEffectiveScale())
	self.verticalScrollBarHeightWhenThumbClicked = self.scrollBar:GetHeight()
	self.verticalThumbHeightWhenThumbClicked = self.thumb:GetHeight()
	self.verticalThumbIsDragging = true
	self.thumb:SetScript("OnUpdate", function()
		HandleVerticalThumbUpdate(self)
	end)
end

---@param self EPTimelineSection
local function HandleVerticalThumbMouseUp(self)
	self.verticalThumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

---@class SharedTimelineSectionData
---@field verticalPositionLineOffset number
---@field verticalPositionLineVisible boolean
---@field timelineFrameWidth number
---@field horizontalScroll number
---@field zoomFactor number
---@field timelineLinePadding {x: number, y: number}

---@class EPTimelineSection : AceGUIWidget
---@field type string
---@field frame table|Frame
---@field listFrame table|ScrollFrame
---@field listScrollFrame table|Frame
---@field scrollFrame table|ScrollFrame
---@field timelineFrame table|Frame
---@field verticalPositionLine Texture
---@field scrollBar table|Frame
---@field thumb table|Frame
---@field ticks table<number, table<number, Texture>>
---@field verticalThumbOffsetWhenThumbClicked number
---@field verticalScrollBarHeightWhenThumbClicked number
---@field verticalThumbHeightWhenThumbClicked number
---@field verticalThumbIsDragging boolean
---@field textureHeight number
---@field listPadding number
---@field listContainer EPContainer

---@param self EPTimelineSection
local function OnAcquire(self)
	self.frame:Show()
	self.ticks = self.ticks or {}
	self.ticks[1] = self.ticks[1] or {}
	self.verticalThumbOffsetWhenThumbClicked = 0
	self.verticalScrollBarHeightWhenThumbClicked = 0
	self.verticalThumbHeightWhenThumbClicked = 0
	self.verticalThumbIsDragging = false
	self.textureHeight = 0
	self.listPadding = defaultListPadding
	self.listContainer = AceGUI:Create("EPContainer")
	self.listFrame:SetWidth(listFrameWidth)
	self.listScrollFrame:SetWidth(listFrameWidth)
	self.listContainer.frame:SetParent(self.listFrame)
	self.listContainer.frame:SetPoint("TOPLEFT", self.listFrame, "TOPLEFT")
	self.listContainer:SetLayout("EPVerticalLayout")
	self.listContainer:SetWidth(listFrameWidth)
	self:SetListPadding(defaultListPadding)
	self.scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", listFrameWidth + listTimelinePadding, 0)
end

---@param self EPTimelineSection
local function OnRelease(self)
	self.listContainer:Release()
	self.listContainer = nil
	for _, ticks in pairs(self.ticks) do
		for _, tick in pairs(ticks) do
			tick:Hide()
		end
	end
	for _, ticks in pairs(self.ticks) do
		for _, tick in pairs(ticks) do
			tick:Hide()
		end
	end
end

---@param self EPTimelineSection
---@param height number
local function OnHeightSet(self, height)
	self.scrollFrame:SetHeight(height)
	self.listScrollFrame:SetHeight(height)
end

---@param self EPTimelineSection
---@return table<number, table<number, Texture>>
local function GetTicks(self)
	return self.ticks
end

---@param self EPTimelineSection
---@param padding number
local function SetListPadding(self, padding)
	self.listPadding = padding
	self.listContainer:SetSpacing(0, padding)
end

---@param self EPTimelineSection
---@param height number
local function SetTimelineFrameHeight(self, height)
	self.timelineFrame:SetHeight(height)
	self.listFrame:SetHeight(height)
	self:UpdateVerticalScroll()
end

---@param self EPTimelineSection
---@param height number
local function SetTextureHeight(self, height)
	self.textureHeight = height
end

---@param self EPTimelineSection
local function UpdateVerticalScroll(self)
	local scrollBarHeight = self.scrollBar:GetHeight()
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local timelineHeight = self.timelineFrame:GetHeight()
	local verticalScroll = self.scrollFrame:GetVerticalScroll()

	local thumbHeight = (scrollFrameHeight / timelineHeight) * (scrollBarHeight - (2 * thumbPadding.y))
	thumbHeight = max(thumbHeight, 20) -- Minimum size so it's always visible
	thumbHeight = min(thumbHeight, scrollFrameHeight - (2 * thumbPadding.y))
	self.thumb:SetHeight(thumbHeight)

	local maxScroll = timelineHeight - scrollFrameHeight
	local maxThumbPosition = scrollBarHeight - thumbHeight - (2 * thumbPadding.y)
	local verticalThumbPosition = 0
	if maxScroll > 0 then
		verticalThumbPosition = (verticalScroll / maxScroll) * maxThumbPosition
		verticalThumbPosition = verticalThumbPosition + thumbPadding.x
	else
		verticalThumbPosition = thumbPadding.y -- If no scrolling is possible, reset the thumb to the start
	end
	self.thumb:SetPoint("TOP", 0, -verticalThumbPosition)
end

---@param self EPTimelineSection
---@param distanceToTop number Distance from the top of the scroll frame to the top of the frame to make visible
---@param distanceToBottom number Distance from the top of the scroll frame to the bottom of the frame to make visible
local function ScrollVerticallyIfNotVisible(self, distanceToTop, distanceToBottom)
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local timelineFrameHeight = self.timelineFrame:GetHeight()

	local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()
	local distanceFromTopScrollFrameToBottomTimelineFrame = currentVerticalScroll + self.scrollFrame:GetHeight()
	local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
	local newVerticalScroll = nil

	if abs(distanceToBottom) > distanceFromTopScrollFrameToBottomTimelineFrame then
		local difference = abs(distanceToBottom) - distanceFromTopScrollFrameToBottomTimelineFrame
		newVerticalScroll = currentVerticalScroll + difference
	elseif abs(distanceToTop) < currentVerticalScroll then
		newVerticalScroll = abs(distanceToTop)
	end

	if newVerticalScroll then
		local snapValue = (self.textureHeight + self.listPadding) / 2
		local currentSnapValue = floor((newVerticalScroll / snapValue) + 0.5)
		newVerticalScroll = max(min(currentSnapValue * snapValue, maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		self.listScrollFrame:SetVerticalScroll(newVerticalScroll)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
	scrollFrame:SetPoint("TOPLEFT")
	scrollFrame:SetPoint("RIGHT", -scrollBarWidth - paddingBetweenTimelineAndScrollBar, 0)

	local listScrollFrame = CreateFrame("ScrollFrame", Type .. "ListScrollFrame" .. count, frame)
	listScrollFrame:SetPoint("TOPLEFT")
	listScrollFrame:SetWidth(listFrameWidth)

	local listFrame = CreateFrame("Frame", Type .. "ListFrame" .. count, listScrollFrame)
	listFrame:SetPoint("TOPLEFT")
	listFrame:SetWidth(listFrameWidth)
	listFrame:EnableMouse(true)

	listScrollFrame:SetScrollChild(listFrame)
	listScrollFrame:EnableMouseWheel(true)

	local timelineFrame = CreateFrame("Frame", Type .. "TimelineFrame" .. count, scrollFrame)
	timelineFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	timelineFrame:EnableMouse(true)
	timelineFrame:RegisterForDrag("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")

	scrollFrame:SetScrollChild(timelineFrame)
	scrollFrame:EnableMouseWheel(true)

	local verticalPositionLine =
		timelineFrame:CreateTexture(Type .. "PositionLine" .. count, "OVERLAY", nil, verticalPositionLineSubLevel)
	verticalPositionLine:SetColorTexture(unpack(verticalPositionLineColor))
	verticalPositionLine:SetPoint("TOP", scrollFrame, "TOPLEFT")
	verticalPositionLine:SetPoint("BOTTOM", scrollFrame, "BOTTOMLEFT")
	verticalPositionLine:SetWidth(1)
	verticalPositionLine:Hide()

	local verticalScrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	verticalScrollBar:SetWidth(scrollBarWidth)
	verticalScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	verticalScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	local verticalScrollBarBackground =
		verticalScrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(0.25, 0.25, 0.25, 1)

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, verticalScrollBar)
	verticalThumb:SetPoint("TOP", 0, thumbPadding.y)
	verticalThumb:SetSize(scrollBarWidth - (2 * thumbPadding.x), verticalScrollBar:GetHeight() - 2 * thumbPadding.y)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(0.05, 0.05, 0.05, 1)

	---@class EPTimelineSection
	local widget = {
		frame = frame,
		scrollFrame = scrollFrame,
		type = Type,
		timelineFrame = timelineFrame,
		listFrame = listFrame,
		listScrollFrame = listScrollFrame,
		verticalPositionLine = verticalPositionLine,
		scrollBar = verticalScrollBar,
		thumb = verticalThumb,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		OnHeightSet = OnHeightSet,
		GetTicks = GetTicks,
		SetListPadding = SetListPadding,
		SetTimelineFrameHeight = SetTimelineFrameHeight,
		SetTextureHeight = SetTextureHeight,
		UpdateVerticalScroll = UpdateVerticalScroll,
		ScrollVerticallyIfNotVisible = ScrollVerticallyIfNotVisible,
		verticalThumbOffsetWhenThumbClicked = 0,
		verticalScrollBarHeightWhenThumbClicked = 0,
		verticalThumbHeightWhenThumbClicked = 0,
		verticalThumbIsDragging = false,
	}

	verticalThumb:SetScript("OnMouseDown", function()
		HandleVerticalThumbMouseDown(widget)
	end)
	verticalThumb:SetScript("OnMouseUp", function()
		HandleVerticalThumbMouseUp(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
