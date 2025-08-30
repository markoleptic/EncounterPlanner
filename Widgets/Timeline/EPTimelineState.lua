local _, Namespace = ...

---@class Private
local Private = Namespace

local ipairs = ipairs

---@class EPTimelineConstants
local k = Private.timeline.constants

local AssignmentSelectionType = Private.constants.AssignmentSelectionType
local BossAbilitySelectionType = Private.constants.BossAbilitySelectionType

---@class EPTimelineState
local s = {
	AssignmentBeingDuplicated = false,
	AssignmentFrameBeingDragged = nil, ---@type AssignmentFrame|nil
	AssignmentIsDragging = false,
	BossAbilityTimeline = nil, ---@type EPTimelineSection|nil
	HorizontalCursorAssignmentFrameOffsetWhenClicked = 0,
	HorizontalCursorPositionWhenAssignmentFrameClicked = 0,
	IsSimulating = false,
	LastExecutionTime = 0.0,
	Preferences = nil, ---@type Preferences|nil
	ScrollBarWidthWhenThumbClicked = 0.0,
	SelectedAssignmentIDsFromBossAbilityFrameEnter = {},
	SimulationStartTime = 0.0,
	ThumbIsDragging = false,
	ThumbOffsetWhenThumbClicked = 0.0,
	ThumbWidthWhenThumbClicked = 0.0,
	TimelineAssignments = nil, ---@type table<integer, TimelineAssignment>|nil
	TimelineFrameIsDragging = false,
	TimelineFrameOffsetWhenDragStarted = 0.0,
	TotalTimelineDuration = 0.0,

	AssignmentFrames = {}, ---@type table<integer, AssignmentFrame>
	BossAbilityFrames = {}, ---@type table<integer, BossAbilityFrame>
	BossPhaseIndicators = {}, ---@type table<integer, table<1|2, BossPhaseIndicatorTexture>>
}

function s:Init()
	self.TimelineAssignments = {}
end

function s:Reset()
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
	self.AssignmentBeingDuplicated = false
	self.AssignmentFrameBeingDragged = nil
	self.AssignmentIsDragging = false
	self.BossAbilityTimeline = nil
	self.HorizontalCursorAssignmentFrameOffsetWhenClicked = 0
	self.HorizontalCursorPositionWhenAssignmentFrameClicked = 0
	self.IsSimulating = false
	self.LastExecutionTime = 0.0
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
