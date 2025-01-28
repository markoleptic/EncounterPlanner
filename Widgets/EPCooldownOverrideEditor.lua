local _, Namespace = ...
local L = Namespace.L

local Type = "EPCooldownOverrideEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local format = format
local ipairs = ipairs
local tinsert = tinsert
local tostring = tostring
local unpack = unpack

local defaultFrameWidth = 550
local defaultFrameHeight = 400
local minFrameWidth = 400
local relWidths = {}
local windowBarHeight = 28
local contentFramePadding = { x = 15, y = 15 }
local otherPadding = { x = 10, y = 10 }
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local headingColor = { 1, 0.82, 0, 1 }
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 27, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}

---@param self EPCooldownOverrideEditor
local function ResetToDefault(self)
	for i = 2, #self.activeContainer.children do
		local child = self.activeContainer.children[i]
		if child.type == "EPContainer" then
			local containerChildren = child.children
			if #containerChildren == 5 then
			end
		end
	end
end

---@param self EPCooldownOverrideEditor
---@param entry any
---@return EPContainer
local function CreateEntry(self, entry)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPHorizontalLayout")
	container:SetSpacing(16, 0)
	container:SetFullWidth(true)

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:AddItems(self.spellDropdownItems, "EPDropdownItemToggle")
	dropdown:SetValue(entry.spellID)

	local defaultContainer = AceGUI:Create("EPContainer")
	defaultContainer:SetLayout("EPHorizontalLayout")
	defaultContainer:SetSpacing(0, 0)
	defaultContainer:SetRelativeWidth(relWidths[2])

	local defaultMinutes, defaultSeconds = self.FormatTime(entry.defaultDuration)
	local defaultText = format("%s:%s", defaultMinutes, defaultSeconds)
	local defaultLabel = AceGUI:Create("EPLabel")
	defaultLabel:SetText(defaultText, 0)
	defaultLabel:SetHorizontalTextAlignment("CENTER")
	defaultLabel:SetFullWidth(true)

	local currentContainer = AceGUI:Create("EPContainer")
	currentContainer:SetLayout("EPHorizontalLayout")
	currentContainer:SetSpacing(0, 0)
	currentContainer:SetRelativeWidth(relWidths[3])

	local minuteLineEdit = AceGUI:Create("EPLineEdit")
	local secondLineEdit = AceGUI:Create("EPLineEdit")
	local minutes, seconds = self.FormatTime(entry.duration)
	minuteLineEdit:SetText(minutes)
	minuteLineEdit:SetRelativeWidth(0.475)
	minuteLineEdit:SetCallback("OnTextSubmitted", function(widget, ...)
		self:Fire("DataChanged", entry.spellID, widget, secondLineEdit)
	end)

	local separatorLabel = AceGUI:Create("EPLabel")
	separatorLabel:SetText(":", 0)
	separatorLabel:SetHorizontalTextAlignment("CENTER")
	separatorLabel:SetRelativeWidth(0.05)

	secondLineEdit:SetText(seconds)
	secondLineEdit:SetRelativeWidth(0.475)
	secondLineEdit:SetCallback("OnTextSubmitted", function(widget, _, text)
		self:Fire("DataChanged", entry.spellID, minuteLineEdit, widget)
	end)

	defaultContainer:AddChildren(defaultLabel)
	currentContainer:AddChildren(minuteLineEdit, separatorLabel, secondLineEdit)
	container:AddChildren(dropdown, defaultContainer, currentContainer)
	return container
end

---@class EPCooldownOverrideEditor : AceGUIWidget
---@field frame Frame|table
---@field type string
---@field windowBar table|Frame
---@field closeButton EPButton
---@field activeContainer EPContainer
---@field resetAllButton EPButton
---@field FormatTime fun(number): string,string
---@field spellDropdownItems table<integer, DropdownItemData>

---@param self EPCooldownOverrideEditor
local function OnAcquire(self)
	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.resetAllButton = AceGUI:Create("EPButton")
	self.resetAllButton.frame:SetParent(self.frame)
	self.resetAllButton.frame:SetPoint("BOTTOM", 0, contentFramePadding.y)
	self.resetAllButton:SetText(L["Reset All to Default"])
	self.resetAllButton:SetWidthFromText()
	self.resetAllButton:SetCallback("Clicked", function()
		ResetToDefault(self)
		self:Fire("ResetAllButtonClicked")
	end)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 4)
	self.activeContainer:SetFullWidth(true)
	self.activeContainer.frame:EnableMouse(true)
	self.activeContainer.frame:SetParent(self.frame)
	self.activeContainer.frame:SetPoint(
		"TOPLEFT",
		self.windowBar,
		"BOTTOMLEFT",
		contentFramePadding.x,
		-contentFramePadding.y
	)
	self.activeContainer.frame:SetPoint("RIGHT", self.frame, "RIGHT", -contentFramePadding.x, 0)

	local labelsAndWidths = {}
	local columnZeroLabel = AceGUI:Create("EPLabel")
	columnZeroLabel:SetText(L["Spell"], 0)
	columnZeroLabel:SetFrameWidthFromText()
	columnZeroLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { columnZeroLabel, columnZeroLabel.frame:GetWidth() + 150 })

	local columnOneLabel = AceGUI:Create("EPLabel")
	columnOneLabel:SetText(L["Default Cooldown"], 0)
	columnOneLabel:SetHorizontalTextAlignment("CENTER")
	columnOneLabel:SetFrameWidthFromText()
	columnOneLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { columnOneLabel, columnOneLabel.frame:GetWidth() })

	local columnTwoLabel = AceGUI:Create("EPLabel")
	columnTwoLabel:SetText(L["Custom Cooldown"], 0)
	columnTwoLabel:SetHorizontalTextAlignment("CENTER")
	columnTwoLabel:SetFrameWidthFromText()
	columnTwoLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { columnTwoLabel, columnTwoLabel.frame:GetWidth() })

	local totalWidth = 0.0
	for _, labelAndWidth in ipairs(labelsAndWidths) do
		totalWidth = totalWidth + labelAndWidth[2]
	end
	for i, labelAndWidth in ipairs(labelsAndWidths) do
		local relWidth = labelAndWidth[2] / totalWidth
		labelAndWidth[1]:SetRelativeWidth(relWidth)
		relWidths[i] = relWidth
	end

	local labelContainer = AceGUI:Create("EPContainer")
	labelContainer:SetLayout("EPHorizontalLayout")
	labelContainer:SetSpacing(16, 0)
	labelContainer:SetFullWidth(true)
	labelContainer:AddChildren(columnZeroLabel, columnOneLabel, columnTwoLabel)

	local addEntryButton = AceGUI:Create("EPButton")
	addEntryButton:SetText("+")
	addEntryButton:SetHeight(24)
	addEntryButton:SetWidth(24)
	addEntryButton:SetCallback("Clicked", function()
		self.activeContainer:AddChild(CreateEntry(self), addEntryButton)
		self:Resize()
	end)

	self.activeContainer:AddChildren(labelContainer)

	self.frame:Show()
end

---@param self EPCooldownOverrideEditor
local function OnRelease(self)
	self.closeButton:Release()
	self.closeButton = nil

	self.activeContainer.frame:EnableMouse(false)
	self.activeContainer:Release()
	self.activeContainer = nil

	self.resetAllButton:Release()
	self.resetAllButton = nil

	self.FormatTime = nil
	self.spellDropdownItems = nil
	wipe(relWidths)
end

---@param self EPCooldownOverrideEditor
---@param entries table
local function AddEntries(self, entries)
	local containers = {}

	for index, entry in ipairs(entries) do
		local container = AceGUI:Create("EPContainer")
		container:SetLayout("EPHorizontalLayout")
		container:SetSpacing(16, 0)
		container:SetFullWidth(true)

		local dropdown = AceGUI:Create("EPDropdown")
		dropdown:AddItems(self.spellDropdownItems, "EPDropdownItemToggle")
		dropdown:SetValue(entry.spellID)

		local defaultContainer = AceGUI:Create("EPContainer")
		defaultContainer:SetLayout("EPHorizontalLayout")
		defaultContainer:SetSpacing(0, 0)
		defaultContainer:SetRelativeWidth(relWidths[2])

		local defaultMinutes, defaultSeconds = self.FormatTime(entry.defaultDuration)
		local defaultText = format("%s:%s", defaultMinutes, defaultSeconds)
		local defaultLabel = AceGUI:Create("EPLabel")
		defaultLabel:SetText(defaultText, 0)
		defaultLabel:SetHorizontalTextAlignment("CENTER")
		defaultLabel:SetFullWidth(true)

		local currentContainer = AceGUI:Create("EPContainer")
		currentContainer:SetLayout("EPHorizontalLayout")
		currentContainer:SetSpacing(0, 0)
		currentContainer:SetRelativeWidth(relWidths[3])

		local minuteLineEdit = AceGUI:Create("EPLineEdit")
		local secondLineEdit = AceGUI:Create("EPLineEdit")
		local minutes, seconds = self.FormatTime(entry.duration)
		minuteLineEdit:SetText(minutes)
		minuteLineEdit:SetRelativeWidth(0.475)
		minuteLineEdit:SetCallback("OnTextSubmitted", function(widget, ...)
			self:Fire("DataChanged", index, widget, secondLineEdit)
		end)

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":", 0)
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)

		secondLineEdit:SetText(seconds)
		secondLineEdit:SetRelativeWidth(0.475)
		secondLineEdit:SetCallback("OnTextSubmitted", function(widget, _, text)
			self:Fire("DataChanged", index, minuteLineEdit, widget)
		end)

		defaultContainer:AddChildren(defaultLabel)
		currentContainer:AddChildren(minuteLineEdit, separatorLabel, secondLineEdit)
		container:AddChildren(dropdown, defaultContainer, currentContainer)

		container:AddChildren(dropdown)
		tinsert(containers, container)
	end

	self.activeContainer:InsertChildren(
		self.activeContainer.children[#self.activeContainer.children],
		unpack(containers)
	)
end

---@param self EPCooldownOverrideEditor
local function Resize(self)
	local height = contentFramePadding.y
		+ self.windowBar:GetHeight()
		+ self.activeContainer.frame:GetHeight()
		+ otherPadding.y
		+ self.resetAllButton.frame:GetHeight()
		+ contentFramePadding.y
	self.frame:SetSize(defaultFrameWidth, height)
	self.activeContainer:DoLayout()
end

---@param self EPCooldownOverrideEditor
local function SetSpellDropdownItems(self, spellDropdownItems)
	self.spellDropdownItems = spellDropdownItems
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(L["Cooldown Overrides"])
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		local x, y = frame:GetLeft(), frame:GetTop()
		frame:StopMovingOrSizing()
		frame:ClearAllPoints()
		frame:SetPoint("TOP", x - UIParent:GetWidth() / 2.0 + frame:GetWidth() / 2.0, -(UIParent:GetHeight() - y))
	end)
	---@class EPCooldownOverrideEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		AddEntries = AddEntries,
		Resize = Resize,
		SetSpellDropdownItems = SetSpellDropdownItems,
		frame = frame,
		type = Type,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
