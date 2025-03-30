local _, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L
local GenerateUniqueID = Private.GenerateUniqueID
---@class TimedAssignment
local TimedAssignment = Private.classes.TimedAssignment
---@class CombatLogEventAssignment
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment

---@class Constants
local constants = Private.constants
local kTextAssignmentSpellID = constants.kTextAssignmentSpellID

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local GetBoss = bossUtilities.GetBoss

---@class Utilities
local utilities = Private.utilities
local CreateReminderContainer = utilities.CreateReminderContainer
local CreateReminderText = utilities.CreateReminderText
local FindGroupMemberUnit = utilities.FindGroupMemberUnit
local FilterSelf = utilities.FilterSelf

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local LCG = LibStub("LibCustomGlow-1.0")
local LGF = LibStub("LibGetFrame-1.0")

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local floor = math.floor
local format = string.format
local getmetatable = getmetatable
local GetSpellTexture = C_Spell.GetSpellTexture
local GetTime = GetTime
local ipairs = ipairs
local max = math.max
local NewTicker = C_Timer.NewTicker
local NewTimer = C_Timer.NewTimer
local next = next
local pairs = pairs
local PlaySoundFile = PlaySoundFile
local SpeakText = C_VoiceChat.SpeakText
local split = string.split
local tinsert = table.insert
local tonumber = tonumber
local type = type
local UnitGUID = UnitGUID
local UnitIsGroupLeader = UnitIsGroupLeader
local unpack = unpack
local wipe = table.wipe

local playerGUID = UnitGUID("player")

local combatLogEventMap = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
	["UD"] = "UNIT_DIED",
}

---@class CombatLogEventAssignmentData
---@field preferences ReminderPreferences
---@field assignment CombatLogEventAssignment
---@field roster table<string, RosterEntry>

local messageContainer = nil ---@type EPContainer|nil
local progressBarContainer = nil ---@type EPContainer|nil

local simulationTimer = nil ---@type FunctionContainer|nil

---@type table<string, FunctionContainer>
local timers = {} -- Timers that will either call ExecuteReminderTimer or deferred functions created in ExecuteReminderTimer

---@type table<FullCombatLogEventType, table<integer, integer>> -- FullCombatLogEventType -> SpellID -> Count \
local spellCounts = {} -- Acts as filter for combat log events. Increments spell occurrences for registered combat log events.
---@type table<FullCombatLogEventType, table<integer, table<integer, table<integer, CombatLogEventAssignmentData>>>>
local combatLogEventReminders = {} -- Table of active reminders for responding to combat log events

---@type table<integer, table<string, FunctionContainer>> -- Spell ID -> Timer ID -> Timer
local cancelTimerIfCasted = {}
---@type table<integer, table<string, EPProgressBar|EPReminderMessage>> -- Spell ID -> Timer ID -> Widget
local hideWidgetIfCasted = {}
---@type table<integer, table<string, {frame: Frame, targetGUID: integer|nil}>> -- Spell ID -> [{Frame, Target GUID}]
local stopGlowIfCasted = {}

---@type table<integer, Frame> -- [Frame]
local noSpellIDGlowFrames = {}
---@type table<string, FunctionContainer> -- All timers used to glow frames [timers]
local frameGlowTimers = {}

---@type table<integer, number> -- Buffers to use to prevent successive combat log events from retriggering.
local bufferDurations = {}
---@type table<integer, table<FullCombatLogEventType, boolean>> -- Active buffers preventing successive combat log events from retriggering.
local activeBuffers = {}
---@type table<string, FunctionContainer> -- Active buffers preventing successive combat log events from retriggering.
local bufferTimers = {}

local hideIfAlreadyCasted = false
local isSimulating = false
local updateTimerTickRate = 0.04
local updateTimerIterations = 30000
local defaultNoSpellIDGlowDuration = 5.0
local maxGlowDuration = 10.0
local updateTimer = nil ---@type FunctionContainer|nil
local messagesToAdd = {}
local progressBarsToAdd = {}
local messagesToRemove = {}
local progressBarsToRemove = {}

local function ResetLocalVariables()
	if updateTimer and not updateTimer:IsCancelled() then
		updateTimer:Cancel()
	end
	updateTimer = nil

	for _, timer in pairs(timers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(timers)
	wipe(cancelTimerIfCasted)

	if simulationTimer and not simulationTimer:IsCancelled() then
		simulationTimer:Cancel()
	end
	simulationTimer = nil

	for _, timer in pairs(frameGlowTimers) do
		if not timer:IsCancelled() then
			timer:Invoke(timer)
			timer:Cancel()
		end
	end
	wipe(frameGlowTimers)

	for _, targetFrames in pairs(stopGlowIfCasted) do
		for _, targetFrame in pairs(targetFrames) do
			if targetFrame.frame then
				LCG.PixelGlow_Stop(targetFrame.frame)
			end
		end
	end
	wipe(stopGlowIfCasted)

	for _, frame in ipairs(noSpellIDGlowFrames) do
		if frame then
			LCG.PixelGlow_Stop(frame)
		end
	end
	wipe(noSpellIDGlowFrames)

	wipe(hideWidgetIfCasted)
	wipe(combatLogEventReminders)
	wipe(spellCounts)

	for _, timer in pairs(bufferTimers) do
		if not timer:IsCancelled() then
			timer:Cancel()
		end
	end
	wipe(bufferTimers)
	wipe(bufferDurations)
	wipe(activeBuffers)

	for _, widget in ipairs(messagesToAdd) do
		if widget then
			AceGUI:Release(widget)
		end
	end

	for _, widget in ipairs(progressBarsToAdd) do
		if widget then
			AceGUI:Release(widget)
		end
	end

	wipe(messagesToAdd)
	wipe(progressBarsToAdd)
	wipe(messagesToRemove)
	wipe(progressBarsToRemove)

	if messageContainer then
		messageContainer:Release()
	end
	if progressBarContainer then
		progressBarContainer:Release()
	end

	isSimulating = false
	hideIfAlreadyCasted = false
end

---@param ... unknown
---@return table
local function pack(...)
	return { n = select("#", ...), ... }
end

---@param spellID integer
---@param bossPhaseOrderIndex integer|nil
---@return table
local function CreateTimerWithCleanupArgs(spellID, bossPhaseOrderIndex)
	local args = {}
	if hideIfAlreadyCasted and spellID > kTextAssignmentSpellID then
		cancelTimerIfCasted[spellID] = cancelTimerIfCasted[spellID] or {}
		args[#args + 1] = cancelTimerIfCasted[spellID]
	end
	return args
end

---@param duration number Duration of timer to create in seconds.
---@param func fun(timerObject: FunctionContainer) Function to execute when timer expires.
---@param ... table<string, FunctionContainer> Tables to insert the timer into on creation and remove from on expiration.
---@return FunctionContainer
local function CreateTimerWithCleanup(duration, func, ...)
	local args = pack(...)
	local timer = NewTimer(duration, function(timerObject)
		func(timerObject)
		timerObject.RemoveTimerRef(timerObject)
	end)
	timer.RemoveTimerRef = function(self)
		for i = 1, args.n do
			local tableRef = args[i]
			if tableRef then
				tableRef[self.ID] = nil
			end
		end
	end

	local ID = GenerateUniqueID()
	timer.ID = ID
	for i = 1, args.n do
		local tableRef = args[i]
		if tableRef then
			tableRef[ID] = timer
		end
	end
	return timer
end

local function ProcessNextOperation()
	if messageContainer then
		messageContainer:RemoveChildren(unpack(messagesToRemove))
		messagesToRemove = {}
		messageContainer:AddChildren(unpack(messagesToAdd))
		messagesToAdd = {}
	end
	if progressBarContainer then
		progressBarContainer:RemoveChildren(unpack(progressBarsToRemove))
		progressBarsToRemove = {}
		progressBarContainer:AddChildren(unpack(progressBarsToAdd))
		progressBarsToAdd = {}
	end
end

-- Creates a container for adding progress bars to using preferences.
---@param preferences MessagePreferences
local function CreateMessageContainer(preferences)
	if not messageContainer then
		messageContainer = CreateReminderContainer(preferences)
		messageContainer:SetCallback("OnRelease", function()
			messageContainer = nil
		end)
	end
end

-- Creates a container for adding progress bars to using preferences.
---@param preferences ProgressBarPreferences
local function CreateProgressBarContainer(preferences)
	if not progressBarContainer then
		progressBarContainer = CreateReminderContainer(preferences, preferences.spacing)
		progressBarContainer:SetCallback("OnRelease", function()
			progressBarContainer = nil
		end)
	end
end

---@param widget EPReminderMessage|EPProgressBar
---@param spellID integer
---@param bossPhaseOrderIndex integer|nil
---@param isProgressBar boolean
local function CreateReminderWidgetCallback(widget, spellID, bossPhaseOrderIndex, isProgressBar)
	local uniqueID = GenerateUniqueID()

	widget:SetCallback("Completed", function(w)
		if hideWidgetIfCasted[spellID] then
			hideWidgetIfCasted[spellID][uniqueID] = nil
		end
		if isProgressBar then
			tinsert(progressBarsToRemove, w)
		else
			tinsert(messagesToRemove, w)
		end
	end)

	if hideIfAlreadyCasted and spellID > kTextAssignmentSpellID then
		hideWidgetIfCasted[spellID] = hideWidgetIfCasted[spellID] or {}
		hideWidgetIfCasted[spellID][uniqueID] = widget
	end
end

-- Creates an EPProgressBar widget and schedules its cleanup on the Completed callback. Starts the countdown.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param icon integer|nil
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, duration, reminderText, icon, progressBarPreferences)
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	local progressBar = AceGUI:Create("EPProgressBar")
	progressBar:Set(progressBarPreferences, reminderText, duration, icon)
	CreateReminderWidgetCallback(progressBar, assignment.spellID, bossPhaseOrderIndex, true)
	tinsert(progressBarsToAdd, progressBar)
	progressBar:Start()
end

-- Creates an EPReminderMessage widget and schedules its cleanup based on completion. Starts the countdown if applicable.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param icon integer|nil
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, duration, reminderText, icon, messagePreferences)
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	local message = AceGUI:Create("EPReminderMessage")
	message:Set(messagePreferences, reminderText, icon)
	CreateReminderWidgetCallback(message, assignment.spellID, bossPhaseOrderIndex, false)
	tinsert(messagesToAdd, message)
	message:Start(duration)
end

-- Starts glowing the frame for the unit and creates a timer to stop the glowing of the frame.
---@param unit string
---@param frame Frame
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
local function GlowFrameAndCreateTimer(unit, frame, assignment)
	local spellID = assignment.spellID
	if spellID > kTextAssignmentSpellID then
		local targetFrameObject = { frame = frame, targetGUID = UnitGUID(unit) }
		stopGlowIfCasted[spellID] = stopGlowIfCasted[spellID] or {}
		local timer = CreateTimerWithCleanup(maxGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			if stopGlowIfCasted[spellID] then
				stopGlowIfCasted[spellID][timerObject.ID] = nil
			end
		end, frameGlowTimers)
		stopGlowIfCasted[spellID][timer.ID] = targetFrameObject
	else
		local timer = CreateTimerWithCleanup(defaultNoSpellIDGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			noSpellIDGlowFrames[timerObject.ID] = nil
		end, frameGlowTimers)
		noSpellIDGlowFrames[timer.ID] = frame
	end
	LCG.PixelGlow_Start(frame)
end

-- Executes the actions that occur at the time in which reminders are first displayed. This is usually at countdown start
-- time before the assignment, but can also be sooner if towards the start of the encounter. Creates timers for actions
-- that occur at assignment time.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param duration number
local function ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
	local reminderText = CreateReminderText(assignment, roster, false)
	local ttsPreferences = reminderPreferences.textToSpeech
	local soundPreferences = reminderPreferences.sound
	local spellID = assignment.spellID
	local icon = spellID > constants.kTextAssignmentSpellID and GetSpellTexture(spellID) or nil

	if reminderPreferences.progressBars.enabled then
		AddProgressBar(assignment, duration, reminderText, icon, reminderPreferences.progressBars)
	end
	if reminderPreferences.messages.enabled and not reminderPreferences.messages.showOnlyAtExpiration then
		AddMessage(assignment, duration, reminderText, icon, reminderPreferences.messages)
	end
	if ttsPreferences.enableAtCountdownStart then
		if reminderText:len() > 0 then
			local textWithCountdown = format("%s %s %d", reminderText, L["in"], floor(duration))
			SpeakText(ttsPreferences.voiceID, textWithCountdown, 1, 1.0, ttsPreferences.volume)
		end
	end
	if soundPreferences.enableAtCountdownStart then
		if soundPreferences.countdownStartSound and soundPreferences.countdownStartSound ~= "" then
			PlaySoundFile(soundPreferences.countdownStartSound)
		end
	end

	---@type table<integer, fun()>
	local deferredFunctions = {}

	if reminderPreferences.messages.enabled and reminderPreferences.messages.showOnlyAtExpiration then
		deferredFunctions[#deferredFunctions + 1] = function()
			AddMessage(assignment, 0, reminderText, icon, reminderPreferences.messages)
		end
	end
	if ttsPreferences.enableAtCountdownEnd then
		if reminderText:len() > 0 then
			deferredFunctions[#deferredFunctions + 1] = function()
				SpeakText(ttsPreferences.voiceID, reminderText, 1, 1.0, ttsPreferences.volume)
			end
		end
	end
	if
		soundPreferences.enableAtCountdownEnd
		and soundPreferences.countdownEndSound
		and soundPreferences.countdownEndSound ~= ""
	then
		deferredFunctions[#deferredFunctions + 1] = function()
			PlaySoundFile(soundPreferences.countdownEndSound)
		end
	end
	if reminderPreferences.glowTargetFrame and assignment.targetName ~= "" then
		deferredFunctions[#deferredFunctions + 1] = function()
			local unit = FindGroupMemberUnit(assignment.targetName)
			if unit then
				local frame = LGF.GetUnitFrame(unit)
				if frame then
					GlowFrameAndCreateTimer(unit, frame, assignment)
				end
			end
		end
	end

	if #deferredFunctions > 0 then
		local args = CreateTimerWithCleanupArgs(spellID, assignment.bossPhaseOrderIndex)
		CreateTimerWithCleanup(duration, function()
			for _, func in ipairs(deferredFunctions) do
				func()
			end
		end, timers, unpack(args))
	end
end

---@param assignment TimedAssignment|CombatLogEventAssignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param elapsed number
local function CreateTimer(assignment, roster, reminderPreferences, elapsed)
	local duration = reminderPreferences.countdownLength
	local startTime = assignment.time - duration - elapsed

	if startTime < 0 then
		duration = max(0.1, assignment.time - elapsed)
	end

	if startTime < 0.1 then
		ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
	else
		local args = CreateTimerWithCleanupArgs(assignment.spellID, assignment.bossPhaseOrderIndex)
		CreateTimerWithCleanup(startTime, function()
			ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
		end, timers, unpack(args))
	end
end

-- Creates an empty table entry so that a CombatLogEventAssignment can be inserted into it.
---@param combatLogEventType FullCombatLogEventType
---@param spellID integer
---@param spellCount integer
local function CreateSpellCountEntry(combatLogEventType, spellID, spellCount)
	spellCounts[combatLogEventType] = spellCounts[combatLogEventType] or {}
	spellCounts[combatLogEventType][spellID] = spellCounts[combatLogEventType][spellID] or 0
	combatLogEventReminders[combatLogEventType] = combatLogEventReminders[combatLogEventType] or {}
	combatLogEventReminders[combatLogEventType][spellID] = combatLogEventReminders[combatLogEventType][spellID] or {}
	for i = 1, spellCount do
		if not combatLogEventReminders[combatLogEventType][spellID][i] then
			combatLogEventReminders[combatLogEventType][spellID][i] = {}
		end
	end
end

-- Populates the combatLogEventReminders table with CombatLogEventAssignments, creates timers for timed assignments, and
-- sets the script that updates the operation queue.
---@param plans table<string, Plan>
---@param preferences ReminderPreferences
---@param startTime number
---@param abilities table<integer, BossAbility>
local function SetupReminders(plans, preferences, startTime, abilities)
	if not messageContainer then
		CreateMessageContainer(preferences.messages)
	end
	if not progressBarContainer then
		CreateProgressBarContainer(preferences.progressBars)
	end

	for _, plan in pairs(plans) do
		local roster = plan.roster
		local assignments = plan.assignments
		local filteredAssignments = nil
		if preferences.onlyShowMe then
			filteredAssignments = FilterSelf(assignments) --[[@as table<integer, Assignment>]]
		end
		for _, assignment in ipairs(filteredAssignments or assignments) do
			if getmetatable(assignment) == CombatLogEventAssignment then
				---@cast assignment CombatLogEventAssignment
				local abbreviatedCombatLogEventType = assignment.combatLogEventType
				local fullCombatLogEventType = combatLogEventMap[abbreviatedCombatLogEventType]
				local spellID = assignment.combatLogEventSpellID
				local spellCount = assignment.spellCount
				if abilities[spellID] and abilities[spellID].buffer then
					bufferDurations[spellID] = abilities[spellID].buffer
				end
				CreateSpellCountEntry(fullCombatLogEventType, spellID, spellCount)

				local currentSize = #combatLogEventReminders[fullCombatLogEventType][spellID][spellCount]
				combatLogEventReminders[fullCombatLogEventType][spellID][spellCount][currentSize + 1] = {
					preferences = preferences,
					assignment = assignment,
					roster = roster,
				}
			elseif getmetatable(assignment) == TimedAssignment then
				---@cast assignment TimedAssignment
				CreateTimer(assignment, roster, preferences, GetTime() - startTime)
			end
		end
	end

	updateTimer = NewTicker(updateTimerTickRate, ProcessNextOperation, updateTimerIterations)
end

---@param spellID integer
---@param combatLogEventType FullCombatLogEventType
local function ApplyBuffer(spellID, combatLogEventType)
	activeBuffers[spellID] = activeBuffers[spellID] or {}
	activeBuffers[spellID][combatLogEventType] = true
	CreateTimerWithCleanup(bufferDurations[spellID], function()
		activeBuffers[spellID][combatLogEventType] = nil
		if not next(activeBuffers[spellID]) then
			activeBuffers[spellID] = nil
		end
	end, bufferTimers)
end

-- Cancels active timers and releases active widgets associated with a spellID.
---@param spellID integer
local function CancelRemindersDueToSpellAlreadyCast(spellID)
	if type(cancelTimerIfCasted[spellID]) == "table" then
		for _, timer in pairs(cancelTimerIfCasted[spellID]) do
			timer:Cancel()
			timer.RemoveTimerRef(timer)
		end
		cancelTimerIfCasted[spellID] = nil
	end
	if type(hideWidgetIfCasted[spellID]) == "table" then
		for _, widget in pairs(hideWidgetIfCasted[spellID]) do
			if widget.type == "EPReminderMessage" then
				tinsert(messagesToRemove, widget)
			elseif widget.type == "EPProgressBar" then
				tinsert(progressBarsToRemove, widget)
			end
		end
		hideWidgetIfCasted[spellID] = nil
	end
end

-- Callback for CombatLogEventUnfiltered events. Creates timers from previously created reminders for
-- CombatLogEventAssignments.
local function HandleCombatLogEventUnfiltered()
	local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
	if not spellCounts[subEvent] then
		return
	end

	if subEvent == "UNIT_DIED" and destGUID then
		local _, _, _, _, _, id = split("-", destGUID)
		local mobID = tonumber(id)
		if mobID and spellCounts[subEvent][mobID] then
			if not activeBuffers[mobID] or (activeBuffers[mobID] and not activeBuffers[mobID][subEvent]) then
				if bufferDurations[mobID] then
					ApplyBuffer(mobID, subEvent)
				end
				local spellCount = spellCounts[subEvent][mobID] + 1
				spellCounts[subEvent][mobID] = spellCount
				local reminders = combatLogEventReminders[subEvent][mobID]
					and combatLogEventReminders[subEvent][mobID][1]
				if reminders then
					for _, reminder in ipairs(reminders) do
						CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
					end
					combatLogEventReminders[subEvent][mobID][spellCount] = nil

					if not next(combatLogEventReminders[subEvent][mobID]) then
						spellCounts[subEvent][mobID], combatLogEventReminders[subEvent][mobID] = nil, nil
						if not next(combatLogEventReminders[subEvent]) then
							spellCounts[subEvent], combatLogEventReminders[subEvent] = nil, nil
						end
					end
				end
			end
		end
	elseif spellID then
		if spellCounts[subEvent][spellID] then
			if not activeBuffers[spellID] or (activeBuffers[spellID] and not activeBuffers[spellID][subEvent]) then
				if bufferDurations[spellID] then
					ApplyBuffer(spellID, subEvent)
				end
				local spellCount = spellCounts[subEvent][spellID] + 1
				spellCounts[subEvent][spellID] = spellCount
				local reminders = combatLogEventReminders[subEvent][spellID]
					and combatLogEventReminders[subEvent][spellID][spellCount]
				if reminders then
					for _, reminder in ipairs(reminders) do
						CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
					end
					combatLogEventReminders[subEvent][spellID][spellCount] = nil

					if not next(combatLogEventReminders[subEvent][spellID]) then
						spellCounts[subEvent][spellID], combatLogEventReminders[subEvent][spellID] = nil, nil
						if not next(combatLogEventReminders[subEvent]) then
							spellCounts[subEvent], combatLogEventReminders[subEvent] = nil, nil
						end
					end
				end
			end
		end
		if playerGUID == sourceGUID then
			if hideIfAlreadyCasted then
				if subEvent == "SPELL_CAST_START" or subEvent == "SPELL_CAST_SUCCESS" then
					CancelRemindersDueToSpellAlreadyCast(spellID)
				end
			end
			if stopGlowIfCasted[spellID] then
				for ID, obj in pairs(stopGlowIfCasted[spellID]) do
					if destGUID == obj.targetGUID then
						if frameGlowTimers[ID] and not frameGlowTimers[ID]:IsCancelled() then
							frameGlowTimers[ID]:Invoke(frameGlowTimers[ID])
						end
					end
				end
				if not next(stopGlowIfCasted[spellID]) then
					stopGlowIfCasted[spellID] = nil
				end
			end
		end
	end
end

-- BigWigs event handler function.
---@param event string Name of the event.
---@param addon string AddOn name maybe?
---@param ... any args
local function HandleBigWigsEvent(event, addon, ...)
	-- print(event, addon, ...)
end

local kMythicRaidID = 16
local kMythicDungeonID = 23
local kMythicPlusDungeonID = 8
local difficulties = { [kMythicRaidID] = true, [kMythicDungeonID] = true, [kMythicPlusDungeonID] = true }

---@param encounterID integer
---@param encounterName string
---@param difficultyID integer
---@param groupSize integer
local function HandleEncounterStart(_, encounterID, encounterName, difficultyID, groupSize)
	ResetLocalVariables()
	local reminderPreferences = AddOn.db.profile.preferences.reminder
	if reminderPreferences.enabled then
		--[===[@non-debug@
		if difficulties[difficultyID] then
        --@end-non-debug@]===]
		local boss = GetBoss(encounterID)
		if boss then
			if UnitIsGroupLeader("player") then
				Private.SendTextToGroup(encounterID)
			end

			local startTime = GetTime()
			local plans = AddOn.db.profile.plans
			local activePlans = {}
			for _, plan in pairs(plans) do
				if plan.dungeonEncounterID == encounterID and plan.remindersEnabled then
					tinsert(activePlans, plan)
				end
			end
			if #activePlans > 0 then
				hideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
				SetupReminders(activePlans, reminderPreferences, startTime, boss.abilities)
				Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
			end
		end
		--[===[@non-debug@
		end
        --@end-non-debug@]===]
	end
end

---@param encounterID integer encounterID ID for the specific encounter that ended.
---@param encounterName string Name of the encounter that ended.
---@param difficultyID integer ID representing the difficulty of the encounter.
---@param groupSize integer Group size for the encounter.
---@param success integer 1 if success, 0 for wipe.
local function HandleEncounterEnd(_, encounterID, encounterName, difficultyID, groupSize, success)
	Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ResetLocalVariables()
end

-- Registers callbacks from Encounter start/end.
function Private:RegisterReminderEvents()
	self:RegisterEvent("ENCOUNTER_START", HandleEncounterStart)
	self:RegisterEvent("ENCOUNTER_END", HandleEncounterEnd)

	-- if type(BigWigsLoader) == "table" and BigWigsLoader.RegisterMessage then
	-- 	BigWigsLoader.RegisterMessage(self, "BigWigs_SetStage", HandleBigWigsEvent)
	-- 	BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossEngage", HandleBigWigsEvent)
	-- 	BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWin", HandleBigWigsEvent)
	-- 	BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWipe", HandleBigWigsEvent)
	-- 	BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossDisable", HandleBigWigsEvent)
	-- end
end

-- Unregisters callbacks from Encounter start/end and CombatLogEventUnfiltered.
function Private:UnregisterReminderEvents()
	ResetLocalVariables()
	self:UnregisterEvent("ENCOUNTER_START")
	self:UnregisterEvent("ENCOUNTER_END")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- if type(BigWigsLoader) == "table" and BigWigsLoader.UnregisterMessage then
	-- 	BigWigsLoader.UnregisterMessage(self, "BigWigs_SetStage")
	-- 	BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossEngage")
	-- 	BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWin")
	-- 	BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWipe")
	-- 	BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossDisable")
	-- end
end

---@param timelineAssignment TimelineAssignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param elapsed number
local function CreateSimulationTimer(timelineAssignment, roster, reminderPreferences, elapsed)
	local assignment = timelineAssignment.assignment
	---@cast assignment TimedAssignment
	local oldTime = assignment.time
	assignment.time = timelineAssignment.startTime
	CreateTimer(assignment, roster, reminderPreferences, elapsed)
	assignment.time = oldTime
end

local function HandleSimulationCompleted()
	Private:StopSimulatingBoss()
	Private.callbacks:Fire("SimulationCompleted")
end

-- Sets up reminders to simulate a boss encounter using static timings.
---@param bossDungeonEncounterID integer
---@param timelineAssignments table<integer, TimelineAssignment>
---@param roster table<string, RosterEntry>
function Private:SimulateBoss(bossDungeonEncounterID, timelineAssignments, roster)
	isSimulating = true
	local reminderPreferences = AddOn.db.profile.preferences.reminder
	if reminderPreferences.enabled then
		if not messageContainer then
			CreateMessageContainer(reminderPreferences.messages)
		end
		if not progressBarContainer then
			CreateProgressBarContainer(reminderPreferences.progressBars)
		end

		local boss = GetBoss(bossDungeonEncounterID)
		if boss then
			hideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted

			local totalDuration = 0.0
			for _, phaseData in pairs(boss.phases) do
				totalDuration = totalDuration + (phaseData.duration * phaseData.count)
			end

			local filtered
			if reminderPreferences.onlyShowMe then
				filtered = FilterSelf(timelineAssignments) --[[@as table<integer, TimelineAssignment>]]
			end
			for _, timelineAssignment in ipairs(filtered or timelineAssignments) do
				CreateSimulationTimer(timelineAssignment, roster, reminderPreferences, 0.0)
			end
			simulationTimer = NewTimer(totalDuration, HandleSimulationCompleted)
			updateTimer = NewTicker(updateTimerTickRate, ProcessNextOperation, updateTimerIterations)
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
		end
	end
end

-- Clears all timers and reminder widgets.
function Private:StopSimulatingBoss()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ResetLocalVariables()
end

-- Returns true if SimulateBoss has been called without calling StopSimulatingBoss afterwards.
---@return boolean
function Private.IsSimulatingBoss()
	return isSimulating
end

--@debug@
do
	---@class Test
	local test = Private.test
	---@class TestUtilities
	local testUtilities = Private.testUtilities

	---@param testSpellCounts table<FullCombatLogEventType, table<integer, integer>>
	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param spellID integer
	---@param count integer
	local function CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, spellID, count)
		for _, eventType in pairs(combatLogEventMap) do
			CreateSpellCountEntry(eventType, spellID, 1)
			testSpellCounts[eventType] = testSpellCounts[eventType] or {}
			testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] or 0
			testCombatLogEventReminders[eventType] = testCombatLogEventReminders[eventType] or {}
			testCombatLogEventReminders[eventType][spellID] = testCombatLogEventReminders[eventType][spellID] or {}
			for i = 1, count do
				if not testCombatLogEventReminders[eventType][spellID][i] then
					testCombatLogEventReminders[eventType][spellID][i] = {}
				end
			end
		end
	end

	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param eventType FullCombatLogEventType
	---@param spellID integer
	---@param count integer
	local function AddTestSpellCount(testCombatLogEventReminders, eventType, spellID, count)
		CreateSpellCountEntry(eventType, spellID, count)
		testCombatLogEventReminders[eventType][spellID][count] = {}
	end

	---@param testSpellCounts table<FullCombatLogEventType, table<integer, integer>>
	---@param testCombatLogEventReminders table<FullCombatLogEventType, table<integer, table<integer, table>>>
	---@param eventType FullCombatLogEventType
	---@param spellID integer|nil
	---@param count integer|nil
	local function RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, spellID, count)
		if spellID then
			if count then
				testCombatLogEventReminders[eventType][spellID][count] = nil
				testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] + 1
			else
				testSpellCounts[eventType][spellID] = nil
				testCombatLogEventReminders[eventType][spellID] = nil
			end
		else
			testSpellCounts[eventType] = nil
			testCombatLogEventReminders[eventType] = nil
		end
	end

	do
		function test.CombatLogEvents()
			local oldCreateTimer = CreateTimer
			local oldCombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

			CreateTimer = function() end
			local currentEventType = "SPELL_CAST_SUCCESS"
			local currentSpellID = 123
			CombatLogGetCurrentEventInfo = function()
				return nil, currentEventType, nil, nil, nil, nil, nil, nil, nil, nil, nil, currentSpellID
			end

			local testSpellCounts, testCombatLogEventReminders = {}, {}
			CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, 123, 1)
			CreateTestSpellCounts(testSpellCounts, testCombatLogEventReminders, 321, 1)
			AddTestSpellCount(testCombatLogEventReminders, "SPELL_CAST_SUCCESS", 123, 2)
			AddTestSpellCount(testCombatLogEventReminders, "SPELL_CAST_SUCCESS", 321, 2)

			local context = "Initialized Test Tables Equal"
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentEventType = "SPELL_CAST_SUCCESS"
			currentSpellID = 123
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, 1)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentSpellID = 321
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, 1)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentSpellID = 123
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 2
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentSpellID = 321
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 2
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)
			HandleCombatLogEventUnfiltered()

			currentEventType = "SPELL_CAST_START"
			currentSpellID = 123
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentSpellID = 321
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)
			HandleCombatLogEventUnfiltered()

			currentEventType = "SPELL_AURA_APPLIED"
			currentSpellID = 123
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, currentSpellID, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentSpellID = 321
			context = "Event: " .. currentEventType .. " Spell ID: " .. currentSpellID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, currentEventType, nil, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)
			HandleCombatLogEventUnfiltered()

			CreateTimer = oldCreateTimer
			CombatLogGetCurrentEventInfo = oldCombatLogGetCurrentEventInfo
			ResetLocalVariables()
			return "CombatLogEvents"
		end

		function test.UnitDied()
			local oldCreateTimer = CreateTimer
			local oldCombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

			CreateTimer = function() end
			local eventType = "UNIT_DIED"
			local currentSpellID = 123
			local currentDestGUID = "a-b-c-d-e-111"
			CombatLogGetCurrentEventInfo = function()
				return nil, eventType, nil, nil, nil, nil, nil, currentDestGUID, nil, nil, nil, currentSpellID
			end

			local testSpellCounts, testCombatLogEventReminders = {}, {}
			CreateSpellCountEntry(eventType, 111, 1)
			CreateSpellCountEntry(eventType, 112, 1)
			for spellID = 111, 112 do
				testSpellCounts[eventType] = testSpellCounts[eventType] or {}
				testSpellCounts[eventType][spellID] = testSpellCounts[eventType][spellID] or 0
				testCombatLogEventReminders[eventType] = testCombatLogEventReminders[eventType] or {}
				testCombatLogEventReminders[eventType][spellID] = testCombatLogEventReminders[eventType][spellID] or {}
				if not testCombatLogEventReminders[eventType][spellID][1] then
					testCombatLogEventReminders[eventType][spellID][1] = {}
				end
			end

			local context = "Initialized Test Tables Equal"
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)

			currentDestGUID = "a-b-c-d-e-111"
			currentSpellID = 111
			context = "Event: " .. eventType .. " Dest GUID: " .. currentDestGUID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, currentSpellID, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)
			HandleCombatLogEventUnfiltered()

			currentDestGUID = "a-b-c-d-e-112"
			currentSpellID = 112
			context = "Event: " .. eventType .. " Dest GUID: " .. currentDestGUID .. " Count: " .. 1
			HandleCombatLogEventUnfiltered()
			RemoveTestSpellCount(testSpellCounts, testCombatLogEventReminders, eventType, nil, nil)
			testUtilities.TestEqual(spellCounts, testSpellCounts, context)
			testUtilities.TestEqual(combatLogEventReminders, testCombatLogEventReminders, context)
			HandleCombatLogEventUnfiltered()

			CreateTimer = oldCreateTimer
			CombatLogGetCurrentEventInfo = oldCombatLogGetCurrentEventInfo
			ResetLocalVariables()
			return "UnitDied"
		end
	end
end
--@end-debug@
