---@meta _

-- Abstract base class for assignments.
---@class Assignment
---@field uniqueID integer Incremented each time a new assignment is created used to distinguish in-memory assignments.
---@field assignee string Who to assign the assignment to, AssigneeType.
---@field text string Text to display for the assignment. If empty, the spell name is used.
---@field spellID integer The spell ID for the assignment.
---@field targetName string The target's name if the assignment has a '@'.

-- An assignment based on a combat log event.
---@class CombatLogEventAssignment : Assignment
---@field combatLogEventType CombatLogEventType The type of combat log even the assignment is triggered by.
---@field combatLogEventSpellID integer The spell for the event.
---@field spellCount integer The number of times the combat log event must occur before the assignment is triggered.
---@field time number The time from the combat log event to trigger the assignment.
---@field phase integer The boss phase that the combatLogEventSpellID and spellCount are located in.
---@field bossPhaseOrderIndex integer The index into the ordered boss phase table.

-- An assignment based on time from the boss being pulled.
---@class TimedAssignment : Assignment
---@field time number The length of time from the beginning of the fight to when this assignment is triggered.

-- An assignment dependent only upon a boss phase. Currently half-implemented.
---@class PhasedAssignment : Assignment
---@field phase integer The boss phase this assignment is triggered by.
---@field time number The time from the start of the phase to trigger the assignment.

-- Wrapper around an assignment with additional info about where to draw the assignment on the timeline.
---@class TimelineAssignment
---@field assignment Assignment The assignment.
---@field startTime number Time used to place the assignment on the timeline.
---@field cooldownDuration number The cooldown duration of the spell assignment, or 0 if no spell.
-- The maximum number of charges the spell assignment, or 1 if no spell or the spell does not have charges.
---@field maxCharges integer
-- The effective cooldown duration, which could be more or less than the actual cooldown duration depending on if
-- multiple charges are coming back up.
---@field effectiveCooldownDuration number
---@field relativeChargeRestoreTime number|nil Time relative to the start time in which a cooldown charge is restored.
---@field invalidChargeCast boolean|nil If specified, there were no spell charges available to cast.

-- A raid or dungeon with a specific instanceID.
---@class DungeonInstance
---@field name string The name of the raid or dungeon.
--  The journal instance ID of the raid or dungeon. All bosses share the same JournalInstanceID.
---@field journalInstanceID integer
---@field instanceID integer The instance ID for the zone. All bosses share the same instanceID.
---@field mapChallengeModeID integer|nil If part of a split dungeon instance, the map challenge mode ID.
---@field customGroups string[]|nil Custom group to use when populating dropdowns.
---@field bosses table<integer, Boss>|nil List of bosses for the instance. Nil if split.
---@field icon integer Button image 2 from EJ_GetInstanceInfo.
---@field executeAndNil fun()|nil
---@field isRaid boolean|nil
---@field hasHeroic boolean|nil
---@field isSplit boolean|nil Whether the dungeon is split into groups (Mega-dungeons).
-- If split into groups (Mega-dungeons), this holds the actual dungeon instances, where the keys are map challenge mode
-- IDs.
---@field splitDungeonInstances table<integer, DungeonInstance>|nil

---@class PreferredCombatLogEventAbility
---@field combatLogEventSpellID integer
---@field combatLogEventType CombatLogEventType

-- A raid or dungeon boss containing abilities, phases, etc.
---@class Boss
---@field name string Name of the boss.
---@field bossIDs table<integer, integer> ID of the boss or bosses.
-- Maps journal encounter creature IDs to boss Npc IDs.
---@field journalEncounterCreatureIDsToBossIDs table<integer, integer>
---@field bossNames table<integer, string> Maps boss Npc IDs to individual boss names.
---@field journalEncounterID integer Journal encounter ID of the boss encounter.
---@field dungeonEncounterID integer Dungeon encounter ID of the boss encounter.
---@field instanceID integer The instance ID for the zone the boss is located in.
---@field mapChallengeModeID integer|nil If part of a split dungeon instance, map challenge mode id for dungeon.
---@field phases table<integer, BossPhase> A list of phases and their durations.
---@field abilities table<integer, BossAbility> A list of abilities where the keys are spell IDs.
---@field sortedAbilityIDs table<integer, integer> An ordered list of abilities sorted by first appearance.
-- Data about a single instance of a boss ability stored in a boss ability frame in the timeline.
---@field abilityInstances table<integer, BossAbilityInstance>
---@field treatAsSinglePhase boolean|nil If specified, the boss phases will be merged into one phase.
---@field icon integer Icon image from EJ_GetCreatureInfo.
-- Preferred abilities to use for each boss phase.
---@field preferredCombatLogEventAbilities table<integer, PreferredCombatLogEventAbility|nil>|nil
---@field hasBossDeath boolean|nil If specified, at least one ability corresponds to a boss death.
---@field customSpells table<integer, {text: string, iconID: string|number}>|nil
---@field preferredCombatLogEventAbilitiesHeroic table<integer, PreferredCombatLogEventAbility|nil>|nil
---@field abilitiesHeroic table<integer, BossAbility>
---@field phasesHeroic table<integer, BossPhase>
---@field sortedAbilityIDsHeroic table<integer, integer>
---@field abilityInstancesHeroic table<integer, BossAbilityInstance>

-- A stage/phase in a boss encounter.
---@class BossPhase
---@field duration number The duration of the boss phase.
---@field defaultDuration number The default duration of the boss phase.
---@field count number The number of times the boss phase occurs.
---@field defaultCount number The default number of times the boss phase occurs.
---@field repeatAfter number|nil Which phase this phase repeats after.
---@field name string|nil If specified, the phase will be displayed on the timeline under this name. Otherwise hidden.
---@field shortName string|nil Short name to use if limited on space in timeline. No bosses currently implement.
---@field fixedDuration boolean|nil If specified, the duration is not editable.
---@field fixedCount boolean|nil If specified, the number of phases will not be editable.
---@field minDuration number|nil
---@field maxDuration number|nil

-- A spell that a boss casts including when the spell is cast.
---@class BossAbility
---@field phases table<number, BossAbilityPhase> Describes at which times in which phases the ability occurs in.
---@field eventTriggers table<integer, EventTrigger>|nil Other boss abilities that trigger the ability.
-- Boss deaths that cancel this ability.
---@field cancelTriggers table<integer, {bossNpcID: integer, combatLogEventType: CombatLogEventType}>|nil
---@field duration number Usually how long the ability effect lasts.
---@field durationLastsUntilEndOfPhase boolean|nil If true, duration lasts until end of phase.
---@field castTimeLastsUntilEndOfPhase boolean|nil If true, castTime lasts until end of phase.
---@field durationLastsUntilEndOfNextPhase boolean|nil If true, duration lasts until end of next phase.
---@field castTime number The actual cast time of the ability.
-- Restrict creating combat log event assignments to only these types.
---@field allowedCombatLogEventTypes table<integer, CombatLogEventType>
---@field additionalContext string|nil Additional context to append to boss ability names.
---@field tankAbility boolean|nil If true, is a tank buster or similar.
---@field bossNpcID integer|nil If defined, the ability represents a boss's death with the given npc ID.
-- If true, a buffer will be applied after the each combat log event to prevent successive events from triggering it
-- again.
---@field buffer number|nil
---@field defaultHidden boolean|nil If true, the ability is hidden by default.
-- If defined, boss ability bars will be half height and alternate vertical offset on each cast.
---@field halfHeight boolean|nil

-- A phase in which a boss ability is triggered/cast at least once. May also repeat.
---@class BossAbilityPhase
---@field castTimes table<integer, number> An ordered list of cast times, where the actual cast time is the running sum.
-- If defined, the ability will repeat at this interval starting from the last cast time.
---@field repeatInterval number|table<integer, number>|nil
---@field signifiesPhaseStart boolean|nil If defined, first cast denotes the start of the phase it occurs in.
---@field signifiesPhaseEnd boolean|nil If defined, last cast completion denotes the end of the phase it occurs in.
---@field skipFirst boolean|nil If defined, the first occurrence of this boss ability phase will be skipped.
-- If specified, casts will only be created if the phase occurrence number is in the table.
---@field phaseOccurrences table<integer, boolean>|table<integer, {min: number?, max: number?}>|nil
---@field castTime number|nil Phase specific cast time override
---@field duration number|nil Phase specific duration override

-- Defines a boss ability that triggers another boss ability. May also repeat.
---@class EventTrigger
---@field castTimes table<integer, number> An ordered list of cast times, where the actual cast time is the running sum.
---@field combatLogEventType CombatLogEventType The combat log event type that acts as a trigger.
---@field onlyRepeatOn integer|nil If defined, casts will only be repeated on this combat log event spell count number.
-- The number of times the other ability must have been cast before the ability begins repeating.
---@field combatLogEventSpellCount integer|nil
-- If defined, the ability will repeat at this interval starting from the last cast time.
---@field repeatInterval number|table<integer, number>|nil
-- If specified, casts will only be created if the phase occurrence number is in the table.
---@field phaseOccurrences table<integer, boolean>|{min: number, max: number}|nil
---@field cast nil|fun(count:integer):boolean Same as combat log event spell count but takes it as a parameter

-- Data about a single instance of a boss ability stored in a boss ability frame in the timeline. The instance may have
-- a different castStart, castEnd, or effectEnd if the boss phase duration or boss phase count are different from
-- default.
---@class BossAbilityInstance
---@field bossAbilitySpellID integer The spell ID of the boss ability.
---@field bossAbilityInstanceIndex integer The occurrence number of this instance out of all boss ability instances.
---@field bossAbilityOrderIndex integer The index of the ability in the boss's sortedAbilityIDs.
---@field bossPhaseIndex integer The phase the ability instance is cast in.
---@field bossPhaseOrderIndex integer The index of boss phase in the boss phase order (not the boss phase).
---@field bossPhaseDuration number The duration of the boss phase.
---@field bossPhaseName string|nil If defined, the name of the phase.
---@field bossPhaseShortName string|nil If defined, the short name of the phase.
---@field nextBossPhaseName string|nil If defined, the name of the next phase.
---@field nextBossPhaseShortName string|nil If defined, the short name of the next phase.
---@field spellCount integer The occurrence number of the boss spell ID.
---@field castStart number The cast time from the start of the encounter.
---@field castEnd number The cast start plus the cast time.
---@field effectEnd number The cast end plus the ability duration.
---@field frameLevel integer Frame level to use for the ability instance on the timeline.
---@field relativeCastTime number|nil If defined, the cast time from the trigger cast time.
---@field signifiesPhaseStart boolean|nil If defined, first cast denotes start of the phase it occurs in.
---@field signifiesPhaseEnd boolean|nil If defined, last cast completion denotes end of the phase it occurs in.
-- A height and offset multiplier to use if perfectly overlapping with another cast of the same ability.
---@field overlaps {heightMultiplier:number, offset:number}|nil

---@class RosterEntry -- An entry in a roster, only used in gui.
---@field class string
---@field classColoredName string
---@field role RaidGroupRole

---@class Plan A plan for a boss encounter.
---@field ID string Uniquely generated ID used when updating assignments received from other characters.
---@field isPrimaryPlan boolean Whether the plan has priority over other plans for the same boss.
---@field name string Name of the plan.
---@field dungeonEncounterID integer Dungeon encounter ID for the boss the plan is associated with.
---@field instanceID integer Instance ID for the boss the plan is associated with.
---@field difficulty DifficultyType Difficulty type (either mythic or heroic)
---@field content table<integer, string> Miscellaneous text that other addons or WeakAuras can use for the encounter.
---@field assignments table<integer, Assignment> Assignments for the plan.
---@field roster table<string, RosterEntry> Roster for the plan.
---@field assigneeSpellSets table<integer, AssigneeSpellSet> Assignees and spells (templates)
---@field collapsed table<string, boolean> Which assignees are collapsed in the assignment timeline.
---@field customPhaseDurations table<integer, number> Overridden boss phase durations.
---@field customPhaseCounts table<integer, number> Overridden boss phase counts.
---@field remindersEnabled boolean Whether reminders are enabled for the plan.

---@class SerializedPlan
---@field [1] string ID
---@field [2] string name
---@field [3] integer dungeonEncounterID
---@field [4] integer instanceID
---@field [5] DifficultyType difficulty
---@field [6] table<integer, SerializedAssignment> assignments
---@field [7] table<string, SerializedRosterEntry> roster
---@field [8] table<integer, string> content
---@field [9] table<integer, SerializedAssigneeSpellSet> Assignees and spells (templates)

---@class SerializedAssignment
---@field [1] string assignee
---@field [2] number spellID
---@field [3] string text
---@field [4] string targetName
---@field [5] number time
---@field [6] CombatLogEventType|nil combatLogEventType
---@field [7] integer|nil combatLogEventSpellID
---@field [8] integer|nil spellCount
---@field [9] integer|nil phase
---@field [10] integer|nil bossPhaseOrderIndex

---@class SerializedRosterEntry
---@field [1] string name
---@field [2] string class
---@field [3] RaidGroupRole role
---@field [4] string classColoredName

---@class SerializedAssigneeSpellSet
---@field [1] string assignee
---@field [2] table<integer, integer> Table of spellIDs for this assignee.

---@class AdditionalMessageBoxButtonData Data needed to add additional buttons an EPMessageBox widget.
-- The child widget index (of EPMessageBox) to insert the button before, at the time of insertion.
---@field beforeButtonIndex integer
---@field buttonText string Button text of the button in the message box.
---@field callback fun()|nil Function executed when the button is clicked.

---@class MessageBoxData Data needed to construct an EPMessageBox widget.
---@field ID string Unique ID to distinguish message boxes in the queue.
---@field widgetType "EPMessageBox"|"EPDiffViewer"
---@field isCommunication boolean True if the message box data was constructed from Communications.lua.
---@field title string Title of the message box.
---@field message string Content of the message box.
---@field acceptButtonText string Accept button text of the message box.
---@field acceptButtonCallback fun() Function executed when the accept button is clicked.
---@field rejectButtonText string Reject button text of the message box.
---@field rejectButtonCallback fun()|nil Function executed when the reject button is clicked.
---@field buttonsToAdd table<integer, AdditionalMessageBoxButtonData> Additional buttons to add to the message box.
---@field planDiff? PlanDiff
---@field oldPlan? Plan
---@field newPlan? Plan

---@class KeyBindings
---@field pan MouseButtonKeyBinding Controls panning the timeline left and right.
---@field zoom ScrollKeyBinding Controls zooming in on the timeline.
---@field scroll ScrollKeyBinding Controls scrolling the timeline up and down.
---@field editAssignment MouseButtonKeyBinding Controls opening the assignment editor or dragging an assignment.
---@field newAssignment MouseButtonKeyBinding Controls creating a new assignment.
---@field duplicateAssignment MouseButtonKeyBinding Controls duplicating an assignment.

---@class TimelineRows
---@field numberOfAssignmentsToShow integer Number of visible rows in the assignment timeline.
---@field numberOfBossAbilitiesToShow integer Number of visible rows in the boss timeline.
---@field assignmentHeight integer Height of individual rows in the assignment timeline.
---@field bossAbilityHeight integer Height of individual rows in the boss timeline.
---@field onlyShowMe boolean Whether to only show assignments on timeline that are relevant to the player.

---@class Preferences
---@field lastOpenTab string Last open preferences menu tab.
---@field keyBindings KeyBindings Timeline keybindings.
---@field assignmentSortType AssignmentSortType Timeline assignment sort method.
---@field timelineRows TimelineRows Visibility and size timeline settings.
---@field zoomCenteredOnCursor boolean If true, zoom in toward the position of mouse cursor, keeping cursor in focus.
---@field reminder ReminderPreferences Reminder-related preferences.
---@field showSpellCooldownDuration boolean Whether to show textures representing player spell cooldown durations.
---@field minimap {show: boolean} Minimap button visibility.

---@class ReminderTextToSpeechPreferences
---@field enableAtCountdownStart boolean Whether to play text to speech sound at the start of the countdown.
---@field enableAtCountdownEnd boolean Whether to play text to speech sound at the end of the countdown.
---@field voiceID integer The voice to use for Text to Speech.
---@field volume number The volume to use for Text to Speech.

---@class ReminderSoundPreferences
---@field enableAtCountdownStart boolean Whether to play a sound at the start of the countdown.
---@field enableAtCountdownEnd boolean Whether to play a sound at the end of the countdown.
---@field countdownStartSound string The sound to play at the start of the countdown.
---@field countdownEndSound string The sound to play at the end of the countdown.

---@class GenericReminderPreferences
---@field enabled boolean Whether this type of reminder is enabled.
---@field font string The font to use for the reminder.
---@field fontSize integer The font size to use for the reminder.
---@field fontOutline ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE" The font outline to use for the reminder.
---@field point AnchorPoint Which spot on the reminder widget container is fixed.
---@field relativeTo string The frame that the reminder widget container is anchored to.
---@field relativePoint AnchorPoint The anchor point on the frame that the reminder widget container is anchored to.
---@field x number The horizontal offset from the Relative Anchor Point to the Anchor Point.
---@field y number The vertical offset from the Relative Anchor Point to the Anchor Point.
---@field alpha number Transparency of the reminder widget.
-- Widgets are displayed in descending order, with the widget expiring the soonest on bottom.
---@field soonestExpirationOnBottom boolean

---@class ProgressBarPreferences : GenericReminderPreferences
---@field texture string The texture to use for the foreground and background of Progress Bars.
---@field iconPosition "LEFT"|"RIGHT" Icon position on Progress Bars.
---@field width number The width of Progress Bars.
---@field height number The height of Progress Bars.
---@field durationAlignment "LEFT"|"RIGHT" Duration position relative to the text.
---@field fill boolean If true, fills Progress Bars from left to right as the countdown progresses.
---@field showBorder boolean Whether to show a 1px border around Progress Bars.
---@field showIconBorder boolean Whether to show a 1px border around Progress Bar icons.
---@field color Color Foreground color for Progress Bars.
---@field backgroundColor Color Background color for Progress Bars.
---@field spacing integer Spacing between Progress Bars.
---@field shrinkTextToFit boolean Whether to decrease font size to attempt to fit text without clipping.

---@class MessagePreferences : GenericReminderPreferences
---@field showOnlyAtExpiration boolean If true, only shows Messages at expiration time.
---@field textColor Color Text color of Messages.
---@field showIcon boolean If true, show the spell icon associated with the assignment.

---@class IconPreferences : GenericReminderPreferences
---@field width number The width of Cooldown Icons.
---@field height number The height of Cooldown Icons.
---@field drawSwipe boolean Whether to show the radial swipe animation on Cooldown Icons.
---@field drawEdge boolean Whether to show the edge indicator on Cooldown Icons.
---@field showText boolean Whether to show reminder text beneath Cooldown Icons.
---@field shrinkTextToFit boolean Whether to decrease font size to attempt to fit text without clipping.
---@field textColor Color Text color to use for text beneath Cooldown Icons.
---@field borderSize integer The size of the border of Cooldown Icons.
---@field spacing integer Spacing between Cooldown Icons.
---@field orientation "vertical"|"horizontal" Whether to grow Cooldown Icons vertically or horizontally.

---@class ReminderPreferences
-- Whether to enable reminders for assignments. If unchecked, this setting overrides any plans with Enable Reminders
-- for Plan checked.
---@field enabled boolean
---@field onlyShowMe boolean Whether to only show assignment reminders that are relevant to the player.
---@field removeDueToPhaseChange boolean Not currently used.
-- If an assignment is a spell and it already on cooldown, the reminder will not be shown. If the spell is cast during
-- the reminder countdown, it will be cancelled.
---@field cancelIfAlreadyCasted boolean
---@field countdownLength number How far ahead to begin showing reminders.
---@field glowTargetFrame boolean Glows the unit frame of the target at the end of the countdown.
---@field progressBars ProgressBarPreferences
---@field messages MessagePreferences
---@field icons IconPreferences
---@field textToSpeech ReminderTextToSpeechPreferences
---@field sound ReminderSoundPreferences

---@class CooldownAndChargeOverride
---@field duration number Overridden cooldown duration.
---@field maxCharges integer|nil Optional overridden charge count.

---@class DefaultProfile
---@field activeBossAbilities table<integer, table<integer, boolean>> Boss abilities to show on the timeline.
---@field activeBossAbilitiesHeroic table<integer, table<integer, boolean>> Heroic abilities to show on the timeline.
---@field plans table<string, Plan> All plans.
---@field templates table<integer, PlanTemplate> Plan templates.
---@field sharedRoster table<string, RosterEntry> A roster that is persistent across plans.
---@field lastOpenPlan string The last open plan.
---@field recentSpellAssignments table<integer, DropdownItemData> Recently assigned spells (up to 10).
---@field favoritedSpellAssignments table<integer, DropdownItemData> Favorited spells.
---@field trustedCharacters table<integer, string> Characters that may bypass the import warning.
---@field windowSize {x: number, y: number}|nil Size of main frame when the addon was closed last.
---@field minimizeFramePosition {x: number, y: number}|nil Position of the minimize frame.
-- Cooldown duration and charge overrides for spells.
---@field cooldownAndChargeOverrides table<integer, CooldownAndChargeOverride>
---@field activeText table<integer, string> External text send by the group leader on encounter start.
---@field preferences Preferences Settings.
---@field createdDefaults table<integer, boolean> Encounter IDs for which default plans have already been created.
---@field version string

---@class TutorialData
---@field completed boolean Whether the tutorial was fully completed by any character.
---@field lastStepName string The last successfully completed tutorial step.
---@field skipped boolean Whether the tutorial was explicitly skipped or closed mid-tutorial..
---@field revision integer Last saved tutorial revision.
---@field firstSpell integer First custom spell chosen during the tutorial.
---@field secondSpell integer Second custom spell chosen during the tutorial.

---@class GlobalProfile
---@field tutorial TutorialData

---@class Defaults : AceDB.Schema, AceDBObject-3.0
---@field profile DefaultProfile
---@field global GlobalProfile

---@class Color
---@field [1] number Red
---@field [2] number Green
---@field [3] number Blue
---@field [4] number Alpha

---@class FailedInfo
---@field bossName string|nil
---@field combatLogEventSpellIDs table<integer, table<integer, integer>>

---@class FailTable
---@field bossName string|nil
---@field combatLogEventSpellIDs table<integer, table<integer, integer>>
---@field onlyInMaxCastTimeTable table<integer, table<integer, integer>>

---@class LoggedPlanInfo
---@field overlapCount integer
---@field pastDurationCount integer
---@field spellIDsCount integer
---@field spellCountsCount integer
---@field maxSpellCountsCount integer

---@class TutorialStep
---@field name string
---@field text string
---@field enableNextButton boolean|fun():boolean
---@field frame Frame|BackdropTemplate|nil
---@field OnStepActivated nil|fun(self: TutorialStep):boolean
---@field PreStepDeactivated fun(self: TutorialStep, incrementing: boolean, cleanUp: boolean|nil)|nil
---@field HighlightFrameAndPositionTutorialFrame fun()|nil
---@field additionalVerticalOffset number|nil
---@field ignoreNextAssignmentEditorReleased boolean|nil

---@class CombatLogEventAssignmentData
---@field preferences ReminderPreferences
---@field assignment CombatLogEventAssignment
---@field roster table<string, RosterEntry>

---@class AssigneeSpellSet
---@field assignee string
---@field assigneeRosterEntry? RosterEntry
---@field spells table<integer, integer> Table of spellIDs for this assignee.

---@class FlatAssigneeSpellSet
---@field assignee string
---@field spellID integer

---@class PlanTemplate
---@field name string Name of the template
---@field assigneeSpellSets table<integer, AssigneeSpellSet> Sorted entries.

---@class CustomDungeonInstanceGroup
---@field instanceName string Custom text to use as the group name in a dropdown.
---@field instanceIDToUseForIcon integer An existing dungeon instance ID to use for the icon beside the text.
---@field order integer The sort index when comparing against other custom groups.

---@class DropdownItemData
---@field itemValue string|number|table the internal value used to index a dropdown item
---@field text string the value shown in the dropdown
---@field dropdownItemMenuData table<integer, DropdownItemData>|nil nested dropdown item menus
---@field selectable? boolean If true, the dropdown item can be selected and a check can be shown
---@field customTexture? string|integer A custom texture to add beside the check or checked indicator
---@field customTextureVertexColor? number[] The color of the texture
-- Whether or not the custom texture should be allowed to fire the CustomTextureClicked callback after user left mouse
-- button mouse up
---@field customTextureSelectable? boolean
---@field itemMenuClickable? boolean If true, item menus can be clicked and trigger OnValueChanged
---@field neverHasChildren? boolean If true, a EPDropdownItemToggle is created instead of an EPDropdownItemMenu
---@field indent? integer
---@field clickable? boolean

---@class SpellCastStartTableEntry
---@field castStart number
---@field bossPhaseOrderIndex integer

---@class PlanDiffEntry<T>: { type: PlanDiffType, index?: integer, aIndex?: integer, bIndex?: integer, value?: `T`, oldValue?: `T`, newValue?: `T`, result: boolean }

---@class PlanRosterDiff
---@field assignee string
---@field type PlanDiffType
---@field oldValue? RosterEntry Nil if type is `PlanDiffType.Insert`.
---@field newValue? RosterEntry Nil if type is `PlanDiffType.Delete`.
---@field result boolean

---@class PlanMetaDataDiff
---@field difficulty? {oldValue: DifficultyType, newValue: DifficultyType, result: boolean}
---@field dungeonEncounterID? {oldValue: integer, newValue: integer, result: boolean}
---@field instanceID? {oldValue: integer, newValue: integer, result: boolean}

---@class PlanDiff
---@field assignments table<integer, PlanDiffEntry<Assignment|TimedAssignment|CombatLogEventAssignment>>
---@field content table<integer, PlanDiffEntry<string>>
---@field roster table<integer, PlanRosterDiff>
---@field assigneeSpellSets table<integer, PlanDiffEntry<FlatAssigneeSpellSet>>
---@field metaData PlanMetaDataDiff
---@field empty boolean

---@class SortedDungeonInstanceEntryBossEntry
---@field dungeonEncounterID integer
---@field index integer

---@class SortedDungeonInstanceEntry
---@field name string
---@field dungeonInstanceID integer
---@field mapChallengeModeID? integer
---@field bosses table<integer, SortedDungeonInstanceEntryBossEntry> Keys are dungeonEncounterID
---@field sortedBosses table<integer, SortedDungeonInstanceEntryBossEntry> Keys are sequential indices
---@field isRaid boolean

---@alias CombatLogEventType
---| "SCC" SPELL_CAST_SUCCESS
---| "SCS" SPELL_CAST_START
---| "SAA" SPELL_AURA_APPLIED
---| "SAR" SPELL_AURA_REMOVED
---| "UD" UNIT_DIED

---@alias FullCombatLogEventType
---| "SPELL_AURA_APPLIED"
---| "SPELL_AURA_REMOVED"
---| "SPELL_CAST_START"
---| "SPELL_CAST_SUCCESS"
---| "UNIT_DIED"

---@alias AssignmentType
---| "CombatLogEventAssignment"
---| "TimedAssignment"
---| "PhasedAssignment"

---@alias AssigneeType
---| "Everyone"
---| "Role"
---| "GroupNumber"
---| "Tanks"
---| "Class"
---| "Individual"
---| "Spec"
---| "Type"

---@alias AssignmentSortType
---| "Alphabetical"
---| "First Appearance"
---| "Role > Alphabetical"
---| "Role > First Appearance"

---@alias RaidGroupRole
---| "role:damager"
---| "role:healer"
---| "role:tank"
---| ""

---@alias ScrollKeyBinding
---| "MouseScroll"
---| "Alt-MouseScroll"
---| "Ctrl-MouseScroll"
---| "Shift-MouseScroll"

---@alias MouseButtonKeyBinding
---| "LeftButton"
---| "Alt-LeftButton"
---| "Ctrl-LeftButton"
---| "Shift-LeftButton"
---| "MiddleButton"
---| "Alt-MiddleButton"
---| "Ctrl-MiddleButton"
---| "Shift-MiddleButton"
---| "RightButton"
---| "Alt-RightButton"
---| "Ctrl-RightButton"
---| "Shift-RightButton"

---@alias AnchorPoint
---| "TOPLEFT"
---| "TOP"
---| "TOPRIGHT"
---| "RIGHT"
---| "BOTTOMRIGHT"
---| "BOTTOM"
---| "LEFT"
---| "BOTTOMLEFT"
---| "CENTER"

---@alias EPSettingOptionType
---| "dropdown"
---| "radioButtonGroup"
---| "lineEdit"
---| "checkBox"
---| "frameChooser"
---| "doubleLineEdit"
---| "horizontalLine"
---| "checkBoxBesideButton"
---| "colorPicker"
---| "doubleColorPicker"
---| "doubleCheckBox"
---| "checkBoxWithDropdown"
---| "centeredButton"
---| "dropdownBesideButton"
---| "cooldownOverrides"

---@alias OptionFailureReason
---|1 Invalid assignment type
---|2 Invalid combat log event type
---|3 Invalid combat log event spell ID
---|4 Invalid combat log event spell count
---|5 No spell count
---|6 Invalid assignee name or role
---|7 Invalid boss

---@alias GetFunction
---| fun(): string|boolean|table<integer, number>|table<integer, CooldownAndChargeOverride>|number,number?,number?,number?

---@alias SetFunction
---| fun(value: string|boolean|number|table<integer, number>|table<integer, CooldownAndChargeOverride>, value2?: string|boolean|number, value3?:number, value4?:number)

---@alias ValidateFunction
---| fun(value: string|number, value2?: string): boolean, string|number?,number?

---@alias EnabledFunction
---| fun(): boolean

---@alias AssignmentFrameOverlapType
--- | 0 NoOverlap
--- | 1 PartialOverlap - Last frame is partially overlapping current frame
--- | 2 FullOverlap - Last frame left is greater than current frame left

---@alias EPRosterEditorTab
---| "Shared Roster"
---| "Current Plan Roster"
---| ""

---@alias SeverityLevel
---|1
---|2
---|3

---@alias IndentLevel
---|1
---|2
---|3

C_Timer = {}

---@class Private
local Private = {}

---@class FunctionContainer
---@field ID string
local FunctionContainer = {}

---@param self FunctionContainer
function FunctionContainer.RemoveTimerRef(self) end

---@param self FunctionContainer
---@param ... any
function FunctionContainer.Invoke(self, ...) end

---[Documentation](https://warcraft.wiki.gg/wiki/API_C_Timer.After)
---@param seconds number
---@param callback TimerTimerObjectCallback
function C_Timer.After(seconds, callback) end

---[Documentation](https://warcraft.wiki.gg/wiki/API_C_Timer.NewTicker)
---@param seconds number
---@param callback TickerTimerObjectCallback
---@param iterations? number
---@return FunctionContainer cbObject
function C_Timer.NewTicker(seconds, callback, iterations) end

---[Documentation](https://warcraft.wiki.gg/wiki/API_C_Timer.NewTimer)
---@param seconds number
---@param callback TimerTimerObjectCallback
---@return FunctionContainer cbObject
function C_Timer.NewTimer(seconds, callback) end

---@param value number
---@param min number
---@param max number
---@return number
function Clamp(value, min, max) end

---@alias TickerTimerObjectCallback FunctionContainer|fun(cb: FunctionContainer)

---@alias TimerTimerObjectCallback FunctionContainer|fun(cb: FunctionContainer)

---@param obj any
---@return string
function Private.Encode(obj) end

---@param obj any
---@return string
function Private.Decode(obj) end

---@param target table
---@param name string
---@param func fun(...)|string
function Private.RegisterCallback(target, name, func) end

---@param target table
---@param name string
function Private.UnregisterCallback(target, name) end

---@param target table
function Private.UnregisterAllCallbacks(target) end
