local Type = "EPDiffViewerEntry"
local Version = 1

local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Utilities
local utilities = Private.utilities

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local max = math.max
local unpack = unpack

local PlanDiffType = Private.classes.PlanDiffType

local k = {
	DefaultHeight = 10,
	DefaultWidth = 10,
	LineColor = { 0.25, 0.25, 0.25, 1.0 },
}

---@param self EPDiffViewerEntry
local function OnAcquire(self)
	self.frame:SetParent(UIParent)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local typeLabel = AceGUI:Create("EPMultiLineText")
	typeLabel:SetText("Type")
	typeLabel.frame:SetParent(self.frame)
	typeLabel.frame:SetPoint("LEFT", 0, -1)
	self.typeLabel = typeLabel

	self.typeDividerLine:SetPoint("LEFT", typeLabel.frame, "RIGHT")
	self.typeDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.typeDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")

	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetText("")
	checkBox:SetFrameWidthFromText()
	checkBox.frame:SetParent(self.frame)
	checkBox.frame:SetPoint("RIGHT", 0, -1)
	checkBox:SetChecked(true)
	checkBox:SetCallback("OnValueChanged", function(_, _, checked)
		self:Fire("OnValueChanged", checked)
	end)

	self.checkBox = checkBox

	self.checkBoxDividerLine:SetPoint("RIGHT", checkBox.frame, "LEFT", -6, 0)
	self.checkBoxDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.checkBoxDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")

	self.frame:Show()
end

---@param self EPDiffViewerEntry
local function OnRelease(self)
	self.typeLabel:Release()
	self.typeLabel = nil

	self.checkBox:Release()
	self.checkBox = nil

	self.typeDividerLine:ClearAllPoints()
	self.checkBoxDividerLine:ClearAllPoints()
	self.diffDividerLine:ClearAllPoints()

	self.valueLabel:Release()
	self.valueLabel = nil

	if self.valueLabelTwo then
		self.valueLabelTwo:Release()
	end
	self.valueLabelTwo = nil
end

---@param self EPDiffViewerEntry
---@param genericDiffEntry GenericDiffEntry
---@param TextFunc fun(genericDiffEntry: GenericDiffEntry): string, string?
local function SetGenericDiffEntryData(self, genericDiffEntry, TextFunc)
	if not genericDiffEntry.result or genericDiffEntry.localOnlyChange then
		return
	end

	local diffType = genericDiffEntry.type
	local typeText = ""
	if diffType == PlanDiffType.Insert then
		typeText = L["Added"]
	elseif diffType == PlanDiffType.Delete then
		typeText = L["Removed"]
	elseif diffType == PlanDiffType.Change then
		typeText = L["Changed"]
	elseif diffType == PlanDiffType.Conflict then
		typeText = L["Conflict"]
	end
	self.typeLabel:SetText(typeText)
	if diffType == PlanDiffType.Conflict then
		self.typeLabel:SetTextColor(1, 0, 0, 1)
	end

	local leftText, rightText = TextFunc(genericDiffEntry)
	local oldValueLabel = AceGUI:Create("EPMultiLineText")
	oldValueLabel.frame:SetParent(self.frame)
	oldValueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	oldValueLabel:SetFullHeight(true)
	oldValueLabel:SetText(leftText)
	self.valueLabel = oldValueLabel

	local maxLabelHeight = max(oldValueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if rightText then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		oldValueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local newValueLabel = AceGUI:Create("EPMultiLineText")
		newValueLabel.frame:SetParent(self.frame)
		newValueLabel.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		newValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		newValueLabel:SetFullHeight(true)
		newValueLabel:SetText(rightText)
		self.valueLabelTwo = newValueLabel

		maxLabelHeight = max(maxLabelHeight, newValueLabel.frame:GetHeight())
	else
		oldValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param diffType PlanDiffType
---@param textOne string
---@param textTwo? string
local function SetContentEntryData(self, diffType, textOne, textTwo)
	local typeText = ""
	if diffType == PlanDiffType.Insert then
		typeText = L["Added"]
	elseif diffType == PlanDiffType.Delete then
		typeText = L["Removed"]
	elseif diffType == PlanDiffType.Change then
		typeText = L["Changed"]
	end
	self.typeLabel:SetText(typeText)

	local valueLabel = AceGUI:Create("EPMultiLineText")
	valueLabel.frame:SetParent(self.frame)
	valueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	valueLabel:SetFullHeight(true)
	valueLabel:SetText(textOne)

	self.valueLabel = valueLabel

	local maxLabelHeight = max(valueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if textTwo then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		valueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local valueLabelTwo = AceGUI:Create("EPMultiLineText")
		valueLabelTwo.frame:SetParent(self.frame)
		valueLabelTwo.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		valueLabelTwo.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		valueLabelTwo:SetFullHeight(true)
		valueLabelTwo:SetText(textTwo)
		self.valueLabelTwo = valueLabelTwo

		maxLabelHeight = max(maxLabelHeight, valueLabelTwo.frame:GetHeight())
	else
		valueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param oldText string
---@param newText string
local function SetMetaDataEntryData(self, oldText, newText)
	self.typeLabel:SetText(L["Changed"])

	local oldValueLabel = AceGUI:Create("EPMultiLineText")
	oldValueLabel.frame:SetParent(self.frame)
	oldValueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	oldValueLabel:SetFullHeight(true)
	oldValueLabel:SetText(oldText)
	self.valueLabel = oldValueLabel

	local maxLabelHeight = max(oldValueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
	self.diffDividerLine:Show()

	oldValueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

	local newValueLabel = AceGUI:Create("EPMultiLineText")
	newValueLabel.frame:SetParent(self.frame)
	newValueLabel.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
	newValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
	newValueLabel:SetFullHeight(true)
	newValueLabel:SetText(newText)
	self.valueLabelTwo = newValueLabel

	maxLabelHeight = max(maxLabelHeight, newValueLabel.frame:GetHeight())

	self.frame:SetHeight(maxLabelHeight)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local bottomLine = frame:CreateTexture(nil, "OVERLAY")
	bottomLine:SetColorTexture(unpack(k.LineColor))
	bottomLine:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
	bottomLine:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT")
	bottomLine:SetHeight(2)

	local typeDividerLine = frame:CreateTexture(nil, "OVERLAY")
	typeDividerLine:SetColorTexture(unpack(k.LineColor))
	typeDividerLine:SetWidth(2)

	local checkBoxDividerLine = frame:CreateTexture(nil, "OVERLAY")
	checkBoxDividerLine:SetColorTexture(unpack(k.LineColor))
	checkBoxDividerLine:SetWidth(2)

	local diffDividerLine = frame:CreateTexture(nil, "OVERLAY")
	diffDividerLine:SetColorTexture(unpack(k.LineColor))
	diffDividerLine:SetWidth(2)

	---@class EPDiffViewerEntry : AceGUIWidget
	---@field diffContainer EPMultiLineText
	---@field diffContainerTwo EPMultiLineText
	---@field checkBox EPCheckBox
	---@field typeLabel EPMultiLineText
	---@field valueLabel EPMultiLineText
	---@field valueLabelTwo EPMultiLineText
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetMetaDataEntryData = SetMetaDataEntryData,
		SetContentEntryData = SetContentEntryData,
		SetGenericDiffEntryData = SetGenericDiffEntryData,
		frame = frame,
		type = Type,
		count = count,
		typeDividerLine = typeDividerLine,
		checkBoxDividerLine = checkBoxDividerLine,
		diffDividerLine = diffDividerLine,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
