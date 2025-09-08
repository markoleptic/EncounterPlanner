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
	kEncounterJournalIcon = [[Interface\EncounterJournal\UI-EJ-Icons]],
	kUnknownIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]],
	resizer = {
		kIcon = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]],
		kIconHighlight = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]],
		kIconPushed = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]],
	},
	kFormatStringGenericInlineIconWithText = "|T%s:16|t %s",
	kFormatStringGenericInlineIconWithZoom = "|T%s:16:16:0:0:64:64:5:59:5:59|t",
}

local isElevenDotTwo = select(4, GetBuildInfo()) >= 110200 -- Remove when 11.2 is live
if not isElevenDotTwo then
	Private.constants.kDefaultBossDungeonEncounterID = 3009
end

Private.constants.kPatchNotesText = [[
-   New Feature: Plan templates
    -   Applying a template to a plan adds placeholders for assignees and spells to the timeline. It also adds any assignees from the template to the plan roster.
    -   Templates can be created, applied, and deleted by navigating to Plan -> Templates.
-   Added Mythic Dimensius.
-   Added Infusion Tether spell to Loom'ithar.
-   Fixed a bug where the roster may not have resolved correctly after approving plan changes.
-   Fixed a bug where add/remove message counts were swapped for external text after approving plan changes.
]]
