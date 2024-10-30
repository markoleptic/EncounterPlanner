local Type = "EPTimeline"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local GetSpellTexture = C_Spell.GetSpellTexture
local ipairs = ipairs
local pairs = pairs
local unpack = unpack

local frameWidth = 900
local frameHeight = 400
local paddingBetweenTimelines = 30
local paddingBetweenBars = 4
local paddingBetweenTimelineAndScrollBar = 25
local barHeight = 30
local horizontalScrollBarHeight = 20
local tickWidth = 2
local assignmentSpellIconSize = { x = 30, y = 30 }
local fontPath = LSM:Fetch("font", "PT Sans Narrow")
local tickColor = { 1, 1, 1, 0.75 }
local tickFontSize = 10
local zoomFactor = 1
local minZoomFactor = 1
local maxZoomFactor = 10
local zoomStep = 0.05
local tooltip = EncounterPlanner.tooltip
local tooltipUpdateTime = EncounterPlanner.tooltipUpdateTime
local colors = {
	{ 255, 87, 51, 1 },
	{ 51, 255, 87, 1 },
	{ 51, 87, 255, 1 },
	{ 255, 51, 184, 1 },
	{ 255, 214, 51, 1 },
	{ 51, 255, 249, 1 },
	{ 184, 51, 255, 1 },
}

local thumbPadding = { x = 2, y = 2 }
local timelineLinePadding = { x = 25, y = 25 }
local timelineFrameIsDragging = false
local timelineFrameDragStartX = 0
local thumbOffsetWhenThumbClicked = 0
local scrollBarWidthWhenThumbClicked = 0
local thumbWidthWhenThumbClicked = 0
local thumbIsDragging = false
local totalTimelineDuration = 0

local function ResetLocalVariables()
	thumbPadding = { x = 2, y = 2 }
	timelineLinePadding = { x = 25, y = 25 }
	timelineFrameIsDragging = false
	timelineFrameDragStartX = 0
	thumbOffsetWhenThumbClicked = 0
	scrollBarWidthWhenThumbClicked = 0
	thumbWidthWhenThumbClicked = 0
	thumbIsDragging = false
	totalTimelineDuration = 0
end

local function HandleTimelineTooltipOnUpdate(frame, elapsed)
	frame.updateTooltipTimer = frame.updateTooltipTimer - elapsed
	if frame.updateTooltipTimer > 0 then
		return
	end
	frame.updateTooltipTimer = tooltipUpdateTime
	local owner = frame:GetOwner()
	if owner and frame.spellID then
		frame:SetSpellByID(frame.spellID)
	end
end

local function HandleIconEnter(frame, _)
	if frame.spellID and frame.spellID ~= 0 then
		tooltip:ClearLines()
		tooltip:SetOwner(frame.assignmentFrame, "ANCHOR_CURSOR", 0, 0)
		tooltip:SetSpellByID(frame.spellID)
		tooltip:SetScript("OnUpdate", HandleTimelineTooltipOnUpdate)
	end
end

local function HandleIconLeave(_, _)
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()
end

local function HandleAssignmentMouseUp(frame, mouseButton, epTimeline)
	if mouseButton ~= "RightButton" then
		return
	end
	if frame.assignmentIndex then
		epTimeline:Fire("AssignmentClicked", frame.assignmentIndex)
	end
end

local function UpdateLinePosition(frame)
	local self = frame.obj
	local xPosition, _ = GetCursorPosition()
	local newTimeOffset = (xPosition / UIParent:GetEffectiveScale()) - self.timelineFrame:GetLeft()
	local newassignmentTimeOffset = (xPosition / UIParent:GetEffectiveScale()) - self.assignmentTimelineFrame:GetLeft()

	self.timelineVerticalPositionLine:SetPoint("TOP", self.timelineFrame, "TOPLEFT", newTimeOffset, 0)
	self.timelineVerticalPositionLine:SetPoint("BOTTOM", self.timelineFrame, "BOTTOMLEFT", newTimeOffset, 0)
	self.timelineVerticalPositionLine:Show()

	self.assignmentTimelineVerticalPositionLine:SetPoint(
		"TOP",
		self.assignmentTimelineFrame,
		"TOPLEFT",
		newassignmentTimeOffset,
		0
	)
	self.assignmentTimelineVerticalPositionLine:SetPoint(
		"BOTTOM",
		self.assignmentTimelineFrame,
		"BOTTOMLEFT",
		newassignmentTimeOffset,
		0
	)
	self.assignmentTimelineVerticalPositionLine:Show()
end

local function HandleTimelineFrameEnter(frame)
	if timelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", function()
		UpdateLinePosition(frame)
	end)
end

local function HandleTimelineFrameLeave(frame)
	local self = frame.obj
	if timelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", nil)
	self.timelineVerticalPositionLine:Hide()
	self.assignmentTimelineVerticalPositionLine:Hide()
end

local function HandleThumbUpdate(frame)
	local self = frame.obj
	if not thumbIsDragging then
		return
	end

	local paddingX = thumbPadding.x
	local currentOffset = thumbOffsetWhenThumbClicked
	local currentWidth = thumbWidthWhenThumbClicked
	local currentScrollBarWidth = scrollBarWidthWhenThumbClicked
	local xPosition, _ = GetCursorPosition()
	local newOffset = (xPosition / UIParent:GetEffectiveScale()) - self.scrollBar:GetLeft() - currentOffset

	local minAllowedOffset = paddingX
	local maxAllowedOffset = currentScrollBarWidth - currentWidth - paddingX
	newOffset = math.max(newOffset, minAllowedOffset)
	newOffset = math.min(newOffset, maxAllowedOffset)
	self.thumb:SetPoint("LEFT", newOffset, 0)

	local scrollFrame = self.frame
	local scrollFrameWidth = scrollFrame:GetWidth()
	local timelineWidth = self.timelineWrapperFrame:GetWidth()
	local maxScroll = timelineWidth - scrollFrameWidth

	-- Calculate the scroll frame's horizontal scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * paddingX)
	local scrollOffset = ((newOffset - paddingX) / maxThumbPosition) * maxScroll
	scrollFrame:SetHorizontalScroll(scrollOffset)
end

local function HandleThumbMouseDown(frame)
	local self = frame.obj
	local x, _ = GetCursorPosition()
	thumbOffsetWhenThumbClicked = (x / UIParent:GetEffectiveScale()) - self.thumb:GetLeft()
	scrollBarWidthWhenThumbClicked = self.scrollBar:GetWidth()
	thumbWidthWhenThumbClicked = self.thumb:GetWidth()
	thumbIsDragging = true
	self.thumb:SetScript("OnUpdate", HandleThumbUpdate)
end

local function HandleThumbMouseUp(frame)
	local self = frame.obj
	thumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

local function HandleTimelineFrameUpdate(frame)
	local self = frame.obj
	if not timelineFrameIsDragging then
		return
	end

	local timelineWrapperFrame = self.timelineWrapperFrame
	local scrollFrame = self.frame

	local currentX, _ = GetCursorPosition()
	local dx = (currentX - timelineFrameDragStartX) / scrollFrame:GetEffectiveScale()
	local newScrollH = scrollFrame:GetHorizontalScroll() - dx
	local maxScrollH = timelineWrapperFrame:GetWidth() - scrollFrame:GetWidth()

	scrollFrame:SetHorizontalScroll(math.min(math.max(0, newScrollH), maxScrollH))
	timelineFrameDragStartX = currentX
	self:UpdateScrollBar()
end

local function HandleTimelineFrameDragStart(frame, button)
	local self = frame.obj
	timelineFrameIsDragging = true
	local x, _ = GetCursorPosition()
	timelineFrameDragStartX = x
	frame:SetScript("OnUpdate", HandleTimelineFrameUpdate)
	self.timelineVerticalPositionLine:Hide()
	self.assignmentTimelineVerticalPositionLine:Hide()
end

local function HandleTimelineFrameDragStop(frame)
	local self = frame.obj
	timelineFrameIsDragging = false
	frame:SetScript("OnUpdate", nil)

	local x, y = GetCursorPosition()
	x = x / UIParent:GetEffectiveScale()
	y = y / UIParent:GetEffectiveScale()

	if
		x > self.assignmentTimelineFrame:GetLeft()
		and x < self.assignmentTimelineFrame:GetRight()
		and y < self.assignmentTimelineFrame:GetTop()
		and y > self.assignmentTimelineFrame:GetBottom()
	then
		self.assignmentTimelineFrame:SetScript("OnUpdate", function()
			UpdateLinePosition(self.assignmentTimelineFrame)
		end)
	elseif
		x > self.timelineFrame:GetLeft()
		and x < self.timelineFrame:GetRight()
		and y < self.timelineFrame:GetTop()
		and y > self.timelineFrame:GetBottom()
	then
		self.timelineFrame:SetScript("OnUpdate", function()
			UpdateLinePosition(self.timelineFrame)
		end)
	end
end

local function HandleTimelineFrameMouseWheel(frame, delta)
	local self = frame.obj
	local timelineWrapperFrame = self.timelineWrapperFrame
	local timelineDuration = totalTimelineDuration
	local scrollFrame = self.frame

	local visibleDuration = timelineDuration / zoomFactor
	local visibleStartTime = (scrollFrame:GetHorizontalScroll() / timelineWrapperFrame:GetWidth()) * timelineDuration
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
	newVisibleStartTime = math.max(0, newVisibleStartTime)
	newVisibleEndTime = math.min(timelineDuration, newVisibleEndTime)

	-- Adjust the timeline frame width based on zoom factor
	local newTimelineFrameWidth = scrollFrame:GetWidth() * zoomFactor

	-- Recalculate the new scroll position based on the new visible start time
	local newHorizontalScroll = (newVisibleStartTime / timelineDuration) * newTimelineFrameWidth
	scrollFrame:SetHorizontalScroll(newHorizontalScroll)

	timelineWrapperFrame:SetWidth(newTimelineFrameWidth)

	self:UpdateScrollBar()
	self:UpdateTickMarks()
	self:UpdateBossAbilityBars()
	self:UpdateAssignments()
end

local function HandleAssignmentTimelineFrameMouseDown(frame, button)
	if button ~= "RightButton" then
		return
	end
	local self = frame.obj

	local scrollFrame = self.frame

	local currentX, currentY = GetCursorPosition()
	currentX = currentX / scrollFrame:GetEffectiveScale()
	currentY = currentY / scrollFrame:GetEffectiveScale()

	-- todo: Choose the nearest boss ability based on horizontal distance from the cursor and create a new assignment
end

---@class EPTimeline : AceGUIWidget
---@field parent AceGUIContainer|nil
---@field frame ScrollFrame
---@field type string
---@field timelineWrapperFrame table|Frame
---@field assignmentTimelineFrame table|Frame
---@field timelineFrame table|Frame
---@field assignmentTimelineVerticalPositionLine table|Texture
---@field timelineVerticalPositionLine table|Texture
---@field scrollBar table|Frame
---@field thumb Button
---
---@field assignees table<integer, string>
---@field assignmentTimelineTicks table<number, Texture>
---@field assignmentTextures table<number, Texture>
---@field bossAbilities table<number, BossAbility>
---@field bossAbilityOrder table<number, number>
---@field bossAbilityTextureBars table<number, Texture>
---@field bossAbilityTimelineTicks table<number, Texture>
---@field bossPhaseOrder table<number, number> sequence of phases based on repeatAfter
---@field bossPhases table<number, BossPhase>
---@field timelineAssignments table<integer, TimelineAssignment>

---@param self EPTimeline
local function OnAcquire(self)
	self.assignmentTimelineTicks = self.assignmentTimelineTicks or {}
	self.assignmentTextures = self.assignmentTextures or {}
	self.bossAbilityTextureBars = self.bossAbilityTextureBars or {}
	self.bossAbilityTimelineTicks = self.bossAbilityTimelineTicks or {}
	self.bossAbilities = self.bossAbilities or {}
	self.bossAbilityOrder = self.bossAbilityOrder or {}
	self.bossPhaseOrder = self.bossPhaseOrder or {}
	self.bossPhases = self.bossPhases or {}
	self.timelineAssignments = self.timelineAssignments or {}
	self.assignees = self.assignees or {}
end

---@param self EPTimeline
local function OnRelease(self)
	ResetLocalVariables()
end

-- Sets the boss ability entries for the timeline.
---@param self EPTimeline
---@param abilities table<number, BossAbility>
---@param abilityOrder table<number, number>
---@param phases table<number, BossPhase>
---@param assignments table<integer, TimelineAssignment>
---@param assignees table<integer, string>
local function SetEntries(self, abilities, abilityOrder, phases, assignments, assignees)
	self.bossAbilities = abilities
	self.bossAbilityOrder = abilityOrder
	self.bossPhases = phases
	self.timelineAssignments = assignments
	self.assignees = assignees

	local totalOccurances = 0
	local timelineDuration = 0
	for _, phaseData in pairs(self.bossPhases) do
		timelineDuration = timelineDuration + (phaseData.duration * phaseData.count)
		totalOccurances = totalOccurances + phaseData.count
	end
	totalTimelineDuration = timelineDuration

	local currentPhase = 1
	while #self.bossPhaseOrder < totalOccurances and currentPhase ~= nil do
		table.insert(self.bossPhaseOrder, currentPhase)
		currentPhase = phases[currentPhase].repeatAfter
	end

	self:UpdateHeight()

	HandleTimelineFrameMouseWheel(self.timelineFrame, 0)
end

-- Updates the rendering of assignments on the timeline.
---@param self EPTimeline
local function UpdateAssignments(self)
	-- Hide existing assignments
	for _, texture in pairs(self.assignmentTextures) do
		texture:Hide()
	end

	for index, assignment in ipairs(self.timelineAssignments) do
		self:DrawAssignment(assignment.startTime, assignment.assignment.spellInfo.spellID, index, assignment.offset)
	end
end

-- Helper function to draw a boss ability timeline bar.
---@param self EPTimeline
---@param startTime number absolute start time of the assignment.
---@param spellID integer spellID of the spell being assigned.
---@param index integer index into the assignments table.
---@param offsetY number offset from the top of the timeline frame.
local function DrawAssignment(self, startTime, spellID, index, offsetY)
	if totalTimelineDuration <= 0.0 then
		return
	end

	---@class Texture
	local assignment = self.assignmentTextures[index]
	if not assignment then
		assignment = self.assignmentTimelineFrame:CreateTexture(nil, "OVERLAY")
		assignment.assignmentFrame = self.assignmentTimelineFrame
		assignment:SetScript("OnEnter", function(frame, motion)
			HandleIconEnter(frame, motion)
		end)
		assignment:SetScript("OnLeave", function(frame, motion)
			HandleIconLeave(frame, motion)
		end)
		assignment:SetScript("OnMouseUp", function(frame, mouseButton, _)
			HandleAssignmentMouseUp(frame, mouseButton, self)
		end)
		self.assignmentTextures[index] = assignment
	end

	assignment.spellID = spellID
	assignment.assignmentIndex = index
	if spellID == 0 or spellID == nil then
		assignment:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
	else
		local iconID, _ = GetSpellTexture(spellID)
		assignment:SetTexture(iconID)
	end

	local timelineWidth = self.timelineWrapperFrame:GetWidth() - 2 * timelineLinePadding.x
	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local offsetX = timelineStartPosition + timelineLinePadding.x

	assignment:SetSize(assignmentSpellIconSize.x, assignmentSpellIconSize.y)
	assignment:SetPoint("TOPLEFT", self.assignmentTimelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignment:Show()
end

-- Updates the rendering of boss abilities on the timeline.
---@param self EPTimeline
local function UpdateBossAbilityBars(self)
	-- Hide existing bars
	for _, texture in pairs(self.bossAbilityTextureBars) do
		texture:Hide()
	end

	local cumulativePhaseStartTimes = 0
	local index = 1

	for _, phaseId in ipairs(self.bossPhaseOrder) do
		local phaseData = self.bossPhases[phaseId]
		if phaseData then
			local phaseStartTime = cumulativePhaseStartTimes

			-- Iterate over abilities for the current phase
			local colorIndex = 1
			for _, spellID in pairs(self.bossAbilityOrder) do
				local abilityData = self.bossAbilities[spellID]
				local color = colors[colorIndex]
				local cumulativePhaseCastTimes = phaseStartTime
				local offset = (colorIndex - 1) * (barHeight + paddingBetweenBars)
				if abilityData.phases[phaseId] then -- phase based timers
					local phaseDetails = abilityData.phases[phaseId]

					-- Iterate over each cast time
					if phaseDetails.castTimes then
						for _, castTime in ipairs(phaseDetails.castTimes) do
							cumulativePhaseCastTimes = cumulativePhaseCastTimes + castTime
							local castStart = cumulativePhaseCastTimes
							local castEnd = castStart + abilityData.castTime
							local effectEnd = castEnd + abilityData.duration

							self:DrawBossAbilityBar(castStart, effectEnd, color, index, offset)
							index = index + 1

							-- Handle repeat intervals for abilities
							if phaseDetails.repeatInterval then
								local repeatInterval = phaseDetails.repeatInterval
								local nextRepeatStart = castStart + repeatInterval

								while nextRepeatStart < phaseStartTime + phaseData.duration do
									local repeatEnd = nextRepeatStart + abilityData.castTime
									local repeatEffectEnd = repeatEnd + abilityData.duration

									self:DrawBossAbilityBar(nextRepeatStart, repeatEffectEnd, color, index, offset)
									index = index + 1

									nextRepeatStart = nextRepeatStart + repeatInterval
								end
							end
						end
					end
				end
				if abilityData.eventTriggers then -- event based timers
					for triggerSpellID, eventTriggerData in pairs(abilityData.eventTriggers) do
						local triggerAbilityData = self.bossAbilities[triggerSpellID]
						if triggerAbilityData and triggerAbilityData.phases[phaseId] then
							local triggerPhaseDetails = triggerAbilityData.phases[phaseId]
							local cumulativeTriggerTime = phaseStartTime
							-- iterate through the trigger ability cast times
							for castOccurance, triggerCastTime in ipairs(triggerPhaseDetails.castTimes) do
								cumulativeTriggerTime = cumulativeTriggerTime
									+ triggerCastTime
									+ triggerAbilityData.castTime
								local cumulativeCastTime = 0
								-- iterate through the dependent ability cast times
								for _, castTime in ipairs(eventTriggerData.castTimes) do
									cumulativeCastTime = cumulativeCastTime + castTime
									local castStart = cumulativeTriggerTime + cumulativeCastTime
									local castEnd = castStart + abilityData.castTime
									local effectEnd = castEnd + abilityData.duration
									self:DrawBossAbilityBar(castStart, effectEnd, color, index, offset)
									index = index + 1
								end
								if
									eventTriggerData.repeatCriteria
									and eventTriggerData.repeatCriteria.castOccurance == castOccurance
								then
									cumulativeCastTime = cumulativeCastTime + cumulativeTriggerTime
									while cumulativeCastTime < totalTimelineDuration do
										for _, repeatCastTime in ipairs(eventTriggerData.repeatCriteria.castTimes) do
											cumulativeCastTime = cumulativeCastTime + repeatCastTime
											local castStart = cumulativeCastTime
											local castEnd = cumulativeCastTime + abilityData.castTime
											local effectEnd = castEnd + abilityData.duration
											self:DrawBossAbilityBar(castStart, effectEnd, color, index, offset)
											index = index + 1
										end
									end
								end
							end
						end
					end
				end
				colorIndex = colorIndex + 1
			end
			cumulativePhaseStartTimes = cumulativePhaseStartTimes + phaseData.duration
		end
	end
end

-- Helper function to draw a boss ability timeline bar.
---@param self EPTimeline
---@param startTime number absolute start time of the bar.
---@param endTime number absolute end time of the bar.
---@param color integer[] color of the bar.
---@param index integer index into the bars table.
---@param offset number offset from the top of the timeline frame.
local function DrawBossAbilityBar(self, startTime, endTime, color, index, offset)
	if totalTimelineDuration <= 0.0 then
		return
	end

	local padding = timelineLinePadding
	local timelineFrame = self.timelineFrame
	local timelineWidth = self.timelineWrapperFrame:GetWidth() - 2 * padding.x

	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local timelinetimeEndPosition = (endTime / totalTimelineDuration) * timelineWidth

	local bar = self.bossAbilityTextureBars[index]
	if not bar then
		bar = timelineFrame:CreateTexture(nil, "OVERLAY")
		self.bossAbilityTextureBars[index] = bar
	end

	local r, g, b, a = unpack(color)
	bar:SetColorTexture(r / 255.0, g / 255.0, b / 255.0, a)
	bar:SetSize(timelinetimeEndPosition - timelineStartPosition, barHeight)
	bar:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", timelineStartPosition + padding.x, -offset)
	bar:Show()
end

-- Updates the scroll bar width and offset based on the visible area of the timeline.
---@param self EPTimeline
local function UpdateScrollBar(self)
	local scrollFrame = self.frame
	local scrollFrameWidth = scrollFrame:GetWidth()
	local timelineWidth = self.timelineWrapperFrame:GetWidth()
	local scrollBarWidth = self.scrollBar:GetWidth()
	local thumbPaddingX = thumbPadding.x

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
end

-- Updates the ticks for the boss ability timeline and assignments timeline.
---@param self EPTimeline
local function UpdateTickMarks(self)
	-- Clear existing tick marks
	for _, tick in pairs(self.bossAbilityTimelineTicks) do
		tick:Hide()
	end
	for _, tick in pairs(self.assignmentTimelineTicks) do
		tick:Hide()
	end

	if totalTimelineDuration <= 0.0 then
		return
	end

	-- Define visible range in time (based on zoomFactor)
	local visibleDuration = totalTimelineDuration / zoomFactor

	-- Determine appropriate tick interval based on visible duration
	local tickInterval
	if visibleDuration >= 600 then
		tickInterval = 60 -- Show tick marks every 1 minute
	elseif visibleDuration >= 120 then
		tickInterval = 30 -- Show tick marks every 30 seconds
	elseif visibleDuration >= 60 then
		tickInterval = 10 -- Show tick marks every 10 seconds
	else
		tickInterval = 5 -- Show tick marks every 5 seconds
	end

	local timelineWrapperFrame = self.timelineWrapperFrame
	local timelineFrame = self.timelineFrame
	local assignmentTimelineFrame = self.assignmentTimelineFrame
	local timelineWidth = timelineWrapperFrame:GetWidth()
	local padding = timelineLinePadding

	-- Loop through to create the tick marks at the calculated intervals
	for i = 0, totalTimelineDuration, tickInterval do
		local position = (i / totalTimelineDuration) * (timelineWidth - (2 * padding.x))
		local currentTickWidth = tickWidth
		if tickInterval == 60 then
			currentTickWidth = tickWidth
		elseif i % 2 == 0 then
			currentTickWidth = tickWidth * 0.5
		else
			currentTickWidth = tickWidth
		end
		-- Create or reuse tick mark
		local timelineTick = self.bossAbilityTimelineTicks[i]
		if not timelineTick then
			timelineTick = timelineFrame:CreateTexture(nil, "ARTWORK")
			timelineTick:SetColorTexture(unpack(tickColor))
			self.bossAbilityTimelineTicks[i] = timelineTick
		end
		timelineTick:SetWidth(currentTickWidth)
		timelineTick:SetPoint("TOP", timelineFrame, "TOPLEFT", position + padding.x, 0)
		timelineTick:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", position + padding.x, 0)
		timelineTick:Show()

		local assignmentTick = self.assignmentTimelineTicks[i]
		if not assignmentTick then
			assignmentTick = assignmentTimelineFrame:CreateTexture(nil, "ARTWORK")
			assignmentTick:SetColorTexture(unpack(tickColor))
			self.assignmentTimelineTicks[i] = assignmentTick
		end
		assignmentTick:SetWidth(currentTickWidth)
		assignmentTick:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT", position + padding.x, 0)
		assignmentTick:SetPoint("BOTTOM", assignmentTimelineFrame, "BOTTOMLEFT", position + padding.x, 0)
		assignmentTick:Show()

		-- Create or reuse timestamp label
		local label = self.bossAbilityTimelineTicks["label" .. i]
		if not label then
			label = timelineWrapperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			self.bossAbilityTimelineTicks["label" .. i] = label
			if fontPath then
				label:SetFont(fontPath, tickFontSize)
			end
		end
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		label:SetText(string.format("%d:%02d", minutes, seconds))
		label:SetPoint("TOP", timelineTick, "BOTTOM")
		label:SetPoint("BOTTOM", assignmentTick, "TOP")
		label:Show()
	end
end

-- Called when the width is set for EPTimeline widget.
---@param self EPTimeline
---@param width number
local function OnWidthSet(self, width)
	HandleTimelineFrameMouseWheel(self.timelineWrapperFrame, 0)
end

-- Called when the height is set for EPTimeline widget.
---@param self EPTimeline
---@param height number
local function OnHeightSet(self, height)
	self.timelineWrapperFrame:SetHeight(height - paddingBetweenTimelineAndScrollBar - horizontalScrollBarHeight)
	self.timelineFrame:SetPoint("TOPLEFT", self.timelineWrapperFrame, "TOPLEFT")
	self.timelineFrame:SetPoint("TOPRIGHT", self.timelineWrapperFrame, "TOPRIGHT")
	self.timelineFrame:SetHeight(self:CalculateRequiredBarHeight())
	self.assignmentTimelineFrame:SetPoint("TOPLEFT", self.timelineFrame, "BOTTOMLEFT", 0, -paddingBetweenTimelines)
	self.assignmentTimelineFrame:SetPoint("TOPRIGHT", self.timelineFrame, "BOTTOMRIGHT", 0, -paddingBetweenTimelines)
	self.assignmentTimelineFrame:SetPoint("BOTTOMLEFT", self.timelineWrapperFrame, "BOTTOMLEFT")
	self.assignmentTimelineFrame:SetPoint("BOTTOMRIGHT", self.timelineWrapperFrame, "BOTTOMRIGHT")
	HandleTimelineFrameMouseWheel(self.timelineWrapperFrame, 0)
end

-- Calculate the total required height for boss ability bars.
---@param self EPTimeline
---@return number
local function CalculateRequiredBarHeight(self)
	local totalBarHeight = 0
	if self.bossAbilityOrder then
		local count = #self.bossAbilityOrder
		totalBarHeight = count * (barHeight + paddingBetweenBars) - paddingBetweenBars
	end
	return totalBarHeight
end

---@param self EPTimeline
---@return number
local function CountUniqueAssignees(self)
	return #self.assignees
end

-- Calculate the total required height for assignments.
---@param self EPTimeline
---@return number
local function CalculateRequiredAssignmentHeight(self)
	local count = self:CountUniqueAssignees()
	if count > 0 then
		return count * (assignmentSpellIconSize.y + 2) - 2
	end
	return 0
end

-- Calculate the total required height for widget.
---@param self EPTimeline
---@return number
local function CalculateRequiredHeight(self)
	local totalBarHeight = self:CalculateRequiredBarHeight()
	local totalAssignmentHeight = self:CalculateRequiredAssignmentHeight()
	return totalBarHeight
		+ paddingBetweenTimelines
		+ totalAssignmentHeight
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
end

---@param self EPTimeline
local function UpdateHeight(self)
	self:SetHeight(self:CalculateRequiredHeight())
	if self.parent and self.parent.DoLayout then
		self.parent:DoLayout()
	end
end

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("ScrollFrame", Type .. num, UIParent)
	frame:SetSize(frameWidth, frameHeight)

	local timelineWrapperFrame = CreateFrame("Frame", Type .. num .. "TimelineWrapperFrame", frame)
	timelineWrapperFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	timelineWrapperFrame:SetSize(
		frameWidth,
		frameHeight - horizontalScrollBarHeight - paddingBetweenTimelineAndScrollBar
	)

	local timelineFrame = CreateFrame("Frame", Type .. num .. "TimelineFrame", timelineWrapperFrame)
	timelineFrame:SetPoint("TOPLEFT", timelineWrapperFrame, "TOPLEFT")
	timelineFrame:SetPoint("TOPRIGHT", timelineWrapperFrame, "TOPRIGHT")
	timelineFrame:SetSize(frameWidth, (timelineWrapperFrame:GetHeight() - paddingBetweenTimelines) / 2.0)
	timelineFrame:EnableMouse(true)
	timelineFrame:RegisterForDrag("LeftButton", "LeftButtonUp")
	timelineFrame:SetScript("OnMouseWheel", HandleTimelineFrameMouseWheel)
	timelineFrame:SetScript("OnDragStart", HandleTimelineFrameDragStart)
	timelineFrame:SetScript("OnDragStop", HandleTimelineFrameDragStop)
	timelineFrame:SetScript("OnEnter", HandleTimelineFrameEnter)
	timelineFrame:SetScript("OnLeave", HandleTimelineFrameLeave)
	timelineFrame:Show()

	local assignmentTimelineFrame = CreateFrame("Frame", Type .. num .. "AssignmentTimelineFrame", timelineWrapperFrame)
	assignmentTimelineFrame:SetPoint("TOPLEFT", timelineFrame, "BOTTOMLEFT", 0, -paddingBetweenTimelines)
	assignmentTimelineFrame:SetPoint("TOPRIGHT", timelineFrame, "BOTTOMRIGHT", 0, -paddingBetweenTimelines)
	assignmentTimelineFrame:SetPoint("BOTTOMLEFT", timelineWrapperFrame, "BOTTOMLEFT")
	assignmentTimelineFrame:SetPoint("BOTTOMRIGHT", timelineWrapperFrame, "BOTTOMRIGHT")
	assignmentTimelineFrame:SetSize(frameWidth, (timelineWrapperFrame:GetHeight() - paddingBetweenTimelines) / 2.0)
	assignmentTimelineFrame:EnableMouse(true)
	assignmentTimelineFrame:RegisterForDrag("LeftButton", "LeftButtonUp")
	assignmentTimelineFrame:SetScript("OnMouseWheel", HandleTimelineFrameMouseWheel)
	assignmentTimelineFrame:SetScript("OnDragStart", HandleTimelineFrameDragStart)
	assignmentTimelineFrame:SetScript("OnDragStop", HandleTimelineFrameDragStop)
	assignmentTimelineFrame:SetScript("OnMouseDown", HandleAssignmentTimelineFrameMouseDown)
	assignmentTimelineFrame:SetScript("OnEnter", HandleTimelineFrameEnter)
	assignmentTimelineFrame:SetScript("OnLeave", HandleTimelineFrameLeave)
	assignmentTimelineFrame:Show()

	frame:SetScrollChild(timelineWrapperFrame)
	frame:EnableMouseWheel(true)

	local timelineVerticalPositionLine = timelineFrame:CreateTexture(Type .. num .. "AbilityPositionLine", "OVERLAY")
	timelineVerticalPositionLine:SetColorTexture(1, 0.82, 0, 1)
	timelineVerticalPositionLine:SetPoint("TOP", timelineFrame, "TOPLEFT")
	timelineVerticalPositionLine:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT")
	timelineVerticalPositionLine:SetWidth(1)
	timelineVerticalPositionLine:Hide()

	local assignmentTimelineVerticalPositionLine =
		assignmentTimelineFrame:CreateTexture(Type .. num .. "AssignmentPositionLine", "OVERLAY")
	assignmentTimelineVerticalPositionLine:SetColorTexture(1, 0.82, 0, 1)
	assignmentTimelineVerticalPositionLine:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT")
	assignmentTimelineVerticalPositionLine:SetPoint("BOTTOM", assignmentTimelineFrame, "BOTTOMLEFT")
	assignmentTimelineVerticalPositionLine:SetWidth(1)
	assignmentTimelineVerticalPositionLine:Hide()

	local scrollBar = CreateFrame("Frame", Type .. num .. "HorizontalScrollBar", frame)
	scrollBar:SetHeight(horizontalScrollBarHeight)
	scrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	local scrollBarBackground = scrollBar:CreateTexture(Type .. num .. "ScrollBarBackground", "BACKGROUND")
	scrollBarBackground:SetAllPoints()
	scrollBarBackground:SetColorTexture(1, 0, 0, 0.7)

	local thumb = CreateFrame("Button", Type .. num .. "ScrollBarThumb", scrollBar)
	thumb:SetPoint("LEFT", thumbPadding.x, 0)
	thumb:SetSize(scrollBar:GetWidth() - 2 * thumbPadding.x, horizontalScrollBarHeight - (2 * thumbPadding.y))
	thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
	thumb:SetScript("OnMouseDown", HandleThumbMouseDown)
	thumb:SetScript("OnMouseUp", HandleThumbMouseUp)

	local thumbBackground = thumb:CreateTexture(Type .. num .. "ScrollBarThumbBackground", "BACKGROUND")
	thumbBackground:SetAllPoints()
	thumbBackground:SetColorTexture(0, 0, 0, 0.7)

	---@class EPTimeline
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEntries = SetEntries,
		CountUniqueAssignees = CountUniqueAssignees,
		UpdateAssignments = UpdateAssignments,
		DrawAssignment = DrawAssignment,
		UpdateBossAbilityBars = UpdateBossAbilityBars,
		DrawBossAbilityBar = DrawBossAbilityBar,
		UpdateScrollBar = UpdateScrollBar,
		UpdateTickMarks = UpdateTickMarks,
		OnWidthSet = OnWidthSet,
		OnHeightSet = OnHeightSet,
		CalculateRequiredBarHeight = CalculateRequiredBarHeight,
		CalculateRequiredAssignmentHeight = CalculateRequiredAssignmentHeight,
		CalculateRequiredHeight = CalculateRequiredHeight,
		UpdateHeight = UpdateHeight,
		frame = frame,
		type = Type,
		timelineWrapperFrame = timelineWrapperFrame,
		assignmentTimelineFrame = assignmentTimelineFrame,
		timelineFrame = timelineFrame,
		scrollBar = scrollBar,
		thumb = thumb,
		timelineVerticalPositionLine = timelineVerticalPositionLine,
		assignmentTimelineVerticalPositionLine = assignmentTimelineVerticalPositionLine,
	}

	frame.obj = widget
	scrollBar.obj = widget
	thumb.obj = widget
	timelineFrame.obj = widget
	timelineWrapperFrame.obj = widget
	assignmentTimelineFrame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
