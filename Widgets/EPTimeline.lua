local Type = "EPTimeline"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local abs = math.abs
local CreateFrame = CreateFrame
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local GetSpellTexture = C_Spell.GetSpellTexture
local hugeNumber = math.huge
local ipairs = ipairs
local max = math.max
local min = math.min
local pairs = pairs
local unpack = unpack

local frameWidth = 900
local frameHeight = 400
local paddingBetweenTimelines = 36
local paddingBetweenBossAbilityBars = 4
local paddingBetweenTimelineAndScrollBar = 10
local bossAbilityBarHeight = 30
local assignmentTextureSize = { x = 30, y = 30 }
local assignmentTextureSubLevel = 0
local bossAbilityTextureSubLevel = 0
local paddingBetweenAssignments = 2
local horizontalScrollBarHeight = 20
local minimumNumberOfAssignmentRows = 4
local maximumNumberOfAssignmentRows = 12
local minimumNumberOfBossAbilityRows = 4
local maximumNumberOfBossAbilityRows = 12
local tickWidth = 2
local fontPath = LSM:Fetch("font", "PT Sans Narrow")
local tickColor = { 1, 1, 1, 0.75 }
local assignmentOutlineColor = { 0.25, 0.25, 0.25, 1 }
local assignmentSelectOutlineColor = { 1, 0.82, 0, 1 }
local tickFontSize = 12
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
local thumbOffsetWhenThumbClicked = 0
local scrollBarWidthWhenThumbClicked = 0
local thumbWidthWhenThumbClicked = 0
local thumbIsDragging = false
local totalTimelineDuration = 0

local function ResetLocalVariables()
	thumbPadding = { x = 2, y = 2 }
	timelineLinePadding = { x = 25, y = 25 }
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

local function HandleAssignmentMouseDown(frame, mouseButton, epTimeline)
	if mouseButton ~= "LeftButton" then
		return
	end
	-- TODO: Implement dragging an assignment spell icon to change the time
end

---@param epTimeline EPTimeline
local function HandleAssignmentMouseUp(frame, mouseButton, epTimeline)
	if mouseButton ~= "RightButton" then
		return
	end
	if frame.assignmentIndex then
		epTimeline:Fire("AssignmentClicked", frame.assignmentIndex)
		epTimeline:SelectAssignment(frame.assignmentIndex)
	end
end

-- Updates the tick mark positions for the boss ability timeline and assignments timeline.
---@param self EPTimeline
local function UpdateTickMarks(self)
	local assignmentTicks = self.assignmentTimeline:GetTicks()
	local bossTicks = self.bossAbilityTimeline:GetTicks()
	-- Clear existing tick marks
	for _, tick in pairs(assignmentTicks) do
		tick:Hide()
	end
	for _, tick in pairs(bossTicks) do
		tick:Hide()
	end
	for _, label in pairs(self.timelineLabels) do
		label:Hide()
	end
	if totalTimelineDuration <= 0.0 then
		return
	end

	-- Define visible range in time (based on zoomFactor)
	local visibleDuration = totalTimelineDuration / self.bossAbilityTimeline:GetZoomFactor()

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

	local assignmentTimelineFrame = self.assignmentTimeline:GetTimelineFrame()
	local bossTimelineFrame = self.bossAbilityTimeline:GetTimelineFrame()
	local timelineWidth = bossTimelineFrame:GetWidth()
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
		local assignmentTick = assignmentTicks[i]
		if not assignmentTick then
			assignmentTick = assignmentTimelineFrame:CreateTexture(nil, "ARTWORK")
			assignmentTick:SetColorTexture(unpack(tickColor))
			assignmentTicks[i] = assignmentTick
		end
		assignmentTick:SetWidth(currentTickWidth)
		assignmentTick:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT", position + padding.x, 0)
		assignmentTick:SetPoint("BOTTOM", assignmentTimelineFrame, "BOTTOMLEFT", position + padding.x, 0)
		assignmentTick:Show()

		local bossTick = bossTicks[i]
		if not bossTick then
			bossTick = bossTimelineFrame:CreateTexture(nil, "ARTWORK")
			bossTick:SetColorTexture(unpack(tickColor))
			bossTicks[i] = bossTick
		end
		bossTick:SetWidth(currentTickWidth)
		bossTick:SetPoint("TOP", bossTimelineFrame, "TOPLEFT", position + padding.x, 0)
		bossTick:SetPoint("BOTTOM", bossTimelineFrame, "BOTTOMLEFT", position + padding.x, 0)
		bossTick:Show()

		-- Create or reuse timestamp label
		local label = self.timelineLabels[i]
		if not label then
			label = self.splitterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			self.timelineLabels[i] = label
			if fontPath then
				label:SetFont(fontPath, tickFontSize)
			end
		end
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		label:SetText(string.format("%d:%02d", minutes, seconds))
		label:SetPoint("LEFT", self.splitterFrame, "LEFT", position + label:GetUnboundedStringWidth() / 2, 0)
		label:Show()
	end
end

local function HandleThumbUpdate(frame)
	local self = frame.obj --[[@as EPTimeline]]
	if not thumbIsDragging then
		return
	end

	local paddingX = thumbPadding.x
	local currentOffset = thumbOffsetWhenThumbClicked
	local currentWidth = thumbWidthWhenThumbClicked
	local currentScrollBarWidth = scrollBarWidthWhenThumbClicked
	local xPosition, _ = GetCursorPosition()
	local newOffset = (xPosition / UIParent:GetEffectiveScale()) - self.horizontalScrollBar:GetLeft() - currentOffset

	local minAllowedOffset = paddingX
	local maxAllowedOffset = currentScrollBarWidth - currentWidth - paddingX
	newOffset = max(newOffset, minAllowedOffset)
	newOffset = min(newOffset, maxAllowedOffset)
	self.horizontalScrollBar.thumb:SetPoint("LEFT", newOffset, 0)

	-- Calculate the scroll frame's horizontal scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * paddingX)
	local scrollOffset = ((newOffset - paddingX) / maxThumbPosition) * self.bossAbilityTimeline:GetMaxScroll()
	self.bossAbilityTimeline:SetHorizontalScroll(scrollOffset)
	self.assignmentTimeline:SetHorizontalScroll(scrollOffset)
	self.splitterScrollFrame:SetHorizontalScroll(scrollOffset)
end

local function HandleThumbMouseDown(frame)
	local self = frame.obj --[[@as EPTimeline]]
	local x, _ = GetCursorPosition()
	thumbOffsetWhenThumbClicked = (x / UIParent:GetEffectiveScale()) - self.horizontalScrollBar.thumb:GetLeft()
	scrollBarWidthWhenThumbClicked = self.horizontalScrollBar:GetWidth()
	thumbWidthWhenThumbClicked = self.horizontalScrollBar.thumb:GetWidth()
	thumbIsDragging = true
	self.horizontalScrollBar.thumb:SetScript("OnUpdate", HandleThumbUpdate)
end

local function HandleThumbMouseUp(frame)
	local self = frame.obj --[[@as EPTimeline]]
	thumbIsDragging = false
	self.horizontalScrollBar.thumb:SetScript("OnUpdate", nil)
end

---@param self EPTimeline
local function HandleAssignmentTimelineFrameMouseUp(frame, button, self)
	if button ~= "RightButton" then
		return
	end

	local currentX, currentY = GetCursorPosition()
	currentX = currentX / UIParent:GetEffectiveScale()
	currentY = currentY / UIParent:GetEffectiveScale()
	local nearestBarIndex = nil
	local minDistance = hugeNumber
	for index, bar in ipairs(self.bossAbilityTextureBars) do
		if bar:IsShown() then
			local distance = abs(bar:GetLeft() - currentX)
			if distance < minDistance then
				minDistance = distance
				nearestBarIndex = index
			end
		end
	end
	if nearestBarIndex then
		local relativeDistanceFromTop = abs(self.assignmentTimeline:GetTimelineFrame():GetTop() - currentY)
		local totalAssignmentHeight = 0
		local assigneeIndex = nil
		for index, assigneeAndSpell in ipairs(self.assigneesAndSpells) do
			if assigneeAndSpell.spellID == nil or not self.collapsed[assigneeAndSpell.assigneeNameOrRole] then
				totalAssignmentHeight = totalAssignmentHeight + (assignmentTextureSize.y + paddingBetweenAssignments)
				if totalAssignmentHeight >= relativeDistanceFromTop then
					assigneeIndex = index
					break
				end
			end
		end
		if assigneeIndex then
			self:Fire(
				"CreateNewAssignment",
				self.bossAbilityTextureBars[nearestBarIndex].abilityInstance,
				assigneeIndex
			)
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
---@param abilityInstance BossAbilityInstance
local function DrawBossAbilityBar(self, startTime, endTime, color, index, offset, abilityInstance)
	if totalTimelineDuration <= 0.0 then
		return
	end

	local padding = timelineLinePadding
	local timelineFrame = self.bossAbilityTimeline:GetTimelineFrame()
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x

	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local timelineEndPosition = (endTime / totalTimelineDuration) * timelineWidth

	---@class Texture
	local bar = self.bossAbilityTextureBars[index]
	if not bar then
		bar = timelineFrame:CreateTexture(nil, "OVERLAY", nil, bossAbilityTextureSubLevel)
		self.bossAbilityTextureBars[index] = bar
	end

	bar.abilityInstance = abilityInstance

	local r, g, b, a = unpack(color)
	bar:SetColorTexture(r / 255.0, g / 255.0, b / 255.0, a)
	bar:SetSize(timelineEndPosition - timelineStartPosition, bossAbilityBarHeight)
	bar:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", timelineStartPosition + padding.x, -offset)
	bar:Show()
end

-- Helper function to draw a spell icon for an assignment.
---@param self EPTimeline
---@param startTime number absolute start time of the assignment
---@param spellID integer spellID of the spell being assigned
---@param index integer index of the assignment texture
---@param uniqueID integer unique index of the assignment
---@param order number the relative order of the assignee of the assignment
local function DrawAssignment(self, startTime, spellID, index, uniqueID, order)
	if totalTimelineDuration <= 0.0 then
		return
	end

	local padding = timelineLinePadding
	local timelineFrame = self.assignmentTimeline:GetTimelineFrame()
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x

	---@class Frame
	local assignment = self.assignmentFrames[index]
	if not assignment then
		assignment = CreateFrame("Frame", nil, timelineFrame)
		assignment.spellTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel)
		assignment.outlineTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel - 1)
		assignment.outlineTexture:SetAllPoints()
		assignment.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
		assignment.outlineTexture:Show()
		assignment.spellTexture:SetPoint("TOPLEFT", 1, -1)
		assignment.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
		assignment.assignmentFrame = timelineFrame
		assignment:SetScript("OnEnter", function(frame, motion)
			HandleIconEnter(frame, motion)
		end)
		assignment:SetScript("OnLeave", function(frame, motion)
			HandleIconLeave(frame, motion)
		end)
		assignment:SetScript("OnMouseDown", function(frame, mouseButton, _)
			HandleAssignmentMouseDown(frame, mouseButton, self)
		end)
		assignment:SetScript("OnMouseUp", function(frame, mouseButton, _)
			HandleAssignmentMouseUp(frame, mouseButton, self)
		end)
		self.assignmentFrames[index] = assignment
	end

	assignment.spellID = spellID
	assignment.assignmentIndex = uniqueID
	if spellID == 0 or spellID == nil then
		assignment.spellTexture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
	else
		local iconID, _ = GetSpellTexture(spellID)
		assignment.spellTexture:SetTexture(iconID)
	end

	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local offsetX = timelineStartPosition + timelineLinePadding.x
	local offsetY = (order - 1) * (assignmentTextureSize.y + paddingBetweenAssignments)

	assignment:SetSize(assignmentTextureSize.x, assignmentTextureSize.y)
	assignment:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignment:SetFrameLevel(timelineFrame:GetFrameLevel() + 1 + floor(startTime))
	assignment:Show()
end

-- Updates the rendering of assignments on the timeline.
---@param self EPTimeline
local function UpdateAssignments(self)
	-- Hide existing assignments
	for _, texture in pairs(self.assignmentFrames) do
		texture:Hide()
	end

	for index, assignment in ipairs(self.timelineAssignments) do
		DrawAssignment(
			self,
			assignment.startTime,
			assignment.assignment.spellInfo.spellID,
			index,
			assignment.assignment.uniqueID,
			assignment.order
		)
	end
end

---@param self EPTimeline
---@param bossAbility BossAbility
---@param bossPhaseIndex integer
---@param bossAbilitySpellID integer
---@param bossPhaseStartTime number
---@param bossPhaseDuration number
---@param bossAbilityOrderIndex integer
---@param bossAbilityInstanceIndex integer
---@param offset number
---@return integer
local function DrawPhaseOrTimeBasedBossAbility(
	self,
	bossAbility,
	bossPhaseIndex,
	bossAbilitySpellID,
	bossPhaseStartTime,
	bossPhaseDuration,
	bossAbilityOrderIndex,
	bossAbilityInstanceIndex,
	offset
)
	if not bossAbility.phases[bossPhaseIndex] then
		return bossAbilityInstanceIndex
	end

	local color = colors[((bossAbilityOrderIndex - 1) % #colors) + 1]
	local cumulativePhaseCastTimes = bossPhaseStartTime
	local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
	for _, castTime in ipairs(bossAbilityPhase.castTimes) do
		local castStart = cumulativePhaseCastTimes + castTime
		local castEnd = castStart + bossAbility.castTime
		local effectEnd = castEnd + bossAbility.duration
		DrawBossAbilityBar(
			self,
			castStart,
			effectEnd,
			color,
			bossAbilityInstanceIndex,
			offset,
			{ spellID = bossAbilitySpellID, phase = bossPhaseIndex, castTime = castStart }
		)
		bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
		if bossAbilityPhase.repeatInterval then
			local repeatInterval = bossAbilityPhase.repeatInterval
			local nextRepeatStart = castStart + repeatInterval
			local repeatInstance = 1
			while nextRepeatStart < bossPhaseStartTime + bossPhaseDuration do
				local repeatEnd = nextRepeatStart + bossAbility.castTime
				local repeatEffectEnd = repeatEnd + bossAbility.duration
				DrawBossAbilityBar(self, nextRepeatStart, repeatEffectEnd, color, bossAbilityInstanceIndex, offset, {
					spellID = bossAbilitySpellID,
					phase = bossPhaseIndex,
					castTime = nextRepeatStart,
					repeatInstance = repeatInstance,
				})
				bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
				nextRepeatStart = nextRepeatStart + repeatInterval
				repeatInstance = repeatInstance + 1
			end
		end
		cumulativePhaseCastTimes = castStart
	end

	return bossAbilityInstanceIndex
end

---@param self EPTimeline
---@param bossAbility BossAbility
---@param bossPhaseIndex integer
---@param bossAbilitySpellID integer
---@param bossPhaseStartTime number
---@param bossPhaseEndTime number
---@param bossAbilityOrderIndex integer
---@param bossAbilityInstanceIndex integer
---@param offset number
---@return integer
local function DrawEventTriggerBossAbility(
	self,
	bossAbility,
	bossPhaseIndex,
	bossAbilitySpellID,
	bossPhaseStartTime,
	bossPhaseEndTime,
	bossAbilityOrderIndex,
	bossAbilityInstanceIndex,
	offset
)
	if not bossAbility.eventTriggers then
		return bossAbilityInstanceIndex
	end

	local color = colors[((bossAbilityOrderIndex - 1) % #colors) + 1]

	for triggerSpellID, eventTrigger in pairs(bossAbility.eventTriggers) do
		local bossAbilityTrigger = self.bossAbilities[triggerSpellID]
		if bossAbilityTrigger and bossAbilityTrigger.phases[bossPhaseIndex] then
			local cumulativeTriggerTime = bossPhaseStartTime
			for triggerCastIndex, triggerCastTime in ipairs(bossAbilityTrigger.phases[bossPhaseIndex].castTimes) do
				local cumulativeCastTime = cumulativeTriggerTime + triggerCastTime + bossAbilityTrigger.castTime
				for _, castTime in ipairs(eventTrigger.castTimes) do
					local castStart = cumulativeCastTime + castTime
					local castEnd = castStart + bossAbility.castTime
					local effectEnd = castEnd + bossAbility.duration
					DrawBossAbilityBar(self, castStart, effectEnd, color, bossAbilityInstanceIndex, offset, {
						combatLogEventType = eventTrigger.combatLogEventType,
						spellID = bossAbilitySpellID,
						phase = bossPhaseIndex,
						castTime = castStart - cumulativeCastTime,
						triggerSpellID = triggerSpellID,
						triggerCastIndex = triggerCastIndex,
					})
					bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
					cumulativeCastTime = cumulativeCastTime + castTime
				end
				if eventTrigger.repeatInterval and eventTrigger.repeatInterval.triggerCastIndex == triggerCastIndex then
					local repeatInstance = 1
					while cumulativeCastTime < bossPhaseEndTime do
						for repeatCastIndex, castTime in ipairs(eventTrigger.repeatInterval.castTimes) do
							local castStart = cumulativeCastTime + castTime
							local castEnd = castStart + bossAbility.castTime
							local effectEnd = castEnd + bossAbility.duration
							if effectEnd < bossPhaseEndTime then
								DrawBossAbilityBar(
									self,
									castStart,
									effectEnd,
									color,
									bossAbilityInstanceIndex,
									offset,
									{
										combatLogEventType = eventTrigger.combatLogEventType,
										spellID = bossAbilitySpellID,
										phase = bossPhaseIndex,
										castTime = castStart - cumulativeCastTime,
										triggerSpellID = triggerSpellID,
										triggerCastIndex = triggerCastIndex,
										repeatInstance = repeatInstance,
										repeatCastIndex = repeatCastIndex,
									}
								)
								bossAbilityInstanceIndex = bossAbilityInstanceIndex + 1
								repeatInstance = repeatInstance + 1
							end
							cumulativeCastTime = cumulativeCastTime + castTime
						end
					end
				end
				cumulativeTriggerTime = cumulativeTriggerTime + triggerCastTime + bossAbilityTrigger.castTime
			end
		end
	end
	return bossAbilityInstanceIndex
end

-- Updates the rendering of boss abilities on the timeline.
---@param self EPTimeline
local function UpdateBossAbilityBars(self)
	-- Hide existing bars
	for _, texture in pairs(self.bossAbilityTextureBars) do
		texture:Hide()
	end

	local cumulativePhaseStartTime = 0
	local bossAbilityInstanceIndex = 1
	local offsets = {}
	local offset = 0
	for _, bossAbilitySpellID in pairs(self.bossAbilityOrder) do
		offsets[bossAbilitySpellID] = offset
		if self.bossAbilityVisibility[bossAbilitySpellID] == true then
			offset = offset + bossAbilityBarHeight + paddingBetweenBossAbilityBars
		end
	end
	for _, bossPhaseIndex in ipairs(self.bossPhaseOrder) do
		local bossPhase = self.bossPhases[bossPhaseIndex]
		if bossPhase then
			local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration
			for bossAbilityOrderIndex, bossAbilitySpellID in pairs(self.bossAbilityOrder) do
				if self.bossAbilityVisibility[bossAbilitySpellID] == true then
					local bossAbility = self.bossAbilities[bossAbilitySpellID]
					bossAbilityInstanceIndex = DrawPhaseOrTimeBasedBossAbility(
						self,
						bossAbility,
						bossPhaseIndex,
						bossAbilitySpellID,
						cumulativePhaseStartTime,
						bossPhase.duration,
						bossAbilityOrderIndex,
						bossAbilityInstanceIndex,
						offsets[bossAbilitySpellID]
					)
					bossAbilityInstanceIndex = DrawEventTriggerBossAbility(
						self,
						bossAbility,
						bossPhaseIndex,
						bossAbilitySpellID,
						cumulativePhaseStartTime,
						phaseEndTime,
						bossAbilityOrderIndex,
						bossAbilityInstanceIndex,
						offsets[bossAbilitySpellID]
					)
				end
			end
			cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
		end
	end
end

-- Calculate the total required height for boss ability bars.
---@param self EPTimeline
---@param limit boolean|nil
---@return number
local function CalculateRequiredBarHeight(self, limit)
	if limit == nil then
		limit = true
	end
	local totalBarHeight = 0
	local abilityCount = 0
	for _, visible in pairs(self.bossAbilityVisibility) do
		if visible == true then
			totalBarHeight = totalBarHeight + (bossAbilityBarHeight + paddingBetweenBossAbilityBars)
			abilityCount = abilityCount + 1
		end
		if limit == true and abilityCount == maximumNumberOfBossAbilityRows then
			break
		end
	end
	if totalBarHeight >= (bossAbilityBarHeight + paddingBetweenBossAbilityBars) then
		totalBarHeight = totalBarHeight - paddingBetweenBossAbilityBars
	end
	return totalBarHeight
end

-- Calculate the total required height for assignments.
---@param self EPTimeline
---@param limit boolean
---@return number
local function CalculateRequiredAssignmentHeight(self, limit)
	local totalAssignmentHeight = 0
	local totalAssignmentRows = 0
	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not self.collapsed[as.assigneeNameOrRole] then
			totalAssignmentHeight = totalAssignmentHeight + (assignmentTextureSize.y + paddingBetweenAssignments)
			totalAssignmentRows = totalAssignmentRows + 1
			if limit == true and totalAssignmentRows >= maximumNumberOfAssignmentRows then
				break
			end
		end
	end
	if totalAssignmentHeight >= (assignmentTextureSize.y + paddingBetweenAssignments) then
		totalAssignmentHeight = totalAssignmentHeight - paddingBetweenAssignments
	end
	return totalAssignmentHeight
end

---@param self EPTimeline
local function CalculateMinMaxStepBarHeight(self)
	local abilityCount = 0
	local minH, maxH, stepH = 0, 0, (bossAbilityBarHeight + paddingBetweenBossAbilityBars)
	for _, visible in pairs(self.bossAbilityVisibility) do
		if visible == true then
			maxH = maxH + stepH
			abilityCount = abilityCount + 1
			if abilityCount <= minimumNumberOfBossAbilityRows then
				minH = maxH
			end
			if abilityCount >= maximumNumberOfBossAbilityRows then
				break
			end
		end
	end
	if minH >= stepH then
		minH = minH - paddingBetweenBossAbilityBars
	end
	if maxH >= stepH then
		maxH = maxH - paddingBetweenBossAbilityBars
	end
	self.barDimensions.min = minH
	self.barDimensions.max = maxH
	self.barDimensions.step = stepH
end

---@param self EPTimeline
local function CalculateMinMaxStepAssignmentHeight(self)
	local totalAssignmentRows = 0
	local minH, maxH, stepH = 0, 0, (assignmentTextureSize.y + paddingBetweenAssignments)
	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not self.collapsed[as.assigneeNameOrRole] then
			maxH = maxH + stepH
			totalAssignmentRows = totalAssignmentRows + 1
			if totalAssignmentRows <= minimumNumberOfAssignmentRows then
				minH = maxH
			end
			if totalAssignmentRows >= maximumNumberOfAssignmentRows then
				break
			end
		end
	end
	if minH >= stepH then
		minH = minH - paddingBetweenAssignments
	end
	if maxH >= stepH then
		maxH = maxH - paddingBetweenAssignments
	end
	self.assignmentDimensions.min = minH
	self.assignmentDimensions.max = maxH
	self.assignmentDimensions.step = stepH
end

-- Sets the height of the widget based on boss ability bars and assignment icons
---@param self EPTimeline
local function UpdateHeight(self)
	CalculateMinMaxStepBarHeight(self)
	CalculateMinMaxStepAssignmentHeight(self)
	local minHeight = self.assignmentDimensions.min
		+ self.barDimensions.min
		+ paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
	local maxHeight = self.assignmentDimensions.max
		+ self.barDimensions.max
		+ paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
	self:Fire("ResizeBoundsCalculated", minHeight, maxHeight)

	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()
	local height = paddingBetweenTimelines + paddingBetweenTimelineAndScrollBar + horizontalScrollBarHeight
	if bossFrameHeight < self.barDimensions.min then
		height = height + self.barDimensions.min
		self.bossAbilityTimeline.frame:SetHeight(self.barDimensions.min)
	elseif bossFrameHeight > self.barDimensions.max then
		height = height + self.barDimensions.max
		self.bossAbilityTimeline.frame:SetHeight(self.barDimensions.max)
	else
		height = height + bossFrameHeight
	end

	local assignmentFrameHeight = self.assignmentTimeline.frame:GetHeight()
	if assignmentFrameHeight < self.assignmentDimensions.min then
		height = height + self.assignmentDimensions.min
		self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.min)
	elseif assignmentFrameHeight > self.assignmentDimensions.max then
		height = height + self.assignmentDimensions.max
		self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	else
		height = height + assignmentFrameHeight
	end
	self:SetHeight(height)
end

---@param self EPTimeline
local function SetMaxAssignmentHeight(self)
	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()
	local height = paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
		+ bossFrameHeight
	self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	self:SetHeight(height + self.assignmentDimensions.max)
end

---@param self EPTimeline
---@param otherTimeline EPTimelineSection
---@param needsFullUpdate boolean
local function HandleTimelineSectionStaticDataChanged(self, otherTimeline, needsFullUpdate)
	otherTimeline:SyncFromStaticData()
	if needsFullUpdate == true then
		local scroll, width = self.bossAbilityTimeline:GetHorizontalScrollAndWidth()
		self.splitterScrollFrame:SetHorizontalScroll(scroll)
		self.splitterFrame:SetWidth(width)
		UpdateTickMarks(self)
		UpdateBossAbilityBars(self)
		UpdateAssignments(self)
	end
end

---@class EPTimeline : AceGUIWidget
---@field parent AceGUIContainer|nil
---@field frame table|Frame
---@field splitterFrame table|Frame
---@field type string
---@field assignmentTimeline EPTimelineSection
---@field bossAbilityTimeline EPTimelineSection
---@field timelineLabels table<integer, FontString>
---@field contentFrame table|Frame
---@field horizontalScrollBar table|Frame
---@field addAssigneeDropdown EPDropdown
---
---@field assigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
---@field assignmentFrames table<integer, Frame>
---@field bossAbilities table<integer, BossAbility>
---@field bossAbilityVisibility table<integer, boolean>
---@field bossAbilityOrder table<integer, integer>
---@field bossAbilityTextureBars table<integer, Texture>
---@field bossPhaseOrder table<integer, integer>
---@field bossPhases table<integer, BossPhase>
---@field collapsed table<string, boolean>
---@field timelineAssignments table<integer, TimelineAssignment>
---@field allowHeightResizing boolean
---@field barDimensions {min: number, max:number, step:number}
---@field assignmentDimensions {min: number, max:number, step:number}

---@param self EPTimeline
local function OnAcquire(self)
	self.assignmentFrames = self.assignmentFrames or {}
	self.bossAbilityTextureBars = self.bossAbilityTextureBars or {}
	self.timelineLabels = self.timelineLabels or {}
	self.bossAbilities = {}
	self.bossAbilityOrder = {}
	self.bossPhaseOrder = {}
	self.bossPhases = {}
	self.timelineAssignments = {}
	self.assigneesAndSpells = {}
	self.bossAbilityVisibility = {}
	self.collapsed = {}
	self.allowHeightResizing = false
	self.barDimensions = {}
	self.assignmentDimensions = {}

	self.assignmentTimeline = AceGUI:Create("EPTimelineSection")
	local assignmentTimelineFrame = self.assignmentTimeline:GetFrame()
	assignmentTimelineFrame:SetParent(self.contentFrame)

	self.bossAbilityTimeline = AceGUI:Create("EPTimelineSection")
	local bossTimelineFrame = self.bossAbilityTimeline:GetFrame()
	bossTimelineFrame:SetParent(self.contentFrame)

	local table = {
		verticalPositionLineOffset = 0,
		verticalPositionLineVisible = false,
		timelineFrameWidth = frameWidth,
		horizontalScroll = 0,
		zoomFactor = 1,
		timelineLinePadding = timelineLinePadding,
	}
	self.assignmentTimeline:SetSharedData(table)
	self.bossAbilityTimeline:SetSharedData(table)
	self.assignmentTimeline:SetListPadding(paddingBetweenAssignments)
	self.bossAbilityTimeline:SetListPadding(paddingBetweenBossAbilityBars)
	self.assignmentTimeline:SetTextureHeight(assignmentTextureSize.y)
	self.bossAbilityTimeline:SetTextureHeight(bossAbilityBarHeight)
	self.assignmentTimeline:SetHorizontalScrollBarReference(self.horizontalScrollBar)
	self.bossAbilityTimeline:SetHorizontalScrollBarReference(self.horizontalScrollBar)
	self.bossAbilityTimeline:SetCallback("StaticDataChanged", function(_, _, needsFullUpdate)
		HandleTimelineSectionStaticDataChanged(self, self.assignmentTimeline, needsFullUpdate)
	end)
	self.assignmentTimeline:SetCallback("StaticDataChanged", function(_, _, needsFullUpdate)
		HandleTimelineSectionStaticDataChanged(self, self.bossAbilityTimeline, needsFullUpdate)
	end)
	self.assignmentTimeline:GetTimelineFrame():SetScript("OnMouseUp", function(frame, button)
		HandleAssignmentTimelineFrameMouseUp(frame, button, self)
	end)

	bossTimelineFrame:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT")
	bossTimelineFrame:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT")
	assignmentTimelineFrame:SetPoint("TOPLEFT", bossTimelineFrame, "BOTTOMLEFT", 0, -36)
	assignmentTimelineFrame:SetPoint("TOPRIGHT", bossTimelineFrame, "BOTTOMRIGHT", 0, -36)

	self.addAssigneeDropdown = AceGUI:Create("EPDropdown")
	self.addAssigneeDropdown.frame:SetParent(self.contentFrame)
	self.addAssigneeDropdown.frame:SetPoint("RIGHT", self.splitterScrollFrame, "LEFT", -10, 0)
end

---@param self EPTimeline
local function OnRelease(self)
	self.assignmentTimeline:Release()
	self.assignmentTimeline = nil
	self.bossAbilityTimeline:Release()
	self.bossAbilityTimeline = nil
	self.addAssigneeDropdown:Release()
	self.addAssigneeDropdown = nil
	self.bossAbilities = nil
	self.bossAbilityOrder = nil
	self.bossPhaseOrder = nil
	self.bossPhases = nil
	self.timelineAssignments = nil
	self.assigneesAndSpells = nil
	self.bossAbilityVisibility = nil
	self.collapsed = nil
	self.allowHeightResizing = nil
	self.barDimensions = nil
	self.assignmentDimensions = nil
	ResetLocalVariables()
end

-- Sets the boss ability entries for the timeline.
---@param self EPTimeline
---@param abilities table<integer, BossAbility>
---@param abilityOrder table<integer, integer>
---@param phases table<integer, BossPhase>
---@param phaseOrder table<integer, integer>
---@param bossAbilityVisibility table<integer, boolean>
local function SetBossAbilities(self, abilities, abilityOrder, phases, phaseOrder, bossAbilityVisibility)
	self.bossAbilities = abilities
	self.bossAbilityOrder = abilityOrder
	self.bossPhases = phases
	self.bossPhaseOrder = phaseOrder
	self.bossAbilityVisibility = bossAbilityVisibility

	totalTimelineDuration = 0
	for _, phaseData in pairs(self.bossPhases) do
		totalTimelineDuration = totalTimelineDuration + (phaseData.duration * phaseData.count)
	end
	self.bossAbilityTimeline:SetTimelineDuration(totalTimelineDuration)
	self.assignmentTimeline:SetTimelineDuration(totalTimelineDuration)
	UpdateHeight(self)
end

---@param self EPTimeline
---@param assignments table<integer, TimelineAssignment>
---@param assigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
---@param collapsed table<string, boolean>
local function SetAssignments(self, assignments, assigneesAndSpells, collapsed)
	self.timelineAssignments = assignments
	self.assigneesAndSpells = assigneesAndSpells
	self.collapsed = collapsed
	UpdateHeight(self)
end

---@param self EPTimeline
---@return table<integer, TimelineAssignment>
local function GetAssignments(self)
	return self.timelineAssignments
end

---@param self EPTimeline
---@return EPContainer
local function GetAssignmentContainer(self)
	return self.assignmentTimeline:GetListContainer()
end

---@param self EPTimeline
---@return EPContainer
local function GetBossAbilityContainer(self)
	return self.bossAbilityTimeline:GetListContainer()
end

---@param self EPTimeline
---@return EPDropdown
local function GetAddAssigneeDropdown(self)
	return self.addAssigneeDropdown
end

---@param self EPTimeline
local function UpdateTimeline(self)
	self.assignmentTimeline:UpdateWidthAndScroll()
	self.bossAbilityTimeline:UpdateWidthAndScroll()

	UpdateTickMarks(self)
	UpdateBossAbilityBars(self)
	UpdateAssignments(self)
end

-- Called when the width is set for EPTimeline widget.
---@param self EPTimeline
---@param width number
local function OnWidthSet(self, width)
	self:UpdateTimeline()
end

-- Called when the height is set for EPTimeline widget.
---@param self EPTimeline
---@param height number
local function OnHeightSet(self, height)
	local barHeight = self.bossAbilityTimeline.frame:GetHeight()
	local assignmentHeight = self.assignmentTimeline.frame:GetHeight()
	local newContentFrameHeight = height - paddingBetweenTimelineAndScrollBar - horizontalScrollBarHeight

	if self.allowHeightResizing then
		local contentFloor = newContentFrameHeight - paddingBetweenTimelines
		local timelineFloor = barHeight + assignmentHeight
		if contentFloor > timelineFloor then
			local surplus = contentFloor - timelineFloor
			local barPlusSurplus = barHeight + surplus
			local assignmentPlusSurplus = assignmentHeight + surplus
			if barPlusSurplus <= assignmentHeight and barPlusSurplus <= self.barDimensions.max then
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
			if barMinusSurplus >= assignmentHeight and barMinusSurplus >= self.barDimensions.min then
				barHeight = barMinusSurplus
			elseif assignmentMinusSurplus >= barHeight and assignmentMinusSurplus >= self.assignmentDimensions.min then
				assignmentHeight = assignmentMinusSurplus
			else
				local surplusSplit = surplus * 0.5
				barHeight = barHeight - surplusSplit
				assignmentHeight = assignmentHeight - surplusSplit
			end
		end
		barHeight = min(max(barHeight, self.barDimensions.min), self.barDimensions.max)
		assignmentHeight = min(max(assignmentHeight, self.assignmentDimensions.min), self.assignmentDimensions.max)
	end

	self.bossAbilityTimeline:SetHeight(barHeight)
	self.assignmentTimeline:SetHeight(assignmentHeight)

	local fullBarHeight = CalculateRequiredBarHeight(self, false)
	local fullAssignmentHeight = CalculateRequiredAssignmentHeight(self, false)

	self.bossAbilityTimeline:SetTimelineFrameHeight(fullBarHeight)
	self.assignmentTimeline:SetTimelineFrameHeight(fullAssignmentHeight)

	self.splitterScrollFrame:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 210, -barHeight)
	self.splitterScrollFrame:SetPoint(
		"TOPRIGHT",
		self.contentFrame,
		"TOPRIGHT",
		-paddingBetweenTimelineAndScrollBar - horizontalScrollBarHeight,
		-barHeight
	)
	self.contentFrame:SetHeight(newContentFrameHeight)
	self:UpdateTimeline()
end

---@param self EPTimeline
---@param assignmentID integer
local function SelectAssignment(self, assignmentID)
	for _, assignmentFrame in pairs(self.assignmentFrames) do
		if assignmentFrame.assignmentIndex == assignmentID then
			assignmentFrame.outlineTexture:SetColorTexture(unpack(assignmentSelectOutlineColor))
			assignmentFrame.spellTexture:SetPoint("TOPLEFT", 2, -2)
			assignmentFrame.spellTexture:SetPoint("BOTTOMRIGHT", -2, 2)
		end
	end
end

---@param self EPTimeline
---@param assignmentID integer
local function ClearSelectedAssignment(self, assignmentID)
	for _, assignmentFrame in pairs(self.assignmentFrames) do
		if assignmentFrame.assignmentIndex == assignmentID then
			assignmentFrame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
			assignmentFrame.spellTexture:SetPoint("TOPLEFT", 1, -1)
			assignmentFrame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
		end
	end
end

---@param self EPTimeline
---@param label EPLabel
local function SetCurrentTimeLabel(self, label)
	self.assignmentTimeline.currentTimeLabel = label
	self.bossAbilityTimeline.currentTimeLabel = label
end

---@param self EPTimeline
---@param allow boolean
local function SetAllowHeightResizing(self, allow)
	self.allowHeightResizing = allow
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(frameWidth, frameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	contentFrame:SetSize(frameWidth, frameHeight - horizontalScrollBarHeight - paddingBetweenTimelineAndScrollBar)

	local splitterScrollFrame = CreateFrame("ScrollFrame", Type .. "SplitterScrollFrame" .. count, contentFrame)
	splitterScrollFrame:SetHeight(paddingBetweenTimelines)

	local splitterFrame = CreateFrame("Frame", Type .. "SplitterFrame" .. count, splitterScrollFrame)
	splitterFrame:SetHeight(paddingBetweenTimelines)
	splitterFrame:SetPoint("LEFT")
	splitterScrollFrame:SetScrollChild(splitterFrame)

	local horizontalScrollBar = CreateFrame("Frame", Type .. "HorizontalScrollBar" .. count, frame)
	horizontalScrollBar:SetHeight(horizontalScrollBarHeight)
	horizontalScrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 210, 0)
	horizontalScrollBar:SetPoint(
		"BOTTOMRIGHT",
		frame,
		"BOTTOMRIGHT",
		-horizontalScrollBarHeight - paddingBetweenTimelineAndScrollBar,
		0
	)

	local scrollBarBackground = horizontalScrollBar:CreateTexture(Type .. "ScrollBarBackground" .. count, "BACKGROUND")
	scrollBarBackground:SetAllPoints()
	scrollBarBackground:SetColorTexture(0.25, 0.25, 0.25, 1)

	local thumb = CreateFrame("Button", Type .. "ScrollBarThumb" .. count, horizontalScrollBar)
	thumb:SetPoint("LEFT", thumbPadding.x, 0)
	thumb:SetSize(horizontalScrollBar:GetWidth() - 2 * thumbPadding.x, horizontalScrollBarHeight - (2 * thumbPadding.y))
	thumb:EnableMouse(true)
	thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
	thumb:SetScript("OnMouseDown", HandleThumbMouseDown)
	thumb:SetScript("OnMouseUp", HandleThumbMouseUp)
	horizontalScrollBar.thumb = thumb

	local thumbBackground = thumb:CreateTexture(Type .. "ScrollBarThumbBackground" .. count, "BACKGROUND")
	thumbBackground:SetAllPoints()
	thumbBackground:SetColorTexture(0.05, 0.05, 0.05, 1)

	---@class EPTimeline
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
		OnWidthSet = OnWidthSet,
		OnHeightSet = OnHeightSet,
		SelectAssignment = SelectAssignment,
		ClearSelectedAssignment = ClearSelectedAssignment,
		SetCurrentTimeLabel = SetCurrentTimeLabel,
		SetAllowHeightResizing = SetAllowHeightResizing,
		SetMaxAssignmentHeight = SetMaxAssignmentHeight,
		frame = frame,
		splitterFrame = splitterFrame,
		splitterScrollFrame = splitterScrollFrame,
		contentFrame = contentFrame,
		type = Type,
		horizontalScrollBar = horizontalScrollBar,
	}
	contentFrame.obj = widget
	frame.obj = widget
	horizontalScrollBar.obj = widget
	thumb.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
