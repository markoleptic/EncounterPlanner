local _, Namespace = ...

---@class Private
local Private = Namespace

local constants = Private.constants
local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType

local Type = "EPTimeline"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent

local abs = math.abs
local ceil, floor = math.ceil, math.floor
local Clamp = Clamp
local CreateFrame = CreateFrame
local format = string.format
local GetCursorPosition = GetCursorPosition
local GetSpellTexture = C_Spell.GetSpellTexture
local GetTime = GetTime
local ipairs = ipairs
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsLeftShiftKeyDown, IsRightShiftKeyDown = IsLeftShiftKeyDown, IsRightShiftKeyDown
local max, min = math.max, math.min
local next = next
local pairs = pairs
local select = select
local sort = table.sort
local split = string.split
local tinsert = table.insert
local tremove = table.remove
local type = type
local unpack = unpack
local wipe = table.wipe

local frameWidth = 900
local frameHeight = 400
local paddingBetweenTimelines = constants.timeline.kPaddingBetweenTimelines
local paddingBetweenBossAbilityBars = 2
local paddingBetweenTimelineAndScrollBar = constants.timeline.kPaddingBetweenTimelineAndScrollBar
local assignmentTextureSubLevel = 0
local cooldownWidthTolerance = 0.01
local bossAbilityTextureSubLevel = 0
local paddingBetweenAssignments = 2
local horizontalScrollBarHeight = constants.timeline.kHorizontalScrollBarHeight
local minimumSpacingBetweenLabels = 4
local minimumNumberOfAssignmentRows = 2
local minimumNumberOfBossAbilityRows = 2
local minimumBossAbilityWidth = 10
local defaultTickWidth = 2
local minZoomFactor = 1
local maxZoomFactor = 10
local zoomStep = 0.05
local fontPath = LSM:Fetch("font", "PT Sans Narrow")
local tickColor = { 1, 1, 1, 0.75 }
local tickLabelColor = { 1, 1, 1, 1 }
local assignmentOutlineColor = { 0.25, 0.25, 0.25, 1 }
local phaseIndicatorColor = { 1, 0.82, 0, 1 }
local phaseIndicatorWidth = 2
local phaseIndicatorFontSize = 12
local phaseIndicatorTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-checkered-50]]
local assignmentSelectOutlineColor = { 1, 0.82, 0, 1 }
local invalidTextureColor = { 0.8, 0.1, 0.1, 0.4 }
local tickFontSize = 12
local scrollBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local scrollThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 }
local tickIntervals = { 5, 10, 30, 60, 90 }
local colors = {
	{ 0.122, 0.467, 0.706, 1 },
	{ 1.0, 0.498, 0.055, 1 },
	{ 0.173, 0.627, 0.173, 1 },
	{ 0.839, 0.153, 0.157, 1 },
	{ 0.58, 0.404, 0.741, 1 },
	{ 0.549, 0.337, 0.294, 1 },
	{ 0.89, 0.467, 0.761, 1 },
	{ 0.498, 0.498, 0.498, 1 },
	{ 0.737, 0.741, 0.133, 1 },
	{ 0.09, 0.745, 0.812, 1 },
}
local cooldownTextureFile = [[Interface\AddOns\EncounterPlanner\Media\DiagonalLine]]
local cooldownPadding = 1
local cooldownBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local spellChargeRestorationColor = { 0.4, 1, 0.8, 1 }
local cooldownTextureAlpha = 0.5

local assignmentIsDragging = false
local assignmentBeingDuplicated = false
local assignmentFrameBeingDragged = nil ---@type AssignmentFrame|nil
local horizontalCursorAssignmentFrameOffsetWhenClicked = 0
local horizontalCursorPositionWhenAssignmentFrameClicked = 0
local thumbPadding = { x = 2, y = 2 }
local timelineLinePadding = { x = 25, y = 25 }
local thumbOffsetWhenThumbClicked = 0.0
local scrollBarWidthWhenThumbClicked = 0.0
local thumbWidthWhenThumbClicked = 0.0
local thumbIsDragging = false
local timelineFrameOffsetWhenDragStarted = 0.0
local timelineFrameIsDragging = false
local totalTimelineDuration = 0.0
local selectedAssignmentIDsFromBossAbilityFrameEnter = {}
local isSimulating = false
local simulationStartTime = 0.0

local throttleInterval = 0.015 -- Minimum time between executions, in seconds
local lastExecutionTime = 0.0

---@class BossPhaseIndicatorTexture : Texture
---@field label FontString

---@class AssignmentFrame : Frame, BackdropTemplate
---@field spellTexture Texture
---@field invalidTexture Texture
---@field cooldownFrame Frame
---@field cooldownParent Texture
---@field cooldownBackground Texture
---@field cooldownTexture Texture
---@field assignmentFrame Frame
---@field timelineAssignment TimelineAssignment|nil
---@field spellID integer
---@field selectionType AssignmentSelectionType
---@field uniqueAssignmentID integer
---@field chargeMarker Texture|nil

---@class BossAbilityFrame : Frame, BackdropTemplate
---@field assignmentFrame table|Frame
---@field spellTexture Texture
---@field abilityInstance BossAbilityInstance
---@field selectionType BossAbilitySelectionType

---@class FakeAssignmentFrame : AssignmentFrame
---@field temporaryAssignmentFrameIndex integer

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
---@field assigneesAndSpells table<integer, {assignee:string, spellID:integer|nil}>
---@field assignmentFrames table<integer, AssignmentFrame>
---@field orderedWithSpellIDAssignmentFrameIndices table<integer, table<integer, table<integer, integer>>>
---@field fakeAssignmentFrame FakeAssignmentFrame
---@field bossAbilityInstances table<integer, BossAbilityInstance>
---@field bossAbilityVisibility table<integer, boolean>
---@field bossAbilityOrder table<integer, integer>
---@field bossAbilityFrames table<integer, BossAbilityFrame>
---@field bossPhaseIndicators table<integer, table<1|2, BossPhaseIndicatorTexture>>
---@field bossPhaseOrder table<integer, integer>
---@field bossPhases table<integer, BossPhase>
---@field collapsed table<string, boolean>
---@field timelineAssignments table<integer, TimelineAssignment>
---@field allowHeightResizing boolean
---@field bossAbilityDimensions {min: integer, max:integer, step:number}
---@field assignmentDimensions {min: integer, max:integer, step:number}
---@field preferences Preferences
---@field zoomFactor number
---@field CalculateAssignmentTimeFromStart fun(assignment: TimelineAssignment): number|nil
---@field GetMinimumCombatLogEventTime fun(assignment: TimelineAssignment): number|nil
---@field ComputeChargeStates fun(timelineAssignments: table<integer, TimelineAssignment>)
---@field minTickInterval number

---@enum HighlightType
local HighlightType = {
	None = {},
	Full = {},
	Half = {},
}

local function ResetLocalVariables()
	assignmentIsDragging = false
	assignmentBeingDuplicated = false
	assignmentFrameBeingDragged = nil
	horizontalCursorAssignmentFrameOffsetWhenClicked = 0
	horizontalCursorPositionWhenAssignmentFrameClicked = 0
	thumbPadding = { x = 2, y = 2 }
	timelineLinePadding = { x = 25, y = 25 }
	thumbOffsetWhenThumbClicked = 0.0
	scrollBarWidthWhenThumbClicked = 0.0
	thumbWidthWhenThumbClicked = 0.0
	thumbIsDragging = false
	timelineFrameOffsetWhenDragStarted = 0
	timelineFrameIsDragging = false
	totalTimelineDuration = 0.0
	lastExecutionTime = 0.0
	selectedAssignmentIDsFromBossAbilityFrameEnter = {}
	isSimulating = false
	simulationStartTime = 0.0
end

---@param value number
---@param precision integer
---@return number
local function Round(value, precision)
	local factor = 10 ^ precision
	if value > 0 then
		return floor(value * factor + 0.5) / factor
	else
		return ceil(value * factor - 0.5) / factor
	end
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

---@param frame Frame|Texture
---@param timelineFrame Frame
---@return number|nil
local function ConvertTimelineOffsetToTime(frame, timelineFrame)
	local offset = (frame:GetLeft() or 0) - (timelineFrame:GetLeft() or 0)
	local padding = timelineLinePadding.x
	local time = (offset - padding) * totalTimelineDuration / (timelineFrame:GetWidth() - padding * 2)
	if time < 0 or time > totalTimelineDuration then
		return nil
	end
	return time
end

---@param time number
---@param timelineFrameWidth number
---@return number
local function ConvertTimeToTimelineOffset(time, timelineFrameWidth)
	local timelineWidth = timelineFrameWidth - 2 * timelineLinePadding.x
	local timelineStartPosition = (time / totalTimelineDuration) * timelineWidth
	return timelineStartPosition + timelineLinePadding.x
end

---@param timelineAssignments table<integer, TimelineAssignment>
---@param uniqueID integer
---@return TimelineAssignment|nil,integer|nil
local function FindTimelineAssignment(timelineAssignments, uniqueID)
	for index, timelineAssignment in ipairs(timelineAssignments) do
		if timelineAssignment.assignment.uniqueID == uniqueID then
			return timelineAssignment, index
		end
	end
	return nil, nil
end

---@param assignmentFrames table<integer, AssignmentFrame>
---@param uniqueID integer
---@return AssignmentFrame|nil
local function FindAssignmentFrame(assignmentFrames, uniqueID)
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
local function FindBossAbilityFrame(bossAbilityFrames, spellID, spellCount)
	for _, frame in ipairs(bossAbilityFrames) do
		if frame.abilityInstance.bossAbilitySpellID == spellID and frame.abilityInstance.spellCount == spellCount then
			return frame
		end
	end
	return nil
end

---@param frame AssignmentFrame
---@param highlightType HighlightType
---@param height number
local function SetAssignmentFrameOutline(frame, highlightType, height)
	if highlightType == HighlightType.Full then
		frame.spellTexture:SetSize(height - 4, height - 4)
		frame:SetBackdropBorderColor(unpack(assignmentSelectOutlineColor))
	elseif highlightType == HighlightType.Half then
		frame.spellTexture:SetSize(height - 2, height - 2)
		frame:SetBackdropBorderColor(unpack(assignmentSelectOutlineColor))
	elseif highlightType == HighlightType.None then
		frame.spellTexture:SetSize(height - 2, height - 2)
		frame:SetBackdropBorderColor(unpack(assignmentOutlineColor))
	end
end

-- Updates the time of the current time label and hides time labels that overlap with it.
---@param self EPTimeline
local function UpdateTimeLabels(self)
	local verticalPositionLine = self.bossAbilityTimeline.verticalPositionLine
	local hideVerticalPositionLineAndLabels = true
	if verticalPositionLine:IsVisible() then
		local timelineFrame = self.bossAbilityTimeline.timelineFrame
		local time = ConvertTimelineOffsetToTime(verticalPositionLine, timelineFrame)
		if time then
			hideVerticalPositionLineAndLabels = false
			local currentTimeLabel = self.currentTimeLabel
			currentTimeLabel.frame:Show()

			time = Round(time, 0)
			local minutes = floor(time / 60)
			local seconds = time % 60
			currentTimeLabel:SetText(format("%d:%02d", minutes, seconds), 2)
			currentTimeLabel:SetFrameWidthFromText()

			local lineOffsetFromTimelineFrame = verticalPositionLine:GetLeft() - timelineFrame:GetLeft()
			local labelOffsetFromTimelineFrame = lineOffsetFromTimelineFrame
				- currentTimeLabel.text:GetStringWidth() / 2.0
			currentTimeLabel:SetPoint("LEFT", self.splitterFrame, "LEFT", labelOffsetFromTimelineFrame, 0)

			for _, label in pairs(self.timelineLabels) do
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
		self.currentTimeLabel.frame:Hide()
		for _, label in pairs(self.timelineLabels) do
			if label.wantsToShow then
				label:Show()
			end
		end
	end
end

-- Updates the horizontal offset a vertical line from a timeline frame and shows it.
---@param timelineFrame Frame
---@param verticalPositionLine Texture
---@param offset? number Optional offset to add
local function UpdateLinePosition(timelineFrame, verticalPositionLine, offset)
	local newTimeOffset = (GetCursorPosition() / UIParent:GetEffectiveScale()) - (timelineFrame:GetLeft() or 0)

	if offset then
		newTimeOffset = newTimeOffset + offset
	end

	verticalPositionLine:SetPoint("TOP", timelineFrame, "TOPLEFT", newTimeOffset, 0)
	verticalPositionLine:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", newTimeOffset, 0)
	verticalPositionLine:Show()
end

---@param assignmentFrames table<integer, AssignmentFrame>
---@param frameIndices table<integer, integer>
local function SortAssignmentFrameIndices(assignmentFrames, frameIndices)
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

-- Updates the tick mark positions for the boss ability timeline and assignments timeline.
---@param self EPTimeline
local function UpdateTickMarks(self)
	local assignmentTicks = self.assignmentTimeline:GetTicks()
	local bossTicks = self.bossAbilityTimeline:GetTicks()
	for _, tick in pairs(bossTicks) do
		tick:Hide()
	end
	for _, tick in pairs(assignmentTicks) do
		tick:Hide()
	end
	for _, label in pairs(self.timelineLabels) do
		label:Hide()
		label.wantsToShow = false
	end
	if totalTimelineDuration <= 0.0 then
		return
	end

	local assignmentTimelineFrame = self.assignmentTimeline.timelineFrame
	local bossTimelineFrame = self.bossAbilityTimeline.timelineFrame
	local timelineWidth = bossTimelineFrame:GetWidth()
	local padding = timelineLinePadding
	local timelineWidthWithoutPadding = timelineWidth - (2 * padding.x)

	local tickInterval = tickIntervals[1]
	for i = 1, #tickIntervals do
		local interval = tickIntervals[i]
		if (interval / totalTimelineDuration) * timelineWidthWithoutPadding >= self.minTickInterval then
			tickInterval = interval
			break
		end
	end

	for i = 0, totalTimelineDuration, tickInterval do
		local position = (i / totalTimelineDuration) * timelineWidthWithoutPadding
		local tickPosition = position + padding.x
		local tickWidth = (i % 2 == 0) and defaultTickWidth * 0.5 or defaultTickWidth
		local bossTick = bossTicks[i]
		if not bossTick then
			bossTick = bossTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
			bossTick:SetColorTexture(unpack(tickColor))
			bossTicks[i] = bossTick
		end
		bossTick:SetWidth(tickWidth)
		bossTick:SetPoint("TOP", bossTimelineFrame, "TOPLEFT", tickPosition, 0)
		bossTick:SetPoint("BOTTOM", bossTimelineFrame, "BOTTOMLEFT", tickPosition, 0)
		bossTick:Show()

		local assignmentTick = assignmentTicks[i]
		if not assignmentTick then
			assignmentTick = assignmentTimelineFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
			assignmentTick:SetColorTexture(unpack(tickColor))
			assignmentTicks[i] = assignmentTick
		end

		assignmentTick:SetWidth(tickWidth)
		assignmentTick:SetHeight(self.preferences.timelineRows.assignmentHeight + paddingBetweenAssignments)
		assignmentTick:SetPoint("TOP", assignmentTimelineFrame, "TOPLEFT", tickPosition, 0)
		assignmentTick:SetPoint("BOTTOM", assignmentTimelineFrame, "BOTTOMLEFT", tickPosition, 0)
		assignmentTick:Show()

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
		local time = Round(i, 0)
		local minutes = floor(time / 60)
		local seconds = time % 60

		label:SetText(format("%d:%02d", minutes, seconds))
		label:SetPoint("CENTER", self.splitterFrame, "LEFT", tickPosition, 0)
		label:Show()
		label.wantsToShow = true
	end
end

-- Updates the position of the horizontal scroll bar thumb.
---@param scrollBarWidth number
---@param thumb Button
---@param scrollFrameWidth number
---@param timelineWidth number
---@param horizontalScroll number
local function UpdateHorizontalScrollBarThumb(scrollBarWidth, thumb, scrollFrameWidth, timelineWidth, horizontalScroll)
	-- Sometimes horizontal scroll bar width can be zero when resizing, but is same as timeline width
	if scrollBarWidth == 0 then
		scrollBarWidth = timelineWidth
	end

	-- Calculate the scroll bar thumb size based on the visible area
	local thumbWidth = (scrollFrameWidth / timelineWidth) * (scrollBarWidth - (2 * thumbPadding.x))
	thumbWidth = Clamp(thumbWidth, 20, scrollFrameWidth - (2 * thumbPadding.x))
	thumb:SetWidth(thumbWidth)

	local maxScroll = timelineWidth - scrollFrameWidth
	local maxThumbPosition = scrollBarWidth - thumbWidth - (2 * thumbPadding.x)
	local horizontalThumbPosition
	if maxScroll > 0 then -- Prevent division by zero if maxScroll is 0
		horizontalThumbPosition = (horizontalScroll / maxScroll) * maxThumbPosition
		horizontalThumbPosition = horizontalThumbPosition + thumbPadding.x
	else
		horizontalThumbPosition = thumbPadding.x -- If no scrolling is possible, reset the thumb to the start
	end
	thumb:SetPoint("LEFT", horizontalThumbPosition, 0)
end

---@param self EPTimeline
---@return BossPhaseIndicatorTexture
local function CreatePhaseIndicatorTexture(self)
	local frame = self.bossAbilityTimeline.timelineFrame
	local level = bossAbilityTextureSubLevel - 2
	local phaseIndicator = frame:CreateTexture(nil, "BACKGROUND", nil, level) --[[@as BossPhaseIndicatorTexture]]
	phaseIndicator:SetTexture(phaseIndicatorTexture, "REPEAT", "REPEAT")
	phaseIndicator:SetVertTile(true)
	phaseIndicator:SetHorizTile(true)
	phaseIndicator:SetVertexColor(unpack(phaseIndicatorColor))
	phaseIndicator:SetWidth(phaseIndicatorWidth)
	phaseIndicator:SetTexCoord(0.1, 1.1, 0, 1)
	phaseIndicator:Hide()

	local phaseIndicatorLabel = self.phaseNameFrame:CreateFontString(nil, "OVERLAY")
	if fontPath then
		phaseIndicatorLabel:SetFont(fontPath, phaseIndicatorFontSize)
		phaseIndicatorLabel:SetTextColor(unpack(phaseIndicatorColor))
	end
	phaseIndicatorLabel:Hide()

	phaseIndicator.label = phaseIndicatorLabel
	return phaseIndicator
end

-- ---@param width number
-- ---@param height number
-- ---@param rotationInRadians number
-- ---@return number, number
-- local function CalculateRotatedOffset(width, height, rotationInRadians)
-- 	local cosRotation, sinRotation = cos(rotationInRadians), sin(rotationInRadians)
-- 	local widthRotated = width * cosRotation + height * sinRotation
-- 	local heightRotated = height * cosRotation + width * sinRotation
-- 	local additionalHorizontalOffset = height * sinRotation
-- 	local horizontalOffset = abs(width - widthRotated) / 2.0 + additionalHorizontalOffset
-- 	local verticalOffset = abs(height - heightRotated) / 2.0
-- 	return horizontalOffset, verticalOffset
-- end

---@class LastInfo
---@field left number
---@field right number
---@field shortName	string
---@field partialLeft number
---@field label FontString|nil
---@field alreadyShortened boolean|nil

---@param self EPTimeline
---@param index integer
---@param longName string
---@param shortName string
---@param offset number
---@param width number
---@param lastInfo table<integer, LastInfo>
local function DrawBossPhaseIndicator(self, phaseStart, index, longName, shortName, offset, width, lastInfo)
	local indicator = self.bossPhaseIndicators[index][phaseStart and 1 or 2]
	local timelineFrame = self.bossAbilityTimeline.timelineFrame

	local startHorizontalOffset = offset
	if phaseStart then
		startHorizontalOffset = startHorizontalOffset + phaseIndicatorWidth
	else
		startHorizontalOffset = startHorizontalOffset + width - phaseIndicatorWidth
	end

	indicator:SetPoint("TOP", timelineFrame, "TOPLEFT", startHorizontalOffset, 0)
	indicator:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", startHorizontalOffset, 0)
	indicator:Show()

	local label = indicator.label
	label:SetText(longName)
	label:SetPoint("TOP", self.phaseNameFrame, "TOP")
	label:SetPoint("BOTTOM", self.phaseNameFrame, "BOTTOM")

	local labelWidth = label:GetWidth()
	local partialLeft = startHorizontalOffset + phaseIndicatorWidth / 2.0
	local left = partialLeft - labelWidth / 2.0

	label:SetPoint("LEFT", timelineFrame, "LEFT", left, 0)
	label:Show()

	tinsert(lastInfo, {
		shortName = shortName,
		partialLeft = partialLeft,
		left = left,
		right = left + labelWidth,
		label = label,
	})
end

---@param self EPTimeline
local function ClearSelectedAssignmentsFromBossAbilityFrameEnter(self)
	for _, assignmentID in ipairs(selectedAssignmentIDsFromBossAbilityFrameEnter) do
		self:ClearSelectedAssignment(assignmentID, true)
	end
	wipe(selectedAssignmentIDsFromBossAbilityFrameEnter)
end

---@param self EPTimeline
---@param frame BossAbilityFrame
local function HandleBossAbilityBarEnter(self, frame)
	local spellID = frame.abilityInstance.bossAbilitySpellID
	local spellCount = frame.abilityInstance.spellCount
	if #selectedAssignmentIDsFromBossAbilityFrameEnter > 0 then
		ClearSelectedAssignmentsFromBossAbilityFrameEnter(self)
	end
	for _, timelineAssignment in ipairs(self.timelineAssignments) do
		local assignment = timelineAssignment.assignment
		---@cast assignment CombatLogEventAssignment
		if assignment.combatLogEventSpellID and assignment.spellCount then
			if assignment.combatLogEventSpellID == spellID and assignment.spellCount == spellCount then
				tinsert(selectedAssignmentIDsFromBossAbilityFrameEnter, assignment.uniqueID)
			end
		end
	end
	self:SelectBossAbility(spellID, spellCount, BossAbilitySelectionType.kSelection)
	for _, assignmentID in ipairs(selectedAssignmentIDsFromBossAbilityFrameEnter) do
		self:SelectAssignment(assignmentID, AssignmentSelectionType.kBossAbilityHover)
	end
end

-- Helper function to draw a boss ability timeline bar.
---@param self EPTimeline
---@param abilityInstance BossAbilityInstance
---@param hOffset number offset from the left of the timeline frame.
---@param vOffset number offset from the top of the timeline frame.
---@param width number width of bar.
---@param height number height of bar.
---@param color integer[] color of the bar.
---@param frameLevel integer Frame level to assign to the frame.
---@param index integer Index into boss ability frames.
local function DrawBossAbilityBar(self, abilityInstance, hOffset, vOffset, width, height, color, frameLevel, index)
	local timelineFrame = self.bossAbilityTimeline.timelineFrame
	local frame = self.bossAbilityFrames[index]
	if not frame then
		frame = CreateFrame("Frame", nil, timelineFrame, "BackdropTemplate") --[[@as BossAbilityFrame]]
		frame:SetBackdrop({
			edgeFile = "Interface\\BUTTONS\\White8x8",
			edgeSize = 2,
		})
		frame:SetBackdropBorderColor(unpack(assignmentOutlineColor))
		frame:SetScript("OnEnter", function(f)
			HandleBossAbilityBarEnter(self, f --[[@as BossAbilityFrame]])
		end)
		frame:SetScript("OnLeave", function(f)
			self:ClearSelectedBossAbility(
				f--[[@as BossAbilityFrame]].abilityInstance.bossAbilitySpellID,
				f--[[@as BossAbilityFrame]].abilityInstance.spellCount,
				true
			)
			ClearSelectedAssignmentsFromBossAbilityFrameEnter(self)
		end)
		local spellTexture = frame:CreateTexture(nil, "OVERLAY", nil, bossAbilityTextureSubLevel)
		spellTexture:SetPoint("TOPLEFT", 2, -2)
		spellTexture:SetPoint("BOTTOMRIGHT", -2, 2)

		frame.assignmentFrame = timelineFrame
		frame.spellTexture = spellTexture
		frame.selectionType = BossAbilitySelectionType.kNone
		self.bossAbilityFrames[index] = frame
	end

	frame.abilityInstance = abilityInstance

	frame.spellTexture:SetColorTexture(unpack(color))
	frame:SetSize(width, height)
	frame:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", hOffset, -vOffset)
	frame:SetFrameLevel(frameLevel)
	-- frame:SetAlpha(abilityInstance.alpha)
	frame:Show()
end

---@param self EPTimeline
local function UpdateBossAbilityBars(self)
	for _, frame in pairs(self.bossAbilityFrames) do
		frame:Hide()
	end
	for _, textureGroup in ipairs(self.bossPhaseIndicators) do
		for _, texture in ipairs(textureGroup) do
			texture:Hide()
			texture.label:Hide()
		end
	end

	if totalTimelineDuration <= 0.0 then
		return
	end

	local offsets = {}
	local offset = 0
	local bossAbilityHeight = self.preferences.timelineRows.bossAbilityHeight
	for _, bossAbilitySpellID in ipairs(self.bossAbilityOrder) do
		offsets[bossAbilitySpellID] = offset
		if self.bossAbilityVisibility[bossAbilitySpellID] == true then
			offset = offset + bossAbilityHeight + paddingBetweenBossAbilityBars
		end
	end

	local padding = timelineLinePadding
	local timelineFrame = self.bossAbilityTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x
	local baseFrameLevel = timelineFrame:GetFrameLevel()

	local lastInfo = {} ---@type table<integer, LastInfo>
	local currentIndex = 1 -- In case boss abilities are hidden, this ensures boss ability frames are indexed correctly
	for _, entry in ipairs(self.bossAbilityInstances) do
		local timelineStartPosition = (entry.castStart / totalTimelineDuration) * timelineWidth
		local timelineEndPosition = (entry.effectEnd / totalTimelineDuration) * timelineWidth
		local horizontalOffset = timelineStartPosition + padding.x
		local width = max(minimumBossAbilityWidth, timelineEndPosition - timelineStartPosition)

		local index = entry.bossPhaseOrderIndex

		if entry.signifiesPhaseStart and entry.bossPhaseName and entry.bossPhaseShortName then
			local long, short = entry.bossPhaseName, entry.bossPhaseShortName
			if long and short then
				DrawBossPhaseIndicator(self, true, index, long, short, horizontalOffset, width, lastInfo)
			end
		end
		if entry.signifiesPhaseEnd then
			local long, short = entry.nextBossPhaseName, entry.nextBossPhaseShortName
			if long and short then
				DrawBossPhaseIndicator(self, false, index, long, short, horizontalOffset, width, lastInfo)
			end
		end

		if self.bossAbilityVisibility[entry.bossAbilitySpellID] == true then
			local verticalOffset = offsets[entry.bossAbilitySpellID]
			local height = bossAbilityHeight
			local color = colors[((entry.bossAbilityOrderIndex - 1) % #colors) + 1]
			if entry.overlaps then
				verticalOffset = verticalOffset + entry.overlaps.offset * height
				height = height * entry.overlaps.heightMultiplier
			end
			local frameLevel = baseFrameLevel + entry.frameLevel
			DrawBossAbilityBar(
				self,
				entry,
				horizontalOffset,
				verticalOffset,
				width,
				height,
				color,
				frameLevel,
				currentIndex
			)
			currentIndex = currentIndex + 1
		end
	end
	sort(lastInfo, function(a, b)
		return a.left < b.left
	end)
	local lastLastInfo ---@type LastInfo|nil
	for index, info in ipairs(lastInfo) do
		if index > 1 and lastLastInfo then
			if info.left <= lastLastInfo.right + 5 then
				info.label:SetText(info.shortName)
				local labelWidth = info.label:GetWidth()
				local left = info.partialLeft - labelWidth / 2.0
				info.label:SetPoint("LEFT", timelineFrame, "LEFT", left, 0)
				info.alreadyShortened = true
				if not lastLastInfo.alreadyShortened and lastLastInfo.label then
					lastLastInfo.label:SetText(lastLastInfo.shortName)
					local lastLeft = lastLastInfo.partialLeft - lastLastInfo.label:GetWidth() / 2.0
					lastLastInfo.label:SetPoint("LEFT", timelineFrame, "LEFT", lastLeft, 0)
					lastLastInfo.alreadyShortened = true
				end
			end
		end
		lastLastInfo = info
	end
end

-- Called when an assignment has stopped being dragged. Returns true if the assignment was duplicated, or the
-- difference between the previous assignment time and the new assignment time if the assignment was only moved.
---@param self EPTimeline
---@param assignmentFrame AssignmentFrame
---@return boolean|number
local function StopMovingAssignment(self, assignmentFrame)
	assignmentIsDragging = false
	assignmentFrame:SetScript("OnUpdate", nil)

	local timelineAssignment = assignmentFrame.timelineAssignment

	assignmentFrame.timelineAssignment = nil
	assignmentFrameBeingDragged = nil
	horizontalCursorPositionWhenAssignmentFrameClicked = 0

	local time = ConvertTimelineOffsetToTime(assignmentFrame, self.bossAbilityTimeline.timelineFrame)

	if assignmentBeingDuplicated then
		self.fakeAssignmentFrame:Hide()
		assignmentBeingDuplicated = false
		if timelineAssignment then
			local spellID = timelineAssignment.assignment.spellID
			local orderTable = self.orderedWithSpellIDAssignmentFrameIndices[timelineAssignment.order]
			local spellIDTable = orderTable[spellID]
			for index, assignmentFrameIndex in ipairs(spellIDTable) do
				if assignmentFrameIndex == self.fakeAssignmentFrame.temporaryAssignmentFrameIndex then
					tremove(self.assignmentFrames, assignmentFrameIndex)
					tremove(spellIDTable, index)
					if not next(orderTable[spellID]) then
						orderTable[spellID] = nil
					end
					break
				end
			end

			if time then
				self:Fire("DuplicateAssignmentEnd", timelineAssignment, time)
			end
		end
		self.fakeAssignmentFrame:SetWidth(self.preferences.timelineRows.assignmentHeight)
		self.fakeAssignmentFrame.cooldownFrame:Hide()
		self.fakeAssignmentFrame.spellTexture:SetTexture(nil)
		self.fakeAssignmentFrame.spellID = nil
		self.fakeAssignmentFrame.uniqueAssignmentID = nil
		self.fakeAssignmentFrame.timelineAssignment = nil
		self.fakeAssignmentFrame.temporaryAssignmentFrameIndex = nil
		if self.fakeAssignmentFrame.chargeMarker then
			self.fakeAssignmentFrame.chargeMarker:Hide()
		end
		return true
	else
		if time and timelineAssignment then
			timelineAssignment.startTime = Round(time, 1)
			local relativeTime = self.CalculateAssignmentTimeFromStart(timelineAssignment)
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
---@param self EPTimeline
---@param frame AssignmentFrame
local function HandleAssignmentUpdate(self, frame)
	if isSimulating or not assignmentIsDragging then
		return
	end

	local horizontalCursorPosition = GetCursorPosition() / UIParent:GetEffectiveScale()
	local difference = horizontalCursorPosition - horizontalCursorPositionWhenAssignmentFrameClicked
	if abs(difference) < 5 then -- Use a threshold of 5 pixels before changing the time
		UpdateLinePosition(
			self.assignmentTimeline.frame,
			self.assignmentTimeline.verticalPositionLine,
			-horizontalCursorAssignmentFrameOffsetWhenClicked - difference
		)
		UpdateLinePosition(
			self.bossAbilityTimeline.frame,
			self.bossAbilityTimeline.verticalPositionLine,
			-horizontalCursorAssignmentFrameOffsetWhenClicked - difference
		)
		UpdateTimeLabels(self)
		return
	end
	horizontalCursorPositionWhenAssignmentFrameClicked = 0

	local timelineFrameLeft = self.bossAbilityTimeline.timelineFrame:GetLeft()
	local timelineFrameWidth = self.bossAbilityTimeline.timelineFrame:GetWidth()
	local minOffsetFromTimelineFrameLeft = timelineLinePadding.x
	local maxOffsetFromTimelineFrameLeft = timelineFrameWidth - timelineLinePadding.x

	local minTime = self.GetMinimumCombatLogEventTime(frame.timelineAssignment)
	if minTime then
		local minOffsetFromTime = ConvertTimeToTimelineOffset(minTime, timelineFrameWidth)
		minOffsetFromTimelineFrameLeft = max(minOffsetFromTime, minOffsetFromTimelineFrameLeft)
	end

	local assignmentFrameOffsetFromTimelineFrameLeft = horizontalCursorPosition
		- timelineFrameLeft
		- horizontalCursorAssignmentFrameOffsetWhenClicked

	assignmentFrameOffsetFromTimelineFrameLeft = Clamp(
		assignmentFrameOffsetFromTimelineFrameLeft,
		minOffsetFromTimelineFrameLeft,
		maxOffsetFromTimelineFrameLeft
	)

	local assignmentLeft = frame:GetLeft()
	local assignmentRight = assignmentLeft + self.preferences.timelineRows.assignmentHeight
	local horizontalScroll = self.bossAbilityTimeline.scrollFrame:GetHorizontalScroll()
	local scrollFrameWidth = self.bossAbilityTimeline.scrollFrame:GetWidth()
	local scrollFrameLeft = self.bossAbilityTimeline.scrollFrame:GetLeft()
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
		self.bossAbilityTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.assignmentTimeline.scrollFrame:SetHorizontalScroll(newHorizontalScroll)
		self.splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
		UpdateHorizontalScrollBarThumb(
			self.horizontalScrollBar:GetWidth(),
			self.thumb,
			self.bossAbilityTimeline.scrollFrame:GetWidth(),
			self.bossAbilityTimeline.timelineFrame:GetWidth(),
			newHorizontalScroll
		)
	end

	local verticalOffsetFromTimelineFrameTop = (frame.timelineAssignment.order - 1)
		* (self.preferences.timelineRows.assignmentHeight + paddingBetweenAssignments)
	frame:SetPoint("TOPLEFT", assignmentFrameOffsetFromTimelineFrameLeft, -verticalOffsetFromTimelineFrameTop)
	UpdateLinePosition(
		self.assignmentTimeline.frame,
		self.assignmentTimeline.verticalPositionLine,
		-horizontalCursorAssignmentFrameOffsetWhenClicked
	)
	UpdateLinePosition(
		self.bossAbilityTimeline.frame,
		self.bossAbilityTimeline.verticalPositionLine,
		-horizontalCursorAssignmentFrameOffsetWhenClicked
	)
	UpdateTimeLabels(self)

	if assignmentFrameBeingDragged and assignmentFrameBeingDragged.timelineAssignment then
		local time = ConvertTimelineOffsetToTime(assignmentFrameBeingDragged, self.bossAbilityTimeline.timelineFrame)
		if time then
			assignmentFrameBeingDragged.timelineAssignment.startTime = time
			local order = assignmentFrameBeingDragged.timelineAssignment.order
			local spellIDAssignmentFrameIndices = self.orderedWithSpellIDAssignmentFrameIndices[order]

			local sortedAssignmentFrameIndices = {} ---@type table<integer,integer>
			for _, assignmentFrameIndices in pairs(spellIDAssignmentFrameIndices) do
				for _, assignmentFrameIndex in ipairs(assignmentFrameIndices) do
					sortedAssignmentFrameIndices[#sortedAssignmentFrameIndices + 1] = assignmentFrameIndex
				end
			end
			local assignmentFrames = self.assignmentFrames
			-- Need to sort by offset due to the fake assignment frame
			SortAssignmentFrameIndices(assignmentFrames, sortedAssignmentFrameIndices)

			local spellID = assignmentFrameBeingDragged.timelineAssignment.assignment.spellID
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
			self.ComputeChargeStates(matchingTimelineAssignments)

			local showSpellCooldownDuration = self.preferences.showSpellCooldownDuration
			local collapsed = self.collapsed
			for _, assignmentFrameIndex in ipairs(matchingSpellIDAssignmentFrameIndices) do
				local timelineAssignment = assignmentFrames[assignmentFrameIndex].timelineAssignment
				if timelineAssignment then
					local assignee = timelineAssignment.assignment.assignee
					local showCooldown = showSpellCooldownDuration and not collapsed[assignee]
					local cooldown = showCooldown and timelineAssignment.effectiveCooldownDuration or nil
					self:DrawAssignment(
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

			local timelineFrame = self.assignmentTimeline.timelineFrame
			local minFrameLevel = timelineFrame:GetFrameLevel() + 1
			local left = (-self.preferences.timelineRows.assignmentHeight * order)

			for _, index in ipairs(sortedAssignmentFrameIndices) do
				local assignmentFrame = assignmentFrames[index]
				assignmentFrame:SetFrameLevel(minFrameLevel)
				assignmentFrame.cooldownParent:SetPoint("LEFT", left, 0)
				minFrameLevel = minFrameLevel + 1
			end
		end
	end
end

---@param self EPTimeline
---@param frame AssignmentFrame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentMouseDown(self, frame, mouseButton)
	if isSimulating then
		return
	end

	local isValidEdit = IsValidKeyCombination(self.preferences.keyBindings.editAssignment, mouseButton)
	local isValidDuplicate = IsValidKeyCombination(self.preferences.keyBindings.duplicateAssignment, mouseButton)

	if not isValidEdit and not isValidDuplicate then
		return
	end

	horizontalCursorPositionWhenAssignmentFrameClicked = GetCursorPosition() / UIParent:GetEffectiveScale()
	horizontalCursorAssignmentFrameOffsetWhenClicked = horizontalCursorPositionWhenAssignmentFrameClicked
		- frame:GetLeft()

	self:ClearSelectedAssignments()
	assignmentIsDragging = true
	local timelineAssignment, index = FindTimelineAssignment(self.timelineAssignments, frame.uniqueAssignmentID)

	if isValidDuplicate then
		assignmentBeingDuplicated = true
		if timelineAssignment and index then
			local spellID = timelineAssignment.assignment.spellID
			local orderTable = self.orderedWithSpellIDAssignmentFrameIndices[timelineAssignment.order]
			local spellIDTable = orderTable[spellID]

			local newTimelineAssignment = {}
			self:Fire("DuplicateAssignmentStart", timelineAssignment, newTimelineAssignment)

			for spellIDTablePositionIndex, assignmentFrameIndex in ipairs(spellIDTable) do
				if assignmentFrameIndex == index then
					local newIndex = #self.assignmentFrames + 1
					self.fakeAssignmentFrame.temporaryAssignmentFrameIndex = newIndex
					self.fakeAssignmentFrame.timelineAssignment = newTimelineAssignment
					self.assignmentFrames[newIndex] = self.fakeAssignmentFrame
					tinsert(spellIDTable, spellIDTablePositionIndex, newIndex)
					break
				end
			end

			local fakeAssignmentFrame = self.fakeAssignmentFrame
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
				local left = -self.preferences.timelineRows.assignmentHeight * timelineAssignment.order
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
	self:SelectAssignment(frame, AssignmentSelectionType.kSelection)
	frame.timelineAssignment = timelineAssignment
	assignmentFrameBeingDragged = frame
	frame:SetScript("OnUpdate", function(f)
		HandleAssignmentUpdate(self, f)
	end)
end

---@param self EPTimeline
---@param frame AssignmentFrame
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentMouseUp(self, frame, mouseButton)
	if isSimulating then
		return
	end
	local duplicatedOrAssignmentTimeDifference = nil
	if assignmentIsDragging then
		duplicatedOrAssignmentTimeDifference = StopMovingAssignment(self, frame)
		if type(duplicatedOrAssignmentTimeDifference) == "boolean" and duplicatedOrAssignmentTimeDifference == true then
			self.bossAbilityTimeline.verticalPositionLine:Hide()
			self.assignmentTimeline.verticalPositionLine:Hide()
			UpdateTimeLabels(self)
			return
		end
	end

	if IsValidKeyCombination(self.preferences.keyBindings.editAssignment, mouseButton) then
		if frame.uniqueAssignmentID then
			self:Fire("AssignmentClicked", frame.uniqueAssignmentID, duplicatedOrAssignmentTimeDifference)
		end
	end

	self.bossAbilityTimeline.verticalPositionLine:Hide()
	self.assignmentTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels(self)
end

---@param self EPTimeline
---@param mouseButton "LeftButton"|"RightButton"|"MiddleButton"|"Button4"|"Button5"
local function HandleAssignmentTimelineFrameMouseUp(self, mouseButton)
	if isSimulating then
		return
	end

	if assignmentIsDragging and assignmentFrameBeingDragged then
		StopMovingAssignment(self, assignmentFrameBeingDragged)
		self.bossAbilityTimeline.verticalPositionLine:Hide()
		self.assignmentTimeline.verticalPositionLine:Hide()
		UpdateTimeLabels(self)
		return
	end

	if IsValidKeyCombination(self.preferences.keyBindings.newAssignment, mouseButton) then
		local currentX, currentY = GetCursorPosition()
		currentX = currentX / UIParent:GetEffectiveScale()
		currentY = currentY / UIParent:GetEffectiveScale()

		local timelineFrame = self.bossAbilityTimeline.timelineFrame
		local timelineWidth = timelineFrame:GetWidth()
		local padding = timelineLinePadding.x
		local newTimeOffset = currentX - timelineFrame:GetLeft()
		local time = (newTimeOffset - padding) * totalTimelineDuration / (timelineWidth - padding * 2)

		if time < 0.0 or time > totalTimelineDuration then
			return
		end

		local relativeDistanceFromTop = abs(self.assignmentTimeline.timelineFrame:GetTop() - currentY)
		local totalAssignmentHeight = 0
		local assignee, spellID = nil, nil
		for _, assigneeAndSpell in ipairs(self.assigneesAndSpells) do
			if assigneeAndSpell.spellID == nil or not self.collapsed[assigneeAndSpell.assignee] then
				totalAssignmentHeight = totalAssignmentHeight
					+ (self.preferences.timelineRows.assignmentHeight + paddingBetweenAssignments)
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
---@param spellID integer
---@param timelineFrame Frame
---@param offsetX number
---@param offsetY number
---@return AssignmentFrame
local function CreateAssignmentFrame(self, spellID, timelineFrame, offsetX, offsetY)
	local assignmentHeight = self.preferences.timelineRows.assignmentHeight
	local assignment = CreateFrame("Frame", nil, timelineFrame, "BackdropTemplate")
	assignment:SetBackdrop({
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 2,
	})
	assignment:SetBackdropBorderColor(unpack(assignmentOutlineColor))
	assignment:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignment:SetSize(assignmentHeight, assignmentHeight)

	local cooldownFrame = CreateFrame("Frame", nil, assignment)
	cooldownFrame:SetPoint("LEFT", assignment, "RIGHT")
	cooldownFrame:SetHeight(assignmentHeight + 0.01)
	cooldownFrame:SetClipsChildren(true)
	cooldownFrame:EnableMouse(false)

	local spellTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel)
	spellTexture:SetPoint("CENTER")
	spellTexture:SetSize(assignmentHeight - 2, assignmentHeight - 2)
	spellTexture:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")
	spellTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cooldownParent = self.frame:CreateTexture(nil, "BACKGROUND")
	cooldownParent:SetPoint("TOPRIGHT", cooldownFrame, "TOPRIGHT")
	cooldownParent:SetPoint("BOTTOMRIGHT", cooldownFrame, "BOTTOMRIGHT")
	cooldownParent:SetAlpha(0)
	cooldownParent:EnableMouse(false)

	local cooldownBackground = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	cooldownBackground:SetColorTexture(unpack(cooldownBackgroundColor))
	cooldownBackground:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT")
	cooldownBackground:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT")
	cooldownBackground:EnableMouse(false)

	local cooldownTexture = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -1)
	cooldownTexture:SetTexture(cooldownTextureFile, "REPEAT", "REPEAT")
	cooldownTexture:SetSnapToPixelGrid(false)
	cooldownTexture:SetTexelSnappingBias(0)
	cooldownTexture:SetHorizTile(true)
	cooldownTexture:SetVertTile(true)
	cooldownTexture:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT", cooldownPadding, -cooldownPadding)
	cooldownTexture:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT", -cooldownPadding, cooldownPadding)
	cooldownTexture:SetAlpha(cooldownTextureAlpha)
	cooldownTexture:EnableMouse(false)

	local invalidTexture = assignment:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel + 1)
	invalidTexture:SetAllPoints(spellTexture)
	invalidTexture:SetColorTexture(unpack(invalidTextureColor))
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

	assignment:SetScript("OnMouseDown", function(frame, mouseButton, _)
		HandleAssignmentMouseDown(self, frame, mouseButton)
	end)
	assignment:SetScript("OnMouseUp", function(frame, mouseButton, _)
		HandleAssignmentMouseUp(self, frame, mouseButton)
	end)

	return assignment --[[@as AssignmentFrame]]
end

-- Helper function to draw a spell icon for an assignment.
---@param self EPTimeline
---@param startTime number absolute start time of the assignment
---@param spellID integer spellID of the spell being assigned
---@param index integer index of the AssignmentFrame to use to display the assignment
---@param uniqueID integer unique index of the assignment
---@param order number the relative order of the assignee of the assignment
---@param cooldownDuration number|nil
---@param relativeChargeRestoreTime number|nil
---@param invalidChargeCast boolean|nil
local function DrawAssignment(
	self,
	startTime,
	spellID,
	index,
	uniqueID,
	order,
	cooldownDuration,
	relativeChargeRestoreTime,
	invalidChargeCast
)
	if totalTimelineDuration <= 0.0 then
		return
	end

	local padding = timelineLinePadding
	local timelineFrame = self.assignmentTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x
	local assignmentHeight = self.preferences.timelineRows.assignmentHeight

	local timelineStartPosition = (startTime / totalTimelineDuration) * timelineWidth
	local offsetX = timelineStartPosition + timelineLinePadding.x
	local offsetY = (order - 1) * (assignmentHeight + paddingBetweenAssignments)

	local assignmentFrame = self.assignmentFrames[index]
	if not assignmentFrame then
		assignmentFrame = CreateAssignmentFrame(self, spellID, timelineFrame, offsetX, offsetY)
		self.assignmentFrames[index] = assignmentFrame
	end

	assignmentFrame.spellID = spellID
	assignmentFrame.uniqueAssignmentID = uniqueID

	assignmentFrame:SetHeight(assignmentHeight)
	assignmentFrame:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", offsetX, -offsetY)
	assignmentFrame:Show()

	local hideMarker = true
	if spellID == constants.kInvalidAssignmentSpellID then
		assignmentFrame.spellTexture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
	elseif spellID == constants.kTextAssignmentSpellID then
		assignmentFrame.spellTexture:SetTexture(constants.kTextAssignmentTexture)
	else
		local iconID, _ = GetSpellTexture(spellID)
		assignmentFrame.spellTexture:SetTexture(iconID)
		if cooldownDuration then
			local cooldownEndPosition = (startTime + cooldownDuration) / totalTimelineDuration * timelineWidth
			local cooldownWidth = (cooldownEndPosition - timelineStartPosition) - cooldownWidthTolerance
			local visibleCooldownWidth = cooldownWidth - assignmentHeight
			local cooldownFrame = assignmentFrame.cooldownFrame
			if visibleCooldownWidth > 0 then
				cooldownFrame:SetWidth(visibleCooldownWidth)
				cooldownFrame:Show()
			else
				cooldownFrame:SetWidth(0)
				cooldownFrame:Hide()
			end

			if relativeChargeRestoreTime then
				local chargeMarker = assignmentFrame.chargeMarker
				if not chargeMarker then
					chargeMarker = self.chargeFrame:CreateTexture(nil, "OVERLAY", nil, assignmentTextureSubLevel + 1)
					chargeMarker:SetTexture(phaseIndicatorTexture, "REPEAT", "REPEAT")
					chargeMarker:SetVertexColor(unpack(spellChargeRestorationColor))
					chargeMarker:SetWidth(2)
					assignmentFrame.chargeMarker = chargeMarker
				end
				local left = (relativeChargeRestoreTime / totalTimelineDuration) * timelineWidth
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
---@param self EPTimeline
local function UpdateAssignments(self)
	-- Clears/resets assignment frames
	local selected = self:GetSelectedAssignments(true)

	wipe(self.orderedWithSpellIDAssignmentFrameIndices)
	local orderedFrameIndices = {}
	local collapsed = self.collapsed
	local showSpellCooldownDuration = self.preferences.showSpellCooldownDuration
	local orderedSpellIDFrameIndices = self.orderedWithSpellIDAssignmentFrameIndices

	for index, timelineAssignment in ipairs(self.timelineAssignments) do
		local order = timelineAssignment.order
		local assignment = timelineAssignment.assignment
		local spellID = assignment.spellID
		if not orderedSpellIDFrameIndices[order] then
			orderedSpellIDFrameIndices[order] = {}
			orderedFrameIndices[order] = {}
		end
		if not orderedSpellIDFrameIndices[order][spellID] then
			orderedSpellIDFrameIndices[order][spellID] = {}
		end
		local showCooldown = showSpellCooldownDuration and not collapsed[assignment.assignee]
		local cooldown = showCooldown and timelineAssignment.effectiveCooldownDuration or nil
		DrawAssignment(
			self,
			timelineAssignment.startTime,
			spellID,
			index,
			assignment.uniqueID,
			order,
			cooldown,
			timelineAssignment.relativeChargeRestoreTime,
			timelineAssignment.invalidChargeCast
		)
		self.assignmentFrames[index].timelineAssignment = timelineAssignment
		orderedSpellIDFrameIndices[order][spellID][#orderedSpellIDFrameIndices[order][spellID] + 1] = index
		orderedFrameIndices[order][#orderedFrameIndices[order] + 1] = index
	end

	local assignmentFrames = self.assignmentFrames
	local timelineFrame = self.assignmentTimeline.timelineFrame
	local timelineAssignments = self.timelineAssignments
	local timelineFrameLevel = timelineFrame:GetFrameLevel()
	local assignmentHeight = self.preferences.timelineRows.assignmentHeight

	local maxFrameLevel = 0
	for order, assignmentFrameIndices in pairs(orderedFrameIndices) do
		sort(assignmentFrameIndices, function(a, b)
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

	self.chargeFrame:SetFrameLevel(maxFrameLevel)

	for assignmentSelectionType, uniqueAssignmentIDs in pairs(selected) do
		for _, uniqueAssignmentID in ipairs(uniqueAssignmentIDs) do
			self:SelectAssignment(uniqueAssignmentID, assignmentSelectionType)
		end
	end
end

---@param self EPTimeline
---@param isBossTimelineSection boolean
---@param delta number
local function HandleTimelineFrameMouseWheel(self, isBossTimelineSection, delta)
	if assignmentIsDragging and assignmentFrameBeingDragged then
		StopMovingAssignment(self, assignmentFrameBeingDragged)
	end

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
			local xPosition = GetCursorPosition() or 0
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
			-- local overflow = newVisibleStartTime
			-- newVisibleEndTime = newVisibleEndTime - overflow
			newVisibleStartTime = 0
		elseif newVisibleEndTime > totalTimelineDuration then
			-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
			local overflow = totalTimelineDuration - newVisibleEndTime
			-- newVisibleEndTime = totalTimelineDuration
			newVisibleStartTime = newVisibleStartTime + overflow
		end

		-- Ensure boundaries are within the total timeline range
		newVisibleStartTime = max(0, newVisibleStartTime)
		-- newVisibleEndTime = min(totalTimelineDuration, newVisibleEndTime)

		-- Adjust the timeline frame width based on zoom factor
		local scrollFrameWidth = scrollFrame:GetWidth()
		local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

		-- Recalculate the new scroll position based on the new visible start time
		local newHorizontalScroll = (newVisibleStartTime / totalTimelineDuration) * newTimelineFrameWidth

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
		UpdateAssignments(self)
		UpdateBossAbilityBars(self)
		UpdateTickMarks(self)
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
	thumbOffsetWhenThumbClicked = GetCursorPosition() / UIParent:GetEffectiveScale() - thumb:GetLeft()
	scrollBarWidthWhenThumbClicked = horizontalScrollBar:GetWidth()
	thumbWidthWhenThumbClicked = thumb:GetWidth()
	thumbIsDragging = true

	thumb:SetScript("OnUpdate", function()
		if not thumbIsDragging then
			return
		end

		local paddingX = thumbPadding.x
		local currentOffset = thumbOffsetWhenThumbClicked
		local currentWidth = thumbWidthWhenThumbClicked
		local currentScrollBarWidth = scrollBarWidthWhenThumbClicked
		local newOffset = GetCursorPosition() / UIParent:GetEffectiveScale()
			- horizontalScrollBar:GetLeft()
			- currentOffset

		local minAllowedOffset = paddingX
		local maxAllowedOffset = currentScrollBarWidth - currentWidth - paddingX
		newOffset = Clamp(newOffset, minAllowedOffset, maxAllowedOffset)
		thumb:SetPoint("LEFT", newOffset, 0)

		-- Calculate the scroll frame's horizontal scroll based on the thumb's position
		local maxThumbPosition = currentScrollBarWidth - currentWidth - (2 * paddingX)
		local maxScroll = bossAbilityTimelineFrame:GetWidth() - bossAbilityScrollFrame:GetWidth()
		local scrollOffset = 0
		if maxThumbPosition ~= 0 then
			scrollOffset = ((newOffset - paddingX) / maxThumbPosition) * maxScroll
			bossAbilityScrollFrame:SetHorizontalScroll(scrollOffset)
			assignmentScrollFrame:SetHorizontalScroll(scrollOffset)
			splitterScrollFrame:SetHorizontalScroll(scrollOffset)
		end
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
	if isSimulating or timelineFrameIsDragging then
		return
	end
	local assignmentFrame = self.assignmentTimeline.frame
	local bossAbilityFrame = self.bossAbilityTimeline.frame
	local assignmentLine = self.assignmentTimeline.verticalPositionLine
	local bossAbilityLine = self.bossAbilityTimeline.verticalPositionLine
	frame:SetScript("OnUpdate", function()
		UpdateLinePosition(assignmentFrame, assignmentLine)
		UpdateLinePosition(bossAbilityFrame, bossAbilityLine)
		UpdateTimeLabels(self)
	end)
end

---@param self EPTimeline
---@param frame Frame
local function HandleTimelineFrameLeave(self, frame)
	if isSimulating or timelineFrameIsDragging then
		return
	end
	frame:SetScript("OnUpdate", nil)
	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels(self)
end

---@param self EPTimeline
---@param frame Frame
---@param button string
local function HandleTimelineFrameDragStart(self, frame, button)
	if not IsValidKeyCombination(self.preferences.keyBindings.pan, button) then
		return
	end
	if isSimulating then
		return
	end

	timelineFrameIsDragging = true
	timelineFrameOffsetWhenDragStarted = GetCursorPosition()

	self.assignmentTimeline.verticalPositionLine:Hide()
	self.bossAbilityTimeline.verticalPositionLine:Hide()
	UpdateTimeLabels(self)

	local splitterScrollFrame = self.splitterScrollFrame
	local scrollFrameWidth = self.bossAbilityTimeline.scrollFrame:GetWidth()
	local timelineFrameWidth = self.bossAbilityTimeline.timelineFrame:GetWidth()
	local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
	local assignmentScrollFrame = self.assignmentTimeline.scrollFrame
	local horizontalScrollBarWidth = self.horizontalScrollBar:GetWidth()
	local thumb = self.thumb

	frame:SetScript("OnUpdate", function()
		if timelineFrameIsDragging then
			local x = GetCursorPosition()
			local dx = (x - timelineFrameOffsetWhenDragStarted) / bossAbilityScrollFrame:GetEffectiveScale()
			local newHorizontalScroll = bossAbilityScrollFrame:GetHorizontalScroll() - dx
			local maxHorizontalScroll = timelineFrameWidth - scrollFrameWidth
			newHorizontalScroll = Clamp(newHorizontalScroll, 0, maxHorizontalScroll)
			bossAbilityScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			assignmentScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			splitterScrollFrame:SetHorizontalScroll(newHorizontalScroll)
			timelineFrameOffsetWhenDragStarted = x
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
	if isSimulating then
		return
	end

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
		local assignmentFrame = self.assignmentTimeline.frame
		local bossAbilityFrame = self.bossAbilityTimeline.frame
		local assignmentLine = self.assignmentTimeline.verticalPositionLine
		local bossAbilityLine = self.bossAbilityTimeline.verticalPositionLine
		frame:SetScript("OnUpdate", function()
			UpdateLinePosition(assignmentFrame, assignmentLine)
			UpdateLinePosition(bossAbilityFrame, bossAbilityLine)
			UpdateTimeLabels(self)
		end)
	end
end

-- Calculate the total required height for boss ability bars.
---@param self EPTimeline
---@return number
local function CalculateRequiredBarHeight(self)
	local totalBarHeight = 0.0
	local rowHeight = self.preferences.timelineRows.bossAbilityHeight

	local activeAbilities = {}
	for _, spellID in pairs(self.bossAbilityOrder) do
		activeAbilities[spellID] = true
	end

	for spellID, visible in pairs(self.bossAbilityVisibility) do
		if visible == true and activeAbilities[spellID] then
			totalBarHeight = totalBarHeight + (rowHeight + paddingBetweenBossAbilityBars)
		end
	end
	if totalBarHeight >= (rowHeight + paddingBetweenBossAbilityBars) then
		totalBarHeight = totalBarHeight - paddingBetweenBossAbilityBars
	end
	return totalBarHeight
end

-- Calculate the total required height for assignments.
---@param self EPTimeline
---@return number
local function CalculateRequiredAssignmentHeight(self)
	local totalAssignmentHeight = 0
	local totalAssignmentRows = 0
	local rowHeight = self.preferences.timelineRows.assignmentHeight
	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not self.collapsed[as.assignee] then
			totalAssignmentHeight = totalAssignmentHeight + (rowHeight + paddingBetweenAssignments)
			totalAssignmentRows = totalAssignmentRows + 1
		end
	end
	if totalAssignmentHeight >= (rowHeight + paddingBetweenAssignments) then
		totalAssignmentHeight = totalAssignmentHeight - paddingBetweenAssignments
	end
	return totalAssignmentHeight
end

---@param self EPTimeline
local function UpdateResizeBounds(self)
	local minHeight = self.assignmentDimensions.min
		+ self.bossAbilityDimensions.min
		+ paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
	local maxHeight = self.assignmentDimensions.max
		+ self.bossAbilityDimensions.max
		+ paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
	self:Fire("ResizeBoundsCalculated", minHeight, maxHeight)
end

local kNonTimelineHeight = constants.timeline.kHorizontalScrollBarHeight
	+ constants.timeline.kPaddingBetweenTimelineAndScrollBar
	+ constants.timeline.kPaddingBetweenTimelines
	+ constants.kStatusBarHeight
	+ constants.kStatusBarPadding
	+ constants.kWindowBarHeight
	+ constants.kMainFramePadding[2]
	+ constants.kMainFramePadding[4]
	+ constants.kTopContainerHeight
	+ constants.kMainFrameSpacing[2]

---@param self EPTimeline
local function CalculateMinMaxStepBarHeight(self)
	local abilityCount = 1
	local timelineRows = self.preferences.timelineRows
	local rowHeight = timelineRows.bossAbilityHeight
	local minH, maxH, stepH = 0, 0, (rowHeight + paddingBetweenBossAbilityBars)

	local activeAbilities = {}
	for _, spellID in pairs(self.bossAbilityOrder) do
		activeAbilities[spellID] = true
	end

	local availableHeight = UIParent:GetHeight() - kNonTimelineHeight
	local assignmentTimelineHeight = timelineRows.numberOfAssignmentsToShow * (timelineRows.assignmentHeight + 2) - 2
	local usableHeight = availableHeight - assignmentTimelineHeight - 2
	local maximumNumberOfBossAbilityRows = floor(usableHeight / (timelineRows.bossAbilityHeight + 2))

	for spellID, visible in pairs(self.bossAbilityVisibility) do
		if visible == true and activeAbilities[spellID] then
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
		minH = rowHeight -- Prevent boss ability timeline frame from having 0 height
	end
	if maxH >= stepH then
		maxH = maxH - paddingBetweenBossAbilityBars
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
	local timelineRows = self.preferences.timelineRows
	local minH, maxH, stepH = 0, 0, (self.preferences.timelineRows.assignmentHeight + paddingBetweenAssignments)
	local availableHeight = UIParent:GetHeight() - kNonTimelineHeight

	local bossTimelineHeight = timelineRows.numberOfBossAbilitiesToShow * (timelineRows.bossAbilityHeight + 2) - 2
	local usableHeight = availableHeight - bossTimelineHeight - 2
	local maximumNumberOfAssignmentRows = floor(usableHeight / (timelineRows.assignmentHeight + 2))

	for _, as in ipairs(self.assigneesAndSpells) do
		if as.spellID == nil or not self.collapsed[as.assignee] then
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

	UpdateResizeBounds(self)
end

---@param self EPTimeline
local function OnAcquire(self)
	self.assignmentFrames = self.assignmentFrames or {}
	self.bossAbilityFrames = self.bossAbilityFrames or {}
	self.bossPhaseIndicators = self.bossPhaseIndicators or {}
	self.timelineLabels = self.timelineLabels or {}
	self.zoomFactor = self.zoomFactor or 1.0
	self.orderedWithSpellIDAssignmentFrameIndices = {}
	self.bossAbilityOrder = {}
	self.bossPhaseOrder = {}
	self.bossPhases = {}
	self.timelineAssignments = {}
	self.assigneesAndSpells = {}
	self.bossAbilityVisibility = {}
	self.collapsed = {}
	self.allowHeightResizing = false
	self.bossAbilityDimensions = { min = 0, max = 0, step = 0 }
	self.assignmentDimensions = { min = 0, max = 0, step = 0 }

	self.contentFrame:SetParent(self.frame)
	self.contentFrame:SetPoint("TOPLEFT")
	self.contentFrame:SetPoint("TOPRIGHT")
	self.contentFrame:SetPoint("BOTTOM", self.horizontalScrollBar, "TOP", 0, paddingBetweenTimelineAndScrollBar)
	self.contentFrame:Show()

	self.assignmentTimeline = AceGUI:Create("EPTimelineSection")
	self.assignmentTimeline.frame:SetParent(self.contentFrame)
	self.assignmentTimeline:SetListPadding(paddingBetweenAssignments)

	self.bossAbilityTimeline = AceGUI:Create("EPTimelineSection")
	self.bossAbilityTimeline.frame:SetParent(self.contentFrame)
	self.bossAbilityTimeline:SetListPadding(paddingBetweenBossAbilityBars)

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
	assignmentFrame:SetPoint("TOPLEFT", bossAbilityFrame, "BOTTOMLEFT", 0, -paddingBetweenTimelines)
	assignmentFrame:SetPoint("TOPRIGHT", bossAbilityFrame, "BOTTOMRIGHT", 0, -paddingBetweenTimelines)

	self.chargeFrame:SetPoint("TOPLEFT", self.assignmentTimeline.scrollFrame, "TOPLEFT")
	self.chargeFrame:SetPoint("BOTTOMRIGHT", self.assignmentTimeline.scrollFrame, "BOTTOMRIGHT")

	self.splitterScrollFrame:SetParent(self.contentFrame)
	self.splitterScrollFrame:SetPoint("TOP", bossAbilityFrame, "BOTTOM")
	self.splitterScrollFrame:SetPoint("LEFT", 210, 0)
	self.splitterScrollFrame:SetPoint("RIGHT", -paddingBetweenTimelineAndScrollBar - horizontalScrollBarHeight, 0)
	self.splitterScrollFrame:SetHeight(paddingBetweenTimelines)
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

	local label = self.timelineLabels[1]
	if not label then
		label = self.splitterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.timelineLabels[1] = label
		if fontPath then
			label:SetFont(fontPath, tickFontSize)
			label:SetTextColor(unpack(tickLabelColor))
		end
		label:Hide()
		label:SetPoint("LEFT")
		label:SetText("00:00")
		self.minTickInterval = label:GetStringWidth() + minimumSpacingBetweenLabels
	end

	self.horizontalScrollBar:SetHeight(horizontalScrollBarHeight)
	self.horizontalScrollBar:SetParent(self.frame)
	self.horizontalScrollBar:SetPoint("BOTTOMLEFT", 210, 0)
	self.horizontalScrollBar:SetPoint("BOTTOMRIGHT", -horizontalScrollBarHeight - paddingBetweenTimelineAndScrollBar, 0)
	self.horizontalScrollBar:Show()

	self.thumb:SetParent(self.horizontalScrollBar)
	self.thumb:SetPoint("LEFT", thumbPadding.x, 0)
	local scrollBarThumbWidth = self.horizontalScrollBar:GetWidth() - 2 * thumbPadding.x
	local scrollBarThumbHeight = horizontalScrollBarHeight - (2 * thumbPadding.y)
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

	self.currentTimeLabel = AceGUI:Create("EPLabel")
	self.currentTimeLabel.text:SetTextColor(unpack(assignmentSelectOutlineColor))
	self.currentTimeLabel:SetFontSize(18)
	self.currentTimeLabel.frame:SetParent(self.splitterScrollFrame)
	self.currentTimeLabel.frame:SetPoint("CENTER", self.splitterScrollFrame, "LEFT", 200, 0)
	self.currentTimeLabel.frame:Hide()

	if self.fakeAssignmentFrame then
		self.fakeAssignmentFrame:SetParent(self.assignmentTimeline.timelineFrame)
		self.fakeAssignmentFrame:ClearAllPoints()
		self.fakeAssignmentFrame:Hide()
	end

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
	self.currentTimeLabel:Release()
	self.currentTimeLabel = nil

	for _, frame in ipairs(self.assignmentFrames) do
		frame:ClearAllPoints()
		frame:Hide()
		frame:SetScript("OnUpdate", nil)
		frame.spellTexture:SetTexture(nil)
		SetAssignmentFrameOutline(frame, HighlightType.None, 2)
		if frame.chargeMarker then
			frame.chargeMarker:ClearAllPoints()
			frame.chargeMarker:Hide()
		end

		frame.spellID = nil
		frame.uniqueAssignmentID = nil
		frame.timelineAssignment = nil
		frame.selectionType = AssignmentSelectionType.kNone
	end

	for _, frame in ipairs(self.bossAbilityFrames) do
		frame:ClearAllPoints()
		frame:Hide()
		frame.spellTexture:SetTexture(nil)
		frame.abilityInstance = nil
		frame:SetBackdropBorderColor(unpack(assignmentOutlineColor))
		frame.selectionType = BossAbilitySelectionType.kNone
	end

	for _, textureGroup in ipairs(self.bossPhaseIndicators) do
		for _, texture in ipairs(textureGroup) do
			texture:ClearAllPoints()
			texture:Hide()
			texture.label:ClearAllPoints()
			texture.label:Hide()
		end
	end

	for _, label in pairs(self.timelineLabels) do
		label:ClearAllPoints()
		label:Hide()
		label.wantsToShow = nil
	end

	self.phaseNameFrame:ClearAllPoints()
	self.phaseNameFrame:SetParent(UIParent)
	self.phaseNameFrame:Hide()

	self.fakeAssignmentFrame:ClearAllPoints()
	self.fakeAssignmentFrame:SetParent(UIParent)
	self.fakeAssignmentFrame:Hide()
	self.fakeAssignmentFrame:SetWidth(0)
	self.fakeAssignmentFrame.cooldownFrame:Hide()
	self.fakeAssignmentFrame.spellTexture:SetTexture(nil)
	SetAssignmentFrameOutline(self.fakeAssignmentFrame, HighlightType.None, 2)
	if self.fakeAssignmentFrame.chargeMarker then
		self.fakeAssignmentFrame.chargeMarker:ClearAllPoints()
		self.fakeAssignmentFrame.chargeMarker:Hide()
	end
	self.fakeAssignmentFrame.spellID = nil
	self.fakeAssignmentFrame.uniqueAssignmentID = nil
	self.fakeAssignmentFrame.timelineAssignment = nil

	self.orderedWithSpellIDAssignmentFrameIndices = nil
	self.bossAbilityOrder = nil
	self.bossPhaseOrder = nil
	self.bossPhases = nil
	self.timelineAssignments = nil
	self.assigneesAndSpells = nil
	self.bossAbilityVisibility = nil
	self.collapsed = nil
	self.allowHeightResizing = nil
	self.bossAbilityDimensions = nil
	self.assignmentDimensions = nil
	self.preferences = nil
	self.CalculateAssignmentTimeFromStart = nil
	self.GetMinimumCombatLogEventTime = nil
	self.ComputeChargeStates = nil
	ResetLocalVariables()
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

	totalTimelineDuration = 0.0
	for _, phaseData in pairs(self.bossPhases) do
		totalTimelineDuration = totalTimelineDuration + (phaseData.duration * phaseData.count)
	end

	for bossPhaseOrderIndex, _ in pairs(self.bossPhaseOrder) do
		if not self.bossPhaseIndicators[bossPhaseOrderIndex] then
			self.bossPhaseIndicators[bossPhaseOrderIndex] = {}
			self.bossPhaseIndicators[bossPhaseOrderIndex][1] = CreatePhaseIndicatorTexture(self) -- start of phase
			self.bossPhaseIndicators[bossPhaseOrderIndex][2] = CreatePhaseIndicatorTexture(self) -- end of phase
		end
	end

	self:UpdateHeightFromBossAbilities()
	self:SetBossAbilityTimelineVerticalScroll()

	if #self.bossPhases == 0 then
		UpdateBossAbilityBars(self)
		UpdateTickMarks(self)
	end
end

---@param self EPTimeline
---@param assignments table<integer, TimelineAssignment>
---@param assigneesAndSpells table<integer, {assignee:string, spellID:number|nil}>
---@param collapsed table<string, boolean>
local function SetAssignments(self, assignments, assigneesAndSpells, collapsed)
	self.timelineAssignments = assignments
	self.assigneesAndSpells = assigneesAndSpells
	self.collapsed = collapsed

	self:UpdateHeightFromAssignments()
	self:SetAssignmentTimelineVerticalScroll()
end

-- Only here to preserve ordering of local functions...
---@param self EPTimeline
local function UpdateAssignmentsAndTickMarks(self)
	UpdateAssignments(self)
	UpdateTickMarks(self)
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
---@param skipUpdateAssignments boolean?
---@param skipUpdateBossAbilityBars boolean?
---@param skipUpdateTickMarks boolean?
local function UpdateTimeline(self, skipUpdateAssignments, skipUpdateBossAbilityBars, skipUpdateTickMarks)
	if not totalTimelineDuration or totalTimelineDuration <= 0 then
		return
	end
	if self.bossAbilityTimeline.scrollFrame:GetWidth() == 0 then
		return
	end

	local bossAbilityScrollFrame = self.bossAbilityTimeline.scrollFrame
	local bossAbilityTimelineFrame = self.bossAbilityTimeline.timelineFrame
	local timelineWidth = bossAbilityTimelineFrame:GetWidth()
	local visibleDuration = totalTimelineDuration / self.zoomFactor
	local visibleStartTime = bossAbilityScrollFrame:GetHorizontalScroll() / timelineWidth * totalTimelineDuration
	local visibleEndTime = visibleStartTime + visibleDuration
	local newVisibleStartTime, newVisibleEndTime

	if self.preferences.zoomCenteredOnCursor then
		local frameLeft = bossAbilityTimelineFrame:GetLeft() or 0
		local relativeCursorOffset = (GetCursorPosition() or 0) / UIParent:GetEffectiveScale() - frameLeft

		-- Convert offset to time, accounting for padding
		local padding = timelineLinePadding.x
		local effectiveTimelineWidth = timelineWidth - (padding * 2)
		local cursorTime = (relativeCursorOffset - padding) * totalTimelineDuration / effectiveTimelineWidth

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
	elseif newVisibleEndTime > totalTimelineDuration then
		-- Add overflow from end time to start time to prevent empty space between end of timeline and scroll frame
		local overflow = totalTimelineDuration - newVisibleEndTime
		-- newVisibleEndTime = totalTimelineDuration
		newVisibleStartTime = newVisibleStartTime + overflow
	end

	-- Ensure boundaries are within the total timeline range
	newVisibleStartTime = max(0, newVisibleStartTime)
	-- newVisibleEndTime = min(totalTimelineDuration, newVisibleEndTime)

	-- Adjust the timeline frame width based on zoom factor
	local scrollFrameWidth = bossAbilityScrollFrame:GetWidth()
	local newTimelineFrameWidth = max(scrollFrameWidth, scrollFrameWidth * self.zoomFactor)

	-- Recalculate the new scroll position based on the new visible start time
	local newHorizontalScroll = (newVisibleStartTime / totalTimelineDuration) * newTimelineFrameWidth

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
		UpdateAssignments(self)
	end
	if not skipUpdateBossAbilityBars then
		UpdateBossAbilityBars(self)
	end
	if not skipUpdateTickMarks then
		UpdateTickMarks(self)
	end
end

-- Sets the height of the widget based assignment frames
---@param self EPTimeline
local function UpdateHeightFromAssignments(self)
	CalculateMinMaxStepAssignmentHeight(self)
	self.assignmentTimeline:SetTextureHeight(self.preferences.timelineRows.assignmentHeight)
	local height = paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
		+ self.bossAbilityTimeline.frame:GetHeight()

	local assignmentFrameHeight = self.assignmentTimeline.frame:GetHeight()
	local numberToShow = self.preferences.timelineRows.numberOfAssignmentsToShow
	local preferredAssignmentHeight = numberToShow * self.assignmentDimensions.step
	if numberToShow > 1 then
		preferredAssignmentHeight = preferredAssignmentHeight - paddingBetweenAssignments
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
	self.bossAbilityTimeline:SetTextureHeight(self.preferences.timelineRows.bossAbilityHeight)
	local height = paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
		+ self.assignmentTimeline.frame:GetHeight()
	local bossFrameHeight = self.bossAbilityTimeline.frame:GetHeight()
	local numberToShow = self.preferences.timelineRows.numberOfBossAbilitiesToShow
	local preferredBossHeight = numberToShow * self.bossAbilityDimensions.step
	if numberToShow > 1 then
		preferredBossHeight = preferredBossHeight - paddingBetweenBossAbilityBars
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
	local height = paddingBetweenTimelines
		+ paddingBetweenTimelineAndScrollBar
		+ horizontalScrollBarHeight
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
	local newContentFrameHeight = height - paddingBetweenTimelineAndScrollBar - horizontalScrollBarHeight

	if self.allowHeightResizing then
		local contentFloor = newContentFrameHeight - paddingBetweenTimelines
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
---@param assignmentIDOrAssignmentFrame integer|AssignmentFrame
---@param assignmentSelectionType AssignmentSelectionType
local function SelectAssignment(self, assignmentIDOrAssignmentFrame, assignmentSelectionType)
	local frame = nil
	if type(assignmentIDOrAssignmentFrame) == "table" then
		frame = assignmentIDOrAssignmentFrame
	else
		frame = FindAssignmentFrame(self.assignmentFrames, assignmentIDOrAssignmentFrame)
	end

	if frame then
		if assignmentSelectionType == AssignmentSelectionType.kSelection then
			SetAssignmentFrameOutline(frame, HighlightType.Full, self.preferences.timelineRows.assignmentHeight)
			frame.selectionType = assignmentSelectionType
		elseif assignmentSelectionType == AssignmentSelectionType.kBossAbilityHover then
			if frame.selectionType ~= AssignmentSelectionType.kSelection then
				SetAssignmentFrameOutline(frame, HighlightType.Half, self.preferences.timelineRows.assignmentHeight)
				frame.selectionType = assignmentSelectionType
			end
		elseif assignmentSelectionType == AssignmentSelectionType.kNone then
			SetAssignmentFrameOutline(frame, HighlightType.None, self.preferences.timelineRows.assignmentHeight)
			frame.selectionType = assignmentSelectionType
		end
	end
end

-- Returns tables of selected assignments and optionally resets assignment frames.
---@param self EPTimeline
---@param clear boolean If true, assignment frames are reset
---@return table<AssignmentSelectionType, table<integer, integer>> -- Unique assignment IDs of the selected frames
local function GetSelectedAssignments(self, clear)
	local selection, bossAbilityHover = {}, {}
	for _, frame in ipairs(self.assignmentFrames) do
		if frame.selectionType == AssignmentSelectionType.kSelection then
			selection[#selection + 1] = frame.uniqueAssignmentID
		elseif frame.selectionType == AssignmentSelectionType.kBossAbilityHover then
			bossAbilityHover[#bossAbilityHover + 1] = frame.uniqueAssignmentID
		end
		if clear then
			frame:Hide()
			frame:SetWidth(self.preferences.timelineRows.assignmentHeight)
			frame.invalidTexture:Hide()
			frame.cooldownFrame:Hide()
			frame.uniqueAssignmentID = 0
			SetAssignmentFrameOutline(frame, HighlightType.None, self.preferences.timelineRows.assignmentHeight)
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

---@param self EPTimeline
---@param assignmentID integer
---@param onlyClearIfNotSelectedByClicking boolean|nil
local function ClearSelectedAssignment(self, assignmentID, onlyClearIfNotSelectedByClicking)
	local frame = FindAssignmentFrame(self.assignmentFrames, assignmentID)
	if frame then
		if not onlyClearIfNotSelectedByClicking or frame.selectionType ~= AssignmentSelectionType.kSelection then
			SetAssignmentFrameOutline(frame, HighlightType.None, self.preferences.timelineRows.assignmentHeight)
			frame.selectionType = AssignmentSelectionType.kNone
		end
	end
end

---@param self EPTimeline
---@param spellID integer
---@param spellCount integer
---@param selectionType BossAbilitySelectionType
local function SelectBossAbility(self, spellID, spellCount, selectionType)
	local frame = FindBossAbilityFrame(self.bossAbilityFrames, spellID, spellCount)
	if frame then
		frame:SetBackdropBorderColor(unpack(assignmentSelectOutlineColor))
		if selectionType == BossAbilitySelectionType.kSelection then
			local y = select(5, frame:GetPointByName("TOPLEFT"))
			self.bossAbilityTimeline:ScrollVerticallyIfNotVisible(y, y - frame:GetHeight())
		end
		frame.selectionType = selectionType
	end
end

---@param self EPTimeline
---@param spellID integer
---@param spellCount integer
---@param onlyClearIfNotSelectedByClicking boolean|nil
local function ClearSelectedBossAbility(self, spellID, spellCount, onlyClearIfNotSelectedByClicking)
	local frame = FindBossAbilityFrame(self.bossAbilityFrames, spellID, spellCount)
	if frame then
		if not onlyClearIfNotSelectedByClicking or frame.selectionType ~= AssignmentSelectionType.kSelection then
			frame:SetBackdropBorderColor(unpack(assignmentOutlineColor))
			frame.selectionType = BossAbilitySelectionType.kNone
		end
	end
end

---@param self EPTimeline
local function ClearSelectedAssignments(self)
	for _, frame in ipairs(self.assignmentFrames) do
		SetAssignmentFrameOutline(frame, HighlightType.None, self.preferences.timelineRows.assignmentHeight)
		frame.selectionType = AssignmentSelectionType.kNone
	end
end

---@param self EPTimeline
local function ClearSelectedBossAbilities(self)
	for _, frame in ipairs(self.bossAbilityFrames) do
		frame:SetBackdropBorderColor(unpack(assignmentOutlineColor))
		frame.selectionType = BossAbilitySelectionType.kNone
	end
end

---@param self EPTimeline
---@param assignmentID integer
local function ScrollAssignmentIntoView(self, assignmentID)
	local frame = FindAssignmentFrame(self.assignmentFrames, assignmentID)
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
			assignmentHeight = assignmentHeight - paddingBetweenAssignments
		end

		local barHeight = self.bossAbilityTimeline.frame:GetHeight()
		local barProximity = barHeight % self.bossAbilityDimensions.step
		if barProximity < self.bossAbilityDimensions.step / 2.0 then
			barHeight = barHeight - barProximity
		else
			barHeight = barHeight + (self.bossAbilityDimensions.step - barProximity)
		end
		if barHeight >= self.bossAbilityDimensions.step then
			barHeight = barHeight - paddingBetweenBossAbilityBars
		end

		assignmentHeight = Clamp(assignmentHeight, self.assignmentDimensions.min, self.assignmentDimensions.max)
		barHeight = Clamp(barHeight, self.bossAbilityDimensions.min, self.bossAbilityDimensions.max)

		self.assignmentTimeline:SetHeight(assignmentHeight)
		self.bossAbilityTimeline:SetHeight(barHeight)

		local numberOfAssignmentsToShow =
			floor((assignmentHeight + paddingBetweenAssignments + 0.5) / self.assignmentDimensions.step)
		numberOfAssignmentsToShow = max(minimumNumberOfAssignmentRows, numberOfAssignmentsToShow)
		self.preferences.timelineRows.numberOfAssignmentsToShow = numberOfAssignmentsToShow

		local numberOfBossAbilitiesToShow =
			floor((barHeight + paddingBetweenBossAbilityBars + 0.5) / self.bossAbilityDimensions.step)
		numberOfBossAbilitiesToShow = max(minimumNumberOfBossAbilityRows, numberOfBossAbilitiesToShow)
		self.preferences.timelineRows.numberOfBossAbilitiesToShow = numberOfBossAbilitiesToShow

		local totalHeight = paddingBetweenTimelineAndScrollBar
			+ horizontalScrollBarHeight
			+ paddingBetweenTimelines
			+ barHeight
			+ assignmentHeight

		self:SetHeight(totalHeight)
		self:UpdateTimeline()
	end
end

---@param self EPTimeline
---@param preferences Preferences
local function SetPreferences(self, preferences)
	self.preferences = preferences
	if not self.fakeAssignmentFrame then
		local fakeAssignmentFrame = CreateAssignmentFrame(self, 0, self.frame, 0, 0)
		fakeAssignmentFrame:SetParent(self.assignmentTimeline.timelineFrame)
		fakeAssignmentFrame:SetScript("OnMouseDown", nil)
		fakeAssignmentFrame:SetScript("OnMouseUp", nil)
		fakeAssignmentFrame:Hide()
		fakeAssignmentFrame.assignmentFrame = nil
		self.fakeAssignmentFrame = fakeAssignmentFrame --[[@as FakeAssignmentFrame]]
	end
end

---@return number
local function GetTotalTimelineDuration()
	return totalTimelineDuration
end

---@param self EPTimeline
---@param simulating boolean
local function SetIsSimulating(self, simulating)
	isSimulating = simulating
	if simulating then
		simulationStartTime = GetTime()
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
			local horizontalOffset = ConvertTimeToTimelineOffset(GetTime() - simulationStartTime, timelineFrameWidth)
			horizontalOffset = bossAbilityTimelineFrame:GetLeft() - bossAbilityFrame:GetLeft() + horizontalOffset

			bossAbilityLine:SetPoint("TOP", bossAbilityFrame, "TOPLEFT", horizontalOffset, 0)
			bossAbilityLine:SetPoint("BOTTOM", bossAbilityFrame, "BOTTOMLEFT", horizontalOffset, 0)
			bossAbilityLine:Show()

			assignmentLine:SetPoint("TOP", assignmentFrame, "TOPLEFT", horizontalOffset, 0)
			assignmentLine:SetPoint("BOTTOM", assignmentFrame, "BOTTOMLEFT", horizontalOffset, 0)
			assignmentLine:Show()

			UpdateTimeLabels(self)
		end)
	else
		simulationStartTime = 0.0
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
		UpdateTimeLabels(self)
	end
end

---@param self EPTimeline
local function GetOffsetFromTime(self, time)
	if not time or time < 0 then
		return 0
	end

	local timelineFrame = self.assignmentTimeline.timelineFrame
	local timelineFrameWidth = timelineFrame:GetWidth()

	if totalTimelineDuration <= 0 then
		return 0
	end

	-- Convert time to an offset percentage
	local offsetPercent = time / totalTimelineDuration

	-- Apply padding adjustments
	local padding = timelineLinePadding.x
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
	contentFrame:SetSize(frameWidth, frameHeight - horizontalScrollBarHeight - paddingBetweenTimelineAndScrollBar)

	local splitterScrollFrame = CreateFrame("ScrollFrame", Type .. "SplitterScrollFrame" .. count, contentFrame)
	splitterScrollFrame:SetHeight(paddingBetweenTimelines)
	splitterScrollFrame:SetClipsChildren(true)

	local splitterFrame = CreateFrame("Frame", Type .. "SplitterFrame" .. count, splitterScrollFrame)
	splitterFrame:SetHeight(paddingBetweenTimelines)
	splitterScrollFrame:SetScrollChild(splitterFrame)

	local horizontalScrollBar = CreateFrame("Frame", Type .. "HorizontalScrollBar" .. count, frame)
	horizontalScrollBar:SetSize(frameWidth, horizontalScrollBarHeight)

	local scrollBarBackground = horizontalScrollBar:CreateTexture(Type .. "ScrollBarBackground" .. count, "BACKGROUND")
	scrollBarBackground:SetAllPoints()
	scrollBarBackground:SetColorTexture(unpack(scrollBackgroundColor))

	local thumb = CreateFrame("Button", Type .. "ScrollBarThumb" .. count, horizontalScrollBar)
	thumb:SetPoint("LEFT", thumbPadding.x, 0)
	thumb:SetSize(horizontalScrollBar:GetWidth() - 2 * thumbPadding.x, horizontalScrollBarHeight - (2 * thumbPadding.y))
	thumb:EnableMouse(true)
	thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local thumbBackground = thumb:CreateTexture(Type .. "ScrollBarThumbBackground" .. count, "BACKGROUND")
	thumbBackground:SetAllPoints()
	thumbBackground:SetColorTexture(unpack(scrollThumbBackgroundColor))

	local phaseNameFrame = CreateFrame("Frame", nil, frame)
	phaseNameFrame:SetClipsChildren(true)

	local chargeFrame = CreateFrame("Frame", nil, frame)
	chargeFrame:SetClipsChildren(true)

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
		UpdateHeightFromBossAbilities = UpdateHeightFromBossAbilities,
		UpdateHeightFromAssignments = UpdateHeightFromAssignments,
		UpdateAssignmentsAndTickMarks = UpdateAssignmentsAndTickMarks,
		GetTotalTimelineDuration = GetTotalTimelineDuration,
		SetIsSimulating = SetIsSimulating,
		GetSelectedAssignments = GetSelectedAssignments,
		ScrollAssignmentIntoView = ScrollAssignmentIntoView,
		ConvertTimeToTimelineOffset = ConvertTimeToTimelineOffset,
		FindTimelineAssignment = FindTimelineAssignment,
		GetOffsetFromTime = GetOffsetFromTime,
		SetHorizontalScroll = SetHorizontalScroll,
		SetAssignmentTimelineVerticalScroll = SetAssignmentTimelineVerticalScroll,
		SetBossAbilityTimelineVerticalScroll = SetBossAbilityTimelineVerticalScroll,
		DrawAssignment = DrawAssignment,
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
