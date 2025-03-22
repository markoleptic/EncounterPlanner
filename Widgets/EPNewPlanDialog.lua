local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants
local L = Private.L

local Type = "EPNewPlanDialog"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultHeight = 400
local defaultWidth = 400
local dropdownWidth = 200
local dropdownHeight = 26
local dropdownHorizontalPadding = 4
local defaultFontSize = 14
local contentFramePadding = { x = 15, y = 15 }
local otherPadding = { x = 10, y = 10 }
local windowBarHeight = 28
local neutralButtonColor = constants.colors.kNeutralButtonActionColor
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local title = L["Create New Plan"]
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

---@class EPNewPlanDialog : AceGUIWidget
---@field frame table|Frame|BackdropTemplate
---@field type string
---@field bossDropdown EPDropdown
---@field planNameLineEdit EPLineEdit
---@field createButton EPButton
---@field cancelButton EPButton
---@field closeButton EPButton
---@field container EPContainer
---@field buttonContainer EPContainer

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

---@param self EPNewPlanDialog
local function OnAcquire(self)
	self.frame:SetSize(defaultWidth, defaultHeight)

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar --[[@as Frame]])
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)
	self.frame:Show()

	self.container = AceGUI:Create("EPContainer")
	self.container:SetLayout("EPVerticalLayout")
	self.container:SetSpacing(otherPadding.x, otherPadding.y)
	self.container.frame:SetParent(self.frame --[[@as Frame]])
	self.container.frame:EnableMouse(true)
	self.container.frame:SetPoint(
		"TOPLEFT",
		self.windowBar,
		"BOTTOMLEFT",
		contentFramePadding.x,
		-contentFramePadding.y
	)

	local bossContainer = AceGUI:Create("EPContainer")
	bossContainer:SetLayout("EPHorizontalLayout")
	bossContainer:SetFullWidth(true)

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetText(L["Boss"] .. ":")
	bossLabel:SetFrameWidthFromText()

	self.bossDropdown = AceGUI:Create("EPDropdown")
	self.bossDropdown:SetWidth(dropdownWidth)
	self.bossDropdown:SetTextFontSize(defaultFontSize)
	self.bossDropdown:SetItemTextFontSize(defaultFontSize)
	self.bossDropdown:SetTextHorizontalPadding(dropdownHorizontalPadding)
	self.bossDropdown:SetItemHorizontalPadding(dropdownHorizontalPadding)
	self.bossDropdown:SetHeight(dropdownHeight)
	self.bossDropdown:SetDropdownItemHeight(dropdownHeight)
	self.bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("CreateNewPlanName", value)
	end)

	local planNameContainer = AceGUI:Create("EPContainer")
	planNameContainer:SetLayout("EPHorizontalLayout")
	planNameContainer:SetFullWidth(true)

	local planNameLabel = AceGUI:Create("EPLabel")
	planNameLabel:SetText(L["Plan Name:"])
	planNameLabel:SetFrameWidthFromText()

	self.planNameLineEdit = AceGUI:Create("EPLineEdit")
	self.planNameLineEdit:SetMaxLetters(36)
	local font, _, flags = self.planNameLineEdit.editBox:GetFont()
	if font then
		self.planNameLineEdit:SetFont(font, defaultFontSize, flags)
	end
	self.planNameLineEdit:SetCallback("OnTextChanged", function(_, _, value)
		self:Fire("ValidatePlanName", value)
	end)

	local labelWidth = max(planNameLabel.frame:GetWidth(), bossLabel.frame:GetWidth())
	planNameLabel.frame:SetWidth(labelWidth)
	bossLabel.frame:SetWidth(labelWidth)

	bossContainer:AddChildren(bossLabel, self.bossDropdown)
	planNameContainer:AddChildren(planNameLabel, self.planNameLineEdit)
	self.container:AddChildren(bossContainer, planNameContainer)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(otherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame --[[@as Frame]])
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, contentFramePadding.y)

	self.createButton = AceGUI:Create("EPButton")
	self.createButton:SetText(L["Create"])
	self.createButton:SetWidthFromText()
	self.createButton:SetColor(unpack(neutralButtonColor))
	self.createButton:SetCallback("Clicked", function()
		self:Fire("CreateButtonClicked", self.bossDropdown:GetValue(), self.planNameLineEdit:GetText())
	end)

	self.cancelButton = AceGUI:Create("EPButton")
	self.cancelButton:SetText(L["Cancel"])
	self.cancelButton:SetWidthFromText()
	self.cancelButton:SetCallback("Clicked", function()
		self:Fire("CancelButtonClicked")
	end)

	self.buttonContainer:AddChildren(self.createButton, self.cancelButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
end

---@param self EPNewPlanDialog
local function OnRelease(self)
	self.closeButton:Release()
	self.closeButton = nil
	self.container:Release()
	self.container = nil
	self.buttonContainer:Release()
	self.buttonContainer = nil
	self.bossDropdown = nil
	self.planNameLineEdit = nil
	self.createButton = nil
	self.cancelButton = nil
end

---@param self EPNewPlanDialog
---@param items table<integer, string|DropdownItemData>
---@param valueToSelect string|integer
local function SetBossDropdownItems(self, items, valueToSelect)
	self.bossDropdown:AddItems(items, "EPDropdownItemToggle")
	self.bossDropdown:SetValue(valueToSelect)
end

---@param self EPNewPlanDialog
---@param text string
local function SetPlanNameLineEditText(self, text)
	self.planNameLineEdit:SetText(text)
end

---@param self EPNewPlanDialog
---@param enable boolean
local function SetCreateButtonEnabled(self, enable)
	self.createButton:SetEnabled(enable)
end

---@param self EPNewPlanDialog
local function Resize(self)
	local containerHeight = self.container.frame:GetHeight()
	local buttonContainerHeight = self.buttonContainer.frame:GetHeight()
	local paddingHeight = contentFramePadding.y * 3

	local containerWidth = self.container.frame:GetWidth()
	local buttonWidth = self.buttonContainer.frame:GetWidth()

	local width = contentFramePadding.x * 2
	width = width + max(containerWidth, buttonWidth)

	local height = windowBarHeight + buttonContainerHeight + paddingHeight + containerHeight
	self.frame:SetSize(width, height)
	self.container:DoLayout()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultWidth, defaultHeight)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")

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

	---@class EPNewPlanDialog
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetBossDropdownItems = SetBossDropdownItems,
		SetPlanNameLineEditText = SetPlanNameLineEditText,
		SetCreateButtonEnabled = SetCreateButtonEnabled,
		Resize = Resize,
		windowBar = windowBar,
		frame = frame,
		type = Type,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
