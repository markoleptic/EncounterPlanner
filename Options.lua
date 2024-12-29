---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class OptionsModule : AceModule
local OptionsModule = Private.addOn.optionsModule

---@class Utilities
local utilities = Private.utilities

---@class BossUtilities
local bossUtilities = Private.bossUtilities

---@class InterfaceUpdater
local interfaceUpdater = Private.interfaceUpdater

local AddOn = Private.addOn

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

local previewDuration = 15.0

local MouseButtonKeyBindingValues = {
	{ itemValue = "LeftButton", text = "Left Click" },
	{ itemValue = "Alt-LeftButton", text = "Alt + Left Click" },
	{ itemValue = "Ctrl-LeftButton", text = "Ctrl + Left Click" },
	{ itemValue = "Shift-LeftButton", text = "Shift + Left Click" },
	{ itemValue = "MiddleButton", text = "Middle Mouse Button" },
	{ itemValue = "Alt-MiddleButton", text = "Alt + Middle Mouse Button" },
	{ itemValue = "Ctrl-MiddleButton", text = "Ctrl + Middle Mouse Button" },
	{ itemValue = "Shift-MiddleButton", text = "Shift + Middle Mouse Button" },
	{ itemValue = "RightButton", text = "Right Click" },
	{ itemValue = "Alt-RightButton", text = "Alt + Right Click" },
	{ itemValue = "Ctrl-RightButton", text = "Ctrl + Right Click" },
	{ itemValue = "Shift-RightButton", text = "Shift + Right Click" },
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
	{ itemValue = "LEFT", text = "Left" },
	{ itemValue = "CENTER", text = "Center" },
	{ itemValue = "RIGHT", text = "Right" },
}

local anchorPointValues = {
	{ itemValue = "TOPLEFT", text = "Top Left" },
	{ itemValue = "TOP", text = "Top" },
	{ itemValue = "TOPRIGHT", text = "Top Right" },
	{ itemValue = "RIGHT", text = "Right" },
	{ itemValue = "BOTTOMRIGHT", text = "Bottom Right" },
	{ itemValue = "BOTTOM", text = "Bottom" },
	{ itemValue = "LEFT", text = "Left" },
	{ itemValue = "BOTTOMLEFT", text = "Bottom Left" },
	{ itemValue = "CENTER", text = "Center" },
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
---@param relativeFrame Frame|ScriptRegion|nil
---@param relativePoint AnchorPoint|nil
---@return AnchorPoint, string, AnchorPoint, number, number
local function ApplyPoint(frame, point, relativeFrame, relativePoint)
	local p, rF, rP, _, _ = frame:GetPoint()
	point = point or p
	relativeFrame = relativeFrame or rF
	relativePoint = relativePoint or rP
	local x, y = CalculateNewOffset(
		frame:GetLeft(),
		frame:GetTop(),
		frame:GetWidth(),
		frame:GetHeight(),
		point,
		relativeFrame:GetLeft(),
		relativeFrame:GetTop(),
		relativeFrame:GetWidth(),
		relativeFrame:GetHeight(),
		relativePoint
	)
	x = utilities.Round(x, 2)
	y = utilities.Round(y, 2)
	local relativeTo = relativeFrame:GetName()
	frame:ClearAllPoints()
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
	return point, relativeTo, relativePoint, x, y
end

---@return EPProgressBar
local function CreateProgressBarAnchor()
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]
	local progressBarAnchor = AceGUI:Create("EPProgressBar")
	progressBarAnchor:SetAnchorMode(true)
	progressBarAnchor:SetFont(
		reminderPreferences.progressBars.font,
		reminderPreferences.progressBars.fontSize,
		reminderPreferences.progressBars.fontOutline
	)
	progressBarAnchor:SetHorizontalTextAlignment(reminderPreferences.progressBars.textAlignment)
	progressBarAnchor:SetDurationTextAlignment(reminderPreferences.progressBars.durationAlignment)
	progressBarAnchor:SetTexture(reminderPreferences.progressBars.texture)
	progressBarAnchor:SetIconPosition(reminderPreferences.progressBars.iconPosition)
	progressBarAnchor:SetIconAndText([[Interface\Icons\INV_MISC_QUESTIONMARK]], "Progress Bar Text")
	progressBarAnchor:SetProgressBarWidth(reminderPreferences.progressBars.width)
	progressBarAnchor:SetFill(reminderPreferences.progressBars.fill)
	progressBarAnchor:SetCallback("OnRelease", function()
		Private.progressBarAnchor = nil
	end)
	progressBarAnchor:SetCallback("NewPoint", function(_, _, point, relativeFrame, relativePoint)
		local progressBars = reminderPreferences.progressBars
		progressBars.point, progressBars.relativeTo, progressBars.relativePoint, progressBars.x, progressBars.y =
			ApplyPoint(Private.progressBarAnchor.frame, point, relativeFrame, relativePoint)
		if Private.optionsMenu then
			Private.optionsMenu:UpdateOptions()
		end
	end)
	progressBarAnchor:SetCallback("Completed", function()
		progressBarAnchor:SetDuration(previewDuration)
		progressBarAnchor:Start()
	end)
	progressBarAnchor.frame:SetParent(UIParent)
	progressBarAnchor:SetDuration(previewDuration)
	progressBarAnchor.frame:SetPoint(
		reminderPreferences.progressBars.point,
		reminderPreferences.progressBars.relativeTo or UIParent,
		reminderPreferences.progressBars.relativePoint,
		reminderPreferences.progressBars.x,
		reminderPreferences.progressBars.y
	)
	return progressBarAnchor
end

---@return EPReminderMessage
local function CreateMessageAnchor()
	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]
	local messageAnchor = AceGUI:Create("EPReminderMessage")
	messageAnchor:SetAnchorMode(true)
	messageAnchor:SetFont(
		reminderPreferences.messages.font,
		reminderPreferences.messages.fontSize,
		reminderPreferences.messages.fontOutline
	)
	messageAnchor:SetIcon([[Interface\Icons\INV_MISC_QUESTIONMARK]])
	messageAnchor:SetCallback("OnRelease", function()
		Private.messageAnchor = nil
	end)
	messageAnchor:SetCallback("NewPoint", function(_, _, point, relativeFrame, relativePoint)
		local messages = reminderPreferences.messages
		messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
			ApplyPoint(Private.messageAnchor.frame, point, relativeFrame, relativePoint)
		if Private.optionsMenu then
			Private.optionsMenu:UpdateOptions()
		end
	end)
	messageAnchor:SetCallback("Completed", function()
		messageAnchor:SetDuration(previewDuration)
		messageAnchor:Start()
	end)
	messageAnchor.frame:SetParent(UIParent)
	messageAnchor.frame:SetPoint(
		reminderPreferences.messages.point,
		reminderPreferences.messages.relativeTo or UIParent,
		reminderPreferences.messages.relativePoint,
		reminderPreferences.messages.x,
		reminderPreferences.messages.y
	)
	return messageAnchor
end

function Private:CreateOptionsMenu()
	local optionsMenu = AceGUI:Create("EPOptions")
	if Private.mainFrame then
		optionsMenu.frame:SetParent(Private.mainFrame.frame)
	else
		optionsMenu.frame:SetParent(UIParent)
		optionsMenu.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	end
	optionsMenu.frame:SetFrameLevel(100)
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

	local keyBindingOptions = {
		{
			label = "Pan",
			type = "dropdown",
			description = "Pans the timeline to the left and right when holding this key.",
			category = "Timeline",
			values = MouseButtonKeyBindingValues,
			get = function()
				return AddOn.db.profile.preferences.keyBindings.pan
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.pan = key
			end,
			validate = function(key)
				if
					AddOn.db.profile.preferences.keyBindings.editAssignment == key
					or AddOn.db.profile.preferences.keyBindings.newAssignment == key
				then
					return false, AddOn.db.profile.preferences.keyBindings.pan
				end
				return true
			end,
		},
		{
			label = "Scroll",
			type = "dropdown",
			description = "Scrolls the timeline up and down.",
			category = "Timeline",
			values = {
				{ itemValue = "MouseScroll", text = "Mouse Scroll" },
				{ itemValue = "Alt-MouseScroll", text = "Alt + Mouse Scroll" },
				{ itemValue = "Ctrl-MouseScroll", text = "Ctrl + Mouse Scroll" },
				{ itemValue = "Shift-MouseScroll", text = "Shift + Mouse Scroll" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.scroll
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.scroll = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.zoom == key then
					return false, AddOn.db.profile.preferences.keyBindings.scroll
				end
				return true
			end,
		},
		{
			label = "Zoom",
			type = "dropdown",
			description = "Zooms in horizontally on the timeline.",
			category = "Timeline",
			values = {
				{ itemValue = "MouseScroll", text = "Mouse Scroll" },
				{ itemValue = "Alt-MouseScroll", text = "Alt + Mouse Scroll" },
				{ itemValue = "Ctrl-MouseScroll", text = "Ctrl + Mouse Scroll" },
				{ itemValue = "Shift-MouseScroll", text = "Shift + Mouse Scroll" },
			},
			get = function()
				return AddOn.db.profile.preferences.keyBindings.zoom
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.zoom = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.scroll == key then
					return false, AddOn.db.profile.preferences.keyBindings.zoom
				end
				return true
			end,
		},
		{
			label = "Add Assignment",
			type = "dropdown",
			description = "Creates a new assignment when this key is pressed when hovering over the timeline.",
			category = "Assignment",
			values = MouseButtonKeyBindingValues,
			get = function(_)
				return AddOn.db.profile.preferences.keyBindings.newAssignment
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.newAssignment = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.pan == key then
					return false, AddOn.db.profile.preferences.keyBindings.newAssignment
				end
				return true
			end,
		},
		{
			label = "Edit Assignment",
			type = "dropdown",
			description = "Opens the assignment editor when this key is pressed when hovering over an assignment spell icon.",
			category = "Assignment",
			values = MouseButtonKeyBindingValues,
			get = function()
				return AddOn.db.profile.preferences.keyBindings.editAssignment
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.editAssignment = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.pan == key then
					return false, AddOn.db.profile.preferences.keyBindings.editAssignment
				elseif AddOn.db.profile.preferences.keyBindings.duplicateAssignment == key then
					return false, AddOn.db.profile.preferences.keyBindings.editAssignment
				end
				return true
			end,
		},
		{
			label = "Duplicate Assignment",
			type = "dropdown",
			description = "Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key.",
			category = "Assignment",
			values = MouseButtonKeyBindingValues,
			get = function()
				return AddOn.db.profile.preferences.keyBindings.duplicateAssignment
			end,
			set = function(key)
				AddOn.db.profile.preferences.keyBindings.duplicateAssignment = key
			end,
			validate = function(key)
				if AddOn.db.profile.preferences.keyBindings.editAssignment == key then
					return false, AddOn.db.profile.preferences.keyBindings.duplicateAssignment
				end
				return true
			end,
		},
	}

	local viewOptions = {
		{
			label = "Preferred Number of Assignments to Show",
			type = "dropdown",
			description = "The assignment timeline will attempt to expand or shrink to show this many rows.",
			values = rowValues,
			get = function()
				return tostring(AddOn.db.profile.preferences.timelineRows.numberOfAssignmentsToShow)
			end,
			set = function(key)
				AddOn.db.profile.preferences.timelineRows.numberOfAssignmentsToShow = tonumber(key)
				local timeline = Private.mainFrame.timeline
				if timeline then
					timeline:UpdateHeightFromAssignments()
					Private.mainFrame:DoLayout()
				end
			end,
		},
		{
			label = "Preferred Number of Boss Abilities to Show",
			type = "dropdown",
			description = "The boss ability timeline will attempt to expand or shrink to show this many rows.",
			values = rowValues,
			get = function()
				return tostring(AddOn.db.profile.preferences.timelineRows.numberOfBossAbilitiesToShow)
			end,
			set = function(key)
				AddOn.db.profile.preferences.timelineRows.numberOfBossAbilitiesToShow = tonumber(key)
				local timeline = Private.mainFrame.timeline
				if timeline then
					timeline:UpdateHeightFromBossAbilities()
					Private.mainFrame:DoLayout()
				end
			end,
		},
		{
			label = "Timeline Zoom Center",
			type = "radioButtonGroup",
			description = "Where to center the zoom when zooming in on the timeline.",
			category = "Assignment",
			values = {
				{ itemValue = "At cursor", text = "At cursor" },
				{ itemValue = "Middle of timeline", text = "Middle of timeline" },
			},
			get = function()
				if AddOn.db.profile.preferences.zoomCenteredOnCursor == true then
					return "At cursor"
				else
					return "Middle of timeline"
				end
			end,
			set = function(key)
				if key == "At cursor" then
					AddOn.db.profile.preferences.zoomCenteredOnCursor = true
				else
					AddOn.db.profile.preferences.zoomCenteredOnCursor = false
				end
			end,
		},
		{
			label = "Assignment Sort Priority",
			type = "dropdown",
			description = "Sorts the rows of the assignment timeline.",
			category = "Assignment",
			values = {
				{ itemValue = "Alphabetical", text = "Alphabetical" },
				{ itemValue = "First Appearance", text = "First Appearance" },
				{ itemValue = "Role > Alphabetical", text = "Role > Alphabetical" },
				{ itemValue = "Role > First Appearance", text = "Role > First Appearance" },
			},
			get = function()
				return AddOn.db.profile.preferences.assignmentSortType
			end,
			set = function(key)
				if key ~= AddOn.db.profile.preferences.assignmentSortType then
					AddOn.db.profile.preferences.assignmentSortType = key
					if Private.mainFrame.bossSelectDropdown then
						local bossName =
							bossUtilities.GetBossDefinition(Private.mainFrame.bossSelectDropdown:GetValue()).name
						interfaceUpdater.UpdateAllAssignments(false, bossName)
					end
				end
				AddOn.db.profile.preferences.assignmentSortType = key
			end,
		},
		{
			label = "Show Spell Cooldown Duration",
			type = "checkBox",
			description = "Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key.",
			category = "Assignment",
			get = function()
				return AddOn.db.profile.preferences.showSpellCooldownDuration
			end,
			set = function(key)
				if key ~= AddOn.db.profile.preferences.showSpellCooldownDuration then
					AddOn.db.profile.preferences.showSpellCooldownDuration = key
					if Private.mainFrame.timeline then
						Private.mainFrame.timeline:UpdateTimeline()
					end
				end
				AddOn.db.profile.preferences.showSpellCooldownDuration = key
			end,
		},
	}

	local sounds = {}
	for name, value in pairs(LSM:HashTable("sound")) do
		tinsert(sounds, { itemValue = value, text = name })
	end
	sort(sounds, function(a, b)
		return a.text < b.text
	end)

	local fonts = {}
	for name, value in pairs(LSM:HashTable("font")) do
		tinsert(fonts, { itemValue = value, text = name })
	end
	sort(fonts, function(a, b)
		return a.text < b.text
	end)

	local statusBarTextures = {}
	for name, value in pairs(LSM:HashTable("statusbar")) do
		tinsert(statusBarTextures, { itemValue = value, text = name })
	end
	sort(statusBarTextures, function(a, b)
		return a.text < b.text
	end)

	local fontOutlineValues = {
		{ itemValue = "", text = "None" },
		{ itemValue = "MONOCHROME", text = "Monochrome" },
		{ itemValue = "OUTLINE", text = "Outline" },
		{ itemValue = "THICKOUTLINE", text = "Thick Outline" },
	}

	local voices = {}
	for _, ttsVoiceTable in pairs(GetTtsVoices()) do
		tinsert(voices, { itemValue = ttsVoiceTable.voiceID, text = ttsVoiceTable.name })
	end

	local reminderPreferences = AddOn.db.profile.preferences.reminder --[[@as ReminderPreferences]]

	local enableReminderOption = function()
		return reminderPreferences.enabled == true
	end

	local reminderOptions = {
		{
			label = "Enable Reminders",
			type = "checkBox",
			description = "Whether to enable reminders for assignments.",
			get = function()
				return reminderPreferences.enabled
			end,
			set = function(key)
				if key ~= reminderPreferences.enabled and key == false then
					if Private.messageAnchor.frame:IsShown() then
						Private.messageAnchor:Pause()
						Private.messageAnchor.frame:Hide()
					end
					if Private.progressBarAnchor.frame:IsShown() then
						Private.progressBarAnchor:Pause()
						Private.progressBarAnchor.frame:Hide()
					end
				end
				reminderPreferences.enabled = key
			end,
		},
		{
			label = "Only Show Reminders For Me",
			type = "checkBox",
			description = "Whether to only show assignment reminders that are relevant to you.",
			enabled = enableReminderOption,
			get = function()
				return reminderPreferences.onlyShowMe
			end,
			set = function(key)
				reminderPreferences.onlyShowMe = key
			end,
		},
		{
			label = "Hide or Cancel if Spell on Cooldown",
			type = "checkBox",
			description = "If an assignment is a spell and it already on cooldown, the assignment will not be shown. If the spell is cast during its countdown, it will be cancelled.",
			enabled = enableReminderOption,
			get = function()
				return reminderPreferences.cancelIfAlreadyCasted
			end,
			set = function(key)
				reminderPreferences.cancelIfAlreadyCasted = key
			end,
		},
		{
			label = "Reminder Advance Notice",
			type = "lineEdit",
			description = "How far ahead of assignment time to begin showing reminders.",
			category = nil,
			values = nil,
			get = function()
				return tostring(reminderPreferences.advanceNotice)
			end,
			set = function(key)
				local value = tonumber(key)
				if value then
					reminderPreferences.advanceNotice = value
				end
			end,
			enabled = enableReminderOption,
		},
		{
			label = "Enable Messages",
			type = "checkBoxBesideButton",
			description = "Whether to show Messages for assignments.",
			category = "Messages",
			get = function()
				return reminderPreferences.messages.enabled
			end,
			set = function(key)
				if key ~= reminderPreferences.messages.enabled and key == false then
					if Private.messageAnchor.frame:IsShown() then
						Private.messageAnchor:Pause()
						Private.messageAnchor.frame:Hide()
					end
				end
				reminderPreferences.messages.enabled = key
			end,
			enabled = enableReminderOption,
			buttonText = "Toggle Message Anchor",
			buttonEnabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			buttonCallback = function()
				if Private.messageAnchor.frame:IsShown() then
					Private.messageAnchor:Pause()
					Private.messageAnchor.frame:Hide()
				else
					if not reminderPreferences.messages.showOnlyAtExpiration then
						Private.messageAnchor:SetDuration(previewDuration)
						Private.messageAnchor:Start()
					end
					Private.messageAnchor.frame:Show()
				end
			end,
		},
		{
			label = "Message Visibility",
			type = "radioButtonGroup",
			description = "When to show the Messages for assignments.",
			category = "Messages",
			values = {
				{ itemValue = "expirationOnly", text = "Expiration Only" },
				{ itemValue = "fullCountdown", text = "With Countdown" },
			},
			get = function()
				if reminderPreferences.messages.showOnlyAtExpiration then
					return "expirationOnly"
				else
					return "fullCountdown"
				end
			end,
			set = function(key)
				if key == "expirationOnly" then
					if reminderPreferences.messages.showOnlyAtExpiration ~= true then
						if Private.messageAnchor.frame:IsShown() then
							Private.messageAnchor:Pause()
							Private.messageAnchor:SetDuration(0)
						end
					end
					reminderPreferences.messages.showOnlyAtExpiration = true
				else
					if reminderPreferences.messages.showOnlyAtExpiration ~= false then
						if Private.messageAnchor.frame:IsShown() then
							Private.messageAnchor:SetDuration(previewDuration)
							Private.messageAnchor:Start()
						end
					end
					reminderPreferences.messages.showOnlyAtExpiration = false
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Anchor Point",
			type = "dropdown",
			description = 'Anchor point of the Message frame, or the "spot" on the Message frame that will be placed relative to another frame.',
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { 0, 1, 2, 3 },
			get = function()
				return reminderPreferences.messages.point
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y = ApplyPoint(
					Private.messageAnchor.frame,
					key,
					_G[messages.relativeTo] or UIParent,
					messages.relativePoint
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Anchor Frame",
			type = "frameChooser",
			description = "The frame that the Message frame is anchored to. Defaults to UIParent (screen).",
			category = "Messages",
			updateIndices = { -1, 0, 1, 2 },
			get = function()
				return reminderPreferences.messages.relativeTo
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
					ApplyPoint(Private.messageAnchor.frame, messages.point, _G[key] or UIParent, messages.relativePoint)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Relative Anchor Point",
			type = "dropdown",
			description = "The anchor point on the frame that the Message frame is anchored to.",
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { -2, -1, 0, 1 },
			get = function()
				return reminderPreferences.messages.relativePoint
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y =
					ApplyPoint(Private.messageAnchor.frame, messages.point, _G[messages.relativeTo] or UIParent, key)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Position",
			labels = { "X:", "Y:" },
			type = "doubleLineEdit",
			description = "The offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point.",
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { -3, -2, -1, 0 },
			get = function()
				return reminderPreferences.messages.x, reminderPreferences.messages.y
			end,
			set = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key2)
				if x and y then
					reminderPreferences.messages.x = x
					reminderPreferences.messages.y = y
					local messages = reminderPreferences.messages
					Private.messageAnchor.frame:SetPoint(
						messages.point,
						_G[messages.relativeTo] or UIParent,
						messages.relativePoint,
						x,
						y
					)
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key2)
				if x and y then
					return true
				end
				return false, reminderPreferences.messages.x, reminderPreferences.messages.y
			end,
		},
		{
			type = "horizontalLine",
			category = "Messages",
		},
		{
			label = "Font",
			type = "dropdown",
			description = "Font to use for Message text.",
			category = "Messages",
			values = fonts,
			get = function()
				return reminderPreferences.messages.font
			end,
			set = function(key)
				reminderPreferences.messages.font = key
				Private.messageAnchor:SetFont(
					reminderPreferences.messages.font,
					reminderPreferences.messages.fontSize,
					reminderPreferences.messages.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Font Size",
			type = "lineEdit",
			description = "Font size to use for Message text.",
			category = "Messages",
			get = function()
				return reminderPreferences.messages.fontSize
			end,
			set = function(key)
				reminderPreferences.messages.fontSize = key
				Private.messageAnchor:SetFont(
					reminderPreferences.messages.font,
					reminderPreferences.messages.fontSize,
					reminderPreferences.messages.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				local valid = false
				local value = tonumber(key)
				if value then
					valid = value >= 8 and value <= 48
				end
				if not valid then
					return false, reminderPreferences.messages.fontSize
				end
				return true
			end,
		},
		{
			label = "Font Outline",
			type = "dropdown",
			description = "Font outline to use for Message text.",
			category = "Messages",
			values = fontOutlineValues,
			get = function()
				return reminderPreferences.messages.fontOutline
			end,
			set = function(key)
				reminderPreferences.messages.fontOutline = key
				Private.messageAnchor:SetFont(
					reminderPreferences.messages.font,
					reminderPreferences.messages.fontSize,
					reminderPreferences.messages.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
		},
		{
			label = "Enable Progress Bars",
			type = "checkBoxBesideButton",
			description = "Whether to show Progress Bars for assignments.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.enabled
			end,
			set = function(key)
				if key ~= reminderPreferences.progressBars.enabled and key == false then
					if Private.progressBarAnchor.frame:IsShown() then
						Private.progressBarAnchor:Pause()
						Private.progressBarAnchor.frame:Hide()
					end
				end
				reminderPreferences.progressBars.enabled = key
			end,
			enabled = enableReminderOption,
			buttonText = "Toggle Progress Bar Anchor",
			buttonEnabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
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
		},
		{
			label = "Anchor Point",
			type = "dropdown",
			description = 'Anchor point of the Progress Bars frame, or the "spot" on the Progress Bars frame that will be placed relative to another frame.',
			category = "Progress Bars",
			values = anchorPointValues,
			updateIndices = { 0, 1, 2, 3 },
			get = function()
				return reminderPreferences.progressBars.point
			end,
			set = function(key)
				local progressBars = reminderPreferences.progressBars
				progressBars.point, progressBars.relativeTo, progressBars.relativePoint, progressBars.x, progressBars.y =
					ApplyPoint(
						Private.progressBarAnchor.frame,
						key,
						_G[progressBars.relativeTo] or UIParent,
						progressBars.relativePoint
					)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Anchor Frame",
			type = "frameChooser",
			description = "The frame that the Progress Bars frame is anchored to. Defaults to UIParent (screen).",
			category = "Progress Bars",
			updateIndices = { -1, 0, 1, 2 },
			get = function()
				return reminderPreferences.progressBars.relativeTo
			end,
			set = function(key)
				local progressBars = reminderPreferences.progressBars
				progressBars.point, progressBars.relativeTo, progressBars.relativePoint, progressBars.x, progressBars.y =
					ApplyPoint(
						Private.progressBarAnchor.frame,
						progressBars.point,
						_G[key] or UIParent,
						progressBars.relativePoint
					)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Relative Anchor Point",
			type = "dropdown",
			description = "The anchor point on the frame that the Progress Bars frame is anchored to.",
			category = "Progress Bars",
			values = anchorPointValues,
			updateIndices = { -2, -1, 0, 1 },
			get = function()
				return reminderPreferences.progressBars.relativePoint
			end,
			set = function(key)
				local progressBars = reminderPreferences.progressBars
				progressBars.point, progressBars.relativeTo, progressBars.relativePoint, progressBars.x, progressBars.y =
					ApplyPoint(
						Private.progressBarAnchor.frame,
						progressBars.point,
						_G[progressBars.relativeTo] or UIParent,
						key
					)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Position",
			type = "doubleLineEdit",
			description = "The offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point.",
			category = "Progress Bars",
			values = anchorPointValues,
			updateIndices = { -3, -2, -1, 0 },
			get = function()
				return reminderPreferences.progressBars.x, reminderPreferences.progressBars.y
			end,
			set = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key2)
				if x and y then
					reminderPreferences.progressBars.x = x
					reminderPreferences.progressBars.y = y
					local progressBars = reminderPreferences.progressBars
					Private.progressBarAnchor.frame:SetPoint(
						progressBars.point,
						_G[progressBars.relativeTo] or UIParent,
						progressBars.relativePoint,
						x,
						y
					)
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key2)
				if x and y then
					return true
				end
				return false, reminderPreferences.progressBars.x, reminderPreferences.progressBars.y
			end,
		},
		{
			type = "horizontalLine",
			category = "Progress Bars",
		},
		{
			label = "Font",
			type = "dropdown",
			description = "Font to use for Progress Bar text.",
			category = "Progress Bars",
			values = fonts,
			get = function()
				return reminderPreferences.progressBars.font
			end,
			set = function(key)
				reminderPreferences.progressBars.font = key
				Private.progressBarAnchor:SetFont(
					reminderPreferences.progressBars.font,
					reminderPreferences.progressBars.fontSize,
					reminderPreferences.progressBars.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Font Size",
			type = "lineEdit",
			description = "Font size to use for Progress Bar text.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.fontSize
			end,
			set = function(key)
				reminderPreferences.progressBars.fontSize = key
				Private.progressBarAnchor:SetFont(
					reminderPreferences.progressBars.font,
					reminderPreferences.progressBars.fontSize,
					reminderPreferences.progressBars.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				local valid = false
				local value = tonumber(key)
				if value then
					valid = value >= 8 and value <= 48
				end
				if not valid then
					return false, reminderPreferences.progressBars.fontSize
				end
				return true
			end,
		},
		{
			label = "Font Outline",
			type = "dropdown",
			description = "Font outline to use for Progress Bar text.",
			category = "Progress Bars",
			values = fontOutlineValues,
			get = function()
				return reminderPreferences.progressBars.fontOutline
			end,
			set = function(key)
				reminderPreferences.progressBars.fontOutline = key
				Private.progressBarAnchor:SetFont(
					reminderPreferences.progressBars.font,
					reminderPreferences.progressBars.fontSize,
					reminderPreferences.progressBars.fontOutline
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Text Alignment",
			type = "radioButtonGroup",
			description = "Alignment of Progress Bar text.",
			category = "Progress Bars",
			values = textAlignmentValues,
			get = function()
				return reminderPreferences.progressBars.textAlignment
			end,
			set = function(key)
				reminderPreferences.progressBars.textAlignment = key
				Private.progressBarAnchor:SetHorizontalTextAlignment(reminderPreferences.progressBars.textAlignment)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Duration Alignment",
			type = "radioButtonGroup",
			description = "Alignment of Progress Bar duration text.",
			category = "Progress Bars",
			values = textAlignmentValues,
			get = function()
				return reminderPreferences.progressBars.durationAlignment
			end,
			set = function(key)
				reminderPreferences.progressBars.durationAlignment = key
				Private.progressBarAnchor:SetDurationTextAlignment(reminderPreferences.progressBars.durationAlignment)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			type = "horizontalLine",
			category = "Progress Bars",
		},
		{
			label = "Bar Texture",
			type = "dropdown",
			description = "The texture to use for the Progress Bar foreground and background.",
			category = "Progress Bars",
			values = statusBarTextures,
			get = function()
				return reminderPreferences.progressBars.texture
			end,
			set = function(key)
				reminderPreferences.progressBars.texture = key
				Private.progressBarAnchor:SetTexture(reminderPreferences.progressBars.texture)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Bar Width",
			type = "lineEdit",
			description = "The width of Progress Bars.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.width
			end,
			set = function(key)
				reminderPreferences.progressBars.width = key
				Private.progressBarAnchor:SetProgressBarWidth(reminderPreferences.progressBars.width)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				local value = tonumber(key)
				local valid = false
				if value then
					valid = value > 0 and value < 500
				end
				if valid then
					return true
				else
					return false, reminderPreferences.progressBars.width
				end
			end,
		},
		{
			label = "Bar Progress Type",
			type = "radioButtonGroup",
			description = "Whether to fill or drain Progress Bars.",
			category = "Progress Bars",
			values = { { itemValue = "fill", text = "Fill" }, { itemValue = "drain", text = "Drain" } },
			get = function()
				if reminderPreferences.progressBars.fill == true then
					return "fill"
				else
					return "drain"
				end
			end,
			set = function(key)
				if key == "fill" then
					reminderPreferences.progressBars.fill = true
				else
					reminderPreferences.progressBars.fill = false
				end
				Private.progressBarAnchor:SetFill(reminderPreferences.progressBars.fill)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Icon Position",
			type = "radioButtonGroup",
			description = "Which side to place the icon for Progress Bars.",
			category = "Progress Bars",
			values = { { itemValue = "LEFT", text = "Left" }, { itemValue = "RIGHT", text = "Right" } },
			get = function()
				return reminderPreferences.progressBars.iconPosition
			end,
			set = function(key)
				reminderPreferences.progressBars.iconPosition = key
				Private.progressBarAnchor:SetIconPosition(reminderPreferences.progressBars.iconPosition)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
		},
		{
			label = "Play Text to Speech at Advance Notice",
			type = "checkBox",
			description = "Whether to play text to speech sound at advance notice time (i.e. Spell in x seconds).",
			category = "Text to Speech",
			values = nil,
			get = function()
				return reminderPreferences.textToSpeech.enableAtAdvanceNotice
			end,
			set = function(key)
				reminderPreferences.textToSpeech.enableAtAdvanceNotice = key
			end,
			enabled = enableReminderOption,
		},
		{
			label = "Play Text to Speech at Assignment Time",
			type = "checkBox",
			description = "Whether to play text to speech sound at assignment time (i.e. Spell in x seconds).",
			category = "Text to Speech",
			get = function()
				return reminderPreferences.textToSpeech.enableAtTime
			end,
			set = function(key)
				reminderPreferences.textToSpeech.enableAtTime = key
			end,
			enabled = enableReminderOption,
		},
		{
			label = "Text to Speech Voice",
			type = "dropdown",
			description = "The voice to use for Text to Speech",
			category = "Text to Speech",
			values = voices,
			get = function()
				return reminderPreferences.textToSpeech.voiceID
			end,
			set = function(key)
				reminderPreferences.textToSpeech.voiceID = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true
					and (
						reminderPreferences.textToSpeech.enableAtTime
						or reminderPreferences.textToSpeech.enableAtAdvanceNotice
					)
			end,
		},
		{
			label = "Text to Speech Volume",
			type = "lineEdit",
			description = "The volume to use for Text to Speech",
			category = "Text to Speech",
			get = function()
				return tostring(reminderPreferences.textToSpeech.volume)
			end,
			set = function(key)
				local value = tonumber(key)
				if value then
					reminderPreferences.textToSpeech.volume = value
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true
					and (
						reminderPreferences.textToSpeech.enableAtTime
						or reminderPreferences.textToSpeech.enableAtAdvanceNotice
					)
			end,
			validate = function(key)
				local valid = false
				local value = tonumber(key)
				if value then
					valid = value >= 0 and value <= 100
				end
				if not valid then
					return false, reminderPreferences.textToSpeech.volume
				end
				return true
			end,
		},
		{
			label = "Play Sound at Advance Notice",
			type = "checkBox",
			description = "Whether to play a sound at advance notice time.",
			category = "Sound",
			get = function()
				return reminderPreferences.sound.enableAtAdvanceNotice
			end,
			set = function(key)
				reminderPreferences.sound.enableAtAdvanceNotice = key
			end,
			enabled = enableReminderOption,
		},
		{
			label = "Sound to Play",
			type = "dropdown",
			description = "The sound to play at advance notice time.",
			category = "Sound",
			indent = true,
			values = sounds,
			get = function()
				return reminderPreferences.sound.advanceNoticeSound
			end,
			set = function(key)
				reminderPreferences.sound.advanceNoticeSound = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.sound.enableAtAdvanceNotice == true
			end,
		},
		{
			label = "Play Sound at Assignment Time",
			type = "checkBox",
			description = "Whether to play a sound at assignment time.",
			category = "Sound",
			get = function()
				return reminderPreferences.sound.enableAtTime
			end,
			set = function(key)
				reminderPreferences.sound.enableAtTime = key
			end,
			enabled = enableReminderOption,
		},
		{
			label = "Sound to Play",
			type = "dropdown",
			description = "The sound to play at assignment time.",
			category = "Sound",
			indent = true,
			values = sounds,
			get = function()
				return reminderPreferences.sound.atSound
			end,
			set = function(key)
				reminderPreferences.sound.atSound = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.sound.enableAtTime == true
			end,
		},
	}

	Private.messageAnchor = CreateMessageAnchor()
	Private.messageAnchor.frame:Hide()

	Private.progressBarAnchor = CreateProgressBarAnchor()
	Private.progressBarAnchor.frame:Hide()

	optionsMenu:AddOptionTab("Keybindings", keyBindingOptions, { "Assignment", "Timeline" })
	optionsMenu:AddOptionTab("Reminder", reminderOptions, { "Messages", "Progress Bars", "Text to Speech", "Sound" })
	optionsMenu:AddOptionTab("View", viewOptions, { "Assignment" })
	optionsMenu:SetCurrentTab("Keybindings")

	if Private.mainFrame then
		optionsMenu.frame:SetPoint("CENTER", Private.mainFrame.frame, "CENTER", 0, 0)
		optionsMenu.frame:SetSize(500, Private.mainFrame.frame:GetHeight())
	else
		optionsMenu.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	Private.optionsMenu = optionsMenu
end

function OptionsModule:OnInitialize()
	self:CreateOptions()
end

function OptionsModule:CreateOptions()
	ACR:RegisterOptionsTable(AddOnName, self:GetOptions())
	ACD:SetDefaultSize(AddOnName, 700, 500)
	ACD:AddToBlizOptions(AddOnName)
end

function OptionsModule:GetOptions()
	local options = {
		name = AddOnName,
		type = "group",
		args = {
			[""] = {
				name = "Open Preferences",
				type = "execute",
				width = 200,
				func = function()
					if not Private.optionsMenu then
						Private:CreateOptionsMenu()
					end
				end,
			},
		},
	}
	return options
end

function OptionsModule:OpenOptions()
	ACD:Open(AddOnName)
end
