local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants
local DifficultyType = Private.classes.DifficultyType

local Type = "EPNewPlanDialog"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local max = math.max
local unpack = unpack

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	BackdropColor = { 0, 0, 0, 0.9 },
	ContentFramePadding = { x = 15, y = 15 },
	DefaultFontSize = 14,
	DefaultHeight = 400,
	DefaultWidth = 400,
	FrameBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	DifficultyDropdownItemData = {
		{ itemValue = DifficultyType.Heroic, text = L["Heroic"] },
		{ itemValue = DifficultyType.Mythic, text = L["Mythic"] },
	},
	DropdownWidth = 200,
	NeutralButtonColor = constants.colors.kNeutralButtonActionColor,
	OtherPadding = { x = 10, y = 10 },
	Title = L["Create New Plan"],
}

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
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	self.planNameManuallyChanged = false

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
	end)
	self.windowBar = windowBar

	self.frame:Show()

	self.container = AceGUI:Create("EPContainer")
	self.container:SetLayout("EPVerticalLayout")
	self.container:SetSpacing(k.OtherPadding.x, k.OtherPadding.y)
	self.container.frame:SetParent(self.frame)
	self.container.frame:EnableMouse(true)
	self.container.frame:SetPoint(
		"TOPLEFT",
		self.windowBar.frame,
		"BOTTOMLEFT",
		k.ContentFramePadding.x,
		-k.ContentFramePadding.y
	)

	local bossContainer = AceGUI:Create("EPContainer")
	bossContainer:SetLayout("EPHorizontalLayout")
	bossContainer:SetFullWidth(true)

	local bossLabel = AceGUI:Create("EPLabel")
	bossLabel:SetText(L["Boss"] .. ":")
	bossLabel:SetFrameWidthFromText()

	self.bossDropdown = AceGUI:Create("EPDropdown")
	self.bossDropdown:SetWidth(k.DropdownWidth)
	self.bossDropdown:SetTextFontSize(k.DefaultFontSize)
	self.bossDropdown:SetItemTextFontSize(k.DefaultFontSize)
	self.bossDropdown:SetMaxVisibleItems(10)
	self.bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("BossChanged", value)
	end)

	local difficultyContainer = AceGUI:Create("EPContainer")
	difficultyContainer:SetLayout("EPHorizontalLayout")
	difficultyContainer:SetFullWidth(true)

	local difficultyLabel = AceGUI:Create("EPLabel")
	difficultyLabel:SetText(L["Difficulty"] .. ":")
	difficultyLabel:SetFrameWidthFromText()

	self.difficultyDropdown = AceGUI:Create("EPDropdown")
	self.difficultyDropdown:SetWidth(k.DropdownWidth)
	self.difficultyDropdown:SetTextFontSize(k.DefaultFontSize)
	self.difficultyDropdown:SetItemTextFontSize(k.DefaultFontSize)
	self.difficultyDropdown:AddItems(k.DifficultyDropdownItemData)

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
		self.planNameLineEdit:SetFont(font, k.DefaultFontSize, flags)
	end
	self.planNameLineEdit:SetCallback("OnTextChanged", function(_, _, value)
		self.planNameManuallyChanged = true
		self:Fire("ValidatePlanName", value)
	end)

	local labelWidth = max(planNameLabel.frame:GetWidth(), bossLabel.frame:GetWidth(), difficultyLabel.frame:GetWidth())
	planNameLabel.frame:SetWidth(labelWidth)
	bossLabel.frame:SetWidth(labelWidth)
	difficultyLabel.frame:SetWidth(labelWidth)

	bossContainer:AddChildren(bossLabel, self.bossDropdown)
	difficultyContainer:AddChildren(difficultyLabel, self.difficultyDropdown)
	planNameContainer:AddChildren(planNameLabel, self.planNameLineEdit)
	self.container:AddChildren(bossContainer, difficultyContainer, planNameContainer)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(k.OtherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.ContentFramePadding.y)

	self.createButton = AceGUI:Create("EPButton")
	self.createButton:SetText(L["Create"])
	self.createButton:SetWidthFromText()
	self.createButton:SetColor(unpack(k.NeutralButtonColor))
	self.createButton:SetCallback("Clicked", function()
		self:Fire(
			"CreateButtonClicked",
			self.bossDropdown:GetValue(),
			self.planNameLineEdit:GetText(),
			self.difficultyDropdown:GetValue()
		)
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
	self.windowBar:Release()
	self.windowBar = nil
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
	self.bossDropdown:AddItems(items)
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
	local paddingHeight = k.ContentFramePadding.y * 3

	local containerWidth = self.container.frame:GetWidth()
	local buttonWidth = self.buttonContainer.frame:GetWidth()

	local width = k.ContentFramePadding.x * 2
	width = width + max(containerWidth, buttonWidth)

	local height = self.windowBar.frame:GetHeight() + buttonContainerHeight + paddingHeight + containerHeight
	self.frame:SetSize(width, height)
	self.container:DoLayout()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")

	---@class EPNewPlanDialog : AceGUIWidget
	---@field bossDropdown EPDropdown
	---@field difficultyDropdown EPDropdown
	---@field planNameLineEdit EPLineEdit
	---@field createButton EPButton
	---@field cancelButton EPButton
	---@field container EPContainer
	---@field buttonContainer EPContainer
	---@field planNameManuallyChanged boolean
	---@field windowBar EPWindowBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetBossDropdownItems = SetBossDropdownItems,
		SetPlanNameLineEditText = SetPlanNameLineEditText,
		SetCreateButtonEnabled = SetCreateButtonEnabled,
		Resize = Resize,
		frame = frame,
		type = Type,
		count = count,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
