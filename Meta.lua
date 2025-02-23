---@meta _
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
