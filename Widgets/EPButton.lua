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
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self.frame:Show()
	self:SetDisabled(false)
end

---@param self EPButton
local function OnRelease(self) end

---@param self EPButton
---@param text string
local function SetText(self, text)
	self.button:SetText(text or "")
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

	button.bg = button:CreateTexture(Type .. "Background" .. count, "BORDER")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0.725, 0.008, 0.008)
	button.bg:Hide()

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
		LayoutFinished = LayoutFinished,
		SetColor = SetColor,
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
