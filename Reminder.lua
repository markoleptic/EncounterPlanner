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
local DifficultyType = Private.classes.DifficultyType

---@class Constants
local constants = Private.constants

---@class BossUtilities
local bossUtilities = Private.bossUtilities
local GetBoss = bossUtilities.GetBoss
local GetBossAbilities = bossUtilities.GetBossAbilities

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

local kMythicDungeonID = 23
local kMythicPlusDungeonID = 8

local k = {
	CombatLogEventMap = {
		["SCC"] = "SPELL_CAST_SUCCESS",
		["SCS"] = "SPELL_CAST_START",
		["SAA"] = "SPELL_AURA_APPLIED",
		["SAR"] = "SPELL_AURA_REMOVED",
		["UD"] = "UNIT_DIED",
	},
	DefaultNoSpellIDGlowDuration = 5.0,
	Difficulties = {
		[DifficultyType.Heroic] = true,
		[DifficultyType.Mythic] = true,
		[kMythicDungeonID] = true,
		[kMythicPlusDungeonID] = true,
	},
	MaxGlowDuration = 10.0,
	PlayerGUID = UnitGUID("player"),
	TextAssignmentSpellID = constants.kTextAssignmentSpellID,
}

local s = {
	IconContainer = nil, ---@type EPContainer|nil
	MessageContainer = nil, ---@type EPContainer|nil
	ProgressBarContainer = nil, ---@type EPContainer|nil
	SimulationTimer = nil, ---@type FunctionContainer|nil

	---@type table<string, FunctionContainer>
	Timers = {}, -- Timers that will either call ExecuteReminderTimer or deferred functions created in ExecuteReminderTimer
	---@type table<FullCombatLogEventType, table<integer, integer>> -- FullCombatLogEventType -> SpellID -> Count \
	SpellCounts = {}, -- Acts as filter for combat log events. Increments spell occurrences for registered combat log events.
	---@type table<FullCombatLogEventType, table<integer, table<integer, table<integer, CombatLogEventAssignmentData>>>>
	CombatLogEventReminders = {}, -- Table of active reminders for responding to combat log events

	---@type table<integer, table<string, FunctionContainer>> -- Spell ID -> Timer ID -> Timer
	CancelTimerIfCasted = {},
	---@type table<integer, table<string, EPProgressBar|EPReminderMessage|EPReminderIcon>> -- Spell ID -> Timer ID -> Widget
	HideWidgetIfCasted = {},
	---@type table<integer, table<string, {frame: Frame, targetGUID: integer|nil}>> -- Spell ID -> [{Frame, Target GUID}]
	StopGlowIfCasted = {},

	---@type table<integer, Frame> -- [Frame]
	NoSpellIDGlowFrames = {},
	---@type table<string, FunctionContainer> -- All s.timers used to glow frames [s.timers]
	FrameGlowTimers = {},

	---@type table<integer, number> -- Buffers to use to prevent successive combat log events from retriggering.
	BufferDurations = {},
	---@type table<integer, table<FullCombatLogEventType, boolean>> -- Active buffers preventing successive combat log events from retriggering.
	ActiveBuffers = {},
	---@type table<string, FunctionContainer> -- Active buffers preventing successive combat log events from retriggering.
	BufferTimers = {},

	HideIfAlreadyCasted = false,
	IsSimulating = false,
}

local function ResetLocalVariables()
	for _, timer in pairs(s.Timers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(s.Timers)
	wipe(s.CancelTimerIfCasted)

	if s.SimulationTimer and not s.SimulationTimer:IsCancelled() then
		s.SimulationTimer:Cancel()
	end
	s.SimulationTimer = nil

	for _, timer in pairs(s.FrameGlowTimers) do
		if not timer:IsCancelled() then
			timer:Invoke(timer)
			timer:Cancel()
		end
	end
	wipe(s.FrameGlowTimers)

	for _, targetFrames in pairs(s.StopGlowIfCasted) do
		for _, targetFrame in pairs(targetFrames) do
			if targetFrame.frame then
				LCG.PixelGlow_Stop(targetFrame.frame)
			end
		end
	end
	wipe(s.StopGlowIfCasted)

	for _, frame in ipairs(s.NoSpellIDGlowFrames) do
		if frame then
			LCG.PixelGlow_Stop(frame)
		end
	end
	wipe(s.NoSpellIDGlowFrames)

	wipe(s.HideWidgetIfCasted)
	wipe(s.CombatLogEventReminders)
	wipe(s.SpellCounts)

	for _, timer in pairs(s.BufferTimers) do
		if not timer:IsCancelled() then
			timer:Cancel()
		end
	end
	wipe(s.BufferTimers)
	wipe(s.BufferDurations)
	wipe(s.ActiveBuffers)

	if s.MessageContainer then
		AceGUI:Release(s.MessageContainer)
	end
	if s.ProgressBarContainer then
		AceGUI:Release(s.ProgressBarContainer)
	end
	if s.IconContainer then
		AceGUI:Release(s.IconContainer)
	end

	s.IsSimulating = false
	s.HideIfAlreadyCasted = false
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
	if s.HideIfAlreadyCasted and spellID > k.TextAssignmentSpellID then
		s.CancelTimerIfCasted[spellID] = s.CancelTimerIfCasted[spellID] or {}
		args[#args + 1] = s.CancelTimerIfCasted[spellID]
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

	local uniqueID = GenerateUniqueID()
	timer.ID = uniqueID
	for i = 1, args.n do
		local tableRef = args[i]
		if tableRef then
			tableRef[uniqueID] = timer
		end
	end
	return timer
end

-- Creates a container for adding messages to using preferences.
---@param preferences MessagePreferences
local function CreateMessageContainer(preferences)
	if not s.MessageContainer then
		s.MessageContainer = CreateReminderContainer(preferences)
		s.MessageContainer:SetCallback("OnRelease", function()
			s.MessageContainer = nil
		end)
	end
end

-- Creates a container for adding progress bars to using preferences.
---@param preferences ProgressBarPreferences
local function CreateProgressBarContainer(preferences)
	if not s.ProgressBarContainer then
		s.ProgressBarContainer = CreateReminderContainer(preferences, preferences.spacing)
		s.ProgressBarContainer:SetCallback("OnRelease", function()
			s.ProgressBarContainer = nil
		end)
	end
end

-- Creates a container for adding icons to using preferences.
---@param preferences IconPreferences
local function CreateIconContainer(preferences)
	if not s.IconContainer then
		s.IconContainer = CreateReminderContainer(preferences, preferences.spacing)
		s.IconContainer:SetCallback("OnRelease", function()
			s.IconContainer = nil
		end)
	end
end

---@param widget EPReminderMessage|EPProgressBar|EPReminderIcon
---@param spellID integer
---@param bossPhaseOrderIndex integer|nil
local function CreateReminderWidgetCallback(widget, spellID, bossPhaseOrderIndex)
	local uniqueID = GenerateUniqueID()

	widget:SetCallback("Completed", function(w)
		if s.HideWidgetIfCasted[spellID] then
			s.HideWidgetIfCasted[spellID][uniqueID] = nil
		end
		if w.type == "EPReminderIcon" then
			s.IconContainer:RemoveChild(widget)
		elseif w.type == "EPProgressBar" then
			s.ProgressBarContainer:RemoveChild(widget)
		elseif w.type == "EPReminderMessage" then
			s.MessageContainer:RemoveChild(widget)
		end
	end)

	if s.HideIfAlreadyCasted and spellID > k.TextAssignmentSpellID then
		s.HideWidgetIfCasted[spellID] = s.HideWidgetIfCasted[spellID] or {}
		s.HideWidgetIfCasted[spellID][uniqueID] = widget
	end
end

-- Creates an EPProgressBar widget and schedules its cleanup on the Completed callback. Starts the countdown.
---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param icon integer|nil
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, duration, reminderText, icon, progressBarPreferences)
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	local progressBar = AceGUI:Create("EPProgressBar")
	progressBar:Set(progressBarPreferences, reminderText, duration, icon)
	CreateReminderWidgetCallback(progressBar, assignment.spellID, bossPhaseOrderIndex)
	s.ProgressBarContainer:AddChild(progressBar)
	progressBar:Start()
end

-- Creates an EPReminderMessage widget and schedules its cleanup based on completion. Starts the countdown if applicable.
---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param icon integer|nil
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, duration, reminderText, icon, messagePreferences)
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	local message = AceGUI:Create("EPReminderMessage")
	message:Set(messagePreferences, reminderText, icon)
	CreateReminderWidgetCallback(message, assignment.spellID, bossPhaseOrderIndex)
	s.MessageContainer:AddChild(message)
	message:Start(duration)
end

-- Creates an EPReminderIcon widget and schedules its cleanup based on completion. Starts the countdown.
---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param icon integer
---@param iconPreferences IconPreferences
local function AddIcon(assignment, duration, reminderText, icon, iconPreferences)
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	local reminderIcon = AceGUI:Create("EPReminderIcon")
	reminderIcon:Set(iconPreferences, reminderText, icon)
	CreateReminderWidgetCallback(reminderIcon, assignment.spellID, bossPhaseOrderIndex)
	s.IconContainer:AddChild(reminderIcon)
	reminderIcon:Start(GetTime(), duration)
end

-- Starts glowing the frame for the unit and creates a timer to stop the glowing of the frame.
---@param unit string
---@param frame Frame
---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
local function GlowFrameAndCreateTimer(unit, frame, assignment)
	local spellID = assignment.spellID
	if spellID > k.TextAssignmentSpellID then
		local targetFrameObject = { frame = frame, targetGUID = UnitGUID(unit) }
		s.StopGlowIfCasted[spellID] = s.StopGlowIfCasted[spellID] or {}
		local timer = CreateTimerWithCleanup(k.MaxGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			if s.StopGlowIfCasted[spellID] then
				s.StopGlowIfCasted[spellID][timerObject.ID] = nil
			end
		end, s.FrameGlowTimers)
		s.StopGlowIfCasted[spellID][timer.ID] = targetFrameObject
	else
		local timer = CreateTimerWithCleanup(k.DefaultNoSpellIDGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			s.NoSpellIDGlowFrames[timerObject.ID] = nil
		end, s.FrameGlowTimers)
		s.NoSpellIDGlowFrames[timer.ID] = frame
	end
	LCG.PixelGlow_Start(frame)
end

-- Executes the actions that occur at the time in which reminders are first displayed. This is usually at countdown start
-- time before the assignment, but can also be sooner if towards the start of the encounter. Creates s.timers for actions
-- that occur at assignment time.
---@param assignment CombatLogEventAssignment|TimedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param duration number
local function ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
	local reminderText = CreateReminderText(assignment, roster, false)
	local ttsPreferences = reminderPreferences.textToSpeech
	local soundPreferences = reminderPreferences.sound
	local spellID = assignment.spellID
	local icon = spellID > constants.kTextAssignmentSpellID and GetSpellTexture(spellID) or nil

	if reminderPreferences.icons.enabled and icon then
		AddIcon(assignment, duration, reminderText, icon, reminderPreferences.icons)
	end
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
		end, s.Timers, unpack(args))
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
		end, s.Timers, unpack(args))
	end
end

-- Creates an empty table entry so that a CombatLogEventAssignment can be inserted into it.
---@param combatLogEventType FullCombatLogEventType
---@param spellID integer
---@param spellCount integer
local function CreateSpellCountEntry(combatLogEventType, spellID, spellCount)
	s.SpellCounts[combatLogEventType] = s.SpellCounts[combatLogEventType] or {}
	s.SpellCounts[combatLogEventType][spellID] = s.SpellCounts[combatLogEventType][spellID] or 0
	s.CombatLogEventReminders[combatLogEventType] = s.CombatLogEventReminders[combatLogEventType] or {}
	s.CombatLogEventReminders[combatLogEventType][spellID] = s.CombatLogEventReminders[combatLogEventType][spellID]
		or {}
	for i = 1, spellCount do
		if not s.CombatLogEventReminders[combatLogEventType][spellID][i] then
			s.CombatLogEventReminders[combatLogEventType][spellID][i] = {}
		end
	end
end

-- Populates the s.combatLogEventReminders table with CombatLogEventAssignments, creates s.timers for timed assignments, and
-- sets the script that updates the operation queue.
---@param plans table<string, Plan>
---@param preferences ReminderPreferences
---@param startTime number
---@param abilities table<integer, BossAbility>
local function SetupReminders(plans, preferences, startTime, abilities)
	if not s.MessageContainer and preferences.messages.enabled then
		CreateMessageContainer(preferences.messages)
	end
	if not s.ProgressBarContainer and preferences.progressBars.enabled then
		CreateProgressBarContainer(preferences.progressBars)
	end
	if not s.IconContainer and preferences.icons.enabled then
		CreateIconContainer(preferences.icons)
	end

	local atLeastOneAssignmentActive = false

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
				local fullCombatLogEventType = k.CombatLogEventMap[abbreviatedCombatLogEventType]
				local spellID = assignment.combatLogEventSpellID
				local spellCount = assignment.spellCount
				if abilities[spellID] and abilities[spellID].buffer then
					s.BufferDurations[spellID] = abilities[spellID].buffer
				end
				CreateSpellCountEntry(fullCombatLogEventType, spellID, spellCount)

				local currentSize = #s.CombatLogEventReminders[fullCombatLogEventType][spellID][spellCount]
				s.CombatLogEventReminders[fullCombatLogEventType][spellID][spellCount][currentSize + 1] = {
					preferences = preferences,
					assignment = assignment,
					roster = roster,
				}
			elseif getmetatable(assignment) == TimedAssignment then
				---@cast assignment TimedAssignment
				CreateTimer(assignment, roster, preferences, GetTime() - startTime)
			end
			atLeastOneAssignmentActive = true
		end
	end

	return atLeastOneAssignmentActive
end

---@param spellID integer
---@param combatLogEventType FullCombatLogEventType
local function ApplyBuffer(spellID, combatLogEventType)
	s.ActiveBuffers[spellID] = s.ActiveBuffers[spellID] or {}
	s.ActiveBuffers[spellID][combatLogEventType] = true
	CreateTimerWithCleanup(s.BufferDurations[spellID], function()
		s.ActiveBuffers[spellID][combatLogEventType] = nil
		if not next(s.ActiveBuffers[spellID]) then
			s.ActiveBuffers[spellID] = nil
		end
	end, s.BufferTimers)
end

-- Cancels active timers and queues widgets associated with a spellID for release.
---@param spellID integer
local function CancelRemindersDueToSpellAlreadyCast(spellID)
	if type(s.CancelTimerIfCasted[spellID]) == "table" then
		for _, timer in pairs(s.CancelTimerIfCasted[spellID]) do
			timer:Cancel()
			timer.RemoveTimerRef(timer)
		end
		s.CancelTimerIfCasted[spellID] = nil
	end
	if type(s.HideWidgetIfCasted[spellID]) == "table" then
		for _, widget in pairs(s.HideWidgetIfCasted[spellID]) do
			if widget.type == "EPReminderIcon" then
				s.IconContainer:RemoveChild(widget)
			elseif widget.type == "EPProgressBar" then
				s.ProgressBarContainer:RemoveChild(widget)
			elseif widget.type == "EPReminderMessage" then
				s.MessageContainer:RemoveChild(widget)
			end
		end
		s.HideWidgetIfCasted[spellID] = nil
	end
end

-- Callback for CombatLogEventUnfiltered events. Creates timers from previously created reminders for
-- CombatLogEventAssignments.
local function HandleCombatLogEventUnfiltered()
	local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
	if not s.SpellCounts[subEvent] then
		return
	end

	if subEvent == "UNIT_DIED" and destGUID then
		local _, _, _, _, _, id = split("-", destGUID)
		local mobID = tonumber(id)
		if mobID and s.SpellCounts[subEvent][mobID] then
			if not s.ActiveBuffers[mobID] or (s.ActiveBuffers[mobID] and not s.ActiveBuffers[mobID][subEvent]) then
				if s.BufferDurations[mobID] then
					ApplyBuffer(mobID, subEvent)
				end
				local spellCount = s.SpellCounts[subEvent][mobID] + 1
				s.SpellCounts[subEvent][mobID] = spellCount
				local reminders = s.CombatLogEventReminders[subEvent][mobID]
					and s.CombatLogEventReminders[subEvent][mobID][1]
				if reminders then
					for _, reminder in ipairs(reminders) do
						CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
					end
					s.CombatLogEventReminders[subEvent][mobID][spellCount] = nil

					if not next(s.CombatLogEventReminders[subEvent][mobID]) then
						s.SpellCounts[subEvent][mobID], s.CombatLogEventReminders[subEvent][mobID] = nil, nil
						if not next(s.CombatLogEventReminders[subEvent]) then
							s.SpellCounts[subEvent], s.CombatLogEventReminders[subEvent] = nil, nil
						end
					end
				end
			end
		end
	elseif spellID then
		if s.SpellCounts[subEvent][spellID] then
			if
				not s.ActiveBuffers[spellID] or (s.ActiveBuffers[spellID] and not s.ActiveBuffers[spellID][subEvent])
			then
				if s.BufferDurations[spellID] then
					ApplyBuffer(spellID, subEvent)
				end
				local spellCount = s.SpellCounts[subEvent][spellID] + 1
				s.SpellCounts[subEvent][spellID] = spellCount
				local reminders = s.CombatLogEventReminders[subEvent][spellID]
					and s.CombatLogEventReminders[subEvent][spellID][spellCount]
				if reminders then
					for _, reminder in ipairs(reminders) do
						CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
					end
					s.CombatLogEventReminders[subEvent][spellID][spellCount] = nil

					if not next(s.CombatLogEventReminders[subEvent][spellID]) then
						s.SpellCounts[subEvent][spellID], s.CombatLogEventReminders[subEvent][spellID] = nil, nil
						if not next(s.CombatLogEventReminders[subEvent]) then
							s.SpellCounts[subEvent], s.CombatLogEventReminders[subEvent] = nil, nil
						end
					end
				end
			end
		end
		if k.PlayerGUID == sourceGUID then
			if s.HideIfAlreadyCasted then
				if subEvent == "SPELL_CAST_START" or subEvent == "SPELL_CAST_SUCCESS" then
					CancelRemindersDueToSpellAlreadyCast(spellID)
				end
			end
			if s.StopGlowIfCasted[spellID] then
				for glowSpellID, obj in pairs(s.StopGlowIfCasted[spellID]) do
					if destGUID == obj.targetGUID then
						if s.FrameGlowTimers[glowSpellID] and not s.FrameGlowTimers[glowSpellID]:IsCancelled() then
							s.FrameGlowTimers[glowSpellID]:Invoke(s.FrameGlowTimers[glowSpellID])
						end
					end
				end
				if not next(s.StopGlowIfCasted[spellID]) then
					s.StopGlowIfCasted[spellID] = nil
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

---@param encounterID integer
---@param encounterName string
---@param difficultyID integer
---@param groupSize integer
local function HandleEncounterStart(_, encounterID, encounterName, difficultyID, groupSize)
	ResetLocalVariables()
	local reminderPreferences = AddOn.db.profile.preferences.reminder
	if reminderPreferences.enabled then
		--[===[@non-debug@
		if k.Difficulties[difficultyID] then
        --@end-non-debug@]===]
		local boss = GetBoss(encounterID)
		if boss then
			local difficultyType
			if difficultyID == DifficultyType.Heroic then
				difficultyType = DifficultyType.Heroic
			else
				difficultyType = DifficultyType.Mythic
			end
			if UnitIsGroupLeader("player") then
				Private.SendTextToGroup(encounterID, difficultyType)
			end

			local startTime = GetTime()
			local plans = AddOn.db.profile.plans
			local activePlans = {}
			for _, plan in pairs(plans) do
				if plan.dungeonEncounterID == encounterID and plan.difficulty == difficultyType then
					if plan.remindersEnabled == true then
						tinsert(activePlans, plan)
					end
				end
			end
			if #activePlans > 0 then
				s.HideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
				if
					SetupReminders(activePlans, reminderPreferences, startTime, GetBossAbilities(boss, difficultyType))
				then
					Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
				else
					ResetLocalVariables()
				end
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
---@param difficulty DifficultyType
function Private:SimulateBoss(bossDungeonEncounterID, timelineAssignments, roster, difficulty)
	s.IsSimulating = true
	local preferences = AddOn.db.profile.preferences.reminder
	if preferences.enabled then
		if not s.MessageContainer and preferences.messages.enabled then
			CreateMessageContainer(preferences.messages)
		end
		if not s.ProgressBarContainer and preferences.progressBars.enabled then
			CreateProgressBarContainer(preferences.progressBars)
		end
		if not s.IconContainer and preferences.icons.enabled then
			CreateIconContainer(preferences.icons)
		end

		local boss = GetBoss(bossDungeonEncounterID)
		if boss then
			s.HideIfAlreadyCasted = preferences.cancelIfAlreadyCasted

			local totalDuration = 0.0
			for _, phaseData in pairs(bossUtilities.GetBossPhases(boss, difficulty)) do
				totalDuration = totalDuration + (phaseData.duration * phaseData.count)
			end

			local filtered
			if preferences.onlyShowMe then
				filtered = FilterSelf(timelineAssignments) --[[@as table<integer, TimelineAssignment>]]
			end
			for _, timelineAssignment in ipairs(filtered or timelineAssignments) do
				CreateSimulationTimer(timelineAssignment, roster, preferences, 0.0)
			end
			s.SimulationTimer = NewTimer(totalDuration, HandleSimulationCompleted)
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
		end
	end
end

-- Clears all s.timers and reminder widgets.
function Private:StopSimulatingBoss()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ResetLocalVariables()
end

-- Returns true if SimulateBoss has been called without calling StopSimulatingBoss afterwards.
---@return boolean
function Private.IsSimulatingBoss()
	return s.IsSimulating
end

--@debug@
Private.CreateSpellCountEntry = CreateSpellCountEntry
Private.HandleCombatLogEventUnfiltered = HandleCombatLogEventUnfiltered
Private.CombatLogEventMap = k.CombatLogEventMap
Private.ResetLocalVariables = ResetLocalVariables
Private.SpellCounts = s.SpellCounts
Private.CombatLogEventReminders = s.CombatLogEventReminders
Private.CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
Private.SetCombatLogGetCurrentEventInfo = function(func)
	CombatLogGetCurrentEventInfo = func
end
Private.CreateTimer = CreateTimer
Private.SetCreateTimer = function(func)
	CreateTimer = func
end
--@end-debug@
