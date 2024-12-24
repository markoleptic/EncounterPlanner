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

local frameWidth = 400
local frameHeight = 400
local windowBarHeight = 28
local contentFramePadding = { x = 20, y = 20 }
local title = "Preferences"
local categoryFontSize = 18
local optionLabelFontSize = 14
local horizontalCategoryOffset = 10
local spacingBetweenOptions = 5
local spacingBetweenCategories = 10
local preLineSpacing = 2
local postLineSpacing = 4
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

---@param radioButton EPRadioButton
---@param radioButtonGroup EPContainer
local function handleRadioButtonToggled(radioButton, radioButtonGroup)
	for _, child in ipairs(radioButtonGroup.children) do
		if child ~= radioButton then
			child:SetToggled(false)
		end
	end
end

---@param option EPSettingOption
---@return EPContainer
local function CreateOptionWidget(option)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPVerticalLayout")
	container:SetSpacing(0, 2)
	container:SetFullWidth(true)

	local containerChildren = {}
	if option.type == "checkBox" then
		local checkBox = AceGUI:Create("EPCheckBox")
		checkBox:SetFullWidth(true)
		checkBox:SetText(option.label)
		checkBox:SetChecked(option.get() == true)
		checkBox:SetCallback("OnValueChanged", function(_, _, checked)
			if checked then
				option.set(true)
			else
				option.set(false)
			end
		end)
		checkBox.button:SetCallback("OnEnter", function()
			tooltip:SetOwner(checkBox.frame, "ANCHOR_TOP")
			tooltip:SetText(option.label, 1, 0.82, 0, true)
			if type(option.description) == "string" then
				tooltip:AddLine(option.description, 1, 1, 1, true)
			end
			tooltip:Show()
		end)
		checkBox.button:SetCallback("OnLeave", function()
			tooltip:Hide()
		end)
		tinsert(containerChildren, checkBox)
	else
		local label = AceGUI:Create("EPLabel")
		label:SetText(option.label)
		label:SetFontSize(optionLabelFontSize)
		label:SetFullWidth(true)
		label:SetFrameHeightFromText()
		label.text:SetTextColor(1, 0.82, 0, 1)
		tinsert(containerChildren, label)

		if option.type == "dropdown" then
			local dropdown = AceGUI:Create("EPDropdown")
			dropdown:SetFullWidth(true)
			dropdown:SetCallback("OnValueChanged", function(_, _, value, _)
				local valid, valueToRevertTo = option.validate(value)
				if not valid and valueToRevertTo then
					dropdown:SetValue(valueToRevertTo)
					option.set(valueToRevertTo)
				else
					option.set(value)
				end
			end)
			dropdown:AddItems(option.values, "EPDropdownItemToggle")
			dropdown:SetValue(option.get())
			dropdown:SetCallback("OnLeave", function()
				tooltip:Hide()
			end)
			dropdown:SetCallback("OnEnter", function()
				tooltip:SetOwner(dropdown.frame, "ANCHOR_TOP")
				tooltip:SetText(option.label, 1, 0.82, 0, true)
				if type(option.description) == "string" then
					tooltip:AddLine(option.description, 1, 1, 1, true)
				end
				tooltip:Show()
			end)
			tinsert(containerChildren, dropdown)
		elseif option.type == "radioButtonGroup" then
			local radioButtonGroup = AceGUI:Create("EPContainer")
			radioButtonGroup:SetLayout("EPHorizontalLayout")
			radioButtonGroup:SetSpacing(0, 0)
			local radioButtonGroupChildren = {}
			for _, itemValueAndText in pairs(option.values) do
				local radioButton = AceGUI:Create("EPRadioButton")
				radioButton:SetFullWidth(true)
				radioButton:SetLabelText(itemValueAndText.text)
				radioButton:SetToggled(option.get() == itemValueAndText.itemValue)
				radioButton:GetUserDataTable().key = itemValueAndText.itemValue
				tinsert(radioButtonGroupChildren, radioButton)
			end
			if #radioButtonGroupChildren > 0 then
				radioButtonGroup:AddChildren(unpack(radioButtonGroupChildren))
				tinsert(containerChildren, radioButtonGroup)
			end
			for _, child in ipairs(radioButtonGroup.children) do
				child:SetCallback("Toggled", function(radioButton, _, _)
					handleRadioButtonToggled(radioButton, radioButtonGroup)
					local value = radioButton:GetUserData("key")
					option.set(value)
				end)
				child:SetCallback("OnLeave", function()
					tooltip:Hide()
				end)
				child:SetCallback("OnEnter", function()
					tooltip:SetOwner(radioButtonGroup.frame --[[@as Frame]], "ANCHOR_TOP")
					tooltip:SetText(option.label, 1, 0.82, 0, true)
					if type(option.description) == "string" then
						tooltip:AddLine(option.description, 1, 1, 1, true)
					end
					tooltip:Show()
				end)
			end
		elseif option.type == "lineEdit" then
			local lineEdit = AceGUI:Create("EPLineEdit")
			lineEdit:SetFullWidth(true)
			lineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
				local valid, valueToRevertTo = option.validate(value)
				if not valid and valueToRevertTo then
					lineEdit:SetText(valueToRevertTo)
					option.set(valueToRevertTo)
				else
					option.set(value)
				end
			end)
			lineEdit:SetText(option.get())
			lineEdit:SetCallback("OnLeave", function()
				tooltip:Hide()
			end)
			lineEdit:SetCallback("OnEnter", function()
				tooltip:SetOwner(lineEdit.frame, "ANCHOR_TOP")
				tooltip:SetText(option.label, 1, 0.82, 0, true)
				if type(option.description) == "string" then
					tooltip:AddLine(option.description, 1, 1, 1, true)
				end
				tooltip:Show()
			end)
			tinsert(containerChildren, lineEdit)
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

	if self.tabCategories[tab] then
		for index, option in ipairs(self.optionTabs[tab]) do
			if not option.category then
				tinsert(activeContainerChildren, CreateOptionWidget(option))
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
			label.text:SetTextColor(1, 0.82, 0, 1)
			tinsert(activeContainerChildren, label)

			local preLineSpacer = AceGUI:Create("EPSpacer")
			preLineSpacer:SetHeight(preLineSpacing)
			preLineSpacer:SetFullWidth(true)
			tinsert(activeContainerChildren, preLineSpacer)

			local line = AceGUI:Create("EPSpacer")
			line.frame:SetBackdrop({
				bgFile = "Interface\\BUTTONS\\White8x8",
				edgeFile = nil,
				tile = false,
				tileSize = 0,
				edgeSize = 0,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			line.frame:SetBackdropColor(0.25, 0.25, 0.25, 1)
			line:SetHeight(2)
			line:SetFullWidth(true)
			tinsert(activeContainerChildren, line)

			local postLineSpacer = AceGUI:Create("EPSpacer")
			postLineSpacer:SetHeight(postLineSpacing)
			postLineSpacer:SetFullWidth(true)
			tinsert(activeContainerChildren, postLineSpacer)

			local categoryContainerWrapper = AceGUI:Create("EPContainer")
			categoryContainerWrapper:SetLayout("EPHorizontalLayout")
			categoryContainerWrapper:SetSpacing(0, 0)
			categoryContainerWrapper:SetFullWidth(true)
			local leftOffsetSpacer = AceGUI:Create("EPSpacer")
			leftOffsetSpacer:SetWidth(horizontalCategoryOffset)
			categoryContainerWrapper:AddChild(leftOffsetSpacer)

			local categoryContainer = AceGUI:Create("EPContainer")
			categoryContainer:SetLayout("EPVerticalLayout")
			categoryContainer:SetSpacing(0, spacingBetweenOptions)
			categoryContainer:SetFullWidth(true)
			local categoryContainerChildren = {}
			for _, option in ipairs(self.optionTabs[tab]) do
				if option.category == category then
					tinsert(categoryContainerChildren, CreateOptionWidget(option))
				end
			end

			if #categoryContainerChildren > 0 then
				categoryContainer:AddChildren(unpack(categoryContainerChildren))
				categoryContainerWrapper:AddChild(categoryContainer)
				tinsert(activeContainerChildren, categoryContainerWrapper)
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
			tinsert(activeContainerChildren, CreateOptionWidget(option))
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

	self:DoLayout()
end

---@class EPSettingOption
---@field label string
---@field type "dropdown"|"radioButtonGroup"
---@field description string?
---@field category string?
---@field values table<integer, string|DropdownItemData>
---@field get fun(): string|boolean
---@field set fun(value: string|boolean)
---@field validate fun(value: string): boolean, string?

---@class EPOptions : AceGUIContainer
---@field type string
---@field count number
---@field frame Frame|table
---@field windowBar Frame|table
---@field closeButton EPButton
---@field children table<integer, AceGUIWidget>
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
	self.content.alignment = "center"
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-96]])
	self.closeButton:SetBackdropColor(0, 0, 0, 0.9)
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

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 0)
	self.activeContainer:SetFullWidth(true)
	self:AddChildren(self.tabTitleContainer, self.activeContainer)
end

---@param self EPOptions
local function OnRelease(self)
	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil
	self.optionTabs = nil
	self.activeTab = nil
	self.tabCategories = nil
end

local function OnHeightSet(self, width)
	self.content:SetHeight(width)
	self.content.height = width
end

local function OnWidthSet(self, width)
	self.content:SetWidth(width)
	self.content.width = width
end

---@param self EPOptions
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(width + contentFramePadding.x * 2, height + windowBarHeight + contentFramePadding.y * 2)
	end
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
	tab:SetWidth(150)
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
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 1)
	windowBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
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

	local contentFrameName = Type .. "ContentFrame" .. count
	local contentFrame = CreateFrame("Frame", contentFrameName, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", contentFramePadding.x, -contentFramePadding.y - windowBarHeight)
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentFramePadding.x, contentFramePadding.y)

	---@class EPOptions
	local widget = {
		type = Type,
		count = count,
		frame = frame,
		content = contentFrame,
		windowBar = windowBar,
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		OnHeightSet = OnHeightSet,
		OnWidthSet = OnWidthSet,
		LayoutFinished = LayoutFinished,
		AddOptionTab = AddOptionTab,
		SetCurrentTab = SetCurrentTab,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
