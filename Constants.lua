local _, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
Private.constants = {
	kInvalidAssignmentSpellID = 0,
	kTextAssignmentSpellID = 1,
	kTextAssignmentTexture = 1500878,
	frameLevels = {
		kAssignmentEditorFrameLevel = 20,
		kRosterEditorFrameLevel = 40,
		kPhaseEditorFrameLevel = 60,
		kImportEditBoxFrameLevel = 80,
		kExportEditBoxFrameLevel = 100,
		kExternalTextEditorFrameLevel = 110,
		kNewPlanDialogFrameLevel = 120,
		kNewTemplateDialogFrameLevel = 130,
		kOptionsMenuFrameLevel = 140,
		kMessageBoxFrameLevel = 160,
		kPatchNotesDialogFrameLevel = 180,
		kReminderContainerFrameLevel = 100,
	},
	communications = {
		kDistributePlan = "EPDistributePlan",
		kDistributePlanReceived = "EPPlanReceived",
		kDistributeText = "EPDistributeText",
		kRequestPlanUpdate = "EPPlanUpdate",
		kRequestPlanUpdateResponse = "EPPlanUpdateR",
	},
	colors = {
		kNeutralButtonActionColor = { 74 / 255.0, 174 / 255.0, 242 / 255.0, 0.65 },
		kDestructiveButtonActionColor = { 0.725, 0.008, 0.008, 0.9 },
		kToggledButtonColor = { 1.0, 1.0, 1.0, 0.9 },
		kDefaultButtonBackdropColor = { 0.25, 0.25, 0.25, 1 },
		kToggledButtonBackdropColor = { 0.35, 0.35, 0.35, 1 },
		kEnabledTextColor = { 1, 1, 1 },
		kDisabledTextColor = { 0.5, 0.5, 0.5 },
	},
	textures = {
		kGenericWhite = [[Interface\BUTTONS\White8x8]],
		kSkull = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]],
		kDiagonalLine = [[Interface\AddOns\EncounterPlanner\Media\DiagonalLine]],
		kDiagonalLineSmall = [[Interface\AddOns\EncounterPlanner\Media\DiagonalLineSmall.tga]],
		kAdd = [[Interface\AddOns\EncounterPlanner\Media\icons8-add-32.tga]],
		kEncounterJournalIcons = [[Interface\EncounterJournal\UI-EJ-Icons]],
		kAnchor = [[Interface\AddOns\EncounterPlanner\Media\icons8-anchor-32.tga]],
		kCheck = [[Interface\AddOns\EncounterPlanner\Media\icons8-check-64.tga]],
		kCheckered = [[Interface\AddOns\EncounterPlanner\Media\icons8-checkered-50.tga]],
		kClose = [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32.tga]],
		kCollapse = [[Interface\AddOns\EncounterPlanner\Media\icons8-collapse-64.tga]],
		kDiscord = [[Interface\AddOns\EncounterPlanner\Media\icons8-discord-new-48.tga]],
		kDropdown = [[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96.tga]],
		kDuplicate = [[Interface\AddOns\EncounterPlanner\Media\icons8-duplicate-32.tga]],
		kExpand = [[Interface\AddOns\EncounterPlanner\Media\icons8-expand-64.tga]],
		kExport = [[Interface\AddOns\EncounterPlanner\Media\icons8-export-32.tga]],
		kFavoriteFilled = [[Interface\AddOns\EncounterPlanner\Media\icons8-favorite-filled-96.tga]],
		kFavoriteOutlined = [[Interface\AddOns\EncounterPlanner\Media\icons8-favorite-outline-96.tga]],
		kImport = [[Interface\AddOns\EncounterPlanner\Media\icons8-import-32.tga]],
		kLearning = [[Interface\AddOns\EncounterPlanner\Media\icons8-learning-30.tga]],
		kLogo = [[Interface\AddOns\EncounterPlanner\Media\ep-logo.tga]],
		kLfgPortraitRoles = [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]],
		kMaximize = [[Interface\AddOns\EncounterPlanner\Media\icons8-maximize-button-32.tga]],
		kMinus = [[Interface\AddOns\EncounterPlanner\Media\icons8-minus-32.tga]],
		kNoReminder = [[Interface\AddOns\EncounterPlanner\Media\icons8-no-reminder-24.tga]],
		kRadioButtonCenter = [[Interface\AddOns\EncounterPlanner\Media\icons8-radio-button-center-96.tga]],
		kReminder = [[Interface\AddOns\EncounterPlanner\Media\icons8-reminder-24.tga]],
		kResizer = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]],
		kResizerHighlight = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]],
		kResizerPushed = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]],
		kRightArrow = [[Interface\AddOns\EncounterPlanner\Media\icons8-right-arrow-32.tga]],
		kSettings = [[Interface\AddOns\EncounterPlanner\Media\icons8-settings-96.tga]],
		kSortDown = [[Interface\AddOns\EncounterPlanner\Media\icons8-sort-down-32.tga]],
		kStatusBarClean = [[Interface\AddOns\WeakAuras\Media\Textures\Statusbar_Clean]],
		kSwap = [[Interface\AddOns\EncounterPlanner\Media\icons8-swap-32.tga]],
		kTemplate = [[Interface\AddOns\EncounterPlanner\Media\icons8-template-32.tga]],
		kTooltipBorder = [[Interface\Tooltips\UI-Tooltip-Border]],
		kUncheckedRadioButton = [[Interface\AddOns\EncounterPlanner\Media\icons8-unchecked-radio-button-96.tga]],
		kUnknown = [[Interface\Icons\INV_MISC_QUESTIONMARK]],
		kUserManual = [[Interface\AddOns\EncounterPlanner\Media\icons8-user-manual-32.tga]],
	},
	timeline = {
		kPaddingBetweenTimelines = 44,
		kPaddingBetweenTimelineAndScrollBar = 10,
		kHorizontalScrollBarHeight = 20,
	},
	kMainFrameWindowBarHeight = 30,
	kStatusBarHeight = 48,
	kStatusBarPadding = 5,
	kMaxBossDuration = 1200.0,
	kMinBossPhaseDuration = 10.0,
	kMainFramePadding = { 10, 10, 10, 10 },
	kMainFrameSpacing = { 0, 22 },
	kTopContainerHeight = 68,
	kMinimumTimeBetweenAssignmentsBeforeWarning = 2.0,
	kDefaultBossDungeonEncounterID = 3129, -- Plexus Sentinel
	kDefaultFont = [[Interface\Addons\EncounterPlanner\Media\Fonts\PTSansNarrow-Bold.ttf]],
	---@enum AssignmentSelectionType
	AssignmentSelectionType = {
		kNone = {},
		kSelection = {},
		kBossAbilityHover = {},
	},
	---@enum BossAbilitySelectionType
	BossAbilitySelectionType = {
		kNone = {},
		kSelection = {},
		kAssignmentHover = {},
	},
	kRegexIconText = ".*|t%s*(.+)$",
	-- Requires 6 arguments
	kFormatStringDifficultyIcon = "|T%s:16:16:%d:0:64:64:%d:%d:%d:%d|t",
	kFormatStringGenericInlineIconWithText = "|T%s:16|t %s",
	kFormatStringGenericInlineIconWithZoom = "|T%s:16:16:0:0:64:64:5:59:5:59|t",
	kRolePriority = {
		["role:healer"] = 1,
		["role:tank"] = 2,
		["role:damager"] = 3,
		[""] = 4,
	},
}

local isElevenDotTwo = select(4, GetBuildInfo()) >= 110200 -- Remove when 11.2 is live
if not isElevenDotTwo then
	Private.constants.kDefaultBossDungeonEncounterID = 3009
end

Private.constants.kPatchNotesText = [[
-   Updated supported WoW versions.
]]
