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
		kOptionsMenuFrameLevel = 140,
		kMessageBoxFrameLevel = 160,
		kReminderContainerFrameLevel = 100,
	},
	communications = {
		kDistributePlan = "EPDistributePlan",
		kPlanReceived = "EPPlanReceived",
		kDistributeText = "EPDistributeText",
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
	kMaxBossDuration = 1200.0,
	kMinBossPhaseDuration = 10.0,
	kMinimumTimeBetweenAssignmentsBeforeWarning = 2.0,
	kDefaultBossDungeonEncounterID = 3009, -- Vexie
}
