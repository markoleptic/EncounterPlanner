local _, Namespace = ...

---@class Private
local Private = Namespace
---@class EPTimelineConstants
local k = Private.timeline.constants
---@class EPTimelineState
local s = Private.timeline.state

---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment
local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType

---@class EPTimelineBossAbility
local EPTimelineBossAbility = Private.timeline.bossAbility

local ClearSelectedAssignment = Private.timeline.utilities.ClearSelectedAssignment
local ClearSelectedBossAbility = Private.timeline.utilities.ClearSelectedBossAbility
local SelectAssignment = Private.timeline.utilities.SelectAssignment
local SelectBossAbility = Private.timeline.utilities.SelectBossAbility

local CreateFrame = CreateFrame
local getmetatable = getmetatable
local ipairs = ipairs
local max = math.max
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local unpack = unpack
local wipe = wipe

local function ClearSelectedAssignmentsFromBossAbilityFrameEnter()
	for _, assignmentID in ipairs(s.SelectedAssignmentIDsFromBossAbilityFrameEnter) do
		ClearSelectedAssignment(assignmentID, true)
	end
	wipe(s.SelectedAssignmentIDsFromBossAbilityFrameEnter)
end

---@param frame BossAbilityFrame
local function HandleBossAbilityFrameEnter(frame)
	if not frame.abilityInstance then
		return
	end
	local spellID = frame.abilityInstance.bossAbilitySpellID
	local spellCount = frame.abilityInstance.spellCount
	if #s.SelectedAssignmentIDsFromBossAbilityFrameEnter > 0 then
		ClearSelectedAssignmentsFromBossAbilityFrameEnter()
	end
	for _, timelineAssignment in ipairs(s.TimelineAssignments) do
		local assignment = timelineAssignment.assignment
		if getmetatable(assignment) == CombatLogEventAssignment then
			---@cast assignment CombatLogEventAssignment
			if assignment.combatLogEventSpellID == spellID and assignment.spellCount == spellCount then
				tinsert(s.SelectedAssignmentIDsFromBossAbilityFrameEnter, assignment.uniqueID)
			end
		end
	end
	SelectBossAbility(spellID, spellCount, BossAbilitySelectionType.kSelection)
	for _, assignmentID in ipairs(s.SelectedAssignmentIDsFromBossAbilityFrameEnter) do
		SelectAssignment(assignmentID, AssignmentSelectionType.kBossAbilityHover)
	end
end

---@param frame BossAbilityFrame
local function HandleBossAbilityFrameLeave(frame)
	if frame.abilityInstance then
		ClearSelectedBossAbility(frame.abilityInstance.bossAbilitySpellID, frame.abilityInstance.spellCount, true)
	end
	ClearSelectedAssignmentsFromBossAbilityFrameEnter()
end

---@param phaseNameFrame Frame
---@return BossPhaseIndicatorTexture
local function CreatePhaseIndicatorTexture(phaseNameFrame)
	local frame = s.BossAbilityTimeline.timelineFrame
	local level = k.BossAbilityTextureSubLevel - 2
	local phaseIndicator = frame:CreateTexture(nil, "BACKGROUND", nil, level) --[[@as BossPhaseIndicatorTexture]]
	phaseIndicator:SetTexture(k.PhaseIndicatorTexture, "REPEAT", "REPEAT")
	phaseIndicator:SetVertTile(true)
	phaseIndicator:SetHorizTile(true)
	phaseIndicator:SetVertexColor(unpack(k.PhaseIndicatorColor))
	phaseIndicator:SetWidth(k.PhaseIndicatorWidth)
	phaseIndicator:SetTexCoord(0.1, 1.1, 0, 1)
	phaseIndicator:Hide()

	local phaseIndicatorLabel = phaseNameFrame:CreateFontString(nil, "OVERLAY")
	if k.FontPath then
		phaseIndicatorLabel:SetFont(k.FontPath, k.PhaseIndicatorFontSize)
		phaseIndicatorLabel:SetTextColor(unpack(k.PhaseIndicatorColor))
	end
	phaseIndicatorLabel:Hide()

	phaseIndicator.label = phaseIndicatorLabel
	return phaseIndicator
end

---@param phaseNameFrame Frame
---@param index integer
---@param longName string
---@param shortName string
---@param offset number
---@param width number
---@param lastInfo table<integer, LastPhaseIndicatorInfo>
local function DrawBossPhaseIndicator(phaseNameFrame, phaseStart, index, longName, shortName, offset, width, lastInfo)
	local indicator = s.BossPhaseIndicators[index][phaseStart and 1 or 2]
	local timelineFrame = s.BossAbilityTimeline.timelineFrame

	local startHorizontalOffset = offset
	if phaseStart then
		startHorizontalOffset = startHorizontalOffset + k.PhaseIndicatorWidth
	else
		startHorizontalOffset = startHorizontalOffset + width - k.PhaseIndicatorWidth
	end

	indicator:SetPoint("TOP", timelineFrame, "TOPLEFT", startHorizontalOffset, 0)
	indicator:SetPoint("BOTTOM", timelineFrame, "BOTTOMLEFT", startHorizontalOffset, 0)
	indicator:Show()

	local label = indicator.label
	label:SetText(longName)
	label:SetPoint("TOP", phaseNameFrame, "TOP")
	label:SetPoint("BOTTOM", phaseNameFrame, "BOTTOM")

	local labelWidth = label:GetWidth()
	local partialLeft = startHorizontalOffset + k.PhaseIndicatorWidth / 2.0
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

---@param width number
---@param height number
---@param color integer[]
---@return BossAbilityFrame
local function CreateBossAbilityFrame(width, height, color)
	---@type BossAbilityFrame
	local frame = CreateFrame("Frame", nil, s.BossAbilityTimeline.timelineFrame, "BackdropTemplate")
	frame:SetSize(width, height)
	local borderSize = 2
	frame:SetBackdrop({
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = borderSize,
	})
	frame:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))

	frame:SetScript("OnEnter", HandleBossAbilityFrameEnter)
	frame:SetScript("OnLeave", HandleBossAbilityFrameLeave)

	local spellTexture = frame:CreateTexture(nil, "OVERLAY", nil, k.BossAbilityTextureSubLevel)
	spellTexture:SetPoint("TOPLEFT", borderSize, -borderSize)
	spellTexture:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
	spellTexture:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")

	local cooldownFrame = CreateFrame("Frame", nil, frame)
	cooldownFrame:SetHeight(height)
	cooldownFrame:SetClipsChildren(true)
	cooldownFrame:EnableMouse(false)

	local cooldownParent = s.BossAbilityTimeline.frame:CreateTexture(nil, "BACKGROUND")
	cooldownParent:SetPoint("TOPRIGHT", cooldownFrame, "TOPRIGHT")
	cooldownParent:SetPoint("BOTTOMRIGHT", cooldownFrame, "BOTTOMRIGHT")
	cooldownParent:SetAlpha(0)
	cooldownParent:EnableMouse(false)

	local cooldownBackground = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	cooldownBackground:SetColorTexture(unpack(color))
	cooldownBackground:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT", borderSize, -borderSize)
	cooldownBackground:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT", -borderSize, borderSize)
	cooldownBackground:EnableMouse(false)

	local cooldownTexture = cooldownFrame:CreateTexture(nil, "ARTWORK", nil, -1)
	cooldownTexture:SetTexture([[Interface\AddOns\EncounterPlanner\Media\DiagonalLineSmall]], "REPEAT", "REPEAT")
	cooldownTexture:SetSnapToPixelGrid(false)
	cooldownTexture:SetTexelSnappingBias(0)
	cooldownTexture:SetHorizTile(true)
	cooldownTexture:SetVertTile(true)
	cooldownTexture:SetPoint("TOPLEFT", cooldownParent, "TOPLEFT", borderSize, -borderSize)
	cooldownTexture:SetPoint("BOTTOMRIGHT", cooldownParent, "BOTTOMRIGHT", -borderSize, borderSize)
	cooldownTexture:SetAlpha(k.CooldownTextureAlpha)
	cooldownTexture:EnableMouse(false)

	local lineTexture = frame:CreateTexture(nil, "OVERLAY", nil, k.BossAbilityTextureSubLevel + 1)
	lineTexture:SetColorTexture(unpack(k.AssignmentOutlineColor))
	lineTexture:SetWidth(borderSize)
	lineTexture:Hide()

	frame.spellTexture = spellTexture
	frame.cooldownBackground = cooldownBackground
	frame.cooldownTexture = cooldownTexture
	frame.cooldownParent = cooldownParent
	frame.cooldownFrame = cooldownFrame
	frame.selectionType = BossAbilitySelectionType.kNone
	frame.lineTexture = lineTexture

	return frame
end

-- Helper function to draw a boss ability timeline bar.
---@param abilityInstance BossAbilityInstance Ability instance data for this ability instance.
---@param horizontalOffset number Horizontal offset from the boss ability timeline frame.
---@param verticalOffset number Vertical offset from the boss ability timeline frame.
---@param width number Width of the boss ability bar.
---@param baseFrameLevel integer Base frame level.
---@param index integer Index into boss ability frames.
---@param rowIndex integer Index (starting from 1) of the row, where 1 is the first boss ability row
local function DrawBossAbilityFrame(
	abilityInstance,
	horizontalOffset,
	verticalOffset,
	width,
	baseFrameLevel,
	index,
	rowIndex
)
	local height = s.Preferences.timelineRows.bossAbilityHeight
	if abilityInstance.overlaps then
		verticalOffset = verticalOffset + abilityInstance.overlaps.offset * height
		height = height * abilityInstance.overlaps.heightMultiplier
	end

	local color = k.BossAbilityColors[((rowIndex - 1) % #k.BossAbilityColors) + 1]
	local frame = s.BossAbilityFrames[index]
	if not frame then
		s.BossAbilityFrames[index] = CreateBossAbilityFrame(width, height, color)
		frame = s.BossAbilityFrames[index]
	end

	frame.abilityInstance = abilityInstance

	local castDuration = abilityInstance.castEnd - abilityInstance.castStart
	local effectDuration = abilityInstance.effectEnd - abilityInstance.castEnd
	local totalDuration = castDuration + effectDuration

	local castWidthPercentage = 0
	if totalDuration > 0 then
		castWidthPercentage = castDuration / totalDuration
	end

	local borderSize = 2

	local line = frame.lineTexture
	local cooldownFrame = frame.cooldownFrame
	if effectDuration > 0 then
		local castLeft = (width - borderSize) * castWidthPercentage

		if castDuration > 0 then
			line:SetHeight(height - (2 * borderSize))
			line:ClearAllPoints()
			line:SetPoint("LEFT", frame, "LEFT", castLeft, 0)
			line:Show()
		else
			line:Hide()
		end

		cooldownFrame:ClearAllPoints()
		cooldownFrame:SetHeight(height)
		cooldownFrame:SetPoint("LEFT", castLeft + borderSize, 0)
		cooldownFrame:SetPoint("RIGHT")
		frame.cooldownParent:SetPoint("LEFT", -verticalOffset, 0)
		frame.cooldownBackground:SetColorTexture(unpack(color))
		cooldownFrame:Show()
	else
		line:Hide()
		cooldownFrame:Hide()
	end

	frame.spellTexture:SetColorTexture(unpack(color))
	frame:SetSize(width, height)
	frame:SetPoint("TOPLEFT", s.BossAbilityTimeline.timelineFrame, "TOPLEFT", horizontalOffset, -verticalOffset)
	frame:SetFrameLevel(baseFrameLevel + abilityInstance.frameLevel)
	frame:Show()
end

---@param bossPhaseOrder table<integer, integer>
---@param phaseNameFrame Frame
function EPTimelineBossAbility.CreateBossPhaseIndicators(bossPhaseOrder, phaseNameFrame)
	for bossPhaseOrderIndex, _ in pairs(bossPhaseOrder) do
		if not s.BossPhaseIndicators[bossPhaseOrderIndex] then
			s.BossPhaseIndicators[bossPhaseOrderIndex] = {}
			s.BossPhaseIndicators[bossPhaseOrderIndex][1] = CreatePhaseIndicatorTexture(phaseNameFrame) -- start of phase
			s.BossPhaseIndicators[bossPhaseOrderIndex][2] = CreatePhaseIndicatorTexture(phaseNameFrame) -- end of phase
		end
	end
end

---@param bossAbilityOrder table<integer, integer>
---@param bossAbilityVisibility table<integer, boolean>
---@param bossAbilityInstances table<integer, BossAbilityInstance>
---@param phaseNameFrame Frame
function EPTimelineBossAbility.UpdateBossAbilityFrames(
	bossAbilityOrder,
	bossAbilityVisibility,
	bossAbilityInstances,
	phaseNameFrame
)
	for _, frame in pairs(s.BossAbilityFrames) do
		frame:Hide()
	end
	for _, textureGroup in ipairs(s.BossPhaseIndicators) do
		for _, texture in ipairs(textureGroup) do
			texture:Hide()
			texture.label:Hide()
		end
	end

	if s.TotalTimelineDuration <= 0.0 then
		return
	end

	local offsets = {}
	local rowIndices = {}
	local rowIndex = 1
	local offset = 0

	local bossAbilityHeight = s.Preferences.timelineRows.bossAbilityHeight
	for _, bossAbilitySpellID in ipairs(bossAbilityOrder) do
		offsets[bossAbilitySpellID] = offset
		rowIndices[bossAbilitySpellID] = rowIndex
		if bossAbilityVisibility[bossAbilitySpellID] == true then
			offset = offset + bossAbilityHeight + k.PaddingBetweenBossAbilityBars
			rowIndex = rowIndex + 1
		end
	end

	local padding = k.TimelineLinePadding
	local timelineFrame = s.BossAbilityTimeline.timelineFrame
	local timelineWidth = timelineFrame:GetWidth() - 2 * padding.x
	local baseFrameLevel = timelineFrame:GetFrameLevel()

	local lastInfo = {} ---@type table<integer, LastPhaseIndicatorInfo>
	local currentIndex = 1 -- In case boss abilities are hidden, this ensures boss ability frames are indexed correctly
	for _, entry in ipairs(bossAbilityInstances) do
		local timelineStartPosition = (entry.castStart / s.TotalTimelineDuration) * timelineWidth
		local timelineEndPosition = (entry.effectEnd / s.TotalTimelineDuration) * timelineWidth
		local horizontalOffset = timelineStartPosition + padding.x
		local width = max(k.MinimumBossAbilityWidth, timelineEndPosition - timelineStartPosition)

		local index = entry.bossPhaseOrderIndex

		if entry.signifiesPhaseStart and entry.bossPhaseName and entry.bossPhaseShortName then
			local long, short = entry.bossPhaseName, entry.bossPhaseShortName
			if long and short then
				DrawBossPhaseIndicator(phaseNameFrame, true, index, long, short, horizontalOffset, width, lastInfo)
			end
		end
		if entry.signifiesPhaseEnd then
			local long, short = entry.nextBossPhaseName, entry.nextBossPhaseShortName
			if long and short then
				DrawBossPhaseIndicator(phaseNameFrame, false, index, long, short, horizontalOffset, width, lastInfo)
			end
		end

		if bossAbilityVisibility[entry.bossAbilitySpellID] == true then
			local verticalOffset = offsets[entry.bossAbilitySpellID]
			rowIndex = rowIndices[entry.bossAbilitySpellID]
			DrawBossAbilityFrame(entry, horizontalOffset, verticalOffset, width, baseFrameLevel, currentIndex, rowIndex)
			currentIndex = currentIndex + 1
		end
	end
	sort(lastInfo, function(a, b)
		return a.left < b.left
	end)
	local lastLastInfo ---@type LastPhaseIndicatorInfo|nil
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
