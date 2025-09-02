local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPOptions"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local tooltip = Private.tooltip

local CreateFrame = CreateFrame
local geterrorhandler = geterrorhandler
local format = string.format
local GetMouseFoci = GetMouseFoci
local ipairs = ipairs
local IsMouseButtonDown = IsMouseButtonDown
local max = math.max
local pairs = pairs
local ResetCursor = ResetCursor
local SetCursor = SetCursor
local tinsert = table.insert
local type = type
local unpack = unpack
local xpcall = xpcall
local wipe = table.wipe

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function SafeCall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

local k = {
	ActiveContainerPadding = { 10, 10, 10, 10 },
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	BackdropColor = { 0, 0, 0, 1 },
	CategoryFontSize = 18,
	CategoryPadding = { 15, 15, 15, 15 },
	CategoryTextColor = { 1, 0.82, 0, 1 },
	ContentFramePadding = { x = 15, y = 15 },
	DoubleLineEditContainerSpacing = { 8, 0 },
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 27, bottom = 0 },
	},
	FrameChooserContainerSpacing = { 8, 0 },
	FrameHeight = 500,
	FrameWidth = 500,
	GroupBoxBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	},
	GroupBoxBorderColor = { 0.25, 0.25, 0.25, 1.0 },
	IndentWidth = 20,
	LabelTextColor = { 1, 1, 1, 1 },
	LineBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		tile = false,
		edgeSize = 0,
		insets = { left = 0, right = 0 },
	},
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	OptionLabelFontSize = 14,
	PreferredHeight = 600,
	RadioButtonGroupSpacing = { 8, 0 },
	SpacingBetweenCategories = 15,
	SpacingBetweenLabelAndWidget = 8,
	SpacingBetweenOptions = 10,
	Title = L["Preferences"],
}
k.LineBackdrop.insets.top = k.SpacingBetweenOptions / 2
k.LineBackdrop.insets.bottom = k.SpacingBetweenOptions / 2

local s = {
	IsChoosingFrame = false,
	MessageBox = nil, ---@type EPMessageBox|nil
}

local function GetName(frame)
	if frame.GetName and frame:GetName() then
		return frame:GetName()
	end
	local parent = frame.GetParent and frame:GetParent()
	if parent then
		return GetName(parent) .. ".UnknownChild"
	end
	return nil
end

---@param frameChooserFrame Frame
---@param frameChooserBox table|BackdropTemplate|Frame
---@param focusName string|nil
---@param setFunc fun(value: string|nil)|nil
local function StopChoosingFrame(frameChooserFrame, frameChooserBox, focusName, setFunc)
	s.IsChoosingFrame = false
	frameChooserFrame:SetScript("OnUpdate", nil)
	frameChooserFrame:Hide()
	frameChooserBox:ClearAllPoints()
	frameChooserBox:Hide()
	ResetCursor()
	if setFunc then
		setFunc(focusName)
	end
end

---@param frameChooserFrame Frame
---@param frameChooserBox table|BackdropTemplate|Frame
---@param setFunc fun(value: string|nil)
local function StartChoosingFrame(frameChooserFrame, frameChooserBox, setFunc)
	frameChooserFrame:Show()
	s.IsChoosingFrame = true
	local oldFocus = nil
	local oldFocusName = nil
	local cursorIsSet = false
	SetCursor("CAST_CURSOR")

	frameChooserFrame:SetScript("OnUpdate", function()
		if IsMouseButtonDown("RightButton") then
			StopChoosingFrame(frameChooserFrame, frameChooserBox, nil, setFunc)
			return
		elseif IsMouseButtonDown("LeftButton") then
			if oldFocusName == nil or oldFocusName == "WorldFrame" then
				StopChoosingFrame(frameChooserFrame, frameChooserBox, "UIParent", setFunc)
			else
				StopChoosingFrame(frameChooserFrame, frameChooserBox, oldFocusName, setFunc)
			end
			return
		end

		local foci = GetMouseFoci()
		local focus = foci and foci[1] or nil
		local focusName = focus and GetName(focus) or nil

		if focusName == "WorldFrame" or (focusName and focusName:match("^EP")) then
			focusName = nil
		end

		if focusName and not cursorIsSet then
			SetCursor("CAST_CURSOR")
			cursorIsSet = true
		elseif not focusName and cursorIsSet then
			ResetCursor()
			cursorIsSet = false
		end

		if focus ~= oldFocus then
			if focusName then
				frameChooserBox:ClearAllPoints()
				frameChooserBox:SetPoint("BOTTOMLEFT", focus, "BOTTOMLEFT", 2, 2)
				frameChooserBox:SetPoint("TOPRIGHT", focus, "TOPRIGHT", -2, -2)
				frameChooserBox:Show()
			else
				frameChooserBox:Hide()
			end

			oldFocus = focus
			oldFocusName = focusName
		end
	end)
end

---@param frame Frame
---@param label string
---@param description string
local function ShowTooltip(frame, label, description)
	tooltip:SetOwner(frame, "ANCHOR_TOP")
	tooltip:SetText(label, 1, 0.82, 0, true)
	if type(description) == "string" then
		tooltip:AddLine(description, 1, 1, 1, true)
	end
	tooltip:Show()
end

---@class CooldownOverrideObject
---@field FormatTime fun(number): string,string
---@field GetSpellCooldownAndCharges fun(integer): number, integer
---@field cooldownAndChargeOverrides table<integer, CooldownAndChargeOverride>
---@field option EPSettingOption
---@field activeContainer EPContainer
---@field scrollFrame EPScrollFrame
---@field realDropdown EPDropdown
local cooldownOverrideObject = {}

do
	local abs = math.abs
	local ceil, floor = math.ceil, math.floor
	local Clamp = Clamp
	local GetSpellName = C_Spell.GetSpellName
	local sort = table.sort
	local tonumber = tonumber

	local kDeleteButtonSize = 24
	local kHeadingColor = { 1, 0.82, 0, 1 }
	local kMinDuration = 0.0
	local kSeparatorRelWidth = 0.05
	local kTimeLineEditRelWidth = 0.475

	local function Round(value, precision)
		local factor = 10 ^ precision
		if value > 0 then
			return floor(value * factor + 0.5) / factor
		else
			return ceil(value * factor - 0.5) / factor
		end
	end

	local function CopyAndSet()
		local copy = {} ---@type table<integer, CooldownAndChargeOverride>
		for key, value in pairs(cooldownOverrideObject.cooldownAndChargeOverrides) do
			copy[key] = {
				duration = value.duration,
				maxCharges = value.maxCharges,
			}
		end
		cooldownOverrideObject.option.set(copy)
	end

	---@param spellID integer
	---@param minLineEdit EPLineEdit
	---@param secLineEdit EPLineEdit
	local function UpdateCooldown(spellID, minLineEdit, secLineEdit)
		local previousDuration = cooldownOverrideObject.cooldownAndChargeOverrides[spellID].duration
		local newDuration = previousDuration
		local timeMinutes = tonumber(minLineEdit:GetText())
		local timeSeconds = tonumber(secLineEdit:GetText())
		if timeMinutes and timeSeconds then
			local roundedMinutes = Round(timeMinutes, 0)
			local roundedSeconds = Round(timeSeconds, 1)
			newDuration = roundedMinutes * 60 + roundedSeconds
			local maxDuration = cooldownOverrideObject.GetSpellCooldownAndCharges(spellID) * 2.0
			newDuration = Clamp(newDuration, kMinDuration, maxDuration)
			cooldownOverrideObject.cooldownAndChargeOverrides[spellID].duration = newDuration
			if abs(previousDuration - newDuration) > 0.01 then
				CopyAndSet()
			end
		end

		local minutes, seconds = cooldownOverrideObject.FormatTime(newDuration)
		minLineEdit:SetText(minutes)
		secLineEdit:SetText(seconds)
	end

	---@param spellID integer
	---@param maxChargesLineEdit EPLineEdit
	local function UpdateMaxCharges(spellID, maxChargesLineEdit)
		local previousMaxCharges = cooldownOverrideObject.cooldownAndChargeOverrides[spellID].maxCharges
		local text = maxChargesLineEdit:GetText()
		if text:trim():len() == 0 then
			cooldownOverrideObject.cooldownAndChargeOverrides[spellID].maxCharges = nil
			CopyAndSet()
		else
			local maxCharges = tonumber(text)
			if maxCharges then
				maxCharges = Round(maxCharges, 0)
				maxCharges = Clamp(maxCharges, 1, 5)
				cooldownOverrideObject.cooldownAndChargeOverrides[spellID].maxCharges = maxCharges
				if maxCharges ~= previousMaxCharges then
					CopyAndSet()
				end
			else
				maxCharges = previousMaxCharges
			end
			maxChargesLineEdit:SetText(maxCharges)
		end
	end

	local function SetRelativeLabelWidths()
		local width = cooldownOverrideObject.scrollFrame.scrollFrameWrapper:GetWidth()
		local labelContainer = cooldownOverrideObject.labelContainer
		labelContainer.frame:SetWidth(width)
		local containerWidth = cooldownOverrideObject.activeContainer.frame:GetWidth()
		local widthDiff = width - 4 - containerWidth

		local fullNonSpacingWidth = width - 4 * labelContainer.content.spacing.x
		local spacerWidth = (kDeleteButtonSize + widthDiff) / fullNonSpacingWidth
		local totalAvailableWidgetWidth = fullNonSpacingWidth - kDeleteButtonSize - widthDiff

		labelContainer.children[1]:SetRelativeWidth(totalAvailableWidgetWidth * 0.4 / fullNonSpacingWidth)
		labelContainer.children[2]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
		labelContainer.children[3]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
		labelContainer.children[4]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
		labelContainer.children[5]:SetRelativeWidth(spacerWidth)
		labelContainer:DoLayout()
	end

	---@param container EPContainer
	---@param width number
	local function SetRelativeWidths(container, width)
		local fullNonSpacingWidth = width - 4 * container.content.spacing.x
		local totalAvailableWidgetWidth = fullNonSpacingWidth - kDeleteButtonSize

		for _, widget in ipairs(container.children) do
			if widget.children and #widget.children == 5 then
				widget.children[1]:SetRelativeWidth(totalAvailableWidgetWidth * 0.4 / fullNonSpacingWidth)
				widget.children[2]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
				widget.children[3]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
				widget.children[4]:SetRelativeWidth(totalAvailableWidgetWidth * 0.2 / fullNonSpacingWidth)
				widget.children[5]:SetRelativeWidth(kDeleteButtonSize / fullNonSpacingWidth)
				widget:DoLayout()
			end
		end
	end

	---@param activeContainer EPContainer
	---@param initialSpellID integer?
	---@param duration number?
	---@param maxCharges integer?
	---@return EPContainer
	---@return EPSpacer
	local function CreateEntry(activeContainer, initialSpellID, duration, maxCharges)
		local currentSpellID = initialSpellID

		local container = AceGUI:Create("EPContainer")
		container:SetLayout("EPHorizontalLayout")
		container:SetSpacing(k.SpacingBetweenLabelAndWidget, 0)
		container:SetFullWidth(true)

		local dropdownContainer = AceGUI:Create("EPContainer")
		dropdownContainer:SetLayout("EPHorizontalLayout")
		dropdownContainer:SetSpacing(0, 0)

		local dropdown = AceGUI:Create("EPDropdown")
		dropdown:SetEnabled(initialSpellID == nil)
		dropdown:SetFullWidth(true)
		dropdown.isFake = true

		local defaultContainer = AceGUI:Create("EPContainer")
		defaultContainer:SetLayout("EPHorizontalLayout")
		defaultContainer:SetSpacing(0, 0)

		local chargeContainer = AceGUI:Create("EPContainer")
		chargeContainer:SetLayout("EPHorizontalLayout")
		chargeContainer:SetSpacing(0, 0)

		local defaultLabel = AceGUI:Create("EPLabel")
		defaultLabel:SetHorizontalTextAlignment("CENTER")
		defaultLabel:SetFullWidth(true)

		if initialSpellID then
			local spellCooldown = cooldownOverrideObject.GetSpellCooldownAndCharges(initialSpellID)
			defaultLabel:SetText(format("%s:%s", cooldownOverrideObject.FormatTime(spellCooldown)), 0)
		else
			defaultLabel:SetText("0:00")
		end

		local currentContainer = AceGUI:Create("EPContainer")
		currentContainer:SetLayout("EPHorizontalLayout")
		currentContainer:SetSpacing(0, 0)

		local minuteLineEdit = AceGUI:Create("EPLineEdit")
		local secondLineEdit = AceGUI:Create("EPLineEdit")
		do
			local minutes, seconds = "0", "00"
			if duration then
				minutes, seconds = cooldownOverrideObject.FormatTime(duration)
			end
			minuteLineEdit:SetText(minutes)
			minuteLineEdit:SetRelativeWidth(kTimeLineEditRelWidth)
			secondLineEdit:SetText(seconds)
			secondLineEdit:SetRelativeWidth(kTimeLineEditRelWidth)
		end

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":", 0)
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(kSeparatorRelWidth)

		minuteLineEdit:SetCallback("OnTextSubmitted", function()
			if type(currentSpellID) == "number" then
				UpdateCooldown(currentSpellID, minuteLineEdit, secondLineEdit)
			end
		end)
		secondLineEdit:SetCallback("OnTextSubmitted", function()
			if type(currentSpellID) == "number" then
				UpdateCooldown(currentSpellID, minuteLineEdit, secondLineEdit)
			end
		end)
		minuteLineEdit:SetCallback("OnEnter", function()
			ShowTooltip(
				currentContainer.frame,
				L["Custom Duration"],
				L["Overrides the cooldown duration of the spell."]
			)
		end)
		secondLineEdit:SetCallback("OnEnter", function()
			ShowTooltip(
				currentContainer.frame,
				L["Custom Duration"],
				L["Overrides the cooldown duration of the spell."]
			)
		end)
		minuteLineEdit:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
		secondLineEdit:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)

		local chargeLineEdit = AceGUI:Create("EPLineEdit")
		chargeLineEdit:SetFullWidth(true)
		chargeLineEdit:SetCallback("OnTextSubmitted", function()
			if type(currentSpellID) == "number" then
				UpdateMaxCharges(currentSpellID, chargeLineEdit)
			end
		end)
		chargeLineEdit:SetText(maxCharges)
		chargeLineEdit:SetCallback("OnEnter", function()
			ShowTooltip(
				chargeContainer.frame,
				L["Custom Charges"],
				L["Overrides the max number of charges of the spell (1-5). If left empty, uses charges based on current talents."]
			)
		end)
		chargeLineEdit:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)

		local deleteButton = AceGUI:Create("EPButton")
		deleteButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
		deleteButton:SetIconPadding(0, 0)
		deleteButton:SetWidth(kDeleteButtonSize)
		deleteButton:SetHeight(kDeleteButtonSize)

		local spacer = AceGUI:Create("EPSpacer")
		spacer:SetFullWidth(true)
		spacer:SetHeight(4)

		local cooldownAndChargeOverrides = cooldownOverrideObject.cooldownAndChargeOverrides
		deleteButton:SetCallback("Clicked", function()
			if currentSpellID then
				cooldownAndChargeOverrides[currentSpellID] = nil
				CopyAndSet()
			end
			activeContainer:RemoveChildNoDoLayout(container)
			activeContainer:RemoveChildNoDoLayout(spacer)
			activeContainer:DoLayout()
			SetRelativeWidths(activeContainer, activeContainer.content:GetWidth())
			SetRelativeLabelWidths()
		end)

		if initialSpellID then
			local _, text = cooldownOverrideObject.realDropdown:FindItemAndText(initialSpellID)
			if text then
				dropdown:SetText(text)
			end
		else
			dropdown:SetCallback("Clicked", function()
				if dropdown.enabled then
					local realDropdown = cooldownOverrideObject.realDropdown
					realDropdown:SetText("")
					realDropdown.frame:SetParent(dropdown.frame)
					realDropdown.frame:SetFrameLevel(dropdown.frame:GetFrameLevel() + 10)
					realDropdown.frame:SetSize(dropdown.frame:GetSize())
					realDropdown.frame:SetPoint("TOPLEFT", dropdown.frame, "TOPLEFT")
					realDropdown.frame:SetPoint("BOTTOMRIGHT", dropdown.frame, "BOTTOMRIGHT")
					realDropdown:SetCallback("OnValueChanged", function(widget, _, value)
						local _, text = widget:FindItemAndText(value)
						if type(value) == "number" then
							if not cooldownAndChargeOverrides[value] then
								local cooldown = cooldownOverrideObject.GetSpellCooldownAndCharges(value)
								local minutes, seconds = cooldownOverrideObject.FormatTime(cooldown)
								defaultLabel:SetText(format("%s:%s", minutes, seconds), 0)
								minuteLineEdit:SetText(minutes)
								secondLineEdit:SetText(seconds)
								chargeLineEdit:SetText()
								dropdown:SetText(text)
								dropdown:SetEnabled(false)
								currentSpellID = value
								cooldownAndChargeOverrides[currentSpellID] = { duration = cooldown }
								CopyAndSet()
							else
								activeContainer:RemoveChildNoDoLayout(container)
								activeContainer:RemoveChildNoDoLayout(spacer)
								activeContainer:DoLayout()
								SetRelativeWidths(activeContainer, activeContainer.content:GetWidth())
								SetRelativeLabelWidths()
							end
						end
						realDropdown:Close()
						realDropdown.frame:Hide()
						realDropdown.frame:SetParent(UIParent)
						realDropdown.frame:ClearAllPoints()
					end)
					realDropdown.frame:Show()
					realDropdown:Open()
				end
			end)
		end

		dropdownContainer:AddChild(dropdown)
		defaultContainer:AddChild(defaultLabel)
		currentContainer:AddChildren(minuteLineEdit, separatorLabel, secondLineEdit)
		chargeContainer:AddChild(chargeLineEdit)
		container:AddChildren(dropdownContainer, defaultContainer, currentContainer, chargeContainer, deleteButton)

		return container, spacer
	end

	---@param entries table<integer, CooldownAndChargeOverride>
	local function AddEntries(entries)
		local cooldownDurations = cooldownOverrideObject.cooldownAndChargeOverrides
		wipe(cooldownDurations)

		local containersAndSpacers = {}
		local activeContainer = cooldownOverrideObject.activeContainer
		for spellID, cooldownAndChargeOverride in pairs(entries) do
			local duration = cooldownAndChargeOverride.duration
			local maxCharges = cooldownAndChargeOverride.maxCharges
			cooldownDurations[spellID] = {
				duration = duration,
				maxCharges = maxCharges,
			}
			local spellName = GetSpellName(spellID)
			local container, spacer = CreateEntry(activeContainer, spellID, duration, maxCharges)
			tinsert(containersAndSpacers, { container = container, spacer = spacer, spellName = spellName or "" })
		end

		sort(containersAndSpacers, function(a, b)
			return a.spellName < b.spellName
		end)

		local widgets = {}
		for _, obj in ipairs(containersAndSpacers) do
			tinsert(widgets, obj.container)
			tinsert(widgets, obj.spacer)
		end

		local beforeWidget = activeContainer.children[#activeContainer.children]
		activeContainer:InsertChildren(beforeWidget, unpack(widgets))
	end

	---@param option EPSettingOption
	function cooldownOverrideObject.CreateCooldownOverrideTab(option)
		local columnZeroLabel = AceGUI:Create("EPLabel")
		columnZeroLabel:SetText(L["Spell"], 0)
		columnZeroLabel.text:SetTextColor(unpack(kHeadingColor))

		local columnOneLabel = AceGUI:Create("EPLabel")
		columnOneLabel:SetText(L["Default Duration"], 0)
		columnOneLabel:SetHorizontalTextAlignment("CENTER")
		columnOneLabel.text:SetTextColor(unpack(kHeadingColor))

		local columnTwoLabel = AceGUI:Create("EPLabel")
		columnTwoLabel:SetText(L["Custom Duration"], 0)
		columnTwoLabel:SetHorizontalTextAlignment("CENTER")
		columnTwoLabel.text:SetTextColor(unpack(kHeadingColor))

		local columnThreeLabel = AceGUI:Create("EPLabel")
		columnThreeLabel:SetText(L["Custom Charges"], 0)
		columnThreeLabel:SetHorizontalTextAlignment("CENTER")
		columnThreeLabel.text:SetTextColor(unpack(kHeadingColor))

		local spacer = AceGUI:Create("EPSpacer")
		spacer:SetWidth(kDeleteButtonSize)
		spacer:SetHeight(kDeleteButtonSize)

		cooldownOverrideObject.labelContainer:AddChildren(
			columnZeroLabel,
			columnOneLabel,
			columnTwoLabel,
			columnThreeLabel,
			spacer
		)

		local activeContainer = cooldownOverrideObject.activeContainer
		local addEntryButton = AceGUI:Create("EPButton")
		addEntryButton:SetText("+")
		addEntryButton:SetHeight(kDeleteButtonSize)
		addEntryButton:SetWidth(kDeleteButtonSize)
		addEntryButton:SetColor(unpack(k.NeutralButtonColor))
		addEntryButton:SetCallback("Clicked", function()
			local container, space = CreateEntry(activeContainer, nil, nil, nil)
			activeContainer:InsertChildren(addEntryButton, container, space)
			SetRelativeWidths(activeContainer, activeContainer.content:GetWidth())
			activeContainer:DoLayout()
			SetRelativeLabelWidths()
		end)

		activeContainer:AddChild(addEntryButton)
		local options = option.get()
		if type(options) == "table" then
			---@cast options table<integer, CooldownAndChargeOverride>
			AddEntries(options)
		end
	end

	function cooldownOverrideObject.UpdateRelativeWidths()
		local activeContainer = cooldownOverrideObject.activeContainer
		SetRelativeWidths(activeContainer, activeContainer.content:GetWidth())
		SetRelativeLabelWidths()
	end
end

---@param container EPContainer
local function SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		maxWidth = max(maxWidth, child.frame:GetWidth())
	end
	for _, child in ipairs(container.children) do
		child:SetWidth(maxWidth)
	end
end

---@param radioButton EPRadioButton
---@param radioButtonGroup EPContainer
local function handleRadioButtonToggled(radioButton, radioButtonGroup)
	for _, child in ipairs(radioButtonGroup.children) do
		if child ~= radioButton then
			child:SetToggled(false)
		end
	end
end

---@param descriptions string[]|fun():string[]
---@return string[]
local function GetDescriptions(descriptions)
	if type(descriptions) == "function" then
		return descriptions()
	else
		return descriptions
	end
end

---@param labels string[]|fun():string[]
---@return string[]
local function GetLabels(labels)
	if type(labels) == "function" then
		return labels()
	else
		return labels
	end
end

---@param values table<integer, DropdownItemData>|fun():table<integer, DropdownItemData>
---@return table<integer, DropdownItemData>
local function GetValues(values)
	if type(values) == "function" then
		return values()
	else
		return values
	end
end

---@param dropdown EPDropdown
---@param values table<integer, DropdownItemData>|fun():table<integer, DropdownItemData>
---@param option EPSettingOption
local function AddDropdownValues(dropdown, values, option)
	if type(values) == "table" then
		dropdown:AddItems(values, "EPDropdownItemToggle", option.neverShowItemsAsSelected)
		if option.itemsAreFonts then
			for _, value in pairs(values) do
				local item, _ = dropdown:FindItemAndText(value.itemValue)
				if item then
					local fPath = LSM:Fetch("font", value.itemValue --[[@as string]])
					if fPath then
						local _, fontSize, _ = item.text:GetFont()
						item.text:SetFont(fPath, fontSize)
						item.changedFont = true
					end
				end
			end
		end
	elseif type(values) == "function" then
		dropdown:AddItems(values(), "EPDropdownItemToggle", option.neverShowItemsAsSelected)
	end
end

---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
local function RefreshEnabledStates(refreshMap)
	for _, tab in pairs(refreshMap) do
		---@diagnostic disable-next-line: undefined-field
		if tab.widget.SetEnabled and tab.enabled then
			---@diagnostic disable-next-line: undefined-field
			tab.widget:SetEnabled(tab.enabled())
		end
	end
end

---@param updateMap table<integer, fun()>
local function Update(updateMap)
	for _, func in pairs(updateMap) do
		if type(func) == "function" then
			func()
		end
	end
end

---@param updateIndices table<string, table<integer, table<integer, fun()>>>
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param func fun()
local function UpdateUpdateIndices(updateIndices, option, optionGroupKey, optionIndex, func)
	if type(func) == "function" then
		if option.updateIndices then
			if not updateIndices[optionGroupKey] then
				updateIndices[optionGroupKey] = {}
			end
			for _, indexOffset in ipairs(option.updateIndices) do
				local relativeOptionIndex = optionIndex + indexOffset
				if not updateIndices[optionGroupKey][relativeOptionIndex] then
					updateIndices[optionGroupKey][relativeOptionIndex] = {}
				end
				tinsert(updateIndices[optionGroupKey][relativeOptionIndex], func)
			end
		end
	end
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param label EPLabel
---@return EPContainer
local function CreateFrameChooser(self, option, optionGroupKey, optionIndex, label)
	local frameChooserContainer = AceGUI:Create("EPContainer")
	frameChooserContainer:SetFullWidth(true)
	frameChooserContainer:SetLayout("EPHorizontalLayout")
	frameChooserContainer:SetSpacing(unpack(k.FrameChooserContainerSpacing))

	local valueLineEdit = AceGUI:Create("EPLineEdit")
	valueLineEdit:SetText(option.get() --[[@as string]])
	valueLineEdit:SetRelativeWidth(0.6)
	valueLineEdit:SetFullHeight(true)
	valueLineEdit:SetReadOnly(true)

	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			valueLineEdit:SetText(option.get() --[[@as string]])
		end)
	end

	local button = AceGUI:Create("EPButton")
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetText(L["Choose"])
	button:SetRelativeWidth(0.4)
	button:SetCallback("Clicked", function()
		if s.IsChoosingFrame then
			StopChoosingFrame(self.frameChooserFrame, self.frameChooserBox, nil, nil)
			button:SetText(L["Choose"])
		else
			StartChoosingFrame(self.frameChooserFrame, self.frameChooserBox, function(value)
				if value then
					option.set(value)
					valueLineEdit:SetText(value)
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
						Update(self.updateIndices[optionGroupKey][optionIndex])
					end
				end
				button:SetText(L["Choose"])
			end)
			button:SetText(L["Right Click to Cancel"])
		end
	end)
	button:SetCallback("OnEnter", function()
		ShowTooltip(button.frame, option.label, option.description)
	end)
	button:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)

	if option.enabled then
		tinsert(self.refreshMap, { widget = valueLineEdit, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = button, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	frameChooserContainer:AddChildren(valueLineEdit, button)
	return frameChooserContainer
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param label EPLabel
---@return EPContainer
local function CreateRadioButtonGroup(self, option, optionGroupKey, optionIndex, label)
	local radioButtonGroup = AceGUI:Create("EPContainer")
	radioButtonGroup:SetLayout("EPHorizontalLayout")
	radioButtonGroup:SetSpacing(unpack(k.RadioButtonGroupSpacing))
	radioButtonGroup:SetFullWidth(true)
	local radioButtonGroupChildren = {}
	local values = GetValues(option.values)
	local relativeWidth = 1.0 / #values
	for _, itemValueAndText in pairs(values) do
		local radioButton = AceGUI:Create("EPRadioButton")
		radioButton:SetRelativeWidth(relativeWidth)
		radioButton:SetLabelText(itemValueAndText.text)
		radioButton:SetToggled(option.get() == itemValueAndText.itemValue)
		radioButton:SetUserData("key", itemValueAndText.itemValue)
		tinsert(radioButtonGroupChildren, radioButton)
	end
	if option.enabled then
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	radioButtonGroup:AddChildren(unpack(radioButtonGroupChildren))
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			if type(option.values) == "function" then
				local v = GetValues(option.values)
				for i, child in ipairs(radioButtonGroup.children) do
					---@cast child EPRadioButton
					child:SetLabelText(v[i].text)
					child:SetUserData("key", v[i].itemValue)
				end
			end
			for _, child in ipairs(radioButtonGroup.children) do
				child:SetToggled(option.get() == child:GetUserData("key"))
			end
		end)
	end
	for i, child in ipairs(radioButtonGroup.children) do
		if option.enabled and child.SetEnabled then
			child:SetEnabled(option.enabled())
			tinsert(self.refreshMap, { widget = child, enabled = option.enabled })
		end
		child:SetCallback("Toggled", function(radioButton, _, _)
			handleRadioButtonToggled(radioButton, radioButtonGroup)
			local value = radioButton:GetUserData("key")
			option.set(value)
			RefreshEnabledStates(self.refreshMap)
			if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
				Update(self.updateIndices[optionGroupKey][optionIndex])
			end
		end)
		child:SetCallback("OnEnter", function(widget)
			ShowTooltip(widget.frame, GetLabels(option.labels)[i], GetDescriptions(option.descriptions)[i])
		end)
		child:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
	end
	return radioButtonGroup
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleLineEdit(self, option, optionGroupKey, optionIndex, label)
	local doubleLineEditContainer = AceGUI:Create("EPContainer")
	doubleLineEditContainer:SetFullWidth(true)
	doubleLineEditContainer:SetLayout("EPHorizontalLayout")
	doubleLineEditContainer:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local labelRelativeWidth = 0.05
	local lineEditRelativeWidth = 0.45

	local labels = GetLabels(option.labels)
	local labelX = AceGUI:Create("EPLabel")
	labelX:SetText(labels[1] .. ":", 0)
	if labelX:GetText():len() > 5 then
		labelRelativeWidth = 0.10
		lineEditRelativeWidth = 0.40
	end
	labelX:SetRelativeWidth(labelRelativeWidth)
	labelX:SetFullHeight(true)

	local lineEditX = AceGUI:Create("EPLineEdit")
	lineEditX:SetRelativeWidth(lineEditRelativeWidth)

	local labelY = AceGUI:Create("EPLabel")
	labelY:SetText(labels[2] .. ":", 0)
	labelY:SetRelativeWidth(labelRelativeWidth)
	labelY:SetFullHeight(true)

	local lineEditY = AceGUI:Create("EPLineEdit")
	lineEditY:SetRelativeWidth(lineEditRelativeWidth)

	if option.enabled then
		tinsert(self.refreshMap, { widget = labelX, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = lineEditX, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = labelY, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = lineEditY, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			local x, y = option.get()
			lineEditX:SetText(x)
			lineEditY:SetText(y)
		end)
	end
	local function Callback()
		local valueX, valueY = lineEditX:GetText(), lineEditY:GetText()
		local valid, valueToRevertTo, valueToRevertToB = option.validate(valueX, valueY)
		if not valid and valueToRevertTo and valueToRevertToB then
			lineEditX:SetText(valueToRevertTo)
			lineEditY:SetText(valueToRevertToB)
			option.set(valueToRevertTo, valueToRevertToB)
		else
			option.set(valueX, valueY)
		end
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end
	lineEditX:SetCallback("OnTextSubmitted", Callback)
	lineEditY:SetCallback("OnTextSubmitted", Callback)
	local x, y = option.get()
	lineEditX:SetText(x)
	lineEditY:SetText(y)
	lineEditX:SetCallback("OnEnter", function()
		ShowTooltip(lineEditX.frame, GetLabels(option.labels)[1], GetDescriptions(option.descriptions)[1])
	end)
	lineEditY:SetCallback("OnEnter", function()
		ShowTooltip(lineEditY.frame, GetLabels(option.labels)[2], GetDescriptions(option.descriptions)[2])
	end)
	lineEditX:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	lineEditY:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	doubleLineEditContainer:AddChildren(labelX, lineEditX, labelY, lineEditY)
	return doubleLineEditContainer
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleColorPicker(self, option, optionGroupKey, optionIndex, label)
	if not option.set[1] or not option.set[2] then
		error("No set functions for double color picker.")
	end
	if not option.get[1] or not option.get[2] then
		error("No get functions for double color picker.")
	end
	local doubleColorPickerContainer = AceGUI:Create("EPContainer")
	doubleColorPickerContainer:SetFullWidth(true)
	doubleColorPickerContainer:SetLayout("EPHorizontalLayout")
	doubleColorPickerContainer:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local labels = GetLabels(option.labels)
	local colorPickerOne = AceGUI:Create("EPColorPicker")
	colorPickerOne:SetFullHeight(true)
	colorPickerOne:SetRelativeWidth(0.5)
	colorPickerOne:SetLabelText(labels[1] .. ":", k.SpacingBetweenLabelAndWidget)
	colorPickerOne:SetColor(option.get[1]())

	local colorPickerTwo = AceGUI:Create("EPColorPicker")
	colorPickerTwo:SetFullHeight(true)
	colorPickerTwo:SetRelativeWidth(0.5)
	colorPickerTwo:SetLabelText(labels[2] .. ":", k.SpacingBetweenLabelAndWidget)
	colorPickerTwo:SetColor(option.get[2]())

	if type(option.enabled) == "function" then
		tinsert(self.refreshMap, { widget = colorPickerOne, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = colorPickerTwo, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			colorPickerOne:SetColor(option.get[1]())
			colorPickerTwo:SetColor(option.get[2]())
		end)
	end
	colorPickerOne:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)
	colorPickerTwo:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)

	colorPickerOne:SetCallback("OnEnter", function()
		ShowTooltip(colorPickerOne.frame, GetLabels(option.labels)[1], GetDescriptions(option.descriptions)[1])
	end)
	colorPickerTwo:SetCallback("OnEnter", function()
		ShowTooltip(colorPickerTwo.frame, GetLabels(option.labels)[2], GetDescriptions(option.descriptions)[2])
	end)
	colorPickerOne:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	colorPickerTwo:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	doubleColorPickerContainer:AddChildren(colorPickerOne, colorPickerTwo)
	return doubleColorPickerContainer
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleCheckBox(self, option, optionGroupKey, optionIndex, label)
	if not option.set[1] or not option.set[2] then
		error("No set functions for double check box.")
	end
	if not option.get[1] or not option.get[2] then
		error("No get functions for double check box.")
	end
	local doubleCheckBoxContainer = AceGUI:Create("EPContainer")
	doubleCheckBoxContainer:SetFullWidth(true)
	doubleCheckBoxContainer:SetLayout("EPHorizontalLayout")
	doubleCheckBoxContainer:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local labels = GetLabels(option.labels)

	local checkBoxOne = AceGUI:Create("EPCheckBox")
	checkBoxOne:SetFullHeight(true)
	checkBoxOne:SetRelativeWidth(0.5)
	checkBoxOne:SetText(labels[1])
	checkBoxOne:SetChecked(option.get[1]())

	local checkBoxTwo = AceGUI:Create("EPCheckBox")
	checkBoxTwo:SetFullHeight(true)
	checkBoxTwo:SetRelativeWidth(0.5)
	checkBoxTwo:SetText(labels[2])
	checkBoxTwo:SetChecked(option.get[2]())

	if type(option.enabled) == "function" then
		tinsert(self.refreshMap, { widget = checkBoxOne, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = checkBoxTwo, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			checkBoxOne:SetChecked(option.get[1]())
			checkBoxTwo:SetChecked(option.get[2]())
		end)
	end
	checkBoxOne:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)
	checkBoxTwo:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)

	checkBoxOne:SetCallback("OnEnter", function()
		ShowTooltip(checkBoxOne.frame, GetLabels(option.labels)[1], GetDescriptions(option.descriptions)[1])
	end)
	checkBoxTwo:SetCallback("OnEnter", function()
		ShowTooltip(checkBoxTwo.frame, GetLabels(option.labels)[2], GetDescriptions(option.descriptions)[2])
	end)
	checkBoxOne:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	checkBoxTwo:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	doubleCheckBoxContainer:AddChildren(checkBoxOne, checkBoxTwo)
	return doubleCheckBoxContainer
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@return EPContainer
local function CreateCheckBoxWithDropdown(self, option, optionGroupKey, optionIndex)
	if not option.set[1] or not option.set[2] then
		error("No set functions for check box with dropdown.")
	end
	if not option.get[1] or not option.get[2] then
		error("No get functions for check box with dropdown.")
	end
	local checkBoxWithDropdownContainer = AceGUI:Create("EPContainer")
	checkBoxWithDropdownContainer:SetFullWidth(true)
	checkBoxWithDropdownContainer:SetLayout("EPHorizontalLayout")
	checkBoxWithDropdownContainer:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetFullHeight(true)
	checkBox:SetRelativeWidth(0.5)
	checkBox:SetText(option.label)
	checkBox:SetChecked(option.get[1]())

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetRelativeWidth(0.5)
	AddDropdownValues(dropdown, option.values, option)
	dropdown:SetValue(option.get[2]())

	if
		type(option.enabled) == "table"
		and type(option.enabled[1]) == "function"
		and type(option.enabled[2]) == "function"
	then
		tinsert(self.refreshMap, { widget = checkBox, enabled = option.enabled[1] })
		tinsert(self.refreshMap, { widget = dropdown, enabled = option.enabled[2] })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
			checkBox:SetChecked(option.get[1]())
			dropdown:SetValue(option.get[2]())
		end)
	end
	checkBox:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)
	dropdown:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)

	checkBox:SetCallback("OnEnter", function()
		ShowTooltip(checkBox.frame, GetLabels(option.labels)[1], GetDescriptions(option.descriptions)[1])
	end)
	dropdown:SetCallback("OnEnter", function()
		ShowTooltip(dropdown.frame, GetLabels(option.labels)[2], GetDescriptions(option.descriptions)[2])
	end)
	checkBox:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	dropdown:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	checkBoxWithDropdownContainer:AddChildren(checkBox, dropdown)
	return checkBoxWithDropdownContainer
end

---@param self EPOptions
---@param option EPSettingOption
---@return EPContainer, EPCheckBox, fun(EPCheckBox, boolean), string
local function CreateCheckBoxBesideButton(self, option)
	local checkBoxBesideButtonContainer = AceGUI:Create("EPContainer")
	checkBoxBesideButtonContainer:SetFullWidth(true)
	checkBoxBesideButtonContainer:SetLayout("EPHorizontalLayout")
	checkBoxBesideButtonContainer:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local widget = AceGUI:Create("EPCheckBox")
	widget:SetRelativeWidth(0.5)
	widget:SetText(option.label)

	local button = AceGUI:Create("EPButton")
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetText(option.buttonText)
	button:SetRelativeWidth(0.5)
	button:SetCallback("Clicked", option.buttonCallback)
	if type(option.buttonEnabled) == "function" then
		tinsert(self.refreshMap, { widget = button, enabled = option.buttonEnabled })
	end
	checkBoxBesideButtonContainer:AddChildren(widget, button)
	return checkBoxBesideButtonContainer, widget, widget.SetChecked, "OnValueChanged"
end

---@param self EPOptions
---@param option EPSettingOption
---@return EPContainer
local function CreateCenteredButton(self, option)
	local container = AceGUI:Create("EPContainer")
	container:SetFullWidth(true)
	container:SetLayout("EPVerticalLayout")
	container:SetAlignment("center")
	container:SetSelfAlignment("center")

	local button = AceGUI:Create("EPButton")
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetText(option.label)
	button:SetWidthFromText()

	if type(option.enabled) == "function" then
		tinsert(self.refreshMap, { widget = button, enabled = option.enabled })
	end
	button:SetCallback("Clicked", function()
		if type(option.buttonCallback) == "function" then
			option.buttonCallback()
		end
		RefreshEnabledStates(self.refreshMap)
	end)

	button:SetCallback("OnEnter", function()
		ShowTooltip(button.frame, option.label, option.description)
	end)
	button:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)

	container:AddChild(button)
	return container
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@return EPContainer
local function CreateDropdownBesideButton(self, option, optionGroupKey, optionIndex)
	local container = AceGUI:Create("EPContainer")
	container:SetFullWidth(true)
	container:SetLayout("EPHorizontalLayout")
	container:SetSpacing(unpack(k.DoubleLineEditContainerSpacing))

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetRelativeWidth(0.7)
	local values = {}
	if type(option.values) == "table" then
		values = option.values --[[@as table]]
	elseif type(option.values) == "function" then
		values = option.values()
	end
	dropdown:AddItems(values, "EPDropdownItemToggle")
	dropdown:SetValue(option.get())

	local button = AceGUI:Create("EPButton")
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetText(option.buttonText)
	button:SetRelativeWidth(0.3)

	if option.updateIndices then
		if type(option.values) == "function" then
			UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
				dropdown:Clear()
				dropdown:AddItems(option.values(), "EPDropdownItemToggle", option.neverShowItemsAsSelected)
				dropdown:SetValue(option.get())
			end)
		else
			UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
				dropdown:SetValue(option.get())
			end)
		end
	end

	dropdown:SetCallback("OnValueChanged", function(_, _, value)
		option.set(value)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
			Update(self.updateIndices[optionGroupKey][optionIndex])
		end
	end)

	if option.confirm then
		button:SetCallback("Clicked", function()
			if not s.MessageBox then
				s.MessageBox = AceGUI:Create("EPMessageBox")
				s.MessageBox.frame:SetParent(UIParent)
				s.MessageBox.frame:SetFrameLevel(self.frame:GetFrameLevel() + 100)
				s.MessageBox:SetTitle(L["Confirmation"])
				if type(option.confirmText) == "string" then
					s.MessageBox:SetText(option.confirmText --[[@as string]])
				else
					s.MessageBox:SetText(option.confirmText(false))
				end
				s.MessageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				s.MessageBox:SetPoint("TOP", UIParent, "TOP", 0, -s.MessageBox.frame:GetBottom())
				s.MessageBox:SetCallback("Accepted", function()
					AceGUI:Release(s.MessageBox)
					s.MessageBox = nil
					if type(option.buttonCallback) == "function" then
						option.buttonCallback()
					end
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
						Update(self.updateIndices[optionGroupKey][optionIndex])
					end
				end)
				s.MessageBox:SetCallback("Rejected", function()
					AceGUI:Release(s.MessageBox)
					s.MessageBox = nil
				end)
			end
		end)
	else
		button:SetCallback("Clicked", option.buttonCallback)
	end

	if type(option.enabled) == "function" then
		tinsert(self.refreshMap, { widget = dropdown, enabled = option.enabled })
	end
	if type(option.buttonEnabled) == "function" then
		tinsert(self.refreshMap, { widget = button, enabled = option.buttonEnabled })
	end

	dropdown:SetCallback("OnEnter", function()
		ShowTooltip(dropdown.frame, option.label, option.description)
	end)
	dropdown:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)

	if option.buttonDescription then
		button:SetCallback("OnEnter", function()
			ShowTooltip(button.frame, option.buttonText, option.buttonDescription)
		end)
		button:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
	end

	container:AddChildren(dropdown, button)
	return container
end

---@param self EPOptions
---@param widget any
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@param callbackName string
---@param setWidgetValue fun(...:any)?
---@param label EPLabel?
local function SetCallbacks(self, widget, option, optionGroupKey, optionIndex, callbackName, setWidgetValue, label)
	if widget and callbackName then
		if type(setWidgetValue) == "function" then
			setWidgetValue(widget, option.get())
		end
		if type(option.enabled) == "function" then
			tinsert(self.refreshMap, { widget = widget, enabled = option.enabled })
			if label then
				tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
			end
		end

		if type(setWidgetValue) == "function" then
			if option.updateIndices then
				if option.type == "dropdown" and type(option.values) == "function" then
					UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
						widget:Clear()
						widget:AddItems(option.values(), "EPDropdownItemToggle", option.neverShowItemsAsSelected)
						setWidgetValue(widget, option.get())
					end)
				else
					UpdateUpdateIndices(self.updateIndices, option, optionGroupKey, optionIndex, function()
						setWidgetValue(widget, option.get())
					end)
				end
			end
			if type(option.validate) == "function" then
				widget:SetCallback(callbackName, function(_, _, ...)
					local valid, valueToRevertTo, valueToRevertToB = option.validate(...)
					if not valid and valueToRevertTo then
						setWidgetValue(widget, valueToRevertTo)
						if valueToRevertToB then
							option.set(valueToRevertTo, valueToRevertToB)
						else
							option.set(valueToRevertTo)
						end
					else
						option.set(...)
					end
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
						Update(self.updateIndices[optionGroupKey][optionIndex])
					end
				end)
			elseif option.confirm then
				widget:SetCallback(callbackName, function(_, _, ...)
					if not s.MessageBox then
						local value1, value2, value3, value4 = ...
						s.MessageBox = AceGUI:Create("EPMessageBox")
						s.MessageBox.frame:SetParent(UIParent)
						s.MessageBox.frame:SetFrameLevel(self.frame:GetFrameLevel() + 100)
						s.MessageBox:SetTitle(L["Confirmation"])
						if type(option.confirmText) == "string" then
							s.MessageBox:SetText(option.confirmText --[[@as string]])
						else
							s.MessageBox:SetText(option.confirmText(value1))
						end
						s.MessageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						s.MessageBox:SetPoint("TOP", UIParent, "TOP", 0, -s.MessageBox.frame:GetBottom())
						s.MessageBox:SetCallback("Accepted", function()
							AceGUI:Release(s.MessageBox)
							s.MessageBox = nil
							option.set(value1, value2, value3, value4)
							RefreshEnabledStates(self.refreshMap)
							if
								self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex]
							then
								Update(self.updateIndices[optionGroupKey][optionIndex])
							end
						end)
						s.MessageBox:SetCallback("Rejected", function()
							AceGUI:Release(s.MessageBox)
							s.MessageBox = nil
							if widget and widget.pullout and option and option.neverShowItemsAsSelected then
								setWidgetValue(widget, nil)
							end
						end)
					end
				end)
			else
				widget:SetCallback(callbackName, function(_, _, ...)
					option.set(...)
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
						Update(self.updateIndices[optionGroupKey][optionIndex])
					end
				end)
			end
		else
			widget:SetCallback(callbackName, function(_, _, ...)
				if type(option.validate) == "function" then
					local valid, valueToRevertTo, valueToRevertToB = option.validate(...)
					if not valid and valueToRevertTo then
						if valueToRevertToB then
							option.set(valueToRevertTo, valueToRevertToB)
						else
							option.set(valueToRevertTo)
						end
					else
						option.set(...)
					end
				else
					option.set(...)
				end
				RefreshEnabledStates(self.refreshMap)
				if self.updateIndices[optionGroupKey] and self.updateIndices[optionGroupKey][optionIndex] then
					Update(self.updateIndices[optionGroupKey][optionIndex])
				end
			end)
		end
		widget:SetCallback("OnEnter", function()
			ShowTooltip(widget.frame, option.label, option.description)
		end)
		widget:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
	end
end

---@param self EPOptions
---@param option EPSettingOption
---@param optionGroupKey string
---@param optionIndex integer
---@return EPContainer
local function CreateOptionWidget(self, option, optionGroupKey, optionIndex)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPHorizontalLayout")
	container:SetSpacing(k.SpacingBetweenLabelAndWidget, 0)
	container:SetFullWidth(true)

	if option.indent then
		container:SetPadding(k.IndentWidth, 0, 0, 0)
	end

	local containerChildren = {}
	if option.type == "checkBox" then
		local widget = AceGUI:Create("EPCheckBox")
		widget:SetFullWidth(true)
		widget:SetText(option.label)
		SetCallbacks(self, widget, option, optionGroupKey, optionIndex, "OnValueChanged", widget.SetChecked, nil)
		tinsert(containerChildren, widget)
	elseif option.type == "checkBoxBesideButton" then
		local checkBoxBesideButtonContainer, widget, setWidgetValue, callbackName =
			CreateCheckBoxBesideButton(self, option)
		SetCallbacks(self, widget, option, optionGroupKey, optionIndex, callbackName, setWidgetValue, nil)
		tinsert(containerChildren, checkBoxBesideButtonContainer)
	elseif option.type == "checkBoxWithDropdown" then
		tinsert(containerChildren, CreateCheckBoxWithDropdown(self, option, optionGroupKey, optionIndex))
	elseif option.type == "centeredButton" then
		tinsert(containerChildren, CreateCenteredButton(self, option))
	else
		local label = AceGUI:Create("EPLabel")
		label:SetText(option.label .. ":", 0)
		label:SetFontSize(k.OptionLabelFontSize)
		label:SetFrameWidthFromText()
		label:SetFullHeight(true)
		label.text:SetTextColor(unpack(k.LabelTextColor))
		tinsert(containerChildren, label)

		if option.type == "dropdown" then
			local widget = AceGUI:Create("EPDropdown")
			widget:SetFullWidth(true)
			AddDropdownValues(widget, option.values, option)
			SetCallbacks(self, widget, option, optionGroupKey, optionIndex, "OnValueChanged", widget.SetValue, label)
			tinsert(containerChildren, widget)
		elseif option.type == "lineEdit" then
			local widget = AceGUI:Create("EPLineEdit")
			widget:SetFullWidth(true)
			SetCallbacks(self, widget, option, optionGroupKey, optionIndex, "OnTextSubmitted", widget.SetText, label)
			tinsert(containerChildren, widget)
		elseif option.type == "colorPicker" then
			local widget = AceGUI:Create("EPColorPicker")
			widget:SetFullWidth(true)
			SetCallbacks(self, widget, option, optionGroupKey, optionIndex, "OnValueChanged", widget.SetColor, label)
			tinsert(containerChildren, widget)
		elseif option.type == "doubleColorPicker" then
			tinsert(containerChildren, CreateDoubleColorPicker(self, option, optionGroupKey, optionIndex, label))
		elseif option.type == "doubleCheckBox" then
			tinsert(containerChildren, CreateDoubleCheckBox(self, option, optionGroupKey, optionIndex, label))
		elseif option.type == "radioButtonGroup" then
			tinsert(containerChildren, CreateRadioButtonGroup(self, option, optionGroupKey, optionIndex, label))
		elseif option.type == "doubleLineEdit" then
			tinsert(containerChildren, CreateDoubleLineEdit(self, option, optionGroupKey, optionIndex, label))
		elseif option.type == "frameChooser" then
			tinsert(containerChildren, CreateFrameChooser(self, option, optionGroupKey, optionIndex, label))
		elseif option.type == "dropdownBesideButton" then
			tinsert(containerChildren, CreateDropdownBesideButton(self, option, optionGroupKey, optionIndex))
		end
	end

	container:AddChildren(unpack(containerChildren))
	return container
end

---@param self EPOptions
---@param tab string
---@return EPContainer|nil
local function CreateUncategorizedOptionWidgets(self, tab)
	local optionGroupKey = tab .. "_u"
	local uncategorizedContainerChildren = {}
	local labels = {}
	local maxLabelWidth = 0

	for optionIndex, option in ipairs(self.optionTabs[tab]) do
		if not option.category and not option.uncategorizedBottom then
			if option.type == "horizontalLine" then
				local line = AceGUI:Create("EPSpacer")
				line.frame:SetBackdrop(k.LineBackdrop)
				line.frame:SetBackdropColor(unpack(k.BackdropBorderColor))
				line:SetFullWidth(true)
				line:SetHeight(2 + k.SpacingBetweenOptions)
				tinsert(uncategorizedContainerChildren, line)
			else
				local container = CreateOptionWidget(self, option, optionGroupKey, optionIndex)
				if #container.children >= 2 and container.children[1].type == "EPLabel" then
					maxLabelWidth = max(maxLabelWidth, container.children[1].frame:GetWidth())
					tinsert(labels, container.children[1])
				end
				tinsert(uncategorizedContainerChildren, container)
			end
		end
	end

	for _, label in ipairs(labels) do
		label:SetWidth(maxLabelWidth)
	end

	if #uncategorizedContainerChildren > 0 then
		local uncategorizedContainer = AceGUI:Create("EPContainer")
		uncategorizedContainer:SetLayout("EPVerticalLayout")
		uncategorizedContainer:SetSpacing(0, k.SpacingBetweenOptions)
		uncategorizedContainer:SetFullWidth(true)

		uncategorizedContainer:AddChildren(unpack(uncategorizedContainerChildren))
		return uncategorizedContainer
	else
		return nil
	end
end

---@param self EPOptions
---@param tab string
local function PopulateActiveTab(self, tab)
	if tab == self.activeTab then
		return
	end
	self.activeTab = tab
	self.activeContainer:ReleaseChildren()
	wipe(self.updateIndices)
	wipe(self.refreshMap)

	if s.MessageBox then
		s.MessageBox:Release()
	end
	s.MessageBox = nil

	if self.optionTabs[tab][1].type == "cooldownOverrides" then
		self.labelContainer.frame:Show()
		self.labelContainer.frame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
		self.labelContainer.frame:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
		local wrapperPadding = self.scrollFrame.GetWrapperPadding()
		self.scrollFrame.frame:SetPoint("TOP", self.labelContainer.frame, "BOTTOM", 0, wrapperPadding)

		cooldownOverrideObject.FormatTime = self.FormatTime
		cooldownOverrideObject.GetSpellCooldownAndCharges = self.GetSpellCooldownAndCharges
		cooldownOverrideObject.labelContainer = self.labelContainer
		cooldownOverrideObject.activeContainer = self.activeContainer
		cooldownOverrideObject.scrollFrame = self.scrollFrame
		cooldownOverrideObject.option = self.optionTabs[tab][1]
		cooldownOverrideObject.cooldownAndChargeOverrides = {} ---@type table<integer, CooldownAndChargeOverride>
		cooldownOverrideObject.realDropdown = AceGUI:Create("EPDropdown")
		cooldownOverrideObject.realDropdown:AddItems(self.spellDropdownItems, "EPDropdownItemToggle")
		cooldownOverrideObject.realDropdown.frame:Hide()
		cooldownOverrideObject.CreateCooldownOverrideTab(self.optionTabs[tab][1])

		self:Resize()
		cooldownOverrideObject.UpdateRelativeWidths()
		self.scrollFrame:UpdateThumbPositionAndSize()
	else
		self.scrollFrame.frame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
		self.labelContainer:ReleaseChildren()
		self.labelContainer.frame:ClearAllPoints()
		self.labelContainer.frame:Hide()

		cooldownOverrideObject.FormatTime = nil
		cooldownOverrideObject.GetSpellCooldownAndCharges = nil
		cooldownOverrideObject.cooldownAndChargeOverrides = nil
		cooldownOverrideObject.labelContainer = nil
		cooldownOverrideObject.activeContainer = nil
		cooldownOverrideObject.scrollFrame = nil
		cooldownOverrideObject.option = nil
		if cooldownOverrideObject.realDropdown then
			cooldownOverrideObject.realDropdown:Release()
			cooldownOverrideObject.realDropdown = nil
		end

		local activeContainerChildren = {}

		local uncategorizedContainer = CreateUncategorizedOptionWidgets(self, tab)
		if uncategorizedContainer then
			tinsert(activeContainerChildren, uncategorizedContainer)
			local categorySpacer = AceGUI:Create("EPSpacer")
			categorySpacer:SetHeight(k.SpacingBetweenCategories)
			tinsert(activeContainerChildren, categorySpacer)
		end

		local categories = self.tabCategories[tab]
		if categories then
			for categoryIndex, category in ipairs(categories) do
				local categoryLabel = AceGUI:Create("EPLabel")
				categoryLabel:SetText(category, 0)
				categoryLabel:SetFontSize(k.CategoryFontSize)
				categoryLabel:SetFullWidth(true)
				categoryLabel:SetFrameHeightFromText()
				categoryLabel.text:SetTextColor(unpack(k.CategoryTextColor))
				tinsert(activeContainerChildren, categoryLabel)

				local categoryContainer = AceGUI:Create("EPContainer")
				categoryContainer:SetLayout("EPVerticalLayout")
				categoryContainer:SetSpacing(0, k.SpacingBetweenOptions)
				categoryContainer:SetFullWidth(true)
				categoryContainer:SetPadding(unpack(k.CategoryPadding))
				categoryContainer:SetBackdrop(k.GroupBoxBackdrop, { 0, 0, 0, 0 }, k.GroupBoxBorderColor)

				local optionGroupKey = tab .. categoryIndex
				local categoryContainerChildren = {}
				local labels = {}
				local maxLabelWidth = 0

				for optionIndex, option in ipairs(self.optionTabs[tab]) do
					if option.category == category then
						if option.type == "horizontalLine" then
							local line = AceGUI:Create("EPSpacer")
							line.frame:SetBackdrop(k.LineBackdrop)
							line.frame:SetBackdropColor(unpack(k.BackdropBorderColor))
							line:SetFullWidth(true)
							line:SetHeight(2 + k.SpacingBetweenOptions)
							tinsert(categoryContainerChildren, line)
						else
							local container = CreateOptionWidget(self, option, optionGroupKey, optionIndex)
							if #container.children >= 2 and container.children[1].type == "EPLabel" then
								maxLabelWidth = max(maxLabelWidth, container.children[1].frame:GetWidth())
								tinsert(labels, container.children[1])
							end
							tinsert(categoryContainerChildren, container)
						end
					end
				end

				for _, label in ipairs(labels) do
					label:SetWidth(maxLabelWidth)
				end

				categoryContainer:AddChildren(unpack(categoryContainerChildren))
				tinsert(activeContainerChildren, categoryContainer)

				if categoryIndex < #categories then
					local categorySpacer = AceGUI:Create("EPSpacer")
					categorySpacer:SetHeight(k.SpacingBetweenCategories)
					tinsert(activeContainerChildren, categorySpacer)
				end
			end
		end

		local optionGroupKey = tab .. "_ub"

		for optionIndex, option in ipairs(self.optionTabs[tab]) do
			if option.uncategorizedBottom and not option.category then
				local categorySpacer = AceGUI:Create("EPSpacer")
				categorySpacer:SetHeight(k.SpacingBetweenCategories)
				tinsert(activeContainerChildren, categorySpacer)

				local container = CreateOptionWidget(self, option, optionGroupKey, optionIndex)
				tinsert(activeContainerChildren, container)
			end
		end

		self.activeContainer:AddChildren(unpack(activeContainerChildren))
		RefreshEnabledStates(self.refreshMap)
		self:Resize()
		self.scrollFrame:UpdateThumbPositionAndSize()
	end
end

---@param self EPOptions
local function OnAcquire(self)
	self.activeTab = ""
	self.optionTabs = {}
	self.tabCategories = {}
	self.updateIndices = {}
	self.refreshMap = {}

	self.frame:SetSize(k.FrameWidth, k.FrameHeight)

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle(k.Title)
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("CloseButtonClicked", function()
		self:Fire("CloseButtonClicked")
	end)
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
		local x, y = self.frame:GetLeft(), self.frame:GetTop()
		self.frame:StopMovingOrSizing()
		self.frame:ClearAllPoints()
		self.frame:SetPoint(
			"TOP",
			x - UIParent:GetWidth() / 2.0 + self.frame:GetWidth() / 2.0,
			-(UIParent:GetHeight() - y)
		)
	end)
	self.windowBar = windowBar

	self.tabTitleContainer = AceGUI:Create("EPContainer")
	self.tabTitleContainer:SetLayout("EPHorizontalLayout")
	self.tabTitleContainer:SetSpacing(0, 0)
	self.tabTitleContainer:SetAlignment("center")
	self.tabTitleContainer:SetSelfAlignment("center")
	self.tabTitleContainer.frame:SetParent(self.frame)
	self.tabTitleContainer.frame:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.ContentFramePadding.y)

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetSize(k.FrameWidth, k.FrameHeight)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.ContentFramePadding.y)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 0)
	self.activeContainer:SetPadding(unpack(k.ActiveContainerPadding))
	self.scrollFrame:SetScrollChild(self.activeContainer.frame --[[@as Frame]], true, false)

	self.labelContainer = AceGUI:Create("EPContainer")
	self.labelContainer:SetLayout("EPHorizontalLayout")
	self.labelContainer:SetSpacing(k.SpacingBetweenLabelAndWidget, 0)
	local horizontalLabelContainerPadding = self.scrollFrame.GetWrapperPadding() + k.ActiveContainerPadding[1]
	self.labelContainer:SetPadding(horizontalLabelContainerPadding, 0, horizontalLabelContainerPadding, 0)
	self.labelContainer.frame:SetBackdrop(k.GroupBoxBackdrop)
	self.labelContainer.frame:SetBackdropColor(unpack(k.BackdropColor))
	self.labelContainer.frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	self.labelContainer.frame:SetParent(self.frame)
	self.labelContainer.frame:SetHeight(0)
	self.labelContainer.frame:Hide()

	self.frame:Show()
end

---@param self EPOptions
local function OnRelease(self)
	if s.MessageBox then
		AceGUI:Release(s.MessageBox)
	end
	s.MessageBox = nil

	AceGUI:Release(self.scrollFrame)
	self.scrollFrame = nil

	AceGUI:Release(self.activeContainer)
	self.activeContainer = nil

	cooldownOverrideObject.FormatTime = nil
	cooldownOverrideObject.GetSpellCooldown = nil
	cooldownOverrideObject.cooldownAndChargeOverrides = nil
	cooldownOverrideObject.labelContainer = nil
	cooldownOverrideObject.activeContainer = nil
	cooldownOverrideObject.scrollFrame = nil
	cooldownOverrideObject.option = nil
	if cooldownOverrideObject.realDropdown then
		AceGUI:Release(cooldownOverrideObject.realDropdown)
	end
	cooldownOverrideObject.realDropdown = nil

	AceGUI:Release(self.windowBar)
	self.windowBar = nil

	AceGUI:Release(self.tabTitleContainer)
	self.tabTitleContainer = nil

	AceGUI:Release(self.labelContainer)
	self.labelContainer = nil

	self.optionTabs = nil
	self.activeTab = nil
	self.tabCategories = nil
	self.updateIndices = nil
	self.refreshMap = nil
	self.FormatTime = nil
	self.GetSpellCooldownAndCharges = nil
	self.spellDropdownItems = nil
end

---@param self EPOptions
---@param tabName string
---@param options table<integer, EPSettingOption>
---@param categories table<integer, string>?
local function AddOptionTab(self, tabName, options, categories)
	self.optionTabs[tabName] = options
	if categories then
		self.tabCategories[tabName] = categories
	end
	local tab = AceGUI:Create("EPButton")
	tab:SetIsToggleable(true)
	tab:SetText(tabName)
	tab:SetWidthFromText()
	tab:SetColor(unpack(k.NeutralButtonColor))
	self.tabTitleContainer:AddChild(tab)
	tab:SetCallback("Clicked", function(button, _)
		if not button:IsToggled() then
			for _, child in ipairs(self.tabTitleContainer.children) do
				if child:IsToggled() then
					child:Toggle()
				end
			end
			button:Toggle()
			local success, err = SafeCall(PopulateActiveTab, self, button.button:GetText())
			if not success then
				print("Error opening options widget:", err)
			end
		end
	end)
	SetButtonWidths(self.tabTitleContainer)
	self.tabTitleContainer:DoLayout()
end

---@param self EPOptions
---@param tab string
---@param fallbackTab string
local function SetCurrentTab(self, tab, fallbackTab)
	self.activeTab = ""
	if not self.tabCategories[tab] then
		tab = fallbackTab
	end
	for _, child in ipairs(self.tabTitleContainer.children) do
		if child.button:GetText() == tab and not child:IsToggled() then
			child:Toggle()
		elseif child:IsToggled() then
			child:Toggle()
		end
	end
	PopulateActiveTab(self, tab)
end

---@param self EPOptions
local function UpdateOptions(self)
	for _, indices in pairs(self.updateIndices) do
		for _, functions in pairs(indices) do
			Update(functions)
		end
	end
end

---@param self EPOptions
local function Resize(self)
	local wrapperPadding = self.scrollFrame.GetWrapperPadding()

	-- local tableTitleContainerHeight = self.tabTitleContainer.frame:GetHeight()
	-- local containerHeight = self.activeContainer.frame:GetHeight()
	-- if self.labelContainer.frame:IsShown() then
	-- 	containerHeight = containerHeight + self.labelContainer.frame:GetHeight() - wrapperPadding
	-- end

	-- local paddingHeight = k.ContentFramePadding.y * 3
	-- local height = self.windowBar.frame:GetHeight() + tableTitleContainerHeight + containerHeight + paddingHeight

	local tabWidth = self.tabTitleContainer.frame:GetWidth()
	local activeWidth = self.activeContainer.frame:GetWidth() + 2 * wrapperPadding
	if self.scrollFrame.scrollBar:IsShown() then
		activeWidth = activeWidth + self.scrollFrame.scrollBarScrollFramePadding + self.scrollFrame.scrollBar:GetWidth()
	end
	local width = k.ContentFramePadding.x * 2 + max(tabWidth, activeWidth)

	self.frame:SetSize(width, k.PreferredHeight)
	self.activeContainer:DoLayout()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.FrameWidth, k.FrameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local frameChooserFrame = CreateFrame("Frame", nil, frame)
	frameChooserFrame:Hide()
	local frameChooserBox = CreateFrame("Frame", nil, frameChooserFrame, "BackdropTemplate")
	frameChooserBox:SetFrameStrata("TOOLTIP")
	frameChooserBox:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frameChooserBox:SetBackdropBorderColor(0, 1, 0)
	frameChooserBox:Hide()

	---@class EPOptions : AceGUIWidget
	---@field windowBar EPWindowBar
	---@field tabTitleContainer EPContainer
	---@field activeContainer EPContainer
	---@field labelContainer EPContainer
	---@field activeTab string
	---@field optionTabs table<string, table<integer, EPSettingOption>>
	---@field tabCategories table<string, table<integer, string>>
	---@field updateIndices table<string, table<integer, table<integer, fun()>>>
	---@field refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
	---@field scrollFrame EPScrollFrame
	---@field spellDropdownItems table<integer, DropdownItemData>
	---@field FormatTime fun(number): string,string
	---@field GetSpellCooldownAndCharges fun(integer): number, integer
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		AddOptionTab = AddOptionTab,
		SetCurrentTab = SetCurrentTab,
		UpdateOptions = UpdateOptions,
		Resize = Resize,
		frameChooserFrame = frameChooserFrame,
		frameChooserBox = frameChooserBox,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
