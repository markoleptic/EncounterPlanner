local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPExpanderHeader"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local k = {
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
end

---@param self EPExpanderHeader
local function OnRelease(self)
	self.frame:ClearBackdrop()
	if self.labelAndCheckBox then
		self.labelAndCheckBox:Release()
	end
	if self.label then
		self.label:Release()
	end
	self.labelAndCheckBox = nil
	self.label = nil
	self.button:ClearAllPoints()
	self:SetExpanded(false)
end

---@param self EPExpanderHeader
---@param text string
---@param showCheckBox boolean
---@param fontSize? integer
local function SetText(self, text, showCheckBox, fontSize)
	if showCheckBox then
		local labelAndCheckBox = AceGUI:Create("EPCheckBox")
		labelAndCheckBox.frame:SetParent(self.frame)
		labelAndCheckBox:SetChecked(false)
		labelAndCheckBox:SetCallback("OnValueChanged", function(_, _, checked)
			self:Fire("OnValueChanged", checked)
		end)
		if fontSize then
			labelAndCheckBox.label:SetFontSize(fontSize)
		end
		labelAndCheckBox:SetText(text)
		labelAndCheckBox:SetFullWidth(true)
		labelAndCheckBox:SetFrameHeightFromText()
		labelAndCheckBox:SetFrameWidthFromText()
		local height = labelAndCheckBox.frame:GetHeight()
		self.frame:SetHeight(height)
		labelAndCheckBox.frame:SetPoint("LEFT", self.frame, "LEFT")
		self.button:SetSize(height, height)
		self.button:SetPoint("LEFT", labelAndCheckBox.frame, "RIGHT")
		self.labelAndCheckBox = labelAndCheckBox
	else
		local label = AceGUI:Create("EPLabel")
		label.frame:SetParent(self.frame)
		label:SetCallback("OnValueChanged", function(_, _, checked)
			self:Fire("OnValueChanged", checked)
		end)
		if fontSize then
			label:SetFontSize(fontSize)
		end
		label:SetText(text)
		label:SetFullWidth(true)
		label:SetFrameHeightFromText()
		label:SetFrameWidthFromText()
		local height = label.frame:GetHeight()
		self.frame:SetHeight(height)
		label.frame:SetPoint("LEFT", self.frame, "LEFT")
		self.button:SetSize(height, height)
		self.button:SetPoint("LEFT", label.frame, "RIGHT")
		self.label = label
	end
end

---@param self EPExpanderHeader
---@param checked boolean
local function SetChecked(self, checked)
	if self.labelAndCheckBox.type == "EPCheckBox" then
		self.labelAndCheckBox:SetChecked(checked)
	end
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

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
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

	---@class EPExpanderHeader : AceGUIWidget
	---@field labelAndCheckBox EPCheckBox
	---@field label EPLabel
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		SetChecked = SetChecked,
		SetExpanded = SetExpanded,
		frame = frame,
		type = Type,
		count = count,
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
