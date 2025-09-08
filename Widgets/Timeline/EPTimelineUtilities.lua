local _, Namespace = ...

---@class Private
local Private = Namespace
---@class EPTimelineConstants
local k = Private.timeline.constants
---@class EPTimelineState
local s = Private.timeline.state

---@class EPTimelineUtilities
local EPTimelineUtilities = Private.timeline.utilities

local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType

local abs = math.abs
local Clamp = Clamp
local floor = math.floor
local format = string.format
local GetCursorPosition = GetCursorPosition
local ipairs = ipairs
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsLeftShiftKeyDown, IsRightShiftKeyDown = IsLeftShiftKeyDown, IsRightShiftKeyDown
local pairs = pairs
local select = select
local sort = table.sort
local split = string.split
local type = type
local unpack = unpack

---@param frame Frame|Texture
---@param timelineFrame Frame
---@return number|nil
function EPTimelineUtilities.ConvertTimelineOffsetToTime(frame, timelineFrame)
	local offset = (frame:GetLeft() or 0) - (timelineFrame:GetLeft() or 0)
	local padding = k.TimelineLinePadding.x
	local time = (offset - padding) * s.TotalTimelineDuration / (timelineFrame:GetWidth() - padding * 2)
	if time < 0 or time > s.TotalTimelineDuration then
		return nil
	end
	return time
end

---@param time number
---@param timelineFrameWidth number
---@return number
function EPTimelineUtilities.ConvertTimeToTimelineOffset(time, timelineFrameWidth)
	local timelineWidth = timelineFrameWidth - 2 * k.TimelineLinePadding.x
	local timelineStartPosition = (time / s.TotalTimelineDuration) * timelineWidth
	return timelineStartPosition + k.TimelineLinePadding.x
end

---@param assignmentFrames table<integer, AssignmentFrame>
---@param uniqueID integer
---@return AssignmentFrame|nil
function EPTimelineUtilities.FindAssignmentFrame(assignmentFrames, uniqueID)
	for _, frame in ipairs(assignmentFrames) do
		if frame.uniqueAssignmentID == uniqueID then
			return frame
		end
	end
	return nil
end

---@param uniqueID integer
---@return TimelineAssignment|nil
---@return integer|nil
function EPTimelineUtilities.FindTimelineAssignment(uniqueID)
	if s.TimelineAssignments then
		for index, timelineAssignment in ipairs(s.TimelineAssignments) do
			if timelineAssignment.assignment.uniqueID == uniqueID then
				return timelineAssignment, index
			end
		end
	end
	return nil, nil
end

---@param keyBinding ScrollKeyBinding|MouseButtonKeyBinding
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"|"MouseScroll"
---@return boolean
function EPTimelineUtilities.IsValidKeyCombination(keyBinding, mouseButton)
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

---@param frame AssignmentFrame
---@param highlightType HighlightType
---@param height number
function EPTimelineUtilities.SetAssignmentFrameOutline(frame, highlightType, height)
	if highlightType == k.HighlightType.Full then
		frame.spellTexture:SetSize(height - 4, height - 4)
		frame:SetBackdropBorderColor(unpack(k.AssignmentSelectOutlineColor))
	elseif highlightType == k.HighlightType.Half then
		frame.spellTexture:SetSize(height - 2, height - 2)
		frame:SetBackdropBorderColor(unpack(k.AssignmentSelectOutlineColor))
	elseif highlightType == k.HighlightType.None then
		frame.spellTexture:SetSize(height - 2, height - 2)
		frame:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))
	end
end

---@param assignmentFrames table<integer, AssignmentFrame>
---@param frameIndices table<integer, integer>
function EPTimelineUtilities.SortAssignmentFrameIndices(assignmentFrames, frameIndices)
	sort(frameIndices, function(a, b)
		local leftA, leftB = assignmentFrames[a]:GetLeft(), assignmentFrames[b]:GetLeft()
		if leftA and leftB then
			if leftA == leftB then
				local spellIDA, spellIDB = assignmentFrames[a].spellID, assignmentFrames[b].spellID
				if spellIDA == spellIDB then
					return a < b
				end
				return spellIDA < spellIDB
			end
			return leftA < leftB
		end
		return a < b
	end)
end

-- Updates the position of the horizontal scroll bar thumb.
---@param scrollBarWidth number
---@param thumb Button
---@param scrollFrameWidth number
---@param timelineWidth number
---@param horizontalScroll number
function EPTimelineUtilities.UpdateHorizontalScrollBarThumb(
	scrollBarWidth,
	thumb,
	scrollFrameWidth,
	timelineWidth,
	horizontalScroll
)
	-- Sometimes horizontal scroll bar width can be zero when resizing, but is same as timeline width
	if scrollBarWidth == 0 then
		scrollBarWidth = timelineWidth
	end

	-- Calculate the scroll bar thumb size based on the visible area
	local thumbWidth = (scrollFrameWidth / timelineWidth) * (scrollBarWidth - (2 * k.ThumbPadding.x))
	thumbWidth = Clamp(thumbWidth, 20, scrollFrameWidth - (2 * k.ThumbPadding.x))
	thumb:SetWidth(thumbWidth)

	local maxScroll = timelineWidth - scrollFrameWidth
	local maxThumbPosition = scrollBarWidth - thumbWidth - (2 * k.ThumbPadding.x)
	local horizontalThumbPosition
	if maxScroll > 0 then -- Prevent division by zero if maxScroll is 0
		horizontalThumbPosition = (horizontalScroll / maxScroll) * maxThumbPosition
		horizontalThumbPosition = horizontalThumbPosition + k.ThumbPadding.x
	else
		horizontalThumbPosition = k.ThumbPadding.x -- If no scrolling is possible, reset the thumb to the start
	end
	thumb:SetPoint("LEFT", horizontalThumbPosition, 0)
end

-- Updates the horizontal offset a vertical line from a timeline frame and shows it.
---@param timelineFrame Frame
---@param verticalPositionLine Texture
---@param offset? number Optional offset to add
---@param override? number Optional override offset from the timeline frame
function EPTimelineUtilities.UpdateLinePosition(timelineFrame, verticalPositionLine, offset, override)
	local newTimeOffset
	if override then
		newTimeOffset = override
	else
		newTimeOffset = (GetCursorPosition() / UIParent:GetEffectiveScale()) - (timelineFrame:GetLeft() or 0)
		if offset then
			newTimeOffset = newTimeOffset + offset
		end
	end

	verticalPositionLine:SetPoint("TOP", timelineFrame, "TOPLEFT", newTimeOffset, 0)
	verticalPositionLine:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", newTimeOffset, 0)
	verticalPositionLine:Show()
end

---@param assignmentIDOrAssignmentFrame integer|AssignmentFrame
---@param assignmentSelectionType AssignmentSelectionType
function EPTimelineUtilities.SelectAssignment(assignmentIDOrAssignmentFrame, assignmentSelectionType)
	local frame = nil
	if type(assignmentIDOrAssignmentFrame) == "table" then
		frame = assignmentIDOrAssignmentFrame
	else
		frame = EPTimelineUtilities.FindAssignmentFrame(s.AssignmentFrames, assignmentIDOrAssignmentFrame)
	end

	if frame then
		local assignmentHeight = s.Preferences.timelineRows.assignmentHeight
		if assignmentSelectionType == AssignmentSelectionType.kSelection then
			EPTimelineUtilities.SetAssignmentFrameOutline(frame, k.HighlightType.Full, assignmentHeight)
			frame.selectionType = assignmentSelectionType
		elseif assignmentSelectionType == AssignmentSelectionType.kBossAbilityHover then
			if frame.selectionType ~= AssignmentSelectionType.kSelection then
				EPTimelineUtilities.SetAssignmentFrameOutline(frame, k.HighlightType.Half, assignmentHeight)
				frame.selectionType = assignmentSelectionType
			end
		elseif assignmentSelectionType == AssignmentSelectionType.kNone then
			EPTimelineUtilities.SetAssignmentFrameOutline(frame, k.HighlightType.None, assignmentHeight)
			frame.selectionType = assignmentSelectionType
		end
	end
end

---@param assignmentID integer
---@param onlyClearIfNotSelectedByClicking boolean|nil
function EPTimelineUtilities.ClearSelectedAssignment(assignmentID, onlyClearIfNotSelectedByClicking)
	local frame = EPTimelineUtilities.FindAssignmentFrame(s.AssignmentFrames, assignmentID)
	if frame then
		if not onlyClearIfNotSelectedByClicking or frame.selectionType ~= AssignmentSelectionType.kSelection then
			EPTimelineUtilities.SetAssignmentFrameOutline(
				frame,
				k.HighlightType.None,
				s.Preferences.timelineRows.assignmentHeight
			)
			frame.selectionType = AssignmentSelectionType.kNone
		end
	end
end

function EPTimelineUtilities.ClearSelectedAssignments()
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight
	for _, frame in ipairs(s.AssignmentFrames) do
		EPTimelineUtilities.SetAssignmentFrameOutline(frame, k.HighlightType.None, assignmentHeight)
		frame.selectionType = AssignmentSelectionType.kNone
	end
end

-- Returns tables of selected assignments and optionally resets assignment frames.
---@param clear boolean If true, assignment frames are reset
---@return table<AssignmentSelectionType, table<integer, integer>> -- Unique assignment IDs of the selected frames
function EPTimelineUtilities.GetSelectedAssignments(clear)
	local selection, bossAbilityHover = {}, {}
	local SetAssignmentFrameOutline = EPTimelineUtilities.SetAssignmentFrameOutline
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight
	for _, frame in ipairs(s.AssignmentFrames) do
		if frame.selectionType == AssignmentSelectionType.kSelection then
			selection[#selection + 1] = frame.uniqueAssignmentID
		elseif frame.selectionType == AssignmentSelectionType.kBossAbilityHover then
			bossAbilityHover[#bossAbilityHover + 1] = frame.uniqueAssignmentID
		end
		if clear then
			frame:Hide()
			frame:SetWidth(assignmentHeight)
			frame.invalidTexture:Hide()
			frame.cooldownFrame:Hide()
			frame.uniqueAssignmentID = 0
			SetAssignmentFrameOutline(frame, k.HighlightType.None, assignmentHeight)
			frame.selectionType = AssignmentSelectionType.kNone
			frame.timelineAssignment = nil
			if frame.chargeMarker then
				frame.chargeMarker:ClearAllPoints()
				frame.chargeMarker:Hide()
			end
		end
	end
	return {
		[AssignmentSelectionType.kSelection] = selection,
		[AssignmentSelectionType.kBossAbilityHover] = bossAbilityHover,
	}
end

do
	---@param bossAbilityFrames table<integer, BossAbilityFrame>
	---@param spellID integer
	---@param spellCount integer
	---@return BossAbilityFrame|nil
	local function FindBossAbilityFrame(bossAbilityFrames, spellID, spellCount)
		for _, frame in ipairs(bossAbilityFrames) do
			if frame.abilityInstance then
				if
					frame.abilityInstance.bossAbilitySpellID == spellID
					and frame.abilityInstance.spellCount == spellCount
				then
					return frame
				end
			end
		end
		return nil
	end

	---@param spellID integer
	---@param spellCount integer
	---@param selectionType BossAbilitySelectionType
	function EPTimelineUtilities.SelectBossAbility(spellID, spellCount, selectionType)
		local frame = FindBossAbilityFrame(s.BossAbilityFrames, spellID, spellCount)
		if frame then
			frame:SetBackdropBorderColor(unpack(k.AssignmentSelectOutlineColor))
			if selectionType == BossAbilitySelectionType.kSelection then
				local y = select(5, frame:GetPointByName("TOPLEFT"))
				s.BossAbilityTimeline:ScrollVerticallyIfNotVisible(y, y - frame:GetHeight())
			end
			frame.selectionType = selectionType
		end
	end

	---@param spellID integer
	---@param spellCount integer
	---@param onlyClearIfNotSelectedByClicking boolean|nil
	function EPTimelineUtilities.ClearSelectedBossAbility(spellID, spellCount, onlyClearIfNotSelectedByClicking)
		local frame = FindBossAbilityFrame(s.BossAbilityFrames, spellID, spellCount)
		if frame then
			if not onlyClearIfNotSelectedByClicking or frame.selectionType ~= AssignmentSelectionType.kSelection then
				frame:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))
				frame.selectionType = BossAbilitySelectionType.kNone
			end
		end
	end
end

function EPTimelineUtilities.ClearSelectedBossAbilities()
	for _, frame in ipairs(s.BossAbilityFrames) do
		frame:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))
		frame.selectionType = BossAbilitySelectionType.kNone
	end
end

-- Updates the time of the current time label and hides time labels that overlap with it.
function EPTimelineUtilities.UpdateTimeLabels()
	local hideVerticalPositionLineAndLabels = true
	local verticalPositionLine = s.BossAbilityTimeline.verticalPositionLine
	local currentTimeLabel = s.CurrentTimeLabel
	local timelineLabels = s.TimelineLabels
	local splitterFrame = s.MainTimelineSplitterFrame
	if verticalPositionLine:IsVisible() then
		local timelineFrame = s.BossAbilityTimeline.timelineFrame
		local time = EPTimelineUtilities.ConvertTimelineOffsetToTime(verticalPositionLine, timelineFrame)
		if time then
			hideVerticalPositionLineAndLabels = false
			currentTimeLabel.frame:Show()

			time = Private.utilities.Round(time, 0)
			local minutes = floor(time / 60)
			local seconds = time % 60
			currentTimeLabel:SetText(format("%d:%02d", minutes, seconds), 2)
			currentTimeLabel:SetFrameWidthFromText()

			local lineOffsetFromTimelineFrame = verticalPositionLine:GetLeft() - timelineFrame:GetLeft()
			local labelOffsetFromTimelineFrame = lineOffsetFromTimelineFrame
				- currentTimeLabel.text:GetStringWidth() / 2.0
			currentTimeLabel:SetPoint("LEFT", splitterFrame, "LEFT", labelOffsetFromTimelineFrame, 0)

			for _, label in pairs(timelineLabels) do
				if label.wantsToShow then
					local text = currentTimeLabel.text
					local textLeft, textRight = text:GetLeft(), text:GetRight()
					local labelLeft, labelRight = label:GetLeft(), label:GetRight()
					if not (textRight <= labelLeft or textLeft >= labelRight) then
						label:Hide()
					elseif label.wantsToShow then
						label:Show()
					end
				end
			end
		end
	end
	if hideVerticalPositionLineAndLabels then
		currentTimeLabel.frame:Hide()
		for _, label in pairs(timelineLabels) do
			if label.wantsToShow then
				label:Show()
			end
		end
	end
end

-- Updates the tick mark positions for the boss ability timeline and assignments timeline.
function EPTimelineUtilities.UpdateTickMarks()
	local assignmentTicks = s.AssignmentTimeline:GetTicks()
	local bossTicks = s.BossAbilityTimeline:GetTicks()
	for _, tick in pairs(bossTicks) do
		tick:Hide()
	end
	for _, tick in pairs(assignmentTicks) do
		tick:Hide()
	end
	for _, label in pairs(s.TimelineLabels) do
		label:Hide()
		label.wantsToShow = false
	end
	if s.TotalTimelineDuration <= 0.0 then
		return
	end

	local assignmentTimelineFrame = s.AssignmentTimeline.timelineFrame
	local bossTimelineFrame = s.BossAbilityTimeline.timelineFrame
	local timelineWidth = bossTimelineFrame:GetWidth()
	local padding = k.TimelineLinePadding
	local timelineWidthWithoutPadding = timelineWidth - (2 * padding.x)

	local tickInterval = k.TickIntervals[1]
	for i = 1, #k.TickIntervals do
		local interval = k.TickIntervals[i]
		if (interval / s.TotalTimelineDuration) * timelineWidthWithoutPadding >= s.MinTickInterval then
			tickInterval = interval
			break
		end
	end

	local Round = Private.utilities.Round
	for i = 0, s.TotalTimelineDuration, tickInterval do
		local position = (i / s.TotalTimelineDuration) * timelineWidthWithoutPadding
		local tickPosition = position + padding.x
		local tickWidth = (i % 2 == 0) and k.DefaultTickWidth * 0.5 or k.DefaultTickWidth
		local bossTick = bossTicks[i]
		if not bossTick then
			bossTick = bossTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
			bossTick:SetColorTexture(unpack(k.TickColor))
			bossTicks[i] = bossTick
		end
		bossTick:SetWidth(tickWidth)
		bossTick:SetPoint("TOP", bossTimelineFrame, "TOPLEFT", tickPosition, 0)
		bossTick:SetPoint("BOTTOM", bossTimelineFrame, "BOTTOMLEFT", tickPosition, 0)
		bossTick:Show()

		local assignmentTick = assignmentTicks[i]
		if not assignmentTick then
			assignmentTick = assignmentTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
			assignmentTick:SetColorTexture(unpack(k.TickColor))
			assignmentTicks[i] = assignmentTick
		end

		assignmentTick:SetWidth(tickWidth)
		assignmentTick:SetHeight(s.Preferences.timelineRows.assignmentHeight + k.PaddingBetweenAssignments)
		assignmentTick:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT", tickPosition, 0)
		assignmentTick:SetPoint("BOTTOM", assignmentTimelineFrame, "BOTTOMLEFT", tickPosition, 0)
		assignmentTick:Show()

		local label = s.TimelineLabels[i]
		if not label then
			---@type EPTimeLabel
			label = s.MainTimelineSplitterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			s.TimelineLabels[i] = label
			if k.FontPath then
				label:SetFont(k.FontPath, k.TickFontSize)
				label:SetTextColor(unpack(k.TickLabelColor))
			end
		end
		local time = Round(i, 0)
		local minutes = floor(time / 60)
		local seconds = time % 60

		label:SetText(format("%d:%02d", minutes, seconds))
		label:SetPoint("CENTER", s.MainTimelineSplitterFrame, "LEFT", tickPosition, 0)
		label:Show()
		label.wantsToShow = true
	end
end

---@param assigneeSpellSets table<integer, AssigneeSpellSet>
---@param currentY number
---@return string? assignee
---@return integer? spellID
function EPTimelineUtilities.FindAssigneeAndSpellFromDistanceFromTop(assigneeSpellSets, currentY)
	local relativeDistanceFromTop = abs(s.AssignmentTimeline.timelineFrame:GetTop() - currentY)
	local totalAssignmentHeight = 0
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight + k.PaddingBetweenAssignments
	for _, assigneeAndSpell in ipairs(assigneeSpellSets) do
		totalAssignmentHeight = totalAssignmentHeight + assignmentHeight -- Row for assignee
		if totalAssignmentHeight >= relativeDistanceFromTop then
			return assigneeAndSpell.assignee, nil
		end
		if not s.Collapsed[assigneeAndSpell.assignee] then
			for _, currentSpellID in ipairs(assigneeAndSpell.spells) do
				totalAssignmentHeight = totalAssignmentHeight + assignmentHeight -- Row for spell
				if totalAssignmentHeight >= relativeDistanceFromTop then
					return assigneeAndSpell.assignee, currentSpellID
				end
			end
		end
	end
end

---@param assignee string
---@param spellID integer
---@return integer
function EPTimelineUtilities.ComputeAssignmentRowIndex(assignee, spellID)
	local rowIndex = 0
	for _, assigneesAndSpell in ipairs(s.AssigneeSpellSets) do
		local assigneeEqual = assigneesAndSpell.assignee == assignee
		if not s.Collapsed[assigneesAndSpell.assignee] then
			for _, currentSpellID in ipairs(assigneesAndSpell.spells) do
				rowIndex = rowIndex + 1
				if assigneeEqual == true and spellID == currentSpellID then
					break
				end
			end
		end

		rowIndex = rowIndex + 1
		if assigneeEqual == true then
			break
		end
	end
	return rowIndex
end

---@param uniqueID integer
---@return integer|nil
function EPTimelineUtilities.ComputeAssignmentRowIndexFromAssignmentID(uniqueID)
	local timelineAssignment = EPTimelineUtilities.FindTimelineAssignment(uniqueID)
	if timelineAssignment then
		local rowIndex = 0
		local assignee = timelineAssignment.assignment.assignee
		local spellID = timelineAssignment.assignment.spellID
		for _, assigneesAndSpell in ipairs(s.AssigneeSpellSets) do
			local assigneeEqual = assigneesAndSpell.assignee == assignee
			if not s.Collapsed[assigneesAndSpell.assignee] then
				for _, currentSpellID in ipairs(assigneesAndSpell.spells) do
					rowIndex = rowIndex + 1
					if assigneeEqual == true and spellID == currentSpellID then
						break
					end
				end
			end

			rowIndex = rowIndex + 1
			if assigneeEqual == true then
				break
			end
		end
		return rowIndex
	end
end
