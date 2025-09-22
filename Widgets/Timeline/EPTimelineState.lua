local _, Namespace = ...

---@class Private
local Private = Namespace

local AceGUI = LibStub("AceGUI-3.0")
local ipairs = ipairs

---@class EPTimelineConstants
local k = Private.timeline.constants

local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType

---@class EPTimelineState
local s = {
	-- Used to determine which assignee or spell to create when the timeline is clicked, total assignment timeline
	-- height, and assignment dimensions (min/max/step).
	AssigneeSpellSets = {}, ---@type table<integer, AssigneeSpellSet>
	AssignmentBeingDuplicated = false,
	AssignmentFrameBeingDragged = nil, ---@type AssignmentFrame|nil
	AssignmentIsDragging = false,
	-- Row Index -> spellID -> [frame indices]
	AssignmentRowSpellFrameMap = nil, ---@type table<integer, table<integer, table<integer, integer>>>|nil
	AssignmentTimeline = nil, ---@type EPTimelineSection|nil
	BossAbilityTimeline = nil, ---@type EPTimelineSection|nil
	CalculateAssignmentTimeFromStart = nil, ---@type fun(timelineAssignment: TimelineAssignment): number|nil
	Collapsed = nil, ---@type table<string, boolean>
	ComputeChargeStates = nil, ---@type fun(timelineAssignments: table<integer, TimelineAssignment>)
	Fire = nil, ---@type fun(name: string, ...: any)
	GetMinimumCombatLogEventTime = nil, ---@type fun(timelineAssignment: TimelineAssignment): number|nil
	HorizontalCursorAssignmentFrameOffsetWhenClicked = 0,
	HorizontalCursorPositionWhenAssignmentFrameClicked = 0,
	IsSimulating = false,
	LastExecutionTime = 0.0,
	MainTimelineChargeFrame = nil, ---@type Frame
	MainTimelineHorizontalScrollBar = nil, ---@type Frame
	MainTimelineSplitterFrame = nil, ---@type Frame
	MainTimelineSplitterScrollFrame = nil, ---@type ScrollFrame|BackdropTemplate
	MainTimelineThumb = nil, ---@type Button
	MinTickInterval = k.MinimumSpacingBetweenLabels,
	Preferences = nil, ---@type Preferences|nil
	ScrollBarWidthWhenThumbClicked = 0.0,
	SelectedAssignmentIDsFromBossAbilityFrameEnter = {}, ---@type table<integer, string>
	SimulationStartTime = 0.0,
	ThumbIsDragging = false,
	ThumbOffsetWhenThumbClicked = 0.0,
	ThumbWidthWhenThumbClicked = 0.0,
	TimelineAssignments = nil, ---@type table<integer, TimelineAssignment>|nil
	TimelineFrameIsDragging = false,
	TimelineFrameOffsetWhenDragStarted = 0.0,
	TotalTimelineDuration = 0.0,

	-- Persistent frames created for assignments
	AssignmentFrames = {}, ---@type table<integer, AssignmentFrame>
	-- Persistent frames created for boss abilities
	BossAbilityFrames = {}, ---@type table<integer, BossAbilityFrame>
	-- Persistent frames created for boss phases
	BossPhaseIndicators = {}, ---@type table<integer, table<1|2, BossPhaseIndicatorTexture>>
	-- Persistent frame created for moving assignments
	FakeAssignmentFrame = nil, ---@type FakeAssignmentFrame|nil
	-- Persistent frames created for labeling times
	TimelineLabels = {}, ---@type table<integer, EPTimeLabel>
}

---@param self EPTimelineState
---@param splitterFrame Frame|BackdropTemplate
---@param splitterScrollFrame ScrollFrame|BackdropTemplate
---@param scrollBar Frame
---@param thumb Button
function s:Init(splitterFrame, splitterScrollFrame, chargeFrame, scrollBar, thumb)
	self.TimelineAssignments = {}
	self.AssignmentRowSpellFrameMap = {}
	self.MainTimelineSplitterFrame = splitterFrame
	self.MainTimelineSplitterScrollFrame = splitterScrollFrame
	self.MainTimelineChargeFrame = chargeFrame
	self.MainTimelineHorizontalScrollBar = scrollBar
	self.MainTimelineThumb = thumb

	if self.FakeAssignmentFrame then
		self.FakeAssignmentFrame:SetParent(self.AssignmentTimeline.timelineFrame)
		self.FakeAssignmentFrame:ClearAllPoints()
		self.FakeAssignmentFrame:Hide()
	end

	local label = s.TimelineLabels[1]
	if not label then
		---@type EPTimeLabel
		label = splitterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		s.TimelineLabels[1] = label
		if k.FontPath then
			label:SetFont(k.FontPath, k.TickFontSize)
			label:SetTextColor(unpack(k.TickLabelColor))
		end
		label:Hide()
		label:SetPoint("LEFT")
		label:SetText("00:00")
	end
	self.MinTickInterval = label:GetStringWidth() + k.MinimumSpacingBetweenLabels

	self.CurrentTimeLabel = AceGUI:Create("EPLabel")
	self.CurrentTimeLabel.text:SetTextColor(unpack(k.AssignmentSelectOutlineColor))
	self.CurrentTimeLabel:SetFontSize(18)
	self.CurrentTimeLabel.frame:SetParent(splitterScrollFrame)
	self.CurrentTimeLabel.frame:SetPoint("CENTER", splitterScrollFrame, "LEFT", 200, 0)
	self.CurrentTimeLabel.frame:Hide()
end

---@param self EPTimelineState
---@param fire fun(name: string, ...: any)
---@param calculateAssignmentTimeFromStart fun(timelineAssignment: TimelineAssignment): number|nil
---@param getMinimumCombatLogEventTime fun(timelineAssignment: TimelineAssignment): number|nil
---@param computeChargeStates fun(timelineAssignments: table<integer, TimelineAssignment>)
function s:SetFunctionReferences(
	fire,
	calculateAssignmentTimeFromStart,
	getMinimumCombatLogEventTime,
	computeChargeStates
)
	self.Fire = fire
	self.CalculateAssignmentTimeFromStart = calculateAssignmentTimeFromStart
	self.GetMinimumCombatLogEventTime = getMinimumCombatLogEventTime
	self.ComputeChargeStates = computeChargeStates
end

---@param self EPTimelineState
---@param preferences Preferences
function s:SetPreferences(preferences)
	self.Preferences = preferences
	if not self.FakeAssignmentFrame then
		local fakeAssignmentFrame = Private.timeline.assignment.CreateAssignmentFrame(0, 0, 0)
		fakeAssignmentFrame:SetParent(self.AssignmentTimeline.timelineFrame)
		fakeAssignmentFrame:SetScript("OnMouseDown", nil)
		fakeAssignmentFrame:SetScript("OnMouseUp", nil)
		fakeAssignmentFrame:Hide()
		fakeAssignmentFrame.assignmentFrame = nil
		self.FakeAssignmentFrame = fakeAssignmentFrame --[[@as FakeAssignmentFrame]]
	end
end

---@param self EPTimelineState
---@param assignments table<integer, TimelineAssignment>
---@param collapsed table<string, boolean>
---@param assigneeAndSpellSets table<integer, AssigneeSpellSet>
function s:SetAssignments(assignments, collapsed, assigneeAndSpellSets)
	self.TimelineAssignments = assignments
	self.Collapsed = collapsed
	self.AssigneeSpellSets = assigneeAndSpellSets
end

---@param self EPTimelineState
---@param assignmentTimeline EPTimelineSection
---@param bossAbilityTimeline EPTimelineSection
function s:SetTimelineSections(assignmentTimeline, bossAbilityTimeline)
	self.AssignmentTimeline = assignmentTimeline
	self.BossAbilityTimeline = bossAbilityTimeline
end

---@param self EPTimelineState
function s:Reset()
	self.AssigneeSpellSets = {}
	local SetAssignmentFrameOutline = Private.timeline.utilities.SetAssignmentFrameOutline

	for _, frame in ipairs(self.AssignmentFrames) do
		frame:ClearAllPoints()
		frame:Hide()
		frame:SetScript("OnUpdate", nil)
		frame.spellTexture:SetTexture(nil)
		SetAssignmentFrameOutline(frame, k.HighlightType.None, 2)
		if frame.chargeMarker then
			frame.chargeMarker:ClearAllPoints()
			frame.chargeMarker:Hide()
		end

		frame.spellID = nil
		frame.uniqueAssignmentID = nil
		frame.timelineAssignment = nil
		frame.selectionType = AssignmentSelectionType.kNone
	end

	self.FakeAssignmentFrame:ClearAllPoints()
	self.FakeAssignmentFrame:SetParent(UIParent)
	self.FakeAssignmentFrame:Hide()
	self.FakeAssignmentFrame:SetWidth(0)
	self.FakeAssignmentFrame.cooldownFrame:Hide()
	self.FakeAssignmentFrame.spellTexture:SetTexture(nil)
	SetAssignmentFrameOutline(self.FakeAssignmentFrame, k.HighlightType.None, 2)
	if self.FakeAssignmentFrame.chargeMarker then
		self.FakeAssignmentFrame.chargeMarker:ClearAllPoints()
		self.FakeAssignmentFrame.chargeMarker:Hide()
	end
	self.FakeAssignmentFrame.spellID = nil
	self.FakeAssignmentFrame.uniqueAssignmentID = nil
	self.FakeAssignmentFrame.timelineAssignment = nil

	for _, frame in ipairs(self.BossAbilityFrames) do
		frame:ClearAllPoints()
		frame:Hide()
		frame.spellTexture:SetTexture(nil)
		frame.abilityInstance = nil
		frame:SetBackdropBorderColor(unpack(k.AssignmentOutlineColor))
		frame.selectionType = BossAbilitySelectionType.kNone
	end

	for _, textureGroup in ipairs(self.BossPhaseIndicators) do
		for _, texture in ipairs(textureGroup) do
			texture:ClearAllPoints()
			texture:Hide()
			texture.label:ClearAllPoints()
			texture.label:Hide()
		end
	end

	for _, label in pairs(self.TimelineLabels) do
		label:ClearAllPoints()
		label:Hide()
		label.wantsToShow = nil
	end

	self.CurrentTimeLabel:Release()

	self.AssignmentBeingDuplicated = false
	self.AssignmentFrameBeingDragged = nil
	self.AssignmentIsDragging = false
	self.BossAbilityTimeline = nil
	self.CalculateAssignmentTimeFromStart = nil
	self.Collapsed = nil
	self.ComputeChargeStates = nil
	self.CurrentTimeLabel = nil
	self.Fire = nil
	self.GetMinimumCombatLogEventTime = nil
	self.HorizontalCursorAssignmentFrameOffsetWhenClicked = 0
	self.HorizontalCursorPositionWhenAssignmentFrameClicked = 0
	self.IsSimulating = false
	self.LastExecutionTime = 0.0
	self.MainTimelineChargeFrame = nil
	self.MainTimelineHorizontalScrollBar = nil
	self.MainTimelineSplitterFrame = nil
	self.MainTimelineSplitterScrollFrame = nil
	self.MainTimelineThumb = nil
	self.MinTickInterval = k.MinimumSpacingBetweenLabels
	self.AssignmentRowSpellFrameMap = nil
	self.Preferences = nil
	self.ScrollBarWidthWhenThumbClicked = 0.0
	self.SelectedAssignmentIDsFromBossAbilityFrameEnter = {}
	self.SimulationStartTime = 0.0
	self.ThumbIsDragging = false
	self.ThumbOffsetWhenThumbClicked = 0.0
	self.ThumbWidthWhenThumbClicked = 0.0
	self.TimelineAssignments = nil
	self.TimelineFrameIsDragging = false
	self.TimelineFrameOffsetWhenDragStarted = 0
	self.TotalTimelineDuration = 0.0
end

Private.timeline.state = s
