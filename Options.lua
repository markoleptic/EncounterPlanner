local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local AddOn = Private.addOn
local L = Private.L

---@class Constants
local constants = Private.constants
local kOptionsMenuFrameLevel = constants.frameLevels.kOptionsMenuFrameLevel

---@class OptionsModule : AceModule
local OptionsModule = Private.addOn.optionsModule

---@class Utilities
local utilities = Private.utilities
local IsValidRegionName = utilities.IsValidRegionName
local Round = utilities.Round

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater
local UpdateAllAssignments = interfaceUpdater.UpdateAllAssignments

local LibStub = LibStub
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local GetTtsVoices = C_VoiceChat.GetTtsVoices
local pairs = pairs
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

---@type EPContainer|nil
local messageAnchor = nil
---@type EPContainer|nil
local progressBarAnchor = nil

---@param left number
---@param top number
---@param width number
---@param height number
---@param point AnchorPoint
---@param rLeft number
---@param rTop number
---@param rWidth number
---@param rhHeight number
---@param rPoint AnchorPoint
local function CalculateNewOffset(left, top, width, height, point, rLeft, rTop, rWidth, rhHeight, rPoint)
	if point == "TOP" then
		left = left + width / 2.0
	elseif point == "TOPRIGHT" then
		left = left + width
	elseif point == "RIGHT" then
		left = left + width
		top = top - height / 2.0
	elseif point == "BOTTOMRIGHT" then
		left = left + width
		top = top - height
	elseif point == "BOTTOM" then
		left = left + width / 2.0
		top = top - height
	elseif point == "LEFT" then
		top = top - height / 2.0
	elseif point == "BOTTOMLEFT" then
		top = top - height
	elseif point == "CENTER" then
		left = left + width / 2.0
		top = top - height / 2.0
	end

	if rPoint == "TOP" then
		rLeft = rLeft + rWidth / 2.0
	elseif rPoint == "TOPRIGHT" then
		rLeft = rLeft + rWidth
	elseif rPoint == "RIGHT" then
		rLeft = rLeft + rWidth
		rTop = rTop - rhHeight / 2.0
	elseif rPoint == "BOTTOMRIGHT" then
		rLeft = rLeft + rWidth
		rTop = rTop - rhHeight
	elseif rPoint == "BOTTOM" then
		rLeft = rLeft + rWidth / 2.0
		rTop = rTop - rhHeight
	elseif rPoint == "LEFT" then
		rTop = rTop - rhHeight / 2.0
	elseif rPoint == "BOTTOMLEFT" then
		rTop = rTop - rhHeight
	elseif rPoint == "CENTER" then
		rLeft = rLeft + rWidth / 2.0
		rTop = rTop - rhHeight / 2.0
	end

	return left - rLeft, top - rTop
end

---@param frame Frame
---@param point AnchorPoint|nil
---@param regionName string|nil
---@param relativePoint AnchorPoint|nil
---@return AnchorPoint, string, AnchorPoint, number, number
local function ApplyPoint(frame, point, regionName, relativePoint)
	local p, rF, rP, _, _ = frame:GetPoint()
	point = point or p
	local relativeFrame = IsValidRegionName(regionName) and _G[regionName] or rF
	relativePoint = relativePoint or rP
	local left, top, width, height = frame:GetLeft(), frame:GetTop(), frame:GetWidth(), frame:GetHeight()
	local rLeft, rTop, rWidth, rHeight =
		relativeFrame:GetLeft(), relativeFrame:GetTop(), relativeFrame:GetWidth(), relativeFrame:GetHeight()

	local x, y = CalculateNewOffset(left, top, width, height, point, rLeft, rTop, rWidth, rHeight, relativePoint)
	x = Round(x, 2)
	y = Round(y, 2)

	local relativeTo = relativeFrame:GetName()
	frame:ClearAllPoints()
	frame:SetPoint(point, relativeTo, relativePoint, x, y)

	return point, relativeTo, relativePoint, x, y
end

---@return Preferences
local function GetPreferences()
	return AddOn.db.profile.preferences
end

---@return ReminderPreferences
local function GetReminderPreferences()
	return AddOn.db.profile.preferences.reminder
end

---@return ProgressBarPreferences
local function GetProgressBarPreferences()
	return AddOn.db.profile.preferences.reminder.progressBars
end

---@return MessagePreferences
local function GetMessagePreferences()
	return AddOn.db.profile.preferences.reminder.messages
end

local function ResetProfile()
	AddOn.db:ResetProfile()
end

---@param name string
local function SetProfile(name)
	AddOn.db:SetProfile(name)
end

---@return string
local function GetCurrentProfile()
	return AddOn.db:GetCurrentProfile()
end

---@param noCurrent boolean
---@return table<integer, DropdownItemData>
local function GetProfiles(noCurrent)
	local profiles = {}
	local db = AddOn.db

	local currentProfile = db:GetCurrentProfile()
	for _, v in pairs(db:GetProfiles()) do
		if not (noCurrent and v == currentProfile) then
			tinsert(profiles, { itemValue = v, text = v })
		end
	end

	return profiles
end

---@param name string
local function CopyProfile(name)
	AddOn.db:CopyProfile(name)
end

---@param name string
local function DeleteProfile(name)
	AddOn.db:DeleteProfile(name)
end

local mouseIsDown = false
local progressBarManager = {}
do
	local NewTimer = C_Timer.NewTimer
	local timers = {}
	local kGenericTimerMultiplier = 0.33
	local isAddingProgressBars = false

	local function AddDelayedProgressBar(time)
		local timer = NewTimer(time, function()
			progressBarManager:AddProgressBar()
			tremove(timers, 1)
		end)
		tinsert(timers, timer)
	end

	local function AddSecondAndThirdProgressBarsDelayed()
		isAddingProgressBars = true
		local secondTimerDuration = GetReminderPreferences().advanceNotice * kGenericTimerMultiplier
		local thirdTimerDuration = secondTimerDuration * 2.0
		AddDelayedProgressBar(secondTimerDuration)
		AddDelayedProgressBar(thirdTimerDuration)
	end

	function progressBarManager:AddProgressBar()
		if progressBarAnchor then
			local reminderPreferences = GetReminderPreferences()
			local preferences = reminderPreferences.progressBars
			local progressBar = utilities.CreateProgressBar(
				preferences,
				L["Progress Bar Text"],
				reminderPreferences.advanceNotice,
				[[Interface\Icons\INV_MISC_QUESTIONMARK]]
			)
			progressBar:SetCallback("Completed", function(widget)
				if progressBarAnchor then
					if not isAddingProgressBars and #progressBarAnchor.children == 1 then
						widget:SetDuration(GetReminderPreferences().advanceNotice)
						widget:Start()

						AddSecondAndThirdProgressBarsDelayed()
					else
						if mouseIsDown then
							local p = GetProgressBarPreferences()
							local p1, p2, p3, p4, p5 =
								ApplyPoint(progressBarAnchor.frame, p.point, p.relativeTo, p.relativePoint)
							progressBarAnchor:RemoveChild(widget)
							if mouseIsDown and p1 then
								progressBarAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
							end
						else
							progressBarAnchor:RemoveChild(widget)
						end
					end
				end
			end)

			if mouseIsDown then
				local p = GetProgressBarPreferences()
				local p1, p2, p3, p4, p5 = ApplyPoint(progressBarAnchor.frame, p.point, p.relativeTo, p.relativePoint)
				progressBarAnchor:AddChild(progressBar)
				if mouseIsDown and p1 then
					progressBarAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
				end
			else
				progressBarAnchor:AddChild(progressBar)
			end
			progressBar:Start()

			if #progressBarAnchor.children >= 3 then
				isAddingProgressBars = false
			end
		end
	end

	function progressBarManager:AddProgressBarsOnTimer()
		if progressBarAnchor then
			progressBarAnchor:ReleaseChildren()
			self:AddProgressBar()
			AddSecondAndThirdProgressBarsDelayed()
		end
	end

	function progressBarManager:CancelTimers()
		for _, timer in ipairs(timers) do
			if timer and timer.Cancel then
				timer:Cancel()
			end
		end
		wipe(timers)
		isAddingProgressBars = false
	end
end

local messageManager = {}
do
	local NewTimer = C_Timer.NewTimer
	local timers = {}
	local secondTimerDurationNoCountdown = 1.2
	local thirdTimerDurationNoCountdown = 2.4
	local kGenericTimerMultiplier = 0.33
	local isAddingMessages = false

	local function AddMessageDelayed(time)
		local timer = NewTimer(time, function()
			messageManager:AddMessage()
			tremove(timers, 1)
		end)
		tinsert(timers, timer)
	end

	local function AddSecondAndThirdMessagesDelayed()
		isAddingMessages = true
		local reminderPreferences = GetReminderPreferences()
		if reminderPreferences.messages.showOnlyAtExpiration then
			AddMessageDelayed(secondTimerDurationNoCountdown)
			AddMessageDelayed(thirdTimerDurationNoCountdown)
		else
			local secondTimerDuration = reminderPreferences.advanceNotice * kGenericTimerMultiplier
			local thirdTimerDuration = secondTimerDuration * 2.0
			AddMessageDelayed(secondTimerDuration)
			AddMessageDelayed(thirdTimerDuration)
		end
	end

	function messageManager:AddMessage()
		if messageAnchor then
			local reminderPreferences = GetReminderPreferences()
			local preferences = reminderPreferences.messages
			local message = utilities.CreateMessage(
				preferences,
				L["Cast spell or something"],
				[[Interface\Icons\INV_MISC_QUESTIONMARK]]
			)
			message:SetAnchorMode(true)
			message:SetCallback("Completed", function(widget)
				if messageAnchor then
					if not isAddingMessages and #messageAnchor.children == 1 then
						local p = GetReminderPreferences()
						widget:Start(p.messages.showOnlyAtExpiration and 0 or p.advanceNotice)
						AddSecondAndThirdMessagesDelayed()
					else
						if mouseIsDown then
							local p = GetMessagePreferences()
							local p1, p2, p3, p4, p5 =
								ApplyPoint(messageAnchor.frame, p.point, p.relativeTo, p.relativePoint)
							messageAnchor:RemoveChild(widget)
							if mouseIsDown and p1 then
								messageAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
							end
						else
							messageAnchor:RemoveChild(widget)
						end
					end
				end
			end)

			if mouseIsDown then
				local p = GetMessagePreferences()
				local p1, p2, p3, p4, p5 = ApplyPoint(messageAnchor.frame, p.point, p.relativeTo, p.relativePoint)
				messageAnchor:AddChild(message)
				if mouseIsDown and p1 then
					messageAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
				end
			else
				messageAnchor:AddChild(message)
			end
			message:Start(preferences.showOnlyAtExpiration and 0 or reminderPreferences.advanceNotice)

			if #messageAnchor.children >= 3 then
				isAddingMessages = false
			end
		end
	end

	function messageManager:AddMessagesOnTimer()
		if messageAnchor then
			messageAnchor:ReleaseChildren()
			self:AddMessage()
			AddSecondAndThirdMessagesDelayed()
		end
	end

	function messageManager:CancelTimers()
		for _, timer in ipairs(timers) do
			if timer and timer.Cancel then
				timer:Cancel()
			end
		end
		wipe(timers)
		isAddingMessages = false
	end
end

---@return EPContainer
local function CreateProgressBarAnchor()
	local progressBarPreferences = GetProgressBarPreferences()
	local container = utilities.CreateReminderContainer(progressBarPreferences, progressBarPreferences.spacing)
	container:SetAnchorMode(true, progressBarPreferences.point)
	container.frame:SetClampedToScreen(true)
	progressBarManager:AddProgressBarsOnTimer()

	container:SetCallback("OnRelease", function()
		progressBarManager:CancelTimers()
		if progressBarAnchor then
			progressBarAnchor.frame:SetClampedToScreen(false)
		end
		progressBarAnchor = nil
		mouseIsDown = false
	end)
	container:SetCallback("MouseDown", function()
		mouseIsDown = true
	end)
	container:SetCallback("NewPoint", function(_, _, point, regionName, relativePoint)
		mouseIsDown = false
		if progressBarAnchor then
			local preferences = GetProgressBarPreferences()
			if progressBarAnchor.frame:GetName() == regionName then
				regionName = preferences.relativeTo
			end
			preferences.point, preferences.relativeTo, preferences.relativePoint, preferences.x, preferences.y =
				ApplyPoint(progressBarAnchor.frame, point, regionName, relativePoint)
			if Private.optionsMenu then
				Private.optionsMenu:UpdateOptions()
			end
		end
	end)

	return container
end

---@return EPContainer
local function CreateMessageAnchor()
	local messagePreferences = GetMessagePreferences()
	local container = utilities.CreateReminderContainer(messagePreferences)
	container.frame:SetClampedToScreen(true)
	container:SetAnchorMode(true, messagePreferences.point)

	container:SetCallback("OnRelease", function()
		messageManager:CancelTimers()
		if messageAnchor then
			messageAnchor.frame:SetClampedToScreen(false)
		end
		messageAnchor = nil
		mouseIsDown = false
	end)
	container:SetCallback("MouseDown", function()
		mouseIsDown = true
	end)
	container:SetCallback("NewPoint", function(_, _, point, relativeFrame, relativePoint)
		mouseIsDown = false
		if messageAnchor then
			local preferences = GetMessagePreferences()
			if messageAnchor.frame:GetName() == relativeFrame then
				relativeFrame = preferences.relativeTo
			end
			preferences.point, preferences.relativeTo, preferences.relativePoint, preferences.x, preferences.y =
				ApplyPoint(messageAnchor.frame, point, relativeFrame, relativePoint)
			if Private.optionsMenu then
				Private.optionsMenu:UpdateOptions()
			end
		end
	end)

	return container
end

---@param progressBar boolean
---@param point AnchorPoint|nil
---@param relativeTo string|nil
---@param relativePoint AnchorPoint|nil
local function ApplyPointToAnchor(progressBar, point, relativeTo, relativePoint)
	if progressBarAnchor and progressBar then
		local x, y
		point, relativeTo, relativePoint, x, y = ApplyPoint(progressBarAnchor.frame, point, relativeTo, relativePoint)
		progressBarAnchor:SetAnchorPoint(point)
		local preferences = GetProgressBarPreferences()
		preferences.point = point
		preferences.relativeTo = relativeTo
		preferences.relativePoint = relativePoint
		preferences.x, preferences.y = x, y
	elseif messageAnchor and not progressBar then
		local x, y
		point, relativeTo, relativePoint, x, y = ApplyPoint(messageAnchor.frame, point, relativeTo, relativePoint)
		messageAnchor:SetAnchorPoint(point)
		local preferences = GetMessagePreferences()
		preferences.point = point
		preferences.relativeTo = relativeTo
		preferences.relativePoint = relativePoint
		preferences.x, preferences.y = x, y
	end
end

---@param func fun(message: EPReminderMessage)
local function CallMessageAnchorFunction(func)
	if messageAnchor then
		for _, child in ipairs(messageAnchor.children) do
			func(child)
		end
		messageAnchor:DoLayout()
	end
end

---@param func fun(progressBar: EPProgressBar)
local function CallProgressBarAnchorFunction(func)
	if progressBarAnchor then
		for _, child in ipairs(progressBarAnchor.children) do
			func(child)
		end
		progressBarAnchor:DoLayout()
	end
end

---@param progressBar boolean
local function HideAnchor(progressBar)
	if progressBarAnchor and progressBar then
		progressBarAnchor.frame:Hide()
		progressBarManager:CancelTimers()
		progressBarAnchor:ReleaseChildren()
	elseif messageAnchor and not progressBar then
		messageAnchor.frame:Hide()
		messageManager:CancelTimers()
		messageAnchor:ReleaseChildren()
	end
end

---@param progressBar boolean
local function ShowAnchor(progressBar)
	if progressBarAnchor and progressBar then
		progressBarAnchor.frame:Show()
		progressBarManager:CancelTimers()
		progressBarManager:AddProgressBarsOnTimer()
	elseif messageAnchor and not progressBar then
		messageAnchor.frame:Show()
		messageManager:CancelTimers()
		messageManager:AddMessagesOnTimer()
	end
end

local optionCreator = {}
do
	local Clamp = Clamp
	local wipe = wipe

	local MouseButtonKeyBindingValues = {
		{ itemValue = "LeftButton", text = L["Left Click"] },
		{ itemValue = "Alt-LeftButton", text = L["Alt + Left Click"] },
		{ itemValue = "Ctrl-LeftButton", text = L["Ctrl + Left Click"] },
		{ itemValue = "Shift-LeftButton", text = L["Shift + Left Click"] },
		{ itemValue = "MiddleButton", text = L["Middle Mouse Button"] },
		{ itemValue = "Alt-MiddleButton", text = L["Alt + Middle Mouse Button"] },
		{ itemValue = "Ctrl-MiddleButton", text = L["Ctrl + Middle Mouse Button"] },
		{ itemValue = "Shift-MiddleButton", text = L["Shift + Middle Mouse Button"] },
		{ itemValue = "RightButton", text = L["Right Click"] },
		{ itemValue = "Alt-RightButton", text = L["Alt + Right Click"] },
		{ itemValue = "Ctrl-RightButton", text = L["Ctrl + Right Click"] },
		{ itemValue = "Shift-RightButton", text = L["Shift + Right Click"] },
	}

	local rowValues = {
		{ itemValue = 1, text = "1" },
		{ itemValue = 2, text = "2" },
		{ itemValue = 3, text = "3" },
		{ itemValue = 4, text = "4" },
		{ itemValue = 5, text = "5" },
		{ itemValue = 6, text = "6" },
		{ itemValue = 7, text = "7" },
		{ itemValue = 8, text = "8" },
		{ itemValue = 9, text = "9" },
		{ itemValue = 10, text = "10" },
		{ itemValue = 11, text = "11" },
		{ itemValue = 12, text = "12" },
	}

	local sortingValues = {
		{ itemValue = false, text = L["Soonest Expiration on Top"] },
		{ itemValue = true, text = L["Soonest Expiration on Bottom"] },
	}

	local anchorPointValues = {
		{ itemValue = "TOPLEFT", text = L["Top Left"] },
		{ itemValue = "TOP", text = L["Top"] },
		{ itemValue = "TOPRIGHT", text = L["Top Right"] },
		{ itemValue = "RIGHT", text = L["Right"] },
		{ itemValue = "BOTTOMRIGHT", text = L["Bottom Right"] },
		{ itemValue = "BOTTOM", text = L["Bottom"] },
		{ itemValue = "LEFT", text = L["Left"] },
		{ itemValue = "BOTTOMLEFT", text = L["Bottom Left"] },
		{ itemValue = "CENTER", text = L["Center"] },
	}

	local fontOutlineValues = {
		{ itemValue = "", text = L["None"] },
		{ itemValue = "MONOCHROME", text = L["Monochrome"] },
		{ itemValue = "OUTLINE", text = L["Outline"] },
		{ itemValue = "THICKOUTLINE", text = L["Thick Outline"] },
	}

	--[[@type table<integer, EPSettingOption>]]
	local cooldownOverrideOptions = nil
	--[[@type table<integer, EPSettingOption>]]
	local keyBindingOptions = nil
	--[[@type table<integer, EPSettingOption>]]
	local viewOptions = nil
	--[[@type table<integer, EPSettingOption>]]
	local reminderOptions = nil
	--[[@type table<integer, EPSettingOption>]]
	local profileOptions = nil

	--[[@type table<integer, DropdownItemData>]]
	local sounds = nil
	--[[@type table<integer, DropdownItemData>]]
	local fonts = nil
	--[[@type table<integer, DropdownItemData>]]
	local statusBarTextures = nil
	--[[@type table<integer, DropdownItemData>]]
	local voices = nil

	local sortFunc = function(a, b)
		return a.text < b.text
	end

	---@param mediaType "background"|"border"|"font"|"sound"|"statusbar"
	---@return table<integer, DropdownItemData>
	local function IterateHashTable(mediaType)
		local returnTable = {}
		for name, value in pairs(LSM:HashTable(mediaType)) do
			tinsert(returnTable, { itemValue = value, text = name })
		end
		sort(returnTable, sortFunc)
		return returnTable
	end

	---@return table<integer, EPSettingOption>
	local function CreateKeyBindingOptions()
		return {
			{
				label = L["Pan"],
				type = "dropdown",
				description = L["Pans the timeline to the left and right when holding this key."],
				category = L["Timeline"],
				values = MouseButtonKeyBindingValues,
				get = function()
					return GetPreferences().keyBindings.pan
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.pan = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if
						preferences.keyBindings.editAssignment == key
						or preferences.keyBindings.newAssignment == key
					then
						return false, preferences.keyBindings.pan
					end
					return true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Scroll"],
				type = "dropdown",
				description = L["Scrolls the timeline up and down."],
				category = L["Timeline"],
				values = {
					{ itemValue = "MouseScroll", text = L["Mouse Scroll"] },
					{ itemValue = "Alt-MouseScroll", text = L["Alt + Mouse Scroll"] },
					{ itemValue = "Ctrl-MouseScroll", text = L["Ctrl + Mouse Scroll"] },
					{ itemValue = "Shift-MouseScroll", text = L["Shift + Mouse Scroll"] },
				},
				get = function()
					return GetPreferences().keyBindings.scroll
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.scroll = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if preferences.keyBindings.zoom == key then
						return false, preferences.keyBindings.scroll
					end
					return true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Zoom"],
				type = "dropdown",
				description = L["Zooms in horizontally on the timeline."],
				category = L["Timeline"],
				values = {
					{ itemValue = "MouseScroll", text = L["Mouse Scroll"] },
					{ itemValue = "Alt-MouseScroll", text = L["Alt + Mouse Scroll"] },
					{ itemValue = "Ctrl-MouseScroll", text = L["Ctrl + Mouse Scroll"] },
					{ itemValue = "Shift-MouseScroll", text = L["Shift + Mouse Scroll"] },
				},
				get = function()
					return GetPreferences().keyBindings.zoom
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.zoom = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if preferences.keyBindings.scroll == key then
						return false, preferences.keyBindings.zoom
					end
					return true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Add Assignment"],
				type = "dropdown",
				description = L["Creates a new assignment when this key is pressed when hovering over the timeline."],
				category = L["Assignment"],
				values = MouseButtonKeyBindingValues,
				get = function()
					return GetPreferences().keyBindings.newAssignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.newAssignment = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if preferences.keyBindings.pan == key then
						return false, preferences.keyBindings.newAssignment
					end
					return true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Edit Assignment"],
				type = "dropdown",
				description = L["Opens the assignment editor when this key is pressed when hovering over an assignment spell icon."],
				category = L["Assignment"],
				values = MouseButtonKeyBindingValues,
				get = function()
					return GetPreferences().keyBindings.editAssignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.editAssignment = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if preferences.keyBindings.pan == key then
						return false, preferences.keyBindings.editAssignment
					elseif preferences.keyBindings.duplicateAssignment == key then
						return false, preferences.keyBindings.editAssignment
					end
					return true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Duplicate Assignment"],
				type = "dropdown",
				description = L["Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key."],
				category = L["Assignment"],
				values = MouseButtonKeyBindingValues,
				get = function()
					return GetPreferences().keyBindings.duplicateAssignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetPreferences().keyBindings.duplicateAssignment = key
					end
				end,
				validate = function(key)
					local preferences = GetPreferences()
					if preferences.keyBindings.editAssignment == key then
						return false, preferences.keyBindings.duplicateAssignment
					end
					return true
				end,
			} --[[@as EPSettingOption]],
		}
	end

	local function CreateReminderOptions()
		local enableReminderOption = function()
			return GetReminderPreferences().enabled == true
		end
		local enableMessageOption = function()
			local preferences = GetReminderPreferences()
			return preferences.enabled == true and preferences.messages.enabled == true
		end
		local enableProgressBarOption = function()
			local preferences = GetReminderPreferences()
			return preferences.enabled == true and preferences.progressBars.enabled == true
		end
		local kMaxProgressBarWidth = 1000.0
		local kMaxProgressBarHeight = 100.0
		local kMinSpacing = -1
		local kMaxSpacing = 100
		local kMinAdvanceNotice = 2.0
		local kMaxAdvanceNotice = 30.0
		local kMinFontSize = 8
		local kMaxFontSize = 64
		local kMaxVolume = 100.0
		local kOne = 1.0
		local kZero = 0.0
		return {
			{
				label = L["Enable Reminders"],
				type = "checkBox",
				description = L["Whether to enable reminders for assignments."],
				get = function()
					return GetReminderPreferences().enabled
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetReminderPreferences()
						if key ~= preferences.enabled then
							if key == true then
								Private:RegisterReminderEvents()
							else
								Private:UnregisterReminderEvents()
								if messageAnchor and messageAnchor.frame:IsShown() then
									HideAnchor(false)
								end
								if progressBarAnchor and progressBarAnchor.frame:IsShown() then
									HideAnchor(true)
								end
							end
						end
						preferences.enabled = key
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Only Show Reminders For Me"],
				type = "checkBox",
				description = L["Whether to only show assignment reminders that are relevant to you."],
				enabled = enableReminderOption,
				get = function()
					return GetReminderPreferences().onlyShowMe
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().onlyShowMe = key
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Hide or Cancel if Spell on Cooldown"],
				type = "checkBox",
				description = L["If an assignment is a spell and it already on cooldown, the reminder will not be shown. If the spell is cast during the reminder countdown, it will be cancelled."],
				enabled = enableReminderOption,
				get = function()
					return GetReminderPreferences().cancelIfAlreadyCasted
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().cancelIfAlreadyCasted = key
					end
				end,
			} --[[@as EPSettingOption]],
			-- {
			-- 	label = L["Hide or Cancel on Phase Change"],
			-- 	type = "checkBox",
			-- 	description = L["Reminders associated with combat log events in a certain phase will be cancelled or hidden when the phase transitions."],
			-- 	enabled = enableReminderOption,
			-- 	get = function()
			-- 		return GetReminderPreferences().removeDueToPhaseChange
			-- 	end,
			-- 	set = function(key)
			-- 		if type(key) == "boolean" then
			-- 			GetReminderPreferences().removeDueToPhaseChange = key
			-- 		end
			-- 	end,
			-- } --[[@as EPSettingOption]],
			{
				label = L["Glow Frame for Targeted Spells"],
				type = "checkBox",
				description = L["Glows the unit frame of the target at assignment time. If the assignment has a spell ID, the frame will glow until the spell is cast on the target, up to a maximum of 10 seconds. Otherwise, shows for 5 seconds."],
				enabled = enableReminderOption,
				get = function()
					return GetReminderPreferences().glowTargetFrame
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().glowTargetFrame = key
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Reminder Advance Notice"],
				type = "lineEdit",
				description = L["How far ahead of assignment time to begin showing reminders."],
				get = function()
					return tostring(GetReminderPreferences().advanceNotice)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetReminderPreferences().advanceNotice = value
						progressBarManager:AddProgressBarsOnTimer()
					end
				end,
				validate = function(value)
					local numericValue = tonumber(value)
					if numericValue then
						if numericValue > kMinAdvanceNotice and numericValue < kMaxAdvanceNotice then
							return true
						else
							return false, Clamp(numericValue, kMinAdvanceNotice, kMaxAdvanceNotice)
						end
					else
						return false, GetReminderPreferences().advanceNotice
					end
				end,
				enabled = enableReminderOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Enable Messages"],
				type = "checkBoxBesideButton",
				description = L["Whether to show Messages for assignments."],
				category = L["Messages"],
				get = function()
					return GetMessagePreferences().enabled
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetMessagePreferences()
						if key ~= preferences.enabled and key == false then
							preferences.enabled = false
							if messageAnchor and messageAnchor.frame:IsShown() then
								HideAnchor(false)
							end
						end
						preferences.enabled = key
					end
				end,
				enabled = enableReminderOption,
				buttonText = L["Toggle Message Anchor"],
				buttonEnabled = function()
					local preferences = GetReminderPreferences()
					return preferences.enabled == true and preferences.messages.enabled == true
				end,
				buttonCallback = function()
					if messageAnchor and messageAnchor.frame:IsShown() then
						HideAnchor(false)
					else
						ShowAnchor(false)
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Visibility"],
				type = "radioButtonGroup",
				description = L["Whether to show Messages only at expiration or show them for the duration of the countdown."],
				category = L["Messages"],
				values = {
					{ itemValue = "expirationOnly", text = L["Expiration Only"] },
					{ itemValue = "fullCountdown", text = L["With Countdown"] },
				},
				get = function()
					if GetMessagePreferences().showOnlyAtExpiration then
						return "expirationOnly"
					else
						return "fullCountdown"
					end
				end,
				set = function(key)
					local preferences = GetReminderPreferences()
					if key == "expirationOnly" then
						if preferences.messages.showOnlyAtExpiration ~= true then
							preferences.messages.showOnlyAtExpiration = true
							if messageAnchor and messageAnchor.frame:IsShown() then
								ShowAnchor(false)
							end
						end
					else -- if key == "fullCountdown" then
						if preferences.messages.showOnlyAtExpiration ~= false then
							preferences.messages.showOnlyAtExpiration = false
							if messageAnchor and messageAnchor.frame:IsShown() then
								ShowAnchor(false)
							end
						end
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Animation"],
				type = "checkBox",
				description = L["Whether to show a bounce animation when a Message first appears."],
				category = L["Messages"],
				get = function()
					return GetMessagePreferences().showAnimation
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetReminderPreferences()
						if key ~= preferences.messages.showAnimation then
							preferences.messages.showAnimation = key
							if messageAnchor and messageAnchor.frame:IsShown() then
								ShowAnchor(false)
							end
						end
						preferences.messages.showAnimation = key
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Position"],
				labels = { L["X"], L["Y"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The horizontal offset from the Relative Anchor Point to the Anchor Point."],
					L["The vertical offset from the Relative Anchor Point to the Anchor Point."],
				},
				category = L["Messages"],
				updateIndices = { 0, 1, 2, 3 },
				get = function()
					local preferences = GetMessagePreferences()
					return preferences.x, preferences.y
				end,
				set = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						local preferences = GetMessagePreferences()
						preferences.x = x
						preferences.y = y
						local regionName = IsValidRegionName(preferences.relativeTo) and preferences.relativeTo
							or "UIParent"
						if messageAnchor then
							messageAnchor.frame:SetPoint(preferences.point, regionName, preferences.relativePoint, x, y)
						end
					end
				end,
				enabled = enableMessageOption,
				validate = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						return true
					else
						local preferences = GetMessagePreferences()
						return false, preferences.x, preferences.y
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Order"],
				type = "radioButtonGroup",
				description = L["Whether to sort Messages by ascending or descending expiration time."],
				category = L["Messages"],
				values = sortingValues,
				get = function()
					return GetMessagePreferences().soonestExpirationOnBottom
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetMessagePreferences().soonestExpirationOnBottom = key
						if messageAnchor then
							messageAnchor.content.sortAscending = key
							messageAnchor:DoLayout()
						end
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Point"],
				type = "dropdown",
				description = L["Which spot on the Message container is fixed; Bottom will expand upwards, Top downwards, Left/Right/Center from center."],
				category = L["Messages"],
				values = anchorPointValues,
				updateIndices = { -1, 0, 1, 2 },
				get = function()
					return GetMessagePreferences().point
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						ApplyPointToAnchor(false, key, messages.relativeTo, messages.relativePoint)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Frame"],
				type = "frameChooser",
				description = L["The frame that the Message container is anchored to. Defaults to UIParent (screen)."],
				category = L["Messages"],
				updateIndices = { -2, -1, 0, 1 },
				get = function()
					return GetMessagePreferences().relativeTo
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						if messageAnchor and messageAnchor.frame:GetName() == key then
							key = messages.relativeTo
						end
						ApplyPointToAnchor(false, messages.point, key, messages.relativePoint)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Relative Anchor Point"],
				type = "dropdown",
				description = L["The anchor point on the frame that the Message container is anchored to."],
				category = L["Messages"],
				values = anchorPointValues,
				updateIndices = { -3, -2, -1, 0 },
				get = function()
					return GetMessagePreferences().relativePoint
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						ApplyPointToAnchor(false, messages.point, messages.relativeTo, key)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Messages"],
			} --[[@as EPSettingOption]],
			{
				label = L["Font"],
				type = "dropdown",
				description = L["Font to use for Message text."],
				category = L["Messages"],
				itemsAreFonts = true,
				values = fonts,
				get = function()
					return GetMessagePreferences().font
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetMessagePreferences()
						preferences.font = key
						CallMessageAnchorFunction(function(message)
							message:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
						end)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Size"],
				type = "lineEdit",
				description = L["Font size to use for Message text (8 - 64)."],
				category = L["Messages"],
				get = function()
					return GetMessagePreferences().fontSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						local preferences = GetMessagePreferences()
						preferences.fontSize = value
						CallMessageAnchorFunction(function(message)
							message:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
						end)
					end
				end,
				enabled = enableMessageOption,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kMinFontSize or value > kMaxFontSize then
							return false, Clamp(value, kMinFontSize, kMaxFontSize)
						else
							return true
						end
					else
						return false, GetMessagePreferences().fontSize
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Outline"],
				type = "dropdown",
				description = L["Font outline to use for Message text."],
				category = L["Messages"],
				values = fontOutlineValues,
				get = function()
					return GetMessagePreferences().fontOutline
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetMessagePreferences()
						preferences.fontOutline = key
						CallMessageAnchorFunction(function(message)
							message:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
						end)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Text Color"],
				type = "colorPicker",
				description = L["Text color to use for Message text."],
				category = L["Messages"],
				get = function()
					local r, g, b, a = unpack(GetMessagePreferences().textColor)
					return r, g, b, a
				end,
				set = function(r, g, b, a)
					if type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a) == "number" then
						GetMessagePreferences().textColor = { r, g, b, a }
						CallMessageAnchorFunction(function(message)
							message:SetTextColor(r, g, b, a)
						end)
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Transparency"],
				type = "lineEdit",
				description = L["Transparency of Messages (0.0 - 1.0)."],
				category = L["Messages"],
				get = function()
					return GetMessagePreferences().alpha
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetMessagePreferences().alpha = value
						CallMessageAnchorFunction(function(message)
							message:SetAlpha(value)
						end)
					end
				end,
				enabled = enableMessageOption,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kZero or value > kOne then
							return false, Clamp(value, kZero, kOne)
						else
							return true
						end
					else
						return false, GetMessagePreferences().alpha
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Enable Progress Bars"],
				type = "checkBoxBesideButton",
				description = L["Whether to show Progress Bars for assignments."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().enabled
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetProgressBarPreferences()
						if key ~= preferences.enabled and key == false then
							preferences.enabled = false
							if progressBarAnchor and progressBarAnchor.frame:IsShown() then
								HideAnchor(true)
							end
						end
						preferences.enabled = key
					end
				end,
				enabled = enableReminderOption,
				buttonText = L["Toggle Progress Bar Anchor"],
				buttonEnabled = enableProgressBarOption,
				buttonCallback = function()
					if progressBarAnchor and progressBarAnchor.frame:IsShown() then
						HideAnchor(true)
					else
						ShowAnchor(true)
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Position"],
				labels = { L["X"], L["Y"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The horizontal offset from the Relative Anchor Point to the Anchor Point."],
					L["The vertical offset from the Relative Anchor Point to the Anchor Point."],
				},
				category = L["Progress Bars"],
				updateIndices = { 0, 1, 2, 3 },
				get = function()
					return GetProgressBarPreferences().x, GetProgressBarPreferences().y
				end,
				set = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						local preferences = GetProgressBarPreferences()
						preferences.x, preferences.y = x, y
						local regionName = IsValidRegionName(preferences.relativeTo) and preferences.relativeTo
							or "UIParent"
						if progressBarAnchor then
							progressBarAnchor.frame:SetPoint(
								preferences.point,
								regionName,
								preferences.relativePoint,
								x,
								y
							)
						end
					end
				end,
				enabled = enableProgressBarOption,
				validate = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						return true
					else
						local preferences = GetProgressBarPreferences()
						return false, preferences.x, preferences.y
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Order"],
				type = "radioButtonGroup",
				description = L["Whether to sort Messages by ascending or descending expiration time."],
				category = L["Progress Bars"],
				values = sortingValues,
				get = function()
					return GetProgressBarPreferences().soonestExpirationOnBottom
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetProgressBarPreferences().soonestExpirationOnBottom = key
						if progressBarAnchor then
							progressBarAnchor.content.sortAscending = key
							progressBarAnchor:DoLayout()
						end
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Point"],
				type = "dropdown",
				description = L["Which spot on the Progress Bar container is fixed; Bottom will expand upwards, Top downwards, Left/Right/Center from center."],
				category = L["Progress Bars"],
				values = anchorPointValues,
				updateIndices = { -1, 0, 1, 2 },
				get = function()
					return GetProgressBarPreferences().point
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						ApplyPointToAnchor(true, key, preferences.relativeTo, preferences.relativePoint)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Frame"],
				type = "frameChooser",
				description = L["The frame that the Progress Bar container is anchored to. Defaults to UIParent (screen)."],
				category = L["Progress Bars"],
				updateIndices = { -2, -1, 0, 1 },
				get = function()
					return GetProgressBarPreferences().relativeTo
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						if progressBarAnchor and progressBarAnchor.frame:GetName() == key then
							key = preferences.relativeTo
						end
						ApplyPointToAnchor(true, preferences.point, key, preferences.relativePoint)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Relative Anchor Point"],
				type = "dropdown",
				description = L["The anchor point on the frame that the Progress Bar container is anchored to."],
				category = L["Progress Bars"],
				values = anchorPointValues,
				updateIndices = { -3, -2, -1, 0 },
				get = function()
					return GetProgressBarPreferences().relativePoint
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						ApplyPointToAnchor(true, preferences.point, preferences.relativeTo, key)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Progress Bars"],
			} --[[@as EPSettingOption]],
			{
				label = L["Font"],
				type = "dropdown",
				itemsAreFonts = true,
				description = L["Font to use for Progress Bar text."],
				category = L["Progress Bars"],
				values = fonts,
				get = function()
					return GetProgressBarPreferences().font
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						preferences.font = key
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
							progressBar:SetIconAndText(
								[[Interface\Icons\INV_MISC_QUESTIONMARK]],
								L["Progress Bar Text"]
							)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Size"],
				type = "lineEdit",
				description = L["Font size to use for Progress Bar text (8 - 64)."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().fontSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						local preferences = GetProgressBarPreferences()
						preferences.fontSize = value
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
						end)
					end
				end,
				enabled = enableProgressBarOption,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kMinFontSize or value > kMaxFontSize then
							return false, Clamp(value, kMinFontSize, kMaxFontSize)
						else
							return true
						end
					else
						return false, GetProgressBarPreferences().fontSize
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Outline"],
				type = "dropdown",
				description = L["Font outline to use for Progress Bar text."],
				category = L["Progress Bars"],
				values = fontOutlineValues,
				get = function()
					return GetProgressBarPreferences().fontOutline
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						preferences.fontOutline = key
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Progress Bars"],
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Position"],
				type = "radioButtonGroup",
				description = L["Which side to place the icon for Progress Bars."],
				category = L["Progress Bars"],
				values = { { itemValue = "LEFT", text = L["Left"] }, { itemValue = "RIGHT", text = L["Right"] } },
				get = function()
					return GetProgressBarPreferences().iconPosition
				end,
				set = function(key)
					if type(key) == "string" then
						GetProgressBarPreferences().iconPosition = key
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetIconPosition(key)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Duration Position"],
				type = "radioButtonGroup",
				description = L["Position of Progress Bar duration text."],
				category = L["Progress Bars"],
				values = {
					{ itemValue = "LEFT", text = L["Left"] },
					{ itemValue = "RIGHT", text = L["Right"] },
				},
				get = function()
					return GetProgressBarPreferences().durationAlignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetProgressBarPreferences().durationAlignment = key
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetDurationTextAlignment(key)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Progress Type"],
				type = "radioButtonGroup",
				description = L["Whether to fill or drain Progress Bars."],
				category = L["Progress Bars"],
				values = { { itemValue = "fill", text = L["Fill"] }, { itemValue = "drain", text = L["Drain"] } },
				get = function()
					if GetProgressBarPreferences().fill == true then
						return "fill"
					else
						return "drain"
					end
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						if key == "fill" then
							preferences.fill = true
						else
							preferences.fill = false
						end
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetFill(preferences.fill)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Progress Bars"],
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Size"],
				labels = { L["Width"], L["Height"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The width of Progress Bars."],
					L["The height of Progress Bars."],
				},
				category = L["Progress Bars"],
				get = function()
					local preferences = GetProgressBarPreferences()
					return preferences.width, preferences.height
				end,
				set = function(key, key2)
					local width = tonumber(key)
					local height = tonumber(key2)
					if width and height then
						local preferences = GetProgressBarPreferences()
						preferences.width = width
						preferences.height = height
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetProgressBarSize(preferences.width, preferences.height)
						end)
					end
				end,
				enabled = enableProgressBarOption,
				validate = function(key, key2)
					local preferences = GetProgressBarPreferences()
					local width = tonumber(key)
					local height = tonumber(key2)
					if width and height then
						local minProgressBarHeight = preferences.fontSize
						if
							width < 0.0
							or width > kMaxProgressBarWidth
							or height < minProgressBarHeight
							or height > kMaxProgressBarHeight
						then
							return false,
								Clamp(width, 0.0, kMaxProgressBarWidth),
								Clamp(height, minProgressBarHeight, kMaxProgressBarHeight)
						else
							return true
						end
					else
						return false, preferences.width, preferences.height
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Texture"],
				type = "dropdown",
				description = L["The texture to use for the Progress Bar foreground and background."],
				category = L["Progress Bars"],
				values = statusBarTextures,
				get = function()
					return GetProgressBarPreferences().texture
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetProgressBarPreferences()
						preferences.texture = key
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetTexture(preferences.texture, preferences.color, preferences.backgroundColor)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Color"],
				labels = { L["Foreground"], L["Background"] },
				type = "doubleColorPicker",
				descriptions = {
					L["Foreground color for Progress Bars."],
					L["Background color for Progress Bars."],
				},
				category = L["Progress Bars"],
				get = {
					function()
						local r, g, b, a = unpack(GetProgressBarPreferences().color)
						return r, g, b, a
					end,
					function()
						local r, g, b, a = unpack(GetProgressBarPreferences().backgroundColor)
						return r, g, b, a
					end,
				},
				set = {
					function(r, g, b, a)
						if
							type(r) == "number"
							and type(g) == "number"
							and type(b) == "number"
							and type(a) == "number"
						then
							GetProgressBarPreferences().color = { r, g, b, a }
							CallProgressBarAnchorFunction(function(progressBar)
								progressBar:SetColor(r, g, b, a)
							end)
						end
					end,
					function(r, g, b, a)
						if
							type(r) == "number"
							and type(g) == "number"
							and type(b) == "number"
							and type(a) == "number"
						then
							GetProgressBarPreferences().backgroundColor = { r, g, b, a }
							CallProgressBarAnchorFunction(function(progressBar)
								progressBar:SetBackgroundColor(r, g, b, a)
							end)
						end
					end,
				},
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Transparency"],
				type = "lineEdit",
				description = L["Transparency of Progress Bars (0.0 - 1.0)."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().alpha
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetProgressBarPreferences().alpha = value
						CallProgressBarAnchorFunction(function(progressBar)
							progressBar:SetAlpha(value)
						end)
					end
				end,
				enabled = enableProgressBarOption,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kZero or value > kOne then
							return false, Clamp(value, kZero, kOne)
						else
							return true
						end
					end
					return false, GetProgressBarPreferences().alpha
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Border"],
				labels = { L["Show Border"], L["Show Icon Border"] },
				type = "doubleCheckBox",
				descriptions = {
					L["Whether to show a 1px border around Progress Bars."],
					L["Whether to show a 1px border around Progress Bar icons."],
				},
				category = L["Progress Bars"],
				get = {
					function()
						return GetProgressBarPreferences().showBorder
					end,
					function()
						return GetProgressBarPreferences().showIconBorder
					end,
				},
				set = {
					function(key)
						if type(key) == "boolean" then
							GetProgressBarPreferences().showBorder = key
							CallProgressBarAnchorFunction(function(progressBar)
								progressBar:SetShowBorder(key)
							end)
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetProgressBarPreferences().showIconBorder = key
							CallProgressBarAnchorFunction(function(progressBar)
								progressBar:SetShowIconBorder(key)
							end)
						end
					end,
				},
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Spacing"],
				type = "lineEdit",
				description = L["Spacing between Progress Bars (-1 - 100)."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().spacing
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetProgressBarPreferences().spacing = value
						if progressBarAnchor then
							progressBarAnchor:SetSpacing(0, value)
							progressBarAnchor:DoLayout()
						end
					end
				end,
				enabled = enableProgressBarOption,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kMinSpacing or value > kMaxSpacing then
							return false, Clamp(value, kMinSpacing, kMaxSpacing)
						else
							return true
						end
					end
					return false, GetProgressBarPreferences().spacing
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Play Text to Speech at Advance Notice"],
				type = "checkBox",
				description = L["Whether to play text to speech sound at advance notice time (i.e. Spell in x seconds)."],
				category = L["Text to Speech"],
				get = function()
					return GetReminderPreferences().textToSpeech.enableAtAdvanceNotice
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().textToSpeech.enableAtAdvanceNotice = key
					end
				end,
				enabled = enableReminderOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Play Text to Speech at Assignment Time"],
				type = "checkBox",
				description = L["Whether to play text to speech sound at assignment time (i.e. Spell in x seconds)."],
				category = L["Text to Speech"],
				get = function()
					return GetReminderPreferences().textToSpeech.enableAtTime
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().textToSpeech.enableAtTime = key
					end
				end,
				enabled = enableReminderOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Text to Speech Voice"],
				type = "dropdown",
				description = L["The voice to use for Text to Speech."],
				category = L["Text to Speech"],
				values = voices,
				get = function()
					return GetReminderPreferences().textToSpeech.voiceID
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetReminderPreferences().textToSpeech.voiceID = value
					end
				end,
				enabled = function()
					local preferences = GetReminderPreferences()
					return preferences.enabled == true
						and (preferences.textToSpeech.enableAtTime or preferences.textToSpeech.enableAtAdvanceNotice)
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Text to Speech Volume"],
				type = "lineEdit",
				description = L["The volume to use for Text to Speech."],
				category = L["Text to Speech"],
				get = function()
					return tostring(GetReminderPreferences().textToSpeech.volume)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetReminderPreferences().textToSpeech.volume = value
					end
				end,
				enabled = function()
					local preferences = GetReminderPreferences()
					return preferences.enabled == true
						and (preferences.textToSpeech.enableAtTime or preferences.textToSpeech.enableAtAdvanceNotice)
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kZero or value > kMaxVolume then
							return false, Clamp(value, kZero, kMaxVolume)
						else
							return true
						end
					else
						return false, GetReminderPreferences().textToSpeech.volume
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Play Sound at Advance Notice"],
				labels = { L["Play Sound at Advance Notice"], L["Sound to Play at Advance Notice"] },
				type = "checkBoxWithDropdown",
				descriptions = {
					L["Whether to play a sound at advance notice time."],
					L["The sound to play at advance notice time."],
				},
				category = L["Sound"],
				values = sounds,
				get = {
					function()
						return GetReminderPreferences().sound.enableAtAdvanceNotice
					end,
					function()
						return GetReminderPreferences().sound.advanceNoticeSound
					end,
				},
				set = {
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.enableAtAdvanceNotice = key
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.advanceNoticeSound = key
						end
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						local preferences = GetReminderPreferences()
						return preferences.enabled == true and preferences.sound.enableAtAdvanceNotice == true
					end,
				},
			} --[[@as EPSettingOption]],
			{
				label = L["Play Sound at Assignment Time"],
				labels = { L["Play Sound at Assignment Time"], L["Sound to Play at Assignment Time"] },
				type = "checkBoxWithDropdown",
				descriptions = {
					L["Whether to play a sound at assignment time."],
					L["The sound to play at assignment time."],
				},
				category = L["Sound"],
				values = sounds,
				get = {
					function()
						return GetReminderPreferences().sound.enableAtTime
					end,
					function()
						return GetReminderPreferences().sound.atSound
					end,
				},
				set = {
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.enableAtTime = key
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.atSound = key
						end
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						local preferences = GetReminderPreferences()
						return preferences.enabled == true and preferences.sound.enableAtTime == true
					end,
				},
			} --[[@as EPSettingOption]],
			{
				label = L["Clear Trusted Characters"],
				category = L["Other"],
				type = "centeredButton",
				get = function()
					return ""
				end,
				set = function() end,
				description = L["Clears all saved trusted characters. You will see a confirmation dialogue each time a non-trusted character sends a plan to you."],
				enabled = function()
					return #AddOn.db.profile.trustedCharacters > 0
				end,
				buttonCallback = function()
					wipe(AddOn.db.profile.trustedCharacters)
				end,
			} --[[@as EPSettingOption]],
		}
	end

	---@return table<integer, EPSettingOption>
	local function CreateViewOptions()
		return {
			{
				label = L["Preferred Number of Assignments to Show"],
				type = "dropdown",
				description = L["The assignment timeline will attempt to expand or shrink to show this many rows."],
				values = rowValues,
				get = function()
					return GetPreferences().timelineRows.numberOfAssignmentsToShow
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.numberOfAssignmentsToShow = value
						local timeline = Private.mainFrame.timeline
						if timeline then
							timeline:UpdateHeightFromAssignments()
							Private.mainFrame:DoLayout()
						end
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Preferred Number of Boss Abilities to Show"],
				type = "dropdown",
				description = L["The boss ability timeline will attempt to expand or shrink to show this many rows."],
				values = rowValues,
				get = function()
					return GetPreferences().timelineRows.numberOfBossAbilitiesToShow
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.numberOfBossAbilitiesToShow = value
						local timeline = Private.mainFrame.timeline
						if timeline then
							timeline:UpdateHeightFromBossAbilities()
							Private.mainFrame:DoLayout()
						end
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Timeline Zoom Center"],
				type = "radioButtonGroup",
				description = L["Where to center the zoom when zooming in on the timeline."],
				category = L["Assignment"],
				values = {
					{ itemValue = "At cursor", text = L["At cursor"] },
					{ itemValue = "Middle of timeline", text = L["Middle of timeline"] },
				},
				get = function()
					if GetPreferences().zoomCenteredOnCursor == true then
						return "At cursor"
					else
						return "Middle of timeline"
					end
				end,
				set = function(key)
					if type(key) == "string" then
						if key == "At cursor" then
							GetPreferences().zoomCenteredOnCursor = true
						else
							GetPreferences().zoomCenteredOnCursor = false
						end
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Assignment Sort Priority"],
				type = "dropdown",
				description = L["Sorts the rows of the assignment timeline."],
				category = L["Assignment"],
				values = {
					{ itemValue = "Alphabetical", text = L["Alphabetical"] },
					{ itemValue = "First Appearance", text = L["First Appearance"] },
					{ itemValue = "Role > Alphabetical", text = L["Role > Alphabetical"] },
					{ itemValue = "Role > First Appearance", text = L["Role > First Appearance"] },
				},
				get = function()
					return GetPreferences().assignmentSortType
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetPreferences()
						if key ~= preferences.assignmentSortType then
							preferences.assignmentSortType = key
							if Private.mainFrame and Private.mainFrame.bossLabel then
								local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
								if bossDungeonEncounterID then
									UpdateAllAssignments(false, bossDungeonEncounterID)
								end
							end
						end
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Show Spell Cooldown Duration"],
				type = "checkBox",
				description = L["Whether to show textures representing player spell cooldown durations."],
				category = L["Assignment"],
				get = function()
					return GetPreferences().showSpellCooldownDuration
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetPreferences()
						if key ~= preferences.showSpellCooldownDuration then
							preferences.showSpellCooldownDuration = key
							if Private.mainFrame and Private.mainFrame.timeline then
								Private.mainFrame.timeline:UpdateTimeline()
							end
						end
					end
				end,
			} --[[@as EPSettingOption]],
		}
	end

	---@return table<integer, EPSettingOption>
	local function CreateProfileOptions()
		return {
			{
				label = L["Current Profile"],
				type = "dropdownBesideButton",
				category = L["Profile"],
				description = L["Select the currently active profile."],
				values = function()
					return GetProfiles(false)
				end,
				get = function()
					return GetCurrentProfile()
				end,
				set = function(value)
					if type(value) == "string" then
						SetProfile(value)
					end
				end,
				buttonText = L["Reset Profile"],
				buttonDescription = L["Displays a confirmation dialog, and if confirmed, resets the Current Profile to default."],
				buttonCallback = ResetProfile,
				confirm = true,
				confirmText = function()
					return format("%s %s?", L["Are you sure you want to reset"], GetCurrentProfile())
				end,
				updateIndices = { 0, 1, 2, 3 },
			} --[[@as EPSettingOption]],
			{
				label = L["New"],
				type = "lineEdit",
				category = L["Profile"],
				description = L["Creates a new empty profile and switches to it."],
				get = function()
					return ""
				end,
				set = function(value)
					if type(value) == "string" then
						value = value:gsub("%s+", "")
						if value:len() > 0 then
							SetProfile(value)
						end
					end
				end,
				updateIndices = { -1, 0, 1, 2 },
			} --[[@as EPSettingOption]],
			{
				label = L["Copy From"],
				type = "dropdown",
				neverShowItemsAsSelected = true,
				category = L["Profile"],
				description = L["Copies the settings from an existing profile into the Current Profile."],
				values = function()
					return GetProfiles(true)
				end,
				get = function()
					return false
				end,
				set = function(value)
					if type(value) == "string" then
						CopyProfile(value)
					end
				end,
				enabled = function()
					return #GetProfiles(true) > 0
				end,
				updateIndices = { -2, -1, 0, 1 },
			} --[[@as EPSettingOption]],
			{
				label = L["Delete a Profile"],
				type = "dropdown",
				neverShowItemsAsSelected = true,
				category = L["Profile"],
				description = L["Displays a confirmation dialog, and if confirmed, deletes the selected profile from the database."],
				values = function()
					return GetProfiles(true)
				end,
				get = function()
					return false
				end,
				set = function(value)
					if type(value) == "string" then
						DeleteProfile(value)
					end
				end,
				enabled = function()
					return #GetProfiles(true) > 0
				end,
				confirm = true,
				confirmText = function(arg)
					return format("%s %s?", L["Are you sure you want to delete"], arg)
				end,
				updateIndices = { -3, -2, -1, 0 },
			} --[[@as EPSettingOption]],
		}
	end

	local function GetCooldownOverrideOptions()
		return {
			{
				label = L["Cooldown Overrides"],
				type = "cooldownOverrides",
				description = L["Override the default cooldown of player spells."],
				get = function()
					return AddOn.db.profile.cooldownOverrides
				end,
				set = function(value)
					if type(value) == "table" then
						AddOn.db.profile.cooldownOverrides = value
						if Private.mainFrame and Private.mainFrame.bossLabel then
							local bossDungeonEncounterID = Private.mainFrame.bossLabel:GetValue()
							if bossDungeonEncounterID then
								UpdateAllAssignments(false, bossDungeonEncounterID)
							end
						end
					end
				end,
			} --[[@as EPSettingOption]],
		}
	end

	function optionCreator.GetOrCreateOptions()
		if not sounds then
			sounds = IterateHashTable("sound")
		end
		if not fonts then
			fonts = IterateHashTable("font")
		end
		if not statusBarTextures then
			statusBarTextures = IterateHashTable("statusbar")
		end
		if not voices then
			voices = {}
			for _, ttsVoiceTable in pairs(GetTtsVoices()) do
				tinsert(voices, { itemValue = ttsVoiceTable.voiceID, text = ttsVoiceTable.name })
			end
			sort(voices, sortFunc)
		end

		if not cooldownOverrideOptions then
			cooldownOverrideOptions = GetCooldownOverrideOptions()
		end
		if not keyBindingOptions then
			keyBindingOptions = CreateKeyBindingOptions()
		end
		if not reminderOptions then
			reminderOptions = CreateReminderOptions()
		end
		if not viewOptions then
			viewOptions = CreateViewOptions()
		end
		if not profileOptions then
			profileOptions = CreateProfileOptions()
		end

		local cooldownOverrideTab = { L["Cooldown Overrides"], cooldownOverrideOptions }
		local keyBindingsTab = { L["Keybindings"], keyBindingOptions, { L["Assignment"], L["Timeline"] } }
		local reminderTabs = { L["Messages"], L["Progress Bars"], L["Text to Speech"], L["Sound"], L["Other"] }
		local reminderTab = { L["Reminder"], reminderOptions, reminderTabs }
		local viewTab = { L["View"], viewOptions, { L["Assignment"] } }
		local profileTab = { L["Profile"], profileOptions, { L["Profile"] } }

		return cooldownOverrideTab, keyBindingsTab, reminderTab, viewTab, profileTab
	end
end

-- Creates and shows the options menu. The message anchor and progress bar anchor are released when the options menu is
-- released.
function Private:CreateOptionsMenu()
	local optionsMenu = AceGUI:Create("EPOptions")
	optionsMenu.spellDropdownItems = utilities.GetOrCreateSpellDropdownItems().dropdownItemMenuData
	optionsMenu.FormatTime = utilities.FormatTime
	optionsMenu.GetSpellCooldown = utilities.GetSpellCooldown
	optionsMenu.frame:SetParent(UIParent)
	optionsMenu.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	optionsMenu.frame:SetFrameLevel(kOptionsMenuFrameLevel)
	optionsMenu:SetCallback("OnRelease", function()
		GetPreferences().lastOpenTab = Private.optionsMenu.activeTab
		if messageAnchor then
			messageAnchor:Release()
		end
		if progressBarAnchor then
			progressBarAnchor:Release()
		end
		messageAnchor = nil
		progressBarAnchor = nil
		Private.optionsMenu = nil
	end)

	messageAnchor = CreateMessageAnchor()
	messageAnchor.frame:Hide()

	progressBarAnchor = CreateProgressBarAnchor()
	progressBarAnchor.frame:Hide()

	local cooldownOverrideTab, keyBindingsTab, reminderTab, viewTab, profileTab = optionCreator.GetOrCreateOptions()
	optionsMenu:AddOptionTab(unpack(cooldownOverrideTab))
	optionsMenu:AddOptionTab(unpack(keyBindingsTab))
	optionsMenu:AddOptionTab(unpack(reminderTab))
	optionsMenu:AddOptionTab(unpack(viewTab))
	optionsMenu:AddOptionTab(unpack(profileTab))
	optionsMenu:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	optionsMenu:SetCurrentTab(GetPreferences().lastOpenTab or L["Cooldown Overrides"])
	optionsMenu:SetPoint("TOP", UIParent, "TOP", 0, -optionsMenu.frame:GetBottom())

	Private.optionsMenu = optionsMenu
end

function Private:RecreateAnchors()
	if Private.optionsMenu then
		messageAnchor = CreateMessageAnchor()
		messageAnchor.frame:Hide()

		progressBarAnchor = CreateProgressBarAnchor()
		progressBarAnchor.frame:Hide()
	end
end

function Private:CloseAnchors()
	if messageAnchor then
		messageAnchor:Release()
	end
	if progressBarAnchor then
		progressBarAnchor:Release()
	end
end

function OptionsModule:OnInitialize()
	local options = {
		name = AddOnName,
		type = "group",
		width = "full",
		args = {
			[""] = {
				name = L["Open Preferences"],
				type = "execute",
				width = "full",
				order = 0,
				func = function()
					if not Private.optionsMenu then
						Private:CreateOptionsMenu()
					end
				end,
			},
		},
	}
	ACR:RegisterOptionsTable(AddOnName, options)
	ACD:SetDefaultSize(AddOnName, 700, 500)
	ACD:AddToBlizOptions(AddOnName)
end

function OptionsModule:OpenOptions()
	ACD:Open(AddOnName)
end
