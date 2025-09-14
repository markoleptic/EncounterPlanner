local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Constants
local constants = Private.constants

local Type = "EPNewTemplateDialog"
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
	DropdownWidth = 200,
	NeutralButtonColor = constants.colors.kNeutralButtonActionColor,
	OtherPadding = { x = 10, y = 10 },
	Title = L["Create Template"],
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

---@param self EPNewTemplateDialog
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)

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

	local templateNameLabel = AceGUI:Create("EPLabel")
	templateNameLabel:SetText(L["Template Name:"])
	templateNameLabel:SetFrameWidthFromText()

	self.templateNameLineEdit = AceGUI:Create("EPLineEdit")
	self.templateNameLineEdit:SetMaxLetters(36)
	local font, _, flags = self.templateNameLineEdit.editBox:GetFont()
	if font then
		self.templateNameLineEdit:SetFont(font, k.DefaultFontSize, flags)
	end
	self.templateNameLineEdit:SetCallback("OnTextChanged", function(_, _, value)
		self:Fire("ValidateTemplateName", value)
	end)

	local assigneesLabel = AceGUI:Create("EPLabel")
	assigneesLabel:SetText(L["Included assignees"] .. ":")
	assigneesLabel:SetFrameWidthFromText()

	self.assigneeDropdown = AceGUI:Create("EPDropdown")
	self.assigneeDropdown:SetWidth(k.DropdownWidth)
	self.assigneeDropdown:SetTextFontSize(k.DefaultFontSize)
	self.assigneeDropdown:SetItemTextFontSize(k.DefaultFontSize)
	self.assigneeDropdown:SetMaxVisibleItems(10)
	self.assigneeDropdown:SetMultiselect(true)
	self.assigneeDropdown:SetCallback("OnValueChanged", function(_, _, value, selected)
		self:Fire("AssigneeChanged", value, selected)
	end)

	local labelWidth = max(templateNameLabel.frame:GetWidth(), assigneesLabel.frame:GetWidth())
	templateNameLabel.frame:SetWidth(labelWidth)
	assigneesLabel.frame:SetWidth(labelWidth)

	local templateNameContainer = AceGUI:Create("EPContainer")
	templateNameContainer:SetLayout("EPHorizontalLayout")
	templateNameContainer:SetFullWidth(true)
	templateNameContainer:AddChildren(templateNameLabel, self.templateNameLineEdit)

	local assigneesContainer = AceGUI:Create("EPContainer")
	assigneesContainer:SetLayout("EPHorizontalLayout")
	assigneesContainer:SetFullWidth(true)
	assigneesContainer:AddChildren(assigneesLabel, self.assigneeDropdown)

	self.container:AddChildren(templateNameContainer, assigneesContainer)

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
		self:Fire("CreateButtonClicked", self.templateNameLineEdit:GetText())
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

---@param self EPNewTemplateDialog
local function OnRelease(self)
	self.windowBar:Release()
	self.windowBar = nil
	self.container:Release()
	self.container = nil
	self.buttonContainer:Release()
	self.buttonContainer = nil
	self.assigneeDropdown = nil
	self.templateNameLineEdit = nil
	self.createButton = nil
	self.cancelButton = nil
end

---@param self EPNewTemplateDialog
---@param items table<integer, string|DropdownItemData>
local function SetAssigneeDropdownItems(self, items)
	local selectedItems = {}
	for _, data in ipairs(items) do
		selectedItems[data.itemValue] = true
	end
	self.assigneeDropdown:AddItems(items, "EPDropdownItemToggle")
	self.assigneeDropdown:SetSelectedItems(selectedItems)
end

---@param self EPNewTemplateDialog
---@param text string
local function SetTemplateNameLineEditText(self, text)
	self.templateNameLineEdit:SetText(text)
end

---@param self EPNewTemplateDialog
---@param enable boolean
local function SetCreateButtonEnabled(self, enable)
	self.createButton:SetEnabled(enable)
end

---@param self EPNewTemplateDialog
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

	---@class EPNewTemplateDialog : AceGUIWidget
	---@field templateNameLineEdit EPLineEdit
	---@field assigneeDropdown EPDropdown
	---@field createButton EPButton
	---@field cancelButton EPButton
	---@field container EPContainer
	---@field buttonContainer EPContainer
	---@field windowBar EPWindowBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetAssigneeDropdownItems = SetAssigneeDropdownItems,
		SetTemplateNameLineEditText = SetTemplateNameLineEditText,
		SetCreateButtonEnabled = SetCreateButtonEnabled,
		Resize = Resize,
		frame = frame,
		type = Type,
		count = count,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
