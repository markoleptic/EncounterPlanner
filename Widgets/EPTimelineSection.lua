local Type = "EPTimelineSection"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local IsControlKeyDown = IsControlKeyDown
local max = math.max
local min = math.min

local frameWidth = 400
local frameHeight = 400
local verticalPositionLineSubLevel = -8
local verticalPositionLineColor = { 1, 0.82, 0, 1 }
local scrollBarWidth = 20
local thumbPadding = { x = 2, y = 2 }
local paddingBetweenTimelineAndScrollBar = 10
local minZoomFactor = 1
local maxZoomFactor = 10
local zoomStep = 0.05
local defaultListPadding = 4
local listFrameWidth = 200
local listTimelinePadding = 10

local function UpdateLinePosition(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	local xPosition, _ = GetCursorPosition()
	local newTimeOffset = (xPosition / UIParent:GetEffectiveScale()) - self.timelineFrame:GetLeft()

	self.verticalPositionLine:SetPoint("TOP", self.timelineFrame, "TOPLEFT", newTimeOffset, 0)
	self.verticalPositionLine:SetPoint("BOTTOM", self.timelineFrame, "BOTTOMLEFT", newTimeOffset, 0)
	self.verticalPositionLine:Show()

	local padding = self.staticTimelineSectionData.timelineLinePadding.x
	local time = (newTimeOffset - padding) * self.totalTimelineDuration / (self.timelineFrame:GetWidth() - padding * 2)
	time = min(max(0, time), self.totalTimelineDuration)
	local minutes = floor(time / 60)
	local seconds = time % 60
	self.currentTimeLabel:SetText(string.format("%d:%02d", minutes, seconds))

	if
		self.staticTimelineSectionData.verticalPositionLineVisible ~= true
		or self.staticTimelineSectionData.verticalPositionLineOffset ~= newTimeOffset
	then
		self.staticTimelineSectionData.verticalPositionLineVisible = true
		self.staticTimelineSectionData.verticalPositionLineOffset = newTimeOffset
		self:Fire("StaticDataChanged", false)
	end
end

local function HandleTimelineFrameEnter(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	if self.timelineFrameIsDragging == true then
		return
	end
	frame:SetScript("OnUpdate", function()
		UpdateLinePosition(frame)
	end)
end

local function HandleTimelineFrameLeave(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	if self.timelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", nil)
	self.verticalPositionLine:Hide()

	if self.staticTimelineSectionData.verticalPositionLineVisible ~= false then
		self.staticTimelineSectionData.verticalPositionLineVisible = false
		self:Fire("StaticDataChanged", false)
	end
end

-- Updates the scroll bar width and offset based on the visible area of the timeline.
---@param self EPTimelineSection
local function UpdateScrollBarPrivate(self)
	local scrollFrame = self.scrollFrame

	local scrollFrameHeight = scrollFrame:GetHeight()
	local scrollFrameWidth = scrollFrame:GetWidth()

	local timelineHeight = self.timelineFrame:GetHeight()
	local timelineWidth = self.timelineFrame:GetWidth()

	local verticalScrollBarHeight = self.scrollBar:GetHeight()
	local horizontalScrollBarWidth = self.horizontalScrollBar:GetWidth()

	-- Calculate the scroll bar thumb size based on the visible area
	local thumbWidth = (scrollFrameWidth / timelineWidth) * (horizontalScrollBarWidth - (2 * thumbPadding.x))
	thumbWidth = max(thumbWidth, 20) -- Minimum size so it's always visible
	thumbWidth = min(thumbWidth, scrollFrameWidth - (2 * thumbPadding.x))
	local horizontalThumb = self.horizontalScrollBar.thumb
	horizontalThumb:SetWidth(thumbWidth)

	local scrollOffset = scrollFrame:GetHorizontalScroll()
	local maxScroll = timelineWidth - scrollFrameWidth
	local maxThumbPosition = horizontalScrollBarWidth - thumbWidth - (2 * thumbPadding.x)
	local horizontalThumbPosition = 0
	if maxScroll > 0 then -- Prevent division by zero if maxScroll is 0
		horizontalThumbPosition = (scrollOffset / maxScroll) * maxThumbPosition
		horizontalThumbPosition = horizontalThumbPosition + thumbPadding.x
	else
		horizontalThumbPosition = thumbPadding.x -- If no scrolling is possible, reset the thumb to the start
	end
	horizontalThumb:SetPoint("LEFT", horizontalThumbPosition, 0)

	local thumbHeight = (scrollFrameHeight / timelineHeight) * (verticalScrollBarHeight - (2 * thumbPadding.y))
	thumbHeight = max(thumbHeight, 20)
	thumbHeight = min(thumbHeight, scrollFrameHeight - (2 * thumbPadding.y))
	local verticalThumb = self.thumb
	verticalThumb:SetHeight(thumbHeight)

	local verticalScrollOffset = scrollFrame:GetVerticalScroll()
	local maxVerticalScroll = timelineHeight - scrollFrameHeight
	local maxVerticalThumbPosition = verticalScrollBarHeight - thumbHeight - (2 * thumbPadding.y)
	local verticalThumbPosition = 0
	if maxVerticalScroll > 0 then -- Prevent division by zero if maxScroll is 0
		verticalThumbPosition = (verticalScrollOffset / maxVerticalScroll) * maxVerticalThumbPosition
		verticalThumbPosition = -(thumbPadding.x + verticalThumbPosition)
	else
		verticalThumbPosition = -thumbPadding.x -- If no scrolling is possible, reset the thumb to the start
	end
	verticalThumb:SetPoint("TOP", 0, verticalThumbPosition)
end

local function HandleTimelineFrameMouseWheel(frame, delta, updateBoth)
	local self = frame.obj --[[@as EPTimelineSection]]
	if not self.totalTimelineDuration or self.totalTimelineDuration <= 0 then
		return
	end

	local controlKeyDown = IsControlKeyDown()
	local scrollFrame = self.scrollFrame
	local timelineFrame = self.timelineFrame

	if not controlKeyDown or updateBoth then
		local scrollFrameHeight = scrollFrame:GetHeight()
		local timelineFrameHeight = timelineFrame:GetHeight()

		local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
		local currentVerticalScroll = scrollFrame:GetVerticalScroll()
		local snapValue = (self.textureHeight + self.listPadding) / 2
		local currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)

		if delta > 0 then
			currentSnapValue = currentSnapValue - 1
		elseif delta < 0 then
			currentSnapValue = currentSnapValue + 1
		end

		local newVerticalScroll = max(min(currentSnapValue * snapValue, maxVerticalScroll), 0)
		scrollFrame:SetVerticalScroll(newVerticalScroll)
		self.listScrollFrame:SetVerticalScroll(newVerticalScroll)
	end

	if controlKeyDown or updateBoth then
		local timelineDuration = self.totalTimelineDuration
		local zoomFactor = self.staticTimelineSectionData.zoomFactor
		local visibleDuration = timelineDuration / zoomFactor
		local visibleStartTime = (scrollFrame:GetHorizontalScroll() / timelineFrame:GetWidth()) * timelineDuration
		local visibleEndTime = visibleStartTime + visibleDuration
		local visibleMidpointTime = (visibleStartTime + visibleEndTime) / 2.0

		-- Update zoom factor based on scroll delta
		if delta > 0 and zoomFactor < maxZoomFactor then
			zoomFactor = zoomFactor * (1.0 + zoomStep)
		elseif delta < 0 and zoomFactor > minZoomFactor then
			zoomFactor = zoomFactor / (1.0 + zoomStep)
		end

		-- Recalculate visible duration after zoom
		local newVisibleDuration = timelineDuration / zoomFactor

		-- Calculate new start and end time while keeping midpoint constant
		local newVisibleStartTime = visibleMidpointTime - (newVisibleDuration / 2.0)
		local newVisibleEndTime = visibleMidpointTime + (newVisibleDuration / 2.0)

		-- Add overflow from end time to start time to prevent empty space between end of timeline and parent frame
		if newVisibleEndTime > timelineDuration then
			local surplus = timelineDuration - newVisibleEndTime
			newVisibleEndTime = timelineDuration
			newVisibleStartTime = newVisibleStartTime + surplus
		end

		-- Ensure boundaries are within the total timeline range
		newVisibleStartTime = max(0, newVisibleStartTime)
		newVisibleEndTime = min(timelineDuration, newVisibleEndTime)

		-- Adjust the timeline frame width based on zoom factor
		local newTimelineFrameWidth = scrollFrame:GetWidth() * zoomFactor

		-- Recalculate the new scroll position based on the new visible start time
		local newHorizontalScroll = (newVisibleStartTime / timelineDuration) * newTimelineFrameWidth

		scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		timelineFrame:SetWidth(newTimelineFrameWidth)

		if
			self.staticTimelineSectionData.zoomFactor ~= zoomFactor
			or self.staticTimelineSectionData.timelineFrameWidth ~= newTimelineFrameWidth
			or self.staticTimelineSectionData.horizontalScroll ~= newHorizontalScroll
		then
			self.staticTimelineSectionData.zoomFactor = zoomFactor
			self.staticTimelineSectionData.timelineFrameWidth = newTimelineFrameWidth
			self.staticTimelineSectionData.horizontalScroll = newHorizontalScroll
			self:Fire("StaticDataChanged", true)
		end
	end

	UpdateScrollBarPrivate(self)
end

local function HandleTimelineFrameUpdate(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	if not self.timelineFrameIsDragging then
		return
	end

	local scrollFrame = self.scrollFrame
	local x, _ = GetCursorPosition()
	local dx = (x - self.timelineFrameDragStartX) / scrollFrame:GetEffectiveScale()
	local newHorizontalScroll = scrollFrame:GetHorizontalScroll() - dx
	local maxHorizontalScroll = self.timelineFrame:GetWidth() - scrollFrame:GetWidth()
	newHorizontalScroll = min(max(0, newHorizontalScroll), maxHorizontalScroll)
	scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.timelineFrameDragStartX = x

	if self.staticTimelineSectionData.horizontalScroll ~= newHorizontalScroll then
		self.staticTimelineSectionData.horizontalScroll = newHorizontalScroll
		self:Fire("StaticDataChanged", true)
		UpdateScrollBarPrivate(self)
	end
end

local function HandleTimelineFrameDragStart(frame, button)
	local self = frame.obj --[[@as EPTimelineSection]]
	self.timelineFrameIsDragging = true
	local x, _ = GetCursorPosition()
	self.timelineFrameDragStartX = x

	self.verticalPositionLine:Hide()

	if self.staticTimelineSectionData.verticalPositionLineVisible ~= false then
		self.staticTimelineSectionData.verticalPositionLineVisible = false
		self:Fire("StaticDataChanged", false)
	end

	frame:SetScript("OnUpdate", HandleTimelineFrameUpdate)
end

local function HandleTimelineFrameDragStop(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	self.timelineFrameIsDragging = false
	frame:SetScript("OnUpdate", nil)

	local x, y = GetCursorPosition()
	x = x / UIParent:GetEffectiveScale()
	y = y / UIParent:GetEffectiveScale()
	local scrollFrame = self.scrollFrame

	if
		x > scrollFrame:GetLeft()
		and x < scrollFrame:GetRight()
		and y < scrollFrame:GetTop()
		and y > scrollFrame:GetBottom()
	then
		local timelineFrame = self.timelineFrame
		timelineFrame:SetScript("OnUpdate", function()
			UpdateLinePosition(timelineFrame)
		end)
	end
end

local function HandleVerticalThumbUpdate(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
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

local function HandleVerticalThumbMouseDown(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
	local _, y = GetCursorPosition()
	self.verticalThumbOffsetWhenThumbClicked = self.thumb:GetTop() - (y / UIParent:GetEffectiveScale())
	self.verticalScrollBarHeightWhenThumbClicked = self.scrollBar:GetHeight()
	self.verticalThumbHeightWhenThumbClicked = self.thumb:GetHeight()
	self.verticalThumbIsDragging = true
	self.thumb:SetScript("OnUpdate", HandleVerticalThumbUpdate)
end

local function HandleVerticalThumbMouseUp(frame)
	local self = frame.obj --[[@as EPTimelineSection]]
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
---@field horizontalScrollBar table|Frame
---@field ticks table<number, Texture>
---@field totalTimelineDuration number
---@field verticalThumbOffsetWhenThumbClicked number
---@field verticalScrollBarHeightWhenThumbClicked number
---@field verticalThumbHeightWhenThumbClicked number
---@field verticalThumbIsDragging boolean
---@field timelineFrameIsDragging boolean
---@field timelineFrameDragStartX number
---@field staticTimelineSectionData SharedTimelineSectionData
---@field textureHeight number
---@field listPadding number
---@field listContainer EPContainer
---@field currentTimeLabel EPLabel

---@param self EPTimelineSection
local function OnAcquire(self)
	self.frame:Show()
	self.ticks = self.ticks or {}
	self.verticalThumbOffsetWhenThumbClicked = 0
	self.verticalScrollBarHeightWhenThumbClicked = 0
	self.verticalThumbHeightWhenThumbClicked = 0
	self.verticalThumbIsDragging = false
	self.timelineFrameIsDragging = false
	self.timelineFrameDragStartX = 0
	self.textureHeight = 0
	self.listPadding = defaultListPadding
	self.listContainer = AceGUI:Create("EPContainer")
	self.listFrame:SetWidth(listFrameWidth)
	self.listScrollFrame:SetWidth(listFrameWidth)
	self.listContainer.frame:SetParent(self.listFrame)
	self.listContainer.frame:SetPoint("TOPLEFT", self.listFrame, "TOPLEFT")
	self.listContainer:SetLayout("EPVerticalLayout")
	self.listContainer:SetFullWidth(true)
	self:SetListPadding(defaultListPadding)
	self.scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", listFrameWidth + listTimelinePadding, 0)
end

---@param self EPTimelineSection
local function SetSharedData(self, data)
	self.staticTimelineSectionData = data
end

---@param self EPTimelineSection
local function OnRelease(self)
	self.listContainer:Release()
	self.listContainer = nil
	self.horizontalScrollBar = nil
	self.staticTimelineSectionData = nil
	self.currentTimeLabel = nil
end

---@param self EPTimelineSection
---@param height number
local function OnHeightSet(self, height)
	self.scrollFrame:SetHeight(height)
	self.listScrollFrame:SetHeight(height)
end

---@param self EPTimelineSection
local function GetFrame(self)
	return self.frame
end

---@param self EPTimelineSection
local function GetScrollFrame(self)
	return self.scrollFrame
end

---@param self EPTimelineSection
---@return Frame|table
local function GetTimelineFrame(self)
	return self.timelineFrame
end

---@param self EPTimelineSection
---@return table<number, Texture>
local function GetTicks(self)
	return self.ticks
end

---@param self EPTimelineSection
---@return EPContainer
local function GetListContainer(self)
	return self.listContainer
end

---@param self EPTimelineSection
---@param horizontalScrollBar table|Frame
local function SetHorizontalScrollBarReference(self, horizontalScrollBar)
	self.horizontalScrollBar = horizontalScrollBar
end

---@param self EPTimelineSection
---@param totalTimelineDuration number
local function SetTimelineDuration(self, totalTimelineDuration)
	self.totalTimelineDuration = totalTimelineDuration
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
end

---@param self EPTimelineSection
---@param height number
local function SetTextureHeight(self, height)
	self.textureHeight = height
end

---@param self EPTimelineSection
local function SyncFromStaticData(self)
	local data = self.staticTimelineSectionData
	self.verticalPositionLine:SetPoint("TOP", self.timelineFrame, "TOPLEFT", data.verticalPositionLineOffset, 0)
	self.verticalPositionLine:SetPoint("BOTTOM", self.timelineFrame, "BOTTOMLEFT", data.verticalPositionLineOffset, 0)
	if data.verticalPositionLineVisible == true then
		self.verticalPositionLine:Show()
	else
		self.verticalPositionLine:Hide()
	end
	self.scrollFrame:SetHorizontalScroll(data.horizontalScroll)
	self.timelineFrame:SetWidth(data.timelineFrameWidth)
end

---@param self EPTimelineSection
---@param horizontalScroll number
local function SetHorizontalScroll(self, horizontalScroll)
	self.staticTimelineSectionData.horizontalScroll = horizontalScroll
	self.scrollFrame:SetHorizontalScroll(horizontalScroll)
end

---@param self EPTimelineSection
local function UpdateScrollBar(self)
	UpdateScrollBarPrivate(self)
end

---@param self EPTimelineSection
local function UpdateWidthAndScroll(self)
	HandleTimelineFrameMouseWheel(self.timelineFrame, 0, true)
end

---@param self EPTimelineSection
---@return number
local function GetMaxScroll(self)
	return self.timelineFrame:GetWidth() - self.scrollFrame:GetWidth()
end

---@param self EPTimelineSection
---@return number, number
local function GetHorizontalScrollAndWidth(self)
	return self.scrollFrame:GetHorizontalScroll(), self.timelineFrame:GetWidth()
end

---@param self EPTimelineSection
---@return number
local function GetZoomFactor(self)
	return self.staticTimelineSectionData.zoomFactor
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(frameWidth, frameHeight)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
	scrollFrame:SetPoint("TOPLEFT")
	scrollFrame:SetPoint("RIGHT", -scrollBarWidth - paddingBetweenTimelineAndScrollBar, 0)
	scrollFrame:SetSize(frameWidth - scrollBarWidth - paddingBetweenTimelineAndScrollBar, frameHeight)

	local listScrollFrame = CreateFrame("ScrollFrame", Type .. "ListScrollFrame" .. count, frame)
	listScrollFrame:SetPoint("TOPLEFT")
	listScrollFrame:SetSize(listFrameWidth, frameHeight)

	local listFrame = CreateFrame("Frame", Type .. "ListFrame" .. count, listScrollFrame)
	listFrame:SetPoint("TOPLEFT")
	listFrame:SetSize(listFrameWidth, frameHeight)
	listFrame:EnableMouse(true)
	listFrame:SetScript("OnMouseWheel", HandleTimelineFrameMouseWheel)

	listScrollFrame:SetScrollChild(listFrame)
	listScrollFrame:EnableMouseWheel(true)

	local timelineFrame = CreateFrame("Frame", Type .. "TimelineFrame" .. count, scrollFrame)
	timelineFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	timelineFrame:SetSize(frameWidth - scrollBarWidth - paddingBetweenTimelineAndScrollBar, frameHeight)
	timelineFrame:EnableMouse(true)
	timelineFrame:RegisterForDrag("LeftButton")
	timelineFrame:SetScript("OnMouseWheel", HandleTimelineFrameMouseWheel)
	timelineFrame:SetScript("OnDragStart", HandleTimelineFrameDragStart)
	timelineFrame:SetScript("OnDragStop", HandleTimelineFrameDragStop)
	timelineFrame:SetScript("OnEnter", HandleTimelineFrameEnter)
	timelineFrame:SetScript("OnLeave", HandleTimelineFrameLeave)

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
	verticalThumb:SetScript("OnMouseDown", HandleVerticalThumbMouseDown)
	verticalThumb:SetScript("OnMouseUp", HandleVerticalThumbMouseUp)

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
		GetFrame = GetFrame,
		GetScrollFrame = GetScrollFrame,
		GetTimelineFrame = GetTimelineFrame,
		GetTicks = GetTicks,
		GetListContainer = GetListContainer,
		SetHorizontalScrollBarReference = SetHorizontalScrollBarReference,
		UpdateScrollBar = UpdateScrollBar,
		UpdateWidthAndScroll = UpdateWidthAndScroll,
		SetTimelineDuration = SetTimelineDuration,
		SyncFromStaticData = SyncFromStaticData,
		GetHorizontalScrollAndWidth = GetHorizontalScrollAndWidth,
		GetMaxScroll = GetMaxScroll,
		GetZoomFactor = GetZoomFactor,
		SetHorizontalScroll = SetHorizontalScroll,
		SetSharedData = SetSharedData,
		SetListPadding = SetListPadding,
		SetTimelineFrameHeight = SetTimelineFrameHeight,
		SetTextureHeight = SetTextureHeight,
	}

	frame.obj = widget
	listFrame.obj = widget
	scrollFrame.obj = widget
	timelineFrame.obj = widget
	verticalScrollBar.obj = widget
	verticalThumb.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
