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
local contentFramePadding = { x = 20, y = 20 }
local title = "Preferences"
local categoryFontSize = 18
local optionLabelFontSize = 14
local spacingBetweenOptions = 5
local spacingBetweenCategories = 10
local spacingBetweenLabelAndWidget = 2
local indentWidth = 26
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local categoryTextColor = { 1, 0.82, 0, 1 }
local labelTextColor = { 1, 1, 1, 1 }
local scrollBarWidth = 20
local thumbPadding = { x = 2, y = 2 }
local verticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local verticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 }
local minThumbSize = 20
local frameChooserContainerSpacing = { 5, 0 }
local doubleLineEditContainerSpacing = { 5, 0 }
local radioButtonGroupSpacing = { 5, 0 }
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
local groupBoxBorderColor = { 0.25, 0.25, 0.25, 0.9 }

local isChoosingFrame = false

---@param left number
---@param top number
---@param width number
---@param height number
---@param point "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
---@param rLeft number
---@param rTop number
---@param rWidth number
---@param rhHeight number
---@param rPoint "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
local function calculateNewOffset(left, top, width, height, point, rLeft, rTop, rWidth, rhHeight, rPoint)
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
				StopChoosingFrame(frameChooserFrame, frameChooserBox, "UIParent")
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

local function Refresh(refreshMap)
	for _, tab in pairs(refreshMap) do
		tab.widget:SetEnabled(tab.enabled())
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

---@param option EPSettingOption
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPCheckBox
local function CreateCheckBox(option, refreshMap)
	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetFullWidth(true)
	checkBox:SetText(option.label)
	checkBox:SetChecked(option.get() == true)
	if option.enabled then
		checkBox:SetEnabled(option.enabled())
		tinsert(refreshMap, { widget = checkBox, enabled = option.enabled })
	end
	checkBox:SetCallback("OnValueChanged", function(_, _, checked)
		if checked then
			option.set(true)
		else
			option.set(false)
		end
		Refresh(refreshMap)
	end)
	checkBox.button:SetCallback("OnEnter", function()
		ShowTooltip(checkBox.frame, option.label, option.description)
	end)
	checkBox.button:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	return checkBox
end

---@param option EPSettingOption
---@param frameChooserFrame Frame
---@param frameChooserBox Frame
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPContainer
local function CreateFrameChooser(option, frameChooserFrame, frameChooserBox, refreshMap)
	local frameChooserContainer = AceGUI:Create("EPContainer")
	frameChooserContainer:SetFullWidth(true)
	frameChooserContainer:SetLayout("EPHorizontalLayout")
	frameChooserContainer:SetSpacing(unpack(frameChooserContainerSpacing))

	local label = AceGUI:Create("EPLabel")
	label:SetText(option.label)
	label:SetFontSize(optionLabelFontSize)
	label:SetFrameWidthFromText()
	label:SetFullHeight(true)
	label.text:SetTextColor(unpack(labelTextColor))

	local valueLabel = AceGUI:Create("EPLabel")
	valueLabel:SetText(option.get() --[[@as string]])
	valueLabel:SetFontSize(optionLabelFontSize)
	valueLabel:SetFrameWidthFromText()
	valueLabel:SetFullHeight(true)
	valueLabel.text:SetTextColor(unpack(labelTextColor))

	local button = AceGUI:Create("EPButton")
	button:SetText("Choose")
	button:SetWidthFromText()
	button:SetCallback("Clicked", function()
		if not isChoosingFrame then
			frameChooserFrame:Show()
			StartChoosingFrame(frameChooserFrame, frameChooserBox, function(value)
				option.set(value)
				valueLabel:SetText(value)
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
		button:SetEnabled(option.enabled())
		tinsert(refreshMap, { widget = button, enabled = option.enabled })
	end
	frameChooserContainer:AddChildren(label, valueLabel, button)
	return frameChooserContainer
end

---@param option EPSettingOption
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPDropdown
local function CreateDropdown(option, refreshMap)
	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetFullWidth(true)
	if option.enabled then
		dropdown:SetEnabled(option.enabled())
		tinsert(refreshMap, { widget = dropdown, enabled = option.enabled })
	end
	dropdown:SetCallback("OnValueChanged", function(_, _, value, _)
		local valid, valueToRevertTo = option.validate(value)
		if not valid and valueToRevertTo then
			dropdown:SetValue(valueToRevertTo)
			option.set(valueToRevertTo)
		else
			option.set(value)
		end
		Refresh(refreshMap)
	end)
	dropdown:AddItems(option.values, "EPDropdownItemToggle")
	dropdown:SetValue(option.get())
	dropdown:SetCallback("OnEnter", function()
		ShowTooltip(dropdown.frame, option.label, option.description)
	end)
	dropdown:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	return dropdown
end

---@param option EPSettingOption
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPContainer
local function CreateRadioButtonGroup(option, refreshMap)
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
		if option.enabled then
			radioButton:SetEnabled(option.enabled())
			tinsert(refreshMap, { widget = radioButton, enabled = option.enabled })
		end
		tinsert(radioButtonGroupChildren, radioButton)
	end
	radioButtonGroup:AddChildren(unpack(radioButtonGroupChildren))
	for _, child in ipairs(radioButtonGroup.children) do
		if option.enabled and child.SetEnabled then
			child:SetEnabled(option.enabled())
			tinsert(refreshMap, { widget = child, enabled = option.enabled })
		end
		child:SetCallback("Toggled", function(radioButton, _, _)
			handleRadioButtonToggled(radioButton, radioButtonGroup)
			local value = radioButton:GetUserData("key")
			option.set(value)
			Refresh(refreshMap)
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

---@param option EPSettingOption
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPLineEdit
local function CreateLineEdit(option, refreshMap)
	local lineEdit = AceGUI:Create("EPLineEdit")
	lineEdit:SetFullWidth(true)
	if option.enabled then
		lineEdit:SetEnabled(option.enabled())
		tinsert(refreshMap, { widget = lineEdit, enabled = option.enabled })
	end
	lineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
		local valid, valueToRevertTo = option.validate(value)
		if not valid and valueToRevertTo then
			lineEdit:SetText(valueToRevertTo)
			option.set(valueToRevertTo)
		else
			option.set(value)
		end
		Refresh(refreshMap)
	end)
	lineEdit:SetText(option.get())
	lineEdit:SetCallback("OnLeave", function()
		tooltip:Hide()
	end)
	lineEdit:SetCallback("OnEnter", function()
		ShowTooltip(lineEdit.frame, option.label, option.description)
	end)
	return lineEdit
end

---@param option EPSettingOption
---@param refreshMap table<integer, {widget: AceGUIWidget, enabled: fun(): boolean}>
---@return EPContainer
local function CreateDoubleLineEdit(option, refreshMap)
	local doubleLineEditContainer = AceGUI:Create("EPContainer")
	doubleLineEditContainer:SetFullWidth(true)
	doubleLineEditContainer:SetLayout("EPHorizontalLayout")
	doubleLineEditContainer:SetSpacing(unpack(doubleLineEditContainerSpacing))

	local labelX = AceGUI:Create("EPLabel")
	labelX:SetText("X:")
	labelX:SetFrameWidthFromText()
	labelX:SetFullHeight(true)

	local lineEditX = AceGUI:Create("EPLineEdit")
	lineEditX:SetWidth(100)

	local lineEditY = AceGUI:Create("EPLineEdit")
	lineEditY:SetWidth(100)

	local labelY = AceGUI:Create("EPLabel")
	labelY:SetText("Y:")
	labelY:SetFrameWidthFromText()
	labelY:SetFullHeight(true)

	if option.enabled then
		local result = option.enabled()
		lineEditX:SetEnabled(result)
		lineEditY:SetEnabled(result)
		tinsert(refreshMap, { widget = lineEditX, enabled = option.enabled })
		tinsert(refreshMap, { widget = lineEditY, enabled = option.enabled })
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
		Refresh(refreshMap)
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

---@param option EPSettingOption
---@return EPContainer
local function CreateOptionWidget(option, refreshMap, frameChooserFrame, frameChooserBox)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPVerticalLayout")
	container:SetSpacing(0, spacingBetweenLabelAndWidget)
	container:SetFullWidth(true)

	if option.indent then
		container:SetPadding(indentWidth, 0, 0, 0)
	end

	local containerChildren = {}
	if option.type == "checkBox" then
		tinsert(containerChildren, CreateCheckBox(option, refreshMap))
	elseif option.type == "frameChooser" then
		tinsert(containerChildren, CreateFrameChooser(option, frameChooserFrame, frameChooserBox, refreshMap))
	else
		local label = AceGUI:Create("EPLabel")
		label:SetText(option.label)
		label:SetFontSize(optionLabelFontSize)
		label:SetFullWidth(true)
		label:SetFrameHeightFromText()
		label.text:SetTextColor(unpack(labelTextColor))
		tinsert(containerChildren, label)

		if option.type == "dropdown" then
			tinsert(containerChildren, CreateDropdown(option, refreshMap))
		elseif option.type == "radioButtonGroup" then
			tinsert(containerChildren, CreateRadioButtonGroup(option, refreshMap))
		elseif option.type == "lineEdit" then
			tinsert(containerChildren, CreateLineEdit(option, refreshMap))
		elseif option.type == "doubleLineEdit" then
			tinsert(containerChildren, CreateDoubleLineEdit(option, refreshMap))
		end
	end

	if #containerChildren > 0 then
		container:AddChildren(unpack(containerChildren))
	end
	return container
end

---@param self EPOptions
---@param tab string
local function PopulateActiveTab(self, tab)
	if tab == self.activeTab then
		return
	end
	self.activeTab = tab
	self.activeContainer:ReleaseChildren()
	local activeContainerChildren = {}
	local refreshMap = {}

	if self.tabCategories[tab] then
		for index, option in ipairs(self.optionTabs[tab]) do
			if not option.category then
				tinsert(
					activeContainerChildren,
					CreateOptionWidget(option, refreshMap, self.frameChooserFrame, self.frameChooserBox)
				)
				if index ~= #self.optionTabs[tab] then
					local spacer = AceGUI:Create("EPSpacer")
					spacer:SetHeight(spacingBetweenOptions)
					spacer:SetFullWidth(true)
					tinsert(activeContainerChildren, spacer)
				end
			end
		end
		for categoryIndex, category in ipairs(self.tabCategories[tab]) do
			local label = AceGUI:Create("EPLabel")
			label:SetText(category)
			label:SetFontSize(categoryFontSize)
			label:SetFullWidth(true)
			label:SetFrameHeightFromText()
			label.text:SetTextColor(unpack(categoryTextColor))
			tinsert(activeContainerChildren, label)

			local categoryContainer = AceGUI:Create("EPContainer")
			categoryContainer:SetLayout("EPVerticalLayout")
			categoryContainer:SetSpacing(0, spacingBetweenOptions)
			categoryContainer:SetFullWidth(true)
			categoryContainer:SetPadding(unpack(categoryPadding))
			categoryContainer:SetBackdrop(groupBoxBackdrop, { 0, 0, 0, 0 }, groupBoxBorderColor)
			local categoryContainerChildren = {}
			for _, option in ipairs(self.optionTabs[tab]) do
				if option.category == category then
					tinsert(
						categoryContainerChildren,
						CreateOptionWidget(option, refreshMap, self.frameChooserFrame, self.frameChooserBox)
					)
				end
			end

			if #categoryContainerChildren > 0 then
				categoryContainer:AddChildren(unpack(categoryContainerChildren))
				tinsert(activeContainerChildren, categoryContainer)
			end

			if categoryIndex ~= #self.tabCategories[tab] then
				local spacer = AceGUI:Create("EPSpacer")
				spacer:SetHeight(spacingBetweenCategories)
				spacer:SetFullWidth(true)
				tinsert(activeContainerChildren, spacer)
			end
		end
	else
		for index, option in ipairs(self.optionTabs[tab]) do
			tinsert(
				activeContainerChildren,
				CreateOptionWidget(option, refreshMap, self.frameChooserFrame, self.frameChooserBox)
			)
			if index ~= #self.optionTabs[tab] then
				local spacer = AceGUI:Create("EPSpacer")
				spacer:SetHeight(spacingBetweenOptions)
				spacer:SetFullWidth(true)
				tinsert(activeContainerChildren, spacer)
			end
		end
	end

	if #activeContainerChildren > 0 then
		self.activeContainer:AddChildren(unpack(activeContainerChildren))
	end
	self:UpdateVerticalScroll()
end

---@class EPSettingOption
---@field label string
---@field type "dropdown"|"radioButtonGroup"|"lineEdit"|"checkBox"|"frameChooser"|"doubleLineEdit"
---@field description? string
---@field category? string
---@field indent? boolean
---@field values? table<integer, string|DropdownItemData>
---@field get fun(): string|boolean
---@field set fun(value: string|boolean, value2?: string|boolean)
---@field enabled? fun(): boolean
---@field validate? fun(value: string, value2?: string): boolean, string?

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

---@param self EPOptions
local function OnAcquire(self)
	self.activeTab = ""
	self.optionTabs = {}
	self.tabCategories = {}
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
	self.tabTitleContainer.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -contentFramePadding.y / 2.0)
	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -contentFramePadding.y / 2.0)
	self.scrollBar:SetPoint(
		"BOTTOMRIGHT",
		self.frame,
		"BOTTOMRIGHT",
		-contentFramePadding.x / 2.0,
		contentFramePadding.y / 2.0
	)
	self.thumb:SetPoint("TOP", 0, thumbPadding.y)
	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetPoint("TOP", self.tabTitleContainer.frame, "BOTTOM", 0, -contentFramePadding.y / 2.0)
	self.scrollFrame:SetPoint("LEFT", self.frame, "LEFT", contentFramePadding.x / 2.0, 0)
	self.scrollFrame:SetPoint("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -contentFramePadding.x / 2.0, 0)
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
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", contentFramePadding.x, -contentFramePadding.y - windowBarHeight)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentFramePadding.x * 2, contentFramePadding.y)

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
	verticalScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -contentFramePadding.y - windowBarHeight)
	verticalScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, contentFramePadding.y)

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
