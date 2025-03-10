local AddOnName, Namespace = ...

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
	kMaxBossDuration = 1200.0,
	kMinBossPhaseDuration = 10.0,
	kMinimumTimeBetweenAssignmentsBeforeWarning = 2.0,
	kDefaultBossDungeonEncounterID = 3009, -- Vexie
}
