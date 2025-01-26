local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local L = Private.L
local GenerateUniqueID = Private.GenerateUniqueID
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
local tinsert = tinsert
local tremove = tremove
local type = type
local UnitGUID = UnitGUID
local unpack = unpack
local wipe = wipe

local kReminderContainerFrameLevel = constants.frameLevels.kReminderContainerFrameLevel
local playerGUID = UnitGUID("player")

local combatLogEventMap = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}
---@alias FullCombatLogEventType
---| "SPELL_AURA_APPLIED"
---| "SPELL_AURA_REMOVED"
---| "SPELL_CAST_START"
---| "SPELL_CAST_SUCCESS"

---@class CombatLogEventAssignmentData
---@field preferences ReminderPreferences
---@field assignment CombatLogEventAssignment
---@field roster table<string, RosterEntry>

---@type FunctionContainer|nil
local simulationTimer = nil

---@type table<string,FunctionContainer>
local timers = {} -- Timers that will either call ExecuteReminderTimer or deferred functions created in ExecuteReminderTimer

---@type table<integer, integer> -- [boss phase order index -> boss phase index]
local orderedBossPhaseTable = {}
---@type table<FullCombatLogEventType, table<integer, integer>> -- FullCombatLogEventType -> SpellID -> Count \
local spellCounts = {} -- Acts as filter for combat log events. Increments spell occurrences for registered combat log events.
---@type table<FullCombatLogEventType, table<integer, table<integer, table<integer, CombatLogEventAssignmentData>>>>
local combatLogEventReminders = {} -- Table of active reminders for responding to combat log events

---@type table<integer, table<integer, FunctionContainer>> -- Spell ID -> [timers]
local cancelTimerIfCasted = {}
---@type table<integer, table<integer, EPProgressBar|EPReminderMessage>> -- Spell ID -> [widgets]
local hideWidgetIfCasted = {}

---@type table<integer, table<integer, FunctionContainer>> -- Ordered boss phases index -> [timers for combat log events]
local cancelTimerIfPhased = {}
---@type table<integer, table<integer, EPProgressBar|EPReminderMessage>> -- Ordered boss phases index -> [widgets]
local hideWidgetIfPhased = {}

---@type table<integer, table<string, {frame: Frame, targetGUID: integer|nil}>> -- Spell ID -> [{Frame, Target GUID}]
local stopGlowIfCasted = {}
---@type table<integer, table<integer, FunctionContainer>> -- Ordered boss phases index -> [timers]
local stopGlowIfPhased = {}
---@type table<integer, Frame> -- [Frame]
local noSpellIDGlowFrames = {}
---@type table<string, FunctionContainer> -- All timers used to glow frames [timers]
local frameGlowTimers = {}

local currentEstimatedPhaseNumber = 1
local currentEstimatedOrderedBossPhaseIndex = 1
local phaseStartSpells, phaseEndSpells, phaseLimitedSpells = {}, {}, {}
local hideIfAlreadyCasted = false
local hideIfAlreadyPhased = false

local operationQueue = {} -- Queue holding pending message or progress bar operations.
local isLocked = false -- Operation Queue lock state.
local isSimulating = false
local lastExecutionTime = 0
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
	wipe(cancelTimerIfPhased)

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
	wipe(stopGlowIfPhased)

	for _, targetFrames in pairs(stopGlowIfCasted) do
		for _, targetFrame in ipairs(targetFrames) do
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
	wipe(hideWidgetIfPhased)
	wipe(orderedBossPhaseTable)
	wipe(phaseStartSpells)
	wipe(phaseEndSpells)
	wipe(phaseLimitedSpells)
	wipe(combatLogEventReminders)
	wipe(spellCounts)

	if Private.messageContainer then
		Private.messageContainer:Release()
	end

	if Private.progressBarContainer then
		Private.progressBarContainer:Release()
	end

	lastExecutionTime = 0
	isLocked = false
	isSimulating = false
	hideIfAlreadyCasted = false
	currentEstimatedPhaseNumber = 1
	currentEstimatedOrderedBossPhaseIndex = 1
end

---@param ... unknown
---@return table
local function pack(...)
	return { n = select("#", ...), ... }
end

---@param duration number
---@param func fun(timerObject: FunctionContainer)
---@param ... table<string, FunctionContainer>
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
			eventMap[event] = eventMap[event] or {}
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
	local regionName = utilities.IsValidRegionName(preferences.relativeTo) and preferences.relativeTo or "UIParent"
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
	progressBar:SetTexture(preferences.texture)
	progressBar:SetIconPosition(preferences.iconPosition)
	progressBar:SetColor(unpack(preferences.color))
	progressBar:SetBackgroundColor(unpack(preferences.backgroundColor))
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
---@param duration number|nil
---@param icon string|number|nil
---@return EPReminderMessage
local function CreateMessage(preferences, text, duration, icon)
	local message = AceGUI:Create("EPReminderMessage")
	message:SetText(text, nil, preferences.font, preferences.fontSize, preferences.fontOutline)
	message:SetAlpha(preferences.alpha)
	message:SetTextColor(unpack(preferences.textColor))
	if duration then
		message:SetDuration(duration)
	end
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
	elseif spellID > constants.kTextAssignmentSpellID then
		icon = GetSpellTexture(spellID)
	end
	return icon
end

-- Creates an EPProgressBar widget and schedules its cleanup on the Completed callback. Starts the countdown.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param duration number
---@param reminderText string
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, duration, reminderText, progressBarPreferences)
	tinsert(operationQueue, function()
		local icon = GetAssignmentIcon(assignment.spellInfo)
		local progressBar = CreateProgressBar(progressBarPreferences, reminderText, duration, icon)
		progressBar:SetCallback("Completed", function()
			tinsert(operationQueue, function()
				hideWidgetIfCasted[assignment.spellInfo.spellID] = nil
				Private.progressBarContainer:RemoveChildNoDoLayout(progressBar)
			end)
		end)
		Private.progressBarContainer:AddChildNoDoLayout(progressBar)
		progressBar:Start()
		if assignment.spellInfo.spellID > constants.kTextAssignmentSpellID then
			if not hideWidgetIfCasted[assignment.spellInfo.spellID] then
				hideWidgetIfCasted[assignment.spellInfo.spellID] = {}
			end
			tinsert(hideWidgetIfCasted[assignment.spellInfo.spellID], progressBar)
		end
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			if not hideWidgetIfPhased[assignment.bossPhaseOrderIndex] then
				hideWidgetIfPhased[assignment.bossPhaseOrderIndex] = {}
			end
			local hideWidgetTable = hideWidgetIfPhased[assignment.bossPhaseOrderIndex]
			hideWidgetTable[#hideWidgetTable + 1] = progressBar
		end
	end)
end

-- Creates an EPReminderMessage widget and schedules its cleanup based on completion. Starts the countdown if applicable.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param duration number|nil
---@param reminderText string
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, duration, reminderText, messagePreferences)
	tinsert(operationQueue, function()
		local icon = GetAssignmentIcon(assignment.spellInfo)
		local message = CreateMessage(messagePreferences, reminderText, duration, icon)
		local spellID = assignment.spellInfo.spellID
		message:SetCallback("Completed", function()
			tinsert(operationQueue, function()
				hideWidgetIfCasted[spellID] = nil
				Private.messageContainer:RemoveChildNoDoLayout(message)
			end)
		end)
		Private.messageContainer:AddChildNoDoLayout(message)
		if duration then
			message:Start(true)
		else
			message:Start(false)
		end
		if spellID > constants.kTextAssignmentSpellID then
			if not hideWidgetIfCasted[spellID] then
				hideWidgetIfCasted[spellID] = {}
			end
			tinsert(hideWidgetIfCasted[spellID], message)
		end
		if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
			if not hideWidgetIfPhased[assignment.bossPhaseOrderIndex] then
				hideWidgetIfPhased[assignment.bossPhaseOrderIndex] = {}
			end
			local hideWidgetTable = hideWidgetIfPhased[assignment.bossPhaseOrderIndex]
			hideWidgetTable[#hideWidgetTable + 1] = message
		end
	end)
end

-- Starts glowing the frame for the unit and creates a timer to stop the glowing of the frame.
---@param unit string
---@param frame Frame
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
local function GlowFrameAndCreateTimer(unit, frame, assignment)
	local spellID = assignment.spellInfo.spellID
	local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
	if hideIfAlreadyPhased and bossPhaseOrderIndex then
		stopGlowIfPhased[bossPhaseOrderIndex] = stopGlowIfPhased[bossPhaseOrderIndex] or {}
	end
	local timer
	if spellID > constants.kTextAssignmentSpellID then
		local targetFrameObject = { frame = frame, targetGUID = UnitGUID(unit) }
		stopGlowIfCasted[spellID] = stopGlowIfCasted[spellID] or {}
		timer = CreateTimerWithCleanup(maxGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			if stopGlowIfCasted[spellID] then
				stopGlowIfCasted[spellID][timerObject.ID] = nil
			end
		end, frameGlowTimers, stopGlowIfPhased[bossPhaseOrderIndex])
		stopGlowIfCasted[spellID][timer.ID] = targetFrameObject
	else
		timer = CreateTimerWithCleanup(defaultNoSpellIDGlowDuration, function(timerObject)
			LCG.PixelGlow_Stop(frame)
			noSpellIDGlowFrames[timerObject.ID] = nil
		end, frameGlowTimers, stopGlowIfPhased[bossPhaseOrderIndex])
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
	local reminderText = utilities.CreateReminderText(assignment, roster, false)
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
			AddMessage(assignment, nil, reminderText, reminderPreferences.messages)
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
			local unit = utilities.FindGroupMemberUnit(assignment.targetName)
			if unit then
				local frame = LGF.GetUnitFrame(unit)
				if frame then
					GlowFrameAndCreateTimer(unit, frame, assignment)
				end
			end
		end
	end

	if #deferredFunctions > 0 then
		local timer = CreateTimerWithCleanup(duration, function()
			for _, func in ipairs(deferredFunctions) do
				func()
			end
			cancelTimerIfCasted[spellID] = nil
		end, timers)

		if hideIfAlreadyCasted and spellID > constants.kTextAssignmentSpellID then
			if not cancelTimerIfCasted[spellID] then
				cancelTimerIfCasted[spellID] = {}
			end
			tinsert(cancelTimerIfCasted[spellID], timer)
		end

		if hideIfAlreadyPhased then
			local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
			if bossPhaseOrderIndex then
				if not cancelTimerIfPhased[bossPhaseOrderIndex] then
					cancelTimerIfPhased[bossPhaseOrderIndex] = {}
				end
				tinsert(cancelTimerIfPhased[bossPhaseOrderIndex], timer)
			end
		end
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
		local spellID = assignment.spellInfo.spellID
		local timer = CreateTimerWithCleanup(startTime, function()
			cancelTimerIfCasted[spellID] = nil
			ExecuteReminderTimer(assignment, reminderPreferences, roster, duration)
		end, timers)

		if hideIfAlreadyCasted and spellID > constants.kTextAssignmentSpellID then
			if not cancelTimerIfCasted[spellID] then
				cancelTimerIfCasted[spellID] = {}
			end
			tinsert(cancelTimerIfCasted[spellID], timer)
		end

		if hideIfAlreadyPhased then
			local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex
			if bossPhaseOrderIndex then
				if not cancelTimerIfPhased[bossPhaseOrderIndex] then
					cancelTimerIfPhased[bossPhaseOrderIndex] = {}
				end
				tinsert(cancelTimerIfPhased[bossPhaseOrderIndex], timer)
			end
		end
	end
end

-- Creates an empty table entry so that a CombatLogEventAssignment can be inserted into it.
---@param combatLogEventType "SPELL_AURA_APPLIED"|"SPELL_AURA_REMOVED"|"SPELL_CAST_START"|"SPELL_CAST_SUCCESS"
---@param spellID integer
---@param spellCount integer
local function CreateSpellCountEntry(combatLogEventType, spellID, spellCount)
	if not spellCounts[combatLogEventType] then
		spellCounts[combatLogEventType] = {}
	end
	if not spellCounts[combatLogEventType][spellID] then
		spellCounts[combatLogEventType][spellID] = 0
	end
	if not combatLogEventReminders[combatLogEventType] then
		combatLogEventReminders[combatLogEventType] = {}
	end
	if not combatLogEventReminders[combatLogEventType][spellID] then
		combatLogEventReminders[combatLogEventType][spellID] = {}
	end
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
local function SetupReminders(plans, preferences, startTime)
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
			filteredAssignments = utilities.FilterSelf(assignments) --[[@as table<integer, Assignment>]]
		end
		for _, assignment in ipairs(filteredAssignments or assignments) do
			if getmetatable(assignment) == Private.classes.CombatLogEventAssignment then
				local abbreviatedCombatLogEventType = assignment--[[@as CombatLogEventAssignment]].combatLogEventType
				local fullCombatLogEventType = combatLogEventMap[abbreviatedCombatLogEventType]
				local spellID = assignment--[[@as CombatLogEventAssignment]].combatLogEventSpellID
				local spellCount = assignment--[[@as CombatLogEventAssignment]].spellCount
				CreateSpellCountEntry(fullCombatLogEventType, spellID, spellCount)

				local currentSize = #combatLogEventReminders[fullCombatLogEventType][spellID][spellCount]
				combatLogEventReminders[fullCombatLogEventType][spellID][spellCount][currentSize + 1] = {
					preferences = preferences,
					assignment = assignment --[[@as CombatLogEventAssignment]],
					roster = roster,
				}
			elseif getmetatable(assignment) == Private.classes.TimedAssignment then
				CreateTimer(assignment--[[@as TimedAssignment]], roster, preferences, GetTime() - startTime)
			end
		end
	end

	updateFrame:SetScript("OnUpdate", HandleFrameUpdate)
	-- print("Timers active:", #timers, "combatLogEventReminders", #combatLogEventReminders)
end

-- Cancels active timers and releases active widgets associated with an ordered boss phase index.
---@param orderedBossPhaseIndex integer
local function CancelRemindersDueToPhaseUpdate(orderedBossPhaseIndex)
	if cancelTimerIfPhased[orderedBossPhaseIndex] then
		for _, timer in pairs(cancelTimerIfPhased[orderedBossPhaseIndex]) do
			timer:Cancel()
		end
		print(format("Removed %d timers from %d", #cancelTimerIfPhased[orderedBossPhaseIndex], orderedBossPhaseIndex))
		cancelTimerIfPhased[orderedBossPhaseIndex] = nil
	end
	if hideWidgetIfPhased[orderedBossPhaseIndex] then
		for _, widget in pairs(hideWidgetIfPhased[orderedBossPhaseIndex]) do
			if widget and widget.parent then
				widget.parent:RemoveChildNoDoLayout(widget)
			end
		end
		if Private.messageContainer then
			Private.messageContainer:DoLayout()
		end
		if Private.progressBarContainer then
			Private.progressBarContainer:DoLayout()
		end
		print(format("Removed %d widgets from %d", #hideWidgetIfPhased[orderedBossPhaseIndex], orderedBossPhaseIndex))
		hideWidgetIfPhased[orderedBossPhaseIndex] = nil
	end
	if stopGlowIfPhased[orderedBossPhaseIndex] then
		for _, timer in pairs(stopGlowIfPhased[orderedBossPhaseIndex]) do
			timer:Cancel()
			timer.RemoveTimerRef(timer)
		end
		stopGlowIfPhased[orderedBossPhaseIndex] = nil
	end
end

-- Increments the current estimated phase number by using the next entry in the ordered boss phase table.
local function UpdatePhase()
	local previousPhaseNumber = currentEstimatedPhaseNumber

	if not orderedBossPhaseTable[currentEstimatedOrderedBossPhaseIndex + 1] then
		return
	end

	CancelRemindersDueToPhaseUpdate(currentEstimatedOrderedBossPhaseIndex)
	currentEstimatedOrderedBossPhaseIndex = currentEstimatedOrderedBossPhaseIndex + 1
	currentEstimatedPhaseNumber = orderedBossPhaseTable[currentEstimatedOrderedBossPhaseIndex]

	print(format("Update Phase from %d to %d", previousPhaseNumber, currentEstimatedPhaseNumber))
	print(
		format(
			"Update OrderedBossPhaseIndex from %d to %d",
			currentEstimatedOrderedBossPhaseIndex - 1,
			currentEstimatedOrderedBossPhaseIndex
		)
	)
end

-- Searches the phaseStartSpells, phaseEndSpells, and phaseLimitedSpells to see if the phase can be updated.
---@param spellID integer
---@param subEvent string
local function MaybeUpdatePhase(spellID, subEvent)
	local maybeNewPhaseNumber = phaseStartSpells[spellID]
	if maybeNewPhaseNumber and (subEvent == combatLogEventMap["SCS"] or subEvent == combatLogEventMap["SAA"]) then
		UpdatePhase()
		phaseStartSpells[spellID] = nil
		return
	end

	maybeNewPhaseNumber = phaseEndSpells[spellID]
	if maybeNewPhaseNumber and currentEstimatedPhaseNumber == maybeNewPhaseNumber then
		if subEvent == combatLogEventMap["SCC"] or subEvent == combatLogEventMap["SAR"] then
			UpdatePhase()
			phaseEndSpells[spellID] = nil
			return
		end
	end

	maybeNewPhaseNumber = phaseLimitedSpells[spellID]
	if maybeNewPhaseNumber and maybeNewPhaseNumber > currentEstimatedPhaseNumber then
		UpdatePhase()
		phaseLimitedSpells[spellID] = nil
		return
	end
end

-- Cancels active timers and releases active widgets associated with a spellID.
---@param spellID integer
local function CancelRemindersDueToSpellAlreadyCast(spellID)
	if type(cancelTimerIfCasted[spellID]) == "table" then
		for _, timer in ipairs(cancelTimerIfCasted[spellID]) do
			timer:Cancel()
		end
		cancelTimerIfCasted[spellID] = nil
	end
	if type(hideWidgetIfCasted[spellID]) == "table" then
		for _, widget in ipairs(hideWidgetIfCasted[spellID]) do
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
	if spellID then
		if spellCounts[subEvent] and spellCounts[subEvent][spellID] then
			local spellCount = spellCounts[subEvent][spellID] + 1
			spellCounts[subEvent][spellID] = spellCount
			local reminders = combatLogEventReminders[subEvent][spellID][spellCount]
			if reminders then
				for _, reminder in ipairs(reminders) do
					CreateTimer(reminder.assignment, reminder.roster, reminder.preferences, 0.0)
				end
			end
			-- combatLogEventReminders[subEvent][spellID][spellCount] = nil
		end

		MaybeUpdatePhase(spellID, subEvent)
		if playerGUID == sourceGUID then
			MaybeCancelStuff(spellID, destGUID, subEvent)
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
	-- or difficultyID == 23 or difficultyID == 8 Mythic dung, M+
	if
		not reminderPreferences.messages.enabled
		and not reminderPreferences.progressBars.enabled
		and not reminderPreferences.sound.enableAtAdvanceNotice
		and not reminderPreferences.sound.enableAtTime
		and not reminderPreferences.textToSpeech.enableAtAdvanceNotice
		and not reminderPreferences.textToSpeech.enableAtTime
	then
		return
	end
	if difficultyID == 16 then -- Mythic raid
		local startTime = GetTime()
		local plans = AddOn.db.profile.plans --[[@as table<string, Plan>]]
		local activePlans = {}
		for _, plan in pairs(plans) do
			if plan.dungeonEncounterID == encounterID and plan.remindersEnabled then
				tinsert(activePlans, plan)
			end
		end
		if #activePlans > 0 then
			local boss = bossUtilities.GetBoss(encounterID)
			if boss then
				hideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
				bossUtilities.GenerateBossTables(boss)
				local bossPhaseTable = bossUtilities.GetOrderedBossPhases(boss.dungeonEncounterID)
				if bossPhaseTable then
					orderedBossPhaseTable = bossPhaseTable
				end
				for spellID, ability in pairs(boss.abilities) do
					if #ability.phases == 1 then
						phaseLimitedSpells[spellID] = next(ability.phases)
					end

					for phaseNumber, bossAbilityPhase in pairs(ability.phases) do
						if bossAbilityPhase.signifiesPhaseStart then
							phaseStartSpells[spellID] = phaseNumber
						end
						if bossAbilityPhase.signifiesPhaseEnd then
							phaseEndSpells[spellID] = phaseNumber
						end
					end
				end
				SetupReminders(activePlans, reminderPreferences, startTime)
				Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
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

-- Registers callbacks from BigWigs, Encounter start/end.
function Private:RegisterReminderEvents()
	if type(BigWigsLoader) == "table" and BigWigsLoader.RegisterMessage then
		BigWigsLoader.RegisterMessage(self, "BigWigs_SetStage", HandleBigWigsEvent)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossEngage", HandleBigWigsEvent)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWin", HandleBigWigsEvent)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWipe", HandleBigWigsEvent)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossDisable", HandleBigWigsEvent)
	end

	Private:RegisterEvent("ENCOUNTER_START", HandleEncounterStart)
	Private:RegisterEvent("ENCOUNTER_END", HandleEncounterEnd)
end

-- Unregisters callbacks from BigWigs, Encounter start/end, and CombatLogEventUnfiltered.
function Private:UnregisterReminderEvents()
	ResetLocalVariables()

	if type(BigWigsLoader) == "table" and BigWigsLoader.UnregisterMessage then
		BigWigsLoader.UnregisterMessage(self, "BigWigs_SetStage")
		BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossEngage")
		BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWin")
		BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWipe")
		BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossDisable")
	end

	Private:UnregisterEvent("ENCOUNTER_START")
	Private:UnregisterEvent("ENCOUNTER_END")
	Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
	Private.callbackHandler:Fire("SimulationCompleted")
end

-- Sets up reminders to simulate a boss encounter using static timings.
---@param bossDungeonEncounterID integer
---@param timelineAssignments table<integer, TimelineAssignment>
---@param roster table<string, RosterEntry>
function Private:SimulateBoss(bossDungeonEncounterID, timelineAssignments, roster)
	LGF:ScanForUnitFrames()
	isSimulating = true
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]

	local ttsPreferences = reminderPreferences.textToSpeech
	local soundPreferences = reminderPreferences.sound
	if
		not reminderPreferences.messages.enabled
		and not reminderPreferences.progressBars.enabled
		and not soundPreferences.enableAtAdvanceNotice
		and not soundPreferences.enableAtTime
		and not ttsPreferences.enableAtAdvanceNotice
		and not ttsPreferences.enableAtTime
	then
		return
	end

	if not Private.messageContainer then
		CreateMessageContainer(reminderPreferences.messages)
	end
	if not Private.progressBarContainer then
		CreateProgressBarContainer(reminderPreferences.progressBars)
	end

	local boss = bossUtilities.GetBoss(bossDungeonEncounterID)
	if boss then
		hideIfAlreadyCasted = reminderPreferences.cancelIfAlreadyCasted
		hideIfAlreadyPhased = reminderPreferences.removeDueToPhaseChange
		bossUtilities.GenerateBossTables(boss)
		local bossPhaseTable = bossUtilities.GetOrderedBossPhases(boss.dungeonEncounterID)
		if bossPhaseTable then
			orderedBossPhaseTable = bossPhaseTable
		end
		for spellID, ability in pairs(boss.abilities) do
			if #ability.phases == 1 then
				phaseLimitedSpells[spellID] = next(ability.phases)
			end

			for phaseNumber, bossAbilityPhase in pairs(ability.phases) do
				if bossAbilityPhase.signifiesPhaseStart then
					phaseStartSpells[spellID] = phaseNumber
				end
				if bossAbilityPhase.signifiesPhaseEnd then
					phaseEndSpells[spellID] = phaseNumber
				end
			end
		end

		local totalDuration = 0.0
		for _, phaseData in pairs(boss.phases) do
			totalDuration = totalDuration + (phaseData.duration * phaseData.count)
		end

		local filtered
		if reminderPreferences.onlyShowMe then
			filtered = utilities.FilterSelf(timelineAssignments) --[[@as table<integer, TimelineAssignment>]]
		end
		for _, timelineAssignment in ipairs(filtered or timelineAssignments) do
			CreateSimulationTimer(timelineAssignment, roster, reminderPreferences, 0.0)
		end
		simulationTimer = NewTimer(totalDuration, HandleSimulationCompleted)
		updateFrame:SetScript("OnUpdate", HandleFrameUpdate)
		Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
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
