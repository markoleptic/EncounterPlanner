local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPButton"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local defaultFrameHeight = 24
local defaultFrameWidth = 100
local defaultFontHeight = 14
local defaultBackgroundColor = Private.constants.colors.kDestructiveButtonActionColor
local toggledColor = Private.constants.colors.kToggledButtonColor
local defaultBackdropColor = Private.constants.colors.kDefaultButtonBackdropColor
local toggledBackdropColor = Private.constants.colors.kToggledButtonBackdropColor
local enabledTextColor = Private.constants.colors.kEnabledTextColor
local disabledTextColor = Private.constants.colors.kDisabledTextColor
local defaultIconColor = { 1, 1, 1, 1 }
local buttonBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = nil,
	tile = false,
	tileSize = 0,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

---@class EPButton : AceGUIWidget
---@field frame Frame
---@field button table|BackdropTemplate|Button
---@field icon Texture
---@field background Texture
---@field toggleIndicator Texture
---@field type string
---@field enabled boolean
---@field obj any
---@field toggleable boolean|nil
---@field toggled boolean|nil
---@field value any
---@field fireEventsIfDisabled boolean|nil

---@param self EPButton
local function OnAcquire(self)
	self:SetIsToggleable(false)
	self.toggleIndicator:Hide()
	self.background:SetPoint("TOPLEFT")
	self.background:SetPoint("BOTTOMRIGHT")
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self:SetIconPadding(0, 0)
	self:SetBackdrop(buttonBackdrop, defaultBackdropColor)
	self:SetBackdropColor(unpack(defaultBackdropColor))
	self:SetColor(unpack(defaultBackgroundColor))
	self:SetIconColor(unpack(defaultIconColor))
	self:SetIcon(nil)
	self:SetFontSize(defaultFontHeight)
	self.frame:Show()
	self:SetEnabled(true)
end

---@param self EPButton
local function OnRelease(self)
	self.toggleable = nil
	self.toggled = nil
	self.value = nil
	self.fireEventsIfDisabled = nil
end

---@param self EPButton
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	local fontString = self.button:GetFontString()
	self.icon:SetDesaturated(not enabled)
	self.button:SetMouseClickEnabled(enabled)
	if enabled then
		fontString:SetTextColor(unpack(enabledTextColor))
	else
		fontString:SetTextColor(unpack(disabledTextColor))
	end
	if not enabled then
		if self.fadeOutGroup:IsPlaying() then
			self.fadeOutGroup:Stop()
		end
		if self.fadeInGroup:IsPlaying() then
			self.fadeInGroup:Stop()
		end
		self.background:Hide()
	end
end

---@param self EPButton
---@param text string
---@param value any?
local function SetText(self, text, value)
	self.button:SetText(text or "")
	self.value = value
end

---@return any?
local function GetValue(self)
	return self.value
end

---@param self EPButton
---@param size integer
local function SetFontSize(self, size)
	local fontFile, _, flags = self.button:GetFontString():GetFont()
	if fontFile then
		self.button:GetFontString():SetFont(fontFile, size, flags)
	end
end

---@param self EPButton
---@param iconID string|number|nil
local function SetIcon(self, iconID)
	self.icon:SetTexture(iconID)
	if iconID then
		self.icon:Show()
		self.button:SetText("")
	else
		self.icon:Hide()
	end
end

---@param self EPButton
---@param r number
---@param g number
---@param b number
---@param a number
local function SetIconColor(self, r, g, b, a)
	local iconTexture = self.icon
	if iconTexture then
		iconTexture:SetVertexColor(r, g, b, a)
	end
end
---@param self EPButton
---@param totalHorizontalPadding number|nil
local function SetWidthFromText(self, totalHorizontalPadding)
	local fontString = self.button:GetFontString()
	self.frame:SetWidth(fontString:GetUnboundedStringWidth() + (totalHorizontalPadding or 20))
end

---@param self EPButton
---@param toggleable boolean?
local function SetIsToggleable(self, toggleable)
	self.toggleable = toggleable
end

---@param self EPButton
local function Toggle(self)
	if not self.toggleable then
		return
	end
	self.toggled = not self.toggled
	if not self.toggled then
		self.toggleIndicator:Hide()
		self.background:ClearAllPoints()
		self.background:SetPoint("TOPLEFT")
		self.background:SetPoint("BOTTOMRIGHT")
		self.button:SetBackdropColor(unpack(defaultBackdropColor))
	else
		self.background:ClearAllPoints()
		self.background:SetPoint("BOTTOMLEFT", 0, 0)
		self.background:SetPoint("BOTTOMRIGHT", 0, 0)
		self.background:SetPoint("TOP", 0, -2)
		self.button:SetBackdropColor(unpack(toggledBackdropColor))
		self.toggleIndicator:Show()
	end
end

---@param self EPButton
local function IsToggled(self)
	return self.toggled
end

---@param self EPButton
---@param backdropInfo backdropInfo
---@param backdropColor table<number>?
---@param backdropBorderColor table<number>?
local function SetBackdrop(self, backdropInfo, backdropColor, backdropBorderColor)
	self.button:SetBackdrop(backdropInfo)
	if backdropColor then
		self.button:SetBackdropColor(unpack(backdropColor))
	end
	if backdropBorderColor then
		self.button:SetBackdropBorderColor(unpack(backdropBorderColor))
	end
end

---@param self EPButton
---@param r number
---@param g number
---@param b number
---@param a number
local function SetBackdropColor(self, r, g, b, a)
	self.button:SetBackdropColor(r, g, b, a)
end

---@param self EPButton
---@param r number
---@param g number
---@param b number
---@param a number
local function SetColor(self, r, g, b, a)
	self.background:SetColorTexture(r, g, b, a)
end

---@param self EPButton
---@param x number
---@param y number
local function SetIconPadding(self, x, y)
	self.icon:SetPoint("TOPLEFT", x, -y)
	self.icon:SetPoint("BOTTOMRIGHT", -x, y)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:EnableMouse(true)

	local button = CreateFrame("Button", Type .. "Button" .. count, frame, "BackdropTemplate")
	button:SetBackdrop(buttonBackdrop)
	button:SetBackdropColor(unpack(defaultBackdropColor))
	button:RegisterForClicks("LeftButtonUp")
	button:SetAllPoints()
	button:SetNormalFontObject("GameFontNormal")
	button:SetText("Text")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		local fontString = button:GetFontString()
		fontString:SetFont(fPath, defaultFontHeight)
	end

	local icon = button:CreateTexture(Type .. "Icon" .. count, "OVERLAY")
	icon:SetBlendMode("ADD")
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMRIGHT")
	icon:Hide()
	icon:SetSnapToPixelGrid(false)
	icon:SetTexelSnappingBias(0)
	local background = button:CreateTexture(Type .. "Background" .. count, "BORDER")
	background:SetPoint("TOPLEFT")
	background:SetPoint("BOTTOMRIGHT")
	background:SetColorTexture(unpack(defaultBackgroundColor))
	background:Hide()

	local toggleIndicator = button:CreateTexture(Type .. "ToggleIndicator" .. count, "BORDER")
	toggleIndicator:SetPoint("TOPLEFT")
	toggleIndicator:SetPoint("TOPRIGHT")
	toggleIndicator:SetColorTexture(unpack(toggledColor))
	toggleIndicator:Hide()
	toggleIndicator:SetHeight(2)

	local fadeInGroup = background:CreateAnimationGroup()
	fadeInGroup:SetScript("OnPlay", function()
		background:Show()
	end)
	local fadeIn = fadeInGroup:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	local fadeOutGroup = background:CreateAnimationGroup()
	fadeOutGroup:SetScript("OnFinished", function()
		background:Hide()
	end)
	local fadeOut = fadeOutGroup:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")

	---@class EPButton
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetText = SetText,
		SetWidthFromText = SetWidthFromText,
		SetBackdropColor = SetBackdropColor,
		SetColor = SetColor,
		SetIsToggleable = SetIsToggleable,
		Toggle = Toggle,
		IsToggled = IsToggled,
		SetIcon = SetIcon,
		SetIconPadding = SetIconPadding,
		SetIconColor = SetIconColor,
		SetBackdrop = SetBackdrop,
		SetFontSize = SetFontSize,
		GetValue = GetValue,
		frame = frame,
		type = Type,
		button = button,
		icon = icon,
		background = background,
		toggleIndicator = toggleIndicator,
		fadeInGroup = fadeInGroup,
		fadeOutGroup = fadeOutGroup,
	}

	button:SetScript("OnEnter", function()
		if widget.enabled then
			if fadeOutGroup:IsPlaying() then
				fadeOutGroup:Stop()
			end
			fadeInGroup:Play()
			widget:Fire("OnEnter")
		elseif widget.fireEventsIfDisabled then
			widget:Fire("OnEnter")
		end
	end)
	button:SetScript("OnLeave", function()
		if fadeInGroup:IsPlaying() then
			fadeInGroup:Stop()
		end
		if widget.enabled then
			fadeOutGroup:Play()
		end
		widget:Fire("OnLeave")
	end)
	button:SetScript("OnClick", function()
		if widget.enabled then
			widget:Fire("Clicked")
		end
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
