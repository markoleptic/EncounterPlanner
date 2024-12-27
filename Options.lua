---@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

---@class OptionsModule : AceModule
local OptionsModule = Private.addOn.optionsModule

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
	local relativeTo = relativeFrame:GetName()
	frame:ClearAllPoints()
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
	return point, relativeTo, relativePoint, x, y
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
		Private.messageAnchor:Release()
		Private.progressBarAnchor:Release()
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
			category = nil,
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
			validate = function(key)
				return true
			end,
		},
		{
			label = "Preferred Number of Boss Abilities to Show",
			type = "dropdown",
			description = "The boss ability timeline will attempt to expand or shrink to show this many rows.",
			category = nil,
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
			validate = function(key)
				return true
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
			validate = function(key)
				return true
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
			validate = function(key)
				return true
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
		tinsert(sounds, { itemValue = value, text = name })
	end
	sort(fonts, function(a, b)
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
		[1] = {
			label = "Enable Reminders",
			type = "checkBox",
			description = "Whether to enable reminders for assignments.",
			get = function()
				return reminderPreferences.enabled
			end,
			set = function(key)
				reminderPreferences.enabled = key
			end,
			validate = function(key)
				return true
			end,
		},
		[2] = {
			label = "Only Show Reminders For Me",
			type = "checkBox",
			description = "Whether to show assignment reminders that are only relevant to you.",
			enabled = enableReminderOption,
			get = function()
				return reminderPreferences.onlyShowMe
			end,
			set = function(key)
				reminderPreferences.onlyShowMe = key
			end,
			validate = function(key)
				return true
			end,
		},
		[3] = {
			label = "Don't Show/Cancel if Already Casted",
			type = "checkBox",
			description = "If the assignment is a spell, don't show the assignment or cancel it.",
			enabled = enableReminderOption,
			get = function()
				return reminderPreferences.cancelIfAlreadyCasted
			end,
			set = function(key)
				reminderPreferences.cancelIfAlreadyCasted = key
			end,
			validate = function(key)
				return true
			end,
		},
		[4] = {
			label = "Reminder Advance Notice",
			type = "lineEdit",
			description = "How far ahead of assignment time to begin showing reminder widgets.",
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
			validate = function(key)
				return true
			end,
		},
		[5] = {
			label = "Enable Messages",
			type = "checkBox",
			description = "Whether to show messages widgets for assignments.",
			get = function()
				return reminderPreferences.messages.enabled
			end,
			set = function(key)
				reminderPreferences.messages.enabled = key
			end,
			enabled = enableReminderOption,
			validate = function(key)
				return true
			end,
		},
		[6] = {
			label = "Text Alignment",
			type = "radioButtonGroup",
			description = "Alignment of Message text.",
			category = "Messages",
			values = textAlignmentValues,
			get = function()
				return reminderPreferences.messages.textAlignment
			end,
			set = function(key)
				reminderPreferences.messages.textAlignment = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[7] = {
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
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[8] = {
			label = "Font Size",
			type = "lineEdit",
			description = "Font size to use for Message text.",
			category = "Messages",
			get = function()
				return reminderPreferences.messages.fontSize
			end,
			set = function(key)
				reminderPreferences.messages.fontSize = key
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
		[9] = {
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
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[10] = {
			label = "Monochrome",
			type = "checkBox",
			description = "Whether to use monochrome font for Message text.",
			category = "Messages",
			get = function()
				return reminderPreferences.messages.fontMonochrome
			end,
			set = function(key)
				reminderPreferences.messages.fontMonochrome = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[11] = {
			label = "Grow Messages Down",
			type = "checkBox",
			description = "",
			category = "Messages",
			get = function()
				return reminderPreferences.messages.growDown
			end,
			set = function(key)
				reminderPreferences.messages.growDown = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[12] = {
			label = "Message Anchor",
			type = "dropdown",
			description = "",
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { 12, 13, 14, 15 },
			get = function()
				return reminderPreferences.messages.point
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y = ApplyPoint(
					Private.messageAnchor.frame,
					key,
					_G[reminderPreferences.messages.relativeTo] or UIParent,
					reminderPreferences.messages.relativePoint
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[13] = {
			label = "Message Anchor Frame:",
			type = "frameChooser",
			description = "",
			category = "Messages",
			updateIndices = { 12, 13, 14, 15 },
			get = function()
				return reminderPreferences.messages.relativeTo
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y = ApplyPoint(
					Private.messageAnchor.frame,
					messages.point,
					_G[key] or UIParent,
					reminderPreferences.messages.relativePoint
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[14] = {
			label = "Relative Anchor",
			type = "dropdown",
			description = "The Message frame is anchored to this point on the Anchor frame.",
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { 12, 13, 14, 15 },
			get = function()
				return reminderPreferences.messages.relativePoint
			end,
			set = function(key)
				local messages = reminderPreferences.messages
				messages.point, messages.relativeTo, messages.relativePoint, messages.x, messages.y = ApplyPoint(
					Private.messageAnchor.frame,
					messages.point,
					_G[reminderPreferences.messages.relativeTo] or UIParent,
					key
				)
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[15] = {
			label = "Position",
			labels = { "X:", "Y:" },
			type = "doubleLineEdit",
			description = "",
			category = "Messages",
			values = anchorPointValues,
			updateIndices = { 12, 13, 14, 15 },
			get = function()
				return reminderPreferences.messages.x, reminderPreferences.messages.y
			end,
			set = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key)
				if x and y then
					reminderPreferences.messages.x = x
					reminderPreferences.messages.y = y
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.messages.enabled == true
			end,
			validate = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key)
				if x and y then
					return true
				end
				return false, reminderPreferences.messages.x, reminderPreferences.messages.y
			end,
		},
		[16] = {
			label = "Enable Progress Bars",
			type = "checkBox",
			description = "Whether to show progress bar widgets for assignments.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.enabled
			end,
			set = function(key)
				reminderPreferences.progressBars.enabled = key
			end,
			enabled = enableReminderOption,
			validate = function(key)
				return true
			end,
		},
		[17] = {
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
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[18] = {
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
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[19] = {
			label = "Font Size",
			type = "lineEdit",
			description = "Font size to use for Progress Bar text.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.fontSize
			end,
			set = function(key)
				reminderPreferences.progressBars.fontSize = key
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
		[20] = {
			label = "Font Outline",
			type = "dropdown",
			description = "Font outline to use for Message text.",
			category = "Progress Bars",
			values = fontOutlineValues,
			get = function()
				return reminderPreferences.progressBars.fontOutline
			end,
			set = function(key)
				reminderPreferences.progressBars.fontOutline = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[21] = {
			label = "Monochrome",
			type = "checkBox",
			description = "Whether to use monochrome font for Message text.",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.fontMonochrome
			end,
			set = function(key)
				reminderPreferences.progressBars.fontMonochrome = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[22] = {
			label = "Grow Messages Down",
			type = "checkBox",
			description = "",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.growDown
			end,
			set = function(key)
				reminderPreferences.progressBars.growDown = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[23] = {
			label = "Message Anchor",
			type = "dropdown",
			description = "",
			category = "Progress Bars",
			values = anchorPointValues,
			get = function()
				return reminderPreferences.progressBars.point
			end,
			set = function(key)
				reminderPreferences.progressBars.point = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[24] = {
			label = "Message Anchor Frame:",
			type = "frameChooser",
			description = "",
			category = "Progress Bars",
			get = function()
				return reminderPreferences.progressBars.relativeTo
			end,
			set = function(key)
				reminderPreferences.progressBars.relativeTo = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[25] = {
			label = "Relative Anchor:",
			type = "dropdown",
			description = "The Message frame is anchored to this point on the Anchor frame.",
			category = "Progress Bars",
			values = anchorPointValues,
			get = function()
				return reminderPreferences.progressBars.relativePoint
			end,
			set = function(key)
				reminderPreferences.progressBars.relativePoint = key
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key)
				return true
			end,
		},
		[26] = {
			label = "Position",
			type = "doubleLineEdit",
			description = "",
			category = "Progress Bars",
			values = anchorPointValues,
			get = function()
				return reminderPreferences.progressBars.x, reminderPreferences.progressBars.y
			end,
			set = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key)
				if x and y then
					reminderPreferences.progressBars.x = x
					reminderPreferences.progressBars.y = y
				end
			end,
			enabled = function()
				return reminderPreferences.enabled == true and reminderPreferences.progressBars.enabled == true
			end,
			validate = function(key, key2)
				local x = tonumber(key)
				local y = tonumber(key)
				if x and y then
					return true
				end
				return false, reminderPreferences.progressBars.x, reminderPreferences.progressBars.y
			end,
		},
		[27] = {
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
			validate = function(key)
				return true
			end,
		},
		[28] = {
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
			validate = function(key)
				return true
			end,
		},
		[29] = {
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
			validate = function(key)
				return true
			end,
		},
		[30] = {
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
		[31] = {
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
			validate = function(key)
				return true
			end,
		},
		[32] = {
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
			validate = function(key)
				return true
			end,
		},
		[33] = {
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
			validate = function(key)
				return true
			end,
		},
		[34] = {
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
			validate = function(key)
				return true
			end,
		},
	}

	optionsMenu:AddOptionTab("Keybindings", keyBindingOptions, { "Assignment", "Timeline" })
	optionsMenu:AddOptionTab("Reminder", reminderOptions, { "Messages", "Progress Bars", "Text to Speech", "Sound" })
	optionsMenu:AddOptionTab("View", viewOptions)
	optionsMenu:SetCurrentTab("Keybindings")

	if Private.mainFrame then
		optionsMenu.frame:SetPoint("CENTER", Private.mainFrame.frame, "CENTER", 0, 0)
		optionsMenu.frame:SetSize(500, Private.mainFrame.frame:GetHeight())
	else
		optionsMenu.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	Private.optionsMenu = optionsMenu

	local messageAnchor = AceGUI:Create("EPReminderMessage")
	messageAnchor.frame:SetParent(UIParent)
	messageAnchor.frame:SetPoint(
		reminderPreferences.messages.point,
		reminderPreferences.messages.relativeTo or UIParent,
		reminderPreferences.messages.relativePoint,
		reminderPreferences.messages.x,
		reminderPreferences.messages.y
	)
	messageAnchor.frame:Hide()
	Private.messageAnchor = messageAnchor

	local progressBarAnchor = AceGUI:Create("EPProgressBar")
	progressBarAnchor.frame:SetParent(UIParent)
	progressBarAnchor.frame:SetPoint(
		reminderPreferences.progressBars.point,
		reminderPreferences.progressBars.relativeTo or UIParent,
		reminderPreferences.progressBars.relativePoint,
		reminderPreferences.progressBars.x,
		reminderPreferences.progressBars.y
	)
	progressBarAnchor.frame:Hide()
	Private.progressBarAnchor = progressBarAnchor
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
