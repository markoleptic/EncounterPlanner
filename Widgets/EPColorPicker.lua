local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPColorPicker"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local ColorPickerFrame = ColorPickerFrame or _G[ColorPickerFrame]
local CreateFrame = CreateFrame
local unpack = unpack

local k = {
	CheckeredTexture = Private.constants.textures.kCheckered,
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 24,
	DefaultFontHeight = 14,
	DefaultColor = { 1.0, 1.0, 1.0, 1.0 },
	DefaultColorSwatchBackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	DefaultCheckersColor = { 0.5, 0.5, 0.5, 0.75 },
	DisabledTextColor = { 0.5, 0.5, 0.5, 1 },
	EnabledTextColor = { 1, 1, 1, 1 },
	DefaultHorizontalPadding = 0,
	FrameBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = false,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
}

---@param self EPColorPicker
local function ColorCallback(self)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = ColorPickerFrame:GetColorAlpha()
	if not self.hasAlpha then
		a = 1
	end
	if r == self.color[0] and g == self.color[1] and b == self.color[2] and a == self.color[3] then
		return
	end
	self:SetColor(r, g, b, a)
	self:Fire("OnValueChanged", r, g, b, a)
end

---@param self EPColorPicker
local function HandleColorSwatchClicked(self)
	ColorPickerFrame:Hide()
	if self.enabled then
		ColorPickerFrame:SetFrameStrata("DIALOG")
		ColorPickerFrame:SetFrameLevel(self.frame:GetFrameLevel() + 10)
		ColorPickerFrame:SetClampedToScreen(true)
		local r, g, b, a = unpack(self.color)
		local info = {
			swatchFunc = function()
				ColorCallback(self)
			end,
			opacityFunc = function()
				ColorCallback(self)
			end,
			cancelFunc = function()
				self:SetColor(r, g, b, a)
				self:Fire("OnValueChanged", r, g, b, a)
			end,
			r = r,
			g = g,
			b = b,
			opacity = a,
			hasOpacity = self.hasAlpha,
		}
		ColorPickerFrame:SetupColorPickerAndShow(info)
	end
	AceGUI:ClearFocus()
end

---@class EPColorPicker : AceGUIWidget
---@field frame Frame
---@field type string
---@field label FontString
---@field enabled boolean
---@field hasAlpha boolean
---@field colorSwatch Frame|table
---@field color [number, number, number, number]

---@param self EPColorPicker
local function OnAcquire(self)
	ColorPickerFrame = ColorPickerFrame or _G["ColorPickerFrame"]
end

---@param self EPColorPicker
local function OnRelease(self)
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	end
	self:SetEnabled(true)
	self:SetHasAlpha(true)
	self:SetLabelText("")
	self:SetColor(unpack(k.DefaultColor))
end

---@param self EPColorPicker
---@param text string
---@param horizontalPadding number?
local function SetLabelText(self, text, horizontalPadding)
	self.label:SetText(text)
	self.label:ClearAllPoints()
	self.colorSwatch:ClearAllPoints()
	if text:len() > 0 then
		self.label:Show()
		self.label:SetWidth(self.label:GetStringWidth())
		self.label:SetPoint("LEFT", self.frame, "LEFT")
		self.colorSwatch:SetPoint("LEFT", self.label, "RIGHT", horizontalPadding or k.DefaultHorizontalPadding, 0)
		self.colorSwatch:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
		self.colorSwatch:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
	else
		self.label:Hide()
		self.colorSwatch:SetPoint("TOPLEFT")
		self.colorSwatch:SetPoint("BOTTOMRIGHT")
	end
end

---@param self EPColorPicker
---@param r number
---@param g number
---@param b number
---@param a number
local function SetColor(self, r, g, b, a)
	self.color = { r, g, b, a }
	self.colorTexture:SetColorTexture(unpack(self.color))
end

---@param self EPColorPicker
---@param hasAlpha boolean
local function SetHasAlpha(self, hasAlpha)
	self.hasAlpha = hasAlpha
end

---@param self EPColorPicker
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	if self.enabled then
		self.colorSwatch:EnableMouse(true)
		self.label:SetTextColor(unpack(k.EnabledTextColor))
		self.colorTexture:SetDesaturated(false)
		self.colorSwatch:SetBackdropColor(unpack(k.DefaultColor))
	else
		self.colorSwatch:EnableMouse(false)
		self.label:SetTextColor(unpack(k.DisabledTextColor))
		self.colorTexture:SetDesaturated(true)
		self.colorSwatch:SetBackdropColor(unpack(k.DisabledTextColor))
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local colorSwatch = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	colorSwatch:SetBackdrop(k.FrameBackdrop)
	colorSwatch:SetBackdropColor(unpack(k.DefaultColor))
	colorSwatch:SetBackdropBorderColor(unpack(k.DefaultColorSwatchBackdropBorderColor))
	colorSwatch:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	colorSwatch:SetPoint("TOPLEFT")
	colorSwatch:SetPoint("BOTTOMRIGHT")
	colorSwatch:EnableMouse(true)
	colorSwatch:SetClipsChildren(true)

	local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
	colorTexture:SetPoint("TOPLEFT", k.FrameBackdrop.edgeSize, -k.FrameBackdrop.edgeSize)
	colorTexture:SetPoint("BOTTOMRIGHT", -k.FrameBackdrop.edgeSize, k.FrameBackdrop.edgeSize)
	colorTexture:SetVertexColor(unpack(k.DefaultColor))

	local checkers = colorSwatch:CreateTexture(nil, "BACKGROUND")
	checkers:SetPoint("LEFT", k.FrameBackdrop.edgeSize)
	checkers:SetPoint("RIGHT", -k.FrameBackdrop.edgeSize)
	checkers:SetPoint("TOP", -k.FrameBackdrop.edgeSize)
	checkers:SetPoint("BOTTOM", k.FrameBackdrop.edgeSize)
	checkers:SetSize(k.DefaultFontHeight - k.FrameBackdrop.edgeSize, k.DefaultFontHeight - k.FrameBackdrop.edgeSize)
	checkers:SetTexture(k.CheckeredTexture, "REPEAT", "REPEAT")
	checkers:SetVertTile(true)
	checkers:SetHorizTile(true)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(unpack(k.DefaultCheckersColor))

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetJustifyH("LEFT")
	label:SetJustifyV("MIDDLE")
	label:SetTextColor(unpack(k.DefaultColor))

	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		label:SetFont(fPath, k.DefaultFontHeight)
	end

	---@class EPColorPicker
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetHasAlpha = SetHasAlpha,
		SetColor = SetColor,
		SetLabelText = SetLabelText,
		frame = frame,
		type = Type,
		label = label,
		checkers = checkers,
		colorSwatch = colorSwatch,
		colorTexture = colorTexture,
		color = k.DefaultColor,
		hasAlpha = true,
	}

	colorSwatch:SetScript("OnEnter", function()
		widget:Fire("OnEnter")
	end)
	colorSwatch:SetScript("OnLeave", function()
		widget:Fire("OnLeave")
	end)
	colorSwatch:SetScript("OnMouseUp", function()
		HandleColorSwatchClicked(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
