---@meta _

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
---| fun(): string|boolean|table<integer, number>|number,number?,number?,number?

---@alias SetFunction
---| fun(value: string|boolean|number|table<integer, number>, value2?: string|boolean|number, value3?:number, value4?:number)

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

---@alias AssignmentConversionMethod
---| 1 # Convert combat log event assignments to timed assignments
---| 2 # Replace combat log event spells with those of the new boss, matching the closest timing

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
---@param func fun()|string
function Private.RegisterCallback(target, name, func) end

---@param target table
---@param name string
function Private.UnregisterCallback(target, name) end
