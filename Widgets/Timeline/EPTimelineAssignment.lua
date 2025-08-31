local _, Namespace = ...

---@class Private
local Private = Namespace
---@class EPTimelineConstants
local k = Private.timeline.constants
---@class EPTimelineState
local s = Private.timeline.state

local AssignmentSelectionType = Private.constants.AssignmentSelectionType

---@class EPTimelineAssignment
local EPTimelineAssignment = Private.timeline.assignment

local ConvertTimelineOffsetToTime = Private.timeline.utilities.ConvertTimelineOffsetToTime
local ConvertTimeToTimelineOffset = Private.timeline.utilities.ConvertTimeToTimelineOffset
local FindTimelineAssignment = Private.timeline.utilities.FindTimelineAssignment
local IsValidKeyCombination = Private.timeline.utilities.IsValidKeyCombination
local SortAssignmentFrameIndices = Private.timeline.utilities.SortAssignmentFrameIndices
local UpdateHorizontalScrollBarThumb = Private.timeline.utilities.UpdateHorizontalScrollBarThumb
local UpdateLinePosition = Private.timeline.utilities.UpdateLinePosition
local SelectAssignment = Private.timeline.utilities.SelectAssignment
local ClearSelectedAssignments = Private.timeline.utilities.ClearSelectedAssignments
local GetSelectedAssignments = Private.timeline.utilities.GetSelectedAssignments
local UpdateTimeLabels = Private.timeline.utilities.UpdateTimeLabels

local abs = math.abs
local Clamp = Clamp
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local GetSpellTexture = C_Spell.GetSpellTexture
local ipairs = ipairs
local max = math.max
local next = next
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local tremove = table.remove
local type = type
local unpack = unpack
local wipe = table.wipe
local UIParent = UIParent

-- Called when an assignment has stopped being dragged. Returns true if the assignment was duplicated, or the
-- difference between the previous assignment time and the new assignment time if the assignment was only moved.
---@param assignmentFrame AssignmentFrame
---@return boolean|number
function EPTimelineAssignment.StopMovingAssignment(assignmentFrame)
	s.AssignmentIsDragging = false
	assignmentFrame:SetScript("OnUpdate", nil)

	local timelineAssignment = assignmentFrame.timelineAssignment

	assignmentFrame.timelineAssignment = nil
	s.AssignmentFrameBeingDragged = nil
	s.HorizontalCursorPositionWhenAssignmentFrameClicked = 0

	local time = ConvertTimelineOffsetToTime(assignmentFrame, s.BossAbilityTimeline.timelineFrame)

	if s.AssignmentBeingDuplicated then
		s.FakeAssignmentFrame:Hide()
		s.AssignmentBeingDuplicated = false
		if timelineAssignment then
			local spellID = timelineAssignment.assignment.spellID
			local orderTable = s.OrderedSpellIDFrameIndices[timelineAssignment.order]
			local spellIDTable = orderTable[spellID]
			for index, assignmentFrameIndex in ipairs(spellIDTable) do
				if assignmentFrameIndex == s.FakeAssignmentFrame.temporaryAssignmentFrameIndex then
					tremove(s.AssignmentFrames, assignmentFrameIndex)
					tremove(spellIDTable, index)
					if not next(orderTable[spellID]) then
						orderTable[spellID] = nil
					end
					break
				end
			end

			if time then
				s.Fire("DuplicateAssignmentEnd", timelineAssignment, time)
			end
		end
		s.FakeAssignmentFrame:SetWidth(s.Preferences.timelineRows.assignmentHeight)
		s.FakeAssignmentFrame.cooldownFrame:Hide()
		s.FakeAssignmentFrame.spellTexture:SetTexture(nil)
		s.FakeAssignmentFrame.spellID = nil
		s.FakeAssignmentFrame.uniqueAssignmentID = nil
		s.FakeAssignmentFrame.timelineAssignment = nil
		s.FakeAssignmentFrame.temporaryAssignmentFrameIndex = nil
		if s.FakeAssignmentFrame.chargeMarker then
			s.FakeAssignmentFrame.chargeMarker:Hide()
		end
		return true
	else
		if time and timelineAssignment then
			timelineAssignment.startTime = Private.utilities.Round(time, 1)
			local relativeTime = s.CalculateAssignmentTimeFromStart(timelineAssignment)
			local assignment = timelineAssignment.assignment
			---@cast assignment TimedAssignment
			local previousTime = assignment.time

			if relativeTime then
				---@cast assignment CombatLogEventAssignment
				assignment.time = relativeTime
			else
				---@cast assignment TimedAssignment
				assignment.time = timelineAssignment.startTime
			end
			return abs(previousTime - assignment.time)
		end
	end
	return 0.0
end

-- Called while an assignment is being dragged.
---@param frame AssignmentFrame
local function HandleAssignmentUpdate(frame)
	if s.IsSimulating or not s.AssignmentIsDragging then
		return
	end

	local horizontalCursorPosition = GetCursorPosition() / UIParent:GetEffectiveScale()
	local difference = horizontalCursorPosition - s.HorizontalCursorPositionWhenAssignmentFrameClicked
	if abs(difference) < 5 then -- Use a threshold of 5 pixels before changing the time
		UpdateLinePosition(
			s.AssignmentTimeline.frame,
			s.AssignmentTimeline.verticalPositionLine,
			-s.HorizontalCursorAssignmentFrameOffsetWhenClicked - difference
		)
		UpdateLinePosition(
			s.BossAbilityTimeline.frame,
			s.BossAbilityTimeline.verticalPositionLine,
			-s.HorizontalCursorAssignmentFrameOffsetWhenClicked - difference
		)
		UpdateTimeLabels()
		return
	end
	s.HorizontalCursorPositionWhenAssignmentFrameClicked = 0

	local timelineFrameLeft = s.BossAbilityTimeline.timelineFrame:GetLeft()
	local timelineFrameWidth = s.BossAbilityTimeline.timelineFrame:GetWidth()
	local minOffsetFromTimelineFrameLeft = k.TimelineLinePadding.x
	local maxOffsetFromTimelineFrameLeft = timelineFrameWidth - k.TimelineLinePadding.x

	local minTime = s.GetMinimumCombatLogEventTime(frame.timelineAssignment)
	if minTime then
		local minOffsetFromTime = ConvertTimeToTimelineOffset(minTime, timelineFrameWidth)
		minOffsetFromTimelineFrameLeft = max(minOffsetFromTime, minOffsetFromTimelineFrameLeft)
	end

	local assignmentFrameOffsetFromTimelineFrameLeft = horizontalCursorPosition
		- timelineFrameLeft
		- s.HorizontalCursorAssignmentFrameOffsetWhenClicked

	assignmentFrameOffsetFromTimelineFrameLeft = Clamp(
		assignmentFrameOffsetFromTimelineFrameLeft,
		minOffsetFromTimelineFrameLeft,
		maxOffsetFromTimelineFrameLeft
	)

	local assignmentLeft = frame:GetLeft()
	local assignmentRight = assignmentLeft + s.Preferences.timelineRows.assignmentHeight
	local horizontalScroll = s.BossAbilityTimeline.scrollFrame:GetHorizontalScroll()
	local scrollFrameWidth = s.BossAbilityTimeline.scrollFrame:GetWidth()
	local scrollFrameLeft = s.BossAbilityTimeline.scrollFrame:GetLeft()
	local scrollFrameRight = scrollFrameLeft + scrollFrameWidth
	local newHorizontalScroll = nil
	if assignmentLeft < scrollFrameLeft then
		local negativeOverflow = scrollFrameLeft - assignmentLeft
		newHorizontalScroll = horizontalScroll - negativeOverflow
	elseif assignmentRight > scrollFrameRight then
		local positiveOverflow = assignmentRight - scrollFrameRight
		newHorizontalScroll = horizontalScroll + positiveOverflow
	end

	if newHorizontalScroll then
		newHorizontalScroll = Clamp(newHorizontalScroll, 0, timelineFrameWidth - scrollFrameWidth)
		s.BossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		s.AssignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		s.MainTimelineSplitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
		UpdateHorizontalScrollBarThumb(
			s.MainTimelineHorizontalScrollBar:GetWidth(),
			s.MainTimelineThumb,
			s.BossAbilityTimeline.scrollFrame:GetWidth(),
			s.BossAbilityTimeline.timelineFrame:GetWidth(),
			newHorizontalScroll
		)
	end

	local verticalOffsetFromTimelineFrameTop = (frame.timelineAssignment.order - 1)
		* (s.Preferences.timelineRows.assignmentHeight + k.PaddingBetweenAssignments)
	frame:SetPoint("TOPLEFT", assignmentFrameOffsetFromTimelineFrameLeft, -verticalOffsetFromTimelineFrameTop)

	local frameTimelineFrameDifference = timelineFrameLeft - (s.AssignmentTimeline.frame:GetLeft() or 0)
	local overrideLineLeft = assignmentFrameOffsetFromTimelineFrameLeft + frameTimelineFrameDifference
	UpdateLinePosition(s.AssignmentTimeline.frame, s.AssignmentTimeline.verticalPositionLine, nil, overrideLineLeft)
	UpdateLinePosition(s.BossAbilityTimeline.frame, s.BossAbilityTimeline.verticalPositionLine, nil, overrideLineLeft)
	UpdateTimeLabels()

	if s.AssignmentFrameBeingDragged and s.AssignmentFrameBeingDragged.timelineAssignment then
		local time = ConvertTimelineOffsetToTime(s.AssignmentFrameBeingDragged, s.BossAbilityTimeline.timelineFrame)
		if time then
			s.AssignmentFrameBeingDragged.timelineAssignment.startTime = time
			local order = s.AssignmentFrameBeingDragged.timelineAssignment.order
			local spellIDAssignmentFrameIndices = s.OrderedSpellIDFrameIndices[order]

			local sortedAssignmentFrameIndices = {} ---@type table<integer,integer>
			for _, assignmentFrameIndices in pairs(spellIDAssignmentFrameIndices) do
				for _, assignmentFrameIndex in ipairs(assignmentFrameIndices) do
					sortedAssignmentFrameIndices[#sortedAssignmentFrameIndices + 1] = assignmentFrameIndex
				end
			end
			local assignmentFrames = s.AssignmentFrames
			-- Need to sort by offset due to the fake assignment frame
			SortAssignmentFrameIndices(assignmentFrames, sortedAssignmentFrameIndices)

			local spellID = s.AssignmentFrameBeingDragged.timelineAssignment.assignment.spellID
			local matchingSpellIDAssignmentFrameIndices = {} ---@type table<integer, integer>
			local matchingTimelineAssignments = {} ---@type table<integer, TimelineAssignment>

			-- Only compute charge states for matching spellIDs
			for _, index in ipairs(sortedAssignmentFrameIndices) do
				if assignmentFrames[index].spellID == spellID then
					local newIndex = #matchingSpellIDAssignmentFrameIndices + 1
					matchingSpellIDAssignmentFrameIndices[newIndex] = index
					matchingTimelineAssignments[newIndex] = assignmentFrames[index].timelineAssignment
				end
			end
			s.ComputeChargeStates(matchingTimelineAssignments)

			local showSpellCooldownDuration = s.Preferences.showSpellCooldownDuration
			local collapsed = s.Collapsed
			for _, assignmentFrameIndex in ipairs(matchingSpellIDAssignmentFrameIndices) do
				local timelineAssignment = assignmentFrames[assignmentFrameIndex].timelineAssignment
				if timelineAssignment then
					local assignee = timelineAssignment.assignment.assignee
					local showCooldown = showSpellCooldownDuration and not collapsed[assignee]
					local cooldown = showCooldown and timelineAssignment.effectiveCooldownDuration or nil
					EPTimelineAssignment.DrawAssignment(
						timelineAssignment.startTime,
						timelineAssignment.assignment.spellID,
						assignmentFrameIndex,
						timelineAssignment.assignment.uniqueID,
						timelineAssignment.order,
						cooldown,
						timelineAssignment.relativeChargeRestoreTime,
						timelineAssignment.invalidChargeCast
					)
				end
			end

			local timelineFrame = s.AssignmentTimeline.timelineFrame
			local minFrameLevel = timelineFrame:GetFrameLevel() + 1
			local left = (-s.Preferences.timelineRows.assignmentHeight * order)

			for _, index in ipairs(sortedAssignmentFrameIndices) do
				local assignmentFrame = assignmentFrames[index]
				assignmentFrame:SetFrameLevel(minFrameLevel)
				assignmentFrame.cooldownParent:SetPoint("LEFT", left, 0)
				minFrameLevel = minFrameLevel + 1
			end
		end
	end
end

---@param frame AssignmentFrame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentMouseDown(frame, mouseButton)
	if s.IsSimulating then
		return
	end

	local isValidEdit = IsValidKeyCombination(s.Preferences.keyBindings.editAssignment, mouseButton)
	local isValidDuplicate = IsValidKeyCombination(s.Preferences.keyBindings.duplicateAssignment, mouseButton)

	if not isValidEdit and not isValidDuplicate then
		return
	end

	s.HorizontalCursorPositionWhenAssignmentFrameClicked = GetCursorPosition() / UIParent:GetEffectiveScale()
	s.HorizontalCursorAssignmentFrameOffsetWhenClicked = s.HorizontalCursorPositionWhenAssignmentFrameClicked
		- frame:GetLeft()

	ClearSelectedAssignments()
	s.AssignmentIsDragging = true
	local timelineAssignment, index = FindTimelineAssignment(frame.uniqueAssignmentID)

	if isValidDuplicate then
		s.AssignmentBeingDuplicated = true
		if timelineAssignment and index then
			local spellID = timelineAssignment.assignment.spellID
			local orderTable = s.OrderedSpellIDFrameIndices[timelineAssignment.order]
			local spellIDTable = orderTable[spellID]

			local newTimelineAssignment = {}
			s.Fire("DuplicateAssignmentStart", timelineAssignment, newTimelineAssignment)

			for spellIDTablePositionIndex, assignmentFrameIndex in ipairs(spellIDTable) do
				if assignmentFrameIndex == index then
					local newIndex = #s.AssignmentFrames + 1
					s.FakeAssignmentFrame.temporaryAssignmentFrameIndex = newIndex
					s.FakeAssignmentFrame.timelineAssignment = newTimelineAssignment
					s.AssignmentFrames[newIndex] = s.FakeAssignmentFrame
					tinsert(spellIDTable, spellIDTablePositionIndex, newIndex)
					break
				end
			end

			local fakeAssignmentFrame = s.FakeAssignmentFrame
			if fakeAssignmentFrame then
				fakeAssignmentFrame:Hide()
				fakeAssignmentFrame.spellID = frame.spellID
				fakeAssignmentFrame.uniqueAssignmentID = frame.uniqueAssignmentID
				fakeAssignmentFrame:SetPoint(frame:GetPointByName("TOPLEFT"))
				fakeAssignmentFrame:SetSize(frame:GetSize())
				fakeAssignmentFrame.spellTexture:SetSize(frame.spellTexture:GetSize())
				fakeAssignmentFrame.spellTexture:SetTexture(frame.spellTexture:GetTexture())

				if frame.cooldownFrame:IsShown() then
					fakeAssignmentFrame.cooldownFrame:SetWidth(frame.cooldownFrame:GetWidth())
					fakeAssignmentFrame.cooldownFrame:Show()
					local left = -s.Preferences.timelineRows.assignmentHeight * timelineAssignment.order
					fakeAssignmentFrame.cooldownParent:SetPoint("LEFT", left, 0)
				else
					fakeAssignmentFrame.cooldownFrame:Hide()
				end
				if frame.invalidTexture:IsShown() then
					fakeAssignmentFrame.invalidTexture:Show()
				else
					fakeAssignmentFrame.invalidTexture:Hide()
				end
				fakeAssignmentFrame:SetFrameLevel(frame:GetFrameLevel() - 1)
				fakeAssignmentFrame:Show()
			end
		end
	end
	SelectAssignment(frame, AssignmentSelectionType.kSelection)
	frame.timelineAssignment = timelineAssignment
	s.AssignmentFrameBeingDragged = frame
	frame:SetScript("OnUpdate", function(f)
		HandleAssignmentUpdate(f)
	end)
end

---@param frame AssignmentFrame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentMouseUp(frame, mouseButton)
	if s.IsSimulating then
		return
	end
	local duplicatedOrAssignmentTimeDifference = nil
	if s.AssignmentIsDragging then
		duplicatedOrAssignmentTimeDifference = EPTimelineAssignment.StopMovingAssignment(frame)
		if type(duplicatedOrAssignmentTimeDifference) == "boolean" and duplicatedOrAssignmentTimeDifference == true then
			s.BossAbilityTimeline.verticalPositionLine:Hide()
			s.AssignmentTimeline.verticalPositionLine:Hide()
			UpdateTimeLabels()
			return
		end
	end

	if IsValidKeyCombination(s.Preferences.keyBindings.editAssignment, mouseButton) then
		if frame.uniqueAssignmentID then
			s.Fire("AssignmentClicked", frame.uniqueAssignmentID, duplicatedOrAssignmentTimeDifference)
		end
	end

	s.BossAbilityTimeline.verticalPositionLine:Hide()
	s.AssignmentTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels()
end

---@param spellID integer
---@param offsetX number
---@param offsetY number
---@return AssignmentFrame
function EPTimelineAssignment.CreateAssignmentFrame(spellID, offsetX, offsetY)
	local timelineFrame = s.AssignmentTimeline.timelineFrame
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight
	local assignment = CreateFrame("Frame", nil, timelineFrame, "BackdropTemplate")
	assignment:SetBackdrop({
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 2,
	})
	assignment:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))
	assignment:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignment:SetSize(assignmentHeight, assignmentHeight)

	local cooldownFrame = CreateFrame("Frame", nil, assignment)
	cooldownFrame:SetPoint("LEFT", assignment, "RIGHT")
	cooldownFrame:SetHeight(assignmentHeight + 0.01)
	cooldownFrame:SetClipsChildren(true)
	cooldownFrame:EnableMouse(false)

	local spellTexture = assignment:CreateTexture(nil, "OVERLAY", nil, k.AssignmentTextureSubLevel)
	spellTexture:SetPoint("CENTER")
	spellTexture:SetSize(assignmentHeight - 2, assignmentHeight - 2)
	spellTexture:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")
	spellTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cooldownParent = s.AssignmentTimeline.frame:CreateTexture(nil, "BACKGROUND")
	cooldownParent:SetPoint("TOPRIGHT", cooldownFrame, "TOPRIGHT")
	cooldownParent:SetPoint("BOTTOMRIGHT", cooldownFrame, "BOTTOMRIGHT")
	cooldownParent:SetAlpha(0)
	cooldownParent:EnableMouse(false)

	local cooldownBackground = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	cooldownBackground:SetColorTexture(unpack(k.CooldownBackgroundColor))
	cooldownBackground:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT")
	cooldownBackground:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT")
	cooldownBackground:EnableMouse(false)

	local cooldownTexture = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -1)
	cooldownTexture:SetTexture(k.CooldownTextureFile, "REPEAT", "REPEAT")
	cooldownTexture:SetSnapToPixelGrid(false)
	cooldownTexture:SetTexelSnappingBias(0)
	cooldownTexture:SetHorizTile(true)
	cooldownTexture:SetVertTile(true)
	cooldownTexture:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT", k.CooldownPadding, -k.CooldownPadding)
	cooldownTexture:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT", -k.CooldownPadding, k.CooldownPadding)
	cooldownTexture:SetAlpha(k.CooldownTextureAlpha)
	cooldownTexture:EnableMouse(false)

	local invalidTexture = assignment:CreateTexture(nil, "OVERLAY", nil, k.AssignmentTextureSubLevel + 1)
	invalidTexture:SetAllPoints(spellTexture)
	invalidTexture:SetColorTexture(unpack(k.InvalidTextureColor))
	invalidTexture:Hide()

	assignment.spellTexture = spellTexture
	assignment.invalidTexture = invalidTexture
	assignment.cooldownBackground = cooldownBackground
	assignment.cooldownTexture = cooldownTexture
	assignment.assignmentFrame = timelineFrame
	assignment.timelineAssignment = nil
	assignment.spellID = spellID
	assignment.cooldownParent = cooldownParent
	assignment.cooldownFrame = cooldownFrame
	assignment.selectionType = AssignmentSelectionType.kNone

	assignment:SetScript("OnMouseDown", HandleAssignmentMouseDown)
	assignment:SetScript("OnMouseUp", HandleAssignmentMouseUp)

	return assignment --[[@as AssignmentFrame]]
end

-- Helper function to draw a spell icon for an assignment.
---@param startTime number absolute start time of the assignment
---@param spellID integer spellID of the spell being assigned
---@param index integer index of the AssignmentFrame to use to display the assignment
---@param uniqueID integer unique index of the assignment
---@param order number the relative order of the assignee of the assignment
---@param cooldownDuration number|nil
---@param relativeChargeRestoreTime number|nil
---@param invalidChargeCast boolean|nil
function EPTimelineAssignment.DrawAssignment(
	startTime,
	spellID,
	index,
	uniqueID,
	order,
	cooldownDuration,
	relativeChargeRestoreTime,
	invalidChargeCast
)
	if s.TotalTimelineDuration <= 0.0 then
		return
	end

	local padding = k.TimelineLinePadding
	local timelineFrame = s.AssignmentTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight

	local timelineStartPosition = (startTime / s.TotalTimelineDuration) * timelineWidth
	local offsetX = timelineStartPosition + k.TimelineLinePadding.x
	local offsetY = (order - 1) * (assignmentHeight + k.PaddingBetweenAssignments)

	local assignmentFrame = s.AssignmentFrames[index]
	if not assignmentFrame then
		assignmentFrame = EPTimelineAssignment.CreateAssignmentFrame(spellID, offsetX, offsetY)
		s.AssignmentFrames[index] = assignmentFrame
	end

	assignmentFrame.spellID = spellID
	assignmentFrame.uniqueAssignmentID = uniqueID

	assignmentFrame:SetHeight(assignmentHeight)
	assignmentFrame:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignmentFrame:Show()

	local hideMarker = true
	if spellID == k.InvalidAssignmentSpellID then
		assignmentFrame.spellTexture:SetTexture(k.UnknownIcon)
	elseif spellID == k.TextAssignmentSpellID then
		assignmentFrame.spellTexture:SetTexture(k.TextAssignmentTexture)
	else
		local iconID, _ = GetSpellTexture(spellID)
		assignmentFrame.spellTexture:SetTexture(iconID)
		if cooldownDuration then
			local cooldownEndPosition = (startTime + cooldownDuration) / s.TotalTimelineDuration * timelineWidth
			local cooldownWidth = (cooldownEndPosition - timelineStartPosition) - k.CooldownWidthTolerance
			local visibleCooldownWidth = cooldownWidth - assignmentHeight
			local cooldownFrame = assignmentFrame.cooldownFrame
			if visibleCooldownWidth > 0 then
				cooldownFrame:SetSize(visibleCooldownWidth, assignmentHeight + 0.01)
				cooldownFrame:Show()
			else
				cooldownFrame:SetWidth(0)
				cooldownFrame:Hide()
			end

			if relativeChargeRestoreTime then
				local chargeMarker = assignmentFrame.chargeMarker
				if not chargeMarker then
					chargeMarker =
						s.MainTimelineChargeFrame:CreateTexture(nil, "OVERLAY", nil, k.AssignmentTextureSubLevel + 1)
					chargeMarker:SetTexture(k.PhaseIndicatorTexture, "REPEAT", "REPEAT")
					chargeMarker:SetVertexColor(unpack(k.SpellChargeRestorationColor))
					chargeMarker:SetWidth(2)
					assignmentFrame.chargeMarker = chargeMarker
				end
				local left = (relativeChargeRestoreTime / s.TotalTimelineDuration) * timelineWidth
				chargeMarker:SetHeight(assignmentHeight - 2)
				chargeMarker:SetTexCoord(0.1, 0.4, 0, 4.5)
				chargeMarker:SetPoint("LEFT", assignmentFrame, "LEFT", left - 1, 0)
				chargeMarker:Show()
				hideMarker = false
			end
		end
	end
	if assignmentFrame.chargeMarker and hideMarker then
		assignmentFrame.chargeMarker:Hide()
	end
	if invalidChargeCast == true then
		assignmentFrame.invalidTexture:Show()
	else
		assignmentFrame.invalidTexture:Hide()
	end
end

-- Updates the rendering of assignments on the timeline.
function EPTimelineAssignment.UpdateAssignmentFrames()
	-- Clears/resets assignment frames
	local selected = GetSelectedAssignments(true)

	wipe(s.OrderedSpellIDFrameIndices)
	local orderedFrameIndices = {}
	local showSpellCooldownDuration = s.Preferences.showSpellCooldownDuration

	local DrawAssignment = EPTimelineAssignment.DrawAssignment
	for index, timelineAssignment in ipairs(s.TimelineAssignments) do
		local order = timelineAssignment.order
		local assignment = timelineAssignment.assignment
		local spellID = assignment.spellID
		if not s.OrderedSpellIDFrameIndices[order] then
			s.OrderedSpellIDFrameIndices[order] = {}
			orderedFrameIndices[order] = {}
		end
		if not s.OrderedSpellIDFrameIndices[order][spellID] then
			s.OrderedSpellIDFrameIndices[order][spellID] = {}
		end
		local showCooldown = showSpellCooldownDuration and not s.Collapsed[assignment.assignee]
		local cooldown = showCooldown and timelineAssignment.effectiveCooldownDuration or nil
		DrawAssignment(
			timelineAssignment.startTime,
			spellID,
			index,
			assignment.uniqueID,
			order,
			cooldown,
			timelineAssignment.relativeChargeRestoreTime,
			timelineAssignment.invalidChargeCast
		)
		s.AssignmentFrames[index].timelineAssignment = timelineAssignment
		s.OrderedSpellIDFrameIndices[order][spellID][#s.OrderedSpellIDFrameIndices[order][spellID] + 1] = index
		orderedFrameIndices[order][#orderedFrameIndices[order] + 1] = index
	end

	local assignmentFrames = s.AssignmentFrames
	local timelineFrame = s.AssignmentTimeline.timelineFrame
	local timelineAssignments = s.TimelineAssignments
	local timelineFrameLevel = timelineFrame:GetFrameLevel()
	local assignmentHeight = s.Preferences.timelineRows.assignmentHeight

	local maxFrameLevel = 0
	for order, assignmentFrameIndices in pairs(orderedFrameIndices) do
		sort(assignmentFrameIndices, function(a, b)
			---@diagnostic disable-next-line: need-check-nil
			return timelineAssignments[a].startTime < timelineAssignments[b].startTime
		end)
		local minFrameLevel = timelineFrameLevel + 1
		local left = (-assignmentHeight * order)
		for _, index in ipairs(assignmentFrameIndices) do
			local assignmentFrame = assignmentFrames[index]
			assignmentFrame:SetFrameLevel(minFrameLevel)
			assignmentFrame.cooldownParent:SetPoint("LEFT", left, 0)
			minFrameLevel = minFrameLevel + 1
		end
		maxFrameLevel = max(maxFrameLevel, minFrameLevel)
	end

	s.MainTimelineChargeFrame:SetFrameLevel(maxFrameLevel)

	for assignmentSelectionType, uniqueAssignmentIDs in pairs(selected) do
		for _, uniqueAssignmentID in ipairs(uniqueAssignmentIDs) do
			SelectAssignment(uniqueAssignmentID, assignmentSelectionType)
		end
	end
end
