---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class Utilities
local utilities = Private.utilities

local AddOn = Private.addOn
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local floor = math.floor
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
local tinsert = tinsert
local type = type
local unpack = unpack
local wipe = wipe

local messageDuration = 1.0
local timers = {}
local combatLogEventReminders = {}
local eventFilter = {}
local spellCounts = {}
local combatLogEventMap = {
	["SCC"] = "SPELL_CAST_SUCCESS",
	["SCS"] = "SPELL_CAST_START",
	["SAA"] = "SPELL_AURA_APPLIED",
	["SAR"] = "SPELL_AURA_REMOVED",
}

local updateFrame = CreateFrame("Frame")

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

local function GetOrCreateTable(tbl, key)
	if not tbl[key] then
		tbl[key] = {}
	end
	return tbl[key]
end

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

local operationQueue = {} -- Queue to hold pending operations
local isLocked = false -- Mutex lock state

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

---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@param duration number
---@param progressBarPreferences ProgressBarPreferences
local function AddProgressBar(assignment, roster, duration, progressBarPreferences)
	tinsert(operationQueue, function()
		local icon = assignment.spellInfo.iconID or GetSpellTexture(assignment.spellInfo.spellID)
		local text = utilities.CreateReminderProgressBarText(assignment, roster)
		local progressBar = CreateProgressBar(progressBarPreferences, text, duration, icon > 0 and icon or nil)
		progressBar:SetCallback("Completed", function()
			tinsert(operationQueue, function()
				Private.progressBarContainer:RemoveChildNoDoLayout(progressBar)
			end)
		end)
		Private.progressBarContainer:AddChildNoDoLayout(progressBar)
		progressBar:Start()
	end)
end

---@param assignment CombatLogEventAssignment|TimedAssignment|PhasedAssignment|Assignment
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@param duration number|nil If nil, the message will be shown for 1 second, otherwise will be shown with countdown.
---@param messagePreferences MessagePreferences
local function AddMessage(assignment, roster, duration, messagePreferences)
	tinsert(operationQueue, function()
		local icon = assignment.spellInfo.iconID or GetSpellTexture(assignment.spellInfo.spellID)
		local text = utilities.CreateReminderProgressBarText(assignment, roster)
		local message = CreateMessage(messagePreferences, text, duration, icon > 0 and icon or nil)
		if duration then
			message:SetCallback("Completed", function()
				tinsert(operationQueue, function()
					Private.messageContainer:RemoveChildNoDoLayout(message)
				end)
			end)
		else
			tinsert(
				timers,
				NewTimer(messageDuration, function()
					tinsert(operationQueue, function()
						Private.messageContainer:RemoveChildNoDoLayout(message)
					end)
				end)
			)
		end
		Private.messageContainer:AddChildNoDoLayout(message)
		if duration then
			message:Start()
		end
	end)
end

local function SimulateHandleCombatLogEventUnfiltered(time, event, spellID)
	-- local time, event, _, _, sourceName, _, _, _, _, _, _, spellID, _, _, _, _ = CombatLogGetCurrentEventInfo()
	if eventFilter[event] then
		spellCounts[spellID] = spellCounts[spellID] + 1
		local combatLogEventReminder = combatLogEventReminders[event][spellID][spellCounts[spellID]]
		if combatLogEventReminder then
			local start = combatLogEventReminder.relativeStartTime - combatLogEventReminder.advanceNotice
			tinsert(
				timers,
				NewTimer(start < 0 and 0.1 or start, function()
					-- AddProgressBar(
					-- 	combatLogEventReminder.assignment,
					-- 	combatLogEventReminder.roster,
					-- 	combatLogEventReminder.advanceNotice,
					-- 	reminderPreferences.textToSpeech
					-- )
				end)
			)
		end
	end
end

---@param timelineAssignment TimelineAssignment
---@param roster table<string, EncounterPlannerDbRosterEntry>
---@param reminderPreferences ReminderPreferences
local function CreateTimer(timelineAssignment, roster, reminderPreferences)
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
	local assignment = timelineAssignment.assignment
	local reminderText = utilities.CreateReminderProgressBarText(assignment, roster)
	local startTime = timelineAssignment.startTime - reminderPreferences.advanceNotice -- (GetTime() - startTime)
	if timelineAssignment.startTime < reminderPreferences.advanceNotice then
		startTime = timelineAssignment.startTime
	end
	startTime = max(startTime, 0.1)

	timers[#timers + 1] = NewTimer(startTime, function()
		if reminderPreferences.progressBars.enabled then
			AddProgressBar(assignment, roster, reminderPreferences.advanceNotice, reminderPreferences.progressBars)
		end
		if not reminderPreferences.messages.showOnlyAtExpiration then
			AddMessage(assignment, roster, reminderPreferences.advanceNotice, reminderPreferences.messages)
		end
		if ttsPreferences.enableAtAdvanceNotice then
			if reminderText:len() > 0 then
				local textWithAdvanceNotice = reminderText .. " in " .. floor(reminderPreferences.advanceNotice)
				SpeakText(ttsPreferences.voiceID, textWithAdvanceNotice, 1, 1.0, ttsPreferences.volume)
			end
		end
		if soundPreferences.enableAtAdvanceNotice then
			if soundPreferences.advanceNoticeSound and soundPreferences.advanceNoticeSound ~= "" then
				PlaySoundFile(soundPreferences.advanceNoticeSound)
			end
		end

		local deferredFunctions = {}

		if reminderPreferences.messages.showOnlyAtExpiration then
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
			timers[#timers + 1] = NewTimer(reminderPreferences.advanceNotice, function()
				for _, func in ipairs(deferredFunctions) do
					func()
				end
			end)
		end
	end)
end

---@param timelineAssignments table<integer, TimelineAssignment>
---@param roster table<string, EncounterPlannerDbRosterEntry>
function Private:SimulateBoss(timelineAssignments, roster)
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]
	local messagePreferences = reminderPreferences.messages
	local progressBarPreferences = reminderPreferences.progressBars

	do
		Private.messageContainer = AceGUI:Create("EPContainer")
		Private.messageContainer:SetLayout("EPProgressBarLayout")
		Private.messageContainer.frame:SetFrameStrata("MEDIUM")
		Private.messageContainer.frame:SetFrameLevel(100)
		Private.messageContainer:SetSpacing(0, 0)
		local anchorFrame = _G[messagePreferences.relativeTo] or UIParent
		local point, relativePoint = messagePreferences.point, messagePreferences.relativePoint
		local x, y = messagePreferences.x, messagePreferences.y
		Private.messageContainer.frame:SetPoint(point, anchorFrame, relativePoint, x, y)
		Private.messageContainer:SetCallback("OnRelease", function()
			Private.messageContainer = nil
		end)
	end
	do
		Private.progressBarContainer = AceGUI:Create("EPContainer")
		Private.progressBarContainer:SetLayout("EPProgressBarLayout")
		Private.progressBarContainer.frame:SetFrameStrata("MEDIUM")
		Private.progressBarContainer.frame:SetFrameLevel(100)
		Private.progressBarContainer:SetSpacing(0, progressBarPreferences.showBorder and -1 or 0)
		local anchorFrame = _G[progressBarPreferences.relativeTo] or UIParent
		local point, relativePoint = progressBarPreferences.point, progressBarPreferences.relativePoint
		local x, y = progressBarPreferences.x, progressBarPreferences.y
		Private.progressBarContainer.frame:SetPoint(point, anchorFrame, relativePoint, x, y)
		Private.progressBarContainer:SetCallback("OnRelease", function()
			Private.progressBarContainer = nil
		end)
	end

	local startTime = GetTime()
	local lastExecutionTime = 0
	updateFrame:SetScript("OnUpdate", function(_, elapsed)
		local currentTime = GetTime()
		if currentTime - lastExecutionTime < 0.04 then
			return
		end
		lastExecutionTime = currentTime
		ProcessNextOperation()
	end)
	local filteredTimelineAssignments
	if reminderPreferences.onlyShowMe then
		filteredTimelineAssignments = utilities.FilterSelf(timelineAssignments)
	end
	for _, timelineAssignment in ipairs(filteredTimelineAssignments or timelineAssignments) do
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

			CreateTimer(timelineAssignment, roster, reminderPreferences)
		elseif getmetatable(timelineAssignment.assignment) == Private.classes.TimedAssignment then
			CreateTimer(timelineAssignment, roster, reminderPreferences)
		end
	end
end

function Private:StopSimulatingBoss()
	wipe(operationQueue)
	updateFrame:SetScript("OnUpdate", nil)
	if Private.messageContainer then
		Private.messageContainer:Release()
	end
	if Private.progressBarContainer then
		Private.progressBarContainer:Release()
	end
	for _, timer in pairs(timers) do
		if timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(timers)
	wipe(eventFilter)
	wipe(combatLogEventReminders)
	wipe(spellCounts)
end

---@return boolean
function Private:IsSimulatingBoss()
	return #timers > 0
end

function Private:InitializeReminder()
	-- TODO: Disable/update based on reminderPreferences.enabled
	if type(BigWigsLoader) == "table" and BigWigsLoader.RegisterMessage then
		BigWigsLoader.RegisterMessage(self, "BigWigs_SetStage", function(event, addon, stage)
			print("Stage", stage)
		end)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossEngage", function(...)
			print("OnBossEngage", ...)
		end)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWin", function(...)
			print("OnBossWin", ...)
		end)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWipe", function(...)
			print("OnBossWipe", ...)
		end)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossDisable", function(...)
			print("OnBossDisable", ...)
		end)
	end
	Private:RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
		print(encounterID, encounterName, difficultyID, groupSize)
		Private:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
			local time, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, extraSpellId, amount =
				CombatLogGetCurrentEventInfo()
		end)
	end)
	Private:RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
		print(encounterID, encounterName, difficultyID, groupSize, success)
		Private:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end)
end
