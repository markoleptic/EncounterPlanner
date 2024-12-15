local Type = "EPTimeline"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local abs = math.abs
local CreateFrame = CreateFrame
local format = string.format
local floor = math.floor
local GetCursorPosition = GetCursorPosition
local GetSpellBaseCooldown = GetSpellBaseCooldown
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellTexture = C_Spell.GetSpellTexture
local hugeNumber = math.huge
local ipairs = ipairs
local IsAltKeyDown = IsAltKeyDown
local IsLeftShiftKeyDown, IsRightShiftKeyDown = IsLeftShiftKeyDown, IsRightShiftKeyDown
local max = math.max
local min = math.min
local pairs = pairs
local select = select
local split = string.split
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
local minimumNumberOfAssignmentRows = 1
local maximumNumberOfAssignmentRows = 12
local minimumNumberOfBossAbilityRows = 1
local maximumNumberOfBossAbilityRows = 12
local minimumBossAbilityWidth = 5
local tickWidth = 2
local minZoomFactor = 1
local maxZoomFactor = 10
local zoomStep = 0.05
local fontPath = LSM:Fetch("font", "PT Sans Narrow")
local tickColor = { 1, 1, 1, 0.75 }
local tickLabelColor = { 1, 1, 1, 1 }
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
local cooldownTextureFile = [[Interface\AddOns\EncounterPlanner\Media\DiagonalLine]]
local cooldownPadding = 2
local cooldownBackGroundColor = { 1, 1, 1, 0.2 }
local cooldownTextureAlpha = 0.4

local assignmentIsDragging = false
local assignmentOffsetWhenClicked = 0
local assignmentVerticalOffsetWhenClicked = 0
local thumbPadding = { x = 2, y = 2 }
local timelineLinePadding = { x = 25, y = 25 }
local thumbOffsetWhenThumbClicked = 0
local scrollBarWidthWhenThumbClicked = 0
local thumbWidthWhenThumbClicked = 0
local thumbIsDragging = false
local timelineFrameOffsetWhenDragStarted = 0
local timelineFrameIsDragging = false
local totalTimelineDuration = 0

local throttleInterval = 0.015 -- Minimum time between executions, in seconds
local lastExecutionTime = 0

local function ResetLocalVariables()
	assignmentIsDragging = false
	assignmentOffsetWhenClicked = 0
	assignmentVerticalOffsetWhenClicked = 0
	thumbPadding = { x = 2, y = 2 }
	timelineLinePadding = { x = 25, y = 25 }
	thumbOffsetWhenThumbClicked = 0
	scrollBarWidthWhenThumbClicked = 0
	thumbWidthWhenThumbClicked = 0
	thumbIsDragging = false
	timelineFrameOffsetWhenDragStarted = 0
	timelineFrameIsDragging = false
	totalTimelineDuration = 0
	lastExecutionTime = 0
end

---@param keyBinding ScrollKeyBinding|MouseButtonKeyBinding
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"|"MouseScroll"
---@return boolean
local function IsValidKeyCombination(keyBinding, mouseButton)
	local modifier, key = split("-", keyBinding)
	if modifier and key then
		if modifier == "Ctrl" then
			if not IsControlKeyDown() then
				return false
			end
		elseif modifier == "Shift" then
			if not IsLeftShiftKeyDown() and not IsRightShiftKeyDown() then
				return false
			end
		elseif modifier == "Alt" then
			if not IsAltKeyDown() then
				return false
			end
		end
		if mouseButton ~= key then
			return false
		end
	else
		if IsControlKeyDown() or IsLeftShiftKeyDown() or IsRightShiftKeyDown() or IsAltKeyDown() then
			return false
		end
		if mouseButton ~= keyBinding then
			return false
		end
	end
	return true
end

---@param self EPTimeline
---@param frame Frame|Texture
---@return number|nil
local function ConvertTimelineOffsetToTime(self, frame)
	local timelineFrame = self.bossAbilityTimeline.timelineFrame
	local offset = (frame:GetLeft() or 0) - (timelineFrame:GetLeft() or 0)
	local padding = timelineLinePadding.x
	local time = (offset - padding) * totalTimelineDuration / (timelineFrame:GetWidth() - padding * 2)
	if time < 0 or time > totalTimelineDuration then
		return nil
	end
	return time
end

-- Updates the time of the current time label and hides time labels that overlap with it.
---@param self EPTimeline
local function UpdateTimeLabels(self)
	local showCurrentTimeLabel = self.bossAbilityTimeline.verticalPositionLine:IsVisible()
	local offset = self.bossAbilityTimeline.verticalPositionLine:GetLeft()
		- self.bossAbilityTimeline.timelineFrame:GetLeft()
	local time = ConvertTimelineOffsetToTime(self, self.bossAbilityTimeline.verticalPositionLine)

	if time and showCurrentTimeLabel then
		self.currentTimeLabel.frame:Show()

		local minutes = floor(time / 60)
		local seconds = time % 60
		self.currentTimeLabel:SetText(format("%d:%02d", minutes, seconds), 2)
		self.currentTimeLabel:SetFrameWidthFromText()

		local left = offset - self.currentTimeLabel.text:GetStringWidth() / 2.0
		self.currentTimeLabel:SetPoint("LEFT", self.splitterFrame, "LEFT", left, 0)

		for _, label in pairs(self.timelineLabels) do
			local text = self.currentTimeLabel.text
			if not (text:GetRight() <= label:GetLeft() or text:GetLeft() >= label:GetRight()) then
				label:Hide()
			elseif label.wantsToShow then
				label:Show()
			end
		end
	else
		self.currentTimeLabel.frame:Hide()
		for _, label in pairs(self.timelineLabels) do
			if label.wantsToShow then
				label:Show()
			end
		end
	end
end

---@param timelineFrame Frame
---@param verticalPositionLine Texture
---@param offset? number
local function UpdateLinePosition(timelineFrame, verticalPositionLine, offset)
	local newTimeOffset = (select(1, GetCursorPosition()) / UIParent:GetEffectiveScale())
		- (timelineFrame:GetLeft() or 0)

	if offset then
		newTimeOffset = newTimeOffset + offset
	end

	verticalPositionLine:SetPoint("TOP", timelineFrame, "TOPLEFT", newTimeOffset, 0)
	verticalPositionLine:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", newTimeOffset, 0)
	verticalPositionLine:Show()
end

-- Updates the tick mark positions for the boss ability timeline and assignments timeline.
---@param self EPTimeline
local function UpdateTickMarks(self)
	local assignmentTicks = self.assignmentTimeline:GetTicks()
	local bossTicks = self.bossAbilityTimeline:GetTicks()
	-- Clear existing tick marks
	for _, ticks in pairs(assignmentTicks) do
		for _, tick in pairs(ticks) do
			tick:Hide()
		end
	end
	for _, ticks in pairs(bossTicks) do
		for _, tick in pairs(ticks) do
			tick:Hide()
		end
	end
	for _, label in pairs(self.timelineLabels) do
		label:Hide()
		label.wantsToShow = false
	end
	if totalTimelineDuration <= 0.0 then
		return
	end

	-- Define visible range in time (based on zoomFactor)
	local visibleDuration = totalTimelineDuration / self.zoomFactor

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

	local assignmentTimelineFrame = self.assignmentTimeline.timelineFrame
	local bossTimelineFrame = self.bossAbilityTimeline.timelineFrame
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

		local bossTickTable = bossTicks[1]
		if not bossTickTable then
			bossTicks[1] = {}
			bossTickTable = bossTicks[1]
		end
		local bossTick = bossTickTable[i]
		if not bossTick then
			bossTick = bossTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
			bossTick:SetColorTexture(unpack(tickColor))
			bossTickTable[i] = bossTick
		end
		bossTick:SetWidth(currentTickWidth)
		bossTick:SetPoint("TOP", bossTimelineFrame, "TOPLEFT", position + padding.x, 0)
		bossTick:SetPoint("BOTTOM", bossTimelineFrame, "BOTTOMLEFT", position + padding.x, 0)
		bossTick:Show()

		-- Create or reuse timestamp label
		---@class FontString
		local label = self.timelineLabels[i]
		if not label then
			label = self.splitterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			self.timelineLabels[i] = label
			if fontPath then
				label:SetFont(fontPath, tickFontSize)
				label:SetTextColor(unpack(tickLabelColor))
			end
		end
		local minutes = floor(i / 60)
		local seconds = i % 60
		label:SetText(format("%d:%02d", minutes, seconds))
		label:SetPoint("LEFT", self.splitterFrame, "LEFT", position + label:GetStringWidth() / 2.0, 0)
		label:Show()
		label.wantsToShow = true
	end

	for order, assignmentFrameIndices in ipairs(self.orderedAssignmentFrames) do
		local offsetY = (order - 1) * (assignmentTextureSize.y + paddingBetweenAssignments)

		local assignmentTickTable = assignmentTicks[order]
		if not assignmentTickTable then
			assignmentTicks[order] = {}
			assignmentTickTable = assignmentTicks[order]
		end

		for i = 0, totalTimelineDuration, tickInterval do
			local currentTickWidth = tickWidth
			if tickInterval == 60 then
				currentTickWidth = tickWidth
			elseif i % 2 == 0 then
				currentTickWidth = tickWidth * 0.5
			else
				currentTickWidth = tickWidth
			end

			local offsetX = (i / totalTimelineDuration) * (timelineWidth - (2 * padding.x)) + padding.x
			local assignmentTick = assignmentTickTable[i]
			if not assignmentTick then
				assignmentTick = assignmentTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
				assignmentTick:SetColorTexture(unpack(tickColor))
				assignmentTickTable[i] = assignmentTick
			end

			assignmentTick:SetWidth(currentTickWidth)
			assignmentTick:SetHeight(assignmentTextureSize.y + paddingBetweenAssignments)
			assignmentTick:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT", offsetX, -offsetY + 1)

			local showTick = true
			local tickLeft = assignmentTick:GetLeft()
			if tickLeft then
				local tickRight = tickLeft + currentTickWidth
				for _, assignmentFrameIndex in ipairs(assignmentFrameIndices) do
					local cooldown = self.assignmentFrames[assignmentFrameIndex].cooldownBackGround
					local cooldownLeft = cooldown:GetLeft()
					if not cooldownLeft then
						showTick = true
						break
					end
					local cooldownRight = cooldownLeft + cooldown:GetWidth()
					if not (tickRight <= cooldownLeft or tickLeft >= cooldownRight) then
						showTick = false
						break
					end
				end
			end
			if showTick then
				assignmentTick:Show()
			else
				assignmentTick:Hide()
			end
		end
	end
end

---@param horizontalScrollBar Frame
---@param thumb Button
---@param scrollFrameWidth number
---@param timelineWidth number
---@param horizontalScroll number
local function UpdateHorizontalScroll(horizontalScrollBar, thumb, scrollFrameWidth, timelineWidth, horizontalScroll)
	-- Sometimes horizontal scroll bar width can be zero when resizing, but is same as timeline width
	local horizontalScrollBarWidth = horizontalScrollBar:GetWidth()
	if horizontalScrollBarWidth == 0 then
		horizontalScrollBarWidth = timelineWidth
	end

	-- Calculate the scroll bar thumb size based on the visible area
	local thumbWidth = (scrollFrameWidth / timelineWidth) * (horizontalScrollBarWidth - (2 * thumbPadding.x))
	thumbWidth = max(thumbWidth, 20) -- Minimum size so it's always visible
	thumbWidth = min(thumbWidth, scrollFrameWidth - (2 * thumbPadding.x))
	thumb:SetWidth(thumbWidth)

	local maxScroll = timelineWidth - scrollFrameWidth
	local maxThumbPosition = horizontalScrollBarWidth - thumbWidth - (2 * thumbPadding.x)
	local horizontalThumbPosition = 0
	if maxScroll > 0 then -- Prevent division by zero if maxScroll is 0
		horizontalThumbPosition = (horizontalScroll / maxScroll) * maxThumbPosition
		horizontalThumbPosition = horizontalThumbPosition + thumbPadding.x
	else
		horizontalThumbPosition = thumbPadding.x -- If no scrolling is possible, reset the thumb to the start
	end
	thumb:SetPoint("LEFT", horizontalThumbPosition, 0)
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
	local timelineFrame = self.bossAbilityTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x

	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local timelineEndPosition = (endTime / totalTimelineDuration) * timelineWidth

	---@class Frame
	local frame = self.bossAbilityFrames[index]
	if not frame then
		frame = CreateFrame("Frame", nil, timelineFrame)
		frame.spellTexture = frame:CreateTexture(nil, "OVERLAY", nil, bossAbilityTextureSubLevel)
		frame.outlineTexture = frame:CreateTexture(nil, "OVERLAY", nil, bossAbilityTextureSubLevel - 1)
		frame.outlineTexture:SetAllPoints()
		frame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
		frame.outlineTexture:Show()
		frame.spellTexture:SetPoint("TOPLEFT", 1, -1)
		frame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
		frame.assignmentFrame = timelineFrame
		self.bossAbilityFrames[index] = frame
	end

	frame.abilityInstance = abilityInstance

	local r, g, b, a = unpack(color)
	frame.spellTexture:SetColorTexture(r / 255.0, g / 255.0, b / 255.0, a)
	frame:SetSize(max(minimumBossAbilityWidth, timelineEndPosition - timelineStartPosition), bossAbilityBarHeight)
	frame:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", timelineStartPosition + padding.x, -offset)
	frame:SetFrameLevel(timelineFrame:GetFrameLevel() + 1 + floor(startTime))
	frame:Show()
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
---@param spellCount table<integer, integer>
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
	offset,
	spellCount
)
	if not bossAbility.phases[bossPhaseIndex] then
		return bossAbilityInstanceIndex
	end

	if not spellCount[bossAbilitySpellID] then
		spellCount[bossAbilitySpellID] = 1
	end

	local color = colors[((bossAbilityOrderIndex - 1) % #colors) + 1]
	local cumulativePhaseCastTimes = bossPhaseStartTime
	local bossAbilityPhase = bossAbility.phases[bossPhaseIndex]
	for _, castTime in ipairs(bossAbilityPhase.castTimes) do
		local castStart = cumulativePhaseCastTimes + castTime
		local castEnd = castStart + bossAbility.castTime
		local effectEnd = castEnd + bossAbility.duration
		DrawBossAbilityBar(self, castStart, effectEnd, color, bossAbilityInstanceIndex, offset, {
			spellID = bossAbilitySpellID,
			phase = bossPhaseIndex,
			castTime = castStart,
			spellOccurrence = spellCount[bossAbilitySpellID],
		})
		spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] + 1
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
					spellOccurrence = spellCount[bossAbilitySpellID],
				})
				spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] + 1
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
---@param spellCount table<integer, integer>
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
	offset,
	spellCount
)
	if not bossAbility.eventTriggers then
		return bossAbilityInstanceIndex
	end

	if not spellCount[bossAbilitySpellID] then
		spellCount[bossAbilitySpellID] = 1
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
						spellOccurrence = spellCount[bossAbilitySpellID],
						phase = bossPhaseIndex,
						castTime = castStart,
						relativeCastTime = castTime,
						triggerSpellID = triggerSpellID,
						triggerCastIndex = triggerCastIndex,
					})
					spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] + 1
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
										spellOccurrence = spellCount[bossAbilitySpellID],
										phase = bossPhaseIndex,
										castTime = castStart,
										relativeCastTime = castTime,
										triggerSpellID = triggerSpellID,
										triggerCastIndex = triggerCastIndex,
										repeatInstance = repeatInstance,
										repeatCastIndex = repeatCastIndex,
									}
								)
								spellCount[bossAbilitySpellID] = spellCount[bossAbilitySpellID] + 1
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
	for _, texture in pairs(self.bossAbilityFrames) do
		texture:Hide()
	end

	local cumulativePhaseStartTime = 0
	local bossAbilityInstanceIndex = 1
	local offsets = {}
	local offset = 0
	for _, bossAbilitySpellID in ipairs(self.bossAbilityOrder) do
		offsets[bossAbilitySpellID] = offset
		if self.bossAbilityVisibility[bossAbilitySpellID] == true then
			offset = offset + bossAbilityBarHeight + paddingBetweenBossAbilityBars
		end
	end
	local spellCount = {}
	for _, bossPhaseIndex in ipairs(self.bossPhaseOrder) do
		local bossPhase = self.bossPhases[bossPhaseIndex]
		if bossPhase then
			local phaseEndTime = cumulativePhaseStartTime + bossPhase.duration
			for bossAbilityOrderIndex, bossAbilitySpellID in ipairs(self.bossAbilityOrder) do
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
						offsets[bossAbilitySpellID],
						spellCount
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
						offsets[bossAbilitySpellID],
						spellCount
					)
				end
			end
			cumulativePhaseStartTime = cumulativePhaseStartTime + bossPhase.duration
		end
	end
end

---@param frame GameTooltip|table
---@param elapsed number
local function HandleAssignmentSpellTextureTooltipUpdate(frame, elapsed)
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

---@param frame Frame
local function HandleAssignmentSpellTextureEnter(frame)
	if frame.spellID and frame.spellID ~= 0 then
		tooltip:ClearLines()
		tooltip:SetOwner(frame.assignmentFrame, "ANCHOR_CURSOR", 0, 0)
		tooltip:SetSpellByID(frame.spellID)
		tooltip:SetScript("OnUpdate", HandleAssignmentSpellTextureTooltipUpdate)
	end
end

local function HandleAssignmentSpellTextureLeave()
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()
end

---@param frame Frame
---@param elapsed number
---@param timeline EPTimeline
local function HandleAssignmentUpdate(frame, elapsed, timeline)
	if not assignmentIsDragging then
		return
	end

	local newOffset = (select(1, GetCursorPosition()) / UIParent:GetEffectiveScale())
		- timeline.bossAbilityTimeline.timelineFrame:GetLeft()
		- assignmentOffsetWhenClicked

	local padding = timelineLinePadding.x
	local scaledPadding = padding
		* (timeline.bossAbilityTimeline.timelineFrame:GetWidth() / timeline.bossAbilityTimeline.scrollFrame:GetWidth())

	local minAllowedOffset = scaledPadding
	local maxAllowedOffset = timeline.bossAbilityTimeline.timelineFrame:GetWidth()
		- scaledPadding
		- assignmentTextureSize.x
	local lineOffset = -assignmentOffsetWhenClicked
	if newOffset < minAllowedOffset then
		lineOffset = lineOffset + minAllowedOffset - newOffset
		newOffset = minAllowedOffset
	elseif newOffset > maxAllowedOffset then
		lineOffset = lineOffset - (newOffset - maxAllowedOffset)
		newOffset = maxAllowedOffset
	end

	UpdateLinePosition(timeline.assignmentTimeline.frame, timeline.assignmentTimeline.verticalPositionLine, lineOffset)
	UpdateLinePosition(
		timeline.bossAbilityTimeline.frame,
		timeline.bossAbilityTimeline.verticalPositionLine,
		lineOffset
	)
	UpdateTimeLabels(timeline)

	frame:SetPoint("TOPLEFT", newOffset, assignmentVerticalOffsetWhenClicked)
end

---@param frame Frame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
---@param timeline EPTimeline
local function HandleAssignmentMouseDown(frame, mouseButton, timeline)
	if not IsValidKeyCombination(timeline.preferences.keyBindings.editAssignment, mouseButton) then
		return
	end

	assignmentIsDragging = true
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()

	assignmentOffsetWhenClicked = (select(1, GetCursorPosition()) / UIParent:GetEffectiveScale()) - frame:GetLeft()
	assignmentVerticalOffsetWhenClicked = select(5, frame:GetPointByName("TOPLEFT"))

	frame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
	frame.spellTexture:SetPoint("TOPLEFT", 1, -1)
	frame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)

	frame:SetScript("OnUpdate", function(f, delta)
		HandleAssignmentUpdate(f, delta, timeline)
	end)
end

---@param frame Frame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
---@param timeline EPTimeline
local function HandleAssignmentMouseUp(frame, mouseButton, timeline)
	if assignmentIsDragging then
		assignmentIsDragging = false
		frame:SetScript("OnUpdate", nil)
	end
	if not IsValidKeyCombination(timeline.preferences.keyBindings.editAssignment, mouseButton) then
		return
	end

	if frame.assignmentIndex then
		timeline:Fire("AssignmentClicked", frame.assignmentIndex)
	end
end

---@param frame Frame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
---@param self EPTimeline
local function HandleAssignmentTimelineFrameMouseUp(frame, mouseButton, self)
	if not IsValidKeyCombination(self.preferences.keyBindings.newAssignment, mouseButton) then
		return
	end

	local currentX, currentY = GetCursorPosition()
	currentX = currentX / UIParent:GetEffectiveScale()
	currentY = currentY / UIParent:GetEffectiveScale()

	local nearestBarIndex = nil
	local minDistance = hugeNumber
	for index, bar in ipairs(self.bossAbilityFrames) do
		if bar:IsShown() then
			local barStart = bar:GetLeft()
			if barStart <= currentX then
				local distance = currentX - barStart
				if distance < minDistance then
					minDistance = distance
					nearestBarIndex = index
				end
			end
		end
	end

	if nearestBarIndex then
		local relativeDistanceFromTop = abs(self.assignmentTimeline.timelineFrame:GetTop() - currentY)
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
			local timelineFrame = self.bossAbilityTimeline.timelineFrame
			local timelineWidth = timelineFrame:GetWidth()
			local padding = timelineLinePadding.x
			local newTimeOffset = currentX - timelineFrame:GetLeft()
			local time = (newTimeOffset - padding) * totalTimelineDuration / (timelineWidth - padding * 2)
			time = min(max(0, time), totalTimelineDuration)
			local relativeAssignmentStartTime = time - self.bossAbilityFrames[nearestBarIndex].abilityInstance.castTime
			self:Fire(
				"CreateNewAssignment",
				self.bossAbilityFrames[nearestBarIndex].abilityInstance,
				assigneeIndex,
				relativeAssignmentStartTime
			)
		end
	end
end

-- Helper function to draw a spell icon for an assignment.
---@param self EPTimeline
---@param startTime number absolute start time of the assignment
---@param spellID integer spellID of the spell being assigned
---@param index integer index of the assignment texture
---@param uniqueID integer unique index of the assignment
---@param order number the relative order of the assignee of the assignment
---@param showCooldown boolean
local function DrawAssignment(self, startTime, spellID, index, uniqueID, order, showCooldown)
	if totalTimelineDuration <= 0.0 then
		return
	end

	local padding = timelineLinePadding
	local timelineFrame = self.assignmentTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x

	---@class Frame
	local assignment = self.assignmentFrames[index]
	if not assignment then
		assignment = CreateFrame("Frame", nil, timelineFrame)
		local spellTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel)
		spellTexture:SetPoint("TOPLEFT", 1, -1)
		spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)

		local outlineTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel - 1)
		outlineTexture:SetAllPoints()
		outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
		outlineTexture:Show()

		local cooldownBackGround = timelineFrame:CreateTexture(nil, "ARTWORK", nil, -1)
		cooldownBackGround:SetColorTexture(unpack(cooldownBackGroundColor))
		cooldownBackGround:SetPoint("TOPLEFT", assignment, "TOPLEFT")
		cooldownBackGround:SetPoint("BOTTOMLEFT", assignment, "BOTTOMLEFT")
		cooldownBackGround:Hide()

		local cooldownTexture = timelineFrame:CreateTexture(nil, "ARTWORK", nil, 0)
		cooldownTexture:SetTexture(cooldownTextureFile, "REPEAT", "REPEAT")
		cooldownTexture:SetHorizTile(true)
		cooldownTexture:SetVertTile(true)
		cooldownTexture:SetPoint("TOPLEFT", cooldownBackGround, "TOPLEFT", cooldownPadding, -cooldownPadding)
		cooldownTexture:SetPoint("BOTTOMRIGHT", cooldownBackGround, "BOTTOMRIGHT", -cooldownPadding, cooldownPadding)
		cooldownTexture:SetAlpha(cooldownTextureAlpha)
		cooldownTexture:Hide()

		assignment.outlineTexture = outlineTexture
		assignment.cooldownBackGround = cooldownBackGround
		assignment.cooldownTexture = cooldownTexture
		assignment.spellTexture = spellTexture
		assignment.assignmentFrame = timelineFrame
		assignment:SetScript("OnEnter", function(frame, _)
			HandleAssignmentSpellTextureEnter(frame)
		end)
		assignment:SetScript("OnLeave", function()
			HandleAssignmentSpellTextureLeave()
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
	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth

	if spellID == 0 or spellID == nil then
		assignment.spellTexture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
		assignment.cooldownBackGround:Hide()
		assignment.cooldownTexture:Hide()
	else
		local iconID, _ = GetSpellTexture(spellID)
		assignment.spellTexture:SetTexture(iconID)
		local cooldownEndPosition = nil
		if showCooldown then
			local cooldownMS, _ = GetSpellBaseCooldown(spellID)
			if not cooldownMS or cooldownMS <= 0 then
				local chargeInfo = GetSpellCharges(spellID)
				if chargeInfo then
					cooldownEndPosition = ((startTime + chargeInfo.cooldownDuration) / totalTimelineDuration)
						* timelineWidth
				end
			else
				cooldownEndPosition = ((startTime + cooldownMS / 1000) / totalTimelineDuration) * timelineWidth
			end
		end
		if showCooldown and cooldownEndPosition then
			assignment.cooldownBackGround:SetWidth(cooldownEndPosition - timelineStartPosition)
			assignment.cooldownBackGround:Show()
			assignment.cooldownTexture:Show()
		end
	end

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
	for _, frame in pairs(self.assignmentFrames) do
		frame:Hide()
		frame.cooldownBackGround:SetWidth(0)
		frame.cooldownBackGround:Hide()
		frame.cooldownTexture:Hide()
	end

	wipe(self.orderedAssignmentFrames)
	local maxOrder = -hugeNumber

	for index, assignment in ipairs(self.timelineAssignments) do
		if not self.orderedAssignmentFrames[assignment.order] then
			self.orderedAssignmentFrames[assignment.order] = {}
		end
		local showCooldown = not self.collapsed[assignment.assignment.assigneeNameOrRole]
			and self.preferences.showSpellCooldownDuration
		DrawAssignment(
			self,
			assignment.startTime,
			assignment.assignment.spellInfo.spellID,
			index,
			assignment.assignment.uniqueID,
			assignment.order,
			showCooldown
		)
		if showCooldown then
			tinsert(self.orderedAssignmentFrames[assignment.order], index)
		end
		maxOrder = max(maxOrder, assignment.order)
	end
	for i = 1, maxOrder do
		if not self.orderedAssignmentFrames[i] then
			self.orderedAssignmentFrames[i] = {}
		end
	end
end

---@param self EPTimeline
---@param isBossTimelineSection boolean
---@param delta number
---@param updateBoth boolean
local function HandleTimelineFrameMouseWheel(self, isBossTimelineSection, delta, updateBoth)
	local currentTime = GetTime()
	if currentTime - lastExecutionTime < throttleInterval then
		return
	end
	lastExecutionTime = currentTime
	if not totalTimelineDuration or totalTimelineDuration <= 0 then
		return
	end

	local validScroll = IsValidKeyCombination(self.preferences.keyBindings.scroll, "MouseScroll")
	local validZoom = IsValidKeyCombination(self.preferences.keyBindings.zoom, "MouseScroll")

	local timelineSection = nil
	if isBossTimelineSection then
		timelineSection = self.bossAbilityTimeline
	else
		timelineSection = self.assignmentTimeline
	end
	local timelineFrame = timelineSection.timelineFrame
	local scrollFrame = timelineSection.scrollFrame

	if validScroll or updateBoth then
		local scrollFrameHeight = scrollFrame:GetHeight()
		local timelineFrameHeight = timelineFrame:GetHeight()

		local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
		local currentVerticalScroll = scrollFrame:GetVerticalScroll()
		local snapValue = (timelineSection.textureHeight + timelineSection.listPadding) / 2
		local currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)

		if delta > 0 then
			currentSnapValue = currentSnapValue - 1
		elseif delta < 0 then
			currentSnapValue = currentSnapValue + 1
		end

		local newVerticalScroll = max(min(currentSnapValue * snapValue, maxVerticalScroll), 0)
		scrollFrame:SetVerticalScroll(newVerticalScroll)
		timelineSection.listScrollFrame:SetVerticalScroll(newVerticalScroll)
		timelineSection:UpdateVerticalScroll()
	end

	if validZoom or updateBoth then
		local timelineWidth = timelineFrame:GetWidth()

		local visibleDuration = totalTimelineDuration / self.zoomFactor
		local visibleStartTime = (scrollFrame:GetHorizontalScroll() / timelineWidth) * totalTimelineDuration
		local visibleEndTime = visibleStartTime + visibleDuration

		-- Update zoom factor based on scroll delta
		if delta > 0 and self.zoomFactor < maxZoomFactor then
			self.zoomFactor = self.zoomFactor * (1.0 + zoomStep)
		elseif delta < 0 and self.zoomFactor > minZoomFactor then
			self.zoomFactor = self.zoomFactor / (1.0 + zoomStep)
		end

		local newVisibleDuration = totalTimelineDuration / self.zoomFactor
		local newVisibleStartTime, newVisibleEndTime

		if self.preferences.zoomCenteredOnCursor then
			local xPosition = select(1, GetCursorPosition()) or 0
			local frameLeft = timelineFrame:GetLeft() or 0
			local relativeCursorOffset = xPosition / UIParent:GetEffectiveScale() - frameLeft

			-- Convert offset to time, accounting for padding
			local padding = timelineLinePadding.x
			local effectiveTimelineWidth = timelineWidth - (padding * 2)
			local cursorTime = (relativeCursorOffset - padding) * totalTimelineDuration / effectiveTimelineWidth

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
			local overflow = newVisibleStartTime
			newVisibleEndTime = newVisibleEndTime - overflow
			newVisibleStartTime = 0
		elseif newVisibleEndTime > totalTimelineDuration then
			-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
			local overflow = totalTimelineDuration - newVisibleEndTime
			newVisibleEndTime = totalTimelineDuration
			newVisibleStartTime = newVisibleStartTime + overflow
		end

		-- Ensure boundaries are within the total timeline range
		newVisibleStartTime = max(0, newVisibleStartTime)
		newVisibleEndTime = min(totalTimelineDuration, newVisibleEndTime)

		-- Adjust the timeline frame width based on zoom factor
		local scrollFrameWidth = scrollFrame:GetWidth()
		local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

		-- Recalculate the new scroll position based on the new visible start time
		local newHorizontalScroll = (newVisibleStartTime / totalTimelineDuration) * newTimelineFrameWidth

		self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)

		self.assignmentTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)
		self.bossAbilityTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)

		self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.splitterFrame:SetWidth(newTimelineFrameWidth)

		UpdateHorizontalScroll(
			self.horizontalScrollBar,
			self.thumb,
			scrollFrameWidth,
			newTimelineFrameWidth,
			newHorizontalScroll
		)
		UpdateAssignments(self)
		UpdateBossAbilityBars(self)
		UpdateTickMarks(self)
	end
end

---@param self EPTimeline
local function HandleThumbMouseDown(self)
	thumbOffsetWhenThumbClicked = (select(1, GetCursorPosition()) / UIParent:GetEffectiveScale()) - self.thumb:GetLeft()
	scrollBarWidthWhenThumbClicked = self.horizontalScrollBar:GetWidth()
	thumbWidthWhenThumbClicked = self.thumb:GetWidth()
	thumbIsDragging = true

	self.thumb:SetScript("OnUpdate", function()
		if not thumbIsDragging then
			return
		end

		local paddingX = thumbPadding.x
		local currentOffset = thumbOffsetWhenThumbClicked
		local currentWidth = thumbWidthWhenThumbClicked
		local currentScrollBarWidth = scrollBarWidthWhenThumbClicked
		local newOffset = (select(1, GetCursorPosition()) / UIParent:GetEffectiveScale())
			- self.horizontalScrollBar:GetLeft()
			- currentOffset

		local minAllowedOffset = paddingX
		local maxAllowedOffset = currentScrollBarWidth - currentWidth - paddingX
		newOffset = max(newOffset, minAllowedOffset)
		newOffset = min(newOffset, maxAllowedOffset)
		self.thumb:SetPoint("LEFT", newOffset, 0)

		local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
		-- Calculate the scroll frame's horizontal scroll based on the thumb's position
		local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * paddingX)
		local maxScroll = self.bossAbilityTimeline.timelineFrame:GetWidth() - bossAbilityScrollFrame:GetWidth()
		local scrollOffset = ((newOffset - paddingX) / maxThumbPosition) * maxScroll
		bossAbilityScrollFrame:SetHorizontalScroll(scrollOffset)
		self.assignmentTimeline.scrollFrame:SetHorizontalScroll(scrollOffset)
		self.splitterScrollFrame:SetHorizontalScroll(scrollOffset)
	end)
end

---@param self EPTimeline
local function HandleThumbMouseUp(self)
	thumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

---@param self EPTimeline
---@param frame Frame
local function HandleTimelineFrameEnter(self, frame)
	if timelineFrameIsDragging == true then
		return
	end
	frame:SetScript("OnUpdate", function()
		UpdateLinePosition(self.assignmentTimeline.frame, self.assignmentTimeline.verticalPositionLine)
		UpdateLinePosition(self.bossAbilityTimeline.frame, self.bossAbilityTimeline.verticalPositionLine)
		UpdateTimeLabels(self)
	end)
end

---@param self EPTimeline
---@param frame Frame
local function HandleTimelineFrameLeave(self, frame)
	if timelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", nil)
	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels(self)
end

---@param self EPTimeline
local function HandleTimelineFrameDragUpdate(self)
	if not timelineFrameIsDragging then
		return
	end

	local scrollFrame = self.bossAbilityTimeline.scrollFrame
	local x = select(1, GetCursorPosition())
	local dx = (x - timelineFrameOffsetWhenDragStarted) / scrollFrame:GetEffectiveScale()
	local newHorizontalScroll = scrollFrame:GetHorizontalScroll() - dx
	local scrollFrameWidth = scrollFrame:GetWidth()
	local timelineFrameWidth = self.bossAbilityTimeline.timelineFrame:GetWidth()
	local maxHorizontalScroll = self.bossAbilityTimeline.timelineFrame:GetWidth() - scrollFrameWidth
	newHorizontalScroll = min(max(0, newHorizontalScroll), maxHorizontalScroll)
	self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
	timelineFrameOffsetWhenDragStarted = x
	UpdateHorizontalScroll(
		self.horizontalScrollBar,
		self.thumb,
		scrollFrameWidth,
		timelineFrameWidth,
		newHorizontalScroll
	)
end

---@param self EPTimeline
---@param frame Frame
---@param button string
local function HandleTimelineFrameDragStart(self, frame, button)
	if not IsValidKeyCombination(self.preferences.keyBindings.pan, button) then
		return
	end
	timelineFrameIsDragging = true
	timelineFrameOffsetWhenDragStarted = select(1, GetCursorPosition())
	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels(self)
	frame:SetScript("OnUpdate", function()
		HandleTimelineFrameDragUpdate(self)
	end)
end

---@param self EPTimeline
---@param frame Frame
---@param scrollFrame ScrollFrame
local function HandleTimelineFrameDragStop(self, frame, scrollFrame)
	timelineFrameIsDragging = false
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
		frame:SetScript("OnUpdate", function()
			UpdateLinePosition(self.assignmentTimeline.frame, self.assignmentTimeline.verticalPositionLine)
			UpdateLinePosition(self.bossAbilityTimeline.frame, self.bossAbilityTimeline.verticalPositionLine)
			UpdateTimeLabels(self)
		end)
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
	local abilityCount = 1
	local minH, maxH, stepH = 0, 0, (bossAbilityBarHeight + paddingBetweenBossAbilityBars)
	for _, visible in pairs(self.bossAbilityVisibility) do
		if visible == true then
			if abilityCount <= maximumNumberOfBossAbilityRows then
				maxH = maxH + stepH
			end
			if abilityCount <= minimumNumberOfBossAbilityRows then
				minH = maxH
			end
			abilityCount = abilityCount + 1
		end
	end
	if minH >= stepH then
		minH = minH - paddingBetweenBossAbilityBars
	else
		minH = bossAbilityBarHeight -- Prevent boss ability timeline frame from having 0 height
	end
	if maxH >= stepH then
		maxH = maxH - paddingBetweenBossAbilityBars
	else
		maxH = bossAbilityBarHeight -- Prevent boss ability timeline frame from having 0 height
	end
	self.barDimensions.min = minH
	self.barDimensions.max = maxH
	self.barDimensions.step = stepH
end

---@param self EPTimeline
local function CalculateMinMaxStepAssignmentHeight(self)
	local totalAssignmentRows = 1
	local minH, maxH, stepH = 0, 0, (assignmentTextureSize.y + paddingBetweenAssignments)
	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not self.collapsed[as.assigneeNameOrRole] then
			if totalAssignmentRows <= maximumNumberOfAssignmentRows then
				maxH = maxH + stepH
			end
			if totalAssignmentRows <= minimumNumberOfAssignmentRows then
				minH = maxH
			end
			totalAssignmentRows = totalAssignmentRows + 1
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
---@field thumb Button
---@field addAssigneeDropdown EPDropdown
---@field currentTimeLabel EPLabel
---
---@field assigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
---@field assignmentFrames table<integer, Frame>
---@field orderedAssignmentFrames table<integer, table<integer, integer>>
---@field bossAbilities table<integer, BossAbility>
---@field bossAbilityVisibility table<integer, boolean>
---@field bossAbilityOrder table<integer, integer>
---@field bossAbilityFrames table<integer, Frame>
---@field bossPhaseOrder table<integer, integer>
---@field bossPhases table<integer, BossPhase>
---@field collapsed table<string, boolean>
---@field timelineAssignments table<integer, TimelineAssignment>
---@field allowHeightResizing boolean
---@field barDimensions {min: integer, max:integer, step:number}
---@field assignmentDimensions {min: integer, max:integer, step:number}
---@field preferences EncounterPlannerPreferences
---@field zoomFactor number

---@param self EPTimeline
local function OnAcquire(self)
	self.assignmentFrames = self.assignmentFrames or {}
	self.orderedAssignmentFrames = {}
	self.bossAbilityFrames = self.bossAbilityFrames or {}
	self.timelineLabels = self.timelineLabels or {}
	self.zoomFactor = self.zoomFactor or 1.0
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
	local assignmentTimelineSectionFrame = self.assignmentTimeline.frame
	assignmentTimelineSectionFrame:SetParent(self.contentFrame)

	self.bossAbilityTimeline = AceGUI:Create("EPTimelineSection")
	local bossAbilityTimelineSectionFrame = self.bossAbilityTimeline.frame
	bossAbilityTimelineSectionFrame:SetParent(self.contentFrame)

	self.assignmentTimeline:SetListPadding(paddingBetweenAssignments)
	self.bossAbilityTimeline:SetListPadding(paddingBetweenBossAbilityBars)

	self.assignmentTimeline:SetTextureHeight(assignmentTextureSize.y)
	self.bossAbilityTimeline:SetTextureHeight(bossAbilityBarHeight)

	self.assignmentTimeline.listFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, false, delta, false)
	end)
	self.bossAbilityTimeline.listFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, true, delta, false)
	end)
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, false, delta, false)
	end)
	self.bossAbilityTimeline.timelineFrame:SetScript("OnMouseWheel", function(_, delta)
		HandleTimelineFrameMouseWheel(self, true, delta, false)
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
	self.assignmentTimeline.timelineFrame:SetScript("OnMouseUp", function(frame, button)
		HandleAssignmentTimelineFrameMouseUp(frame, button, self)
	end)

	bossAbilityTimelineSectionFrame:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT")
	bossAbilityTimelineSectionFrame:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT")
	assignmentTimelineSectionFrame:SetPoint("TOPLEFT", bossAbilityTimelineSectionFrame, "BOTTOMLEFT", 0, -36)
	assignmentTimelineSectionFrame:SetPoint("TOPRIGHT", bossAbilityTimelineSectionFrame, "BOTTOMRIGHT", 0, -36)

	self.addAssigneeDropdown = AceGUI:Create("EPDropdown")
	self.addAssigneeDropdown.frame:SetParent(self.contentFrame)
	self.addAssigneeDropdown.frame:SetPoint("RIGHT", self.splitterScrollFrame, "LEFT", -10, 0)

	self.currentTimeLabel = AceGUI:Create("EPLabel")
	self.currentTimeLabel.text:SetTextColor(unpack(assignmentSelectOutlineColor))
	self.currentTimeLabel:SetFontSize(18)
	self.currentTimeLabel.frame:SetParent(self.splitterScrollFrame)
	self.currentTimeLabel.frame:SetPoint("CENTER", self.splitterScrollFrame, "LEFT", 200, 0)
	self.currentTimeLabel.frame:Hide()
end

---@param self EPTimeline
local function OnRelease(self)
	self.assignmentTimeline:Release()
	self.assignmentTimeline = nil
	self.bossAbilityTimeline:Release()
	self.bossAbilityTimeline = nil
	self.addAssigneeDropdown:Release()
	self.currentTimeLabel:Release()
	self.currentTimeLabel = nil

	self:ClearSelectedAssignments()
	self:ClearSelectedBossAbilities()

	for _, frame in ipairs(self.assignmentFrames) do
		frame:Hide()
		frame.cooldownBackGround:SetWidth(0)
		frame.cooldownBackGround:Hide()
		frame.cooldownTexture:Hide()
		frame.spellTexture:SetTexture(nil)
		frame.spellID = nil
		frame.assignmentIndex = nil
	end

	for _, frame in ipairs(self.bossAbilityFrames) do
		frame:Hide()
		frame.spellTexture:SetTexture(nil)
		frame.abilityInstance = nil
	end

	self.orderedAssignmentFrames = nil
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
	self.preferences = nil

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

	self:UpdateHeight()
end

---@param self EPTimeline
---@param assignments table<integer, TimelineAssignment>
---@param assigneesAndSpells table<integer, {assigneeNameOrRole:string, spellID:number|nil}>
---@param collapsed table<string, boolean>
local function SetAssignments(self, assignments, assigneesAndSpells, collapsed)
	self.timelineAssignments = assignments
	self.assigneesAndSpells = assigneesAndSpells
	self.collapsed = collapsed
	self:UpdateHeight()
end

---@param self EPTimeline
---@return table<integer, TimelineAssignment>
local function GetAssignments(self)
	return self.timelineAssignments
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
local function UpdateTimeline(self)
	if not totalTimelineDuration or totalTimelineDuration <= 0 then
		return
	end

	local assignmentScrollFrameHeight = self.assignmentTimeline.scrollFrame:GetHeight()
	local assignmentTimelineFrameHeight = self.assignmentTimeline.timelineFrame:GetHeight()
	local maxVerticalScroll = assignmentTimelineFrameHeight - assignmentScrollFrameHeight
	local currentVerticalScroll = self.assignmentTimeline.scrollFrame:GetVerticalScroll()
	local snapValue = (self.assignmentTimeline.textureHeight + self.assignmentTimeline.listPadding) / 2
	local currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)
	local newVerticalScroll = max(min(currentSnapValue * snapValue, maxVerticalScroll), 0)
	self.assignmentTimeline.scrollFrame:SetVerticalScroll(newVerticalScroll)
	self.assignmentTimeline.listScrollFrame:SetVerticalScroll(newVerticalScroll)
	self.assignmentTimeline:UpdateVerticalScroll()

	local bossScrollFrameHeight = self.bossAbilityTimeline.scrollFrame:GetHeight()
	local bossTimelineFrameHeight = self.bossAbilityTimeline.timelineFrame:GetHeight()
	local bossMaxVerticalScroll = bossTimelineFrameHeight - bossScrollFrameHeight
	local bossCurrentVerticalScroll = self.bossAbilityTimeline.scrollFrame:GetVerticalScroll()
	local bossSnapValue = (self.bossAbilityTimeline.textureHeight + self.bossAbilityTimeline.listPadding) / 2
	local bossCurrentSnapValue = floor((bossCurrentVerticalScroll / bossSnapValue) + 0.5)
	local bossNewVerticalScroll = max(min(bossCurrentSnapValue * bossSnapValue, bossMaxVerticalScroll), 0)
	self.bossAbilityTimeline.scrollFrame:SetVerticalScroll(bossNewVerticalScroll)
	self.bossAbilityTimeline.listScrollFrame:SetVerticalScroll(bossNewVerticalScroll)
	self.bossAbilityTimeline:UpdateVerticalScroll()

	local timelineWidth = self.bossAbilityTimeline.timelineFrame:GetWidth()
	local visibleDuration = totalTimelineDuration / self.zoomFactor
	local visibleStartTime = (self.bossAbilityTimeline.scrollFrame:GetHorizontalScroll() / timelineWidth)
		* totalTimelineDuration
	local visibleEndTime = visibleStartTime + visibleDuration
	local newVisibleDuration = totalTimelineDuration / self.zoomFactor
	local newVisibleStartTime, newVisibleEndTime

	if self.preferences.zoomCenteredOnCursor then
		local xPosition = select(1, GetCursorPosition()) or 0
		local frameLeft = self.bossAbilityTimeline.timelineFrame:GetLeft() or 0
		local relativeCursorOffset = xPosition / UIParent:GetEffectiveScale() - frameLeft

		-- Convert offset to time, accounting for padding
		local padding = timelineLinePadding.x
		local effectiveTimelineWidth = timelineWidth - (padding * 2)
		local cursorTime = (relativeCursorOffset - padding) * totalTimelineDuration / effectiveTimelineWidth

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
		local overflow = newVisibleStartTime
		newVisibleEndTime = newVisibleEndTime - overflow
		newVisibleStartTime = 0
	elseif newVisibleEndTime > totalTimelineDuration then
		-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
		local overflow = totalTimelineDuration - newVisibleEndTime
		newVisibleEndTime = totalTimelineDuration
		newVisibleStartTime = newVisibleStartTime + overflow
	end

	-- Ensure boundaries are within the total timeline range
	newVisibleStartTime = max(0, newVisibleStartTime)
	newVisibleEndTime = min(totalTimelineDuration, newVisibleEndTime)

	-- Adjust the timeline frame width based on zoom factor
	local scrollFrameWidth = self.bossAbilityTimeline.scrollFrame:GetWidth()
	local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

	-- Recalculate the new scroll position based on the new visible start time
	local newHorizontalScroll = (newVisibleStartTime / totalTimelineDuration) * newTimelineFrameWidth

	self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.assignmentTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)

	self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.bossAbilityTimeline.timelineFrame:SetWidth(newTimelineFrameWidth)

	self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
	self.splitterFrame:SetWidth(newTimelineFrameWidth)

	UpdateHorizontalScroll(
		self.horizontalScrollBar,
		self.thumb,
		scrollFrameWidth,
		newTimelineFrameWidth,
		newHorizontalScroll
	)
	UpdateAssignments(self)
	UpdateBossAbilityBars(self)
	UpdateTickMarks(self)
end

-- Sets the height of the widget based on boss ability bars and assignment icons
---@param self EPTimeline
local function UpdateHeight(self)
	CalculateMinMaxStepAssignmentHeight(self)
	CalculateMinMaxStepBarHeight(self)
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

	local height = paddingBetweenTimelines + paddingBetweenTimelineAndScrollBar + horizontalScrollBarHeight

	local assignmentFrameHeight = self.assignmentTimeline.frame:GetHeight()
	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()

	local preferredAssignmentHeight = self.preferences.timelineRows.numberOfAssignmentsToShow
			* self.assignmentDimensions.step
		- paddingBetweenAssignments
	preferredAssignmentHeight = min(preferredAssignmentHeight, self.assignmentDimensions.max)
	local preferredBossHeight = self.preferences.timelineRows.numberOfBossAbilitiesToShow * self.barDimensions.step
		- paddingBetweenBossAbilityBars
	preferredBossHeight = min(preferredBossHeight, self.barDimensions.max)

	if assignmentFrameHeight - self.assignmentDimensions.max > 0.5 then
		height = height + self.assignmentDimensions.max
		self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	elseif abs(assignmentFrameHeight - preferredAssignmentHeight) > 0.5 then
		height = height + preferredAssignmentHeight
		self.assignmentTimeline.frame:SetHeight(preferredAssignmentHeight)
	else
		height = height + assignmentFrameHeight
	end

	if bossFrameHeight - self.barDimensions.max > 0.5 then
		height = height + self.barDimensions.max
		self.bossAbilityTimeline.frame:SetHeight(self.barDimensions.max)
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
	local height = paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
		+ bossFrameHeight
	self.assignmentTimeline.frame:SetHeight(self.assignmentDimensions.max)
	self.preferences.timelineRows.numberOfAssignmentsToShow = maximumNumberOfAssignmentRows
	self:SetHeight(height + self.assignmentDimensions.max)
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
	local assignmentHeight = self.assignmentTimeline.frame:GetHeight()
	local barHeight = self.bossAbilityTimeline.frame:GetHeight()
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

	self.assignmentTimeline:SetHeight(assignmentHeight)
	self.bossAbilityTimeline:SetHeight(barHeight)

	local fullAssignmentHeight = CalculateRequiredAssignmentHeight(self, false)
	local fullBarHeight = CalculateRequiredBarHeight(self, false)

	self.assignmentTimeline:SetTimelineFrameHeight(fullAssignmentHeight)
	self.bossAbilityTimeline:SetTimelineFrameHeight(fullBarHeight)

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
			break
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
			break
		end
	end
end

---@param self EPTimeline
---@param spellID integer
---@param spellOccurrence integer
local function SelectBossAbility(self, spellID, spellOccurrence)
	for _, frame in pairs(self.bossAbilityFrames) do
		if frame.abilityInstance.spellID == spellID and frame.abilityInstance.spellOccurrence == spellOccurrence then
			frame.outlineTexture:SetColorTexture(unpack(assignmentSelectOutlineColor))
			frame.spellTexture:SetPoint("TOPLEFT", 2, -2)
			frame.spellTexture:SetPoint("BOTTOMRIGHT", -2, 2)
			local y = select(5, frame:GetPointByName("TOPLEFT"))
			self.bossAbilityTimeline:ScrollVerticallyIfNotVisible(y, y - frame:GetHeight())
			break
		end
	end
end

---@param self EPTimeline
---@param spellID integer
---@param spellOccurrence integer
local function ClearSelectedBossAbility(self, spellID, spellOccurrence)
	for _, frame in pairs(self.bossAbilityFrames) do
		if frame.abilityInstance.spellID == spellID and frame.abilityInstance.spellOccurrence == spellOccurrence then
			frame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
			frame.spellTexture:SetPoint("TOPLEFT", 1, -1)
			frame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
			break
		end
	end
end

---@param self EPTimeline
local function ClearSelectedAssignments(self)
	for _, assignmentFrame in pairs(self.assignmentFrames) do
		assignmentFrame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
		assignmentFrame.spellTexture:SetPoint("TOPLEFT", 1, -1)
		assignmentFrame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
	end
end

---@param self EPTimeline
local function ClearSelectedBossAbilities(self)
	for _, frame in pairs(self.bossAbilityFrames) do
		frame.outlineTexture:SetColorTexture(unpack(assignmentOutlineColor))
		frame.spellTexture:SetPoint("TOPLEFT", 1, -1)
		frame.spellTexture:SetPoint("BOTTOMRIGHT", -1, 1)
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
			assignmentHeight = assignmentHeight - paddingBetweenAssignments
		end

		local barHeight = self.bossAbilityTimeline.frame:GetHeight()
		local barProximity = barHeight % self.barDimensions.step
		if barProximity < self.barDimensions.step / 2.0 then
			barHeight = barHeight - barProximity
		else
			barHeight = barHeight + (self.barDimensions.step - barProximity)
		end
		if barHeight >= self.barDimensions.step then
			barHeight = barHeight - paddingBetweenBossAbilityBars
		end

		assignmentHeight = min(max(assignmentHeight, self.assignmentDimensions.min), self.assignmentDimensions.max)
		barHeight = min(max(barHeight, self.barDimensions.min), self.barDimensions.max)

		self.assignmentTimeline:SetHeight(assignmentHeight)
		self.bossAbilityTimeline:SetHeight(barHeight)

		local numberOfAssignmentsToShow =
			floor((assignmentHeight + paddingBetweenAssignments + 0.5) / self.assignmentDimensions.step)
		numberOfAssignmentsToShow =
			min(max(minimumNumberOfAssignmentRows, numberOfAssignmentsToShow), maximumNumberOfAssignmentRows)
		self.preferences.timelineRows.numberOfAssignmentsToShow = numberOfAssignmentsToShow

		local numberOfBossAbilitiesToShow =
			floor((barHeight + paddingBetweenBossAbilityBars + 0.5) / self.barDimensions.step)
		numberOfBossAbilitiesToShow =
			min(max(minimumNumberOfBossAbilityRows, numberOfBossAbilitiesToShow), maximumNumberOfBossAbilityRows)
		self.preferences.timelineRows.numberOfBossAbilitiesToShow = numberOfBossAbilitiesToShow

		local totalHeight = paddingBetweenTimelineAndScrollBar
			+ horizontalScrollBarHeight
			+ paddingBetweenTimelines
			+ barHeight
			+ assignmentHeight

		self:SetHeight(totalHeight) -- todo :remove
		self:UpdateTimeline()
	end
end

---@param self EPTimeline
---@param preferences EncounterPlannerPreferences
local function SetPreferences(self, preferences)
	self.preferences = preferences
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
		SelectBossAbility = SelectBossAbility,
		ClearSelectedBossAbility = ClearSelectedBossAbility,
		ClearSelectedAssignments = ClearSelectedAssignments,
		ClearSelectedBossAbilities = ClearSelectedBossAbilities,
		SetAllowHeightResizing = SetAllowHeightResizing,
		SetMaxAssignmentHeight = SetMaxAssignmentHeight,
		SetPreferences = SetPreferences,
		UpdateHeight = UpdateHeight,
		frame = frame,
		splitterFrame = splitterFrame,
		splitterScrollFrame = splitterScrollFrame,
		contentFrame = contentFrame,
		type = Type,
		horizontalScrollBar = horizontalScrollBar,
		thumb = thumb,
	}

	thumb:SetScript("OnMouseDown", function()
		HandleThumbMouseDown(widget)
	end)
	thumb:SetScript("OnMouseUp", function()
		HandleThumbMouseUp(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
