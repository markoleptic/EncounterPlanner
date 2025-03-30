local Type = "EPColorPicker"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local ColorPickerFrame = ColorPickerFrame or _G[ColorPickerFrame]
local CreateFrame = CreateFrame
local unpack = unpack

local defaultFrameHeight = 24
local defaultFrameWidth = 24
local defaultFontHeight = 14
local defaultColor = { 1.0, 1.0, 1.0, 1.0 }
local defaultColorSwatchBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local defaultCheckersColor = { 0.5, 0.5, 0.5, 0.75 }
local disabledTextColor = { 0.5, 0.5, 0.5, 1 }
local enabledTextColor = { 1, 1, 1, 1 }
local defaultHorizontalPadding = 0
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
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
	self:SetColor(unpack(defaultColor))
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
		self.colorSwatch:SetPoint("LEFT", self.label, "RIGHT", horizontalPadding or defaultHorizontalPadding, 0)
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
		self.label:SetTextColor(unpack(enabledTextColor))
		self.colorTexture:SetDesaturated(false)
		self.colorSwatch:SetBackdropColor(unpack(defaultColor))
	else
		self.colorSwatch:EnableMouse(false)
		self.label:SetTextColor(unpack(disabledTextColor))
		self.colorTexture:SetDesaturated(true)
		self.colorSwatch:SetBackdropColor(unpack(disabledTextColor))
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local colorSwatch = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	colorSwatch:SetBackdrop(frameBackdrop)
	colorSwatch:SetBackdropColor(unpack(defaultColor))
	colorSwatch:SetBackdropBorderColor(unpack(defaultColorSwatchBackdropBorderColor))
	colorSwatch:SetSize(defaultFrameWidth, defaultFrameHeight)
	colorSwatch:SetPoint("TOPLEFT")
	colorSwatch:SetPoint("BOTTOMRIGHT")
	colorSwatch:EnableMouse(true)
	colorSwatch:SetClipsChildren(true)

	local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
	colorTexture:SetPoint("TOPLEFT", frameBackdrop.edgeSize, -frameBackdrop.edgeSize)
	colorTexture:SetPoint("BOTTOMRIGHT", -frameBackdrop.edgeSize, frameBackdrop.edgeSize)
	colorTexture:SetVertexColor(unpack(defaultColor))

	local checkers = colorSwatch:CreateTexture(nil, "BACKGROUND")
	checkers:SetPoint("LEFT", frameBackdrop.edgeSize)
	checkers:SetPoint("RIGHT", -frameBackdrop.edgeSize)
	checkers:SetPoint("TOP", -frameBackdrop.edgeSize)
	checkers:SetPoint("BOTTOM", frameBackdrop.edgeSize)
	checkers:SetSize(defaultFontHeight - frameBackdrop.edgeSize, defaultFontHeight - frameBackdrop.edgeSize)
	checkers:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-checkered-50]], "REPEAT", "REPEAT")
	checkers:SetVertTile(true)
	checkers:SetHorizTile(true)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(unpack(defaultCheckersColor))

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetJustifyH("LEFT")
	label:SetJustifyV("MIDDLE")
	label:SetTextColor(unpack(defaultColor))

	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		label:SetFont(fPath, defaultFontHeight)
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
		color = defaultColor,
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
