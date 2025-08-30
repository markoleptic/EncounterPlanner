local _, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants

local LSM = LibStub("LibSharedMedia-3.0")

---@class EPTimelineConstants
local k = {
	AssignmentOutlineColor = { 0.25, 0.25, 0.25, 1 },
	AssignmentSelectOutlineColor = { 1, 0.82, 0, 1 },
	AssignmentTextureSubLevel = 0,
	BossAbilityColors = {
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
	},
	BossAbilityTextureSubLevel = 0,
	CooldownBackgroundColor = { 0.25, 0.25, 0.25, 1 },
	CooldownPadding = 1,
	CooldownTextureAlpha = 0.5,
	CooldownTextureFile = [[Interface\AddOns\EncounterPlanner\Media\DiagonalLine]],
	CooldownWidthTolerance = 0.01,
	DefaultTickWidth = 2,
	FontPath = LSM:Fetch("font", "PT Sans Narrow"),
	FrameHeight = 400,
	FrameWidth = 900,
	---@enum HighlightType
	HighlightType = {
		None = 1,
		Full = 2,
		Half = 3,
	},
	HorizontalScrollBarHeight = constants.timeline.kHorizontalScrollBarHeight,
	InvalidTextureColor = { 0.8, 0.1, 0.1, 0.4 },
	InvalidAssignmentSpellID = constants.kInvalidAssignmentSpellID,
	MaxZoomFactor = 10,
	MinimumBossAbilityWidth = 10,
	MinimumNumberOfAssignmentRows = 2,
	MinimumNumberOfBossAbilityRows = 2,
	MinimumSpacingBetweenLabels = 4,
	MinZoomFactor = 1,
	NonTimelineHeight = constants.timeline.kHorizontalScrollBarHeight
		+ constants.timeline.kPaddingBetweenTimelineAndScrollBar
		+ constants.timeline.kPaddingBetweenTimelines
		+ constants.kStatusBarHeight
		+ constants.kStatusBarPadding
		+ constants.kWindowBarHeight
		+ constants.kMainFramePadding[2]
		+ constants.kMainFramePadding[4]
		+ constants.kTopContainerHeight
		+ constants.kMainFrameSpacing[2],
	PaddingBetweenAssignments = 2,
	PaddingBetweenBossAbilityBars = 2,
	PaddingBetweenTimelineAndScrollBar = constants.timeline.kPaddingBetweenTimelineAndScrollBar,
	PaddingBetweenTimelines = constants.timeline.kPaddingBetweenTimelines,
	PhaseIndicatorColor = { 1, 0.82, 0, 1 },
	PhaseIndicatorFontSize = 12,
	PhaseIndicatorTexture = [[Interface\AddOns\EncounterPlanner\Media\icons8-checkered-50]],
	PhaseIndicatorWidth = 2,
	ScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 },
	ScrollThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 },
	SpellChargeRestorationColor = { 0.4, 1, 0.8, 1 },
	TextAssignmentSpellID = constants.kTextAssignmentSpellID,
	TextAssignmentTexture = constants.kTextAssignmentTexture,
	ThrottleInterval = 0.015, -- Minimum time between executions, in seconds
	ThumbPadding = { x = 2, y = 2 },
	TickColor = { 1, 1, 1, 0.75 },
	TickFontSize = 12,
	TickIntervals = { 5, 10, 30, 60, 90 },
	TickLabelColor = { 1, 1, 1, 1 },
	TimelineLinePadding = { x = 25, y = 25 },
	UnknownIcon = constants.kUnknownIcon,
	ZoomStep = 0.05,
}

Private.timeline.constants = k
