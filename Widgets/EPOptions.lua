local Type = "EPOptions"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local tooltip = EncounterPlanner.tooltip
local ipairs = ipairs
local pairs = pairs
local type = type
local tinsert = tinsert
local unpack = unpack
local IsMouseButtonDown = IsMouseButtonDown
local ResetCursor = ResetCursor
local SetCursor = SetCursor
local GetMouseFoci = GetMouseFoci

local frameWidth = 400
local frameHeight = 400
local windowBarHeight = 28
local contentFramePadding = { x = 10, y = 10 }
local title = "Preferences"
local categoryFontSize = 18
local optionLabelFontSize = 14
local spacingBetweenOptions = 8
local spacingBetweenCategories = 16
local spacingBetweenLabelAndWidget = 8
local indentWidth = 20
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local categoryTextColor = { 1, 0.82, 0, 1 }
local labelTextColor = { 1, 1, 1, 1 }
local scrollBarWidth = 16
local thumbPadding = { x = 2, y = 2 }
local verticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local verticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 }
local minThumbSize = 20
local frameChooserContainerSpacing = { 8, 0 }
local doubleLineEditContainerSpacing = { 8, 0 }
local radioButtonGroupSpacing = { 8, 0 }
local categoryPadding = { 10, 10, 10, 10 }

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

---@param self EPOptions
local function HandleVerticalThumbUpdate(self)
	if not self.verticalThumbIsDragging then
		return
	end

	local currentOffset = self.verticalThumbOffsetWhenThumbClicked
	local currentHeight = self.verticalThumbHeightWhenThumbClicked
	local currentScrollBarHeight = self.verticalScrollBarHeightWhenThumbClicked
	local _, yPosition = GetCursorPosition()
	local newOffset = self.scrollBar:GetTop() - (yPosition / UIParent:GetEffectiveScale()) - currentOffset

	local minAllowedOffset = thumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - thumbPadding.y
	newOffset = max(newOffset, minAllowedOffset)
	newOffset = min(newOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local timelineHeight = self.activeContainer.frame:GetHeight()
	local maxScroll = timelineHeight - scrollFrameHeight

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * thumbPadding.y)
	local scrollOffset = ((newOffset - thumbPadding.y) / maxThumbPosition) * maxScroll
	scrollFrame:SetVerticalScroll(max(0, scrollOffset))
end

---@param self EPOptions
local function HandleVerticalThumbMouseDown(self)
	local _, y = GetCursorPosition()
	self.verticalThumbOffsetWhenThumbClicked = self.thumb:GetTop() - (y / UIParent:GetEffectiveScale())
	self.verticalScrollBarHeightWhenThumbClicked = self.scrollBar:GetHeight()
	self.verticalThumbHeightWhenThumbClicked = self.thumb:GetHeight()
	self.verticalThumbIsDragging = true
	self.thumb:SetScript("OnUpdate", function()
		HandleVerticalThumbUpdate(self)
	end)
end

---@param self EPOptions
local function HandleVerticalThumbMouseUp(self)
	self.verticalThumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
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
	local radioButtonGroupChildren = {}
	for _, itemValueAndText in pairs(option.values) do
		local radioButton = AceGUI:Create("EPRadioButton")
		radioButton:SetFullWidth(true)
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
	labelX:SetText("X:")
	labelX:SetRelativeWidth(0.05)
	labelX:SetFullHeight(true)

	local lineEditX = AceGUI:Create("EPLineEdit")
	lineEditX:SetRelativeWidth(0.45)

	local labelY = AceGUI:Create("EPLabel")
	labelY:SetText("Y:")
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
		if not valid and valueToRevertTo then
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
		ShowTooltip(lineEditX.frame, option.label, option.description)
	end)
	lineEditY:SetCallback("OnEnter", function()
		ShowTooltip(lineEditY.frame, option.label, option.description)
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
	else
		label = AceGUI:Create("EPLabel")
		label:SetText(option.label .. ":")
		label:SetFontSize(optionLabelFontSize)
		label:SetFrameWidthFromText()
		label:SetFullHeight(true)
		label.text:SetTextColor(unpack(labelTextColor))
		tinsert(containerChildren, label)

		if option.type == "dropdown" then
			widget = AceGUI:Create("EPDropdown")
			widget:SetFullWidth(true)
			widget:AddItems(option.values, "EPDropdownItemToggle")
			setWidgetValue = widget.SetValue
			callbackName = "OnValueChanged"
		elseif option.type == "radioButtonGroup" then
			tinsert(containerChildren, CreateRadioButtonGroup(self, option, index, label))
		elseif option.type == "lineEdit" then
			widget = AceGUI:Create("EPLineEdit")
			widget:SetFullWidth(true)
			setWidgetValue = widget.SetText
			callbackName = "OnTextSubmitted"
		elseif option.type == "doubleLineEdit" then
			tinsert(containerChildren, CreateDoubleLineEdit(self, option, index, label))
		elseif option.type == "frameChooser" then
			tinsert(containerChildren, CreateFrameChooser(self, option, index, label))
		end
	end

	if widget and setWidgetValue and callbackName then
		setWidgetValue(widget, option.get())
		if option.enabled then
			tinsert(self.refreshMap, { widget = widget, enabled = option.enabled })
			if label then
				tinsert(self.refreshMap, { widget = label, enabled = option.enabled })
			end
		end
		if option.updateIndices then
			UpdateUpdateIndices(self.updateIndices, option, index, function()
				setWidgetValue(widget, option.get())
			end)
		end
		widget:SetCallback(callbackName, function(_, _, value)
			if option.validate then
				local valid, valueToRevertTo = option.validate(value)
				if not valid and valueToRevertTo then
					setWidgetValue(widget, valueToRevertTo)
					option.set(valueToRevertTo)
				else
					option.set(value)
				end
			else
				option.set(value)
			end
			RefreshEnabledStates(self.refreshMap)
			if self.updateIndices[option.category] and self.updateIndices[option.category][index] then
				Update(self.updateIndices[option.category][index])
			end
		end)
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
		if not option.category then
			if option.type == "horizontalLine" then
				local line = AceGUI:Create("EPSpacer")
				line.frame:SetBackdrop(lineBackdrop)
				line.frame:SetBackdropColor(unpack(backdropBorderColor))
				line.frame:SetBackdropBorderColor(unpack(backdropBorderColor))
				line:SetFullWidth(true)
				line:SetHeight(2)
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
	for categoryIndex, category in ipairs(categories) do
		local categoryLabel = AceGUI:Create("EPLabel")
		categoryLabel:SetText(category)
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

	self.activeContainer:AddChildren(unpack(activeContainerChildren))
	RefreshEnabledStates(self.refreshMap)
	self:UpdateVerticalScroll()
end

---@class EPSettingOption
---@field label string
---@field type "dropdown"|"radioButtonGroup"|"lineEdit"|"checkBox"|"frameChooser"|"doubleLineEdit"|"horizontalLine"|"checkBoxBesideButton"
---@field description? string
---@field category? string
---@field indent? boolean
---@field values? table<integer, string|DropdownItemData>
---@field get fun(): string|boolean
---@field set fun(value: string|boolean, value2?: string|boolean)
---@field enabled? fun(): boolean
---@field validate? fun(value: string, value2?: string): boolean, string?
---@field updateIndices? table<integer, integer>
---@field buttonText? string
---@field toggledButtonText? string
---@field buttonEnabled? fun(): boolean
---@field buttonCallback? fun()

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

---@param self EPOptions
local function OnAcquire(self)
	self.activeTab = ""
	self.optionTabs = {}
	self.tabCategories = {}
	self.updateIndices = {}
	self.refreshMap = {}
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-96]])
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

	local halfPaddingX, halfPaddingY = contentFramePadding.x / 2.0, contentFramePadding.y / 2.0

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -halfPaddingY)
	self.scrollBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -contentFramePadding.x, contentFramePadding.y)

	self.thumb:SetPoint("TOP", 0, thumbPadding.y)

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -halfPaddingY)
	self.scrollFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", contentFramePadding.x, contentFramePadding.y)
	self.scrollFrame:SetPoint("RIGHT", self.scrollBar, "LEFT", -halfPaddingX, 0)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 0)
	self.activeContainer.frame:SetParent(self.scrollFrame)
	self.activeContainer.frame:EnableMouse(true)
	self.activeContainer.frame:SetScript("OnMouseWheel", function(_, delta)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local timelineFrameHeight = self.activeContainer.frame:GetHeight()
		local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
		local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()
		local newVerticalScroll = max(min(currentVerticalScroll - (delta * 20), maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		self:UpdateVerticalScroll()
	end)
	self.scrollFrame:SetScrollChild(self.activeContainer.frame --[[@as Frame]])
	self.activeContainer.frame:SetPoint("TOPLEFT", self.scrollFrame)
	self.activeContainer.frame:SetPoint("TOPRIGHT", self.scrollFrame)
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
	self.optionTabs = nil
	self.activeTab = nil
	self.tabCategories = nil
	self.updateIndices = nil
	self.refreshMap = nil
end

---@param self EPOptions
local function UpdateVerticalScroll(self)
	local scrollBarHeight = self.scrollBar:GetHeight()
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local containerHeight = self.activeContainer.frame:GetHeight()
	local verticalScroll = self.scrollFrame:GetVerticalScroll()

	local thumbHeight = (scrollFrameHeight / containerHeight) * (scrollBarHeight - (2 * thumbPadding.y))
	thumbHeight = max(thumbHeight, minThumbSize) -- Minimum size so it's always visible
	thumbHeight = min(thumbHeight, scrollFrameHeight - (2 * thumbPadding.y))
	self.thumb:SetHeight(thumbHeight)

	local maxScroll = containerHeight - scrollFrameHeight
	local maxThumbPosition = scrollBarHeight - thumbHeight - (2 * thumbPadding.y)
	local verticalThumbPosition = 0
	if maxScroll > 0 then
		verticalThumbPosition = (verticalScroll / maxScroll) * maxThumbPosition
		verticalThumbPosition = verticalThumbPosition + thumbPadding.x
	else
		verticalThumbPosition = thumbPadding.y -- If no scrolling is possible, reset the thumb to the start
	end
	self.thumb:SetPoint("TOP", 0, -verticalThumbPosition)

	if verticalScroll > maxScroll then
		self.scrollFrame:SetVerticalScroll(max(0, maxScroll))
	end
end

local function OnHeightSet(self, width)
	self:UpdateVerticalScroll()
end

local function OnWidthSet(self, width) end

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
	self.tabTitleContainer:AddChild(tab)
	tab:SetCallback("Clicked", function(button, _)
		if not button:IsToggled() then
			for _, child in ipairs(self.tabTitleContainer.children) do
				if child:IsToggled() then
					child:Toggle()
				end
			end
			button:Toggle()
			PopulateActiveTab(self, button.button:GetText())
		end
	end)
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
	end)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)

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

	local verticalScrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	verticalScrollBar:SetWidth(scrollBarWidth)
	verticalScrollBar:SetPoint("TOPRIGHT")
	verticalScrollBar:SetPoint("BOTTOMRIGHT")

	local verticalScrollBarBackground =
		verticalScrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(unpack(verticalScrollBackgroundColor))

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, verticalScrollBar)
	verticalThumb:SetPoint("TOP", 0, thumbPadding.y)
	verticalThumb:SetSize(scrollBarWidth - (2 * thumbPadding.x), verticalScrollBar:GetHeight() - 2 * thumbPadding.y)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(unpack(verticalThumbBackgroundColor))

	---@class EPOptions
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		scrollFrame = scrollFrame,
		windowBar = windowBar,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		OnHeightSet = OnHeightSet,
		OnWidthSet = OnWidthSet,
		AddOptionTab = AddOptionTab,
		SetCurrentTab = SetCurrentTab,
		UpdateVerticalScroll = UpdateVerticalScroll,
		UpdateOptions = UpdateOptions,
		frameChooserFrame = frameChooserFrame,
		frameChooserBox = frameChooserBox,
		scrollBar = verticalScrollBar,
		thumb = verticalThumb,
		verticalThumbOffsetWhenThumbClicked = 0,
		verticalScrollBarHeightWhenThumbClicked = 0,
		verticalThumbHeightWhenThumbClicked = 0,
		verticalThumbIsDragging = false,
	}

	verticalThumb:SetScript("OnMouseDown", function()
		HandleVerticalThumbMouseDown(widget)
	end)
	verticalThumb:SetScript("OnMouseUp", function()
		HandleVerticalThumbMouseUp(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
