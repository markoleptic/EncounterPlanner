---@meta _
---@alias EPLayoutType
---|"EPContentFrameLayout"

---@alias EPWidgetType
---|"EPAbilityEntry"
---|"EPDropdown"
---|"EPMainFrame"
---|"EPDropdownItemToggle"
---|"EPSpacer"
---|"EPTimeline"
---|"Dropdown-Item-Execute"
---|"EPDropdownItemToggle"
---|"EPDropdownPullout"

---@alias EPContainerType
---|"EPMainFrame"


---@class Private
local Private = {}

function Private:Note() end

---[Documentation](https://www.wowace.com/projects/ace3/pages/api/ace-gui-3-0)
---@class AceGUI-3.0
local AceGUI = {}

---@param type AceGUIWidgetType|AceGUIContainerType|EPWidgetType|EPLayoutType
---@return AceGUIWidget
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

---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets)
---@class AceGUIWidget
local AceGUIWidget = {}

---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets)
---@class AceGUIContainer : AceGUIWidget
local AceGUIContainer = {}

---@param widget AceGUIWidget|EPWidgetType
---@param beforeWidget? AceGUIWidget|EPWidgetType
---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets#title-3-1)
function AceGUIContainer:AddChild(widget, beforeWidget) end

---@param layout AceGUILayoutType|EPLayoutType
---[Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets#title-3-2)
function AceGUIContainer:SetLayout(layout) end

---@class EPAbilityEntry : AceGUIWidget
local EPAbilityEntry = {}

---@param spellID number
function EPAbilityEntry:SetAbility(spellID) end

---@class EPTimeline : AceGUIWidget
local EPTimeline = {}

---@param abilities table
---@param abilityOrder table
---@param phases table
function EPTimeline:SetEntries(abilities, abilityOrder, phases) end

---@class EPDropdown : AceGUIWidget
local EPDropdown = {}

function EPDropdown:SetList(list, order, itemType) end

function EPDropdown:SetValue(value) end
