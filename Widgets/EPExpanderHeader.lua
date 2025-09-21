local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPExpanderHeader"
local Version = 1

local LSM = LibStub("LibSharedMedia-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local k = {
	DefaultFontHeight = 14,
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 200,
	DisabledTextColor = { 0.33, 0.33, 0.33, 1 },
	DropdownTexture = Private.constants.textures.kDropdown,
	PiOverTwo = math.pi / 2,
}

---@param self EPExpanderHeader
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self.frame:Show()
	self.labelAndCheckBox = AceGUI:Create("EPCheckBox")
	self.labelAndCheckBox.frame:SetParent(self.frame)
	self.labelAndCheckBox:SetChecked(false)
	self.labelAndCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
		self:Fire("OnValueChanged", checked)
	end)
end

---@param self EPExpanderHeader
local function OnRelease(self)
	self.labelAndCheckBox:Release()
	self.labelAndCheckBox = nil
	self.text:SetText("")
	self.text:ClearAllPoints()
	self.button:ClearAllPoints()
	self:SetExpanded(false)
end

---@param self EPExpanderHeader
---@param text string
local function SetText(self, text)
	self.labelAndCheckBox:SetText(text)
	self.labelAndCheckBox:SetFullWidth(true)
	self.labelAndCheckBox:SetFrameHeightFromText()
	self.labelAndCheckBox:SetFrameWidthFromText()
	local height = self.labelAndCheckBox.frame:GetHeight()
	self.frame:SetHeight(height)
	self.labelAndCheckBox.frame:SetPoint("LEFT", self.frame, "LEFT")
	self.button:SetSize(height, height)
	self.button:SetPoint("LEFT", self.labelAndCheckBox.frame, "RIGHT")
end

---@param self EPExpanderHeader
---@param checked boolean
local function SetChecked(self, checked)
	self.labelAndCheckBox:SetChecked(checked)
end

---@param self EPExpanderHeader
---@param expanded boolean
local function SetExpanded(self, expanded)
	self.open = expanded
	if expanded then
		self.button:GetNormalTexture():SetRotation(0)
		self.button:GetPushedTexture():SetRotation(0)
		self.button:GetHighlightTexture():SetRotation(0)
	else
		self.button:GetNormalTexture():SetRotation(k.PiOverTwo)
		self.button:GetPushedTexture():SetRotation(k.PiOverTwo)
		self.button:GetHighlightTexture():SetRotation(k.PiOverTwo)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local button = CreateFrame("Button", Type .. "Button" .. count, frame)
	button:ClearAllPoints()

	button:SetNormalTexture(k.DropdownTexture)
	button:SetPushedTexture(k.DropdownTexture)
	button:SetHighlightTexture(k.DropdownTexture)
	button:SetDisabledTexture(k.DropdownTexture)
	button:GetDisabledTexture():SetVertexColor(unpack(k.DisabledTextColor))

	button:GetNormalTexture():SetRotation(k.PiOverTwo)
	button:GetPushedTexture():SetRotation(k.PiOverTwo)
	button:GetHighlightTexture():SetRotation(k.PiOverTwo)

	local buttonCover = CreateFrame("Button", Type .. "ButtonCover" .. count, frame)
	buttonCover:ClearAllPoints()
	buttonCover:SetPoint("TOPLEFT")
	buttonCover:SetPoint("BOTTOMRIGHT")
	buttonCover:SetFrameLevel(button:GetFrameLevel() + 1)

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.DefaultFontHeight)
	end
	text:SetWordWrap(false)

	---@class EPExpanderHeader : AceGUIWidget
	---@field labelAndCheckBox EPCheckBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		SetChecked = SetChecked,
		SetExpanded = SetExpanded,
		frame = frame,
		type = Type,
		count = count,
		text = text,
		button = button,
		open = false,
	}

	buttonCover:SetScript("OnClick", function()
		widget:SetExpanded(not widget.open)
		widget:Fire("Clicked", widget.open)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
