local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
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
local type = type
local UnitGUID = UnitGUID
local unpack = unpack
local wipe = wipe

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

---@type table<integer, table<integer, FunctionContainer>> -- Ordered boss phases index -> [timers] \
local timers = {} -- All timers are stored here. Ordered boss phases index -> [timers]

---@type table<FullCombatLogEventType, table<integer, table<integer, table<integer, CombatLogEventAssignmentData>>>>
local combatLogEventReminders = {} -- Table of active reminders for responding to combat log events

---@type table<FullCombatLogEventType, table<integer, integer>> -- FullCombatLogEventType -> SpellID -> Count \
local spellCounts = {} -- Acts as filter for combat log events. Increments spell occurrences for registered combat log events.

---@type table<integer, table<integer, FunctionContainer>> -- Spell ID -> [timers]
local cancelTimerIfCasted = {}

---@type table<integer, table<integer, EPProgressBar|EPReminderMessage>> -- Spell ID -> [widgets]
local hideWidgetIfCasted = {}

---@type table<integer, table<integer, EPProgressBar|EPReminderMessage>> -- Ordered boss phases index -> [widgets]
local hideWidgetIfPhased = {}

---@type table<integer, integer> -- [boss phase order index -> boss phase index]
local orderedBossPhaseTable = {}

local currentEstimatedPhaseNumber = 1
local currentEstimatedOrderedBossPhaseIndex = 1
local phaseStartSpells, phaseEndSpells, phaseLimitedSpells = {}, {}, {}
local hideIfAlreadyCasted = false

local operationQueue = {} -- Queue holding pending message or progress bar operations.
local isLocked = false -- Operation Queue lock state.
local isSimulating = false
local lastExecutionTime = 0
local updateFrameTickRate = 0.04
local updateFrame = CreateFrame("Frame")

local function ResetLocalVariables()
	updateFrame:SetScript("OnUpdate", nil)
	for _, indexedTimers in pairs(timers) do
		for _, timer in pairs(indexedTimers) do
			if timer.Cancel then
				timer:Cancel()
			end
		end
	end
	wipe(timers)
	wipe(operationQueue)
	wipe(cancelTimerIfCasted)
	wipe(hideWidgetIfCasted)
	wipe(hideWidgetIfPhased)
	wipe(orderedBossPhaseTable)
	wipe(phaseStartSpells)
	wipe(phaseEndSpells)
	wipe(phaseLimitedSpells)
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
	wipe(combatLogEventReminders)
	wipe(spellCounts)
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
	container.frame:SetFrameLevel(100)
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

-- Creates an EPProgressBar widget and schedules its cleanup on the Completed callback. Starts the countdown.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param duration number
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, roster, duration, progressBarPreferences)
	tinsert(operationQueue, function()
		local icon = assignment.spellInfo.iconID or GetSpellTexture(assignment.spellInfo.spellID)
		local text = utilities.CreateReminderProgressBarText(assignment, roster)
		local progressBar = CreateProgressBar(progressBarPreferences, text, duration, icon > 0 and icon or nil)
		progressBar:SetCallback("Completed", function()
			tinsert(operationQueue, function()
				hideWidgetIfCasted[assignment.spellInfo.spellID] = nil
				Private.progressBarContainer:RemoveChildNoDoLayout(progressBar)
			end)
		end)
		Private.progressBarContainer:AddChildNoDoLayout(progressBar)
		progressBar:Start()
		if assignment.spellInfo.spellID > 1 then
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
---@param roster table<string, RosterEntry>
---@param duration number|nil
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, roster, duration, messagePreferences)
	tinsert(operationQueue, function()
		local icon = assignment.spellInfo.iconID or GetSpellTexture(assignment.spellInfo.spellID)
		local text = utilities.CreateReminderProgressBarText(assignment, roster)
		local message = CreateMessage(messagePreferences, text, duration, icon > 0 and icon or nil)
		message:SetCallback("Completed", function()
			tinsert(operationQueue, function()
				hideWidgetIfCasted[assignment.spellInfo.spellID] = nil
				Private.messageContainer:RemoveChildNoDoLayout(message)
			end)
		end)
		Private.messageContainer:AddChildNoDoLayout(message)
		if duration then
			message:Start(true)
		else
			message:Start(false)
		end
		if assignment.spellInfo.spellID > 1 then
			if not hideWidgetIfCasted[assignment.spellInfo.spellID] then
				hideWidgetIfCasted[assignment.spellInfo.spellID] = {}
			end
			tinsert(hideWidgetIfCasted[assignment.spellInfo.spellID], message)
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

-- Executes the actions that occur at the time in which reminders are first displayed. This is usually at advance notice
-- time before the assignment, but can also be sooner if towards the start of the encounter. Creates timers for actions
-- that occur at assignment time.
---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param reminderText string
---@param duration number
local function ExecuteReminderTimer(assignment, roster, reminderPreferences, reminderText, duration)
	local ttsPreferences = reminderPreferences.textToSpeech
	local soundPreferences = reminderPreferences.sound
	if reminderPreferences.progressBars.enabled then
		AddProgressBar(assignment, roster, duration, reminderPreferences.progressBars)
	end
	if reminderPreferences.messages.enabled and not reminderPreferences.messages.showOnlyAtExpiration then
		AddMessage(assignment, roster, duration, reminderPreferences.messages)
	end
	if ttsPreferences.enableAtAdvanceNotice then
		if reminderText:len() > 0 then
			local textWithAdvanceNotice = reminderText .. " in " .. floor(duration)
			SpeakText(ttsPreferences.voiceID, textWithAdvanceNotice, 1, 1.0, ttsPreferences.volume)
		end
	end
	if soundPreferences.enableAtAdvanceNotice then
		if soundPreferences.advanceNoticeSound and soundPreferences.advanceNoticeSound ~= "" then
			PlaySoundFile(soundPreferences.advanceNoticeSound)
		end
	end

	local deferredFunctions = {}

	if reminderPreferences.messages.enabled and reminderPreferences.messages.showOnlyAtExpiration then
		deferredFunctions[#deferredFunctions + 1] = function()
			AddMessage(assignment, roster, nil, reminderPreferences.messages)
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

	if #deferredFunctions > 0 then
		local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex or 0
		if not timers[bossPhaseOrderIndex] then
			timers[bossPhaseOrderIndex] = {}
		end
		local phaseTimers = timers[bossPhaseOrderIndex]
		local timer = NewTimer(duration, function()
			for _, func in ipairs(deferredFunctions) do
				func()
			end
			cancelTimerIfCasted[assignment.spellInfo.spellID] = nil
		end)
		phaseTimers[#phaseTimers + 1] = timer
		if hideIfAlreadyCasted and assignment.spellInfo.spellID > 1 then
			if not cancelTimerIfCasted[assignment.spellInfo.spellID] then
				cancelTimerIfCasted[assignment.spellInfo.spellID] = {}
			end
			tinsert(cancelTimerIfCasted[assignment.spellInfo.spellID], timer)
		end
	end
end

---@param assignment TimedAssignment|CombatLogEventAssignment
---@param roster table<string, RosterEntry>
---@param reminderPreferences ReminderPreferences
---@param elapsed number
local function CreateTimer(assignment, roster, reminderPreferences, elapsed)
	local reminderText = utilities.CreateReminderProgressBarText(assignment, roster)
	local duration = reminderPreferences.advanceNotice
	local startTime = assignment.time - duration - elapsed

	if startTime < 0 then
		duration = max(0.1, assignment.time - elapsed)
	end

	if startTime < 0.1 then
		ExecuteReminderTimer(assignment, roster, reminderPreferences, reminderText, duration)
	else
		local bossPhaseOrderIndex = assignment.bossPhaseOrderIndex or 0
		if not timers[bossPhaseOrderIndex] then
			timers[bossPhaseOrderIndex] = {}
		end
		local phaseTimers = timers[bossPhaseOrderIndex]
		local timer = NewTimer(startTime, function()
			cancelTimerIfCasted[assignment.spellInfo.spellID] = nil
			ExecuteReminderTimer(assignment, roster, reminderPreferences, reminderText, duration)
		end)
		phaseTimers[#phaseTimers + 1] = timer
		if hideIfAlreadyCasted and assignment.spellInfo.spellID > 1 then
			if not cancelTimerIfCasted[assignment.spellInfo.spellID] then
				cancelTimerIfCasted[assignment.spellInfo.spellID] = {}
			end
			tinsert(cancelTimerIfCasted[assignment.spellInfo.spellID], timer)
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
---@param notes table<string, Plan>
---@param preferences ReminderPreferences
---@param startTime number
local function SetupReminders(notes, preferences, startTime)
	if not Private.messageContainer then
		CreateMessageContainer(preferences.messages)
	end
	if not Private.progressBarContainer then
		CreateProgressBarContainer(preferences.progressBars)
	end

	for _, note in pairs(notes) do
		local roster = note.roster
		local assignments = note.assignments
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
	if timers[orderedBossPhaseIndex] then
		for _, timer in ipairs(timers[orderedBossPhaseIndex]) do
			timer:Cancel()
		end
		print(format("Removed %d timers from %d", #timers[orderedBossPhaseIndex], orderedBossPhaseIndex))
		timers[orderedBossPhaseIndex] = nil
	end
	if hideWidgetIfPhased[orderedBossPhaseIndex] then
		for _, widget in ipairs(hideWidgetIfPhased[orderedBossPhaseIndex]) do
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

function Private.NextPhase()
	UpdatePhase()
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

-- Callback for CombatLogEventUnfiltered events. Creates timers from previously created reminders for
-- CombatLogEventAssignments.
local function HandleCombatLogEventUnfiltered()
	local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
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
		if hideIfAlreadyCasted then
			if
				UnitGUID("player") == sourceGUID and subEvent == "SPELL_CAST_START"
				or subEvent == "SPELL_CAST_SUCCESS"
			then
				CancelRemindersDueToSpellAlreadyCast(spellID)
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
		local notes = AddOn.db.profile.plans --[[@as table<string, Plan>]]
		local activeNotes = {}
		for _, note in pairs(notes) do
			if note.dungeonEncounterID == encounterID and note.remindersEnabled then
				tinsert(activeNotes, note)
			end
		end
		if #activeNotes > 0 then
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
				SetupReminders(activeNotes, reminderPreferences, startTime)
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

-- Sets up reminders to simulate a boss encounter using static timings.
---@param bossDungeonEncounterID integer
---@param timelineAssignments table<integer, TimelineAssignment>
---@param roster table<string, RosterEntry>
function Private:SimulateBoss(bossDungeonEncounterID, timelineAssignments, roster)
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
	end

	local filtered
	if reminderPreferences.onlyShowMe then
		filtered = utilities.FilterSelf(timelineAssignments) --[[@as table<integer, TimelineAssignment>]]
	end
	for _, timelineAssignment in ipairs(filtered or timelineAssignments) do
		CreateSimulationTimer(timelineAssignment, roster, reminderPreferences, 0.0)
	end

	updateFrame:SetScript("OnUpdate", HandleFrameUpdate)
	Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", HandleCombatLogEventUnfiltered)
end

-- Clears all timers and reminder widgets.
function Private:StopSimulatingBoss()
	Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ResetLocalVariables()
end

-- Returns true if SimulateBoss has been called without calling StopSimulatingBoss afterwards.
---@return boolean
function Private:IsSimulatingBoss()
	return isSimulating
end
