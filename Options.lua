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
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

function Private:CreateOptionsMenu()
	local optionsMenu = AceGUI:Create("EPOptions")
	optionsMenu.frame:SetParent(UIParent) --Private.mainFrame.frame --[[@as Frame]])
	optionsMenu.frame:SetFrameStrata("FULLSCREEN_DIALOG")

	optionsMenu.frame:SetFrameLevel(100)

	optionsMenu:SetLayout("EPVerticalLayout")
	optionsMenu:SetCallback("OnRelease", function()
		Private.optionsMenu = nil
	end)

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
					timeline:UpdateHeight()
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
					timeline:UpdateHeight()
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

	optionsMenu:AddOptionTab("Keybindings", keyBindingOptions, { "Assignment", "Timeline" })
	optionsMenu:AddOptionTab("View", viewOptions)
	optionsMenu:SetCurrentTab("Keybindings")

	local yPos = -(UIParent:GetHeight() / 2) + (optionsMenu.frame:GetHeight() / 2)
	optionsMenu.frame:SetPoint("TOP", UIParent, "TOP", 0, yPos)
	yPos = -(UIParent:GetHeight() / 2) + (optionsMenu.frame:GetHeight() / 2)
	optionsMenu.frame:SetPoint("TOP", UIParent, "TOP", 0, yPos)
	optionsMenu:DoLayout()

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
