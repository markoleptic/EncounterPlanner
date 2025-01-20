local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class OptionsModule : AceModule
local OptionsModule = Private.addOn.optionsModule

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn
local L = Private.L
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local GetTtsVoices = C_VoiceChat.GetTtsVoices
local pairs = pairs
local sort = sort
local tinsert = tinsert
local tostring = tostring
local tonumber = tonumber
local type = type
local unpack = unpack

local previewDuration = 15.0

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
	{ itemValue = "1", text = "1" },
	{ itemValue = "2", text = "2" },
	{ itemValue = "3", text = "3" },
	{ itemValue = "4", text = "4" },
	{ itemValue = "5", text = "5" },
	{ itemValue = "6", text = "6" },
	{ itemValue = "7", text = "7" },
	{ itemValue = "8", text = "8" },
	{ itemValue = "9", text = "9" },
	{ itemValue = "10", text = "10" },
	{ itemValue = "11", text = "11" },
	{ itemValue = "12", text = "12" },
}

local textAlignmentValues = {
	{ itemValue = "LEFT", text = L["Left"] },
	{ itemValue = "CENTER", text = L["Center"] },
	{ itemValue = "RIGHT", text = L["Right"] },
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
	local relativeFrame = utilities.IsValidRegionName(regionName) and _G[regionName] or rF
	relativePoint = relativePoint or rP
	local left, top, width, height = frame:GetLeft(), frame:GetTop(), frame:GetWidth(), frame:GetHeight()
	local rLeft, rTop, rWidth, rHeight =
		relativeFrame:GetLeft(), relativeFrame:GetTop(), relativeFrame:GetWidth(), relativeFrame:GetHeight()

	local x, y = CalculateNewOffset(left, top, width, height, point, rLeft, rTop, rWidth, rHeight, relativePoint)
	x = utilities.Round(x, 2)
	y = utilities.Round(y, 2)

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

---@return EPProgressBar
local function CreateProgressBarAnchor()
	local progressBarAnchor = AceGUI:Create("EPProgressBar")
	progressBarAnchor.frame:SetParent(UIParent)

	do
		local preferences = GetProgressBarPreferences()
		local point, regionName, relativePoint = preferences.point, preferences.relativeTo, preferences.relativePoint
		regionName = utilities.IsValidRegionName(regionName) and regionName or "UIParent"
		progressBarAnchor.frame:SetPoint(point, regionName, relativePoint, preferences.x, preferences.y)
		progressBarAnchor:SetAnchorMode(true)
		progressBarAnchor:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
		progressBarAnchor:SetShowBorder(preferences.showBorder)
		progressBarAnchor:SetShowIconBorder(preferences.showIconBorder)
		progressBarAnchor:SetHorizontalTextAlignment(preferences.textAlignment)
		progressBarAnchor:SetDurationTextAlignment(preferences.durationAlignment)
		progressBarAnchor:SetTexture(preferences.texture)
		progressBarAnchor:SetIconPosition(preferences.iconPosition)
		progressBarAnchor:SetIconAndText([[Interface\Icons\INV_MISC_QUESTIONMARK]], L["Progress Bar Text"])
		progressBarAnchor:SetColor(unpack(preferences.color))
		progressBarAnchor:SetBackgroundColor(unpack(preferences.backgroundColor))
		progressBarAnchor:SetProgressBarWidth(preferences.width)
		progressBarAnchor:SetFill(preferences.fill)
		progressBarAnchor:SetAlpha(preferences.alpha)
		progressBarAnchor:SetDuration(previewDuration)
	end

	progressBarAnchor:SetCallback("OnRelease", function()
		Private.progressBarAnchor = nil
	end)
	progressBarAnchor:SetCallback("NewPoint", function(_, _, point, regionName, relativePoint)
		local preferences = GetProgressBarPreferences()
		preferences.point, preferences.relativeTo, preferences.relativePoint, preferences.x, preferences.y =
			ApplyPoint(Private.progressBarAnchor.frame, point, regionName, relativePoint)
		if Private.optionsMenu then
			Private.optionsMenu:UpdateOptions()
		end
	end)
	progressBarAnchor:SetCallback("Completed", function()
		progressBarAnchor:SetDuration(previewDuration)
		progressBarAnchor:Start()
	end)

	return progressBarAnchor
end

---@return EPReminderMessage
local function CreateMessageAnchor()
	local messageAnchor = AceGUI:Create("EPReminderMessage")
	messageAnchor.frame:SetParent(UIParent)

	do
		local preferences = GetMessagePreferences()
		local point, regionName, relativePoint = preferences.point, preferences.relativeTo, preferences.relativePoint
		regionName = utilities.IsValidRegionName(regionName) and regionName or "UIParent"
		messageAnchor.frame:SetPoint(point, regionName, relativePoint, preferences.x, preferences.y)
		messageAnchor:SetAnchorMode(true)
		messageAnchor:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
		messageAnchor:SetIcon([[Interface\Icons\INV_MISC_QUESTIONMARK]])
		messageAnchor:SetAlpha(preferences.alpha)
		messageAnchor:SetTextColor(unpack(preferences.textColor))
	end

	messageAnchor:SetCallback("OnRelease", function()
		Private.messageAnchor = nil
	end)
	messageAnchor:SetCallback("NewPoint", function(_, _, point, relativeFrame, relativePoint)
		local preferences = GetMessagePreferences()
		preferences.point, preferences.relativeTo, preferences.relativePoint, preferences.x, preferences.y =
			ApplyPoint(Private.messageAnchor.frame, point, relativeFrame, relativePoint)
		if Private.optionsMenu then
			Private.optionsMenu:UpdateOptions()
		end
	end)
	messageAnchor:SetCallback("Completed", function()
		messageAnchor:SetDuration(previewDuration)
		messageAnchor:Start(true)
	end)

	return messageAnchor
end

do
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
					if
						GetPreferences().keyBindings.editAssignment == key
						or GetPreferences().keyBindings.newAssignment == key
					then
						return false, GetPreferences().keyBindings.pan
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
					if GetPreferences().keyBindings.zoom == key then
						return false, GetPreferences().keyBindings.scroll
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
					if GetPreferences().keyBindings.scroll == key then
						return false, GetPreferences().keyBindings.zoom
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
					if GetPreferences().keyBindings.pan == key then
						return false, GetPreferences().keyBindings.newAssignment
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
					if GetPreferences().keyBindings.pan == key then
						return false, GetPreferences().keyBindings.editAssignment
					elseif GetPreferences().keyBindings.duplicateAssignment == key then
						return false, GetPreferences().keyBindings.editAssignment
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
					if GetPreferences().keyBindings.editAssignment == key then
						return false, GetPreferences().keyBindings.duplicateAssignment
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
						if key ~= GetReminderPreferences().enabled then
							if key == true then
								Private:RegisterReminderEvents()
							else
								Private:UnregisterReminderEvents()
								if Private.messageAnchor.frame:IsShown() then
									Private.messageAnchor:Pause()
									Private.messageAnchor.frame:Hide()
								end
								if Private.progressBarAnchor.frame:IsShown() then
									Private.progressBarAnchor:Pause()
									Private.progressBarAnchor.frame:Hide()
								end
							end
						end
						GetReminderPreferences().enabled = key
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
			{
				label = L["Hide or Cancel on Phase Change"],
				type = "checkBox",
				description = L["Reminders associated with combat log events in a certain phase will be cancelled or hidden when the phase transitions."],
				enabled = enableReminderOption,
				get = function()
					return GetReminderPreferences().removeDueToPhaseChange
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().removeDueToPhaseChange = key
					end
				end,
			} --[[@as EPSettingOption]],
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
				category = nil,
				values = nil,
				get = function()
					return tostring(GetReminderPreferences().advanceNotice)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetReminderPreferences().advanceNotice = value
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
						if key ~= GetMessagePreferences().enabled and key == false then
							if Private.messageAnchor.frame:IsShown() then
								Private.messageAnchor:Pause()
								Private.messageAnchor.frame:Hide()
							end
						end
						GetMessagePreferences().enabled = key
					end
				end,
				enabled = enableReminderOption,
				buttonText = L["Toggle Message Anchor"],
				buttonEnabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
				buttonCallback = function()
					if Private.messageAnchor.frame:IsShown() then
						Private.messageAnchor:Pause()
						Private.messageAnchor.frame:Hide()
					else
						if not GetMessagePreferences().showOnlyAtExpiration then
							Private.messageAnchor:SetDuration(previewDuration)
							Private.messageAnchor:Start(true)
						end
						Private.messageAnchor.frame:Show()
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Visibility"],
				type = "radioButtonGroup",
				description = L["When to show Messages only at expiration or show them for the duration of the countdown."],
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
					local preferences = GetMessagePreferences()
					if key == "expirationOnly" then
						if preferences.showOnlyAtExpiration ~= true then
							if Private.messageAnchor.frame:IsShown() then
								Private.messageAnchor:Pause()
							end
							Private.messageAnchor:SetDuration(0)
						end
						preferences.showOnlyAtExpiration = true
					else -- if key == "fullCountdown" then
						if preferences.showOnlyAtExpiration ~= false then
							Private.messageAnchor:SetDuration(previewDuration)
							if Private.messageAnchor.frame:IsShown() then
								Private.messageAnchor:Start(true)
							end
						end
						preferences.showOnlyAtExpiration = false
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Point"],
				type = "dropdown",
				description = L['Anchor point of the Message frame, or the "spot" on the Message frame that will be placed relative to another frame.'],
				category = L["Messages"],
				values = anchorPointValues,
				updateIndices = { 0, 1, 2, 3 },
				get = function()
					return GetMessagePreferences().point
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
							ApplyPoint(Private.messageAnchor.frame, key, messages.relativeTo, messages.relativePoint)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Frame"],
				type = "frameChooser",
				description = L["The frame that the Message frame is anchored to. Defaults to UIParent (screen)."],
				category = L["Messages"],
				updateIndices = { -1, 0, 1, 2 },
				get = function()
					return GetMessagePreferences().relativeTo
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
							ApplyPoint(Private.messageAnchor.frame, messages.point, key, messages.relativePoint)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Relative Anchor Point"],
				type = "dropdown",
				description = L["The anchor point on the frame that the Message frame is anchored to."],
				category = L["Messages"],
				values = anchorPointValues,
				updateIndices = { -2, -1, 0, 1 },
				get = function()
					return GetMessagePreferences().relativePoint
				end,
				set = function(key)
					if type(key) == "string" then
						local messages = GetMessagePreferences()
						messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
							ApplyPoint(Private.messageAnchor.frame, messages.point, messages.relativeTo, key)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Position"],
				labels = { L["X"], L["Y"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The horizontal offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."],
					L["The vertical offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."],
				},
				category = L["Messages"],
				values = anchorPointValues,
				updateIndices = { -3, -2, -1, 0 },
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
						local regionName = utilities.IsValidRegionName(preferences.relativeTo)
								and preferences.relativeTo
							or "UIParent"
						Private.messageAnchor.frame:SetPoint(
							preferences.point,
							regionName,
							preferences.relativePoint,
							x,
							y
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
				validate = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						return true
					end
					return false, GetMessagePreferences().x, GetMessagePreferences().y
				end,
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
				values = fonts,
				get = function()
					return GetMessagePreferences().font
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetMessagePreferences()
						preferences.font = key
						Private.messageAnchor:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Size"],
				type = "lineEdit",
				description = L["Font size to use for Message text (8 - 48)."],
				category = L["Messages"],
				get = function()
					return GetMessagePreferences().fontSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						local preferences = GetMessagePreferences()
						preferences.fontSize = value
						Private.messageAnchor:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 8 or value > 48 then
							return false, utilities.Clamp(value, 8, 48)
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
						Private.messageAnchor:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
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
						Private.messageAnchor:SetTextColor(r, g, b, a)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Alpha"],
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
						Private.messageAnchor:SetAlpha(value)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetMessagePreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 0.0 or value > 1.0 then
							return false, utilities.Clamp(value, 0.0, 1.0)
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
						if key ~= GetProgressBarPreferences().enabled and key == false then
							if Private.progressBarAnchor.frame:IsShown() then
								Private.progressBarAnchor:Pause()
								Private.progressBarAnchor.frame:Hide()
							end
						end
						GetProgressBarPreferences().enabled = key
					end
				end,
				enabled = enableReminderOption,
				buttonText = L["Toggle Progress Bar Anchor"],
				buttonEnabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				buttonCallback = function()
					if Private.progressBarAnchor.frame:IsShown() then
						Private.progressBarAnchor:Pause()
						Private.progressBarAnchor.frame:Hide()
					else
						Private.progressBarAnchor:SetDuration(previewDuration)
						Private.progressBarAnchor:Start()
						Private.progressBarAnchor.frame:Show()
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Point"],
				type = "dropdown",
				description = L['Anchor point of the Progress Bars frame, or the "spot" on the Progress Bars frame that will be placed relative to another frame.'],
				category = L["Progress Bars"],
				values = anchorPointValues,
				updateIndices = { 0, 1, 2, 3 },
				get = function()
					return GetProgressBarPreferences().point
				end,
				set = function(key)
					if type(key) == "string" then
						local progressBars = GetProgressBarPreferences()
						local point, relativeTo, relativePoint, x, y = ApplyPoint(
							Private.progressBarAnchor.frame,
							key,
							progressBars.relativeTo,
							progressBars.relativePoint
						)
						progressBars.point = point
						progressBars.relativeTo = relativeTo
						progressBars.relativePoint = relativePoint
						progressBars.x, progressBars.y = x, y
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Frame"],
				type = "frameChooser",
				description = L["The frame that the Progress Bars frame is anchored to. Defaults to UIParent (screen)."],
				category = L["Progress Bars"],
				updateIndices = { -1, 0, 1, 2 },
				get = function()
					return GetProgressBarPreferences().relativeTo
				end,
				set = function(key)
					if type(key) == "string" then
						local progressBars = GetProgressBarPreferences()
						local point, relativeTo, relativePoint, x, y = ApplyPoint(
							Private.progressBarAnchor.frame,
							progressBars.point,
							key,
							progressBars.relativePoint
						)
						progressBars.point = point
						progressBars.relativeTo = relativeTo
						progressBars.relativePoint = relativePoint
						progressBars.x, progressBars.y = x, y
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Relative Anchor Point"],
				type = "dropdown",
				description = L["The anchor point on the frame that the Progress Bars frame is anchored to."],
				category = L["Progress Bars"],
				values = anchorPointValues,
				updateIndices = { -2, -1, 0, 1 },
				get = function()
					return GetProgressBarPreferences().relativePoint
				end,
				set = function(key)
					if type(key) == "string" then
						local progressBars = GetProgressBarPreferences()
						local point, relativeTo, relativePoint, x, y = ApplyPoint(
							Private.progressBarAnchor.frame,
							progressBars.point,
							progressBars.relativeTo,
							key
						)
						progressBars.point = point
						progressBars.relativeTo = relativeTo
						progressBars.relativePoint = relativePoint
						progressBars.x, progressBars.y = x, y
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Position"],
				labels = { L["X"], L["Y"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The horizontal offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."],
					L["The vertical offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."],
				},
				category = L["Progress Bars"],
				values = anchorPointValues,
				updateIndices = { -3, -2, -1, 0 },
				get = function()
					return GetProgressBarPreferences().x, GetProgressBarPreferences().y
				end,
				set = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						GetProgressBarPreferences().x = x
						GetProgressBarPreferences().y = y
						local progressBars = GetProgressBarPreferences()
						local regionName = utilities.IsValidRegionName(progressBars.relativeTo)
								and progressBars.relativeTo
							or "UIParent"
						Private.progressBarAnchor.frame:SetPoint(
							progressBars.point,
							regionName,
							progressBars.relativePoint,
							x,
							y
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				validate = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						return true
					end
					return false, GetProgressBarPreferences().x, GetProgressBarPreferences().y
				end,
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
						Private.progressBarAnchor:SetFont(
							preferences.font,
							preferences.fontSize,
							preferences.fontOutline
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Size"],
				type = "lineEdit",
				description = L["Font size to use for Progress Bar text."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().fontSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						local preferences = GetProgressBarPreferences()
						preferences.fontSize = value
						Private.progressBarAnchor:SetFont(
							preferences.font,
							preferences.fontSize,
							preferences.fontOutline
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 8 or value > 48 then
							return false, utilities.Clamp(value, 8, 48)
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
						Private.progressBarAnchor:SetFont(
							preferences.font,
							preferences.fontSize,
							preferences.fontOutline
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Text Alignment"],
				type = "radioButtonGroup",
				description = L["Alignment of Progress Bar text."],
				category = L["Progress Bars"],
				values = textAlignmentValues,
				get = function()
					return GetProgressBarPreferences().textAlignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetProgressBarPreferences().textAlignment = key
						Private.progressBarAnchor:SetHorizontalTextAlignment(GetProgressBarPreferences().textAlignment)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Duration Alignment"],
				type = "radioButtonGroup",
				description = L["Alignment of Progress Bar duration text."],
				category = L["Progress Bars"],
				values = textAlignmentValues,
				get = function()
					return GetProgressBarPreferences().durationAlignment
				end,
				set = function(key)
					if type(key) == "string" then
						GetProgressBarPreferences().durationAlignment = key
						Private.progressBarAnchor:SetDurationTextAlignment(
							GetProgressBarPreferences().durationAlignment
						)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
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
						GetProgressBarPreferences().texture = key
						Private.progressBarAnchor:SetTexture(GetProgressBarPreferences().texture)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Width"],
				type = "lineEdit",
				description = L["The width of Progress Bars."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().width
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetProgressBarPreferences().width = value
						Private.progressBarAnchor:SetProgressBarWidth(value)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 0.0 or value < 500.0 then
							return false, utilities.Clamp(value, 0.0, 500.0)
						else
							return true
						end
					else
						return false, GetProgressBarPreferences().width
					end
				end,
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
					if key == "fill" then
						GetProgressBarPreferences().fill = true
					else
						GetProgressBarPreferences().fill = false
					end
					Private.progressBarAnchor:SetFill(GetProgressBarPreferences().fill)
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
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
						Private.progressBarAnchor:SetIconPosition(key)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Alpha"],
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
						Private.progressBarAnchor:SetAlpha(value)
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 0.0 or value > 1.0 then
							return false, utilities.Clamp(value, 0.0, 1.0)
						else
							return true
						end
					end
					return false, GetProgressBarPreferences().alpha
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Color"],
				labels = { L["Foreground"], L["Background"] },
				type = "doubleColorPicker",
				descriptions = {
					L["Foreground color for Progress Bars."],
					L["Background color for Progress Bars."],
				},
				category = L["Progress Bars"],
				get = {
					function()
						return unpack(GetProgressBarPreferences().color)
					end,
					function()
						return unpack(GetProgressBarPreferences().backgroundColor)
					end,
				},
				set = {
					function(r, g, b, a)
						GetProgressBarPreferences().color = { r, g, b, a }
						Private.progressBarAnchor:SetColor(r, g, b, a)
					end,
					function(r, g, b, a)
						GetProgressBarPreferences().backgroundColor = { r, g, b, a }
						Private.progressBarAnchor:SetBackgroundColor(r, g, b, a)
					end,
				},
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Border"],
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
						GetProgressBarPreferences().showBorder = key
						Private.progressBarAnchor:SetShowBorder(GetProgressBarPreferences().showBorder)
					end,
					function(key)
						GetProgressBarPreferences().showIconBorder = key
						Private.progressBarAnchor:SetShowIconBorder(GetProgressBarPreferences().showIconBorder)
					end,
				},
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Spacing"],
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
					end
				end,
				enabled = function()
					return GetReminderPreferences().enabled == true and GetProgressBarPreferences().enabled == true
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < -1 or value > 100 then
							return false, utilities.Clamp(value, -1, 100)
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
				values = nil,
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
				description = L["The voice to use for Text to Speech"],
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
					return GetReminderPreferences().enabled == true
						and (
							GetReminderPreferences().textToSpeech.enableAtTime
							or GetReminderPreferences().textToSpeech.enableAtAdvanceNotice
						)
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Text to Speech Volume"],
				type = "lineEdit",
				description = L["The volume to use for Text to Speech"],
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
					return GetReminderPreferences().enabled == true
						and (
							GetReminderPreferences().textToSpeech.enableAtTime
							or GetReminderPreferences().textToSpeech.enableAtAdvanceNotice
						)
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < 0.0 or value > 100.0 then
							return false, utilities.Clamp(value, 0.0, 100.0)
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
						GetReminderPreferences().sound.enableAtAdvanceNotice = key
					end,
					function(key)
						GetReminderPreferences().sound.advanceNoticeSound = key
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						return GetReminderPreferences().enabled == true
							and GetReminderPreferences().sound.enableAtAdvanceNotice == true
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
						GetReminderPreferences().sound.enableAtTime = key
					end,
					function(key)
						GetReminderPreferences().sound.atSound = key
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						return GetReminderPreferences().enabled == true
							and GetReminderPreferences().sound.enableAtTime == true
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
				description = L["Clears all saved trusted characters. You will see a warning each time a new character sends a plan to you."],
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
					return tostring(GetPreferences().timelineRows.numberOfAssignmentsToShow)
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
					return tostring(GetPreferences().timelineRows.numberOfBossAbilitiesToShow)
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
					if key == "At cursor" then
						GetPreferences().zoomCenteredOnCursor = true
					else
						GetPreferences().zoomCenteredOnCursor = false
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
						if key ~= GetPreferences().assignmentSortType then
							GetPreferences().assignmentSortType = key
							if Private.mainFrame and Private.mainFrame.bossSelectDropdown then
								local bossDungeonEncounterID = Private.mainFrame.bossSelectDropdown:GetValue()
								if bossDungeonEncounterID then
									interfaceUpdater.UpdateAllAssignments(false, bossDungeonEncounterID)
								end
							end
						end
						GetPreferences().assignmentSortType = key
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Show Spell Cooldown Duration"],
				type = "checkBox",
				description = L["Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key."],
				category = L["Assignment"],
				get = function()
					return GetPreferences().showSpellCooldownDuration
				end,
				set = function(key)
					if type(key) == "boolean" then
						if key ~= GetPreferences().showSpellCooldownDuration then
							GetPreferences().showSpellCooldownDuration = key
							if Private.mainFrame and Private.mainFrame.timeline then
								Private.mainFrame.timeline:UpdateTimeline()
							end
						end
						GetPreferences().showSpellCooldownDuration = key
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
				buttonDescription = L["Reset the current profile to default."],
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
				description = L["Create a new empty profile."],
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
				category = L["Profile"],
				description = L["Copy the settings from an existing profile into the currently active profile."],
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
				category = L["Profile"],
				description = L["Delete a profile from the database."],
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

	function Private:GetOrCreateOptions()
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

		local keyBindingsTab = { L["Keybindings"], keyBindingOptions, { L["Assignment"], L["Timeline"] } }
		local reminderTabs = { L["Messages"], L["Progress Bars"], L["Text to Speech"], L["Sound"], L["Other"] }
		local reminderTab = { L["Reminder"], reminderOptions, reminderTabs }
		local viewTab = { L["View"], viewOptions, { L["Assignment"] } }
		local profileTab = { L["Profile"], profileOptions, { L["Profile"] } }

		return keyBindingsTab, reminderTab, viewTab, profileTab
	end
end

-- Creates and shows the options menu. The message anchor and progress bar anchor are released when the options menu is
-- released.
function Private:CreateOptionsMenu()
	local optionsMenu = AceGUI:Create("EPOptions")
	optionsMenu.frame:SetParent(UIParent)
	optionsMenu.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	optionsMenu.frame:SetFrameLevel(90)
	optionsMenu:SetCallback("OnRelease", function()
		if Private.messageAnchor then
			Private.messageAnchor:Release()
		end
		if Private.progressBarAnchor then
			Private.progressBarAnchor:Release()
		end
		Private.messageAnchor = nil
		Private.progressBarAnchor = nil
		Private.optionsMenu = nil
	end)

	Private.messageAnchor = CreateMessageAnchor()
	Private.messageAnchor.frame:Hide()

	Private.progressBarAnchor = CreateProgressBarAnchor()
	Private.progressBarAnchor.frame:Hide()

	local keyBindingsTab, reminderTab, viewTab, profileTab = self:GetOrCreateOptions()
	optionsMenu:AddOptionTab(unpack(keyBindingsTab))
	optionsMenu:AddOptionTab(unpack(reminderTab))
	optionsMenu:AddOptionTab(unpack(viewTab))
	optionsMenu:AddOptionTab(unpack(profileTab))
	optionsMenu:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	optionsMenu:SetCurrentTab(L["Keybindings"])
	optionsMenu:SetPoint("TOP", UIParent, "TOP", 0, -optionsMenu.frame:GetBottom())

	Private.optionsMenu = optionsMenu
end

function Private:RecreateAnchors()
	if Private.optionsMenu then
		Private.messageAnchor = CreateMessageAnchor()
		Private.messageAnchor.frame:Hide()

		Private.progressBarAnchor = CreateProgressBarAnchor()
		Private.progressBarAnchor.frame:Hide()
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
