local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

---@class Constants
local constants = Private.constants
local L = Private.L

local Type = "EPNewPlanDialog"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultHeight = 400
local defaultWidth = 400
local dropdownWidth = 200
local dropdownHeight = 26
local dropdownHorizontalPadding = 4
local defaultFontSize = 14

---@class EPNewPlanDialog : AceGUIWidget
---@field frame table|Frame|BackdropTemplate
---@field type string
---@field bossDropdown EPDropdown
---@field planNameLineEdit EPLineEdit
---@field createButton EPButton
---@field cancelButton EPButton

---@param self EPNewPlanDialog
local function OnAcquire(self)
	self.frame:Show()

	self.bossDropdown = AceGUI:Create("EPDropdown")
	self.bossDropdown:SetWidth(dropdownWidth)
	self.bossDropdown:SetTextFontSize(defaultFontSize)
	self.bossDropdown:SetItemTextFontSize(defaultFontSize)
	self.bossDropdown:SetTextHorizontalPadding(dropdownHorizontalPadding)
	self.bossDropdown:SetItemHorizontalPadding(dropdownHorizontalPadding)
	self.bossDropdown:SetHeight(dropdownHeight)
	self.bossDropdown:SetDropdownItemHeight(dropdownHeight)

	self.planNameLineEdit = AceGUI:Create("EPLineEdit")
	self.planNameLineEdit:SetMaxLetters(24)
	local font, _, flags = self.planNameLineEdit.editBox:GetFont()
	if font then
		self.planNameLineEdit:SetFont(font, defaultFontSize, flags)
	end
	self.planNameLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
		self:Fire("ValidatePlanName", value)
	end)

	self.createButton = AceGUI:Create("EPButton")
	self.createButton:SetText(L["Create"])
	self.createButton:SetWidthFromText()

	self.cancelButton = AceGUI:Create("EPButton")
	self.cancelButton:SetText(L["Cancel"])
	self.cancelButton:SetWidthFromText()
end

---@param self EPNewPlanDialog
local function OnRelease(self)
	self.bossDropdown:Release()
	self.bossDropdown = nil

	self.planNameLineEdit:Release()
	self.planNameLineEdit = nil

	self.createButton:Release()
	self.createButton = nil

	self.cancelButton:Release()
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

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultWidth, defaultHeight)

	---@class EPNewPlanDialog
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetBossDropdownItems = SetBossDropdownItems,
		SetPlanNameLineEditText = SetPlanNameLineEditText,
		SetCreateButtonEnabled = SetCreateButtonEnabled,
		frame = frame,
		type = Type,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
