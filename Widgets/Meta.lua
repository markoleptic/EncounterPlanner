---@meta

---@alias EPLayoutType
---|"EPContentFrameLayout"
---|"EPHorizontalLayout"
---|"EPVerticalLayout"

---@alias EPBaseContainerType
---|"EPContainer"

---@alias EPSpacerType
---|"EPSpacer"

---@alias EPLabelType
---|"EPLabel"

---@alias EPLineEditType
---|"EPLineEdit"

---@alias EPDropdownPulloutType
---|"EPDropdownPullout"

---@alias EPDropdownItemToggleType
---|"EPDropdownItemToggle"

---@alias EPDropdownItemMenuType
---|"EPDropdownItemMenu"

---@alias EPDropdownType
---|"EPDropdown"

---@class EPAbilityEntry : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field checkbg Texture
---@field check table|Frame
---@field checkbox table|Frame
---@field label EPLabel
---@field highlight Texture
---@field disabled boolean
---@field checked boolean

---@alias EPAbilityEntryType
---|"EPAbilityEntry"

---@alias EPAssignmentEditorType
---|"EPAssignmentEditor"

---@alias EPTimelineType
---|"EPTimeline"

---@alias EPMainFrameType
---|"EPMainFrame"

---@alias EPWidgetType
---| EPSpacerType
---| EPLabelType
---| EPLineEditType
---| EPDropdownPulloutType
---| EPDropdownItemToggleType
---| EPDropdownItemMenuType
---| EPDropdownType
---| EPAbilityEntryType
---| EPAssignmentEditorType
---| EPTimelineType
---| EPMainFrameType

---@alias EPContainerType
---| EPAssignmentEditorType
---| EPMainFrameType
---| EPBaseContainerType

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

---@param type EPSpacerType
---@return EPSpacer
function AceGUI:Create(type) end

---@param type EPLabelType
---@return EPLabel
function AceGUI:Create(type) end

---@param type EPLineEditType
---@return EPLineEdit
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

---@param widget AceGUIWidget|EPWidgetType
---@param beforeWidget? AceGUIWidget|EPWidgetType
function AceGUIContainer:AddChild(widget, beforeWidget) end

---@param layout AceGUILayoutType|EPLayoutType
function AceGUIContainer:SetLayout(layout) end
