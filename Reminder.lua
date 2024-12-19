---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn

local getmetatable = getmetatable
local GetTime = GetTime
local ipairs = ipairs
local NewTimer = C_Timer.NewTimer
local next = next
local pairs = pairs
local tinsert = tinsert
local type = type
local wipe = wipe

local timers = {}
local activeTimers = {}
local activeSimulationTimers = {}
local combatLogEventReminders = {}
local eventFilter = {}
local spellCounts = {}
local combatLogEventMap = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

do
	local eventMap = {}
	local eventFrame = CreateFrame("Frame")

	eventFrame:SetScript("OnEvent", function(_, event, ...)
		for k, v in pairs(eventMap[event]) do
			if type(v) == "function" then
				v(event, ...)
			else
				k[v](k, event, ...)
			end
		end
	end)

	function Private:RegisterEvent(event, func)
		if type(event) == "string" then
			eventMap[event][self] = func or event
			eventFrame:RegisterEvent(event)
		end
	end

	function Private:UnregisterEvent(event)
		if type(event) == "string" then
			if eventMap[event] then
				eventMap[event][self] = nil
				if not next(eventMap[event]) then
					eventFrame:UnregisterEvent(event)
					eventMap[event] = nil
				end
			end
		end
	end

	function Private:UnregisterAllEvents()
		for k, v in pairs(eventMap) do
			for _, j in pairs(v) do
				j:UnregisterEvent(k)
			end
		end
	end
end

local function GetOrCreateTable(tbl, key)
	if not tbl[key] then
		tbl[key] = {}
	end
	return tbl[key]
end

local function PrintReminder(assignment, roster)
	print(Private:CreateNotePreviewText(assignment, roster))
end

local function SimulateHandleCombatLogEventUnfiltered(time, event, spellID)
	-- local time, event, _, _, sourceName, _, _, _, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
	if eventFilter[event] then
		spellCounts[spellID] = spellCounts[spellID] + 1
		local combatLogEventReminder = combatLogEventReminders[event][spellID][spellCounts[spellID]]
		if combatLogEventReminder then
			local start = combatLogEventReminder.relativeStartTime - combatLogEventReminder.advanceNotice
			tinsert(
				activeTimers,
				NewTimer(start < 0 and 0.1 or start, function()
					PrintReminder(combatLogEventReminder.assignment, combatLogEventReminder.roster)
				end)
			)
		end
	end
end

---@param timelineAssignments table<integer, TimelineAssignment>
---@param roster table<string, EncounterPlannerDbRosterEntry>
function Private:SimulateBoss(timelineAssignments, roster)
	local startTime = GetTime()
	for _, timelineAssignment in ipairs(timelineAssignments) do
		if getmetatable(timelineAssignment.assignment) == Private.classes.CombatLogEventAssignment then
			local assignment = timelineAssignment.assignment --[[@as CombatLogEventAssignment]]
			local combatLogEventType = combatLogEventMap[assignment.combatLogEventType]

			if not eventFilter[combatLogEventType] then
				eventFilter[combatLogEventType] = true
				GetOrCreateTable(spellCounts, combatLogEventType)
			end
			if not spellCounts[combatLogEventType][assignment.combatLogEventSpellID] then
				spellCounts[combatLogEventType][assignment.combatLogEventSpellID] = 0
			end

			local t1 = GetOrCreateTable(combatLogEventReminders, assignment.combatLogEventType)
			local t2 = GetOrCreateTable(t1, assignment.combatLogEventSpellID)
			local t3 = GetOrCreateTable(t2, assignment.spellCount)

			local reminder = {
				advanceNotice = 10,
				cancelIfAlreadyCasted = true,
				assignment = assignment,
				relativeStartTime = timelineAssignment.startTime,
				order = timelineAssignment.order,
				roster = roster,
			}
			tinsert(t3, reminder)
			local start = timelineAssignment.startTime - reminder.advanceNotice - (GetTime() - startTime)
			tinsert(
				activeSimulationTimers,
				NewTimer(start < 0 and 0.1 or start, function()
					SimulateHandleCombatLogEventUnfiltered(
						GetTime(),
						combatLogEventMap[assignment.combatLogEventType],
						assignment.combatLogEventSpellID
					)
				end)
			)
		elseif getmetatable(timelineAssignment.assignment) == Private.classes.TimedAssignment then
			local assignment = timelineAssignment.assignment --[[@as TimedAssignment]]
			local reminder = { advanceNotice = 10, cancelIfAlreadyCasted = true }
			local start = timelineAssignment.startTime - reminder.advanceNotice - (GetTime() - startTime)
			tinsert(
				activeSimulationTimers,
				NewTimer(start < 0 and 0.1 or start, function()
					PrintReminder(assignment, roster)
				end)
			)
		end
	end
end

function Private:StopSimulatingBoss()
	for _, timer in pairs(activeSimulationTimers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	for _, timer in pairs(activeTimers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	for _, timer in pairs(timers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(activeSimulationTimers)
	wipe(activeTimers)
	wipe(timers)
	wipe(eventFilter)
	wipe(combatLogEventReminders)
	wipe(spellCounts)
end

function Private:IsSimulatingBoss()
	return #activeSimulationTimers > 0
end
