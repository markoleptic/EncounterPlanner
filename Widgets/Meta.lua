---@meta

---@class EPContentFrameLayout
---@class EPHorizontalLayout
---@class EPVerticalLayout
---@class EPReminderLayout

---@alias EPLayoutType
---| EPContentFrameLayout
---| EPHorizontalLayout
---| EPVerticalLayout
---| EPReminderLayout

---@alias EPWidgetType
---| EPSpacer
---| EPLabel
---| EPLineEdit
---| EPEditBox
---| EPDropdownPullout
---| EPDropdownItemToggle
---| EPDropdownItemMenu
---| EPDropdown
---| EPAbilityEntry
---| EPAssignmentEditor
---| EPTimeline
---| EPMainFrame
---| EPTimelineSection
---| EPRadioButton
---| EPCheckBox
---| EPProgressBar
---| EPReminderMessage
---| EPReminderIcon
---| EPColorPicker
---| EPMessageBox
---| EPPhaseLengthEditor
---| EPNewPlanDialog
---| EPScrollFrame
---| EPStatusBar
---| EPTutorial
---| EPDiffViewer
---| EPDiffViewerEntry
---| EPMultiLineText
---| EPWindowBar

---@alias EPContainerType
---| EPAssignmentEditor
---| EPMainFrame
---| EPContainer
---| EPRosterEditor
---| EPAnchorContainer

---@class AceGUI-3.0
local AceGUI = {}

---@class AceGUIWidget
local AceGUIWidget = {}

---@class AceGUIContainer : AceGUIWidget
local AceGUIContainer = {}

---@generic T
---@param type `T` | EPWidgetType
---@return T
function AceGUI:Create(type) end

---@generic T
---@param type `T` | EPContainerType
---@return `T`
function AceGUI:Create(type) end

---@generic T
---@param Name `T` | EPLayoutType
---@return function
function AceGUI:GetLayout(Name) end

---@generic T
---@param widget `T` | EPContainerType
function AceGUI:RegisterAsContainer(widget) end

---@generic T
---@param widget EPWidgetType
function AceGUI:RegisterAsWidget(widget) end

---@generic T
---@param widget `T` | EPWidgetType | EPContainerType
function AceGUI:Release(widget) end

---@generic T
---@param widget `T` | EPWidgetType | EPContainerType
function AceGUI:SetFocus(widget) end

---@generic T
---@param parent `T` | EPWidgetType | EPContainerType
function AceGUIWidget:SetParent(parent) end

---@generic T
---@param widget `T` | EPWidgetType | EPContainerType
---@param beforeWidget? `T` | EPWidgetType | EPContainerType
function AceGUIContainer:AddChild(widget, beforeWidget) end

---@generic T
---@param ... `T` | EPWidgetType | EPContainerType
function AceGUIContainer:AddChildren(...) end

---@generic T
---@param layout `T` | EPLayoutType
function AceGUIContainer:SetLayout(layout) end

---@class AssignmentFrame : Frame, BackdropTemplate
---@field spellTexture Texture
---@field invalidTexture Texture
---@field cooldownFrame Frame
---@field cooldownParent Texture
---@field cooldownBackground Texture
---@field cooldownTexture Texture
---@field assignmentFrame Frame
---@field timelineAssignment TimelineAssignment|nil
---@field spellID integer
---@field selectionType AssignmentSelectionType
---@field uniqueAssignmentID integer
---@field chargeMarker Texture|nil

---@class FakeAssignmentFrame : AssignmentFrame
---@field temporaryAssignmentFrameIndex integer

---@class BossAbilityFrame : Frame, BackdropTemplate
---@field spellTexture Texture
---@field lineTexture Texture
---@field cooldownFrame Frame
---@field cooldownParent Texture
---@field cooldownBackground Texture
---@field cooldownTexture Texture
---@field abilityInstance BossAbilityInstance|nil
---@field selectionType BossAbilitySelectionType

---@class BossPhaseIndicatorTexture : Texture
---@field label FontString

---@class LastPhaseIndicatorInfo
---@field left number
---@field right number
---@field shortName	string
---@field partialLeft number
---@field label FontString|nil
---@field alreadyShortened boolean|nil

---@class EPTimeLabel : FontString
---@field wantsToShow boolean
