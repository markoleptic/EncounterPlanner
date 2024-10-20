---@meta
---@alias EPLayoutType
---|"EPContentFrameLayout"

---@alias EPWidgetType
---|"EPAbilityEntry"
---|"EPDropdown"
---|"EPDropdownItemToggle"
---|"EPSpacer"
---|"EPTimeline"
---|"Dropdown-Item-Execute"
---|"EPDropdownItemToggle"
---|"EPDropdownPullout"

---@alias EPContainerType
---|"EPMainFrame"

---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0)
---@class AceGUI-3.0
local AceGUI = {}

---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets)
---@class AceGUIWidget
local AceGUIWidget = {}

---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets)
---@class AceGUIContainer : AceGUIWidget
local AceGUIContainer = {}

---@param type AceGUIWidgetType|EPWidgetType|EPLayoutType
---@return AceGUIWidget
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-3)
function AceGUI:Create(type) end

---@param type AceGUIContainerType|EPContainerType
---@return AceGUIContainer
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-3)
function AceGUI:Create(type) end

---@param Name AceGUILayoutType|EPLayoutType
---@return function
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-4)
function AceGUI:GetLayout(Name) end

---@param widget AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-8)
function AceGUI:RegisterAsContainer(widget) end

---@param widget AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-9)
function AceGUI:RegisterAsWidget(widget) end

---@param widget AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-12)
function AceGUI:Release(widget) end

---@param widget AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0#title-13)
function AceGUI:SetFocus(widget) end

---@param widget AceGUIWidget|EPWidgetType
---@param beforeWidget? AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets#title-3-1)
function AceGUIContainer:AddChild(widget, beforeWidget) end

---@param layout AceGUILayoutType|EPLayoutType
---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets#title-3-2)
function AceGUIContainer:SetLayout(layout) end
