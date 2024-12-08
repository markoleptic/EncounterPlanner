local Type = "EPButton"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultFrameHeight = 24
local defaultFrameWidth = 100
local defaultFontHeight = 14
local buttonBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = nil,
	tile = false,
	tileSize = 0,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local function HandleButtonLeave(self)
	local fadeIn = self.fadeIn
	if fadeIn:IsPlaying() then
		fadeIn:Stop()
	end
	self.fadeOut:Play()
end

local function HandleButtonEnter(self)
	local fadeOut = self.fadeOut
	if fadeOut:IsPlaying() then
		fadeOut:Stop()
	end
	self.fadeIn:Play()
end

local function HandleButtonClicked(frame, _, _)
	local self = frame.obj
	self:Fire("Clicked")
end

---@class EPButton : AceGUIWidget
---@field frame Frame
---@field button table|BackdropTemplate|Button
---@field type string
---@field disabled boolean
---@field obj any
---@field toggleable boolean|nil
---@field toggled boolean|nil

---@param self EPButton
local function SetDisabled(self, disable)
	self.disabled = disable
	local fontString = self.button:GetFontString()
	if disable then
		fontString:SetTextColor(0.5, 0.5, 0.5)
	else
		fontString:SetTextColor(1, 1, 1)
	end
end

---@param self EPButton
local function OnAcquire(self)
	self:SetIsToggleable(false)
	self.button.toggleIndicator:Hide()
	self.button.bg:SetPoint("TOPLEFT")
	self.button.bg:SetPoint("BOTTOMRIGHT")
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self:SetIconPadding(0, 0)
	self:SetBackdropColor(0.25, 0.25, 0.25, 1)
	self:SetColor(0.725, 0.008, 0.008, 1)
	self:SetIcon(nil)
	self.frame:Show()
	self:SetDisabled(false)
end

---@param self EPButton
local function OnRelease(self)
	self.toggleable = nil
	self.toggled = nil
end

---@param self EPButton
---@param text string
local function SetText(self, text)
	self.button:SetText(text or "")
end

---@param self EPButton
---@param iconID string|number|nil
local function SetIcon(self, iconID)
	self.button.icon:SetTexture(iconID)
	if iconID then
		self.button.icon:Show()
		self.button:SetText("")
	else
		self.button.icon:Hide()
	end
end

---@param self EPButton
local function SetWidthFromText(self)
	local fontString = self.button:GetFontString()
	self.frame:SetWidth(fontString:GetUnboundedStringWidth() + 20)
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
		self.button.toggleIndicator:Hide()
		self.button.bg:ClearAllPoints()
		self.button.bg:SetAllPoints()
		self.button:SetBackdropColor(0.25, 0.25, 0.25, 1)
	else
		self.button.bg:ClearAllPoints()
		self.button.bg:SetPoint("BOTTOMLEFT", 0, 0)
		self.button.bg:SetPoint("BOTTOMRIGHT", 0, 0)
		self.button.bg:SetPoint("TOP", 0, -2)
		self.button:SetBackdropColor(0.35, 0.35, 0.35, 1)
		self.button.toggleIndicator:Show()
	end
end

---@param self EPButton
local function IsToggled(self)
	return self.toggled
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
	self.button.bg:SetColorTexture(r, g, b, a)
end

---@param self EPButton
---@param x number
---@param y number
local function SetIconPadding(self, x, y)
	self.button.icon:SetPoint("TOPLEFT", x, -y)
	self.button.icon:SetPoint("BOTTOMRIGHT", -x, y)
end

---@param self EPButton
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height) end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:EnableMouse(true)

	local button =
		CreateFrame("Button", Type .. "Button" .. count, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	button:SetBackdrop(buttonBackdrop)
	button:SetBackdropColor(0.25, 0.25, 0.25, 1)
	button:RegisterForClicks("LeftButtonUp")
	button:SetAllPoints()
	button:SetNormalFontObject("GameFontNormal")
	button:SetText("Text")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		local fontString = button:GetFontString()
		fontString:SetFont(fPath, defaultFontHeight)
	end

	button.icon = button:CreateTexture(Type .. "Icon" .. count, "OVERLAY")
	button.icon:SetBlendMode("ADD")
	button.icon:SetPoint("TOPLEFT")
	button.icon:SetPoint("BOTTOMRIGHT")
	button.icon:Hide()
	button.icon:SetSnapToPixelGrid(false)
	button.icon:SetTexelSnappingBias(0)
	button.bg = button:CreateTexture(Type .. "Background" .. count, "BORDER")
	button.bg:SetPoint("TOPLEFT")
	button.bg:SetPoint("BOTTOMRIGHT")
	button.bg:SetColorTexture(0.725, 0.008, 0.008)
	button.bg:Hide()

	button.toggleIndicator = button:CreateTexture(Type .. "ToggleIndicator" .. count, "BORDER")
	button.toggleIndicator:SetPoint("TOPLEFT")
	button.toggleIndicator:SetPoint("TOPRIGHT")
	button.toggleIndicator:SetColorTexture(74 / 255.0, 174 / 255.0, 242 / 255.0)
	button.toggleIndicator:Hide()
	button.toggleIndicator:SetHeight(2)

	button.fadeIn = button.bg:CreateAnimationGroup()
	button.fadeIn:SetScript("OnPlay", function()
		button.bg:Show()
	end)
	local fadeIn = button.fadeIn:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	button.fadeOut = button.bg:CreateAnimationGroup()
	button.fadeOut:SetScript("OnFinished", function()
		button.bg:Hide()
	end)
	local fadeOut = button.fadeOut:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")

	---@class EPButton
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetDisabled = SetDisabled,
		SetText = SetText,
		SetWidthFromText = SetWidthFromText,
		LayoutFinished = LayoutFinished,
		SetBackdropColor = SetBackdropColor,
		SetColor = SetColor,
		SetIsToggleable = SetIsToggleable,
		Toggle = Toggle,
		IsToggled = IsToggled,
		SetIcon = SetIcon,
		SetIconPadding = SetIconPadding,
		frame = frame,
		type = Type,
		button = button,
	}

	frame.obj = widget
	button.obj = widget

	button:SetScript("OnEnter", HandleButtonEnter)
	button:SetScript("OnLeave", HandleButtonLeave)
	button:SetScript("OnClick", HandleButtonClicked)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
