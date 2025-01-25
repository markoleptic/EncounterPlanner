local _, Namespace = ...
local L = Namespace.L

---@class Private
local Private = Namespace

local Type = "EPOptions"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local tooltip = Private.tooltip

local CreateFrame = CreateFrame
local geterrorhandler = geterrorhandler
local GetMouseFoci = GetMouseFoci
local ipairs = ipairs
local min = math.min
local pairs = pairs
local type = type
local tinsert = tinsert
local unpack = unpack
local IsMouseButtonDown = IsMouseButtonDown
local ResetCursor = ResetCursor
local SetCursor = SetCursor
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function SafeCall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

local frameWidth = 500
local frameHeight = 500
local minScrollFrameHeight = 400
local maxScrollFrameHeight = 600
local windowBarHeight = 28
local contentFramePadding = { x = 15, y = 15 }
local title = L["Preferences"]
local categoryFontSize = 18
local optionLabelFontSize = 14
local spacingBetweenOptions = 10
local spacingBetweenCategories = 15
local spacingBetweenLabelAndWidget = 8
local indentWidth = 20
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local categoryTextColor = { 1, 0.82, 0, 1 }
local labelTextColor = { 1, 1, 1, 1 }
local frameChooserContainerSpacing = { 8, 0 }
local doubleLineEditContainerSpacing = { 8, 0 }
local radioButtonGroupSpacing = { 8, 0 }
local activeContainerPadding = { 10, 10, 10, 10 }
local categoryPadding = { 15, 15, 15, 15 }

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
local groupBoxBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}
local lineBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = spacingBetweenOptions / 2, bottom = spacingBetweenOptions / 2 },
}
local groupBoxBorderColor = { 0.25, 0.25, 0.25, 0.9 }

local isChoosingFrame = false
local messageBox = nil

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

local function StopChoosingFrame(frameChooserFrame, frameChooserBox, focusName, setFunc)
	isChoosingFrame = false
	if frameChooserFrame then
		frameChooserFrame:SetScript("OnUpdate", nil)
		frameChooserBox:Hide()
	end
	ResetCursor()
	if setFunc then
		setFunc(focusName)
	end
end

local function StartChoosingFrame(frameChooserFrame, frameChooserBox, setFunc)
	isChoosingFrame = true
	local oldFocus = nil
	local oldFocusName = nil
	local focusName = nil
	SetCursor("CAST_CURSOR")
	frameChooserFrame:SetScript("OnUpdate", function()
		if IsMouseButtonDown("RightButton") then
			StopChoosingFrame(frameChooserFrame, frameChooserBox, nil)
			return
		elseif IsMouseButtonDown("LeftButton") then
			if oldFocusName then
				StopChoosingFrame(frameChooserFrame, frameChooserBox, oldFocusName, setFunc)
			else
				StopChoosingFrame(frameChooserFrame, frameChooserBox, "UIParent", setFunc)
			end
		else
			local foci = GetMouseFoci()
			local focus = foci[1] or nil
			if focus then
				focusName = GetName(focus)
				if focusName == "WorldFrame" or not focusName then
					focusName = nil
				end
				if focus ~= oldFocus then
					if focusName then
						frameChooserBox:ClearAllPoints()
						frameChooserBox:SetPoint("BOTTOMLEFT", focus, "BOTTOMLEFT", 4, -4)
						frameChooserBox:SetPoint("TOPRIGHT", focus, "TOPRIGHT", -4, 4)
						frameChooserBox:Show()
					end
					if focusName ~= oldFocusName then
						oldFocusName = focusName
					end
					oldFocus = focus
				end
			end
			if not focusName then
				frameChooserBox:Hide()
			else
				SetCursor("CAST_CURSOR")
			end
		end
	end)
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

---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
local function RefreshEnabledStates(refreshMap)
	for _, tab in pairs(refreshMap) do
		---@diagnostic disable-next-line: undefined-field
		if tab.widget.SetEnabled then
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
---@param func fun()
local function UpdateUpdateIndices(updateIndices, option, index, func)
	if option.updateIndices then
		if not updateIndices[option.category] then
			updateIndices[option.category] = {}
		end
		for _, relativeOptionIndex in pairs(option.updateIndices) do
			local optionIndex = index + relativeOptionIndex
			if not updateIndices[option.category][optionIndex] then
				updateIndices[option.category][optionIndex] = {}
			end
			tinsert(updateIndices[option.category][optionIndex], func)
		end
	end
end

local function ShowTooltip(frame, label, description)
	tooltip:SetOwner(frame, "ANCHOR_TOP")
	tooltip:SetText(label, 1, 0.82, 0, true)
	if type(description) == "string" then
		tooltip:AddLine(description, 1, 1, 1, true)
	end
	tooltip:Show()
end

---@param self EPOptions
---@param option EPSettingOption
---@param index integer
---@param label EPLabel
---@return EPContainer
local function CreateFrameChooser(self, option, index, label)
	local frameChooserContainer = AceGUI:Create("EPContainer")
	frameChooserContainer:SetFullWidth(true)
	frameChooserContainer:SetLayout("EPHorizontalLayout")
	frameChooserContainer:SetSpacing(unpack(frameChooserContainerSpacing))

	local valueLineEdit = AceGUI:Create("EPLineEdit")
	valueLineEdit:SetText(option.get() --[[@as string]])
	valueLineEdit:SetRelativeWidth(0.75)
	valueLineEdit:SetFullHeight(true)
	valueLineEdit:SetReadOnly(true)

	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			valueLineEdit:SetText(option.get() --[[@as string]])
		end)
	end

	local button = AceGUI:Create("EPButton")
	button:SetText("Choose")
	button:SetRelativeWidth(0.25)
	button:SetCallback("Clicked", function()
		if not isChoosingFrame then
			self.frameChooserFrame:Show()
			StartChoosingFrame(self.frameChooserFrame, self.frameChooserBox, function(value)
				option.set(value)
				valueLineEdit:SetText(value)
				RefreshEnabledStates(self.refreshMap)
				if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
					Update(self.updateIndices[option.category][index])
				end
			end)
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
---@param index integer
---@param label EPLabel
---@return EPContainer
local function CreateRadioButtonGroup(self, option, index, label)
	local radioButtonGroup = AceGUI:Create("EPContainer")
	radioButtonGroup:SetLayout("EPHorizontalLayout")
	radioButtonGroup:SetSpacing(unpack(radioButtonGroupSpacing))
	radioButtonGroup:SetFullWidth(true)
	local radioButtonGroupChildren = {}
	local values = type(option.values) == "table" and option.values or option.values() --[[@as table<integer, DropdownItemData>]]
	local relativeWidth = 1.0 / #values
	for _, itemValueAndText in pairs(values) do
		local radioButton = AceGUI:Create("EPRadioButton")
		radioButton:SetRelativeWidth(relativeWidth)
		radioButton:SetLabelText(itemValueAndText.text)
		radioButton:SetToggled(option.get() == itemValueAndText.itemValue)
		radioButton:GetUserDataTable().key = itemValueAndText.itemValue
		tinsert(radioButtonGroupChildren, radioButton)
	end
	if option.enabled then
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	radioButtonGroup:AddChildren(unpack(radioButtonGroupChildren))
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			for _, child in ipairs(radioButtonGroup.children) do
				child:SetToggled(option.get() == child:GetUserDataTable().key)
			end
		end)
	end
	for _, child in ipairs(radioButtonGroup.children) do
		if option.enabled and child.SetEnabled then
			child:SetEnabled(option.enabled())
			tinsert(self.refreshMap, { widget = child, enabled = option.enabled })
		end
		child:SetCallback("Toggled", function(radioButton, _, _)
			handleRadioButtonToggled(radioButton, radioButtonGroup)
			local value = radioButton:GetUserData("key")
			option.set(value)
			RefreshEnabledStates(self.refreshMap)
			if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
				Update(self.updateIndices[option.category][index])
			end
		end)
		child:SetCallback("OnEnter", function()
			ShowTooltip(radioButtonGroup.frame, option.label, option.description)
		end)
		child:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
	end
	return radioButtonGroup
end

---@param self EPOptions
---@param option EPSettingOption
---@param index integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleLineEdit(self, option, index, label)
	local doubleLineEditContainer = AceGUI:Create("EPContainer")
	doubleLineEditContainer:SetFullWidth(true)
	doubleLineEditContainer:SetLayout("EPHorizontalLayout")
	doubleLineEditContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local labelX = AceGUI:Create("EPLabel")
	labelX:SetText(option.labels[1] .. ":", 0)
	labelX:SetRelativeWidth(0.05)
	labelX:SetFullHeight(true)

	local lineEditX = AceGUI:Create("EPLineEdit")
	lineEditX:SetRelativeWidth(0.45)

	local labelY = AceGUI:Create("EPLabel")
	labelY:SetText(option.labels[2] .. ":", 0)
	labelY:SetRelativeWidth(0.05)
	labelY:SetFullHeight(true)

	local lineEditY = AceGUI:Create("EPLineEdit")
	lineEditY:SetRelativeWidth(0.45)

	if option.enabled then
		tinsert(self.refreshMap, { widget = labelX, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = lineEditX, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = labelY, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = lineEditY, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
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
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end
	lineEditX:SetCallback("OnTextSubmitted", Callback)
	lineEditY:SetCallback("OnTextSubmitted", Callback)
	local x, y = option.get()
	lineEditX:SetText(x)
	lineEditY:SetText(y)
	lineEditX:SetCallback("OnEnter", function()
		ShowTooltip(lineEditX.frame, option.labels[1], option.descriptions[1])
	end)
	lineEditY:SetCallback("OnEnter", function()
		ShowTooltip(lineEditY.frame, option.labels[2], option.descriptions[2])
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
---@param index integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleColorPicker(self, option, index, label)
	local doubleColorPickerContainer = AceGUI:Create("EPContainer")
	doubleColorPickerContainer:SetFullWidth(true)
	doubleColorPickerContainer:SetLayout("EPHorizontalLayout")
	doubleColorPickerContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local colorPickerOne = AceGUI:Create("EPColorPicker")
	colorPickerOne:SetFullHeight(true)
	colorPickerOne:SetRelativeWidth(0.5)
	colorPickerOne:SetLabelText(option.labels[1] .. ":", spacingBetweenLabelAndWidget)
	colorPickerOne:SetColor(option.get[1]())

	local colorPickerTwo = AceGUI:Create("EPColorPicker")
	colorPickerTwo:SetFullHeight(true)
	colorPickerTwo:SetRelativeWidth(0.5)
	colorPickerTwo:SetLabelText(option.labels[2] .. ":", spacingBetweenLabelAndWidget)
	colorPickerTwo:SetColor(option.get[2]())

	if option.enabled then
		tinsert(self.refreshMap, { widget = colorPickerOne, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = colorPickerTwo, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			colorPickerOne:SetColor(option.get[1]())
			colorPickerTwo:SetColor(option.get[2]())
		end)
	end
	colorPickerOne:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)
	colorPickerTwo:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)

	colorPickerOne:SetCallback("OnEnter", function()
		ShowTooltip(colorPickerOne.frame, option.labels[1], option.descriptions[1])
	end)
	colorPickerTwo:SetCallback("OnEnter", function()
		ShowTooltip(colorPickerTwo.frame, option.labels[2], option.descriptions[2])
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
---@param index integer
---@param label EPLabel
---@return EPContainer
local function CreateDoubleCheckBox(self, option, index, label)
	local doubleCheckBoxContainer = AceGUI:Create("EPContainer")
	doubleCheckBoxContainer:SetFullWidth(true)
	doubleCheckBoxContainer:SetLayout("EPHorizontalLayout")
	doubleCheckBoxContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local checkBoxOne = AceGUI:Create("EPCheckBox")
	checkBoxOne:SetFullHeight(true)
	checkBoxOne:SetRelativeWidth(0.5)
	checkBoxOne:SetText(option.labels[1])
	checkBoxOne:SetChecked(option.get[1]())

	local checkBoxTwo = AceGUI:Create("EPCheckBox")
	checkBoxTwo:SetFullHeight(true)
	checkBoxTwo:SetRelativeWidth(0.5)
	checkBoxTwo:SetText(option.labels[2])
	checkBoxTwo:SetChecked(option.get[2]())

	if option.enabled then
		tinsert(self.refreshMap, { widget = checkBoxOne, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = checkBoxTwo, enabled = option.enabled })
		tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			checkBoxOne:SetChecked(option.get[1]())
			checkBoxTwo:SetChecked(option.get[2]())
		end)
	end
	checkBoxOne:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)
	checkBoxTwo:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)

	checkBoxOne:SetCallback("OnEnter", function()
		ShowTooltip(checkBoxOne.frame, option.labels[1], option.descriptions[1])
	end)
	checkBoxTwo:SetCallback("OnEnter", function()
		ShowTooltip(checkBoxTwo.frame, option.labels[2], option.descriptions[2])
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
---@param index integer
---@return EPContainer
local function CreateCheckBoxWithDropdown(self, option, index)
	local checkBoxWithDropdownContainer = AceGUI:Create("EPContainer")
	checkBoxWithDropdownContainer:SetFullWidth(true)
	checkBoxWithDropdownContainer:SetLayout("EPHorizontalLayout")
	checkBoxWithDropdownContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetFullHeight(true)
	checkBox:SetRelativeWidth(0.5)
	checkBox:SetText(option.label)
	checkBox:SetChecked(option.get[1]())

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetRelativeWidth(0.5)
	local values = type(option.values) == "table" and option.values or option.values() --[[@as table<integer, DropdownItemData>]]
	dropdown:AddItems(values, "EPDropdownItemToggle")
	dropdown:SetValue(option.get[2]())

	if option.enabled then
		tinsert(self.refreshMap, { widget = checkBox, enabled = option.enabled[1] })
		tinsert(self.refreshMap, { widget = dropdown, enabled = option.enabled[2] })
	end
	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			checkBox:SetChecked(option.get[1]())
			dropdown:SetValue(option.get[2]())
		end)
	end
	checkBox:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[1](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)
	dropdown:SetCallback("OnValueChanged", function(_, _, ...)
		option.set[2](...)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)

	checkBox:SetCallback("OnEnter", function()
		ShowTooltip(checkBox.frame, option.labels[1], option.descriptions[1])
	end)
	dropdown:SetCallback("OnEnter", function()
		ShowTooltip(dropdown.frame, option.labels[2], option.descriptions[2])
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
	checkBoxBesideButtonContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local widget = AceGUI:Create("EPCheckBox")
	widget:SetRelativeWidth(0.5)
	widget:SetText(option.label)

	local button = AceGUI:Create("EPButton")
	button:SetText(option.buttonText)
	button:SetRelativeWidth(0.5)
	button:SetCallback("Clicked", option.buttonCallback)
	if option.buttonEnabled then
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
	button:SetText(option.label)
	button:SetWidthFromText()

	if option.enabled then
		tinsert(self.refreshMap, { widget = button, enabled = option.enabled })
	end
	button:SetCallback("Clicked", function()
		if option.buttonCallback then
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
---@param index integer
---@return EPContainer
local function CreateDropdownBesideButton(self, option, index)
	local container = AceGUI:Create("EPContainer")
	container:SetFullWidth(true)
	container:SetLayout("EPHorizontalLayout")
	container:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetRelativeWidth(0.7)
	if type(option.values) == "function" then
		dropdown:AddItems(option.values(), "EPDropdownItemToggle")
		if option.updateIndices then
			UpdateUpdateIndices(self.updateIndices, option, index, function()
				dropdown:Clear()
				dropdown:AddItems(option.values(), "EPDropdownItemToggle")
			end)
		end
	elseif type(option.values) == "table" then
		dropdown:AddItems(option.values --[[@as table]], "EPDropdownItemToggle")
	end
	dropdown:SetValue(option.get())

	local button = AceGUI:Create("EPButton")
	button:SetText(option.buttonText)
	button:SetRelativeWidth(0.3)

	if option.updateIndices then
		UpdateUpdateIndices(self.updateIndices, option, index, function()
			dropdown:SetValue(option.get())
		end)
	end

	dropdown:SetCallback("OnValueChanged", function(_, _, value)
		option.set(value)
		RefreshEnabledStates(self.refreshMap)
		if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
			Update(self.updateIndices[option.category][index])
		end
	end)

	if option.confirm then
		button:SetCallback("Clicked", function()
			if not messageBox then
				messageBox = AceGUI:Create("EPMessageBox")
				messageBox.frame:SetParent(UIParent)
				messageBox.frame:SetFrameLevel(110)
				messageBox:SetTitle(L["Confirmation"])
				if type(option.confirmText) == "string" then
					messageBox:SetText(option.confirmText --[[@as string]])
				else
					messageBox:SetText(option.confirmText(false))
				end
				messageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				messageBox:SetPoint("TOP", UIParent, "TOP", 0, -messageBox.frame:GetBottom())
				messageBox:SetCallback("Accepted", function()
					option.buttonCallback()
					messageBox:Release()
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
						Update(self.updateIndices[option.category][index])
					end
				end)
				messageBox:SetCallback("OnRelease", function()
					messageBox = nil
				end)
			end
		end)
	else
		button:SetCallback("Clicked", option.buttonCallback)
	end

	if option.enabled then
		tinsert(self.refreshMap, { widget = dropdown, enabled = option.enabled })
	end
	if option.buttonEnabled then
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
---@param option EPSettingOption
---@param index integer
---@return EPContainer
local function CreateOptionWidget(self, option, index)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPHorizontalLayout")
	container:SetSpacing(spacingBetweenLabelAndWidget, 0)
	container:SetFullWidth(true)

	if option.indent then
		container:SetPadding(indentWidth, 0, 0, 0)
	end

	local containerChildren = {}
	local widget, setWidgetValue, callbackName, addWidget = nil, nil, nil, true
	local label = nil
	if option.type == "checkBox" then
		widget = AceGUI:Create("EPCheckBox")
		widget:SetFullWidth(true)
		widget:SetText(option.label)
		setWidgetValue = widget.SetChecked
		callbackName = "OnValueChanged"
	elseif option.type == "checkBoxBesideButton" then
		local checkBoxBesideButtonContainer
		checkBoxBesideButtonContainer, widget, setWidgetValue, callbackName = CreateCheckBoxBesideButton(self, option)
		tinsert(containerChildren, checkBoxBesideButtonContainer)
		addWidget = false
	elseif option.type == "checkBoxWithDropdown" then
		tinsert(containerChildren, CreateCheckBoxWithDropdown(self, option, index))
	elseif option.type == "centeredButton" then
		tinsert(containerChildren, CreateCenteredButton(self, option))
	else
		label = AceGUI:Create("EPLabel")
		label:SetText(option.label .. ":", 0)
		label:SetFontSize(optionLabelFontSize)
		label:SetFrameWidthFromText()
		label:SetFullHeight(true)
		label.text:SetTextColor(unpack(labelTextColor))
		tinsert(containerChildren, label)

		if option.type == "dropdown" then
			widget = AceGUI:Create("EPDropdown")
			widget:SetFullWidth(true)
			if type(option.values) == "function" then
				widget:AddItems(option.values(), "EPDropdownItemToggle")
				if option.updateIndices then
					UpdateUpdateIndices(self.updateIndices, option, index, function()
						widget:Clear()
						widget:AddItems(option.values(), "EPDropdownItemToggle")
					end)
				end
			elseif type(option.values) == "table" then
				widget:AddItems(option.values --[[@as table]], "EPDropdownItemToggle")
			end
			setWidgetValue = widget.SetValue
			callbackName = "OnValueChanged"
		elseif option.type == "lineEdit" then
			widget = AceGUI:Create("EPLineEdit")
			widget:SetFullWidth(true)
			setWidgetValue = widget.SetText
			callbackName = "OnTextSubmitted"
		elseif option.type == "colorPicker" then
			widget = AceGUI:Create("EPColorPicker")
			widget:SetFullWidth(true)
			setWidgetValue = widget.SetColor
			callbackName = "OnValueChanged"
		elseif option.type == "doubleColorPicker" then
			tinsert(containerChildren, CreateDoubleColorPicker(self, option, index, label))
		elseif option.type == "doubleCheckBox" then
			tinsert(containerChildren, CreateDoubleCheckBox(self, option, index, label))
		elseif option.type == "radioButtonGroup" then
			tinsert(containerChildren, CreateRadioButtonGroup(self, option, index, label))
		elseif option.type == "doubleLineEdit" then
			tinsert(containerChildren, CreateDoubleLineEdit(self, option, index, label))
		elseif option.type == "frameChooser" then
			tinsert(containerChildren, CreateFrameChooser(self, option, index, label))
		elseif option.type == "dropdownBesideButton" then
			tinsert(containerChildren, CreateDropdownBesideButton(self, option, index))
		end
	end

	if widget and callbackName then
		if setWidgetValue then
			setWidgetValue(widget, option.get())
		end
		if option.enabled then
			tinsert(self.refreshMap, { widget = widget, enabled = option.enabled })
			if label then
				tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
			end
		end
		if option.updateIndices then
			if setWidgetValue then
				UpdateUpdateIndices(self.updateIndices, option, index, function()
					setWidgetValue(widget, option.get())
				end)
			end
		end
		if setWidgetValue then
			widget:SetCallback(callbackName, function(_, _, ...)
				if option.validate then
					local valid, valueToRevertTo = option.validate(...)
					if not valid and valueToRevertTo then
						setWidgetValue(widget, valueToRevertTo)
						option.set(valueToRevertTo)
					else
						option.set(...)
					end
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
						Update(self.updateIndices[option.category][index])
					end
				elseif option.confirm then
					if not messageBox then
						local value1, value2, value3, value4 = ...
						messageBox = AceGUI:Create("EPMessageBox")
						messageBox.frame:SetParent(UIParent)
						messageBox.frame:SetFrameLevel(110)
						messageBox:SetTitle(L["Confirmation"])
						if type(option.confirmText) == "string" then
							messageBox:SetText(option.confirmText --[[@as string]])
						else
							messageBox:SetText(option.confirmText(value1))
						end
						messageBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						messageBox:SetPoint("TOP", UIParent, "TOP", 0, -messageBox.frame:GetBottom())
						messageBox:SetCallback("Accepted", function()
							option.set(value1, value2, value3, value4)
							RefreshEnabledStates(self.refreshMap)
							if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
								Update(self.updateIndices[option.category][index])
							end
						end)
						messageBox:SetCallback("OnRelease", function()
							messageBox = nil
						end)
					end
				else
					option.set(...)
					RefreshEnabledStates(self.refreshMap)
					if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
						Update(self.updateIndices[option.category][index])
					end
				end
			end)
		else
			widget:SetCallback(callbackName, function(_, _, ...)
				if option.validate then
					local valid, valueToRevertTo = option.validate(...)
					if not valid and valueToRevertTo then
						option.set(valueToRevertTo)
					else
						option.set(...)
					end
				else
					option.set(...)
				end
				RefreshEnabledStates(self.refreshMap)
				if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
					Update(self.updateIndices[option.category][index])
				end
			end)
		end
		widget:SetCallback("OnEnter", function()
			ShowTooltip(widget.frame, option.label, option.description)
		end)
		widget:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
		if addWidget then
			tinsert(containerChildren, widget)
		end
	end

	container:AddChildren(unpack(containerChildren))
	return container
end

---@param self EPOptions
---@param tab string
---@return EPContainer|nil
local function CreateUncategorizedOptionWidgets(self, tab)
	local uncategorizedContainerChildren = {}
	local labels = {}
	local maxLabelWidth = 0

	for index, option in ipairs(self.optionTabs[tab]) do
		if not option.category and not option.uncategorizedBottom then
			if option.type == "horizontalLine" then
				local line = AceGUI:Create("EPSpacer")
				line.frame:SetBackdrop(lineBackdrop)
				line.frame:SetBackdropColor(unpack(backdropBorderColor))
				line:SetFullWidth(true)
				line:SetHeight(2 + spacingBetweenOptions)
				tinsert(uncategorizedContainerChildren, line)
			else
				local container = CreateOptionWidget(self, option, index)
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
		uncategorizedContainer:SetSpacing(0, spacingBetweenOptions)
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
	local activeContainerChildren = {}

	local uncategorizedContainer = CreateUncategorizedOptionWidgets(self, tab)
	if uncategorizedContainer then
		tinsert(activeContainerChildren, uncategorizedContainer)
		local categorySpacer = AceGUI:Create("EPSpacer")
		categorySpacer:SetHeight(spacingBetweenCategories)
		tinsert(activeContainerChildren, categorySpacer)
	end

	local categories = self.tabCategories[tab]
	if categories then
		for categoryIndex, category in ipairs(categories) do
			local categoryLabel = AceGUI:Create("EPLabel")
			categoryLabel:SetText(category, 0)
			categoryLabel:SetFontSize(categoryFontSize)
			categoryLabel:SetFullWidth(true)
			categoryLabel:SetFrameHeightFromText()
			categoryLabel.text:SetTextColor(unpack(categoryTextColor))
			tinsert(activeContainerChildren, categoryLabel)

			local categoryContainer = AceGUI:Create("EPContainer")
			categoryContainer:SetLayout("EPVerticalLayout")
			categoryContainer:SetSpacing(0, spacingBetweenOptions)
			categoryContainer:SetFullWidth(true)
			categoryContainer:SetPadding(unpack(categoryPadding))
			categoryContainer:SetBackdrop(groupBoxBackdrop, { 0, 0, 0, 0 }, groupBoxBorderColor)

			local categoryContainerChildren = {}
			local labels = {}
			local maxLabelWidth = 0

			for index, option in ipairs(self.optionTabs[tab]) do
				if option.category == category then
					if option.type == "horizontalLine" then
						local line = AceGUI:Create("EPSpacer")
						line.frame:SetBackdrop(lineBackdrop)
						line.frame:SetBackdropColor(unpack(backdropBorderColor))
						line:SetFullWidth(true)
						line:SetHeight(2 + spacingBetweenOptions)
						tinsert(categoryContainerChildren, line)
					else
						local container = CreateOptionWidget(self, option, index)
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
				categorySpacer:SetHeight(spacingBetweenCategories)
				tinsert(activeContainerChildren, categorySpacer)
			end
		end
	end

	for index, option in ipairs(self.optionTabs[tab]) do
		if option.uncategorizedBottom and not option.category then
			local categorySpacer = AceGUI:Create("EPSpacer")
			categorySpacer:SetHeight(spacingBetweenCategories)
			tinsert(activeContainerChildren, categorySpacer)
			local container = CreateOptionWidget(self, option, index)
			tinsert(activeContainerChildren, container)
		end
	end

	self.activeContainer:AddChildren(unpack(activeContainerChildren))
	RefreshEnabledStates(self.refreshMap)
	self:Resize()
	self.scrollFrame:UpdateThumbPositionAndSize()
end

---@alias EPSettingOptionType
---| "dropdown"
---| "radioButtonGroup"
---| "lineEdit"
---| "checkBox"
---| "frameChooser"
---| "doubleLineEdit"
---| "horizontalLine"
---| "checkBoxBesideButton"
---| "colorPicker"
---| "doubleColorPicker"
---| "doubleCheckBox"
---| "checkBoxWithDropdown"
---| "centeredButton"
---| "dropdownBesideButton"

---@alias GetFunction
---| fun(): string|boolean|number,number?,number?,number?

---@alias SetFunction
---| fun(value: string|boolean|number, value2?: string|boolean|number, value3?:number, value4?:number)

---@alias ValidateFunction
---| fun(value: string|number, value2?: string): boolean, string|number?,number?

---@alias EnabledFunction
---| fun(): boolean

---@class FourNumbers
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number

---@class EPSettingOption
---@field label string
---@field labels? string[]
---@field type EPSettingOptionType
---@field get GetFunction|{func1: GetFunction, func2:GetFunction}
---@field set SetFunction|{func1: SetFunction, func2:SetFunction}
---@field description? string
---@field descriptions? [string]
---@field validate? ValidateFunction|{func1: ValidateFunction, func2:ValidateFunction}
---@field category? string
---@field indent? boolean
---@field values? table<integer, string|DropdownItemData>|fun():table<integer, string|DropdownItemData>
---@field enabled? EnabledFunction|{func1: EnabledFunction, func2: EnabledFunction}
---@field updateIndices? table<integer, integer>
---@field buttonText? string
---@field buttonDescription? string
---@field buttonEnabled? EnabledFunction
---@field buttonCallback? fun()
---@field uncategorizedBottom? boolean
---@field confirm? boolean
---@field confirmText? string|fun(arg: string|boolean|number):string

---@class EPOptions : AceGUIWidget
---@field type string
---@field count number
---@field frame Frame|table
---@field windowBar Frame|table
---@field closeButton EPButton
---@field tabTitleContainer EPContainer
---@field activeContainer EPContainer
---@field activeTab string
---@field optionTabs table<string, table<integer, EPSettingOption>>
---@field tabCategories table<string, table<integer, string>>
---@field updateIndices table<string, table<integer, table<integer, fun()>>>
---@field refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@field scrollFrame EPScrollFrame

---@param self EPOptions
local function OnAcquire(self)
	self.activeTab = ""
	self.optionTabs = {}
	self.tabCategories = {}
	self.updateIndices = {}
	self.refreshMap = {}

	self.frame:SetSize(frameWidth, frameHeight)

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Release()
	end)
	self.tabTitleContainer = AceGUI:Create("EPContainer")
	self.tabTitleContainer:SetLayout("EPHorizontalLayout")
	self.tabTitleContainer:SetSpacing(0, 0)
	self.tabTitleContainer:SetAlignment("center")
	self.tabTitleContainer:SetSelfAlignment("center")
	self.tabTitleContainer.frame:SetParent(self.frame)
	self.tabTitleContainer.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -contentFramePadding.y)

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetSize(frameWidth, frameHeight)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", contentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -contentFramePadding.y)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -contentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, contentFramePadding.y)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 0)
	self.activeContainer:SetPadding(unpack(activeContainerPadding))
	self.activeContainer.frame:EnableMouse(true)
	self.scrollFrame:SetScrollChild(self.activeContainer.frame --[[@as Frame]], true, false)

	self.frame:Show()
end

---@param self EPOptions
local function OnRelease(self)
	self.closeButton:Release()
	self.closeButton = nil

	self.tabTitleContainer:Release()
	self.tabTitleContainer = nil

	self.activeContainer.frame:EnableMouse(false)
	self.activeContainer.frame:SetScript("OnMouseWheel", nil)
	self.activeContainer:Release()
	self.activeContainer = nil

	self.scrollFrame:Release()
	self.scrollFrame = nil

	self.optionTabs = nil
	self.activeTab = nil
	self.tabCategories = nil
	self.updateIndices = nil
	self.refreshMap = nil
end

---@param self EPOptions
---@param tabName string
---@param categories table<integer, string>?
---@param options table<integer, EPSettingOption>
local function AddOptionTab(self, tabName, options, categories)
	self.optionTabs[tabName] = options
	if categories then
		self.tabCategories[tabName] = categories
	end
	local tab = AceGUI:Create("EPButton")
	tab:SetIsToggleable(true)
	tab:SetText(tabName)
	tab:SetWidthFromText()
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
local function SetCurrentTab(self, tab)
	self.activeTab = ""
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
	local tableTitleContainerHeight = self.tabTitleContainer.frame:GetHeight()
	local containerHeight = self.activeContainer.frame:GetHeight()
	local scrollAreaHeight = min(max(containerHeight, minScrollFrameHeight), maxScrollFrameHeight)
	local paddingHeight = contentFramePadding.y * 3
	local height = windowBarHeight + tableTitleContainerHeight + scrollAreaHeight + paddingHeight

	local tabWidth = self.tabTitleContainer.frame:GetWidth()
	local activeWidth = self.activeContainer.frame:GetWidth() + 4
	if self.scrollFrame.scrollBar:IsShown() then
		activeWidth = activeWidth + self.scrollFrame.scrollBarScrollFramePadding + self.scrollFrame.scrollBar:GetWidth()
	end
	local width = contentFramePadding.x * 2 + max(tabWidth, activeWidth)

	self.frame:SetSize(width, height)
	self.activeContainer:DoLayout()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
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

	---@class EPOptions
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		windowBar = windowBar,
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
