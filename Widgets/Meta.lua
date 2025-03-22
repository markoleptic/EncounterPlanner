---@meta

---@alias EPLayoutType
---|"EPContentFrameLayout"
---|"EPHorizontalLayout"
---|"EPVerticalLayout"
---|"EPProgressBarLayout"

---@alias EPBaseContainerType
---|"EPContainer"

---@alias EPAnchorContainerType
---|"EPAnchorContainer"

---@alias EPSpacerType
---|"EPSpacer"

---@alias EPLabelType
---|"EPLabel"

---@alias EPLineEditType
---|"EPLineEdit"

---@alias EPButtonType
---|"EPButton"

---@alias EPEditBoxType
---|"EPEditBox"

---@alias EPDropdownPulloutType
---|"EPDropdownPullout"

---@alias EPDropdownItemToggleType
---|"EPDropdownItemToggle"

---@alias EPDropdownItemMenuType
---|"EPDropdownItemMenu"

---@alias EPDropdownType
---|"EPDropdown"

---@alias EPAbilityEntryType
---|"EPAbilityEntry"

---@alias EPAssignmentEditorType
---|"EPAssignmentEditor"

---@alias EPRosterEntryType
---|"EPRosterEntry"

---@alias EPTimelineType
---|"EPTimeline"

---@alias EPMainFrameType
---|"EPMainFrame"

---@alias EPRosterEditorType
---|"EPRosterEditor"

---@alias EPTimelineSectionType
---|"EPTimelineSection"

---@alias EPOptionsType
---|"EPOptions"

---@alias EPRadioButtonType
---|"EPRadioButton"

---@alias EPCheckBoxType
---|"EPCheckBox"

---@alias EPProgressBarType
---|"EPProgressBar"

---@alias EPReminderMessageType
---|"EPReminderMessage"

---@alias EPColorPickerType
---|"EPColorPicker"

---@alias EPMessageBoxType
---|"EPMessageBox"

---@alias EPPhaseLengthEditorType
---|"EPPhaseLengthEditor"

---@alias EPNewPlanDialogType
---|"EPNewPlanDialog"

---@alias EPScrollFrameType
---|"EPScrollFrame"

---@alias EPStatusBarType
---|"EPStatusBar"

---@alias EPTutorialType
---|"EPTutorial"

---@alias EPWidgetType
---| EPSpacerType
---| EPLabelType
---| EPLineEditType
---| EPEditBoxType
---| EPDropdownPulloutType
---| EPDropdownItemToggleType
---| EPDropdownItemMenuType
---| EPDropdownType
---| EPAbilityEntryType
---| EPAssignmentEditorType
---| EPTimelineType
---| EPMainFrameType
---| EPTimelineSectionType
---| EPRadioButtonType
---| EPCheckBoxType
---| EPProgressBarType
---| EPReminderMessageType
---| EPColorPickerType
---| EPMessageBoxType
---| EPPhaseLengthEditor
---| EPNewPlanDialog
---| EPScrollFrame
---| EPStatusBar
---| EPTutorial

---@alias EPContainerType
---| EPAssignmentEditorType
---| EPMainFrameType
---| EPBaseContainerType
---| EPRosterEditorType
---| EPAnchorContainerType

---@class AceGUI-3.0
local AceGUI = {}

---@class AceGUIWidget
local AceGUIWidget = {}

---@class AceGUIContainer : AceGUIWidget
local AceGUIContainer = {}

---@param type AceGUIWidgetType|EPWidgetType|EPLayoutType
---@return AceGUIWidget
function AceGUI:Create(type) end

---@param type EPBaseContainerType
---@return EPContainer
function AceGUI:Create(type) end

---@param type EPAnchorContainerType
---@return EPAnchorContainer
function AceGUI:Create(type) end

---@param type EPSpacerType
---@return EPSpacer
function AceGUI:Create(type) end

---@param type EPLabelType
---@return EPLabel
function AceGUI:Create(type) end

---@param type EPLineEditType
---@return EPLineEdit
function AceGUI:Create(type) end

---@param type EPButtonType
---@return EPButton
function AceGUI:Create(type) end

---@param type EPRadioButtonType
---@return EPRadioButton
function AceGUI:Create(type) end

---@param type EPCheckBoxType
---@return EPCheckBox
function AceGUI:Create(type) end

---@param type EPEditBoxType
---@return EPEditBox
function AceGUI:Create(type) end

---@param type EPDropdownPulloutType
---@return EPDropdownPullout
function AceGUI:Create(type) end

---@param type EPDropdownItemToggleType
---@return EPDropdownItemToggle
function AceGUI:Create(type) end

---@param type EPDropdownItemMenuType
---@return EPDropdownItemMenu
function AceGUI:Create(type) end

---@param type EPDropdownType
---@return EPDropdown
function AceGUI:Create(type) end

---@param type EPAbilityEntryType
---@return EPAbilityEntry
function AceGUI:Create(type) end

---@param type EPAssignmentEditorType
---@return EPAssignmentEditor
function AceGUI:Create(type) end

---@param type EPTimelineType
---@return EPTimeline
function AceGUI:Create(type) end

---@param type EPMainFrameType
---@return EPMainFrame
function AceGUI:Create(type) end

---@param type EPRosterEditorType
---@return EPRosterEditor
function AceGUI:Create(type) end

---@param type EPRosterEntryType
---@return EPRosterEntry
function AceGUI:Create(type) end

---@param type EPTimelineSectionType
---@return EPTimelineSection
function AceGUI:Create(type) end

---@param type EPOptionsType
---@return EPOptions
function AceGUI:Create(type) end

---@param type EPProgressBarType
---@return EPProgressBar
function AceGUI:Create(type) end

---@param type EPReminderMessageType
---@return EPReminderMessage
function AceGUI:Create(type) end

---@param type EPColorPickerType
---@return EPColorPicker
function AceGUI:Create(type) end

---@param type EPMessageBoxType
---@return EPMessageBox
function AceGUI:Create(type) end

---@param type EPPhaseLengthEditorType
---@return EPPhaseLengthEditor
function AceGUI:Create(type) end

---@param type EPNewPlanDialogType
---@return EPNewPlanDialog
function AceGUI:Create(type) end

---@param type EPScrollFrameType
---@return EPScrollFrame
function AceGUI:Create(type) end

---@param type EPStatusBarType
---@return EPStatusBar
function AceGUI:Create(type) end

---@param type EPTutorialType
---@return EPTutorial
function AceGUI:Create(type) end

---@param type AceGUIContainerType|EPContainerType
---@return AceGUIContainer
function AceGUI:Create(type) end

---@param Name AceGUILayoutType|EPLayoutType
---@return function
function AceGUI:GetLayout(Name) end

---@param widget AceGUIWidget|EPWidgetType
function AceGUI:RegisterAsContainer(widget) end

---@param widget AceGUIWidget|EPWidgetType
function AceGUI:RegisterAsWidget(widget) end

---@param widget AceGUIWidget|EPWidgetType
function AceGUI:Release(widget) end

---@param widget AceGUIWidget|EPWidgetType
function AceGUI:SetFocus(widget) end

---@param parent AceGUIWidget|EPWidgetType
function AceGUIWidget:SetParent(parent) end

---@param widget AceGUIWidget|EPWidgetType
---@param beforeWidget? AceGUIWidget|EPWidgetType
function AceGUIContainer:AddChild(widget, beforeWidget) end

---@param ... AceGUIWidget|EPWidgetType
function AceGUIContainer:AddChildren(...) end

---@param layout AceGUILayoutType|EPLayoutType
function AceGUIContainer:SetLayout(layout) end
