local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPTimeline"
local Version = 1

---@class EPTimelineConstants
local k = Private.timeline.constants
---@class EPTimelineState
local s = Private.timeline.state

local ConvertTimeToTimelineOffset = Private.timeline.utilities.ConvertTimeToTimelineOffset
local CreateBossPhaseIndicators = Private.timeline.bossAbility.CreateBossPhaseIndicators
local FindAssignmentFrame = Private.timeline.utilities.FindAssignmentFrame
local IsValidKeyCombination = Private.timeline.utilities.IsValidKeyCombination
local StopMovingAssignment = Private.timeline.assignment.StopMovingAssignment
local UpdateAssignmentFrames = Private.timeline.assignment.UpdateAssignmentFrames
local UpdateBossAbilityFrames = Private.timeline.bossAbility.UpdateBossAbilityFrames
local UpdateHorizontalScrollBarThumb = Private.timeline.utilities.UpdateHorizontalScrollBarThumb
local UpdateLinePosition = Private.timeline.utilities.UpdateLinePosition
local UpdateTickMarks = Private.timeline.utilities.UpdateTickMarks
local UpdateTimeLabels = Private.timeline.utilities.UpdateTimeLabels

local abs = math.abs
local AceGUI = LibStub("AceGUI-3.0")
local Clamp = Clamp
local CreateFrame = CreateFrame
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local GetTime = GetTime
local ipairs = ipairs
local max, min = math.max, math.min
local pairs = pairs
local select = select
local UIParent = UIParent
local unpack = unpack

---@param self EPTimeline
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentTimelineFrameMouseUp(self, mouseButton)
	if s.IsSimulating then
		return
	end

	if s.AssignmentIsDragging and s.AssignmentFrameBeingDragged then
		StopMovingAssignment(s.AssignmentFrameBeingDragged)
		s.BossAbilityTimeline.verticalPositionLine:Hide()
		s.AssignmentTimeline.verticalPositionLine:Hide()
		UpdateTimeLabels()
		return
	end

	if IsValidKeyCombination(s.Preferences.keyBindings.newAssignment, mouseButton) then
		local currentX, currentY = GetCursorPosition()
		currentX = currentX / UIParent:GetEffectiveScale()
		currentY = currentY / UIParent:GetEffectiveScale()

		local timelineFrame = s.BossAbilityTimeline.timelineFrame
		local timelineWidth = timelineFrame:GetWidth()
		local padding = k.TimelineLinePadding.x
		local newTimeOffset = currentX - timelineFrame:GetLeft()
		local time = (newTimeOffset - padding) * s.TotalTimelineDuration / (timelineWidth - padding * 2)

		if time < 0.0 or time > s.TotalTimelineDuration then
			return
		end

		local relativeDistanceFromTop = abs(s.AssignmentTimeline.timelineFrame:GetTop() - currentY)
		local totalAssignmentHeight = 0
		local assignee, spellID = nil, nil
		for _, assigneeAndSpell in ipairs(self.assigneesAndSpells) do
			if assigneeAndSpell.spellID == nil or not s.Collapsed[assigneeAndSpell.assignee] then
				totalAssignmentHeight = totalAssignmentHeight
					+ (s.Preferences.timelineRows.assignmentHeight + k.PaddingBetweenAssignments)
				if totalAssignmentHeight >= relativeDistanceFromTop then
					assignee, spellID = assigneeAndSpell.assignee, assigneeAndSpell.spellID
					break
				end
			end
		end

		if assignee then
			self:Fire("CreateNewAssignment", assignee, spellID, time)
		end
	end
end

---@param self EPTimeline
---@param isBossTimelineSection boolean
---@param delta number
local function HandleTimelineFrameMouseWheel(self, isBossTimelineSection, delta)
	if s.AssignmentIsDragging and s.AssignmentFrameBeingDragged then
		StopMovingAssignment(s.AssignmentFrameBeingDragged)
	end

	local currentTime = GetTime()
	if currentTime - s.LastExecutionTime < k.ThrottleInterval then
		return
	end

	s.LastExecutionTime = currentTime
	if not s.TotalTimelineDuration or s.TotalTimelineDuration <= 0 then
		return
	end

	local validScroll = IsValidKeyCombination(s.Preferences.keyBindings.scroll, "MouseScroll")
	local validZoom = IsValidKeyCombination(s.Preferences.keyBindings.zoom, "MouseScroll")

	local timelineSection
	if isBossTimelineSection then
		timelineSection = self.bossAbilityTimeline
	else
		timelineSection = self.assignmentTimeline
	end
	local timelineFrame = timelineSection.timelineFrame
	local scrollFrame = timelineSection.scrollFrame

	if validScroll then
		local scrollFrameHeight = scrollFrame:GetHeight()
		local timelineFrameHeight = timelineFrame:GetHeight()

		local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
		local currentVerticalScroll = scrollFrame:GetVerticalScroll()
		local snapValue = (timelineSection.textureHeight + timelineSection.listPadding)
		local currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)

		if delta > 0 then
			currentSnapValue = currentSnapValue - 1
		elseif delta < 0 then
			currentSnapValue = currentSnapValue + 1
		end

		local newVerticalScroll = Clamp(currentSnapValue * snapValue, 0, maxVerticalScroll)
		scrollFrame:SetVerticalScroll(newVerticalScroll)
		timelineSection.listScrollFrame:SetVerticalScroll(newVerticalScroll)
		timelineSection:UpdateVerticalScroll()
	end

	if validZoom then
		local timelineWidth = timelineFrame:GetWidth()

		local visibleDuration = s.TotalTimelineDuration / self.zoomFactor
		local visibleStartTime = (scrollFrame:GetHorizontalScroll() / timelineWidth) * s.TotalTimelineDuration
		local visibleEndTime = visibleStartTime + visibleDuration

		-- Update zoom factor based on scroll delta
		if delta > 0 and self.zoomFactor < k.MaxZoomFactor then
			self.zoomFactor = self.zoomFactor * (1.0 + k.ZoomStep)
		elseif delta < 0 and self.zoomFactor > k.MinZoomFactor then
			self.zoomFactor = self.zoomFactor / (1.0 + k.ZoomStep)
		end

		local newVisibleDuration = s.TotalTimelineDuration / self.zoomFactor
		local newVisibleStartTime, newVisibleEndTime

		if s.Preferences.zoomCenteredOnCursor then
			local xPosition = GetCursorPosition() or 0
			local frameLeft = timelineFrame:GetLeft() or 0
			local relativeCursorOffset = xPosition / UIParent:GetEffectiveScale() - frameLeft

			-- Convert offset to time, accounting for padding
			local padding = k.TimelineLinePadding.x
			local effectiveTimelineWidth = timelineWidth - (padding * 2)
			local cursorTime = (relativeCursorOffset - padding) * s.TotalTimelineDuration / effectiveTimelineWidth

			local beforeCursorDuration = cursorTime - visibleStartTime
			local afterCursorDuration = visibleEndTime - cursorTime
			local leftScaleFactor = beforeCursorDuration / visibleDuration
			local rightScaleFactor = afterCursorDuration / visibleDuration
			newVisibleStartTime = cursorTime - (newVisibleDuration * leftScaleFactor)
			newVisibleEndTime = cursorTime + (newVisibleDuration * rightScaleFactor)
		else
			local visibleMidpointTime = (visibleStartTime + visibleEndTime) / 2.0
			newVisibleStartTime = visibleMidpointTime - (newVisibleDuration / 2.0)
			newVisibleEndTime = visibleMidpointTime + (newVisibleDuration / 2.0)
		end

		-- Correct boundaries
		if newVisibleStartTime < 0 then
			-- local overflow = newVisibleStartTime
			-- newVisibleEndTime = newVisibleEndTime - overflow
			newVisibleStartTime = 0
		elseif newVisibleEndTime > s.TotalTimelineDuration then
			-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
			local overflow = s.TotalTimelineDuration - newVisibleEndTime
			-- newVisibleEndTime = s.TotalTimelineDuration
			newVisibleStartTime = newVisibleStartTime + overflow
		end

		-- Ensure boundaries are within the total timeline range
		newVisibleStartTime = max(0, newVisibleStartTime)
		-- newVisibleEndTime = min(s.TotalTimelineDuration, newVisibleEndTime)

		-- Adjust the timeline frame width based on zoom factor
		local scrollFrameWidth = scrollFrame:GetWidth()
		local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

		-- Recalculate the new scroll position based on the new visible start time
		local newHorizontalScroll = (newVisibleStartTime / s.TotalTimelineDuration) * newTimelineFrameWidth

		self.bossAbilityTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)
		self.assignmentTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)
		self.splitterFrame:SetWidth(newTimelineFrameWidth)

		self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)

		UpdateHorizontalScrollBarThumb(
			self.horizontalScrollBar:GetWidth(),
			self.thumb,
			scrollFrameWidth,
			newTimelineFrameWidth,
			newHorizontalScroll
		)
		UpdateAssignmentFrames()
		UpdateBossAbilityFrames(
			self.bossAbilityOrder,
			self.bossAbilityVisibility,
			self.bossAbilityInstances,
			self.phaseNameFrame
		)
		UpdateTickMarks()
		if Private.activeTutorialCallbackName then
			Private.callbacks:Fire(Private.activeTutorialCallbackName, "timelineFrameMouseWheel")
		end
	end
end

---@param self EPTimeline
local function HandleThumbMouseDown(self)
	local thumb = self.thumb
	local splitterScrollFrame = self.splitterScrollFrame
	local horizontalScrollBar = self.horizontalScrollBar
	local assignmentScrollFrame = self.assignmentTimeline.scrollFrame
	local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
	local bossAbilityTimelineFrame = self.bossAbilityTimeline.timelineFrame
	s.ThumbOffsetWhenThumbClicked = GetCursorPosition() / UIParent:GetEffectiveScale() - thumb:GetLeft()
	s.ScrollBarWidthWhenThumbClicked = horizontalScrollBar:GetWidth()
	s.ThumbWidthWhenThumbClicked = thumb:GetWidth()
	s.ThumbIsDragging = true

	thumb:SetScript("OnUpdate", function()
		if not s.ThumbIsDragging then
			return
		end

		local currentOffset = s.ThumbOffsetWhenThumbClicked
		local currentWidth = s.ThumbWidthWhenThumbClicked
		local currentScrollBarWidth = s.ScrollBarWidthWhenThumbClicked
		local xPosition = GetCursorPosition() / UIParent:GetEffectiveScale()
		local newOffset = -horizontalScrollBar:GetLeft() + xPosition - currentOffset

		local minAllowedOffset = k.ThumbPadding.x
		local maxAllowedOffset = currentScrollBarWidth - currentWidth - k.ThumbPadding.x
		newOffset = Clamp(newOffset, minAllowedOffset, maxAllowedOffset)
		thumb:SetPoint("LEFT", newOffset, 0)

		local maxScroll = bossAbilityTimelineFrame:GetWidth() - bossAbilityScrollFrame:GetWidth()
		-- Calculate the scroll frame's horizontal scroll based on the thumb's position
		local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * k.ThumbPadding.x)

		if maxScroll <= 0 or maxThumbPosition <= 0 then
			-- No scrollable content or thumb fills the scroll bar
			bossAbilityScrollFrame:SetHorizontalScroll(0)
			assignmentScrollFrame:SetHorizontalScroll(0)
			splitterScrollFrame:SetHorizontalScroll(0)
		else
			local scrollOffset = ((newOffset - k.ThumbPadding.x) / maxThumbPosition) * maxScroll
			bossAbilityScrollFrame:SetHorizontalScroll(scrollOffset)
			assignmentScrollFrame:SetHorizontalScroll(scrollOffset)
			splitterScrollFrame:SetHorizontalScroll(scrollOffset)
		end
	end)
end

---@param self EPTimeline
local function HandleThumbMouseUp(self)
	s.ThumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

---@param self EPTimeline
---@param frame Frame
local function HandleTimelineFrameEnter(self, frame)
	if s.IsSimulating or s.TimelineFrameIsDragging then
		return
	end
	local assignmentFrame = self.assignmentTimeline.frame
	local bossAbilityFrame = self.bossAbilityTimeline.frame
	local assignmentLine = self.assignmentTimeline.verticalPositionLine
	local bossAbilityLine = self.bossAbilityTimeline.verticalPositionLine
	frame:SetScript("OnUpdate", function()
		UpdateLinePosition(assignmentFrame, assignmentLine)
		UpdateLinePosition(bossAbilityFrame, bossAbilityLine)
		UpdateTimeLabels()
	end)
end

---@param self EPTimeline
---@param frame Frame
local function HandleTimelineFrameLeave(self, frame)
	if s.IsSimulating or s.TimelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", nil)
	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels()
end

---@param self EPTimeline
---@param frame Frame
---@param button string
local function HandleTimelineFrameDragStart(self, frame, button)
	if not IsValidKeyCombination(s.Preferences.keyBindings.pan, button) then
		return
	end
	if s.IsSimulating then
		return
	end

	s.TimelineFrameIsDragging = true
	s.TimelineFrameOffsetWhenDragStarted = GetCursorPosition()

	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels()

	local splitterScrollFrame = self.splitterScrollFrame
	local scrollFrameWidth = self.bossAbilityTimeline.scrollFrame:GetWidth()
	local timelineFrameWidth = self.bossAbilityTimeline.timelineFrame:GetWidth()
	local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
	local assignmentScrollFrame = self.assignmentTimeline.scrollFrame
	local horizontalScrollBarWidth = self.horizontalScrollBar:GetWidth()
	local thumb = self.thumb

	frame:SetScript("OnUpdate", function()
		if s.TimelineFrameIsDragging then
			local x = GetCursorPosition()
			local dx = (x - s.TimelineFrameOffsetWhenDragStarted) / bossAbilityScrollFrame:GetEffectiveScale()
			local newHorizontalScroll = bossAbilityScrollFrame:GetHorizontalScroll() - dx
			local maxHorizontalScroll = timelineFrameWidth - scrollFrameWidth
			newHorizontalScroll = Clamp(newHorizontalScroll, 0, maxHorizontalScroll)
			bossAbilityScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			assignmentScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			s.TimelineFrameOffsetWhenDragStarted = x
			UpdateHorizontalScrollBarThumb(
				horizontalScrollBarWidth,
				thumb,
				scrollFrameWidth,
				timelineFrameWidth,
				newHorizontalScroll
			)
		end
	end)
end

---@param self EPTimeline
---@param frame Frame
---@param scrollFrame ScrollFrame
local function HandleTimelineFrameDragStop(self, frame, scrollFrame)
	if s.IsSimulating then
		return
	end

	s.TimelineFrameIsDragging = false
	frame:SetScript("OnUpdate", nil)

	local x, y = GetCursorPosition()
	x = x / UIParent:GetEffectiveScale()
	y = y / UIParent:GetEffectiveScale()

	if
		x > scrollFrame:GetLeft()
		and x < scrollFrame:GetRight()
		and y < scrollFrame:GetTop()
		and y > scrollFrame:GetBottom()
	then
		local assignmentFrame = self.assignmentTimeline.frame
		local bossAbilityFrame = self.bossAbilityTimeline.frame
		local assignmentLine = self.assignmentTimeline.verticalPositionLine
		local bossAbilityLine = self.bossAbilityTimeline.verticalPositionLine
		frame:SetScript("OnUpdate", function()
			UpdateLinePosition(assignmentFrame, assignmentLine)
			UpdateLinePosition(bossAbilityFrame, bossAbilityLine)
			UpdateTimeLabels()
		end)
	end
end

-- Calculate the total required height for boss ability bars.
---@param self EPTimeline
---@return number
local function CalculateRequiredBarHeight(self)
	local totalBarHeight = 0.0
	local rowHeight = s.Preferences.timelineRows.bossAbilityHeight

	local activeAbilities = {}
	for _, spellID in pairs(self.bossAbilityOrder) do
		activeAbilities[spellID] = true
	end

	for spellID, visible in pairs(self.bossAbilityVisibility) do
		if visible == true and activeAbilities[spellID] then
			totalBarHeight = totalBarHeight + (rowHeight + k.PaddingBetweenBossAbilityBars)
		end
	end
	if totalBarHeight >= (rowHeight + k.PaddingBetweenBossAbilityBars) then
		totalBarHeight = totalBarHeight - k.PaddingBetweenBossAbilityBars
	end
	return totalBarHeight
end

-- Calculate the total required height for assignments.
---@param self EPTimeline
---@return number
local function CalculateRequiredAssignmentHeight(self)
	local totalAssignmentHeight = 0
	local totalAssignmentRows = 0
	local rowHeight = s.Preferences.timelineRows.assignmentHeight
	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not s.Collapsed[as.assignee] then
			totalAssignmentHeight = totalAssignmentHeight + (rowHeight + k.PaddingBetweenAssignments)
			totalAssignmentRows = totalAssignmentRows + 1
		end
	end
	if totalAssignmentHeight >= (rowHeight + k.PaddingBetweenAssignments) then
		totalAssignmentHeight = totalAssignmentHeight - k.PaddingBetweenAssignments
	end
	return totalAssignmentHeight
end

---@param self EPTimeline
local function UpdateResizeBounds(self)
	local minHeight = self.assignmentDimensions.min
		+ self.bossAbilityDimensions.min
		+ k.PaddingBetweenTimelines
		+ k.PaddingBetweenTimelineAndScrollBar
		+ k.HorizontalScrollBarHeight
	local maxHeight = self.assignmentDimensions.max
		+ self.bossAbilityDimensions.max
		+ k.PaddingBetweenTimelines
		+ k.PaddingBetweenTimelineAndScrollBar
		+ k.HorizontalScrollBarHeight
	self:Fire("ResizeBoundsCalculated", minHeight, maxHeight)
end

---@param self EPTimeline
local function CalculateMinMaxStepBarHeight(self)
	local abilityCount = 1
	local timelineRows = s.Preferences.timelineRows
	local rowHeight = timelineRows.bossAbilityHeight
	local minH, maxH, stepH = 0, 0, (rowHeight + k.PaddingBetweenBossAbilityBars)

	local activeAbilities = {}
	for _, spellID in pairs(self.bossAbilityOrder) do
		activeAbilities[spellID] = true
	end

	local availableHeight = UIParent:GetHeight() - k.NonTimelineHeight
	local assignmentTimelineHeight = timelineRows.numberOfAssignmentsToShow * (timelineRows.assignmentHeight + 2) - 2
	local usableHeight = availableHeight - assignmentTimelineHeight - 2
	local maximumNumberOfBossAbilityRows = floor(usableHeight / (timelineRows.bossAbilityHeight + 2))

	for spellID, visible in pairs(self.bossAbilityVisibility) do
		if visible == true and activeAbilities[spellID] then
			if abilityCount <= maximumNumberOfBossAbilityRows then
				maxH = maxH + stepH
			end
			if abilityCount <= k.MinimumNumberOfBossAbilityRows then
				minH = maxH
			end
			abilityCount = abilityCount + 1
		end
	end
	if minH >= stepH then
		minH = minH - k.PaddingBetweenBossAbilityBars
	else
		minH = rowHeight -- Prevent boss ability timeline frame from having 0 height
	end
	if maxH >= stepH then
		maxH = maxH - k.PaddingBetweenBossAbilityBars
	else
		maxH = rowHeight -- Prevent boss ability timeline frame from having 0 height
	end
	self.bossAbilityDimensions.min = minH
	self.bossAbilityDimensions.max = maxH
	self.bossAbilityDimensions.step = stepH

	UpdateResizeBounds(self)
end

---@param self EPTimeline
local function CalculateMinMaxStepAssignmentHeight(self)
	local totalAssignmentRows = 1
	local timelineRows = s.Preferences.timelineRows
	local minH, maxH, stepH = 0, 0, (s.Preferences.timelineRows.assignmentHeight + k.PaddingBetweenAssignments)
	local availableHeight = UIParent:GetHeight() - k.NonTimelineHeight

	local bossTimelineHeight = timelineRows.numberOfBossAbilitiesToShow * (timelineRows.bossAbilityHeight + 2) - 2
	local usableHeight = availableHeight - bossTimelineHeight - 2
	local maximumNumberOfAssignmentRows = floor(usableHeight / (timelineRows.assignmentHeight + 2))

	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not s.Collapsed[as.assignee] then
			if totalAssignmentRows <= maximumNumberOfAssignmentRows then
				maxH = maxH + stepH
			end
			if totalAssignmentRows <= k.MinimumNumberOfAssignmentRows then
				minH = maxH
			end
			totalAssignmentRows = totalAssignmentRows + 1
		end
	end
	if minH >= stepH then
		minH = minH - k.PaddingBetweenAssignments
	end
	if maxH >= stepH then
		maxH = maxH - k.PaddingBetweenAssignments
	end
	self.assignmentDimensions.min = minH
	self.assignmentDimensions.max = maxH
	self.assignmentDimensions.step = stepH

	UpdateResizeBounds(self)
end

---@param self EPTimeline
local function OnAcquire(self)
	s:Init(self.splitterFrame, self.splitterScrollFrame, self.chargeFrame, self.horizontalScrollBar, self.thumb)
	self.zoomFactor = self.zoomFactor or 1.0
	self.bossAbilityOrder = {}
	self.bossPhaseOrder = {}
	self.bossPhases = {}
	self.assigneesAndSpells = {}
	self.bossAbilityVisibility = {}
	self.allowHeightResizing = false
	self.bossAbilityDimensions = { min = 0, max = 0, step = 0 }
	self.assignmentDimensions = { min = 0, max = 0, step = 0 }

	self.contentFrame:SetParent(self.frame)
	self.contentFrame:SetPoint("TOPLEFT")
	self.contentFrame:SetPoint("TOPRIGHT")
	self.contentFrame:SetPoint("BOTTOM", self.horizontalScrollBar, "TOP", 0, k.PaddingBetweenTimelineAndScrollBar)
	self.contentFrame:Show()

	self.assignmentTimeline = AceGUI:Create("EPTimelineSection")
	self.assignmentTimeline.frame:SetParent(self.contentFrame)
	self.assignmentTimeline:SetListPadding(k.PaddingBetweenAssignments)

	self.bossAbilityTimeline = AceGUI:Create("EPTimelineSection")
	self.bossAbilityTimeline.frame:SetParent(self.contentFrame)
	self.bossAbilityTimeline:SetListPadding(k.PaddingBetweenBossAbilityBars)

	s:SetTimelineSections(self.assignmentTimeline, self.bossAbilityTimeline)

	self.assignmentTimeline.listContainer.frame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, false, delta)
	end)
	self.bossAbilityTimeline.listContainer.frame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, true, delta)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, false, delta)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, true, delta)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnDragStart", function(frame, button)
		HandleTimelineFrameDragStart(self, frame, button)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnDragStart", function(frame, button)
		HandleTimelineFrameDragStart(self, frame, button)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnDragStop", function(frame, _)
		HandleTimelineFrameDragStop(self, frame, self.assignmentTimeline.scrollFrame)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnDragStop", function(frame, _)
		HandleTimelineFrameDragStop(self, frame, self.bossAbilityTimeline.scrollFrame)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnEnter", function(frame)
		HandleTimelineFrameEnter(self, frame)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnEnter", function(frame)
		HandleTimelineFrameEnter(self, frame)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnLeave", function(frame)
		HandleTimelineFrameLeave(self, frame)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnLeave", function(frame)
		HandleTimelineFrameLeave(self, frame)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseUp", function(_, button)
		HandleAssignmentTimelineFrameMouseUp(self, button)
	end)

	local bossAbilityFrame = self.bossAbilityTimeline.frame
	bossAbilityFrame:SetPoint("TOP", self.contentFrame, "TOP")
	bossAbilityFrame:SetPoint("LEFT", self.contentFrame, "LEFT")
	bossAbilityFrame:SetPoint("RIGHT", self.contentFrame, "RIGHT")

	local assignmentFrame = self.assignmentTimeline.frame
	assignmentFrame:SetPoint("TOPLEFT", bossAbilityFrame, "BOTTOMLEFT", 0, -k.PaddingBetweenTimelines)
	assignmentFrame:SetPoint("TOPRIGHT", bossAbilityFrame, "BOTTOMRIGHT", 0, -k.PaddingBetweenTimelines)

	self.chargeFrame:SetPoint("TOPLEFT", self.assignmentTimeline.scrollFrame, "TOPLEFT")
	self.chargeFrame:SetPoint("BOTTOMRIGHT", self.assignmentTimeline.scrollFrame, "BOTTOMRIGHT")

	self.splitterScrollFrame:SetParent(self.contentFrame)
	self.splitterScrollFrame:SetPoint("TOP", bossAbilityFrame, "BOTTOM")
	self.splitterScrollFrame:SetPoint("LEFT", 210, 0)
	self.splitterScrollFrame:SetPoint("RIGHT", -k.PaddingBetweenTimelineAndScrollBar - k.HorizontalScrollBarHeight, 0)
	self.splitterScrollFrame:SetHeight(k.PaddingBetweenTimelines)
	self.splitterScrollFrame:Show()

	self.splitterFrame:SetParent(self.splitterScrollFrame)
	self.splitterScrollFrame:SetScrollChild(self.splitterFrame)
	self.splitterFrame:SetPoint("LEFT")
	self.splitterFrame:Show()

	self.phaseNameFrame:SetParent(self.frame)
	self.phaseNameFrame:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 210, 0)
	self.phaseNameFrame:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT")
	self.phaseNameFrame:SetHeight(22)
	self.phaseNameFrame:Show()

	self.horizontalScrollBar:SetHeight(k.HorizontalScrollBarHeight)
	self.horizontalScrollBar:SetParent(self.frame)
	self.horizontalScrollBar:SetPoint("BOTTOMLEFT", 210, 0)
	self.horizontalScrollBar:SetPoint(
		"BOTTOMRIGHT",
		-k.HorizontalScrollBarHeight - k.PaddingBetweenTimelineAndScrollBar,
		0
	)
	self.horizontalScrollBar:Show()

	self.thumb:SetParent(self.horizontalScrollBar)
	self.thumb:SetPoint("LEFT", k.ThumbPadding.x, 0)
	local scrollBarThumbWidth = self.horizontalScrollBar:GetWidth() - 2 * k.ThumbPadding.x
	local scrollBarThumbHeight = k.HorizontalScrollBarHeight - (2 * k.ThumbPadding.y)
	self.thumb:SetSize(scrollBarThumbWidth, scrollBarThumbHeight)
	self.thumb:Show()
	self.thumb:SetScript("OnMouseDown", function()
		HandleThumbMouseDown(self)
	end)
	self.thumb:SetScript("OnMouseUp", function()
		HandleThumbMouseUp(self)
	end)

	self.addAssigneeDropdown = AceGUI:Create("EPDropdown")
	self.addAssigneeDropdown.frame:SetParent(self.contentFrame)
	self.addAssigneeDropdown.frame:SetPoint("RIGHT", self.splitterScrollFrame, "LEFT", -10, 0)

	self.frame:Show()
end

---@param self EPTimeline
local function OnRelease(self)
	self.contentFrame:ClearAllPoints()
	self.contentFrame:SetParent(UIParent)
	self.contentFrame:Hide()
	self.splitterScrollFrame:ClearAllPoints()
	self.splitterScrollFrame:SetParent(UIParent)
	self.splitterScrollFrame:Hide()
	self.splitterFrame:ClearAllPoints()
	self.splitterFrame:SetParent(UIParent)
	self.splitterFrame:Hide()
	self.horizontalScrollBar:ClearAllPoints()
	self.horizontalScrollBar:SetParent(UIParent)
	self.horizontalScrollBar:Hide()
	self.thumb:ClearAllPoints()
	self.thumb:SetParent(UIParent)
	self.thumb:Hide()
	self.thumb:SetScript("OnMouseDown", nil)
	self.thumb:SetScript("OnMouseUp", nil)
	self.thumb:SetScript("OnUpdate", nil)

	self.assignmentTimeline.listContainer.frame:SetScript("OnMouseWheel", nil)
	self.bossAbilityTimeline.listContainer.frame:SetScript("OnMouseWheel", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseWheel", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnMouseWheel", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnDragStart", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnDragStart", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnDragStop", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnDragStop", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnEnter", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnEnter", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnLeave", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnLeave", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseUp", nil)
	self.assignmentTimeline.timelineFrame:SetScript("OnUpdate", nil)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnUpdate", nil)

	self.assignmentTimeline:Release()
	self.assignmentTimeline = nil
	self.bossAbilityTimeline:Release()
	self.bossAbilityTimeline = nil
	self.addAssigneeDropdown:Release()
	self.addAssigneeDropdown = nil

	self.phaseNameFrame:ClearAllPoints()
	self.phaseNameFrame:SetParent(UIParent)
	self.phaseNameFrame:Hide()

	self.bossAbilityOrder = nil
	self.bossPhaseOrder = nil
	self.bossPhases = nil
	self.assigneesAndSpells = nil
	self.bossAbilityVisibility = nil
	self.allowHeightResizing = nil
	self.bossAbilityDimensions = nil
	self.assignmentDimensions = nil
	s:Reset()
end

-- Sets the boss ability entries for the timeline.
---@param self EPTimeline
---@param bossAbilityInstances table<integer, BossAbilityInstance>
---@param abilityOrder table<integer, integer>
---@param phases table<integer, BossPhase>
---@param phaseOrder table<integer, integer>
---@param bossAbilityVisibility table<integer, boolean>
local function SetBossAbilities(self, bossAbilityInstances, abilityOrder, phases, phaseOrder, bossAbilityVisibility)
	self.bossAbilityInstances = bossAbilityInstances
	self.bossAbilityOrder = abilityOrder
	self.bossPhases = phases
	self.bossPhaseOrder = phaseOrder
	self.bossAbilityVisibility = bossAbilityVisibility

	s.TotalTimelineDuration = 0.0
	for _, phaseData in pairs(self.bossPhases) do
		s.TotalTimelineDuration = s.TotalTimelineDuration + (phaseData.duration * phaseData.count)
	end

	CreateBossPhaseIndicators(self.bossPhaseOrder, self.phaseNameFrame)

	self:UpdateHeightFromBossAbilities()
	self:SetBossAbilityTimelineVerticalScroll()

	if #self.bossPhases == 0 then
		UpdateBossAbilityFrames(
			self.bossAbilityOrder,
			self.bossAbilityVisibility,
			self.bossAbilityInstances,
			self.phaseNameFrame
		)
		UpdateTickMarks()
	end
end

---@param self EPTimeline
---@param assignments table<integer, TimelineAssignment>
---@param assigneesAndSpells table<integer, AssignmentTimelineRow>
---@param collapsed table<string, boolean>
local function SetAssignments(self, assignments, assigneesAndSpells, collapsed)
	s:SetAssignments(assignments, collapsed)
	self.assigneesAndSpells = assigneesAndSpells
	self:UpdateHeightFromAssignments()
	self:SetAssignmentTimelineVerticalScroll()
end

-- Only here to preserve ordering of local functions...
---@param self EPTimeline
local function UpdateAssignmentsAndTickMarks(self)
	UpdateAssignmentFrames()
	UpdateTickMarks()
end

---@param self EPTimeline
---@return table<integer, TimelineAssignment>
local function GetAssignments(self)
	return s.TimelineAssignments
end

---@param self EPTimeline
---@return EPContainer
local function GetAssignmentContainer(self)
	return self.assignmentTimeline.listContainer
end

---@param self EPTimeline
---@return EPContainer
local function GetBossAbilityContainer(self)
	return self.bossAbilityTimeline.listContainer
end

---@param self EPTimeline
---@return EPDropdown
local function GetAddAssigneeDropdown(self)
	return self.addAssigneeDropdown
end

---@param self EPTimeline
---@param skipUpdateAssignments boolean?
---@param skipUpdateBossAbilityBars boolean?
---@param skipUpdateTickMarks boolean?
local function UpdateTimeline(self, skipUpdateAssignments, skipUpdateBossAbilityBars, skipUpdateTickMarks)
	if not s.TotalTimelineDuration or s.TotalTimelineDuration <= 0 then
		return
	end
	if self.bossAbilityTimeline.scrollFrame:GetWidth() == 0 then
		return
	end

	local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
	local bossAbilityTimelineFrame = self.bossAbilityTimeline.timelineFrame
	local timelineWidth = bossAbilityTimelineFrame:GetWidth()
	local visibleDuration = s.TotalTimelineDuration / self.zoomFactor
	local visibleStartTime = bossAbilityScrollFrame:GetHorizontalScroll() / timelineWidth * s.TotalTimelineDuration
	local visibleEndTime = visibleStartTime + visibleDuration
	local newVisibleStartTime, newVisibleEndTime

	if s.Preferences.zoomCenteredOnCursor then
		local frameLeft = bossAbilityTimelineFrame:GetLeft() or 0
		local relativeCursorOffset = (GetCursorPosition() or 0) / UIParent:GetEffectiveScale() - frameLeft

		-- Convert offset to time, accounting for padding
		local padding = k.TimelineLinePadding.x
		local effectiveTimelineWidth = timelineWidth - (padding * 2)
		local cursorTime = (relativeCursorOffset - padding) * s.TotalTimelineDuration / effectiveTimelineWidth

		local beforeCursorDuration = cursorTime - visibleStartTime
		local afterCursorDuration = visibleEndTime - cursorTime
		local leftScaleFactor = beforeCursorDuration / visibleDuration
		local rightScaleFactor = afterCursorDuration / visibleDuration
		newVisibleStartTime = cursorTime - (visibleDuration * leftScaleFactor)
		newVisibleEndTime = cursorTime + (visibleDuration * rightScaleFactor)
	else
		local visibleMidpointTime = (visibleStartTime + visibleEndTime) / 2.0
		newVisibleStartTime = visibleMidpointTime - (visibleDuration / 2.0)
		newVisibleEndTime = visibleMidpointTime + (visibleDuration / 2.0)
	end

	-- Correct boundaries
	if newVisibleStartTime < 0 then
		-- local overflow = newVisibleStartTime
		-- newVisibleEndTime = newVisibleEndTime - overflow
		newVisibleStartTime = 0
	elseif newVisibleEndTime > s.TotalTimelineDuration then
		-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
		local overflow = s.TotalTimelineDuration - newVisibleEndTime
		-- newVisibleEndTime = s.TotalTimelineDuration
		newVisibleStartTime = newVisibleStartTime + overflow
	end

	-- Ensure boundaries are within the total timeline range
	newVisibleStartTime = max(0, newVisibleStartTime)
	-- newVisibleEndTime = min(s.TotalTimelineDuration, newVisibleEndTime)

	-- Adjust the timeline frame width based on zoom factor
	local scrollFrameWidth = bossAbilityScrollFrame:GetWidth()
	local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

	-- Recalculate the new scroll position based on the new visible start time
	local newHorizontalScroll = (newVisibleStartTime / s.TotalTimelineDuration) * newTimelineFrameWidth

	bossAbilityTimelineFrame:SetWidth(newTimelineFrameWidth)
	self.assignmentTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)
	self.splitterFrame:SetWidth(newTimelineFrameWidth)

	bossAbilityScrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)

	UpdateHorizontalScrollBarThumb(
		self.horizontalScrollBar:GetWidth(),
		self.thumb,
		scrollFrameWidth,
		newTimelineFrameWidth,
		newHorizontalScroll
	)
	if not skipUpdateAssignments then
		UpdateAssignmentFrames()
	end
	if not skipUpdateBossAbilityBars then
		UpdateBossAbilityFrames(
			self.bossAbilityOrder,
			self.bossAbilityVisibility,
			self.bossAbilityInstances,
			self.phaseNameFrame
		)
	end
	if not skipUpdateTickMarks then
		UpdateTickMarks()
	end
end

-- Sets the height of the widget based assignment frames
---@param self EPTimeline
local function UpdateHeightFromAssignments(self)
	CalculateMinMaxStepAssignmentHeight(self)
	self.assignmentTimeline:SetTextureHeight(s.Preferences.timelineRows.assignmentHeight)
	local height = k.PaddingBetweenTimelines
		+ k.PaddingBetweenTimelineAndScrollBar
		+ k.HorizontalScrollBarHeight
		+ self.bossAbilityTimeline.frame:GetHeight()

	local assignmentFrameHeight = self.assignmentTimeline.frame:GetHeight()
	local numberToShow = s.Preferences.timelineRows.numberOfAssignmentsToShow
	local preferredAssignmentHeight = numberToShow * self.assignmentDimensions.step
	if numberToShow > 1 then
		preferredAssignmentHeight = preferredAssignmentHeight - k.PaddingBetweenAssignments
	end
	preferredAssignmentHeight = min(preferredAssignmentHeight, self.assignmentDimensions.max)
	if assignmentFrameHeight - self.assignmentDimensions.max > 0.5 then
		height = height + self.assignmentDimensions.max
		self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	elseif abs(assignmentFrameHeight - preferredAssignmentHeight) > 0.5 then
		height = height + preferredAssignmentHeight
		self.assignmentTimeline.frame:SetHeight(preferredAssignmentHeight)
	else
		height = height + assignmentFrameHeight
	end
	self:SetHeight(height)
end

-- Sets the height of the widget based on boss ability frames
---@param self EPTimeline
local function UpdateHeightFromBossAbilities(self)
	CalculateMinMaxStepBarHeight(self)
	self.bossAbilityTimeline:SetTextureHeight(s.Preferences.timelineRows.bossAbilityHeight)
	local height = k.PaddingBetweenTimelines
		+ k.PaddingBetweenTimelineAndScrollBar
		+ k.HorizontalScrollBarHeight
		+ self.assignmentTimeline.frame:GetHeight()
	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()
	local numberToShow = s.Preferences.timelineRows.numberOfBossAbilitiesToShow
	local preferredBossHeight = numberToShow * self.bossAbilityDimensions.step
	if numberToShow > 1 then
		preferredBossHeight = preferredBossHeight - k.PaddingBetweenBossAbilityBars
	end
	preferredBossHeight = min(preferredBossHeight, self.bossAbilityDimensions.max)
	if bossFrameHeight - self.bossAbilityDimensions.max > 0.5 then
		height = height + self.bossAbilityDimensions.max
		self.bossAbilityTimeline.frame:SetHeight(self.bossAbilityDimensions.max)
	elseif abs(bossFrameHeight - preferredBossHeight) > 0.5 then
		height = height + preferredBossHeight
		self.bossAbilityTimeline.frame:SetHeight(preferredBossHeight)
	else
		height = height + bossFrameHeight
	end
	self:SetHeight(height)
end

---@param self EPTimeline
local function SetMaxAssignmentHeight(self)
	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()
	local height = k.PaddingBetweenTimelines
		+ k.PaddingBetweenTimelineAndScrollBar
		+ k.HorizontalScrollBarHeight
		+ bossFrameHeight
	self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	self:SetHeight(height + self.assignmentDimensions.max)
end

-- Called when the height is set for EPTimeline widget.
---@param self EPTimeline
---@param height number
local function OnHeightSet(self, height)
	local assignmentHeight = self.assignmentTimeline.frame:GetHeight()
	local barHeight = self.bossAbilityTimeline.frame:GetHeight()
	local newContentFrameHeight = height - k.PaddingBetweenTimelineAndScrollBar - k.HorizontalScrollBarHeight

	if self.allowHeightResizing then
		local contentFloor = newContentFrameHeight - k.PaddingBetweenTimelines
		local timelineFloor = barHeight + assignmentHeight
		if contentFloor > timelineFloor then
			local surplus = contentFloor - timelineFloor
			local barPlusSurplus = barHeight + surplus
			local assignmentPlusSurplus = assignmentHeight + surplus
			if barPlusSurplus <= assignmentHeight and barPlusSurplus <= self.bossAbilityDimensions.max then
				barHeight = barPlusSurplus
			elseif assignmentPlusSurplus <= barHeight and assignmentPlusSurplus <= self.assignmentDimensions.max then
				assignmentHeight = assignmentPlusSurplus
			else
				local surplusSplit = surplus * 0.5
				barHeight = barHeight + surplusSplit
				assignmentHeight = assignmentHeight + surplusSplit
			end
		elseif contentFloor < timelineFloor then
			local surplus = timelineFloor - contentFloor
			local barMinusSurplus = barHeight - surplus
			local assignmentMinusSurplus = assignmentHeight - surplus
			if barMinusSurplus >= assignmentHeight and barMinusSurplus >= self.bossAbilityDimensions.min then
				barHeight = barMinusSurplus
			elseif assignmentMinusSurplus >= barHeight and assignmentMinusSurplus >= self.assignmentDimensions.min then
				assignmentHeight = assignmentMinusSurplus
			else
				local surplusSplit = surplus * 0.5
				barHeight = barHeight - surplusSplit
				assignmentHeight = assignmentHeight - surplusSplit
			end
		end
		barHeight = Clamp(barHeight, self.bossAbilityDimensions.min, self.bossAbilityDimensions.max)
		assignmentHeight = Clamp(assignmentHeight, self.assignmentDimensions.min, self.assignmentDimensions.max)
	end

	self.assignmentTimeline:SetHeight(assignmentHeight)
	self.bossAbilityTimeline:SetHeight(barHeight)

	local fullAssignmentHeight = CalculateRequiredAssignmentHeight(self)
	local fullBarHeight = CalculateRequiredBarHeight(self)

	self.assignmentTimeline:SetTimelineFrameHeight(fullAssignmentHeight)
	self.assignmentTimeline:UpdateVerticalScroll()

	self.bossAbilityTimeline:SetTimelineFrameHeight(fullBarHeight)
	self.bossAbilityTimeline:UpdateVerticalScroll()

	self.contentFrame:SetHeight(newContentFrameHeight)
	self:UpdateTimeline()
end

---@param self EPTimeline
---@param assignmentID integer
local function ScrollAssignmentIntoView(self, assignmentID)
	local frame = FindAssignmentFrame(s.AssignmentFrames, assignmentID)
	if frame then
		local y = select(5, frame:GetPointByName("TOPLEFT"))
		self.assignmentTimeline:ScrollVerticallyIfNotVisible(y, y - frame:GetHeight())
	end
end

---@param self EPTimeline
---@param allow boolean
local function SetAllowHeightResizing(self, allow)
	local previousAllowHeightResizing = self.allowHeightResizing
	self.allowHeightResizing = allow

	if previousAllowHeightResizing and not self.allowHeightResizing then
		local assignmentHeight = self.assignmentTimeline.frame:GetHeight()
		local assignmentProximity = assignmentHeight % self.assignmentDimensions.step
		if assignmentProximity < self.assignmentDimensions.step / 2.0 then
			assignmentHeight = assignmentHeight - assignmentProximity
		else
			assignmentHeight = assignmentHeight + (self.assignmentDimensions.step - assignmentProximity)
		end
		if assignmentHeight >= self.assignmentDimensions.step then
			assignmentHeight = assignmentHeight - k.PaddingBetweenAssignments
		end

		local barHeight = self.bossAbilityTimeline.frame:GetHeight()
		local barProximity = barHeight % self.bossAbilityDimensions.step
		if barProximity < self.bossAbilityDimensions.step / 2.0 then
			barHeight = barHeight - barProximity
		else
			barHeight = barHeight + (self.bossAbilityDimensions.step - barProximity)
		end
		if barHeight >= self.bossAbilityDimensions.step then
			barHeight = barHeight - k.PaddingBetweenBossAbilityBars
		end

		assignmentHeight = Clamp(assignmentHeight, self.assignmentDimensions.min, self.assignmentDimensions.max)
		barHeight = Clamp(barHeight, self.bossAbilityDimensions.min, self.bossAbilityDimensions.max)

		self.assignmentTimeline:SetHeight(assignmentHeight)
		self.bossAbilityTimeline:SetHeight(barHeight)

		local numberOfAssignmentsToShow =
			floor((assignmentHeight + k.PaddingBetweenAssignments + 0.5) / self.assignmentDimensions.step)
		numberOfAssignmentsToShow = max(k.MinimumNumberOfAssignmentRows, numberOfAssignmentsToShow)
		s.Preferences.timelineRows.numberOfAssignmentsToShow = numberOfAssignmentsToShow

		local numberOfBossAbilitiesToShow =
			floor((barHeight + k.PaddingBetweenBossAbilityBars + 0.5) / self.bossAbilityDimensions.step)
		numberOfBossAbilitiesToShow = max(k.MinimumNumberOfBossAbilityRows, numberOfBossAbilitiesToShow)
		s.Preferences.timelineRows.numberOfBossAbilitiesToShow = numberOfBossAbilitiesToShow

		local totalHeight = k.PaddingBetweenTimelineAndScrollBar
			+ k.HorizontalScrollBarHeight
			+ k.PaddingBetweenTimelines
			+ barHeight
			+ assignmentHeight

		self:SetHeight(totalHeight)
		self:UpdateTimeline()
	end
end

---@param preferences Preferences
local function SetPreferences(preferences)
	s:SetPreferences(preferences)
end

---@param self EPTimeline
---@param calculateAssignmentTimeFromStart fun(timelineAssignment: TimelineAssignment): number|nil
---@param getMinimumCombatLogEventTime fun(timelineAssignment: TimelineAssignment): number|nil
---@param computeChargeStates fun(timelineAssignments: table<integer, TimelineAssignment>)
local function SetFunctionReferences(
	self,
	calculateAssignmentTimeFromStart,
	getMinimumCombatLogEventTime,
	computeChargeStates
)
	s:SetFunctionReferences(function(name, ...)
		self:Fire(name, ...)
	end, calculateAssignmentTimeFromStart, getMinimumCombatLogEventTime, computeChargeStates)
end

---@return number
local function GetTotalTimelineDuration()
	return s.TotalTimelineDuration
end

---@param self EPTimeline
---@param simulating boolean
local function SetIsSimulating(self, simulating)
	s.IsSimulating = simulating
	if simulating then
		s.SimulationStartTime = GetTime()
		self.assignmentTimeline.timelineFrame:SetScript("OnEnter", nil)
		self.bossAbilityTimeline.timelineFrame:SetScript("OnEnter", nil)
		self.assignmentTimeline.timelineFrame:SetScript("OnLeave", nil)
		self.bossAbilityTimeline.timelineFrame:SetScript("OnLeave", nil)
		local assignmentFrame = self.assignmentTimeline.frame
		local bossAbilityFrame = self.bossAbilityTimeline.frame
		local bossAbilityTimelineFrame = self.bossAbilityTimeline.timelineFrame
		local assignmentLine = self.assignmentTimeline.verticalPositionLine
		local bossAbilityLine = self.bossAbilityTimeline.verticalPositionLine
		bossAbilityTimelineFrame:SetScript("OnUpdate", function()
			local timelineFrameWidth = bossAbilityTimelineFrame:GetWidth()
			local horizontalOffset = ConvertTimeToTimelineOffset(GetTime() - s.SimulationStartTime, timelineFrameWidth)
			horizontalOffset = bossAbilityTimelineFrame:GetLeft() - bossAbilityFrame:GetLeft() + horizontalOffset

			bossAbilityLine:SetPoint("TOP", bossAbilityFrame, "TOPLEFT", horizontalOffset, 0)
			bossAbilityLine:SetPoint("BOTTOM", bossAbilityFrame, "BOTTOMLEFT", horizontalOffset, 0)
			bossAbilityLine:Show()

			assignmentLine:SetPoint("TOP", assignmentFrame, "TOPLEFT", horizontalOffset, 0)
			assignmentLine:SetPoint("BOTTOM", assignmentFrame, "BOTTOMLEFT", horizontalOffset, 0)
			assignmentLine:Show()

			UpdateTimeLabels()
		end)
	else
		s.SimulationStartTime = 0.0
		self.bossAbilityTimeline.timelineFrame:SetScript("OnUpdate", nil)
		self.assignmentTimeline.timelineFrame:SetScript("OnEnter", function(frame)
			HandleTimelineFrameEnter(self, frame)
		end)
		self.bossAbilityTimeline.timelineFrame:SetScript("OnEnter", function(frame)
			HandleTimelineFrameEnter(self, frame)
		end)
		self.assignmentTimeline.timelineFrame:SetScript("OnLeave", function(frame)
			HandleTimelineFrameLeave(self, frame)
		end)
		self.bossAbilityTimeline.timelineFrame:SetScript("OnLeave", function(frame)
			HandleTimelineFrameLeave(self, frame)
		end)
		self.assignmentTimeline.verticalPositionLine:Hide()
		self.bossAbilityTimeline.verticalPositionLine:Hide()
		UpdateTimeLabels()
	end
end

---@param self EPTimeline
local function GetOffsetFromTime(self, time)
	if not time or time < 0 then
		return 0
	end

	local timelineFrame = self.assignmentTimeline.timelineFrame
	local timelineFrameWidth = timelineFrame:GetWidth()

	if s.TotalTimelineDuration <= 0 then
		return 0
	end

	-- Convert time to an offset percentage
	local offsetPercent = time / s.TotalTimelineDuration

	-- Apply padding adjustments
	local padding = k.TimelineLinePadding.x
	local effectiveTimelineWidth = timelineFrameWidth - (padding * 2)

	-- Calculate the offset within the timeline frame
	local offset = (offsetPercent * effectiveTimelineWidth) + padding

	-- Ensure the offset stays within valid bounds
	return Clamp(offset, 0, effectiveTimelineWidth + padding)
end

---@param self EPTimeline
---@param scroll number
local function SetHorizontalScroll(self, scroll)
	local scrollFrameWidth = self.bossAbilityTimeline.scrollFrame:GetWidth()
	local timelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

	self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(scroll)
	self.assignmentTimeline.scrollFrame:SetHorizontalScroll(scroll)
	self.splitterScrollFrame:SetHorizontalScroll(scroll)

	UpdateHorizontalScrollBarThumb(
		self.horizontalScrollBar:GetWidth(),
		self.thumb,
		scrollFrameWidth,
		timelineFrameWidth,
		scroll
	)
end

---@param self EPTimeline
---@param scroll number|nil
local function SetAssignmentTimelineVerticalScroll(self, scroll)
	if not scroll then
		scroll = self.assignmentTimeline.scrollFrame:GetVerticalScroll()
	end
	local assignmentScrollFrameHeight = self.assignmentTimeline.scrollFrame:GetHeight()
	local assignmentTimelineFrameHeight = self.assignmentTimeline.timelineFrame:GetHeight()
	local maxVerticalScroll = assignmentTimelineFrameHeight - assignmentScrollFrameHeight
	local snapValue = (self.assignmentTimeline.textureHeight + self.assignmentTimeline.listPadding) / 2
	local currentSnapValue = floor((scroll / snapValue) + 0.5)
	local newVerticalScroll = Clamp(currentSnapValue * snapValue, 0, maxVerticalScroll)
	self.assignmentTimeline.scrollFrame:SetVerticalScroll(newVerticalScroll)
	self.assignmentTimeline.listScrollFrame:SetVerticalScroll(newVerticalScroll)
	self.assignmentTimeline:UpdateVerticalScroll()
end

---@param self EPTimeline
---@param scroll number|nil
local function SetBossAbilityTimelineVerticalScroll(self, scroll)
	if not scroll then
		scroll = self.bossAbilityTimeline.scrollFrame:GetVerticalScroll()
	end
	local bossScrollFrameHeight = self.bossAbilityTimeline.scrollFrame:GetHeight()
	local bossTimelineFrameHeight = self.bossAbilityTimeline.timelineFrame:GetHeight()
	local bossMaxVerticalScroll = bossTimelineFrameHeight - bossScrollFrameHeight
	local bossSnapValue = (self.bossAbilityTimeline.textureHeight + self.bossAbilityTimeline.listPadding) / 2
	local bossCurrentSnapValue = floor((scroll / bossSnapValue) + 0.5)
	local bossNewVerticalScroll = Clamp(bossCurrentSnapValue * bossSnapValue, 0, bossMaxVerticalScroll)
	self.bossAbilityTimeline.scrollFrame:SetVerticalScroll(bossNewVerticalScroll)
	self.bossAbilityTimeline.listScrollFrame:SetVerticalScroll(bossNewVerticalScroll)
	self.bossAbilityTimeline:UpdateVerticalScroll()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetSize(
		k.FrameWidth,
		k.FrameHeight - k.HorizontalScrollBarHeight - k.PaddingBetweenTimelineAndScrollBar
	)

	local splitterScrollFrame = CreateFrame("ScrollFrame", Type .. "SplitterScrollFrame" .. count, contentFrame)
	splitterScrollFrame:SetHeight(k.PaddingBetweenTimelines)
	splitterScrollFrame:SetClipsChildren(true)

	local splitterFrame = CreateFrame("Frame", Type .. "SplitterFrame" .. count, splitterScrollFrame)
	splitterFrame:SetHeight(k.PaddingBetweenTimelines)
	splitterScrollFrame:SetScrollChild(splitterFrame)

	local horizontalScrollBar = CreateFrame("Frame", Type .. "HorizontalScrollBar" .. count, frame)
	horizontalScrollBar:SetSize(k.FrameWidth, k.HorizontalScrollBarHeight)

	local scrollBarBackground = horizontalScrollBar:CreateTexture(Type .. "ScrollBarBackground" .. count, "BACKGROUND")
	scrollBarBackground:SetAllPoints()
	scrollBarBackground:SetColorTexture(unpack(k.ScrollBackgroundColor))

	local thumb = CreateFrame("Button", Type .. "ScrollBarThumb" .. count, horizontalScrollBar)
	thumb:SetPoint("LEFT", k.ThumbPadding.x, 0)
	thumb:SetSize(
		horizontalScrollBar:GetWidth() - 2 * k.ThumbPadding.x,
		k.HorizontalScrollBarHeight - (2 * k.ThumbPadding.y)
	)
	thumb:EnableMouse(true)
	thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local thumbBackground = thumb:CreateTexture(Type .. "ScrollBarThumbBackground" .. count, "BACKGROUND")
	thumbBackground:SetAllPoints()
	thumbBackground:SetColorTexture(unpack(k.ScrollThumbBackgroundColor))

	local phaseNameFrame = CreateFrame("Frame", nil, frame)
	phaseNameFrame:SetClipsChildren(true)

	local chargeFrame = CreateFrame("Frame", nil, frame)
	chargeFrame:SetClipsChildren(true)

	---@class EPTimeline : AceGUIWidget
	---@field parent AceGUIContainer|nil
	---@field assignmentTimeline EPTimelineSection
	---@field bossAbilityTimeline EPTimelineSection
	---@field addAssigneeDropdown EPDropdown
	---@field assigneesAndSpells table<integer, AssignmentTimelineRow>
	---@field bossAbilityInstances table<integer, BossAbilityInstance>
	---@field bossAbilityVisibility table<integer, boolean>
	---@field bossAbilityOrder table<integer, integer>
	---@field bossPhaseOrder table<integer, integer>
	---@field bossPhases table<integer, BossPhase>
	---@field allowHeightResizing boolean
	---@field bossAbilityDimensions {min: integer, max:integer, step:number}
	---@field assignmentDimensions {min: integer, max:integer, step:number}
	---@field zoomFactor number
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetBossAbilities = SetBossAbilities,
		SetAssignments = SetAssignments,
		GetAssignments = GetAssignments,
		GetAssignmentContainer = GetAssignmentContainer,
		GetBossAbilityContainer = GetBossAbilityContainer,
		GetAddAssigneeDropdown = GetAddAssigneeDropdown,
		UpdateTimeline = UpdateTimeline,
		OnHeightSet = OnHeightSet,
		SelectAssignment = Private.timeline.utilities.SelectAssignment,
		ClearSelectedAssignment = Private.timeline.utilities.ClearSelectedAssignment,
		SelectBossAbility = Private.timeline.utilities.SelectBossAbility,
		ClearSelectedBossAbility = Private.timeline.utilities.ClearSelectedBossAbility,
		ClearSelectedAssignments = Private.timeline.utilities.ClearSelectedAssignments,
		ClearSelectedBossAbilities = Private.timeline.utilities.ClearSelectedBossAbilities,
		SetAllowHeightResizing = SetAllowHeightResizing,
		SetMaxAssignmentHeight = SetMaxAssignmentHeight,
		SetPreferences = SetPreferences,
		SetFunctionReferences = SetFunctionReferences,
		UpdateHeightFromBossAbilities = UpdateHeightFromBossAbilities,
		UpdateHeightFromAssignments = UpdateHeightFromAssignments,
		UpdateAssignmentsAndTickMarks = UpdateAssignmentsAndTickMarks,
		GetTotalTimelineDuration = GetTotalTimelineDuration,
		SetIsSimulating = SetIsSimulating,
		ScrollAssignmentIntoView = ScrollAssignmentIntoView,
		ConvertTimeToTimelineOffset = ConvertTimeToTimelineOffset,
		FindTimelineAssignment = Private.timeline.utilities.FindTimelineAssignment,
		GetOffsetFromTime = GetOffsetFromTime,
		SetHorizontalScroll = SetHorizontalScroll,
		SetAssignmentTimelineVerticalScroll = SetAssignmentTimelineVerticalScroll,
		SetBossAbilityTimelineVerticalScroll = SetBossAbilityTimelineVerticalScroll,
		frame = frame,
		splitterFrame = splitterFrame,
		splitterScrollFrame = splitterScrollFrame,
		contentFrame = contentFrame,
		type = Type,
		horizontalScrollBar = horizontalScrollBar,
		thumb = thumb,
		phaseNameFrame = phaseNameFrame,
		chargeFrame = chargeFrame,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
