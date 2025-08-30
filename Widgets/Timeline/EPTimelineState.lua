local _, Namespace = ...

---@class Private
local Private = Namespace

---@class EPTimelineState
local s = {
	AssignmentBeingDuplicated = false,
	AssignmentFrameBeingDragged = nil, ---@type AssignmentFrame|nil
	AssignmentIsDragging = false,
	HorizontalCursorAssignmentFrameOffsetWhenClicked = 0,
	HorizontalCursorPositionWhenAssignmentFrameClicked = 0,
	IsSimulating = false,
	LastExecutionTime = 0.0,
	ScrollBarWidthWhenThumbClicked = 0.0,
	SelectedAssignmentIDsFromBossAbilityFrameEnter = {},
	SimulationStartTime = 0.0,
	ThumbIsDragging = false,
	ThumbOffsetWhenThumbClicked = 0.0,
	ThumbWidthWhenThumbClicked = 0.0,
	TimelineFrameIsDragging = false,
	TimelineFrameOffsetWhenDragStarted = 0.0,
	TotalTimelineDuration = 0.0,

	Reset = function(self)
		self.AssignmentBeingDuplicated = false
		self.AssignmentFrameBeingDragged = nil
		self.AssignmentIsDragging = false
		self.HorizontalCursorAssignmentFrameOffsetWhenClicked = 0
		self.HorizontalCursorPositionWhenAssignmentFrameClicked = 0
		self.IsSimulating = false
		self.LastExecutionTime = 0.0
		self.ScrollBarWidthWhenThumbClicked = 0.0
		self.SelectedAssignmentIDsFromBossAbilityFrameEnter = {}
		self.SimulationStartTime = 0.0
		self.ThumbIsDragging = false
		self.ThumbOffsetWhenThumbClicked = 0.0
		self.ThumbWidthWhenThumbClicked = 0.0
		self.TimelineFrameIsDragging = false
		self.TimelineFrameOffsetWhenDragStarted = 0
		self.TotalTimelineDuration = 0.0
	end,
}

Private.timeline.state = s
