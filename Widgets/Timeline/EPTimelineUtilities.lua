local _, Namespace = ...

---@class Private
local Private = Namespace
---@class EPTimelineConstants
local k = Private.timeline.constants
---@class EPTimelineState
local s = Private.timeline.state

---@class EPTimelineUtilities
local EPTimelineUtilities = Private.timeline.utilities

local Clamp = Clamp
local GetCursorPosition = GetCursorPosition
local ipairs = ipairs
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsLeftShiftKeyDown, IsRightShiftKeyDown = IsLeftShiftKeyDown, IsRightShiftKeyDown
local sort = table.sort
local split = string.split
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

---@param bossAbilityFrames table<integer, BossAbilityFrame>
---@param spellID integer
---@param spellCount integer
---@return BossAbilityFrame|nil
function EPTimelineUtilities.FindBossAbilityFrame(bossAbilityFrames, spellID, spellCount)
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

---@param timelineAssignments table<integer, TimelineAssignment>
---@param uniqueID integer
---@return TimelineAssignment|nil,integer|nil
function EPTimelineUtilities.FindTimelineAssignment(timelineAssignments, uniqueID)
	for index, timelineAssignment in ipairs(timelineAssignments) do
		if timelineAssignment.assignment.uniqueID == uniqueID then
			return timelineAssignment, index
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
