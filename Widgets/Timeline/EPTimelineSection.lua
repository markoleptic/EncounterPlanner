local Type = "EPTimelineSection"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local abs = math.abs
local Clamp = Clamp
local CreateFrame = CreateFrame
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local unpack = unpack

local k = {
	DefaultListPadding = 4,
	ListFrameWidth = 200,
	ListTimelinePadding = 10,
	MinThumbSize = 20,
	PaddingBetweenTimelineAndScrollBar = 10,
	ScrollBarWidth = 20,
	ThumbPadding = { x = 2, y = 2 },
	VerticalPositionLineColor = { 1, 0.82, 0, 1 },
	VerticalPositionLineSubLevel = -8,
	VerticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 },
	VerticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 },
}
k.TotalVerticalThumbPadding = 2 * k.ThumbPadding.y

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

	local minAllowedOffset = k.ThumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - k.ThumbPadding.y
	newOffset = Clamp(newOffset, minAllowedOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local timelineHeight = self.timelineFrame:GetHeight()
	local maxScroll = timelineHeight - scrollFrameHeight

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * k.ThumbPadding.y)

	if maxScroll <= 0 or maxThumbPosition <= 0 then
		-- No scrollable content or thumb fills the scroll bar
		scrollFrame:SetVerticalScroll(0)
		self.listScrollFrame:SetVerticalScroll(0)
		return
	end

	local scrollOffset = ((newOffset - k.ThumbPadding.y) / maxThumbPosition) * maxScroll
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

---@param self EPTimelineSection
local function OnAcquire(self)
	self.ticks = self.ticks or {}
	self.verticalThumbOffsetWhenThumbClicked = 0
	self.verticalScrollBarHeightWhenThumbClicked = 0
	self.verticalThumbHeightWhenThumbClicked = 0
	self.verticalThumbIsDragging = false
	self.textureHeight = 0
	self.listPadding = k.DefaultListPadding

	self.listScrollFrame:ClearAllPoints()
	self.listScrollFrame:SetParent(self.frame)
	self.listScrollFrame:SetPoint("TOP")
	self.listScrollFrame:SetPoint("LEFT")
	self.listScrollFrame:SetWidth(k.ListFrameWidth)
	self.listScrollFrame:Show()

	self.listContainer = AceGUI:Create("EPContainer")
	self.listContainer.frame:SetParent(self.listScrollFrame)
	self.listContainer.frame:SetPoint("TOPLEFT")
	self.listContainer.frame:EnableMouse(true)
	self.listContainer:SetLayout("EPVerticalLayout")
	self.listContainer:SetWidth(k.ListFrameWidth)
	self:SetListPadding(k.DefaultListPadding)

	self.listScrollFrame:SetScrollChild(self.listContainer.frame)

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(self.frame)
	self.scrollFrame:SetPoint("TOP")
	self.scrollFrame:SetPoint("LEFT", k.ListFrameWidth + k.ListTimelinePadding, 0)
	self.scrollFrame:SetPoint("RIGHT", -k.ScrollBarWidth - k.PaddingBetweenTimelineAndScrollBar, 0)
	self.scrollFrame:Show()

	self.timelineFrame:ClearAllPoints()
	self.timelineFrame:SetParent(self.scrollFrame)
	self.scrollFrame:SetScrollChild(self.timelineFrame)
	self.timelineFrame:SetPoint("TOPLEFT")
	self.timelineFrame:Show()

	self.verticalPositionLine:ClearAllPoints()
	self.verticalPositionLine:SetParent(self.timelineFrame)
	self.verticalPositionLine:SetPoint("TOP", self.scrollFrame, "TOPLEFT")
	self.verticalPositionLine:SetPoint("BOTTOM", self.scrollFrame, "BOTTOMLEFT")
	self.verticalPositionLine:SetWidth(1)
	self.verticalPositionLine:Hide()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(self.frame)
	self.scrollBar:SetWidth(k.ScrollBarWidth)
	self.scrollBar:SetPoint("TOPRIGHT")
	self.scrollBar:Show()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(self.scrollBar)
	self.thumb:SetPoint("TOP", 0, -k.ThumbPadding.y)
	self.thumb:SetSize(k.ScrollBarWidth - (2 * k.ThumbPadding.x), self.scrollBar:GetHeight() - 2 * k.ThumbPadding.y)
	self.thumb:Show()
	self.thumb:SetScript("OnMouseDown", function()
		HandleVerticalThumbMouseDown(self)
	end)
	self.thumb:SetScript("OnMouseUp", function()
		HandleVerticalThumbMouseUp(self)
	end)

	self.frame:Show()
end

---@param self EPTimelineSection
local function OnRelease(self)
	self.listScrollFrame:ClearAllPoints()
	self.listScrollFrame:SetParent(UIParent)
	self.listScrollFrame:Hide()
	self.listScrollFrame:SetHorizontalScroll(0)
	self.listScrollFrame:SetVerticalScroll(0)

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(UIParent)
	self.scrollFrame:Hide()
	self.scrollFrame:SetHorizontalScroll(0)
	self.scrollFrame:SetVerticalScroll(0)

	self.timelineFrame:ClearAllPoints()
	self.timelineFrame:SetParent(UIParent)
	self.timelineFrame:Hide()

	self.verticalPositionLine:ClearAllPoints()
	self.verticalPositionLine:SetParent(UIParent)
	self.verticalPositionLine:Hide()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(UIParent)
	self.scrollBar:Hide()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(UIParent)
	self.thumb:Hide()
	self.thumb:SetScript("OnUpdate", nil)

	self.thumb:SetScript("OnMouseDown", nil)
	self.thumb:SetScript("OnMouseUp", nil)

	self.listContainer:Release()
	self.listContainer = nil

	for _, tick in pairs(self.ticks) do
		tick:Hide()
	end
end

---@param self EPTimelineSection
---@param height number
local function OnHeightSet(self, height)
	self.scrollFrame:SetHeight(height)
	self.listScrollFrame:SetHeight(height)
	self.scrollBar:SetHeight(height)
	local heightDifference = self.timelineFrame:GetHeight() - height
	if heightDifference > 0 then
		local currentScroll = self.scrollFrame:GetVerticalScroll()
		if currentScroll > heightDifference then
			self.scrollFrame:SetVerticalScroll(heightDifference)
			self.listScrollFrame:SetVerticalScroll(heightDifference)
		end
	end
end

---@param self EPTimelineSection
---@return table<number, Texture>
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
	self.listContainer:SetHeight(height)
end

---@param self EPTimelineSection
---@param height number
local function SetTextureHeight(self, height)
	self.textureHeight = height
end

---@param self EPTimelineSection
local function UpdateVerticalScroll(self)
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local timelineHeight = self.timelineFrame:GetHeight()

	local scrollRange = timelineHeight - scrollFrameHeight
	if scrollRange <= 0 then
		-- No scrolling needed, reset thumb
		self.thumb:SetHeight(self.scrollBar:GetHeight() - k.TotalVerticalThumbPadding)
		self.thumb:SetPoint("TOP", 0, -k.ThumbPadding.y)
		return
	end

	local scrollPercentage = self.scrollFrame:GetVerticalScroll() / scrollRange
	local availableThumbHeight = self.scrollBar:GetHeight() - k.TotalVerticalThumbPadding

	local thumbHeight = (scrollFrameHeight / timelineHeight) * availableThumbHeight
	thumbHeight = Clamp(thumbHeight, k.MinThumbSize, availableThumbHeight)
	self.thumb:SetHeight(thumbHeight)

	local maxThumbPosition = availableThumbHeight - thumbHeight
	local verticalThumbPosition = Clamp(scrollPercentage * maxThumbPosition, 0, maxThumbPosition) + k.ThumbPadding.y
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
		newVerticalScroll = Clamp(currentSnapValue * snapValue, 0, maxVerticalScroll)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		self.listScrollFrame:SetVerticalScroll(newVerticalScroll)
	end
	UpdateVerticalScroll(self)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(100, 100)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
	scrollFrame:SetPoint("TOPLEFT")
	scrollFrame:SetPoint("RIGHT", -k.ScrollBarWidth - k.PaddingBetweenTimelineAndScrollBar, 0)

	local listScrollFrame = CreateFrame("ScrollFrame", Type .. "ListScrollFrame" .. count, frame)
	listScrollFrame:SetPoint("TOPLEFT")
	listScrollFrame:SetSize(k.ListFrameWidth, 1)
	listScrollFrame:EnableMouseWheel(true)

	local timelineFrame = CreateFrame("Frame", Type .. "TimelineFrame" .. count, scrollFrame)
	timelineFrame:SetSize(100, 100)
	timelineFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	timelineFrame:EnableMouse(true)
	timelineFrame:RegisterForDrag("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")

	scrollFrame:SetScrollChild(timelineFrame)
	scrollFrame:EnableMouseWheel(true)

	local verticalPositionLine =
		timelineFrame:CreateTexture(Type .. "PositionLine" .. count, "OVERLAY", nil, k.VerticalPositionLineSubLevel)
	verticalPositionLine:SetColorTexture(unpack(k.VerticalPositionLineColor))
	verticalPositionLine:SetPoint("TOP", scrollFrame, "TOPLEFT")
	verticalPositionLine:SetPoint("BOTTOM", scrollFrame, "BOTTOMLEFT")
	verticalPositionLine:SetWidth(1)
	verticalPositionLine:Hide()

	local verticalScrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	verticalScrollBar:SetWidth(k.ScrollBarWidth)
	verticalScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	verticalScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	local verticalScrollBarBackground =
		verticalScrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(unpack(k.VerticalScrollBackgroundColor))

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, verticalScrollBar)
	verticalThumb:SetPoint("TOP", 0, k.ThumbPadding.y)
	verticalThumb:SetSize(
		k.ScrollBarWidth - (2 * k.ThumbPadding.x),
		verticalScrollBar:GetHeight() - 2 * k.ThumbPadding.y
	)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(unpack(k.VerticalThumbBackgroundColor))

	---@class EPTimelineSection : AceGUIWidget
	---@field ticks table<number, Texture>
	---@field verticalThumbOffsetWhenThumbClicked number
	---@field verticalScrollBarHeightWhenThumbClicked number
	---@field verticalThumbHeightWhenThumbClicked number
	---@field verticalThumbIsDragging boolean
	---@field textureHeight number
	---@field listPadding number
	---@field listContainer EPContainer
	local widget = {
		frame = frame,
		scrollFrame = scrollFrame,
		type = Type,
		count = count,
		timelineFrame = timelineFrame,
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

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
