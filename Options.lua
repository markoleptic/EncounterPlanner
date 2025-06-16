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
local UIParent = UIParent
local format = string.format
local GetTtsVoices = C_VoiceChat.GetTtsVoices
local NewTimer = C_Timer.NewTimer
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tremove = table.remove
local type = type
local unpack = unpack
local wipe = table.wipe

---@type EPAnchorContainer|nil
local messageAnchor = nil
---@type EPAnchorContainer|nil
local progressBarAnchor = nil
---@type EPAnchorContainer|nil
local iconAnchor = nil

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

---@return IconPreferences
local function GetIconPreferences()
	return AddOn.db.profile.preferences.reminder.icons
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

---@return Plan
local function GetCurrentPlan()
	return AddOn.db.profile.plans[AddOn.db.profile.lastOpenPlan]
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
	local timers = {}
	local kGenericTimerMultiplier = 0.33
	local isAddingProgressBars = false
	local progressBarText = L["Progress Bar Text"]
	local questionMarkIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]]

	local function AddDelayedProgressBar(time)
		local timer = NewTimer(time, function()
			progressBarManager:AddProgressBar()
			tremove(timers, 1)
		end)
		tinsert(timers, timer)
	end

	local function AddSecondAndThirdProgressBarsDelayed()
		isAddingProgressBars = true
		local secondTimerDuration = GetReminderPreferences().countdownLength * kGenericTimerMultiplier
		local thirdTimerDuration = secondTimerDuration * 2.0
		AddDelayedProgressBar(secondTimerDuration)
		AddDelayedProgressBar(thirdTimerDuration)
	end

	function progressBarManager:AddProgressBar()
		if progressBarAnchor then
			local reminderPreferences = GetReminderPreferences()
			local preferences = reminderPreferences.progressBars
			local progressBar = AceGUI:Create("EPProgressBar")
			progressBar:Set(preferences, progressBarText, reminderPreferences.countdownLength, questionMarkIcon)
			progressBar:SetCallback("Completed", function(widget)
				---@cast widget EPProgressBar
				if progressBarAnchor then
					if not isAddingProgressBars and #progressBarAnchor.children == 1 then
						widget:SetDuration(GetReminderPreferences().countdownLength)
						widget:Start()
						widget.frame:Show()
						AddSecondAndThirdProgressBarsDelayed()
					elseif mouseIsDown then
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
	local timers = {}
	local secondTimerDurationNoCountdown = 1.2
	local thirdTimerDurationNoCountdown = 2.4
	local kGenericTimerMultiplier = 0.33
	local isAddingMessages = false
	local messageText = L["Cast spell or something"]
	local questionMarkIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]]

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
			local secondTimerDuration = reminderPreferences.countdownLength * kGenericTimerMultiplier
			local thirdTimerDuration = secondTimerDuration * 2.0
			AddMessageDelayed(secondTimerDuration)
			AddMessageDelayed(thirdTimerDuration)
		end
	end

	function messageManager:AddMessage()
		if messageAnchor then
			local reminderPreferences = GetReminderPreferences()
			local preferences = reminderPreferences.messages
			local message = AceGUI:Create("EPReminderMessage")
			message:Set(preferences, messageText, questionMarkIcon)
			message:SetAnchorMode(true)
			message:SetCallback("Completed", function(widget)
				---@cast widget EPReminderMessage
				if messageAnchor then
					if not isAddingMessages and #messageAnchor.children == 1 then
						local p = GetReminderPreferences()
						widget:Start(p.messages.showOnlyAtExpiration and 0 or p.countdownLength)
						widget.frame:Show()
						AddSecondAndThirdMessagesDelayed()
					elseif mouseIsDown then
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
			message:Start(preferences.showOnlyAtExpiration and 0 or reminderPreferences.countdownLength)

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

local iconManager = {}
do
	local timers = {}
	local kGenericTimerMultiplier = 0.33
	local isAddingIcons = false
	local iconText = L["Icon Text"]
	local questionMarkIcon = [[Interface\Icons\INV_MISC_QUESTIONMARK]]

	local function AddDelayedIcon(time)
		local timer = NewTimer(time, function()
			iconManager:AddIcon()
			tremove(timers, 1)
		end)
		tinsert(timers, timer)
	end

	local function AddSecondAndThirdIconsDelayed()
		isAddingIcons = true
		local secondTimerDuration = GetReminderPreferences().countdownLength * kGenericTimerMultiplier
		local thirdTimerDuration = secondTimerDuration * 2.0
		AddDelayedIcon(secondTimerDuration)
		AddDelayedIcon(thirdTimerDuration)
	end

	function iconManager:AddIcon()
		if iconAnchor then
			local reminderPreferences = GetReminderPreferences()
			local preferences = reminderPreferences.icons
			local icon = AceGUI:Create("EPReminderIcon")
			icon:Set(preferences, iconText, questionMarkIcon)
			icon:SetCallback("Completed", function(widget)
				---@cast widget EPReminderIcon
				if iconAnchor then
					if not isAddingIcons and #iconAnchor.children == 1 then
						widget:Start(GetTime(), GetReminderPreferences().countdownLength)
						widget.frame:Show()
						AddSecondAndThirdIconsDelayed()
					elseif mouseIsDown then
						local p = GetIconPreferences()
						local p1, p2, p3, p4, p5 = ApplyPoint(iconAnchor.frame, p.point, p.relativeTo, p.relativePoint)
						iconAnchor:RemoveChild(widget)
						if mouseIsDown and p1 then
							iconAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
						end
					else
						iconAnchor:RemoveChild(widget)
					end
				end
			end)

			if mouseIsDown then
				local p = GetIconPreferences()
				local p1, p2, p3, p4, p5 = ApplyPoint(iconAnchor.frame, p.point, p.relativeTo, p.relativePoint)
				iconAnchor:AddChild(icon)
				if mouseIsDown and p1 then
					iconAnchor.frame:SetPoint(p1, p2, p3, p4, p5)
				end
			else
				iconAnchor:AddChild(icon)
			end
			icon:Start(GetTime(), reminderPreferences.countdownLength)

			if #iconAnchor.children >= 3 then
				isAddingIcons = false
			end
		end
	end

	function iconManager:AddIconsOnTimer()
		if iconAnchor then
			iconAnchor:ReleaseChildren()
			self:AddIcon()
			AddSecondAndThirdIconsDelayed()
		end
	end

	function iconManager:CancelTimers()
		for _, timer in ipairs(timers) do
			if timer and timer.Cancel then
				timer:Cancel()
			end
		end
		wipe(timers)
		isAddingIcons = false
	end
end

---@return EPAnchorContainer
local function CreateProgressBarAnchor()
	local progressBarPreferences = GetProgressBarPreferences()
	local container = utilities.CreateReminderAnchorContainer(progressBarPreferences, progressBarPreferences.spacing)
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

---@return EPAnchorContainer
local function CreateMessageAnchor()
	local messagePreferences = GetMessagePreferences()
	local container = utilities.CreateReminderAnchorContainer(messagePreferences)
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

---@return EPAnchorContainer
local function CreateIconAnchor()
	local iconPreferences = GetIconPreferences()
	local container = utilities.CreateReminderAnchorContainer(iconPreferences, iconPreferences.spacing)
	container.frame:SetClampedToScreen(true)
	container:SetAnchorMode(true, iconPreferences.point)

	container:SetCallback("OnRelease", function()
		iconManager:CancelTimers()
		if iconAnchor then
			iconAnchor.frame:SetClampedToScreen(false)
		end
		iconAnchor = nil
		mouseIsDown = false
	end)
	container:SetCallback("MouseDown", function()
		mouseIsDown = true
	end)
	container:SetCallback("NewPoint", function(_, _, point, relativeFrame, relativePoint)
		mouseIsDown = false
		if iconAnchor then
			local preferences = GetIconPreferences()
			if iconAnchor.frame:GetName() == relativeFrame then
				relativeFrame = preferences.relativeTo
			end
			preferences.point, preferences.relativeTo, preferences.relativePoint, preferences.x, preferences.y =
				ApplyPoint(iconAnchor.frame, point, relativeFrame, relativePoint)
			if Private.optionsMenu then
				Private.optionsMenu:UpdateOptions()
			end
		end
	end)

	return container
end

---@enum AnchorType
local AnchorType = {
	Message = {},
	ProgressBar = {},
	Icon = {},
}

---@param anchorType AnchorType
---@param point AnchorPoint|nil
---@param relativeTo string|nil
---@param relativePoint AnchorPoint|nil
local function ApplyPointToAnchor(anchorType, point, relativeTo, relativePoint)
	if anchorType == AnchorType.ProgressBar then
		if progressBarAnchor then
			local x, y
			point, relativeTo, relativePoint, x, y =
				ApplyPoint(progressBarAnchor.frame, point, relativeTo, relativePoint)
			progressBarAnchor:SetAnchorPoint(point)
			local preferences = GetProgressBarPreferences()
			preferences.point = point
			preferences.relativeTo = relativeTo
			preferences.relativePoint = relativePoint
			preferences.x, preferences.y = x, y
		end
	elseif anchorType == AnchorType.Message then
		if messageAnchor then
			local x, y
			point, relativeTo, relativePoint, x, y = ApplyPoint(messageAnchor.frame, point, relativeTo, relativePoint)
			messageAnchor:SetAnchorPoint(point)
			local preferences = GetMessagePreferences()
			preferences.point = point
			preferences.relativeTo = relativeTo
			preferences.relativePoint = relativePoint
			preferences.x, preferences.y = x, y
		end
	elseif anchorType == AnchorType.Icon then
		if iconAnchor then
			local x, y
			point, relativeTo, relativePoint, x, y = ApplyPoint(iconAnchor.frame, point, relativeTo, relativePoint)
			iconAnchor:SetAnchorPoint(point)
			local preferences = GetIconPreferences()
			preferences.point = point
			preferences.relativeTo = relativeTo
			preferences.relativePoint = relativePoint
			preferences.x, preferences.y = x, y
		end
	end
end

---@param anchorType AnchorType
---@param func fun(widget: EPProgressBar|EPReminderMessage|EPReminderIcon)
local function CallAnchorFunction(anchorType, func)
	if anchorType == AnchorType.ProgressBar then
		if progressBarAnchor then
			for _, child in ipairs(progressBarAnchor.children) do
				---@cast child EPProgressBar
				func(child)
			end
			progressBarAnchor:DoLayout()
		end
	elseif anchorType == AnchorType.Message then
		if messageAnchor then
			for _, child in ipairs(messageAnchor.children) do
				---@cast child EPReminderMessage
				func(child)
			end
			messageAnchor:DoLayout()
		end
	elseif anchorType == AnchorType.Icon then
		if iconAnchor then
			for _, child in ipairs(iconAnchor.children) do
				---@cast child EPReminderIcon
				func(child)
			end
			iconAnchor:DoLayout()
		end
	end
end

---@param anchorType AnchorType
local function HideAnchor(anchorType)
	if anchorType == AnchorType.ProgressBar then
		if progressBarAnchor then
			progressBarAnchor.frame:Hide()
			progressBarManager:CancelTimers()
			progressBarAnchor:ReleaseChildren()
		end
	elseif anchorType == AnchorType.Message then
		if messageAnchor then
			messageAnchor.frame:Hide()
			messageManager:CancelTimers()
			messageAnchor:ReleaseChildren()
		end
	elseif anchorType == AnchorType.Icon then
		if iconAnchor then
			iconAnchor.frame:Hide()
			iconManager:CancelTimers()
			iconAnchor:ReleaseChildren()
		end
	end
end

---@param anchorType AnchorType
local function ShowAnchor(anchorType)
	if anchorType == AnchorType.ProgressBar then
		if progressBarAnchor then
			progressBarAnchor.frame:Show()
			progressBarManager:CancelTimers()
			progressBarManager:AddProgressBarsOnTimer()
		end
	elseif anchorType == AnchorType.Message then
		if messageAnchor then
			messageAnchor.frame:Show()
			messageManager:CancelTimers()
			messageManager:AddMessagesOnTimer()
		end
	elseif anchorType == AnchorType.Icon then
		if iconAnchor then
			iconAnchor.frame:Show()
			iconManager:CancelTimers()
			iconManager:AddIconsOnTimer()
		end
	end
end

local optionCreator = {}
do
	local Clamp = Clamp

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

	local horizontalSortingValues = {
		{ itemValue = true, text = L["Soonest Expiration on Left"] },
		{ itemValue = false, text = L["Soonest Expiration on Right"] },
	}

	local verticalSortingValues = {
		{ itemValue = false, text = L["Soonest Expiration on Top"] },
		{ itemValue = true, text = L["Soonest Expiration on Bottom"] },
	}

	local growDirectionValues = {
		{ itemValue = "horizontal", text = L["Horizontal"] },
		{ itemValue = "vertical", text = L["Vertical"] },
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
	local controlOptions = nil
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
	local function CreateControlOptions()
		return {
			{
				label = L["Add Assignment"],
				type = "dropdown",
				category = L["Assignment Timeline"],
				description = L["Creates a new assignment when this key is pressed when hovering over the timeline."],
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
				category = L["Assignment Timeline"],
				description = L["Opens the assignment editor when this key is pressed when hovering over an assignment spell icon."],
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
				category = L["Assignment Timeline"],
				description = L["Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key."],
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
			{
				label = L["Pan"],
				type = "dropdown",
				category = L["Timeline"],
				description = L["Pans the timeline to the left and right when holding this key."],
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
				category = L["Timeline"],
				description = L["Scrolls the timeline up and down."],
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
				category = L["Timeline"],
				description = L["Zooms in horizontally on the timeline."],
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
				label = L["Zoom Behavior"],
				labels = { L["At cursor"], L["Middle of timeline"] },
				type = "radioButtonGroup",
				category = L["Timeline"],
				descriptions = {
					L["Zooms in toward the position of your mouse cursor, keeping the area under the cursor in focus."],
					L["Zooms in toward the horizontal center of the timeline, keeping the middle of the visible area in focus."],
				},
				values = {
					{ itemValue = 1, text = L["At cursor"] },
					{ itemValue = 0, text = L["Middle of timeline"] },
				},
				get = function()
					return GetPreferences().zoomCenteredOnCursor == true and 1 or 0
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().zoomCenteredOnCursor = value == 1
					end
				end,
			} --[[@as EPSettingOption]],
		}
	end

	---@return table<integer, EPSettingOption>
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
		local enableIconOption = function()
			local preferences = GetReminderPreferences()
			return preferences.enabled == true and preferences.icons.enabled == true
		end

		local kMinIconSize = 10.0
		local kMaxIconSize = 100.0
		local kMaxProgressBarWidth = 1000.0
		local kMaxProgressBarHeight = 100.0
		local kMinSpacing = -1
		local kMaxSpacing = 100
		local kMinCountdownLength = 2.0
		local kMaxCountdownLength = 30.0
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
							preferences.enabled = key
							if key == true then
								Private:RegisterReminderEvents()
							else
								if Private.IsSimulatingBoss() then
									Private:StopSimulatingBoss()
								end
								Private:UnregisterReminderEvents()
								if messageAnchor and messageAnchor.frame:IsShown() then
									HideAnchor(AnchorType.Message)
								end
								if progressBarAnchor and progressBarAnchor.frame:IsShown() then
									HideAnchor(AnchorType.ProgressBar)
								end
								if iconAnchor and iconAnchor.frame:IsShown() then
									HideAnchor(AnchorType.Icon)
								end
							end
							interfaceUpdater.UpdatePlanCheckBoxes(GetCurrentPlan())
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
				description = L["Glows the unit frame of the target at the end of the countdown. If the assignment has a spell ID, the frame will glow until the spell is cast on the target, up to a maximum of 10 seconds. Otherwise, shows for 5 seconds."],
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
				label = L["Countdown Length"],
				type = "lineEdit",
				description = L["How far ahead to begin showing reminders."],
				get = function()
					return tostring(GetReminderPreferences().countdownLength)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetReminderPreferences().countdownLength = value
						progressBarManager:AddProgressBarsOnTimer()
					end
				end,
				validate = function(value)
					local numericValue = tonumber(value)
					if numericValue then
						if numericValue > kMinCountdownLength and numericValue < kMaxCountdownLength then
							return true
						else
							return false, Clamp(numericValue, kMinCountdownLength, kMaxCountdownLength)
						end
					else
						return false, GetReminderPreferences().countdownLength
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
								HideAnchor(AnchorType.Message)
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
						HideAnchor(AnchorType.Message)
					else
						ShowAnchor(AnchorType.Message)
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Visibility"],
				labels = { L["Expiration Only"], L["With Countdown"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Only shows Messages at the end of the countdown. Messages are displayed for 2 seconds before fading for 1.2 seconds."],
					L["Messages are displayed for the duration of the countdown, including time, before fading for 1.2 seconds."],
				},
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
								ShowAnchor(AnchorType.Message)
							end
						end
					else -- if key == "fullCountdown" then
						if preferences.messages.showOnlyAtExpiration ~= false then
							preferences.messages.showOnlyAtExpiration = false
							if messageAnchor and messageAnchor.frame:IsShown() then
								ShowAnchor(AnchorType.Message)
							end
						end
					end
				end,
				enabled = enableMessageOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Message Order"],
				labels = { L["Soonest Expiration on Top"], L["Soonest Expiration on Bottom"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Displayed in ascending order of expiration time, with the message expiring the soonest on top."],
					L["Displayed in descending order of expiration time, with the message expiring the soonest on bottom."],
				},
				category = L["Messages"],
				values = verticalSortingValues,
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
						CallAnchorFunction(AnchorType.Message, function(message)
							---@cast message EPReminderMessage
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
						CallAnchorFunction(AnchorType.Message, function(message)
							---@cast message EPReminderMessage
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
						CallAnchorFunction(AnchorType.Message, function(message)
							---@cast message EPReminderMessage
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
						CallAnchorFunction(AnchorType.Message, function(message)
							---@cast message EPReminderMessage
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
						CallAnchorFunction(AnchorType.Message, function(message)
							---@cast message EPReminderMessage
							message:SetTextColor(r, g, b, a)
						end)
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
						local region = _G[regionName] or UIParent
						if messageAnchor then
							messageAnchor.frame:SetPoint(preferences.point, region, preferences.relativePoint, x, y)
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
						ApplyPointToAnchor(AnchorType.Message, key, messages.relativeTo, messages.relativePoint)
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
						ApplyPointToAnchor(AnchorType.Message, messages.point, key, messages.relativePoint)
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
						ApplyPointToAnchor(AnchorType.Message, messages.point, messages.relativeTo, key)
					end
				end,
				enabled = enableMessageOption,
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
								HideAnchor(AnchorType.ProgressBar)
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
						HideAnchor(AnchorType.ProgressBar)
					else
						ShowAnchor(AnchorType.ProgressBar)
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Size"],
				labels = { L["Width"], L["Height"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The width of Progress Bars. Must be at least twice the font size and less than 1000."],
					L["The height of Progress Bars. Must be at least the font size and less than 100."],
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetProgressBarSize(preferences.width, preferences.height)
							progressBar:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit
							)
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
						local minProgressBarWidth = minProgressBarHeight * 2
						if
							width < minProgressBarWidth
							or width > kMaxProgressBarWidth
							or height < minProgressBarHeight
							or height > kMaxProgressBarHeight
						then
							return false,
								Clamp(width, minProgressBarWidth, kMaxProgressBarWidth),
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
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
							CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
								---@cast progressBar EPProgressBar
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
							CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
								---@cast progressBar EPProgressBar
								progressBar:SetBackgroundColor(r, g, b, a)
							end)
						end
					end,
				},
				enabled = enableProgressBarOption,
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
							CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
								---@cast progressBar EPProgressBar
								progressBar:SetShowBorder(key)
							end)
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetProgressBarPreferences().showIconBorder = key
							CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
								---@cast progressBar EPProgressBar
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
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
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Progress Bars"],
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Order"],
				labels = { L["Soonest Expiration on Top"], L["Soonest Expiration on Bottom"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Displayed in ascending order of expiration time, with the bar expiring the soonest on top."],
					L["Displayed in descending order of expiration time, with the bar expiring the soonest on bottom."],
				},
				category = L["Progress Bars"],
				values = verticalSortingValues,
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
				label = L["Icon Position"],
				labels = { L["Left"], L["Right"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Icon on left, text and duration on right."],
					L["Icon on right, text and duration on left."],
				},
				category = L["Progress Bars"],
				values = { { itemValue = "LEFT", text = L["Left"] }, { itemValue = "RIGHT", text = L["Right"] } },
				get = function()
					return GetProgressBarPreferences().iconPosition
				end,
				set = function(key)
					if type(key) == "string" then
						GetProgressBarPreferences().iconPosition = key
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetIconPosition(key)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Duration Position"],
				labels = { L["Left"], L["Right"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Duration to the left of text."],
					L["Duration to the right of text."],
				},
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetDurationTextAlignment(key)
						end)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Bar Progress Type"],
				labels = { L["Fill"], L["Drain"] },
				type = "radioButtonGroup",
				descriptions = {
					L["Fills Progress Bars from left to right as the countdown progresses."],
					L["Drains Progress Bars from right to left as the countdown progresses."],
				},
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
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
				label = L["Shrink Text to Fit"],
				type = "checkBox",
				description = L["Whether to attempt to shrink reminder text to fit within Progress Bars. Does not affect duration text size."],
				category = L["Progress Bars"],
				get = function()
					return GetProgressBarPreferences().shrinkTextToFit
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetProgressBarPreferences()
						preferences.shrinkTextToFit = key
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit
							)
						end)
					end
				end,
				enabled = enableProgressBarOption,
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit
							)
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit
							)
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
						CallAnchorFunction(AnchorType.ProgressBar, function(progressBar)
							---@cast progressBar EPProgressBar
							progressBar:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit
							)
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
						local region = _G[regionName] or UIParent
						if progressBarAnchor then
							progressBarAnchor.frame:SetPoint(preferences.point, region, preferences.relativePoint, x, y)
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
						ApplyPointToAnchor(
							AnchorType.ProgressBar,
							key,
							preferences.relativeTo,
							preferences.relativePoint
						)
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
						ApplyPointToAnchor(AnchorType.ProgressBar, preferences.point, key, preferences.relativePoint)
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
						ApplyPointToAnchor(AnchorType.ProgressBar, preferences.point, preferences.relativeTo, key)
					end
				end,
				enabled = enableProgressBarOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Enable Cooldown Icons"],
				type = "checkBoxBesideButton",
				description = L["Whether to show cooldown-style icons for spell assignments (does not apply to text only assignments)."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().enabled
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetIconPreferences()
						if key ~= preferences.enabled and key == false then
							preferences.enabled = false
							if iconAnchor and iconAnchor.frame:IsShown() then
								HideAnchor(AnchorType.Icon)
							end
						end
						preferences.enabled = key
					end
				end,
				enabled = enableReminderOption,
				buttonText = L["Toggle Cooldown Icon Anchor"],
				buttonEnabled = enableIconOption,
				buttonCallback = function()
					if iconAnchor and iconAnchor.frame:IsShown() then
						HideAnchor(AnchorType.Icon)
					else
						ShowAnchor(AnchorType.Icon)
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Size"],
				labels = { L["Width"], L["Height"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The width of Cooldown Icons (10 - 100)."],
					L["The height of Cooldown Icons (10 - 100)."],
				},
				category = L["Cooldown Icons"],
				get = function()
					local preferences = GetIconPreferences()
					return preferences.width, preferences.height
				end,
				set = function(key, key2)
					local width = tonumber(key)
					local height = tonumber(key2)
					if width and height then
						local preferences = GetIconPreferences()
						preferences.width = width
						preferences.height = height
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon.frame:SetSize(preferences.width, preferences.height)
							icon:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit,
								preferences.width
							)
						end)
					end
				end,
				validate = function(key, key2)
					local preferences = GetIconPreferences()
					local width = tonumber(key)
					local height = tonumber(key2)
					if width and height then
						if
							width < kMinIconSize
							or width > kMaxIconSize
							or height < kMinIconSize
							or height > kMaxIconSize
						then
							return false,
								Clamp(width, kMinIconSize, kMaxIconSize),
								Clamp(height, kMinIconSize, kMaxIconSize)
						else
							return true
						end
					else
						return false, preferences.width, preferences.height
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Border Size"],
				type = "lineEdit",
				description = L["The size of the border of Cooldown Icons."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().borderSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						value = utilities.Round(value, 0)
						GetIconPreferences().borderSize = value
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetBorderSize(value)
						end)
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						value = utilities.Round(value, 0)
						local preferences = GetIconPreferences()
						local maxValue = min(preferences.width, preferences.height)
						if value < kZero or value > maxValue then
							return false, Clamp(value, kZero, maxValue)
						else
							return true
						end
					else
						return false, GetIconPreferences().borderSize
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Spacing"],
				type = "lineEdit",
				description = L["Spacing between Cooldown Icons (-1 - 100)."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().spacing
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetIconPreferences().spacing = value
						if iconAnchor then
							iconAnchor:SetSpacing(value, value)
							iconAnchor:DoLayout()
						end
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kMinSpacing or value > kMaxSpacing then
							return false, Clamp(value, kMinSpacing, kMaxSpacing)
						else
							return true
						end
					end
					return false, GetIconPreferences().spacing
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Transparency"],
				type = "lineEdit",
				description = L["Transparency of Cooldown Icons (0.0 - 1.0)."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().alpha
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetIconPreferences().alpha = value
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPProgressBar
							icon:SetAlpha(value)
						end)
					end
				end,
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
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Cooldown Icons"],
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Grow Direction"],
				labels = { L["Horizontal"], L["Vertical"] },
				type = "radioButtonGroup",
				updateIndices = { 1 },
				descriptions = {
					L["Cooldown Icons grow horizontally."],
					L["Cooldown Icons grow vertically."],
				},
				category = L["Cooldown Icons"],
				values = growDirectionValues,
				get = function()
					return GetIconPreferences().orientation
				end,
				set = function(key)
					if type(key) == "string" then
						local icons = GetIconPreferences()
						icons.orientation = key
						if iconAnchor then
							iconAnchor.content.orientation = key
							iconAnchor:DoLayout()
						end
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Icon Order"],
				labels = function()
					if GetIconPreferences().orientation == "vertical" then
						return { L["Soonest Expiration on Top"], L["Soonest Expiration on Bottom"] }
					else
						return { L["Soonest Expiration on Left"], L["Soonest Expiration on Right"] }
					end
				end,
				type = "radioButtonGroup",
				updateIndices = { -1 },
				descriptions = function()
					if GetIconPreferences().orientation == "vertical" then
						return {
							L["Displayed in ascending order of expiration time, with the icon expiring the soonest on top."],
							L["Displayed in descending order of expiration time, with the icon expiring the soonest on bottom."],
						}
					else
						return {
							L["Displayed in ascending order of expiration time, with the icon expiring the soonest on the left."],
							L["Displayed in descending order of expiration time, with the icon expiring the soonest on the right."],
						}
					end
				end,
				category = L["Cooldown Icons"],
				values = function()
					if GetIconPreferences().orientation == "vertical" then
						return verticalSortingValues
					else
						return horizontalSortingValues
					end
				end,
				get = function()
					return GetIconPreferences().soonestExpirationOnBottom
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetIconPreferences().soonestExpirationOnBottom = key
						if iconAnchor then
							iconAnchor.content.sortAscending = key
							iconAnchor:DoLayout()
						end
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Show Edge"],
				type = "checkBox",
				description = L["Whether to show the edge indicator on Cooldown Icons."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().drawEdge
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetIconPreferences()
						preferences.drawEdge = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetDraw(preferences.drawEdge, preferences.drawSwipe)
						end)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Show Swipe"],
				type = "checkBox",
				description = L["Whether to show the radial swipe animation on Cooldown Icons."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().drawSwipe
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetIconPreferences()
						preferences.drawSwipe = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetDraw(preferences.drawEdge, preferences.drawSwipe)
						end)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Cooldown Icons"],
			} --[[@as EPSettingOption]],
			{
				label = L["Show Text Beneath Icon"],
				type = "checkBox",
				description = L["Whether to show reminder text beneath Cooldown Icons."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().showText
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetIconPreferences().showText = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetShowText(key)
						end)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Shrink Text to Fit"],
				type = "checkBox",
				description = L["Whether to attempt to shrink reminder text beneath Cooldown Icons to fit within the Cooldown Icon width."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().shrinkTextToFit
				end,
				set = function(key)
					if type(key) == "boolean" then
						local preferences = GetIconPreferences()
						preferences.shrinkTextToFit = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit,
								preferences.width
							)
						end)
					end
				end,
				enabled = function()
					return enableIconOption() and GetIconPreferences().showText == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font"],
				type = "dropdown",
				itemsAreFonts = true,
				description = L["Font to use for text beneath Cooldown Icons."],
				category = L["Cooldown Icons"],
				values = fonts,
				get = function()
					return GetIconPreferences().font
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetIconPreferences()
						preferences.font = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit,
								preferences.width
							)
						end)
					end
				end,
				enabled = function()
					return enableIconOption() and GetIconPreferences().showText == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Size"],
				type = "lineEdit",
				description = L["Font size to use for text beneath Cooldown Icons (8 - 64)."],
				category = L["Cooldown Icons"],
				get = function()
					return GetIconPreferences().fontSize
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						local preferences = GetIconPreferences()
						preferences.fontSize = value
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit,
								preferences.width
							)
						end)
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						if value < kMinFontSize or value > kMaxFontSize then
							return false, Clamp(value, kMinFontSize, kMaxFontSize)
						else
							return true
						end
					else
						return false, GetIconPreferences().fontSize
					end
				end,
				enabled = function()
					return enableIconOption() and GetIconPreferences().showText == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Font Outline"],
				type = "dropdown",
				description = L["Font outline to use for text beneath Cooldown Icons."],
				category = L["Cooldown Icons"],
				values = fontOutlineValues,
				get = function()
					return GetIconPreferences().fontOutline
				end,
				set = function(key)
					if type(key) == "string" then
						local preferences = GetIconPreferences()
						preferences.fontOutline = key
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetFont(
								preferences.font,
								preferences.fontSize,
								preferences.fontOutline,
								preferences.shrinkTextToFit,
								preferences.width
							)
						end)
					end
				end,
				enabled = function()
					return enableIconOption() and GetIconPreferences().showText == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Text Color"],
				type = "colorPicker",
				description = L["Text color to use for text beneath Cooldown Icons."],
				category = L["Cooldown Icons"],
				get = function()
					local r, g, b, a = unpack(GetIconPreferences().textColor)
					return r, g, b, a
				end,
				set = function(r, g, b, a)
					if type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a) == "number" then
						GetIconPreferences().textColor = { r, g, b, a }
						CallAnchorFunction(AnchorType.Icon, function(icon)
							---@cast icon EPReminderIcon
							icon:SetTextColor(r, g, b, a)
						end)
					end
				end,
				enabled = function()
					return enableIconOption() and GetIconPreferences().showText == true
				end,
			} --[[@as EPSettingOption]],
			{
				label = "",
				get = function()
					return ""
				end,
				set = function() end,
				type = "horizontalLine",
				category = L["Cooldown Icons"],
			} --[[@as EPSettingOption]],
			{
				label = L["Position"],
				labels = { L["X"], L["Y"] },
				type = "doubleLineEdit",
				descriptions = {
					L["The horizontal offset from the Relative Anchor Point to the Anchor Point."],
					L["The vertical offset from the Relative Anchor Point to the Anchor Point."],
				},
				category = L["Cooldown Icons"],
				updateIndices = { 0, 1, 2, 3 },
				get = function()
					local p = GetIconPreferences()
					return p.x, p.y
				end,
				set = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						local preferences = GetIconPreferences()
						preferences.x, preferences.y = x, y
						local regionName = IsValidRegionName(preferences.relativeTo) and preferences.relativeTo
							or "UIParent"
						local region = _G[regionName] or UIParent
						if iconAnchor then
							iconAnchor.frame:SetPoint(preferences.point, region, preferences.relativePoint, x, y)
						end
					end
				end,
				enabled = enableIconOption,
				validate = function(key, key2)
					local x = tonumber(key)
					local y = tonumber(key2)
					if x and y then
						return true
					else
						local preferences = GetIconPreferences()
						return false, preferences.x, preferences.y
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Point"],
				type = "dropdown",
				description = L["Which spot on the Cooldown Icon container is fixed; Bottom will expand upwards, Top downwards, Left expands to the right, Right expands to the left, Center from center."],
				category = L["Cooldown Icons"],
				values = anchorPointValues,
				updateIndices = { -1, 0, 1, 2 },
				get = function()
					return GetIconPreferences().point
				end,
				set = function(key)
					if type(key) == "string" then
						local icons = GetIconPreferences()
						ApplyPointToAnchor(AnchorType.Icon, key, icons.relativeTo, icons.relativePoint)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Anchor Frame"],
				type = "frameChooser",
				description = L["The frame that the Cooldown Icon container is anchored to. Defaults to UIParent (screen)."],
				category = L["Cooldown Icons"],
				updateIndices = { -2, -1, 0, 1 },
				get = function()
					return GetIconPreferences().relativeTo
				end,
				set = function(key)
					if type(key) == "string" then
						local icons = GetIconPreferences()
						if iconAnchor and iconAnchor.frame:GetName() == key then
							key = icons.relativeTo
						end
						ApplyPointToAnchor(AnchorType.Icon, icons.point, key, icons.relativePoint)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Relative Anchor Point"],
				type = "dropdown",
				description = L["The anchor point on the frame that the Cooldown Icon container is anchored to."],
				category = L["Cooldown Icons"],
				values = anchorPointValues,
				updateIndices = { -3, -2, -1, 0 },
				get = function()
					return GetIconPreferences().relativePoint
				end,
				set = function(key)
					if type(key) == "string" then
						local icons = GetIconPreferences()
						ApplyPointToAnchor(AnchorType.Icon, icons.point, icons.relativeTo, key)
					end
				end,
				enabled = enableIconOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Play Text to Speech at Countdown Start"],
				type = "checkBox",
				description = L["Whether to play text to speech sound at the start of the countdown (i.e. Spell in x seconds)."],
				category = L["Text to Speech"],
				get = function()
					return GetReminderPreferences().textToSpeech.enableAtCountdownStart
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().textToSpeech.enableAtCountdownStart = key
					end
				end,
				enabled = enableReminderOption,
			} --[[@as EPSettingOption]],
			{
				label = L["Play Text to Speech at Countdown End"],
				type = "checkBox",
				description = L["Whether to play text to speech sound at the end of the countdown (i.e. speak spell or text)."],
				category = L["Text to Speech"],
				get = function()
					return GetReminderPreferences().textToSpeech.enableAtCountdownEnd
				end,
				set = function(key)
					if type(key) == "boolean" then
						GetReminderPreferences().textToSpeech.enableAtCountdownEnd = key
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
						and (
							preferences.textToSpeech.enableAtCountdownEnd
							or preferences.textToSpeech.enableAtCountdownStart
						)
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
						and (
							preferences.textToSpeech.enableAtCountdownEnd
							or preferences.textToSpeech.enableAtCountdownStart
						)
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
				label = L["Play Sound at Countdown Start"],
				labels = { L["Play Sound at Countdown Start"], L["Sound to Play at Countdown Start"] },
				type = "checkBoxWithDropdown",
				descriptions = {
					L["Whether to play a sound at the start of the countdown."],
					L["The sound to play at the start of the countdown."],
				},
				category = L["Sound"],
				values = sounds,
				get = {
					function()
						return GetReminderPreferences().sound.enableAtCountdownStart
					end,
					function()
						return GetReminderPreferences().sound.countdownStartSound
					end,
				},
				set = {
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.enableAtCountdownStart = key
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.countdownStartSound = key
						end
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						local preferences = GetReminderPreferences()
						return preferences.enabled == true and preferences.sound.enableAtCountdownStart == true
					end,
				},
			} --[[@as EPSettingOption]],
			{
				label = L["Play Sound at Countdown End"],
				labels = { L["Play Sound at Countdown End"], L["Sound to Play at Countdown End"] },
				type = "checkBoxWithDropdown",
				descriptions = {
					L["Whether to play a sound at the end of the countdown."],
					L["The sound to play at the end of the countdown."],
				},
				category = L["Sound"],
				values = sounds,
				get = {
					function()
						return GetReminderPreferences().sound.enableAtCountdownEnd
					end,
					function()
						return GetReminderPreferences().sound.countdownEndSound
					end,
				},
				set = {
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.enableAtCountdownEnd = key
						end
					end,
					function(key)
						if type(key) == "boolean" then
							GetReminderPreferences().sound.countdownEndSound = key
						end
					end,
				},
				enabled = {
					enableReminderOption,
					function()
						local preferences = GetReminderPreferences()
						return preferences.enabled == true and preferences.sound.enableAtCountdownEnd == true
					end,
				},
			} --[[@as EPSettingOption]],
		}
	end

	local floor = math.floor

	---@return table<integer, EPSettingOption>
	local function CreateViewOptions()
		local kMinimumRowHeight = 16.0
		local kMaximumRowHeight = 48.0
		local kMinimumNumberOfRows = 2
		local kNonTimelineHeight = constants.timeline.kHorizontalScrollBarHeight
			+ constants.timeline.kPaddingBetweenTimelineAndScrollBar
			+ constants.timeline.kPaddingBetweenTimelines
			+ constants.kStatusBarHeight
			+ constants.kStatusBarPadding
			+ constants.kWindowBarHeight
			+ constants.kMainFramePadding[2]
			+ constants.kMainFramePadding[4]
			+ constants.kTopContainerHeight
			+ constants.kMainFrameSpacing[2]

		return {
			{
				label = L["Number of Visible Rows"],
				type = "lineEdit",
				category = L["Assignment Timeline"],
				updateIndices = { 0, 1 },
				description = L["Number of assignment rows visible before scrolling is required."],
				get = function()
					return GetPreferences().timelineRows.numberOfAssignmentsToShow
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.numberOfAssignmentsToShow = utilities.Round(value, 0)
						if Private.mainFrame and Private.mainFrame.timeline then
							Private.mainFrame.timeline:UpdateHeightFromAssignments()
							Private.mainFrame:DoLayout()
						end
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						local numberOfAssignmentsToShow = utilities.Round(value, 0)
						local availableHeight = UIParent:GetHeight() - kNonTimelineHeight
						local timelineRows = GetPreferences().timelineRows
						local bossTimelineHeight = timelineRows.numberOfBossAbilitiesToShow
								* (timelineRows.bossAbilityHeight + 2)
							- 2
						local usableHeight = availableHeight - bossTimelineHeight - 2
						local maxRows = floor(usableHeight / (timelineRows.assignmentHeight + 2))

						if numberOfAssignmentsToShow < kMinimumNumberOfRows or numberOfAssignmentsToShow > maxRows then
							return false, Clamp(numberOfAssignmentsToShow, kMinimumNumberOfRows, maxRows)
						else
							return true
						end
					else
						return false, GetPreferences().timelineRows.numberOfAssignmentsToShow
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Row Height"],
				type = "lineEdit",
				category = L["Assignment Timeline"],
				updateIndices = { -1, 0 },
				description = L["The height of individual assignment rows in the timeline (16 - 48)."],
				get = function()
					return tostring(GetPreferences().timelineRows.assignmentHeight)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.assignmentHeight = utilities.Round(value, 0)
						if Private.mainFrame and Private.mainFrame.timeline then
							local lastOpenPlan = AddOn.db.profile.lastOpenPlan
							local plan = AddOn.db.profile.plans[lastOpenPlan]
							interfaceUpdater.UpdateAllAssignments(false, plan.dungeonEncounterID)
						end
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						local assignmentHeight = utilities.Round(value, 0)
						local availableHeight = UIParent:GetHeight() - kNonTimelineHeight
						local timelineRows = GetPreferences().timelineRows
						local bossTimelineHeight = timelineRows.numberOfBossAbilitiesToShow
								* (timelineRows.bossAbilityHeight + 2)
							- 2
						local usableHeight = availableHeight - bossTimelineHeight - 2
						local maxHeight =
							floor(min(kMaximumRowHeight, (usableHeight / timelineRows.numberOfAssignmentsToShow) - 2))

						if assignmentHeight < kMinimumRowHeight or assignmentHeight > maxHeight then
							return false, Clamp(assignmentHeight, kMinimumRowHeight, maxHeight)
						else
							return true
						end
					else
						return false, GetPreferences().timelineRows.assignmentHeight
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Assignee Sort Priority"],
				type = "dropdown",
				category = L["Assignment Timeline"],
				description = L["How to sort the assignee rows of the assignment timeline."],
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
				label = L["Show Spell Cooldown Duration And Charges"],
				type = "checkBox",
				category = L["Assignment Timeline"],
				description = L["Whether to show textures representing player spell cooldown durations and charges."],
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
			{
				label = L["Number of Visible Rows"],
				type = "lineEdit",
				category = L["Boss Ability Timeline"],
				updateIndices = { 0, 1 },
				description = L["Number of boss ability rows visible before scrolling is required."],
				get = function()
					return GetPreferences().timelineRows.numberOfBossAbilitiesToShow
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.numberOfBossAbilitiesToShow = utilities.Round(value, 0)
						if Private.mainFrame and Private.mainFrame.timeline then
							Private.mainFrame.timeline:UpdateHeightFromBossAbilities()
							Private.mainFrame:DoLayout()
						end
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						local numberOfBossAbilitiesToShow = utilities.Round(value, 0)
						local availableHeight = UIParent:GetHeight() - kNonTimelineHeight
						local timelineRows = GetPreferences().timelineRows
						local assignmentTimelineHeight = timelineRows.numberOfAssignmentsToShow
								* (timelineRows.assignmentHeight + 2)
							- 2
						local usableHeight = availableHeight - assignmentTimelineHeight - 2
						local maxRows = floor(usableHeight / (timelineRows.bossAbilityHeight + 2))

						if
							numberOfBossAbilitiesToShow <= kMinimumNumberOfRows
							or numberOfBossAbilitiesToShow > maxRows
						then
							return false, Clamp(numberOfBossAbilitiesToShow, kMinimumNumberOfRows, maxRows)
						else
							return true
						end
					else
						return false, GetPreferences().timelineRows.numberOfBossAbilitiesToShow
					end
				end,
			} --[[@as EPSettingOption]],
			{
				label = L["Row Height"],
				type = "lineEdit",
				category = L["Boss Ability Timeline"],
				updateIndices = { -1, 0 },
				description = L["The height of individual boss ability rows in the timeline (16 - 48)."],
				get = function()
					return tostring(GetPreferences().timelineRows.bossAbilityHeight)
				end,
				set = function(key)
					local value = tonumber(key)
					if value then
						GetPreferences().timelineRows.bossAbilityHeight = utilities.Round(value, 0)
						if Private.mainFrame and Private.mainFrame.timeline then
							local lastOpenPlan = AddOn.db.profile.lastOpenPlan
							local plan = AddOn.db.profile.plans[lastOpenPlan]
							interfaceUpdater.UpdateBoss(plan.dungeonEncounterID, false)
						end
					end
				end,
				validate = function(key)
					local value = tonumber(key)
					if value then
						local bossAbilityHeightHeight = utilities.Round(value, 0)
						local availableHeight = UIParent:GetHeight() - kNonTimelineHeight
						local timelineRows = GetPreferences().timelineRows
						local assignmentTimelineHeight = timelineRows.numberOfAssignmentsToShow
								* (timelineRows.assignmentHeight + 2)
							- 2
						local usableHeight = availableHeight - assignmentTimelineHeight - 2
						local maxHeight =
							floor(min(kMaximumRowHeight, (usableHeight / timelineRows.numberOfBossAbilitiesToShow) - 2))

						if bossAbilityHeightHeight < kMinimumRowHeight or bossAbilityHeightHeight > maxHeight then
							return false, Clamp(bossAbilityHeightHeight, kMinimumRowHeight, maxHeight)
						else
							return true
						end
					else
						return false, GetPreferences().timelineRows.bossAbilityHeight
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
			{
				label = L["Clear Trusted Characters"],
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
	local function GetCooldownOverrideOptions()
		return {
			{
				label = L["Cooldown Overrides"],
				type = "cooldownOverrides",
				get = function()
					return AddOn.db.profile.cooldownAndChargeOverrides
				end,
				set = function(value)
					if type(value) == "table" then
						---@cast value table<integer, CooldownAndChargeOverride>
						AddOn.db.profile.cooldownAndChargeOverrides = value
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

	---@return { [1]: string, [2]: table<integer, EPSettingOption>, [3]: table<integer, string>?}
	---@return { [1]: string, [2]: table<integer, EPSettingOption>, [3]: table<integer, string>?}>
	---@return { [1]: string, [2]: table<integer, EPSettingOption>, [3]: table<integer, string>?}>
	---@return { [1]: string, [2]: table<integer, EPSettingOption>, [3]: table<integer, string>?}>
	---@return { [1]: string, [2]: table<integer, EPSettingOption>, [3]: table<integer, string>?}>
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
		if not controlOptions then
			controlOptions = CreateControlOptions()
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
		local controlsTab = { L["Controls"], controlOptions, { L["Assignment Timeline"], L["Timeline"] } }
		local reminderTabs = { L["Messages"], L["Progress Bars"], L["Cooldown Icons"], L["Text to Speech"], L["Sound"] }
		local reminderTab = { L["Reminder"], reminderOptions, reminderTabs }
		local viewTab = { L["View"], viewOptions, { L["Assignment Timeline"], L["Boss Ability Timeline"] } }
		local profileTab = { L["Profile"], profileOptions }

		return cooldownOverrideTab, controlsTab, reminderTab, viewTab, profileTab
	end
end

-- Releases the message and progress bar anchors if they exist.
function Private:CloseAnchors()
	if messageAnchor then
		AceGUI:Release(messageAnchor)
	end
	messageAnchor = nil
	if progressBarAnchor then
		AceGUI:Release(progressBarAnchor)
	end
	progressBarAnchor = nil
	if iconAnchor then
		AceGUI:Release(iconAnchor)
	end
	iconAnchor = nil
end

local function CreateAnchors()
	Private:CloseAnchors()

	messageAnchor = CreateMessageAnchor()
	messageAnchor.frame:Hide()

	progressBarAnchor = CreateProgressBarAnchor()
	progressBarAnchor.frame:Hide()

	iconAnchor = CreateIconAnchor()
	iconAnchor.frame:Hide()
end

-- Releases the message and progress bar anchors if they exist and recreates them. Requires the options menu to be open.
function Private:RecreateAnchors()
	if Private.optionsMenu then
		CreateAnchors()
	end
end

-- Releases the options menu, message anchor, and progress bar anchor, if they exist.
function Private:ReleaseOptionsMenu()
	if self.optionsMenu then
		GetPreferences().lastOpenTab = self.optionsMenu.activeTab
		AceGUI:Release(self.optionsMenu)
	end
	self.optionsMenu = nil
	self:CloseAnchors()
end

-- Creates and shows the options menu. The message anchor and progress bar anchor are released when the options menu is
-- released.
function Private:CreateOptionsMenu()
	if not self.optionsMenu then
		local optionsMenu = AceGUI:Create("EPOptions")
		optionsMenu.spellDropdownItems = utilities.GetOrCreateSpellDropdownItems(false).dropdownItemMenuData
		optionsMenu.FormatTime = utilities.FormatTime
		optionsMenu.GetSpellCooldownAndCharges = utilities.GetSpellCooldownAndCharges
		optionsMenu.frame:SetParent(UIParent)
		optionsMenu.frame:SetFrameStrata("DIALOG")
		optionsMenu.frame:SetFrameLevel(kOptionsMenuFrameLevel)
		optionsMenu:SetCallback("OnRelease", function()
			self.optionsMenu = nil
		end)
		optionsMenu:SetCallback("CloseButtonClicked", function()
			self:ReleaseOptionsMenu()
			if self.activeTutorialCallbackName then
				self.callbacks:Fire(self.activeTutorialCallbackName, "optionsMenuClosed")
			end
		end)

		CreateAnchors()

		local cooldownOverrideTab, keyBindingsTab, reminderTab, viewTab, profileTab = optionCreator.GetOrCreateOptions()
		optionsMenu:AddOptionTab(cooldownOverrideTab[1], cooldownOverrideTab[2], cooldownOverrideTab[3])
		optionsMenu:AddOptionTab(keyBindingsTab[1], keyBindingsTab[2], keyBindingsTab[3])
		optionsMenu:AddOptionTab(reminderTab[1], reminderTab[2], reminderTab[3])
		optionsMenu:AddOptionTab(viewTab[1], viewTab[2], viewTab[3])
		optionsMenu:AddOptionTab(profileTab[1], profileTab[2], profileTab[3])
		optionsMenu:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		optionsMenu:SetCurrentTab(GetPreferences().lastOpenTab, L["Cooldown Overrides"])
		optionsMenu:SetPoint("TOP", UIParent, "TOP", 0, -optionsMenu.frame:GetBottom())

		self.optionsMenu = optionsMenu
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
