local Type                      = "EPTimeline"
local Version                   = 1
local AceGUI                    = LibStub("AceGUI-3.0")
local LSM                       = LibStub("LibSharedMedia-3.0")

local frameWidth                = 900
local frameHeight               = 500
local barHeight                 = 30
local paddingBetweenBars        = 4
local horizontalScrollBarHeight = 20
local scrollBarThumbPadding     = { x = 2, y = 2 }
local tickWidth                 = 2
local fontPath                  = LSM:Fetch("font", "PT Sans Narrow")
local tickColor                 = { 1, 1, 1, 0.75 }
local tickFontSize              = 10
local tickTextOffset            = { x = 0, y = 5 }
local timelineLinePadding       = { x = 25, y = 25 }
local zoomFactor                = 1
local minZoomFactor             = 1
local maxZoomFactor             = 10
local zoomStep                  = 0.05
local colors                    = {
	{ 255, 87,  51, 1 },
	{ 51,  255, 87, 1 }, { 51, 87, 255, 1 }, { 255, 51, 184, 1 }, { 255, 214, 51, 1 },
	{ 51, 255, 249, 1 }, { 184, 51, 255, 1 } }

local function HandleThumbUpdate(frame)
	local self = frame.obj
	local private = self.private
	if not private.thumbIsDragging then return end

	local paddingX = private.thumbPadding.x
	local currentOffset = private.thumbOffsetWhenThumbClicked
	local currentWidth = private.thumbWidthWhenThumbClicked
	local currentScrollBarWidth = private.scrollBarWidthWhenThumbClicked
	local xPosition, _ = GetCursorPosition()
	local newOffset = (xPosition / UIParent:GetEffectiveScale()) - self.scrollBar:GetLeft() - currentOffset

	local minAllowedOffset = paddingX
	local maxAllowedOffset = currentScrollBarWidth - currentWidth - paddingX
	newOffset = math.max(newOffset, minAllowedOffset)
	newOffset = math.min(newOffset, maxAllowedOffset)
	self.thumb:SetPoint("LEFT", newOffset, 0)

	local scrollFrame = self.frame
	local scrollFrameWidth = scrollFrame:GetWidth()
	local timelineWidth = self.timelineFrame:GetWidth()
	local maxScroll = timelineWidth - scrollFrameWidth

	-- Calculate the scroll frame's horizontal scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * paddingX)
	local scrollOffset = ((newOffset - paddingX) / maxThumbPosition) * maxScroll
	scrollFrame:SetHorizontalScroll(scrollOffset)
end

local function HandleThumbMouseDown(frame)
	local self = frame.obj
	local x, _ = GetCursorPosition()
	self.private.thumbOffsetWhenThumbClicked = (x / UIParent:GetEffectiveScale()) - self.thumb:GetLeft()
	self.private.scrollBarWidthWhenThumbClicked = self.scrollBar:GetWidth()
	self.private.thumbWidthWhenThumbClicked = self.thumb:GetWidth()
	self.private.thumbIsDragging = true
	self.thumb:SetScript("OnUpdate", HandleThumbUpdate)
end

local function HandleThumbMouseUp(frame)
	local self = frame.obj
	self.private.thumbIsDragging = nil
	self.thumb:SetScript("OnUpdate", nil)
end

local function HandleTimelineFrameUpdate(frame)
	local self = frame.obj
	local private = self.private
	if not private.timelineFrameIsDragging then return end

	local timelineFrame = self.timelineFrame
	local scrollFrame = self.frame

	local currentX, _ = GetCursorPosition()
	local dx = (currentX - private.timelineFrameDragStartX) / scrollFrame:GetEffectiveScale()
	local newScrollH = scrollFrame:GetHorizontalScroll() - dx
	local maxScrollH = timelineFrame:GetWidth() - scrollFrame:GetWidth()

	scrollFrame:SetHorizontalScroll(math.min(math.max(0, newScrollH), maxScrollH))
	private.timelineFrameDragStartX = currentX
	self:UpdateScrollBar()
end

local function HandleTimelineFrameDragStart(frame)
	local self = frame.obj
	self.private.timelineFrameIsDragging = true
	self.private.timelineFrameDragStartX, _ = GetCursorPosition()
	self.timelineFrame:SetScript("OnUpdate", HandleTimelineFrameUpdate)
end

local function HandleTimelineFrameDragStop(frame)
	local self = frame.obj
	self.private.timelineFrameIsDragging = nil
	self.timelineFrame:SetScript("OnUpdate", nil)
end

local function HandleTimelineFrameMouseWheel(frame, delta)
	local self = frame.obj
	local timelineFrame = self.timelineFrame
	local totalTimelineDuration = self.totalTimelineDuration
	local scrollFrame = self.frame

	local visibleDuration = totalTimelineDuration / zoomFactor
	local visibleStartTime = (scrollFrame:GetHorizontalScroll() / timelineFrame:GetWidth()) * totalTimelineDuration
	local visibleEndTime = visibleStartTime + visibleDuration
	local visibleMidpointTime = (visibleStartTime + visibleEndTime) / 2.0

	-- Update zoom factor based on scroll delta
	if delta > 0 and zoomFactor < maxZoomFactor then
		zoomFactor = zoomFactor * (1.0 + zoomStep)
	elseif delta < 0 and zoomFactor > minZoomFactor then
		zoomFactor = zoomFactor / (1.0 + zoomStep)
	end

	-- Recalculate visible duration after zoom
	local newVisibleDuration = totalTimelineDuration / zoomFactor

	-- Calculate new start and end time while keeping midpoint constant
	local newVisibleStartTime = visibleMidpointTime - (newVisibleDuration / 2.0)
	local newVisibleEndTime = visibleMidpointTime + (newVisibleDuration / 2.0)

	-- Add overflow from end time to start time to prevent empty space between end of timeline and parent frame
	if newVisibleEndTime > totalTimelineDuration then
		local surplus = totalTimelineDuration - newVisibleEndTime
		newVisibleEndTime = totalTimelineDuration
		newVisibleStartTime = newVisibleStartTime + surplus
	end

	-- Ensure boundaries are within the total timeline range
	newVisibleStartTime = math.max(0, newVisibleStartTime)
	newVisibleEndTime = math.min(totalTimelineDuration, newVisibleEndTime)

	-- Adjust the timeline frame width based on zoom factor
	local newTimelineFrameWidth = scrollFrame:GetWidth() * zoomFactor

	-- Recalculate the new scroll position based on the new visible start time
	local newHorizontalScroll = (newVisibleStartTime / totalTimelineDuration) * newTimelineFrameWidth
	scrollFrame:SetHorizontalScroll(newHorizontalScroll)

	timelineFrame:SetWidth(newTimelineFrameWidth)

	self:UpdateScrollBar()
	self:UpdateTickMarks()
	self:UpdateBars()
end

local methods = {
	["OnAcquire"] = function(self)
		self.private = {}
		self.private.timelineLinePadding = timelineLinePadding
		self.private.thumbPadding = scrollBarThumbPadding
		self.private.timelineFrameIsDragging = false
		self.private.timelineFrameDragStartX = 0
		self.private.thumbOffsetWhenThumbClicked = 0
		self.private.scrollBarWidthWhenThumbClicked = 0
		self.private.thumbWidthWhenThumbClicked = 0
		self.private.thumbIsDragging = false
		self.bars = self.bars or {}
		self.tickMarks = self.tickMarks or {}
		self.totalTimelineDuration = 0
		self.phases = {}
		self.phaseOrder = {}
		self.frame:Show()
	end,

	["OnRelease"] = function(self)
		self.private = nil
		self.totalTimelineDuration = 0
		self.abilityEntries = nil
		self.phases = nil
		self.phaseOrder = nil
	end,

	["SetEntries"] = function(self, abilities, phases)
		self.abilityEntries = abilities
		self.phases = phases
		self.phaseOrder = {} -- Sequence of phases based on repeatAfter

		local totalOccurances = 0
		local totalTimelineDuration = 0
		for _, phaseData in pairs(self.phases) do
			totalTimelineDuration = totalTimelineDuration + (phaseData.duration * phaseData.count)
			totalOccurances = totalOccurances + phaseData.count
		end
		self.totalTimelineDuration = totalTimelineDuration

		local currentPhase = 1
		while #self.phaseOrder < totalOccurances do
			table.insert(self.phaseOrder, currentPhase)
			currentPhase = phases[currentPhase].repeatAfter
		end

		self:SetHeight(self:CalculateRequiredHeight())

		HandleTimelineFrameMouseWheel(self.timelineFrame, 0)
	end,

	["UpdateBars"] = function(self)
		-- Hide existing bars
		for _, bar in pairs(self.bars) do
			bar:Hide()
		end
		local cumulativePhaseStartTimes = 0
		local index = 1

		for _, phaseId in ipairs(self.phaseOrder) do
			local phaseData = self.phases[phaseId]
			local phaseStartTime = cumulativePhaseStartTimes

			-- Iterate over abilities for the current phase
			local colorIndex = 1
			for _, abilityData in pairs(self.abilityEntries) do
				if abilityData.phases[phaseId] then
					local color = colors[colorIndex]
					local offset = (colorIndex - 1) * (barHeight + paddingBetweenBars)
					local phaseDetails = abilityData.phases[phaseId]
					local cumulativePhaseCastTimes = phaseStartTime

					-- Iterate over each cast time
					for _, castTime in ipairs(phaseDetails.castTimes) do
						cumulativePhaseCastTimes = cumulativePhaseCastTimes + castTime
						local castStart = cumulativePhaseCastTimes
						local castEnd = castStart + abilityData.castTime
						local effectEnd = castEnd + abilityData.duration

						self:DrawTimelineBar(castStart, effectEnd, color, index, offset)
						index = index + 1

						-- Handle repeat intervals for abilities
						if phaseDetails.repeatInterval then
							local repeatInterval = phaseDetails.repeatInterval
							local nextRepeatStart = castStart + repeatInterval

							while nextRepeatStart < phaseStartTime + phaseData.duration do
								local repeatEnd = nextRepeatStart + abilityData.castTime
								local repeatEffectEnd = repeatEnd + abilityData.duration

								self:DrawTimelineBar(nextRepeatStart, repeatEffectEnd, color, index, offset)
								index = index + 1

								nextRepeatStart = nextRepeatStart + repeatInterval
							end
						end
					end
				end
				colorIndex = colorIndex + 1
			end
			cumulativePhaseStartTimes = cumulativePhaseStartTimes + phaseData.duration
		end
	end,

	-- Helper function to draw a timeline bar
	["DrawTimelineBar"] = function(self, startTime, endTime, color, index, offset)
		if self.totalTimelineDuration <= 0.0 then return end

		local timelineFrame = self.timelineFrame
		local timelineWidth = self.timelineLine:GetWidth()
		local padding = self.private.timelineLinePadding

		local timelineStartPosition = (startTime / self.totalTimelineDuration) * timelineWidth
		local timelinetimeEndPosition = (endTime / self.totalTimelineDuration) * timelineWidth

		local bar = self.bars[index]
		if not bar then
			bar = timelineFrame:CreateTexture(nil, "ARTWORK")
			self.bars[index] = bar
		end

		local r, g, b, a = unpack(color)
		bar:SetColorTexture(r / 255.0, g / 255.0, b / 255.0, a)
		bar:SetSize(timelinetimeEndPosition - timelineStartPosition, barHeight)
		bar:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", timelineStartPosition + padding.x, -offset)
		bar:Show()
	end,

	["UpdateScrollBar"] = function(self)
		local scrollFrame = self.frame
		local scrollFrameWidth = scrollFrame:GetWidth()
		local timelineWidth = self.timelineFrame:GetWidth()
		local scrollBarWidth = self.scrollBar:GetWidth()
		local thumbPaddingX = self.private.thumbPadding.x

		-- Calculate the scroll bar thumb size based on the visible area
		local thumbWidth = (scrollFrameWidth / timelineWidth) * (scrollBarWidth - (2 * thumbPaddingX))
		thumbWidth = math.max(thumbWidth, 20) -- Minimum size so it's always visible
		thumbWidth = math.min(thumbWidth, scrollFrameWidth - (2 * thumbPaddingX))

		local thumb = self.thumb
		thumb:SetWidth(thumbWidth)

		local scrollOffset = scrollFrame:GetHorizontalScroll()

		-- Calculate the thumb's relative position in the scroll bar
		local maxScroll = timelineWidth - scrollFrameWidth
		local maxThumbPosition = scrollBarWidth - thumbWidth - (2 * thumbPaddingX)

		-- Prevent division by zero if maxScroll is 0
		if maxScroll > 0 then
			local thumbPosition = (scrollOffset / maxScroll) * maxThumbPosition

			-- Update the thumb's position based on the scroll offset
			thumb:SetPoint("LEFT", thumbPaddingX + thumbPosition, 0)
		else
			-- If no scrolling is possible, reset the thumb to the start
			thumb:SetPoint("LEFT", thumbPaddingX, 0)
		end
	end,

	["UpdateTickMarks"] = function(self)
		-- Clear existing tick marks
		for _, tick in pairs(self.tickMarks) do
			tick:Hide()
		end

		if self.totalTimelineDuration <= 0.0 then return end

		-- Define visible range in time (based on zoomFactor)
		local visibleDuration = self.totalTimelineDuration / zoomFactor

		-- Determine appropriate tick interval based on visible duration
		local tickInterval
		if visibleDuration > 600 then
			tickInterval = 60 -- Show tick marks every 1 minute
		elseif visibleDuration > 120 then
			tickInterval = 30 -- Show tick marks every 30 seconds
		elseif visibleDuration > 60 then
			tickInterval = 10 -- Show tick marks every 10 seconds
		else
			tickInterval = 5 -- Show tick marks every 5 seconds
		end

		local timelineFrame = self.timelineFrame
		local timelineLine = self.timelineLine
		local timelineWidth = timelineLine:GetWidth()
		local padding = self.private.timelineLinePadding

		-- Loop through to create the tick marks at the calculated intervals
		for i = 0, self.totalTimelineDuration, tickInterval do
			local position = (i / self.totalTimelineDuration) * timelineWidth

			-- Create or reuse tick mark
			local tick = self.tickMarks[i]
			if not tick then
				tick = timelineFrame:CreateTexture(nil, "ARTWORK")
				tick:SetColorTexture(unpack(tickColor))
				tick:SetWidth(tickWidth)
				self.tickMarks[i] = tick
			end
			tick:SetPoint("TOP", timelineFrame, "TOPLEFT", position + padding.x, 0)
			--tick:SetHeight(timelineFrame:GetHeight() - timelineLinePadding.y)
			tick:SetPoint("BOTTOM", timelineLine, "LEFT", position, 0)
			tick:Show()

			-- Create or reuse timestamp label
			local label = self.tickMarks["label" .. i]
			if not label then
				label = timelineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				self.tickMarks["label" .. i] = label
				if fontPath then label:SetFont(fontPath, tickFontSize) end
			end
			local minutes = math.floor(i / 60)
			local seconds = i % 60
			label:SetText(string.format("%d:%02d", minutes, seconds))
			label:SetPoint("TOP", tick, "BOTTOM", 0, -tickTextOffset.y)
			label:Show()
		end
	end,

	["OnWidthSet"] = function(self, width)
		HandleTimelineFrameMouseWheel(self.timelineFrame, 0)
	end,

	["OnHeightSet"] = function(self, height)
		self.timelineFrame:SetHeight(height - horizontalScrollBarHeight)
		HandleTimelineFrameMouseWheel(self.timelineFrame, 0)
	end,

	["CalculateRequiredHeight"] = function(self)
		local totalBarHeight = 0
		if self.abilityEntries then
			local count = #self.abilityEntries
			totalBarHeight = count * (barHeight + paddingBetweenBars) - paddingBetweenBars
		end
		return totalBarHeight + horizontalScrollBarHeight + timelineLinePadding.y
	end,
}

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("ScrollFrame", Type .. num, UIParent)
	frame:SetSize(frameWidth, frameHeight)
	frame:Hide()

	-- Scrollbar
	local scrollBar = CreateFrame("Frame", Type .. num .. "HorizontalScrollBar", frame)
	scrollBar:SetHeight(horizontalScrollBarHeight)
	scrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	local scrollBarBackground = scrollBar:CreateTexture(Type .. num .. "ScrollBarBackground", "BACKGROUND")
	scrollBarBackground:SetAllPoints()
	scrollBarBackground:SetColorTexture(1, 0, 0, 0.7)

	local thumb = CreateFrame("Button", Type .. num .. "ScrollBarThumb", scrollBar)
	thumb:SetPoint("LEFT", scrollBarThumbPadding.x, 0)
	thumb:SetSize(scrollBar:GetWidth() - 2 * scrollBarThumbPadding.x,
		horizontalScrollBarHeight - (2 * scrollBarThumbPadding.y))
	thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
	thumb:SetScript("OnMouseDown", HandleThumbMouseDown)
	thumb:SetScript("OnMouseUp", HandleThumbMouseUp)

	local thumbBackground = thumb:CreateTexture(Type .. num .. "ScrollBarThumbBackground", "BACKGROUND")
	thumbBackground:SetAllPoints()
	thumbBackground:SetColorTexture(0, 0, 0, 0.7)

	local timelineFrame = CreateFrame("Frame", Type .. num .. "TimelineFrame", frame)
	timelineFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	timelineFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	timelineFrame:SetSize(frameWidth, frameHeight)
	timelineFrame:SetScript("OnMouseWheel", HandleTimelineFrameMouseWheel)
	timelineFrame:EnableMouse(true)
	timelineFrame:RegisterForDrag("LeftButton", "LeftButtonUp")
	timelineFrame:SetScript("OnDragStart", HandleTimelineFrameDragStart)
	timelineFrame:SetScript("OnDragStop", HandleTimelineFrameDragStop)

	frame:SetScrollChild(timelineFrame)
	frame:EnableMouseWheel(true)

	local timelineLine = timelineFrame:CreateTexture(Type .. num .. "TimelineLine", "ARTWORK")
	timelineLine:SetColorTexture(0, 0, 0, 0)
	timelineLine:SetPoint("BOTTOMLEFT", timelineFrame, "BOTTOMLEFT", timelineLinePadding.x,
		timelineLinePadding.y)
	timelineLine:SetPoint("BOTTOMRIGHT", timelineFrame, "BOTTOMRIGHT", -timelineLinePadding.x,
		timelineLinePadding.y)

	local widget = {
		frame         = frame,
		type          = Type,
		scrollBar     = scrollBar,
		thumb         = thumb,
		timelineFrame = timelineFrame,
		timelineLine  = timelineLine,
	}

	frame.obj = widget
	scrollBar.obj = widget
	thumb.obj = widget
	timelineFrame.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
