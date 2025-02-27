local AddOnName, Namespace = ...

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
local IsValidRegionName = utilities.IsValidRegionName
local CreateReminderText = utilities.CreateReminderText
local FindGroupMemberUnit = utilities.FindGroupMemberUnit
local FilterSelf = utilities.FilterSelf

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local LCG = LibStub("LibCustomGlow-1.0")
local LGF = LibStub("LibGetFrame-1.0")

local UIParent = UIParent
local floor = math.floor
local getmetatable = getmetatable
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
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
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local UnitGUID = UnitGUID
local UnitIsGroupLeader = UnitIsGroupLeader
local unpack = unpack
local wipe = wipe

local kReminderContainerFrameLevel = constants.frameLevels.kReminderContainerFrameLevel
local playerGUID = UnitGUID("player")

local combatLogEventMap = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
	["UD"] = "UNIT_DIED",
}
---@alias FullCombatLogEventType
---| "SPELL_AURA_APPLIED"
---| "SPELL_AURA_REMOVED"
---| "SPELL_CAST_START"
---| "SPELL_CAST_SUCCESS"
---| "UNIT_DIED"

---@class CombatLogEventAssignmentData
---@field preferences ReminderPreferences
---@field assignment CombatLogEventAssignment
---@field roster table<string, RosterEntry>

---@type FunctionContainer|nil
local simulationTimer = nil

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
local buffers = {}
---@type table<integer, table<FullCombatLogEventType, boolean>> -- Active buffers preventing successive combat log events from retriggering.
local activeBuffers = {}
---@type table<string, FunctionContainer> -- Active buffers preventing successive combat log events from retriggering.
local bufferTimers = {}

local hideIfAlreadyCasted = false
local operationQueue = {} -- Queue holding pending message or progress bar operations.
local isLocked = false -- Operation Queue lock state.
local isSimulating = false
local lastExecutionTime = 0.0
local updateFrameTickRate = 0.04
local defaultNoSpellIDGlowDuration = 5.0
local maxGlowDuration = 10.0
local updateFrame = CreateFrame("Frame")

local function ResetLocalVariables()
	updateFrame:SetScript("OnUpdate", nil)

	for _, timer in pairs(timers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(timers)
	wipe(cancelTimerIfCasted)

	if simulationTimer then
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

	wipe(operationQueue)
	wipe(hideWidgetIfCasted)
	wipe(combatLogEventReminders)
	wipe(spellCounts)

	for _, timer in pairs(bufferTimers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(bufferTimers)
	wipe(buffers)
	wipe(activeBuffers)

	if Private.messageContainer then
		Private.messageContainer:Release()
	end

	if Private.progressBarContainer then
		Private.progressBarContainer:Release()
	end

	lastExecutionTime = 0.0
	isLocked = false
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

-- Locks the Operation Queue and dequeues until empty. Updates Message container and Progress Bar Container at end.
local function ProcessNextOperation()
	if not isLocked then
		isLocked = true
		while #operationQueue > 0 do
			local nextOperation = table.remove(operationQueue, 1)
			if not nextOperation then
				break
			end
			nextOperation()
		end
		if Private.messageContainer then
			Private.messageContainer:DoLayout()
		end
		if Private.progressBarContainer then
			Private.progressBarContainer:DoLayout()
		end
	end
	isLocked = false
end

local function HandleFrameUpdate(_, elapsed)
	local currentTime = GetTime()
	if currentTime - lastExecutionTime < updateFrameTickRate then
		return
	end
	lastExecutionTime = currentTime
	ProcessNextOperation()
end

-- Creates a container for adding progress bars or messages to.
---@param preferences GenericReminderPreferences
---@param spacing number|nil
---@return EPContainer
local function CreateReminderContainer(preferences, spacing)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPProgressBarLayout")
	container.frame:SetParent(UIParent)
	container.frame:SetFrameStrata("MEDIUM")
	container.frame:SetFrameLevel(kReminderContainerFrameLevel)
	container:SetSpacing(0, spacing or 0)
	container.content.sortAscending = preferences.soonestExpirationOnBottom
	local regionName = IsValidRegionName(preferences.relativeTo) and preferences.relativeTo or "UIParent"
	local point, relativePoint = preferences.point, preferences.relativePoint
	local x, y = preferences.x, preferences.y
	container.frame:SetPoint(point, regionName, relativePoint, x, y)
	return container
end

-- Creates a container for adding progress bars to using preferences.
---@param preferences MessagePreferences
local function CreateMessageContainer(preferences)
	if not Private.messageContainer then
		Private.messageContainer = CreateReminderContainer(preferences)
		Private.messageContainer:SetCallback("OnRelease", function()
			Private.messageContainer = nil
		end)
	end
end

-- Creates a container for adding progress bars to using preferences.
---@param preferences ProgressBarPreferences
local function CreateProgressBarContainer(preferences)
	if not Private.progressBarContainer then
		Private.progressBarContainer = CreateReminderContainer(preferences, preferences.spacing)
		Private.progressBarContainer:SetCallback("OnRelease", function()
			Private.progressBarContainer = nil
		end)
	end
end

-- Creates an EPProgressBar widget using preferences.
---@param preferences ProgressBarPreferences
---@param text string
---@param duration number
---@param icon string|number|nil
---@return EPProgressBar
local function CreateProgressBar(preferences, text, duration, icon)
	local progressBar = AceGUI:Create("EPProgressBar")
	progressBar:SetProgressBarWidth(preferences.width)
	progressBar:SetHorizontalTextAlignment(preferences.textAlignment)
	progressBar:SetDurationTextAlignment(preferences.durationAlignment)
	progressBar:SetShowBorder(preferences.showBorder)
	progressBar:SetShowIconBorder(preferences.showIconBorder)
	progressBar:SetTexture(preferences.texture, preferences.color, preferences.backgroundColor)
	progressBar:SetIconPosition(preferences.iconPosition)
	progressBar:SetFill(preferences.fill)
	progressBar:SetAlpha(preferences.alpha)
	progressBar:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	progressBar:SetDuration(duration)
	progressBar:SetIconAndText(icon, text)
	return progressBar
end

-- Creates an EPReminderMessage widget using preferences.
---@param preferences MessagePreferences
---@param text string
---@param icon string|number|nil
---@return EPReminderMessage
local function CreateMessage(preferences, text, icon)
	local message = AceGUI:Create("EPReminderMessage")
	message:SetText(text, nil, preferences.font, preferences.fontSize, preferences.fontOutline)
	message:SetAlpha(preferences.alpha)
	message:SetTextColor(unpack(preferences.textColor))
	message:SetShowAnimation(preferences.showAnimation)
	if icon then
		message:SetIcon(icon)
	end
	return message
end

---@param spellInfo SpellInfo
---@return integer|nil
local function GetAssignmentIcon(spellInfo)
	local icon = nil
	local spellID = spellInfo.spellID
	if spellInfo.iconID > 0 then
		icon = spellInfo.iconID
	elseif spellID > kTextAssignmentSpellID then
		icon = GetSpellTexture(spellID)
	end
	return icon
end

---@param widget EPReminderMessage|EPProgressBar
---@param spellID integer
---@param bossPhaseOrderIndex integer|nil
---@param isProgressBar boolean
local function CreateReminderWidgetCallback(widget, spellID, bossPhaseOrderIndex, isProgressBar)
	local uniqueID = GenerateUniqueID()

	widget:SetCallback("Completed", function()
		if hideWidgetIfCasted[spellID] then
			hideWidgetIfCasted[spellID][uniqueID] = nil
		end
		if isProgressBar then
			tinsert(operationQueue, function()
				Private.progressBarContainer:RemoveChildNoDoLayout(widget)
			end)
		else
			tinsert(operationQueue, function()
				Private.messageContainer:RemoveChildNoDoLayout(widget)
			end)
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
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, duration, reminderText, progressBarPreferences)
	tinsert(operationQueue, function()
		local icon = GetAssignmentIcon(assignment.spellInfo)
		local spellID = assignment.spellInfo.spellID
		local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
		local progressBar = CreateProgressBar(progressBarPreferences, reminderText, duration, icon)
		CreateReminderWidgetCallback(progressBar, spellID, bossPhaseOrderIndex, true)
		Private.progressBarContainer:AddChildNoDoLayout(progressBar)
		progressBar:Start()
	end)
end

-- Creates an EPReminderMessage widget and schedules its cleanup based on completion. Starts the countdown if applicable.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, duration, reminderText, messagePreferences)
	tinsert(operationQueue, function()
		local icon = GetAssignmentIcon(assignment.spellInfo)
		local spellID = assignment.spellInfo.spellID
		local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
		local message = CreateMessage(messagePreferences, reminderText, icon)
		CreateReminderWidgetCallback(message, spellID, bossPhaseOrderIndex, false)
		Private.messageContainer:AddChildNoDoLayout(message)
		message:Start(duration)
	end)
end

-- Starts glowing the frame for the unit and creates a timer to stop the glowing of the frame.
---@param unit string
---@param frame Frame
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
local function GlowFrameAndCreateTimer(unit, frame, assignment)
	local spellID = assignment.spellInfo.spellID
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

-- Executes the actions that occur at the time in which reminders are first displayed. This is usually at advance notice
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
	local spellID = assignment.spellInfo.spellID

	if reminderPreferences.progressBars.enabled then
		AddProgressBar(assignment, duration, reminderText, reminderPreferences.progressBars)
	end
	if reminderPreferences.messages.enabled and not reminderPreferences.messages.showOnlyAtExpiration then
		AddMessage(assignment, duration, reminderText, reminderPreferences.messages)
	end
	if ttsPreferences.enableAtAdvanceNotice then
		if reminderText:len() > 0 then
			local textWithAdvanceNotice = format("%s %s %d", reminderText, L["in"], floor(duration))
			SpeakText(ttsPreferences.voiceID, textWithAdvanceNotice, 1, 1.0, ttsPreferences.volume)
		end
	end
	if soundPreferences.enableAtAdvanceNotice then
		if soundPreferences.advanceNoticeSound and soundPreferences.advanceNoticeSound ~= "" then
			PlaySoundFile(soundPreferences.advanceNoticeSound)
		end
	end

	---@type table<integer, fun()>
	local deferredFunctions = {}

	if reminderPreferences.messages.enabled and reminderPreferences.messages.showOnlyAtExpiration then
		deferredFunctions[#deferredFunctions + 1] = function()
			AddMessage(assignment, 0, reminderText, reminderPreferences.messages)
		end
	end
	if ttsPreferences.enableAtTime then
		if reminderText:len() > 0 then
			deferredFunctions[#deferredFunctions + 1] = function()
				SpeakText(ttsPreferences.voiceID, reminderText, 1, 1.0, ttsPreferences.volume)
			end
		end
	end
	if soundPreferences.enableAtTime and soundPreferences.atSound and soundPreferences.atSound ~= "" then
		deferredFunctions[#deferredFunctions + 1] = function()
			PlaySoundFile(soundPreferences.atSound)
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
	local duration = reminderPreferences.advanceNotice
	local startTime = assignment.time - duration - elapsed

	if startTime < 0 then
		duration = max(0.1, assignment.time - elapsed)
	end

	if startTime < 0.1 then
		ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
	else
		local args = CreateTimerWithCleanupArgs(assignment.spellInfo.spellID, assignment.bossPhaseOrderIndex)
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
	spellCounts[combatLogEventType][spellID] = spellCounts[combatLogEventType][spellID] or {}
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
	if not Private.messageContainer then
		CreateMessageContainer(preferences.messages)
	end
	if not Private.progressBarContainer then
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
				local abbreviatedCombatLogEventType = assignment--[[@as CombatLogEventAssignment]].combatLogEventType
				local fullCombatLogEventType = combatLogEventMap[abbreviatedCombatLogEventType]
				local spellID = assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				local spellCount = assignment--[[@as CombatLogEventAssignment]].spellCount
				if abilities[spellID] and abilities[spellID].buffer then
					buffers[spellID] = abilities[spellID].buffer
				end
				CreateSpellCountEntry(fullCombatLogEventType, spellID, spellCount)

				local currentSize = #combatLogEventReminders[fullCombatLogEventType][spellID][spellCount]
				combatLogEventReminders[fullCombatLogEventType][spellID][spellCount][currentSize + 1] = {
					preferences = preferences,
					assignment = assignment --[[@as CombatLogEventAssignment]],
					roster = roster,
				}
			elseif getmetatable(assignment) == TimedAssignment then
				CreateTimer(assignment--[[@as TimedAssignment]], roster, preferences, GetTime() - startTime)
			end
		end
	end

	updateFrame:SetScript("OnUpdate", HandleFrameUpdate)
end

---@param combatLogEventType FullCombatLogEventType
---@param spellID integer
local function ApplyBuffer(combatLogEventType, spellID)
	activeBuffers[spellID] = activeBuffers[spellID] or {}
	activeBuffers[spellID][combatLogEventType] = true
	CreateTimerWithCleanup(buffers[spellID], function()
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
			if widget.parent and widget.parent.RemoveChildNoDoLayout then
				widget.parent:RemoveChildNoDoLayout(widget)
			end
		end
		hideWidgetIfCasted[spellID] = nil
	end
end

-- Possibly cancels reminders or frame glows based on the spell being cast, subEvent, and destGUID.
---@param spellID integer
---@param destGUID string
---@param subEvent FullCombatLogEventType
local function MaybeCancelStuff(spellID, destGUID, subEvent)
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

-- Callback for CombatLogEventUnfiltered events. Creates timers from previously created reminders for
-- CombatLogEventAssignments.
local function HandleCombatLogEventUnfiltered()
	local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
	if spellCounts[subEvent] then
		if subEvent == "UNIT_DIED" then
			local _, _, _, _, _, id = split("-", destGUID)
			local mobID = tonumber(id)
			if mobID and spellCounts[subEvent][mobID] then
				if not activeBuffers[mobID][subEvent] then
					if buffers[mobID] then
						ApplyBuffer(subEvent, mobID)
					end
					local spellCount = spellCounts[subEvent][mobID] + 1
					spellCounts[subEvent][mobID] = spellCount
					local reminders = combatLogEventReminders[subEvent][mobID][spellCount]
					if reminders then
						for _, reminder in ipairs(reminders) do
							CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
						end
					end
				end
			end
		elseif spellID then
			if spellCounts[subEvent][spellID] then
				if not activeBuffers[spellID][subEvent] then
					if buffers[spellID] then
						ApplyBuffer(subEvent, spellID)
					end
					local spellCount = spellCounts[subEvent][spellID] + 1
					spellCounts[subEvent][spellID] = spellCount
					local reminders = combatLogEventReminders[subEvent][spellID][spellCount]
					if reminders then
						for _, reminder in ipairs(reminders) do
							CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
						end
					end
				end
			end
			if playerGUID == sourceGUID then
				MaybeCancelStuff(spellID, destGUID, subEvent)
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
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]
	if reminderPreferences.enabled then
		if difficultyID == 16 or difficultyID == 23 or difficultyID == 8 then -- Mythic raid, Mythic dung, M+
			if UnitIsGroupLeader("player") then
				Private.SendTextToGroup(encounterID)
			end
			local startTime = GetTime()
			local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
			local activePlans = {}
			for _, plan in pairs(plans) do
				if plan.dungeonEncounterID == encounterID and plan.remindersEnabled then
					tinsert(activePlans, plan)
				end
			end
			if #activePlans > 0 then
				local boss = GetBoss(encounterID)
				if boss then
					LGF:ScanForUnitFrames()
					hideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
					SetupReminders(activePlans, reminderPreferences, startTime, boss.abilities)
					Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
				end
			end
		end
	end
end

---@param encounterID integer ID for the specific encounter that ended.
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
	Private:RegisterEvent("ENCOUNTER_START", HandleEncounterStart)
	Private:RegisterEvent("ENCOUNTER_END", HandleEncounterEnd)

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
	Private:UnregisterEvent("ENCOUNTER_START")
	Private:UnregisterEvent("ENCOUNTER_END")
	Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

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
	local assignment = timelineAssignment.assignment --[[@as TimedAssignment]]
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
	LGF:ScanForUnitFrames()
	isSimulating = true
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]
	if reminderPreferences.enabled then
		if not Private.messageContainer then
			CreateMessageContainer(reminderPreferences.messages)
		end
		if not Private.progressBarContainer then
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
			updateFrame:SetScript("OnUpdate", HandleFrameUpdate)
			Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
		end
	end
end

-- Clears all timers and reminder widgets.
function Private:StopSimulatingBoss()
	Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ResetLocalVariables()
end

-- Returns true if SimulateBoss has been called without calling StopSimulatingBoss afterwards.
---@return boolean
function Private.IsSimulatingBoss()
	return isSimulating
end
