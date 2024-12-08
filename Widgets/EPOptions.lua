local Type = "EPOptions"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local tooltip = EncounterPlanner.tooltip

local frameWidth = 200
local frameHeight = 200
local windowBarHeight = 28
local dropdownWidth = 250
local contentFramePadding = { x = 10, y = 10 }
local title = "Options"
local categoryFontSize = 16
local optionLabelFontSize = 14
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

---@param option EPSettingOption
---@return EPContainer
local function CreateOptionWidget(option)
	local container = AceGUI:Create("EPContainer")
	container:SetLayout("EPVerticalLayout")
	container:SetSpacing(0, 2)
	container:SetFullWidth(true)
	local label = AceGUI:Create("EPLabel")
	label:SetText(option.label)
	label:SetFontSize(optionLabelFontSize)
	label:SetFullWidth(true)
	label:SetFrameHeightFromText()
	label.text:SetTextColor(1, 0.82, 0, 1)
	local dropdown = AceGUI:Create("EPDropdown")
	dropdown:SetWidth(dropdownWidth)
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
	container:AddChild(label)
	container:AddChild(dropdown)
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

	if self.tabCategories[tab] then
		for categoryIndex, category in ipairs(self.tabCategories[tab]) do
			local label = AceGUI:Create("EPLabel")
			label:SetText(category)
			label:SetFontSize(categoryFontSize)
			label:SetFullWidth(true)
			label:SetFrameHeightFromText()
			label.text:SetTextColor(1, 0.82, 0, 1)
			self.activeContainer:AddChild(label)

			local preLineSpacer = AceGUI:Create("EPSpacer")
			preLineSpacer:SetHeight(preLineSpacing)
			self.activeContainer:AddChild(preLineSpacer)

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
			self.activeContainer:AddChild(line)

			local postLineSpacer = AceGUI:Create("EPSpacer")
			postLineSpacer:SetHeight(postLineSpacing)
			self.activeContainer:AddChild(postLineSpacer)

			local container = AceGUI:Create("EPContainer")
			container:SetLayout("EPVerticalLayout")
			container:SetSpacing(0, spacingBetweenOptions)
			container:SetFullWidth(true)
			for _, option in ipairs(self.optionTabs[tab]) do
				if option.category == category then
					container:AddChild(CreateOptionWidget(option))
				end
			end
			self.activeContainer:AddChild(container)
			if categoryIndex ~= #self.tabCategories[tab] then
				local spacer = AceGUI:Create("EPSpacer")
				spacer:SetHeight(spacingBetweenCategories)
				container:AddChild(spacer)
			end
		end
	else
		for index, option in ipairs(self.optionTabs[tab]) do
			self.activeContainer:AddChild(CreateOptionWidget(option))
			if index ~= #self.optionTabs[tab] then
				local spacer = AceGUI:Create("EPSpacer")
				spacer:SetHeight(spacingBetweenOptions)
				self.activeContainer:AddChild(spacer)
			end
		end
	end

	self.activeContainer:DoLayout()
	self:DoLayout()
end

---@class EPSettingOption
---@field label string
---@field description string?
---@field category string?
---@field values table<integer, string|DropdownItemData>
---@field get fun(): string
---@field set fun(value: string)
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
	self:SetLayout("EPVerticalLayout")
	self.frame:Show()
	self.content.alignment = "center"

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
	self.tabTitleContainer:SetAlignment("center")
	self.tabTitleContainer:SetSpacing(0, 0)
	self:AddChild(self.tabTitleContainer)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 0)
	self.activeContainer:SetWidth(350)
	self:AddChild(self.activeContainer)
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
				child:Toggle()
			end
			PopulateActiveTab(self, button.button:GetText())
		end
	end)
end

---@param self EPOptions
---@param tab string
local function SetCurrentTab(self, tab)
	self.activeTab = ""
	for _, child in ipairs(self.tabTitleContainer.children) do
		if child:IsToggled() then
			child:Toggle()
		elseif child.button:GetText() == tab then
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
		LayoutFinished = LayoutFinished,
		AddOptionTab = AddOptionTab,
		SetCurrentTab = SetCurrentTab,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
